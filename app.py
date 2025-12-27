import streamlit as st
from agents.orchestrator import decide_plan
from dotenv import load_dotenv
import os
from datetime import date
import pandas as pd
import traceback
try:
    import plotly.express as px
    PLOTLY_AVAILABLE = True
except Exception:
    px = None
    PLOTLY_AVAILABLE = False

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


init_state()
supabase = init_supabase()

st.set_page_config(page_title="Adaptive Fitness Agent", layout="wide")
st.title("🧠 Adaptive Fitness Agent")

page = st.sidebar.radio("Navigate", ["Dashboard", "Log Today", "History", "Settings"])

# Inject minimal custom CSS for card-like visuals
st.markdown(
    """
    <style>
    .stProgress > div > div {background: linear-gradient(90deg,#66bb6a,#42a5f5)}
    .card {background:#ffffff; padding:12px; border-radius:8px; box-shadow:0 2px 6px rgba(0,0,0,0.08);}
    </style>
    """,
    unsafe_allow_html=True,
)


def dashboard_view():
    st.header("Dashboard")
    logs = read_logs(supabase)
    decisions = read_decisions(supabase)

    # timeframe selector
    timeframe = st.selectbox("Timeframe", ["Last 7 days", "Last 14 days", "All"], index=0)
    if timeframe == "Last 7 days":
        period_days = 7
    elif timeframe == "Last 14 days":
        period_days = 14
    else:
        period_days = None

    df = pd.DataFrame(logs) if logs else pd.DataFrame()

    # prepare recent period slice
    if not df.empty and "date" in df.columns:
        df["date"] = pd.to_datetime(df["date"]).dt.date
        if period_days:
            cutoff = pd.to_datetime(date.today()).date() - pd.to_timedelta(period_days, unit="D")
            period_df = df[df["date"] >= cutoff]
        else:
            period_df = df
    else:
        period_df = pd.DataFrame()

    total_logs = len(period_df)
    missed_days = int(period_df["missed_workout"].sum()) if not period_df.empty else 0
    workouts_done = total_logs - missed_days
    avg_sleep = period_df["sleep_hours"].mean() if not period_df.empty else None

    # KPIs (main and sidebar breakdown)
    k1, k2, k3, k4 = st.columns([1,1,1,1])
    k1.metric("Logs", total_logs)
    k2.metric("Workouts Done", workouts_done)
    k3.metric("Missed Workouts", missed_days)
    k4.metric("Avg Sleep", f"{avg_sleep:.1f} hrs" if avg_sleep else "—")

    # Sidebar KPI breakdown
    with st.sidebar:
        st.header("Quick KPIs")
        st.metric("Logs", total_logs)
        st.metric("Workouts Done", workouts_done)
        st.metric("Missed", missed_days)
        st.metric("Avg Sleep", f"{avg_sleep:.1f}h" if avg_sleep else "—")
        if PLOTLY_AVAILABLE:
            st.success("Plotly available: enhanced charts enabled")
        else:
            st.info("Plotly not available: using Streamlit charts")

    # weekly goal progress (assume goal 5 workouts/week)
    st.subheader("Weekly Goal Progress")
    last7_cutoff = pd.to_datetime(date.today()).date() - pd.to_timedelta(7, unit="D")
    last7 = df[df["date"] >= last7_cutoff] if not df.empty else pd.DataFrame()
    last7_done = (len(last7) - int(last7["missed_workout"].sum())) if not last7.empty else 0
    weekly_goal = 5
    progress = min(1.0, last7_done / weekly_goal) if weekly_goal else 0
    st.progress(int(progress * 100))
    st.caption(f"{last7_done} / {weekly_goal} workouts this week")

    # charts
    col_a, col_b = st.columns(2)
    with col_a:
        st.subheader("Sleep Over Time")
        if not df.empty and "sleep_hours" in df.columns:
            sleep_ts = df.sort_values("date")["sleep_hours"].reset_index(drop=True)
            if PLOTLY_AVAILABLE:
                fig = px.line(sleep_ts, y="sleep_hours", labels={"index":"Entry","sleep_hours":"Sleep (hrs)"})
                st.plotly_chart(fig, use_container_width=True)
            else:
                st.line_chart(sleep_ts)
        else:
            st.info("No sleep data yet.")

    with col_b:
        st.subheader("Energy Distribution")
        if not df.empty and "energy_level" in df.columns:
            energy_counts = df["energy_level"].value_counts().reset_index()
            energy_counts.columns = ["energy_level","count"]
            if PLOTLY_AVAILABLE:
                fig2 = px.bar(energy_counts, x="energy_level", y="count", labels={"count":"Count","energy_level":"Energy"}, color="energy_level")
                st.plotly_chart(fig2, use_container_width=True)
            else:
                st.bar_chart(energy_counts.set_index("energy_level"))
        else:
            st.info("No energy data yet.")

    st.subheader("Recent Activity")
    if not period_df.empty:
        recent = period_df.sort_values("date", ascending=False).head(4)
        for _, row in recent.iterrows():
            cols = st.columns([1,4])
            with cols[0]:
                emoji = "✅" if not row.get("missed_workout") else "⚠️"
                st.markdown(f"<div style='font-size:28px'>{emoji}</div>", unsafe_allow_html=True)
            with cols[1]:
                st.markdown(f"**{row.get('date')}** — Stress: **{row.get('stress_level')}**, Sleep: **{row.get('sleep_hours')}h**, Energy: **{row.get('energy_level')}**")
                if row.get("missed_workout"):
                    st.markdown("<small style='color:#d9534f'>Missed workout</small>", unsafe_allow_html=True)
    else:
        st.info("No recent activity to display.")

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
        try:
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
        except Exception as e:
            # log traceback to session_state and a file for debugging
            tb = traceback.format_exc()
            st.error("An error occurred while running the agent. See details below.")
            st.exception(e)
            st.write("--- Traceback ---")
            st.code(tb)
            try:
                with open("agent_error.log", "a", encoding="utf-8") as f:
                    f.write("---\n")
                    f.write(tb)
            except Exception:
                pass


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
import streamlit as st
from agents.orchestrator import decide_plan
from supabase import create_client
from dotenv import load_dotenv
import os
from datetime import date

st.title("🧠 Adaptive Fitness Agent (DEBUG MODE)")

# Load environment
load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

st.write("🔍 Supabase URL Loaded:", SUPABASE_URL is not None)
st.write("🔍 Supabase KEY Loaded:", SUPABASE_KEY is not None)

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

USER_ID = "11111111-1111-1111-1111-111111111111"

st.subheader("Today's Status")

stress = st.selectbox("Stress Level", ["low", "medium", "high"])
sleep_hours = st.slider("Sleep Hours", 3, 10, 7)
energy = st.selectbox("Energy Level", ["low", "medium", "high"])

if st.button("Run Agent"):
    st.write("✅ Button clicked")

    try:
        st.write("📤 Saving daily log to Supabase...")

        supabase.table("daily_logs").insert({
            "user_id": USER_ID,
            "date": date.today().isoformat(),
            "missed_workout": False,
            "stress_level": stress,
            "sleep_hours": sleep_hours,
            "energy_level": energy
        }).execute()

        st.write("✅ Daily log saved")

        st.write("📥 Fetching recent logs...")

        logs = supabase.table("daily_logs") \
            .select("*") \
            .eq("user_id", USER_ID) \
            .order("date", desc=True) \
            .limit(3) \
            .execute()

        st.write("📊 Logs fetched:", logs.data)

        missed_days = sum(1 for log in logs.data if log["missed_workout"])
        latest = logs.data[0]

        user_state = {
            "missed_days": missed_days,
            "stress": latest["stress_level"],
            "sleep_hours": latest["sleep_hours"],
            "energy": latest["energy_level"]
        }

        st.write("🧠 User State:", user_state)

        plan = decide_plan(user_state)

        st.write("🤖 Agent Plan:", plan)

        supabase.table("agent_decisions").insert({
            "user_id": USER_ID,
            "date": date.today().isoformat(),
            "goal_status": plan["goal"],
            "wellness_state": plan["wellness"],
            "final_plan": plan["plan"]
        }).execute()

        st.success("🎉 Agent decision saved!")
        st.json(plan)

    except Exception as e:
        st.error("❌ ERROR OCCURRED")
        st.exception(e)
