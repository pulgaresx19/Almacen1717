CREATE OR REPLACE FUNCTION rpc_get_damages_summary()
RETURNS TABLE (date_group DATE, damage_count BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        DATE("created_at") AS date_group,
        COUNT(*) AS damage_count
    FROM damage_reports
    WHERE "created_at" IS NOT NULL
    GROUP BY DATE("created_at")
    ORDER BY DATE("created_at") DESC;
END;
$$ LANGUAGE plpgsql;
