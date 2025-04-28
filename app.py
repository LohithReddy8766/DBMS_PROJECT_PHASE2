from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
from flask import Flask, render_template


app = Flask(__name__)
CORS(app)  # Allow frontend access

# Database connection
def get_db_connection():
    return mysql.connector.connect(
        host='localhost',
        user='root',
        password='root',
        database='MLRG'
    )

# ---------- USER AUTH ----------
@app.route('/signup', methods=['POST'])
def signup():
    data = request.json
    print("Signup data received:", data)  # Debug log
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.callproc('sp_register_user', (data['username'], data['email'], data['password']))
        conn.commit()
        print("User inserted successfully.")
        return jsonify({'success': True})
    except mysql.connector.Error as err:
        print("Signup failed with error:", err)  # Show error in terminal
        return jsonify({'success': False, 'error': str(err)})
    finally:
        cursor.close()
        conn.close()


@app.route('/login', methods=['POST'])
def login():
    data = request.json
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.callproc('sp_login_user', (data['username'], data['password']))
        for result in cursor.stored_results():
            user = result.fetchone()
            if user:
                print("Login Successful, User:", user)  # Debugging
                return jsonify({'success': True, 'user': user})
        return jsonify({'success': False, 'message': 'Invalid credentials'})
    finally:
        cursor.close()
        conn.close()


# ---------- RECIPES ----------
@app.route('/recipes', methods=['GET'])
def get_recipes():
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        level = request.args.get('level', 'all')
        if level == 'all':
            cursor.execute("SELECT * FROM Recipes")
        else:
            cursor.execute("SELECT * FROM Recipes WHERE difficulty_level = %s", (level,))
        
        recipes = cursor.fetchall()
        return jsonify(recipes)

    except Exception as e:
        print(f"Database error: {str(e)}")
        return jsonify({"error": "Database operation failed"}), 500

    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()


@app.route('/recipe/<int:recipe_id>', methods=['GET'])
def get_recipe_detail(recipe_id):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.callproc('sp_get_recipe_by_id', (recipe_id,))
        for result in cursor.stored_results():
            recipe = result.fetchone()
            return jsonify(recipe)
    finally:
        cursor.close()
        conn.close()

# ---------- REVIEWS ----------
@app.route('/recipe/<int:recipe_id>/review', methods=['POST'])
def submit_review(recipe_id):
    data = request.json
    conn = None
    cursor = None
    try:
        if not data or 'user_id' not in data or 'rating' not in data or 'comment' not in data:
            return jsonify({'success': False, 'error': 'Invalid input data'}), 400

        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.callproc('sp_add_review', (
            recipe_id,
            data['user_id'],
            data['rating'],
            data['comment']
        ))
        conn.commit()
        return jsonify({'success': True})

    except mysql.connector.Error as err:
        print(f"MySQL Error: {err}")  # Debugging
        return jsonify({'success': False, 'error': f"MySQL Error: {str(err)}"}), 500

    except Exception as e:
        print(f"Unexpected Error: {e}")  # Debugging
        return jsonify({'success': False, 'error': f"Unexpected error: {str(e)}"}), 500

    finally:
        if cursor:  # Check if cursor is initialized
            cursor.close()
        if conn:
            conn.close()



# ---------- PROGRESS ----------
@app.route('/recipe/<int:recipe_id>/complete', methods=['POST'])
def complete_recipe(recipe_id):
    import mysql.connector  # Ensure this is imported

    try:
        data = request.get_json()
        print(f"Request data: {data}")
        if not data or 'user_id' not in data or not isinstance(data['user_id'], int):
            print("Invalid data format or missing user_id")
            return jsonify({'success': False, 'error': 'Invalid or missing user_id'}), 400

        conn = get_db_connection()
        print("Database connection established")
        cursor = conn.cursor()

        try:
            print(f"Calling stored procedure with user_id={data['user_id']} and recipe_id={recipe_id}")
            cursor.callproc('sp_complete_recipe', (data['user_id'], recipe_id))
            conn.commit()
            print("Stored procedure executed successfully")
            return jsonify({'success': True})
        except mysql.connector.Error as err:
            print(f"SQL Error: {err}")
            return jsonify({'success': False, 'error': f"Database error: {err}"}), 500
        finally:
            cursor.close()
            conn.close()
    except Exception as e:
        print(f"Unexpected error: {e}")
        return jsonify({'success': False, 'error': f"Unexpected error: {e}"}), 500



@app.route('/user/<int:user_id>/profile', methods=['GET'])
def get_profile(user_id):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.callproc('sp_get_user_profile', (user_id,))
        for result in cursor.stored_results():
            profile = result.fetchone()
            return jsonify(profile)
    finally:
        cursor.close()
        conn.close()

@app.route('/user/<int:user_id>/trophies', methods=['GET'])
def get_trophies(user_id):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.callproc('sp_get_user_trophies', (user_id,))
        trophies = []
        for result in cursor.stored_results():
            trophies.extend(result.fetchall())
        return jsonify(trophies)
    finally:
        cursor.close()
        conn.close()

@app.route('/user/<int:user_id>/dashboard', methods=['GET'])
def get_dashboard(user_id):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.callproc('sp_get_dashboard_stats', (user_id,))
        for result in cursor.stored_results():
            stats = result.fetchone()
            return jsonify(stats)
    finally:
        cursor.close()
        conn.close()

@app.route('/')
def home():
    return render_template('index.html')

# ---------- RUN ----------
if __name__ == '__main__':
    app.run(debug=True)

