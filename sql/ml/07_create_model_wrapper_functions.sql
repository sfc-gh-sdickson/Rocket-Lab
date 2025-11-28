-- ============================================================================
-- Rocket Lab Intelligence Agent - ML Model Wrappers
-- ============================================================================
-- Purpose: SQL stored procedures to invoke ML models
-- Pattern: EXACTLY matches Kratos Defense working example (SQL Procedures)
-- Syntax: Verified against Snowflake SQL Reference
-- ============================================================================

USE DATABASE ROCKET_LAB_INTELLIGENCE;
USE SCHEMA ANALYTICS;
USE WAREHOUSE ROCKET_LAB_WH;

-- ============================================================================
-- 1. Mission Risk Predictor Wrapper
-- Model: MISSION_RISK_PREDICTOR
-- Features: Weather, Technical Risk, Payload Mass, Budget (Contract Value)
-- ============================================================================
CREATE OR REPLACE PROCEDURE PREDICT_MISSION_RISK(
    TARGET_ORBIT VARCHAR
)
RETURNS STRING
LANGUAGE SQL
COMMENT = 'Calls MISSION_RISK_PREDICTOR ML model to predict mission success/failure risk'
AS $$
DECLARE
    result_json STRING;
    total_count INTEGER;
    low_risk INTEGER;
    high_risk INTEGER;
    high_risk_pct FLOAT;
    avg_weather_risk FLOAT;
BEGIN
    -- 1. Get predictions using the ML model
    WITH predictions AS (
        WITH m AS MODEL ROCKET_LAB_INTELLIGENCE.ANALYTICS.MISSION_RISK_PREDICTOR
        SELECT
            weather_risk,
            m!PREDICT(
                weather_risk,
                technical_risk,
                payload_mass,
                contract_val,
                target_orbit
            ):RISK_LABEL::INT AS predicted_risk
        FROM ROCKET_LAB_INTELLIGENCE.ANALYTICS.V_MISSION_RISK_FEATURES
        WHERE (:TARGET_ORBIT IS NULL OR :TARGET_ORBIT = 'NULL' OR :TARGET_ORBIT = '' OR UPPER(target_orbit) = UPPER(:TARGET_ORBIT))
        LIMIT 100
    )
    SELECT
        COUNT(*),
        SUM(CASE WHEN predicted_risk = 0 THEN 1 ELSE 0 END),
        SUM(CASE WHEN predicted_risk = 1 THEN 1 ELSE 0 END),
        ROUND(AVG(weather_risk), 2)
    INTO total_count, low_risk, high_risk, avg_weather_risk
    FROM predictions;

    -- Calculate percentage
    IF (total_count > 0) THEN
        high_risk_pct := ROUND(high_risk / total_count * 100, 2);
    ELSE
        high_risk_pct := 0;
    END IF;

    -- Build JSON response
    result_json := OBJECT_CONSTRUCT(
        'prediction_source', 'MISSION_RISK_PREDICTOR ML Model',
        'orbit_filter', COALESCE(:TARGET_ORBIT, 'ALL'),
        'missions_analyzed', total_count,
        'predicted_low_risk', low_risk,
        'predicted_high_risk', high_risk,
        'high_risk_pct', high_risk_pct,
        'avg_weather_risk_factor', avg_weather_risk
    )::STRING;

    RETURN result_json;
END;
$$;

-- ============================================================================
-- 2. Supplier Quality Predictor Wrapper
-- Model: SUPPLIER_QUALITY_PREDICTOR
-- Features: Ratings, Risk Score, Spend
-- ============================================================================
CREATE OR REPLACE PROCEDURE PREDICT_SUPPLIER_QUALITY(
    SUPPLIER_TYPE VARCHAR
)
RETURNS STRING
LANGUAGE SQL
COMMENT = 'Calls SUPPLIER_QUALITY_PREDICTOR ML model to predict supplier quality issues'
AS $$
DECLARE
    result_json STRING;
    total_count INTEGER;
    good_standing INTEGER;
    at_risk INTEGER;
    at_risk_pct FLOAT;
    avg_quality FLOAT;
BEGIN
    WITH predictions AS (
        WITH m AS MODEL ROCKET_LAB_INTELLIGENCE.ANALYTICS.SUPPLIER_QUALITY_PREDICTOR
        SELECT
            quality_score,
            m!PREDICT(
                quality_score,
                delivery_score,
                risk_metric,
                spend_amount,
                supplier_type
            ):QUALITY_LABEL::INT AS predicted_quality
        FROM ROCKET_LAB_INTELLIGENCE.ANALYTICS.V_SUPPLIER_QUALITY_FEATURES
        WHERE (:SUPPLIER_TYPE IS NULL OR :SUPPLIER_TYPE = 'NULL' OR :SUPPLIER_TYPE = '' OR UPPER(supplier_type) = UPPER(:SUPPLIER_TYPE))
        LIMIT 100
    )
    SELECT
        COUNT(*),
        SUM(CASE WHEN predicted_quality = 0 THEN 1 ELSE 0 END),
        SUM(CASE WHEN predicted_quality = 1 THEN 1 ELSE 0 END),
        ROUND(AVG(quality_score), 2)
    INTO total_count, good_standing, at_risk, avg_quality
    FROM predictions;

    IF (total_count > 0) THEN
        at_risk_pct := ROUND(at_risk / total_count * 100, 2);
    ELSE
        at_risk_pct := 0;
    END IF;

    result_json := OBJECT_CONSTRUCT(
        'prediction_source', 'SUPPLIER_QUALITY_PREDICTOR ML Model',
        'supplier_type_filter', COALESCE(:SUPPLIER_TYPE, 'ALL'),
        'suppliers_analyzed', total_count,
        'predicted_good_standing', good_standing,
        'predicted_at_risk', at_risk,
        'at_risk_pct', at_risk_pct,
        'avg_quality_score', avg_quality
    )::STRING;

    RETURN result_json;
END;
$$;

-- ============================================================================
-- 3. Component Failure Predictor Wrapper
-- Model: COMPONENT_FAILURE_PREDICTOR
-- Features: Test Cycles, Age
-- ============================================================================
CREATE OR REPLACE PROCEDURE PREDICT_COMPONENT_FAILURE(
    COMPONENT_TYPE VARCHAR
)
RETURNS STRING
LANGUAGE SQL
COMMENT = 'Calls COMPONENT_FAILURE_PREDICTOR ML model to predict component failure likelihood'
AS $$
DECLARE
    result_json STRING;
    total_count INTEGER;
    healthy INTEGER;
    likely_fail INTEGER;
    fail_pct FLOAT;
    avg_cycles FLOAT;
BEGIN
    WITH predictions AS (
        WITH m AS MODEL ROCKET_LAB_INTELLIGENCE.ANALYTICS.COMPONENT_FAILURE_PREDICTOR
        SELECT
            cycle_count,
            m!PREDICT(
                cycle_count,
                age_days,
                component_type
            ):FAILURE_LABEL::INT AS predicted_failure
        FROM ROCKET_LAB_INTELLIGENCE.ANALYTICS.V_COMPONENT_FAILURE_FEATURES
        WHERE (:COMPONENT_TYPE IS NULL OR :COMPONENT_TYPE = 'NULL' OR :COMPONENT_TYPE = '' OR UPPER(component_type) = UPPER(:COMPONENT_TYPE))
        LIMIT 100
    )
    SELECT
        COUNT(*),
        SUM(CASE WHEN predicted_failure = 0 THEN 1 ELSE 0 END),
        SUM(CASE WHEN predicted_failure = 1 THEN 1 ELSE 0 END),
        ROUND(AVG(cycle_count), 1)
    INTO total_count, healthy, likely_fail, avg_cycles
    FROM predictions;

    IF (total_count > 0) THEN
        fail_pct := ROUND(likely_fail / total_count * 100, 2);
    ELSE
        fail_pct := 0;
    END IF;

    result_json := OBJECT_CONSTRUCT(
        'prediction_source', 'COMPONENT_FAILURE_PREDICTOR ML Model',
        'component_type_filter', COALESCE(:COMPONENT_TYPE, 'ALL'),
        'components_analyzed', total_count,
        'predicted_healthy', healthy,
        'predicted_likely_fail', likely_fail,
        'failure_risk_pct', fail_pct,
        'avg_test_cycles', avg_cycles
    )::STRING;

    RETURN result_json;
END;
$$;

SELECT 'Model wrapper procedures created successfully' AS status;

