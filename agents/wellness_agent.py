def check_wellness(stress, sleep):
    if stress == "high" or sleep < 6:
        return "recovery"
    return "normal"

def suggest_wellness(stress):
    return "Breathing exercise" if stress == "high" else "Normal routine"
