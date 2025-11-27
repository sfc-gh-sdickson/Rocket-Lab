-- ============================================================================
-- Rocket Lab Intelligence Agent - Table Definitions
-- ============================================================================
-- Purpose: Create all necessary tables for aerospace business model
-- All columns verified against Rocket Lab business requirements
-- Syntax: Verified against Snowflake SQL Reference
-- ============================================================================

USE DATABASE ROCKET_LAB_INTELLIGENCE;
USE SCHEMA RAW;
USE WAREHOUSE ROCKET_LAB_WH;

-- ============================================================================
-- DIVISIONS TABLE
-- ============================================================================
CREATE OR REPLACE TABLE DIVISIONS (
    division_id VARCHAR(20) PRIMARY KEY,
    division_name VARCHAR(200) NOT NULL,
    division_code VARCHAR(10) NOT NULL,
    location VARCHAR(100),
    head_count NUMBER(6,0) DEFAULT 0,
    annual_budget NUMBER(15,2) DEFAULT 0.00,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ============================================================================
-- EMPLOYEES TABLE
-- ============================================================================
CREATE OR REPLACE TABLE EMPLOYEES (
    employee_id VARCHAR(30) PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(200) NOT NULL,
    job_title VARCHAR(100),
    department VARCHAR(100),
    division_id VARCHAR(20),
    hire_date DATE,
    salary NUMBER(12,2),
    security_clearance VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (division_id) REFERENCES DIVISIONS(division_id)
);

-- ============================================================================
-- SUPPLIERS TABLE
-- ============================================================================
CREATE OR REPLACE TABLE SUPPLIERS (
    supplier_id VARCHAR(30) PRIMARY KEY,
    supplier_name VARCHAR(300) NOT NULL,
    supplier_type VARCHAR(50) NOT NULL, -- 'RAW_MATERIAL', 'ELECTRONICS', 'MACHINING'
    country VARCHAR(50) DEFAULT 'USA',
    quality_rating NUMBER(3,2), -- 1.00 to 5.00
    delivery_rating NUMBER(3,2),
    risk_score NUMBER(3,2), -- 0.00 (Low) to 1.00 (High)
    total_spend NUMBER(15,2) DEFAULT 0.00,
    status VARCHAR(30) DEFAULT 'ACTIVE',
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ============================================================================
-- VEHICLES TABLE (Rockets/Spacecraft)
-- ============================================================================
CREATE OR REPLACE TABLE VEHICLES (
    vehicle_id VARCHAR(30) PRIMARY KEY,
    vehicle_name VARCHAR(100) NOT NULL, -- e.g., "The Owl Spreads Its Wings"
    vehicle_type VARCHAR(50) NOT NULL, -- 'ELECTRON', 'NEUTRON', 'PHOTON'
    serial_number VARCHAR(50),
    manufacturing_date DATE,
    status VARCHAR(30) DEFAULT 'ASSEMBLY', -- 'ASSEMBLY', 'TESTING', 'READY', 'LAUNCHED', 'RETIRED'
    stage_count NUMBER(1,0),
    reuse_count NUMBER(3,0) DEFAULT 0,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ============================================================================
-- MISSIONS TABLE (Launches)
-- ============================================================================
CREATE OR REPLACE TABLE MISSIONS (
    mission_id VARCHAR(30) PRIMARY KEY,
    mission_name VARCHAR(200) NOT NULL,
    vehicle_id VARCHAR(30),
    customer_name VARCHAR(100),
    launch_site VARCHAR(50), -- 'MAHIA', 'WALLOPS'
    target_orbit VARCHAR(50), -- 'LEO', 'MEO', 'SSO'
    launch_date DATE,
    launch_window_start TIMESTAMP_NTZ,
    launch_window_end TIMESTAMP_NTZ,
    status VARCHAR(30) DEFAULT 'SCHEDULED', -- 'SCHEDULED', 'SUCCESS', 'SCRUBBED', 'FAILURE'
    contract_value NUMBER(15,2),
    payload_mass_kg NUMBER(10,2),
    weather_risk_score NUMBER(3,2), -- 0.00 to 1.00
    technical_risk_score NUMBER(3,2), -- 0.00 to 1.00
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (vehicle_id) REFERENCES VEHICLES(vehicle_id)
);

-- ============================================================================
-- COMPONENTS TABLE
-- ============================================================================
CREATE OR REPLACE TABLE COMPONENTS (
    component_id VARCHAR(30) PRIMARY KEY,
    component_name VARCHAR(200) NOT NULL, -- 'Rutherford Engine', 'Reaction Wheel'
    component_type VARCHAR(50),
    supplier_id VARCHAR(30),
    vehicle_id VARCHAR(30), -- Installed on vehicle
    batch_number VARCHAR(50),
    manufacturing_date DATE,
    status VARCHAR(30) DEFAULT 'IN_STOCK', -- 'IN_STOCK', 'INSTALLED', 'TESTING', 'FAILED'
    test_cycles NUMBER(5,0) DEFAULT 0,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (supplier_id) REFERENCES SUPPLIERS(supplier_id),
    FOREIGN KEY (vehicle_id) REFERENCES VEHICLES(vehicle_id)
);

-- ============================================================================
-- TEST_RESULTS TABLE
-- ============================================================================
CREATE OR REPLACE TABLE TEST_RESULTS (
    test_id VARCHAR(30) PRIMARY KEY,
    component_id VARCHAR(30),
    test_type VARCHAR(50) NOT NULL, -- 'VIBRATION', 'THERMAL', 'STATIC_FIRE'
    test_date TIMESTAMP_NTZ,
    result VARCHAR(20) NOT NULL, -- 'PASS', 'FAIL'
    measured_value NUMBER(10,4),
    limit_value NUMBER(10,4),
    inspector_id VARCHAR(30),
    notes VARCHAR(2000),
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (component_id) REFERENCES COMPONENTS(component_id),
    FOREIGN KEY (inspector_id) REFERENCES EMPLOYEES(employee_id)
);

-- ============================================================================
-- Display confirmation
-- ============================================================================
SELECT 'All tables created successfully' AS status;

