
from flask import Blueprint, jsonify, request
from database.db import get_db_connection

inspection_bp = Blueprint(
    "inspections",
    __name__,
    url_prefix="/api/inspections"
)



@inspection_bp.route("/", methods=["GET"])
def get_inspections():
    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        cursor.execute("""
            SELECT *
            FROM inspections
            ORDER BY inspection_id DESC
        """)

        inspections = cursor.fetchall()

        return jsonify({
            "status": "success",
            "count": len(inspections),
            "data": inspections
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



@inspection_bp.route("/<int:inspection_id>", methods=["GET"])
def get_inspection(inspection_id):
    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        cursor.execute("""
            SELECT *
            FROM inspections
            WHERE inspection_id = %s
        """, (inspection_id,))

        inspection = cursor.fetchone()

        if inspection is None:
            return jsonify({
                "status": "error",
                "message": "Inspection not found"
            }), 404

        return jsonify({
            "status": "success",
            "data": inspection
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


@inspection_bp.route("/tyre/<int:tyre_id>", methods=["GET"])
def get_tyre_inspections(tyre_id):
    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        cursor.execute("""
            SELECT *
            FROM inspections
            WHERE tyre_id = %s
            ORDER BY inspection_date DESC
        """, (tyre_id,))

        inspections = cursor.fetchall()

        return jsonify({
            "status": "success",
            "count": len(inspections),
            "data": inspections
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


@inspection_bp.route("/", methods=["POST"])
def create_inspection():
    connection = None
    cursor = None

    try:
        data = request.get_json(silent=True)

        if not isinstance(data, dict):
            return jsonify({
                "status": "error",
                "message": "A valid JSON request body is required"
            }), 400

        tyre_id = data.get("tyre_id")
        inspected_by = data.get("inspected_by")
        inspection_type = data.get("inspection_type")
        organization_id = data.get("organization_id")
        inspection_notes = data.get("inspection_notes")

        if not tyre_id or not inspected_by or not inspection_type:
            return jsonify({
                "status": "error",
                "message": "tyre_id, inspected_by and inspection_type are required"
            }), 400

        valid_types = ["AI_IMAGE", "TREAD_DEPTH", "COMBINED"]

        if inspection_type not in valid_types:
            return jsonify({
                "status": "error",
                "message": "Invalid inspection_type",
                "allowed_types": valid_types
            }), 400

        connection = get_db_connection()

        if connection is None:
            return jsonify({
                "status": "error",
                "message": "Database connection failed"
            }), 500

        cursor = connection.cursor()

        cursor.execute("""
            INSERT INTO inspections (
                tyre_id,
                inspected_by,
                organization_id,
                inspection_type,
                inspection_notes
            )
            VALUES (%s, %s, %s, %s, %s)
        """, (
            tyre_id,
            inspected_by,
            organization_id,
            inspection_type,
            inspection_notes
        ))

        connection.commit()

        new_inspection_id = cursor.lastrowid

        return jsonify({
            "status": "success",
            "message": "Inspection created successfully",
            "inspection_id": new_inspection_id
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
