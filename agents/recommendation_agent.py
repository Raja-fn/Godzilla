"""
AI Recommendation Agent with LLM integration
Analyzes user's overall health data and provides personalized next-day recommendations
"""
import os
from dotenv import load_dotenv

# Try to import LLM libraries
try:
    from openai import OpenAI
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False

try:
    from anthropic import Anthropic
    ANTHROPIC_AVAILABLE = True
except ImportError:
    ANTHROPIC_AVAILABLE = False

try:
    from agents.ml_predictor import get_predictor
    ML_AVAILABLE = True
except ImportError:
    try:
        from agents.ml_predictor import get_predictor
        ML_AVAILABLE = True
    except ImportError:
        ML_AVAILABLE = False

load_dotenv()

def generate_llm_recommendation(user_state, recent_logs, user_profile=None, use_openai=True):
    """
    Generate recommendation using LLM API (OpenAI or Anthropic)
    
    Args:
        user_state: Current user state
        recent_logs: Recent daily logs
        user_profile: User profile
        use_openai: If True, use OpenAI; if False, use Anthropic
    
    Returns:
        dict with LLM-generated recommendation
    """
    # Prepare context for LLM
    stress = user_state.get("stress", "medium")
    sleep_hours = user_state.get("sleep_hours", 7)
    energy = user_state.get("energy", "medium")
    missed_days = user_state.get("missed_days", 0)
    
    # Get ML predictions if available
    workout_prob = 0.7
    predicted_energy = 5.0
    if ML_AVAILABLE:
        try:
            predictor = get_predictor()
            workout_prob = predictor.predict_workout_completion(user_state, recent_logs, user_profile)
            predicted_energy = predictor.predict_energy_level(user_state, recent_logs, user_profile)
        except Exception:
            pass
    
    # Build context string
    context = f"""User Profile:
- Age: {user_profile.get('age', 'N/A') if user_profile else 'N/A'}
- Activity Level: {user_profile.get('activity_level', 'N/A') if user_profile else 'N/A'}
- Goal: {user_profile.get('goal', 'N/A') if user_profile else 'N/A'}

Current State:
- Stress Level: {stress}
- Sleep Hours: {sleep_hours}
- Energy Level: {energy}
- Missed Workouts (last 30 days): {missed_days}

ML Predictions:
- Workout Completion Probability: {workout_prob:.1%}
- Predicted Tomorrow's Energy: {predicted_energy:.1f}/10

Recent Patterns (last {len(recent_logs)} days):
"""
    
    if recent_logs:
        avg_sleep = sum(log.get("sleep_hours", 7) for log in recent_logs) / len(recent_logs)
        workouts_completed = sum(1 for log in recent_logs if not log.get("missed_workout"))
        context += f"- Average Sleep: {avg_sleep:.1f} hours\n"
        context += f"- Workouts Completed: {workouts_completed}/{len(recent_logs)}\n"
    
    prompt = f"""{context}

Based on this information, provide a personalized fitness and wellness recommendation for tomorrow. 
Include:
1. A specific action to take
2. 3-4 practical tips
3. Priority level (high/medium/low)
4. A motivational message

Format your response as a brief, actionable recommendation."""

    try:
        if use_openai and OPENAI_AVAILABLE:
            api_key = os.getenv("OPENAI_API_KEY")
            if not api_key:
                return None
            
            client = OpenAI(api_key=api_key)
            response = client.chat.completions.create(
                model="gpt-4o-mini",  # or "gpt-3.5-turbo" for cheaper option
                messages=[
                    {"role": "system", "content": "You are a fitness and wellness coach providing personalized recommendations."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.7,
                max_tokens=300
            )
            
            llm_text = response.choices[0].message.content
            
        elif not use_openai and ANTHROPIC_AVAILABLE:
            api_key = os.getenv("ANTHROPIC_API_KEY")
            if not api_key:
                return None
            
            client = Anthropic(api_key=api_key)
            response = client.messages.create(
                model="claude-3-haiku-20240307",  # or "claude-3-sonnet-20240229"
                max_tokens=300,
                messages=[
                    {"role": "user", "content": prompt}
                ]
            )
            
            llm_text = response.content[0].text
        
        else:
            return None
        
        # Parse LLM response (simple parsing - you can enhance this)
        return {
            "llm_generated": True,
            "llm_text": llm_text,
            "workout_probability": workout_prob,
            "predicted_energy": predicted_energy
        }
    
    except Exception as e:
        print(f"LLM API error: {e}")
        return None

def generate_ai_recommendation(user_state, recent_logs, user_profile=None, use_llm=True):
    """
    Generate comprehensive AI-powered recommendations
    Now with ML predictions and optional LLM integration
    
    Args:
        user_state: Current user state (stress, sleep_hours, energy, missed_days)
        recent_logs: Recent daily logs (last 7-14 days)
        user_profile: User profile with goals, activity level, etc.
        use_llm: Whether to use LLM API (requires API key)
    
    Returns:
        dict with recommendation details including title, description, actions, and priority
    """
    
    # Try to get LLM recommendation first
    llm_rec = None
    if use_llm:
        llm_rec = generate_llm_recommendation(user_state, recent_logs, user_profile)
    
    # Get ML predictions
    workout_prob = 0.7
    predicted_energy = 5.0
    if ML_AVAILABLE:
        try:
            predictor = get_predictor()
            workout_prob = predictor.predict_workout_completion(user_state, recent_logs, user_profile)
            predicted_energy = predictor.predict_energy_level(user_state, recent_logs, user_profile)
        except Exception as e:
            print(f"ML prediction error: {e}")
    
    stress = user_state.get("stress", "medium")
    sleep_hours = user_state.get("sleep_hours", 7)
    energy = user_state.get("energy", "medium")
    missed_days = user_state.get("missed_days", 0)
    
    # Analyze recent patterns
    avg_sleep = sum(log.get("sleep_hours", 7) for log in recent_logs) / len(recent_logs) if recent_logs else 7
    avg_stress_high = sum(1 for log in recent_logs if log.get("stress_level") == "high") / len(recent_logs) if recent_logs else 0
    recent_workouts = sum(1 for log in recent_logs if not log.get("missed_workout"))
    
    # If LLM provided recommendation, use it as primary
    if llm_rec:
        return {
            "title": "AI-Powered Recommendation",
            "main_action": llm_rec["llm_text"],
            "tips": [
                f"ML Prediction: {workout_prob:.0%} chance of completing workout tomorrow",
                f"Predicted Energy Level: {predicted_energy:.1f}/10",
                "Based on your patterns and ML analysis"
            ],
            "priority": "high" if missed_days >= 3 or sleep_hours < 6 else "medium",
            "icon": "brain",
            "personalized_message": llm_rec["llm_text"],
            "all_recommendations": [{
                "category": "AI Recommendation",
                "priority": "high",
                "action": llm_rec["llm_text"],
                "tips": ["Generated by LLM with ML insights"],
                "icon": "brain"
            }],
            "ml_insights": {
                "workout_probability": workout_prob,
                "predicted_energy": predicted_energy
            }
        }
    
    # Fallback to rule-based recommendations (original logic) with ML enhancements
    priority_areas = []
    recommendations = []
    
    # Enhanced with ML predictions
    if workout_prob < 0.5:
        recommendations.append({
            "category": "Workout Motivation",
            "priority": "high",
            "action": f"ML predicts {workout_prob:.0%} completion chance. Let's boost this!",
            "tips": [
                "Schedule your workout at a specific time",
                "Start with just 15-20 minutes if motivation is low",
                "Choose activities you enjoy",
                f"Your predicted energy tomorrow: {predicted_energy:.1f}/10"
            ],
            "icon": "dumbbell"
        })
    
    # Sleep Analysis
    if sleep_hours < 6 or avg_sleep < 6.5:
        priority_areas.append("sleep")
        recommendations.append({
            "category": "Sleep Improvement",
            "priority": "high",
            "action": "Aim for 7-9 hours of quality sleep tonight",
            "tips": [
                "Create a bedtime routine 1 hour before sleep",
                "Avoid screens and blue light 30 minutes before bed",
                "Keep your bedroom cool and dark",
                "Try meditation or deep breathing exercises"
            ],
            "icon": "bed"
        })
    
    # Stress Management
    if stress == "high" or avg_stress_high > 0.4:
        priority_areas.append("stress")
        recommendations.append({
            "category": "Stress Management",
            "priority": "high",
            "action": "Focus on stress reduction activities tomorrow",
            "tips": [
                "Start your day with 10 minutes of meditation",
                "Take 3-5 minute breaks every hour for deep breathing",
                "Consider a gentle yoga or stretching session",
                "Spend time in nature or go for a peaceful walk"
            ],
            "icon": "heartbeat"
        })
    
    # Workout Consistency
    if missed_days >= 3 or (recent_logs and recent_workouts / len(recent_logs) < 0.6):
        priority_areas.append("consistency")
        recommendations.append({
            "category": "Workout Consistency",
            "priority": "medium",
            "action": "Commit to completing your workout tomorrow",
            "tips": [
                "Schedule your workout at a specific time",
                "Start with just 15-20 minutes if motivation is low",
                "Choose activities you enjoy",
                "Find an accountability partner or use the app's reminders"
            ],
            "icon": "dumbbell"
        })
    
    # Energy Levels
    if energy == "low" or predicted_energy < 5:
        priority_areas.append("energy")
        recommendations.append({
            "category": "Energy Boost",
            "priority": "medium",
            "action": f"ML predicts energy at {predicted_energy:.1f}/10. Focus on activities that naturally boost your energy",
            "tips": [
                "Take a brisk 10-minute walk in the morning sunlight",
                "Stay hydrated - aim for 8-10 glasses of water",
                "Eat small, balanced meals throughout the day",
                "Listen to uplifting music or podcasts"
            ],
            "icon": "battery-half"
        })
    
    # Weight/Goal Tracking
    if user_profile and user_profile.get("goal"):
        goal = user_profile.get("goal", "").lower()
        if "weight" in goal or "lose" in goal:
            recent_weights = [log.get("weight") for log in recent_logs if log.get("weight")]
            if recent_weights and len(recent_weights) >= 3:
                recommendations.append({
                    "category": "Goal Progress",
                    "priority": "low",
                    "action": "Continue tracking your progress",
                    "tips": [
                        "Maintain a calorie deficit through balanced nutrition",
                        "Combine cardio and strength training",
                        "Track your meals to ensure you're on target",
                        "Be patient - sustainable weight loss takes time"
                    ],
                    "icon": "target"
                })
    
    # Default recommendation
    if not recommendations:
        recommendations.append({
            "category": "Maintain Momentum",
            "priority": "low",
            "action": "Keep up the excellent work! Continue your current routine",
            "tips": [
                "Maintain your current sleep schedule",
                "Keep your workout routine consistent",
                "Stay hydrated and eat balanced meals",
                "Consider trying a new exercise to keep things interesting"
            ],
            "icon": "trophy"
        })
    
    # Get the highest priority recommendation
    priority_order = {"high": 3, "medium": 2, "low": 1}
    main_recommendation = max(recommendations, key=lambda x: priority_order.get(x["priority"], 0))
    
    # Generate personalized message
    user_name = user_profile.get("name", "Champion") if user_profile else "Champion"
    
    if stress == "high" or (avg_stress_high > 0.4 and sleep_hours < 6):
        personalized_msg = "Your check-in shows you're experiencing high stress and low sleep. Here's what we recommend doing next to improve your wellness."
    elif sleep_hours < 6 or avg_sleep < 6.5:
        personalized_msg = "Your sleep patterns need attention. Based on your latest check-in, here's what you should focus on next to improve your rest and recovery."
    elif missed_days >= 3:
        personalized_msg = "We noticed you've missed several workouts. Here's what we recommend doing next to get back on track with your fitness goals."
    elif energy == "low" or predicted_energy < 5:
        personalized_msg = f"Your energy levels are low (ML predicts {predicted_energy:.1f}/10 tomorrow). Based on your latest check-in analysis, here's what you should do next to boost your energy naturally."
    else:
        personalized_msg = "Great progress! Based on your latest check-in analysis, here's what we recommend doing next to continue improving your health and fitness."
    
    return {
        "title": main_recommendation["category"],
        "main_action": main_recommendation["action"],
        "tips": main_recommendation["tips"],
        "priority": main_recommendation["priority"],
        "icon": main_recommendation["icon"],
        "personalized_message": personalized_msg,
        "all_recommendations": recommendations,
        "ml_insights": {
            "workout_probability": workout_prob,
            "predicted_energy": predicted_energy
        }
    }
