# -*- coding: utf-8 -*-
# 定时调度任务
hive_sql_createtable = '''
 从数据仓库抽取、清洗用户上前5周行为数据，并写入临时表
'''
# 查询需要的数据
hive_sql_searchdata = '''
查询执行完hive_sql_createtable任务后得到的用户行为数据
'''
import pyhs2
import pandas as pd
from pandas import DataFrame

conn = pyhs2.connect(host='主机地址', port=10000, authMechanism="PLAIN", user='user_name',  password='xx',  database='dwd')    # 连接到线上数据库
cur = conn.cursor()
cur.execute(hive_sql_createtable)
#模型输入数据
cur.execute(hive_sql_searchdata)
results_x = cur.fetchall()    # 获取查询得到的用户行为数据
getSchema_ = cur.getSchema()       # 获取数据库架构信息

data = DataFrame(results_x,columns= DataFrame(getSchema_)['columnName'])    #输入模型数据
from sklearn import preprocessing

data_x = data.ix[:,2:].as_matrix()   #将表格转换为矩阵

d=data_x.astype('float64')
X = preprocessing.scale(d)      #标准化数据d  该数据不包含用户id

# 用保存的模型进行预测
from sklearn.externals import joblib
MODEL_LOAD = joblib.load("/home/admin/model/filename.pkl")  # 加载之前保存的决策树模型

#预测
predict_churn = MODEL_LOAD.predict(X)    # X是跑出来的结果，将结果放到pkl数据模型中

#导出预测结果
user_id = pd.DataFrame(data.ix[:,:2])      # 用户id
predict_ = pd.DataFrame(predict_churn)       # 是否流失
result = pd.concat([user_id,predict_], axis=1)     # 将三个字段拼接起来
result.columns = ['user_id','predict_churn']

#导出txt到ftp
import os
filename='/home/admin/model/predict_churn.txt'
os.system('rm -f %s' % filename)
result.to_csv('/home/admin/model/predict_churn.txt', index=False, header=False)

#连接ftp上传
from ftplib  import FTP
ftp=FTP()
ftp.connect(host = '主机地址',port = 21)
ftp.login('username','password')

ftp.cwd('user') #存储到user目录下

remotepath = '/user/predict_churn.txt'
ftp.storbinary('STOR ' + os.path.basename(remotepath), open(filename), 1024)
