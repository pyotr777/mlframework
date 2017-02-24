# Execute tasks with provided parameters
# 2017 (C) Bryzgalov Peter @ CHITEC, Stair Lab

from __future__ import absolute_import, unicode_literals
from .celery import app
from .worker_functions import *
import time


@app.task(bind=True,acks_late=True)
def default(self, pars):
    # Report hostname
    cmd = "echo hostname=$(hostname)"
    sync_exec(self, cmd)

    # Form command
    par = unjsonify(pars)
    cmd = <>
    for key in par:
        cmd.append(str("--"+key))
        if type(par[key]) is not bool:
            cmd.append(str(par[key]))
    report(self, "Command: " + " ".join(cmd))
    sync_exec(self, cmd)
