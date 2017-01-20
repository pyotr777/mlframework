from __future__ import absolute_import, unicode_literals
from .task_fasttext import train, echo

import time

from sklearn.cross_validation import train_test_split, KFold
from sklearn.preprocessing import normalize
import numpy as np
import chainer
from chainer import cuda, Function, FunctionSet, gradient_check, Variable, optimizers, serializers
from .preprocessing import convert_sparse_array_to_variable, convert_numpy_array_to_variable
import codecs, json


def jsonify(numpy_array):
    a = numpy_array.tolist()
    return a

def unjsonify(a):
    try:
        arr = json.loads(a)
        np_arr = np.array(arr)
        return np_arr
    except TypeError:
        print  "unjsonify recieved object of type",type(a)
        return a


if __name__ == '__main__':

    n_folds = 2
    random_state = 0
    n_epoches = 5

    # Load data
    import proj.datasets.twenty_ng as dataset
    X_all, Y_all = dataset.load(subset="all", tfidf=True)
    idx_word = dataset.load_vocaburary()

    """ global parameters """
    n_all_samples, n_vocab = X_all.shape
    print "N samples=",n_all_samples, "N vocab=", n_vocab

    kf = KFold(n_all_samples, n_folds, shuffle=True, random_state=0)
    cv_train_loss_list = []
    cv_train_acc_list = []
    cv_test_acc_list = []
    results = []

    for index_tr, index_te in kf:
        result = train.delay(jsonify(index_tr), jsonify(index_te), n_epoches)
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
                cv_train_loss_list.append(unjsonify(min_train_loss))
                cv_train_acc_list.append(unjsonify(max_train_acc))
                cv_test_acc_list.append(float(unjsonify(max_test_acc)))

    print "--------------------------------- Summary: average test accuracy, std. ---------------------------------"
    print np.mean(cv_test_acc_list), np.std(cv_test_acc_list)


