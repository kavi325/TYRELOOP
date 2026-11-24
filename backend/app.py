
from flask import Flask, jsonify
from config import Config

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    @app.route("/")
    def home():
        return jsonify({
            "system": "TYRELOOP",
            "message": "Backend API is running",
            "status": "success"
        })

    return app

if __name__ == "__main__":
    app = create_app()
    app.run(debug=True)
