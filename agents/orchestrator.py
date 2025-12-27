from agents.goal_agent import evaluate_goal
from agents.wellness_agent import check_wellness
from agents.fitness_agent import plan_workout

def decide_plan(user_state):
    goal_status = evaluate_goal(user_state["missed_days"])
    wellness_state = check_wellness(
        user_state["stress"],
        user_state["sleep_hours"]
    )

    if wellness_state == "recovery":
        return {
            "goal": goal_status,
            "wellness": wellness_state,
            "plan": ["breathing", "light walk"]
        }

    workout = plan_workout(goal_status, user_state["energy"])
    return {
        "goal": goal_status,
        "wellness": wellness_state,
        "plan": workout
    }
