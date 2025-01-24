#!/usr/bin/python
# -*- coding: utf-8 -*-
"""
An lldb Python script to load breakpoints from file

Add to ~/.lldbinit:
    command script import ~/path/to/BreakpointLoader.py

Usage:
    (lldb)bl path/to/breakpoints/list

Breakpoint list file format:
    symbol  symbol_name       -- symbol breakpoint
    location  filename:linenum  -- set breakpoint at line of file
"""

import argparse
import shlex
import os


class LoadBreakpointCommand:
    description = 'Load breakpoints from file.'
    usage = 'bl <filename>'

    def __init__(self, debugger, unused):
        self.parser = argparse.ArgumentParser(
                description='',
                prog='bl',
                usage=self.usage,
                add_help=False)

        self.parser.add_argument(
                'filename',
                help='path to file which contains breakpoints list')

    def __call__(self, debugger, command, exe_ctx, result):
        command_args = shlex.split(command)
        try:
            args = self.parser.parse_args(command_args)
        except argparse.ArgumentError:
            return

        filename = os.path.expanduser(args.filename)
        try:
            with open(filename, 'r') as file:
                lines = file.readlines()
                target = debugger.GetSelectedTarget()
                self.process_breakpoints(target, lines)
        except IOError as e:
            print(f"Error opening file '{filename}': {e}")
            return

    def process_breakpoints(self, target, lines):
        for _, line in enumerate(lines):
            line = line.strip()
            if not line:
                continue

            items = line.split(' ')
            if len(items) != 2:
                continue

            instruction = items[0]
            destnation = items[1]
            bp = None

            if instruction == 'symbol':
                bp = target.BreakpointCreateByName(destnation)
            elif instruction == 'location':
                location = destnation.split(':')
                if len(location) != 2:
                    continue

                filepath = os.path.expanduser(location[0])
                linenum = int(location[1])
                bp = target.BreakpointCreateByLocation(filepath, linenum)

            if not bp or bp.GetNumLocations() == 0:
                print(f"breakpoint at '{destnation}' could not be set.")

    def get_short_help(self):
        return self.description

    def get_long_help(self):
        return self.parser.format_help()


def __lldb_init_module(debugger, interal_dict):
    debugger.HandleCommand('command script add -c BreakpointLoader.LoadBreakpointCommand bl')
