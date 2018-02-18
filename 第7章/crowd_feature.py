#-*- coding: utf-8 -*-

import pandas as pd
from sklearn.cluster import KMeans #导入K均值聚类算法
import numpy as np
import matplotlib.pyplot as plt


if __name__ == '__main__':
    inputfile = 'RFM_model.xlsx'          # 待聚类的数据文件
    data = pd.read_excel(inputfile)         # 读取数据
    data = data.ix[:,[1,2,3,4]]          # 对应是R F M Label相对应的数据
    crowd_one = data.loc[data['LABEL']==0]
    crowd_one_num = len(crowd_one.index)        # 第一类用户的人数
    crowd_two = data.loc[data['LABEL']==1]
    crowd_two_num = len(crowd_two.index)
    crowd_three = data.loc[data['LABEL']==2]
    crowd_three_num = len(crowd_three.index)
    # crowd_one.mean() 第一类用户的各维度数据均值
    print('第一类人群特征({}人):\n{}\n第二类人群特征({}人):\n{}\n第三类人群特征({}人):\n{}'.
          format(crowd_one_num,crowd_one.mean(),crowd_two_num,crowd_two.mean(),crowd_three_num,crowd_three.mean()))

    ax = plt.subplot(321)
    plt.axis([0,30,0,25000])
    plt.xlabel(u'crowd_one_R')
    plt.ylabel(u'crowd_one_M')
    plt.scatter(crowd_one.ix[:, 0], crowd_one.ix[:, 2],s=5)     # 绘制数据点

    ax = plt.subplot(322)
    plt.axis([0, 30, 0, 25000])
    plt.xlabel(u'crowd_one_F')
    plt.ylabel(u'crowd_one_M')
    plt.scatter(crowd_one.ix[:, 1], crowd_one.ix[:, 2], s=5)    # 绘制数据点

    ax = plt.subplot(323)
    plt.axis([0,30,20000,80000])
    plt.xlabel(u'crowd_two_R')
    plt.ylabel(u'crowd_two_M')
    plt.scatter(crowd_two.ix[:, 0], crowd_two.ix[:, 2],s=5)      # 绘制数据点

    ax = plt.subplot(324)
    plt.axis([0, 120,20000,80000])
    plt.xlabel(u'crowd_two_F')
    plt.ylabel(u'crowd_two_M')
    plt.scatter(crowd_two.ix[:, 1], crowd_two.ix[:, 2], s=5)     # 绘制数据点

    ax = plt.subplot(325)
    plt.axis([0,16,50000,300000])
    plt.xlabel(u'crowd_three_R')
    plt.ylabel(u'crowd_three_M')
    plt.scatter(crowd_three.ix[:, 0], crowd_three.ix[:, 2],s=5)     # 绘制数据点

    ax = plt.subplot(326)
    plt.axis([0, 230,50000,300000])
    plt.xlabel(u'crowd_three_F')
    plt.ylabel(u'crowd_three_M')
    plt.scatter(crowd_three.ix[:, 1], crowd_three.ix[:, 2], s=5)    # 绘制数据点

    plt.show()



