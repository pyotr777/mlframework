# Produce number of tasks with parameters from given ranges.
# 2017 (C) Bryzgalov Peter @ CHITEC, Stair Lab

import json


def unjsonify(a):
    if type(a) is dict:
        return a
    try:
        arr = json.loads(a)
        return arr
    except TypeError:
        print  "unjsonify recieved object of type",type(a)
        return a

def report(self, message):
    #print type(message)
    print message
    if type(message) is str or type(message) is unicode:
        try:
            #print "Parcing "+message
            dic = parseOutput(message)
            #print "dic="+str(dic)
            if dic is not None and type(dic) is dict:
                message = dic
                print "Parsed message (dict): ", message
        except Exception as exp:
            print exp
    self.update_state(state="MSG",meta={"message":message})


# Parse strings with format:
# Title: var=value, var=value,...
# into dictionary:
# {
#   title: "Title",
#   vars: {
#       var: value,
#       var: value
#   }
# }
def parseOutput(s):
    if s.find("=") > 0 :
        #print " Parsing "+s
        title_contents = s.split(":")
        dic = {}
        if len(title_contents) > 1:
            title = title_contents[0]
            #print " title="+title
            dic["title"] = title
            contents = title_contents[1]
        else:
            contents = s

        contents = contents.replace(" ","")
        contents = contents.replace("\n","")
        #print " conte="+contents

        dic["vars"] = {}
        #print "contents="+str(contents)
        tuples=contents.split(",")
        for pair in tuples:
            #print " pair="+str(pair)+" ("+str(len(pair))+")"
            if len(pair) < 2:
                continue
            var_value=pair.split("=")
            if len(var_value) == 2:
                dic["vars"][var_value[0]]=var_value[1]
        #print dic
        return dic
    else:
        return s



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