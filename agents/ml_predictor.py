"""
ML-based prediction module for fitness outcomes
Uses scikit-learn to predict user behavior and outcomes
"""
import numpy as np
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
from sklearn.preprocessing import StandardScaler
import joblib
import os

class FitnessPredictor:
    """ML model to predict workout completion, energy levels, and health outcomes"""
    
    def __init__(self):
        self.model_path = os.path.join(os.path.dirname(__file__), "models")
        os.makedirs(self.model_path, exist_ok=True)
        self.scaler = StandardScaler()
        self.workout_predictor = None
        self.energy_predictor = None
        self.load_or_train_models()
    
    def load_or_train_models(self):
        """Load existing models or create new ones"""
        workout_model_path = os.path.join(self.model_path, "workout_predictor.joblib")
        energy_model_path = os.path.join(self.model_path, "energy_predictor.joblib")
        
        if os.path.exists(workout_model_path):
            try:
                self.workout_predictor = joblib.load(workout_model_path)
            except Exception:
                self.workout_predictor = RandomForestClassifier(n_estimators=100, random_state=42)
        else:
            self.workout_predictor = RandomForestClassifier(n_estimators=100, random_state=42)
        
        if os.path.exists(energy_model_path):
            try:
                self.energy_predictor = joblib.load(energy_model_path)
            except Exception:
                self.energy_predictor = RandomForestRegressor(n_estimators=100, random_state=42)
        else:
            self.energy_predictor = RandomForestRegressor(n_estimators=100, random_state=42)
    
    def extract_features(self, user_state, recent_logs, user_profile=None):
        """Extract features for ML prediction"""
        features = []
        
        # Current state features
        stress_map = {"low": 0, "medium": 1, "high": 2}
        energy_map = {"low": 0, "medium": 1, "high": 2}
        
        features.append(user_state.get("sleep_hours", 7))
        features.append(stress_map.get(user_state.get("stress", "medium"), 1))
        features.append(energy_map.get(user_state.get("energy", "medium"), 1))
        features.append(user_state.get("missed_days", 0))
        
        # Historical features from recent logs
        if recent_logs:
            avg_sleep = np.mean([log.get("sleep_hours", 7) for log in recent_logs])
            avg_stress = np.mean([stress_map.get(log.get("stress_level", "medium"), 1) for log in recent_logs])
            workout_rate = sum(1 for log in recent_logs if not log.get("missed_workout")) / len(recent_logs)
            features.extend([avg_sleep, avg_stress, workout_rate])
        else:
            features.extend([7, 1, 0.5])
        
        # User profile features
        if user_profile:
            age = user_profile.get("age", 30)
            activity_map = {"sedentary": 1, "light": 2, "moderate": 3, "active": 4, "very_active": 5}
            activity_level = activity_map.get(user_profile.get("activity_level", "moderate"), 3)
            features.extend([age, activity_level])
        else:
            features.extend([30, 3])
        
        return np.array(features).reshape(1, -1)
    
    def predict_workout_completion(self, user_state, recent_logs, user_profile=None):
        """Predict probability of completing next workout"""
        features = self.extract_features(user_state, recent_logs, user_profile)
        
        # For demo: use rule-based prediction with ML model structure
        # In production, train on historical data
        if self.workout_predictor:
            try:
                # Try to use the model - if it's trained, this will work
                prob = self.workout_predictor.predict_proba(features)[0][1]
            except (AttributeError, ValueError, Exception):
                # Model not trained yet or error, use rule-based
                prob = self._rule_based_workout_prob(user_state)
        else:
            # Fallback: rule-based prediction
            prob = self._rule_based_workout_prob(user_state)
        
        return prob
    
    def _rule_based_workout_prob(self, user_state):
        """Rule-based fallback for workout probability"""
        sleep = user_state.get("sleep_hours", 7)
        stress = user_state.get("stress", "medium")
        missed = user_state.get("missed_days", 0)
        
        prob = 0.7  # Base probability
        if sleep >= 7:
            prob += 0.1
        if stress == "low":
            prob += 0.1
        if missed < 2:
            prob += 0.1
        return min(1.0, prob)
    
    def predict_energy_level(self, user_state, recent_logs, user_profile=None):
        """Predict next day's energy level (0-10 scale)"""
        features = self.extract_features(user_state, recent_logs, user_profile)
        
        if self.energy_predictor:
            try:
                # Try to use the model - if it's trained, this will work
                energy_score = self.energy_predictor.predict(features)[0]
                energy_score = max(0, min(10, energy_score))
            except (AttributeError, ValueError, Exception):
                # Model not trained yet or error, use rule-based
                energy_score = self._rule_based_energy(user_state)
        else:
            energy_score = self._rule_based_energy(user_state)
        
        return energy_score
    
    def _rule_based_energy(self, user_state):
        """Rule-based fallback for energy prediction"""
        sleep = user_state.get("sleep_hours", 7)
        stress_map = {"low": 0, "medium": 1, "high": 2}
        stress = stress_map.get(user_state.get("stress", "medium"), 1)
        
        energy_score = (sleep / 10) * 5 + (2 - stress) * 2.5
        return max(0, min(10, energy_score))
    
    def train_models(self, training_data):
        """Train models on historical data (for future use)"""
        # This would be called with actual training data
        # X = features, y = labels
        pass

# Global instance
_predictor = None

def get_predictor():
    """Get singleton predictor instance"""
    global _predictor
    if _predictor is None:
        _predictor = FitnessPredictor()
    return _predictor

