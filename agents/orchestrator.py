from agents.goal_agent import evaluate_goal
from agents.wellness_agent import check_wellness
from agents.fitness_agent import plan_workout
from agents.recommendation_agent import generate_ai_recommendation

def decide_plan(user_state, recent_logs=None, user_profile=None):
    """
    Enhanced plan decision with AI recommendations
    
    Args:
        user_state: Dictionary with missed_days, stress, sleep_hours, energy
        recent_logs: List of recent daily logs (optional, for AI analysis)
        user_profile: User profile dictionary (optional, for personalized recommendations)
    
    Returns:
        Dictionary with goal, wellness, plan, and ai_recommendation
    """
    goal_status = evaluate_goal(user_state["missed_days"])
    wellness_state = check_wellness(
        user_state["stress"],
        user_state["sleep_hours"]
    )

    if wellness_state == "recovery":
        workout_plan = ["breathing", "light walk"]
    else:
        workout = plan_workout(goal_status, user_state["energy"])
        workout_plan = workout
    
    # Generate AI recommendation if we have recent logs
    ai_recommendation = None
    if recent_logs:
        ai_recommendation = generate_ai_recommendation(user_state, recent_logs, user_profile)
    
    return {
        "goal": goal_status,
        "wellness": wellness_state,
        "plan": workout_plan,
        "ai_recommendation": ai_recommendation
    }
