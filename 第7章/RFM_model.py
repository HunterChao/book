#-*- coding: utf-8 -*-

import pandas as pd
from sklearn.cluster import KMeans   #导入K均值聚类算法
import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
from mpl_toolkits.mplot3d import proj3d
import pylab

if __name__ == '__main__':

    inputfile = 'RFM_model.xlsx'  #待聚类的数据文件             
    k = 3           # 需要进行的聚类类别数

    #读取数据并进行聚类分析
    data = pd.read_excel(inputfile) #读取数据
    data = data.ix[:,1:4]       # 1-3列是R F M相对应的数据

    #调用k-means算法，进行聚类分析
    kmodel = KMeans(n_clusters = k, n_jobs = 4) #n_jobs是并行数，一般等于CPU数较好

    #kmodel.fit(data) #训练模型

    result = kmodel.fit_predict(data)

    # kmodel.cluster_centers_ 查看聚类中心
    # kmodel.labels_  查看各样本对应的类别

    label =list(kmodel.labels_)    # 分类对应标签

    writer = pd.ExcelWriter('save1.xlsx' )  # 将分类结果写入文件
    df = pd.DataFrame(data=label)
    df.to_excel(writer,'Sheet1')
    writer.save()

    '''对于RFM模型中三种变量在空间中分布特征'''
    ax = plt.subplot(111,projection='3d')
    ax.scatter(data.ix[:,0], data.ix[:,1],data.ix[:,2], c=label)  # 绘制数据点

    ax.set_xlabel('R')
    ax.set_ylabel('F')
    ax.set_zlabel('M')  # 坐标轴
    plt.show()

