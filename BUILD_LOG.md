# Rocket Lab — build log

Account `AWS161`. Database `ROCKET_LAB_INTELLIGENCE`. Warehouse `ROCKET_LAB_WH`. Agent `SNOWFLAKE_INTELLIGENCE.AGENTS.ROCKET_LAB_AGENT`.

| Date | Step | Result |
|---|---|---|
| 2026-11-02 | Schema and 22 RAW tables | Deployed |
| 2026-11-02 | Synthetic data | 100 customers, 100 vehicles, 300 missions, 5,000 components, 150,000 telemetry rows, 6,000 maintenance, 753 anomalies, 20,000 tests, 765 failure reports, 150 mission documents, 219 contracts, 1,995 invoices, 1,807 tickets, 1,200 surveys, 36,500 usage days, 324 opportunities, 1,916 interactions |
| 2026-11-02 | Recovery flags | First version recovered 0 boosters because recovery depended on `ACTUAL`, which was not available yet. Final rule uses Electron missions with `m.I < 100`: attempt when `MOD(m.SEQ, 2) = 0`, recovered when `MOD(m.SEQ, 3) = 0`. Result: 50 attempts, 34 recovered |
| 2026-11-02 | Views | 15 analytical views. `CUSTOMER_360` returns 100 rows |
| 2026-11-02 | Semantic views | 12 `RL_*_SV` deployed |
| 2026-11-02 | Cortex Search | 8 `RL_*_SEARCH` services deployed |
| 2026-11-02 | ML | Five V1 models. Maint ROC AUC 0.981. RUL MAE 9.5 cycles, R² 0.971. Churn grouped CV AUC 1.000. Health CV MAE 2.13, R² 0.928. Expansion grouped CV AUC 1.000. 100 score rows |
| 2026-11-02 | Score wipe | Rerunning step 3 recreates `CUSTOMER_ML_SCORES` and empties it. Views were redeployed and `python3 notebooks/07_ml_models.py` was rerun. Churn and expansion answers recovered |
| 2026-11-02 | Agent functions | 11 functions deployed and tested |
| 2026-11-02 | Agent | 31 tools. `scripts/test_agent.py` 10/10 |
| 2026-11-02 | Component-life app | Local only. Query checked at 3,000 components, 395 urgent, median RUL 10 cycles. Not deployed |
| 2026-11-02 | Docs and diagrams | README, AGENT_SETUP, questions, ARTIFACTS_GUIDE, DEPLOYMENT_SUMMARY, agent.md, BUILD_LOG. Five SVGs pass `scripts/check_svg.py` |

## Verified outcomes

- Launch success rate: 87.5%
- Boosters recovered: 34 of 50 attempts
- High churn: 35 customers
- ARR on high-churn accounts: $765.2M
- ML scores: 100

## Caveat

Customer-model AUCs of 1.000 are from synthetic data. The hidden profile generates both the features and the labels. Do not quote them as production performance.

## Not done

No git commit. No further Snowflake deploy. The Streamlit app stays local until you ask for it.
