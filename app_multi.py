import streamlit as st
from agents.orchestrator import decide_plan
from dotenv import load_dotenv
import os
from datetime import date
import pandas as pd

load_dotenv()

def init_state():
    st.session_state.setdefault("local_logs", [])
    st.session_state.setdefault("local_decisions", [])
    st.session_state.setdefault("supabase_error", "")
    st.session_state.setdefault("use_supabase", False)
    st.session_state.setdefault("user_id", "11111111-1111-1111-1111-111111111111")


def init_supabase():
    SUPABASE_URL = os.getenv("SUPABASE_URL")
    SUPABASE_KEY = os.getenv("SUPABASE_KEY")
    if SUPABASE_URL and SUPABASE_KEY:
        try:
            from supabase import create_client

            client = create_client(SUPABASE_URL, SUPABASE_KEY)
            st.session_state.supabase_error = ""
            return client
        except Exception as e:
            st.session_state.supabase_error = str(e)
            return None
    else:
        st.session_state.supabase_error = "Supabase credentials not set."
        return None


def read_logs(supabase):
    if st.session_state.use_supabase and supabase:
        try:
            resp = supabase.table("daily_logs").select("*").eq("user_id", st.session_state.user_id).order("date", desc=True).execute()
            return resp.data if hasattr(resp, "data") else []
        except Exception as e:
            st.session_state.supabase_error = str(e)
            return list(reversed(st.session_state.local_logs))
    return list(reversed(st.session_state.local_logs))


def read_decisions(supabase):
    if st.session_state.use_supabase and supabase:
        try:
            resp = supabase.table("agent_decisions").select("*").eq("user_id", st.session_state.user_id).order("date", desc=True).execute()
            return resp.data if hasattr(resp, "data") else []
        except Exception as e:
            st.session_state.supabase_error = str(e)
            return list(reversed(st.session_state.local_decisions))
    return list(reversed(st.session_state.local_decisions))


def write_log(supabase, log):
    if st.session_state.use_supabase and supabase:
        try:
            supabase.table("daily_logs").insert(log).execute()
            return True
        except Exception as e:
            st.session_state.supabase_error = str(e)
            st.error("Supabase write failed — saved locally.")
            st.session_state.local_logs.append(log)
            return False
    st.session_state.local_logs.append(log)
    return False


def write_decision(supabase, decision):
    if st.session_state.use_supabase and supabase:
        try:
            supabase.table("agent_decisions").insert(decision).execute()
            return True
        except Exception as e:
            st.session_state.supabase_error = str(e)
            st.error("Supabase write failed for decision — saved locally.")
            st.session_state.local_decisions.append(decision)
            return False
    st.session_state.local_decisions.append(decision)
    return False


st.set_page_config(page_title="Adaptive Fitness Agent", layout="wide")

init_state()
supabase = init_supabase()

st.title("🧠 Adaptive Fitness Agent")

page = st.sidebar.radio("Navigate", ["Dashboard", "Log Today", "History", "Settings"])

def dashboard_view():
    st.header("Dashboard")
    logs = read_logs(supabase)
    decisions = read_decisions(supabase)

    missed_days = sum(1 for l in logs if l.get("missed_workout")) if logs else 0
    avg_sleep = (sum(l.get("sleep_hours", 0) for l in logs) / len(logs)) if logs else None

    col1, col2, col3 = st.columns(3)
    col1.metric("Missed Days (recent)", missed_days)
    col2.metric("Avg Sleep (recent)", f"{avg_sleep:.1f}" if avg_sleep else "—")
    col3.metric("Local Logs", len(st.session_state.local_logs))

    st.subheader("Recent Stress Levels")
    if logs:
        df = pd.DataFrame(logs)
        counts = df["stress_level"].value_counts()
        st.bar_chart(counts)
    else:
        st.info("No logs yet. Log today's status in 'Log Today'.")

    st.subheader("Latest Agent Decision")
    if decisions:
        st.json(decisions[0])
    else:
        st.info("No decisions yet. Run the agent from 'Log Today'.")


def log_today_view():
    st.header("Log Today's Status")
    stress = st.selectbox("Stress Level", ["low", "medium", "high"], index=1)
    sleep_hours = st.slider("Sleep Hours", 0, 12, 7)
    energy = st.selectbox("Energy Level", ["low", "medium", "high"], index=1)
    missed = st.checkbox("Missed today's workout")

    if st.button("Submit & Run Agent"):
        new_log = {
            "user_id": st.session_state.user_id,
            "date": date.today().isoformat(),
            "missed_workout": missed,
            "stress_level": stress,
            "sleep_hours": sleep_hours,
            "energy_level": energy,
        }
        write_log(supabase, new_log)

        logs = read_logs(supabase)
        missed_days = sum(1 for l in logs if l.get("missed_workout")) if logs else 0
        user_state = {"missed_days": missed_days, "stress": stress, "sleep_hours": sleep_hours, "energy": energy}
        plan = decide_plan(user_state)

        decision = {
            "user_id": st.session_state.user_id,
            "date": date.today().isoformat(),
            "goal_status": plan["goal"],
            "wellness_state": plan["wellness"],
            "final_plan": plan["plan"],
        }
        write_decision(supabase, decision)

        st.success("Agent Decision")
        st.json(decision)


def history_view():
    st.header("History")
    logs = read_logs(supabase)
    decisions = read_decisions(supabase)

    st.subheader("Daily Logs")
    if logs:
        st.table(pd.DataFrame(logs))
    else:
        st.info("No logs to show.")

    st.subheader("Agent Decisions")
    if decisions:
        st.table(pd.DataFrame(decisions))
    else:
        st.info("No decisions to show.")


def settings_view():
    st.header("Settings")
    st.session_state.user_id = st.text_input("User ID", value=st.session_state.user_id)
    st.session_state.use_supabase = st.checkbox("Save to Supabase if available", value=st.session_state.use_supabase)
    if st.session_state.supabase_error:
        with st.expander("Supabase status / last error"):
            st.write(st.session_state.supabase_error)

    if st.button("Clear local logs and decisions"):
        st.session_state.local_logs = []
        st.session_state.local_decisions = []
        st.success("Local data cleared")


if page == "Dashboard":
    dashboard_view()
elif page == "Log Today":
    log_today_view()
elif page == "History":
    history_view()
elif page == "Settings":
    settings_view()
