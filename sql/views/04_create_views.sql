-- ============================================================================
-- Rocket Lab Intelligence Agent - Analytical Views
-- ============================================================================
-- Purpose: Create analytical views and ML feature views
-- Rules:
-- 1. All columns VERIFIED against 02_create_tables.sql
-- 2. Feature Views created for ML models (Single Source of Truth)
-- ============================================================================

USE DATABASE ROCKET_LAB_INTELLIGENCE;
USE SCHEMA ANALYTICS;
USE WAREHOUSE ROCKET_LAB_WH;

-- ============================================================================
-- View 1: Mission Summary
-- ============================================================================
CREATE OR REPLACE VIEW V_MISSION_SUMMARY AS
SELECT
    m.mission_id,
    m.mission_name,
    m.customer_name,
    m.launch_site,
    m.target_orbit,
    m.launch_date,
    m.status,
    m.contract_value,
    m.payload_mass_kg,
    m.weather_risk_score,
    m.technical_risk_score,
    v.vehicle_name,
    v.vehicle_type,
    v.status AS vehicle_status
FROM RAW.MISSIONS m
LEFT JOIN RAW.VEHICLES v ON m.vehicle_id = v.vehicle_id;

-- ============================================================================
-- View 2: Vehicle Status
-- ============================================================================
CREATE OR REPLACE VIEW V_VEHICLE_STATUS AS
SELECT
    v.vehicle_id,
    v.vehicle_name,
    v.vehicle_type,
    v.serial_number,
    v.status,
    v.stage_count,
    v.reuse_count,
    v.manufacturing_date,
    (SELECT COUNT(*) FROM RAW.MISSIONS m WHERE m.vehicle_id = v.vehicle_id) AS missions_flown,
    (SELECT COUNT(*) FROM RAW.COMPONENTS c WHERE c.vehicle_id = v.vehicle_id) AS component_count
FROM RAW.VEHICLES v;

-- ============================================================================
-- View 3: Supplier Performance
-- ============================================================================
CREATE OR REPLACE VIEW V_SUPPLIER_PERFORMANCE AS
SELECT
    s.supplier_id,
    s.supplier_name,
    s.supplier_type,
    s.country,
    s.quality_rating,
    s.delivery_rating,
    s.risk_score,
    s.total_spend,
    s.status,
    (SELECT COUNT(*) FROM RAW.COMPONENTS c WHERE c.supplier_id = s.supplier_id) AS components_supplied,
    (SELECT COUNT(*) FROM RAW.COMPONENTS c WHERE c.supplier_id = s.supplier_id AND c.status = 'FAILED') AS components_failed
FROM RAW.SUPPLIERS s;

-- ============================================================================
-- ML FEATURE VIEWS
-- ============================================================================

-- ============================================================================
-- View 4: Mission Risk Features
-- Model: MISSION_RISK_PREDICTOR
-- Features: Weather, Technical Risk, Payload Mass, Budget (Contract Value)
-- ============================================================================
CREATE OR REPLACE VIEW V_MISSION_RISK_FEATURES AS
SELECT
    m.mission_id,
    m.weather_risk_score::FLOAT AS weather_risk,
    m.technical_risk_score::FLOAT AS technical_risk,
    m.payload_mass_kg::FLOAT AS payload_mass,
    m.contract_value::FLOAT AS contract_val,
    m.target_orbit, -- Keep string for filtering if needed, but carefully
    CASE 
        WHEN m.status IN ('FAILURE', 'SCRUBBED') THEN 1
        ELSE 0
    END::FLOAT AS risk_label
FROM RAW.MISSIONS m
WHERE m.status IN ('SUCCESS', 'FAILURE', 'SCRUBBED', 'SCHEDULED');

-- ============================================================================
-- View 5: Supplier Quality Features
-- Model: SUPPLIER_QUALITY_PREDICTOR
-- Features: Ratings, Risk Score, Spend
-- ============================================================================
CREATE OR REPLACE VIEW V_SUPPLIER_QUALITY_FEATURES AS
SELECT
    s.supplier_id,
    s.quality_rating::FLOAT AS quality_score,
    s.delivery_rating::FLOAT AS delivery_score,
    s.risk_score::FLOAT AS risk_metric,
    s.total_spend::FLOAT AS spend_amount,
    s.supplier_type, -- For filtering
    CASE 
        WHEN s.status = 'INACTIVE' THEN 1
        WHEN s.status = 'PROBATION' THEN 1
        ELSE 0
    END::FLOAT AS quality_label
FROM RAW.SUPPLIERS s;

-- ============================================================================
-- View 6: Component Failure Features
-- Model: COMPONENT_FAILURE_PREDICTOR
-- Features: Test Cycles, Days Since Mfg
-- ============================================================================
CREATE OR REPLACE VIEW V_COMPONENT_FAILURE_FEATURES AS
SELECT
    c.component_id,
    c.test_cycles::FLOAT AS cycle_count,
    DATEDIFF('day', c.manufacturing_date, CURRENT_DATE())::FLOAT AS age_days,
    -- Join with test results for avg measurement? Too complex for now, stick to simple features
    c.component_type, -- For filtering
    CASE 
        WHEN c.status = 'FAILED' THEN 1
        ELSE 0
    END::FLOAT AS failure_label
FROM RAW.COMPONENTS c
WHERE c.status IN ('INSTALLED', 'IN_STOCK', 'TESTING', 'FAILED');

SELECT 'Analytical and Feature views created successfully' AS status;

