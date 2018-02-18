# -*- coding: utf-8 -*-

import pymysql.cursors
from sklearn.externals import joblib
import warnings
import pandas as pd
from matplotlib import pylab
from sklearn import tree
from sklearn.cross_validation import train_test_split
from sklearn.metrics import precision_recall_curve,accuracy_score,classification_report
warnings.filterwarnings("ignore")

conn = pymysql.connect(host='localhost', port=3306, user='root', password='', db='gdw', charset='utf8')
cursor = conn.cursor()

sql_info = ''' select *  from  gdw.user_churn_warning'''
df = pd.read_sql(sql_info,conn)     # 将SQL语句放入链接,执行程序
data = pd.DataFrame(df)         # data存储待建模数据

Feature = data.ix[0:8000,1:10].as_matrix()      # 第0列是用户id, 1-10列是用户特征数据
Label = data.ix[0:8000, 11].as_matrix()     # 第11列判断用户是否流失

X_train, X_test, y_train, y_test = train_test_split(Feature, Label, random_state=1)  # 将数据随机分成训练集和测试集

clf = tree.DecisionTreeClassifier(max_depth=3)
clf = clf.fit(X_train, y_train)
pre_labels = clf.predict(X_test)

print(len(X_train))
print(len(X_test))


# 模型评估: 据预测值和真实值来计算一条precision-recall典线
precision, recall, thresholds = precision_recall_curve(y_test,pre_labels)

accuracy_s = accuracy_score(y_test,pre_labels)
print("accuracy_s:{}".format(accuracy_s))  #准确率

print(classification_report(y_test,pre_labels))  # 分类效果
joblib.dump(clf, 'filename.pkl')    # 将模型数据写入pkl文件中


def plot_precision_recall_curve(auc_score, precision, recall, label=None):
    '''
    :param auc_score:准确率
    :param precision:精确率
    :param recall:召回率
    :param label:
    '''
    pylab.figure(num=None, figsize=(6, 5))
    pylab.xlim([0.0, 1.0])
    pylab.ylim([0.0, 1.0])
    pylab.xlabel('Recall')
    pylab.ylabel('Precision')
    pylab.title('P/R (AUC=%0.3f) / %s' % (auc_score, label))
    pylab.fill_between(recall, precision, alpha=0.5)
    pylab.grid(True, linestyle='-', color='0.75')
    pylab.plot(recall, precision, lw=1)
    pylab.show()

from sklearn.externals.six import StringIO
from sklearn.feature_extraction import DictVectorizer
import pydot
dot_data = StringIO()

feature_importance = clf.feature_importances_
print(feature_importance)

with open("user_churn.dot", 'w') as f:
    f=tree.export_graphviz(clf, out_file=f)
    tree.export_graphviz(clf, out_file=dot_data)
    graph = pydot.graph_from_dot_data(dot_data.getvalue())
    graph[0].write_pdf("user_churn.pdf")    # 将分类依据写入pdf文件中

plot_precision_recall_curve(accuracy_s, precision, recall, "pos") # 绘制PR曲线


