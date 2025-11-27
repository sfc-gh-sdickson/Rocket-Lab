-- ============================================================================
-- Rocket Lab Intelligence Agent - Agent Definition
-- ============================================================================
-- Purpose: Create the Cortex Agent with tools and verified questions
-- ============================================================================

USE DATABASE ROCKET_LAB_INTELLIGENCE;
USE SCHEMA ANALYTICS;
USE WAREHOUSE ROCKET_LAB_WH;

CREATE OR REPLACE CORTEX AGENT ROCKET_LAB_AGENT
    MODEL = 'llama3.1-70b'
    TOOLS = (
        -- Semantic Views
        SEMANTIC_MISSIONS,
        SEMANTIC_SUPPLIERS,
        SEMANTIC_VEHICLES,

        -- Cortex Search Services
        MISSION_SEARCH_SERVICE,
        TEST_SEARCH_SERVICE,

        -- ML Model Procedures
        PREDICT_MISSION_RISK,
        PREDICT_SUPPLIER_QUALITY,
        PREDICT_COMPONENT_FAILURE
    );

-- ============================================================================
-- SAMPLE QUESTIONS (Verified against Schema and Data)
-- ============================================================================

/*
SIMPLE QUESTIONS
1. "How many missions are currently scheduled?"
   - Verifies: SEMANTIC_MISSIONS.status
2. "List all vehicles with status 'READY'."
   - Verifies: SEMANTIC_VEHICLES.status
3. "What is the total spend for suppliers in New Zealand?"
   - Verifies: SEMANTIC_SUPPLIERS.country, SEMANTIC_SUPPLIERS.total_spend
4. "Show me the launch date for mission MSN-0001."
   - Verifies: SEMANTIC_MISSIONS.launch_date, SEMANTIC_MISSIONS.mission_id
5. "What is the average quality rating of all suppliers?"
   - Verifies: SEMANTIC_SUPPLIERS.quality_rating

COMPLEX QUESTIONS
1. "Compare the average payload mass for LEO vs SSO orbits."
   - Verifies: SEMANTIC_MISSIONS.payload_kg, SEMANTIC_MISSIONS.target_orbit, Aggregation
2. "Which vehicle type has the highest reuse count on average?"
   - Verifies: SEMANTIC_VEHICLES.vehicle_type, SEMANTIC_VEHICLES.reuse_count, Aggregation
3. "List the top 3 customers by total contract value."
   - Verifies: SEMANTIC_MISSIONS.customer_name, SEMANTIC_MISSIONS.contract_amount, Ordering
4. "Show the trend of mission success rates by vehicle type."
   - Verifies: SEMANTIC_MISSIONS.status, SEMANTIC_MISSIONS.vehicle_type, Grouping
5. "Find suppliers with high risk scores (> 0.5) and total spend over 500,000."
   - Verifies: SEMANTIC_SUPPLIERS.risk_score, SEMANTIC_SUPPLIERS.total_spend, Filtering

ML MODEL QUESTIONS
1. "Predict the risk level for mission MSN-0005."
   - Calls: PREDICT_MISSION_RISK(MSN-0005)
2. "Assess the quality risk for supplier SUP-0002."
   - Calls: PREDICT_SUPPLIER_QUALITY(SUP-0002)
3. "Is component CMP-000100 likely to fail?"
   - Calls: PREDICT_COMPONENT_FAILURE(CMP-000100)
4. "Run a risk prediction for the mission named 'Mission 10'."
   - Requires: Search 'Mission 10' -> Get ID -> Call PREDICT_MISSION_RISK
5. "Check failure probability for the battery pack component CMP-000200."
   - Calls: PREDICT_COMPONENT_FAILURE(CMP-000200)
*/

SELECT 'Rocket Lab Intelligence Agent created successfully' AS status;

