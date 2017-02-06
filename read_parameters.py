#!/usr/bin/env python
#
# Produce number of tasks with parameters from given ranges.
# 2017 (C) Bryzgalov Peter @ CHITEC, Stair Lab

import yaml
import pprint

def yaml_load(filepath):
    with open(filepath,"r") as fd:
        data = yaml.load(fd)
    return data

def yaml_dump(filepath, data):
    with open(filepath, "w") as fd:
        yaml.dump(data, fd)
        fd.close()


if __name__ == "__main__":
    pp = pprint.PrettyPrinter(indent=4)
    filepath = "./paramtest.yml"
    data=yaml_load(filepath)
    if type(data) is dict:
        for k in data:
            print k + " : " + str(data[k])
            paramrange = data[k]
            print type(paramrange)

            if type(paramrange) is dict:
                for key1 in paramrange:
                    print key1 + "=" + str(paramrange[key1])

            if type(paramrange) is list:
                llength = len(paramrange)
                print "List length = " + str(llength)
                start=paramrange[0]
                end  =paramrange[1]
                if llength > 2:
                    step = paramrange[2]
                else:
                    step = 1

                print range(start, end, step)



