
	
	
	--案例涉及到的相关表
	
	  用户信息表 (dwd.user_basic_info)
	  商品订单表 (dwd.gdm_ord_order)
	  图书信息表 (dwd.book_base_basic_info)
 	  图书类目表 (gdw.book_std_type_df)   
	  WEB端日志表 (dwd.beacon_web_books_client_pv_log)
	  APP端日志表 (dwd.beacon_app_books_client_pv_log)
  	  商品评论表 (dwd.book_comment) 
      用户收藏表  (dwd.book_collection_df)
      购物车信息表 (dwd.book_shopping_cart_df)
 	  搜索日志表  (dwd.app_search_log) 	 
	
	
-----------------------------------------	                ----------------------------------------------------------------------
-----------------------------------------	                ----------------------------------------------------------------------
-----------------------------------------	   用户属性表    ----------------------------------------------------------------------
-----------------------------------------	                ----------------------------------------------------------------------
	

		建立用户属性画像
从用户信息表、消费订单、APP页面访问表里挖掘用户基础属性和消费行为


drop table if exists dwd.user_profile_basic_informatin;
create table dwd.user_profile_basic_informatin   --用户属性表
     (
       user_id    string comment '用户编码',
	   user_name  string comment '姓名',
       gender_id   int comment '性别',
	   age int comment '年龄',
	   create_date timestamp comment '注册日期',
       province_name   string comment '省份',
       city_name   string comment '城市',
       mail_id     string comment '邮箱地址',
       call_phone_id int  comment '电话',
       first_order_time timestamp  comment '首次购买时间',
	   last_order_time timestamp  comment '最近一次消费时间',
	   first_order_ago int  comment '首次消费时间距今日期',
	   last_order_ago int  comment '最近一次消费距今日期',
	   max_order_amt double  comment '最大消费金额',
	   min_order_amt double  comment '最小消费金额',
	   sum_order_amount int  comment '累计消费金额',
	   sum_order_cnt double  comment '累计消费次数',
	   city_ratio string comment '常登陆地址'
     )
comment '用户画像-用户属性画像';



	
drop table if exists dwd.user_profile_basic_informatin_01;	 --创建用户属性表临时表1
create table dwd.user_profile_basic_informatin_01 
as
select t.user_name as user_name,	--姓名
	   t.user_id as user_id,	--用户id
	   t.age as age,
	   (case when gender_id = 0 then '男'
			 when gender_id = 1 then '女'
			 when gender_id = 2 then '其他' end) as gender_id,	--性别
	   t.gmt_created_date as create_date,   --注册日期
	   t.province_name as province_name,	--省份
	   t.city_name as city_name,	--城市
	   t.mail_id as mail_id,	--邮箱地址
	   t.call_phone_id as call_phone_id		--电话
  from dwd.user_basic_info t 		-- 从用户信息表抽取字段
where t.user_status_id =1
group by t.user_name,t.user_id,t.age,t.gender_id,t.province_name,t.city_name,t.mail_id,t.call_phone_id
		
	
	
create table dwd.user_profile_basic_informatin_02 
as
select t.user_id as user_id,		-- 用户id
	   min(create_date) as first_order_time ,		--首次购买日期
	   max(create_date) as last_order_time ,	    -- 最近一次消费日期
	   datediff(from_unixtime(unix_timestamp(),'yyyy-MM-dd'),min(create_date)) as first_order_ago,  --首次消费时间距今日期
	   datediff(from_unixtime(unix_timestamp(),'yyyy-MM-dd'),max(create_date)) as last_order_ago,	--最近一次消费距今日期	   
	   max(t.order_amount) as max_order_amt,		--最大消费金额   
	   min(t.order_amount) as min_order_amt,		--最小消费金额
	   sum(t.order_amount) as sum_order_cnt,   --累计消费金额
	   count(distinct order_id) as sum_order_amount,		--累计消费次数
from  dwd.gdm_ord_order t     -- 从商品订单表抽取字段
where  t.status_id in (2,4) 	--订单状态 已完成 已退款
group by t.user_id
		
--———————————————###########################		

			-- pv表取用户最近登录城市和对应次数
create table dwd.user_profile_basic_informatin_03_01
as
select user_id,	  --用户id
	   city,	  --城市
	   count(*) as num	 --访问次数
from  dwd.beacon_app_books_client_pv_log    --APP端日志表
where date_id >= date_sub(from_unixtime(unix_timestamp(),'yyyy-MM-dd'),30)
  and date_id <= date_sub(from_unixtime(unix_timestamp(),'yyyy-MM-dd'),1)	
group by user_id,city
		
	
		  
		
	  -- 计算登录每个城市的比例, 去除城市为空的属性
	create table dwd.user_profile_basic_informatin_03_02
	as
	select t1.user_id,	--用户id
		   t1.city,		--城市
		   t1.num/t2.all_nums as ratio	 --访问比率
	  from dwd.user_profile_basic_informatin_03_01 t1
 left join (select user_id,
				   sum(num) as all_nums	 --总访问次数
			from dwd.user_profile_basic_informatin_03_01  --上一步建立的临时表
			group by user_id
			) t2
		on t1.user_id = t2.user_id
	 where t1.city <> ''	--城市不能为空值
  group by t1.user_id,t1.city,t1.num/t2.all_nums
		
		
		
		-- 取登录比率前三的城市					
drop table if exists dwd.user_profile_basic_informatin_03_03;    
create table dwd.user_profile_basic_informatin_03_03
as 
select user_id,	 --用户id
	   city,	--城市
	   ratio	--比率
 from (
	   select user_id,
			  city,
			  ratio,
			  row_number() over(partition by user_id order by ratio desc) row_id
				-- 固定用户id不变,按比率(城市)从高到低排序
		 from dwd.user_profile_basic_informatin_03_02    --上一步建立的临时表  
	   ) t1
  where row_id <= 3		-- 取登录比率前三的城市	

   
			   
-- 常登录城市和比率合并成  城市:比率 | 城市:比率 | 城市:比率
create table dwd.user_profile_basic_informatin_03
as
select t1.user_id,	 --用户id
	   concat_ws('|', collect_set(t1.concats)) as city_ratio  --常登陆地址
  from (
		select user_id,
				concat(city,':',cast(ratio as string)) as concats
		  from dwd.user_profile_basic_informatin_03_03
		) t1
 group by t1.user_id
	  

------------------------------------------------------------------------------------------------------------------------

		
	create 	table dwd.user_profile_basic_informatin  --用户属性表
	as
	select t1.user_id,		--用户id
		   t1.user_name,    --姓名
		   t1.gender_id,	--性别
		   t1.create_date,	--年龄
		   t1.province_name,	--省份
		   t1.city_name,	--城市
		   t1.mail_id,	 --邮箱
		   t1.call_phone_id,	--电话
		   t2.first_order_time,	--首次购买时间
		   t2.last_order_time,	  --最近一次消费时间
		   t2.first_order_ago,	--首次消费时间距今日期
		   t2.last_order_ago,	--最近一次消费距今日期
		   t2.max_order_amt,	--最大消费金额
		   t2.min_order_amt,	--最小消费金额
		   t2.sum_order_amount,	--累计消费次数
		   t2.sum_order_cnt,	--累计消费金额
		   t3.city_ratio		--常登陆地址
	  from dwd.user_profile_basic_informatin_01 t1	  --临时表1
inner join dwd.user_profile_basic_informatin_02 t2    --临时表2
	    on t1.user_id = t2.user_id
inner join dwd.user_profile_basic_informatin_03 t3    --临时表3
	    on t1.user_id = t3.user_id
  group by t1.user_id,t1.user_name,t1.gender_id,t1.create_date,
           t1.province_name, t1.city_name,t1.mail_id,t1.call_phone_id,
		   t2.first_order_time,t2.last_order_time,t2.first_order_ago,
		   t2.last_order_ago,t2.max_order_amt,t2.min_order_amt,
		   t2.sum_order_amount,t2.sum_order_cnt,t3.city_ratio
		
		
-----------------------------------------	                ----------------------------------------------------------------------
-----------------------------------------	                ----------------------------------------------------------------------
-----------------------------------------  用户行为标签表   ----------------------------------------------------------------------
-----------------------------------------	                ----------------------------------------------------------------------

			 
drop table if exists dwd.persona_user_tag_relation_public;
create table dwd.persona_user_tag_relation_public   --用户属性表
     (
       user_id    string comment '用户编码',
       tag_id   string comment '标签id',
	   tag_name string comment '标签名称',
       cnt   int comment '行为次数',
       date_id   timestamp comment '行为日期',
       tag_type_id   int comment '标签类型',
       act_type_id int  comment '行为类型'
     )
comment '用户画像-用户行为标签表';
		 
 

      drop table if exists dwd.persona_user_tag_relation_public_01;
	  create table dwd.persona_user_tag_relation_public_01
	  as
	  select t1.book_id,      --图书编码
			 t1.book_name,    --图书名称
			 t2.book_type_tag,   --图书类型编码
			 t2.book_type_name    --图书类型名称
		from dwd.book_base_basic_info  t1    -- 图书信息表
  inner join dwd.book_std_type_df  t2		-- 图书类目表
          on t1.book_id = t2.book_id 	-- 通过图书id两表相关联
	   where t2.book_type_name not in  ('未定义', '其他')
    group by t1.book_id,      
			 t1.book_name,    
			 t2.book_type_tag,   
			 t2.book_type_name    
		 
		 
		 
	drop table if exists dwd.persona_user_tag_relation_public_02;
	create table dwd.persona_user_tag_relation_public_02
	as
	select  t1.user_id,
	        t1.date_id,
		    t1.book_id,
		   count(1) as cnt
	  from (
			select user_id as user_id,
				   date_id as date_id,
				   regexp_extract(parse_url(url,'PATH','.*/(.*?)$',1)) as book_id
			  from dwd.beacon_web_books_client_pv_log	--web页面访问表
			 where date_id = date_sub(from_unixtime(unix_timestamp(),'yyyy-MM-dd'),1)	--昨日
			   and url like '%books.com/detail/%'
			   and user_id <> ''
			   and user_id <> '-'
		 union all 	--
		    select user_id as user_id,
				   date_id as date_id,
				   regexp_extract(parse_url(url,'PATH','.*/(.*?)$',1)) as book_id
			  from dwd.beacon_app_books_client_pv_log   --app页面访问表
			 where date_id = date_sub(from_unixtime(unix_timestamp(),'yyyy-MM-dd'),1)	--昨日
			   and url like '%books.com/detail/%'
			   and user_id <> ''
			   and user_id <> '-'
		  ) t1
	where t1.book_id <> ''
 group by t1.user_id,
	      t1.date_id,
		  t1.book_id     
 
		 
--  1：购买行为，2：浏览行为，3：评论行为，4：收藏行为，5：取消收藏行为
--  6：加入购物车行为，7：搜索行为

行为类型1：用户购买图书行为带来的标签，代码执行如下：
insert into dwd.persona_user_tag_relation_public	--建立用户行为标签表
	  select t1.user_id as user_id,
			 t2.book_id as tag_id,		--购买图书对应的图书id作为标签id
			 t2.book_name as tag_name,
			 count(1) as cnt,
			 t1.create_date as date_id,
			 t3.book_type_tag as tag_type_id,
			 1 as act_type_id			--行为类型1
	   from dwd.gdm_ord_order t1		--商品订单表
 inner join dwd.book_base_basic_info t2	--图书信息表
         on t1.std_book_id = t2.book_id
 inner join dwd.book_std_type_df t3		-- 图书类目表	  
         on t2.book_id = t3.book_id
	  where t1.date_id  = date_sub(from_unixtime(unix_timestamp(),'yyyy-MM-dd'),1)	--昨日行为
	    and t1.user_id <> ''
		and t1.user_id <> '-'
   group by t1.user_id
		    t2.book_id,
		    t2.book_name,
		    t1.create_date,
		    t3.book_type_tag,
		    1     


行为类型2：用户浏览图书行为带来的标签，代码执行如下：
insert into dwd.persona_user_tag_relation_public
	  select t1.user_id as user_id,
		     t1.book_id as tag_id,
		     t2.book_name as tag_name,
		     count(1) as cnt,
		     t1.date_id as date_id,
		     t2.book_type_tag as tag_type_id,
		     2 as act_type_id		-- 行为类型2
	    from dwd.persona_user_tag_relation_public_02 t1  --用户浏览图书信息表
  inner join dwd.persona_user_tag_relation_public_01 t2   --获取图书信息临时表
          on t1.book_id = t2.book_id
       where t1.date_id = date_sub(from_unixtime(unix_timestamp(),'yyyy-MM-dd'),1)		
         and t1.user_id <> ''		--过滤用户id为空的脏数据
		 and t1.user_id <> '-'			--过滤用户id为-的脏数据
	group by t1.user_id,
			 t1.book_id,
			 t2.book_name,
			 t1.create_date,
			 t2.book_type_tag,
			 2  	


			 
行为类型3：用户评论图书行为带来的标签，代码执行如下：
insert into dwd.persona_user_tag_relation_public
	  select t1.user_id,
		     t3.book_id as tag_id,
		     t3.book_name as tag_name,
		     count(1) as cnt,
		     t1.create_date as date_id,
		     t2.book_type_tag as tag_type_id,
		     3 as act_type_id		
		from dwd.book_comment t1	 --商品评论表
  inner join dwd.gdm_ord_order t2   --商品订单表
		  on t1.order_code = t2.order_id	--订单id相关联
  inner join dwd.persona_user_tag_relation_public_01 t3   --图书信息临时表
		  on t2.std_book_id = t3.book_id
	   where t1.create_date = date_sub(from_unixtime(unix_timestamp(),'yyyy-MM-dd'),1)	
		 and t1.status_id = 2        --评论状态:已审核 
         and t1.user_id <> ''		 --过滤用户id为空的脏数据
		 and t1.user_id <> '-'		 --过滤用户id为-的脏数据  
    group by t1.user_id,
		     t3.book_id,
		     t3.book_name,
		     t1.create_date,
		     t2.book_type_tag,
		     3		

 
 
 行为类型4：用户收藏图书行为带来的标签，代码执行如下：
insert into dwd.persona_user_tag_relation_public
	  select t1.user_id as user_id,
	         t1.book_id as tag_id,
			 t2.book_name as tag_name,
			 count(1) as cnt,
			 t1.create_date as date_id,
			 t2.book_type_tag as tag_type_id,
			 4 as act_type_id
	   from dwd.book_collection_df t1      --用户收藏表
 inner join dwd.persona_user_tag_relation_public_01 t2    --获取图书信息临时表
         on t1.book_id = t2.book_id
	  where t1.date_id = date_sub(from_unixtime(unix_timestamp(),'yyyy-MM-dd'),1)	
        and t1.status_id = 1   --状态 1 收藏	   
        and t1.user_id <> ''
		and t1.user_id <> '-'
   group by t1.user_id,
			t1.book_id,
			t2.book_name,
			t1.create_date,
			t2.book_type_tag,
			4

			
			
行为类型5：用户取消收藏图书行为带来的标签，代码执行如下：
insert into  dwd.persona_user_tag_relation_public
	  select t1.user_id as user_id,
	         t1.book_id as tag_id,
			 t2.book_name as tag_name,
			 count(1) as cnt,
			 t1.create_date as date_id,
			 t2.book_type_tag as tag_type_id,
			 5 as act_type_id
		from dwd.book_collection_df t1      --用户收藏标签表
  inner join dwd.persona_user_tag_relation_public_01 t2    --获取图书信息临时表
          on t1.book_id = t2.book_id
	   where t1.date_id = date_sub(from_unixtime(unix_timestamp(),'yyyy-MM-dd'),1)	
         and t1.status_id = 0   --状态 0 取消收藏	   
         and t1.user_id <> ''
		 and t1.user_id <> '-'
	group by t1.user_id
			 t1.book_id,
			 t2.book_name,
			 t1.create_date,
			 t2.book_type_tag,
			 5

			 
			 
行为类型6：用户加入购物车行为带来的标签，代码执行如下：
insert into dwd.persona_user_tag_relation_public
	  select t1.user_id as user_id,
	         t1.book_id as tag_id,
			 t2.book_name as tag_name,
			 count(1) as cnt,
			 t1.create_date as date_id,
			 t2.book_type_tag as tag_type_id,
			 6 as act_type_id				--用户行为类型固定写死
		from dwd.book_shopping_cart_df t1	--购物车信息表
  inner join dwd.persona_user_tag_relation_public_01 t2    --获取图书信息临时表
          on t1.book_id = t2.book_id
	   where t1.date_id = date_sub(from_unixtime(unix_timestamp(),'yyyy-MM-dd'),1)	  
         and t1.user_id <> ''
		 and t1.user_id <> '-'
		 and t1.status_id = 1   --状态 1 加入购物车	
	group by t1.user_id
			 t1.book_id,
			 t2.book_name,
			 t1.create_date,
			 t2.book_type_tag,
			 6 	


			 
行为类型7：用户搜索行为带来的标签，代码执行如下：
insert into dwd.persona_user_tag_relation_public
	  select t.user_id,
			 t.tag_id,
			 t.tag_name,
			 t.cnt,
			 t.date_id,
			 t.tag_type_id,
			 t.act_type_id
	   from (
			select t1.user_id,
				   t2.book_id as tag_id,
				   t2.book_name as tag_name,
				   count(1) as cnt
			       t1.date_id,   --搜索日期
				   t3.book_type_tag as tag_type_id,
				   7 as act_type_id				   
			  from dwd.app_search_log t1 	--搜索日志表
		inner join dwd.book_base_basic_info t2	--图书信息表
			    on t1.tag_name = t2.book_name  --搜索匹配到的标签与图书名称相关联
	    inner join dwd.persona_user_tag_relation_public_01 t3    --图书信息临时表
			    on t2.book_id = t3.book_id
			 where t1.date_id = date_sub(from_unixtime(unix_timestamp(),'yyyy-MM-dd'),1)
				) t 
    group by t.user_id,
			 t.tag_id,
			 t.tag_name,
			 t.cnt,
			 t.date_id,
			 t.tag_type_id,
			 t.act_type_id
			 

			 
-----------------------------------------	                    ----------------------------------------------------------------------
-----------------------------------------	                    ----------------------------------------------------------------------
-----------------------------------------  用户行为标签权重表   ----------------------------------------------------------------------
-----------------------------------------	                    ----------------------------------------------------------------------

drop table if exists dwd.person_user_tag_relation_weight;
create table dwd.person_user_tag_relation_weight   --用户行为标签权重表
     (
       user_id  string comment '用户编码',
       tag_id   string comment '标签id',
	   tag_name string comment '标签名称',
       cnt   int comment '行为次数',
       tag_type_id   int comment '标签类型',
	   date_id  date  comment '行为日期',
       act_weight int  comment '权重值'
     )
comment '用户画像-用户行为标签权重表';
	  
		 
		 
drop table if exists dwd.act_weight_plan_detail;
create table dwd.act_weight_plan_detail(      
			act_type_id  int comment '行为类型',   
			act_weight_detail  comment '行为权重',   
			date_id date  comment '维表创建日期',    
			is_time_reduce int comment '是否时间衰减') 
comment '用户画像-用户行为权重维表';




--向行为权重维表中插入数据
    -- is_time_reduce: 1 衰减   0 不衰减
	 insert into dwd.act_weight_plan_detail  
	 values(1, 1.5, '2017-10-01',1);    --1：购买行为 权重 1.5
	 insert into dwd.act_weight_plan_detail 
	 values(2, 0.3, '2017-10-01',1);   --2：浏览行为 权重 0.3
	 insert into dwd.act_weight_plan_detail 
	 values(3, 0.5, '2017-10-01',0);   --3：评论行为 权重 0.5
	 insert into dwd.act_weight_plan_detail  
	 values(4, 0.5, '2017-10-01',1);   --4：收藏行为 权重 0.5
	 insert into dwd.act_weight_plan_detail  
	 values(5, -0.5, '2017-10-01',0);  --5：取消收藏行为 权重 -0.5
	 insert into dwd.act_weight_plan_detail  
	 values(6, 1, '2017-10-01',0);   --6：加入购物车行为 权重 1
	 insert into dwd.act_weight_plan_detail  
	 values(7, 0.8, '2017-10-01',1)   --7：搜索行为 权重 0.8

		 
		 
 drop table if exists dwd.tag_weight_of_tfidf_01;
	 create table dwd.tag_weight_of_tfidf_01
	 as
	 select  t1.user_id,
	         t1.tag_id,
	         t1.tag_name,
		     t1.weight_m_p,   --用户身上每个标签个数
			 t2.weight_m_s   --用户身上标签总数
	  from (
	         select t.user_id,
				    t.tag_id,
				    t.tag_name,
				    count(t.tag_id) as weight_m_p	--用户身上每个标签个数
			   from dwd.persona_user_tag_relation_public t
		   group by t.user_id,t.tag_id,t.tag_name
		   ) t1
  left join (
			 select t.user_id,
					count(t.tag_id) as weight_m_s  --用户身上标签总数
			   from dwd.persona_user_tag_relation_public t
		   group by t.user_id
		    ) t2
		 on t1.user_id = t2.user_id
   group by  t1.user_id,t1.tag_id,t1.tag_name,t1.weight_m_p,t2.weight_m_s
		 
		 
 drop table if exists dwd.tag_weight_of_tfidf_02;
	create table  dwd.tag_weight_of_tfidf_02
	as
	select t1.tag_id,
	       t1.tag_name,
		   t1.weight_w_p,	--每个标签在全体标签中共有多少个
		   t2.weight_w_s	--全体所有标签的总个数
	  from (
             select t.tag_id,
				    t.tag_name,
				    sum(weight_m_p) as weight_w_p
			   from dwd.tag_weight_of_tfidf_01 t
		   group by t.tag_id,t.tag_name
		   ) t1
cross join (
			select sum(t.weight_m_p) as weight_w_s
			  from dwd.tag_weight_of_tfidf_01 t
			 ) t2

			 
-- TF-IDF计算每个用户身上标签权重    
drop table if exists dwd.tag_weight_of_tfidf_03;
   create table dwd.tag_weight_of_tfidf_03
   as
   select t1.user_id,
		  t1.tag_id,
		  t1.tag_name,
		  (t1.weight_m_p/t1.weight_m_s)*(log10(t2.weight_w_s/t2.weight_w_p)) as ratio
     from dwd.tag_weight_of_tfidf_01 t1
left join dwd.tag_weight_of_tfidf_02 t1
	   on t1.tag_id = t2.tag_id  
 group by t1.user_id,t1.tag_id,t1.tag_name,
		  (t1.weight_m_p/t1.weight_m_s)*(log10(t2.weight_w_s/t2.weight_w_p))

  

				
  
    insert into  dwd.person_user_tag_relation_weight
    select t1.user_id,
		   t1.tag_id,
		   t1.tag_name,
		   t1.cnt,
		   t1.date_id,
		   t1.tag_type_id,
		   case when t2.is_time_reduce = 1 then
			        exp(datediff('2017-10-01', t1.date_id) * (-0.1556)) * t2.act_weight * t1.cnt * t3.ratio  --随时间衰减行为
			    when t2.is_time_reduce = 0 then
			         t2.act_weight * t1.cnt * t3.ratio   --不随时间衰减行为
		   end as act_weight
	  from  dwd.persona_user_tag_relation_public t1  --用户行为标签表
inner join  dwd.act_weight_plan_detail t2		 -- 行为权重维表
	    on  t1.tag_type_id = t2.act_type_id  --通过行为类型关联
inner join  dwd.tag_weight_of_tfidf_03 t3		--TF-IDF标签权重表
	    on  (t1.user_id = t3.user_id and t1.tag_id = t3.tag_id)	--用户id和标签id两个字段做主键关联
     where  t1.date_id <= '2017-10-01'  --以'2017-10-01'作为当前日期,跑批历史数据
  group by t1.user_id,t1.tag_id,t1.tag_name,t1.cnt,t1.date_id,t1.tag_type_id,
		   case when t2.is_time_reduce = 1 then
			        exp(datediff('2017-10-01', t1.date_id) * (-0.1556)) * t2.act_weight * t1.cnt * t3.ratio  --随时间衰减行为
			    when t2.is_time_reduce = 0 then
			         t2.act_weight * t1.cnt * t3.ratio end
	 
	 
-----------------------------------------	                ----------------------------------------------------------------------
-----------------------------------------	                ----------------------------------------------------------------------
-----------------------------------------	 群体用户画像   ----------------------------------------------------------------------
-----------------------------------------	                ----------------------------------------------------------------------


drop table if exists dwd.person_groups_perfer_books;
create table dwd.person_groups_perfer_books   --群体用户画像表
     (
       age    string comment '年龄段',
       sex   string comment '性别',
	   tag_id string comment '标签id',
       tag_name  string comment '标签名称'   
	   )
comment '用户画像-群体用户画像';
	  
	 
	  
	  
drop table if exists dwd.person_groups_temp_age;
 create table dwd.person_groups_temp_age
 as 
 select  user_id,
		case when gender_id = 0 then '男性'
			 when gender_id = 1 then '女性'
			 else '其他'
		end as user_sex,
		case when age >= 0 and age <= 8 then '儿童'
			 when age >= 8 and age <= 16 then '少年'
			 when age >= 17 and age <= 40 then '青年'
			 when age >= 41 and age <= 60 then '中年'
			 when age >= 61 then '老年'
			 else '其他'
		end as user_age
  from  dwd.user_profile_basic_informatin     --用户属性表 
 where user_id is not null


	  
drop table if exists dwd.tmp_person_groups_prefer_01;
	create table dwd.tmp_person_groups_prefer_01
	as 
	select t1.user_id,		
	       t1.tag_id,	--标签id
		   t1.tag_name,	  --标签名称	
		   t1.act_weight,  --标签权重
		   t2.user_sex,		--用户性别
		   t2.user_age		--用户年龄段
	  from dwd.person_user_tag_relation_weight t1    --用户标签权重表
inner join dwd.person_groups_temp_age t2	 --用户年龄分段临时表
		on t1.user_id = t2.user_id 
  group by t1.user_id,t1.tag_id,t1.tag_name,
           t1.act_weight,t2.user_sex,t2.user_age
		   
	
	  
	  
-- 使用TF-IDF计算用户人群标签总权重
	drop table dwd.tmp_person_groups_man_prefer_sum;
	create table dwd.tmp_person_groups_man_prefer_sum
	as
	select t1.tag_id,
		   t1.weight_w_p,		--全体用户中某个图书的总权重值
		   t1.weight_w_s		--全体用户中所有图书的总权重值
	  from (
			select tag_id,
				   sum(act_weight) as weight_w_p
			  from dwd.tmp_person_groups_prefer_01
		  group by tag_id
		   ) t1
 cross join (
			select sum(act_weight) as weight_w_s
			  from dwd.tmp_person_groups_prefer_01
			 )
 
 
 
-- 使用TF-IDF算法计算男性各年龄段的偏好图书标签
drop table if exists dwd.tmp_person_groups_man_prefer_01;
	create table dwd.tmp_person_groups_man_prefer_01
	as
	select t1.user_sex,
		   t1.user_age,
		   t1.tag_id,	--标签id
		   t1.tag_name,	 --标签名称
		   t1.weight_m_p,   --男性、儿童中某个图书的总权重值
		   t2.weight_m_s    --男性、儿童中所有图书的总权重值
	  from (
			select  user_sex,
				    user_age,
				    tag_id,
				    tag_name,
				    sum(act_weight) as weight_m_p,
			  from  dwd.tmp_person_groups_prefer_01
			 where  user_age = '儿童' 
			   and  user_sex = '男性'
		  group by  user_sex,
				    user_age,
				    tag_id,
				    tag_name
			) t1
 cross join (
		   select  sum(act_weight) as weight_m_s
			 from  dwd.tmp_person_groups_prefer_01
			where  user_age = '儿童' 
			  and  user_sex = '男性'
			 ) t2

			 
		  
		 -- 单个图书标签对男性 儿童的相关度
 drop table if exists dwd.tmp_person_groups_man_tfidf_prefer_01;
   create table dwd.tmp_person_groups_man_tfidf_prefer_01
   as
   select t1.user_sex,	--用户性别
		  t1.user_age,	--用户年龄段
		  t1.tag_id,		--标签id
		  t1.tag_name,	--标签类型
		  t1.weight_m_p,
		  t1.weight_m_s,
		  t2.weight_w_p,
		  t2.weight_w_s,
		  (t1.weight_m_p/t1.weight_m_s)/(t2.weight_w_p/t2.weight_w_s) as ratio
     from dwd.tmp_person_groups_man_prefer_01 t1
	     --t1记录男性、儿童中某个图书的总权重值及所有图书的总权重值
left join dwd.tmp_person_groups_man_prefer_sum t2	
         --t2表记录某个图书的总权重值及全部图书总权重值
	   on t1.tag_id = t2.tag_id

		 
	-- 取出男性儿童人群中最偏好的前10个图书标签
 drop table if exists dwd.person_groups_perfer_books;
  create table dwd.person_groups_perfer_books
  as
  select '儿童' as age,
	     '男性' as sex,
	     tag_id,
	     tag_name
    from dwd.tmp_person_groups_man_tfidf_prefer_01
order by ratio desc    --按相关度的大小做倒排序
   limit 10


   
   
-----------------------------------------	                ----------------------------------------------------------------------
-----------------------------------------	                ----------------------------------------------------------------------
-----------------------------------------	 用户偏好画像   ----------------------------------------------------------------------
-----------------------------------------	                ----------------------------------------------------------------------


drop table if exists dwd.user_prefer_peasona_tag;
create table dwd.user_prefer_peasona_tag   --用户偏好画像表
     (
       user_id    string comment '用户编码',
	   tag_id string comment '标签id',
       tag_name  string comment '标签名称',
	   recommend string comment '推荐值'	   
	   )
comment '用户画像-用户偏好画像表';

		

-- 1：购买行为，2：浏览行为，3：评论行为，4：收藏行为，
-- 5：取消收藏行为，6：加入购物车行为，7：搜索行为

 drop table dwd.user_prefer_peasona_user_tag_01;
   create table dwd.user_prefer_peasona_user_tag_01
	as
	select user_id,
		   org_id,
		   org_name,
		   cnt,
		   date_id,
		   tag_type_id,
		   act_type_id
	  from dwd.persona_user_tag_relation_public  --用户行为标签表
	 where date_id >= date_sub(from_unixtime(unix_timestamp(),'yyyy-MM-dd'),31)	
	   and date_id <= date_sub(from_unixtime(unix_timestamp(),'yyyy-MM-dd'),1)	 --示例 抽取近一个月的标签行为
	   and act_type_id in (1,3,4,6,7)  --取用户购买、评论、收藏、加入购物车、搜索行为带来的标签
  group by user_id,org_id,org_name,cnt,
		   date_id,tag_type_id,act_type_id

		   
	  
  drop table dwd.user_prefer_peasona_user_tag_02;
	create table dwd.user_prefer_peasona_user_tag_02
	as
	select org_id,		--标签id
		   org_name,
		   count(distinct user_id) user_num,	--有该标签的用户数
		   row_number() over (order by count(distinct user_id) desc) rank
	  from dwd.user_prefer_peasona_user_tag_01
  group by org_id,org_name

			   
	  
  drop table dwd.user_prefer_peasona_user_tag_03;
 create table dwd.user_prefer_peasona_user_tag_03
 as
 select t.org_id_1,
		t.org_name_1,
		t.org_id_2,
		t.org_name_2,
		t.num
   from (
		select t1.org_id org_id_1,
			   t1.org_name org_name_1,
			   t2.org_id org_id_2,
			   t2.org_name org_name_2,
			   count(distinct t1.user_id) as num
		  from dwd.user_prefer_peasona_user_tag_01 t1
	cross join dwd.user_prefer_peasona_user_tag_01 t2
		 where t1.user_id <> t2.user_id		--不同的用户
	  group by t1.org_id,
			   t1.org_name,
			   t2.org_id,
			   t2.org_name
		  ) t

				  

 drop table dwd.user_prefer_peasona_user_tag_04				  
   create table dwd.user_prefer_peasona_user_tag_04
   as
   select t1.org_id_1,		--第一个标签id
		  t1.org_name_1,	--第一个标签名称
		  t2.user_num_1,	--第一个标签人数
		  t1.org_id_2,		--第二个标签id
		  t1.org_name_2,
		  t3.user_num_2,
		  t1.num,		--两个标签共同的用户人数
		  (t1.num/sqrt(t2.user_num_1 * t3.user_num_2)) as power,
		  row_number() over(order by (t1.num/sqrt(t2.user_num_1 * t3.user_num_2)) desc) rank
     from dwd.user_prefer_peasona_user_tag_03 t1
left join (select org_id,
			      user_num as user_num_1
		     from dwd.user_prefer_peasona_user_tag_02
		  ) t2
	   on t1.org_id_1 = t2.org_id
left join (select org_id,
			      user_num as user_num_2
		     from dwd.user_prefer_peasona_user_tag_02
		  ) t3
	   on t1.org_id_2 = t3.org_id
 group by t1.org_id_1,t1.org_name_1,t2.user_num_1,
		  t1.org_id_2,t1.org_name_2,t3.user_num_2,
		  t1.num,(t1.num/sqrt(t2.user_num_1 * t3.user_num_2))

				 
			
drop table dwd.user_prefer_peasona_user_tag_05;
  create table dwd.user_prefer_peasona_user_tag_05
  as
  select user_id,
		 org_id,
		 org_name,
		 sum(act_weight) as weight,
		 row_number() over(order by sum(act_weight) desc) as rank
    from dwd.person_user_tag_relation_weight    --用户标签权重表
   where act_type_id in (1,3,4,6,7)  
    --取用户购买、评论、收藏、加入购物车、搜索行为带来的标签
group by user_id,org_id,org_name


				

 insert into dwd.user_prefer_peasona_tag 	--数据插入用户偏好画像表
 select t.user_id,
		t.tag_id,
		t.tag_name,
		t.recommend
   from(
		select t1.user_id,
			   t2.org_id_2 as tag_id,		--推荐的标签
			   t1.org_name_2 as tag_name,	
			   sum(t1.weight * t2.power) as recommend,
			   row_number() over (order by sum(t1.weight * t2.power) desc) as row_rank
		  from dwd.user_prefer_peasona_user_tag_05 t1	--用户历史偏好标签
	 left join dwd.user_prefer_peasona_user_tag_04 t2	--标签相似度表
			on t1.org_id = t2.org_id_1
	  group by t2.user_id,
			   t1.org_id_2,
			   t1.org_name_2
		) t
  where t.row_rank <=10	 --每个用户取前10个推荐的标签

					
				
				

	