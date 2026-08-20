##Description##
## PV流量STP意向宽表：以mart_hoteltopic.aggr_log_pv_info为主表，取近30天数据，
## 通过session_id关联mart_jiulvsearch_algo.stp_result取intention和intention_prob，
## 限制条件：location_type=1 AND is_include_intention=1
## intention补全逻辑：优先取stp_result当天数据，取不到则回退产出表近30天历史分区的最新非空intention

##Extract##
## hive2hive 留空

##Preload##

##Load##
SET hive.exec.dynamic.partition.mode=nonstrict;
SET hive.exec.dynamic.partition=true;
SET hive.exec.max.dynamic.partitions=1000;
SET hive.default.fileformat=orc;
## 提升资源利用率，降低内存申请量，绝大多数任务memory+memoryOverhead<=2304M是可行的，既不会延长任务执行时间，也可以节省计算资源开销
## 注意：内存的调整要以256M的倍数为单位进行增减，即memory+memoryOverhead要是256M的整数倍。如果调整为1025M，实际生效是1024+256=1280M
SET spark.executor.memory=4G;              ## 对于资源利用率低的可以调小至更低，不够用时再调大
SET spark.yarn.executor.memoryOverhead=1024M;  ## 大部分任务其实设置为512M就够用，但个别大任务在peak day可能会oom，因此在768M更为安全
SET spark.memory.fraction=0.6;                ## 提高统一内存的比例，0.5-0.8都可以，如果使用udf中有大量内部变量，则会有oom风险，没有udf的可以设置0.6以上
## 控制map和reduce处理的文件大小
## orc.split.strategy=ETL时既能够控制大文件切分后的大小也能够控制小文件合并后的大小
## orc.split.strategy不等于ETL时可以控制小文件合并后的大小。总体上也能变相控制map stage的输出大小
SET spark.hadoop.hive.exec.orc.split.strategy=ETL;
SET spark.hadoopRDD.targetBytesInPartition=134217728;   
## shuffle read一般控制在64-256m之间；如果有数据膨胀可以调小（控制shuffle write的数据量在64-256m之间）
SET spark.sql.adaptive.shuffle.targetPostShuffleInputSize=134217728;   
## 小文件合并
SET spark.sql.mergeSmallFileSize=33554432;                 ## 小于32m启动合并，对于多分区的大表来说低于100m都可以考虑启动文件合并
SET spark.sql.targetBytesInPartitionWhenMerge=134217728;   ## 128m，设置为64-256m之间比较合适
## 控制申请的executor的并发数量
## 这是一个根据任务调整的参数，不是对时效性要求高的任务不设置太大的并发。非SLA任务executor*core和最大stage的task数量控制在1:5到1:10之间，SLA任务控制在1:5到1:2之间。
SET spark.dynamicAllocation.maxExecutors=2000;
## 控制partition的最大并行度
## 这是一个根据任务调整的参数，spark3中这里设置的是最大partition数量，如果数据量很大（尤其是peak day数据量很大）可以酌情调大
SET spark.sql.shuffle.partitions=2000;

INSERT OVERWRITE TABLE `${target.table}` PARTITION (dt)
SELECT
    t1.session_id,
    t1.user_key,
    t1.device_id,
    t1.mt_poi_id,
    t1.goods_id,
    t1.mt_checkin_city_id,
    t1.checkin_datekey,
    t1.client_type,
    t1.biz_site,
    t1.app_type,
    COALESCE(t2.intention, t3.intention) AS intention,
    t1.datekey AS dt
FROM mart_hoteltopic.aggr_log_pv_info t1
LEFT JOIN (
    SELECT
        session_id,
        intention
    FROM mart_jiulvsearch_algo.stp_result
    WHERE dt = '${now.datekey}'
    group by session_id,
        intention
) t2
    ON t1.session_id = t2.session_id
LEFT JOIN (
    SELECT
        session_id,
        intention,
        dt
    FROM `${target.table}`
    WHERE dt >= ${now.delta(30).datekey}
        AND dt < ${now.datekey}
        and intention is not null
    group by session_id,
        intention,
        dt
) t3
    ON t1.session_id = t3.session_id
    AND t1.datekey = t3.dt
WHERE t1.datekey >= ${now.delta(30).datekey}
    AND t1.datekey <= ${now.datekey}
    AND t1.location_type = 1
    AND t1.is_include_intention = 1
;

##TargetDDL##
CREATE TABLE IF NOT EXISTS `${target.table}`
(
    `session_id` string COMMENT '访问会话ID',
    `user_key` string COMMENT '用户key',
    `device_id` string COMMENT '设备ID',
    `mt_poi_id` bigint COMMENT 'mt门店ID',
    `goods_id` bigint COMMENT '商品ID',
    `mt_checkin_city_id` bigint COMMENT '美团侧入住城市ID',
    `checkin_datekey` bigint COMMENT '预计入住日期，格式yyyymmdd',
    `client_type` string COMMENT '客户端端类型',
    `biz_site` string COMMENT '业绩归属 mt:美团,dp:点评',
    `app_type` string COMMENT '小程序应用类型',
    `intention` int COMMENT '意向（1:出游,0:办事）'
)
COMMENT 'PV流量STP意向宽表，关联stp_result取意图识别结果'
PARTITIONED BY (dt bigint COMMENT '日期分区，格式yyyymmdd')
STORED AS ORC
;
