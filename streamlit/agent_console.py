# streamlit/agent_console.py
import streamlit as st
from agents.orchestrator import decide_plan
from dotenv import load_dotenv
from datetime import date
import os
import pandas as pd
import traceback

load_dotenv()

st.set_page_config(
    page_title="Agent Console | Adaptive Fitness",
    layout="wide"
)

# ------------------ STATE ------------------
def init_state():
    st.session_state.setdefault("logs", [])
    st.session_state.setdefault("decisions", [])
    st.session_state.setdefault("user_id", "11111111-1111-1111-1111-111111111111")

init_state()

# ------------------ UI ------------------
st.title("🧠 Adaptive Fitness · Agent Console")
st.caption("Internal monitoring interface for agent behavior")

page = st.sidebar.radio(
    "Navigation",
    ["Dashboard", "Signal Intake", "History"]
)

# ------------------ DASHBOARD ------------------
def dashboard_view():
    st.subheader("Agent Overview")

    logs = st.session_state.logs
    decisions = st.session_state.decisions

    col1, col2, col3 = st.columns(3)
    col1.metric("Total Logs", len(logs))
    col2.metric("Decisions Made", len(decisions))
    col3.metric("Last Decision", decisions[-1]["date"] if decisions else "—")

    if decisions:
        st.subheader("Latest Agent Decision")
        st.json(decisions[-1])

# ------------------ SIGNAL INTAKE ------------------
def signal_view():
    st.subheader("Daily Signal Intake")

    stress = st.selectbox("Stress Level", ["low", "medium", "high"], index=1)
    sleep = st.slider("Sleep Hours", 0, 12, 7)
    energy = st.selectbox("Energy Level", ["low", "medium", "high"], index=1)
    missed = st.checkbox("Missed previous plan")

    if st.button("Submit Signals & Run Agent"):
        try:
            log = {
                "date": date.today().isoformat(),
                "stress": stress,
                "sleep_hours": sleep,
                "energy": energy,
                "missed": missed
            }
            st.session_state.logs.append(log)

            user_state = {
                "missed_days": sum(1 for l in st.session_state.logs if l["missed"]),
                "stress": stress,
                "sleep_hours": sleep,
                "energy": energy
            }

            decision = decide_plan(user_state)

            decision_record = {
                "date": date.today().isoformat(),
                "input": user_state,
                "output": decision
            }
            st.session_state.decisions.append(decision_record)

            st.success("Agent executed successfully")
            st.json(decision_record)

        except Exception as e:
            st.error("Agent execution failed")
            st.exception(e)

# ------------------ HISTORY ------------------
def history_view():
    st.subheader("Execution History")

    if st.session_state.logs:
        st.write("Logs")
        st.table(pd.DataFrame(st.session_state.logs))
    else:
        st.info("No logs yet")

    if st.session_state.decisions:
        st.write("Decisions")
        st.table(pd.DataFrame(st.session_state.decisions))
    else:
        st.info("No decisions yet")

# ------------------ ROUTING ------------------
if page == "Dashboard":
    dashboard_view()
elif page == "Signal Intake":
    signal_view()
elif page == "History":
    history_view()
