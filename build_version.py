#!/usr/bin/env python3
import os

def update_version():
    with open('VERSION.md', 'r') as f:
        version = f.read().strip()

    header_path = 'src/pc/network/version.h'
    if os.path.exists(header_path):
        with open(header_path, 'r') as f:
            lines = f.readlines()

        with open(header_path, 'w') as f:
            for line in lines:
                if line.startswith('#define SM64COOPDX_VERSION '):
                    f.write(f'#define SM64COOPDX_VERSION "v{version}"\n')
                else:
                    f.write(line)
        print(f"Updated C header to v{version}")
    else:
        print(f"Warning: {header_path} not found.")

if __name__ == '__main__':
    update_version()
