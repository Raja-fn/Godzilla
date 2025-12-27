from flask import Flask, render_template, request, redirect, url_for, flash
from agents.orchestrator import decide_plan
from datetime import date
from dotenv import load_dotenv
import os, json
import time

load_dotenv()

DATA_FILE = os.path.join(os.path.dirname(__file__), "data.json")

app = Flask(__name__)
app.secret_key = os.getenv("FLASK_SECRET_KEY", "dev-key")


@app.context_processor
def inject_globals():
    # provide a cache-busting version for static files and the current year
    try:
        path = os.path.join(app.root_path, 'static', 'style.css')
        ver = str(int(os.path.getmtime(path)))
    except Exception:
        ver = str(int(time.time()))
    return dict(static_version=ver, year=date.today().year)

# Initialize Supabase client if credentials exist
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
supabase_client = None
if SUPABASE_URL and SUPABASE_KEY:
    try:
        from supabase import create_client

        supabase_client = create_client(SUPABASE_URL, SUPABASE_KEY)
    except Exception:
        supabase_client = None


def read_data():
    # prefer Supabase when enabled in settings and client available
    if os.path.exists(DATA_FILE):
        with open(DATA_FILE, "r", encoding="utf-8") as f:
            local = json.load(f)
    else:
        local = {"daily_logs": [], "agent_decisions": [], "settings": {"user_id": "11111111-1111-1111-1111-111111111111", "use_supabase": False}}
        with open(DATA_FILE, "w", encoding="utf-8") as f:
            json.dump(local, f, indent=2)

    settings = local.get("settings", {})
    if settings.get("use_supabase") and supabase_client:
        try:
            logs_resp = supabase_client.table("daily_logs").select("*").order("date", desc=True).execute()
            decisions_resp = supabase_client.table("agent_decisions").select("*").order("date", desc=True).execute()
            local["daily_logs"] = logs_resp.data if hasattr(logs_resp, "data") else local.get("daily_logs", [])
            local["agent_decisions"] = decisions_resp.data if hasattr(decisions_resp, "data") else local.get("agent_decisions", [])
        except Exception:
            pass

    return local


def write_data(data):
    # always persist locally
    with open(DATA_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)

    # if settings ask for Supabase and client present, try to persist there too
    settings = data.get("settings", {})
    if settings.get("use_supabase") and supabase_client:
        try:
            # upload daily_logs
            for log in data.get("daily_logs", []):
                # naive insert - in real app use upsert/unique keys
                supabase_client.table("daily_logs").insert(log).execute()
            for dec in data.get("agent_decisions", []):
                supabase_client.table("agent_decisions").insert(dec).execute()
        except Exception:
            pass



@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        email = request.form.get("email")
        password = request.form.get("password")
        # Simple authentication - in production, use proper auth
        if email and password:
            flash("Login successful!", "success")
            return redirect(url_for("index"))
        else:
            flash("Please enter email and password", "danger")
    return render_template("login.html")


@app.route("/")
@app.route("/dashboard")
def index():
    data = read_data()
    logs = list(reversed(data.get("daily_logs", [])))
    decisions = list(reversed(data.get("agent_decisions", [])))

    # compute KPIs
    recent = logs[:14]
    total_logs = len(recent)
    missed = sum(1 for l in recent if l.get("missed_workout"))
    avg_sleep = (sum(l.get("sleep_hours", 0) for l in recent)/len(recent)) if recent else None

    # prepare chart data
    # sleep time series (last 14 entries)
    sleep_series = []
    sleep_labels = []
    for l in list(reversed(recent)):
        sleep_labels.append(l.get("date"))
        sleep_series.append(l.get("sleep_hours", 0))

    # stress distribution
    stress_counts = {}
    energy_counts = {}
    for l in recent:
        stress_counts[l.get("stress_level", "unknown")] = stress_counts.get(l.get("stress_level", "unknown"), 0) + 1
        energy_counts[l.get("energy_level", "unknown")] = energy_counts.get(l.get("energy_level", "unknown"), 0) + 1

    return render_template(
        "dashboard.html",
        logs=logs,
        decisions=decisions,
        total_logs=total_logs,
        missed=missed,
        avg_sleep=avg_sleep,
        sleep_series=sleep_series,
        sleep_labels=sleep_labels,
        stress_counts=stress_counts,
        energy_counts=energy_counts,
    )


@app.route("/log", methods=["GET", "POST"])
def log_today():
    data = read_data()
    if request.method == "POST":
        user_id = data["settings"].get("user_id")
        stress = request.form.get("stress")
        sleep_hours = int(request.form.get("sleep_hours", 0))
        energy = request.form.get("energy")
        missed = True if request.form.get("missed") == "on" else False

        entry = {"user_id": user_id, "date": date.today().isoformat(), "missed_workout": missed, "stress_level": stress, "sleep_hours": sleep_hours, "energy_level": energy}
        data["daily_logs"].append(entry)
        write_data(data)

        # compute plan
        # compute missed_days from last 30 logs
        recent = data["daily_logs"][-30:]
        missed_days = sum(1 for l in recent if l.get("missed_workout"))
        user_state = {"missed_days": missed_days, "stress": stress, "sleep_hours": sleep_hours, "energy": energy}
        plan = decide_plan(user_state)

        decision = {"user_id": user_id, "date": date.today().isoformat(), "goal_status": plan["goal"], "wellness_state": plan["wellness"], "final_plan": plan["plan"]}
        data["agent_decisions"].append(decision)
        write_data(data)

        flash("Log saved and agent decision created.", "success")
        return redirect(url_for("index"))

    return render_template("log.html")


@app.route("/history")
def history():
    data = read_data()
    return render_template("history.html", logs=list(reversed(data.get("daily_logs", []))), decisions=list(reversed(data.get("agent_decisions", []))))


@app.route("/programs")
def programs():
    return render_template("programs.html")


@app.route("/profile")
def profile():
    data = read_data()
    return render_template("profile.html", settings=data.get("settings", {}))


@app.route("/analytics")
def analytics():
    data = read_data()
    return render_template("analytics.html")


@app.route("/spa")
def spa():
    # Single-page React-like app served via template (uses fetch to API endpoints)
    return render_template("spa.html")


# API endpoints for SPA / integrations
@app.route("/api/logs", methods=["GET", "POST"])
def api_logs():
    data = read_data()
    if request.method == "GET":
        return json.dumps(list(reversed(data.get("daily_logs", []))))
    payload = request.get_json() or {}
    data["daily_logs"].append(payload)
    write_data(data)
    return json.dumps(payload)


@app.route("/api/decisions", methods=["GET"])
def api_decisions():
    data = read_data()
    return json.dumps(list(reversed(data.get("agent_decisions", []))))


@app.route("/settings", methods=["GET", "POST"])
def settings():
    data = read_data()
    if request.method == "POST":
        uid = request.form.get("user_id")
        use_sup = True if request.form.get("use_supabase") == "on" else False
        data["settings"]["user_id"] = uid
        data["settings"]["use_supabase"] = use_sup
        write_data(data)
        flash("Settings saved.", "success")
        return redirect(url_for("index"))
    return render_template("settings.html", settings=data.get("settings", {}))


if __name__ == "__main__":
    # bind to localhost on port 3000 per user request
    app.run(host="127.0.0.1", port=3000, debug=True)
