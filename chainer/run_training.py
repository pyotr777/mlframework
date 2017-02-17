# Produce number of tasks with parameters from given ranges.
# 2017 (C) Bryzgalov Peter @ CHITEC, Stair Lab

from __future__ import absolute_import, unicode_literals
from .celery import app
from .master_functions import *
from .tasks import train, echo
from subprocess import Popen, PIPE, STDOUT
import numpy as np


if __name__ == '__main__':

    # Open file for writing results
    f= open("output.csv","w")

    paramatrix=yaml2Matrix("chainer/parameters.yml")

    # Create combinations matrix
    combinations=[]
    for l in range(0, len(paramatrix)):
        line = paramatrix[l][1:]
        combinations = joinLists(combinations, line)

    debug_print("Have "+str(len(combinations))+" combinations.",243)
    # Wrap combinataions into dictionary
    base_pars = {
    }
    results = []

    for c in range(0,len(combinations)):
        debug_print("paramatrix: "+str(paramatrix))
        debug_print("combinations:"+str(combinations))
        dic=base_pars
        for l in range(0, len(paramatrix)):
            debug_print(str(paramatrix[l][0])+"="+str(combinations[c][l]))
            dic[paramatrix[l][0]]=str(combinations[c][l])
        result = train.delay(jsonify(dic))
        debug_print("New task: "+str(result.id), 20)
        debug_print("Paramters: "+str(dic),20)
        results.append(result)

    print "All tasks sent"

    for r in results:
        r.get(on_message=parse_message, propagate=False)

    print "All tasks finished."



