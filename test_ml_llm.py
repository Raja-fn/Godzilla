"""
Test script to verify ML and LLM integration
Run this to verify everything is working correctly
"""
import os
from dotenv import load_dotenv
from agents.orchestrator import decide_plan

load_dotenv()

def test_ml_llm_integration():
    """Test the ML and LLM integration"""
    print("Testing ML and LLM Integration...")
    print("=" * 50)
    
    # Test user state
    user_state = {
        "missed_days": 2,
        "stress": "medium",
        "sleep_hours": 6.5,
        "energy": "medium"
    }
    
    # Test recent logs
    recent_logs = [
        {"sleep_hours": 7, "stress_level": "low", "missed_workout": False},
        {"sleep_hours": 6, "stress_level": "medium", "missed_workout": False},
        {"sleep_hours": 5.5, "stress_level": "high", "missed_workout": True},
    ]
    
    # Test user profile
    user_profile = {
        "name": "Test User",
        "age": 25,
        "activity_level": "moderate",
        "goal": "improve_fitness"
    }
    
    print("\n1. Testing ML Predictor...")
    try:
        from agents.ml_predictor import get_predictor
        predictor = get_predictor()
        workout_prob = predictor.predict_workout_completion(user_state, recent_logs, user_profile)
        predicted_energy = predictor.predict_energy_level(user_state, recent_logs, user_profile)
        print(f"   [OK] ML Predictor working!")
        print(f"   - Workout completion probability: {workout_prob:.1%}")
        print(f"   - Predicted energy level: {predicted_energy:.1f}/10")
    except Exception as e:
        print(f"   [ERROR] ML Predictor error: {e}")
    
    print("\n2. Testing LLM Integration...")
    api_key = os.getenv("OPENAI_API_KEY")
    if api_key:
        print(f"   [OK] OpenAI API key found")
        try:
            from agents.recommendation_agent import generate_llm_recommendation
            llm_rec = generate_llm_recommendation(user_state, recent_logs, user_profile)
            if llm_rec:
                print(f"   [OK] LLM recommendation generated!")
                print(f"   - LLM Text: {llm_rec['llm_text'][:100]}...")
            else:
                print(f"   [WARNING] LLM returned None (check API key)")
        except Exception as e:
            print(f"   [ERROR] LLM error: {e}")
    else:
        print(f"   [WARNING] OpenAI API key not found in .env file")
        print(f"   Add OPENAI_API_KEY=sk-... to your .env file")
    
    print("\n3. Testing Full Integration...")
    try:
        plan = decide_plan(user_state, recent_logs=recent_logs, user_profile=user_profile)
        print(f"   [OK] Full integration working!")
        print(f"   - Goal status: {plan.get('goal')}")
        print(f"   - Wellness state: {plan.get('wellness')}")
        print(f"   - Workout plan: {plan.get('plan')}")
        if plan.get('ai_recommendation'):
            rec = plan.get('ai_recommendation')
            print(f"   - AI Recommendation: {rec.get('title', 'N/A')}")
            if rec.get('ml_insights'):
                print(f"   - ML Insights: {rec.get('ml_insights')}")
    except Exception as e:
        print(f"   [ERROR] Integration error: {e}")
        import traceback
        traceback.print_exc()
    
    print("\n" + "=" * 50)
    print("Test completed!")
    print("\nNote: If you see ML/LLM errors, the system will gracefully")
    print("fall back to rule-based recommendations.")

if __name__ == "__main__":
    test_ml_llm_integration()

