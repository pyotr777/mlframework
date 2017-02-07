# Produce number of tasks with parameters from given ranges.
# 2017 (C) Bryzgalov Peter @ CHITEC, Stair Lab

from __future__ import absolute_import, unicode_literals
from .celery import app
import yaml, json
from .tasks import train, echo


def yaml_load(filepath):
    with open(filepath,"r") as fd:
        data = yaml.load(fd)
    return data

def yaml_dump(filepath, data):
    with open(filepath, "w") as fd:
        yaml.dump(data, fd)
        fd.close()


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
    #print status
    # Intermediate results
    if type(res) is dict:
        for k in res:
            print k,":",res[k]
    else:
        print res

if __name__ == '__main__':
    base_pars = {
        'maxiter':3,
        'dataset':"TwentyNg",
        'minibatchsize':50,
        'nfolds':2
    }
    results = []
    filepath = "./paramtest.yml"
    data=yaml_load(filepath)
    if type(data) is dict:
        for k in data:
            print k + " : " + str(data[k])
            paramrange = data[k]
            if type(paramrange) is list:
                for par in paramrange:
                    llength = len(paramrange)
                    print k+"="+str(par)
                    pars=base_pars
                    pars[k]=par
                    result = train.delay(jsonify(pars))
                    results.append(result)

    print "All tasks sent"
    for r in results:
        r.get(on_message=report_state, propagate=True)

    print "All tasks finished."

