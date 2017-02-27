# Produce number of tasks with parameters from given ranges.
# 2017 (C) Bryzgalov Peter @ CHITEC, Stair Lab

from __future__ import absolute_import, unicode_literals
from .celery import app
from lib.master_functions import *
from .tasks import train, echo
from subprocess import Popen, PIPE, STDOUT
import numpy as np


if __name__ == '__main__':
    # Check current dir
    pwd = ""
    pipe = Popen(["pwd"], stdout=PIPE, stderr=PIPE, close_fds=True)
    for line in iter(pipe.stdout.readline, b''):
        pwd = line
        print "Current dir: "+ pwd
    for line in iter(pipe.stderr.readline, b''):
        if len(line)>0:
            print "!"+line


    # Create file / clear file contents
    f= open("output.csv","w")


    # Wrap combinataions into dictionary
    base_pars = {
        'n':5,
    }
    results = []

    for c in range(0,5):
        dic=base_pars
        dic["n"] = int(dic["n"]) + c
        result = echo.delay(jsonify(dic))
        print "New task: "+str(result.id)
        print "Paramters: "+str(dic)
        results.append(result)
        line = str(result.id) + ","
        for k in dic:
            line += str(k)+"="+str(dic[k])+","
        f.write(line+"\n")
    f.close()

    print "All tasks sent"

    for r in results:
        r.get(on_message=parse_message, propagate=False)

    print "All tasks finished."