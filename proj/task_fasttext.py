from __future__ import absolute_import, unicode_literals
from .celery import app

from sklearn.cross_validation import train_test_split, KFold
from sklearn.preprocessing import normalize
import numpy as np
import chainer
from chainer import cuda, Function, FunctionSet, gradient_check, Variable, optimizers, serializers
from .preprocessing import convert_sparse_array_to_variable, convert_numpy_array_to_variable
import sys
import json

# Load data
import proj.datasets.twenty_ng as dataset
X_all, Y_all = dataset.load(subset="all", tfidf=True)
idx_word = dataset.load_vocaburary()

# default values
n_emb = 50
dropout_rate = 0.3
minibatch_size = 50
n_folds = 5
random_state = 0

""" global parameters """
n_all_samples, n_vocab = X_all.shape
n_classes = np.unique(Y_all).shape[0]
n_epoches = 10
print "N samples=",n_all_samples, "N vocab=", n_vocab, "N classes=", n_classes

from .baselines.fasttext import Model
model = Model(n_vocab, n_emb, n_classes)
optimizer = optimizers.SGD()

@app.task
def echo():
    print "Called echo"
    return "Hello world!"


@app.task
def train(X_all, Y_all, index_tr, index_te):
    X_tr, Y_tr = X_all[index_tr], Y_all[index_tr]
    X_te, Y_te = X_all[index_te], Y_all[index_te]
    n_train = X_tr.shape[0]
    n_test = X_te.shape[0]
    optimizer.setup(model)
    min_train_loss = 10*20
    max_train_acc = 0.0
    max_test_acc = 0.0
    argmax_epoch = 0
    for epoch in range(n_epoches):
        indices = np.random.permutation(n_train)
        model.zerograds()
        loss = 0.0
        for counter, i in enumerate(indices):
            x = convert_sparse_array_to_variable(X_tr[i:i+1], -1, dtype=np.int32, mode="index")
            c = convert_sparse_array_to_variable(X_tr[i:i+1], -1, dtype=np.float32, mode="value")
            t = convert_numpy_array_to_variable(Y_tr[i:i+1].reshape((-1,)), -1, dtype=np.int32)
            loss += model(x, c, t, mode="train")

            if (counter + 1) % minibatch_size == 0:
                loss.backward()
                optimizer.update()
                loss = 0.0
                model.zerograds()

        loss.backward()
        optimizer.update()

        """ compute train loss """
        avg_train_acc = 0
        avg_train_loss = 0
        for i in range(n_train):
            x = convert_sparse_array_to_variable(X_tr[i:i+1], -1, dtype=np.int32, mode="index")
            c = convert_sparse_array_to_variable(X_tr[i:i+1], -1, dtype=np.float32, mode="value")
            t = convert_numpy_array_to_variable(Y_tr[i:i+1].reshape((-1,)), -1, dtype=np.int32)
            model(x, c, t, mode="test")
            avg_train_acc += model.acc
            avg_train_loss += model.loss
        avg_train_acc /= n_train
        avg_train_loss /= n_train

        """ test """
        avg_test_acc = 0
        avg_test_loss = 0
        for i in range(n_test):
            x = convert_sparse_array_to_variable(X_te[i:i+1], -1, dtype=np.int32, mode="index")
            c = convert_sparse_array_to_variable(X_te[i:i+1], -1, dtype=np.float32, mode="value")
            t = convert_numpy_array_to_variable(Y_te[i:i+1].reshape((-1,)), -1, dtype=np.int32)

            model(x, c, t, mode="test")
            avg_test_acc += model.acc
            avg_test_loss += model.loss
        avg_test_acc /= n_test
        avg_test_loss /= n_test

        print "epoch %3d: train loss = %e, train acc = %e, test acc = %e"\
              % (epoch + 1, avg_train_loss.data, avg_train_acc.data, avg_test_acc.data)

        if max_test_acc < avg_test_acc.data:
            min_train_loss = avg_train_loss.data
            max_train_acc = avg_train_acc.data
            max_test_acc = avg_test_acc.data
            argmax_epoch = epoch + 1

    return(min_train_loss, max_train_acc, max_test_acc)

