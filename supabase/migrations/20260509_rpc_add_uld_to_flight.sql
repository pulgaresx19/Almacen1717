CREATE OR REPLACE FUNCTION rpc_add_uld_to_flight(
    p_flight_id UUID,
    p_payload JSONB
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_uld_id UUID;
    v_awb JSONB;
    v_awb_master_id UUID;
    v_house_arr TEXT[];
BEGIN
    -- Insert the ULD
    INSERT INTO ulds (
        id_flight,
        uld_number,
        pieces_total,
        weight_total,
        remarks,
        is_priority,
        is_break
    ) VALUES (
        p_flight_id,
        p_payload->>'uldNumber',
        CAST(NULLIF(p_payload->>'pieces', 'Auto') AS integer),
        CAST(NULLIF(p_payload->>'weight', 'Auto') AS numeric),
        p_payload->>'remarks',
        COALESCE((p_payload->>'priority')::boolean, false),
        COALESCE((p_payload->>'break')::boolean, true)
    ) RETURNING id_uld INTO v_uld_id;

    -- Process AWBs if any
    IF p_payload->'awbs' IS NOT NULL AND jsonb_typeof(p_payload->'awbs') = 'array' THEN
        FOR v_awb IN SELECT * FROM jsonb_array_elements(p_payload->'awbs')
        LOOP
            -- Process house_number
            IF (v_awb->>'house_number') IS NOT NULL AND (v_awb->>'house_number') != '' AND (v_awb->>'house_number') != 'null' THEN
                SELECT array_agg(trim(x)) INTO v_house_arr
                FROM unnest(string_to_array(v_awb->>'house_number', e'\n')) x
                WHERE trim(x) != '';
            ELSE
                v_house_arr := NULL;
            END IF;

            -- Create or get AWB master
            INSERT INTO awbs (
                awb_number,
                total_pieces
            ) VALUES (
                v_awb->>'awb_number',
                CAST(NULLIF(v_awb->>'total', '') AS integer)
            )
            ON CONFLICT (awb_number) DO UPDATE
            SET total_pieces = EXCLUDED.total_pieces
            RETURNING id INTO v_awb_master_id;

            -- Create AWB split
            INSERT INTO awb_splits (
                awb_id,
                uld_id,
                pieces,
                weight,
                house_number,
                remarks,
                status,
                flight_id
            ) VALUES (
                v_awb_master_id,
                v_uld_id,
                CAST(NULLIF(v_awb->>'pieces', '') AS integer),
                CAST(NULLIF(v_awb->>'weight', '') AS numeric),
                v_house_arr,
                v_awb->>'remarks',
                'Pending',
                p_flight_id
            );
        END LOOP;
    END IF;

    RETURN v_uld_id;
END;
$$;
