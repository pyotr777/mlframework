# Produce number of tasks with parameters from given ranges.
# 2017 (C) Bryzgalov Peter @ CHITEC, Stair Lab

from __future__ import absolute_import, unicode_literals
from .celery import app
import yaml, json
from .tasks import train, echo
from subprocess import Popen, PIPE, STDOUT
import numpy as np


def jsonify(pars):
    if type(pars) is list:
        a = pars.tolist()
    else:
        a = json.dumps(pars)
    return a


def unjsonify(a):
    try:
        arr = json.loads(a)
        np_arr = np.array(arr)
        return np_arr
    except TypeError:
        #print  "unjsonify recieved object of type",type(a)
        return a


def report_state(msg):
    #print "Received message of type "+ str(type(msg))
    #for k in msg:
    #    print k,":",msg[k]
    #print ""
    status = msg[u'status']
    res = msg[u'result']
    if status == "SUCCESS":
        print "Finished with result ", res
        return
    elif status == "MSG":
        print res["message"]
        return
    else:
        if type(res) is dict:
            for k in res:
                print k,":",res[k]
        else:
            print res


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

    # Wrap combinataions into dictionary
    base_pars = {
        'maxiter':3,
        'dataset':"TwentyNg",
        'minibatchsize':50,
        'nfolds':2
    }
    results = []

    for c in range(0,5):
        dic=base_pars
        result = echo.delay(jsonify(dic))
        print "New task: "+str(result.id)
        print "Paramters: "+str(dic)
        results.append(result)

    print "All tasks sent"

    for r in results:
        r.get(on_message=report_state, propagate=False)

    print "All tasks finished."