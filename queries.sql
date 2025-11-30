-- Query 1
CREATE TABLE DEVICE_EXPECTATIONS (
    DeviceID VARCHAR(20) NOT NULL,
    LocationName VARCHAR(50) NOT NULL,
    MinSafeTemp DECIMAL(5,2) NOT NULL,
    MaxSafeTemp DECIMAL(5,2) NOT NULL,
    MinSafeHumidity DECIMAL(5,2) NOT NULL,
    MaxSafeHumidity DECIMAL(5,2) NOT NULL,
    Active TINYINT DEFAULT 1,
    PRIMARY KEY (DeviceID)
);

-- Query 2
CREATE TABLE DEVICE_READINGS (
    ReadingID VARCHAR(20) NOT NULL,
    DeviceID VARCHAR(20) NOT NULL,
    Temperature DECIMAL(5,2) NOT NULL,
    Humidity DECIMAL(5,2) NOT NULL,
    RecordedAt DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (ReadingID),
    FOREIGN KEY (DeviceID) REFERENCES DEVICE_EXPECTATIONS(DeviceID)
);

-- Query 3
INSERT INTO DEVICE_EXPECTATIONS(DeviceID, LocationName, MinSafeTemp, MaxSafeTemp, MinSafeHumidity, MaxSafeHumidity)
VALUES ('Device_1', 'Location 1', 15.00, 30.00, 0, 50);

-- Query 4
CREATE VIEW CLINICAL_MONITOR_VIEW
AS 
SELECT DR.ReadingID, DE.LocationName, DR.Temperature, DR.Humidity, DR.RecordedAt, 'SAFE' AS Status
FROM DEVICE_READINGS AS DR
JOIN DEVICE_EXPECTATIONS AS DE
ON DR.DeviceID = DE.DeviceID
WHERE (DR.Temperature BETWEEN DE.MinSafeTemp AND DE.MaxSafeTemp)
AND (DR.Humidity BETWEEN DE.MinSafeHumidity AND DE.MaxSafeHumidity)

UNION ALL

SELECT DR.ReadingID, DE.LocationName, DR.Temperature, DR.Humidity, DR.RecordedAt, 'UNSAFE' AS Status
FROM DEVICE_READINGS AS DR
JOIN DEVICE_EXPECTATIONS AS DE
ON DR.DeviceID = DE.DeviceID
WHERE (DR.Temperature NOT BETWEEN DE.MinSafeTemp AND DE.MaxSafeTemp)
OR (DR.Humidity NOT BETWEEN DE.MinSafeHumidity AND DE.MaxSafeHumidity)

-- Query 5
SELECT TOP 20 * FROM DEVICE_READINGS ORDER BY RecordedAt DESC;

-- Query 6
SELECT TOP 20 * FROM CLINICAL_MONITOR_VIEW ORDER BY RecordedAt DESC;

-- Query 7
DELETE FROM DEVICE_READINGS
WHERE Temperature < 0.00 OR Temperature > 50.00
OR Humidity < 20.00 OR Humidity > 90.00;

-- Query 8
CREATE TABLE HOURLY_DEVICE_SUMMARY (
    SummaryID INT IDENTITY(1,1) PRIMARY KEY,
    DeviceID VARCHAR(20) NOT NULL,
    LogHour DATETIME NOT NULL,
    AvgTemperature DECIMAL(5,2),
    AvgHumidity DECIMAL(5,2),
    ReadingCount INT,
    FOREIGN KEY (DeviceID) REFERENCES DEVICE_EXPECTATIONS(DeviceID)
)

-- Query 9
INSERT INTO HOURLY_DEVICE_SUMMARY(DeviceID, LogHour, AvgTemperature, AvgHumidity, ReadingCount)
SELECT 
    DeviceID,
    DATEADD(hour, DATEDIFF(hour, 0, RecordedAt), 0) AS LogHour, 
    AVG(Temperature) AS AvgTemperature,
    AVG(Humidity) AS AvgHumidity,
    COUNT(*) AS ReadingCount
FROM DEVICE_READINGS
WHERE 
    (Temperature BETWEEN 0 AND 50) AND (Humidity BETWEEN 20 AND 90)
GROUP BY 
    DeviceID, 
    DATEADD(hour, DATEDIFF(hour, 0, RecordedAt), 0)
ORDER BY 
    LogHour DESC;

-- Query 10
SELECT TOP 20 * FROM HOURLY_DEVICE_SUMMARY ORDER BY LogHour DESC;