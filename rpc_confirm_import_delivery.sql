CREATE OR REPLACE FUNCTION rpc_confirm_import_delivery(payload jsonb)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_awb_number text;
    v_total_pieces integer;
    v_total_weight numeric;
    v_pieces_checked integer;
    
    v_awb_id uuid;
    v_flight_id uuid;
    v_uld_id uuid;
    
    v_data_coordinator jsonb;
    v_data_location jsonb;
    v_remarks text;
    
    v_damage_type text[];
    v_photo_urls jsonb;
    v_damage_remarks text;
    v_pieces_damage integer;
    v_user_id uuid;
BEGIN
    -- Extract values from payload
    v_awb_number := payload->>'awb_number';
    v_total_pieces := (payload->>'total_pieces')::integer;
    v_total_weight := (payload->>'total_weight')::numeric;
    v_pieces_checked := (payload->>'pieces_checked')::integer;
    
    v_data_coordinator := payload->'data_coordinator';
    v_data_location := payload->'data_location';
    v_remarks := payload->>'remarks';
    
    v_user_id := (payload->>'user_id')::uuid;
    
    -- Damage details (can be null)
    v_damage_type := string_to_array(payload->>'damage_type', ', ');
    v_photo_urls := payload->'photo_urls';
    v_damage_remarks := payload->>'damage_remarks';
    v_pieces_damage := (payload->>'pieces_damage')::integer;

    -- 1. Upsert into awbs table
    SELECT id INTO v_awb_id FROM awbs WHERE awb_number = v_awb_number LIMIT 1;
    
    -- v_flight_id remains NULL because Import AWBs do not necessarily have a flight
    -- explicitly passing NULL prevents default value constraints from firing.
    
    IF v_awb_id IS NULL THEN
        -- Create new AWB
        INSERT INTO awbs (
            awb_number,
            total_pieces,
            total_weight,
            total_espected, 
            pieces_arrived,
            pieces_received
        ) VALUES (
            v_awb_number,
            v_total_pieces,
            v_total_weight,
            v_pieces_checked,
            v_pieces_checked,
            v_pieces_checked
        ) RETURNING id INTO v_awb_id;
    ELSE
        -- Update existing AWB (Accumulate)
        UPDATE awbs
        SET 
            total_weight = COALESCE(total_weight, 0) + COALESCE(v_total_weight, 0),
            total_espected = COALESCE(total_espected, 0) + v_pieces_checked,
            pieces_arrived = COALESCE(pieces_arrived, 0) + v_pieces_checked,
            pieces_received = COALESCE(pieces_received, 0) + v_pieces_checked
        WHERE id = v_awb_id;
    END IF;

    -- 2. Insert into awb_splits (intermediate table)
    INSERT INTO awb_splits (
        awb_id,
        flight_id,
        uld_id,
        total_checked,
        pieces_arrived,
        weight,
        data_coordinator,
        data_location,
        remarks,
        origin
    ) VALUES (
        v_awb_id,
        v_flight_id,
        v_uld_id,
        v_pieces_checked,
        v_pieces_checked,
        v_total_weight,
        v_data_coordinator,
        v_data_location,
        v_remarks,
        'Import'
    );

    -- 3. Insert into damage_reports if applicable
    IF COALESCE(v_pieces_damage, 0) > 0 
       OR (jsonb_typeof(v_photo_urls) = 'array' AND jsonb_array_length(v_photo_urls) > 0) 
       OR v_damage_remarks IS NOT NULL 
       OR (v_damage_type IS NOT NULL AND array_length(v_damage_type, 1) > 0) THEN
        INSERT INTO damage_reports (
            awb_id,
            flight_id,
            uld_id,
            damage_type,
            photo_urls,
            pieces_damage,
            remarks,
            origin,
            user_id
        ) VALUES (
            v_awb_id,
            v_flight_id,
            v_uld_id,
            v_damage_type,
            v_photo_urls,
            COALESCE(v_pieces_damage, 0),
            COALESCE(v_damage_remarks, ''),
            'Import',
            v_user_id
        );
    END IF;

END;
$$;
