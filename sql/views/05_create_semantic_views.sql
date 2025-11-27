-- ============================================================================
-- Rocket Lab Intelligence Agent - Semantic Views
-- ============================================================================
-- Purpose: Create semantic views for Cortex Analyst
-- Syntax: table.semantic_name AS actual_column
-- Verified against Snowflake Documentation
-- ============================================================================

USE DATABASE ROCKET_LAB_INTELLIGENCE;
USE SCHEMA ANALYTICS;
USE WAREHOUSE ROCKET_LAB_WH;

-- ============================================================================
-- Semantic View: Missions
-- ============================================================================
CREATE OR REPLACE SEMANTIC VIEW SEMANTIC_MISSIONS 
(
    -- TIME DIMENSIONS
    ON m.launch_date AS launch_date,
    
    -- DIMENSIONS
    -- Syntax: alias.semantic_name AS actual_column
    m.mission_name AS mission_name,
    m.mission_id AS mission_id,
    m.customer_name AS customer_name,
    m.launch_site AS launch_site,
    m.target_orbit AS target_orbit,
    m.status AS status,
    v.vehicle_name AS vehicle_name,
    v.vehicle_type AS vehicle_type,
    
    -- MEASURES
    m.contract_value AS contract_value,
    m.payload_mass_kg AS payload_mass_kg,
    m.weather_risk_score AS weather_risk_score,
    m.technical_risk_score AS technical_risk_score
)
AS 
SELECT
    m.launch_date,
    m.mission_name,
    m.mission_id,
    m.customer_name,
    m.launch_site,
    m.target_orbit,
    m.status,
    v.vehicle_name,
    v.vehicle_type,
    m.contract_value,
    m.payload_mass_kg,
    m.weather_risk_score,
    m.technical_risk_score
FROM RAW.MISSIONS m
LEFT JOIN RAW.VEHICLES v ON m.vehicle_id = v.vehicle_id;

-- ============================================================================
-- Semantic View: Suppliers
-- ============================================================================
CREATE OR REPLACE SEMANTIC VIEW SEMANTIC_SUPPLIERS
(
    -- DIMENSIONS
    s.supplier_name AS supplier_name,
    s.supplier_type AS supplier_type,
    s.country AS country,
    s.status AS status,
    
    -- MEASURES
    s.quality_rating AS quality_rating,
    s.delivery_rating AS delivery_rating,
    s.risk_score AS risk_score,
    s.total_spend AS total_spend
)
AS
SELECT
    s.supplier_name,
    s.supplier_type,
    s.country,
    s.status,
    s.quality_rating,
    s.delivery_rating,
    s.risk_score,
    s.total_spend
FROM RAW.SUPPLIERS s;

-- ============================================================================
-- Semantic View: Vehicles
-- ============================================================================
CREATE OR REPLACE SEMANTIC VIEW SEMANTIC_VEHICLES
(
    -- TIME DIMENSIONS
    ON v.manufacturing_date AS manufacturing_date,
    
    -- DIMENSIONS
    v.vehicle_name AS vehicle_name,
    v.vehicle_type AS vehicle_type,
    v.serial_number AS serial_number,
    v.status AS status,
    
    -- MEASURES
    v.stage_count AS stage_count,
    v.reuse_count AS reuse_count
)
AS
SELECT
    v.manufacturing_date,
    v.vehicle_name,
    v.vehicle_type,
    v.serial_number,
    v.status,
    v.stage_count,
    v.reuse_count
FROM RAW.VEHICLES v;

SELECT 'Semantic views created successfully' AS status;

