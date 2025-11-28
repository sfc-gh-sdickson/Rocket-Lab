-- ============================================================================
-- Rocket Lab Intelligence Agent - Semantic Views
-- ============================================================================
-- Purpose: Create semantic views for Snowflake Intelligence agents
-- All syntax VERIFIED against Kratos Defense template
-- ============================================================================
-- Dimensions/Metrics: <table_alias>.<semantic_name> AS <sql_expression>
-- Clause order is MANDATORY: TABLES → RELATIONSHIPS → DIMENSIONS → METRICS → COMMENT
-- ============================================================================

USE DATABASE ROCKET_LAB_INTELLIGENCE;
USE SCHEMA ANALYTICS;
USE WAREHOUSE ROCKET_LAB_WH;

-- ============================================================================
-- Semantic View 1: Mission Intelligence
-- ============================================================================
CREATE OR REPLACE SEMANTIC VIEW SV_MISSION_INTELLIGENCE
  TABLES (
    missions AS RAW.MISSIONS
      PRIMARY KEY (mission_id)
      WITH SYNONYMS ('launches', 'space missions', 'launch missions')
      COMMENT = 'Rocket Lab launch missions',
    vehicles AS RAW.VEHICLES
      PRIMARY KEY (vehicle_id)
      WITH SYNONYMS ('rockets', 'launch vehicles', 'electrons', 'neutrons')
      COMMENT = 'Rocket Lab launch vehicles',
    test_results AS RAW.TEST_RESULTS
      PRIMARY KEY (test_id)
      WITH SYNONYMS ('component tests', 'quality tests', 'testing data')
      COMMENT = 'Component testing results'
  )
  RELATIONSHIPS (
    missions(vehicle_id) REFERENCES vehicles(vehicle_id),
    test_results(vehicle_id) REFERENCES vehicles(vehicle_id)
  )
  DIMENSIONS (
    -- Mission dimensions
    missions.mission_id AS mission_id
      WITH SYNONYMS ('launch id', 'mission identifier')
      COMMENT = 'Unique mission identifier',
    missions.mission_name AS mission_name
      WITH SYNONYMS ('launch name', 'mission title')
      COMMENT = 'Name of the mission',
    missions.customer_name AS customer
      WITH SYNONYMS ('client', 'payload owner')
      COMMENT = 'Customer organization name',
    missions.launch_site AS launch_site
      WITH SYNONYMS ('launch pad', 'site location')
      COMMENT = 'Launch site location (e.g., Mahia, Wallops)',
    missions.target_orbit AS orbit
      WITH SYNONYMS ('trajectory', 'destination orbit')
      COMMENT = 'Target orbit (e.g., LEO, SSO, MEO)',
    missions.status AS status
      WITH SYNONYMS ('launch status', 'mission state')
      COMMENT = 'Mission status: SCHEDULED, COMPLETED, DELAYED, CANCELLED',
    missions.launch_date AS launch_date
      WITH SYNONYMS ('launch time', 'mission date')
      COMMENT = 'Date of launch',
    
    -- Vehicle dimensions
    vehicles.vehicle_id AS vehicle_id
      WITH SYNONYMS ('rocket id', 'vehicle identifier')
      COMMENT = 'Unique vehicle identifier',
    vehicles.vehicle_name AS vehicle_name
      WITH SYNONYMS ('rocket name', 'vehicle title')
      COMMENT = 'Name of the vehicle',
    vehicles.vehicle_type AS vehicle_type
      WITH SYNONYMS ('rocket type', 'vehicle class')
      COMMENT = 'Type: ELECTRON, NEUTRON, HASTE',
    vehicles.status AS vehicle_status
      WITH SYNONYMS ('rocket status', 'operational status')
      COMMENT = 'Vehicle status: MANUFACTURING, TESTING, READY, LAUNCHED, RETIRED',
    vehicles.serial_number AS serial_number
      WITH SYNONYMS ('tail number', 'rocket serial')
      COMMENT = 'Vehicle serial number',

    -- Test Result dimensions
    test_results.test_id AS test_id
      WITH SYNONYMS ('test identifier', 'result id')
      COMMENT = 'Unique test identifier',
    test_results.test_type AS test_type
      WITH SYNONYMS ('test category', 'testing type')
      COMMENT = 'Type of test performed',
    test_results.test_date AS test_date
      WITH SYNONYMS ('date tested', 'testing date')
      COMMENT = 'Date of test',
    test_results.status AS test_status
      WITH SYNONYMS ('test outcome', 'pass fail status')
      COMMENT = 'Status: PASSED, FAILED, PENDING'
  )
  METRICS (
    -- Mission metrics
    missions.total_missions AS COUNT(DISTINCT mission_id)
      WITH SYNONYMS ('mission count', 'launch count')
      COMMENT = 'Total number of missions',
    missions.contract_value AS SUM(contract_value)
      WITH SYNONYMS ('total revenue', 'mission revenue')
      COMMENT = 'Total value of mission contracts',
    missions.payload_mass AS SUM(payload_mass_kg)
      WITH SYNONYMS ('total payload', 'mass to orbit')
      COMMENT = 'Total payload mass in kg',
    missions.avg_weather_risk AS AVG(weather_risk_score)
      WITH SYNONYMS ('weather risk', 'average weather score')
      COMMENT = 'Average weather risk score (0-1)',
    missions.avg_technical_risk AS AVG(technical_risk_score)
      WITH SYNONYMS ('technical risk', 'tech risk score')
      COMMENT = 'Average technical risk score (0-1)',

    -- Vehicle metrics
    vehicles.total_vehicles AS COUNT(DISTINCT vehicle_id)
      WITH SYNONYMS ('vehicle count', 'fleet size')
      COMMENT = 'Total number of vehicles',
    vehicles.avg_reuse_count AS AVG(reuse_count)
      WITH SYNONYMS ('average reusability', 'mean reuse')
      COMMENT = 'Average number of times vehicles are reused',

    -- Test metrics
    test_results.total_tests AS COUNT(DISTINCT test_id)
      WITH SYNONYMS ('test count', 'number of tests')
      COMMENT = 'Total number of tests performed',
    test_results.passed_tests AS SUM(CASE WHEN status = 'PASSED' THEN 1 ELSE 0 END)
      WITH SYNONYMS ('successful tests', 'passed count')
      COMMENT = 'Number of tests passed',
    test_results.failed_tests AS SUM(CASE WHEN status = 'FAILED' THEN 1 ELSE 0 END)
      WITH SYNONYMS ('failed tests', 'failure count')
      COMMENT = 'Number of tests failed'
  )
  COMMENT = 'Mission Intelligence - comprehensive view of missions, vehicles, and testing';

-- ============================================================================
-- Semantic View 2: Supplier & Component Intelligence
-- ============================================================================
CREATE OR REPLACE SEMANTIC VIEW SV_SUPPLIER_COMPONENT_INTELLIGENCE
  TABLES (
    suppliers AS RAW.SUPPLIERS
      PRIMARY KEY (supplier_id)
      WITH SYNONYMS ('vendors', 'partners', 'supply chain')
      COMMENT = 'Supplier master data',
    components AS RAW.COMPONENTS
      PRIMARY KEY (component_id)
      WITH SYNONYMS ('parts', 'materials', 'assemblies')
      COMMENT = 'Component inventory'
  )
  RELATIONSHIPS (
    components(supplier_id) REFERENCES suppliers(supplier_id)
  )
  DIMENSIONS (
    -- Supplier dimensions
    suppliers.supplier_id AS supplier_id
      WITH SYNONYMS ('vendor id', 'partner id')
      COMMENT = 'Unique supplier identifier',
    suppliers.supplier_name AS supplier_name
      WITH SYNONYMS ('vendor name', 'company name')
      COMMENT = 'Name of supplier',
    suppliers.supplier_type AS supplier_type
      WITH SYNONYMS ('vendor type', 'category')
      COMMENT = 'Type: RAW_MATERIAL, ELECTRONICS, MACHINING, SERVICES',
    suppliers.country AS country
      WITH SYNONYMS ('location', 'origin')
      COMMENT = 'Supplier country',
    suppliers.status AS supplier_status
      WITH SYNONYMS ('vendor status', 'active status')
      COMMENT = 'Status: ACTIVE, INACTIVE, PROBATION',

    -- Component dimensions
    components.component_id AS component_id
      WITH SYNONYMS ('part id', 'part number')
      COMMENT = 'Unique component identifier',
    components.component_name AS component_name
      WITH SYNONYMS ('part name', 'description')
      COMMENT = 'Name/description of component',
    components.component_type AS component_type
      WITH SYNONYMS ('part type', 'category')
      COMMENT = 'Type: AVIONICS, PROPULSION, STRUCTURE, BATTERY',
    components.status AS component_status
      WITH SYNONYMS ('part status', 'inventory status')
      COMMENT = 'Status: IN_STOCK, ON_ORDER, ASSIGNED, SCRAPPED'
  )
  METRICS (
    -- Supplier metrics
    suppliers.total_suppliers AS COUNT(DISTINCT supplier_id)
      WITH SYNONYMS ('vendor count', 'supplier count')
      COMMENT = 'Total number of suppliers',
    suppliers.avg_quality_rating AS AVG(quality_rating)
      WITH SYNONYMS ('average quality', 'vendor quality')
      COMMENT = 'Average quality rating (0-10)',
    suppliers.avg_delivery_rating AS AVG(delivery_rating)
      WITH SYNONYMS ('on time delivery', 'delivery score')
      COMMENT = 'Average delivery rating (0-10)',
    suppliers.total_spend AS SUM(total_spend)
      WITH SYNONYMS ('procurement spend', 'total cost')
      COMMENT = 'Total spend with suppliers',
    suppliers.avg_risk_score AS AVG(risk_score)
      WITH SYNONYMS ('supplier risk', 'average risk')
      COMMENT = 'Average supplier risk score (0-1)',

    -- Component metrics
    components.total_components AS COUNT(DISTINCT component_id)
      WITH SYNONYMS ('part count', 'inventory count')
      COMMENT = 'Total number of components',
    components.avg_component_cost AS AVG(cost)
      WITH SYNONYMS ('average part cost', 'unit cost')
      COMMENT = 'Average cost per component'
  )
  COMMENT = 'Supplier & Component Intelligence - comprehensive view of supply chain';

SELECT 'All semantic views created successfully' AS status;

