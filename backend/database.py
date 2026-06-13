import psycopg2
import psycopg2.extras
from dotenv import load_dotenv
import os

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

def get_connection():
    conn = psycopg2.connect(DATABASE_URL)
    return conn

def execute_query(query, params=None, fetch=True):
    conn = get_connection()
    try:
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cursor.execute(query, params)
        
        # Always commit for INSERT/UPDATE/DELETE, regardless of fetch
        if query.strip().upper().startswith(('INSERT', 'UPDATE', 'DELETE')):
            conn.commit()
        
        if fetch:
            result = cursor.fetchall()
            return list(result)
        else:
            if not query.strip().upper().startswith(('INSERT', 'UPDATE', 'DELETE')):
                conn.commit()
            return {"success": True}
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()
        