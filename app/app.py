from flask import Flask, render_template, request
import os
import requests
import json
import mariadb
from datetime import date, datetime
import pandas as pd
from pandas.tseries import offsets


database_cred = {
    "host":"covid.cw1htr89vlre.eu-north-1.rds.amazonaws.com",
    "user":"covid",
    "password":"laserdisk",
    "database":"covid"
}

# database_cred = {
#     "host":os.getenv('db_host'),
#     "user":os.getenv('db_user'),
#     "password":os.getenv('db_password'),
#     "database":os.getenv('db_database')
# }




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
    global database_table
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


def stress_test():
    prew = cur = 1
    element = 1750000

    for _ in range(int(element-2)):
        prew, cur = cur, prew + cur

def main_app():
    insert_data_to_db()


# load data
main_app()

app = Flask(__name__)


@app.route('/')
@app.route('/index')
def index():
    return render_template('index.html', countries = countries)


@app.route('/stats/<country>')
def stats(country):
   db_conn = mariadb.connect(**database_cred)
   cur = db_conn.cursor()
   cur.execute("select * from " + database_table + " where country_code = '" + country + "' order by deaths ASC")
   rows = cur.fetchall()
   return render_template('stats.html', rows = rows, country = country)


@app.route('/update')
def update():
   insert_data_to_db()
   return render_template('update.html', timestamp = timestamp)


@app.route('/stress')
def stress():
   stress_test()
   return render_template('stress.html')


if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0", port="8080")
