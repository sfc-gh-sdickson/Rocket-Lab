-- ============================================================================
-- Rocket Lab Intelligence Agent - Synthetic Data Generation
-- ============================================================================
-- Purpose: Generate realistic sample data for Rocket Lab operations
-- Volume: ~1K employees, 200 missions, 50 vehicles, 5K components, 20K tests
-- Syntax: Verified against Snowflake SQL Reference & Lessons Learned
--
-- CRITICAL RULES ADHERED TO:
-- 1. UNIFORM(min, max, RANDOM()) - min/max are CONSTANT literals
-- 2. SEQ4() - Used only with GENERATOR or replaced with ROW_NUMBER()
-- 3. Varied status distributions (not just uniform random)
-- ============================================================================

USE DATABASE ROCKET_LAB_INTELLIGENCE;
USE SCHEMA RAW;
USE WAREHOUSE ROCKET_LAB_WH;

-- ============================================================================
-- Step 1: Generate Divisions (Static Data)
-- ============================================================================
INSERT INTO DIVISIONS (division_id, division_name, division_code, location, head_count, annual_budget)
VALUES
('DIV001', 'Launch Services', 'LCH', 'Mahia, NZ', 400, 150000000.00),
('DIV002', 'Space Systems', 'SPC', 'Long Beach, CA', 600, 250000000.00),
('DIV003', 'Propulsion', 'PRP', 'Long Beach, CA', 300, 100000000.00),
('DIV004', 'Avionics & Software', 'AVS', 'Auckland, NZ', 250, 80000000.00),
('DIV005', 'Manufacturing', 'MFG', 'Wallops, VA', 350, 120000000.00);

-- ============================================================================
-- Step 2: Generate Employees
-- ============================================================================
INSERT INTO EMPLOYEES
SELECT
    'EMP' || LPAD(SEQ4(), 5, '0') AS employee_id,
    ARRAY_CONSTRUCT('Peter', 'Beck', 'Adam', 'Sarah', 'Jessica', 'Michael', 'David', 'Emily', 'Chris', 'Tom')[UNIFORM(0, 9, RANDOM())] AS first_name,
    ARRAY_CONSTRUCT('Smith', 'Jones', 'Williams', 'Brown', 'Taylor', 'Davies', 'Evans', 'Wilson', 'Thomas', 'Roberts')[UNIFORM(0, 9, RANDOM())] AS last_name,
    'employee' || SEQ4() || '@rocketlabusa.com' AS email,
    ARRAY_CONSTRUCT('Engineer', 'Technician', 'Manager', 'Analyst', 'Specialist')[UNIFORM(0, 4, RANDOM())] AS job_title,
    ARRAY_CONSTRUCT('Engineering', 'Operations', 'Quality', 'Finance', 'HR')[UNIFORM(0, 4, RANDOM())] AS department,
    'DIV00' || UNIFORM(1, 5, RANDOM()) AS division_id,
    DATEADD('day', -1 * UNIFORM(1, 3650, RANDOM()), CURRENT_DATE()) AS hire_date,
    (UNIFORM(60000, 200000, RANDOM()) * 1.0)::NUMBER(12,2) AS salary,
    CASE WHEN UNIFORM(0, 100, RANDOM()) < 20 THEN 'SECRET' ELSE 'NONE' END AS security_clearance,
    TRUE AS is_active,
    CURRENT_TIMESTAMP(),
    CURRENT_TIMESTAMP()
FROM TABLE(GENERATOR(ROWCOUNT => 1000));

-- ============================================================================
-- Step 3: Generate Suppliers
-- ============================================================================
INSERT INTO SUPPLIERS
SELECT
    'SUP' || LPAD(SEQ4(), 4, '0') AS supplier_id,
    'Supplier-' || SEQ4() AS supplier_name,
    ARRAY_CONSTRUCT('RAW_MATERIAL', 'ELECTRONICS', 'MACHINING', 'SERVICES', 'PROPULSION')[UNIFORM(0, 4, RANDOM())] AS supplier_type,
    ARRAY_CONSTRUCT('USA', 'New Zealand', 'Australia', 'UK', 'Canada')[UNIFORM(0, 4, RANDOM())] AS country,
    (UNIFORM(300, 500, RANDOM()) / 100.0)::NUMBER(3,2) AS quality_rating, -- 3.00 to 5.00
    (UNIFORM(300, 500, RANDOM()) / 100.0)::NUMBER(3,2) AS delivery_rating,
    (UNIFORM(0, 100, RANDOM()) / 100.0)::NUMBER(3,2) AS risk_score, -- 0.00 to 1.00
    (UNIFORM(10000, 1000000, RANDOM()) * 1.0)::NUMBER(15,2) AS total_spend,
    CASE 
        WHEN UNIFORM(0, 100, RANDOM()) < 90 THEN 'ACTIVE'
        ELSE 'INACTIVE'
    END AS status,
    CURRENT_TIMESTAMP(),
    CURRENT_TIMESTAMP()
FROM TABLE(GENERATOR(ROWCOUNT => 200));

-- ============================================================================
-- Step 4: Generate Vehicles (Rockets)
-- ============================================================================
INSERT INTO VEHICLES
SELECT
    'VEH' || LPAD(SEQ4(), 3, '0') AS vehicle_id,
    CASE 
        WHEN UNIFORM(0, 1, RANDOM()) = 0 THEN 'The Owl Spreads Its Wings'
        ELSE 'It is a Business Time'
    END || ' ' || SEQ4() AS vehicle_name,
    CASE 
        WHEN UNIFORM(0, 100, RANDOM()) < 80 THEN 'ELECTRON'
        ELSE 'NEUTRON' 
    END AS vehicle_type,
    'SN-' || LPAD(SEQ4(), 3, '0') AS serial_number,
    DATEADD('day', -1 * UNIFORM(100, 2000, RANDOM()), CURRENT_DATE()) AS manufacturing_date,
    -- Varied Status
    CASE 
        WHEN UNIFORM(0, 100, RANDOM()) < 50 THEN 'LAUNCHED'
        WHEN UNIFORM(0, 100, RANDOM()) < 70 THEN 'READY'
        WHEN UNIFORM(0, 100, RANDOM()) < 90 THEN 'TESTING'
        ELSE 'ASSEMBLY'
    END AS status,
    CASE WHEN vehicle_type = 'ELECTRON' THEN 2 ELSE 2 END AS stage_count, -- Logic handled in CASE above? No, simplifying.
    UNIFORM(0, 5, RANDOM()) AS reuse_count,
    CURRENT_TIMESTAMP(),
    CURRENT_TIMESTAMP()
FROM TABLE(GENERATOR(ROWCOUNT => 50));

-- ============================================================================
-- Step 5: Generate Missions
-- ============================================================================
INSERT INTO MISSIONS
SELECT
    'MSN' || LPAD(SEQ4(), 4, '0') AS mission_id,
    'Mission ' || SEQ4() AS mission_name,
    'VEH' || LPAD(UNIFORM(1, 50, RANDOM()), 3, '0') AS vehicle_id,
    ARRAY_CONSTRUCT('NASA', 'NRO', 'Space Force', 'BlackSky', 'Planet', 'Capella Space')[UNIFORM(0, 5, RANDOM())] AS customer_name,
    ARRAY_CONSTRUCT('MAHIA', 'WALLOPS')[UNIFORM(0, 1, RANDOM())] AS launch_site,
    ARRAY_CONSTRUCT('LEO', 'SSO', 'MEO')[UNIFORM(0, 2, RANDOM())] AS target_orbit,
    DATEADD('day', UNIFORM(-365, 365, RANDOM()), CURRENT_DATE()) AS launch_date,
    NULL AS launch_window_start, -- Simplifying
    NULL AS launch_window_end,
    -- Varied Status
    CASE 
        WHEN launch_date < CURRENT_DATE() THEN 
            CASE WHEN UNIFORM(0, 100, RANDOM()) < 90 THEN 'SUCCESS' ELSE 'FAILURE' END
        ELSE 'SCHEDULED'
    END AS status,
    (UNIFORM(5000000, 15000000, RANDOM()) * 1.0)::NUMBER(15,2) AS contract_value,
    (UNIFORM(150, 300, RANDOM()) * 1.0)::NUMBER(10,2) AS payload_mass_kg,
    (UNIFORM(0, 100, RANDOM()) / 100.0)::NUMBER(3,2) AS weather_risk_score,
    (UNIFORM(0, 100, RANDOM()) / 100.0)::NUMBER(3,2) AS technical_risk_score,
    CURRENT_TIMESTAMP(),
    CURRENT_TIMESTAMP()
FROM TABLE(GENERATOR(ROWCOUNT => 200));

-- ============================================================================
-- Step 6: Generate Components
-- ============================================================================
INSERT INTO COMPONENTS
SELECT
    'CMP' || LPAD(SEQ4(), 6, '0') AS component_id,
    ARRAY_CONSTRUCT('Rutherford Engine', 'Curie Engine', 'Flight Computer', 'Battery Pack', 'Reaction Wheel', 'Fairing', 'Interstage')[UNIFORM(0, 6, RANDOM())] AS component_name,
    ARRAY_CONSTRUCT('PROPULSION', 'PROPULSION', 'AVIONICS', 'BATTERY', 'AVIONICS', 'STRUCTURE', 'STRUCTURE')[UNIFORM(0, 6, RANDOM())] AS component_type,
    'SUP' || LPAD(UNIFORM(1, 200, RANDOM()), 4, '0') AS supplier_id,
    'VEH' || LPAD(UNIFORM(1, 50, RANDOM()), 3, '0') AS vehicle_id,
    'BATCH-' || UNIFORM(100, 999, RANDOM()) AS batch_number,
    DATEADD('day', -1 * UNIFORM(100, 1000, RANDOM()), CURRENT_DATE()) AS manufacturing_date,
    -- Status
    CASE 
        WHEN UNIFORM(0, 100, RANDOM()) < 60 THEN 'INSTALLED'
        WHEN UNIFORM(0, 100, RANDOM()) < 80 THEN 'IN_STOCK'
        WHEN UNIFORM(0, 100, RANDOM()) < 95 THEN 'TESTING'
        ELSE 'FAILED'
    END AS status,
    UNIFORM(0, 50, RANDOM()) AS test_cycles,
    CURRENT_TIMESTAMP(),
    CURRENT_TIMESTAMP()
FROM TABLE(GENERATOR(ROWCOUNT => 5000));

-- ============================================================================
-- Step 7: Generate Test Results
-- ============================================================================
INSERT INTO TEST_RESULTS
SELECT
    'TST' || LPAD(SEQ4(), 6, '0') AS test_id,
    'CMP' || LPAD(UNIFORM(1, 5000, RANDOM()), 6, '0') AS component_id,
    ARRAY_CONSTRUCT('VIBRATION', 'THERMAL', 'STATIC_FIRE', 'VACUUM', 'PRESSURE')[UNIFORM(0, 4, RANDOM())] AS test_type,
    DATEADD('day', -1 * UNIFORM(1, 365, RANDOM()), CURRENT_DATE()) AS test_date,
    -- Result skewed towards PASS
    CASE WHEN UNIFORM(0, 100, RANDOM()) < 90 THEN 'PASS' ELSE 'FAIL' END AS result,
    (UNIFORM(0, 10000, RANDOM()) / 100.0)::NUMBER(10,4) AS measured_value,
    100.0000 AS limit_value,
    'EMP' || LPAD(UNIFORM(1, 1000, RANDOM()), 5, '0') AS inspector_id,
    CASE 
        WHEN result = 'FAIL' THEN 'Test failed due to anomaly in sensor readings. Vibration exceeded limits.'
        ELSE 'Test passed. All parameters within nominal range.'
    END AS notes,
    CURRENT_TIMESTAMP()
FROM TABLE(GENERATOR(ROWCOUNT => 20000));

-- ============================================================================
-- Display data generation completion summary
-- ============================================================================
SELECT 'Data generation completed successfully' AS status,
       (SELECT COUNT(*) FROM DIVISIONS) AS divisions,
       (SELECT COUNT(*) FROM EMPLOYEES) AS employees,
       (SELECT COUNT(*) FROM SUPPLIERS) AS suppliers,
       (SELECT COUNT(*) FROM VEHICLES) AS vehicles,
       (SELECT COUNT(*) FROM MISSIONS) AS missions,
       (SELECT COUNT(*) FROM COMPONENTS) AS components,
       (SELECT COUNT(*) FROM TEST_RESULTS) AS test_results;

