CREATE OR REPLACE FUNCTION delete_uld_v2(
    p_uld_id UUID
) RETURNS VOID AS $$
DECLARE
    v_status TEXT;
    split_record RECORD;
    v_total_espected NUMERIC;
BEGIN
    -- 1. Check ULD status
    SELECT status INTO v_status FROM ulds WHERE id_uld = p_uld_id;
    
    IF v_status IS NULL THEN
        RAISE EXCEPTION 'ULD not found';
    END IF;
    
    IF LOWER(v_status) != 'waiting' THEN
        RAISE EXCEPTION 'Cannot delete ULD because it is already in process (status: %)', v_status;
    END IF;

    -- 2. Loop through all splits of this ULD
    FOR split_record IN SELECT id, awb_id, pieces, weight FROM awb_splits WHERE uld_id = p_uld_id
    LOOP
        -- Deduct from main AWB
        UPDATE awbs
        SET 
            total_espected = GREATEST(COALESCE(total_espected, 0) - COALESCE(split_record.pieces, 0), 0),
            total_weight = GREATEST(COALESCE(total_weight, 0) - COALESCE(split_record.weight, 0), 0)
        WHERE id = split_record.awb_id
        RETURNING total_espected INTO v_total_espected;
        
        -- If main AWB has 0 expected pieces, delete it
        IF v_total_espected <= 0 THEN
            DELETE FROM awbs WHERE id = split_record.awb_id;
        END IF;
        
        -- Delete the split
        DELETE FROM awb_splits WHERE id = split_record.id;
    END LOOP;
    
    -- 3. Delete the ULD
    DELETE FROM ulds WHERE id_uld = p_uld_id;
END;
$$ LANGUAGE plpgsql;
