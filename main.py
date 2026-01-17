from agents.orchestrator import decide_plan
from supabase import create_client
from dotenv import load_dotenv
import os
from datetime import date

load_dotenv()

supabase = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_KEY")
)

user_state = {
    "missed_days": 3,
    "stress": "high",
    "sleep_hours": 5,
    "energy": "low"
}

plan = decide_plan(user_state)
print(plan)


