-- ============================================================================
-- Rocket Lab Intelligence Agent - Cortex Search
-- ============================================================================
-- Purpose: Enable semantic search over unstructured data
-- Requirements: Change Tracking enabled on source tables
-- ============================================================================

USE DATABASE ROCKET_LAB_INTELLIGENCE;
USE SCHEMA ANALYTICS;
USE WAREHOUSE ROCKET_LAB_WH;

-- Enable Change Tracking (Required for Cortex Search)
ALTER TABLE RAW.MISSIONS SET CHANGE_TRACKING = TRUE;
ALTER TABLE RAW.TEST_RESULTS SET CHANGE_TRACKING = TRUE;
ALTER TABLE RAW.COMPONENTS SET CHANGE_TRACKING = TRUE;

-- ============================================================================
-- Cortex Search Service: Missions
-- ============================================================================
-- Allows searching mission names and customers
CREATE OR REPLACE CORTEX SEARCH SERVICE MISSION_SEARCH_SERVICE
ON mission_name
ATTRIBUTES customer_name, launch_site, status
WAREHOUSE = ROCKET_LAB_WH
TARGET_LAG = '1 minute'
AS SELECT 
    mission_name,
    customer_name,
    launch_site,
    status,
    target_orbit
FROM RAW.MISSIONS;

-- ============================================================================
-- Cortex Search Service: Test Results (Unstructured/Text)
-- ============================================================================
-- Allows searching test notes and results
CREATE OR REPLACE CORTEX SEARCH SERVICE TEST_SEARCH_SERVICE
ON notes
ATTRIBUTES test_type, result, inspector_id
WAREHOUSE = ROCKET_LAB_WH
TARGET_LAG = '1 minute'
AS SELECT
    notes,
    test_type,
    result,
    inspector_id,
    measured_value
FROM RAW.TEST_RESULTS;

SELECT 'Cortex Search services created successfully' AS status;

