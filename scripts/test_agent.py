"""Run test questions through ROCKET_LAB_AGENT and report tools used plus answer excerpts.

Usage:
    python scripts/test_agent.py --connection AWS161
"""
import argparse
import json
import time

import snowflake.connector

AGENT = "SNOWFLAKE_INTELLIGENCE.AGENTS.ROCKET_LAB_AGENT"
QUESTIONS = [
    "How is the launch fleet doing right now?",
    "What is our launch success rate and how much backlog is still ahead of us?",
    "Which components are closest to needing replacement?",
    "What are the top root causes of anomalies and how many days of schedule have they cost?",
    "Give me a Customer 360 brief for Planet Labs.",
    "Which customers are most likely to churn and how much ARR is at risk?",
    "Which renewals come due in the next 120 days?",
    "Who are the best expansion candidates?",
    "What are customers saying in their NPS comments about schedule slips?",
    "What is the win rate and open pipeline by product line?",
]


def tools_and_text(resp):
    tools, text = [], []
    for item in resp.get("content", []):
        if item.get("type") == "tool_use":
            tools.append(item.get("tool_use", {}).get("name"))
        elif item.get("type") == "text":
            text.append(item.get("text", ""))
    return tools, " ".join(text).strip()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--connection", default="AWS161")
    args = parser.parse_args()
    cur = snowflake.connector.connect(connection_name=args.connection).cursor()
    passed = 0
    for i, q in enumerate(QUESTIONS, 1):
        body = json.dumps({"messages": [{"role": "user", "content": [{"type": "text", "text": q}]}]})
        start = time.time()
        try:
            raw = cur.execute("SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(%s, %s)", (AGENT, body)).fetchone()[0]
            tools, text = tools_and_text(json.loads(raw))
            ok = bool(tools) and len(text) > 40
            passed += ok
            print(f"[{i}] {'PASS' if ok else 'CHECK'} ({time.time() - start:.0f}s) {q}")
            print(f"     tools: {tools}")
            print(f"     answer: {text[:400].replace(chr(10), ' ')}")
        except Exception as e:
            print(f"[{i}] FAIL ({time.time() - start:.0f}s) {q}\n     error: {str(e)[:300]}")
    print(f"\n{passed}/{len(QUESTIONS)} questions used a tool and returned an answer")


if __name__ == "__main__":
    main()
