# Execute tasks with provided parameters
# 2017 (C) Bryzgalov Peter @ CHITEC, Stair Lab

from __future__ import absolute_import, unicode_literals
from .celery import app
from .worker_functions import *
import time


@app.task(bind=True,acks_late=True)
def echo(self, dic={"n":2}):
    dic = unjsonify(dic)
    n = int(dic["n"])
    for i in range(0,n):
        time.sleep(1)
        report(self, "i="+str(i))
        dic["i"]=i
    return dic

@app.task(bind=True,acks_late=True)
def train(self, pars):
    # Report hostname
    cmd = "echo hostname=$(hostname)"
    sync_exec(self, cmd)

    # Form command
    par = unjsonify(pars)
    cmd = ["python","-u", "chainer_bow/examples/word2vec/train_word2vec.py"]
    for key in par:
        cmd.append(str("--"+key))
        if type(par[key]) is not bool:
            cmd.append(str(par[key]))
    report(self, "Command: " + " ".join(cmd))
    sync_exec(self, cmd)
