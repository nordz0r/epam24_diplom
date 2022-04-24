# pylint: disable=missing-module-docstring
# pylint: disable=missing-class-docstring
# pylint: disable=missing-function-docstring
# pylint: disable=line-too-long
# pylint: disable=method-hidden
# pylint: disable=arguments-renamed
import os
from datetime import date

import mariadb
import requests
from flask import Flask, jsonify
from flask.json import JSONEncoder

database_cred = {
    "host": os.getenv('db_host'),
    "user": os.getenv('db_user'),
    "password": os.getenv('db_password'),
    "database": os.getenv('db_database')
}


def get_data():
    current_date = date.today()
    start_date = date(date.today().year, 1, 1)
    target_url = 'https://covidtrackerapi.bsg.ox.ac.uk/api/v2/stringency/date-range/' + str(start_date) + '/' + str(current_date)  # noqa: E501
    response = requests.get(target_url)
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
    # cur.execute("TRUNCATE TABLE " + database_table)
    cur.execute("DROP TABLE IF EXISTS " + database_table)
    cur.execute("CREATE TABLE IF NOT EXISTS " + database_table + " (id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY, date_value DATE, country_code VARCHAR(3), confirmed INT, deaths INT, stringency_actual FLOAT(5,2), stringency FLOAT(5,2))")  # noqa: E501
    # insert to database
    for result_data in result:
        try:
            cur.execute("INSERT INTO " + database_table + " (date_value, country_code, confirmed, deaths, stringency_actual, stringency) VALUES (?, ?, ?, ?, ?, ?)", (result_data['date_value'], result_data['country_code'], result_data['confirmed'], result_data['deaths'], result_data['stringency_actual'], result_data['stringency']))  # noqa: E501
        except mariadb.Error as mariadb_error:
            print("MariaDB error: " + str(mariadb_error))
    # write to db
    db_conn.commit()
    # close connections
    cur.close()
    db_conn.close()


class CustomJSONEncoder(JSONEncoder):
    def default(self, obj):
        try:
            if isinstance(obj, date):
                return obj.isoformat()
            iterable = iter(obj)
        except TypeError:
            pass
        else:
            return list(iterable)
        return JSONEncoder.default(self, obj)


def main_app():
    insert_data_to_db()


# load data
main_app()

app = Flask(__name__)
app.json_encoder = CustomJSONEncoder


@app.route('/backend/api/v1.0/countries', methods=['GET'])
def get_countries():
    database_table = "covid_stats"
    db_conn = mariadb.connect(**database_cred)
    cur = db_conn.cursor()
    cur.execute("select DISTINCT country_code from " + database_table)
    rows = cur.fetchall()
    cur.close()
    db_conn.close()
    return jsonify(rows)


@app.route('/backend/api/v1.0/stats/<country>', methods=['GET'])
def stats(country):
    database_table = "covid_stats"
    db_conn = mariadb.connect(**database_cred)
    cur = db_conn.cursor()
    cur.execute("select * from " + database_table + " where country_code = '" + country + "' order by deaths ASC")  # noqa: E501
    rows = cur.fetchall()
    cur.close()
    db_conn.close()
    return jsonify(rows)


@app.route('/backend/api/v1.0/update')
def update():
    insert_data_to_db()
    return {"message": "success"}


if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0", port="5000")
