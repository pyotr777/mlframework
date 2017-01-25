import os
broker_url = os.environ.get('CELERY_BROKER_URL', 'amqp://')
