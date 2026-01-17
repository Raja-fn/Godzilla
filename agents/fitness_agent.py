def plan_workout(goal_status, energy):
    if goal_status == "at_risk" or energy == "low":
        return ["10 min walk", "stretching"]
    return ["20 min cardio", "bodyweight workout"]

def suggest_fitness(level):
    return "Light activity" if level == "low" else "Moderate activity"
