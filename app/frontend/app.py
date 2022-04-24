from flask import Flask, render_template, request
import os
import requests
import json
from datetime import date, datetime
import pandas as pd
from pandas.tseries import offsets


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
   response = requests.get("http://covapp-backend:5000/backend/api/v1.0/countries") #ToDO: fix zones!
   countries = response.json()
   return render_template('index.html', countries = countries)

@app.route('/stats/<country>')
def stats(country):
   response = requests.get("http://covapp-backend:5000/backend/api/v1.0/stats/" + country)
   rows = response.json()
   return render_template('stats.html', rows = rows, country = country)


@app.route('/update')
def update():
   timestamp = datetime.today().replace(microsecond=0)
   requests.get("http://covapp-backend:5000/backend/api/v1.0/update")
   return render_template('update.html', timestamp = timestamp)


@app.route('/stress')
def stress():
   timestamp = datetime.today().replace(microsecond=0)
   stress_test()
   return render_template('stress.html', timestamp = timestamp)


if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0", port="8080")
