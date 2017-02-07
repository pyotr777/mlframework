#! encoding=UTF-8
__author__ = 'Yuya Yoshikawa'

import numpy as np
import chainer
from chainer import cuda, Function, FunctionSet, gradient_check, Variable, optimizers, serializers
import chainer.functions as F
import chainer.links as L



class Model(chainer.Chain):
    def __init__(self, n_vocab, hidden_dim, n_classes, loss_func="softmax", dropout_rate=0.5):
        super(Model, self).__init__(
            l1=L.Linear(n_vocab, hidden_dim),
            l2=L.Linear(hidden_dim, hidden_dim),
            l3=L.Linear(hidden_dim, hidden_dim),
            l4=L.Linear(hidden_dim, hidden_dim),
            l5=L.Linear(hidden_dim, n_classes),
        )
        self.n_vocab = n_vocab
        self.hidden_dim = hidden_dim
        self.n_classes = n_classes
        self.loss_func = loss_func
        self.dropout_rate = dropout_rate

    def __call__(self, x, c, t=None, mode="train"):
        xp = cuda.get_array_module(x)
        x_dense = xp.zeros((1, self.n_vocab), dtype=xp.float32)
        x_dense[0, x.data[0, :]] = c.data[0, :]

        if mode == "train":
            h = F.relu(self.l1(x_dense))
            h = F.dropout(F.relu(self.l2(h)), ratio=self.dropout_rate, train=True)
            h = F.dropout(F.relu(self.l3(h)), ratio=self.dropout_rate, train=True)
            h = F.dropout(F.relu(self.l4(h)), ratio=self.dropout_rate, train=True)
            y = self.l5(h)

            if self.loss_func == "hinge":
                self.loss = F.hinge(y, t)
            elif self.loss_func == "softmax":
                self.loss = F.softmax_cross_entropy(y, t)
            else:
                NotImplementedError("Invalid loss function.")

            self.acc = F.accuracy(y, t)
            return self.loss

        elif mode == "test":
            h = F.relu(self.l1(x_dense))
            h = F.dropout(F.relu(self.l2(h)), ratio=self.dropout_rate, train=False)
            h = F.dropout(F.relu(self.l3(h)), ratio=self.dropout_rate, train=False)
            h = F.dropout(F.relu(self.l4(h)), ratio=self.dropout_rate, train=False)
            y = self.l5(h)

            if self.loss_func == "hinge":
                self.loss = F.hinge(y, t)
            elif self.loss_func == "softmax":
                self.loss = F.softmax_cross_entropy(y, t)
            else:
                NotImplementedError("Invalid loss function.")

            self.acc = F.accuracy(y, t)
            return self.loss
