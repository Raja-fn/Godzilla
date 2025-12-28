from flask import Flask, render_template, request, redirect, url_for, flash, jsonify, session
from agents.orchestrator import decide_plan
from datetime import date, timedelta
from dotenv import load_dotenv
import os, json
import time
import uuid
import base64
import hashlib
from werkzeug.utils import secure_filename

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
    
    # Get current user for navbar
    current_user_profile = None
    user_id = session.get("user_id")
    if user_id:
        data = read_data()
        user_profiles = data.get("user_profiles", [])
        for profile in user_profiles:
            if profile.get("user_id") == user_id:
                current_user_profile = profile
                break
    
    return dict(static_version=ver, year=date.today().year, current_user_profile=current_user_profile, user_name=session.get("user_name"))

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
        local = {
            "daily_logs": [], 
            "agent_decisions": [], 
            "user_profiles": [],
            "settings": {"user_id": "11111111-1111-1111-1111-111111111111", "use_supabase": False}
        }
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



def get_age_group(age):
    """Determine age group from age"""
    if 13 <= age <= 17:
        return "13-17"
    elif 18 <= age <= 30:
        return "18-30"
    elif 31 <= age <= 50:
        return "31-50"
    elif age >= 50:
        return "50+"
    return None

def calculate_level(activity_level):
    """Calculate user level based on activity level"""
    level_map = {
        "sedentary": 1,
        "light": 2,
        "moderate": 3,
        "active": 4,
        "very_active": 5
    }
    return level_map.get(activity_level, 1)

def calculate_experience_points(activity_level, logs_count=0):
    """Calculate experience points based on activity and logs"""
    base_points = calculate_level(activity_level) * 10
    log_bonus = logs_count * 2
    return base_points + log_bonus

def hash_password(password):
    """Hash password using SHA256 (for demo - use bcrypt in production)"""
    return hashlib.sha256(password.encode()).hexdigest()

def verify_password(password, hashed):
    """Verify password against hash"""
    return hash_password(password) == hashed

@app.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        data = read_data()
        
        # Get form data
        name = request.form.get("name")
        email = request.form.get("email")
        password = request.form.get("password")
        confirm_password = request.form.get("confirm_password")
        age = int(request.form.get("age", 0))
        height = float(request.form.get("height", 0))
        weight = float(request.form.get("weight", 0))
        activity_level = request.form.get("activity_level")
        goal = request.form.get("goal")
        
        # Validate password
        if password != confirm_password:
            flash("Passwords do not match!", "danger")
            return render_template("register.html")
        
        if len(password) < 6:
            flash("Password must be at least 6 characters long!", "danger")
            return render_template("register.html")
        
        # Check if email already exists
        existing_profiles = data.get("user_profiles", [])
        for profile in existing_profiles:
            if profile.get("email") == email:
                flash("Email already registered! Please login instead.", "danger")
                return redirect(url_for("login"))
        
        # Handle profile photo
        profile_photo = None
        if "profile_photo" in request.files:
            file = request.files["profile_photo"]
            if file.filename:
                # Convert to base64 for storage
                file_data = file.read()
                profile_photo = base64.b64encode(file_data).decode('utf-8')
        
        # Validate age
        if age < 13:
            flash("You must be at least 13 years old to register.", "danger")
            return render_template("register.html")
        
        # Get age group
        age_group = get_age_group(age)
        if not age_group:
            flash("Invalid age. Please enter a valid age.", "danger")
            return render_template("register.html")
        
        # Calculate initial level
        level = calculate_level(activity_level)
        experience_points = calculate_experience_points(activity_level, 0)
        
        # Create user profile
        user_id = str(uuid.uuid4())
        hashed_password = hash_password(password)
        user_profile = {
            "user_id": user_id,
            "name": name,
            "email": email,
            "password_hash": hashed_password,
            "age": age,
            "age_group": age_group,
            "height": height,
            "weight": weight,
            "activity_level": activity_level,
            "goal": goal,
            "level": level,
            "experience_points": experience_points,
            "profile_photo": profile_photo,
            "created_at": date.today().isoformat(),
            "total_logs": 0,
            "workouts_completed": 0
        }
        
        # Save user profile
        if "user_profiles" not in data:
            data["user_profiles"] = []
        data["user_profiles"].append(user_profile)
        write_data(data)
        
        # Set user in session
        session["user_id"] = user_id
        session["user_name"] = name
        flash(f"Account created successfully! Welcome, {name}!", "success")
        return redirect(url_for("index"))
    
    return render_template("register.html")

@app.route("/api/leaderboard/<age_group>")
def get_leaderboard(age_group):
    """Get leaderboard for a specific age group"""
    data = read_data()
    profiles = data.get("user_profiles", [])
    
    # Filter by age group
    group_profiles = [p for p in profiles if p.get("age_group") == age_group]
    
    # Sort by level (descending), then by experience_points (descending)
    group_profiles.sort(key=lambda x: (x.get("level", 1), x.get("experience_points", 0)), reverse=True)
    
    # Get top 25
    leaderboard = group_profiles[:25]
    
    # Format for response (don't include photo data to reduce size)
    formatted_leaderboard = []
    for user in leaderboard:
        formatted_leaderboard.append({
            "name": user.get("name", "User"),
            "level": user.get("level", 1),
            "experience_points": user.get("experience_points", 0),
            "activity_level": user.get("activity_level", "sedentary"),
            "workouts_completed": user.get("workouts_completed", 0)
        })
    
    return jsonify({
        "age_group": age_group,
        "leaderboard": formatted_leaderboard,
        "total_users": len(group_profiles)
    })

@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        email = request.form.get("email")
        password = request.form.get("password")
        
        if not email or not password:
            flash("Please enter both email and password", "danger")
            return render_template("login.html")
        
        # Find user by email and verify password
        data = read_data()
        user_profiles = data.get("user_profiles", [])
        
        user_found = None
        for profile in user_profiles:
            if profile.get("email") == email:
                # Verify password
                if verify_password(password, profile.get("password_hash", "")):
                    user_found = profile
                    break
                else:
                    flash("Invalid email or password!", "danger")
                    return render_template("login.html")
        
        if user_found:
            # Set session
            session["user_id"] = user_found.get("user_id")
            session["user_name"] = user_found.get("name", "User")
            session["user_email"] = user_found.get("email")
            flash(f"Welcome back, {user_found.get('name')}!", "success")
            return redirect(url_for("index"))
        else:
            flash("Invalid email or password!", "danger")
    
    return render_template("login.html")

@app.route("/logout")
def logout():
    session.clear()
    flash("You have been logged out.", "info")
    return redirect(url_for("index"))

@app.route("/auth/google")
def google_auth():
    # Placeholder for Google OAuth - in production, implement proper OAuth flow
    flash("Google sign-in is coming soon! Please use email registration for now.", "info")
    return redirect(url_for("register"))


@app.route("/")
@app.route("/dashboard")
def index():
    data = read_data()
    user_id = session.get("user_id") or data["settings"].get("user_id")
    
    # Get current user profile
    current_user = None
    user_profiles = data.get("user_profiles", [])
    for profile in user_profiles:
        if profile.get("user_id") == user_id:
            current_user = profile
            break
    
    # Get user's logs
    user_logs = [l for l in data.get("daily_logs", []) if l.get("user_id") == user_id]
    logs = list(reversed(user_logs))
    decisions = [d for d in data.get("agent_decisions", []) if d.get("user_id") == user_id]
    decisions = list(reversed(decisions))

    # compute KPIs
    recent = logs[:14]
    all_logs = logs
    total_logs = len(all_logs)
    missed = sum(1 for l in recent if l.get("missed_workout"))
    avg_sleep = (sum(l.get("sleep_hours", 0) for l in recent)/len(recent)) if recent else None
    
    # Calculate comprehensive analytics
    total_workouts = sum(1 for l in all_logs if not l.get("missed_workout"))
    total_missed = sum(1 for l in all_logs if l.get("missed_workout"))
    consistency_rate = (total_workouts / total_logs * 100) if total_logs > 0 else 0
    
    # Weekly stats
    week_ago = (date.today() - timedelta(days=7)).isoformat()
    week_logs = [l for l in all_logs if l.get("date") >= week_ago]
    week_workouts = sum(1 for l in week_logs if not l.get("missed_workout"))
    week_avg_sleep = (sum(l.get("sleep_hours", 0) for l in week_logs)/len(week_logs)) if week_logs else None
    
    # Monthly stats
    month_ago = (date.today() - timedelta(days=30)).isoformat()
    month_logs = [l for l in all_logs if l.get("date") >= month_ago]
    month_workouts = sum(1 for l in month_logs if not l.get("missed_workout"))
    
    # Calculate averages
    all_sleep_hours = [l.get("sleep_hours", 0) for l in all_logs if l.get("sleep_hours")]
    overall_avg_sleep = sum(all_sleep_hours) / len(all_sleep_hours) if all_sleep_hours else None
    
    # Activity level distribution
    activity_distribution = {}
    for l in all_logs:
        energy = l.get("energy_level", "unknown")
        activity_distribution[energy] = activity_distribution.get(energy, 0) + 1
    
    # Streak calculation
    current_streak = 0
    if all_logs:
        sorted_logs = sorted(all_logs, key=lambda x: x.get("date", ""), reverse=True)
        for log in sorted_logs:
            if not log.get("missed_workout"):
                current_streak += 1
            else:
                break

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

    # Get leaderboard for user's age group
    leaderboard_data = []
    user_rank = None
    if current_user:
        age_group = current_user.get("age_group")
        group_profiles = [p for p in user_profiles if p.get("age_group") == age_group]
        group_profiles.sort(key=lambda x: (x.get("level", 1), x.get("experience_points", 0)), reverse=True)
        leaderboard_data = group_profiles[:25]
        
        # Find user's rank
        for idx, profile in enumerate(group_profiles):
            if profile.get("user_id") == user_id:
                user_rank = idx + 1
                break
    
    # Get latest AI recommendation
    latest_recommendation = None
    if decisions:
        latest_decision = decisions[0]  # Most recent decision
        latest_recommendation = latest_decision.get("ai_recommendation")

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
        current_user=current_user,
        leaderboard_data=leaderboard_data,
        user_rank=user_rank,
        total_workouts=total_workouts,
        total_missed=total_missed,
        consistency_rate=consistency_rate,
        week_workouts=week_workouts,
        week_avg_sleep=week_avg_sleep,
        month_workouts=month_workouts,
        overall_avg_sleep=overall_avg_sleep,
        current_streak=current_streak,
        activity_distribution=activity_distribution,
        latest_recommendation=latest_recommendation,
    )


@app.route("/log", methods=["GET", "POST"])
def log_today():
    data = read_data()
    if request.method == "POST":
        user_id = session.get("user_id") or data["settings"].get("user_id")
        stress = request.form.get("stress")
        sleep_hours = float(request.form.get("sleep_hours", 0) or 0)
        energy = request.form.get("energy")
        # Checkbox "missed" is checked when workout is missed
        missed = True if request.form.get("missed") == "on" else False
        
        # Get new optional fields
        mood = request.form.get("mood", "")
        water_intake = request.form.get("water_intake")
        water_intake = int(water_intake) if water_intake else None
        steps = request.form.get("steps")
        steps = int(steps) if steps else None
        calories = request.form.get("calories")
        calories = int(calories) if calories else None
        weight = request.form.get("weight")
        weight = float(weight) if weight else None
        workout_type = request.form.get("workout_type", "")
        workout_duration = request.form.get("workout_duration")
        workout_duration = int(workout_duration) if workout_duration else None
        notes = request.form.get("notes", "")

        entry = {
            "user_id": user_id,
            "date": date.today().isoformat(),
            "missed_workout": missed,
            "stress_level": stress,
            "sleep_hours": sleep_hours,
            "energy_level": energy,
            "mood": mood,
            "water_intake": water_intake,
            "steps": steps,
            "calories": calories,
            "weight": weight,
            "workout_type": workout_type,
            "workout_duration": workout_duration,
            "notes": notes
        }
        data["daily_logs"].append(entry)
        
        # Update user profile if exists
        user_profiles = data.get("user_profiles", [])
        for profile in user_profiles:
            if profile.get("user_id") == user_id:
                # Update total logs
                profile["total_logs"] = profile.get("total_logs", 0) + 1
                
                # Update workouts completed if not missed
                if not missed:
                    profile["workouts_completed"] = profile.get("workouts_completed", 0) + 1
                
                # Recalculate experience points and level
                activity_level = profile.get("activity_level", "sedentary")
                profile["experience_points"] = calculate_experience_points(activity_level, profile["total_logs"])
                
                # Level increases based on experience points
                base_level = calculate_level(activity_level)
                experience_bonus = profile["experience_points"] // 50  # Every 50 XP = +1 level
                profile["level"] = min(10, base_level + experience_bonus)  # Cap at level 10
                break
        
        write_data(data)

        # compute plan
        # compute missed_days from last 30 logs
        recent = data["daily_logs"][-30:]
        user_logs = [l for l in recent if l.get("user_id") == user_id]
        missed_days = sum(1 for l in user_logs if l.get("missed_workout"))
        user_state = {"missed_days": missed_days, "stress": stress, "sleep_hours": sleep_hours, "energy": energy}
        
        # Get user profile for personalized recommendations
        current_user_profile = None
        user_profiles = data.get("user_profiles", [])
        for profile in user_profiles:
            if profile.get("user_id") == user_id:
                current_user_profile = profile
                break
        
        # Get recent logs for AI analysis (last 14 days)
        recent_for_ai = user_logs[-14:] if len(user_logs) > 14 else user_logs
        
        plan = decide_plan(user_state, recent_logs=recent_for_ai, user_profile=current_user_profile)

        decision = {
            "user_id": user_id,
            "date": date.today().isoformat(),
            "goal_status": plan["goal"],
            "wellness_state": plan["wellness"],
            "final_plan": plan["plan"],
            "ai_recommendation": plan.get("ai_recommendation")
        }
        data["agent_decisions"].append(decision)
        write_data(data)

        flash("Check-in saved! Check your dashboard for AI-powered recommendations on what to do next.", "success")
        return redirect(url_for("index"))

    return render_template("log.html")


@app.route("/history")
def history():
    data = read_data()
    return render_template("history.html", logs=list(reversed(data.get("daily_logs", []))), decisions=list(reversed(data.get("agent_decisions", []))))


@app.route("/programs")
def programs():
    data = read_data()
    user_id = session.get("user_id") or data["settings"].get("user_id")
    
    # Get current user profile
    current_user = None
    user_profiles = data.get("user_profiles", [])
    for profile in user_profiles:
        if profile.get("user_id") == user_id:
            current_user = profile
            break
    
    return render_template("programs.html", current_user=current_user)

@app.route("/programs/<program_type>")
def program_detail(program_type):
    data = read_data()
    user_id = session.get("user_id") or data["settings"].get("user_id")
    
    # Get current user profile
    current_user = None
    user_profiles = data.get("user_profiles", [])
    for profile in user_profiles:
        if profile.get("user_id") == user_id:
            current_user = profile
            break
    
    # Get user level (default to 1 if no user)
    user_level = current_user.get("level", 1) if current_user else 1
    
    # Import workout generator
    from agents.workout_generator import get_workouts_for_program
    
    # Get workout suggestions
    workout_plan = get_workouts_for_program(program_type, user_level)
    
    return render_template("program_detail.html", 
                         program_type=program_type, 
                         workout_plan=workout_plan,
                         current_user=current_user)


@app.route("/profile", methods=["GET", "POST"])
def profile():
    data = read_data()
    user_id = session.get("user_id") or data["settings"].get("user_id")
    
    # Get current user profile
    current_user = None
    user_profiles = data.get("user_profiles", [])
    for profile in user_profiles:
        if profile.get("user_id") == user_id:
            current_user = profile
            break
    
    if request.method == "POST":
        if not current_user:
            flash("Please login to update your profile.", "danger")
            return redirect(url_for("login"))
        
        # Update profile fields
        current_user["name"] = request.form.get("name", current_user.get("name"))
        current_user["age"] = int(request.form.get("age", current_user.get("age", 0)))
        current_user["height"] = float(request.form.get("height", current_user.get("height", 0)))
        current_user["weight"] = float(request.form.get("weight", current_user.get("weight", 0)))
        current_user["activity_level"] = request.form.get("activity_level", current_user.get("activity_level"))
        current_user["goal"] = request.form.get("goal", current_user.get("goal"))
        
        # Handle age group update
        age = current_user["age"]
        current_user["age_group"] = get_age_group(age)
        
        # Handle profile photo update
        if "profile_photo" in request.files:
            file = request.files["profile_photo"]
            if file.filename:
                file_data = file.read()
                current_user["profile_photo"] = base64.b64encode(file_data).decode('utf-8')
        
        # Update password if provided
        new_password = request.form.get("new_password")
        if new_password and len(new_password) >= 6:
            current_user["password_hash"] = hash_password(new_password)
            flash("Password updated successfully.", "success")
        
        # Update session name
        session["user_name"] = current_user["name"]
        
        # Save data
        write_data(data)
        flash("Profile updated successfully!", "success")
        return redirect(url_for("profile"))
    
    return render_template("profile.html", current_user=current_user, settings=data.get("settings", {}))


@app.route("/analytics")
def analytics():
    data = read_data()
    user_id = session.get("user_id") or data["settings"].get("user_id")
    
    # Get current user profile
    current_user = None
    user_profiles = data.get("user_profiles", [])
    for profile in user_profiles:
        if profile.get("user_id") == user_id:
            current_user = profile
            break
    
    # Get user's logs
    user_logs = [l for l in data.get("daily_logs", []) if l.get("user_id") == user_id]
    logs = list(reversed(user_logs))
    
    # compute KPIs
    recent = logs[:14]
    all_logs = logs
    total_logs = len(all_logs)
    missed = sum(1 for l in recent if l.get("missed_workout"))
    avg_sleep = (sum(l.get("sleep_hours", 0) for l in recent)/len(recent)) if recent else None
    
    # Calculate comprehensive analytics
    total_workouts = sum(1 for l in all_logs if not l.get("missed_workout"))
    total_missed = sum(1 for l in all_logs if l.get("missed_workout"))
    consistency_rate = (total_workouts / total_logs * 100) if total_logs > 0 else 0
    
    # Weekly stats
    week_ago = (date.today() - timedelta(days=7)).isoformat()
    week_logs = [l for l in all_logs if l.get("date") >= week_ago]
    week_workouts = sum(1 for l in week_logs if not l.get("missed_workout"))
    week_avg_sleep = (sum(l.get("sleep_hours", 0) for l in week_logs)/len(week_logs)) if week_logs else None
    
    # Monthly stats
    month_ago = (date.today() - timedelta(days=30)).isoformat()
    month_logs = [l for l in all_logs if l.get("date") >= month_ago]
    month_workouts = sum(1 for l in month_logs if not l.get("missed_workout"))
    
    # Calculate averages
    all_sleep_hours = [l.get("sleep_hours", 0) for l in all_logs if l.get("sleep_hours")]
    overall_avg_sleep = sum(all_sleep_hours) / len(all_sleep_hours) if all_sleep_hours else None
    
    # Activity level distribution
    activity_distribution = {}
    for l in all_logs:
        energy = l.get("energy_level", "unknown")
        activity_distribution[energy] = activity_distribution.get(energy, 0) + 1
    
    # Streak calculation
    current_streak = 0
    if all_logs:
        sorted_logs = sorted(all_logs, key=lambda x: x.get("date", ""), reverse=True)
        for log in sorted_logs:
            if not log.get("missed_workout"):
                current_streak += 1
            else:
                break
    
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
        "analytics.html",
        total_logs=total_logs,
        missed=missed,
        avg_sleep=avg_sleep,
        sleep_series=sleep_series,
        sleep_labels=sleep_labels,
        stress_counts=stress_counts,
        energy_counts=energy_counts,
        current_user=current_user,
        total_workouts=total_workouts,
        total_missed=total_missed,
        consistency_rate=consistency_rate,
        week_workouts=week_workouts,
        week_avg_sleep=week_avg_sleep,
        month_workouts=month_workouts,
        overall_avg_sleep=overall_avg_sleep,
        current_streak=current_streak,
        activity_distribution=activity_distribution,
    )


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
