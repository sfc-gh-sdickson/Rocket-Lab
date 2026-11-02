<img src="../Snowflake_Logo.svg" width="200">

# Questions for the Rocket Lab Intelligence Agent

Ask these in Snowflake Intelligence against **Rocket Lab Assistant**. Names below are real on the loaded data (Planet Labs is a sample-question customer). Counts were checked on 2026-11-02.

The old questions about `PREDICT_MISSION_RISK`, supplier quality models and `CMP-000100` do not match this build. Do not use them.

## Fleet and missions

1. How is the launch fleet doing right now?
2. What is our launch success rate, and how much backlog is still ahead of us?
3. Show launch success rate by vehicle type.
4. How many Electron missions attempted recovery, and how many boosters were recovered?
5. Which launch sites have flown, and what is the success rate at each?
6. Which missions slipped the most, and by how many days?
7. What is the manifest for the next quarter?
8. Compare payload and contract value for LEO versus SSO.

Expected anchors: 300 missions, 87.5% success, 50 recovery attempts, 34 recovered.

## Hardware

9. Which components are closest to needing replacement?
10. Show the 20 components with the shortest remaining useful life.
11. What are the top root causes of anomalies, and how many days of schedule have they cost?
12. How many anomalies are still open, by severity?
13. What did we spend on maintenance in the last 6 months, by vehicle type?
14. Which suppliers are behind the parts with the worst remaining life?

Expected anchors: 5,000 components, 753 anomalies, 6,000 maintenance records.

## Documents

15. Find the mission document that discusses booster recovery.
16. Search test failure reports that mention nozzle temperature.
17. What does the knowledge base say about a Rutherford hot-fire abort?
18. Find maintenance notes for a turbopump replacement.

These should hit `MissionDocumentSearch`, `TestFailureSearch`, `KnowledgeSearch` and `MaintenanceSearch`.

## One account

19. Give me a Customer 360 brief for Planet Labs.
20. Why is that account's health score what it is? Include recent call notes.
21. What tickets are open for Planet Labs, and did we miss SLA?
22. What did Planet Labs say on the last NPS survey?
23. When does the Planet Labs contract renew, and what is the active ARR?

The brief should include ARR, churn tier, health score and days to renewal, and should end with a next action. Notes, tickets and survey comments come from search, not from the brief alone.

## Book of business

24. Which customers are most likely to churn, and how much ARR is at risk?
25. Who are the best expansion candidates?
26. Which renewals come due in the next 120 days?
27. Summarize account health across the portfolio.
28. Show active ARR by segment.
29. Show win rate and open pipeline by stage.
30. Which segment has the worst SLA over the last 90 days?
31. Where is mission-operations usage falling quarter over quarter?

Expected anchors: 35 high-churn customers, $765.2M ARR on those accounts, 100 score rows, 324 opportunities, 1,200 surveys, 1,807 tickets.

## What a bad answer looks like

- Churn or expansion comes back empty. `CUSTOMER_ML_SCORES` was wiped by a data reload. Rerun `python3 notebooks/07_ml_models.py`.
- A success rate that is not 87.5% on the full flown set. Ask which missions were included.
- A recovered-booster count of 0. The recovery rule was fixed; 34 is the checked number.
- A model score presented as a fact with no mention that it is a prediction on synthetic data.
