USE DATABASE ROCKET_LAB_INTELLIGENCE;
USE SCHEMA ANALYTICS;
USE WAREHOUSE ROCKET_LAB_WH;

CREATE OR REPLACE SEMANTIC VIEW RL_FLEET_SV
  TABLES (vf AS ANALYTICS.VEHICLE_FLEET_OVERVIEW PRIMARY KEY (VEHICLE_ID) COMMENT = 'One row per vehicle with component condition')
  DIMENSIONS (
    vf.vehicle_name AS VEHICLE_NAME WITH SYNONYMS ('rocket','vehicle') COMMENT = 'Vehicle name',
    vf.vehicle_type AS VEHICLE_TYPE WITH SYNONYMS ('rocket type','launcher') COMMENT = 'Electron, HASTE, Neutron or Test Article',
    vf.vehicle_status AS VEHICLE_STATUS WITH SYNONYMS ('status') COMMENT = 'Vehicle status',
    vf.is_reusable_booster AS IS_REUSABLE_BOOSTER COMMENT = 'TRUE when the first stage is recoverable')
  METRICS (
    vf.vehicle_count AS COUNT(VEHICLE_ID) COMMENT = 'Number of vehicles',
    vf.avg_age_days AS AVG(AGE_DAYS) COMMENT = 'Average vehicle age in days',
    vf.healthy_components AS SUM(HEALTHY_COMPONENTS) COMMENT = 'Components in Operational condition',
    vf.degraded_components AS SUM(DEGRADED_COMPONENTS) COMMENT = 'Components in Degraded condition',
    vf.critical_components AS SUM(CRITICAL_COMPONENTS) COMMENT = 'Components Failed or Needing Replacement',
    vf.total_reuses AS SUM(REUSE_COUNT) COMMENT = 'Total reflights')
  COMMENT = 'Launch vehicle fleet health';

CREATE OR REPLACE SEMANTIC VIEW RL_MISSIONS_SV
  TABLES (mo AS ANALYTICS.MISSION_OVERVIEW PRIMARY KEY (MISSION_ID) COMMENT = 'One row per mission with vehicle, customer and launch site')
  DIMENSIONS (
    mo.mission_name AS MISSION_NAME COMMENT = 'Mission name',
    mo.vehicle_type AS VEHICLE_TYPE COMMENT = 'Electron, HASTE or Neutron',
    mo.mission_type AS MISSION_TYPE COMMENT = 'Mission type',
    mo.target_orbit AS TARGET_ORBIT WITH SYNONYMS ('orbit') COMMENT = 'Target orbit',
    mo.mission_status AS MISSION_STATUS WITH SYNONYMS ('outcome','result') COMMENT = 'Scheduled, Payload Integration, Launch Ready, Success or Failure',
    mo.site_name AS SITE_NAME WITH SYNONYMS ('launch site','pad','spaceport') COMMENT = 'Launch complex',
    mo.customer_name AS CUSTOMER_NAME WITH SYNONYMS ('customer','client') COMMENT = 'Customer',
    mo.segment AS SEGMENT COMMENT = 'Customer segment',
    mo.industry AS INDUSTRY COMMENT = 'Customer mission area',
    mo.region AS REGION COMMENT = 'Customer region',
    mo.planned_launch_date AS PLANNED_LAUNCH_DATE WITH SYNONYMS ('launch date') COMMENT = 'Planned launch date',
    mo.booster_recovered AS BOOSTER_RECOVERED COMMENT = 'TRUE when the first stage was recovered')
  METRICS (
    mo.mission_count AS COUNT(MISSION_ID) COMMENT = 'Number of missions',
    mo.successes AS COUNT_IF(MISSION_STATUS = 'Success') COMMENT = 'Successful launches',
    mo.failures AS COUNT_IF(MISSION_STATUS = 'Failure') COMMENT = 'Failed launches',
    mo.launch_revenue_usd AS SUM(CONTRACT_VALUE_USD) COMMENT = 'Total launch contract value in US dollars',
    mo.avg_delay_days AS AVG(DELAY_DAYS) COMMENT = 'Average schedule slip in days',
    mo.total_payload_mass_kg AS SUM(PAYLOAD_MASS_KG) COMMENT = 'Total payload mass in kilograms',
    mo.recoveries AS COUNT_IF(BOOSTER_RECOVERED) COMMENT = 'Boosters recovered')
  COMMENT = 'Launch manifest, outcomes, revenue and schedule';

CREATE OR REPLACE SEMANTIC VIEW RL_ENGINE_TELEMETRY_SV
  TABLES (te AS ANALYTICS.ENGINE_TELEMETRY_DAILY PRIMARY KEY (COMPONENT_ID, TELEMETRY_DATE) COMMENT = 'Daily engine telemetry')
  DIMENSIONS (
    te.engine_model AS ENGINE_MODEL WITH SYNONYMS ('engine') COMMENT = 'Rutherford or Archimedes',
    te.component_type AS COMPONENT_TYPE COMMENT = 'Engine variant',
    te.vehicle_type AS VEHICLE_TYPE COMMENT = 'Vehicle type',
    te.vehicle_name AS VEHICLE_NAME COMMENT = 'Vehicle name',
    te.telemetry_date AS TELEMETRY_DATE WITH SYNONYMS ('date') COMMENT = 'Day of the samples')
  METRICS (
    te.sample_count AS SUM(SAMPLE_COUNT) COMMENT = 'Telemetry samples',
    te.avg_chamber_pressure_bar AS AVG(AVG_CHAMBER_PRESSURE_BAR) COMMENT = 'Average chamber pressure in bar',
    te.avg_thrust_kn AS AVG(AVG_THRUST_KN) COMMENT = 'Average thrust in kilonewtons',
    te.avg_nozzle_temp_c AS AVG(AVG_NOZZLE_TEMP_C) COMMENT = 'Average nozzle wall temperature in Celsius',
    te.max_vibration_g AS MAX(MAX_VIBRATION_G) COMMENT = 'Highest vibration in g RMS',
    te.error_count AS SUM(ERROR_COUNT) COMMENT = 'Samples carrying a fault code')
  COMMENT = 'Engine performance telemetry';

CREATE OR REPLACE SEMANTIC VIEW RL_COMPONENT_HEALTH_SV
  TABLES (ch AS ANALYTICS.COMPONENT_HEALTH PRIMARY KEY (COMPONENT_ID) COMMENT = 'Component condition, cycle life and supplier')
  DIMENSIONS (
    ch.component_name AS COMPONENT_NAME COMMENT = 'Component name',
    ch.component_type AS COMPONENT_TYPE WITH SYNONYMS ('part type') COMMENT = 'Component type',
    ch.component_status AS COMPONENT_STATUS WITH SYNONYMS ('condition') COMMENT = 'Operational, Degraded, Needs Replacement, Failed or Flown',
    ch.vehicle_type AS VEHICLE_TYPE COMMENT = 'Vehicle type',
    ch.supplier_name AS SUPPLIER_NAME WITH SYNONYMS ('supplier','vendor') COMMENT = 'Supplier',
    ch.is_single_source AS IS_SINGLE_SOURCE COMMENT = 'TRUE when the only qualified source')
  METRICS (
    ch.component_count AS COUNT(COMPONENT_ID) COMMENT = 'Number of components',
    ch.avg_life_used_pct AS AVG(LIFE_USED_PCT) COMMENT = 'Average percent of qualified life consumed',
    ch.avg_rul_cycles AS AVG(INSPECTION_RUL_CYCLES) COMMENT = 'Average remaining useful life in cycles',
    ch.failed_count AS COUNT_IF(COMPONENT_STATUS = 'Failed') COMMENT = 'Failed components',
    ch.needs_replacement AS COUNT_IF(COMPONENT_STATUS = 'Needs Replacement') COMMENT = 'Components needing replacement',
    ch.test_failures AS SUM(TEST_FAIL_COUNT) COMMENT = 'Failed tests')
  COMMENT = 'Flight hardware condition and remaining life';

CREATE OR REPLACE SEMANTIC VIEW RL_MAINTENANCE_SV
  TABLES (mt AS ANALYTICS.MAINTENANCE_MONTHLY_TREND PRIMARY KEY (MAINTENANCE_MONTH, VEHICLE_TYPE, MAINTENANCE_TYPE, FACILITY) COMMENT = 'Monthly maintenance cost and effort')
  DIMENSIONS (
    mt.maintenance_month AS MAINTENANCE_MONTH WITH SYNONYMS ('month') COMMENT = 'Month',
    mt.vehicle_type AS VEHICLE_TYPE COMMENT = 'Vehicle type',
    mt.maintenance_type AS MAINTENANCE_TYPE WITH SYNONYMS ('work type') COMMENT = 'Post-Flight Refurbishment, Preventive, Corrective, Inspection or Requalification',
    mt.facility AS FACILITY COMMENT = 'Facility')
  METRICS (
    mt.events AS SUM(EVENT_COUNT) COMMENT = 'Maintenance events',
    mt.cost_usd AS SUM(TOTAL_COST_USD) COMMENT = 'Maintenance cost in US dollars',
    mt.avg_hours AS AVG(AVG_HOURS) COMMENT = 'Average labor hours per event')
  COMMENT = 'Maintenance and refurbishment trends';

CREATE OR REPLACE SEMANTIC VIEW RL_ANOMALIES_SV
  TABLES (ad AS ANALYTICS.ANOMALY_DASHBOARD PRIMARY KEY (ANOMALY_ID) COMMENT = 'Anomaly and nonconformance reports')
  DIMENSIONS (
    ad.anomaly_type AS ANOMALY_TYPE WITH SYNONYMS ('issue type') COMMENT = 'Anomaly type',
    ad.severity AS SEVERITY COMMENT = 'Critical, High, Medium or Low',
    ad.phase AS PHASE COMMENT = 'Production Test, Integration, Countdown, Flight or Recovery',
    ad.anomaly_status AS ANOMALY_STATUS COMMENT = 'Open or Closed',
    ad.root_cause AS ROOT_CAUSE COMMENT = 'Root cause category',
    ad.vehicle_type AS VEHICLE_TYPE COMMENT = 'Vehicle type',
    ad.customer_name AS CUSTOMER_NAME COMMENT = 'Customer affected',
    ad.segment AS SEGMENT COMMENT = 'Customer segment')
  METRICS (
    ad.anomaly_count AS COUNT(ANOMALY_ID) COMMENT = 'Number of anomalies',
    ad.open_count AS COUNT_IF(ANOMALY_STATUS = 'Open') COMMENT = 'Anomalies still open',
    ad.critical_count AS COUNT_IF(SEVERITY = 'Critical') COMMENT = 'Critical anomalies',
    ad.total_schedule_impact_days AS SUM(SCHEDULE_IMPACT_DAYS) COMMENT = 'Total days of schedule slip',
    ad.avg_resolution_hours AS AVG(RESOLUTION_HOURS) COMMENT = 'Average hours to close')
  COMMENT = 'Anomalies, causes and schedule impact';

CREATE OR REPLACE SEMANTIC VIEW RL_SUPPLIER_QUALITY_SV
  TABLES (sq AS ANALYTICS.SUPPLIER_QUALITY PRIMARY KEY (SUPPLIER_ID) COMMENT = 'Supplier quality, delivery and test performance')
  DIMENSIONS (
    sq.supplier_name AS SUPPLIER_NAME WITH SYNONYMS ('supplier','vendor') COMMENT = 'Supplier name',
    sq.supplier_type AS SUPPLIER_TYPE WITH SYNONYMS ('commodity') COMMENT = 'Supplier type',
    sq.country AS COUNTRY COMMENT = 'Supplier country',
    sq.supplier_status AS SUPPLIER_STATUS COMMENT = 'Active, Probation or Inactive',
    sq.is_single_source AS IS_SINGLE_SOURCE COMMENT = 'TRUE when the only qualified source',
    sq.is_itar_registered AS IS_ITAR_REGISTERED COMMENT = 'TRUE when ITAR registered')
  METRICS (
    sq.supplier_count AS COUNT(SUPPLIER_ID) COMMENT = 'Number of suppliers',
    sq.avg_quality_rating AS AVG(QUALITY_RATING) COMMENT = 'Average quality rating from 1 to 5',
    sq.avg_defect_rate_ppm AS AVG(DEFECT_RATE_PPM) COMMENT = 'Average defect rate in parts per million',
    sq.total_spend_usd AS SUM(TOTAL_SPEND_USD) COMMENT = 'Total spend in US dollars',
    sq.avg_fail_rate_pct AS AVG(FAIL_RATE_PCT) COMMENT = 'Average test failure rate in percent',
    sq.test_failures AS SUM(FAIL_COUNT) COMMENT = 'Failed tests')
  COMMENT = 'Supply chain quality and risk';

CREATE OR REPLACE SEMANTIC VIEW RL_CUSTOMER_360_SV
  TABLES (c3 AS ANALYTICS.CUSTOMER_360 PRIMARY KEY (CUSTOMER_ID) COMMENT = 'One row per customer with revenue, missions, satisfaction and risk')
  DIMENSIONS (
    c3.customer_name AS CUSTOMER_NAME WITH SYNONYMS ('customer','account','client') COMMENT = 'Customer name',
    c3.customer_type AS CUSTOMER_TYPE COMMENT = 'Commercial, Civil Government, National Security, International Agency or Academic',
    c3.industry AS INDUSTRY WITH SYNONYMS ('mission area') COMMENT = 'Customer mission area',
    c3.segment AS SEGMENT COMMENT = 'Strategic, Enterprise or Commercial',
    c3.region AS REGION COMMENT = 'Headquarters region',
    c3.support_tier AS SUPPORT_TIER COMMENT = 'Platinum, Gold or Silver',
    c3.lifecycle_stage AS LIFECYCLE_STAGE WITH SYNONYMS ('stage') COMMENT = 'Onboarding, Adopting, Mature, Renewal Due or Churned',
    c3.account_manager AS ACCOUNT_MANAGER COMMENT = 'Account executive',
    c3.csm_name AS CSM_NAME WITH SYNONYMS ('customer success manager') COMMENT = 'Customer success manager')
  METRICS (
    c3.customer_count AS COUNT(CUSTOMER_ID) COMMENT = 'Number of customers',
    c3.total_arr_usd AS SUM(ACTIVE_ARR_USD) COMMENT = 'Total active annual recurring revenue in US dollars',
    c3.avg_nps AS AVG(LATEST_NPS) COMMENT = 'Average latest Net Promoter Score',
    c3.total_missions AS SUM(MISSION_COUNT) COMMENT = 'Missions flown and booked',
    c3.failed_missions AS SUM(FAILED_MISSIONS) COMMENT = 'Failed missions',
    c3.launch_backlog_usd AS SUM(LAUNCH_BACKLOG_USD) COMMENT = 'Value of launches not yet flown in US dollars',
    c3.spacecraft_count AS SUM(SPACECRAFT_COUNT) COMMENT = 'Customer spacecraft',
    c3.open_tickets AS SUM(OPEN_TICKETS) COMMENT = 'Open support tickets',
    c3.overdue_usd AS SUM(OVERDUE_USD) COMMENT = 'Overdue invoices in US dollars',
    c3.avg_days_to_renewal AS AVG(DAYS_TO_RENEWAL) COMMENT = 'Average days until contract end')
  COMMENT = 'Customer 360 health, revenue and risk';

CREATE OR REPLACE SEMANTIC VIEW RL_REVENUE_SV
  TABLES (rv AS ANALYTICS.CUSTOMER_REVENUE_MONTHLY PRIMARY KEY (REVENUE_MONTH, SEGMENT, REGION) COMMENT = 'Monthly invoiced revenue')
  DIMENSIONS (
    rv.revenue_month AS REVENUE_MONTH WITH SYNONYMS ('month') COMMENT = 'Invoice month',
    rv.segment AS SEGMENT COMMENT = 'Customer segment',
    rv.region AS REGION COMMENT = 'Customer region')
  METRICS (
    rv.total_invoiced_usd AS SUM(INVOICED_USD) COMMENT = 'Total invoiced in US dollars',
    rv.total_overdue_usd AS SUM(OVERDUE_USD) COMMENT = 'Total overdue in US dollars',
    rv.invoice_count AS SUM(INVOICE_COUNT) COMMENT = 'Invoices',
    rv.avg_late_payment_pct AS AVG(LATE_PAYMENT_PCT) COMMENT = 'Percent of invoices paid late')
  COMMENT = 'Invoiced revenue and collections';

CREATE OR REPLACE SEMANTIC VIEW RL_SUPPORT_SV
  TABLES (st AS ANALYTICS.SUPPORT_TICKET_ANALYSIS PRIMARY KEY (PRIORITY, CATEGORY, CHANNEL, SEGMENT, SUPPORT_TIER) COMMENT = 'Support ticket performance')
  DIMENSIONS (
    st.priority AS PRIORITY COMMENT = 'Critical, High, Medium or Low',
    st.category AS CATEGORY COMMENT = 'Ticket category',
    st.channel AS CHANNEL COMMENT = 'How the ticket was opened',
    st.segment AS SEGMENT COMMENT = 'Customer segment',
    st.support_tier AS SUPPORT_TIER COMMENT = 'Support tier')
  METRICS (
    st.tickets AS SUM(TICKET_COUNT) COMMENT = 'Tickets',
    st.open_tickets AS SUM(OPEN_COUNT) COMMENT = 'Tickets still open',
    st.avg_resolution_hours AS AVG(AVG_RESOLUTION_HOURS) COMMENT = 'Average hours to resolve',
    st.avg_sla_attainment_pct AS AVG(SLA_ATTAINMENT_PCT) COMMENT = 'Percent resolved inside the SLA',
    st.avg_csat AS AVG(AVG_CSAT) COMMENT = 'Average satisfaction score')
  COMMENT = 'Customer support performance';

CREATE OR REPLACE SEMANTIC VIEW RL_PIPELINE_SV
  TABLES (sp AS ANALYTICS.SALES_PIPELINE PRIMARY KEY (OPPORTUNITY_ID) COMMENT = 'Sales opportunities')
  DIMENSIONS (
    sp.opportunity_name AS OPPORTUNITY_NAME COMMENT = 'Opportunity name',
    sp.opportunity_type AS OPPORTUNITY_TYPE WITH SYNONYMS ('deal type') COMMENT = 'Renewal, Additional Launches, Neutron Upgrade, Spacecraft Build, Components or Mission Operations',
    sp.product_line AS PRODUCT_LINE COMMENT = 'Electron, HASTE, Neutron or Space Systems',
    sp.stage AS STAGE WITH SYNONYMS ('deal stage') COMMENT = 'Pipeline stage',
    sp.is_won AS IS_WON COMMENT = 'TRUE when closed won',
    sp.loss_reason AS LOSS_REASON COMMENT = 'Why a deal was lost',
    sp.customer_name AS CUSTOMER_NAME COMMENT = 'Customer',
    sp.segment AS SEGMENT COMMENT = 'Customer segment',
    sp.close_date AS CLOSE_DATE COMMENT = 'Expected or actual close date')
  METRICS (
    sp.opportunity_count AS COUNT(OPPORTUNITY_ID) COMMENT = 'Opportunities',
    sp.pipeline_usd AS SUM(AMOUNT_USD) COMMENT = 'Total opportunity value in US dollars',
    sp.weighted_pipeline_usd AS SUM(WEIGHTED_USD) COMMENT = 'Probability weighted pipeline in US dollars',
    sp.won_count AS COUNT_IF(IS_WON) COMMENT = 'Deals won',
    sp.win_rate_pct AS 100 * DIV0(COUNT_IF(IS_WON), COUNT_IF(IS_CLOSED)) COMMENT = 'Win rate in percent')
  COMMENT = 'Sales pipeline and win rate';

CREATE OR REPLACE SEMANTIC VIEW RL_MISSION_OPS_SV
  TABLES (ut AS ANALYTICS.CUSTOMER_USAGE_TREND PRIMARY KEY (USAGE_MONTH, SEGMENT) COMMENT = 'Monthly mission operations usage')
  DIMENSIONS (
    ut.usage_month AS USAGE_MONTH WITH SYNONYMS ('month') COMMENT = 'Month',
    ut.segment AS SEGMENT COMMENT = 'Customer segment')
  METRICS (
    ut.customers AS SUM(CUSTOMERS) COMMENT = 'Customers with operations activity',
    ut.avg_active_spacecraft AS AVG(AVG_ACTIVE_SPACECRAFT) COMMENT = 'Average spacecraft operated',
    ut.data_downlinked_gb AS SUM(DATA_DOWNLINKED_GB) COMMENT = 'Data downlinked in gigabytes',
    ut.avg_command_success_pct AS AVG(AVG_COMMAND_SUCCESS_PCT) COMMENT = 'Average command success rate in percent',
    ut.avg_automation_pct AS AVG(AVG_AUTOMATION_PCT) COMMENT = 'Average share of contacts run automatically in percent')
  COMMENT = 'Mission operations adoption and performance';
