CREATE OR REPLACE FUNCTION rpc_coordinator_add_awb(
    p_awb_number TEXT,
    p_pieces INTEGER,
    p_total_pieces INTEGER,
    p_weight NUMERIC,
    p_uld_id UUID,
    p_flight_id UUID,
    p_remarks TEXT,
    p_house_numbers TEXT[]
)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    v_awb_id UUID;
    v_current_awb RECORD;
BEGIN
    -- 1. Check if AWB exists
    SELECT * INTO v_current_awb 
    FROM awbs 
    WHERE awb_number = p_awb_number;
    
    IF FOUND THEN
        -- Update existing AWB
        UPDATE awbs 
        SET 
            total_espected = COALESCE(total_espected, 0) + COALESCE(p_pieces, 0),
            total_weight = COALESCE(total_weight, 0) + COALESCE(p_weight, 0)
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
            p_awb_number,
            p_total_pieces,
            p_pieces,
            p_weight
        ) RETURNING id INTO v_awb_id;
    END IF;

    -- 2. Insert Split
    INSERT INTO awb_splits (
        awb_id,
        flight_id,
        uld_id,
        pieces,
        pieces_arrived,
        weight,
        status,
        house_number,
        remarks,
        is_new
    ) VALUES (
        v_awb_id,
        p_flight_id,
        p_uld_id,
        p_pieces,
        p_pieces,
        p_weight,
        'Pending',
        p_house_numbers,
        CASE WHEN p_remarks <> '' THEN p_remarks ELSE NULL END,
        true
    );

    -- 3. Force update of pieces_arrived to solve the issue
    UPDATE awbs 
    SET 
        pieces_arrived = (SELECT COALESCE(SUM(pieces), 0) FROM awb_splits WHERE awb_id = v_awb_id)
    WHERE id = v_awb_id;

    RETURN jsonb_build_object('success', true, 'awb_id', v_awb_id);

EXCEPTION WHEN OTHERS THEN
    RAISE;
END;
$$;
