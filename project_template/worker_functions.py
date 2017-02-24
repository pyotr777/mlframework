# Functions used by workers.
# 2017 (C) Bryzgalov Peter @ CHITEC, Stair Lab

import json, string
from subprocess import Popen, PIPE, STDOUT

def sync_exec(task, command):
    print command
    if type(command) is str or type(command) is unicode:
        pipe = Popen(command, stdout=PIPE, stderr=PIPE, close_fds=True, shell=True)
    elif type(command) is list:
        pipe = Popen(command, stdout=PIPE, stderr=PIPE, close_fds=True)
    for line in iter(pipe.stdout.readline, b''):
        print line
        report(task, { "out": line})
    for line in iter(pipe.stderr.readline, b''):
        if len(line)>0:
            print "! "+line
            report(task, { "err": line })


def report(task, output_dic):
    if type(output_dic) is dict:
        if len(output_dic) < 1:
            return
        if "out" in output_dic and (type(output_dic["out"]) is str or  type(output_dic["out"]) is unicode):
            output_dic["out"] = parseOutput(output_dic["out"])
    task.update_state(state="MSG",meta={"message":output_dic})


# Parse output:
# Remove ANSI control codes.
def parseOutput(s):
    all_bytes = string.maketrans('','')
    s = s.translate(all_bytes, all_bytes[:32])
    return s


def unjsonify(a):
    if type(a) is dict:
        return a
    try:
        arr = json.loads(a)
        return arr
    except TypeError:
        print  "unjsonify recieved object of type",type(a)
        return a

