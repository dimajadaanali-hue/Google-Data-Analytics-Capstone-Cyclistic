-- ============================================================================
-- 1. Data merging, cleaning, and permanent table creation
-- ============================================================================
CREATE OR REPLACE TABLE `cyclistic-bike-capstone-497321.cyclistic_data.cleaned_combined_data` AS (
    SELECT DISTINCT 
        ride_id,
        rideable_type,
        CAST(started_at AS TIMESTAMP) AS started_at,
        
-- Trim leading and trailing whitespaces to standardize text
        TRIM(start_station_name) AS start_station_name,
        TRIM(end_station_name) AS end_station_name,
        
        member_casual,
        
-- Calculate trip duration in minutes
        ROUND(TIMESTAMP_DIFF(CAST(ended_at AS TIMESTAMP), CAST(started_at AS TIMESTAMP), SECOND) / 60.0, 2) AS ride_length_minutes,
        -- Extract day name (e.g., Sunday) and number (1-7) for easier sorting later
        FORMAT_TIMESTAMP('%A', CAST(started_at AS TIMESTAMP)) AS day_of_week,
        EXTRACT(DAYOFWEEK FROM CAST(started_at AS TIMESTAMP)) AS day_number
    FROM (
        -- Combining Q1 tables for 2024 and 2025 via UNION
        SELECT * FROM `cyclistic-bike-capstone-497321.cyclistic_data.q1_jan_2024` UNION ALL
        SELECT * FROM `cyclistic-bike-capstone-497321.cyclistic_data.q1_feb_2024` UNION ALL
        SELECT * FROM `cyclistic-bike-capstone-497321.cyclistic_data.q1_mar_2024` UNION ALL
        SELECT * FROM `cyclistic-bike-capstone-497321.cyclistic_data.q1_jan_2025` UNION ALL
        SELECT * FROM `cyclistic-bike-capstone-497321.cyclistic_data.q1_feb_2025` UNION ALL
        SELECT * FROM `cyclistic-bike-capstone-497321.cyclistic_data.q1_mar_2025`
    )
    WHERE 
    -- Handle missing values and filter out entirely blank rows
        ride_id IS NOT NULL 
        AND start_station_name IS NOT NULL AND TRIM(start_station_name) != ''
        AND end_station_name IS NOT NULL AND TRIM(end_station_name) != ''
        AND TIMESTAMP_DIFF(CAST(ended_at AS TIMESTAMP), CAST(started_at AS TIMESTAMP), SECOND) >= 60
        AND TIMESTAMP_DIFF(CAST(ended_at AS TIMESTAMP), CAST(started_at AS TIMESTAMP), SECOND) <= 86400
);

-- ============================================================================
-- 2. Query 1: Calculate total trips, avg duration, and max duration by category
-- ============================================================================
SELECT 
    member_casual AS user_category,                         
    COUNT(ride_id) AS total_trips,                           
    ROUND(AVG(ride_length_minutes), 2) AS avg_ride_length,   
    MAX(ride_length_minutes) AS max_ride_length              
FROM 
    `cyclistic-bike-capstone-497321.cyclistic_data.cleaned_combined_data` -- Modified to query from the new table
WHERE 
    ride_length_minutes > 0                                  
GROUP BY 
    member_casual;

-- ============================================================================
-- 3. Query 2: Ride distribution and avg duration by day of the week per category
-- ============================================================================
SELECT 
    member_casual AS user_category,
    day_of_week,
    COUNT(ride_id) AS total_trips,
    ROUND(AVG(ride_length_minutes), 2) AS avg_ride_length
FROM 
    `cyclistic-bike-capstone-497321.cyclistic_data.cleaned_combined_data` -- Modified to query from the new table
WHERE 
    ride_length_minutes > 0
GROUP BY 
    member_casual, 
    day_of_week,
    day_number
ORDER BY 
    user_category, 
    day_number;