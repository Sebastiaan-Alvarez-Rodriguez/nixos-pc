import argparse
import os
import pathlib
from pathlib import Path
import re
import subprocess

def yes_no(arg):
    return arg.lower() == 'y' or arg.lower() == 'yes'

def flatten(l):
    return [x for xs in l for x in xs]

def command_available():
    return subprocess.run(generate_cmd_base() + ['--help'], stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL).returncode == 0

def generate_cmd_base() -> list[str]:
    return ['age']
    
def generate_cmd_decrypt(identity: str, age: str):
    return generate_cmd_base() + ['-d', '-i', identity, age]

def generate_cmd_encrypt(identity: list[str]):
    if not any(identity):
        raise ValueError('Must have at least one new identity set')
    return generate_cmd_base() + ['-e'] + flatten(['-i', id] for id in identity)

def secrets_list(rootpath: Path, recursive: bool):
    return [p for p in (rootpath.rglob("*") if recursive else rootpath.glob("*")) if p.name.endswith('.age')]

if __name__ == '__main__':
    parser = argparse.ArgumentParser(prog='swapkey', description='replace identity for a bunch of secrets at once')
    parser.add_argument('path', help='path to subtree containing age files to change')
    parser.add_argument('--current-identity', required=True, help='currently-used secret')
    parser.add_argument('--new-identity', required=True, action='append', help='New secret. Can repeat this argument to define multiple identities')
    parser.add_argument('-r', '--recursive', action='store_true', help='whether to recurse into subdirectories when finding agefiles')

    args = parser.parse_args()
    paths = secrets_list(Path(args.path), args.recursive)
    if not any(paths):
        print(f'error: found 0 paths. Is there any .age files in {args.path}?')
        exit(2)
    if not command_available():
        print(f'need command {generate_cmd_base()[0]} to be available, but could not find it')
        exit(3)

    print('Found the following paths:')
    for path in paths:
        print(f'\t{str(path)}')

    ok = yes_no(input('Continue? [Y/n]: '))
    if ok:
        any_keys = any(args.new_identity)
        for path in paths:
            new_path = Path(str(path)+'.tmp')
            print(f'processing {path}')
            secret = subprocess.run(generate_cmd_decrypt(args.current_identity, str(path)), stdout=subprocess.PIPE, check=True).stdout.decode('utf-8')[:-1]

            if not any_keys:
                print('\tno new keys specified. Continuing...')
            else:
                print('\tgenerating new secret')
                print(f'\tgenerating: {generate_cmd_encrypt(args.new_identity)}')
                enc = (subprocess.run(generate_cmd_encrypt(args.new_identity), input=secret.encode(), stdout=subprocess.PIPE, check=True).stdout)
                print(f'\twriting to {new_path}')
                with open(new_path, 'wb') as f:
                    f.write(enc)
                print(f'\treplacing old secret with new secret')
                os.replace(new_path, path)
