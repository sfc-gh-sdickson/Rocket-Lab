-- ============================================================================
-- Rocket Lab Intelligence Agent - Synthetic Data Generation
-- ============================================================================
-- Purpose: Generate realistic data for Rocket Lab operations
-- Rules Followed:
-- 1. UNIFORM() arguments are constants ONLY.
-- 2. SEQ4() used only within GENERATOR context or ROW_NUMBER() used.
-- 3. Numeric precision verified.
-- 4. NULL handling for NOT NULL columns.
-- ============================================================================

USE DATABASE ROCKET_LAB_INTELLIGENCE;
USE SCHEMA RAW;
USE WAREHOUSE ROCKET_LAB_WH;

-- ============================================================================
-- 1. DIVISIONS
-- ============================================================================
TRUNCATE TABLE DIVISIONS;

INSERT INTO DIVISIONS (division_id, division_name, division_code, location, head_count, annual_budget)
VALUES 
('DIV-001', 'Launch Services', 'LCH', 'Auckland, NZ', 500, 150000000.00),
('DIV-002', 'Space Systems', 'SYS', 'Long Beach, CA', 300, 100000000.00),
('DIV-003', 'Mission Operations', 'OPS', 'Wallops Island, VA', 100, 50000000.00),
('DIV-004', 'Manufacturing', 'MFG', 'Auckland, NZ', 400, 80000000.00);

-- ============================================================================
-- 2. EMPLOYEES
-- ============================================================================
TRUNCATE TABLE EMPLOYEES;

INSERT INTO EMPLOYEES (employee_id, first_name, last_name, email, job_title, department, division_id, hire_date, salary, security_clearance, is_active)
SELECT
    'EMP-' || LPAD(seq4(), 5, '0') as employee_id,
    CASE MOD(ABS(RANDOM()), 10)
        WHEN 0 THEN 'Peter' WHEN 1 THEN 'Sarah' WHEN 2 THEN 'James' WHEN 3 THEN 'Emma' WHEN 4 THEN 'Michael'
        WHEN 5 THEN 'Jessica' WHEN 6 THEN 'David' WHEN 7 THEN 'Emily' WHEN 8 THEN 'Robert' ELSE 'Jennifer'
    END as first_name,
    CASE MOD(ABS(RANDOM()), 10)
        WHEN 0 THEN 'Beck' WHEN 1 THEN 'Smith' WHEN 2 THEN 'Johnson' WHEN 3 THEN 'Williams' WHEN 4 THEN 'Brown'
        WHEN 5 THEN 'Jones' WHEN 6 THEN 'Miller' WHEN 7 THEN 'Davis' WHEN 8 THEN 'Garcia' ELSE 'Rodriguez'
    END as last_name,
    'employee' || seq4() || '@rocketlabusa.com' as email,
    CASE MOD(ABS(RANDOM()), 5)
        WHEN 0 THEN 'Propulsion Engineer'
        WHEN 1 THEN 'GNC Engineer'
        WHEN 2 THEN 'Manufacturing Technician'
        WHEN 3 THEN 'Mission Manager'
        ELSE 'Software Engineer'
    END as job_title,
    CASE MOD(ABS(RANDOM()), 4)
        WHEN 0 THEN 'Propulsion' WHEN 1 THEN 'Avionics' WHEN 2 THEN 'Structures' ELSE 'Operations'
    END as department,
    CASE MOD(ABS(RANDOM()), 4)
        WHEN 0 THEN 'DIV-001' WHEN 1 THEN 'DIV-002' WHEN 2 THEN 'DIV-003' ELSE 'DIV-004'
    END as division_id,
    DATEADD(day, -UNIFORM(1, 1000, RANDOM()), CURRENT_DATE()) as hire_date,
    UNIFORM(70000, 150000, RANDOM()) as salary,
    CASE MOD(ABS(RANDOM()), 3)
        WHEN 0 THEN 'None' WHEN 1 THEN 'Secret' ELSE 'Top Secret'
    END as security_clearance,
    TRUE as is_active
FROM TABLE(GENERATOR(ROWCOUNT => 100));

-- ============================================================================
-- 3. SUPPLIERS
-- ============================================================================
TRUNCATE TABLE SUPPLIERS;

INSERT INTO SUPPLIERS (supplier_id, supplier_name, supplier_type, country, quality_rating, delivery_rating, risk_score, total_spend, status)
SELECT
    'SUP-' || LPAD(seq4(), 4, '0') as supplier_id,
    'Supplier ' || seq4() as supplier_name,
    CASE MOD(ABS(RANDOM()), 3)
        WHEN 0 THEN 'RAW_MATERIAL'
        WHEN 1 THEN 'ELECTRONICS'
        ELSE 'MACHINING'
    END as supplier_type,
    CASE MOD(ABS(RANDOM()), 3)
        WHEN 0 THEN 'USA' WHEN 1 THEN 'New Zealand' ELSE 'Germany'
    END as country,
    (UNIFORM(300, 500, RANDOM()) / 100.0)::NUMBER(3,2) as quality_rating, -- 3.00 to 5.00
    (UNIFORM(300, 500, RANDOM()) / 100.0)::NUMBER(3,2) as delivery_rating,
    (UNIFORM(0, 100, RANDOM()) / 100.0)::NUMBER(3,2) as risk_score, -- 0.00 to 1.00
    UNIFORM(10000, 1000000, RANDOM()) as total_spend,
    CASE 
        WHEN UNIFORM(1, 100, RANDOM()) <= 80 THEN 'ACTIVE' 
        WHEN UNIFORM(1, 100, RANDOM()) <= 90 THEN 'PROBATION'
        ELSE 'INACTIVE' 
    END as status
FROM TABLE(GENERATOR(ROWCOUNT => 20));

-- ============================================================================
-- 4. VEHICLES
-- ============================================================================
TRUNCATE TABLE VEHICLES;

INSERT INTO VEHICLES (vehicle_id, vehicle_name, vehicle_type, serial_number, manufacturing_date, status, stage_count, reuse_count)
SELECT
    'VEH-' || LPAD(seq4(), 4, '0') as vehicle_id,
    CASE MOD(ABS(RANDOM()), 5)
        WHEN 0 THEN 'It is Business Time'
        WHEN 1 THEN 'The Owl Spreads Its Wings'
        WHEN 2 THEN 'That is a Funny Cactus'
        WHEN 3 THEN 'Return to Sender'
        ELSE 'Love At First Insight'
    END || ' ' || seq4() as vehicle_name,
    CASE MOD(ABS(RANDOM()), 10)
        WHEN 0 THEN 'NEUTRON' -- 10% Neutron
        WHEN 1 THEN 'PHOTON'  -- 10% Photon
        ELSE 'ELECTRON'       -- 80% Electron
    END as vehicle_type,
    'SN-' || LPAD(seq4(), 3, '0') as serial_number,
    DATEADD(day, -UNIFORM(1, 700, RANDOM()), CURRENT_DATE()) as manufacturing_date,
    CASE MOD(ABS(RANDOM()), 5)
        WHEN 0 THEN 'ASSEMBLY'
        WHEN 1 THEN 'TESTING'
        WHEN 2 THEN 'READY'
        WHEN 3 THEN 'LAUNCHED'
        ELSE 'RETIRED'
    END as status,
    CASE 
        WHEN MOD(ABS(RANDOM()), 10) = 0 THEN 2 -- Neutron has 2 stages usually + fairing
        ELSE 3 -- Electron (1, 2, Kick)
    END as stage_count,
    CASE 
        WHEN MOD(ABS(RANDOM()), 10) = 0 THEN UNIFORM(0, 5, RANDOM()) -- Neutron reuse
        ELSE 0 -- Electron not reused usually (yet)
    END as reuse_count
FROM TABLE(GENERATOR(ROWCOUNT => 30));

-- ============================================================================
-- 5. MISSIONS
-- ============================================================================
TRUNCATE TABLE MISSIONS;

INSERT INTO MISSIONS (mission_id, mission_name, vehicle_id, customer_name, launch_site, target_orbit, launch_date, launch_window_start, launch_window_end, status, contract_value, payload_mass_kg, weather_risk_score, technical_risk_score)
SELECT
    'MSN-' || LPAD(seq4(), 4, '0') as mission_id,
    'Mission ' || seq4() as mission_name,
    'VEH-' || LPAD(UNIFORM(1, 30, RANDOM()), 4, '0') as vehicle_id,
    CASE MOD(ABS(RANDOM()), 5)
        WHEN 0 THEN 'NASA'
        WHEN 1 THEN 'NRO'
        WHEN 2 THEN 'Space Force'
        WHEN 3 THEN 'BlackSky'
        ELSE 'Planet'
    END as customer_name,
    CASE MOD(ABS(RANDOM()), 2)
        WHEN 0 THEN 'MAHIA' ELSE 'WALLOPS'
    END as launch_site,
    CASE MOD(ABS(RANDOM()), 3)
        WHEN 0 THEN 'LEO' WHEN 1 THEN 'SSO' ELSE 'MEO'
    END as target_orbit,
    DATEADD(day, UNIFORM(-365, 365, RANDOM()), CURRENT_DATE()) as launch_date,
    NULL as launch_window_start, -- Simplified for now
    NULL as launch_window_end,
    CASE 
        WHEN UNIFORM(1, 100, RANDOM()) <= 40 THEN 'SUCCESS'
        WHEN UNIFORM(1, 100, RANDOM()) <= 80 THEN 'SCHEDULED'
        WHEN UNIFORM(1, 100, RANDOM()) <= 95 THEN 'SCRUBBED'
        ELSE 'FAILURE'
    END as status,
    UNIFORM(6000000, 15000000, RANDOM()) as contract_value,
    UNIFORM(100, 300, RANDOM()) as payload_mass_kg,
    (UNIFORM(0, 100, RANDOM()) / 100.0)::NUMBER(3,2) as weather_risk_score,
    (UNIFORM(0, 100, RANDOM()) / 100.0)::NUMBER(3,2) as technical_risk_score
FROM TABLE(GENERATOR(ROWCOUNT => 50));

-- ============================================================================
-- 6. COMPONENTS
-- ============================================================================
TRUNCATE TABLE COMPONENTS;

INSERT INTO COMPONENTS (component_id, component_name, component_type, supplier_id, vehicle_id, batch_number, manufacturing_date, status, test_cycles)
SELECT
    'CMP-' || LPAD(seq4(), 6, '0') as component_id,
    CASE MOD(ABS(RANDOM()), 5)
        WHEN 0 THEN 'Rutherford Engine'
        WHEN 1 THEN 'Reaction Wheel'
        WHEN 2 THEN 'Flight Computer'
        WHEN 3 THEN 'Battery Pack'
        ELSE 'Fairing'
    END as component_name,
    CASE MOD(ABS(RANDOM()), 5)
        WHEN 0 THEN 'PROPULSION'
        WHEN 1 THEN 'GNC'
        WHEN 2 THEN 'AVIONICS'
        WHEN 3 THEN 'POWER'
        ELSE 'STRUCTURE'
    END as component_type,
    'SUP-' || LPAD(UNIFORM(1, 20, RANDOM()), 4, '0') as supplier_id,
    'VEH-' || LPAD(UNIFORM(1, 30, RANDOM()), 4, '0') as vehicle_id,
    'BATCH-' || UNIFORM(100, 999, RANDOM()) as batch_number,
    DATEADD(day, -UNIFORM(1, 365, RANDOM()), CURRENT_DATE()) as manufacturing_date,
    CASE 
        WHEN UNIFORM(1, 100, RANDOM()) <= 80 THEN 'INSTALLED'
        WHEN UNIFORM(1, 100, RANDOM()) <= 90 THEN 'IN_STOCK'
        WHEN UNIFORM(1, 100, RANDOM()) <= 98 THEN 'TESTING'
        ELSE 'FAILED'
    END as status,
    UNIFORM(0, 50, RANDOM()) as test_cycles
FROM TABLE(GENERATOR(ROWCOUNT => 500));

-- ============================================================================
-- 7. TEST_RESULTS
-- ============================================================================
TRUNCATE TABLE TEST_RESULTS;

INSERT INTO TEST_RESULTS (test_id, component_id, test_type, test_date, result, measured_value, limit_value, inspector_id, notes)
SELECT
    'TST-' || LPAD(seq4(), 6, '0') as test_id,
    'CMP-' || LPAD(UNIFORM(1, 500, RANDOM()), 6, '0') as component_id,
    CASE MOD(ABS(RANDOM()), 3)
        WHEN 0 THEN 'VIBRATION'
        WHEN 1 THEN 'THERMAL'
        ELSE 'STATIC_FIRE'
    END as test_type,
    DATEADD(hour, -UNIFORM(1, 5000, RANDOM()), CURRENT_TIMESTAMP()) as test_date,
    CASE 
        WHEN UNIFORM(1, 100, RANDOM()) <= 95 THEN 'PASS'
        ELSE 'FAIL'
    END as result,
    (UNIFORM(9000, 11000, RANDOM()) / 100.0) as measured_value, -- Random metric
    100.00 as limit_value,
    'EMP-' || LPAD(UNIFORM(1, 100, RANDOM()), 5, '0') as inspector_id,
    'Routine inspection ' || seq4() as notes
FROM TABLE(GENERATOR(ROWCOUNT => 1000));

SELECT 'Synthetic data generated successfully' AS status;

