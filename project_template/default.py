# Produce number of tasks with parameters from given ranges.
# Calls "default" task from tasks.py.
# 2017 (C) Bryzgalov Peter @ CHITEC, Stair Lab

from __future__ import absolute_import, unicode_literals
from .celery import app
from lib.master_functions import *
from .tasks import *
from subprocess import Popen, PIPE, STDOUT
import numpy as np
import os


if __name__ == '__main__':
    if os.environ.get('DEBUG') is not None:
        print "default.py is in debug mode"
        debug = os.environ.get('DEBUG')
    # Open file for writing results
    f= open("output.csv","w")

    paramatrix=yaml2Matrix("<>/parameters.yml")

    # Create combinations matrix
    combinations=[]
    for l in range(0, len(paramatrix)):
        line = paramatrix[l][1:]
        combinations = joinLists(combinations, line)

    if debug is not None:
        debug_print("Have "+str(len(combinations))+" combinations.",243)
    # Wrap combinataions into dictionary
    base_pars = {
    }
    results = []
    if debug is not None:
        debug_print("paramatrix: "+str(paramatrix))
        debug_print("combinations:"+str(combinations))
    for c in range(0,len(combinations)):
        dic=base_pars
        for l in range(0, len(paramatrix)):
            dic[paramatrix[l][0]]=str(combinations[c][l])
        result = default.delay(jsonify(dic))
        debug_print("Task ID: "+str(result.id), 20)
        debug_print("Param-s: "+str(dic),20)
        results.append(result)
        s = str(result.id) + ","
        for k in dic:
            s += str(k)+"="+str(dic[k])+","
        f.write(s+"\n")

    f.close()

    print "All tasks sent"

    for r in results:
        r.get(on_message=parse_message, propagate=False)

    print "All tasks finished."



