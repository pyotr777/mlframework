#!/usr/bin/env python
# Testing communicationg through Rabbit broker.


import pika, time, os

# Send message to broker RabbitMQ
RabbitIP = os.environ['RABBIT_PORT_4369_TCP_ADDR']
connection = pika.BlockingConnection(pika.ConnectionParameters(RabbitIP))
channel = connection.channel()

channel.queue_declare(queue='celery2')

channel.basic_publish(exchange='',
                      routing_key='celery2',
                      body='Hello World!')
print(" [>] Message sent")
connection.close()

time.sleep(1)

def echo(ch, method, properties, body):
    print(" [x] Received %r" % body)
    ch.stop_consuming()

# Receive message from broker
connection = pika.BlockingConnection(pika.ConnectionParameters(RabbitIP))
channel = connection.channel()
channel.basic_consume(echo, queue='celery2', no_ack=True)
print(' [*] Waiting for messages. To exit press CTRL+C')
channel.start_consuming()
