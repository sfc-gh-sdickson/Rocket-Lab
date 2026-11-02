/*=============================================================================
  Rocket Lab Intelligence Agent
  Step 2: Table Definitions

  Execution Order: 2 of 9
  Description: Creates the RAW tables. The original Rocket Lab structures
               (divisions, employees, suppliers, vehicles, missions,
               components, test results, mission documents, test failure
               reports) are kept and extended, plus:
                 - Fleet: launch sites, engine telemetry, maintenance and
                   refurbishment records, anomalies, knowledge base
                 - Customer 360: customers, contacts, spacecraft, contracts,
                   invoices, support tickets, surveys, mission operations
                   usage, opportunities, interactions
               Every table and column carries a COMMENT for Cortex Analyst.
=============================================================================*/

USE DATABASE ROCKET_LAB_INTELLIGENCE;
USE SCHEMA RAW;
USE WAREHOUSE ROCKET_LAB_WH;

-- ============================================================================
-- ORGANIZATION
-- ============================================================================
CREATE OR REPLACE TABLE DIVISIONS (
    DIVISION_ID         VARCHAR(20)     NOT NULL COMMENT 'Division identifier (DIV-01 format)',
    DIVISION_NAME       VARCHAR(100)    NOT NULL COMMENT 'Division name: Launch Services, Space Systems, Propulsion, Avionics & Software, Manufacturing, National Security',
    DIVISION_CODE       VARCHAR(10)     NOT NULL COMMENT 'Short division code (LS, SS, PR, AV, MF, NS)',
    LOCATION            VARCHAR(100)    NOT NULL COMMENT 'Primary site of the division',
    HEAD_COUNT          INTEGER                  COMMENT 'Number of active employees in the division',
    ANNUAL_BUDGET_USD   NUMBER(15,2)             COMMENT 'Annual operating budget in US dollars',
    CONSTRAINT PK_DIVISIONS PRIMARY KEY (DIVISION_ID)
) COMMENT = 'Rocket Lab business divisions';

CREATE OR REPLACE TABLE EMPLOYEES (
    EMPLOYEE_ID         VARCHAR(20)     NOT NULL COMMENT 'Employee identifier (EMP-00000 format)',
    FULL_NAME           VARCHAR(100)    NOT NULL COMMENT 'Employee full name',
    EMAIL               VARCHAR(150)    NOT NULL COMMENT 'Work email address',
    JOB_TITLE           VARCHAR(100)    NOT NULL COMMENT 'Job title, for example Propulsion Test Engineer or Quality Inspector',
    DEPARTMENT          VARCHAR(100)    NOT NULL COMMENT 'Department within the division',
    DIVISION_ID         VARCHAR(20)     NOT NULL COMMENT 'Division the employee belongs to. Joins to DIVISIONS',
    HIRE_DATE           DATE            NOT NULL COMMENT 'Date the employee was hired',
    SECURITY_CLEARANCE  VARCHAR(20)     NOT NULL COMMENT 'Clearance level: None, Confidential, Secret or Top Secret',
    IS_ACTIVE           BOOLEAN         NOT NULL COMMENT 'TRUE if currently employed',
    CONSTRAINT PK_EMPLOYEES PRIMARY KEY (EMPLOYEE_ID)
) COMMENT = 'Rocket Lab employees including inspectors, engineers, account managers and customer success managers';

-- ============================================================================
-- SUPPLY CHAIN
-- ============================================================================
CREATE OR REPLACE TABLE SUPPLIERS (
    SUPPLIER_ID          VARCHAR(20)    NOT NULL COMMENT 'Supplier identifier (SUP-0000 format)',
    SUPPLIER_NAME        VARCHAR(150)   NOT NULL COMMENT 'Supplier company name',
    SUPPLIER_TYPE        VARCHAR(50)    NOT NULL COMMENT 'Supplier type: Carbon Composites, Electronics, Precision Machining, Additive Manufacturing, Battery Cells, Propellants & Gases, Test Services or Optics',
    COUNTRY              VARCHAR(50)    NOT NULL COMMENT 'Supplier country',
    SUPPLIER_SINCE       DATE           NOT NULL COMMENT 'Date the supplier was qualified',
    QUALITY_RATING       NUMBER(3,2)    NOT NULL COMMENT 'Supplier quality rating from audits, 1.00 to 5.00 (higher is better)',
    DELIVERY_RATING      NUMBER(3,2)    NOT NULL COMMENT 'Supplier delivery rating, 1.00 to 5.00 (higher is better)',
    ON_TIME_DELIVERY_PCT NUMBER(5,2)    NOT NULL COMMENT 'Percentage of purchase orders delivered on time in the last 12 months',
    DEFECT_RATE_PPM      INTEGER        NOT NULL COMMENT 'Incoming inspection defect rate in parts per million',
    RISK_SCORE           NUMBER(3,2)    NOT NULL COMMENT 'Procurement risk score, 0.00 (low) to 9.99 (high), from financial, geographic and single-source risk',
    TOTAL_SPEND_USD      NUMBER(15,2)   NOT NULL COMMENT 'Spend with the supplier in the last 12 months, US dollars',
    IS_SINGLE_SOURCE     BOOLEAN        NOT NULL COMMENT 'TRUE if the supplier is the only qualified source for its parts',
    IS_ITAR_REGISTERED   BOOLEAN        NOT NULL COMMENT 'TRUE if the supplier is ITAR registered',
    STATUS               VARCHAR(20)    NOT NULL COMMENT 'Supplier status: Active, Probation or Inactive',
    CONSTRAINT PK_SUPPLIERS PRIMARY KEY (SUPPLIER_ID)
) COMMENT = 'Qualified suppliers for launch vehicle and spacecraft hardware';

-- ============================================================================
-- LAUNCH FLEET
-- ============================================================================
CREATE OR REPLACE TABLE LAUNCH_SITES (
    SITE_ID             VARCHAR(20)     NOT NULL COMMENT 'Launch site identifier (LC-1A, LC-1B, LC-2, LC-3, LC-4)',
    SITE_NAME           VARCHAR(150)    NOT NULL COMMENT 'Launch complex name',
    LOCATION            VARCHAR(150)    NOT NULL COMMENT 'Physical location of the launch complex',
    COUNTRY             VARCHAR(50)     NOT NULL COMMENT 'Country of the launch complex',
    LATITUDE            FLOAT           NOT NULL COMMENT 'Latitude in decimal degrees',
    LONGITUDE           FLOAT           NOT NULL COMMENT 'Longitude in decimal degrees',
    SUPPORTED_VEHICLES  VARCHAR(100)    NOT NULL COMMENT 'Vehicles the site supports: Electron, HASTE, Neutron',
    STATUS              VARCHAR(30)     NOT NULL COMMENT 'Site status: Operational, Commissioning or Under Construction',
    CONSTRAINT PK_LAUNCH_SITES PRIMARY KEY (SITE_ID)
) COMMENT = 'Rocket Lab launch complexes: LC-1 Mahia New Zealand (pads A and B), LC-2 and LC-3 Wallops Island Virginia, LC-4 Kodiak Alaska (GHOST)';

CREATE OR REPLACE TABLE VEHICLES (
    VEHICLE_ID          VARCHAR(20)     NOT NULL COMMENT 'Vehicle identifier (VEH-000 format)',
    VEHICLE_NAME        VARCHAR(100)    NOT NULL COMMENT 'Vehicle tail name, for example Electron F-042, HASTE H-07, Neutron N-1 or Test Article TA-03',
    VEHICLE_TYPE        VARCHAR(30)     NOT NULL COMMENT 'Vehicle type: Electron (small orbital), HASTE (suborbital hypersonic test), Neutron (medium-lift reusable) or Test Article',
    SERIAL_NUMBER       VARCHAR(50)     NOT NULL COMMENT 'Manufacturing serial number',
    MANUFACTURING_DATE  DATE            NOT NULL COMMENT 'Date vehicle production started',
    STATUS              VARCHAR(30)     NOT NULL COMMENT 'Status: In Production, Integration, Ready for Launch, Flown, Recovered, Refurbishment, Lost, Active Test',
    STAGE_COUNT         INTEGER         NOT NULL COMMENT 'Number of stages (2 for Electron and Neutron, 1 for test articles)',
    ENGINE_COUNT        INTEGER         NOT NULL COMMENT 'Number of main engines (10 Rutherford on Electron/HASTE, 10 Archimedes on Neutron)',
    IS_REUSABLE_BOOSTER BOOLEAN         NOT NULL COMMENT 'TRUE if the first stage is designed or flown for recovery',
    REUSE_COUNT         INTEGER         NOT NULL COMMENT 'Number of times the first stage has been reflown',
    CONSTRAINT PK_VEHICLES PRIMARY KEY (VEHICLE_ID)
) COMMENT = 'Launch vehicles and qualification test articles: Electron, HASTE, Neutron';

CREATE OR REPLACE TABLE MISSIONS (
    MISSION_ID             VARCHAR(20)  NOT NULL COMMENT 'Mission identifier (MSN-0000 format)',
    MISSION_NUMBER         INTEGER      NOT NULL COMMENT 'Sequential mission number across all vehicles',
    MISSION_NAME           VARCHAR(150) NOT NULL COMMENT 'Mission name (Rocket Lab style)',
    VEHICLE_ID             VARCHAR(20)           COMMENT 'Assigned vehicle. NULL for backlog missions not yet assigned a vehicle. Joins to VEHICLES',
    VEHICLE_TYPE           VARCHAR(30)  NOT NULL COMMENT 'Vehicle type contracted: Electron, HASTE or Neutron',
    CUSTOMER_ID            VARCHAR(20)  NOT NULL COMMENT 'Customer that purchased the mission. Joins to CUSTOMERS',
    SITE_ID                VARCHAR(20)  NOT NULL COMMENT 'Launch site. Joins to LAUNCH_SITES',
    MISSION_TYPE           VARCHAR(50)  NOT NULL COMMENT 'Mission type: Dedicated Orbital, Rideshare, Constellation Deployment, Suborbital Hypersonic Test, Interplanetary, National Security',
    TARGET_ORBIT           VARCHAR(30)  NOT NULL COMMENT 'Target orbit: SSO, LEO, Mid-Inclination LEO, MEO, Lunar Transfer, Suborbital',
    PAYLOAD_COUNT          INTEGER      NOT NULL COMMENT 'Number of payloads deployed',
    PAYLOAD_MASS_KG        NUMBER(8,1)  NOT NULL COMMENT 'Total payload mass in kilograms',
    CONTRACT_VALUE_USD     NUMBER(15,2) NOT NULL COMMENT 'Launch price in US dollars',
    PLANNED_LAUNCH_DATE    DATE         NOT NULL COMMENT 'Launch date committed at contract signature or manifest baseline',
    ACTUAL_LAUNCH_DATE     DATE                  COMMENT 'Actual launch date. NULL if not launched yet',
    DELAY_DAYS             INTEGER               COMMENT 'Days between planned and actual launch. NULL if not launched',
    STATUS                 VARCHAR(30)  NOT NULL COMMENT 'Mission status: Scheduled, Payload Integration, Launch Ready, Success, Failure',
    WEATHER_RISK_SCORE     NUMBER(3,2)  NOT NULL COMMENT 'Seasonal weather risk at the site for the launch window, 0.00 to 1.00',
    TECHNICAL_RISK_SCORE   NUMBER(3,2)  NOT NULL COMMENT 'Engineering technical risk score for the mission, 0.00 to 1.00 (new payload interfaces, new vehicle, open nonconformances)',
    IS_FIRST_FLIGHT_CUSTOMER BOOLEAN    NOT NULL COMMENT 'TRUE if this is the customer''s first mission with Rocket Lab',
    RECOVERY_ATTEMPTED     BOOLEAN      NOT NULL COMMENT 'TRUE if booster recovery was attempted',
    BOOSTER_RECOVERED      BOOLEAN      NOT NULL COMMENT 'TRUE if the first stage was recovered from the ocean',
    CONSTRAINT PK_MISSIONS PRIMARY KEY (MISSION_ID)
) COMMENT = 'Launch manifest: completed Electron and HASTE missions since 2017 and the Electron, HASTE and Neutron backlog';

CREATE OR REPLACE TABLE COMPONENTS (
    COMPONENT_ID          VARCHAR(20)   NOT NULL COMMENT 'Component identifier (CMP-00000 format)',
    VEHICLE_ID            VARCHAR(20)   NOT NULL COMMENT 'Vehicle or test article the component is installed on. Joins to VEHICLES',
    SUPPLIER_ID           VARCHAR(20)   NOT NULL COMMENT 'Key sub-tier supplier for the component. Joins to SUPPLIERS',
    COMPONENT_TYPE        VARCHAR(50)   NOT NULL COMMENT 'Type: Rutherford Engine, Rutherford Vacuum Engine, Archimedes Engine, Archimedes Vacuum Engine, Battery Pack, Flight Computer, Composite Propellant Tank, Fairing, Curie Kick Stage, Stage Separation System, Recovery Parachute, Reaction Control System, Landing Leg',
    COMPONENT_NAME        VARCHAR(100)  NOT NULL COMMENT 'Component name including position, for example Rutherford Engine E3',
    BATCH_NUMBER          VARCHAR(30)   NOT NULL COMMENT 'Production batch number',
    MANUFACTURING_DATE    DATE          NOT NULL COMMENT 'Date the component was built',
    EXPECTED_LIFE_CYCLES  INTEGER       NOT NULL COMMENT 'Qualified life in cycles (hot-fires, flights, charge cycles or actuations)',
    CYCLES_USED           INTEGER       NOT NULL COMMENT 'Cycles accumulated to date',
    STATUS                VARCHAR(30)   NOT NULL COMMENT 'Condition: Operational, Degraded, Needs Replacement, Failed, or Flown (expended on a completed flight; excluded from predictive maintenance)',
    LAST_INSPECTION_DATE  DATE          NOT NULL COMMENT 'Date of the latest inspection',
    INSPECTION_RUL_CYCLES INTEGER       NOT NULL COMMENT 'Remaining useful life in cycles estimated by the inspector at the last inspection',
    CONSTRAINT PK_COMPONENTS PRIMARY KEY (COMPONENT_ID)
) COMMENT = 'Flight and test hardware tracked by serial number with cycle life and condition';

CREATE OR REPLACE TABLE TEST_RESULTS (
    TEST_ID          VARCHAR(20)    NOT NULL COMMENT 'Test identifier (TST-000000 format)',
    COMPONENT_ID     VARCHAR(20)    NOT NULL COMMENT 'Component tested. Joins to COMPONENTS',
    TEST_TYPE        VARCHAR(50)    NOT NULL COMMENT 'Test type: Hot Fire, Acceptance, Vibration, Thermal Vacuum, Pressure Proof, Functional, Wet Dress Rehearsal',
    TEST_FACILITY    VARCHAR(100)   NOT NULL COMMENT 'Facility: Long Beach Engine Test Complex, Auckland Production Complex, Stennis A-Complex, Wallops Integration Facility, Mahia LC-1 Pad',
    TEST_DATE        TIMESTAMP_NTZ  NOT NULL COMMENT 'Timestamp of the test',
    RESULT           VARCHAR(20)    NOT NULL COMMENT 'Result: Pass, Conditional Pass or Fail',
    MEASURED_VALUE   FLOAT          NOT NULL COMMENT 'Primary measured value for the test',
    LIMIT_VALUE      FLOAT          NOT NULL COMMENT 'Acceptance limit for the measured value',
    UNIT             VARCHAR(20)    NOT NULL COMMENT 'Unit of MEASURED_VALUE and LIMIT_VALUE',
    INSPECTOR_ID     VARCHAR(20)    NOT NULL COMMENT 'Quality inspector who signed off. Joins to EMPLOYEES',
    NOTES            VARCHAR(2000)           COMMENT 'Inspector notes',
    CONSTRAINT PK_TEST_RESULTS PRIMARY KEY (TEST_ID)
) COMMENT = 'Component and vehicle test results from engine hot-fires through acceptance and wet dress rehearsals';

CREATE OR REPLACE TABLE ENGINE_TELEMETRY (
    TELEMETRY_ID          VARCHAR(20)   NOT NULL COMMENT 'Telemetry sample identifier (TEL-0000000 format)',
    COMPONENT_ID          VARCHAR(20)   NOT NULL COMMENT 'Engine component that produced the sample. Joins to COMPONENTS',
    RECORDED_AT           TIMESTAMP_NTZ NOT NULL COMMENT 'Sample timestamp',
    ENGINE_MODEL          VARCHAR(30)   NOT NULL COMMENT 'Engine model: Rutherford (electric pump-fed, kerosene/LOX) or Archimedes (gas generator, methane/LOX)',
    TEST_PHASE            VARCHAR(30)   NOT NULL COMMENT 'Phase: Startup, Mainstage, Throttle, Shutdown',
    CHAMBER_PRESSURE_BAR  FLOAT         NOT NULL COMMENT 'Combustion chamber pressure in bar',
    THRUST_KN             FLOAT         NOT NULL COMMENT 'Measured thrust in kilonewtons',
    PUMP_SPEED_RPM        FLOAT         NOT NULL COMMENT 'Propellant pump speed in RPM (electric pump on Rutherford, turbopump on Archimedes)',
    BATTERY_VOLTAGE_V     FLOAT                  COMMENT 'Pump battery bus voltage in volts (Rutherford only; NULL for Archimedes)',
    LOX_INLET_TEMP_K      FLOAT         NOT NULL COMMENT 'Liquid oxygen pump inlet temperature in Kelvin',
    NOZZLE_WALL_TEMP_C    FLOAT         NOT NULL COMMENT 'Nozzle wall temperature in Celsius',
    VIBRATION_G_RMS       FLOAT         NOT NULL COMMENT 'Engine vibration in g RMS',
    MIXTURE_RATIO         FLOAT         NOT NULL COMMENT 'Oxidizer to fuel mixture ratio',
    ERROR_CODE            VARCHAR(20)            COMMENT 'Controller fault code, NULL when nominal',
    CONSTRAINT PK_ENGINE_TELEMETRY PRIMARY KEY (TELEMETRY_ID)
) COMMENT = 'High-rate engine telemetry samples from hot-fire tests and flights for Rutherford and Archimedes engines';

CREATE OR REPLACE TABLE MAINTENANCE_RECORDS (
    MAINTENANCE_ID    VARCHAR(20)    NOT NULL COMMENT 'Maintenance record identifier (MNT-00000 format)',
    VEHICLE_ID        VARCHAR(20)    NOT NULL COMMENT 'Vehicle serviced. Joins to VEHICLES',
    COMPONENT_ID      VARCHAR(20)             COMMENT 'Component serviced, NULL for vehicle-level work. Joins to COMPONENTS',
    MAINTENANCE_TYPE  VARCHAR(50)    NOT NULL COMMENT 'Type: Post-Flight Refurbishment, Preventive, Corrective, Inspection, Requalification',
    DESCRIPTION       VARCHAR(1000)  NOT NULL COMMENT 'Description of the work performed',
    FACILITY          VARCHAR(100)   NOT NULL COMMENT 'Facility where the work was performed',
    PERFORMED_BY      VARCHAR(100)   NOT NULL COMMENT 'Lead technician',
    PERFORMED_AT      TIMESTAMP_NTZ  NOT NULL COMMENT 'Timestamp the work was completed',
    DURATION_HOURS    NUMBER(6,1)    NOT NULL COMMENT 'Labor hours',
    COST_USD          NUMBER(12,2)   NOT NULL COMMENT 'Cost of labor and parts in US dollars',
    PARTS_REPLACED    VARCHAR(300)            COMMENT 'Parts replaced, NULL if none',
    OUTCOME           VARCHAR(30)    NOT NULL COMMENT 'Outcome: Returned to Service, Monitoring, Scrapped',
    CONSTRAINT PK_MAINTENANCE PRIMARY KEY (MAINTENANCE_ID)
) COMMENT = 'Maintenance, inspection and post-flight refurbishment records for vehicles and components';

CREATE OR REPLACE TABLE ANOMALIES (
    ANOMALY_ID            VARCHAR(20)   NOT NULL COMMENT 'Anomaly identifier (ANM-00000 format)',
    VEHICLE_ID            VARCHAR(20)   NOT NULL COMMENT 'Vehicle involved. Joins to VEHICLES',
    MISSION_ID            VARCHAR(20)            COMMENT 'Mission affected, NULL if not tied to a mission campaign. Joins to MISSIONS',
    COMPONENT_ID          VARCHAR(20)            COMMENT 'Component implicated, if known. Joins to COMPONENTS',
    ANOMALY_TYPE          VARCHAR(50)   NOT NULL COMMENT 'Type: Engine Performance, Avionics Fault, Telemetry Dropout, Propellant System, Structural, Ground Support Equipment, Range Hold, Weather Hold',
    SEVERITY              VARCHAR(20)   NOT NULL COMMENT 'Severity: Critical, High, Medium, Low',
    PHASE                 VARCHAR(30)   NOT NULL COMMENT 'Phase: Production Test, Integration, Countdown, Flight, Recovery',
    DESCRIPTION           VARCHAR(2000) NOT NULL COMMENT 'Anomaly description',
    REPORTED_AT           TIMESTAMP_NTZ NOT NULL COMMENT 'Timestamp the anomaly was reported',
    RESOLVED_AT           TIMESTAMP_NTZ          COMMENT 'Timestamp the anomaly was closed, NULL if open',
    RESOLUTION            VARCHAR(1000)          COMMENT 'Corrective action, NULL if open',
    ROOT_CAUSE            VARCHAR(100)  NOT NULL COMMENT 'Root cause category',
    SCHEDULE_IMPACT_DAYS  INTEGER       NOT NULL COMMENT 'Days of schedule slip caused by the anomaly',
    CONSTRAINT PK_ANOMALIES PRIMARY KEY (ANOMALY_ID)
) COMMENT = 'Nonconformance and anomaly reports across production test, integration, countdown, flight and recovery';

CREATE OR REPLACE TABLE MISSION_DOCUMENTS (
    DOC_ID      VARCHAR(20)     NOT NULL COMMENT 'Document identifier (DOC-00000 format)',
    MISSION_ID  VARCHAR(20)     NOT NULL COMMENT 'Mission the document belongs to. Joins to MISSIONS',
    DOC_TITLE   VARCHAR(300)    NOT NULL COMMENT 'Document title',
    DOC_TYPE    VARCHAR(50)     NOT NULL COMMENT 'Type: Mission Requirements, Flight Readiness Review, Post-Flight Report, Payload Interface Control',
    CONTENT     VARCHAR(16000)  NOT NULL COMMENT 'Document body text (searchable via RL_MISSION_DOCUMENT_SEARCH)',
    AUTHOR      VARCHAR(100)    NOT NULL COMMENT 'Document author',
    CREATED_AT  TIMESTAMP_NTZ   NOT NULL COMMENT 'Timestamp the document was published',
    CONSTRAINT PK_MISSION_DOCUMENTS PRIMARY KEY (DOC_ID)
) COMMENT = 'Mission documentation: requirements, flight readiness reviews, post-flight reports and payload ICDs';

CREATE OR REPLACE TABLE TEST_FAILURE_REPORTS (
    REPORT_ID          VARCHAR(20)    NOT NULL COMMENT 'Failure report identifier (TFR-00000 format)',
    TEST_ID            VARCHAR(20)    NOT NULL COMMENT 'Failed test. Joins to TEST_RESULTS',
    COMPONENT_ID       VARCHAR(20)    NOT NULL COMMENT 'Component that failed. Joins to COMPONENTS',
    SUPPLIER_ID        VARCHAR(20)    NOT NULL COMMENT 'Supplier of the failed component. Joins to SUPPLIERS',
    COMPONENT_TYPE     VARCHAR(50)    NOT NULL COMMENT 'Type of the failed component',
    REPORT_TITLE       VARCHAR(300)   NOT NULL COMMENT 'Report title',
    CONTENT            VARCHAR(8000)  NOT NULL COMMENT 'Failure analysis text (searchable via RL_TEST_FAILURE_SEARCH)',
    SEVERITY           VARCHAR(20)    NOT NULL COMMENT 'Severity: Critical, Major, Minor',
    ROOT_CAUSE         VARCHAR(100)   NOT NULL COMMENT 'Root cause category',
    CORRECTIVE_ACTION  VARCHAR(500)   NOT NULL COMMENT 'Corrective action taken',
    CREATED_AT         TIMESTAMP_NTZ  NOT NULL COMMENT 'Timestamp the report was filed',
    CONSTRAINT PK_TEST_FAILURE_REPORTS PRIMARY KEY (REPORT_ID)
) COMMENT = 'Failure analysis reports for every failed test';

CREATE OR REPLACE TABLE KNOWLEDGE_BASE (
    ARTICLE_ID   VARCHAR(20)     NOT NULL COMMENT 'Article identifier (KB-0000 format)',
    TITLE        VARCHAR(300)    NOT NULL COMMENT 'Article title',
    CATEGORY     VARCHAR(50)     NOT NULL COMMENT 'Category: Vehicle Specifications, Procedures, Troubleshooting, Safety & Compliance, Customer Success, Company',
    VEHICLE_TYPE VARCHAR(50)     NOT NULL COMMENT 'Applicable vehicle or product: Electron, HASTE, Neutron, Space Systems or All',
    CONTENT      VARCHAR(16000)  NOT NULL COMMENT 'Article body text',
    TAGS         VARCHAR(500)    NOT NULL COMMENT 'Comma-separated tags',
    AUTHOR       VARCHAR(100)    NOT NULL COMMENT 'Article owner',
    UPDATED_AT   TIMESTAMP_NTZ   NOT NULL COMMENT 'Last update timestamp',
    CONSTRAINT PK_KNOWLEDGE_BASE PRIMARY KEY (ARTICLE_ID)
) COMMENT = 'Engineering and customer success knowledge base';

-- ============================================================================
-- CUSTOMER 360
-- ============================================================================
CREATE OR REPLACE TABLE CUSTOMERS (
    CUSTOMER_ID          VARCHAR(20)   NOT NULL COMMENT 'Customer identifier (CUST-0000 format)',
    CUSTOMER_NAME        VARCHAR(150)  NOT NULL COMMENT 'Customer organization name',
    CUSTOMER_TYPE        VARCHAR(50)   NOT NULL COMMENT 'Customer type: Commercial, Civil Government, National Security, International Agency, Academic',
    INDUSTRY             VARCHAR(50)   NOT NULL COMMENT 'Mission area: Earth Observation, Communications, IoT & Tracking, Defense & Hypersonics, Science & Exploration, In-Space Services',
    SEGMENT              VARCHAR(30)   NOT NULL COMMENT 'Go-to-market segment by contracted ARR: Strategic, Enterprise, Commercial',
    REGION               VARCHAR(50)   NOT NULL COMMENT 'Headquarters region: North America, Europe, Asia Pacific',
    COUNTRY              VARCHAR(50)   NOT NULL COMMENT 'Headquarters country',
    HQ_CITY              VARCHAR(100)  NOT NULL COMMENT 'Headquarters city',
    ACCOUNT_MANAGER      VARCHAR(100)  NOT NULL COMMENT 'Rocket Lab account executive',
    CSM_NAME             VARCHAR(100)  NOT NULL COMMENT 'Rocket Lab customer success / mission manager',
    SUPPORT_TIER         VARCHAR(20)   NOT NULL COMMENT 'Mission support tier: Platinum, Gold, Silver',
    CUSTOMER_SINCE       DATE                   COMMENT 'Date of the first contract',
    CONTRACT_START_DATE  DATE                   COMMENT 'Start of the current contract term',
    CONTRACT_END_DATE    DATE                   COMMENT 'End of the current contract term (renewal date); churn date for churned customers',
    LIFECYCLE_STAGE      VARCHAR(30)            COMMENT 'Lifecycle stage: Onboarding, Adopting, Mature, Renewal Due, Churned',
    CONSTRAINT PK_CUSTOMERS PRIMARY KEY (CUSTOMER_ID)
) COMMENT = 'Launch and space systems customers. Names are real organizations, but every metric and relationship status is synthetic';

CREATE OR REPLACE TABLE CONTACTS (
    CONTACT_ID    VARCHAR(20)   NOT NULL COMMENT 'Contact identifier (CON-00000 format)',
    CUSTOMER_ID   VARCHAR(20)   NOT NULL COMMENT 'Customer. Joins to CUSTOMERS',
    FULL_NAME     VARCHAR(100)  NOT NULL COMMENT 'Contact full name (synthetic)',
    TITLE         VARCHAR(100)  NOT NULL COMMENT 'Job title',
    CONTACT_ROLE  VARCHAR(30)   NOT NULL COMMENT 'Buying-group role: Economic Buyer, Champion, Mission Manager, Procurement',
    EMAIL         VARCHAR(150)  NOT NULL COMMENT 'Email address (synthetic)',
    IS_PRIMARY    BOOLEAN       NOT NULL COMMENT 'TRUE for the primary contact',
    CONSTRAINT PK_CONTACTS PRIMARY KEY (CONTACT_ID)
) COMMENT = 'Customer contacts';

CREATE OR REPLACE TABLE CUSTOMER_SPACECRAFT (
    SPACECRAFT_ID     VARCHAR(20)   NOT NULL COMMENT 'Spacecraft identifier (SC-00000 format)',
    CUSTOMER_ID       VARCHAR(20)   NOT NULL COMMENT 'Owning customer. Joins to CUSTOMERS',
    SPACECRAFT_NAME   VARCHAR(100)  NOT NULL COMMENT 'Spacecraft name',
    PLATFORM          VARCHAR(50)   NOT NULL COMMENT 'Platform: Photon, Pioneer, Explorer, Lightning, Flatellite, or Customer Bus (with Rocket Lab components)',
    RL_CONTENT        VARCHAR(200)  NOT NULL COMMENT 'Rocket Lab hardware and services on board, for example star trackers, reaction wheels, solar arrays, mission operations',
    MISSION_ID        VARCHAR(20)            COMMENT 'Launch mission, NULL if launched by another provider or not yet launched. Joins to MISSIONS',
    LAUNCH_DATE       DATE                   COMMENT 'Launch date, NULL if not launched',
    STATUS            VARCHAR(30)   NOT NULL COMMENT 'Status: On Orbit - Nominal, On Orbit - Degraded, Awaiting Launch, Decommissioned',
    CONSTRAINT PK_CUSTOMER_SPACECRAFT PRIMARY KEY (SPACECRAFT_ID)
) COMMENT = 'Customer spacecraft built, equipped, launched or operated by Rocket Lab';

CREATE OR REPLACE TABLE CONTRACTS (
    CONTRACT_ID     VARCHAR(20)   NOT NULL COMMENT 'Contract identifier (CTR-00000 format)',
    CUSTOMER_ID     VARCHAR(20)   NOT NULL COMMENT 'Customer. Joins to CUSTOMERS',
    CONTRACT_TYPE   VARCHAR(50)   NOT NULL COMMENT 'Type: Multi-Launch Agreement, Launch Services Agreement, Spacecraft & Components Supply, Mission Operations Subscription, Expansion',
    PRODUCT_LINE    VARCHAR(30)   NOT NULL COMMENT 'Primary product line: Electron, HASTE, Neutron, Space Systems',
    START_DATE      DATE          NOT NULL COMMENT 'Contract term start',
    END_DATE        DATE          NOT NULL COMMENT 'Contract term end',
    ARR_USD         NUMBER(15,2)  NOT NULL COMMENT 'Annualized contract value in US dollars',
    TCV_USD         NUMBER(15,2)  NOT NULL COMMENT 'Total contract value for the term in US dollars',
    LAUNCH_QUANTITY INTEGER       NOT NULL COMMENT 'Launches included in the term (0 for space systems or operations contracts)',
    AUTO_RENEW      BOOLEAN       NOT NULL COMMENT 'TRUE if the term renews automatically',
    STATUS          VARCHAR(20)   NOT NULL COMMENT 'Status: Active, Renewed, Churned',
    CONSTRAINT PK_CONTRACTS PRIMARY KEY (CONTRACT_ID)
) COMMENT = 'Customer contract terms (annualized)';

CREATE OR REPLACE TABLE INVOICES (
    INVOICE_ID      VARCHAR(20)   NOT NULL COMMENT 'Invoice identifier (INV-000000 format)',
    CONTRACT_ID     VARCHAR(20)   NOT NULL COMMENT 'Contract billed. Joins to CONTRACTS',
    CUSTOMER_ID     VARCHAR(20)   NOT NULL COMMENT 'Customer. Joins to CUSTOMERS',
    INVOICE_DATE    DATE          NOT NULL COMMENT 'Invoice date',
    DUE_DATE        DATE          NOT NULL COMMENT 'Payment due date (net 30)',
    AMOUNT_USD      NUMBER(15,2)  NOT NULL COMMENT 'Invoice amount in US dollars',
    PAID_DATE       DATE                   COMMENT 'Date paid, NULL if unpaid',
    PAYMENT_STATUS  VARCHAR(20)   NOT NULL COMMENT 'Payment status: Paid, Paid Late, Overdue, Open',
    DAYS_LATE       INTEGER       NOT NULL COMMENT 'Days paid after the due date, or days overdue so far; 0 if on time',
    CONSTRAINT PK_INVOICES PRIMARY KEY (INVOICE_ID)
) COMMENT = 'Monthly milestone billing invoices';

CREATE OR REPLACE TABLE SUPPORT_TICKETS (
    TICKET_ID         VARCHAR(20)    NOT NULL COMMENT 'Ticket identifier (TKT-000000 format)',
    CUSTOMER_ID       VARCHAR(20)    NOT NULL COMMENT 'Customer. Joins to CUSTOMERS',
    CONTACT_ID        VARCHAR(20)    NOT NULL COMMENT 'Contact who opened the ticket. Joins to CONTACTS',
    MISSION_ID        VARCHAR(20)             COMMENT 'Related mission, if any. Joins to MISSIONS',
    CATEGORY          VARCHAR(50)    NOT NULL COMMENT 'Category: Payload Integration, Launch Schedule, Mission Operations, Spacecraft Anomaly, Ground Segment, Documentation, Export Compliance, Billing',
    PRIORITY          VARCHAR(20)    NOT NULL COMMENT 'Priority: Critical, High, Medium, Low',
    CHANNEL           VARCHAR(30)    NOT NULL COMMENT 'Channel: Mission Portal, Email, Phone, Mission Manager',
    SUBJECT           VARCHAR(300)   NOT NULL COMMENT 'Ticket subject',
    DESCRIPTION       VARCHAR(2000)  NOT NULL COMMENT 'Ticket description',
    STATUS            VARCHAR(20)    NOT NULL COMMENT 'Status: Open or Closed',
    OPENED_AT         TIMESTAMP_NTZ  NOT NULL COMMENT 'Timestamp opened',
    CLOSED_AT         TIMESTAMP_NTZ           COMMENT 'Timestamp closed, NULL while open',
    RESOLUTION_HOURS  NUMBER(8,1)             COMMENT 'Hours to resolve, NULL while open',
    SLA_MET           BOOLEAN                 COMMENT 'TRUE if resolved within the priority SLA, NULL while open',
    CSAT_SCORE        INTEGER                 COMMENT 'Ticket satisfaction 1-5, NULL while open',
    ASSIGNED_TO       VARCHAR(100)   NOT NULL COMMENT 'Support or mission engineer assigned',
    CONSTRAINT PK_SUPPORT_TICKETS PRIMARY KEY (TICKET_ID)
) COMMENT = 'Customer support and mission management tickets';

CREATE OR REPLACE TABLE SURVEYS (
    SURVEY_ID      VARCHAR(20)    NOT NULL COMMENT 'Survey response identifier (SRV-00000 format)',
    CUSTOMER_ID    VARCHAR(20)    NOT NULL COMMENT 'Customer. Joins to CUSTOMERS',
    CONTACT_ID     VARCHAR(20)    NOT NULL COMMENT 'Respondent. Joins to CONTACTS',
    SURVEY_TYPE    VARCHAR(10)    NOT NULL COMMENT 'NPS (0-10) or CSAT (1-5)',
    SCORE          INTEGER        NOT NULL COMMENT 'Score: 0-10 for NPS, 1-5 for CSAT',
    NPS_CATEGORY   VARCHAR(20)    NOT NULL COMMENT 'NPS: Promoter, Passive, Detractor. CSAT: Satisfied, Neutral, Dissatisfied',
    VERBATIM       VARCHAR(1000)  NOT NULL COMMENT 'Free-text comment',
    RESPONSE_DATE  DATE           NOT NULL COMMENT 'Response date',
    CONSTRAINT PK_SURVEYS PRIMARY KEY (SURVEY_ID)
) COMMENT = 'NPS and CSAT survey responses';

CREATE OR REPLACE TABLE MISSION_OPS_USAGE_DAILY (
    CUSTOMER_ID           VARCHAR(20)   NOT NULL COMMENT 'Customer. Joins to CUSTOMERS',
    USAGE_DATE            DATE          NOT NULL COMMENT 'Usage date',
    ACTIVE_SPACECRAFT     INTEGER       NOT NULL COMMENT 'Customer spacecraft operated through Rocket Lab mission operations that day',
    GROUND_CONTACTS       INTEGER       NOT NULL COMMENT 'Ground station passes completed',
    DATA_DOWNLINKED_GB    NUMBER(10,2)  NOT NULL COMMENT 'Payload data downlinked in gigabytes',
    COMMAND_SUCCESS_PCT   NUMBER(5,2)   NOT NULL COMMENT 'Percentage of uplinked commands executed successfully',
    AUTOMATION_PCT        NUMBER(5,2)   NOT NULL COMMENT 'Percentage of passes scheduled and executed automatically by the mission operations software',
    PORTAL_LOGINS         INTEGER       NOT NULL COMMENT 'Customer logins to the Rocket Lab Mission Portal',
    CONSTRAINT PK_MISSION_OPS_USAGE PRIMARY KEY (CUSTOMER_ID, USAGE_DATE)
) COMMENT = 'Daily mission operations and portal adoption per customer';

CREATE OR REPLACE TABLE OPPORTUNITIES (
    OPPORTUNITY_ID    VARCHAR(20)   NOT NULL COMMENT 'Opportunity identifier (OPP-00000 format)',
    CUSTOMER_ID       VARCHAR(20)   NOT NULL COMMENT 'Customer. Joins to CUSTOMERS',
    OPPORTUNITY_NAME  VARCHAR(200)  NOT NULL COMMENT 'Opportunity name',
    OPPORTUNITY_TYPE  VARCHAR(30)   NOT NULL COMMENT 'Type: Renewal, Additional Launches, Neutron Upgrade, Spacecraft Build, Components, Mission Operations',
    PRODUCT_LINE      VARCHAR(30)   NOT NULL COMMENT 'Product line: Electron, HASTE, Neutron, Space Systems',
    STAGE             VARCHAR(30)   NOT NULL COMMENT 'Stage: Discovery, Qualification, Proposal, Negotiation, Commit, Closed Won, Closed Lost',
    AMOUNT_USD        NUMBER(15,2)  NOT NULL COMMENT 'Opportunity value in US dollars',
    PROBABILITY_PCT   INTEGER       NOT NULL COMMENT 'Win probability percent',
    CREATED_DATE      DATE          NOT NULL COMMENT 'Created date',
    CLOSE_DATE        DATE          NOT NULL COMMENT 'Expected or actual close date',
    OWNER             VARCHAR(100)  NOT NULL COMMENT 'Opportunity owner',
    IS_CLOSED         BOOLEAN       NOT NULL COMMENT 'TRUE if Closed Won or Closed Lost',
    IS_WON            BOOLEAN       NOT NULL COMMENT 'TRUE if Closed Won',
    LOSS_REASON       VARCHAR(100)           COMMENT 'Reason lost, NULL unless Closed Lost',
    CONSTRAINT PK_OPPORTUNITIES PRIMARY KEY (OPPORTUNITY_ID)
) COMMENT = 'Sales pipeline';

CREATE OR REPLACE TABLE INTERACTIONS (
    INTERACTION_ID    VARCHAR(20)    NOT NULL COMMENT 'Interaction identifier (INT-000000 format)',
    CUSTOMER_ID       VARCHAR(20)    NOT NULL COMMENT 'Customer. Joins to CUSTOMERS',
    CONTACT_ID        VARCHAR(20)    NOT NULL COMMENT 'Contact. Joins to CONTACTS',
    INTERACTION_TYPE  VARCHAR(30)    NOT NULL COMMENT 'Type: QBR, Check-in Call, Email, Site Visit, Executive Briefing, Mission Readiness Review, Escalation Call',
    INTERACTION_DATE  DATE           NOT NULL COMMENT 'Interaction date',
    OWNER             VARCHAR(100)   NOT NULL COMMENT 'Rocket Lab owner (account manager or CSM)',
    SUBJECT           VARCHAR(300)   NOT NULL COMMENT 'Subject line',
    SUMMARY           VARCHAR(4000)  NOT NULL COMMENT 'Meeting notes',
    SENTIMENT         VARCHAR(20)    NOT NULL COMMENT 'Sentiment: Positive, Neutral, Negative',
    NEXT_STEPS        VARCHAR(500)   NOT NULL COMMENT 'Agreed next steps',
    CONSTRAINT PK_INTERACTIONS PRIMARY KEY (INTERACTION_ID)
) COMMENT = 'Customer interaction notes';
