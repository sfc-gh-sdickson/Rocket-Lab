-- ============================================================================
-- Rocket Lab Intelligence Agent - Create Snowflake Intelligence Agent
-- ============================================================================
-- Purpose: Create and configure Snowflake Intelligence Agent with:
--          - Cortex Analyst tools (Semantic Views)
--          - Cortex Search tools (Unstructured Data)
--          - ML Model tools (Predictions)
-- Execution: Run this after completing steps 01-07 and running the notebook
-- 
-- CRITICAL VERIFICATION:
-- - Procedure parameter names MUST match tool input_schema properties
-- - Sample questions MUST reference metrics exposed in semantic views
-- - Sample questions MUST be answerable by generated data
--
-- ML MODELS (from notebook):
--   1. MISSION_RISK_PREDICTOR → PREDICT_MISSION_RISK(VARCHAR)
--   2. SUPPLIER_QUALITY_PREDICTOR → PREDICT_SUPPLIER_QUALITY(VARCHAR)
--   3. COMPONENT_FAILURE_PREDICTOR → PREDICT_COMPONENT_FAILURE(VARCHAR)
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE ROCKET_LAB_INTELLIGENCE;
USE SCHEMA ANALYTICS;
USE WAREHOUSE ROCKET_LAB_WH;

-- ============================================================================
-- Step 1: Grant Required Permissions for Cortex Analyst
-- ============================================================================

-- Grant Cortex Analyst user role to your role
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_ANALYST_USER TO ROLE SYSADMIN;

-- Grant usage on database and schemas
GRANT USAGE ON DATABASE ROCKET_LAB_INTELLIGENCE TO ROLE SYSADMIN;
GRANT USAGE ON SCHEMA ROCKET_LAB_INTELLIGENCE.ANALYTICS TO ROLE SYSADMIN;
GRANT USAGE ON SCHEMA ROCKET_LAB_INTELLIGENCE.RAW TO ROLE SYSADMIN;

-- Grant privileges on semantic views for Cortex Analyst
GRANT REFERENCES, SELECT ON SEMANTIC VIEW ROCKET_LAB_INTELLIGENCE.ANALYTICS.SV_MISSION_INTELLIGENCE TO ROLE SYSADMIN;
GRANT REFERENCES, SELECT ON SEMANTIC VIEW ROCKET_LAB_INTELLIGENCE.ANALYTICS.SV_SUPPLIER_COMPONENT_INTELLIGENCE TO ROLE SYSADMIN;

-- Grant usage on warehouse
GRANT USAGE ON WAREHOUSE ROCKET_LAB_WH TO ROLE SYSADMIN;

-- Grant usage on Cortex Search services
GRANT USAGE ON CORTEX SEARCH SERVICE ROCKET_LAB_INTELLIGENCE.RAW.MISSION_SEARCH_SERVICE TO ROLE SYSADMIN;
GRANT USAGE ON CORTEX SEARCH SERVICE ROCKET_LAB_INTELLIGENCE.RAW.TEST_SEARCH_SERVICE TO ROLE SYSADMIN;

-- Grant execute on ML model wrapper procedures
-- Parameter names MUST match procedure definitions in 07_create_model_wrapper_functions.sql
GRANT USAGE ON PROCEDURE ROCKET_LAB_INTELLIGENCE.ANALYTICS.PREDICT_MISSION_RISK(VARCHAR) TO ROLE SYSADMIN;
GRANT USAGE ON PROCEDURE ROCKET_LAB_INTELLIGENCE.ANALYTICS.PREDICT_SUPPLIER_QUALITY(VARCHAR) TO ROLE SYSADMIN;
GRANT USAGE ON PROCEDURE ROCKET_LAB_INTELLIGENCE.ANALYTICS.PREDICT_COMPONENT_FAILURE(VARCHAR) TO ROLE SYSADMIN;

-- ============================================================================
-- Step 2: Create Snowflake Intelligence Agent
-- ============================================================================

CREATE OR REPLACE AGENT ROCKET_LAB_AGENT
  COMMENT = 'Rocket Lab Intelligence Agent for launch operations and supply chain analytics'
  PROFILE = '{"display_name": "Rocket Lab Intelligence Agent", "avatar": "rocket-icon.png", "color": "black"}'
  FROM SPECIFICATION
  $$
models:
  orchestration: auto

orchestration:
  budget:
    seconds: 60
    tokens: 32000

instructions:
  response: 'You are a specialized analytics assistant for Rocket Lab, a leading space launch provider. For structured data queries use Cortex Analyst semantic views. For unstructured content use Cortex Search services. For predictions use ML model procedures. Keep responses concise and data-driven.'
  orchestration: 'For metrics and KPIs use Cortex Analyst tools. For mission documentation and test reports use Cortex Search tools. For risk forecasting and predictions use ML function tools.'
  system: 'You help analyze launch operations data including missions, vehicles, suppliers, components, and test results using structured and unstructured data sources.'
  sample_questions:
    # ========== 5 SIMPLE QUESTIONS (Cortex Analyst) ==========
    # All questions verified against semantic view metrics from 05_create_semantic_views.sql
    - question: 'How many scheduled missions do we have?'
      answer: 'I will query the missions table filtering by status=SCHEDULED to count missions.'
    - question: 'What is the total payload mass for all missions?'
      answer: 'I will sum the payload_mass_kg from the missions table.'
    - question: 'How many active suppliers do we have?'
      answer: 'I will count distinct supplier_id from the suppliers table filtering by status=ACTIVE.'
    - question: 'What is our average vehicle reuse count?'
      answer: 'I will calculate the average of reuse_count from the vehicles table.'
    - question: 'How many components are currently in stock?'
      answer: 'I will count components filtering by status=IN_STOCK.'
    # ========== 5 COMPLEX QUESTIONS (Cortex Analyst) ==========
    # All questions verified to use metrics exposed in semantic views
    - question: 'Compare mission revenue by launch site.'
      answer: 'I will query missions grouped by launch_site showing sum of contract_value.'
    - question: 'Show vehicle performance by type. Include total missions and average reuse.'
      answer: 'I will join missions with vehicles and aggregate mission count and avg reuse_count by vehicle_type.'
    - question: 'Analyze supplier spend by country. Show total spend and average quality.'
      answer: 'I will query suppliers grouped by country showing sum total_spend and avg quality_rating.'
    - question: 'What is the failure rate of tests by component type?'
      answer: 'I will join test_results with components and calculate percentage of FAILED tests by component_type.'
    - question: 'Show mission risk profile by target orbit. Include avg weather and technical risk.'
      answer: 'I will query missions grouped by target_orbit showing avg weather_risk_score and avg technical_risk_score.'
    # ========== 5 ML MODEL QUESTIONS (Predictions) ==========
    # All questions use correct parameter names from 07_create_model_wrapper_functions.sql
    - question: 'Predict mission risk for LEO orbit missions.'
      answer: 'I will call PREDICT_MISSION_RISK with target_orbit=LEO to analyze risk.'
    - question: 'Identify which Electronics suppliers might have quality issues.'
      answer: 'I will call PREDICT_SUPPLIER_QUALITY with supplier_type=ELECTRONICS to identify at-risk suppliers.'
    - question: 'Which propulsion components are likely to fail?'
      answer: 'I will call PREDICT_COMPONENT_FAILURE with component_type=PROPULSION to predict failure likelihood.'
    - question: 'What is the overall mission risk across all orbits?'
      answer: 'I will call PREDICT_MISSION_RISK with no filter to analyze all missions.'
    - question: 'Predict quality issues for all raw material suppliers.'
      answer: 'I will call PREDICT_SUPPLIER_QUALITY with supplier_type=RAW_MATERIAL to predict quality risks.'

tools:
  - tool_spec:
      type: 'cortex_analyst_text_to_sql'
      name: 'MissionIntelligenceAnalyst'
      description: 'Analyzes missions, vehicles, and test results'
  - tool_spec:
      type: 'cortex_analyst_text_to_sql'
      name: 'SupplierComponentAnalyst'
      description: 'Analyzes suppliers and components supply chain'
  - tool_spec:
      type: 'cortex_search'
      name: 'MissionSearchService'
      description: 'Searches mission documentation and customer requirements'
  - tool_spec:
      type: 'cortex_search'
      name: 'TestSearchService'
      description: 'Searches test result notes and failure reports'
  - tool_spec:
      type: 'generic'
      name: 'PredictMissionRisk'
      description: 'Predicts mission success/failure risk based on weather, technical, and payload data'
      input_schema:
        type: 'object'
        properties:
          target_orbit:
            type: 'string'
            description: 'Target orbit to filter (LEO, SSO, MEO, etc.) or null for all'
        required: []
  - tool_spec:
      type: 'generic'
      name: 'PredictSupplierQuality'
      description: 'Predicts supplier quality issues based on ratings and spend'
      input_schema:
        type: 'object'
        properties:
          supplier_type:
            type: 'string'
            description: 'Supplier type to filter (ELECTRONICS, RAW_MATERIAL, SERVICES, etc.) or null for all'
        required: []
  - tool_spec:
      type: 'generic'
      name: 'PredictComponentFailure'
      description: 'Predicts component failure likelihood based on test cycles and age'
      input_schema:
        type: 'object'
        properties:
          component_type:
            type: 'string'
            description: 'Component type to filter (PROPULSION, AVIONICS, STRUCTURE, BATTERY, etc.) or null for all'
        required: []

tool_resources:
  MissionIntelligenceAnalyst:
    semantic_view: 'ROCKET_LAB_INTELLIGENCE.ANALYTICS.SV_MISSION_INTELLIGENCE'
    execution_environment:
      type: 'warehouse'
      warehouse: 'ROCKET_LAB_WH'
      query_timeout: 60
  SupplierComponentAnalyst:
    semantic_view: 'ROCKET_LAB_INTELLIGENCE.ANALYTICS.SV_SUPPLIER_COMPONENT_INTELLIGENCE'
    execution_environment:
      type: 'warehouse'
      warehouse: 'ROCKET_LAB_WH'
      query_timeout: 60
  MissionSearchService:
    search_service: 'ROCKET_LAB_INTELLIGENCE.RAW.MISSION_SEARCH_SERVICE'
    max_results: 5
    title_column: 'doc_title'
    id_column: 'doc_id'
  TestSearchService:
    search_service: 'ROCKET_LAB_INTELLIGENCE.RAW.TEST_SEARCH_SERVICE'
    max_results: 5
    title_column: 'report_title'
    id_column: 'report_id'
  PredictMissionRisk:
    type: 'procedure'
    identifier: 'ROCKET_LAB_INTELLIGENCE.ANALYTICS.PREDICT_MISSION_RISK'
    execution_environment:
      type: 'warehouse'
      warehouse: 'ROCKET_LAB_WH'
      query_timeout: 60
  PredictSupplierQuality:
    type: 'procedure'
    identifier: 'ROCKET_LAB_INTELLIGENCE.ANALYTICS.PREDICT_SUPPLIER_QUALITY'
    execution_environment:
      type: 'warehouse'
      warehouse: 'ROCKET_LAB_WH'
      query_timeout: 60
  PredictComponentFailure:
    type: 'procedure'
    identifier: 'ROCKET_LAB_INTELLIGENCE.ANALYTICS.PREDICT_COMPONENT_FAILURE'
    execution_environment:
      type: 'warehouse'
      warehouse: 'ROCKET_LAB_WH'
      query_timeout: 60
  $$;

-- ============================================================================
-- Step 3: Verify Agent Creation
-- ============================================================================

-- Show created agent
SHOW AGENTS LIKE 'ROCKET_LAB_AGENT';

-- Describe agent configuration
DESCRIBE AGENT ROCKET_LAB_AGENT;

-- Grant usage
GRANT USAGE ON AGENT ROCKET_LAB_AGENT TO ROLE SYSADMIN;

-- ============================================================================
-- Step 4: Test Agent (Examples)
-- ============================================================================

-- Note: After agent creation, you can test it in Snowsight:
-- 1. Go to AI & ML > Agents
-- 2. Select ROCKET_LAB_AGENT
-- 3. Click "Chat" to interact with the agent

-- Example test queries:
/*
1. Structured queries (Cortex Analyst):
   - "How many scheduled missions do we have?"
   - "What is our average vehicle reuse count?"
   - "Show mission revenue by launch site"

2. Unstructured queries (Cortex Search):
   - "Search for mission requirements"
   - "Find test results about vibration failures"

3. Predictive queries (ML Models):
   - "Predict mission risk for LEO orbit missions"
   - "Identify at-risk Electronics suppliers"
   - "Which propulsion components are likely to fail?"
*/

-- ============================================================================
-- Success Message
-- ============================================================================

SELECT 'ROCKET_LAB_AGENT created successfully! Access it in Snowsight under AI & ML > Agents' AS status;

