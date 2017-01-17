#! encoding=UTF-8
__author__ = 'Yuya Yoshikawa'

import numpy as np
import chainer
from chainer import cuda, Function, FunctionSet, gradient_check, Variable, optimizers, serializers
import chainer.functions as F
import chainer.links as L

class Model(chainer.Chain):
    def __init__(self, n_vocab, n_emb, n_classes=4):
        super(Model, self).__init__(
            emb=L.EmbedID(n_vocab, n_emb),
            l1=L.Linear(n_emb, n_classes)
        )
        self.n_vocab = n_vocab
        self.n_emb = n_emb
        self.n_classes = n_classes

    def __call__(self, x, c, t=None, mode="train"):
        xp = cuda.get_array_module(x)
        n_samples, n_features = x.data.shape
        gpu = -1 if self._cpu else 1

        W = self.emb(x)
        W = F.reshape(W, (-1, self.n_emb))
        y = self.l1(F.matmul(c, W))

        if mode == "train":
            self.loss = F.softmax_cross_entropy(y, t)
            return self.loss

        elif mode == "test":
            self.loss = F.softmax_cross_entropy(y, t)
            self.acc = F.accuracy(y, t)
            return self.loss

        elif mode == "predict":
            return y
