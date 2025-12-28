"""
Workout Generator Agent
Generates workout plans based on program type and user level
"""

def get_workouts_for_program(program_type, user_level):
    """
    Generate workout suggestions based on program type and user level
    
    Args:
        program_type: Type of program (beginner, strength, cardio, wellness, hiit, yoga)
        user_level: User's current level (1-10)
    
    Returns:
        List of workout suggestions with details
    """
    
    # Define workout templates for each program type
    workouts = {
        "beginner": {
            "name": "Beginner Program",
            "description": "Perfect for starting your fitness journey. Focus on building foundational strength and mobility.",
            "workouts": {
                1: [
                    {"name": "Full Body Warm-up", "duration": 10, "exercises": ["Arm circles", "Leg swings", "Neck rolls", "Torso twists"], "rest": 30},
                    {"name": "Bodyweight Squats", "duration": 5, "sets": 2, "reps": 10, "rest": 60},
                    {"name": "Wall Push-ups", "duration": 5, "sets": 2, "reps": 8, "rest": 60},
                    {"name": "Plank Hold", "duration": 5, "sets": 2, "duration_sec": 20, "rest": 60},
                    {"name": "Light Walking", "duration": 10, "type": "cardio"},
                    {"name": "Stretching", "duration": 5, "exercises": ["Hamstring stretch", "Quad stretch", "Shoulder stretch"]}
                ],
                2: [
                    {"name": "Dynamic Warm-up", "duration": 10, "exercises": ["Jumping jacks", "High knees", "Butt kicks", "Arm swings"], "rest": 30},
                    {"name": "Bodyweight Squats", "duration": 8, "sets": 3, "reps": 12, "rest": 45},
                    {"name": "Incline Push-ups", "duration": 8, "sets": 3, "reps": 10, "rest": 45},
                    {"name": "Plank Hold", "duration": 8, "sets": 2, "duration_sec": 30, "rest": 60},
                    {"name": "Bodyweight Lunges", "duration": 8, "sets": 2, "reps": 8, "rest": 45},
                    {"name": "Brisk Walking", "duration": 15, "type": "cardio"},
                    {"name": "Full Body Stretch", "duration": 8}
                ],
                3: [
                    {"name": "Dynamic Warm-up", "duration": 10, "exercises": ["Jumping jacks", "High knees", "Mountain climbers", "Leg swings"], "rest": 20},
                    {"name": "Bodyweight Squats", "duration": 10, "sets": 3, "reps": 15, "rest": 45},
                    {"name": "Push-ups", "duration": 10, "sets": 3, "reps": 12, "rest": 45},
                    {"name": "Plank Hold", "duration": 10, "sets": 3, "duration_sec": 40, "rest": 60},
                    {"name": "Walking Lunges", "duration": 10, "sets": 2, "reps": 12, "rest": 45},
                    {"name": "Moderate Jogging", "duration": 20, "type": "cardio"},
                    {"name": "Full Body Stretch", "duration": 10}
                ]
            }
        },
        "strength": {
            "name": "Strength Training Program",
            "description": "Build muscle and strength with progressive resistance training.",
            "workouts": {
                1: [
                    {"name": "Warm-up", "duration": 10, "exercises": ["Light cardio", "Dynamic stretches", "Joint mobility"], "rest": 30},
                    {"name": "Bodyweight Squats", "duration": 15, "sets": 3, "reps": 12, "rest": 60},
                    {"name": "Push-ups", "duration": 15, "sets": 3, "reps": 10, "rest": 60},
                    {"name": "Plank Hold", "duration": 10, "sets": 3, "duration_sec": 30, "rest": 60},
                    {"name": "Glute Bridges", "duration": 10, "sets": 3, "reps": 12, "rest": 45},
                    {"name": "Cool-down Stretch", "duration": 10}
                ],
                2: [
                    {"name": "Warm-up", "duration": 10, "exercises": ["Jumping jacks", "Arm circles", "Leg swings"], "rest": 20},
                    {"name": "Goblet Squats", "duration": 20, "sets": 4, "reps": 12, "rest": 60},
                    {"name": "Push-ups", "duration": 20, "sets": 4, "reps": 12, "rest": 60},
                    {"name": "Dumbbell Rows", "duration": 15, "sets": 3, "reps": 10, "rest": 60},
                    {"name": "Plank Hold", "duration": 15, "sets": 3, "duration_sec": 45, "rest": 60},
                    {"name": "Cool-down Stretch", "duration": 10}
                ],
                3: [
                    {"name": "Warm-up", "duration": 10, "exercises": ["Light jogging", "Dynamic stretches"], "rest": 20},
                    {"name": "Barbell Squats", "duration": 25, "sets": 4, "reps": 10, "rest": 90},
                    {"name": "Bench Press", "duration": 25, "sets": 4, "reps": 8, "rest": 90},
                    {"name": "Deadlifts", "duration": 20, "sets": 3, "reps": 8, "rest": 120},
                    {"name": "Overhead Press", "duration": 15, "sets": 3, "reps": 8, "rest": 90},
                    {"name": "Pull-ups", "duration": 15, "sets": 3, "reps": 6, "rest": 90},
                    {"name": "Cool-down Stretch", "duration": 10}
                ]
            }
        },
        "cardio": {
            "name": "Cardio Program",
            "description": "Improve cardiovascular health and endurance with varied cardio workouts.",
            "workouts": {
                1: [
                    {"name": "Light Warm-up", "duration": 5, "exercises": ["Walking", "Arm swings", "Leg lifts"], "rest": 30},
                    {"name": "Brisk Walking", "duration": 20, "type": "cardio", "intensity": "moderate"},
                    {"name": "Rest", "duration": 2, "type": "rest"},
                    {"name": "Light Jogging", "duration": 10, "type": "cardio", "intensity": "low"},
                    {"name": "Cool-down Walk", "duration": 5, "type": "cardio"},
                    {"name": "Stretching", "duration": 8}
                ],
                2: [
                    {"name": "Dynamic Warm-up", "duration": 10, "exercises": ["Jumping jacks", "High knees", "Butt kicks"], "rest": 20},
                    {"name": "Interval Running", "duration": 25, "type": "cardio", "intervals": "5 min run, 2 min walk x 3"},
                    {"name": "Rest", "duration": 2, "type": "rest"},
                    {"name": "Brisk Walking", "duration": 10, "type": "cardio"},
                    {"name": "Cool-down & Stretch", "duration": 10}
                ],
                3: [
                    {"name": "Dynamic Warm-up", "duration": 10, "exercises": ["Jumping jacks", "Mountain climbers", "Burpees"], "rest": 20},
                    {"name": "Running", "duration": 30, "type": "cardio", "intensity": "moderate-high"},
                    {"name": "HIIT Intervals", "duration": 15, "type": "cardio", "intervals": "30 sec sprint, 60 sec jog x 6"},
                    {"name": "Cool-down & Stretch", "duration": 10}
                ]
            }
        },
        "wellness": {
            "name": "Wellness & Recovery Program",
            "description": "Focus on recovery, flexibility, and mental wellness through gentle movements.",
            "workouts": {
                1: [
                    {"name": "Gentle Breathing", "duration": 5, "type": "meditation"},
                    {"name": "Neck & Shoulder Stretches", "duration": 10, "exercises": ["Neck rolls", "Shoulder circles", "Cross-body stretch"]},
                    {"name": "Gentle Yoga Flow", "duration": 20, "exercises": ["Cat-cow", "Child's pose", "Seated twists"]},
                    {"name": "Light Walking", "duration": 15, "type": "cardio", "intensity": "low"},
                    {"name": "Full Body Stretch", "duration": 15},
                    {"name": "Meditation", "duration": 10, "type": "meditation"}
                ],
                2: [
                    {"name": "Breathing Exercise", "duration": 5, "type": "meditation"},
                    {"name": "Yoga Flow", "duration": 25, "exercises": ["Sun salutations", "Warrior poses", "Balance poses"]},
                    {"name": "Mobility Work", "duration": 15, "exercises": ["Hip circles", "Spine waves", "Leg swings"]},
                    {"name": "Light Cardio", "duration": 20, "type": "cardio", "intensity": "low"},
                    {"name": "Deep Stretching", "duration": 15},
                    {"name": "Meditation", "duration": 10, "type": "meditation"}
                ],
                3: [
                    {"name": "Breathing & Warm-up", "duration": 10, "type": "meditation"},
                    {"name": "Advanced Yoga Flow", "duration": 30, "exercises": ["Vinyasa flow", "Inversions", "Arm balances"]},
                    {"name": "Mobility & Flexibility", "duration": 20, "exercises": ["Full range movements", "PNF stretching"]},
                    {"name": "Gentle Cardio", "duration": 25, "type": "cardio", "intensity": "moderate"},
                    {"name": "Restorative Stretching", "duration": 15},
                    {"name": "Guided Meditation", "duration": 15, "type": "meditation"}
                ]
            }
        },
        "hiit": {
            "name": "HIIT Program",
            "description": "High-intensity interval training for maximum efficiency and fat burning.",
            "workouts": {
                1: [
                    {"name": "Warm-up", "duration": 10, "exercises": ["Jumping jacks", "High knees", "Butt kicks"], "rest": 20},
                    {"name": "HIIT Circuit", "duration": 20, "rounds": 4, "work": 30, "rest": 60, "exercises": ["Jumping jacks", "Push-ups", "Squats", "Plank"]},
                    {"name": "Active Rest", "duration": 3, "type": "rest"},
                    {"name": "Cool-down & Stretch", "duration": 10}
                ],
                2: [
                    {"name": "Dynamic Warm-up", "duration": 10, "exercises": ["Jumping jacks", "Burpees", "Mountain climbers"], "rest": 15},
                    {"name": "HIIT Circuit", "duration": 25, "rounds": 5, "work": 45, "rest": 45, "exercises": ["Burpees", "Mountain climbers", "Jump squats", "Push-ups", "Plank"]},
                    {"name": "Active Rest", "duration": 3, "type": "rest"},
                    {"name": "Cool-down & Stretch", "duration": 10}
                ],
                3: [
                    {"name": "Dynamic Warm-up", "duration": 10, "exercises": ["Jumping jacks", "Burpees", "High knees"], "rest": 10},
                    {"name": "Advanced HIIT", "duration": 30, "rounds": 6, "work": 60, "rest": 30, "exercises": ["Burpees", "Mountain climbers", "Jump squats", "Push-ups", "Plank jacks", "High knees"]},
                    {"name": "Active Rest", "duration": 3, "type": "rest"},
                    {"name": "Cool-down & Stretch", "duration": 10}
                ]
            }
        },
        "yoga": {
            "name": "Yoga Program",
            "description": "Improve flexibility, strength, and mental clarity through yoga practice.",
            "workouts": {
                1: [
                    {"name": "Breathing Exercise", "duration": 5, "type": "meditation"},
                    {"name": "Gentle Yoga Flow", "duration": 25, "exercises": ["Cat-cow", "Child's pose", "Downward dog", "Warrior I"]},
                    {"name": "Seated Poses", "duration": 10, "exercises": ["Seated forward fold", "Seated twists", "Butterfly pose"]},
                    {"name": "Savasana", "duration": 10, "type": "meditation"}
                ],
                2: [
                    {"name": "Pranayama", "duration": 5, "type": "meditation"},
                    {"name": "Sun Salutations", "duration": 15, "rounds": 5},
                    {"name": "Standing Poses", "duration": 20, "exercises": ["Warrior I & II", "Triangle pose", "Tree pose"]},
                    {"name": "Floor Poses", "duration": 15, "exercises": ["Bridge pose", "Reclined twists", "Hip openers"]},
                    {"name": "Savasana", "duration": 10, "type": "meditation"}
                ],
                3: [
                    {"name": "Pranayama", "duration": 10, "type": "meditation"},
                    {"name": "Advanced Sun Salutations", "duration": 20, "rounds": 8},
                    {"name": "Power Yoga Flow", "duration": 30, "exercises": ["Advanced warrior variations", "Arm balances", "Inversions"]},
                    {"name": "Deep Stretching", "duration": 15, "exercises": ["Advanced hip openers", "Backbends", "Forward folds"]},
                    {"name": "Savasana", "duration": 15, "type": "meditation"}
                ]
            }
        }
    }
    
    # Get program data
    program_data = workouts.get(program_type.lower(), workouts["beginner"])
    
    # Determine level tier (1-3, 4-6, 7-10)
    if user_level <= 3:
        level_tier = 1
    elif user_level <= 6:
        level_tier = 2
    else:
        level_tier = 3
    
    # Get workouts for the level tier
    workout_list = program_data["workouts"].get(level_tier, program_data["workouts"][1])
    
    return {
        "program_name": program_data["name"],
        "description": program_data["description"],
        "workouts": workout_list,
        "user_level": user_level,
        "level_tier": level_tier,
        "total_duration": sum(w.get("duration", 0) for w in workout_list)
    }

