##Description##
## 订单交易STP意向宽表：以mart_hoteltopic.aggr_log_order_trade_info为主表，取近30天数据，
## 通过session_id关联mart_jiulvsearch_algo.stp_result取intention和intention_prob，
## 限制条件：location_type=1 AND biz_type<>'bill' AND is_order=1
## intention补全逻辑：优先取stp_result当天数据，取不到则回退产出表近30天历史分区的最新非空intention


##Extract##
## hive2hive 留空


##Preload##


##Load##
SET hive.exec.dynamic.partition.mode=nonstrict;
SET hive.exec.dynamic.partition=true;
SET hive.exec.max.dynamic.partitions=1000;
SET hive.default.fileformat=orc;
SET spark.sql.mergeSmallFileSize=20971520;
SET spark.hadoopRDD.targetBytesInPartition=67108864;
SET spark.sql.adaptive.shuffle.targetPostShuffleInputSize=134217728;
SET spark.sql.shuffle.partitions=500;

INSERT OVERWRITE TABLE `${target.table}` PARTITION (dt)
SELECT
    t1.session_id,
    t1.order_key,
    t1.user_key,
    t1.device_id,
    t1.poi_id,
    t1.goods_id,
    t1.mt_checkin_city_id,
    t1.checkin_datekey,
    t1.is_order,
    t1.order_roomnight_cnt,
    t1.order_amt,
    t1.is_pay,
    t1.pay_roomnight_cnt,
    t1.pay_amt,
    t1.is_consume,
    t1.consume_roomnight_cnt,
    t1.consume_amt,
    COALESCE(t2.intention, t3.intention) AS intention,
    t1.datekey AS dt
FROM mart_hoteltopic.aggr_log_order_trade_info t1
LEFT JOIN (
    select 
      t.session_id,
      t.intention
    from
    (SELECT
        session_id,
        intention,
        row_number() over(partition by session_id order by dt desc) as rn_int
    FROM mart_jiulvsearch_algo.stp_result
    WHERE dt >= '${now.delta(30).datekey}'
    and dt <= '${now.datekey}' and intention is not null
    ) t
    where t.rn_int=1
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
    group by session_id,
        intention,
        dt
) t3
    ON t1.session_id = t3.session_id
    AND t1.datekey = t3.dt
WHERE t1.datekey >= ${now.delta(30).datekey}
    AND t1.datekey <= ${now.datekey}
    AND t1.location_type = 1
    AND t1.biz_type <> 'bill'
;

##TargetDDL##
CREATE TABLE IF NOT EXISTS `${target.table}`
(
    `session_id` string COMMENT '访问会话ID',
    `order_key` string COMMENT '订单key',
    `user_key` string COMMENT '用户key',
    `device_id` string COMMENT '设备ID',
    `poi_id` bigint COMMENT '门店ID',
    `goods_id` bigint COMMENT '商品ID',
    `mt_checkin_city_id` bigint COMMENT '美团侧入住城市ID',
    `checkin_datekey` bigint COMMENT '预计入住日期，格式yyyymmdd',
    `is_order` int COMMENT '是否当日支付 1:是 0:否',
    `order_roomnight_cnt` int COMMENT '支付间夜量',
    `order_amt` decimal(20,4) COMMENT '支付订单总额',
    `is_pay` int COMMENT '是否当日支付 1:是 0:否',
    `pay_roomnight_cnt` int COMMENT '支付间夜量',
    `pay_amt` decimal(20,4) COMMENT '支付订单总额',
    `is_consume` int COMMENT '是否当日消费 1:是 0:否',
    `consume_roomnight_cnt` int COMMENT '消费间夜量',
    `consume_amt` decimal(20,4) COMMENT '消费金额',
    `intention` int COMMENT '意向（1:出游,0:办事）'
)
COMMENT '订单交易STP意向宽表，关联stp_result取意图识别结果'
PARTITIONED BY (dt bigint COMMENT '日期分区，格式yyyymmdd')
STORED AS ORC
;
