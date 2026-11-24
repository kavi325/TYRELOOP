
from database.db import get_db_connection

connection = get_db_connection()

if connection:
    print("TYRELOOP DATABASE CONNECTED!")

    cursor = connection.cursor()
    cursor.execute("SHOW TABLES")

    for table in cursor.fetchall():
        print(table[0])

    cursor.close()
    connection.close()
else:
    print("Database connection unsuccessful.")
