def evaluate_goal(missed_days):
    if missed_days >= 3:
        return "at_risk"
    return "on_track"
