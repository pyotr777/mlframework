#! encoding=UTF-8
__author__ = 'Yuya Yoshikawa'

import numpy as np
import chainer
from chainer import cuda, Function, FunctionSet, gradient_check, Variable, optimizers
import chainer.functions as F
import chainer.links as L


def convert_sparse_array_to_variable(S, gpu=0, eos=-1, dtype=np.int32, mode="index"):
    xp = cuda.cupy if gpu >= 0 else np
    maxlen = max([S[i].getnnz() for i in range(S.shape[0])])
    V = eos * np.ones((S.shape[0], maxlen), dtype=dtype)
    for i in range(S.shape[0]):
        if mode == "index":
            V[i, :S[i].getnnz()] = S[i].nonzero()[1]
        elif mode == "value":
            V[i, :S[i].getnnz()] = S[i].data

    V = xp.asarray(V)
    if gpu >= 0:
        return Variable(cuda.to_gpu(V))
    else:
        return Variable(V)


def convert_numpy_array_to_variable(A, gpu=0, dtype=np.int32):
    xp = cuda.cupy if gpu >= 0 else np
    A = xp.asarray(A, dtype=dtype)
    if gpu >= 0:
        return Variable(cuda.to_gpu(A))
    else:
        return Variable(A)



