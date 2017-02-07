# Produce number of tasks with parameters from given ranges.
# 2017 (C) Bryzgalov Peter @ CHITEC, Stair Lab

from __future__ import absolute_import, unicode_literals
from .celery import app

import time


def unjsonify(a):
    try:
        arr = json.loads(a)
        np_arr = np.array(arr)
        return np_arr
    except TypeError:
        print  "unjsonify recieved object of type",type(a)
        return a


def jsonify(numpy_array):
    a = numpy_array.tolist()
    return a

def report(self, message):
    self.update_state(state="PROGRESS",meta={"message":message})

@app.task(bind=True)
def echo(self, s="Hello world!"):
    print "Echo: "+str(s)
    return str(s)

@app.task(bind=True)
def train(self, pars):
    print "Parameter pars type: "+ str(type(pars))
    report(self,"Parameter pars type: "+ str(type(pars)))
    cmd = ["python","-m",".cv_baseline"]
    for key in pars:
        cmd.append(str("--"+key))
        cmd.append(str(pars[key]))
    report(self, "Command:"+str(cmd))
    print cmd
    pipe = subprocess.Popen(cmd, stdout=PIPE, stderr=PIPE, close_fds=True)

    for line in iter(pipe.stdout.readline, b''):
        report(self,line)
    for line in iter(pipe.stderr.readline, b''):
        if len(line)>0:
            report(self,"err:"+line)



