from __future__ import absolute_import, unicode_literals
from .task_fasttext import echo

if __name__ == '__main__':
    result = echo.delay()
    #print ("Ready?", result.ready())
    #print ("Result:",result.get(timeout=2))
    #print ("Ready?",result.ready())
    #print ("Result:")
    s = result.get()
    print(s)

