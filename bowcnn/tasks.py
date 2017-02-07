# Produce number of tasks with parameters from given ranges.
# 2017 (C) Bryzgalov Peter @ CHITEC, Stair Lab

from __future__ import absolute_import, unicode_literals
from .celery import app

import time
import json
from subprocess import Popen, PIPE, STDOUT

def unjsonify(a):
    try:
        arr = json.loads(a)
        return arr
    except TypeError:
        print  "unjsonify recieved object of type",type(a)
        return a

def report(self, message):
    self.update_state(state="PROGRESS",meta={"message":message})

@app.task(bind=True)
def echo(self, s="Hello world!"):
    print "Echo: "+str(s)
    return str(s)

@app.task(bind=True)
def train(self, pars):
    report(self,"name:"+__name__+" pars:"+ str(pars))
    par = unjsonify(pars)

    # Check current dir
    pipe = Popen(["pwd"], stdout=PIPE, stderr=PIPE, close_fds=True)
    for line in iter(pipe.stdout.readline, b''):
        report(self,line)
    for line in iter(pipe.stderr.readline, b''):
        if len(line)>0:
            report(self,"err:"+line)

    cmd = ["python","-m","bowcnn.cv_baseline"]
    for key in par:
        cmd.append(str("--"+key))
        cmd.append(str(par[key]))
    report(self, "Command:"+str(cmd))
    print cmd
    pipe = Popen(cmd, stdout=PIPE, stderr=PIPE, close_fds=True)

    for line in iter(pipe.stdout.readline, b''):
        report(self,line)
    for line in iter(pipe.stderr.readline, b''):
        if len(line)>0:
            report(self,"err:"+line)



