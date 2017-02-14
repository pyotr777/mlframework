# Produce number of tasks with parameters from given ranges.
# 2017 (C) Bryzgalov Peter @ CHITEC, Stair Lab

from __future__ import absolute_import, unicode_literals
from .celery import app
from .worker_functions import unjsonify, report, parseOutput, debug_print
import time
from subprocess import Popen, PIPE, STDOUT



@app.task(bind=True,acks_late=True)
def echo(self, dic={"n":2}):
    tid = self.request.id
    dic = unjsonify(dic)
    n = int(dic["n"])
    for i in range(0,n):
        time.sleep(1)
        s = "Title: i="+str(i)
        print str(tid)+" "+s
        report(self, s)
    dic["tid"]=tid
    return dic

@app.task(bind=True,acks_late=True)
def train(self, pars):
    report(self, { "name": __name__, "pars": pars })
    par = unjsonify(pars)

    cmd = ["python","-u", "chainer/examples/mnist/train_mnist.py"]
    for key in par:
        cmd.append(str("--"+key))
        if type(par[key]) is not bool:
            cmd.append(str(par[key]))
    report(self, {"Command": " ".join(cmd)})
    print " ".join(cmd)
    pipe = Popen(cmd, stdout=PIPE, stderr=PIPE, close_fds=True)

    for line in iter(pipe.stdout.readline, b''):
        report(self,line.rstrip())

    for line in iter(pipe.stderr.readline, b''):
        if len(line)>0:
            debug_print(line.rstrip())




