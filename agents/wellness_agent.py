def check_wellness(stress, sleep):
    if stress == "high" or sleep < 6:
        return "recovery"
    return "normal"
