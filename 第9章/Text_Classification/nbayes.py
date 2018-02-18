#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import pickle
from sklearn.naive_bayes import MultinomialNB
import warnings
from sklearn import metrics
warnings.filterwarnings("ignore")

# 读取bunch对象
def read_bunch(path):
    with open(path, "rb") as fp:
        bunch = pickle.load(fp)           # joblib 同样可用于存储模型文件
    return bunch

# 分类结果保存至文件
def save_file(save_path, content):
    with open(save_path, "a",encoding= 'utf-8',errors='ignore') as fp:
        fp.write(content)


# 朴素贝叶斯分类
def nbayes_classify(train_set, test_set):
    '''
    train_set: 训练集样本数据
    test_set: 测试集样本数据
    :return: 测试集样本分类
    '''
    clf = MultinomialNB(alpha=0.5)
    clf.fit(train_set.tdm, train_set.label)  #  训练模型
    predict = clf.predict(test_set.tdm)
    return predict

def classification_result(actual, predict):
    print('精度:{0:.3f}'.format(metrics.precision_score(actual, predict,average='weighted')))
    print('召回:{0:0.3f}'.format(metrics.recall_score(actual, predict,average='weighted')))
    print('f1-score:{0:.3f}'.format(metrics.f1_score(actual, predict,average='weighted')))


if __name__ == '__main__':
    # 导入训练集
    train_path = './train_tfdifspace.dat'
    train_set = read_bunch(train_path)

    # 导入测试集
    test_path = "./test_tfidfspace.dat"
    test_set = read_bunch(test_path)

    predict = nbayes_classify(train_set, test_set)  #
    classification_result(test_set.label, predict)
    print('-' * 100)

    # 保存结果路径
    save_path = './classify_file.txt'
    for label, filename, predict in zip(test_set.label, test_set.filepath , predict):       #test_set
        print(filename, "\t实际类别:",label,"\t-->预测类别:", predict)
        save_content = filename + "\t实际类别:" + label + "\t-->预测类别:" + predict + '\n'
        save_file(save_path, save_content)  # 将分类结果写入txt

