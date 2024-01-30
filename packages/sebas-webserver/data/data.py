import itertools
import json
from pathlib import Path

import utils.fs as fs
import utils.loc as loc

def get_jsons():
    return (Path(x) for x in fs.ls(loc.datadir(), only_files=True, full_paths=True) if x.endswith('.json'))


def post_process(data):
    '''Do post-processing on data. Mainly executes operations that Jinja cannot do inline in HTML templates.'''
    data['projects']['filters'] = set(x.lower() for x in itertools.chain.from_iterable(project['filters'] for project in data['projects']['project_items'].values()))


def get_data():
    '''Reads all JSON files to get the site data. This only happens on server boot, not per-request.'''
    data = {}
    for jsonfilepath in get_jsons():
        with open(jsonfilepath, 'r') as file:
            data[jsonfilepath.stem] = json.load(file)
    post_process(data)
    return data