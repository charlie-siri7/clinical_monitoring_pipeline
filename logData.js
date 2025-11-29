module.exports = async (request, context) => {
    context.log("Processing Request");

    try {
        /*
        Parse the JSON from Arduino
        Example: { "device_id": "Device_1", "temperature": 25.5, "humidity": 60.0 }
        */
        const data = request.body;

        // Generate ID
        const generatedId = Date.now().toString() + '-' + Math.floor(Math.random() * 1000).toString();

        // Map JSON data from Arduino to SQL columns
        const sqlRow = {
            ReadingID: generatedId,
            DeviceID: data.device_id,
            Temperature: data.temperature,
            Humidity: data.humidity
            // RecordedAt is skipped because the default option is a GETDATE() call
        };

        context.bindings.sqlOutput = sqlRow;

        context.res = {
            status: 200,
            body: "Data Saved to SQL!"
        };

    } catch (error) {
        context.log.error(error);
        // A common case: if DeviceID doesn't exist in DEVICE_EXPECTATIONS
        context.res = {
            status: 500,
            body: "Error: " + error.message
        };
    }
}