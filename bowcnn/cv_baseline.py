#! encoding=UTF-8
from __future__ import absolute_import, unicode_literals
__author__ = 'Yuya Yoshikawa'

from sklearn.cross_validation import train_test_split, KFold
from sklearn.preprocessing import normalize
import numpy as np
import chainer
from chainer import cuda, Function, FunctionSet, gradient_check, Variable, optimizers, serializers
from .preprocessing import convert_sparse_array_to_variable, convert_numpy_array_to_variable
import sys
import json

import argparse
parser = argparse.ArgumentParser()
# parser.add_argument('--initmodel', '-m', default='',
#                     help='Initialize the model from given file')
# parser.add_argument('--resume', '-r', default='',
#                     help='Resume the optimization from snapshot')
parser.add_argument('--gpu', '-g', default=-1, type=int,
                    help='GPU ID (negative value indicates CPU)')
parser.add_argument('--maxiter', '-i', default=2, type=int,
                    help='number of iterations')
parser.add_argument('--model', '-m', default="fasttext", type=str,
                    help='model name {fasttext,}')
parser.add_argument('--dataset', '-d', default="20Ng", type=str,
                    help='dataset name')
parser.add_argument('--nemb', '-w', default=50, type=int,
                    help='size of word embedding')
parser.add_argument('--tfidf', '-t', action="store_true",
                    help='apply tfidf transformation')
parser.add_argument('--normalizecount', '-n', action="store_true",
                    help='normalize word counts')
parser.add_argument('--minibatchsize', '-b', default=50, type=int,
                    help='number of samples per a minibatch')
parser.add_argument('--dropoutrate', '-r', default=0.3, type=float,
                    help='dropout rate (0 <= r <= 1)')
parser.add_argument('--optimizer', '-u', default="adam", type=str,
                    help='optimizer name (adam, sgd, or adagrad')
parser.add_argument('--decay', default=0, type=float,
                    help='weight decay rate (default 0)')
parser.add_argument('--output', '-o', default=None, type=str,
                    help='output result filename (a file is generated instead of stdout)')
parser.add_argument('--jsonresult', '-j', default=None, type=str,
                    help='save results as json file')
parser.add_argument('--nfolds', default=1, type=int,
                    help='number of folds in cross validation')
parser.add_argument('--randomstate', default=0, type=int,
                    help='random state used in cross validation')
args = parser.parse_args()
xp = cuda.cupy if args.gpu >= 0 else np

""" dataset load """
if args.dataset == "TwentyNg":
    from .datasets import twenty_ng as dataset
#elif args.dataset == "R8":
#    from .datasets import r8 as dataset
#elif args.dataset == "R52":
#    import datasets.r52 as dataset
#elif args.dataset == "WebKb":
#    import datasets.webkb as dataset
#elif args.dataset == "Cade12":
#    import datasets.cade as dataset
else:
    raise NotImplementedError("Invalid dataset name.")

""" load data """
X_all, Y_all = dataset.load(subset="all", tfidf=args.tfidf)
if args.normalizecount:
    X_all = normalize(X_all, norm="l1", axis=1)
idx_word = dataset.load_vocaburary()

""" global parameters """
n_all_samples, n_vocab = X_all.shape
n_emb = args.nemb
n_classes = np.unique(Y_all).shape[0]
dropout_rate = args.dropoutrate
n_epoches = args.maxiter
minibatch_size = args.minibatchsize
kf = KFold(n_all_samples, n_folds=args.nfolds, shuffle=True, random_state=args.randomstate)

if args.output:
    sys.stdout = open(args.output, "w")

print vars(args)

""" cross validation start """
fold = 1
cv_train_loss_list = []
cv_train_acc_list = []
cv_test_acc_list = []
for index_tr, index_te in kf:
    X_tr, Y_tr = X_all[index_tr], Y_all[index_tr]
    X_te, Y_te = X_all[index_te], Y_all[index_te]
    n_train = X_tr.shape[0]
    n_test = X_te.shape[0]

    """ set up model """
    if args.model == "fasttext":
        from .baselines.fasttext import Model
        model = Model(n_vocab, n_emb, n_classes)
    if args.model == "mlp3l":
        from .baselines.mlp3l import Model
        model = Model(n_vocab, n_emb, n_classes, dropout_rate=args.dropoutrate)
    if args.model == "mlp4l":
        from .baselines.mlp4l import Model
        model = Model(n_vocab, n_emb, n_classes, dropout_rate=args.dropoutrate)
    if args.model == "mlp5l":
        from .baselines.mlp5l import Model
        model = Model(n_vocab, n_emb, n_classes, dropout_rate=args.dropoutrate)

    # elif args.model == 3:
    #     from nets.model3 import Network
    #     model = Network(n_vocab, word_size, n_classes)
    #     model.load("nets/models/VGG.model")
    #     learning_param_names = ["/l1/W", "/emb_r/W", "/emb_g/W", "/emb_b/W"]
    #

    if args.gpu >= 0:
        cuda.get_device(args.gpu).use()
        model.to_gpu()

    if args.optimizer == "adam":
        optimizer = optimizers.Adam()
    elif args.optimizer == "sgd":
        optimizer = optimizers.SGD()
    elif args.optimizer == "adagrad":
        optimizer = optimizers.AdaGrad()

    optimizer.setup(model)

    if args.decay:
        optimizer.add_hook(chainer.optimizer.WeightDecay(args.decayrate))

    print "---------------------------------------- fold %d ----------------------------------------" % fold

    """ training """
    min_train_loss = 10*20
    max_train_acc = 0.0
    max_test_acc = 0.0
    argmax_epoch = 0
    for epoch in range(n_epoches):
        indices = np.random.permutation(n_train)
        model.zerograds()
        loss = 0.0

        for counter, i in enumerate(indices):
            x = convert_sparse_array_to_variable(X_tr[i:i+1], args.gpu, dtype=xp.int32, mode="index")
            c = convert_sparse_array_to_variable(X_tr[i:i+1], args.gpu, dtype=xp.float32, mode="value")
            t = convert_numpy_array_to_variable(Y_tr[i:i+1].reshape((-1,)), args.gpu, dtype=xp.int32)
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
            x = convert_sparse_array_to_variable(X_tr[i:i+1], args.gpu, dtype=xp.int32, mode="index")
            c = convert_sparse_array_to_variable(X_tr[i:i+1], args.gpu, dtype=xp.float32, mode="value")
            t = convert_numpy_array_to_variable(Y_tr[i:i+1].reshape((-1,)), args.gpu, dtype=xp.int32)
            model(x, c, t, mode="test")
            avg_train_acc += model.acc
            avg_train_loss += model.loss
        avg_train_acc /= n_train
        avg_train_loss /= n_train

        """ test """
        avg_test_acc = 0
        avg_test_loss = 0
        for i in range(n_test):
            x = convert_sparse_array_to_variable(X_te[i:i+1], args.gpu, dtype=xp.int32, mode="index")
            c = convert_sparse_array_to_variable(X_te[i:i+1], args.gpu, dtype=xp.float32, mode="value")
            t = convert_numpy_array_to_variable(Y_te[i:i+1].reshape((-1,)), args.gpu, dtype=xp.int32)

            model(x, c, t, mode="test")
            avg_test_acc += model.acc
            avg_test_loss += model.loss
        avg_test_acc /= n_test
        avg_test_loss /= n_test

        print "epoch %3d: train loss = %.4f, train acc = %.4f, test acc = %.4f"\
              % (epoch + 1, avg_train_loss.data, avg_train_acc.data, avg_test_acc.data)

        if max_test_acc < avg_test_acc.data:
            min_train_loss = avg_train_loss.data
            max_train_acc = avg_train_acc.data
            max_test_acc = avg_test_acc.data
            argmax_epoch = epoch + 1

    cv_train_loss_list.append(min_train_loss)
    cv_train_acc_list.append(max_train_acc)
    cv_test_acc_list.append(float(max_test_acc))
    fold += 1

""" result summary """
print "--------------------------------- Summary: average test accuracy, std. ---------------------------------"
print np.mean(cv_test_acc_list), np.std(cv_test_acc_list)


""" close """
sys.stdout.close()

""" save result as json """
if args.jsonresult:
    info = dict()
    info["params"] = vars(args)
    info["results"] = {"cv_test_accuracy": cv_test_acc_list,
                       "cv_mean": float(np.mean(cv_test_acc_list)),
                       "cv_std": float(np.std(cv_test_acc_list))}

    with open(args.json_result, "w") as f:
        json.dump(info, f)


# """ save model """
# if args.output:
#     # import pickle
#     # model.to_cpu()
#     # with open(args.output, "w") as f:
#     #     pickle.dump(model, f)
#     serializers.save_npz(args.output, model)


# """ save result in sqlite """
# setting_dict= args.__dict__
# setting_dict["n_vocab"] = n_vocab
# setting_dict["optimizer"] = optimizer.__module__
#
# import sqlite3
# import json
# import datetime
# connect = sqlite3.connect("results/model5_results.sqlite")
# c = connect.cursor()
# c.execute("""select name from sqlite_master where type='table' and name='%s'""" % args.dataset)
# # print c.fetchall()
# if len(c.fetchall()) == 0:
#     c.execute("""create table %s (date text, argmax_epoch int, max_accuracy real, setting text)""" % args.dataset)
#
# c.execute("""insert into %s values (?,?,?,?)""" % args.dataset,
#           (datetime.datetime.now().__str__(), argmax_epoch, float(max_test_acc), json.dumps(setting_dict)))
# connect.commit()
# connect.close()

