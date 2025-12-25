-- Initialize schema for DEVICE_EXPECTATIONS
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

-- Initialize schema for DEVICE_READINGS
CREATE TABLE DEVICE_READINGS (
    ReadingID VARCHAR(20) NOT NULL,
    DeviceID VARCHAR(20) NOT NULL,
    Temperature DECIMAL(5,2) NOT NULL,
    Humidity DECIMAL(5,2) NOT NULL,
    RecordedAt DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (ReadingID),
    FOREIGN KEY (DeviceID) REFERENCES DEVICE_EXPECTATIONS(DeviceID)
);

-- Sample Data for DEVICE_EXPECTATIONS
INSERT INTO DEVICE_EXPECTATIONS(DeviceID, LocationName, MinSafeTemp, MaxSafeTemp, MinSafeHumidity, MaxSafeHumidity)
VALUES ('Device_1', 'Location 1', 15.00, 30.00, 0, 50);

-- View encompassing DEVICE_READINGS and DEVICE_EXPECTATIONS - with filters for safe and unsafe
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

-- SELECT top entries from DEVICE_READINGS and CLINICAL_MONITOR_VIEW
SELECT TOP 20 * FROM DEVICE_READINGS ORDER BY RecordedAt DESC;
SELECT TOP 20 * FROM CLINICAL_MONITOR_VIEW ORDER BY RecordedAt DESC;

-- Delete readings that may be incorrect
DELETE FROM DEVICE_READINGS
WHERE Temperature < 0.00 OR Temperature > 50.00
OR Humidity < 20.00 OR Humidity > 90.00;

-- Schema for device metrics by hour
CREATE TABLE HOURLY_DEVICE_SUMMARY (
    SummaryID INT IDENTITY(1,1) PRIMARY KEY,
    DeviceID VARCHAR(20) NOT NULL,
    LogHour DATETIME NOT NULL,
    AvgTemperature DECIMAL(5,2),
    AvgHumidity DECIMAL(5,2),
    ReadingCount INT,
    FOREIGN KEY (DeviceID) REFERENCES DEVICE_EXPECTATIONS(DeviceID)
)

-- Add data from DEVICE_READINGS into HOURLY_DEVICE_SUMMARY
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

-- Get top entries from HOURLY_DEVICE_SUMMARY
SELECT TOP 20 * FROM HOURLY_DEVICE_SUMMARY ORDER BY LogHour DESC;

-- Control Table, representing the physical state of the freezer motors
CREATE TABLE equipment_state (
    DeviceID INT,
    FanStatus VARCHAR(10), -- 'ON' or 'OFF'
    LastUpdated DATETIME DEFAULT GETDATE()
);

-- Trigger which checks the logic for each new reading
CREATE TRIGGER trg_ThermostatControl
ON device_readings
AFTER INSERT AS
BEGIN
    -- 1. Get the latest reading and safe limits
    DECLARE @Temp FLOAT, @MaxSafe FLOAT, @DeviceID INT;

    SELECT @Temp = i.Temperature, @DeviceID = i.DeviceID FROM inserted i;

    -- Simplified hardcoding limit for demo - could be joined with expectations table
    SET @MaxSafe = 40; 

    -- 2. The Control Logic (If Temp > Setpoint, Turn Fan ON)
    IF @Temp > @MaxSafe
    BEGIN
        UPDATE equipment_state
        SET FanStatus = 'ON', LastUpdated = GETDATE()
        WHERE DeviceID = @DeviceID;
    END
    ELSE
    BEGIN
        UPDATE equipment_state
        SET FanStatus = 'OFF', LastUpdated = GETDATE()
        WHERE DeviceID = @DeviceID;
    END
END