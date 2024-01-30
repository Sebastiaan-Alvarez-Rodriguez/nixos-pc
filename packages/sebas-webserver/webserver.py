#!/usr/bin/env python
import argparse
from flask import Flask, render_template
from flask_bootstrap import Bootstrap

from data import get_data, protect_data

app = Flask(__name__)
data = get_data()
protect_data(data)
app.config['data'] = data
bootstrap = Bootstrap(app)


@app.route('/')
@app.route('/index')
def index():
    return render_template('index.html')


def main():
    parser = argparse.ArgumentParser(
        prog='sebas-webserver',
        formatter_class=argparse.RawTextHelpFormatter,
        description='Start webserver'
    )

    print('static folder:', app.static_folder)

    parser.add_argument('--interface', metavar='interface', type=str, default='0.0.0.0', help='Interface to listen on (default="0.0.0.0").')
    parser.add_argument('--port', metavar='port', type=int, default=None, help='Port to listen on (default=8080 if debug, 80 otherwise). Do not forget: You MUST open the port in your firewall yourself.')
    parser.add_argument('--debug', action='store_true')
    args = parser.parse_args()


    if args.port == None:
        args.port = 8080 if args.debug else 80
    if args.debug:
        app.run(host=args.interface, port=args.port)
    else:
        from waitress import serve
        serve(app, host=args.interface, port=args.port)


if __name__ == "__main__":
    main()
