import mysql.connector

db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="root123",
    database="mini_project"
)

cursor = db.cursor(dictionary=True)