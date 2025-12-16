import argparse
import subprocess
import pathlib
from pathlib import Path
import re

def generate_cmd_base():
    return 'nix run github:ryantm/agenix --'
    
def generate_cmd_decrypt(identity: str, secret: str):
    return f'{generate_cmd_base()} -d {secret} --identity {identity}'

def generate_cmd_encrypt(identity: str, secret: str):
    return f'{generate_cmd_base()} -e {secret} --identity {identity}'

def secrets_list(rootpath: Path, recursive: bool) -> list(Path):
    return [p for p in (rootpath.rglob("*") if recursive else rootpath.glob("*")) if p.name.endswith('.age')]

def secrets_read():
    with open('./secrets.nix', 'r') as f:
        for line in f.readlines():
            m = re.match('^ *"([\w\d-_/]+\.age)"', line)
            if m:
                yield m.group(1)
        
def secrets(rooutpath: Path, recursive: bool, check: bool = True):
    paths = secrets_list(rootpath, recursive)
    if check:
        listed_secrets = secrets_read()
        ok = True
        for p in paths:
            if not str(p) in listed_secrets:
                print(f'error: found agefile {str(p)}, not listed in secrets.nix')
                ok = False
        if not ok:
            exit(2)
    return paths

if __name__ == 'main':
    parser = argparse.ArgumentParser()
    parser.add_argument('path', description = 'path to subtree containing age files to change')
    parser.add_argument('-r', '--recursive', action='store_true', description = 'whether to recurse into subdirectories when finding agefiles')
    # parser.add_argument('old')
    parser.add_argument('-c', '--check', action='store_true')
