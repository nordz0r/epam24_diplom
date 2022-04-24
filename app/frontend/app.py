# pylint: disable=missing-module-docstring
# pylint: disable=missing-class-docstring
# pylint: disable=missing-function-docstring
from datetime import datetime

import requests
from flask import Flask, render_template


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
    backend = "http://covapp-backend:5000"
    response = requests.get(backend + "/backend/api/v1.0/countries")
    countries = response.json()
    return render_template('index.html', countries=countries)


@app.route('/stats/<country>')
def stats(country):
    backend = "http://covapp-backend:5000"
    response = requests.get(backend + "/backend/api/v1.0/stats/" + country)
    rows = response.json()
    return render_template('stats.html', rows=rows, country=country)


@app.route('/update')
def update():
    timestamp = datetime.today().replace(microsecond=0)
    backend = "http://covapp-backend:5000"
    requests.get(backend + "/backend/api/v1.0/update")
    return render_template('update.html', timestamp=timestamp)


@app.route('/stress')
def stress():
    timestamp = datetime.today().replace(microsecond=0)
    stress_test()
    return render_template('stress.html', timestamp=timestamp)


if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0", port="8080")
