from __future__ import absolute_import, unicode_literals
from celery import Celery

app = Celery('bowcnn',
             broker='amqp://',
             backend='rpc://',
             include=['bowcnn.tasks'])

# Optional configuration, see the application user guide.
#app.conf.update(
#    result_expires=3600,
#)

if __name__ == '__main__':
    app.start()