from flask import Flask, render_template, request, redirect, url_for, flash, jsonify, session
from agents.orchestrator import decide_plan
from datetime import datetime, date, timedelta
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
    # default structure
    default_data = {
        "daily_logs": [], 
        "agent_decisions": [], 
        "user_profiles": [],
        "medical_records": [],
        "medications": [],
        "vaccinations": [],
        "meals": [],
        "personal_goals": [],
        "hydration_logs": [],
        "settings": {"user_id": "11111111-1111-1111-1111-111111111111", "use_supabase": False}
    }

    if os.path.exists(DATA_FILE):
        try:
            with open(DATA_FILE, "r", encoding="utf-8") as f:
                local = json.load(f)
            # Ensure all keys from default_data are present
            for key, value in default_data.items():
                if key not in local:
                    local[key] = value
        except Exception:
            local = default_data
    else:
        local = default_data
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
    
    # Streaks calculation
    current_streak = 0
    if all_logs:
        sorted_logs = sorted(all_logs, key=lambda x: x.get("date", ""), reverse=True)
        for log in sorted_logs:
            if not log.get("missed_workout"):
                current_streak += 1
            else:
                break

    # Calculate Wellness Score (0-100)
    wellness_score = 0
    if logs:
        latest = logs[0]
        # Stress component (max 30)
        stress_map = {"low": 30, "medium": 15, "high": 5, "unknown": 15}
        wellness_score += stress_map.get(latest.get("stress_level", "medium"), 15)
        
        # Sleep component (max 30)
        sleep = latest.get("sleep_hours", 0)
        if sleep >= 7: wellness_score += 30
        elif sleep >= 6: wellness_score += 20
        elif sleep >= 5: wellness_score += 10
        else: wellness_score += 5
        
        # Energy component (max 20)
        energy_map = {"high": 20, "medium": 15, "low": 5, "unknown": 10}
        wellness_score += energy_map.get(latest.get("energy_level", "medium"), 10)
        
        # Activity/Consistency component (max 20)
        wellness_score += min(20, current_streak * 2 + (10 if not latest.get("missed_workout") else 0))
    else:
        wellness_score = 0

    # Enhanced Agentic AI Insights
    friendly_advice = {
        "greeting": f"Good morning, {current_user.get('name', 'Champion') if current_user else 'Champion'}!",
        "mood_prompt": "How are you feeling today?",
        "coach_msg": "You're doing great! Keep focusing on your recovery today.",
        "prediction": "You might feel a bit tired tomorrow, try an earlier bedtime!",
        "agent_thoughts": "Analyzing your recent heart rate and activity levels... I see a healthy trend in your recovery phases.",
        "suggestions": [
            {"icon": "🥗", "text": "Add more leafy greens to your next meal"},
            {"icon": "🏃", "text": "15 min light stretching this evening"},
            {"icon": "📵", "text": "Set digital bedtime 1 hour early"}
        ]
    }
    
    if logs:
        latest = logs[0]
        if latest.get("stress_level") == "high":
            friendly_advice["coach_msg"] = "I noticed things are a bit stressful. Maybe try 5 minutes of mindful breathing? 🌿"
            friendly_advice["prediction"] = "High stress can affect your sleep. Consider a screen-free hour before bed."
            friendly_advice["agent_thoughts"] = "Your cortisol spikes correlate with late-night screen time. I'm prioritizing calming activities today."
            friendly_advice["suggestions"] = [
                {"icon": "🧘", "text": "5-min Deep Breathing"},
                {"icon": "🎧", "text": "Listen to a focus soundscape"},
                {"icon": "☕", "text": "Switch to herbal tea after 4 PM"}
            ]
        elif latest.get("sleep_hours", 7) < 6:
            friendly_advice["coach_msg"] = "Sleep was a bit short. It's okay to take it easy today! A light walk might feel good. 🚶"
            friendly_advice["prediction"] = "Your energy might dip later today. Stay hydrated! 💧"
            friendly_advice["agent_thoughts"] = "Sleep deprivation detected. Adjusting recommendations to low-impact recovery and optimization."
            friendly_advice["suggestions"] = [
                {"icon": "🛏️", "text": "Planned 20-min power nap"},
                {"icon": "💧", "text": "Increase water intake by 2 glasses"},
                {"icon": "🕶️", "text": "Blue light filters on all devices"}
            ]
        elif not latest.get("missed_workout"):
            friendly_advice["coach_msg"] = "Awesome job on your workout! Your body will thank you for the consistency. ✨"
            friendly_advice["prediction"] = "You're building great momentum. Tomorrow looks like a strong day for you!"
            friendly_advice["agent_thoughts"] = "Muscle protein synthesis is peaking. I'm suggesting nutrient-dense recovery options."
            friendly_advice["suggestions"] = [
                {"icon": "🍗", "text": "Priority: 40g Protein Post-load"},
                {"icon": "🛁", "text": "Epsom salt bath for recovery"},
                {"icon": "🎯", "text": "Level Up: Increase intensity by 5% tomorrow"}
            ]

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
    
    # Calculate daily nutrition
    today_str = date.today().isoformat()
    today_meals = [m for m in data.get("meals", []) if m.get("user_id") == user_id and m.get("date") == today_str]
    today_calories = sum(m.get("calories", 0) for m in today_meals)
    
    today_log = next((l for l in logs if l.get("date") == today_str), {})
    today_water = today_log.get("water_intake", 0) or 0
    today_steps = today_log.get("steps", 0) or 0
    today_hr = today_log.get("heart_rate")
    
    # Clinical Alerts logic
    alerts = []
    if today_hr and today_hr > 100:
        alerts.append({"type": "warning", "msg": "High resting heart rate detected today. Consider rhythmic breathing."})
    if today_water < 4 and logs:
        alerts.append({"type": "info", "msg": "Hydration is low. Try to drink 2 more glasses before 6 PM."})
    if today_steps > 0 and today_steps < 3000:
        alerts.append({"type": "info", "msg": "Movement is lower than your average. A 5-minute walk can help!"})

    # Medical-Aware Coaching
    user_meds = [m for m in data.get("medications", []) if m.get("user_id") == user_id]
    user_records = [r for r in data.get("medical_records", []) if r.get("user_id") == user_id]
    
    if user_meds:
        med_names = [m['name'] for m in user_meds]
        friendly_advice["coach_msg"] += f" Don't forget your {', '.join(med_names)} today! 💊"
    
    if any("blood" in r.get("title", "").lower() for r in user_records):
        friendly_advice["coach_msg"] += " I see your recent blood report in the vault. Your iron levels were a bit low—try adding some spinach to your lunch today! 🥗"

    # Unusual Pattern Alerts (Deeper analysis)
    if len(logs) > 3:
        avg_bedtime = sum(float(l.get("sleep_hours", 7)) for l in logs[1:4]) / 3
        if abs(float(latest.get("sleep_hours", 7)) - avg_bedtime) > 2:
            alerts.append({"type": "warning", "msg": "Significant shift in sleep routine detected. Consistency is key for circadian rhythm."})

    # Personal Goals
    user_goals = [g for g in data.get("personal_goals", []) if g.get("user_id") == user_id]

    # Calculate Badges
    user_badges = []
    if today_water >= 8:
        user_badges.append({"icon": "💧", "name": "Hydration Hero", "desc": "Goal reached!"})
    if current_streak >= 3:
        user_badges.append({"icon": "🔥", "name": "Consistency King", "desc": "3+ Day Streak"})
    if avg_sleep and avg_sleep >= 8:
        user_badges.append({"icon": "💤", "name": "Sleep Master", "desc": "Optimal Rest"})
    if total_workouts >= 10:
        user_badges.append({"icon": "💪", "name": "Iron Will", "desc": "10 Workouts"})

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
        wellness_score=wellness_score,
        friendly_advice=friendly_advice,
        today_water=today_water,
        today_calories=today_calories,
        today_steps=today_steps,
        alerts=alerts,
        user_goals=user_goals,
        user_badges=user_badges
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

        distance = request.form.get("distance")
        distance = float(distance) if distance else None
        heart_rate = request.form.get("heart_rate")
        heart_rate = int(heart_rate) if heart_rate else None

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
            "distance": distance,
            "heart_rate": heart_rate,
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

@app.route("/medical", methods=["GET", "POST"])
def medical():
    if not session.get("user_id"):
        return redirect(url_for("login"))
    
    data = read_data()
    user_id = session.get("user_id")
    
    if request.method == "POST":
        m_type = request.form.get("type")
        if m_type == "medication":
            med = {
                "id": str(uuid.uuid4()),
                "user_id": user_id,
                "name": request.form.get("name"),
                "dosage": request.form.get("dosage"),
                "frequency": request.form.get("frequency"),
                "start_date": request.form.get("start_date"),
                "notes": request.form.get("notes")
            }
            data["medications"].append(med)
        elif m_type == "vaccination":
            vac = {
                "id": str(uuid.uuid4()),
                "user_id": user_id,
                "name": request.form.get("name"),
                "date": request.form.get("date"),
                "provider": request.form.get("provider"),
                "notes": request.form.get("notes")
            }
            data["vaccinations"].append(vac)
        elif m_type == "report":
            ref = {
                "id": str(uuid.uuid4()),
                "user_id": user_id,
                "title": request.form.get("title"),
                "date": request.form.get("date"),
                "facility": request.form.get("facility"),
                "notes": request.form.get("notes")
            }
            data["medical_records"].append(ref)
        
        write_data(data)
        flash("Record saved successfully!", "success")
        return redirect(url_for("medical"))

    user_meds = [m for m in data.get("medications", []) if m.get("user_id") == user_id]
    user_vacs = [v for v in data.get("vaccinations", []) if v.get("user_id") == user_id]
    user_records = [r for r in data.get("medical_records", []) if r.get("user_id") == user_id]
    
    return render_template("medical.html", medications=user_meds, vaccinations=user_vacs, records=user_records)

@app.route("/nutrition", methods=["GET", "POST"])
def nutrition():
    if not session.get("user_id"):
        return redirect(url_for("login"))
        
    data = read_data()
    user_id = session.get("user_id")
    
    if request.method == "POST":
        def get_int(field):
            val = request.form.get(field, "0")
            return int(val) if val and val.strip() else 0

        meal = {
            "id": str(uuid.uuid4()),
            "user_id": user_id,
            "date": date.today().isoformat(),
            "time": datetime.now().strftime("%H:%M"),
            "name": request.form.get("name"),
            "calories": get_int("calories"),
            "protein": get_int("protein"),
            "carbs": get_int("carbs"),
            "fats": get_int("fats")
        }
        data["meals"].append(meal)
        write_data(data)
        flash("Meal logged!", "success")
        return redirect(url_for("nutrition"))

    today_meals = [m for m in data.get("meals", []) if m.get("user_id") == user_id and m.get("date") == date.today().isoformat()]
    today_water = [h for h in data.get("hydration_logs", []) if h.get("user_id") == user_id and h.get("date") == date.today().isoformat()]
    
    summary = {
        "calories": sum(m.get("calories", 0) for m in today_meals),
        "protein": sum(m.get("protein", 0) for m in today_meals),
        "carbs": sum(m.get("carbs", 0) for m in today_meals),
        "fats": sum(m.get("fats", 0) for m in today_meals),
        "water_count": len(today_water)
    }

    return render_template("nutrition.html", meals=today_meals, summary=summary, today_str=date.today().strftime("%B %d, %Y"))

@app.route("/api/log-water", methods=["POST"])
def log_water():
    if not session.get("user_id"):
        return jsonify({"success": False, "error": "Unauthorized"}), 401
        
    data = read_data()
    user_id = session.get("user_id")
    
    log = {
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "date": date.today().isoformat(),
        "time": datetime.now().strftime("%H:%M")
    }
    
    if "hydration_logs" not in data:
        data["hydration_logs"] = []
        
    data["hydration_logs"].append(log)
    write_data(data)
    
    today_count = len([h for h in data["hydration_logs"] if h.get("user_id") == user_id and h.get("date") == date.today().isoformat()])
    return jsonify({"success": True, "count": today_count})


@app.route("/goals", methods=["GET", "POST"])
def goals():
    if not session.get("user_id"):
        return redirect(url_for("login"))
    
    data = read_data()
    user_id = session.get("user_id")
    
    if request.method == "POST":
        goal = {
            "id": str(uuid.uuid4()),
            "user_id": user_id,
            "title": request.form.get("title"),
            "target": request.form.get("target"),
            "deadline": request.form.get("deadline"),
            "category": request.form.get("category"),
            "progress": 0,
            "status": "active"
        }
        data["personal_goals"].append(goal)
        write_data(data)
        flash("Goal set! Let's crush it. 🚀", "success")
        return redirect(url_for("goals"))

    user_goals = [g for g in data.get("personal_goals", []) if g.get("user_id") == user_id]
    return render_template("goals.html", goals=user_goals)

@app.route("/wearables")
def wearables():
    if not session.get("user_id"):
        return redirect(url_for("login"))
    return render_template("wearables.html")

@app.route("/meditation")
def meditation():
    if not session.get("user_id"):
        return redirect(url_for("login"))
    return render_template("meditation.html")

@app.route("/history")
def history():
    if not session.get("user_id"):
        return redirect(url_for("login"))
    
    data = read_data()
    user_id = session.get("user_id")
    
    user_logs = [l for l in data.get("daily_logs", []) if l.get("user_id") == user_id]
    user_decisions = [d for d in data.get("agent_decisions", []) if d.get("user_id") == user_id]
    
    # Sort by date descending
    user_logs = sorted(user_logs, key=lambda x: x.get("date", ""), reverse=True)
    user_decisions = sorted(user_decisions, key=lambda x: x.get("date", ""), reverse=True)
    
    return render_template("history.html", logs=user_logs, decisions=user_decisions)


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


@app.route("/api/sync-fitness", methods=["POST"])
def sync_fitness():
    user_id = session.get("user_id")
    if not user_id:
        return json.dumps({"error": "Unauthorized"}), 401
    
    # Simulate fetching from a smartphone fitness app (e.g. Google Fit, Apple Health)
    import random
    synced_data = {
        "steps": random.randint(5000, 12000),
        "hrv": random.randint(40, 95), # Heart Rate Variability
        "vo2max": random.randint(35, 55),
        "active_minutes": random.randint(30, 90),
        "last_sync": datetime.now().strftime("%I:%M %p")
    }
    
    # Persist the sync status to user profile
    data = read_data()
    for profile in data["user_profiles"]:
        if profile.get("user_id") == user_id:
            profile["fitness_sync"] = synced_data
            break
    write_data(data)
    
    return json.dumps({"status": "success", "data": synced_data})

@app.route("/api/decisions", methods=["GET"])
def api_decisions():
    data = read_data()
    return json.dumps(list(reversed(data.get("agent_decisions", []))))


@app.route("/settings", methods=["GET", "POST"])
def settings():
    if not session.get("user_id"):
        return redirect(url_for("login"))
    
    data = read_data()
    user_id = session.get("user_id")
    
    if request.method == "POST":
        # Handle Supabase setting
        use_supabase = True if request.form.get("use_supabase") == "on" else False
        data["settings"]["use_supabase"] = use_supabase
        
        # Handle user settings if needed
        write_data(data)
        flash("Settings updated!", "success")
        return redirect(url_for("settings"))
        
    return render_template("settings.html", settings=data.get("settings", {}))

# API Actions
@app.route("/api/delete-item", methods=["POST"])
def delete_item():
    if not session.get("user_id"):
        return jsonify({"success": False, "error": "Unauthorized"}), 401
    
    req = request.json
    item_type = req.get("type")
    item_id = req.get("id")
    
    if not item_type or not item_id:
        return jsonify({"success": False, "error": "Missing parameters"}), 400
        
    data = read_data()
    user_id = session.get("user_id")
    
    # Map item types to data keys
    type_map = {
        "meal": "meals",
        "medication": "medications",
        "vaccination": "vaccinations",
        "report": "medical_records",
        "goal": "personal_goals"
    }
    
    key = type_map.get(item_type)
    if not key:
        return jsonify({"success": False, "error": "Invalid item type"}), 400
        
    # Find and remove the item
    original_len = len(data.get(key, []))
    data[key] = [item for item in data.get(key, []) if not (item.get("id") == item_id and item.get("user_id") == user_id)]
    
    if len(data[key]) < original_len:
        write_data(data)
        return jsonify({"success": True})
    else:
        return jsonify({"success": False, "error": "Item not found"}), 404

@app.route("/api/update-goal-progress", methods=["POST"])
def update_goal_progress():
    if not session.get("user_id"):
        return jsonify({"success": False, "error": "Unauthorized"}), 401
    
    req = request.json
    goal_id = req.get("id")
    increment = req.get("increment", 10)
    
    data = read_data()
    user_id = session.get("user_id")
    
    for goal in data.get("personal_goals", []):
        if goal.get("id") == goal_id and goal.get("user_id") == user_id:
            goal["progress"] = min(100, goal.get("progress", 0) + increment)
            write_data(data)
            return jsonify({"success": True, "new_progress": goal["progress"]})
            
    return jsonify({"success": False, "error": "Goal not found"}), 404

@app.route("/api/log-mood", methods=["POST"])
def log_mood():
    if not session.get("user_id"):
        return jsonify({"success": False, "error": "Unauthorized"}), 401
    
    req = request.json
    mood = req.get("mood")
    
    if not mood:
        return jsonify({"success": False, "error": "Missing mood"}), 400
        
    data = read_data()
    user_id = session.get("user_id")
    today = date.today().isoformat()
    
    # Check if a log exists for today
    log_found = False
    for log in data.get("daily_logs", []):
        if log.get("user_id") == user_id and log.get("date") == today:
            log["mood"] = mood
            log_found = True
            break
            
    if not log_found:
        # Create a partial log for today with just the mood
        new_log = {
            "id": str(uuid.uuid4()), # Added UUID for new log
            "user_id": user_id,
            "date": today,
            "mood": mood,
            "stress_level": "medium", # defaults
            "sleep_hours": 0,
            "energy_level": "medium",
            "missed_workout": False
        }
        data["daily_logs"].append(new_log)
        
    write_data(data)
    return jsonify({"success": True})


if __name__ == "__main__":
    # bind to localhost on port 3000 per user request
    app.run(host="127.0.0.1", port=3000, debug=True)
