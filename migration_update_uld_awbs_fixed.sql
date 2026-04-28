CREATE OR REPLACE FUNCTION update_uld_awbs_v2(
    p_uld_id UUID,
    p_flight_id UUID,
    p_awbs_to_add JSONB,
    p_awbs_to_remove JSONB
) RETURNS VOID AS $$
DECLARE
    awb_record JSONB;
    v_awb_id UUID;
    v_total_pieces INT;
    v_split_pieces INT;
    v_awb_split_id UUID;
BEGIN
    -- 1. Process items to remove
    IF p_awbs_to_remove IS NOT NULL AND jsonb_array_length(p_awbs_to_remove) > 0 THEN
        FOR awb_record IN SELECT * FROM jsonb_array_elements(p_awbs_to_remove)
        LOOP
            v_awb_id := (awb_record->>'awb_id')::UUID;
            
            -- Find the split pieces in awb_splits for this ULD and AWB
            SELECT id, pieces INTO v_awb_split_id, v_split_pieces
            FROM awb_splits
            WHERE uld_id = p_uld_id AND awb_id = v_awb_id
            LIMIT 1;
            
            IF v_awb_split_id IS NOT NULL THEN
                -- Delete the split
                DELETE FROM awb_splits WHERE id = v_awb_split_id;
                
                -- Subtract pieces from main AWB
                UPDATE awbs
                SET total_espected = COALESCE(total_espected, 0) - COALESCE(v_split_pieces, 0)
                WHERE id = v_awb_id
                RETURNING total_espected INTO v_total_pieces;
                
                -- If total_espected is <= 0, delete the main AWB
                IF v_total_pieces <= 0 THEN
                    DELETE FROM awbs WHERE id = v_awb_id;
                END IF;
            END IF;
        END LOOP;
    END IF;

    -- 2. Process items to add
    IF p_awbs_to_add IS NOT NULL AND jsonb_array_length(p_awbs_to_add) > 0 THEN
        FOR awb_record IN SELECT * FROM jsonb_array_elements(p_awbs_to_add)
        LOOP
            v_awb_id := NULL;
            v_split_pieces := (awb_record->>'pieces')::INT;
            
            -- Check if awb_id is provided in the JSON
            IF awb_record->>'awb_id' IS NOT NULL AND awb_record->>'awb_id' != '' THEN
                v_awb_id := (awb_record->>'awb_id')::UUID;
                
                -- Ensure it exists in awbs
                PERFORM id FROM awbs WHERE id = v_awb_id;
                IF NOT FOUND THEN
                    v_awb_id := NULL;
                END IF;
            END IF;
            
            -- If awb_id is still NULL, try to find by awb_number
            IF v_awb_id IS NULL THEN
                SELECT id INTO v_awb_id
                FROM awbs
                WHERE awb_number = awb_record->>'awb_number'
                LIMIT 1;
            END IF;
            
            IF v_awb_id IS NULL THEN
                -- Does not exist, create it
                INSERT INTO awbs (
                    awb_number,
                    total_pieces,
                    total_espected,
                    total_weight
                ) VALUES (
                    awb_record->>'awb_number',
                    COALESCE(NULLIF(awb_record->>'total_pieces', ''), awb_record->>'pieces')::NUMERIC,
                    v_split_pieces,
                    NULLIF(awb_record->>'weight', '')::NUMERIC
                ) RETURNING id INTO v_awb_id;
            ELSE
                -- It exists, add the new pieces to total_espected
                UPDATE awbs
                SET total_espected = COALESCE(total_espected, 0) + COALESCE(v_split_pieces, 0)
                WHERE id = v_awb_id;
            END IF;
            
            -- Insert the split
            INSERT INTO awb_splits (
                uld_id,
                awb_id,
                pieces,
                weight,
                status,
                flight_id,
                house_number,
                remarks
            ) VALUES (
                p_uld_id,
                v_awb_id,
                v_split_pieces,
                NULLIF(awb_record->>'weight', '')::NUMERIC,
                'Pending',
                p_flight_id,
                ARRAY(SELECT jsonb_array_elements_text(CASE WHEN jsonb_typeof(awb_record->'house_number') = 'array' THEN awb_record->'house_number' ELSE '[]'::jsonb END)),
                awb_record->>'remarks'
            );
            
        END LOOP;
    END IF;
END;
$$ LANGUAGE plpgsql;
