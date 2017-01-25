from __future__ import absolute_import, unicode_literals
from .task_fasttext import power2, echo

import time

def report_state(msg):
    status = msg[u'status']
    res = msg[u'result']
    if status == "SUCCESS":
        print "Finished with result ", res
        return

    # Intermediate results
    if type(res) is dict:
        for k in res:
            print "2**",k,"=",res[k]
    else:
        print res

if __name__ == '__main__':
    s = "--"
    result = echo.apply_async((s,), countdown=1)
    r = result.get()
    print(r)
    tasks = 5
    arr= [1,2,3,4,5,6,7,8]
    results = []
    for i in range(0,tasks):
        result = power2.apply_async((arr,), link=echo.s() )
        results.append(result)
    print "Sent "+str(tasks) + " tasks."
    for r in results:
        print "on message"
        r.get(on_message=report_state, propagate=False)


print "main process finished"

