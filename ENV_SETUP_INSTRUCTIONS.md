# Environment Setup Instructions

## Quick Setup Guide

### Step 1: Create .env file
Copy the `env.example` file and rename it to `.env`:

**Windows:**
```bash
copy env.example .env
```

**macOS/Linux:**
```bash
cp env.example .env
```

### Step 2: Configure Environment Variables

Open the `.env` file and replace the placeholder values with your actual credentials:

#### Required Variables:

1. **FLASK_SECRET_KEY**
   - Generate a random secret key for Flask sessions
   - Example: `FLASK_SECRET_KEY=your-random-secret-key-here`

2. **OPENAI_API_KEY** (Required for LLM features)
   - Sign up at: https://platform.openai.com/
   - Get your API key from: https://platform.openai.com/api-keys
   - Format: `OPENAI_API_KEY=sk-...`

#### Optional Variables:

3. **ANTHROPIC_API_KEY** (Optional)
   - Alternative to OpenAI for LLM recommendations
   - Get from: https://console.anthropic.com/
   - Format: `ANTHROPIC_API_KEY=sk-ant-...`

4. **SUPABASE_URL** and **SUPABASE_KEY** (Optional)
   - For cloud database storage
   - Create project at: https://supabase.com/
   - Get credentials from Project Settings > API

### Step 3: Run the Application

```bash
python flask_app.py
```

The application will run on http://127.0.0.1:3000

## Notes

- **Never commit `.env` file to Git** - it contains sensitive information
- The `.env.example` file shows the structure without real keys
- If you don't have OpenAI API key, the app will use rule-based recommendations with ML insights
- Supabase is optional - the app works with local JSON storage by default

## Troubleshooting

- If you see "API key not found" errors, check that your `.env` file is in the root directory
- Ensure there are no extra spaces in your API keys
- Make sure your OpenAI API key has credits available

