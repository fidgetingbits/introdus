#!/usr/bin/env python
import os
import sys

try:
    import pynvim
except Exception:
    print("WARNING: Your shell is probably inside of a venv?")
    raise

nvim = pynvim.attach("socket", path=os.environ["NVIM"])

if len(sys.argv) <= 1:
    print("WARNING: Specify a path to edit")
else:
    nvim.command(f'execute ":SudaRead {sys.argv[1]}"')
