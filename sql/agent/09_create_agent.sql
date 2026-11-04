/*=============================================================================
  Rocket Lab Intelligence Agent
  Step 9: Cortex Agent

  Execution Order: 9 of 9
  Description: Creates ROCKET_LAB_AGENT, which answers questions about the
               launch fleet and Customer 360 using Cortex Analyst, Cortex
               Search and the agent functions.
=============================================================================*/

USE WAREHOUSE ROCKET_LAB_WH;

CREATE DATABASE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE;
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_INTELLIGENCE.AGENTS;

CREATE OR REPLACE AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.ROCKET_LAB_AGENT
  COMMENT = 'Rocket Lab Intelligence Agent: launch fleet health, missions, engine telemetry, component life, maintenance, anomalies, suppliers and Customer 360'
  PROFILE = '{"display_name": "Rocket Lab Assistant", "color": "red"}'
  FROM SPECIFICATION
  $$
{
  "models": {
    "orchestration": "auto"
  },
  "instructions": {
    "system": "You are the Rocket Lab Intelligence Assistant, an expert on the Electron, HASTE and Neutron launch vehicles, the engines and components that fly on them, and the customers who buy launches, spacecraft and mission operations. You help mission managers, propulsion and quality engineers, production, customer success, sales and executives understand launch performance, hardware health, supplier quality and the full Customer 360: contracts and ARR, invoices, support, NPS, mission operations usage, pipeline, and machine learning scores for churn risk, account health and expansion. Give data-driven answers with specific numbers. Currency is US dollars. Note that churn risk, health score and expansion propensity are machine learning predictions trained on synthetic demonstration data.",
    "orchestration": "FLEET AND LAUNCH: Use GetFleetHealth for an overall fleet snapshot and GetMissionSummary for launch cadence, success rate and backlog. Use FleetAnalytics for vehicle counts and component condition roll-ups, MissionAnalytics for the manifest, sites, orbits and revenue, TelemetryAnalytics for engine performance, ComponentHealthAnalytics for individual part condition and life, MaintenanceAnalytics for refurbishment cost trends, AnomalyAnalytics for nonconformance counts and schedule impact, and SupplierAnalytics for supplier quality and risk. Use GetComponentsAtRisk and GetRulEstimates for the hardware most likely to need work, GetMaintenanceCosts for the last year of spend, and GetAnomalyReport for open issues and root causes. Use MissionDocumentSearch, TestFailureSearch, KnowledgeSearch, MaintenanceSearch and AnomalySearch to find specific documents, failure reports, procedures and work records. CUSTOMER 360: For a brief on one named customer call GetCustomer360 with the name, then add InteractionSearch, SupportTicketSearch or CustomerFeedbackSearch when the user asks why. Use GetChurnRiskList for customers likely to churn, GetExpansionOpportunities for growth candidates, GetRenewalCalendar for upcoming renewals (pass days_ahead), and GetAccountHealthSummary for the portfolio. Use Customer360Analytics for comparisons across customers, RevenueAnalytics for invoicing and collections, SupportAnalytics for ticket and SLA performance, PipelineAnalytics for deals and win rate, and MissionOpsAnalytics for spacecraft operations adoption. When explaining churn risk, cite the drivers returned with the score. CHARTS: For a chart, graph or plot, query the matching Analyst tool, then call data_to_chart using the requested type: bar, line, pie, scatter or area.",
    "response": "Be concise and specific. Use tables for lists of vehicles, missions, components or customers. Include the launch success rate when discussing mission performance, and ARR, churn tier, health score and days to renewal when discussing a customer. End an account brief with one or two recommended next actions. Say when a number comes from a machine learning model.",
    "sample_questions": [
      {
        "question": "How is the launch fleet doing right now?"
      },
      {
        "question": "What is our launch success rate and how much backlog is still ahead of us?"
      },
      {
        "question": "Which components are closest to needing replacement?"
      },
      {
        "question": "What are the top root causes of anomalies and how many days of schedule have they cost?"
      },
      {
        "question": "Give me a Customer 360 brief for Planet Labs."
      },
      {
        "question": "Which customers are most likely to churn and how much ARR is at risk?"
      },
      {
        "question": "Which renewals come due in the next 120 days?"
      },
      {
        "question": "Who are the best expansion candidates?"
      },
      {
        "question": "Chart launch success rate by vehicle type as a bar chart."
      },
      {
        "question": "Show monthly maintenance cost by vehicle type as a line chart."
      },
      {
        "question": "Draw a pie chart of open anomalies by severity."
      },
      {
        "question": "Scatter nozzle temperature against chamber pressure for recent engine tests."
      },
      {
        "question": "Show active ARR by customer segment as an area chart."
      },
      {
        "question": "Table the launch sites with success rate, missions flown and recovered boosters."
      },
      {
        "question": "What does the knowledge base say about a Rutherford hot-fire abort?"
      }
    ]
  },
  "tools": [
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "FleetAnalytics",
        "description": "Query launch vehicle fleet composition, vehicle status and component condition roll-ups. Use for how many vehicles, fleet mix and overall hardware health."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "MissionAnalytics",
        "description": "Query the launch manifest: missions, outcomes, launch sites, orbits, payload, contract value, schedule slip and booster recovery. Use for launch cadence, success rate and revenue questions."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "TelemetryAnalytics",
        "description": "Query daily engine telemetry for Rutherford and Archimedes engines: chamber pressure, thrust, nozzle temperature, vibration, mixture ratio and fault codes."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "ComponentHealthAnalytics",
        "description": "Query individual component condition, qualified life consumed, remaining useful life, test failures and the supplier behind each part."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "MaintenanceAnalytics",
        "description": "Query maintenance and refurbishment cost and effort by month, vehicle type, work type and facility."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "AnomalyAnalytics",
        "description": "Query anomalies and nonconformances: type, severity, phase, root cause, resolution time and schedule impact."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "SupplierAnalytics",
        "description": "Query supplier quality ratings, defect rates, test failure rates, spend, single-source and ITAR status."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "Customer360Analytics",
        "description": "Query one row per customer: ARR, lifecycle stage, NPS, missions, spacecraft, support, late payments, anomalies and days to renewal."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "RevenueAnalytics",
        "description": "Query monthly invoiced revenue, overdue amounts and late payment rates by segment and region."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "SupportAnalytics",
        "description": "Query support ticket volume, resolution time, SLA attainment and satisfaction by priority, category and segment."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "PipelineAnalytics",
        "description": "Query the sales pipeline: opportunity value, weighted pipeline, stage, win rate and loss reasons by product line."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "MissionOpsAnalytics",
        "description": "Query mission operations usage: spacecraft operated, data downlinked, command success and automation by month and segment."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "MissionDocumentSearch",
        "description": "Search mission requirements, flight readiness reviews, post-flight reports and payload interface documents."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "TestFailureSearch",
        "description": "Search test failure analysis reports for root cause and corrective action."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "KnowledgeSearch",
        "description": "Search the engineering and customer success knowledge base: procedures, troubleshooting, specifications and playbooks."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "MaintenanceSearch",
        "description": "Search maintenance and refurbishment work records."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "AnomalySearch",
        "description": "Search anomaly and nonconformance descriptions."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "InteractionSearch",
        "description": "Search customer meeting notes and interaction summaries."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "SupportTicketSearch",
        "description": "Search customer support and mission management tickets."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "CustomerFeedbackSearch",
        "description": "Search NPS and CSAT survey comments."
      }
    },
    {
      "tool_spec": {
        "type": "generic",
        "name": "GetFleetHealth",
        "description": "Returns fleet totals: vehicles by status and type, component condition counts, missions flown, success and failure counts, open anomalies and customer count."
      }
    },
    {
      "tool_spec": {
        "type": "generic",
        "name": "GetMissionSummary",
        "description": "Returns launch performance: success rate, average schedule slip, launch backlog value, boosters recovered and the next five planned launches."
      }
    },
    {
      "tool_spec": {
        "type": "generic",
        "name": "GetComponentsAtRisk",
        "description": "Returns the 25 components in the worst condition, with life used, remaining cycles, supplier quality and test failures."
      }
    },
    {
      "tool_spec": {
        "type": "generic",
        "name": "GetMaintenanceCosts",
        "description": "Returns maintenance events, cost and hours for the last 12 months, broken down by work type."
      }
    },
    {
      "tool_spec": {
        "type": "generic",
        "name": "GetAnomalyReport",
        "description": "Returns open and critical anomaly counts, total schedule impact days, average resolution time and the top root causes."
      }
    },
    {
      "tool_spec": {
        "type": "generic",
        "name": "GetRulEstimates",
        "description": "Returns the 25 components with the least remaining useful life in cycles."
      }
    },
    {
      "tool_spec": {
        "type": "generic",
        "name": "GetCustomer360",
        "description": "Returns the full profile for the customer whose name best matches the text, including ARR, renewal, missions, NPS, tickets, payments and ML churn, health and expansion scores.",
        "input_schema": {
          "type": "object",
          "properties": {
            "customer_name_filter": {
              "type": "string",
              "description": "Full or partial customer name, for example Planet or NASA"
            }
          },
          "required": [
            "customer_name_filter"
          ]
        }
      }
    },
    {
      "tool_spec": {
        "type": "generic",
        "name": "GetChurnRiskList",
        "description": "Returns the 15 customers with the highest ML churn risk, with ARR, days to renewal and the drivers behind the score."
      }
    },
    {
      "tool_spec": {
        "type": "generic",
        "name": "GetExpansionOpportunities",
        "description": "Returns the customers most likely to expand, with ARR, NPS and mission operations automation."
      }
    },
    {
      "tool_spec": {
        "type": "generic",
        "name": "GetRenewalCalendar",
        "description": "Returns customers whose contract ends within the given number of days, with ARR and churn risk tier.",
        "input_schema": {
          "type": "object",
          "properties": {
            "days_ahead": {
              "type": "number",
              "description": "Look-ahead window in days, for example 90 or 180"
            }
          },
          "required": [
            "days_ahead"
          ]
        }
      }
    },
    {
      "tool_spec": {
        "type": "generic",
        "name": "GetAccountHealthSummary",
        "description": "Returns portfolio customer health: average health score, churn risk tier counts, ARR on high-risk accounts, churned customers and renewals due within 120 days."
      }
    }
    {
      "tool_spec": {
        "type": "data_to_chart",
        "name": "data_to_chart",
        "description": "Creates bar, line, pie, scatter and area charts from query results."
      }
    }
  ],
  "tool_resources": {
    "FleetAnalytics": {
      "semantic_view": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.RL_FLEET_SV",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "ROCKET_LAB_WH"
      }
    },
    "MissionAnalytics": {
      "semantic_view": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.RL_MISSIONS_SV",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "ROCKET_LAB_WH"
      }
    },
    "TelemetryAnalytics": {
      "semantic_view": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.RL_ENGINE_TELEMETRY_SV",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "ROCKET_LAB_WH"
      }
    },
    "ComponentHealthAnalytics": {
      "semantic_view": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.RL_COMPONENT_HEALTH_SV",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "ROCKET_LAB_WH"
      }
    },
    "MaintenanceAnalytics": {
      "semantic_view": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.RL_MAINTENANCE_SV",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "ROCKET_LAB_WH"
      }
    },
    "AnomalyAnalytics": {
      "semantic_view": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.RL_ANOMALIES_SV",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "ROCKET_LAB_WH"
      }
    },
    "SupplierAnalytics": {
      "semantic_view": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.RL_SUPPLIER_QUALITY_SV",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "ROCKET_LAB_WH"
      }
    },
    "Customer360Analytics": {
      "semantic_view": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.RL_CUSTOMER_360_SV",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "ROCKET_LAB_WH"
      }
    },
    "RevenueAnalytics": {
      "semantic_view": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.RL_REVENUE_SV",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "ROCKET_LAB_WH"
      }
    },
    "SupportAnalytics": {
      "semantic_view": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.RL_SUPPORT_SV",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "ROCKET_LAB_WH"
      }
    },
    "PipelineAnalytics": {
      "semantic_view": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.RL_PIPELINE_SV",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "ROCKET_LAB_WH"
      }
    },
    "MissionOpsAnalytics": {
      "semantic_view": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.RL_MISSION_OPS_SV",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "ROCKET_LAB_WH"
      }
    },
    "MissionDocumentSearch": {
      "search_service": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.RL_MISSION_DOCUMENT_SEARCH",
      "max_results": 8,
      "columns": [
        "DOC_TITLE",
        "CONTENT",
        "DOC_TYPE",
        "VEHICLE_TYPE",
        "CUSTOMER_NAME"
      ]
    },
    "TestFailureSearch": {
      "search_service": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.RL_TEST_FAILURE_SEARCH",
      "max_results": 8,
      "columns": [
        "REPORT_TITLE",
        "CONTENT",
        "COMPONENT_TYPE",
        "SEVERITY",
        "ROOT_CAUSE",
        "SUPPLIER_NAME"
      ]
    },
    "KnowledgeSearch": {
      "search_service": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.RL_KNOWLEDGE_SEARCH",
      "max_results": 8,
      "columns": [
        "TITLE",
        "CONTENT",
        "CATEGORY",
        "VEHICLE_TYPE",
        "TAGS"
      ]
    },
    "MaintenanceSearch": {
      "search_service": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.RL_MAINTENANCE_SEARCH",
      "max_results": 8,
      "columns": [
        "SEARCH_TEXT",
        "VEHICLE_NAME",
        "VEHICLE_TYPE",
        "MAINTENANCE_TYPE",
        "OUTCOME"
      ]
    },
    "AnomalySearch": {
      "search_service": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.RL_ANOMALY_SEARCH",
      "max_results": 8,
      "columns": [
        "DESCRIPTION",
        "ANOMALY_TYPE",
        "SEVERITY",
        "PHASE",
        "ROOT_CAUSE",
        "VEHICLE_TYPE"
      ]
    },
    "InteractionSearch": {
      "search_service": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.RL_INTERACTION_SEARCH",
      "max_results": 8,
      "columns": [
        "SUMMARY",
        "SUBJECT",
        "CUSTOMER_NAME",
        "SENTIMENT",
        "INTERACTION_TYPE"
      ]
    },
    "SupportTicketSearch": {
      "search_service": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.RL_SUPPORT_TICKET_SEARCH",
      "max_results": 8,
      "columns": [
        "SUBJECT",
        "DESCRIPTION",
        "CUSTOMER_NAME",
        "CATEGORY",
        "PRIORITY",
        "STATUS"
      ]
    },
    "CustomerFeedbackSearch": {
      "search_service": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.RL_CUSTOMER_FEEDBACK_SEARCH",
      "max_results": 8,
      "columns": [
        "VERBATIM",
        "CUSTOMER_NAME",
        "SURVEY_TYPE",
        "NPS_CATEGORY",
        "SCORE"
      ]
    },
    "GetFleetHealth": {
      "type": "function",
      "identifier": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.AGENT_GET_FLEET_HEALTH",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "ROCKET_LAB_WH"
      }
    },
    "GetMissionSummary": {
      "type": "function",
      "identifier": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.AGENT_GET_MISSION_SUMMARY",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "ROCKET_LAB_WH"
      }
    },
    "GetComponentsAtRisk": {
      "type": "function",
      "identifier": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.AGENT_GET_COMPONENTS_AT_RISK",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "ROCKET_LAB_WH"
      }
    },
    "GetMaintenanceCosts": {
      "type": "function",
      "identifier": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.AGENT_GET_MAINTENANCE_COST_SUMMARY",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "ROCKET_LAB_WH"
      }
    },
    "GetAnomalyReport": {
      "type": "function",
      "identifier": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.AGENT_GET_ANOMALY_REPORT",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "ROCKET_LAB_WH"
      }
    },
    "GetRulEstimates": {
      "type": "function",
      "identifier": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.AGENT_GET_RUL_ESTIMATES",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "ROCKET_LAB_WH"
      }
    },
    "GetCustomer360": {
      "type": "function",
      "identifier": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.AGENT_GET_CUSTOMER_360",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "ROCKET_LAB_WH"
      }
    },
    "GetChurnRiskList": {
      "type": "function",
      "identifier": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.AGENT_GET_CHURN_RISK_LIST",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "ROCKET_LAB_WH"
      }
    },
    "GetExpansionOpportunities": {
      "type": "function",
      "identifier": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.AGENT_GET_EXPANSION_OPPORTUNITIES",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "ROCKET_LAB_WH"
      }
    },
    "GetRenewalCalendar": {
      "type": "function",
      "identifier": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.AGENT_GET_RENEWAL_CALENDAR",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "ROCKET_LAB_WH"
      }
    },
    "GetAccountHealthSummary": {
      "type": "function",
      "identifier": "ROCKET_LAB_INTELLIGENCE.ANALYTICS.AGENT_GET_ACCOUNT_HEALTH_SUMMARY",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "ROCKET_LAB_WH"
      }
    }
  }
}
  $$;

GRANT USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.ROCKET_LAB_AGENT TO ROLE PUBLIC;
