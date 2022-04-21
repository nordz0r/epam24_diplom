from flask import Flask, render_template, request
import os
import requests
import json
import mariadb
from datetime import date, datetime
import pandas as pd
from pandas.tseries import offsets


database_cred = {
    "host":os.getenv('db_host'),
    "user":os.getenv('db_user'),
    "password":os.getenv('db_password'),
    "database":os.getenv('db_database')
}

def stress_test():
    prew = cur = 1
    element = 1750000

    for _ in range(int(element-2)):
        prew, cur = cur, prew + cur

def main_app():
    return

# load data
main_app()

app = Flask(__name__)


@app.route('/')
@app.route('/index')
def index():
   # database_table = "covid_stats"
   # db_conn = mariadb.connect(**database_cred)
   # cur = db_conn.cursor()
   # cur.execute("select DISTINCT country_code from " + database_table)
   # countries = cur.fetchall()
   response = requests.get("os.getenv('backend')/backend/api/v1.0/countries")
   countries = response.json()
   return render_template('index.html', countries = countries)


@app.route('/stats/<country>')
def stats(country):
   response = requests.get("os.getenv('backend')/backend/api/v1.0/stats/" + country)
   rows = response.json()
   return render_template('stats.html', rows = rows, country = country)
   # return rows



@app.route('/update')
def update():
   timestamp = datetime.today().replace(microsecond=0)
   requests.get("os.getenv('backend')/backend/api/v1.0/update")
   return render_template('update.html', timestamp = timestamp)


@app.route('/stress')
def stress():
   stress_test()
   return render_template('stress.html')


if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0", port="8080")
