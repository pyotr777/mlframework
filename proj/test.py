from __future__ import absolute_import, unicode_literals
from .tasks import add

if __name__ == '__main__':
    result = add.delay(4, 4)
    print ("Ready?", result.ready())
    print ("Result:",result.get(timeout=2))
    print ("Ready?",result.ready())
    print ("Result:")
    sum = result.get()
    print(sum)

