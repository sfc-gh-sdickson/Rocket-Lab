-- ============================================================================
-- Rocket Lab Intelligence Agent - Analytical & Feature Views
-- ============================================================================
-- Purpose: Create analytical views for reporting and Feature Views for ML
-- Feature Views are the SINGLE SOURCE OF TRUTH for both Training and Prediction
-- ============================================================================

USE DATABASE ROCKET_LAB_INTELLIGENCE;
USE SCHEMA ANALYTICS;
USE WAREHOUSE ROCKET_LAB_WH;

-- ============================================================================
-- View 1: Mission Summary (Analytical)
-- ============================================================================
CREATE OR REPLACE VIEW V_MISSION_SUMMARY AS
SELECT
    m.mission_id,
    m.mission_name,
    m.status,
    m.launch_date,
    m.launch_site,
    m.target_orbit,
    v.vehicle_name,
    v.vehicle_type,
    m.contract_value,
    m.payload_mass_kg,
    -- Calculated Metrics
    (m.contract_value / NULLIF(m.payload_mass_kg, 0))::NUMBER(10,2) AS cost_per_kg,
    DATEDIFF('day', CURRENT_DATE(), m.launch_date) AS days_until_launch
FROM RAW.MISSIONS m
LEFT JOIN RAW.VEHICLES v ON m.vehicle_id = v.vehicle_id;

-- ============================================================================
-- View 2: Supplier Performance (Analytical)
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
    (SELECT COUNT(*) FROM RAW.COMPONENTS c WHERE c.supplier_id = s.supplier_id) AS component_count
FROM RAW.SUPPLIERS s;

-- ============================================================================
-- ML FEATURE VIEWS (Single Source of Truth)
-- ============================================================================

-- ============================================================================
-- View 3: Mission Risk Features
-- Model: MISSION_RISK_PREDICTOR
-- Target: Risk Level (0=Low, 1=High) based on SUCCESS/FAILURE history
-- ============================================================================
CREATE OR REPLACE VIEW V_MISSION_RISK_FEATURES AS
SELECT
    m.mission_id,
    -- Numeric Features (Cast to FLOAT for ML)
    m.weather_risk_score::FLOAT AS weather_risk,
    m.technical_risk_score::FLOAT AS technical_risk,
    m.payload_mass_kg::FLOAT AS payload_mass,
    m.contract_value::FLOAT AS contract_val,
    -- Filter Column (String) - Only used for WHERE clauses
    m.target_orbit,
    -- Label (Target)
    CASE 
        WHEN m.status = 'FAILURE' THEN 1 
        ELSE 0 
    END AS risk_label
FROM RAW.MISSIONS m
WHERE m.status IN ('SUCCESS', 'FAILURE', 'SCHEDULED')
  AND m.weather_risk_score IS NOT NULL;

-- ============================================================================
-- View 4: Supplier Quality Features
-- Model: SUPPLIER_QUALITY_PREDICTOR
-- Target: Quality Issue Likely (0=Good, 1=Risk)
-- ============================================================================
CREATE OR REPLACE VIEW V_SUPPLIER_QUALITY_FEATURES AS
SELECT
    s.supplier_id,
    -- Numeric Features
    COALESCE(s.quality_rating, 3.0)::FLOAT AS quality_score,
    COALESCE(s.delivery_rating, 3.0)::FLOAT AS delivery_score,
    COALESCE(s.risk_score, 0.5)::FLOAT AS risk_metric,
    COALESCE(s.total_spend, 0)::FLOAT AS spend_amount,
    -- Filter Column
    s.supplier_type,
    -- Label
    CASE 
        WHEN s.quality_rating < 4.0 THEN 1 -- At Risk
        ELSE 0 -- Good
    END AS quality_label
FROM RAW.SUPPLIERS s
WHERE s.status = 'ACTIVE';

-- ============================================================================
-- View 5: Component Failure Features
-- Model: COMPONENT_FAILURE_PREDICTOR
-- Target: Failure Probability (0=Healthy, 1=Fail)
-- ============================================================================
CREATE OR REPLACE VIEW V_COMPONENT_FAILURE_FEATURES AS
SELECT
    c.component_id,
    -- Numeric Features
    c.test_cycles::FLOAT AS cycle_count,
    DATEDIFF('day', c.manufacturing_date, CURRENT_DATE())::FLOAT AS age_days,
    -- Filter Column
    c.component_type,
    -- Label
    CASE 
        WHEN c.status = 'FAILED' THEN 1 
        ELSE 0 
    END AS failure_label
FROM RAW.COMPONENTS c
WHERE c.manufacturing_date IS NOT NULL;

-- ============================================================================
-- Display confirmation
-- ============================================================================
SELECT 'Analytical and Feature Views created successfully' AS status;

