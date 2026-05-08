CREATE OR REPLACE FUNCTION rpc_get_deliveries_summary()
RETURNS TABLE (date_group DATE, delivery_count BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        DATE("time") AS date_group, 
        COUNT(*) AS delivery_count
    FROM deliveries
    WHERE "time" IS NOT NULL
    GROUP BY DATE("time")
    ORDER BY DATE("time") DESC;
END;
$$ LANGUAGE plpgsql;
