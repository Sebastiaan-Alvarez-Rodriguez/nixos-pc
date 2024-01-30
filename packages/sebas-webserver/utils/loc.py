import utils.fs as fs


def datadir():
    '''Default path to data directory.'''
    return fs.join(fs.abspath(), 'data', 'json')