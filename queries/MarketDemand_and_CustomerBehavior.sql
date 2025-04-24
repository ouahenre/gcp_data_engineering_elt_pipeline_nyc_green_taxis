-- I/ Market Demand & Seasonality

-- Question 1: How does the demand for green taxis fluctuate over time (daily, weekly, monthly, and seasonally)?
CREATE OR REPLACE VIEW `views_fordashboard.demand_over_time` AS
SELECT 
    DATE(lpep_pickup_datetime) AS trip_date,
    EXTRACT(YEAR FROM lpep_pickup_datetime) AS year,
    EXTRACT(MONTH FROM lpep_pickup_datetime) AS month,
    EXTRACT(WEEK FROM lpep_pickup_datetime) AS week,
    EXTRACT(DAYOFWEEK FROM lpep_pickup_datetime) AS weekday,
    COUNT(*) AS total_trips
FROM `green-taxi-trips-analytics.transformed_data.cleaned_and_filtered`
GROUP BY trip_date, year, month, week, weekday
ORDER BY trip_date;

SELECT count(*) FROM `views_fordashboard.demand_over_time`;


-- Question 2: What are the peak hours for green taxi trips in different boroughs and zones? 
CREATE OR REPLACE VIEW `views_fordashboard.peak_hours_by_zone` AS
SELECT 
    EXTRACT(HOUR FROM t.lpep_pickup_datetime) AS pickup_hour,
    z.Borough,
    z.Zone,
    COUNT(*) AS total_trips
FROM `green-taxi-trips-analytics.transformed_data.cleaned_and_filtered` t
JOIN `green-taxi-trips-analytics.raw_greentrips.taxi_zone` z
ON t.PULocationID = z.LocationID
GROUP BY pickup_hour, z.Borough, z.Zone
ORDER BY total_trips DESC;

SELECT * FROM `views_fordashboard.peak_hours_by_zone` LIMIT 100;

SELECT DISTINCT Zone FROM `views_fordashboard.peak_hours_by_zone`;


-- Question 3: How do weather conditions or major events (holidays, sports events) impact green taxi usage over time? (To be investigated later)

-- II/ Customer Behavior & Ride Characteristics. 

-- Question 4: What are the most popular pickup and drop-off locations, and how do they change over time?
CREATE OR REPLACE VIEW `views_fordashboard.popular_pickup_dropoff` AS
SELECT 
    DATE(t.lpep_pickup_datetime) AS trip_date,
    EXTRACT(YEAR FROM t.lpep_pickup_datetime) AS year,
    EXTRACT(MONTH FROM t.lpep_pickup_datetime) AS month,
    EXTRACT(WEEK FROM t.lpep_pickup_datetime) AS week,
    EXTRACT(DAYOFWEEK FROM t.lpep_pickup_datetime) AS weekday,
    pz.Borough AS pickup_borough,
    pz.Zone AS pickup_zone,
    dz.Borough AS dropoff_borough,
    dz.Zone AS dropoff_zone,
    COUNT(*) AS total_trips
FROM `green-taxi-trips-analytics.transformed_data.cleaned_and_filtered` t
JOIN `green-taxi-trips-analytics.raw_greentrips.taxi_zone` pz 
    ON t.PULocationID = pz.LocationID
JOIN `green-taxi-trips-analytics.raw_greentrips.taxi_zone` dz 
    ON t.DOLocationID = dz.LocationID
GROUP BY trip_date, year, month, week, weekday, pickup_borough, pickup_zone, dropoff_borough, dropoff_zone;

SELECT * FROM `views_fordashboard.popular_pickup_dropoff` LIMIT 1000;

SELECT COUNT(*) FROM `views_fordashboard.popular_pickup_dropoff`;


-- Question 5: What is the average trip distance, and how does it vary by borough, time of day, and season?
CREATE OR REPLACE VIEW `views_fordashboard.avg_trip_distance_analysis` AS
SELECT 
    DATE(t.lpep_pickup_datetime) AS trip_date,
    EXTRACT(YEAR FROM t.lpep_pickup_datetime) AS year,
    EXTRACT(MONTH FROM t.lpep_pickup_datetime) AS month,
    CASE 
        WHEN EXTRACT(MONTH FROM t.lpep_pickup_datetime) IN (12, 1, 2) THEN 'Winter'
        WHEN EXTRACT(MONTH FROM t.lpep_pickup_datetime) IN (3, 4, 5) THEN 'Spring'
        WHEN EXTRACT(MONTH FROM t.lpep_pickup_datetime) IN (6, 7, 8) THEN 'Summer'
        WHEN EXTRACT(MONTH FROM t.lpep_pickup_datetime) IN (9, 10, 11) THEN 'Fall'
    END AS season,
    EXTRACT(HOUR FROM t.lpep_pickup_datetime) AS pickup_hour,
    pz.Borough AS pickup_borough,
    dz.Borough AS dropoff_borough,
    AVG(t.trip_distance) AS avg_trip_distance
FROM `green-taxi-trips-analytics.transformed_data.cleaned_and_filtered` t
JOIN `green-taxi-trips-analytics.raw_greentrips.taxi_zone` pz 
    ON t.PULocationID = pz.LocationID
JOIN `green-taxi-trips-analytics.raw_greentrips.taxi_zone` dz 
    ON t.DOLocationID = dz.LocationID
GROUP BY trip_date, year, month, season, pickup_hour, pickup_borough, dropoff_borough
ORDER BY trip_date, pickup_hour;

SELECT * FROM `views_fordashboard.avg_trip_distance_analysis` LIMIT 100;


-- Question 6: How many trips have only one passenger versus multiple passengers, and does this change seasonally?
CREATE OR REPLACE VIEW `views_fordashboard.passenger_trends_by_season` AS
SELECT 
    DATE(t.lpep_pickup_datetime) AS trip_date,
    EXTRACT(YEAR FROM t.lpep_pickup_datetime) AS year,
    EXTRACT(MONTH FROM t.lpep_pickup_datetime) AS month,
    CASE 
        WHEN EXTRACT(MONTH FROM t.lpep_pickup_datetime) IN (12, 1, 2) THEN 'Winter'
        WHEN EXTRACT(MONTH FROM t.lpep_pickup_datetime) IN (3, 4, 5) THEN 'Spring'
        WHEN EXTRACT(MONTH FROM t.lpep_pickup_datetime) IN (6, 7, 8) THEN 'Summer'
        WHEN EXTRACT(MONTH FROM t.lpep_pickup_datetime) IN (9, 10, 11) THEN 'Fall'
    END AS season,
    CASE 
        WHEN t.passenger_count = 1 THEN 'Single Passenger'
        ELSE 'Multiple Passengers'
    END AS passenger_category,
    COUNT(*) AS total_trips
FROM `green-taxi-trips-analytics.transformed_data.cleaned_and_filtered` t
GROUP BY trip_date, year, month, season, passenger_category
ORDER BY trip_date;


SELECT * FROM `views_fordashboard.passenger_trends_by_season` LIMIT 100;