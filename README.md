<img src="Snowflake_Logo.svg" width="200">

# Rocket Lab Intelligence Agent

A Snowflake Intelligence solution tailored for Rocket Lab's business operations, based on the Kratos Defense template.

## Overview
This solution enables natural language querying and predictive analytics for Rocket Lab's launch services, space systems, and supply chain.

## Components

### 1. Database & Schema
- **Database**: `ROCKET_LAB_INTELLIGENCE`
- **Schemas**: `RAW` (Data), `ANALYTICS` (Views & Models)
- **Tables**: `DIVISIONS`, `EMPLOYEES`, `VEHICLES`, `MISSIONS`, `COMPONENTS`, `SUPPLIERS`, `TEST_RESULTS`.

### 2. Synthetic Data
- Generates realistic data for Electron/Neutron vehicles, missions, and component testing.
- Uses `UNIFORM` and `RANDOM` for varied distributions.

### 3. ML Models
- **Mission Risk Predictor**: Forecasts launch risk (High/Low) based on weather, technical scores, and payload.
- **Supplier Quality Predictor**: Identifies suppliers at risk of quality issues.
- **Component Failure Predictor**: Predicts component failure likelihood based on test cycles and age.
- **Architecture**: Uses "Feature Views" (`V_..._FEATURES`) as a Single Source of Truth for both training (Notebook) and prediction (SQL Procedure).

### 4. Cortex Agent
- **Semantic Search**: Search missions by name/customer, search test notes for keywords.
- **Semantic Views**: Structured data for high-accuracy SQL generation.
- **Tools**: Wraps ML models as callable tools (`PREDICT_MISSION_RISK`, etc.).

## Setup Instructions

1. **Run SQL Setup Scripts**:
   Execute the files in `sql/` in order:
   - `sql/setup/01_database_and_schema.sql`
   - `sql/setup/02_create_tables.sql`
   - `sql/data/03_generate_synthetic_data.sql`
   - `sql/views/04_create_views.sql`
   - `sql/views/05_create_semantic_views.sql`
   - `sql/search/06_create_cortex_search.sql`

2. **Train ML Models**:
   - Open `notebooks/rocket_lab_ml_models.ipynb` in Snowflake Notebooks.
   - Run all cells to train and register the 3 models.

3. **Deploy Agent Tools**:
   - Run `sql/ml/07_create_model_wrapper_functions.sql` to create the SQL wrappers.

4. **Create Agent**:
   - Run `sql/agent/08_create_intelligence_agent.sql`.

## Verification
- All SQL syntax verified against Snowflake documentation.
- ML Feature Views ensure consistency between training and inference.
- Data generation uses correct random function syntax.
