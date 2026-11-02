/*=============================================================================
  Rocket Lab Intelligence Agent
  Step 1: Database, Schemas, and Warehouse Setup

  Execution Order: 1 of 9
  Description: Replaces the ROCKET_LAB_INTELLIGENCE database with RAW,
               ANALYTICS and ML schemas, plus the ROCKET_LAB_WH warehouse.
               WARNING: CREATE OR REPLACE DATABASE drops the previous build.
=============================================================================*/

CREATE OR REPLACE DATABASE ROCKET_LAB_INTELLIGENCE
    COMMENT = 'Rocket Lab Intelligence: launch operations, vehicle and engine health, supply chain quality, and Customer 360';
USE DATABASE ROCKET_LAB_INTELLIGENCE;

CREATE SCHEMA IF NOT EXISTS RAW
    COMMENT = 'Raw layer: vehicles, missions, launch sites, components, engine telemetry, tests, suppliers, anomalies, documents and Customer 360 source tables';

CREATE SCHEMA IF NOT EXISTS ANALYTICS
    COMMENT = 'Analytical layer: views, ML score tables, semantic views, Cortex Search services and agent UDFs';

CREATE SCHEMA IF NOT EXISTS ML
    COMMENT = 'Snowflake Model Registry for the Rocket Lab ML models';

CREATE OR REPLACE WAREHOUSE ROCKET_LAB_WH WITH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Warehouse for Rocket Lab Intelligence Agent';

USE WAREHOUSE ROCKET_LAB_WH;
USE SCHEMA RAW;
