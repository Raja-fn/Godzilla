def decide_plan(signals):
    reasoning = []
    plan = []

    if signals["sleep"] < 5:
        reasoning.append("Low sleep detected")
        plan.append("Breathing – 3 min")
        plan.append("Light walk – 5 min")
    else:
        reasoning.append("Sufficient sleep")
        plan.append("Moderate workout – 15 min")

    if signals["missed"]:
        reasoning.append("Previous plan missed, reducing difficulty")

    return plan, reasoning
