# app.py

from flask import Flask, request, jsonify
import psycopg2
import os
from flask_cors import CORS
from datetime import datetime

app = Flask(__name__)
CORS(app)

# Database connection setup
def get_db_connection():
    conn = psycopg2.connect(
        dbname=os.getenv('DB_NAME', 'todo_app'),
        user=os.getenv('DB_USER', 'postgres'),
        password=os.getenv('DB_PASSWORD', 'prakhar411'),
        host=os.getenv('DB_HOST', 'localhost'),
        port=os.getenv('DB_PORT', '5432')
    )
    return conn

def format_date(date):
    if date:
        return date.isoformat()  # ISO 8601 format
    return None

@app.route('/tasks', methods=['GET'])
def get_tasks():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute('SELECT id, title, is_completed, due_date FROM tasks;')
    tasks = cur.fetchall()
    cur.close()
    conn.close()

    task_list = [{'id': t[0], 'title': t[1], 'is_completed': t[2], 'due_date': format_date(t[3])} for t in tasks]
    return jsonify(task_list)

@app.route('/tasks', methods=['POST'])
def create_task():
    new_task = request.json
    title = new_task['title']
    is_completed = new_task['is_completed']
    due_date = new_task['due_date'] if 'due_date' in new_task else None

    if due_date:
        due_date = datetime.fromisoformat(due_date)  # Convert to datetime if needed

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute('INSERT INTO tasks (title, is_completed, due_date) VALUES (%s, %s, %s) RETURNING id;',
                (title, is_completed, due_date))
    task_id = cur.fetchone()[0]
    conn.commit()
    cur.close()
    conn.close()

    return jsonify({'id': task_id, 'title': title, 'is_completed': is_completed, 'due_date': format_date(due_date)}), 201

@app.route('/tasks/<int:id>', methods=['DELETE'])
def delete_task(id):
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute('DELETE FROM tasks WHERE id = %s;', (id,))
    conn.commit()
    cur.close()
    conn.close()

    return '', 204

@app.route('/tasks/<int:id>', methods=['PUT'])
def update_task(id):
    updated_task = request.json
    title = updated_task['title']
    is_completed = updated_task['is_completed']
    due_date = updated_task.get('due_date', None)  # Handle due_date update

    if due_date:
        due_date = datetime.fromisoformat(due_date)  # Convert to datetime if needed

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute('UPDATE tasks SET title = %s, is_completed = %s, due_date = %s WHERE id = %s;',
                (title, is_completed, due_date, id))
    conn.commit()
    cur.close()
    conn.close()

    return jsonify({'id': id, 'title': title, 'is_completed': is_completed, 'due_date': format_date(due_date)})

if __name__ == '__main__':
    app.run(debug=True)
