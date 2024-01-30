import random

def anti_miner(item):
    '''Very simple protection: 
    Given value is 'encrypted' by a rotation.
    The user has to rotate the chars back to their original place, which happens with javascript.
    Bots that scrape webpages always turn of javascript, and thus cannot find the original value.
    This stuff has been working for years, and probably will keep working in the future.'''
    if not 'value' in item:
        print(f'Encountered non-protectable item: {item}')
        return
    shift_amount = random.randint(6,2**8-1)

    item['value'] = ''.join(chr(ord(char)+shift_amount) for char in str(item['value']))
    item['key'] = -shift_amount 


def __protect(obj):
    is_dict = isinstance(obj, dict)
    do_protect = is_dict and 'protected' in obj and obj['protected']

    if is_dict:
        if do_protect:
            anti_miner(obj)
        for k,v in obj.items():
            __protect(v)


def protect_data(items):
    '''Iterates a dict (with optional nested dicts) and applies protection on items when indicated.
    Items can indicate they need protection using:
    Note: Only 'value' will be protected.
    The 'protected' field can have 3 values: 'true'/true, 'false', 'recursive'.
        + 'true' indicates we need protection for a field named 'value'.
        + 'false' indicates we need no protection for a field named 'value'.
    Example:
        {
            'my_items': {
                'value': 'No protection enabled',
                'protected': false,
                'bla bla': 'oof'
            },
            'general': {
                'value': 'Do not touch', 
                'protected': true
            },
            'oh_hi_mark': {
                'value': 'this is protected!',
                'protected': true,
                'extra_nested': {
                    'value': 'This is not protected'
                }
            }
        }
    '''
    __protect(items)