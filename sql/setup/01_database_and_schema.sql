-- ============================================================================
-- Rocket Lab Intelligence Agent - Database and Schema Setup
-- ============================================================================
-- Purpose: Initialize the database, schema, and warehouse for the Rocket Lab
--          Intelligence Agent solution
-- Syntax: Verified against Snowflake SQL Reference
-- ============================================================================

-- Create the database
CREATE DATABASE IF NOT EXISTS ROCKET_LAB_INTELLIGENCE;

-- Use the database
USE DATABASE ROCKET_LAB_INTELLIGENCE;

-- Create schemas
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS ANALYTICS;

-- Create a virtual warehouse for query processing
CREATE OR REPLACE WAREHOUSE ROCKET_LAB_WH WITH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Warehouse for Rocket Lab Intelligence Agent queries';

-- Set the warehouse as active
USE WAREHOUSE ROCKET_LAB_WH;

-- Display confirmation
SELECT 'Database, schema, and warehouse setup completed successfully' AS STATUS;

