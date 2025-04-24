-- III/ Financial & Pricing Analysis

-- Question 7: How does the total fare revenue of green taxis change over time?
CREATE OR REPLACE VIEW `views_fordashboard.total_fare_revenue_over_time` AS
SELECT 
    DATE(t.lpep_pickup_datetime) AS trip_date,
    EXTRACT(YEAR FROM t.lpep_pickup_datetime) AS year,
    EXTRACT(MONTH FROM t.lpep_pickup_datetime) AS month,
    EXTRACT(WEEK FROM t.lpep_pickup_datetime) AS week,
    EXTRACT(DAYOFWEEK FROM t.lpep_pickup_datetime) AS weekday,
    SUM(t.total_amount) AS total_revenue,
    SUM(t.fare_amount) AS fare_revenue,
    SUM(t.tip_amount) AS tip_revenue,
    SUM(t.tolls_amount) AS tolls_revenue,
    SUM(t.congestion_surcharge) AS congestion_revenue
FROM `green-taxi-trips-analytics.transformed_data.cleaned_and_filtered` t
GROUP BY trip_date, year, month, week, weekday;

SELECT * FROM `views_fordashboard.total_fare_revenue_over_time` LIMIT 1000;


-- Question 8: What is the average fare per trip, and how does it vary by borough, time of day, and trip distance?
CREATE OR REPLACE VIEW `views_fordashboard.avg_fare_analysis` AS
SELECT 
    DATE(t.lpep_pickup_datetime) AS trip_date,
    EXTRACT(YEAR FROM t.lpep_pickup_datetime) AS year,
    EXTRACT(MONTH FROM t.lpep_pickup_datetime) AS month,
    EXTRACT(HOUR FROM t.lpep_pickup_datetime) AS pickup_hour,
    pz.Borough AS pickup_borough,
    dz.Borough AS dropoff_borough,
    ROUND(AVG(t.fare_amount), 2) AS avg_fare_per_trip,
    ROUND(AVG(t.total_amount), 2) AS avg_total_amount_per_trip,
    ROUND(AVG(t.trip_distance), 2) AS avg_trip_distance,
    COUNT(*) AS total_trips
FROM `green-taxi-trips-analytics.transformed_data.cleaned_and_filtered` t
JOIN `green-taxi-trips-analytics.raw_greentrips.taxi_zone` pz 
    ON t.PULocationID = pz.LocationID
JOIN `green-taxi-trips-analytics.raw_greentrips.taxi_zone` dz 
    ON t.DOLocationID = dz.LocationID
GROUP BY trip_date, year, month, pickup_hour, pickup_borough, dropoff_borough;

SELECT * FROM `views_fordashboard.avg_fare_analysis` LIMIT 1000;


-- Question 9: What is the proportion of different payment types (credit card, cash, etc.), and has it changed over time?
CREATE OR REPLACE VIEW `views_fordashboard.payment_type_trends` AS
WITH payment_summary AS (
    SELECT 
        DATE(t.lpep_pickup_datetime) AS trip_date,
        EXTRACT(YEAR FROM t.lpep_pickup_datetime) AS year,
        EXTRACT(MONTH FROM t.lpep_pickup_datetime) AS month,
        EXTRACT(WEEK FROM t.lpep_pickup_datetime) AS week,
        t.payment_type,
        COUNT(*) AS total_trips
    FROM `green-taxi-trips-analytics.transformed_data.cleaned_and_filtered` t
    GROUP BY trip_date, year, month, week, t.payment_type
),
payment_proportion AS (
    SELECT 
        trip_date,
        year,
        month,
        week,
        payment_type,
        total_trips,
        SUM(total_trips) OVER (PARTITION BY trip_date) AS daily_total_trips,
        ROUND(100 * total_trips / SUM(total_trips) OVER (PARTITION BY trip_date), 2) AS payment_percentage
    FROM payment_summary
)
SELECT 
    trip_date,
    year,
    month,
    week,
    CASE 
        WHEN payment_type = 1 THEN 'Credit Card'
        WHEN payment_type = 2 THEN 'Cash'
        WHEN payment_type = 3 THEN 'No Charge'
        WHEN payment_type = 4 THEN 'Dispute'
        WHEN payment_type = 5 THEN 'Unknown'
    END AS payment_method,
    total_trips,
    daily_total_trips,
    payment_percentage
FROM payment_proportion;


SELECT * FROM `views_fordashboard.payment_type_trends` LIMIT 1000;


-- Question 10: How often do passengers tip, and what factors (time of day, borough, fare amount) influence tip amounts?
CREATE OR REPLACE VIEW `views_fordashboard.tipping_behavior_analysis` AS
SELECT 
    DATE(t.lpep_pickup_datetime) AS trip_date,
    EXTRACT(YEAR FROM t.lpep_pickup_datetime) AS year,
    EXTRACT(MONTH FROM t.lpep_pickup_datetime) AS month,
    EXTRACT(HOUR FROM t.lpep_pickup_datetime) AS pickup_hour,
    pz.Borough AS pickup_borough,
    dz.Borough AS dropoff_borough,
    COUNT(*) AS total_trips,
    SUM(CASE WHEN t.tip_amount > 0 THEN 1 ELSE 0 END) AS tipped_trips,
    ROUND(100 * SUM(CASE WHEN t.tip_amount > 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS tip_frequency_percentage,
    ROUND(AVG(t.tip_amount), 2) AS avg_tip_amount,
    ROUND(AVG(t.total_amount), 2) AS avg_total_fare,
    ROUND(AVG(t.fare_amount), 2) AS avg_fare,
    ROUND(AVG(t.tip_amount / NULLIF(t.total_amount, 0)), 4) * 100 AS avg_tip_percentage
FROM `green-taxi-trips-analytics.transformed_data.cleaned_and_filtered` t
JOIN `green-taxi-trips-analytics.raw_greentrips.taxi_zone` pz 
    ON t.PULocationID = pz.LocationID
JOIN `green-taxi-trips-analytics.raw_greentrips.taxi_zone` dz 
    ON t.DOLocationID = dz.LocationID
WHERE t.payment_type = 1  -- Only credit card payments (cash tips are not recorded)
GROUP BY trip_date, year, month, pickup_hour, pickup_borough, dropoff_borough;


SELECT * FROM `views_fordashboard.tipping_behavior_analysis` LIMIT 1000;


-- Question 11: How much revenue is generated from additional charges (MTA tax, congestion surcharge, airport fees), and has it changed over time?
CREATE OR REPLACE VIEW `views_fordashboard.additional_charges_revenue` AS
SELECT 
    DATE(t.lpep_pickup_datetime) AS trip_date,
    EXTRACT(YEAR FROM t.lpep_pickup_datetime) AS year,
    EXTRACT(MONTH FROM t.lpep_pickup_datetime) AS month,
    COUNT(*) AS total_trips,
    ROUND(SUM(t.MTA_tax), 2) AS total_MTA_tax,
    ROUND(SUM(t.congestion_surcharge), 2) AS total_congestion_surcharge,
    ROUND(SUM(t.airport_fee), 2) AS total_airport_fees,
    ROUND(SUM(t.MTA_tax + t.congestion_surcharge + t.airport_fee), 2) AS total_additional_revenue,
    ROUND(AVG(t.MTA_tax + t.congestion_surcharge + t.airport_fee), 2) AS avg_additional_charge_per_trip
FROM `green-taxi-trips-analytics.transformed_data.cleaned_and_filtered` t
GROUP BY trip_date, year, month;

SELECT * FROM `views_fordashboard.additional_charges_revenue` LIMIT 1000;