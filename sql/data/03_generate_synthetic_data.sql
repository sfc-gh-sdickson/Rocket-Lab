/*=============================================================================
  Rocket Lab Intelligence Agent
  Step 3: Synthetic Data Generation

  Execution Order: 3 of 9
  Description: Generates correlated synthetic data for launch operations and
               Customer 360. Each of the 100 customers is assigned a hidden
               profile (HEALTHY / EXPANDING / AT_RISK / CHURNED) that drives
               contracts, tickets, NPS, usage, sentiment and anomalies, so the
               ML models have real signal to learn. Component condition is
               driven by a hidden wear index so predictive maintenance and RUL
               models train on genuine relationships.
               Safe to re-run: every table is truncated first.
               Run the whole file in ONE session (uses temporary tables).
=============================================================================*/

USE DATABASE ROCKET_LAB_INTELLIGENCE;
USE SCHEMA RAW;
USE WAREHOUSE ROCKET_LAB_WH;

TRUNCATE TABLE IF EXISTS DIVISIONS;
TRUNCATE TABLE IF EXISTS EMPLOYEES;
TRUNCATE TABLE IF EXISTS SUPPLIERS;
TRUNCATE TABLE IF EXISTS LAUNCH_SITES;
TRUNCATE TABLE IF EXISTS CUSTOMERS;
TRUNCATE TABLE IF EXISTS VEHICLES;
TRUNCATE TABLE IF EXISTS MISSIONS;
TRUNCATE TABLE IF EXISTS COMPONENTS;
TRUNCATE TABLE IF EXISTS TEST_RESULTS;
TRUNCATE TABLE IF EXISTS ENGINE_TELEMETRY;
TRUNCATE TABLE IF EXISTS MAINTENANCE_RECORDS;
TRUNCATE TABLE IF EXISTS ANOMALIES;
TRUNCATE TABLE IF EXISTS MISSION_DOCUMENTS;
TRUNCATE TABLE IF EXISTS TEST_FAILURE_REPORTS;
TRUNCATE TABLE IF EXISTS KNOWLEDGE_BASE;
TRUNCATE TABLE IF EXISTS CONTACTS;
TRUNCATE TABLE IF EXISTS CUSTOMER_SPACECRAFT;
TRUNCATE TABLE IF EXISTS CONTRACTS;
TRUNCATE TABLE IF EXISTS INVOICES;
TRUNCATE TABLE IF EXISTS SUPPORT_TICKETS;
TRUNCATE TABLE IF EXISTS SURVEYS;
TRUNCATE TABLE IF EXISTS MISSION_OPS_USAGE_DAILY;
TRUNCATE TABLE IF EXISTS OPPORTUNITIES;
TRUNCATE TABLE IF EXISTS INTERACTIONS;

-- ============================================================================
-- DIVISIONS (6)
-- ============================================================================
INSERT INTO DIVISIONS
SELECT column1, column2, column3, column4, column5, column6
FROM VALUES
 ('DIV-01','Launch Services','LS','Long Beach, California',420,185000000),
 ('DIV-02','Space Systems','SS','Long Beach, California',680,410000000),
 ('DIV-03','Propulsion','PR','Long Beach, California',310,240000000),
 ('DIV-04','Avionics and Software','AV','Long Beach, California',260,95000000),
 ('DIV-05','Manufacturing','MF','Auckland, New Zealand',390,160000000),
 ('DIV-06','National Security','NS','Wallops Island, Virginia',180,120000000);

-- ============================================================================
-- EMPLOYEES (1,000)
-- ============================================================================
INSERT INTO EMPLOYEES
SELECT
    'EMP-' || LPAD(g.I::VARCHAR, 5, '0'),
    GET(ARRAY_CONSTRUCT('James','Maria','Liam','Aisha','Hiro','Sofia','Noah','Priya','Lucas','Emma',
        'Kenji','Hannah','Diego','Mei','Owen','Fatima','Samuel','Ingrid','Daniel','Chloe'), MOD(g.I, 20))::VARCHAR
        || ' ' ||
    GET(ARRAY_CONSTRUCT('Anderson','Nakamura','Schmidt','Garcia','Okonkwo','Kowalski','Silva','Dubois','Singh','Johansson',
        'Murphy','Tanaka','Rossi','Kim','Hughes','Martin','Novak','Costa','Reyes','Fischer'), MOD(g.I * 3, 20))::VARCHAR,
    'emp' || LPAD(g.I::VARCHAR, 5, '0') || '@rocketlabusa.com',
    GET(ARRAY_CONSTRUCT('Propulsion Test Engineer','Structures Engineer','Avionics Engineer','Guidance Navigation and Control Engineer',
        'Quality Inspector','Mission Manager','Payload Integration Engineer','Production Technician','Account Executive',
        'Customer Success Manager'), MOD(g.I, 10))::VARCHAR,
    GET(ARRAY_CONSTRUCT('Propulsion','Structures','Avionics','GNC','Quality','Mission Management','Integration','Production',
        'Sales','Customer Success'), MOD(g.I, 10))::VARCHAR,
    'DIV-0' || (1 + MOD(g.I, 6))::VARCHAR,
    DATEADD(DAY, -1 * UNIFORM(60, 2800, RANDOM()), CURRENT_DATE()),
    GET(ARRAY_CONSTRUCT('None','Confidential','Secret','Secret','Top Secret'), MOD(g.I, 5))::VARCHAR,
    UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) > 0.08
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS I FROM TABLE(GENERATOR(ROWCOUNT => 1000))) g;

-- ============================================================================
-- SUPPLIERS (200). Quality rating becomes the hidden supplier signal.
-- ============================================================================
INSERT INTO SUPPLIERS
SELECT
    'SUP-' || LPAD(g.I::VARCHAR, 4, '0'),
    GET(ARRAY_CONSTRUCT('AeroForge','NovaComposites','Helix Precision','Vector Additive','VoltCell','CryoDyne',
        'OptiTest Labs','Machworks','Skylane Electronics','Titan Fiber','Pinnacle Gauges','Arcadia Batteries'), MOD(g.I, 12))::VARCHAR
        || ' ' || LPAD(g.I::VARCHAR, 3, '0'),
    GET(ARRAY_CONSTRUCT('Carbon Composites','Electronics','Precision Machining','Additive Manufacturing',
        'Battery Cells','Propellants and Gases','Test Services','Optics'), MOD(g.I, 8))::VARCHAR,
    GET(ARRAY_CONSTRUCT('United States','United States','United States','New Zealand','Germany','Japan','South Korea','Canada'), MOD(g.I, 8))::VARCHAR,
    DATEADD(DAY, -1 * UNIFORM(400, 4000, RANDOM()), CURRENT_DATE()),
    ROUND(g.QUALITY, 2),
    ROUND(LEAST(5, GREATEST(1, g.QUALITY - UNIFORM(-0.4::FLOAT, 0.4::FLOAT, RANDOM()))), 2),
    ROUND(LEAST(99, 70 + g.QUALITY * 5 + UNIFORM(-3::FLOAT, 3::FLOAT, RANDOM())), 2),
    ROUND(GREATEST(5, 2200 - g.QUALITY * 400 + UNIFORM(-100::FLOAT, 100::FLOAT, RANDOM())))::INT,
    ROUND(GREATEST(0.2, (5.3 - g.QUALITY) * 2 + UNIFORM(0::FLOAT, 1::FLOAT, RANDOM())), 2),
    ROUND(EXP(UNIFORM(12::FLOAT, 16.5::FLOAT, RANDOM())), 2),
    MOD(g.I, 11) = 0,
    MOD(g.I, 4) <> 3,
    CASE WHEN g.QUALITY < 2.4 THEN 'Probation' WHEN g.QUALITY < 2.8 THEN 'Inactive' ELSE 'Active' END
FROM (SELECT I, IFF(MOD(I, 17) IN (3, 7), UNIFORM(1.8::FLOAT, 3.2::FLOAT, RANDOM()), UNIFORM(3.6::FLOAT, 4.9::FLOAT, RANDOM())) AS QUALITY
      FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS I FROM TABLE(GENERATOR(ROWCOUNT => 200)))) g;

-- ============================================================================
-- LAUNCH SITES (5)
-- ============================================================================
INSERT INTO LAUNCH_SITES
SELECT column1, column2, column3, column4, column5::FLOAT, column6::FLOAT, column7, column8
FROM VALUES
 ('LC-1A','Launch Complex 1 Pad A','Mahia Peninsula','New Zealand',-39.26, 177.86,'Electron, HASTE','Operational'),
 ('LC-1B','Launch Complex 1 Pad B','Mahia Peninsula','New Zealand',-39.26, 177.87,'Electron','Operational'),
 ('LC-2','Launch Complex 2','Wallops Island, Virginia','United States', 37.83, -75.49,'Electron, HASTE','Operational'),
 ('LC-3','Launch Complex 3','Wallops Island, Virginia','United States', 37.85, -75.48,'Neutron','Commissioning'),
 ('LC-4','Launch Complex 4 GHOST','Kodiak, Alaska','United States', 57.44,-152.34,'Electron, HASTE','Under Construction');

-- ============================================================================
-- CUSTOMERS (100 real organizations; every metric is synthetic).
-- Hidden profile: 60 HEALTHY, 20 EXPANDING, 10 AT_RISK, 10 CHURNED.
-- CUTOFF_TS is the last date of activity (churn date for churned).
-- ============================================================================
CREATE OR REPLACE TEMPORARY TABLE _CUST_SEED AS
SELECT column1::INT AS N, column2::VARCHAR AS CUSTOMER_NAME, column3::VARCHAR AS IND,
       column4::VARCHAR AS COUNTRY, column5::VARCHAR AS HQ_CITY
FROM VALUES
 (0,'NASA','SCI','United States','Washington'),
 (1,'Planet Labs','EO','United States','San Francisco'),
 (2,'BlackSky','EO','United States','Herndon'),
 (3,'Capella Space','EO','United States','San Francisco'),
 (4,'Spire Global','IOT','United States','Vienna'),
 (5,'HawkEye 360','IOT','United States','Herndon'),
 (6,'Astroscale','SVC','United States','Denver'),
 (7,'Synspective','EO','Japan','Tokyo'),
 (8,'ICEYE','EO','Finland','Espoo'),
 (9,'iQPS','EO','Japan','Fukuoka'),
 (10,'NASA Jet Propulsion Laboratory','SCI','United States','Pasadena'),
 (11,'NASA Goddard Space Flight Center','SCI','United States','Greenbelt'),
 (12,'NOAA','SCI','United States','Silver Spring'),
 (13,'European Space Agency','SCI','France','Paris'),
 (14,'UK Space Agency','SCI','United Kingdom','London'),
 (15,'Japan Aerospace Exploration Agency','SCI','Japan','Tokyo'),
 (16,'Korea Aerospace Research Institute','SCI','South Korea','Daejeon'),
 (17,'Canadian Space Agency','SCI','Canada','Longueuil'),
 (18,'Australian Space Agency','SCI','Australia','Adelaide'),
 (19,'German Aerospace Center','SCI','Germany','Cologne'),
 (20,'United States Space Force','DEF','United States','Colorado Springs'),
 (21,'National Reconnaissance Office','DEF','United States','Chantilly'),
 (22,'Defense Advanced Research Projects Agency','DEF','United States','Arlington'),
 (23,'Missile Defense Agency','DEF','United States','Huntsville'),
 (24,'US Air Force Research Laboratory','DEF','United States','Wright-Patterson AFB'),
 (25,'US Navy','DEF','United States','Washington'),
 (26,'UK Ministry of Defence','DEF','United Kingdom','London'),
 (27,'Japan Ministry of Defense','DEF','Japan','Tokyo'),
 (28,'Australian Department of Defence','DEF','Australia','Canberra'),
 (29,'NATO Communications and Information Agency','DEF','Netherlands','The Hague'),
 (30,'Lockheed Martin Space','DEF','United States','Denver'),
 (31,'Northrop Grumman','DEF','United States','Falls Church'),
 (32,'L3Harris Technologies','DEF','United States','Melbourne'),
 (33,'BAE Systems','DEF','United Kingdom','Farnborough'),
 (34,'General Atomics','DEF','United States','San Diego'),
 (35,'Leidos','DEF','United States','Reston'),
 (36,'Parsons Corporation','DEF','United States','Chantilly'),
 (37,'Boeing Defense','DEF','United States','Arlington'),
 (38,'Raytheon','DEF','United States','Arlington'),
 (39,'Thales Alenia Space','DEF','France','Cannes'),
 (40,'Viasat','COM','United States','Carlsbad'),
 (41,'Eutelsat OneWeb','COM','United Kingdom','London'),
 (42,'Globalstar','COM','United States','Covington'),
 (43,'Iridium Communications','COM','United States','McLean'),
 (44,'SES','COM','Luxembourg','Betzdorf'),
 (45,'Telesat','COM','Canada','Ottawa'),
 (46,'Intelsat','COM','United States','McLean'),
 (47,'EchoStar','COM','United States','Englewood'),
 (48,'Speedcast','COM','United States','Houston'),
 (49,'Inmarsat','COM','United Kingdom','London'),
 (50,'Maxar Technologies','EO','United States','Westminster'),
 (51,'Airbus Defence and Space','EO','Germany','Munich'),
 (52,'Satellogic','EO','United States','New York'),
 (53,'Umbra','EO','United States','Santa Barbara'),
 (54,'GHGSat','EO','Canada','Montreal'),
 (55,'Orbital Sidekick','EO','United States','San Francisco'),
 (56,'Albedo Space','EO','United States','Denver'),
 (57,'EarthDaily Analytics','EO','Canada','Vancouver'),
 (58,'Dragonfly Aerospace','EO','South Africa','Stellenbosch'),
 (59,'OHB SE','EO','Germany','Bremen'),
 (60,'Loft Orbital','SVC','United States','San Francisco'),
 (61,'True Anomaly','SVC','United States','Denver'),
 (62,'Varda Space Industries','SVC','United States','El Segundo'),
 (63,'Redwire Space','SVC','United States','Jacksonville'),
 (64,'Momentus','SVC','United States','San Jose'),
 (65,'D-Orbit','SVC','Italy','Como'),
 (66,'Exotrail','SVC','France','Massy'),
 (67,'Terran Orbital','SVC','United States','Irvine'),
 (68,'York Space Systems','SVC','United States','Denver'),
 (69,'Apex Space','SVC','United States','Los Angeles'),
 (70,'Firefly Aerospace','SVC','United States','Cedar Park'),
 (71,'Astra Space','SVC','United States','Alameda'),
 (72,'ABL Space Systems','SVC','United States','El Segundo'),
 (73,'Relativity Space','SVC','United States','Long Beach'),
 (74,'Rocket Lab Customer Programs','SVC','United States','Long Beach'),
 (75,'Muon Space','EO','United States','Mountain View'),
 (76,'Pixxel','EO','United States','El Segundo'),
 (77,'Tomorrow.io','EO','United States','Boston'),
 (78,'Unseenlabs','IOT','France','Rennes'),
 (79,'Kleos Space','IOT','Luxembourg','Luxembourg'),
 (80,'Kinetic Solutions','IOT','United States','Austin'),
 (81,'Starfish Space','SVC','United States','Seattle'),
 (82,'ClearSpace','SVC','Switzerland','Renens'),
 (83,'Orbit Fab','SVC','United States','Lafayette'),
 (84,'Impulse Space','SVC','United States','Redondo Beach'),
 (85,'Turion Space','SVC','United States','Irvine'),
 (86,'Skyloom Global','COM','United States','Denver'),
 (87,'Bridgesat','COM','United States','Washington'),
 (88,'Mynaric','COM','Germany','Munich'),
 (89,'Cailabs','COM','France','Rennes'),
 (90,'Space Systems Loral Legacy Program','COM','United States','Palo Alto'),
 (91,'MIT Lincoln Laboratory','SCI','United States','Lexington'),
 (92,'Johns Hopkins APL','SCI','United States','Laurel'),
 (93,'University of Colorado LASP','SCI','United States','Boulder'),
 (94,'University of Toronto Institute for Aerospace Studies','SCI','Canada','Toronto'),
 (95,'Surrey Satellite Technology','EO','United Kingdom','Guildford'),
 (96,'Tyvak Nano-Satellite Systems','SVC','United States','Irvine'),
 (97,'AAC Clyde Space','SVC','Sweden','Uppsala'),
 (98,'GomSpace','SVC','Denmark','Aalborg'),
 (99,'Berlin Space Technologies','EO','Germany','Berlin');

CREATE OR REPLACE TEMPORARY TABLE _CUST_PROFILE AS
SELECT N,
    'CUST-' || LPAD(N::VARCHAR, 4, '0') AS CUSTOMER_ID,
    PROFILE,
    CHURN_DATE,
    COALESCE(CHURN_DATE::TIMESTAMP_NTZ, CURRENT_TIMESTAMP()::TIMESTAMP_NTZ) AS CUTOFF_TS,
    CASE PROFILE WHEN 'AT_RISK' THEN 2.0 WHEN 'CHURNED' THEN 1.8 ELSE 1.0 END AS RECENCY_EXP
FROM (
    SELECT N, PROFILE,
        CASE WHEN PROFILE = 'CHURNED' THEN DATEADD(DAY, -1 * UNIFORM(45, 250, RANDOM()), CURRENT_DATE()) END AS CHURN_DATE
    FROM (
        SELECT N,
            CASE WHEN MOD(N, 10) = 3 THEN 'CHURNED'
                 WHEN MOD(N, 10) = 7 THEN 'AT_RISK'
                 WHEN MOD(N, 10) IN (1, 5) THEN 'EXPANDING'
                 ELSE 'HEALTHY' END AS PROFILE
        FROM _CUST_SEED
    )
);

INSERT INTO CUSTOMERS
SELECT
    p.CUSTOMER_ID, s.CUSTOMER_NAME,
    CASE WHEN s.IND IN ('DEF') AND s.COUNTRY = 'United States' THEN 'National Security'
         WHEN s.IND IN ('DEF') THEN 'International Agency'
         WHEN s.IND = 'SCI' AND s.N IN (91,92,93,94) THEN 'Academic'
         WHEN s.IND = 'SCI' THEN 'Civil Government'
         ELSE 'Commercial' END,
    CASE s.IND WHEN 'EO' THEN 'Earth Observation' WHEN 'COM' THEN 'Communications' WHEN 'IOT' THEN 'IoT and Tracking'
               WHEN 'DEF' THEN 'Defense and Hypersonics' WHEN 'SCI' THEN 'Science and Exploration' ELSE 'In-Space Services' END,
    CASE WHEN s.IND IN ('DEF','SCI') THEN 'Strategic' WHEN s.IND IN ('EO','COM') THEN 'Enterprise' ELSE 'Commercial' END,
    CASE WHEN s.COUNTRY IN ('United States','Canada') THEN 'North America'
         WHEN s.COUNTRY IN ('Japan','South Korea','Australia','South Africa') THEN 'Asia Pacific' ELSE 'Europe' END,
    s.COUNTRY, s.HQ_CITY,
    GET(ARRAY_CONSTRUCT('Sarah Chen','Marcus Johnson','Elena Rodriguez','James Park','Priya Patel','David Thompson'), MOD(s.N, 6))::VARCHAR,
    GET(ARRAY_CONSTRUCT('Nina Alvarez','Tom Becker','Grace Liu','Omar Haddad','Rachel Green','Ben Okafor','Hannah Mueller','Luis Romero'), MOD(s.N, 8))::VARCHAR,
    CASE WHEN s.IND IN ('DEF','SCI') THEN 'Platinum' WHEN s.IND IN ('EO','COM') THEN 'Gold' ELSE 'Silver' END,
    NULL, NULL, NULL,
    NULL
FROM _CUST_SEED s
JOIN _CUST_PROFILE p ON p.N = s.N;

-- ============================================================================
-- VEHICLES (100): 40 flown, 60 in the production pipeline or test articles
-- ============================================================================
CREATE OR REPLACE TEMPORARY TABLE _VEHICLE AS
SELECT g.I,
    CASE WHEN g.I < 30 THEN 'Electron' WHEN g.I < 38 THEN 'HASTE' WHEN g.I < 40 THEN 'Neutron' ELSE NULL END AS FLOWN_TYPE,
    CASE WHEN g.I >= 80 THEN 'Test Article'
         WHEN g.I >= 70 THEN 'Neutron'
         WHEN g.I >= 60 THEN 'HASTE' ELSE 'Electron' END AS BUILD_TYPE
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS I FROM TABLE(GENERATOR(ROWCOUNT => 100))) g;

INSERT INTO VEHICLES
SELECT
    'VEH-' || LPAD(v.I::VARCHAR, 3, '0'),
    CASE COALESCE(v.FLOWN_TYPE, v.BUILD_TYPE)
        WHEN 'Electron' THEN 'Electron F-' || LPAD(v.I::VARCHAR, 3, '0')
        WHEN 'HASTE' THEN 'HASTE H-' || LPAD(v.I::VARCHAR, 2, '0')
        WHEN 'Neutron' THEN 'Neutron N-' || LPAD((v.I - 37)::VARCHAR, 2, '0')
        ELSE 'Test Article TA-' || LPAD((v.I - 79)::VARCHAR, 2, '0') END,
    COALESCE(v.FLOWN_TYPE, v.BUILD_TYPE),
    'RL-' || UPPER(SUBSTR(MD5(v.I::VARCHAR), 1, 10)),
    DATEADD(DAY, -1 * UNIFORM(60, 2600, RANDOM()), CURRENT_DATE()),
    CASE WHEN v.FLOWN_TYPE IS NOT NULL AND UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) < 0.06 THEN 'Lost'
         WHEN v.FLOWN_TYPE IS NOT NULL AND v.FLOWN_TYPE = 'Electron' AND UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) < 0.15 THEN 'Recovered'
         WHEN v.FLOWN_TYPE IS NOT NULL THEN 'Flown'
         WHEN COALESCE(v.FLOWN_TYPE, v.BUILD_TYPE) = 'Test Article' THEN 'Active Test'
         ELSE GET(ARRAY_CONSTRUCT('In Production','Integration','Ready for Launch','Refurbishment'), MOD(v.I, 4))::VARCHAR END,
    IFF(COALESCE(v.FLOWN_TYPE, v.BUILD_TYPE) IN ('Electron','HASTE','Neutron'), 2, 1),
    IFF(COALESCE(v.FLOWN_TYPE, v.BUILD_TYPE) IN ('Electron','HASTE','Neutron'), 10, UNIFORM(1, 3, RANDOM())),
    COALESCE(v.FLOWN_TYPE, v.BUILD_TYPE) IN ('Electron','Neutron'),
    IFF(COALESCE(v.FLOWN_TYPE, v.BUILD_TYPE) = 'Electron' AND v.FLOWN_TYPE IS NOT NULL, UNIFORM(0, 2, RANDOM()), 0)
FROM _VEHICLE v;

-- ============================================================================
-- MISSIONS (300): 120 flown, 180 in backlog assigned to pipeline vehicles
-- ============================================================================
CREATE OR REPLACE TEMPORARY TABLE _MISSION AS
SELECT g.I,
    CASE WHEN g.I < 100 THEN 'Electron' WHEN g.I < 118 THEN 'HASTE' ELSE 'Neutron' END AS FLOWN_TYPE
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS I FROM TABLE(GENERATOR(ROWCOUNT => 120))) g
UNION ALL
SELECT 1000 + b.I,
    GET(ARRAY_CONSTRUCT('Electron','Electron','HASTE','Neutron'), MOD(b.I, 4))::VARCHAR
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS I FROM TABLE(GENERATOR(ROWCOUNT => 180))) b;


INSERT INTO MISSIONS
SELECT
    'MSN-' || LPAD(m.SEQ::VARCHAR, 4, '0'),
    m.SEQ + 1,
    GET(ARRAY_CONSTRUCT('The Owl''s Night Begins','Running Out of Toes','A Sky Full of Stars','Catch Me If You Can',
        'Photon to the Stars','Look Ma, No Hands','It''s a Little Chile Up Here','Return to Sender',
        'A Data With Destiny','Virginia is for Launch Lovers'), MOD(m.SEQ, 10))::VARCHAR || ' ' || (m.SEQ + 1)::VARCHAR,
    v.VEHICLE_ID,
    m.FLOWN_TYPE,
    p.CUSTOMER_ID,
    CASE WHEN m.FLOWN_TYPE = 'Neutron' THEN 'LC-3'
         ELSE GET(ARRAY_CONSTRUCT('LC-1A','LC-1A','LC-1B','LC-2','LC-4'), MOD(m.SEQ, 5))::VARCHAR END,
    CASE m.FLOWN_TYPE WHEN 'HASTE' THEN 'Suborbital Hypersonic Test'
         WHEN 'Neutron' THEN IFF(MOD(m.SEQ, 3) = 0, 'Constellation Deployment', 'Dedicated Orbital')
         ELSE GET(ARRAY_CONSTRUCT('Dedicated Orbital','Rideshare','Constellation Deployment','Interplanetary','National Security'), MOD(m.SEQ, 5))::VARCHAR END,
    CASE m.FLOWN_TYPE WHEN 'HASTE' THEN 'Suborbital'
         ELSE GET(ARRAY_CONSTRUCT('SSO','LEO','Mid-Inclination LEO','MEO','Lunar Transfer'), MOD(m.SEQ, 5))::VARCHAR END,
    IFF(m.FLOWN_TYPE = 'HASTE', 1, UNIFORM(1, 12, RANDOM())),
    IFF(m.FLOWN_TYPE = 'HASTE', ROUND(UNIFORM(80::FLOAT, 700::FLOAT, RANDOM()), 1), ROUND(UNIFORM(30::FLOAT, 300::FLOAT, RANDOM()), 1)),
    ROUND(CASE m.FLOWN_TYPE WHEN 'Neutron' THEN UNIFORM(12000000::FLOAT, 55000000::FLOAT, RANDOM())
                            WHEN 'HASTE' THEN UNIFORM(8000000::FLOAT, 25000000::FLOAT, RANDOM())
                            ELSE UNIFORM(7000000::FLOAT, 12000000::FLOAT, RANDOM()) END, 2),
    m.PLANNED, m.ACTUAL,
    IFF(m.ACTUAL IS NULL, NULL, GREATEST(0, DATEDIFF(DAY, m.PLANNED, m.ACTUAL))),
    CASE WHEN m.ACTUAL IS NULL THEN GET(ARRAY_CONSTRUCT('Scheduled','Scheduled','Payload Integration','Launch Ready'), MOD(m.SEQ, 4))::VARCHAR
         WHEN v.STATUS = 'Lost' THEN 'Failure' ELSE 'Success' END,
    ROUND(UNIFORM(0.05::FLOAT, 0.6::FLOAT, RANDOM()), 2),
    ROUND(UNIFORM(0.05::FLOAT, 0.5::FLOAT, RANDOM()), 2),
    m.SEQ = fs.FIRST_SEQ,
    m.FLOWN_TYPE = 'Electron' AND m.I < 100 AND MOD(m.SEQ, 2) = 0,
    m.FLOWN_TYPE = 'Electron' AND m.I < 100 AND MOD(m.SEQ, 3) = 0
FROM (
    SELECT ROW_NUMBER() OVER (ORDER BY m0.I) - 1 AS SEQ, m0.FLOWN_TYPE, m0.I, MOD(m0.I, 100) AS CUST_N,
        IFF(m0.I < 1000,
            DATEADD(DAY, -1 * (2400 - ROUND(m0.I * 18.5))::INT, CURRENT_DATE()),
            DATEADD(DAY, 20 + MOD(m0.I, 180) * 4, CURRENT_DATE())) AS PLANNED,
        IFF(m0.I < 1000, DATEADD(DAY, UNIFORM(0, 45, RANDOM()),
            DATEADD(DAY, -1 * (2400 - ROUND(m0.I * 18.5))::INT, CURRENT_DATE())), NULL) AS ACTUAL
    FROM _MISSION m0
) m
JOIN _CUST_PROFILE p ON p.N = m.CUST_N
JOIN (SELECT MOD(m0.I, 100) AS N, MIN(m0.I) AS FIRST_SEQ FROM _MISSION m0 GROUP BY 1) fs ON fs.N = m.CUST_N
JOIN VEHICLES v ON v.VEHICLE_ID =
    CASE WHEN m.I < 100 THEN 'VEH-' || LPAD(MOD(m.I, 30)::VARCHAR, 3, '0')
         WHEN m.I < 118 THEN 'VEH-' || LPAD((30 + MOD(m.I, 8))::VARCHAR, 3, '0')
         WHEN m.I < 1000 THEN 'VEH-' || LPAD((38 + MOD(m.I, 2))::VARCHAR, 3, '0')
         ELSE 'VEH-' || LPAD((40 + MOD(m.I, 40))::VARCHAR, 3, '0') END;

-- ============================================================================
-- COMPONENTS (5,000 = 50 per vehicle). Condition derives from a hidden wear
-- index (cycles used / qualified life, scaled by duty and supplier quality).
-- Hardware on flown vehicles is marked Flown and excluded from prediction.
-- ============================================================================
CREATE OR REPLACE TEMPORARY TABLE _COMPONENT_RAW AS
SELECT
    'CMP-' || LPAD(g.I::VARCHAR, 5, '0') AS COMPONENT_ID,
    v.VEHICLE_ID,
    v.STATUS AS VEHICLE_STATUS,
    g.CTYPE AS COMPONENT_TYPE,
    'SUP-' || LPAD(MOD(g.I * 3, 200)::VARCHAR, 4, '0') AS SUPPLIER_ID,
    g.LIFE AS EXPECTED_LIFE,
    LEAST(g.LIFE + UNIFORM(0, 200, RANDOM()), ROUND(g.LIFE * (g.CYCLES_FRAC + IFF(v.STATUS = 'Flown', 0.5, 0))))::INT AS CYCLES_USED,
    g.NOISE
FROM (
    SELECT I,
        GET(ARRAY_CONSTRUCT('Rutherford Engine','Rutherford Vacuum Engine','Archimedes Engine','Battery Pack','Flight Computer',
            'Composite Propellant Tank','Fairing','Curie Kick Stage','Stage Separation System','Recovery Parachute',
            'Reaction Control System','Landing Leg'), T)::VARCHAR AS CTYPE,
        CASE T WHEN 0 THEN 20 WHEN 1 THEN 20 WHEN 2 THEN 15 WHEN 3 THEN 400 WHEN 4 THEN 300
               WHEN 5 THEN 25 WHEN 6 THEN 10 WHEN 7 THEN 15 WHEN 8 THEN 30 WHEN 9 THEN 12
               WHEN 10 THEN 500 ELSE 8 END AS LIFE,
        UNIFORM(0.05::FLOAT, 0.95::FLOAT, RANDOM()) AS CYCLES_FRAC,
        UNIFORM(-0.15::FLOAT, 0.15::FLOAT, RANDOM()) AS NOISE
    FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS I, MOD(SEQ4(), 12) AS T
          FROM TABLE(GENERATOR(ROWCOUNT => 5000)))
) g
JOIN VEHICLES v ON v.VEHICLE_ID = 'VEH-' || LPAD(MOD(g.I, 100)::VARCHAR, 3, '0');

INSERT INTO COMPONENTS
SELECT
    c.COMPONENT_ID, c.VEHICLE_ID, c.SUPPLIER_ID, c.COMPONENT_TYPE,
    c.COMPONENT_TYPE || ' ' || LPAD(MOD(c.COMPONENT_ID_N, 50)::VARCHAR, 2, '0'),
    'BAT-' || UPPER(SUBSTR(MD5(c.COMPONENT_ID), 1, 8)),
    DATEADD(DAY, -1 * UNIFORM(60, 1500, RANDOM()), CURRENT_DATE()),
    c.EXPECTED_LIFE, c.CYCLES_USED,
    CASE WHEN c.VEHICLE_STATUS IN ('Flown','Lost','Recovered') THEN 'Flown'
         WHEN c.WEAR < 0.60 THEN 'Operational'
         WHEN c.WEAR < 0.85 THEN 'Degraded'
         WHEN c.WEAR < 1.05 THEN 'Needs Replacement'
         ELSE 'Failed' END,
    DATEADD(DAY, -1 * UNIFORM(1, 120, RANDOM()), CURRENT_DATE()),
    GREATEST(0, ROUND(c.EXPECTED_LIFE * (1.05 - LEAST(c.WEAR, 1.4))))::INT
FROM (
    SELECT cr.*, TO_NUMBER(SUBSTR(cr.COMPONENT_ID, 5)) AS COMPONENT_ID_N,
        DIV0(cr.CYCLES_USED, cr.EXPECTED_LIFE) * IFF(s.QUALITY_RATING < 3, 1.25, 1.0) + cr.NOISE AS WEAR
    FROM _COMPONENT_RAW cr
    JOIN SUPPLIERS s ON s.SUPPLIER_ID = cr.SUPPLIER_ID
) c;

-- ============================================================================
-- TEST RESULTS (20,000). Failure probability rises with component wear and
-- falls with supplier quality, so the quality model has signal.
-- ============================================================================
CREATE OR REPLACE TEMPORARY TABLE _TEST AS
SELECT
    'TST-' || LPAD(g.I::VARCHAR, 6, '0') AS TEST_ID,
    c.COMPONENT_ID, c.SUPPLIER_ID, c.COMPONENT_TYPE, c.STATUS,
    GET(ARRAY_CONSTRUCT('Hot Fire','Acceptance','Vibration','Thermal Vacuum','Pressure Proof','Functional','Wet Dress Rehearsal'), MOD(g.I, 7))::VARCHAR AS TEST_TYPE,
    GET(ARRAY_CONSTRUCT('Long Beach Engine Test Complex','Auckland Production Complex','Stennis A-Complex',
        'Wallops Integration Facility','Mahia LC-1 Pad'), MOD(g.I, 5))::VARCHAR AS TEST_FACILITY,
    DATEADD(DAY, -1 * UNIFORM(1, 900, RANDOM()), CURRENT_TIMESTAMP()::TIMESTAMP_NTZ) AS TEST_DATE,
    UNIFORM(90::FLOAT, 110::FLOAT, RANDOM()) AS MEASURED,
    100.0 AS LIMIT_VALUE,
    'EMP-' || LPAD(MOD(g.I, 1000)::VARCHAR, 5, '0') AS INSPECTOR_ID,
    UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) AS U
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS I FROM TABLE(GENERATOR(ROWCOUNT => 20000))) g
JOIN COMPONENTS c ON c.COMPONENT_ID = 'CMP-' || LPAD(MOD(g.I, 5000)::VARCHAR, 5, '0');

INSERT INTO TEST_RESULTS
SELECT TEST_ID, COMPONENT_ID, TEST_TYPE, TEST_FACILITY, TEST_DATE,
    CASE WHEN U < 0.02 + IFF(STATUS = 'Failed', 0.30, 0) + IFF(STATUS = 'Degraded', 0.10, 0) THEN 'Fail'
         WHEN U < 0.06 THEN 'Conditional Pass' ELSE 'Pass' END,
    MEASURED, LIMIT_VALUE,
    GET(ARRAY_CONSTRUCT('kN','bar','g RMS','C','MPa','deg','seconds'), MOD(TO_NUMBER(SUBSTR(TEST_ID, 5)), 7))::VARCHAR,
    INSPECTOR_ID,
    NULL
FROM _TEST;

-- ============================================================================
-- ENGINE TELEMETRY (150,000 samples over the last year). Stressed engines
-- (failed or degraded) run hotter, vibrate more and fault more often.
-- ============================================================================
INSERT INTO ENGINE_TELEMETRY
SELECT
    'TEL-' || LPAD(g.I::VARCHAR, 7, '0'),
    c.COMPONENT_ID,
    DATEADD(SECOND, -1 * UNIFORM(0, 31536000, RANDOM()), CURRENT_TIMESTAMP()::TIMESTAMP_NTZ),
    IFF(c.COMPONENT_TYPE LIKE 'Archimedes%', 'Archimedes', 'Rutherford'),
    GET(ARRAY_CONSTRUCT('Startup','Mainstage','Mainstage','Throttle','Shutdown'), MOD(g.I, 5))::VARCHAR,
    ROUND(CASE WHEN c.COMPONENT_TYPE LIKE 'Archimedes%' THEN UNIFORM(55::FLOAT, 90::FLOAT, RANDOM())
               ELSE UNIFORM(20::FLOAT, 35::FLOAT, RANDOM()) END + g.STRESS * 4, 2),
    ROUND(CASE WHEN c.COMPONENT_TYPE LIKE 'Archimedes%' THEN UNIFORM(600::FLOAT, 1000::FLOAT, RANDOM())
               ELSE UNIFORM(22::FLOAT, 26::FLOAT, RANDOM()) END, 2),
    ROUND(CASE WHEN c.COMPONENT_TYPE LIKE 'Archimedes%' THEN UNIFORM(25000::FLOAT, 40000::FLOAT, RANDOM())
               ELSE UNIFORM(38000::FLOAT, 45000::FLOAT, RANDOM()) END, 0),
    IFF(c.COMPONENT_TYPE LIKE 'Archimedes%', NULL, ROUND(UNIFORM(330::FLOAT, 420::FLOAT, RANDOM()) - g.STRESS * 15, 1)),
    ROUND(UNIFORM(88::FLOAT, 100::FLOAT, RANDOM()), 1),
    ROUND(UNIFORM(180::FLOAT, 450::FLOAT, RANDOM()) + g.STRESS * 120, 1),
    ROUND(UNIFORM(0.5::FLOAT, 4::FLOAT, RANDOM()) + g.STRESS * 6, 2),
    ROUND(UNIFORM(1.9::FLOAT, 2.6::FLOAT, RANDOM()), 2),
    IFF(UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) < 0.03 + g.STRESS * 0.15,
        'ERR-' || LPAD(UNIFORM(100, 999, RANDOM())::VARCHAR, 3, '0'), NULL)
FROM (
    SELECT g0.I,
        IFF(c0.STATUS IN ('Failed','Degraded','Needs Replacement'), 1, 0) * UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) AS STRESS,
        MOD(g0.I, 400) AS ENG_IDX
    FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS I FROM TABLE(GENERATOR(ROWCOUNT => 150000))) g0
    JOIN (SELECT COMPONENT_ID, STATUS, ROW_NUMBER() OVER (ORDER BY COMPONENT_ID) - 1 AS ENG_IDX
          FROM COMPONENTS WHERE COMPONENT_TYPE IN ('Rutherford Engine','Rutherford Vacuum Engine','Archimedes Engine')) c0
        ON c0.ENG_IDX = MOD(g0.I, 400)
) g
JOIN (SELECT COMPONENT_ID, COMPONENT_TYPE, STATUS, ROW_NUMBER() OVER (ORDER BY COMPONENT_ID) - 1 AS ENG_IDX
      FROM COMPONENTS WHERE COMPONENT_TYPE IN ('Rutherford Engine','Rutherford Vacuum Engine','Archimedes Engine')) c
    ON c.ENG_IDX = g.ENG_IDX;

-- ============================================================================
-- MAINTENANCE (6,000), ANOMALIES (~1,500, rate driven by customer profile)
-- ============================================================================
INSERT INTO MAINTENANCE_RECORDS
SELECT
    'MNT-' || LPAD(g.I::VARCHAR, 5, '0'),
    'VEH-' || LPAD(MOD(g.I, 100)::VARCHAR, 3, '0'),
    IFF(MOD(g.I, 10) < 7, 'CMP-' || LPAD(MOD(g.I * 5, 5000)::VARCHAR, 5, '0'), NULL),
    GET(ARRAY_CONSTRUCT('Post-Flight Refurbishment','Preventive','Corrective','Inspection','Requalification'), MOD(g.I, 5))::VARCHAR,
    GET(ARRAY_CONSTRUCT(
        'Post-flight inspection and refurbishment of the first stage completed and the vehicle returned to the production flow.',
        'Routine inspection and torque check of engine mounts and propellant lines completed.',
        'Replaced degraded battery cells and verified bus voltage under load.',
        'Avionics firmware upgraded and full functional self-test passed.',
        'Tank proof test repeated after seal replacement; pressure hold verified.',
        'Corrective work on stage separation system after nonconformance found in acceptance.',
        'Parachute repack and pyrotechnic continuity check completed.',
        'Engine acceptance hot fire repeated after injector swap.'), MOD(g.I, 8))::VARCHAR,
    GET(ARRAY_CONSTRUCT('Long Beach Engine Test Complex','Auckland Production Complex','Wallops Integration Facility','Mahia LC-1 Pad'), MOD(g.I, 4))::VARCHAR,
    GET(ARRAY_CONSTRUCT('Alex Martinez','Jordan Lee','Sam Nguyen','Robin Patel','Casey Williams','Morgan Brown'), MOD(g.I, 6))::VARCHAR,
    DATEADD(DAY, -1 * UNIFORM(1, 700, RANDOM()), CURRENT_TIMESTAMP()::TIMESTAMP_NTZ),
    ROUND(UNIFORM(2::FLOAT, 80::FLOAT, RANDOM()), 1),
    ROUND(UNIFORM(1500::FLOAT, 85000::FLOAT, RANDOM()), 2),
    IFF(MOD(g.I, 5) < 2, GET(ARRAY_CONSTRUCT('Battery cells','Injector assembly','Actuator','Seal kit','Avionics board'), MOD(g.I, 5))::VARCHAR, NULL),
    GET(ARRAY_CONSTRUCT('Returned to Service','Returned to Service','Returned to Service','Monitoring','Scrapped'), MOD(g.I, 5))::VARCHAR
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS I FROM TABLE(GENERATOR(ROWCOUNT => 6000))) g;

INSERT INTO ANOMALIES
SELECT
    'ANM-' || LPAD((ROW_NUMBER() OVER (ORDER BY x.REPORTED_AT) - 1)::VARCHAR, 5, '0'),
    x.VEHICLE_ID, x.MISSION_ID, x.COMPONENT_ID,
    GET(ARRAY_CONSTRUCT('Engine Performance','Avionics Fault','Telemetry Dropout','Propellant System','Structural',
        'Ground Support Equipment','Range Hold','Weather Hold'), x.T)::VARCHAR,
    CASE WHEN x.U < IFF(x.PROFILE IN ('AT_RISK','CHURNED'), 0.30, 0.12) THEN 'Critical'
         WHEN x.U < IFF(x.PROFILE IN ('AT_RISK','CHURNED'), 0.60, 0.40) THEN 'High'
         WHEN x.U < 0.80 THEN 'Medium' ELSE 'Low' END,
    GET(ARRAY_CONSTRUCT('Production Test','Integration','Countdown','Flight','Recovery'), MOD(x.T, 5))::VARCHAR,
    GET(ARRAY_CONSTRUCT(
        'Engine chamber pressure oscillated outside the acceptance band during mainstage and the test was aborted.',
        'Flight computer watchdog reset during powered ascent simulation. Telemetry was continuous but command uplink dropped for nine seconds.',
        'Telemetry dropout on the S-band link during countdown. Vehicle state was nominal throughout.',
        'LOX tank vent valve failed to seat during chill-down, extending the countdown.',
        'Composite tank layup nonconformance found in ultrasonic inspection.',
        'Ground support equipment hydraulic fault delayed erection of the vehicle.',
        'Range hold for traffic; no vehicle impact.',
        'Weather hold for upper level winds exceeding limits.'), x.T)::VARCHAR,
    x.REPORTED_AT,
    IFF(x.IS_RESOLVED, DATEADD(HOUR, x.RES_H, x.REPORTED_AT), NULL),
    IFF(x.IS_RESOLVED, 'Corrective action completed, hardware retested and released to the flow.', NULL),
    GET(ARRAY_CONSTRUCT('Component wear','Software defect','Supplier quality','Environmental conditions','Ground systems','Workmanship'), MOD(x.T, 6))::VARCHAR,
    IFF(x.PROFILE IN ('AT_RISK','CHURNED'), UNIFORM(2, 21, RANDOM()), UNIFORM(0, 5, RANDOM()))
FROM (
    SELECT y.*, y.RES_U < 0.8 AS IS_RESOLVED
    FROM (
        SELECT m.VEHICLE_ID, m.MISSION_ID, m.CUSTOMER_ID, p.PROFILE,
            SEQ4() AS K, UNIFORM(0, 7, RANDOM()) AS T,
            UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) AS U,
            UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) AS RES_U,
            UNIFORM(4, 240, RANDOM()) AS RES_H,
            DATEADD(DAY, -1 * ROUND(700 * POW(UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()), p.RECENCY_EXP))::INT, p.CUTOFF_TS) AS REPORTED_AT,
            IFF(UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) < 0.7,
                'CMP-' || LPAD(MOD(UNIFORM(0, 4999, RANDOM()), 5000)::VARCHAR, 5, '0'), NULL) AS COMPONENT_ID,
            UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) AS KEEP_U
        FROM MISSIONS m
        JOIN _CUST_PROFILE p ON p.CUSTOMER_ID = m.CUSTOMER_ID
        CROSS JOIN TABLE(GENERATOR(ROWCOUNT => 8)) g
        WHERE m.ACTUAL_LAUNCH_DATE IS NOT NULL OR m.STATUS <> 'Scheduled'
    ) y
    WHERE y.KEEP_U < CASE y.PROFILE WHEN 'AT_RISK' THEN 0.9 WHEN 'CHURNED' THEN 0.75 ELSE 0.35 END
) x;

-- ============================================================================
-- DOCUMENTS and failure reports (text for Cortex Search)
-- ============================================================================
INSERT INTO MISSION_DOCUMENTS
SELECT
    'DOC-' || LPAD(g.SEQ::VARCHAR, 5, '0'),
    g.MISSION_ID,
    GET(ARRAY_CONSTRUCT('Mission Requirements','Flight Readiness Review','Post-Flight Report','Payload Interface Control'), MOD(g.SEQ, 4))::VARCHAR
        || ' - ' || g.MISSION_NAME,
    GET(ARRAY_CONSTRUCT('Mission Requirements','Flight Readiness Review','Post-Flight Report','Payload Interface Control'), MOD(g.SEQ, 4))::VARCHAR,
    'Mission ' || g.MISSION_NAME || ' (' || g.MISSION_ID || ') for customer ' || g.CUSTOMER_ID || ' on vehicle type ' || g.VEHICLE_TYPE
        || ' launching from site ' || g.SITE_ID || ' to ' || g.TARGET_ORBIT || '. Contract value ' || g.CONTRACT_VALUE_USD::VARCHAR
        || ' USD. ' || GET(ARRAY_CONSTRUCT(
            'Requirements baseline covers orbit accuracy, payload environments and interface control. All customer requirements are verified against the trajectory analysis and the payload user guide.',
            'Flight readiness review confirms vehicle, range, payload and weather are green. Open nonconformances are dispositioned and residual risk is accepted by the mission director.',
            'Post-flight report summarizes ascent performance, separation events and payload deployment. All success criteria were met and telemetry is archived for the customer.',
            'Payload interface control document defines the mechanical, electrical and environmental interfaces between the spacecraft and the vehicle.'), MOD(g.SEQ, 4))::VARCHAR,
    GET(ARRAY_CONSTRUCT('Mission Management','Vehicle Engineering','Flight Safety','Payload Integration'), MOD(g.SEQ, 4))::VARCHAR,
    COALESCE(g.ACTUAL_LAUNCH_DATE, g.PLANNED_LAUNCH_DATE)::TIMESTAMP_NTZ
FROM (SELECT m.*, ROW_NUMBER() OVER (ORDER BY m.MISSION_ID) - 1 AS SEQ FROM MISSIONS m) g
WHERE MOD(g.SEQ, 2) = 0;

INSERT INTO TEST_FAILURE_REPORTS
SELECT
    'TFR-' || LPAD((ROW_NUMBER() OVER (ORDER BY t.TEST_DATE) - 1)::VARCHAR, 5, '0'),
    t.TEST_ID, t.COMPONENT_ID, c.SUPPLIER_ID, c.COMPONENT_TYPE,
    'Failure analysis - ' || t.TEST_TYPE || ' of ' || c.COMPONENT_TYPE || ' ' || c.COMPONENT_ID,
    'During the ' || t.TEST_TYPE || ' test at ' || t.TEST_FACILITY || ' the ' || c.COMPONENT_TYPE || ' ' || c.COMPONENT_ID
        || ' from supplier ' || c.SUPPLIER_ID || ' failed to meet acceptance. Measured value ' || ROUND(t.MEASURED_VALUE, 2)::VARCHAR
        || ' against limit ' || t.LIMIT_VALUE::VARCHAR || ' ' || t.UNIT
        || '. The failure was isolated to a single unit and the rest of the batch was re-inspected.',
    GET(ARRAY_CONSTRUCT('Critical','Major','Minor'), MOD(ROW_NUMBER() OVER (ORDER BY t.TEST_DATE), 3))::VARCHAR,
    GET(ARRAY_CONSTRUCT('Supplier workmanship','Material defect','Process escape','Design margin','Test setup'), MOD(ROW_NUMBER() OVER (ORDER BY t.TEST_DATE), 5))::VARCHAR,
    'Unit removed from the flow, supplier corrective action requested and acceptance criteria re-verified on the replacement unit.',
    t.TEST_DATE
FROM TEST_RESULTS t
JOIN COMPONENTS c ON c.COMPONENT_ID = t.COMPONENT_ID
WHERE t.RESULT = 'Fail';

-- ============================================================================
-- KNOWLEDGE BASE (25 articles)
-- ============================================================================
INSERT INTO KNOWLEDGE_BASE
SELECT 'KB-' || LPAD(column1::VARCHAR, 4, '0'), column2, column3, column4, column5, column6, column7,
       DATEADD(DAY, -1 * UNIFORM(0, 120, RANDOM()), CURRENT_TIMESTAMP()::TIMESTAMP_NTZ)
FROM VALUES
(0,'Electron Launch Vehicle Overview','Vehicle Specifications','Electron',
 'Electron is a two stage small orbital launch vehicle. Nine Rutherford engines power the first stage and one Rutherford vacuum engine powers the second stage. It lifts up to about 300 kg to low Earth orbit and has flown dedicated, rideshare and constellation missions since 2017. Electron has demonstrated first stage recovery from the ocean.','electron,specifications,overview','Vehicle Engineering'),
(1,'HASTE Suborbital Vehicle Overview','Vehicle Specifications','HASTE',
 'HASTE (Hypersonic Accelerator Suborbital Test Electron) is a suborbital configuration of Electron for hypersonic test missions. It flies the same Rutherford propulsion with a modified payload accommodation and trajectory, supporting defense flight testing from LC-2 and Mahia.','haste,hypersonic,specifications','Vehicle Engineering'),
(2,'Neutron Launch Vehicle Overview','Vehicle Specifications','Neutron',
 'Neutron is a medium lift reusable launch vehicle in development. Archimedes gas generator engines burning liquid methane and liquid oxygen power the vehicle. The first stage returns for reuse and the vehicle carries a captive fairing. Launch Complex 3 at Wallops Island is being commissioned for Neutron.','neutron,archimedes,specifications','Vehicle Engineering'),
(3,'Rutherford Engine Operating Characteristics','Vehicle Specifications','Electron',
 'Rutherford is an electric pump fed engine burning kerosene and liquid oxygen. Battery powered pumps replace a turbopump, which simplifies the engine and makes thrust controllable. The engine family covers sea level and vacuum variants. Hot fire acceptance is performed at the Long Beach engine test complex before integration.','rutherford,engine,electric pump','Propulsion'),
(4,'Archimedes Engine Operating Characteristics','Vehicle Specifications','Neutron',
 'Archimedes is an oxidizer rich staged combustion... gas generator engine family burning methane and liquid oxygen, designed for reuse on Neutron. Development testing runs at the Stennis A-complex. Key telemetry channels are chamber pressure, turbopump speed, mixture ratio, nozzle wall temperature and vibration.','archimedes,methane,engine,neutron','Propulsion'),
(5,'Hot Fire Acceptance Procedure','Procedures','All',
 'Every engine completes an acceptance hot fire before delivery. The run covers startup, a mainstage dwell, a throttle transient and shutdown. Acceptance requires chamber pressure, thrust and mixture ratio inside limits with no fault codes. A failed acceptance triggers a failure report and supplier corrective action before the unit re-enters the flow.','hot fire,acceptance,procedure','Propulsion Test'),
(6,'Engine Overtemperature Troubleshooting','Troubleshooting','All',
 'Nozzle wall temperature above the acceptance band or rising vibration during mainstage indicates injector damage, cooling channel blockage or mixture ratio excursion. Steps: review telemetry for the throttle segment, compare against the last two hot fires of the same unit, inspect the injector, and repeat acceptance after corrective work.','temperature,vibration,troubleshooting','Propulsion Test'),
(7,'Composite Tank Inspection Procedure','Procedures','All',
 'Carbon composite propellant tanks are inspected with ultrasound after cure and again before integration. Any delamination above the allowable size is a nonconformance. Tanks also complete a proof pressure test. Supplier quality rating and defect rate should be checked when a batch shows repeat findings.','tank,composite,inspection','Quality'),
(8,'Flight Readiness Review Checklist','Procedures','All',
 'The flight readiness review confirms the vehicle, range, payload and weather are go. It covers open nonconformances, residual risk, trajectory, collision avoidance, range safety and customer payload status. All critical anomalies must be closed or formally accepted before launch.','frr,readiness,checklist','Mission Management'),
(9,'Booster Recovery Operations','Procedures','Electron',
 'Electron first stage recovery uses a parachute and ocean splashdown, followed by retrieval and return to Auckland for inspection and refurbishment. Recovery is attempted only when the trajectory, weather and ship availability allow it. Post-recovery inspection sets the remaining cycle life of the recovered hardware.','recovery,reuse,refurbishment','Launch Services'),
(10,'Payload Integration and Interface Control','Procedures','All',
 'Payload integration follows the interface control document for mechanical, electrical and environmental interfaces. Separation systems and the Curie kick stage are verified in a functional test before fairing closeout. Any interface change after the critical design review needs customer concurrence.','payload,integration,icd','Payload Integration'),
(11,'ITAR and Export Compliance','Safety and Compliance','All',
 'Technical data on vehicles, engines and mission performance is controlled. Suppliers supporting controlled hardware must be ITAR registered. Customer deliverables such as telemetry and post-flight reports are reviewed by export compliance before release to international customers.','itar,export,compliance','Compliance'),
(12,'Launch Weather Constraints','Procedures','All',
 'Launch commit criteria cover ground winds, upper level winds, lightning, precipitation and cloud cover, and differ by site. Mahia, Wallops and Kodiak have distinct seasonal weather risk. Weather holds are recorded as anomalies with the delay days they cause.','weather,constraints,range','Launch Services'),
(13,'Range Safety and Flight Termination','Safety and Compliance','All',
 'Every mission carries an autonomous flight termination system. Range safety approves the trajectory and destruct lines before the flight readiness review. Any change to the trajectory after approval requires a delta review.','range safety,flight termination','Flight Safety'),
(14,'Nonconformance and Anomaly Management','Procedures','All',
 'Anomalies are classified Critical, High, Medium or Low and tagged with a phase: production test, integration, countdown, flight or recovery. Critical anomalies stop the flow until dispositioned. Schedule impact days are recorded so mission delay drivers can be analyzed.','anomaly,nonconformance,mrb','Quality'),
(15,'Supplier Quality Management','Procedures','All',
 'Suppliers are rated on quality and delivery. A supplier whose quality rating drops, whose defect rate in parts per million rises, or who becomes the single source for a part moves to heightened surveillance. Single source suppliers carry higher procurement risk and should be flagged in customer and mission reviews.','supplier,quality,single source','Procurement'),
(16,'Telemetry Dropout Troubleshooting','Troubleshooting','All',
 'S-band or telemetry dropouts during countdown are usually ground segment issues: antenna pointing, frequency coordination or interference. Confirm vehicle state is nominal, switch to the backup link and record the event. Recurring dropouts at one site point to ground equipment rather than the vehicle.','telemetry,dropout,ground segment','Avionics'),
(17,'Mission Operations and Portal Adoption','Customer Success','Space Systems',
 'Rocket Lab mission operations runs spacecraft contacts, command uplink and data downlink for customer satellites. Daily metrics cover active spacecraft, ground contacts, data downlinked, command success and the share of contacts executed automatically. Portal logins show customer adoption.','mission operations,portal,spacecraft','Space Systems'),
(18,'Customer Success Playbook: Onboarding','Customer Success','All',
 'The first months set the relationship. Milestones: kickoff and mission requirements baseline, payload interface freeze, integration readiness review, launch, and a post-flight value review. Assign a named mission manager and customer success manager and track time to first launch.','onboarding,customer success','Customer Success'),
(19,'Customer Success Playbook: At-Risk Accounts','Customer Success','All',
 'Warning signs: mission delays accumulating, critical anomalies touching the customer hardware, falling command success, detractor NPS, late invoice payments and negative interaction sentiment. Recovery: executive sponsor call, joint root cause review, dated remediation plan and weekly status until the health score recovers.','at risk,churn,recovery','Customer Success'),
(20,'Customer Success Playbook: Renewals','Customer Success','All',
 'Start renewal planning 180 days before contract end. Deliver a value review with launch reliability and mission operations performance, then the renewal proposal. Accounts with high churn risk or declining usage need a recovery plan before the proposal goes out.','renewal,contracts','Customer Success'),
(21,'Customer Success Playbook: Expansion','Customer Success','All',
 'Expansion signals: high mission operations automation, promoter NPS, rising spacecraft count and requests for additional launches or Neutron capacity. Paths include additional Electron launches, a Neutron upgrade, spacecraft and component supply, and mission operations subscriptions.','expansion,upsell','Customer Success'),
(22,'Predictive Maintenance for Flight Hardware','Procedures','All',
 'Remaining useful life in cycles is estimated from qualified life, cycles used, inspection findings and engine telemetry such as vibration and nozzle temperature. Hardware past most of its qualified life should be scheduled for replacement or requalification. Hardware already flown is expended and excluded from prediction.','predictive maintenance,rul,cycles','Quality'),
(23,'Photon and Space Systems Platforms','Vehicle Specifications','Space Systems',
 'Rocket Lab builds and operates spacecraft platforms including Photon and supports customer buses with components such as reaction wheels, star trackers and solar arrays, plus mission operations. Spacecraft status is tracked from awaiting launch through on-orbit nominal, degraded and decommissioned.','photon,spacecraft,space systems','Space Systems'),
(24,'Billing and Milestone Invoicing','Customer Success','All',
 'Contracts are billed monthly against milestones. Payment is net 30. Paid late, overdue and days late are tracked per invoice. Accounts with a rising share of late payments should be reviewed alongside their support experience and renewal date.','billing,invoices,payments','Finance');

-- ============================================================================
-- CUSTOMER 360
-- ============================================================================
CREATE OR REPLACE TEMPORARY TABLE _CUST_FLEET AS
SELECT p.CUSTOMER_ID, p.N, p.PROFILE, p.CHURN_DATE, p.CUTOFF_TS, p.RECENCY_EXP, s.IND,
    COUNT(m.MISSION_ID) AS MISSION_CNT,
    COUNT_IF(m.ACTUAL_LAUNCH_DATE IS NOT NULL) AS FLOWN_CNT,
    COALESCE(SUM(IFF(m.ACTUAL_LAUNCH_DATE IS NULL, m.CONTRACT_VALUE_USD, 0)), 0) AS BACKLOG_USD
FROM _CUST_PROFILE p
JOIN _CUST_SEED s ON s.N = p.N
LEFT JOIN MISSIONS m ON m.CUSTOMER_ID = p.CUSTOMER_ID
GROUP BY ALL;

INSERT INTO CONTACTS
SELECT
    'CON-' || LPAD((p.N * 4 + g.K)::VARCHAR, 5, '0'),
    p.CUSTOMER_ID,
    GET(ARRAY_CONSTRUCT('Michael','Jennifer','David','Laura','Kenji','Anita','Carlos','Sophie','Ahmed','Olivia'), MOD(p.N + g.K, 10))::VARCHAR
        || ' ' ||
    GET(ARRAY_CONSTRUCT('Anderson','Nakamura','Schmidt','Garcia','Okonkwo','Kowalski','Silva','Dubois','Singh','Johansson'), MOD(p.N * 3 + g.K, 10))::VARCHAR,
    GET(ARRAY_CONSTRUCT('VP of Space Programs','Mission Director','Payload Manager','Procurement Manager'), g.K)::VARCHAR,
    GET(ARRAY_CONSTRUCT('Economic Buyer','Champion','Mission Manager','Procurement'), g.K)::VARCHAR,
    LOWER('contact' || (p.N * 4 + g.K)::VARCHAR || '@' || REGEXP_REPLACE(s.CUSTOMER_NAME, '[^A-Za-z0-9]', '') || '.com'),
    g.K = 1
FROM _CUST_PROFILE p
JOIN _CUST_SEED s ON s.N = p.N
CROSS JOIN (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS K FROM TABLE(GENERATOR(ROWCOUNT => 4))) g;

-- Contract terms: 1-3 annual terms (K=0 is current), plus an expansion term for EXPANDING
CREATE OR REPLACE TEMPORARY TABLE _CUST_TERM AS
SELECT f.*,
    CASE f.PROFILE WHEN 'CHURNED' THEN f.CHURN_DATE
                   WHEN 'AT_RISK' THEN DATEADD(DAY, UNIFORM(20, 140, RANDOM()), CURRENT_DATE())
                   ELSE DATEADD(DAY, UNIFORM(30, 340, RANDOM()), CURRENT_DATE()) END AS LATEST_END,
    1 + MOD(FLOOR(f.N / 3), 3) AS N_TERMS,
    GREATEST(500000, f.BACKLOG_USD / 2 + f.FLOWN_CNT * 2500000 + UNIFORM(500000::FLOAT, 4000000::FLOAT, RANDOM())) AS FULL_ARR,
    CASE f.IND WHEN 'DEF' THEN 'HASTE' WHEN 'SCI' THEN 'Electron' WHEN 'SVC' THEN 'Space Systems'
               WHEN 'COM' THEN IFF(MOD(f.N, 2) = 0, 'Neutron', 'Electron') ELSE 'Electron' END AS PRODUCT_LINE
FROM _CUST_FLEET f;

INSERT INTO CONTRACTS
SELECT 'CTR-' || LPAD((ROW_NUMBER() OVER (ORDER BY START_DATE, CUSTOMER_ID) - 1)::VARCHAR, 5, '0'),
    CUSTOMER_ID, CONTRACT_TYPE, PRODUCT_LINE, START_DATE, END_DATE, ROUND(ARR_USD, 2),
    ROUND(ARR_USD * DATEDIFF(DAY, START_DATE, END_DATE) / 365, 2), LAUNCH_QUANTITY, AUTO_RENEW, STATUS
FROM (
    SELECT t.CUSTOMER_ID,
        CASE t.PRODUCT_LINE WHEN 'Space Systems' THEN 'Spacecraft and Components Supply'
                            WHEN 'HASTE' THEN 'Launch Services Agreement' ELSE 'Multi-Launch Agreement' END AS CONTRACT_TYPE,
        t.PRODUCT_LINE,
        DATEADD(DAY, -365 * (g.K + 1), t.LATEST_END) AS START_DATE,
        DATEADD(DAY, -365 * g.K - IFF(g.K = 0, 0, 1), t.LATEST_END) AS END_DATE,
        t.FULL_ARR * IFF(t.PROFILE = 'EXPANDING', 0.7, 1.0) * POW(0.9, g.K) AS ARR_USD,
        GREATEST(IFF(t.PRODUCT_LINE = 'Space Systems', 0, 1), ROUND(t.MISSION_CNT * POW(0.85, g.K) / t.N_TERMS))::INT AS LAUNCH_QUANTITY,
        MOD(t.N, 4) <> 0 AS AUTO_RENEW,
        CASE WHEN g.K > 0 THEN 'Renewed' WHEN t.PROFILE = 'CHURNED' THEN 'Churned' ELSE 'Active' END AS STATUS
    FROM _CUST_TERM t
    CROSS JOIN (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS K FROM TABLE(GENERATOR(ROWCOUNT => 3))) g
    WHERE g.K < t.N_TERMS
    UNION ALL
    SELECT t.CUSTOMER_ID, 'Expansion', 'Neutron',
        DATEADD(DAY, -1 * UNIFORM(30, 240, RANDOM()), CURRENT_DATE()), t.LATEST_END,
        t.FULL_ARR * 0.4, 0, TRUE, 'Active'
    FROM _CUST_TERM t WHERE t.PROFILE = 'EXPANDING'
);

UPDATE CUSTOMERS c SET
    CONTRACT_START_DATE = x.CUR_START,
    CONTRACT_END_DATE = x.CUR_END,
    CUSTOMER_SINCE = x.FIRST_START,
    LIFECYCLE_STAGE = CASE
        WHEN p.PROFILE = 'CHURNED' THEN 'Churned'
        WHEN DATEDIFF(DAY, x.FIRST_START, CURRENT_DATE()) < 200 THEN 'Onboarding'
        WHEN DATEDIFF(DAY, CURRENT_DATE(), x.CUR_END) <= 120 THEN 'Renewal Due'
        WHEN DATEDIFF(DAY, x.FIRST_START, CURRENT_DATE()) < 600 THEN 'Adopting'
        ELSE 'Mature' END
FROM (SELECT CUSTOMER_ID, MIN(START_DATE) AS FIRST_START,
             MAX(IFF(CONTRACT_TYPE <> 'Expansion', START_DATE, NULL)) AS CUR_START,
             MAX(END_DATE) AS CUR_END FROM CONTRACTS GROUP BY CUSTOMER_ID) x,
     _CUST_PROFILE p
WHERE x.CUSTOMER_ID = c.CUSTOMER_ID AND p.CUSTOMER_ID = c.CUSTOMER_ID;

INSERT INTO CUSTOMER_SPACECRAFT
SELECT
    'SC-' || LPAD(g.I::VARCHAR, 5, '0'),
    f.CUSTOMER_ID,
    GET(ARRAY_CONSTRUCT('Photon','Pioneer','Explorer','Lightning','Flatellite','Customer Bus'), MOD(g.I, 6))::VARCHAR
        || '-' || LPAD(g.I::VARCHAR, 3, '0'),
    GET(ARRAY_CONSTRUCT('Photon','Pioneer','Explorer','Lightning','Flatellite','Customer Bus'), MOD(g.I, 6))::VARCHAR,
    GET(ARRAY_CONSTRUCT('Star trackers and reaction wheels','Solar arrays','Mission operations subscription',
        'Complete spacecraft bus','S-band radio and flight computer'), MOD(g.I, 5))::VARCHAR,
    m.MISSION_ID,
    m.ACTUAL_LAUNCH_DATE,
    CASE WHEN m.ACTUAL_LAUNCH_DATE IS NULL THEN 'Awaiting Launch'
         WHEN f.PROFILE IN ('AT_RISK','CHURNED') AND MOD(g.I, 4) = 0 THEN 'On Orbit - Degraded'
         WHEN DATEDIFF(DAY, m.ACTUAL_LAUNCH_DATE, CURRENT_DATE()) > 1400 THEN 'Decommissioned'
         ELSE 'On Orbit - Nominal' END
FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS I, UNIFORM(0, 99, RANDOM()) AS CUST_N
      FROM TABLE(GENERATOR(ROWCOUNT => 250))) g
JOIN _CUST_FLEET f ON f.N = g.CUST_N
LEFT JOIN (SELECT CUSTOMER_ID, MISSION_ID, ACTUAL_LAUNCH_DATE,
                  ROW_NUMBER() OVER (PARTITION BY CUSTOMER_ID ORDER BY MISSION_ID) AS RN
           FROM MISSIONS) m ON m.CUSTOMER_ID = f.CUSTOMER_ID AND m.RN = 1 + MOD(g.I, GREATEST(f.MISSION_CNT, 1));

INSERT INTO INVOICES
SELECT 'INV-' || LPAD((ROW_NUMBER() OVER (ORDER BY y.INVOICE_DATE, y.CONTRACT_ID) - 1)::VARCHAR, 6, '0'),
    y.CONTRACT_ID, y.CUSTOMER_ID, y.INVOICE_DATE, y.DUE_DATE, y.AMOUNT_USD,
    IFF(y.PAY_DATE <= CURRENT_DATE(), y.PAY_DATE, NULL),
    CASE WHEN y.PAY_DATE <= CURRENT_DATE() THEN IFF(y.DAYS_LATE_RAW > 0, 'Paid Late', 'Paid')
         WHEN y.DUE_DATE < CURRENT_DATE() THEN 'Overdue' ELSE 'Open' END,
    CASE WHEN y.PAY_DATE <= CURRENT_DATE() THEN GREATEST(y.DAYS_LATE_RAW, 0)
         WHEN y.DUE_DATE < CURRENT_DATE() THEN DATEDIFF(DAY, y.DUE_DATE, CURRENT_DATE()) ELSE 0 END
FROM (
    SELECT x.*, DATEADD(DAY, x.DAYS_LATE_RAW, x.DUE_DATE) AS PAY_DATE
    FROM (
        SELECT ct.CONTRACT_ID, ct.CUSTOMER_ID,
            DATEADD(MONTH, g.M, ct.START_DATE) AS INVOICE_DATE,
            DATEADD(DAY, 30, DATEADD(MONTH, g.M, ct.START_DATE)) AS DUE_DATE,
            ROUND(ct.ARR_USD / 12, 2) AS AMOUNT_USD,
            IFF(UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) < CASE p.PROFILE WHEN 'CHURNED' THEN 0.45 WHEN 'AT_RISK' THEN 0.35 ELSE 0.06 END,
                UNIFORM(5, 70, RANDOM()), UNIFORM(-8, 0, RANDOM())) AS DAYS_LATE_RAW
        FROM CONTRACTS ct
        JOIN _CUST_PROFILE p ON p.CUSTOMER_ID = ct.CUSTOMER_ID
        CROSS JOIN (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS M FROM TABLE(GENERATOR(ROWCOUNT => 12))) g
        WHERE DATEADD(MONTH, g.M, ct.START_DATE) < ct.END_DATE
          AND DATEADD(MONTH, g.M, ct.START_DATE) <= CURRENT_DATE()
    ) x
) y;

INSERT INTO SUPPORT_TICKETS
SELECT 'TKT-' || LPAD((ROW_NUMBER() OVER (ORDER BY z.OPENED_AT) - 1)::VARCHAR, 6, '0'),
    z.CUSTOMER_ID, z.CONTACT_ID, z.MISSION_ID, z.CATEGORY, z.PRIORITY, z.CHANNEL, z.SUBJECT, z.DESCRIPTION,
    IFF(z.IS_CLOSED, 'Closed', 'Open'), z.OPENED_AT,
    IFF(z.IS_CLOSED, DATEADD(MINUTE, ROUND(z.RES_HOURS * 60)::INT, z.OPENED_AT), NULL),
    IFF(z.IS_CLOSED, ROUND(z.RES_HOURS, 1), NULL),
    IFF(z.IS_CLOSED, z.RES_HOURS <= z.SLA_HOURS, NULL),
    IFF(z.IS_CLOSED, IFF(z.PROFILE IN ('AT_RISK','CHURNED'), UNIFORM(1, 3, RANDOM()), UNIFORM(4, 5, RANDOM())), NULL),
    GET(ARRAY_CONSTRUCT('Priya Raman','Kevin Walsh','Aisha Bello','Marco Ricci','Sven Larsen','Julia Moreau'), MOD(z.K, 6))::VARCHAR
FROM (
    SELECT y.*,
        CASE y.PRIORITY WHEN 'Critical' THEN 8 WHEN 'High' THEN 24 WHEN 'Medium' THEN 72 ELSE 120 END AS SLA_HOURS,
        DATEADD(MINUTE, ROUND(y.RES_HOURS * 60)::INT, y.OPENED_AT) < LEAST(y.CUTOFF_TS, CURRENT_TIMESTAMP()::TIMESTAMP_NTZ) AS IS_CLOSED
    FROM (
        SELECT x.*,
            CASE x.PRIORITY WHEN 'Critical' THEN UNIFORM(2::FLOAT, 16::FLOAT, RANDOM()) WHEN 'High' THEN UNIFORM(4::FLOAT, 40::FLOAT, RANDOM())
                            WHEN 'Medium' THEN UNIFORM(8::FLOAT, 100::FLOAT, RANDOM()) ELSE UNIFORM(12::FLOAT, 160::FLOAT, RANDOM()) END
                * IFF(x.PROFILE IN ('AT_RISK','CHURNED'), 2.2, 1.0) AS RES_HOURS,
            GET(ARRAY_CONSTRUCT('Payload Integration','Launch Schedule','Mission Operations','Spacecraft Anomaly','Ground Segment',
                'Documentation','Export Compliance','Billing'), x.C)::VARCHAR AS CATEGORY,
            GET(ARRAY_CONSTRUCT('Payload fit check discrepancy','Launch date slip request','Contact scheduling conflict',
                'On-orbit anomaly support','Ground station pass failed','Document delivery delay','Export license question',
                'Invoice does not match contract'), x.C)::VARCHAR AS SUBJECT,
            'Customer ' || x.CUSTOMER_ID || ' reported: ' || GET(ARRAY_CONSTRUCT(
                'the payload mechanical interface does not match the latest revision of the interface control document.',
                'the committed launch date moved and the downstream mission timeline is now at risk.',
                'automated contact scheduling produced overlapping passes for two spacecraft.',
                'a spacecraft is showing degraded power and needs anomaly support from the mission operations team.',
                'a scheduled ground station pass failed and data was not downlinked.',
                'the post-flight report and telemetry package have not been delivered.',
                'clarification is needed on the export classification of the telemetry deliverable.',
                'the latest invoice does not match the contracted launch quantity.'), x.C)::VARCHAR
            || IFF(x.PROFILE IN ('AT_RISK','CHURNED'), ' This is a repeat issue and leadership is escalating.', '') AS DESCRIPTION
        FROM (
            SELECT b.*,
                CASE WHEN b.P_U < IFF(b.PROFILE IN ('AT_RISK','CHURNED'), 0.22, 0.06) THEN 'Critical'
                     WHEN b.P_U < IFF(b.PROFILE IN ('AT_RISK','CHURNED'), 0.55, 0.28) THEN 'High'
                     WHEN b.P_U < 0.78 THEN 'Medium' ELSE 'Low' END AS PRIORITY,
                'CON-' || LPAD((b.N * 4 + MOD(b.K, 4))::VARCHAR, 5, '0') AS CONTACT_ID
            FROM (
                SELECT f.CUSTOMER_ID, f.N, f.PROFILE, f.CUTOFF_TS, SEQ4() AS K,
                    UNIFORM(0, 7, RANDOM()) AS C,
                    UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) AS P_U,
                    GET(ARRAY_CONSTRUCT('Mission Portal','Email','Phone','Mission Manager'), UNIFORM(0, 3, RANDOM()))::VARCHAR AS CHANNEL,
                    (SELECT MIN(MISSION_ID) FROM MISSIONS WHERE CUSTOMER_ID = f.CUSTOMER_ID) AS MISSION_ID,
                    DATEADD(MINUTE, -1 * ROUND(500000 * POW(UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()), f.RECENCY_EXP))::INT, f.CUTOFF_TS) AS OPENED_AT,
                    UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) AS KEEP_U
                FROM _CUST_FLEET f CROSS JOIN TABLE(GENERATOR(ROWCOUNT => 40))
            ) b
        ) x
        WHERE x.KEEP_U < CASE x.PROFILE WHEN 'AT_RISK' THEN 0.85 WHEN 'CHURNED' THEN 0.7
                                        WHEN 'EXPANDING' THEN 0.45 ELSE 0.35 END
    ) y
) z;

INSERT INTO SURVEYS
SELECT 'SRV-' || LPAD((x.N * 12 + x.K)::VARCHAR, 5, '0'), x.CUSTOMER_ID,
    'CON-' || LPAD((x.N * 4 + MOD(x.K, 4))::VARCHAR, 5, '0'),
    IFF(MOD(x.K, 2) = 0, 'NPS', 'CSAT'),
    IFF(MOD(x.K, 2) = 0, ROUND(x.S), LEAST(5, GREATEST(1, ROUND(1 + x.S * 0.4))))::INT,
    CASE WHEN MOD(x.K, 2) = 0 THEN CASE WHEN ROUND(x.S) >= 9 THEN 'Promoter' WHEN ROUND(x.S) >= 7 THEN 'Passive' ELSE 'Detractor' END
         ELSE CASE WHEN ROUND(1 + x.S * 0.4) >= 4 THEN 'Satisfied' WHEN ROUND(1 + x.S * 0.4) >= 3 THEN 'Neutral' ELSE 'Dissatisfied' END END,
    CASE WHEN x.S >= 8.5 THEN GET(ARRAY_CONSTRUCT('Reliable launch cadence and a responsive mission team.','Exactly the ride to orbit we needed.','We plan to fly again next year.','Mission operations has been excellent.','Strong technical team throughout integration.','Best small launch partner we have used.'), MOD(x.N + x.K, 6))
         WHEN x.S >= 6.5 THEN GET(ARRAY_CONSTRUCT('Good vehicle, schedule slipped more than expected.','Integration went well but documentation was slow.','Generally happy, portal could be easier.','Solid performance, communication could improve.','Met the orbit, late on deliverables.','Useful mission operations tools, still learning them.'), MOD(x.N + x.K, 6))
         ELSE GET(ARRAY_CONSTRUCT('Repeated schedule slips are hurting our constellation plan.','Support is slow when anomalies hit our spacecraft.','We are not seeing the responsiveness we were promised.','Too many open issues at flight readiness.','Considering other launch providers at renewal.','Billing disputes and late reports are frustrating.'), MOD(x.N + x.K, 6)) END::VARCHAR,
    x.RESPONSE_DATE
FROM (
    SELECT f.N, f.CUSTOMER_ID, g.K,
        DATEADD(DAY, -1 * (30 * g.K + UNIFORM(0, 20, RANDOM())), f.CUTOFF_TS::DATE) AS RESPONSE_DATE,
        LEAST(10, GREATEST(0, CASE f.PROFILE
            WHEN 'HEALTHY' THEN UNIFORM(6.5::FLOAT, 10::FLOAT, RANDOM())
            WHEN 'EXPANDING' THEN UNIFORM(7.5::FLOAT, 10::FLOAT, RANDOM())
            WHEN 'AT_RISK' THEN 3.0 + g.K * 0.45 + UNIFORM(-1.5::FLOAT, 1.5::FLOAT, RANDOM())
            ELSE 2.0 + g.K * 0.45 + UNIFORM(-1.5::FLOAT, 1.5::FLOAT, RANDOM()) END)) AS S
    FROM _CUST_FLEET f
    CROSS JOIN (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS K FROM TABLE(GENERATOR(ROWCOUNT => 12))) g
) x;

-- Daily mission operations usage, 365 days per customer ending at cutoff
INSERT INTO MISSION_OPS_USAGE_DAILY
SELECT x.CUSTOMER_ID, x.USAGE_DATE,
    GREATEST(0, ROUND(x.BASE_SC * x.F))::INT,
    GREATEST(0, ROUND(x.BASE_SC * x.F * UNIFORM(2::FLOAT, 6::FLOAT, RANDOM())))::INT,
    ROUND(GREATEST(0, x.BASE_SC * x.F * UNIFORM(5::FLOAT, 40::FLOAT, RANDOM())), 2),
    ROUND(LEAST(100, GREATEST(70, x.CMD)), 2),
    ROUND(LEAST(100, GREATEST(10, x.AUTO)), 2),
    GREATEST(0, ROUND(x.F * UNIFORM(0::FLOAT, 8::FLOAT, RANDOM())))::INT
FROM (
    SELECT y.*, LEAST(1.2, GREATEST(0, y.F0)) AS F
    FROM (
        SELECT f.CUSTOMER_ID, GREATEST(1, ROUND(f.FLOWN_CNT / 2)) AS BASE_SC,
            DATEADD(DAY, -1 * g.D, f.CUTOFF_TS::DATE) AS USAGE_DATE,
            (365 - g.D) / 365.0 AS T,
            CASE f.PROFILE
                WHEN 'HEALTHY' THEN 0.9
                WHEN 'EXPANDING' THEN 0.5 + 0.5 * ((365 - g.D) / 365.0)
                WHEN 'AT_RISK' THEN 1.0 - 0.6 * ((365 - g.D) / 365.0)
                ELSE 0.95 - 0.75 * ((365 - g.D) / 365.0) END
                + UNIFORM(-0.1::FLOAT, 0.1::FLOAT, RANDOM()) AS F0,
            CASE f.PROFILE WHEN 'HEALTHY' THEN UNIFORM(96::FLOAT, 99.5::FLOAT, RANDOM())
                           WHEN 'EXPANDING' THEN UNIFORM(95::FLOAT, 99::FLOAT, RANDOM())
                           ELSE 99 - 8 * ((365 - g.D) / 365.0) + UNIFORM(-1::FLOAT, 1::FLOAT, RANDOM()) END AS CMD,
            CASE f.PROFILE WHEN 'EXPANDING' THEN 40 + 45 * ((365 - g.D) / 365.0)
                           WHEN 'HEALTHY' THEN UNIFORM(60::FLOAT, 90::FLOAT, RANDOM())
                           ELSE 70 - 40 * ((365 - g.D) / 365.0) END AS AUTO
        FROM _CUST_FLEET f
        CROSS JOIN (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS D FROM TABLE(GENERATOR(ROWCOUNT => 365))) g
    ) y
) x;

INSERT INTO OPPORTUNITIES
SELECT 'OPP-' || LPAD((ROW_NUMBER() OVER (ORDER BY z.CREATED_DATE, z.CUSTOMER_ID) - 1)::VARCHAR, 5, '0'),
    z.CUSTOMER_ID, z.CUSTOMER_NAME || ' - ' || z.OPP_TYPE || ' - ' || z.PRODUCT_LINE,
    z.OPP_TYPE, z.PRODUCT_LINE, z.STAGE, z.AMOUNT_USD,
    CASE z.STAGE WHEN 'Closed Won' THEN 100 WHEN 'Closed Lost' THEN 0 ELSE z.OPEN_PROB END,
    z.CREATED_DATE, z.CLOSE_DATE, z.OWNER,
    z.STAGE IN ('Closed Won','Closed Lost'), z.STAGE = 'Closed Won',
    IFF(z.STAGE = 'Closed Lost', z.LOSS_REASON, NULL)
FROM (
    SELECT y.*,
        CASE WHEN y.OPP_TYPE = 'Renewal' THEN
                CASE WHEN y.PROFILE = 'CHURNED' THEN 'Closed Lost'
                     WHEN y.PROFILE = 'AT_RISK' THEN IFF(y.U < 0.5, 'Negotiation', 'Proposal')
                     WHEN DATEDIFF(DAY, CURRENT_DATE(), y.LATEST_END) <= 180 THEN IFF(y.U < 0.6, 'Commit', 'Negotiation')
                     ELSE 'Closed Won' END
             ELSE CASE WHEN y.U < CASE y.PROFILE WHEN 'EXPANDING' THEN 0.65 WHEN 'HEALTHY' THEN 0.25 ELSE 0.05 END THEN 'Closed Won'
                       WHEN y.U < CASE y.PROFILE WHEN 'EXPANDING' THEN 0.75 WHEN 'HEALTHY' THEN 0.45 ELSE 0.55 END THEN 'Closed Lost'
                       WHEN y.PROFILE = 'CHURNED' THEN 'Closed Lost'
                       ELSE GET(ARRAY_CONSTRUCT('Discovery','Qualification','Proposal','Negotiation','Commit'), MOD(y.K, 4))::VARCHAR END
        END AS STAGE,
        IFF(y.OPP_TYPE = 'Renewal', y.LATEST_END,
            IFF(y.PROFILE = 'CHURNED', y.CUTOFF_TS::DATE, DATEADD(DAY, UNIFORM(20, 220, RANDOM()), CURRENT_DATE()))) AS CLOSE_DATE,
        DATEADD(DAY, -1 * UNIFORM(40, 400, RANDOM()), LEAST(y.LATEST_END, CURRENT_DATE())) AS CREATED_DATE,
        IFF(y.OPP_TYPE = 'Renewal', y.FULL_ARR, GREATEST(250000, ROUND(y.FULL_ARR * UNIFORM(0.2::FLOAT, 0.8::FLOAT, RANDOM()), -3))) AS AMOUNT_USD,
        IFF(y.OPP_TYPE = 'Renewal', IFF(y.PROFILE = 'AT_RISK', 35, 80), IFF(y.PROFILE = 'EXPANDING', 70, 30)) AS OPEN_PROB,
        GET(ARRAY_CONSTRUCT('Budget cuts','Moved to competitor','Schedule reliability concerns','Program cancelled','Lost to another launch provider'), MOD(y.N, 5))::VARCHAR AS LOSS_REASON
    FROM (
        SELECT t.CUSTOMER_ID, t.N, t.PROFILE, t.CUTOFF_TS, t.LATEST_END, t.FULL_ARR, t.PRODUCT_LINE,
            c.CUSTOMER_NAME, c.ACCOUNT_MANAGER AS OWNER, g.K,
            IFF(g.K = 0, 'Renewal', GET(ARRAY_CONSTRUCT('Additional Launches','Neutron Upgrade','Spacecraft Build','Components','Mission Operations'), MOD(t.N + g.K, 5))::VARCHAR) AS OPP_TYPE,
            UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) AS U,
            UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) AS KEEP_U
        FROM _CUST_TERM t
        JOIN CUSTOMERS c ON c.CUSTOMER_ID = t.CUSTOMER_ID
        CROSS JOIN (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS K FROM TABLE(GENERATOR(ROWCOUNT => 5))) g
    ) y
    WHERE y.K = 0 OR y.KEEP_U < CASE y.PROFILE WHEN 'EXPANDING' THEN 0.9 WHEN 'HEALTHY' THEN 0.5 ELSE 0.35 END
) z;

INSERT INTO INTERACTIONS
SELECT 'INT-' || LPAD((ROW_NUMBER() OVER (ORDER BY w.INTERACTION_DATE) - 1)::VARCHAR, 6, '0'),
    w.CUSTOMER_ID, w.CONTACT_ID, w.ITYPE, w.INTERACTION_DATE,
    IFF(MOD(w.K, 2) = 0, c.ACCOUNT_MANAGER, c.CSM_NAME),
    w.ITYPE || ' - ' || c.CUSTOMER_NAME,
    CASE w.EP
        WHEN 'HEALTHY' THEN 'Productive ' || LOWER(w.ITYPE) || ' with ' || c.CUSTOMER_NAME || '. Launch cadence and mission operations performance are meeting expectations and the customer is satisfied with communication from the mission team.'
        WHEN 'EXPANDING' THEN c.CUSTOMER_NAME || ' wants to grow the program: additional launches and interest in Neutron and spacecraft supply were discussed, and a proposal was requested.'
        WHEN 'AT_RISK' THEN 'Difficult ' || LOWER(w.ITYPE) || ' with ' || c.CUSTOMER_NAME || '. Schedule slips and slow anomaly support were raised, and the customer questioned the value delivered ahead of renewal.'
        ELSE c.CUSTOMER_NAME || ' confirmed they will not continue. Reasons cited: schedule reliability, responsiveness during spacecraft anomalies and cost.' END,
    CASE w.EP WHEN 'HEALTHY' THEN IFF(w.S_U < 0.7, 'Positive', 'Neutral') WHEN 'EXPANDING' THEN IFF(w.S_U < 0.85, 'Positive', 'Neutral')
              WHEN 'AT_RISK' THEN IFF(w.S_U < 0.7, 'Negative', 'Neutral') ELSE IFF(w.S_U < 0.85, 'Negative', 'Neutral') END,
    CASE w.EP WHEN 'HEALTHY' THEN 'Schedule the next review and share the manifest update.'
              WHEN 'EXPANDING' THEN 'Send the expansion proposal and engage the account executive.'
              WHEN 'AT_RISK' THEN 'Assign an executive sponsor and deliver a remediation plan.'
              ELSE 'Confirm the offboarding timeline and document the loss reasons.' END
FROM (
    SELECT v.*, IFF(v.PROFILE IN ('AT_RISK','CHURNED') AND v.DAYS_BEFORE > 220, 'HEALTHY', v.PROFILE) AS EP,
        GET(ARRAY_CONSTRUCT('QBR','Check-in Call','Email','Site Visit','Executive Briefing','Mission Readiness Review','Escalation Call'), MOD(v.K, 7))::VARCHAR AS ITYPE,
        'CON-' || LPAD((v.N * 4 + MOD(v.K, 4))::VARCHAR, 5, '0') AS CONTACT_ID,
        DATEADD(DAY, -1 * v.DAYS_BEFORE, v.CUTOFF_TS::DATE) AS INTERACTION_DATE
    FROM (
        SELECT t.CUSTOMER_ID, t.N, t.PROFILE, t.CUTOFF_TS, d.K,
            UNIFORM(0, 400, RANDOM()) AS DAYS_BEFORE,
            UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) AS S_U,
            UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) AS KEEP_U
        FROM _CUST_TERM t CROSS JOIN (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS K FROM TABLE(GENERATOR(ROWCOUNT => 30))) d
    ) v
    WHERE v.KEEP_U < CASE v.PROFILE WHEN 'EXPANDING' THEN 0.8 WHEN 'AT_RISK' THEN 0.75 WHEN 'CHURNED' THEN 0.55 ELSE 0.6 END
) w
JOIN CUSTOMERS c ON c.CUSTOMER_ID = w.CUSTOMER_ID;

-- ============================================================================
-- INTEGRITY CHECKS (all must return 0)
-- ============================================================================
SELECT 'missions_without_customer' AS CHECK_NAME, COUNT(*) AS N FROM MISSIONS m LEFT JOIN CUSTOMERS c ON c.CUSTOMER_ID = m.CUSTOMER_ID WHERE c.CUSTOMER_ID IS NULL
UNION ALL SELECT 'components_bad_vehicle', COUNT(*) FROM COMPONENTS c LEFT JOIN VEHICLES v ON v.VEHICLE_ID = c.VEHICLE_ID WHERE v.VEHICLE_ID IS NULL
UNION ALL SELECT 'failures_without_test', COUNT(*) FROM TEST_FAILURE_REPORTS r LEFT JOIN TEST_RESULTS t ON t.TEST_ID = r.TEST_ID WHERE t.TEST_ID IS NULL
UNION ALL SELECT 'anomalies_resolved_before_reported', COUNT(*) FROM ANOMALIES WHERE RESOLVED_AT < REPORTED_AT
UNION ALL SELECT 'customers_missing_lifecycle', COUNT(*) FROM CUSTOMERS WHERE LIFECYCLE_STAGE IS NULL
UNION ALL SELECT 'invoices_without_contract', COUNT(*) FROM INVOICES i LEFT JOIN CONTRACTS c ON c.CONTRACT_ID = i.CONTRACT_ID WHERE c.CONTRACT_ID IS NULL;
