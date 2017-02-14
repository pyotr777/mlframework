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


def parse_message(msg):
    debug_print("run_training received message "+ str(msg))
    #for k in msg:
    #    print " ", k,":",msg[k]
    #print ""
    status = msg[u'status']
    res = msg[u'result']
    tid = msg[u'task_id']
    if status == "SUCCESS":
        print tid+" finished with result ", res
        return
    elif status == "MSG":
        msg = res["message"]
        if type(msg) is str or type(msg) is unicode:
            print tid, msg
        elif type(msg) is dict:
            print tid,
            # Check if dict has structure produced by tasks.parseOutput()
            if "vars" in msg:
                if "title" in msg:
                    print msg["title"]+":",
                for var in msg["vars"]:
                    print var+"="+msg["vars"][var],
                print ""
            else:
                for k in msg:
                    print k, ":", msg[k]

        return
    else:
        print tid
        if type(res) is dict:
            for k in res:
                print k,":",res[k]
        else:
            print res


# Load YAML into python object
def yamlLoad(filepath):
    with open(filepath,"r") as fd:
        data = yaml.load(fd)
    return data


# Create matrix of all parameter values.
# Each row represents one parameter.
# First element of each row - parameter name,
# 2nd and later elements - parameter values.
def yaml2Matrix(filepath):
    par_matrix = []
    data=yamlLoad(filepath)
    if type(data) is dict:
        for k in data:
            param = data[k]
            #print ">> "+k + " : " + str(data[k]) + " "+str(type(param))

            if type(param) is list:
                llength=len(param)
                #print "List length = " + str(llength)
                #for par in param:
                #    print k+"="+str(par)
                matrix_line = [k]
                matrix_line.extend(param)
                par_matrix.append(matrix_line)

            elif type(param) is tuple:
                llength=len(param)
                #print "Tuple length = " + str(llength)
                if llength < 2:
                    print "Need range stat and end values: [start, end]."
                    print "Only one value provided:" + str(param)
                    break

                matrix_line = [k]
                start=param[0]
                end  =param[1]
                if llength > 2:
                    step = param[2]
                else:
                    step = 1
                #print start, end, step
                for val in np.arange(start, end, step):
                    #print k+"="+str(val)
                    matrix_line.append(val)

                par_matrix.append(matrix_line)

            elif type(param) is bool:
                #print k + " is " + str(param)
                if param:
                    matrix_line=[k,""]
                    par_matrix.append(matrix_line)

            elif type(param) is dict:
                # Not used in parametrisation
                print "Dictionary type is not used in parameters definition."
                #for key1 in param:
                #    print key1 + "=" + str(param[key1])

    return par_matrix


# Join 2 lists or a list and a scalar value into a list
def concat(a,b):
    comb = []
    if type(a) is list:
        comb.extend(a)
    else:
        comb.append(a)
    if type(b) is list:
        comb.extend(b)
    else:
        comb.append(b)
    return comb

# Create a list of lists with all possible combinations of elements
# of the two input lists. Each list is a unique combination of elements
# from the two input lists.
def joinLists(a, b):
    if len(a)==0:
        return b
    elif len(b)==0:
        return a
    c = []
    for i in range (0, len(a)):
        for j in range (0, len(b)):
            combination=concat(a[i],b[j])
            c.append(combination)
    return c


# Print in color
def debug_print(s,color=237):
    print "\033[38;5;"+str(color)+"m"+str(s)+"\033[m"


if __name__ == '__main__':
    # Check current dir
    pwd = ""
    pipe = Popen(["pwd"], stdout=PIPE, stderr=PIPE, close_fds=True)
    for line in iter(pipe.stdout.readline, b''):
        pwd = line
        debug_print("Current dir: "+ pwd)
    for line in iter(pipe.stderr.readline, b''):
        if len(line)>0:
            debug_print("!"+line)

    paramatrix=yaml2Matrix("bowcnn/paramtest.yml")

    # Create combinations matrix
    combinations=[]
    for l in range(0, len(paramatrix)):
        line = paramatrix[l][1:]
        combinations = joinLists(combinations, line)

    debug_print("Have "+str(len(combinations))+" combinations.",243)
    # Wrap combinataions into dictionary
    base_pars = {
        'maxiter':3,
        'dataset':"TwentyNg",
        'minibatchsize':50,
        'nfolds':2,
        'jsonresult':1
    }
    results = []

    for c in range(0,len(combinations)):
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



