import { app } from '@azure/functions';

// Define SQL output to match table
const sqlOutput = {
    type: 'sql',
    commandText: 'dbo.DEVICE_READINGS', // Match table name
    connectionStringSetting: 'SqlConnectionString',
    name: 'sqlOutput'
};

app.http('logTemperature', {
    methods: ['POST'],
    authLevel: 'function',
    extraOutputs: [sqlOutput],
    handler: async (request, context) => {
        context.log(`Processing request for url "${request.url}"`);

        try {
            /*
             Parse the JSON from Arduino
             Example: { "device_id": "Device_1", "temperature": 25.5, "humidity": 60.0 }
             */
            const incomingData = await request.json();

            // Generate ID
            const generatedId = Date.now().toString() + '-' + Math.floor(Math.random() * 10000).toString();

            // Map JSON data from Arduino to SQL columns
            const sqlRow = {
                ReadingID: generatedId,
                DeviceID: incomingData.device_id,
                Temperature: incomingData.temperature,
                Humidity: incomingData.humidity
                // RecordedAt is skipped because the default option is a GETDATE() call
            };

            // Send to SQL
            context.extraOutputs.set(sqlOutput, sqlRow);

            return { body: "Data successfully saved to DEVICE_READINGS." };

        } catch (error) {
            context.log.error(error);
            // A common case: if DeviceID doesn't exist in DEVICE_EXPECTATIONS
            return { status: 500, body: "Error: " + error.message };
        }
    }
});