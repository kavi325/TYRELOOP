
from flask import Blueprint, jsonify, request
from database.db import get_db_connection

tyre_bp = Blueprint("tyres", __name__, url_prefix="/api/tyres")


# --------------------------------------------------
# GET: Retrieve all tyres
# URL: GET /api/tyres/
# --------------------------------------------------
@tyre_bp.route("/", methods=["GET"])
def get_tyres():
    connection = None
    cursor = None

    try:
        connection = get_db_connection()

        if connection is None:
            return jsonify({
                "status": "error",
                "message": "Database connection failed"
            }), 500

        cursor = connection.cursor(dictionary=True)

        cursor.execute("""
            SELECT *
            FROM tyres
            ORDER BY tyre_id DESC
        """)

        tyres = cursor.fetchall()

        return jsonify({
            "status": "success",
            "count": len(tyres),
            "data": tyres
        }), 200

    except Exception as error:
        return jsonify({
            "status": "error",
            "message": str(error)
        }), 500

    finally:
        if cursor:
            cursor.close()

        if connection:
            connection.close()


# --------------------------------------------------
# GET: Retrieve a single tyre by ID
# URL: GET /api/tyres/<tyre_id>
# --------------------------------------------------
@tyre_bp.route("/<int:tyre_id>", methods=["GET"])
def get_tyre(tyre_id):
    connection = None
    cursor = None

    try:
        connection = get_db_connection()

        if connection is None:
            return jsonify({
                "status": "error",
                "message": "Database connection failed"
            }), 500

        cursor = connection.cursor(dictionary=True)

        cursor.execute("""
            SELECT *
            FROM tyres
            WHERE tyre_id = %s
        """, (tyre_id,))

        tyre = cursor.fetchone()

        if tyre is None:
            return jsonify({
                "status": "error",
                "message": "Tyre not found"
            }), 404

        return jsonify({
            "status": "success",
            "data": tyre
        }), 200

    except Exception as error:
        return jsonify({
            "status": "error",
            "message": str(error)
        }), 500

    finally:
        if cursor:
            cursor.close()

        if connection:
            connection.close()


# --------------------------------------------------
# POST: Register a new tyre
# URL: POST /api/tyres/
# --------------------------------------------------
@tyre_bp.route("/", methods=["POST"])
def register_tyre():
    connection = None
    cursor = None

    try:
        data = request.get_json(silent=True)

        if not data:
            return jsonify({
                "status": "error",
                "message": "A valid JSON request body is required"
            }), 400

        qr_code = data.get("qr_code")

        if not qr_code:
            return jsonify({
                "status": "error",
                "message": "QR code is required"
            }), 400

        connection = get_db_connection()

        if connection is None:
            return jsonify({
                "status": "error",
                "message": "Database connection failed"
            }), 500

        cursor = connection.cursor()

        query = """
            INSERT INTO tyres (
                vehicle_id,
                current_owner_user_id,
                qr_code,
                brand,
                model,
                tyre_size,
                serial_number,
                manufacture_date,
                installation_date
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """

        values = (
            data.get("vehicle_id"),
            data.get("current_owner_user_id"),
            qr_code,
            data.get("brand"),
            data.get("model"),
            data.get("tyre_size"),
            data.get("serial_number"),
            data.get("manufacture_date"),
            data.get("installation_date")
        )

        cursor.execute(query, values)
        connection.commit()

        new_tyre_id = cursor.lastrowid

        return jsonify({
            "status": "success",
            "message": "Tyre registered successfully",
            "tyre_id": new_tyre_id
        }), 201

    except Exception as error:
        if connection:
            connection.rollback()

        return jsonify({
            "status": "error",
            "message": str(error)
        }), 500

    finally:
        if cursor:
            cursor.close()

        if connection:
            connection.close()
