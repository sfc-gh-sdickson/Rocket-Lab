-- ============================================================================
-- Rocket Lab Intelligence Agent - Database and Schema Setup
-- ============================================================================
-- Purpose: Initialize the database environment
-- ============================================================================

CREATE DATABASE IF NOT EXISTS ROCKET_LAB_INTELLIGENCE;
USE DATABASE ROCKET_LAB_INTELLIGENCE;

-- Create Schemas
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS ANALYTICS;

-- Create Warehouse
CREATE WAREHOUSE IF NOT EXISTS ROCKET_LAB_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

USE WAREHOUSE ROCKET_LAB_WH;

-- Display status
SELECT 'Database, Schemas, and Warehouse created successfully' AS status;

