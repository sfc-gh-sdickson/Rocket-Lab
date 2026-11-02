# Rocket Lab agent

`SNOWFLAKE_INTELLIGENCE.AGENTS.ROCKET_LAB_AGENT`

Display name: Rocket Lab Assistant. Color: red. Orchestration model: `auto`.

## What it is for

Launch fleet health, missions, Rutherford and Archimedes telemetry, component life, maintenance, anomalies, suppliers, and Customer 360 (contracts, ARR, invoices, support, NPS, mission-operations usage, pipeline, interactions, churn, health, expansion).

Currency is US dollars. Churn risk, health score and expansion propensity are model predictions trained on synthetic data. The agent is instructed to say when a number comes from a model.

## How it routes

Defined in `sql/agent/09_create_agent.sql`.

| Question shape | Tool |
|---|---|
| Fleet snapshot | `GetFleetHealth` |
| Cadence, success rate, backlog | `GetMissionSummary` |
| Vehicle counts, hardware roll-up | `FleetAnalytics` |
| Manifest, sites, orbits, recovery | `MissionAnalytics` |
| Engine readings | `TelemetryAnalytics` |
| One part's life and supplier | `ComponentHealthAnalytics` |
| Parts most likely to need work | `GetComponentsAtRisk`, `GetRulEstimates` |
| Refurbishment spend | `MaintenanceAnalytics`, `GetMaintenanceCosts` |
| Nonconformance counts and days lost | `AnomalyAnalytics`, `GetAnomalyReport` |
| Supplier quality | `SupplierAnalytics` |
| A named customer's brief | `GetCustomer360`, then a search tool if the user asks why |
| Who might churn, and the drivers | `GetChurnRiskList` |
| Who might expand | `GetExpansionOpportunities` |
| Renewals, with `days_ahead` | `GetRenewalCalendar` |
| Whole book of business | `GetAccountHealthSummary` |
| Compare customers | `Customer360Analytics` |
| Invoices and collections | `RevenueAnalytics` |
| Tickets and SLA | `SupportAnalytics` |
| Deals and win rate | `PipelineAnalytics` |
| Spacecraft operations usage | `MissionOpsAnalytics` |
| Documents, failures, procedures, tickets, notes, verbatims | the matching `*Search` tool |

An account brief should end with one or two next actions, and should include ARR, churn tier, health score and days to renewal.

## Sample questions in the spec

- How is the launch fleet doing right now?
- What is our launch success rate and how much backlog is still ahead of us?
- Which components are closest to needing replacement?
- What are the top root causes of anomalies and how many days of schedule have they cost?
- Give me a Customer 360 brief for Planet Labs.
- Which customers are most likely to churn and how much ARR is at risk?
- Which renewals come due in the next 120 days?
- Who are the best expansion candidates?

## Verification

`scripts/test_agent.py` calls `SNOWFLAKE.CORTEX.DATA_AGENT_RUN`. Last run: 10/10, including the two scoring questions after the retrain.

## Known failure

Rerunning `sql/data/03_generate_synthetic_data.sql` recreates `ANALYTICS.CUSTOMER_ML_SCORES` empty. Churn and expansion tools then return no scores. Fix: `python3 notebooks/07_ml_models.py`.
