# Alivea - AI-Powered Fitness & Wellness Platform

A comprehensive fitness and wellness application that uses **Machine Learning** and **Large Language Models** to provide personalized workout recommendations, health tracking, and AI-powered insights.

## ✨ Features

- 🧠 **AI-Powered Recommendations** - Personalized fitness plans using OpenAI GPT models
- 🤖 **ML Predictions** - Workout completion probability and energy level forecasting
- 📊 **Health Analytics** - Track sleep, stress, energy, and workout consistency
- 📈 **Progress Dashboard** - Visual analytics with charts and metrics
- 🎯 **Goal Tracking** - Set and monitor fitness goals
- 👥 **User Profiles** - Personalized user accounts with profile management
- 🏆 **Leaderboards** - Compete with users in your age group
- 💾 **Data Storage** - Local JSON storage with optional Supabase integration

## 🛠️ Tech Stack

### Backend
- **Flask** - Web framework
- **Python 3.8+** - Programming language

### Machine Learning
- **scikit-learn** - ML models (RandomForest)
- **numpy** - Numerical computing
- **pandas** - Data processing
- **joblib** - Model serialization

### LLM Integration
- **OpenAI API** - GPT-4o-mini / GPT-3.5-turbo
- **Anthropic API** - Claude (optional)

### Frontend
- **Bootstrap 5** - UI framework
- **Font Awesome** - Icons
- **Chart.js** - Data visualization

### Database (Optional)
- **Supabase** - Cloud database

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- **Python 3.8 or higher** ([Download Python](https://www.python.org/downloads/))
- **pip** (Python package manager)
- **Git** (for cloning the repository)

### Optional (for LLM features)
- **OpenAI API Key** ([Get API Key](https://platform.openai.com/api-keys))
- **Anthropic API Key** ([Get API Key](https://console.anthropic.com/)) - Optional

### Optional (for cloud storage)
- **Supabase Account** ([Sign Up](https://supabase.com/)) - Optional

## 🚀 Installation

### 1. Clone the Repository

git clone https://github.com/yourusername/care_fit_agent.git
cd care_fit_agent### 2. Create a Virtual Environment

**Windows:**h
python -m venv venv
venv\Scripts\activate**macOS/Linux:**
python3 -m venv venv
source venv/bin/activate### 3. Install Dependencies

pip install -r requirements.txtThis will install:
- Flask and web dependencies
- scikit-learn, numpy, pandas (ML libraries)
- OpenAI and Anthropic (LLM APIs)
- Supabase client (optional)

## ⚙️ Environment Configuration

### 1. Create `.env` File

Create a `.env` file in the root directory:

# Windows
type nul > .env

# macOS/Linux
touch .env
### 2. Configure Environment Variables

Open `.env` and add the following variables:
nv
# Flask Configuration
FLASK_SECRET_KEY=your-secret-key-here-change-this-in-production

# OpenAI API (Required for LLM features)
OPENAI_API_KEY=sk-your-openai-api-key-here

# Anthropic API (Optional - alternative to OpenAI)
ANTHROPIC_API_KEY=sk-ant-your-anthropic-api-key-here

# Supabase Configuration (Optional - for cloud storage)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-supabase-anon-key### 3. Get API Keys

#### OpenAI API Key
1. Visit [OpenAI Platform](https://platform.openai.com/)
2. Sign up or log in
3. Go to API Keys section
4. Create a new secret key
5. Copy and paste into `.env` file

#### Supabase (Optional)
1. Visit [Supabase](https://supabase.com/)
2. Create a new project
3. Go to Settings > API
4. Copy your Project URL and anon/public key
5. Add to `.env` file

## 🏃 Running the Application

### Development Mode

python flask_app.pyThe application will start on:
- **URL:** http://127.0.0.1:3000
- **Port:** 3000
- **Debug Mode:** Enabled

### Access the Application

Open your web browser and navigate to:
