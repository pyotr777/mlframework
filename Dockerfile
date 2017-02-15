FROM ubuntu:14.04

# Celery master container. Should run on same host with RabbitMQ container.
# Use --link rabbit-broker:rabbit to connect RabbitMQ container.

MAINTAINER Bryzgalov Peter <peterbryz@yahoo.com>

RUN apt-get -y update && apt-get -y upgrade
RUN uname -a
#RUN apt-get install -y ccache curl g++ gfortran git libhdf5-dev linux-headers-$(uname -r)

ENV PATH /usr/lib/ccache:$PATH

RUN apt-get install -y python-pip python-dev
RUN /usr/bin/python --version

RUN pip install -U pip

# Chainer
RUN pip install -U "setuptools"
RUN pip install -U "cython"
RUN pip install -U "numpy<1.12"
RUN pip install -U "hacking"
RUN pip install -U "nose"
RUN pip install -U "mock"
RUN pip install -U "coverage"

RUN pip install filelock
RUN pip install chainer

# Celery
ENV CELERY_VERSION 4.0.2
RUN pip install celery=="$CELERY_VERSION"

RUN pip install -U sklearn
RUN pip install -U scipy

ENV CELERY_BROKER_URL amqp://guest@rabbit

WORKDIR /root

CMD ["/bin/bash"]

# docker build -f ML/mlframework/Dockerfile -t pyotr777/celery-chainer