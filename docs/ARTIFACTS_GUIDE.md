<img src="../Snowflake_Logo.svg" width="200">

# Rocket Lab Intelligence Agent — Artifacts

Artifacts are charts and tables saved from an agent answer. They keep the SQL, the chart settings and a snapshot so you can reopen them without asking again.

## Before you start

- Snowsight, **AI & ML > Snowflake Intelligence**.
- Agent: **Rocket Lab Assistant** (`SNOWFLAKE_INTELLIGENCE.AGENTS.ROCKET_LAB_AGENT`).
- Warehouse: `ROCKET_LAB_WH`.
- A role with USAGE on the agent and the underlying views.

## Questions that produce a chart or a table

| Ask | You should get |
|---|---|
| Show launch success rate by vehicle type as a bar chart. | Bar chart. Electron and Neutron. Overall success is 87.5%. |
| How many missions attempted recovery, and how many boosters came back? Show as a table. | Table. 50 attempts, 34 recovered. |
| Show maintenance cost by vehicle type for the last 6 months as a line chart. | Line chart from `MAINTENANCE_MONTHLY_TREND`. |
| Which components have the shortest remaining useful life? Show the top 20 as a table. | Table from `GetRulEstimates` or `ComponentHealthAnalytics`. |
| Break anomalies down by severity as a bar chart. | Bar chart. 753 anomalies in total. |
| Show active ARR by customer segment as a bar chart. | Bar chart from `Customer360Analytics` or `RevenueAnalytics`. |
| Which customers are high churn risk, and how much ARR sits on them? | Table. 35 customers, $765.2M. |
| Show NPS by segment as a bar chart. | Bar chart from `CUSTOMER_SURVEY_RESULTS` (1,200 surveys). |
| Show the renewal calendar for the next 120 days as a table. | Table from `GetRenewalCalendar`. |
| Show pipeline amount by stage as a bar chart. | Bar chart. 324 opportunities. |

If the churn table is empty, `CUSTOMER_ML_SCORES` was wiped by a data reload. Rerun `python3 notebooks/07_ml_models.py`.

## Save

1. Ask one of the questions above.
2. On the chart or table, choose **Save to Artifacts** (or the equivalent save action in Intelligence).
3. Name it after the question, for example `Launch success by vehicle`.
4. Reopen it from Artifacts. Refresh reruns the saved SQL.

## Share

Share from the artifact with people who already have access to `ROCKET_LAB_AGENT` and `ROCKET_LAB_INTELLIGENCE`. Do not grant `PUBLIC` unless that is an explicit request.

## Good first set

- Launch success by vehicle
- Recovery attempts vs recovered
- Top 20 components by remaining life
- High-churn customers and ARR
- Renewals in 120 days
- Pipeline by stage
