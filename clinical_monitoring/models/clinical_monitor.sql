{{
    config(
        materialized = 'view'
    )
}}

WITH raw_readings AS (
    SELECT * FROM {{ source('iot_source', 'device_readings') }}
),

expectations AS (
    SELECT * FROM {{ source('iot_source', 'device_expectations') }}
)

SELECT R.ReadingID,
    R.DeviceID,
    R.Temperature,
    R.Humidity,
    R.RecordedAt,
    E.LocationName,
    E.MinSafeTemp,
    E.MaxSafeTemp,
    CASE 
        WHEN R.Temperature < E.MinSafeTemp OR R.Temperature > E.MaxSafeTemp THEN 1 
        ELSE 0
    END AS IsUnsafe
FROM raw_readings AS R LEFT JOIN expectations AS E ON R.DeviceID = E.DeviceID