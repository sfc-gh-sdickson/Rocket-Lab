-- ============================================================================
-- Rocket Lab Intelligence Agent - Cortex Search Service Setup
-- ============================================================================
-- Purpose: Create unstructured data tables and Cortex Search services for
--          mission documents and test reports
-- Syntax: Verified against Snowflake SQL Reference
-- ============================================================================

USE DATABASE ROCKET_LAB_INTELLIGENCE;
USE SCHEMA RAW;
USE WAREHOUSE ROCKET_LAB_WH;

-- ============================================================================
-- Step 1: Create table for Mission Documents (Unstructured)
-- ============================================================================
CREATE OR REPLACE TABLE MISSION_DOCUMENTS (
    doc_id VARCHAR(30) PRIMARY KEY,
    mission_id VARCHAR(30),
    doc_title VARCHAR(200),
    doc_type VARCHAR(50), -- 'REQUIREMENTS', 'FLIGHT_PLAN', 'POST_MISSION_REPORT'
    content VARCHAR(16777216), -- Long text content
    author VARCHAR(100),
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (mission_id) REFERENCES MISSIONS(mission_id)
);

-- ============================================================================
-- Step 2: Create table for Test Failure Reports (Unstructured)
-- ============================================================================
CREATE OR REPLACE TABLE TEST_FAILURE_REPORTS (
    report_id VARCHAR(30) PRIMARY KEY,
    test_id VARCHAR(30),
    component_type VARCHAR(50),
    report_title VARCHAR(200),
    content VARCHAR(16777216),
    severity VARCHAR(20), -- 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (test_id) REFERENCES TEST_RESULTS(test_id)
);

-- ============================================================================
-- Step 3: Enable Change Tracking (Required for Cortex Search)
-- ============================================================================
ALTER TABLE MISSION_DOCUMENTS SET CHANGE_TRACKING = TRUE;
ALTER TABLE TEST_FAILURE_REPORTS SET CHANGE_TRACKING = TRUE;

-- ============================================================================
-- Step 4: Generate Sample Mission Documents
-- ============================================================================
INSERT INTO MISSION_DOCUMENTS (doc_id, mission_id, doc_title, doc_type, content, author)
VALUES
('DOC001', 'MSN0001', 'Mission Requirements - Wise One', 'REQUIREMENTS', 
$$MISSION REQUIREMENTS DOCUMENT
Mission: The Wise One Looks Ahead
Customer: NRO
Orbit: LEO (500km, 45 deg inclination)

1.0 PAYLOAD
The payload consists of two (2) NRO reconnaissance satellites. Total mass: 280kg.
Deployment mechanism: Maxwell Dispenser.

2.0 LAUNCH WINDOW
Primary: 2024-07-15 09:00 UTC
Backup: 2024-07-16 09:00 UTC

3.0 ORBITAL PARAMETERS
Injection accuracy: +/- 5km semi-major axis.
RAAN accuracy: +/- 0.1 deg.

4.0 CONSTRAINTS
- No telemetry downlink over specific regions (See Appendix A).
- Maximum vibration load: 6.5 Grms.
$$, 'System Engineering'),

('DOC002', 'MSN0002', 'Flight Plan - Electron Flight 42', 'FLIGHT_PLAN',
$$FLIGHT PLAN SEQUENCE
T-0: Liftoff
T+2:30: Main Engine Cutoff (MECO)
T+2:34: Stage 1 Separation
T+2:36: Stage 2 Ignition
T+3:10: Fairing Jettison
T+8:55: Battery Hot Swap
T+9:05: Stage 2 Cutoff (SECO)
T+50:00: Curie Kick Stage Ignition
T+52:00: Payload Deployment

CONTINGENCY MODES
- Abort available until T-2s.
- Flight Termination System (FTS) active until orbital insertion.
$$, 'Flight Dynamics');

-- ============================================================================
-- Step 5: Generate Sample Test Failure Reports
-- ============================================================================
INSERT INTO TEST_FAILURE_REPORTS (report_id, test_id, component_type, report_title, content, severity)
VALUES
('RPT001', 'TST0001', 'PROPULSION', 'Rutherford Injector Flow Anomaly',
$$FAILURE ANALYSIS REPORT
Component: Rutherford Engine Injector
Issue: Uneven fuel flow observed during static fire test.

OBSERVATIONS
High-speed camera data shows sputtering in Quadrant 4.
Pressure sensors indicated 15% drop in chamber pressure at T+5s.

ROOT CAUSE
Debris blockage in injector port #12. Analysis confirms foreign object debris (FOD) consistent with machining swarf.

CORRECTIVE ACTION
1. Purge all fuel lines.
2. Implement improved ultrasonic cleaning for injector plates.
3. Add 10-micron filter to test stand supply line.
$$, 'HIGH'),

('RPT002', 'TST0002', 'AVIONICS', 'Flight Computer Thermal Shutdown',
$$THERMAL TEST FAILURE
Component: Flight Computer B
Issue: System initiated thermal shutdown at 65C.

DATA ANALYSIS
Log files show CPU temperature rising 2C/sec under load.
Thermal paste application appears uneven upon disassembly.

ROOT CAUSE
Manufacturing process deviation. Heatsink torque spec was not met (4nm vs 6nm required).

CORRECTIVE ACTION
1. Retrain assembly technicians on torque procedures.
2. Add QA inspection point for heatsink installation.
$$, 'MEDIUM');

-- ============================================================================
-- Step 6: Create Cortex Search Services
-- ============================================================================

-- Mission Search Service
CREATE OR REPLACE CORTEX SEARCH SERVICE MISSION_SEARCH_SERVICE
  ON content
  ATTRIBUTES doc_type, mission_id
  WAREHOUSE = ROCKET_LAB_WH
  TARGET_LAG = '1 hour'
  COMMENT = 'Search service for mission requirements and flight plans'
AS SELECT
    doc_id,
    content,
    doc_title,
    doc_type,
    mission_id,
    author
FROM MISSION_DOCUMENTS;

-- Test Search Service
CREATE OR REPLACE CORTEX SEARCH SERVICE TEST_SEARCH_SERVICE
  ON content
  ATTRIBUTES component_type, severity
  WAREHOUSE = ROCKET_LAB_WH
  TARGET_LAG = '1 hour'
  COMMENT = 'Search service for test failure reports and root cause analysis'
AS SELECT
    report_id,
    content,
    report_title,
    component_type,
    severity,
    test_id
FROM TEST_FAILURE_REPORTS;

-- ============================================================================
-- Display confirmation
-- ============================================================================
SELECT 'Cortex Search services created successfully' AS status;

