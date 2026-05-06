CREATE OR REPLACE FUNCTION rpc_save_delivery(payload jsonb)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    item jsonb;
    item_pcs integer;
    item_awb_num text;
    item_uld_id uuid;
BEGIN
    -- 1. Insert into deliveries table
    INSERT INTO deliveries (
        company, 
        driver_name, 
        door, 
        id_pickup, 
        type, 
        "time", 
        remarks, 
        is_priority, 
        list_deliver, 
        total_pieces, 
        total_weight, 
        all_uld
    ) VALUES (
        payload->>'company',
        payload->>'driver_name',
        payload->>'door',
        payload->>'id_pickup',
        payload->>'type',
        (payload->>'time')::timestamptz,
        payload->>'remarks',
        (payload->>'is_priority')::boolean,
        payload->'list_deliver',
        (payload->>'total_pieces')::integer,
        (payload->>'total_weight')::numeric,
        (payload->>'all_uld')::boolean
    );

    -- 2. Update AWBs and ULDs if type is not 'Import'
    IF (payload->>'type') != 'Import' THEN
        FOR item IN SELECT * FROM jsonb_array_elements(payload->'list_deliver')
        LOOP
            -- If it's an AWB
            IF item ? 'awb_id' OR item ? 'awb_number' THEN
                item_awb_num := item->>'awb_number';
                item_pcs := (item->>'found')::integer;
                
                IF item_pcs > 0 THEN
                    UPDATE awbs 
                    SET pieces_in_process = COALESCE(pieces_in_process, 0) + item_pcs
                    WHERE awb_number = item_awb_num;
                END IF;
            END IF;

            -- If it's a ULD
            IF item ? 'uld_id' THEN
                item_uld_id := (item->>'uld_id')::uuid;
                
                UPDATE ulds 
                SET in_process = true
                WHERE id_uld = item_uld_id;
            END IF;
        END LOOP;
    END IF;
END;
$$;
