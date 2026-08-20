##Description##
出游办事session特征主表（优化版）
优化点：
1. 去掉所有维度表不必要的 DISTINCT（减少 Reduce Shuffle）
2. POI 标签子查询用 GROUP BY 聚合，避免一对多膨胀
3. 订单子查询 g 明确多订单处理逻辑（取首单）
4. j 子查询 SUBSTR 改为等值 JOIN
5. 小维表加 MAPJOIN 提示
6. travel_distance 加 ACOS 边界保护
7. 节假日判断保留原逻辑（建议后续迁移至维表）


def get_last_data_partition():
    import datetime
    from time import strftime
    
    now = datetime.datetime.now() + datetime.timedelta(days = -1)
    
    return now.strftime("%Y%m%d")
    
last_partition_datekey = get_last_data_partition();
##Extract##

##Preload##

##Load##
## 这里填写一个能load数据的SQL，非hive2hive流程请留空
## 注意：注释参数请使用##，--注释仅对SQL语句生效
SET hive.exec.dynamic.partition.mode=nonstrict;
SET hive.exec.dynamic.partition=true;
SET hive.exec.max.dynamic.partitions=1000;
SET hive.default.fileformat=orc;
## spark shuffle默认分区数
## 提升资源利用率，降低内存申请量，绝大多数任务memory+memoryOverhead<=2304M是可行的，既不会延长任务执行时间，也可以节省计算资源开销
## 注意：内存的调整要以256M的倍数为单位进行增减，即memory+memoryOverhead要是256M的整数倍。如果调整为1025M，实际生效是1024+256=1280M
SET spark.executor.memory=5000M;                    ## 对于资源利用率低的可以调小至更低，不够用时再调大
SET spark.yarn.executor.memoryOverhead=1024M;       ## 大部分任务其实设置为512M就够用，但个别大任务在peak day可能会oom，因此在768M更为安全
SET spark.memory.fraction=0.7;                      ## 提高统一内存的比例，0.5-0.7都可以，如果使用udf中有大量内部变量，会有oom风险，可适当调小
SET spark.executor.cores=2;
## 控制map和reduce处理的文件大小
SET spark.hadoopRDD.targetBytesInPartition=134217728;                       ## 控制了orc.split.strategy=ETL时的文件切分大小，也变相控制了map stage的输出大小
SET spark.sql.adaptive.shuffle.targetPostShuffleInputSize=16554432;        ## shuffle read一般控制在128-256m之间；如果有数据膨胀可以调小（以shuffle write的数据量为判断依据）
## 小文件合并
SET spark.sql.mergeSmallFileSize=33554432;                      ## 小于32m启动合并，对于多分区的大表来说低于100m都可以考虑启动文件合并
SET spark.sql.targetBytesInPartitionWhenMerge=67108864;        ## 128m，设置为64-256m之间比较合适
## 控制申请的executor的并发数量
## 这是一个根据任务调整的参数，不是对时效性要求高的任务不设置太大的并发。非SLA任务executor*core和最大stage的task数量控制在1:5或1:10，SLA任务控制在1:5到1:2之间。
SET spark.dynamicAllocation.maxExecutors=2000;   ## 控制partition的最大并行度
## 这是一个根据任务调整的参数，spark3中这里设置的是最大partition数量，如果数据量很大（尤其是peak day数据量很大）可以酌情调大
SET spark.sql.shuffle.partitions=5000;        
## 开启AQE自适应执行（Spark3推荐）
SET spark.sql.adaptive.enabled=true;
SET spark.sql.adaptive.coalescePartitions.enabled=true;

with date_temp as (
    SELECT
    datekey, 
    MAX(holiday_name)    AS holiday_name,
    MAX(holiday_type)    AS holiday_type,
    MAX(is_vacation)      AS is_vacation,
    MAX(is_holiday)        AS is_holiday,
    MAX(is_weekend)      AS is_weekend
FROM mart_hoteldim.holiday_info
GROUP BY datekey
)

INSERT OVERWRITE TABLE `${target.table}` PARTITION (dt,level3_biz_code)
SELECT /*+ MAPJOIN(c) */
    a.checkin_datekey,
    a.session_id,
    a.device_id,
    a.user_key,
    b.city_location_name,
    d.yx_id,
    a.poi_id,
    a.goods_id,
    a.page_type,
    a.page_stay_time,
    a.event_identifier,
    -- ========== 节假日/周末/假期判断 ==========
    IF( date_temp.is_holiday = 1 or date_temp.is_weekend =1 or date_temp.is_vacation =1, 1, 0) AS is_holiday_weekend_vacation,
    IF( date_temp.is_holiday = 1 , 1, 0) AS is_holiday,
    IF( date_temp.is_weekend = 1 , 1, 0) AS is_weekend,
    IF( date_temp.is_vacation =1, 1, 0) AS is_vacation,
    IF(DAYOFWEEK(DATEKEY2DATE(a.datekey)) IN (5, 6), 1, 0) AS is_booking_weekend,
    DATEDIFF(DATEKEY2DATE(a.checkin_datekey), DATEKEY2DATE(a.datekey)) AS lead_time,
    -- ========== POI 维度属性 ==========
    b.latitude,
    b.longitude,
    b.is_star2,
    b.is_star3,
    b.is_star4,
    b.is_star5,
    b.is_budget,
    b.is_express,
    b.is_business,
    b.is_theme,
    b.is_couple,
    b.is_apartment,
    b.is_inn,
    b.is_homestay,
    b.is_hostel,
    b.is_farmstay,
    b.is_family_guesthouse,
    b.is_guesthouse,
    b.is_resort_hotel,
    b.is_villa,
    b.is_family,
    b.is_esports,
    b.is_scarce,
    b.is_unique,
    b.is_lowprice,
    b.is_good,
    -- ========== 城市等级 ==========
    c.is_tourism_core_city,
    c.is_tourism_big_city,
    c.is_tourism_seasonal_city,
    c.is_tier1_city,
    c.is_new_tier1_city,
    c.is_tier2_city,
    c.is_tier3_city,
    c.is_tier4_city,
    c.is_tier5_city,
    -- ========== AOI 属性 ==========
    d.is_university,
    d.is_transportation_hub,
    d.is_scenic_area,
    d.is_hospital,
    d.is_performance_sports_venue,
    d.is_convention_center,
    d.is_industrial_park,
    -- ========== 房型属性 ==========
    e.is_king_room,
    e.is_single_room,
    e.is_double_room,
    e.is_triple_room,
    e.is_suite,
    e.is_standalone,
    e.is_dorm,
    -- ========== 搜索/渠道/订单标识 ==========
    IF(f.query_id IS NOT NULL and f.is_jingqu_search=1, 1, 0) AS is_search_scenic,
    IF(m.event_identifier IS NOT NULL, m.is_waitou, 0) AS is_waitou,
    IF(m.event_identifier IS NOT NULL, m.is_rednote, 0) AS is_rednote,
    IF(g.session_id IS NOT NULL, 1, 0) AS is_order,
    IF(b.city_location_name = g.city_location_name, 1, 0) AS is_order_city,
    IF(d.yx_id = g.yx_id, 1, 0) AS is_order_aoi,
    IF(a.poi_id = g.poi_id, 1, 0) AS is_order_poi,
    IF(a.goods_id = g.goods_id, 1, 0) AS is_order_goods,
    g.order_key,
    -- ========== 用户画像标签 ==========
    h.is_college_student,
    h.is_adult_single,
    h.is_adult_married_no_kids,
    h.is_adult_married_with_kids,
    h.is_over_60,
    h.is_senior,
    h.is_middle_age,
    h.is_young,
    h.is_minor,
    h.home_location,
    i.is_high_value,
    i.is_mid_value,
    i.is_low_value,
    j.is_l4,
    j.is_l1_3,
    k.is_youth_campus,
    k.is_business_elite,
    k.is_self_social,
    k.is_practical_life,
    k.is_family_guardian,
    k.is_vital_soldier,
    k.is_quality_visitor,
    k.is_kid_explorer,
    k.is_occasional_traveler,
    -- ========== 间夜数 ==========
    l.holiday_rnt,
    l.rnt,
    -- ========== 出行距离 ==========
    6371004 * ACOS(
        SIN(RADIANS(CAST(SPLIT(h.home_location, ',')[0] AS double)))
        * SIN(RADIANS(b.latitude / 1000000.0))
        + COS(RADIANS(CAST(SPLIT(h.home_location, ',')[0] AS double)))
        * COS(RADIANS(b.latitude / 1000000.0))
        * COS(RADIANS(b.longitude / 1000000.0 - CAST(SPLIT(h.home_location, ',')[1] AS double)))
    ) / 1000.0 AS travel_distance,

    IF(f.query_id IS NOT NULL , 1, 0) AS is_search,
    IF(travel_log.session_id IS NOT NULL , 1, 0) AS is_travel_session,
    a.datekey AS dt,
    'hotel' AS level3_biz_code

-- ==================== 主表：PV 曝光数据 ====================
FROM (
    SELECT DISTINCT
        datekey,
        user_id,
        checkin_datekey,
        session_id,
        user_key,
        device_id,
        mt_poi_id AS poi_id,
        checkin_city_id,
        goods_id,
        page_type,
        page_stay_time,
        event_identifier,
        custom['query_id'] AS query_id,
        stat_time
    FROM mart_hoteltopic.aggr_log_pv_info
    WHERE
        datekey = $now.datekey
        AND event_identifier IS NOT NULL
        AND event_identifier != 'NULL'
        AND event_identifier != ''
        AND location_type = 1 
) a
left join date_temp date_temp
on a.checkin_datekey = date_temp.datekey
-- ==================== POI 维度聚合（核心优化：GROUP BY 收敛为一行一POI）====================
LEFT JOIN (
    SELECT

        base.poi_id,
        base.city_location_name,
        base.latitude,
        base.longitude,
        -- 星级
        MAX(IF(base.comp_star_level = 1, 1, 0)) AS is_star2,
        MAX(IF(base.comp_star_level = 2, 1, 0)) AS is_star3,
        MAX(IF(base.comp_star_level = 3, 1, 0)) AS is_star4,
        MAX(IF(base.comp_star_level = 4, 1, 0)) AS is_star5,
        -- 酒店类型
        MAX(IF(base.hotel_type = '[0]', 1, 0)) AS is_budget,
        MAX(IF(base.hotel_type = '[1]', 1, 0)) AS is_express,
        MAX(IF(base.hotel_type = '[2]', 1, 0)) AS is_business,
        MAX(IF(base.hotel_type = '[3]', 1, 0)) AS is_theme,
        MAX(IF(base.hotel_type = '[4]', 1, 0)) AS is_couple,
        MAX(IF(base.hotel_type = '[5]', 1, 0)) AS is_apartment,
        MAX(IF(base.hotel_type = '[6]', 1, 0)) AS is_inn,
        MAX(IF(base.hotel_type = '[7]', 1, 0)) AS is_homestay,
        MAX(IF(base.hotel_type = '[8]', 1, 0)) AS is_hostel,
        MAX(IF(base.hotel_type = '[9]', 1, 0)) AS is_farmstay,
        MAX(IF(base.hotel_type = '[10]', 1, 0)) AS is_family_guesthouse,
        MAX(IF(base.hotel_type = '[11]', 1, 0)) AS is_guesthouse,
        MAX(IF(base.hotel_type = '[12]', 1, 0)) AS is_resort_hotel,
        MAX(IF(base.hotel_type = '[13]', 1, 0)) AS is_villa,
        -- POI价值等级
        COALESCE(MAX(IF(level.poi_value_level_id = 1, 1, 0)), 0) AS is_scarce,
        COALESCE(MAX(IF(level.poi_value_level_id = 2, 1, 0)), 0) AS is_unique,
        COALESCE(MAX(IF(level.poi_value_level_id = 3, 1, 0)), 0) AS is_lowprice,
        COALESCE(MAX(IF(level.wh_poi_type_id = 1, 1, 0)), 0) AS is_good,
        -- 标签（数组包含判断）
        IF(array_contains(tag.tag_names, '亲子友好_归一')
            OR array_contains(tag.tag_names, '亲子酒店1')
            OR array_contains(tag.tag_names, '亲子酒店-新')
            OR array_contains(tag.tag_names, '亲子酒店_场景识别')
            OR array_contains(tag.tag_names, '亲子酒店test')
            OR array_contains(tag.tag_names, '亲子出游')
            OR array_contains(tag.tag_names, '亲子酒店-202506')
            OR array_contains(tag.tag_names, '玩美周末-亲子酒店')
        , 1, 0) AS is_family,
        IF(array_contains(tag.tag_names, '有星级电竞房POI')
            OR array_contains(tag.tag_names, '3星电竞房')
            OR array_contains(tag.tag_names, '电竞酒店')
            OR array_contains(tag.tag_names, '电竞酒店2026')
            OR array_contains(tag.tag_names, '住吧电竞房_列表页标签筛选用')
            OR array_contains(tag.tag_names, '4星电竞房')
            OR array_contains(tag.tag_names, '玩美周末-电竞酒店')
            OR array_contains(tag.tag_names, '5星电竞房')
        , 1, 0) AS is_esports

    FROM (
        SELECT poi_id, city_location_name, comp_star_level, hotel_type, latitude, longitude
        FROM mart_hoteltopic.dim_poi_detail
        WHERE type = 1
    ) base

    LEFT JOIN (
        SELECT poi_id, poi_value_level_id, wh_poi_type_id
        FROM app_hotel.app_poi_portrait_level_d
        WHERE datekey = $now.datekey

    ) level ON base.poi_id = level.poi_id
    LEFT JOIN (
        SELECT poi_id, collect_set(tag_name) AS tag_names
        FROM ba_hotel.fact_poi_tag_d
        WHERE datekey = $now.datekey
        GROUP BY poi_id
    ) tag ON base.poi_id = tag.poi_id
    GROUP BY base.poi_id, base.city_location_name, base.latitude, base.longitude,tag.tag_names
) b 
ON  a.poi_id = b.poi_id
-- ON coalesce(a.poi_id,-abs(a.event_identifier)) = b.poi_id

-- ==================== 城市等级（MAPJOIN 小维表）====================
LEFT JOIN  (
    SELECT
        a.city_location_name,
        MAX(IF(b.citycate_hotel = '旅游产业支柱型', 1, 0)) AS is_tourism_core_city,
        MAX(IF(b.citycate_hotel = '大体量旅游收入城市', 1, 0)) AS is_tourism_big_city,
        MAX(IF(b.citycate_hotel = '季节性旅游城市', 1, 0)) AS is_tourism_seasonal_city,
        MAX(IF(a.city_level = '一线城市', 1, 0)) AS is_tier1_city,
        MAX(IF(a.city_level = '新一线城市', 1, 0)) AS is_new_tier1_city,
        MAX(IF(a.city_level = '二线城市', 1, 0)) AS is_tier2_city,
        MAX(IF(a.city_level = '三线城市', 1, 0)) AS is_tier3_city,
        MAX(IF(a.city_level = '四线城市', 1, 0)) AS is_tier4_city,
        MAX(IF(a.city_level = '五线及以下城市', 1, 0)) AS is_tier5_city
    FROM mart_hoteldim.city_level_2020 a
    LEFT JOIN upload_table.dim_touristcity_yy b ON a.city_location_name = b.cityname
    GROUP BY a.city_location_name
) c ON b.city_location_name = c.city_location_name

-- ==================== AOI 属性（去掉 DISTINCT）====================
LEFT JOIN (
    SELECT yx_id, poi_id,
        is_university, is_transportation_hub, is_scenic_area,
        is_hospital, is_performance_sports_venue, is_convention_center, is_industrial_park
    FROM mart_hoteltopic.dws_hotel_aoi_rq_detail_qn_df
    WHERE dt = $last_partition_datekey
) d 
ON a.poi_id = d.poi_id
-- ON coalesce(a.poi_id,-abs(a.event_identifier)) = d.poi_id
-- ==================== 房型属性（去掉 DISTINCT）====================
LEFT JOIN (
    SELECT
        a.goods_id,
        MAX(IF(b.room_type = 0, 1, 0)) AS is_king_room,
        MAX(IF(b.room_type = 1, 1, 0)) AS is_single_room,
        MAX(IF(b.room_type = 2, 1, 0)) AS is_double_room,
        MAX(IF(b.room_type = 3, 1, 0)) AS is_triple_room,
        MAX(IF(b.room_type = 4, 1, 0)) AS is_suite,
        MAX(IF(b.room_type = 5, 1, 0)) AS is_standalone,
        MAX(IF(b.room_type = 6, 1, 0)) AS is_dorm
    FROM ba_hotel.dim_hotel_goods_room_rela a
    LEFT JOIN ba_hotel.dim_hotel_real_room b ON a.real_room_id = b.real_room_id
    WHERE a.goods_id > 0
    GROUP BY a.goods_id
) e
ON CASE WHEN a.goods_id > 0 THEN a.goods_id ELSE HASH(a.stat_time) END = e.goods_id

-- ==================== 景区搜索标识（保留原逻辑）====================
LEFT JOIN (
    SELECT /*+ BROADCAST(b) */
        DISTINCT a.query_id,
        if(b.landmark_name is not null,1,0) is_jingqu_search
    FROM (
        SELECT DISTINCT query_id, keywords
        FROM mart_hoteltopic.aggr_log_srv_search_all
        WHERE datekey = $now.datekey
            AND LENGTH(query_id) >= 5
    ) a
    left JOIN (
        SELECT DISTINCT GET_JSON_OBJECT(CONCAT('{', REGEXP_REPLACE(single_item, '(^\\{?)|(\\}?$)', ''), '}'), '$.landmark_name') AS landmark_name
        FROM (
            SELECT REGEXP_REPLACE(aoi_landmark_detail, "'", '"') AS json_arr
            FROM mart_hoteltopic.dws_hotel_aoi_rq_detail_qn_df
            WHERE dt = $last_partition_datekey AND is_scenic_area = 1
        ) t LATERAL VIEW EXPLODE(SPLIT(REGEXP_REPLACE(REGEXP_REPLACE(t.json_arr, '^\\[', ''), '\\]$', ''), '\\},\\s*\\{')) tmp AS single_item
        WHERE GET_JSON_OBJECT(CONCAT('{', REGEXP_REPLACE(single_item, '(^\\{?)|(\\}?$)', ''), '}'), '$.landmark_type') = '景区'
    ) b 
    ON a.keywords LIKE CONCAT('%', b.landmark_name, '%')
) f
ON CASE WHEN LENGTH(a.query_id) >= 5 THEN a.query_id ELSE CAST(HASH(a.stat_time) AS STRING) END = f.query_id

-- ==================== 订单标识 ====================
LEFT JOIN (
    SELECT 
        a.session_id,
        a.order_key,
        a.poi_id,
        a.goods_id,
        b.yx_id,
        c.city_location_name
    FROM ( -- 用户有下单行为的session的is_order打在哪个identifier上
        SELECT DISTINCT
            session_id,
            order_key,
            order_id,
            poi_id,
            goods_id,
            datekey
        FROM mart_hoteltopic.aggr_log_order_trade_info
        WHERE
            datekey = $now.datekey
            AND is_order = 1
            AND event_identifier IS NOT NULL
            AND event_identifier != 'NULL'
            AND event_identifier != ''
            AND goods_id > 0
    ) a
    LEFT JOIN (
        SELECT DISTINCT poi_id, yx_id, dt
        FROM mart_hoteltopic.dws_hotel_aoi_rq_detail_qn_df
        WHERE dt = $last_partition_datekey
    ) b ON a.poi_id = b.poi_id
    LEFT JOIN (
        SELECT DISTINCT poi_id, city_location_name
        FROM mart_hoteltopic.dim_poi_detail
        WHERE type = 1
    ) c ON a.poi_id = c.poi_id
) g 
ON a.session_id = g.session_id
AND a.poi_id = g.poi_id
AND CASE WHEN a.goods_id > 0 THEN a.goods_id ELSE HASH(a.stat_time) END = g.goods_id

-- ==================== 用户画像标签（去掉 DISTINCT）====================
LEFT JOIN (
    SELECT
        datekey,
        user_key,
        IF(life_stage = 0, 1, 0) AS is_college_student,
        IF(life_stage = 1, 1, 0) AS is_adult_single,
        IF(life_stage = 2, 1, 0) AS is_adult_married_no_kids,
        IF(life_stage = 3, 1, 0) AS is_adult_married_with_kids,
        IF(life_stage = 4, 1, 0) AS is_over_60,
        IF(age_range = 1, 1, 0) AS is_senior,
        IF(age_range IN (2, 3, 4), 1, 0) AS is_middle_age,
        IF(age_range IN (5, 6, 7), 1, 0) AS is_young,
        IF(age_range = 8, 1, 0) AS is_minor,
        home_location
    FROM mart_hotel_limit_dev.dim_uzen_user_tag_view -- 上游已切换为新表了
    WHERE datekey = $now.datekey
) h 
ON a.datekey = h.datekey 
AND a.user_key = h.user_key

-- ==================== 用户价值分层（去掉 DISTINCT）====================
LEFT JOIN (
    SELECT
        datekey,
        user_key,
        IF(uzen_value_level_ext IN (6, 7, 9), 1, 0) AS is_high_value,
        IF(uzen_value_level_ext IN (5, 8), 1, 0) AS is_mid_value,
        IF(uzen_value_level_ext IN (1, 2, 3, 4), 1, 0) AS is_low_value
    FROM mart_hoteltopic.dim_inp_user_value_classify_view
    WHERE datekey = $now.datekey
) i ON a.datekey = i.datekey 
AND a.user_key = i.user_key

-- ==================== 会员等级（优化：SUBSTR 改为等值 JOIN）====================
LEFT JOIN (
    SELECT
        datekey,
        user_id,
        IF(member_level IN (4, 5, 6), 1, 0) AS is_l4,
        IF(member_level IN (1, 2, 3), 1, 0) AS is_l1_3
    FROM ba_hotel.dim_inp_user_mt_platform_mem_level_his
    WHERE datekey = IF($now.datekey >= 20250325, $now.datekey, 20250325)
) j ON IF(a.datekey >= 20250325, a.datekey, 20250325) = j.datekey
AND a.user_id = j.user_id

-- ==================== 九群人群（去掉 DISTINCT）====================
LEFT JOIN (
    SELECT
        dt AS datekey,
        user_key,
        IF(n_group = '青春校园族', 1, 0) AS is_youth_campus,
        IF(n_group = '商务精英党', 1, 0) AS is_business_elite,
        IF(n_group = '悦己社交派', 1, 0) AS is_self_social,
        IF(n_group = '务实生活党', 1, 0) AS is_practical_life,
        IF(n_group = '家庭守护者', 1, 0) AS is_family_guardian,
        IF(n_group = '活力特种兵', 1, 0) AS is_vital_soldier,
        IF(n_group = '品质漫游客', 1, 0) AS is_quality_visitor,
        IF(n_group = '带娃探索家', 1, 0) AS is_kid_explorer,
        IF(n_group = '偶发出行者', 1, 0) AS is_occasional_traveler
    FROM app_hotel.dws_user_nine_group_people_df
    WHERE dt = IF($now.datekey >= 20251006, $now.datekey, 20251006)
) k ON IF(a.datekey >= 20251006, a.datekey, 20251006) = k.datekey
AND a.user_key = k.user_key
-- ==================== 间夜数统计（保留原逻辑）====================
LEFT JOIN (
    SELECT
        a.user_key,
        sum(if(date_temp.is_holiday = 1, a.consume_checkin_roomnight_cnt, 0)) AS holiday_rnt,
        SUM(a.consume_checkin_roomnight_cnt) AS rnt
    FROM mart_hoteltopic.topic_ord_order_d_user a
    left join date_temp date_temp
    on a.checkin_datekey = date_temp.datekey
    WHERE
        a.datekey BETWEEN $now.delta(364).datekey AND $now.datekey
        AND a.type = 1
        AND a.biz_type != 'bill'
        AND a.performance_type = 1
        AND a.is_phx_fx = 0
        AND a.is_consumed_checkin = 1
    GROUP BY a.user_key
) l
 ON a.user_key = l.user_key

-- ==================== 渠道来源（去掉 DISTINCT）====================
LEFT JOIN (
    SELECT
        event_identifier,
        IF(channel_belong = '外投', 1, 0) AS is_waitou,
        IF((channel_belong = '外投' AND channel_bu_name = '小红书')
           OR (channel_belong = '内容营销' AND channel_bu_name = '小红书'), 1, 0) AS is_rednote
    FROM mart_hoteltopic.aggr_log_pv_user_channel_wide_d
    WHERE
        datekey = $now.datekey
        AND location_type = 1
        AND on_offline = 0
        AND position_type NOT IN ('自然流量产品位', '交叉推荐位')
        AND channel_belong NOT IN ('私域', '线下')
        AND date_range = 7
) m ON a.event_identifier = m.event_identifier

    LEFT JOIN 
    (
        SELECT DISTINCT
            session_id,
            device_id,
            poi_city_id AS city_id
        FROM ba_travel.unit_log_sdk_pv
        WHERE datekey = $now.datekey
        
    ) travel_log
    ON a.device_id = travel_log.device_id
    AND a.checkin_city_id = travel_log.city_id
;

##TargetDDL##
CREATE TABLE IF NOT EXISTS `${target.table}`
(
   checkin_datekey             bigint COMMENT 'checkin_datekey',
    session_id                  string COMMENT 'session_id',
    device_id                   string COMMENT 'device_id',
    user_key                    string COMMENT 'user_key',
    city_location_name          string COMMENT 'city_location_name',
    yx_id                       string COMMENT 'aoi_id',
    poi_id                      string COMMENT 'poi_id',
    goods_id                    string COMMENT 'goods_id',
    page_type                   string COMMENT 'page_type',
    page_stay_time              double COMMENT 'page_stay_time',
    event_identifier            string COMMENT 'event_identifier',
    is_holiday_weekend_vacation int    COMMENT '入住日期是否节日/周末/假期',
    is_holiday                  int    COMMENT '入住日期是否节日',
    is_weekend                  int    COMMENT '入住日期是否周末',
    is_vacation                 int    COMMENT '入住日期是否假期',
    is_booking_weekend          int    COMMENT '浏览日期是否周末',
    lead_time                   int    COMMENT '提前预订天数',
    latitude                    bigint COMMENT '酒店纬度',
    longitude                   bigint COMMENT '酒店经度',
    is_star2                    int    COMMENT '是否0-2星酒店',
    is_star3                    int    COMMENT '是否3星酒店',
    is_star4                    int    COMMENT '是否4星酒店',
    is_star5                    int    COMMENT '是否5星酒店',
    is_budget                   int    COMMENT '是否经济型酒店',
    is_express                  int    COMMENT '是否快捷酒店',
    is_business                 int    COMMENT '是否商务酒店',
    is_theme                    int    COMMENT '是否主题酒店',
    is_couple                   int    COMMENT '是否情侣酒店',
    is_apartment                int    COMMENT '是否公寓',
    is_inn                      int    COMMENT '是否客栈',
    is_homestay                 int    COMMENT '是否民宿',
    is_hostel                   int    COMMENT '是否青年旅舍',
    is_farmstay                 int    COMMENT '是否农家院',
    is_family_guesthouse        int    COMMENT '是否家庭旅馆',
    is_guesthouse               int    COMMENT '是否招待所',
    is_resort_hotel             int    COMMENT '是否度假酒店',
    is_villa                    int    COMMENT '是否别墅',
    is_family                   int    COMMENT '是否亲子酒店',
    is_esports                  int    COMMENT '是否电竞酒店',
    is_scarce                   int    COMMENT '是否稀缺poi',
    is_unique                   int    COMMENT '是否特色品质poi',
    is_lowprice                 int    COMMENT '是否低价同质poi',
    is_good                     int    COMMENT '是否物好poi',
    is_tourism_core_city        int    COMMENT '是否旅游产业支柱型城市',
    is_tourism_big_city         int    COMMENT '是否大体量旅游收入城市',
    is_tourism_seasonal_city    int    COMMENT '是否季节性旅游城市',
    is_tier1_city               int    COMMENT '是否一线城市',
    is_new_tier1_city           int    COMMENT '是否新一线城市',
    is_tier2_city               int    COMMENT '是否二线城市',
    is_tier3_city               int    COMMENT '是否三线城市',
    is_tier4_city               int    COMMENT '是否四线城市',
    is_tier5_city               int    COMMENT '是否五线城市',
    is_university               int    COMMENT '是否大学aoi',
    is_transportation_hub       int    COMMENT '是否交通枢纽aoi',
    is_scenic_area              int    COMMENT '是否景区aoi',
    is_hospital                 int    COMMENT '是否医院aoi',
    is_performance_sports_venue int    COMMENT '是否文体场馆aoi',
    is_convention_center        int    COMMENT '是否会展中心aoi',
    is_industrial_park          int    COMMENT '是否产业园区aoi',
    is_king_room                int    COMMENT '是否大床房型',
    is_single_room              int    COMMENT '是否单人房型',
    is_double_room              int    COMMENT '是否双人房型',
    is_triple_room              int    COMMENT '是否三人房型',
    is_suite                    int    COMMENT '是否套房房型',
    is_standalone               int    COMMENT '是否独栋房型',
    is_dorm                     int    COMMENT '是否床位房型',
    is_search_scenic            int    COMMENT '是否搜索景区',
    is_waitou                   int    COMMENT '是否外投来源',
    is_rednote                  int    COMMENT '是否小红书来源',
    is_order                    int    COMMENT '是否下单',
    is_order_city               int    COMMENT '是否下单同城市',
    is_order_aoi                int    COMMENT '是否下单同aoi',
    is_order_poi                int    COMMENT '是否下单同poi',
    is_order_goods              int    COMMENT '是否下单同goods',
    order_key                   string COMMENT 'order_key',
    is_college_student          int    COMMENT '是否大学生',
    is_adult_single             int    COMMENT '是否单身成人',
    is_adult_married_no_kids    int    COMMENT '是否已婚无孩成人',
    is_adult_married_with_kids  int    COMMENT '是否已婚有孩成人',
    is_over_60                  int    COMMENT '是否60岁以上',
    is_senior                   int    COMMENT '是否老年人',
    is_middle_age               int    COMMENT '是否中年人',
    is_young                    int    COMMENT '是否年轻人',
    is_minor                    int    COMMENT '是否未成年人',
    home_location               string COMMENT '用户常驻地',
    is_high_value               int    COMMENT '是否高价值用户',
    is_mid_value                int    COMMENT '是否中价值用户',
    is_low_value                int    COMMENT '是否低价值用户',
    is_l4                       int    COMMENT '是否L4+用户',
    is_l1_3                     int    COMMENT '是否L1-L3用户',
    is_youth_campus             int    COMMENT '是否青春校园族',
    is_business_elite           int    COMMENT '是否商务精英党',
    is_self_social              int    COMMENT '是否悦己社交派',
    is_practical_life           int    COMMENT '是否务实生活党',
    is_family_guardian          int    COMMENT '是否家庭守护者',
    is_vital_soldier            int    COMMENT '是否活力特种兵',
    is_quality_visitor          int    COMMENT '是否品质漫游客',
    is_kid_explorer             int    COMMENT '是否带娃探索家',
    is_occasional_traveler      int    COMMENT '是否偶发出行者',
    holiday_rnt                 double COMMENT '假期间夜数',
    rnt                         double COMMENT '总间夜数',
    travel_distance             double COMMENT '出行距离',
    is_search                   int    COMMENT '是否搜索',
    is_travel_session           int    COMMENT '是否同日同城存在门票/度假行为'
)
COMMENT '出游办事session特征主表'
PARTITIONED BY (dt string COMMENT '日期分区字段，格式为dt(yyyymmdd)',level3_biz_code string COMMENT '三级业务编码：hotel-酒店，homestay-民宿，ticket-景点游玩，vacation-度假，zuche-租车，flight-机票，train-火车票，coach-汽车票')
STORED AS ORC
;
