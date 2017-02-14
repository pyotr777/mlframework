# Produce number of tasks with parameters from given ranges.
# 2017 (C) Bryzgalov Peter @ CHITEC, Stair Lab

import json

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

def parse_message(message):
    #debug_print("master received message "+ str(message))
    #for k in message:
    #    print " ", k,":",message[k]
    #print ""

    status = message[u'status']
    res = message[u'result']
    tid = message[u'task_id']
    if status == "SUCCESS":
        print tid+" finished with result ", res
        return
    elif status == "MSG":
        f= open("output.csv","a+")
        msg = res["message"]
        if type(msg) is str or type(msg) is unicode:
            contol_keys = dict.fromkeys(range(32))
            msg = msg.translate(contol_keys)
            print tid, msg
            f.write(str(tid)+"," + str(msg)+"\n")
        elif type(msg) is dict:
            print tid,
            s = str(tid)+","
            # Check if dict has structure produced by tasks.parseOutput()
            if "vars" in msg:
                if "title" in msg:
                    print msg["title"]+":",
                    s += msg["title"]+","
                for var in msg["vars"]:
                    print var+"="+msg["vars"][var],
                    s += str(var)+"="+str(msg["vars"][var])+","
                print ""
                f.write(s+"\n")
            else:
                s = ""
                for k in msg:
                    print k, ":", msg[k]
                    s += str(k)+"="+str(msg[k])+","
                f.write(s+"\n")
        return
    else:
        print tid
        if type(res) is dict:
            for k in res:
                print k,":",res[k]
        else:
            print res

# Print in color
def debug_print(s,color=237):
    print "\033[38;5;"+str(color)+"m"+str(s)+"\033[m"

