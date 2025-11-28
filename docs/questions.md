<img src="../Snowflake_Logo.svg" width="200">

# Sample Questions for Rocket Lab Intelligence Agent

## Simple Questions (Data Retrieval)
1. "How many missions are currently scheduled?"
2. "List all vehicles with status 'READY'."
3. "What is the total spend for suppliers in New Zealand?"
4. "Show me the launch date for mission MSN-0001."
5. "What is the average quality rating of all suppliers?"

## Complex Questions (Aggregation & Reasoning)
1. "Compare the average payload mass for LEO vs SSO orbits."
2. "Which vehicle type has the highest reuse count on average?"
3. "List the top 3 customers by total contract value."
4. "Show the trend of mission success rates by vehicle type."
5. "Find suppliers with high risk scores (> 0.5) and total spend over 500,000."

## Machine Learning & Predictive Questions
1. "Predict the risk level for mission MSN-0005."
2. "Assess the quality risk for supplier SUP-0002."
3. "Is component CMP-000100 likely to fail?"
4. "Run a risk prediction for the mission named 'Mission 10'."
5. "Check failure probability for the battery pack component CMP-000200."
6. "Assess mission risk for all LEO orbit missions." (Uses Aggregate Wrapper)
7. "Which supplier types have the highest risk?" (Uses Aggregate Wrapper)
8. "Analyze component failure risk for PROPULSION components." (Uses Aggregate Wrapper)

## Cortex Search Questions (Unstructured Data)
1. "Find test results that mention 'vibration issue'."
2. "Search for missions with 'NRO' as the customer."
3. "Show me failure notes for thermal tests."

