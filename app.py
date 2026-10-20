 # Flask is used for integeration DB=>PY=>Web [API]
from flask import Flask, render_template, request, jsonify
# Flask : for creating api app
# render template :  to connect webpage with python
# request : to get data from webpage
# jsonify : to conver data in json format so that wen can show on webpage
import mysql.connector # to Connect Mysql db with python
from mysql.connector import Error # Error handling
import os # operating system

app = Flask(__name__) # creating app [Blank api file ]

# Set these environment variables or edit the defaults for local use.
DB_CONFIG = {
    "host": os.getenv("MYSQL_HOST", "localhost"),
    "port": int(os.getenv("MYSQL_PORT", "3306")),
    "user": os.getenv("MYSQL_USER", "root"),
    "password": os.getenv("MYSQL_PASSWORD", "harsh123"),
    "database": os.getenv("MYSQL_DATABASE", "euromart"),
}


def get_connection():
    return mysql.connector.connect(**DB_CONFIG) # def to connect with mysql using configuration


def call_procedure(proc_name, params=()):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.callproc(proc_name, params)

        rows = []
        for result in cursor.stored_results():
            rows.extend(result.fetchall())

        # Procedures containing UPDATE should be committed.
        conn.commit()
        return rows
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()


@app.route("/")
def index():
    return render_template("dashboard.html")


@app.route("/api/procedure", methods=["POST"])
def run_procedure():
    data = request.get_json(silent=True) or {}
    procedure = data.get("procedure") # getting procedure name from webpage
    params = data.get("params", []) # getting procedure parameters from webpage

    allowed = {
        "view_orders",
        "update_model",
        "orders_by_country",
        "orders_by_segment",
        "sales_by_product",
        "sales_by_category",
        "shipmode_summary",
        "customer_orders",
        "product_performance",
        "feedback_summary",
    }

    if procedure not in allowed:
        return jsonify({"ok": False, "error": "Procedure is not allowed."}), 400

    try:
        rows = call_procedure(procedure, tuple(params))
        return jsonify({"ok": True, "rows": rows, "count": len(rows)})
    except Error as e:
        return jsonify({"ok": False, "error": str(e)}), 500
    except Exception as e:
        return jsonify({"ok": False, "error": str(e)}), 500


@app.route("/api/options")
def options():
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT DISTINCT country FROM orders ORDER BY country")
        countries = [r[0] for r in cursor.fetchall()]
        cursor.execute("SELECT DISTINCT segment FROM orders ORDER BY segment")
        segments = [r[0] for r in cursor.fetchall()]
        return jsonify({"countries": countries, "segments": segments})
    except Error as e:
        return jsonify({"ok": False, "error": str(e)}), 500
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()


if __name__ == "__main__":
    app.run(debug=True)