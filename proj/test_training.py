from __future__ import absolute_import, unicode_literals
from .task_fasttext import train, echo

import time

from sklearn.cross_validation import train_test_split, KFold
from sklearn.preprocessing import normalize
import numpy as np
import chainer
from chainer import cuda, Function, FunctionSet, gradient_check, Variable, optimizers, serializers
from .preprocessing import convert_sparse_array_to_variable, convert_numpy_array_to_variable

if __name__ == '__main__':
    result = echo.delay()
    s = result.get()
    print(s)

    # Load data
    import proj.datasets.twenty_ng as dataset
    X_all, Y_all = dataset.load(subset="all", tfidf=True)
    idx_word = dataset.load_vocaburary()

    # default values
    n_emb = 50
    dropout_rate = 0.3
    minibatch_size = 50
    n_folds = 2
    random_state = 0

    """ global parameters """
    n_all_samples, n_vocab = X_all.shape
    n_classes = np.unique(Y_all).shape[0]
    n_epoches = 10
    print "N samples=",n_all_samples, "N vocab=", n_vocab, "N classes=", n_classes

    from .baselines.fasttext import Model
    model = Model(n_vocab, n_emb, n_classes)
    optimizer = optimizers.SGD()

    kf = KFold(n_all_samples, n_folds, shuffle=True, random_state=0)
    cv_train_loss_list = []
    cv_train_acc_list = []
    cv_test_acc_list = []
    results = []

    for index_tr, index_te in kf:
        result = train.delay(X_all, Y_all, index_tr, index_te, n_epoches, model, optimizer)
        results.append(result)

    print "All tasks sent"

    allready = False
    ready = 0
    while allready is False:
        print "Not ready..."
        time.sleep(2)
        allready = True
        for r in results:
            print r.get()
            if r.ready() is False:
                allready = False
            else:
                ready += 1
                print ready, " result(s) ready"
                min_train_loss, max_train_acc, max_test_acc = r.get()
                cv_train_loss_list.append(min_train_loss)
                cv_train_acc_list.append(max_train_acc)
                cv_test_acc_list.append(float(max_test_acc))

    print "--------------------------------- Summary: average test accuracy, std. ---------------------------------"
    print np.mean(cv_test_acc_list), np.std(cv_test_acc_list)

