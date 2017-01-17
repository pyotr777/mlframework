#! encoding=UTF-8

import numpy as np
from scipy.sparse import lil_matrix
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.preprocessing import LabelEncoder
from sklearn.feature_extraction.text import TfidfTransformer

train_fn = "proj/datasets/20Ng/20ng-train-stemmed.txt"
test_fn = "proj/datasets/20Ng/20ng-test-stemmed.txt"

doc_list = []
label_list = []
with open(train_fn) as f:
    for line in f:
        label, doc = line.strip().split("\t")
        label_list.append(label)
        doc_list.append(doc)
cv_base = CountVectorizer(max_features=20000)
cv_base.fit(doc_list)
le_base = LabelEncoder().fit(label_list)

def load(subset="train", tfidf=False):
    le = LabelEncoder()
    label_list = []
    doc_list = []
    if subset == "train":
        with open(train_fn) as f:
            for line in f:
                label, doc = line.strip().split("\t")
                label_list.append(label)
                doc_list.append(doc)

    elif subset == "test":
        with open(test_fn) as f:
            for line in f:
                try:
                    label, doc = line.strip().split("\t")
                except ValueError:
                    continue
                label_list.append(label)
                doc_list.append(doc)

    elif subset == "all":
        with open(train_fn) as f:
            for line in f:
                label, doc = line.strip().split("\t")
                label_list.append(label)
                doc_list.append(doc)
        with open(test_fn) as f:
            for line in f:
                try:
                    label, doc = line.strip().split("\t")
                except ValueError:
                    continue
                label_list.append(label)
                doc_list.append(doc)

    if tfidf:
        tt = TfidfTransformer()
        X = tt.fit_transform(cv_base.transform(doc_list))
    else:
        X = cv_base.transform(doc_list)
    y = le_base.transform(label_list)

    return X, y


def load_vocaburary():
    idx_word = dict([(idx, word) for word, idx in cv_base.vocabulary_.items()])
    return idx_word