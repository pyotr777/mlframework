# Produce number of tasks with parameters from given ranges.
# 2017 (C) Bryzgalov Peter @ CHITEC, Stair Lab

import yaml, json
import numpy as np

def jsonify(pars):
    if type(pars) is list:
        a = pars.tolist()
    else:
        a = json.dumps(pars)
    return a


def unjsonify(a):
    if type(a) is dict:
        return a
    try:
        arr = json.loads(a)
        return arr
    except TypeError:
        print  "unjsonify recieved object of type",type(a)
        return a


# Recieve messages from workers.
# If status is "MSG" received output.
# Format: dictionary {"out":stdout, "err":stderr}.
# Save TID and stdout to output.csv,
# print TID, stdout and stderr.
# If status is "SUCCESS" received result.
# Print result
def parse_message(message):
    status = message[u'status']
    res = message[u'result']
    tid = message[u'task_id']

    if status == "MSG":
        f= open("output.csv","a+")
        f.write(str(tid)+",")
        msg = res["message"]
        if type(msg) is dict:
            print tid,
            s = str(tid)+","
            out = msg["out"]
            err = msg["err"]
            f.write(str(msg)+"\n")
            print out
            if len(err) > 0:
                debug_print err
        elif type(msg) is str or type(msg) is unicode:
            print tid, msg
            f.write(str(msg)+"\n")
        f.close()
    elif status == "SUCCESS":
        print tid+" finished with result ", res
        f= open("output.csv","a+")
        f.write(str(tid)+","+ res)
        f.close()
    else:
        print tid
        if type(res) is dict:
            for k in res:
                print k,":",res[k]
        else:
            print res
    return

# Print in color
def debug_print(s,color=237):
    print "\033[38;5;"+str(color)+"m"+str(s)+"\033[m"

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
            elif type(param) is str:
                par_matrix.append([k,param])
            elif type(param) is int:
                par_matrix.append([k,param])
            else:
                print "Unhandled parameter "+str(param)+" of type "+str(type(param))

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
    c = []
    if len(a)==0:
        for j in range (0, len(b)):
            c.append([b[j]])
    elif len(b)==0:
        for i in range (0, len(a)):
            c.append([a[i]])
    for i in range (0, len(a)):
        for j in range (0, len(b)):
            combination=concat(a[i],b[j])
            c.append(combination)
    return c