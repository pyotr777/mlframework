# Produce number of tasks with parameters from given ranges.
# 2017 (C) Bryzgalov Peter @ CHITEC, Stair Lab

from __future__ import absolute_import, unicode_literals
from .celery import app

import time
import json
from subprocess import Popen, PIPE, STDOUT

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
    tid = self.request.id
    print type(message)
    print message
    if type(message) is str or type(message) is unicode:
        try:
            #print "Parcing "+message
            dic = parseOutput(message)
            #print "dic="+str(dic)
        except Exception as exp:
            print exp
        if dic is not None:
            message = dic
            print "Parsed dic=", message

    self.update_state(state="MSG",meta={"message":message,"TID":tid})

@app.task(bind=True,acks_late=True)
def echo(self, dic={"n":2}):
    tid = self.request.id
    dic = unjsonify(dic)
    n = int(dic["n"])
    for i in range(0,n):
        time.sleep(1)
        s = "Title: i="+str(i)
        print str(tid)+" "+s
        report(self, s)
    dic["tid"]=tid
    return dic

@app.task(bind=True,acks_late=True)
def train(self, pars):
    report(self, { "name": __name__, "pars": pars })
    par = unjsonify(pars)

    # Check current dir
    pipe = Popen(["pwd"], stdout=PIPE, stderr=PIPE, close_fds=True)
    for line in iter(pipe.stdout.readline, b''):
        report(self,line)
    for line in iter(pipe.stderr.readline, b''):
        if len(line)>0:
            report(self,"err:"+line)

    cmd = ["python","-m","bowcnn.cv_baseline"]
    for key in par:
        cmd.append(str("--"+key))
        cmd.append(str(par[key]))
    report(self, {"Command": cmd})
    print cmd
    pipe = Popen(cmd, stdout=PIPE, stderr=PIPE, close_fds=True)

    for line in iter(pipe.stdout.readline, b''):
        report(self,line)
    for line in iter(pipe.stderr.readline, b''):
        if len(line)>0:
            report(self,"err:"+line)


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
    # print s
    if s.find("=") > 0 :
        title_contents=s.split(":")
        #print "title_contents="+str(title_contents)
        dic = {}
        if len(title_contents) > 1:
            title=title_contents[0]
            dic["title"]=title
            #print "dic[title]="+title
            contents=title_contents[1].replace(" ","")
        else:
            contents=s.replace(" ","")

        dic["vars"] = {}
        #print "contents="+str(contents)
        tuples=contents.split(",")
        for pair in tuples:
            #print "pair="+str(pair)+" "+str(len(pair))
            if len(pair) < 2:
                continue
            var_value=pair.split("=")
            if len(var_value) == 2:
                dic["vars"][var_value[0]]=var_value[1]
        #print dic
        return dic
    else:
        return s

