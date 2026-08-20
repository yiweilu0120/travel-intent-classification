# Training Samples

## 1. reviewtags Source

Only `reviewtags` needs to be constrained here; `body` does not need to be constrained. This is inherently to exclude `reviewtags`/`body` conflicts.

Time window: 20260316–20260610

| Leisure Travel / Necessary-purpose | Sample Filter (Broad Scope) | Sample Filter (Narrow Scope) | Notes |
|---|---|---|---|
| Necessary-purpose - Business Trip | `reviewtags LIKE '%"TravelType","values":["出差"%'`<br>`AND body NOT LIKE '%游玩%'`<br>`AND body NOT LIKE '%游览%'`<br>`AND body NOT LIKE '%旅游%'`<br>`AND body NOT LIKE '%旅行%'`<br>`AND body NOT LIKE '%度假%'`<br>`AND body NOT LIKE '%来玩%'`<br>`AND body NOT LIKE '%观光%'`<br>`AND body NOT LIKE '%景区%'`<br>`AND body NOT LIKE '%景点%'`<br>`AND body NOT LIKE '%背包客%'` | `reviewtags LIKE '%"TravelType","values":["出差"%'`<br>`AND body NOT LIKE '%游玩%'`<br>`AND body NOT LIKE '%游览%'`<br>`AND body NOT LIKE '%旅游%'`<br>`AND body NOT LIKE '%旅行%'`<br>`AND body NOT LIKE '%度假%'`<br>`AND body NOT LIKE '%来玩%'`<br>`AND body NOT LIKE '%观光%'`<br>`AND body NOT LIKE '%景区%'`<br>`AND body NOT LIKE '%景点%'`<br>`AND body NOT LIKE '%背包客%'`<br>`AND body NOT LIKE '%玩%'`<br>`AND (body LIKE '%出差%'`<br>`OR body LIKE '%办事%'`<br>`OR body LIKE '%办公%'`<br>`OR body LIKE '%商务%'`<br>`OR body LIKE '%客户%'`<br>`OR body LIKE '%培训%'`<br>`OR body LIKE '%开会%')` | Review body indicates leisure travel, but the user selected business trip |
| Leisure Travel - Couple / Family Parent-child / Friends | `(` <br>`reviewtags LIKE '%"TravelType","values":["情侣"%'`<br>`OR reviewtags LIKE '%"TravelType","values":["家庭亲子"%'`<br>`OR reviewtags LIKE '%"TravelType","values":["朋友"%'`<br>`)`<br>`AND body NOT LIKE '%出差%'`<br>`AND body NOT LIKE '%办事%'`<br>`AND body NOT LIKE '%办公%'`<br>`AND body NOT LIKE '%考试%'`<br>`AND body NOT LIKE '%陪考%'`<br>`AND body NOT LIKE '%高考%'`<br>`AND body NOT LIKE '%国考%'`<br>`AND body NOT LIKE '%省考%'`<br>`AND body NOT LIKE '%考研%'`<br>`AND body NOT LIKE '%面试%'`<br>`AND body NOT LIKE '%医院%'`<br>`AND body NOT LIKE '%看病%'`<br>`AND body NOT LIKE '%就诊%'`<br>`AND body NOT LIKE '%住院%'`<br>`AND body NOT LIKE '%陪护%'`<br>`AND body NOT LIKE '%陪床%'`<br>`AND body NOT LIKE '%办事%'`<br>`AND body NOT LIKE '%参加婚礼%'`<br>`AND body NOT LIKE '%办婚礼%'` | `(`<br>`reviewtags LIKE '%"TravelType","values":["情侣"%'`<br>`OR reviewtags LIKE '%"TravelType","values":["家庭亲子"%'`<br>`OR reviewtags LIKE '%"TravelType","values":["朋友"%'`<br>`)`<br>`AND body NOT LIKE '%出差%'`<br>`AND body NOT LIKE '%办事%'`<br>`AND body NOT LIKE '%办公%'`<br>`AND body NOT LIKE '%考试%'`<br>`AND body NOT LIKE '%陪考%'`<br>`AND body NOT LIKE '%高考%'`<br>`AND body NOT LIKE '%国考%'`<br>`AND body NOT LIKE '%省考%'`<br>`AND body NOT LIKE '%考研%'`<br>`AND body NOT LIKE '%面试%'`<br>`AND body NOT LIKE '%医院%'`<br>`AND body NOT LIKE '%看病%'`<br>`AND body NOT LIKE '%就诊%'`<br>`AND body NOT LIKE '%住院%'`<br>`AND body NOT LIKE '%陪护%'`<br>`AND body NOT LIKE '%陪床%'`<br>`AND body NOT LIKE '%办事%'`<br>`AND body NOT LIKE '%参加婚礼%'`<br>`AND body NOT LIKE '%办婚礼%'`<br>`AND (body LIKE '%玩%'`<br>`OR body LIKE '%旅游%'`<br>`OR body LIKE '%旅行%'`<br>`OR body LIKE '%度假%'`<br>`OR body LIKE '%观光%'`<br>`OR body LIKE '%景点%'`<br>`OR body LIKE '%景区%'`<br>`OR body LIKE '%游览%'`<br>`)` | ① Review body describes necessary-purpose scenarios such as accompanying a child to an exam or visiting a doctor, but the user selected family parent-child; ② Review body describes a business trip scenario, but the user selected friends |

---

## 2. body Source

Only `body`-sourced samples need invalid review filtering:

```sql
AND body IS NOT NULL AND body != '' AND LENGTH(body) BETWEEN 10 AND 500
```

Time window: 20260316–20260630

| Leisure Travel / Necessary-purpose | Sample Filter (Broad Scope) | Sample Filter (Narrow Scope) | Notes |
|---|---|---|---|
| Necessary-purpose - Exams & Interviews | `(body LIKE '%考试%'`<br>`OR body LIKE '%考研%'`<br>`OR body LIKE '%国考%'`<br>`OR body LIKE '%省考%'`<br>`OR body LIKE '%高考%'`<br>`OR body LIKE '%陪考%'`<br>`OR body LIKE '%考场%'`<br>`OR body LIKE '%笔试%'`<br>`OR body LIKE '%准考证%'`<br>`OR body LIKE '%面试%')`<br>`AND body NOT LIKE '%高考结束%'`<br>`AND body NOT LIKE '%结束高考%'`<br>`AND h.body NOT LIKE '%考试结束%'`<br>`AND h.body NOT LIKE '%结束考试%'`<br>`AND body NOT LIKE '%考完%'`<br>`AND body NOT LIKE '%考后%'`<br>`AND h.body NOT LIKE '%旅行%'`<br>`AND h.body NOT LIKE '%旅游%'`<br>`AND h.body NOT LIKE '%玩%'` | `(body LIKE '%考试%'`<br>`OR body LIKE '%笔试%'`<br>`OR body LIKE '%准考证%'`<br>`OR body LIKE '%陪考%'`<br>`OR body LIKE '%考场%'`<br>`OR body LIKE '%面试%')`<br>`AND h.body NOT LIKE '%考试结束%'`<br>`AND h.body NOT LIKE '%结束考试%'`<br>`AND body NOT LIKE '%考完%'`<br>`AND body NOT LIKE '%考后%'`<br>`AND h.body NOT LIKE '%旅行%'`<br>`AND h.body NOT LIKE '%旅游%'`<br>`AND h.body NOT LIKE '%玩%'` | Review body describes going out to play after the college entrance exam / after the exam ends |
| Necessary-purpose - Medical Visits | `body LIKE '%来医院%'`<br>`OR body LIKE '%去医院%'`<br>`OR body LIKE '%在医院%'`<br>`OR body LIKE '%看病%'`<br>`OR body LIKE '%就诊%'`<br>`OR body LIKE '%住院%'`<br>`OR body LIKE '%挂号%'`<br>`OR body LIKE '%陪护%'`<br>`OR body LIKE '%陪床%'`<br>`OR body LIKE '%复查%'`<br>`OR body LIKE '%体检%'` | `body LIKE '%来医院%'`<br>`OR body LIKE '%去医院%'`<br>`OR body LIKE '%在医院%'`<br>`OR body LIKE '%看病%'`<br>`OR body LIKE '%就诊%'`<br>`OR body LIKE '%住院%'`<br>`OR body LIKE '%挂号%'`<br>`OR body LIKE '%陪护%'`<br>`OR body LIKE '%陪床%'`<br>`OR body LIKE '%复查%'`<br>`OR body LIKE '%体检%'` | Review body contains many purely location-based hospital descriptions that are not medical-visit scenarios |
| Leisure Travel - Concerts & Music Festivals | `body LIKE '%演唱会%'`<br>`OR body LIKE '%音乐节%'` | `body LIKE '%演唱会%'`<br>`OR body LIKE '%音乐节%'` | |

---

## 3. Conflict Handling

When a single `session_id` contains both a Leisure Travel STP label and a Necessary-purpose STP label, that `session_id` is discarded.

When a single `session_id` has multiple records but with consistent STP labels, any one record may be taken at random.

---

## 4. Sampling Rules

- All `body`-sourced samples are retained (the volume is already relatively small). Sample trimming is performed on the `reviewtags` source.

- `checkin_datekey` uses a hard constraint, split by public holidays, weekends, and weekdays. The target Leisure Travel share is 68% on public holidays, 60% on weekends, and 32% on weekdays.

- `datekey` uses a soft constraint (upper bound only; trimming happens only when the cap is exceeded, otherwise all samples are kept): Leisure Travel share ≤ 75% on public holidays, ≤ 65% on weekends, ≤ 40% on weekdays.

---

```sql
-- ============================================================
-- STP Training Sample Sampling (v3)
-- Based on wiki: https://km.sankuai.com/collabpage/2771389860
-- Date range: reviewtags 20260316-20260610, body 20260316-20260630
-- Conflict handling: session_id level; sessions with both LeisureTravel and NecessaryPurpose labels are discarded
-- Sampling: body fully retained; reviewtags trimmed by checkin_datekey hard constraint + datekey soft constraint
-- ============================================================

WITH reviewtags_base AS (
    SELECT
        g.datekey, g.order_id, g.user_id, h.review_id, h.body,
        m.session_id, g.checkin_datekey,
        'reviewtags' AS sample_source,
        CASE
            WHEN h.travel_type LIKE '%"TravelType","values":["出差"%'
                THEN 'NecessaryPurpose-BusinessTrip'
            WHEN h.travel_type LIKE '%"TravelType","values":["情侣"%'
                THEN 'LeisureTravel-Couple'
            WHEN h.travel_type LIKE '%"TravelType","values":["家庭亲子"%'
                THEN 'LeisureTravel-FamilyParentChild'
            WHEN h.travel_type LIKE '%"TravelType","values":["朋友"%'
                THEN 'LeisureTravel-Friends'
            ELSE NULL
        END AS scene_label,
        CASE
            WHEN h.travel_type LIKE '%"TravelType","values":["出差"%'
                AND h.body NOT LIKE '%游玩%' AND h.body NOT LIKE '%游览%'
                AND h.body NOT LIKE '%旅游%' AND h.body NOT LIKE '%旅行%'
                AND h.body NOT LIKE '%度假%' AND h.body NOT LIKE '%来玩%'
                AND h.body NOT LIKE '%观光%' AND h.body NOT LIKE '%景区%'
                AND h.body NOT LIKE '%景点%' AND h.body NOT LIKE '%背包客%'
                THEN 'NecessaryPurpose'
            WHEN (
                h.travel_type LIKE '%"TravelType","values":["情侣"%'
                OR h.travel_type LIKE '%"TravelType","values":["家庭亲子"%'
                OR h.travel_type LIKE '%"TravelType","values":["朋友"%'
            )
            AND h.body NOT LIKE '%出差%' AND h.body NOT LIKE '%办事%'
            AND h.body NOT LIKE '%办公%' AND h.body NOT LIKE '%考试%'
            AND h.body NOT LIKE '%陪考%' AND h.body NOT LIKE '%高考%'
            AND h.body NOT LIKE '%国考%' AND h.body NOT LIKE '%省考%'
            AND h.body NOT LIKE '%考研%' AND h.body NOT LIKE '%面试%'
            AND h.body NOT LIKE '%医院%' AND h.body NOT LIKE '%看病%'
            AND h.body NOT LIKE '%就诊%' AND h.body NOT LIKE '%住院%'
            AND h.body NOT LIKE '%陪护%' AND h.body NOT LIKE '%陪床%'
            AND h.body NOT LIKE '%参加婚礼%' AND h.body NOT LIKE '%办婚礼%'
            THEN 'LeisureTravel'
            ELSE NULL
        END AS stp_label
    FROM (
        SELECT DISTINCT datekey, order_id, user_id, checkin_datekey
        FROM mart_hoteltopic.topic_ord_order_d_user
        WHERE datekey BETWEEN 20260316 AND 20260610
        AND type = 1 AND biz_type != 'bill'
        AND performance_type = 1 AND is_phx_fx = 0 AND is_ordered = 1
    ) g
    LEFT JOIN (
        SELECT DISTINCT order_id, session_id
        FROM mart_hoteltopic.aggr_log_order_trade_info
        WHERE datekey BETWEEN 20260316 AND 20260610
        AND is_order = 1 AND event_identifier IS NOT NULL
        AND event_identifier != 'NULL' AND event_identifier != ''
    ) m ON g.order_id = m.order_id
    INNER JOIN (
        SELECT DISTINCT review_id, order_id, body, reviewtags AS travel_type
        FROM mart_hoteltopic.aggr_opt_ugc_review
        WHERE datekey BETWEEN 20260316 AND 20260623
        AND is_real_review = 1 AND is_risk_review = 0
        AND reviewtags IS NOT NULL
        AND (
            reviewtags LIKE '%"TravelType","values":["出差"%'
            OR reviewtags LIKE '%"TravelType","values":["情侣"%'
            OR reviewtags LIKE '%"TravelType","values":["家庭亲子"%'
            OR reviewtags LIKE '%"TravelType","values":["朋友"%'
        )
    ) h ON g.order_id = h.order_id
    WHERE m.session_id IS NOT NULL
),

reviewtags_sample AS (
    SELECT * FROM reviewtags_base
    WHERE stp_label IS NOT NULL
),

body_base AS (
    SELECT
        g.datekey, g.order_id, g.user_id, h.review_id, h.body,
        m.session_id, g.checkin_datekey,
        'body' AS sample_source,
        CASE
            WHEN (
                h.body LIKE '%考试%' OR h.body LIKE '%考研%'
                OR h.body LIKE '%国考%' OR h.body LIKE '%省考%'
                OR h.body LIKE '%高考%' OR h.body LIKE '%陪考%'
                OR h.body LIKE '%考场%' OR h.body LIKE '%笔试%'
                OR h.body LIKE '%准考证%' OR h.body LIKE '%面试%'
            )
            AND (
                h.body NOT LIKE '%高考结束%'
                AND h.body NOT LIKE '%结束高考%'
                AND h.body NOT LIKE '%考试结束%'
                AND h.body NOT LIKE '%结束考试%'
                AND h.body NOT LIKE '%考完%'
                AND h.body NOT LIKE '%考后%'
                AND h.body NOT LIKE '%旅行%'
                AND h.body NOT LIKE '%旅游%'
                AND h.body NOT LIKE '%玩%'
            )
            THEN 'ExamInterview'
            WHEN (
                h.body LIKE '%来医院%' OR h.body LIKE '%去医院%'
                OR h.body LIKE '%在医院%' OR h.body LIKE '%看病%'
                OR h.body LIKE '%就诊%' OR h.body LIKE '%住院%'
                OR h.body LIKE '%挂号%' OR h.body LIKE '%陪护%'
                OR h.body LIKE '%陪床%' OR h.body LIKE '%复查%'
                OR h.body LIKE '%体检%'
            )
            THEN 'MedicalVisit'
            WHEN (
                h.body LIKE '%演唱会%' OR h.body LIKE '%音乐节%'
            )
            THEN 'ConcertMusicFestival'
            ELSE NULL
        END AS scene_label,
        CASE
            WHEN (
                h.body LIKE '%考试%' OR h.body LIKE '%考研%'
                OR h.body LIKE '%国考%' OR h.body LIKE '%省考%'
                OR h.body LIKE '%高考%' OR h.body LIKE '%陪考%'
                OR h.body LIKE '%考场%' OR h.body LIKE '%笔试%'
                OR h.body LIKE '%准考证%' OR h.body LIKE '%面试%'
            )
            AND (
                h.body NOT LIKE '%高考结束%'
                AND h.body NOT LIKE '%结束高考%'
                AND h.body NOT LIKE '%考试结束%'
                AND h.body NOT LIKE '%结束考试%'
                AND h.body NOT LIKE '%考完%'
                AND h.body NOT LIKE '%考后%'
                AND h.body NOT LIKE '%旅行%'
                AND h.body NOT LIKE '%旅游%'
                AND h.body NOT LIKE '%玩%'
            )
            THEN 'NecessaryPurpose'
            WHEN (
                h.body LIKE '%来医院%' OR h.body LIKE '%去医院%'
                OR h.body LIKE '%在医院%' OR h.body LIKE '%看病%'
                OR h.body LIKE '%就诊%' OR h.body LIKE '%住院%'
                OR h.body LIKE '%挂号%' OR h.body LIKE '%陪护%'
                OR h.body LIKE '%陪床%' OR h.body LIKE '%复查%'
                OR h.body LIKE '%体检%'
            )
            THEN 'NecessaryPurpose'
            WHEN (
                h.body LIKE '%演唱会%' OR h.body LIKE '%音乐节%'
            )
            THEN 'LeisureTravel'
            ELSE NULL
        END AS stp_label
    FROM (
        SELECT DISTINCT datekey, order_id, user_id, checkin_datekey
        FROM mart_hoteltopic.topic_ord_order_d_user
        WHERE datekey BETWEEN 20260316 AND 20260630
        AND type = 1 AND biz_type != 'bill'
        AND performance_type = 1 AND is_phx_fx = 0 AND is_ordered = 1
    ) g
    LEFT JOIN (
        SELECT DISTINCT order_id, session_id
        FROM mart_hoteltopic.aggr_log_order_trade_info
        WHERE datekey BETWEEN 20260316 AND 20260630
        AND is_order = 1 AND event_identifier IS NOT NULL
        AND event_identifier != 'NULL' AND event_identifier != ''
    ) m ON g.order_id = m.order_id
    INNER JOIN (
        SELECT DISTINCT review_id, order_id, body
        FROM mart_hoteltopic.aggr_opt_ugc_review
        WHERE datekey BETWEEN 20260316 AND 20260630
        AND is_real_review = 1 AND is_risk_review = 0
        AND body IS NOT NULL AND body != ''
        AND LENGTH(body) BETWEEN 10 AND 500
    ) h ON g.order_id = h.order_id
    WHERE m.session_id IS NOT NULL
),

body_sample AS (
    SELECT * FROM body_base
    WHERE stp_label IS NOT NULL
),

-- Date type tagging
all_samples AS (
    SELECT r.*,
        CASE
            WHEN fd1.datekey IS NOT NULL THEN 'Holiday'
            WHEN d1.day_of_week IN (5, 6) THEN 'Weekend'
            ELSE 'Weekday'
        END AS checkin_date_type,
        CASE
            WHEN fd2.datekey IS NOT NULL THEN 'Holiday'
            WHEN d2.day_of_week IN (5, 6) THEN 'Weekend'
            ELSE 'Weekday'
        END AS order_date_type
    FROM (
        SELECT * FROM reviewtags_sample
        UNION ALL
        SELECT * FROM body_sample
    ) r
    LEFT JOIN ba_hotel.dim_date d1 ON r.checkin_datekey = d1.datekey
    LEFT JOIN upload_table.hotel_festival_datekey fd1 ON r.checkin_datekey = fd1.datekey
    LEFT JOIN ba_hotel.dim_date d2 ON r.datekey = d2.datekey
    LEFT JOIN upload_table.hotel_festival_datekey fd2 ON r.datekey = fd2.datekey
),

-- Conflict detection: discard when both LeisureTravel and NecessaryPurpose labels exist under the same session_id
conflict_sessions AS (
    SELECT session_id
    FROM all_samples
    GROUP BY session_id
    HAVING COUNT(DISTINCT stp_label) > 1
),

-- After conflict removal, deduplicate by session_id, reviewtags takes priority
valid_samples AS (
    SELECT
        a.*,
        ROW_NUMBER() OVER (
            PARTITION BY a.session_id
            ORDER BY CASE WHEN a.sample_source = 'reviewtags' THEN 0 ELSE 1 END
        ) AS rn
    FROM all_samples a
    WHERE a.session_id NOT IN (SELECT session_id FROM conflict_sessions)
),

final_base AS (
    SELECT * FROM valid_samples WHERE rn = 1
),

-- ============================================================
-- Round 1: Hard-constraint sampling by checkin_date_type
-- NecessaryPurpose fully retained; LeisureTravel trimmed to target ratio
-- ============================================================

checkin_necessary AS (
    SELECT checkin_date_type, COUNT(*) AS cnt
    FROM final_base
    WHERE stp_label = 'NecessaryPurpose'
    GROUP BY checkin_date_type
),

checkin_travel_target AS (
    SELECT
        checkin_date_type, cnt AS necessary_cnt,
        CASE checkin_date_type
            WHEN 'Holiday'  THEN CAST(ROUND(cnt * 0.68 / 0.32) AS BIGINT)
            WHEN 'Weekend'  THEN CAST(ROUND(cnt * 0.60 / 0.40) AS BIGINT)
            WHEN 'Weekday'  THEN CAST(ROUND(cnt * 0.32 / 0.68) AS BIGINT)
        END AS travel_take
    FROM checkin_necessary
),

checkin_ranked AS (
    SELECT f.*,
        ROW_NUMBER() OVER (
            PARTITION BY f.checkin_date_type, f.stp_label
            ORDER BY RAND()
        ) AS rn_checkin
    FROM final_base f
),

round1 AS (
    SELECT * FROM checkin_ranked WHERE stp_label = 'NecessaryPurpose'
    UNION ALL
    SELECT c.* FROM checkin_ranked c
    JOIN checkin_travel_target t ON c.checkin_date_type = t.checkin_date_type
    WHERE c.stp_label = 'LeisureTravel' AND c.rn_checkin <= t.travel_take
),

-- ============================================================
-- Round 2: Soft-constraint (upper-bound) sampling by order_date_type
-- LeisureTravel is trimmed only when its share exceeds the cap; otherwise all retained
-- ============================================================

order_stats AS (
    SELECT
        order_date_type,
        COUNT(*) AS total,
        COUNT(CASE WHEN stp_label = 'LeisureTravel' THEN 1 END) AS travel_cnt,
        CASE order_date_type
            WHEN 'Holiday'  THEN 0.75
            WHEN 'Weekend'  THEN 0.65
            WHEN 'Weekday'  THEN 0.40
        END AS travel_cap
    FROM round1
    GROUP BY order_date_type
),

order_travel_target AS (
    SELECT
        order_date_type,
        total,
        travel_cnt,
        travel_cap,
        -- LeisureTravel retention = min(current travel count, upper bound)
        CAST(ROUND(total * travel_cap) AS BIGINT) AS travel_keep
    FROM order_stats
),

order_ranked AS (
    SELECT r.*,
        ROW_NUMBER() OVER (
            PARTITION BY r.order_date_type, r.stp_label
            ORDER BY RAND()
        ) AS rn_order
    FROM round1 r
)

-- ============================================================
-- Final output
-- ============================================================
SELECT
    o.sample_source, o.scene_label, o.stp_label,
    o.order_id, o.session_id, o.checkin_datekey, o.datekey,
    o.checkin_date_type, o.order_date_type
FROM order_ranked o
LEFT JOIN order_travel_target t ON o.order_date_type = t.order_date_type
WHERE
    o.stp_label = 'NecessaryPurpose'
    OR (o.stp_label = 'LeisureTravel' AND o.rn_order <= t.travel_keep);
```

```sql
-- ============================================================
-- STP Training Sample Sampling (v3 Narrow Scope v2)
-- Based on wiki: https://km.sankuai.com/collabpage/2771389860
-- Date range: reviewtags 20260316-20260610, body 20260316-20260630
-- Conflict handling: session_id level; sessions with both LeisureTravel and NecessaryPurpose labels are discarded
-- Sampling: reviewtags trimmed by checkin_datekey hard constraint + datekey soft constraint
--           body NecessaryPurpose samples trimmed by business-trip ratio: BusinessTrip:ExamInterview = 5:1, BusinessTrip:MedicalVisit = 8:1
-- ============================================================

WITH reviewtags_base AS (
    SELECT
        g.datekey, g.order_id, g.user_id, h.review_id, h.body,
        m.session_id, g.checkin_datekey,
        'reviewtags' AS sample_source,
        CASE
            WHEN h.travel_type LIKE '%"TravelType","values":["出差"%'
                THEN 'NecessaryPurpose-BusinessTrip'
            WHEN h.travel_type LIKE '%"TravelType","values":["情侣"%'
                THEN 'LeisureTravel-Couple'
            WHEN h.travel_type LIKE '%"TravelType","values":["家庭亲子"%'
                THEN 'LeisureTravel-FamilyParentChild'
            WHEN h.travel_type LIKE '%"TravelType","values":["朋友"%'
                THEN 'LeisureTravel-Friends'
            ELSE NULL
        END AS scene_label,
        CASE
            WHEN h.travel_type LIKE '%"TravelType","values":["出差"%'
                AND h.body NOT LIKE '%游玩%' AND h.body NOT LIKE '%游览%'
                AND h.body NOT LIKE '%旅游%' AND h.body NOT LIKE '%旅行%'
                AND h.body NOT LIKE '%度假%' AND h.body NOT LIKE '%来玩%'
                AND h.body NOT LIKE '%观光%' AND h.body NOT LIKE '%景区%'
                AND h.body NOT LIKE '%景点%' AND h.body NOT LIKE '%背包客%'
                AND h.body NOT LIKE '%玩%'
                AND (h.body LIKE '%出差%' OR h.body LIKE '%办事%' OR h.body LIKE '%办公%'
                    OR h.body LIKE '%商务%' OR h.body LIKE '%客户%' OR h.body LIKE '%培训%' OR h.body LIKE '%开会%')
                THEN 'NecessaryPurpose'
            WHEN (
                h.travel_type LIKE '%"TravelType","values":["情侣"%'
                OR h.travel_type LIKE '%"TravelType","values":["家庭亲子"%'
                OR h.travel_type LIKE '%"TravelType","values":["朋友"%'
            )
            AND h.body NOT LIKE '%出差%' AND h.body NOT LIKE '%办事%'
            AND h.body NOT LIKE '%办公%' AND h.body NOT LIKE '%考试%'
            AND h.body NOT LIKE '%陪考%' AND h.body NOT LIKE '%高考%'
            AND h.body NOT LIKE '%国考%' AND h.body NOT LIKE '%省考%'
            AND h.body NOT LIKE '%考研%' AND h.body NOT LIKE '%面试%'
            AND h.body NOT LIKE '%医院%' AND h.body NOT LIKE '%看病%'
            AND h.body NOT LIKE '%就诊%' AND h.body NOT LIKE '%住院%'
            AND h.body NOT LIKE '%陪护%' AND h.body NOT LIKE '%陪床%'
            AND h.body NOT LIKE '%参加婚礼%' AND h.body NOT LIKE '%办婚礼%'
            AND (h.body LIKE '%玩%' OR h.body LIKE '%旅游%' OR h.body LIKE '%旅行%'
                OR h.body LIKE '%度假%' OR h.body LIKE '%观光%' OR h.body LIKE '%景点%'
                OR h.body LIKE '%景区%' OR h.body LIKE '%游览%')
            THEN 'LeisureTravel'
            ELSE NULL
        END AS stp_label
    FROM (
        SELECT DISTINCT datekey, order_id, user_id, checkin_datekey
        FROM mart_hoteltopic.topic_ord_order_d_user
        WHERE datekey BETWEEN 20260316 AND 20260610
        AND type = 1 AND biz_type != 'bill'
        AND performance_type = 1 AND is_phx_fx = 0 AND is_ordered = 1
    ) g
    LEFT JOIN (
        SELECT DISTINCT order_id, session_id
        FROM mart_hoteltopic.aggr_log_order_trade_info
        WHERE datekey BETWEEN 20260316 AND 20260610
        AND is_order = 1 AND event_identifier IS NOT NULL
        AND event_identifier != 'NULL' AND event_identifier != ''
    ) m ON g.order_id = m.order_id
    INNER JOIN (
        SELECT DISTINCT review_id, order_id, body, reviewtags AS travel_type
        FROM mart_hoteltopic.aggr_opt_ugc_review
        WHERE datekey BETWEEN 20260316 AND 20260623
        AND is_real_review = 1 AND is_risk_review = 0
        AND reviewtags IS NOT NULL
        AND (
            reviewtags LIKE '%"TravelType","values":["出差"%'
            OR reviewtags LIKE '%"TravelType","values":["情侣"%'
            OR reviewtags LIKE '%"TravelType","values":["家庭亲子"%'
            OR reviewtags LIKE '%"TravelType","values":["朋友"%'
        )
    ) h ON g.order_id = h.order_id
    WHERE m.session_id IS NOT NULL
),

reviewtags_sample AS (
    SELECT * FROM reviewtags_base
    WHERE stp_label IS NOT NULL
),

body_base AS (
    SELECT
        g.datekey, g.order_id, g.user_id, h.review_id, h.body,
        m.session_id, g.checkin_datekey,
        'body' AS sample_source,
        CASE
            WHEN (
                h.body LIKE '%考试%' OR h.body LIKE '%笔试%'
                OR h.body LIKE '%准考证%' OR h.body LIKE '%陪考%'
                OR h.body LIKE '%考场%' OR h.body LIKE '%面试%'
            )
            AND (
                h.body NOT LIKE '%考试结束%'
                AND h.body NOT LIKE '%结束考试%'
                AND h.body NOT LIKE '%考完%'
                AND h.body NOT LIKE '%考后%'
                AND h.body NOT LIKE '%旅行%'
                AND h.body NOT LIKE '%旅游%'
                AND h.body NOT LIKE '%玩%'
            )
            THEN 'ExamInterview'
            WHEN (
                h.body LIKE '%来医院%' OR h.body LIKE '%去医院%'
                OR h.body LIKE '%在医院%' OR h.body LIKE '%看病%'
                OR h.body LIKE '%就诊%' OR h.body LIKE '%住院%'
                OR h.body LIKE '%挂号%' OR h.body LIKE '%陪护%'
                OR h.body LIKE '%陪床%' OR h.body LIKE '%复查%'
                OR h.body LIKE '%体检%'
            )
            THEN 'MedicalVisit'
            WHEN (
                h.body LIKE '%演唱会%' OR h.body LIKE '%音乐节%'
            )
            THEN 'ConcertMusicFestival'
            ELSE NULL
        END AS scene_label,
        CASE
            WHEN (
                h.body LIKE '%考试%' OR h.body LIKE '%笔试%'
                OR h.body LIKE '%准考证%' OR h.body LIKE '%陪考%'
                OR h.body LIKE '%考场%' OR h.body LIKE '%面试%'
            )
            AND (
                h.body NOT LIKE '%考试结束%'
                AND h.body NOT LIKE '%结束考试%'
                AND h.body NOT LIKE '%考完%'
                AND h.body NOT LIKE '%考后%'
                AND h.body NOT LIKE '%旅行%'
                AND h.body NOT LIKE '%旅游%'
                AND h.body NOT LIKE '%玩%'
            )
            THEN 'NecessaryPurpose'
            WHEN (
                h.body LIKE '%来医院%' OR h.body LIKE '%去医院%'
                OR h.body LIKE '%在医院%' OR h.body LIKE '%看病%'
                OR h.body LIKE '%就诊%' OR h.body LIKE '%住院%'
                OR h.body LIKE '%挂号%' OR h.body LIKE '%陪护%'
                OR h.body LIKE '%陪床%' OR h.body LIKE '%复查%'
                OR h.body LIKE '%体检%'
            )
            THEN 'NecessaryPurpose'
            WHEN (
                h.body LIKE '%演唱会%' OR h.body LIKE '%音乐节%'
            )
            THEN 'LeisureTravel'
            ELSE NULL
        END AS stp_label
    FROM (
        SELECT DISTINCT datekey, order_id, user_id, checkin_datekey
        FROM mart_hoteltopic.topic_ord_order_d_user
        WHERE datekey BETWEEN 20260316 AND 20260630
        AND type = 1 AND biz_type != 'bill'
        AND performance_type = 1 AND is_phx_fx = 0 AND is_ordered = 1
    ) g
    LEFT JOIN (
        SELECT DISTINCT order_id, session_id
        FROM mart_hoteltopic.aggr_log_order_trade_info
        WHERE datekey BETWEEN 20260316 AND 20260630
        AND is_order = 1 AND event_identifier IS NOT NULL
        AND event_identifier != 'NULL' AND event_identifier != ''
    ) m ON g.order_id = m.order_id
    INNER JOIN (
        SELECT DISTINCT review_id, order_id, body
        FROM mart_hoteltopic.aggr_opt_ugc_review
        WHERE datekey BETWEEN 20260316 AND 20260630
        AND is_real_review = 1 AND is_risk_review = 0
        AND body IS NOT NULL AND body != ''
        AND LENGTH(body) BETWEEN 10 AND 500
    ) h ON g.order_id = h.order_id
    WHERE m.session_id IS NOT NULL
),

body_sample AS (
    SELECT * FROM body_base
    WHERE stp_label IS NOT NULL
),

-- Date type tagging
all_samples AS (
    SELECT r.*,
        CASE
            WHEN fd1.datekey IS NOT NULL THEN 'Holiday'
            WHEN d1.day_of_week IN (5, 6) THEN 'Weekend'
            ELSE 'Weekday'
        END AS checkin_date_type,
        CASE
            WHEN fd2.datekey IS NOT NULL THEN 'Holiday'
            WHEN d2.day_of_week IN (5, 6) THEN 'Weekend'
            ELSE 'Weekday'
        END AS order_date_type
    FROM (
        SELECT * FROM reviewtags_sample
        UNION ALL
        SELECT * FROM body_sample
    ) r
    LEFT JOIN ba_hotel.dim_date d1 ON r.checkin_datekey = d1.datekey
    LEFT JOIN upload_table.hotel_festival_datekey fd1 ON r.checkin_datekey = fd1.datekey
    LEFT JOIN ba_hotel.dim_date d2 ON r.datekey = d2.datekey
    LEFT JOIN upload_table.hotel_festival_datekey fd2 ON r.datekey = fd2.datekey
),

-- Conflict detection: discard when both LeisureTravel and NecessaryPurpose labels exist under the same session_id
conflict_sessions AS (
    SELECT session_id
    FROM all_samples
    GROUP BY session_id
    HAVING COUNT(DISTINCT stp_label) > 1
),

-- After conflict removal, deduplicate by session_id, reviewtags takes priority
valid_samples AS (
    SELECT
        a.*,
        ROW_NUMBER() OVER (
            PARTITION BY a.session_id
            ORDER BY CASE WHEN a.sample_source = 'reviewtags' THEN 0 ELSE 1 END
        ) AS rn
    FROM all_samples a
    WHERE a.session_id NOT IN (SELECT session_id FROM conflict_sessions)
),

final_base AS (
    SELECT * FROM valid_samples WHERE rn = 1
),

-- ============================================================
-- Round 1: Hard-constraint sampling by checkin_date_type
-- reviewtags NecessaryPurpose + LeisureTravel trimmed to target ratio
-- body NecessaryPurpose samples (ExamInterview / MedicalVisit) trimmed by BusinessTrip:ExamInterview = 5:1, BusinessTrip:MedicalVisit = 8:1
-- ============================================================

checkin_necessary AS (
    SELECT checkin_date_type, COUNT(*) AS cnt
    FROM final_base
    WHERE stp_label = 'NecessaryPurpose' AND scene_label = 'NecessaryPurpose-BusinessTrip'
    GROUP BY checkin_date_type
),

checkin_travel_target AS (
    SELECT
        checkin_date_type, cnt AS necessary_cnt,
        CASE checkin_date_type
            WHEN 'Holiday'  THEN CAST(ROUND(cnt * 0.68 / 0.32) AS BIGINT)
            WHEN 'Weekend'  THEN CAST(ROUND(cnt * 0.60 / 0.40) AS BIGINT)
            WHEN 'Weekday'  THEN CAST(ROUND(cnt * 0.32 / 0.68) AS BIGINT)
        END AS travel_take
    FROM checkin_necessary
),

checkin_body_target AS (
    SELECT
        checkin_date_type,
        cnt AS necessary_cnt,
        -- ExamInterview retention = business-trip count / 5
        CAST(ROUND(cnt / 5.0) AS BIGINT) AS exam_keep,
        -- MedicalVisit retention = business-trip count / 8
        CAST(ROUND(cnt / 8.0) AS BIGINT) AS medical_keep
    FROM checkin_necessary
),

checkin_ranked AS (
    SELECT f.*,
        ROW_NUMBER() OVER (
            PARTITION BY f.checkin_date_type, f.stp_label, f.scene_label
            ORDER BY RAND()
        ) AS rn_checkin
    FROM final_base f
),

round1 AS (
    -- reviewtags NecessaryPurpose retained
    SELECT * FROM checkin_ranked WHERE stp_label = 'NecessaryPurpose' AND sample_source = 'reviewtags'
    UNION ALL
    -- reviewtags LeisureTravel trimmed by ratio
    SELECT c.* FROM checkin_ranked c
    JOIN checkin_travel_target t ON c.checkin_date_type = t.checkin_date_type
    WHERE c.stp_label = 'LeisureTravel' AND c.sample_source = 'reviewtags' AND c.rn_checkin <= t.travel_take
    UNION ALL
    -- body ExamInterview trimmed by business-trip / 5
    SELECT c.* FROM checkin_ranked c
    JOIN checkin_body_target t ON c.checkin_date_type = t.checkin_date_type
    WHERE c.stp_label = 'NecessaryPurpose' AND c.sample_source = 'body' AND c.scene_label = 'ExamInterview'
        AND c.rn_checkin <= t.exam_keep
    UNION ALL
    -- body MedicalVisit trimmed by business-trip / 8
    SELECT c.* FROM checkin_ranked c
    JOIN checkin_body_target t ON c.checkin_date_type = t.checkin_date_type
    WHERE c.stp_label = 'NecessaryPurpose' AND c.sample_source = 'body' AND c.scene_label = 'MedicalVisit'
        AND c.rn_checkin <= t.medical_keep
),

-- ============================================================
-- Round 2: Soft-constraint (upper-bound) sampling by order_date_type, applied to LeisureTravel only
-- NecessaryPurpose samples have already been trimmed in Round 1 and do not participate in Round 2
-- ============================================================

order_stats AS (
    SELECT
        order_date_type,
        COUNT(*) AS total,
        COUNT(CASE WHEN stp_label = 'LeisureTravel' THEN 1 END) AS travel_cnt,
        CASE order_date_type
            WHEN 'Holiday'  THEN 0.75
            WHEN 'Weekend'  THEN 0.65
            WHEN 'Weekday'  THEN 0.40
        END AS travel_cap
    FROM round1
    GROUP BY order_date_type
),

order_travel_target AS (
    SELECT
        order_date_type,
        total,
        travel_cnt,
        travel_cap,
        CAST(ROUND(total * travel_cap) AS BIGINT) AS travel_keep
    FROM order_stats
),

order_ranked AS (
    SELECT r.*,
        ROW_NUMBER() OVER (
            PARTITION BY r.order_date_type, r.stp_label
            ORDER BY RAND()
        ) AS rn_order
    FROM round1 r
)

-- ============================================================
-- Final output
-- ============================================================
SELECT
    o.sample_source, o.scene_label, o.stp_label,
    o.order_id, o.session_id, o.checkin_datekey, o.datekey,
    o.checkin_date_type, o.order_date_type
FROM order_ranked o
LEFT JOIN order_travel_target t ON o.order_date_type = t.order_date_type
WHERE
    o.stp_label = 'NecessaryPurpose'
    OR (o.stp_label = 'LeisureTravel' AND o.rn_order <= t.travel_keep);
```

---

## 5. Training Sample Upload Tables

- Broad scope: `mart_hoteldim.stp_test_session`
- Narrow scope: `mart_hoteldim.stp_test_session_v2`
