-- Запрос для нахождения минимальной и максимальной дат публикации объявлений
-- Это покажет временной интервал, за который представлены данные
SELECT 
    MIN(first_day_exposition) AS min_date,
    MAX(first_day_exposition) AS max_date
FROM 
    real_estate.advertisement;
-- Запрос для анализа распределения объявлений по типам населённых пунктов
SELECT 
    t.type AS locality_type,
    COUNT(DISTINCT c.city_id) AS number_of_localities,
    COUNT(a.id) AS number_of_ads,
    ROUND(COUNT(a.id) * 100.0 / SUM(COUNT(a.id)) OVER(), 1) AS percentage_of_total
FROM 
    real_estate.advertisement a
JOIN 
    real_estate.flats f ON a.id = f.id
JOIN 
    real_estate.city c ON f.city_id = c.city_id
JOIN 
    real_estate.type t ON f.type_id = t.type_id
GROUP BY 
    t.type
ORDER BY 
    number_of_ads DESC;

--Анализ времени активности объявлений о продаже недвижимости
--Запрос вычисляет ключевые статистические показатели по продолжительности размещения объявлений:
-- - минимальное и максимальное время активности (в днях)
-- - среднее значение и медиану для оценки типичного времени продажи
SELECT
MIN(days_exposition) AS min_days,
MAX(days_exposition) AS max_days,
ROUND(CAST(AVG(days_exposition) AS numeric), 2) AS avg_days,
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days_exposition) AS median_days
FROM
real_estate.advertisement
WHERE
days_exposition IS NOT NULL;
--Анализ доли проданной недвижимости (снятых с публикации объявлений)
--Запрос вычисляет процент объявлений, которые были сняты с публикации (days_exposition не NULL)
--Это косвенный показатель процента проданных объектов
SELECT
ROUND(
COUNT(*) FILTER (WHERE days_exposition IS NOT NULL) * 100.0 /
COUNT(*),
2
) AS sold_percentage
FROM
real_estate.advertisement;
-- Анализ распределения объявлений между Санкт-Петербургом и Ленинградской областью
-- Запрос вычисляет процент объявлений, относящихся к Санкт-Петербургу
SELECT
    ROUND(
        COUNT(*) FILTER (WHERE c.city = 'Санкт-Петербург') * 100.0 / 
        COUNT(*),
        2
    ) AS spb_percentage
FROM 
    real_estate.advertisement a
JOIN
    real_estate.flats f ON a.id = f.id
JOIN
    real_estate.city c ON f.city_id = c.city_id;
-- Анализ стоимости квадратного метра недвижимости
-- Запрос вычисляет ключевые статистические показатели цены за м²
WITH square_meter_price AS (
    SELECT 
        (a.last_price / f.total_area) AS price_per_m2
    FROM 
        real_estate.advertisement a
    JOIN
        real_estate.flats f ON a.id = f.id
    WHERE
        f.total_area > 0 AND a.last_price > 0  -- Исключаем нулевые и отрицательные значения
)
SELECT
    ROUND(MIN(price_per_m2)::numeric, 2) AS min_price_per_m2,
    ROUND(MAX(price_per_m2)::numeric, 2) AS max_price_per_m2,
    ROUND(AVG(price_per_m2)::numeric, 2) AS avg_price_per_m2,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price_per_m2)::numeric, 2) AS median_price_per_m2
FROM 
    square_meter_price;
-- Анализ статистических показателей количественных параметров недвижимости 
-- Запрос вычисляет основные метрики для ключевых характеристик объектов 
SELECT
    -- Статистика по общей площади (м²)
    'total_area' AS metric,
    MIN(total_area) AS min_value,
    MAX(total_area) AS max_value,
    ROUND(AVG(total_area)::numeric, 2) AS avg_value,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_area)::numeric(10,2) AS median,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_area)::numeric(10,2) AS percentile_99,
    COUNT(*) AS total_count,
    COUNT(*) FILTER (WHERE total_area <= 0 OR total_area > 1000) AS anomaly_count
FROM
    real_estate.flats
UNION ALL
SELECT
    -- Статистика по количеству комнат
    'rooms' AS metric,
    MIN(rooms) AS min_value,
    MAX(rooms) AS max_value,
    ROUND(AVG(rooms)::numeric, 2) AS avg_value,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY rooms)::numeric(10,2) AS median,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY rooms)::numeric(10,2) AS percentile_99,
    COUNT(*) AS total_count,
    COUNT(*) FILTER (WHERE rooms < 0 OR rooms > 20) AS anomaly_count
FROM
    real_estate.flats
UNION ALL
SELECT
    -- Статистика по количеству балконов
    'balcony' AS metric,
    MIN(balcony) AS min_value,
    MAX(balcony) AS max_value,
    ROUND(AVG(balcony)::numeric, 2) AS avg_value,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY balcony)::numeric(10,2) AS median,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY balcony)::numeric(10,2) AS percentile_99,
    COUNT(*) AS total_count,
    COUNT(*) FILTER (WHERE balcony < 0 OR balcony > 10) AS anomaly_count
FROM
    real_estate.flats
UNION ALL
SELECT
    -- Статистика по высоте потолков (м)
    'ceiling_height' AS metric,
    MIN(ceiling_height) AS min_value,
    MAX(ceiling_height) AS max_value,
    ROUND(AVG(ceiling_height)::numeric, 2) AS avg_value,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ceiling_height)::numeric(10,2) AS median,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY ceiling_height)::numeric(10,2) AS percentile_99,
    COUNT(*) AS total_count,
    COUNT(*) FILTER (WHERE ceiling_height < 1 OR ceiling_height > 10) AS anomaly_count
FROM
    real_estate.flats
UNION ALL
SELECT
    -- Статистика по этажу
    'floor' AS metric,
    MIN(floor) AS min_value,
    MAX(floor) AS max_value,
    ROUND(AVG(floor)::numeric, 2) AS avg_value,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY floor)::numeric(10,2) AS median,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY floor)::numeric(10,2) AS percentile_99,
    COUNT(*) AS total_count,
    COUNT(*) FILTER (WHERE floor < 0 OR floor > 100) AS anomaly_count
FROM
    real_estate.flats;
-- Фильтрация аномальных значений
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    )
-- Выведем объявления без выбросов:
SELECT *
FROM real_estate.flats
WHERE id IN (SELECT * FROM filtered_id); 


-- Задача 1. Время активности объявлений
WITH 
-- Фильтрация данных
filtered_ads AS (
    WITH limits AS (
        SELECT  
            PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
            PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
            PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
            PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
            PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
        FROM real_estate.flats     
    ),
    filtered_id AS(
        SELECT id
        FROM real_estate.flats  
        WHERE 
            total_area < (SELECT total_area_limit FROM limits)
            AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
            AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
            AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
                AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    )
    SELECT 
        a.id,
        a.days_exposition,
        a.last_price,
        f.total_area,
        f.rooms,
        f.balcony,
        f.ceiling_height,
        f.floor,
        f.is_apartment,
        f.open_plan,
        f.airports_nearest,
        f.parks_around3000,
        f.ponds_around3000,
        c.city,
        t.type,
        (a.last_price / NULLIF(f.total_area, 0))::numeric AS price_per_m2
    FROM 
        real_estate.advertisement a
    JOIN 
        real_estate.flats f ON a.id = f.id
    JOIN 
        real_estate.city c ON f.city_id = c.city_id
    JOIN
        real_estate.type t ON f.type_id = t.type_id
    WHERE 
        f.id IN (SELECT id FROM filtered_id)
        AND a.last_price > 0
        AND f.total_area > 0
        -- Фильтрация только городов (исключаем деревни, села и т.д.)
        AND t.type IN ('город', 'Город')
        -- Фильтрация полных годов (2015-2018)
        AND EXTRACT(YEAR FROM a.first_day_exposition) BETWEEN 2015 AND 2018
),
-- Основные данные с категоризацией
categorized_data AS (
    SELECT 
        *,
        CASE 
            WHEN city = 'Санкт-Петербург' THEN 'Санкт-Петербург'
            ELSE 'Ленинградская область'
        END AS region,
        CASE
            WHEN days_exposition IS NULL THEN 'Другие'
            WHEN days_exposition <= 30 THEN 'до месяца'
            WHEN days_exposition <= 90 THEN 'до трех месяцев'
            WHEN days_exposition <= 180 THEN 'до полугода'
            ELSE 'более полугода'
        END AS activity_segment,
        -- Дополнительные показатели
        CASE WHEN rooms = 0 THEN 1 ELSE 0 END AS is_studio,
        CASE WHEN is_apartment = 1 THEN 1 ELSE 0 END AS is_apartment_flag,
        CASE WHEN open_plan = 1 THEN 1 ELSE 0 END AS open_plan_flag
    FROM 
        filtered_ads
)
-- Итог
SELECT 
    region,
    activity_segment,
    COUNT(*) AS ads_count,
    ROUND((COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(PARTITION BY region))::numeric, 1) AS percentage,
    ROUND(AVG(price_per_m2)::numeric, 0) AS avg_price_per_m2,
    ROUND(AVG(total_area::numeric), 2) AS avg_area,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY rooms)::numeric AS median_rooms,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY balcony)::numeric AS median_balcony,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY floor)::numeric AS median_floor,
    -- Дополнительные показатели
    ROUND(AVG(ceiling_height)::numeric, 2) AS avg_ceiling_height,
    ROUND(SUM(is_studio) * 100.0 / COUNT(*), 1) AS studio_percentage,
    ROUND(SUM(is_apartment_flag) * 100.0 / COUNT(*), 1) AS apartment_percentage,
    ROUND(SUM(open_plan_flag) * 100.0 / COUNT(*), 1) AS open_plan_percentage,
    ROUND(AVG(airports_nearest)::numeric, 0) AS avg_airport_distance,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY parks_around3000)::numeric AS median_parks,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ponds_around3000)::numeric AS median_ponds
FROM 
    categorized_data
GROUP BY 
    region, activity_segment
ORDER BY 
    region, 
    CASE 
        WHEN activity_segment = 'Другие' THEN 0
        WHEN activity_segment = 'до месяца' THEN 1
        WHEN activity_segment = 'до трех месяцев' THEN 2
        WHEN activity_segment = 'до полугода' THEN 3
        ELSE 4
    END;
-- Задача 2. Сезонность объявлений
WITH 
-- Фильтрация данных по рекомендованному методу
filtered_ads AS (
    WITH limits AS (
        SELECT  
            PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
            PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
            PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
            PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
            PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
        FROM real_estate.flats     
    ),
    filtered_id AS(
        SELECT id
        FROM real_estate.flats  
        WHERE 
            total_area < (SELECT total_area_limit FROM limits)
            AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
            AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
            AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
                AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    )
    SELECT 
        a.id,
        a.first_day_exposition,
        a.days_exposition,
        a.last_price,
        f.total_area,
        (a.last_price / NULLIF(f.total_area, 0))::numeric AS price_per_m2,
        (a.first_day_exposition + (a.days_exposition || ' days')::interval) AS removal_date
    FROM 
        real_estate.advertisement a
    JOIN 
        real_estate.flats f ON a.id = f.id
    WHERE 
        f.id IN (SELECT id FROM filtered_id)
        AND a.last_price > 0
        AND f.total_area > 0
        AND EXTRACT(YEAR FROM a.first_day_exposition) BETWEEN 2015 AND 2018
),
-- Статистика по опубликованным объявлениям
published_stats AS (
    SELECT
        EXTRACT(MONTH FROM first_day_exposition) AS month_num,
        TO_CHAR(first_day_exposition, 'TMMonth') AS month_name,
        COUNT(*) AS published_count,
        ROUND(AVG(price_per_m2::numeric), 0) AS published_avg_price_m2,
        ROUND(AVG(total_area::numeric), 2) AS published_avg_area,
        RANK() OVER (ORDER BY COUNT(*) DESC) AS published_rank
    FROM
        filtered_ads
    GROUP BY
        EXTRACT(MONTH FROM first_day_exposition),
        TO_CHAR(first_day_exposition, 'TMMonth')
),
-- Статистика по снятым объявлениям
removed_stats AS (
    SELECT
        EXTRACT(MONTH FROM removal_date) AS month_num,
        TO_CHAR(removal_date, 'TMMonth') AS month_name,
        COUNT(*) AS removed_count,
        ROUND(AVG(price_per_m2::numeric), 0) AS removed_avg_price_m2,
        ROUND(AVG(total_area::numeric), 2) AS removed_avg_area,
        RANK() OVER (ORDER BY COUNT(*) DESC) AS removed_rank
    FROM
        filtered_ads
    WHERE
        days_exposition IS NOT NULL
    GROUP BY
        EXTRACT(MONTH FROM removal_date),
        TO_CHAR(removal_date, 'TMMonth')
),
-- Общая статистика
total_counts AS (
    SELECT
        COUNT(*) AS total_published,
        COUNT(*) FILTER (WHERE days_exposition IS NOT NULL) AS total_removed
    FROM
        filtered_ads
)
-- Итог
SELECT
    p.month_name AS "Месяц",
    p.published_count AS "Опубликовано",
    ROUND((p.published_count * 100.0 / t.total_published)::numeric, 1) AS "% от всех публикаций",
    p.published_rank AS "Ранг публикаций",
    CASE WHEN p.published_rank <= 3 THEN 'Высокая' ELSE 'Обычная' END AS "Активность публикаций",
    r.removed_count AS "Снято",
    ROUND((r.removed_count * 100.0 / t.total_removed)::numeric, 1) AS "% от всех снятий",
    r.removed_rank AS "Ранг снятий",
    CASE WHEN r.removed_rank <= 3 THEN 'Высокая' ELSE 'Обычная' END AS "Активность снятий",
    p.published_avg_price_m2 AS "Ср. цена м² (публикация)",
    r.removed_avg_price_m2 AS "Ср. цена м² (снятие)",
    p.published_avg_area AS "Ср. площадь (публикация)",
    r.removed_avg_area AS "Ср. площадь (снятие)"
FROM
    published_stats p
JOIN
    removed_stats r ON p.month_num = r.month_num
CROSS JOIN
    total_counts t
ORDER BY
    p.month_num;
--Задача 3. Анализ рынка недвижимости Ленобласти
-- Фильтрация данных по рекомендованному методу
WITH filtered_data AS (
    WITH limits AS (
        SELECT  
            PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
            PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
            PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
            PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
            PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
        FROM real_estate.flats     
    ),
    filtered_id AS(
        SELECT id
        FROM real_estate.flats  
        WHERE 
            total_area < (SELECT total_area_limit FROM limits)
            AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
            AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
            AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
                AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    )
    SELECT 
        a.id,
        a.days_exposition,
        a.last_price,
        f.total_area,
        f.rooms,
        f.balcony,
        c.city AS locality,
        (a.last_price / NULLIF(f.total_area, 0))::numeric AS price_per_m2
    FROM 
        real_estate.advertisement a
    JOIN 
        real_estate.flats f ON a.id = f.id
    JOIN 
        real_estate.city c ON f.city_id = c.city_id
    WHERE 
        f.id IN (SELECT id FROM filtered_id)
        AND c.city != 'Санкт-Петербург'
        AND f.total_area > 0
        AND a.last_price > 0
),
-- Ранжирование всех населенных пунктов по скорости продаж
all_localities_ranked AS (
    SELECT 
        locality,
        COUNT(*) AS total_ads,
        COUNT(a.days_exposition) AS sold_ads,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY a.days_exposition)::numeric AS median_days_on_market,
        NTILE(4) OVER (ORDER BY PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY a.days_exposition)::numeric) AS speed_quartile
    FROM 
        filtered_data a
    GROUP BY 
        locality
),
-- Основная статистика по отфильтрованным населенным пунктам
locality_stats AS (
    SELECT 
        l.locality,
        l.total_ads,
        l.sold_ads,
        ROUND((l.sold_ads * 100.0 / l.total_ads)::numeric, 1) AS sold_percentage,
        ROUND(AVG(a.price_per_m2::numeric), 0) AS avg_price_per_m2,
        ROUND(AVG(a.total_area::numeric), 2) AS avg_area,
        l.median_days_on_market,
        l.speed_quartile,
        -- Дополнительные показатели
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY a.rooms::numeric)::numeric AS median_rooms,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY a.balcony::numeric)::numeric AS median_balcony
    FROM 
        filtered_data a
    JOIN 
        all_localities_ranked l ON a.locality = l.locality
    GROUP BY 
        l.locality, l.total_ads, l.sold_ads, l.median_days_on_market, l.speed_quartile
    HAVING 
        COUNT(*) > 50 -- Порог выбран для обеспечения репрезентативности данных
)
-- Итог
SELECT 
    locality AS "Населенный пункт",
    total_ads AS "Всего объявлений",
    sold_ads AS "Продано",
    sold_percentage || '%' AS "Доля продаж",
    avg_price_per_m2 AS "Ср. цена м²",
    avg_area AS "Ср. площадь",
    median_days_on_market AS "Медиана дней продажи",
    CASE speed_quartile
        WHEN 1 THEN 'Самые быстрые продажи (Q1)'
        WHEN 2 THEN 'Быстрые продажи (Q2)'
        WHEN 3 THEN 'Медленные продажи (Q3)'
        WHEN 4 THEN 'Самые медленные продажи (Q4)'
    END AS "Квартиль скорости продаж",
    median_rooms AS "Медиана комнат",
    median_balcony AS "Медиана балконов",
    CASE 
        WHEN sold_percentage > 85 THEN 'Очень высокий спрос'
        WHEN sold_percentage > 75 THEN 'Высокий спрос'
        WHEN sold_percentage > 65 THEN 'Средний спрос'
        ELSE 'Низкий спрос'
    END AS "Уровень спроса"
FROM 
    locality_stats
ORDER BY 
    sold_percentage DESC,
    total_ads DESC;
