from __future__ import absolute_import, unicode_literals
from .task_fasttext import power2, echo

import time

def report_state(msg):
    #print type(msg)
    status = msg[u'status']
    res = msg[u'result']
    if status == "SUCCESS":
        print "Finished with result ", res
        return

    #print type(res)
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
    workers = 5
    arr= [1,2,3,4,5,6,7,8]
    results = []
    for i in range(0,workers):
        result = power2.apply_async((arr,), link=echo.s() )
        results.append(result)
    print "Sent "+str(workers) + " of " +str(len(results))+ " tasks."
    all_ready = False
    ready_tasks = 0
    while all_ready is False:
        all_ready = True
        for r in results:
            print "Checking..."
            r.get(on_message=report_state, propagate=False)
            if r.ready():
                ready_tasks += 1
                #print "Get:",r.get()
                print "Res:",r.result
            else:
                all_ready = False
        print "Ready: ", ready_tasks
        time.sleep(2)

print "[o] All tasks finished."

