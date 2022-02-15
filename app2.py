from flask import Flask, render_template

app = Flask(__name__)

if __name__ == '__main__':
    app.run(debug=True)


@app.route('/')
@app.route('/index')
def index():
    return render_template('index.html')
