#!/usr/bin/env python
import pika

connection = pika.BlockingConnection(pika.ConnectionParameters('172.19.5.5'))
channel = connection.channel()
channel.basic_publish(exchange='',
                      routing_key='celery',
                      body='Hello World!')
connection.close()
