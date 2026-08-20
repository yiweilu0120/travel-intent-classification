##Description##
请描述该ETL任务, 方便理解代码内容, 例如该任务产生什么数据、用于支持什么需求等

##Extract##
## 这里填写一个能读取source库下数据sql, 读出的数据会load到target库，hive2hive流程请留空

##Preload##
## 这里可以写load数据之前执行的SQL，例如清理数据、删除特定分区等，不需要请留空

##Load##
## 这里填写一个能load数据的SQL，非hive2hive流程请留空
## 注意：注释参数请使用##，--注释仅对SQL语句生效
## 下面参数的含义可以去https://km.sankuai.com/page/124233475中查看详细的解释
SET hive.exec.dynamic.partition.mode=nonstrict;
SET hive.exec.dynamic.partition=true;
SET hive.exec.max.dynamic.partitions=1000;
SET hive.default.fileformat=orc;
## 提升资源利用率，降低内存申请量，绝大多数任务memory+memoryOverhead<=2304M是可行的，既不会延长任务执行时间，也可以节省计算资源开销
## 注意：内存的调整要以256M的倍数为单位进行增减，即memory+memoryOverhead要是256M的整数倍。如果调整为1025M，实际生效是1024+256=1280M
SET spark.executor.memory=1536M;              ## 对于资源利用率低的可以调小至更低，不够用时再调大
SET spark.yarn.executor.memoryOverhead=768M;  ## 大部分任务其实设置为512M就够用，但个别大任务在peak day可能会oom，因此在768M更为安全
SET spark.memory.fraction=0.6;                ## 提高统一内存的比例，0.5-0.7都可以，如果使用udf中有大量内部变量，会有oom风险，可适当调小
## 控制map和reduce处理的文件大小
SET spark.hadoopRDD.targetBytesInPartition=134217728;                  ## 控制了orc.split.strategy=ETL时的文件切分大小，也变相控制了map stage的输出大小
SET spark.sql.adaptive.shuffle.targetPostShuffleInputSize=134217728;   ## shuffle read一般控制在128-256m之间；如果有数据膨胀可以调小（以shuffle write的数据量为判断依据）
## 小文件合并
SET spark.sql.mergeSmallFileSize=33554432;                 ## 小于32m启动合并，对于多分区的大表来说低于100m都可以考虑启动文件合并
SET spark.sql.targetBytesInPartitionWhenMerge=134217728;   ## 128m，设置为64-256m之间比较合适
## 控制申请的executor的并发数量
## 这是一个根据任务调整的参数，不是对时效性要求高的任务不设置太大的并发。非SLA任务executor*core和最大stage的task数量控制在1:5或1:10，SLA任务控制在1:5到1:2之间。
SET spark.dynamicAllocation.maxExecutors=500;
## 控制partition的最大并行度
## 这是一个根据任务调整的参数，spark3中这里设置的是最大partition数量，如果数据量很大（尤其是peak day数据量很大）可以酌情调大
SET spark.sql.shuffle.partitions=2000;
## SET spark.shuffle.manager=rss; ##只有在SLA中的任务，RSS参数才是有效的，可以根据任务权重是否有A或S判断，比如任务权重是 0S_15A_742B，则是SLA任务


WITH tmp AS (
    SELECT
        a.session_id,
        a.device_id,
        a.datekey,
        a.checkin_datekey,
        IF( date_temp.is_holiday = 1 , 1, 0) AS is_holiday,
        date_temp.holiday_type,
        a.poi_id,
        b.city_location_name
    FROM (
        SELECT DISTINCT
            session_id,
            device_id,
            datekey,
            checkin_datekey,
            mt_poi_id AS poi_id
        FROM mart_hoteltopic.aggr_log_pv_info
        WHERE
            datekey BETWEEN $now.delta(31).datekey AND $now.delta(1).datekey
            AND location_type = 1
            AND is_include_intention = 1
    ) a
    LEFT JOIN (
        SELECT DISTINCT
            poi_id,
            city_location_name
        FROM mart_hoteltopic.dim_poi_detail
        WHERE type = 1
    ) b
        ON a.poi_id = b.poi_id
        LEFT join (
                    SELECT
                    datekey, 
                    MAX(holiday_name)    AS holiday_name,
                    MAX(holiday_type)    AS holiday_type,
                    MAX(is_vacation)      AS is_vacation,
                    MAX(is_holiday)        AS is_holiday,
                    MAX(is_weekend)      AS is_weekend
                FROM mart_hoteldim.holiday_info
                GROUP BY datekey
        )date_temp
    on a.checkin_datekey = date_temp.datekey
         
)

INSERT OVERWRITE TABLE `${target.table}` PARTITION (dt,level3_biz_code)
SELECT DISTINCT
    a.session_id,
    b.session_id AS related_session_id,
    a.datekey as dt,
    'hotel' AS level3_biz_code
FROM
    (
        SELECT 
            session_id,
            device_id,
            datekey,
            checkin_datekey,
            is_holiday,
            holiday_type,
            poi_id,
            city_location_name
        FROM tmp
        WHERE datekey = $now.delta(1).datekey
    ) a
LEFT JOIN (
    SELECT             session_id,
            device_id,
            datekey,
            checkin_datekey,
            is_holiday,
            holiday_type,
            poi_id,
            city_location_name
    FROM tmp
) b
    ON a.device_id = b.device_id
        AND (
            a.checkin_datekey = b.checkin_datekey
            OR (a.holiday_type = b.holiday_type AND a.is_holiday = 1)
            OR (a.city_location_name = b.city_location_name AND DATEDIFF(DATEKEY2DATE(a.checkin_datekey), DATEKEY2DATE(b.checkin_datekey)) BETWEEN -1 AND 1)
            OR (a.poi_id = b.poi_id AND DATEDIFF(DATEKEY2DATE(a.checkin_datekey), DATEKEY2DATE(b.checkin_datekey)) BETWEEN -3 AND 3)
        )
WHERE IF(a.is_holiday > 0, (b.datekey >= $now.delta(7).datekey OR b.datekey >= DATE2DATEKEY(DATE_SUB(DATEKEY2DATE(a.checkin_datekey), 30))), (b.datekey >= $now.delta(7).datekey OR b.datekey >= DATE2DATEKEY(DATE_SUB(DATEKEY2DATE(a.checkin_datekey), 14))))
;

##TargetDDL##
## 填写目标表的表结构定义，用于目标表不存在的时候根据ddl建表。请确保sql中的字段和ddl中的字段的数量、顺序一致！！
CREATE TABLE IF NOT EXISTS `${target.table}`
(
    session_id                                           string COMMENT 'session_id',
    related_session_id                                   string COMMENT '关联session_id'
)
COMMENT 'session关联表'
PARTITIONED BY (dt string COMMENT '日期分区字段，格式为dt(yyyymmdd)',level3_biz_code string COMMENT '三级业务编码：hotel-酒店，homestay-民宿，ticket-景点游玩，vacation-度假，zuche-租车，flight-机票，train-火车票，coach-汽车票')
STORED AS ORC
;
