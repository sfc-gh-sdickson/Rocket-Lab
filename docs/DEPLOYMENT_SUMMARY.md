<img src="../Snowflake_Logo.svg" width="200">

# Rocket Lab — what is deployed

Account `AWS161`, role `ACCOUNTADMIN`, user `SNOWMAN`. This is the state after the rebuild and the ML retrain. Review this repository before deploying anything else.

## Objects

| Object | Name | State |
|---|---|---|
| Database | `ROCKET_LAB_INTELLIGENCE` | Present |
| Warehouse | `ROCKET_LAB_WH` | Present |
| Schemas | `RAW`, `ANALYTICS`, `ML` | Present |
| RAW tables | 22 | Loaded |
| Analytical views | 15 | `CUSTOMER_360` = 100 rows |
| Score table | `ANALYTICS.CUSTOMER_ML_SCORES` | 100 rows |
| Semantic views | 12 `RL_*_SV` | Deployed |
| Search services | 8 `RL_*_SEARCH` | Deployed |
| Models | 5, all version V1 | In `ROCKET_LAB_INTELLIGENCE.ML` |
| Functions | 11 `AGENT_GET_*` | Deployed |
| Agent | `SNOWFLAKE_INTELLIGENCE.AGENTS.ROCKET_LAB_AGENT` | 31 tools, 10/10 test |

## Data checked

| Measure | Value |
|---|---|
| Customers | 100 |
| Vehicles | 100 |
| Missions | 300 |
| Components | 5,000 |
| Engine telemetry | 150,000 |
| Maintenance | 6,000 |
| Anomalies | 753 |
| Tests | 20,000 |
| Failure reports | 765 |
| Mission documents | 150 |
| Contracts | 219 |
| Invoices | 1,995 |
| Tickets | 1,807 |
| Surveys | 1,200 |
| Usage days | 36,500 |
| Opportunities | 324 |
| Interactions | 1,916 |
| Launch success rate | 87.5% |
| Recovery attempts / recovered | 50 / 34 |
| High churn customers | 35 |
| ARR on those accounts | $765.2M |

## Models

| Model | Metric |
|---|---|
| `RL_PREDICTIVE_MAINTENANCE` | ROC AUC 0.981 |
| `RL_REMAINING_USEFUL_LIFE` | MAE 9.5 cycles, R² 0.971 |
| `RL_CHURN_RISK` | Grouped CV AUC 1.000 |
| `RL_CUSTOMER_HEALTH_SCORE` | MAE 2.13, R² 0.928 |
| `RL_EXPANSION_PROPENSITY` | Grouped CV AUC 1.000 |

## Agent tools

Analyst: `FleetAnalytics`, `MissionAnalytics`, `TelemetryAnalytics`, `ComponentHealthAnalytics`, `MaintenanceAnalytics`, `AnomalyAnalytics`, `SupplierAnalytics`, `Customer360Analytics`, `RevenueAnalytics`, `SupportAnalytics`, `PipelineAnalytics`, `MissionOpsAnalytics`.

Search: `MissionDocumentSearch`, `TestFailureSearch`, `KnowledgeSearch`, `MaintenanceSearch`, `AnomalySearch`, `InteractionSearch`, `SupportTicketSearch`, `CustomerFeedbackSearch`.

Functions: `GetFleetHealth`, `GetMissionSummary`, `GetComponentsAtRisk`, `GetMaintenanceCosts`, `GetAnomalyReport`, `GetRulEstimates`, `GetCustomer360`, `GetChurnRiskList`, `GetExpansionOpportunities`, `GetRenewalCalendar`, `GetAccountHealthSummary`.

## Not deployed

`component-life-dashboard/` is local. Do not treat it as a Snowflake Streamlit object.

## If you redeploy data

`sql/data/03_generate_synthetic_data.sql` recreates `CUSTOMER_ML_SCORES`. After it, run:

```bash
python3 notebooks/07_ml_models.py
python3 scripts/test_agent.py --connection AWS161
```

Until that finishes, churn and expansion answers come back empty.
