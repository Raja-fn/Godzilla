from flask import render_template, request
from agents.orchestrator import decide_plan

def register_routes(app):

    @app.route("/")
    def dashboard():
        plan, reasoning = decide_plan({"sleep":5,"missed":False})
        return render_template("dashboard.html", reasoning=reasoning)

    @app.route("/log", methods=["GET","POST"])
    def log():
        if request.method == "POST":
            signals = {
                "sleep": int(request.form["sleep"]),
                "missed": "missed" in request.form
            }
            decide_plan(signals)
        return render_template("log.html")
