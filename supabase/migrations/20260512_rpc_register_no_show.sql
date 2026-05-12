CREATE OR REPLACE FUNCTION rpc_register_no_show(p_id_delivery uuid, p_full_name text)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    -- Update the delivery with the new No Show logic
    UPDATE deliveries
    SET 
        -- 1. Increment the counter
        no_show_count = COALESCE(no_show_count, 0) + 1,
        
        -- 2. Append the new report to the JSONB array
        no_show_report = COALESCE(no_show_report, '[]'::jsonb) || jsonb_build_array(
            jsonb_build_object(
                'user', p_full_name,
                'time', now()
            )
        ),
        
        -- 3. Cancel the delivery if it reaches 3 strikes
        status = CASE 
                    WHEN COALESCE(no_show_count, 0) + 1 >= 3 THEN 'Cancelled'
                    ELSE status 
                 END,
                 
        -- 4. If not cancelled, reset the time to now() to send them to the back of the queue
        "time" = CASE
                    WHEN COALESCE(no_show_count, 0) + 1 < 3 THEN now()
                    ELSE "time"
                 END
    WHERE id_delivery = p_id_delivery;
END;
$$;
