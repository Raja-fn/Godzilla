-- ====================================================================
-- UPDATED SCHEMA FOR AI HEALTH APP
-- Profile Questions (One-time/Rarely Updated) + Survey Questions
-- ====================================================================

-- ====================================================================
-- 1. UPDATE PROFILES TABLE WITH ALL MANDATORY PROFILE QUESTIONS
-- ====================================================================

ALTER TABLE profiles
DROP COLUMN IF EXISTS age,
DROP COLUMN IF EXISTS height,
DROP COLUMN IF EXISTS weight,
DROP COLUMN IF EXISTS body_type,
DROP COLUMN IF EXISTS name,
DROP COLUMN IF EXISTS profile_picture_url;

-- Add all mandatory profile fields with proper types and constraints
ALTER TABLE profiles
ADD COLUMN age_group TEXT NOT NULL DEFAULT 'not_set',
ADD COLUMN biological_sex TEXT NOT NULL DEFAULT 'not_set',
ADD COLUMN height_cm INTEGER,
ADD COLUMN weight_kg DECIMAL(5, 2),
ADD COLUMN body_type TEXT NOT NULL DEFAULT 'not_set',
ADD COLUMN primary_health_goal TEXT NOT NULL DEFAULT 'not_set',
ADD COLUMN activity_level TEXT NOT NULL DEFAULT 'not_set',
ADD COLUMN dietary_preference TEXT NOT NULL DEFAULT 'not_set',
ADD COLUMN avg_sleep_duration TEXT NOT NULL DEFAULT 'not_set',
ADD COLUMN medical_conditions TEXT[] DEFAULT '{}',
ADD COLUMN profile_completed_at TIMESTAMPTZ,
ADD COLUMN profile_last_updated_at TIMESTAMPTZ DEFAULT NOW();

-- Add constraints for numeric fields
ALTER TABLE profiles
ADD CONSTRAINT height_constraint CHECK (height_cm >= 100 AND height_cm <= 250),
ADD CONSTRAINT weight_constraint CHECK (weight_kg >= 30 AND weight_kg <= 300);

-- ====================================================================
-- 2. CREATE USER SURVEY RESPONSES TABLE (For periodic surveys)
-- ====================================================================

CREATE TABLE IF NOT EXISTS user_survey_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Survey Questions (1-10) with responses
  exercise_frequency TEXT,
  energy_levels TEXT,
  diet_balance TEXT,
  water_intake TEXT,
  stress_levels TEXT,
  sleep_quality TEXT,
  body_pain_frequency TEXT,
  junk_food_frequency TEXT,
  mental_refreshment TEXT,
  health_rating TEXT,
  
  -- Calculated Scores
  physical_health_score INTEGER,
  mental_health_score INTEGER,
  lifestyle_score INTEGER,
  overall_wellness_index INTEGER,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, created_at::date)
);

-- Index for efficient queries
CREATE INDEX IF NOT EXISTS idx_user_survey_responses_user_id 
ON user_survey_responses(user_id);

CREATE INDEX IF NOT EXISTS idx_user_survey_responses_created_at 
ON user_survey_responses(user_id, created_at DESC);

-- ====================================================================
-- 3. CREATE SURVEY TEMPLATES TABLE (For flexible survey management)
-- ====================================================================

CREATE TABLE IF NOT EXISTS survey_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  survey_type TEXT NOT NULL, -- 'profile' or 'periodic'
  questions JSONB NOT NULL, -- Store question structure as JSON
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ====================================================================
-- 4. CREATE USER PROFILE ANSWERS TABLE (For structured profile storage)
-- ====================================================================

CREATE TABLE IF NOT EXISTS user_profile_answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Question 1: Age Group
  age_group TEXT,
  
  -- Question 2: Biological Sex
  biological_sex TEXT,
  
  -- Question 3: Height
  height_cm INTEGER,
  
  -- Question 4: Weight
  weight_kg DECIMAL(5, 2),
  
  -- Question 5: Body Type
  body_type TEXT,
  
  -- Question 6: Primary Health Goal
  primary_health_goal TEXT,
  
  -- Question 7: Activity Level
  activity_level TEXT,
  
  -- Question 8: Dietary Preference
  dietary_preference TEXT,
  
  -- Question 9: Sleep Duration
  avg_sleep_duration TEXT,
  
  -- Question 10: Medical Conditions
  medical_conditions TEXT[],
  
  -- Metadata
  completed_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id)
);

-- Index for efficient queries
CREATE INDEX IF NOT EXISTS idx_user_profile_answers_user_id 
ON user_profile_answers(user_id);

-- ====================================================================
-- 5. ALTER EXISTING TABLES IF NEEDED
-- ====================================================================

-- Update the user_surveys table to be more flexible
ALTER TABLE user_surveys
DROP COLUMN IF EXISTS activity_level,
DROP COLUMN IF EXISTS dietary_preferences,
DROP COLUMN IF EXISTS fitness_goals;

-- ====================================================================
-- 6. CREATE ENUMS FOR DATA VALIDATION (Optional but recommended)
-- ====================================================================

-- Age Group Enum
DO $$ BEGIN
  CREATE TYPE age_group_enum AS ENUM (
    'under_18',
    'age_18_24',
    'age_25_34',
    'age_35_44',
    'age_45_54',
    'age_55_plus'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Biological Sex Enum
DO $$ BEGIN
  CREATE TYPE biological_sex_enum AS ENUM (
    'male',
    'female',
    'prefer_not_to_say'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Body Type Enum
DO $$ BEGIN
  CREATE TYPE body_type_enum AS ENUM (
    'ectomorph',
    'mesomorph',
    'endomorph'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Health Goal Enum
DO $$ BEGIN
  CREATE TYPE health_goal_enum AS ENUM (
    'weight_loss',
    'muscle_gain',
    'maintain_fitness',
    'improve_endurance',
    'general_wellness'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Activity Level Enum
DO $$ BEGIN
  CREATE TYPE activity_level_enum AS ENUM (
    'sedentary',
    'light',
    'moderate',
    'active',
    'very_active'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Dietary Preference Enum
DO $$ BEGIN
  CREATE TYPE dietary_preference_enum AS ENUM (
    'vegetarian',
    'vegan',
    'eggetarian',
    'non_vegetarian',
    'no_preference'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Sleep Duration Enum
DO $$ BEGIN
  CREATE TYPE sleep_duration_enum AS ENUM (
    'less_than_5',
    'five_to_6',
    'six_to_7',
    'seven_to_8',
    'more_than_8'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Medical Conditions Enum
DO $$ BEGIN
  CREATE TYPE medical_condition_enum AS ENUM (
    'none',
    'diabetes',
    'hypertension',
    'thyroid',
    'heart_condition',
    'other'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ====================================================================
-- 7. SURVEY RESPONSE SCALE ENUMS (1-5 Rating)
-- ====================================================================

DO $$ BEGIN
  CREATE TYPE survey_scale_enum AS ENUM (
    'never',
    'rarely',
    'sometimes',
    'often',
    'always'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE exercise_frequency_enum AS ENUM (
    'never',
    'one_to_two_times',
    'three_to_four_times',
    'five_plus_times'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE energy_level_enum AS ENUM (
    'very_low',
    'low',
    'moderate',
    'high',
    'very_high'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE quality_scale_enum AS ENUM (
    'very_poor',
    'poor',
    'average',
    'good',
    'excellent'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE water_intake_enum AS ENUM (
    'less_than_4',
    'four_to_6',
    'six_to_8',
    'eight_to_10',
    'ten_plus'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE stress_level_enum AS ENUM (
    'very_high',
    'high',
    'moderate',
    'low',
    'very_low'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE junk_food_frequency_enum AS ENUM (
    'daily',
    'three_to_four_times',
    'one_to_two_times',
    'rarely',
    'never'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ====================================================================
-- 8. FUNCTION TO CALCULATE WELLNESS SCORES
-- ====================================================================

CREATE OR REPLACE FUNCTION calculate_wellness_scores()
RETURNS TRIGGER AS $$
DECLARE
  physical_score INTEGER;
  mental_score INTEGER;
  lifestyle_score INTEGER;
  overall_score INTEGER;
BEGIN
  -- Physical Health Score (Exercise, Sleep Quality, Body Pain, Diet Balance, Health Rating)
  -- Scale: 1-5
  physical_score := COALESCE(
    (CASE WHEN NEW.exercise_frequency = 'never' THEN 1
          WHEN NEW.exercise_frequency = 'one_to_two_times' THEN 2
          WHEN NEW.exercise_frequency = 'three_to_four_times' THEN 4
          WHEN NEW.exercise_frequency = 'five_plus_times' THEN 5 END),
    0
  ) +
  COALESCE(
    (CASE WHEN NEW.sleep_quality = 'very_poorly' THEN 1
          WHEN NEW.sleep_quality = 'poorly' THEN 2
          WHEN NEW.sleep_quality = 'average' THEN 3
          WHEN NEW.sleep_quality = 'well' THEN 4
          WHEN NEW.sleep_quality = 'very_well' THEN 5 END),
    0
  ) +
  COALESCE(
    (CASE WHEN NEW.body_pain_frequency = 'always' THEN 1
          WHEN NEW.body_pain_frequency = 'often' THEN 2
          WHEN NEW.body_pain_frequency = 'sometimes' THEN 3
          WHEN NEW.body_pain_frequency = 'rarely' THEN 4
          WHEN NEW.body_pain_frequency = 'never' THEN 5 END),
    0
  ) +
  COALESCE(
    (CASE WHEN NEW.diet_balance = 'very_poor' THEN 1
          WHEN NEW.diet_balance = 'poor' THEN 2
          WHEN NEW.diet_balance = 'average' THEN 3
          WHEN NEW.diet_balance = 'good' THEN 4
          WHEN NEW.diet_balance = 'excellent' THEN 5 END),
    0
  ) +
  COALESCE(
    (CASE WHEN NEW.health_rating = 'very_poor' THEN 1
          WHEN NEW.health_rating = 'poor' THEN 2
          WHEN NEW.health_rating = 'average' THEN 3
          WHEN NEW.health_rating = 'good' THEN 4
          WHEN NEW.health_rating = 'excellent' THEN 5 END),
    0
  );

  -- Mental Health Score (Stress, Mental Refreshment)
  -- Scale: 1-5
  mental_score := COALESCE(
    (CASE WHEN NEW.stress_levels = 'very_high' THEN 1
          WHEN NEW.stress_levels = 'high' THEN 2
          WHEN NEW.stress_levels = 'moderate' THEN 3
          WHEN NEW.stress_levels = 'low' THEN 4
          WHEN NEW.stress_levels = 'very_low' THEN 5 END),
    0
  ) +
  COALESCE(
    (CASE WHEN NEW.mental_refreshment = 'never' THEN 1
          WHEN NEW.mental_refreshment = 'rarely' THEN 2
          WHEN NEW.mental_refreshment = 'sometimes' THEN 3
          WHEN NEW.mental_refreshment = 'often' THEN 4
          WHEN NEW.mental_refreshment = 'always' THEN 5 END),
    0
  );

  -- Lifestyle Score (Water Intake, Junk Food, Energy Levels)
  -- Scale: 1-5
  lifestyle_score := COALESCE(
    (CASE WHEN NEW.water_intake = 'less_than_4' THEN 1
          WHEN NEW.water_intake = 'four_to_6' THEN 2
          WHEN NEW.water_intake = 'six_to_8' THEN 3
          WHEN NEW.water_intake = 'eight_to_10' THEN 4
          WHEN NEW.water_intake = 'ten_plus' THEN 5 END),
    0
  ) +
  COALESCE(
    (CASE WHEN NEW.junk_food_frequency = 'daily' THEN 1
          WHEN NEW.junk_food_frequency = 'three_to_four_times' THEN 2
          WHEN NEW.junk_food_frequency = 'one_to_two_times' THEN 3
          WHEN NEW.junk_food_frequency = 'rarely' THEN 4
          WHEN NEW.junk_food_frequency = 'never' THEN 5 END),
    0
  ) +
  COALESCE(
    (CASE WHEN NEW.energy_levels = 'very_low' THEN 1
          WHEN NEW.energy_levels = 'low' THEN 2
          WHEN NEW.energy_levels = 'moderate' THEN 3
          WHEN NEW.energy_levels = 'high' THEN 4
          WHEN NEW.energy_levels = 'very_high' THEN 5 END),
    0
  );

  -- Calculate final scores
  NEW.physical_health_score := CASE WHEN physical_score > 0 THEN (physical_score / 5 * 100)::INTEGER ELSE 0 END;
  NEW.mental_health_score := CASE WHEN mental_score > 0 THEN (mental_score / 2 * 100)::INTEGER ELSE 0 END;
  NEW.lifestyle_score := CASE WHEN lifestyle_score > 0 THEN (lifestyle_score / 3 * 100)::INTEGER ELSE 0 END;
  NEW.overall_wellness_index := (COALESCE(NEW.physical_health_score, 0) + 
                                  COALESCE(NEW.mental_health_score, 0) + 
                                  COALESCE(NEW.lifestyle_score, 0)) / 3;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically calculate scores
DROP TRIGGER IF EXISTS calculate_wellness_scores_trigger 
ON user_survey_responses;

CREATE TRIGGER calculate_wellness_scores_trigger
BEFORE INSERT OR UPDATE ON user_survey_responses
FOR EACH ROW
EXECUTE FUNCTION calculate_wellness_scores();

-- ====================================================================
-- 9. ENABLE RLS (Row Level Security) FOR DATA PRIVACY
-- ====================================================================

-- Enable RLS on all tables
ALTER TABLE user_survey_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profile_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE survey_templates ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only see their own data
CREATE POLICY user_survey_responses_policy
ON user_survey_responses FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY user_profile_answers_policy
ON user_profile_answers FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY survey_templates_read_policy
ON survey_templates FOR SELECT
USING (TRUE); -- All authenticated users can read templates

-- ====================================================================
-- 10. SAMPLE DATA FOR SURVEY TEMPLATES
-- ====================================================================

-- Insert Profile Questions Template
INSERT INTO survey_templates (name, description, survey_type, questions)
VALUES (
  'Mandatory Profile Setup',
  'One-time health profile questions',
  'profile',
  '[
    {
      "id": 1,
      "question": "What is your age group?",
      "type": "radio",
      "options": ["Under 18", "18–24", "25–34", "35–44", "45–54", "55+"],
      "values": ["under_18", "age_18_24", "age_25_34", "age_35_44", "age_45_54", "age_55_plus"]
    },
    {
      "id": 2,
      "question": "What is your biological sex?",
      "type": "radio",
      "options": ["Male", "Female", "Prefer not to say"],
      "values": ["male", "female", "prefer_not_to_say"]
    },
    {
      "id": 3,
      "question": "What is your height? (cm)",
      "type": "number",
      "min": 100,
      "max": 250,
      "unit": "cm"
    },
    {
      "id": 4,
      "question": "What is your weight? (kg)",
      "type": "number",
      "min": 30,
      "max": 300,
      "unit": "kg"
    },
    {
      "id": 5,
      "question": "What is your body type?",
      "type": "radio",
      "options": ["Ectomorph (lean / skinny)", "Mesomorph (athletic / muscular)", "Endomorph (higher body fat)"],
      "values": ["ectomorph", "mesomorph", "endomorph"]
    },
    {
      "id": 6,
      "question": "What is your primary health goal?",
      "type": "radio",
      "options": ["Weight loss", "Muscle gain", "Maintain fitness", "Improve endurance", "General wellness"],
      "values": ["weight_loss", "muscle_gain", "maintain_fitness", "improve_endurance", "general_wellness"]
    },
    {
      "id": 7,
      "question": "What is your activity level?",
      "type": "radio",
      "options": ["Sedentary (little or no exercise)", "Light (1–3 days/week)", "Moderate (3–5 days/week)", "Active (6–7 days/week)", "Very active (athlete / labor-intensive)"],
      "values": ["sedentary", "light", "moderate", "active", "very_active"]
    },
    {
      "id": 8,
      "question": "What is your dietary preference?",
      "type": "radio",
      "options": ["Vegetarian", "Vegan", "Eggetarian", "Non-vegetarian", "No specific preference"],
      "values": ["vegetarian", "vegan", "eggetarian", "non_vegetarian", "no_preference"]
    },
    {
      "id": 9,
      "question": "What is your average sleep duration?",
      "type": "radio",
      "options": ["< 5 hours", "5–6 hours", "6–7 hours", "7–8 hours", "> 8 hours"],
      "values": ["less_than_5", "five_to_6", "six_to_7", "seven_to_8", "more_than_8"]
    },
    {
      "id": 10,
      "question": "Do you have any existing medical conditions?",
      "type": "checkbox",
      "options": ["None", "Diabetes", "Hypertension", "Thyroid", "Heart condition", "Other"],
      "values": ["none", "diabetes", "hypertension", "thyroid", "heart_condition", "other"]
    }
  ]'::jsonb
) ON CONFLICT DO NOTHING;

-- Insert Periodic Survey Template
INSERT INTO survey_templates (name, description, survey_type, questions)
VALUES (
  'Weekly Health Survey',
  'Periodic health and wellness survey (recommended weekly)',
  'periodic',
  '[
    {
      "id": 1,
      "question": "How often do you exercise?",
      "type": "radio",
      "options": ["Never", "1–2 times/week", "3–4 times/week", "5+ times/week"],
      "values": ["never", "one_to_two_times", "three_to_four_times", "five_plus_times"]
    },
    {
      "id": 2,
      "question": "How would you rate your daily energy levels?",
      "type": "radio",
      "options": ["Very low", "Low", "Moderate", "High", "Very high"],
      "values": ["very_low", "low", "moderate", "high", "very_high"]
    },
    {
      "id": 3,
      "question": "How balanced is your diet?",
      "type": "radio",
      "options": ["Very poor", "Poor", "Average", "Good", "Excellent"],
      "values": ["very_poor", "poor", "average", "good", "excellent"]
    },
    {
      "id": 4,
      "question": "How many glasses of water do you drink daily?",
      "type": "radio",
      "options": ["< 4", "4–6", "6–8", "8–10", "10+"],
      "values": ["less_than_4", "four_to_6", "six_to_8", "eight_to_10", "ten_plus"]
    },
    {
      "id": 5,
      "question": "How would you describe your stress levels?",
      "type": "radio",
      "options": ["Very high", "High", "Moderate", "Low", "Very low"],
      "values": ["very_high", "high", "moderate", "low", "very_low"]
    },
    {
      "id": 6,
      "question": "How well do you sleep?",
      "type": "radio",
      "options": ["Very poorly", "Poorly", "Average", "Well", "Very well"],
      "values": ["very_poorly", "poorly", "average", "well", "very_well"]
    },
    {
      "id": 7,
      "question": "Do you experience frequent body pain?",
      "type": "radio",
      "options": ["Never", "Rarely", "Sometimes", "Often", "Always"],
      "values": ["never", "rarely", "sometimes", "often", "always"]
    },
    {
      "id": 8,
      "question": "How often do you consume junk or fast food?",
      "type": "radio",
      "options": ["Daily", "3–4 times/week", "1–2 times/week", "Rarely", "Never"],
      "values": ["daily", "three_to_four_times", "one_to_two_times", "rarely", "never"]
    },
    {
      "id": 9,
      "question": "How often do you feel mentally refreshed?",
      "type": "radio",
      "options": ["Never", "Rarely", "Sometimes", "Often", "Always"],
      "values": ["never", "rarely", "sometimes", "often", "always"]
    },
    {
      "id": 10,
      "question": "Overall, how would you rate your health?",
      "type": "radio",
      "options": ["Very poor", "Poor", "Average", "Good", "Excellent"],
      "values": ["very_poor", "poor", "average", "good", "excellent"]
    }
  ]'::jsonb
) ON CONFLICT DO NOTHING;
