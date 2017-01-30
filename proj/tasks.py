from __future__ import absolute_import, unicode_literals
from .celery import app

import time

from sklearn.preprocessing import normalize
import numpy as np
import chainer
from chainer import cuda, Function, FunctionSet, gradient_check, Variable, optimizers, serializers
from .preprocessing import convert_sparse_array_to_variable, convert_numpy_array_to_variable
import sys
import json, codecs

def jsonify(numpy_array):
    a = numpy_array.tolist()
    return a

def unjsonify(a):
    try:
        arr = json.loads(a)
        np_arr = np.array(arr)
        return np_arr
    except TypeError:
        #print  "unjsonify recieved object of type",type(a)
        return a

@app.task(bind=True)
def train(index_tr_s, index_te_s, n_epoches=5, n_emb = 50, dropout_rate = 0.3, minibatch_size = 50):
