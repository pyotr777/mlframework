#!/usr/bin/env python

# Python interface to bash scripts and commands.
# ver 0.1
# 2018 (C) Peter Bryzgalov @ CHITECH Stair Lab

# addCommand() adds a callable object to the namespace of this module with provided name.
# Now the object can be called with "commands.name()"

# Usage:
# After importing module with "import commands"
# a. List available commands with "commands.lscom()"
# b. Call abailable commands with "commands.<command> arguments"


import subprocess
import csv
import os

package_directory = os.path.dirname(os.path.abspath(__file__))
scripts_location=os.path.join(package_directory,"..","scripts")

command_list=[]
debug=True

if debug:
    print "Scripts location:",scripts_location

class BaseCommand(object):

    def __init__(self,command,usage=""):
        self.command = command
        self.usage = usage

    def __call__(self,*args):
        if debug:
            print "Calling",self.command,args
        # Check if command is a scrit file
        exe_script = os.path.join(scripts_location,self.command)
        # Check if file exists
        if os.path.isfile(exe_script):
            exe_command=[exe_script]
        else:
            exe_command=[self.command]

        for arg in args:
            exe_command.append(arg)
        proc = subprocess.Popen(exe_command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,cwd=scripts_location)
        self.__handleOutput__(proc)

    def __handleOutput__(self,proc):
        for line in iter(proc.stdout.readline, b''):
            print line,


# Lists availabale command named and usages
def lscom():
    for com in command_list:
        print com,"\t\t",globals()[com].usage
    #print "globals:"
    #print globals().keys()

def remote(host,command,*args):
    if command in command_list:
        # Command is in list of scripts
        # Change command name to actual script name
        command = os.path.join(scripts_location,globals()[command].command)
        print "Command file is",command
    else:
        print "Command",command,"not found"

# Adds a callable object with given name to the module namespace
def addCommand(command,name=None,usage=""):
    if command is None:
        return
    if name is None:
        name = command
    globals()[name] = BaseCommand(command,usage=usage)
    command_list.append(name)


# Add available scripts
#addCommand("ls", usage="List files.")
#addCommand("../test_nvidia.sh","get_nv",usage="Get installed NVIDIA driver and CUDA versions.")

with open(os.path.join(scripts_location,"scripts.csv"),"rb") as csvfile:
    csv_reader = csv.reader(csvfile)
    for row in csv_reader:
        addCommand(row[0],row[1],row[2])


