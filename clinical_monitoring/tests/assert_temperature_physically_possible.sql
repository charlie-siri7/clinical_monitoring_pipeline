-- Should fail if any rows are returned - looking for impossible temperatures (< -100)
SELECT * FROM {{ ref('clinical_monitor') }} WHERE Temperature < -100