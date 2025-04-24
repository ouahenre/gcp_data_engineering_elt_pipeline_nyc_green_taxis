-- IV/ Competitive Insights & Operational Efficiency

-- Question 12: Which boroughs or zones have the highest and lowest trip volumes, and how do they compare over time?
CREATE OR REPLACE VIEW `views_fordashboard.trip_volume_by_borough` AS
SELECT 
    DATE(t.lpep_pickup_datetime) AS trip_date,
    EXTRACT(YEAR FROM t.lpep_pickup_datetime) AS year,
    EXTRACT(MONTH FROM t.lpep_pickup_datetime) AS month,
    pz.Borough AS pickup_borough,
    dz.Borough AS dropoff_borough,
    pz.Zone AS pickup_zone,
    dz.Zone AS dropoff_zone,
    COUNT(*) AS total_trips
FROM `green-taxi-trips-analytics.transformed_data.cleaned_and_filtered` t
JOIN `green-taxi-trips-analytics.raw_greentrips.taxi_zone` pz 
    ON t.PULocationID = pz.LocationID
JOIN `green-taxi-trips-analytics.raw_greentrips.taxi_zone` dz 
    ON t.DOLocationID = dz.LocationID
GROUP BY trip_date, year, month, pickup_borough, dropoff_borough, pickup_zone, dropoff_zone;

SELECT * FROM `views_fordashboard.trip_volume_by_borough` LIMIT 100;



-- Question 13: How frequently do green taxis serve airports (JFK, LaGuardia, ...), and what is the average fare for these trips?
CREATE OR REPLACE VIEW `views_fordashboard.airport_trips_analysis` AS
SELECT 
    DATE(t.lpep_pickup_datetime) AS trip_date,
    EXTRACT(YEAR FROM t.lpep_pickup_datetime) AS year,
    EXTRACT(MONTH FROM t.lpep_pickup_datetime) AS month,
    CASE 
        WHEN pz.Zone = 'JFK Airport' OR dz.Zone = 'JFK Airport' THEN 'JFK Airport'
        WHEN pz.Zone = 'LaGuardia Airport' OR dz.Zone = 'LaGuardia Airport' THEN 'LaGuardia Airport'
        WHEN pz.Zone = 'Newark Airport' OR dz.Zone = 'Newark Airport' THEN 'Newark Airport'
        ELSE 'Other'
    END AS airport,
    COUNT(*) AS total_trips,
    ROUND(AVG(t.total_amount), 2) AS avg_fare,
    ROUND(AVG(t.trip_distance), 2) AS avg_distance
FROM `green-taxi-trips-analytics.transformed_data.cleaned_and_filtered` t
JOIN `green-taxi-trips-analytics.raw_greentrips.taxi_zone` pz 
    ON t.PULocationID = pz.LocationID
JOIN `green-taxi-trips-analytics.raw_greentrips.taxi_zone` dz 
    ON t.DOLocationID = dz.LocationID
WHERE pz.Zone IN ('JFK Airport', 'LaGuardia Airport', 'Newark Airport') 
   OR dz.Zone IN ('JFK Airport', 'LaGuardia Airport', 'Newark Airport')
GROUP BY trip_date, year, month, airport;

SELECT * FROM `views_fordashboard.airport_trips_analysis` LIMIT 100;



-- Question 14: How often do taxis use different rate codes (e.g., standard rate vs. negotiated fares), and how do these rates vary across boroughs?
CREATE OR REPLACE VIEW `views_fordashboard.rate_code_analysis` AS
SELECT 
    EXTRACT(YEAR FROM t.lpep_pickup_datetime) AS year,
    EXTRACT(MONTH FROM t.lpep_pickup_datetime) AS month,
    pz.Borough AS pickup_borough,
    t.RateCodeID,
    CASE 
        WHEN t.RateCodeID = 1 THEN 'Standard rate'
        WHEN t.RateCodeID = 2 THEN 'JFK'
        WHEN t.RateCodeID = 3 THEN 'Newark'
        WHEN t.RateCodeID = 4 THEN 'Nassau or Westchester'
        WHEN t.RateCodeID = 5 THEN 'Negotiated fare'
        WHEN t.RateCodeID = 6 THEN 'Group ride'
        ELSE 'Unknown'
    END AS rate_code_description,
    COUNT(*) AS total_trips,
    ROUND(AVG(t.total_amount), 2) AS avg_fare
FROM `green-taxi-trips-analytics.transformed_data.cleaned_and_filtered` t
JOIN `green-taxi-trips-analytics.raw_greentrips.taxi_zone` pz 
    ON t.PULocationID = pz.LocationID
GROUP BY year, month, pickup_borough, t.RateCodeID, rate_code_description;

SELECT * FROM `views_fordashboard.rate_code_analysis` LIMIT 100;


-- Question 15: How long do trips typically take, and is there a trend of increasing or decreasing trip durations over time?
CREATE OR REPLACE VIEW `views_fordashboard.trip_duration_analysis` AS
SELECT 
    EXTRACT(YEAR FROM t.lpep_pickup_datetime) AS year,
    EXTRACT(MONTH FROM t.lpep_pickup_datetime) AS month,
    EXTRACT(DAY FROM t.lpep_pickup_datetime) AS day,
    EXTRACT(HOUR FROM t.lpep_pickup_datetime) AS hour,
    ROUND(AVG(TIMESTAMP_DIFF(t.lpep_dropoff_datetime, t.lpep_pickup_datetime, MINUTE)), 2) AS avg_trip_duration_min,
    COUNT(*) AS total_trips
FROM `green-taxi-trips-analytics.transformed_data.cleaned_and_filtered` t
GROUP BY year, month, day, hour;

SELECT * FROM `views_fordashboard.trip_duration_analysis` LIMIT 100;
