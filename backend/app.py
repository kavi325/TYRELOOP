
from flask import Flask, jsonify
from config import Config
from database.db import get_db_connection
from routes.tyre_routes import tyre_bp


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    app.register_blueprint(tyre_bp)

    @app.route("/", methods=["GET"])
    def home():
        return jsonify({
            "system": "TYRELOOP",
            "message": "Backend API is running",
            "status": "success"
        }), 200

    @app.route("/api/health/db", methods=["GET"])
    def database_health():
        connection = get_db_connection()

        if connection is None:
            return jsonify({
                "status": "error",
                "database": "disconnected",
                "message": "Database connection failed"
            }), 503

        try:
            cursor = connection.cursor()
            cursor.execute("SELECT DATABASE()")
            database_name = cursor.fetchone()[0]

            cursor.close()

            return jsonify({
                "status": "success",
                "database": "connected",
                "database_name": database_name
            }), 200

        except Exception:
            app.logger.exception("Database health check failed")

            return jsonify({
                "status": "error",
                "database": "unavailable",
                "message": "Database query failed"
            }), 500

        finally:
            connection.close()

    return app


if __name__ == "__main__":
    app = create_app()
    app.run(debug=True)
