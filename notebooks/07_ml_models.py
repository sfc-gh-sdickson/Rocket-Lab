# %% [markdown]
# # Rocket Lab — ML Model Training (Fleet + Customer 360)
#
# Trains, evaluates and registers the models used by the Rocket Lab
# Intelligence Agent, then batch-scores every customer into
# `ROCKET_LAB_INTELLIGENCE.ANALYTICS.CUSTOMER_ML_SCORES`.
#
# **Fleet models**
# 1. Predictive Maintenance — Random Forest classifier (component needs attention)
# 2. Remaining Useful Life — Gradient Boosting regressor (cycles to replacement)
#
# **Customer 360 models**
# 3. Churn Risk — XGBoost classifier (probability of churn within 180 days)
# 4. Health Score — XGBoost regressor (0-100 composite account health)
# 5. Expansion Propensity — XGBoost classifier (probability of expansion)
#
# Models are logged to the Snowflake Model Registry in `ROCKET_LAB_INTELLIGENCE.ML`.
# Customer scores are produced by the registered model versions.
#
# **Prerequisites:** run SQL steps 01-06 first.

# %%
import warnings

import numpy as np
import pandas as pd
import xgboost as xgb
from sklearn.ensemble import GradientBoostingRegressor, RandomForestClassifier
from sklearn.metrics import classification_report, mean_absolute_error, r2_score, roc_auc_score
from sklearn.model_selection import KFold, StratifiedGroupKFold, train_test_split
from sklearn.preprocessing import LabelEncoder
from snowflake.ml.registry import Registry
from snowflake.snowpark import Session

warnings.filterwarnings("ignore")

try:
    from snowflake.snowpark.context import get_active_session
    session = get_active_session()
except Exception:
    session = Session.builder.config("connection_name", "AWS161").create()

session.use_database("ROCKET_LAB_INTELLIGENCE")
session.use_warehouse("ROCKET_LAB_WH")
session.sql("CREATE SCHEMA IF NOT EXISTS ROCKET_LAB_INTELLIGENCE.ML").collect()
registry = Registry(session=session, database_name="ROCKET_LAB_INTELLIGENCE", schema_name="ML")
MODEL_VERSION = "V1"
RANDOM_STATE = 42
print("Session ready:", session.get_current_account(), session.get_current_role())


def register(model, name, sample_input, comment, metrics):
    """Log a model version, replacing any previous copy so reruns are idempotent."""
    existing = registry.show_models()
    if not existing.empty and name.upper() in existing["name"].str.upper().values:
        registry.delete_model(name)
    mv = registry.log_model(
        model, model_name=name, version_name=MODEL_VERSION,
        sample_input_data=sample_input, comment=comment, target_platforms=["WAREHOUSE"])
    for k, v in metrics.items():
        mv.set_metric(k, float(v))
    print(f"Registered {name} {MODEL_VERSION}: {metrics}")
    return mv


# %% [markdown]
# ## 1. Fleet: component health
#
# Hardware already flown is expended, so it is excluded from both models.

# %%
components = session.table("ROCKET_LAB_INTELLIGENCE.ANALYTICS.COMPONENT_HEALTH").to_pandas()
live = components[components["COMPONENT_STATUS"] != "Flown"].copy()
live["TYPE_ENC"] = LabelEncoder().fit_transform(live["COMPONENT_TYPE"])
live["VEHICLE_ENC"] = LabelEncoder().fit_transform(live["VEHICLE_TYPE"])
print(f"Components: {len(components):,}  live (not yet flown): {len(live):,}")

# %% [markdown]
# ## 2. Predictive Maintenance (Random Forest)
#
# Predicts whether a component is Degraded, Needs Replacement or Failed from its
# cycle usage, supplier quality and test history.

# %%
FLEET_FEATURES = ["EXPECTED_LIFE_CYCLES", "CYCLES_USED", "LIFE_USED_PCT", "DAYS_SINCE_INSPECTION",
                  "QUALITY_RATING", "DEFECT_RATE_PPM", "TEST_COUNT", "TYPE_ENC", "VEHICLE_ENC"]
live["NEEDS_ATTENTION"] = live["COMPONENT_STATUS"].isin(["Degraded", "Needs Replacement", "Failed"]).astype(int)
X = live[FLEET_FEATURES].astype(float)
y = live["NEEDS_ATTENTION"]
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=RANDOM_STATE, stratify=y)

maint_model = RandomForestClassifier(n_estimators=200, max_depth=8, class_weight="balanced", random_state=RANDOM_STATE)
maint_model.fit(X_train, y_train)
maint_auc = roc_auc_score(y_test, maint_model.predict_proba(X_test)[:, 1])
print("=== Predictive Maintenance ===")
print(classification_report(y_test, maint_model.predict(X_test), digits=3))
print(f"ROC AUC: {maint_auc:.3f}")

# %% [markdown]
# ## 3. Remaining Useful Life (Gradient Boosting)
#
# Target: the inspector's remaining-life estimate in cycles. Predicted from
# observable usage and supplier attributes so RUL can be estimated between
# inspections.

# %%
RUL_FEATURES = ["EXPECTED_LIFE_CYCLES", "CYCLES_USED", "DAYS_SINCE_INSPECTION",
                "QUALITY_RATING", "DEFECT_RATE_PPM", "TYPE_ENC", "VEHICLE_ENC"]
X_rul = live[RUL_FEATURES].astype(float)
y_rul = live["INSPECTION_RUL_CYCLES"].astype(float)
Xr_train, Xr_test, yr_train, yr_test = train_test_split(X_rul, y_rul, test_size=0.2, random_state=RANDOM_STATE)

rul_model = GradientBoostingRegressor(n_estimators=300, max_depth=4, learning_rate=0.05, random_state=RANDOM_STATE)
rul_model.fit(Xr_train, yr_train)
rul_pred = rul_model.predict(Xr_test)
rul_mae, rul_r2 = mean_absolute_error(yr_test, rul_pred), r2_score(yr_test, rul_pred)
print(f"=== RUL === median target {y_rul.median():.0f} cycles  MAE: {rul_mae:.1f} cycles  R2: {rul_r2:.3f}")

# %% [markdown]
# ## 4. Customer 360 features
#
# `ANALYTICS.CUSTOMER_ML_FEATURES` holds monthly snapshots. Rows with labels use
# only information available at the snapshot date; the newest snapshot per
# customer is scored.

# %%
feat = session.table("ROCKET_LAB_INTELLIGENCE.ANALYTICS.CUSTOMER_ML_FEATURES").to_pandas()

FEATURES = ["TENURE_DAYS", "DAYS_TO_RENEWAL", "ARR_USD", "NPS_AVG_180D", "DETRACTOR_COUNT_180D",
            "TICKETS_90D", "CRITICAL_TICKETS_90D", "SLA_ATTAINMENT_PCT", "AVG_CSAT",
            "LATE_PAYMENT_PCT", "AVG_AUTOMATION_PCT", "USAGE_TREND",
            "NEGATIVE_INTERACTIONS_180D", "CRITICAL_ANOMALIES_180D"]
FEATURE_LABELS = {
    "TENURE_DAYS": "Short tenure", "DAYS_TO_RENEWAL": "Renewal approaching",
    "ARR_USD": "Contract value", "NPS_AVG_180D": "Low NPS", "DETRACTOR_COUNT_180D": "Detractor responses",
    "TICKETS_90D": "High ticket volume", "CRITICAL_TICKETS_90D": "Critical tickets",
    "SLA_ATTAINMENT_PCT": "SLA misses", "AVG_CSAT": "Low satisfaction",
    "LATE_PAYMENT_PCT": "Late payments", "AVG_AUTOMATION_PCT": "Low automation",
    "USAGE_TREND": "Declining mission operations usage",
    "NEGATIVE_INTERACTIONS_180D": "Negative interactions", "CRITICAL_ANOMALIES_180D": "Critical anomalies",
}

feat[FEATURES] = feat[FEATURES].apply(pd.to_numeric, errors="coerce").astype(float)
feat[FEATURES] = feat[FEATURES].fillna(feat[FEATURES].median())
scoring = feat.sort_values("SNAPSHOT_DATE").groupby("CUSTOMER_ID").tail(1).reset_index(drop=True)
X_c = scoring[FEATURES]
print(f"Snapshots: {len(feat):,}  customers scored: {len(scoring)}")


def grouped_oof(model, X, y, groups, n_splits=5):
    """Out-of-fold probabilities with customer-grouped, stratified folds."""
    oof = np.zeros(len(y))
    for tr, te in StratifiedGroupKFold(n_splits=n_splits, shuffle=True, random_state=RANDOM_STATE).split(X, y, groups):
        model.fit(X.iloc[tr], y.iloc[tr])
        oof[te] = model.predict_proba(X.iloc[te])[:, 1]
    return oof


# %% [markdown]
# ## 5. Churn Risk (XGBoost classifier)

# %%
train_churn = feat[feat["LABEL_CHURNED_180D"].notna()].reset_index(drop=True)
y_churn = train_churn["LABEL_CHURNED_180D"].astype(int)
churn_model = xgb.XGBClassifier(
    n_estimators=200, max_depth=3, learning_rate=0.05, subsample=0.8, colsample_bytree=0.8,
    min_child_weight=3, scale_pos_weight=(len(y_churn) - y_churn.sum()) / max(y_churn.sum(), 1),
    random_state=RANDOM_STATE, eval_metric="logloss")
churn_oof = grouped_oof(churn_model, train_churn[FEATURES], y_churn, train_churn["CUSTOMER_ID"])
churn_auc = roc_auc_score(y_churn, churn_oof)
churn_model.fit(train_churn[FEATURES], y_churn)
print(f"=== Churn Risk === snapshots: {len(y_churn)}  positives: {int(y_churn.sum())}  grouped CV AUC: {churn_auc:.3f}")

# %% [markdown]
# ## 6. Health Score (XGBoost regressor)
#
# Target: a 0-100 composite of satisfaction, support, payment, adoption and
# reliability. The model learns it from the raw signals.

# %%
def clip01(s):
    return s.clip(lower=0, upper=1)


health_target = 100 * (
    0.25 * clip01(X_c["NPS_AVG_180D"] / 10)
    + 0.20 * clip01(X_c["SLA_ATTAINMENT_PCT"] / 100)
    + 0.20 * clip01(1 - X_c["LATE_PAYMENT_PCT"] / 100)
    + 0.15 * clip01(1 - X_c["NEGATIVE_INTERACTIONS_180D"] / 5)
    + 0.10 * clip01(X_c["AVG_AUTOMATION_PCT"] / 100)
    + 0.10 * clip01(1 - X_c["CRITICAL_ANOMALIES_180D"] / 5))
health_model = xgb.XGBRegressor(n_estimators=300, max_depth=3, learning_rate=0.05, subsample=0.8,
                                random_state=RANDOM_STATE)
health_oof = np.zeros(len(health_target))
for tr, te in KFold(n_splits=5, shuffle=True, random_state=RANDOM_STATE).split(X_c):
    health_model.fit(X_c.iloc[tr], health_target.iloc[tr])
    health_oof[te] = health_model.predict(X_c.iloc[te])
health_mae = mean_absolute_error(health_target, health_oof)
health_r2 = r2_score(health_target, health_oof)
health_model.fit(X_c, health_target)
print(f"=== Health Score === 5-fold CV MAE: {health_mae:.2f} points  R2: {health_r2:.3f}")

# %% [markdown]
# ## 7. Expansion Propensity (XGBoost classifier)

# %%
train_exp = feat[feat["LABEL_EXPANDED_180D"].notna()].reset_index(drop=True)
y_exp = train_exp["LABEL_EXPANDED_180D"].astype(int)
exp_model = xgb.XGBClassifier(
    n_estimators=200, max_depth=3, learning_rate=0.05, subsample=0.8, colsample_bytree=0.8,
    min_child_weight=3, random_state=RANDOM_STATE, eval_metric="logloss")
exp_oof = grouped_oof(exp_model, train_exp[FEATURES], y_exp, train_exp["CUSTOMER_ID"])
exp_auc = roc_auc_score(y_exp, exp_oof)
exp_model.fit(train_exp[FEATURES], y_exp)
print(f"=== Expansion === snapshots: {len(y_exp)}  positives: {int(y_exp.sum())}  grouped CV AUC: {exp_auc:.3f}")

# %% [markdown]
# ## 8. Register all models

# %%
mv_maint = register(maint_model, "RL_PREDICTIVE_MAINTENANCE", X_train.head(20),
                    "Random Forest: probability a component needs attention", {"roc_auc": maint_auc})
mv_rul = register(rul_model, "RL_REMAINING_USEFUL_LIFE", Xr_train.head(20),
                  "Gradient Boosting: remaining useful life in cycles", {"mae_cycles": rul_mae, "r2": rul_r2})
mv_churn = register(churn_model, "RL_CHURN_RISK", X_c.head(20),
                    "XGBoost: probability of churn within 180 days", {"grouped_cv_roc_auc": churn_auc})
mv_health = register(health_model, "RL_CUSTOMER_HEALTH_SCORE", X_c.head(20),
                     "XGBoost: customer health score 0-100", {"cv_mae": health_mae, "cv_r2": health_r2})
mv_exp = register(exp_model, "RL_EXPANSION_PROPENSITY", X_c.head(20),
                  "XGBoost: probability of expansion within 180 days", {"grouped_cv_roc_auc": exp_auc})

# %% [markdown]
# ## 9. Batch-score customers with the registered models

# %%
score_input = session.create_dataframe(pd.concat([scoring[["CUSTOMER_ID"]], X_c], axis=1))


def run_registered(mv, function_name, output_col):
    out = mv.run(score_input, function_name=function_name).to_pandas()
    return out.set_index("CUSTOMER_ID")[output_col]


churn_scores = run_registered(mv_churn, "predict_proba", "output_feature_1")
health_scores = run_registered(mv_health, "predict", "output_feature_0")
exp_scores = run_registered(mv_exp, "predict_proba", "output_feature_1")

contribs = churn_model.get_booster().predict(xgb.DMatrix(X_c), pred_contribs=True)[:, :-1]
drivers = []
for row in contribs:
    top = [FEATURES[i] for i in np.argsort(-row)[:3] if row[i] > 0]
    drivers.append(", ".join(FEATURE_LABELS[f] for f in top) if top else "No significant risk drivers")

scores = pd.DataFrame({"CUSTOMER_ID": scoring["CUSTOMER_ID"].values})
scores["CHURN_RISK"] = scores["CUSTOMER_ID"].map(churn_scores).astype(float).round(4)
scores["HEALTH_SCORE"] = scores["CUSTOMER_ID"].map(health_scores).astype(float).clip(0, 100).round(1)
scores["EXPANSION_SCORE"] = scores["CUSTOMER_ID"].map(exp_scores).astype(float).round(4)
scores["CHURN_RISK_TIER"] = pd.cut(scores["CHURN_RISK"], [-1, 0.3, 0.6, 2], labels=["Low", "Medium", "High"]).astype(str)
scores["TOP_DRIVERS"] = drivers
scores["SCORED_AT"] = pd.Timestamp.utcnow().tz_localize(None)

cols = ["CUSTOMER_ID", "SCORED_AT", "CHURN_RISK", "CHURN_RISK_TIER", "HEALTH_SCORE", "EXPANSION_SCORE", "TOP_DRIVERS"]
session.sql("TRUNCATE TABLE ROCKET_LAB_INTELLIGENCE.ANALYTICS.CUSTOMER_ML_SCORES").collect()
session.write_pandas(scores[cols], "CUSTOMER_ML_SCORES", database="ROCKET_LAB_INTELLIGENCE", schema="ANALYTICS",
                     auto_create_table=False, overwrite=False, use_logical_type=True)
print(f"Wrote {len(scores)} rows to ANALYTICS.CUSTOMER_ML_SCORES")

# %% [markdown]
# ## 10. Summary

# %%
summary = scoring[["CUSTOMER_ID", "SEGMENT"]].merge(scores, on="CUSTOMER_ID")
print("=" * 70)
print("ROCKET LAB ML TRAINING SUMMARY")
print("=" * 70)
print(f"Predictive Maintenance   RF       test ROC AUC        {maint_auc:.3f}")
print(f"Remaining Useful Life    GBR      MAE {rul_mae:.1f} cycles, R2 {rul_r2:.3f}")
print(f"Churn Risk               XGBoost  grouped CV AUC      {churn_auc:.3f}")
print(f"Customer Health Score    XGBoost  CV MAE {health_mae:.2f} pts, R2 {health_r2:.3f}")
print(f"Expansion Propensity     XGBoost  grouped CV AUC      {exp_auc:.3f}")
print()
print(summary.groupby("CHURN_RISK_TIER")[["CHURN_RISK", "HEALTH_SCORE", "EXPANSION_SCORE"]].mean().round(3).to_string())
