from __future__ import absolute_import, unicode_literals
from .task_fasttext import power2, echo

import time

if __name__ == '__main__':
    result = echo.delay()
    #print ("Ready?", result.ready())
    #print ("Result:",result.get(timeout=2))
    #print ("Ready?",result.ready())
    #print ("Result:")
    s = result.get()
    print(s)
    print "2 ** 10 = ?"
    arr= [1,2,3,4,5,6,7,8,9,10]
    result = power2.delay(arr)
    while result.ready() is False:
        print "Not ready...", result.result
        time.sleep(2)
        print result.get()
        #print result.ready()

    print "Result:", result.get()

