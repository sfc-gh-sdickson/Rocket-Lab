<img src="../Snowflake_Logo.svg" width="200">

# Rocket Lab Intelligence Agent Setup Guide

## 1. Prerequisites
- Snowflake Account with `ACCOUNTADMIN` or equivalent privileges.
- Cortex Intelligence enabled in your Snowflake region.
- Git integration configured (optional but recommended).

## 2. Setup Order (Mandatory)

Run the SQL scripts in this EXACT order. Do not skip any steps.

### Step 1: Database & Schema
```sql
-- Open and run: sql/setup/01_database_and_schema.sql
-- Creates ROCKET_LAB_INTELLIGENCE database and schemas
```

### Step 2: Table Definitions
```sql
-- Open and run: sql/setup/02_create_tables.sql
-- Creates empty tables: MISSIONS, VEHICLES, SUPPLIERS, etc.
```

### Step 3: Synthetic Data Generation
```sql
-- Open and run: sql/data/03_generate_synthetic_data.sql
-- Populates tables with realistic data using UNIFORM/RANDOM generators
```

### Step 4: Analytical & Feature Views
```sql
-- Open and run: sql/views/04_create_views.sql
-- Creates standard views and ML Feature Views (V_..._FEATURES)
```

### Step 5: Semantic Views
```sql
-- Open and run: sql/views/05_create_semantic_views.sql
-- Creates semantic layer for Cortex Analyst
```

### Step 6: Cortex Search Services
```sql
-- Open and run: sql/search/06_create_cortex_search.sql
-- Enables search on mission names and test result notes
```

## 3. Machine Learning Training

1.  Open **Snowflake Notebooks** in Snowsight.
2.  Import `notebooks/rocket_lab_training.ipynb`.
3.  Ensure `notebooks/environment.yml` is used for the environment.
4.  Run **ALL CELLS** in the notebook.
    *   This trains 3 models: `MISSION_RISK_PREDICTOR`, `SUPPLIER_QUALITY_PREDICTOR`, `COMPONENT_FAILURE_PREDICTOR`.
    *   It registers them to the Snowflake Model Registry.

## 4. Agent Deployment

### Step 7: Create Model Wrappers
```sql
-- Open and run: sql/ml/07_create_model_wrapper_functions.sql
-- Creates SQL procedures that Agent calls to run predictions
```

### Step 8: Create Agent
```sql
-- Open and run: sql/agent/08_create_intelligence_agent.sql
-- Definitions for ROCKET_LAB_AGENT with all tools attached
```

## 5. Testing

Go to **Snowsight > AI & ML > Agents** and select `ROCKET_LAB_AGENT`.

Try these questions:
1.  "How many missions are scheduled for the LEO orbit?"
2.  "Assess mission risk for SSO orbit missions."
3.  "Which suppliers are at risk of quality issues?"
4.  "Predict failure likelihood for PROPULSION components."
5.  "Find test results mentioning 'vibration' failure."
