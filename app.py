from flask import Flask, render_template, request
from os import environ
import requests
import json
import mariadb
from datetime import date, datetime
import pandas as pd
from pandas.tseries import offsets
# import sqlalchemy
# from sqlalchemy import create_engine
# from sqlalchemy.engine.url import URL
# import pymysql

database_cred = {
    "host":"localhost",
    "user":"covid-app",
    "password":"laserdisk",
    "database":"covid-app"
}


def get_data():
    current_date = date.today()
    start_date = date(date.today().year, 1, 1)
    target_url = 'https://covidtrackerapi.bsg.ox.ac.uk/api/v2/stringency/date-range/' + str(start_date) + '/' + str(current_date)
    response = requests.get(target_url)
    # get countries for dropmenu
    global countries, timestamp
    countries = response.json()['countries']
    timestamp = datetime.today().replace(microsecond=0)
    table = response.json()['data']
    return table

def insert_data_to_db():
    # collect data
    database_table = "covid_stats"
    source = get_data()
    result = []

    for source_date in list(source.keys()):
        for source_countries in list(source[source_date].keys()):
            result.append(source[source_date][source_countries])
    try:
        db_conn = mariadb.connect(**database_cred)
    except mariadb.Error as mariadb_error:
        print("Error connecting to MariaDB: " + str(mariadb_error))

    cur = db_conn.cursor()
    # drop and new create new table
    cur.execute("DROP TABLE IF EXISTS " + database_table)
    cur.execute("CREATE TABLE " + database_table + " (id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY, date_value DATE, country_code VARCHAR(3), confirmed INT, deaths INT, stringency_actual FLOAT(5,2), stringency FLOAT(5,2))")
    # insert to database
    for result_data in result:
        try: 
            cur.execute("INSERT INTO " + database_table + " (date_value, country_code, confirmed, deaths, stringency_actual, stringency) VALUES (?, ?, ?, ?, ?, ?)", (result_data['date_value'], result_data['country_code'], result_data['confirmed'], result_data['deaths'], result_data['stringency_actual'], result_data['stringency']))
        except mariadb.Error as mariadb_error: 
            print("MariaDB error: " + str(mariadb_error))
    # write to db
    db_conn.commit()
    # close connections
    cur.close()
    db_conn.close()

def main_app():
    insert_data_to_db()


# insert_data_to_db()
# get_data()


main_app()

app = Flask(__name__)

if __name__ == '__main__':
    app.run(debug=True)


@app.route('/')
@app.route('/index')
def index():
   return render_template('index.html', countries = countries)
