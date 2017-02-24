# Functions used by workers.
# 2017 (C) Bryzgalov Peter @ CHITEC, Stair Lab

import json


def exec(task, command):
    print command
    pipe = Popen(command, stdout=PIPE, stderr=PIPE, close_fds=True)
    out = ""
    err = ""
    for line in iter(pipe.stdout.readline, b''):
        print line
        out += line.rstrip()
    for line in iter(pipe.stderr.readline, b''):
        if len(line)>0:
            print "! "+line
            err += line.rstrip()
    report(task, { "out": out, "err": err })


def report(task, output_dic):
    output_dic["out"] = parseOutput(output_dic["out"])
    task.update_state(state="MSG",meta={"message":output_dic})


# Parse output:
# Remove ANSI control codes.
def parseOutput(s):
    contol_keys = dict.fromkeys(range(32))
    s = s.translate(contol_keys)
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

