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
    print self
    self.update_state(state="MSG",meta={"message":message})

@app.task(bind=True,acks_late=True)
def echo(self, s="Hello world!"):
    print "Echo: "+str(s)
    for i in range(0,5):
        time.sleep(1)
        print "print "+str(i)
        report(self, i)
    dic = {
        "a": "a string",
        "b": 23.45,
        "S" : s
    }
    return dic

@app.task(bind=True,acks_late=True)
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



