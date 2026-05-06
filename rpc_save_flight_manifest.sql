CREATE OR REPLACE FUNCTION rpc_save_flight_manifest(payload JSONB)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    v_flight_id UUID;
    v_uld_id UUID;
    v_awb_id UUID;
    
    v_uld JSONB;
    v_awb JSONB;
    v_current_awb RECORD;
BEGIN
    -- 1. Insert Flight
    INSERT INTO flights (
        carrier,
        number,
        date,
        time_delay,
        cant_break,
        cant_nobreak,
        remarks,
        status
    ) VALUES (
        payload->>'carrier',
        payload->>'number',
        (payload->>'date')::timestamp,
        (payload->>'time_delay')::timestamp,
        (payload->>'cant_break')::integer,
        (payload->>'cant_nobreak')::integer,
        payload->>'remarks',
        payload->>'status'
    ) RETURNING id_flight INTO v_flight_id;
    
    -- 2. Loop through ULDs
    FOR v_uld IN SELECT * FROM jsonb_array_elements(payload->'flightLocalUlds')
    LOOP
        INSERT INTO ulds (
            uld_number,
            pieces_total,
            weight_total,
            is_break,
            is_priority,
            status,
            id_flight
        ) VALUES (
            v_uld->>'uldNumber',
            (v_uld->>'pieces')::integer,
            (v_uld->>'weight')::numeric,
            (v_uld->>'break')::boolean,
            (v_uld->>'priority')::boolean,
            'Waiting',
            v_flight_id
        ) RETURNING id_uld INTO v_uld_id;
        
        -- 3. Loop through AWBs inside ULD
        FOR v_awb IN SELECT * FROM jsonb_array_elements(v_uld->'awbs')
        LOOP
            IF v_awb->>'awb_number' IS NOT NULL AND v_awb->>'awb_number' <> '' THEN
                
                -- Check if AWB exists
                SELECT * INTO v_current_awb 
                FROM awbs 
                WHERE awb_number = v_awb->>'awb_number';
                
                IF FOUND THEN
                    -- Update existing AWB
                    UPDATE awbs 
                    SET 
                        total_espected = COALESCE(total_espected, 0) + COALESCE((v_awb->>'pieces')::integer, 0),
                        total_weight = COALESCE(total_weight, 0) + COALESCE((v_awb->>'weight')::numeric, 0)
                    WHERE id = v_current_awb.id
                    RETURNING id INTO v_awb_id;
                ELSE
                    -- Insert new AWB
                    INSERT INTO awbs (
                        awb_number,
                        total_pieces,
                        total_espected,
                        total_weight
                    ) VALUES (
                        v_awb->>'awb_number',
                        (v_awb->>'total')::integer,
                        (v_awb->>'pieces')::integer,
                        (v_awb->>'weight')::numeric
                    ) RETURNING id INTO v_awb_id;
                END IF;
                
                -- Handle house_number array casting safely
                DECLARE
                    v_house_arr TEXT[] := NULL;
                BEGIN
                    IF v_awb->>'house_number' IS NOT NULL AND v_awb->>'house_number' <> '' THEN
                        IF jsonb_typeof(v_awb->'house_number') = 'array' THEN
                            v_house_arr := ARRAY(SELECT jsonb_array_elements_text(v_awb->'house_number'));
                        ELSE
                            v_house_arr := ARRAY[v_awb->>'house_number'];
                        END IF;
                    END IF;
                    
                    -- Insert Split
                    INSERT INTO awb_splits (
                        awb_id,
                        flight_id,
                        uld_id,
                        pieces,
                        weight,
                        status,
                        house_number,
                        remarks
                    ) VALUES (
                        v_awb_id,
                        v_flight_id,
                        v_uld_id,
                        (v_awb->>'pieces')::integer,
                        (v_awb->>'weight')::numeric,
                        'Pending',
                        v_house_arr,
                        CASE WHEN v_awb->>'remarks' <> '' THEN v_awb->>'remarks' ELSE NULL END
                    );
                END;
                
            END IF;
        END LOOP;
    END LOOP;
    
    RETURN jsonb_build_object('success', true, 'flight_id', v_flight_id);
    
EXCEPTION WHEN OTHERS THEN
    RAISE;
END;
$$;
