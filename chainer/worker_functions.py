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


# Print in color
def debug_print(s,color=237):
    print "\033[38;5;"+str(color)+"m"+str(s)+"\033[m"