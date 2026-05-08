DROP FUNCTION IF EXISTS rpc_save_coordinator_data(uuid, uuid, uuid, uuid, uuid, int, boolean, text, jsonb, text[], text[], int, uuid);

CREATE OR REPLACE FUNCTION rpc_save_coordinator_data(
    p_split_id UUID,
    p_flight_id UUID,
    p_uld_id UUID,
    p_awb_id UUID,
    p_user_id UUID,
    p_checked_pieces INT,
    p_not_found BOOLEAN,
    p_location TEXT,
    p_data_coordinator JSONB,
    p_damage_type TEXT[],
    p_photo_urls TEXT[],
    p_pieces_damage INT,
    p_existing_damage_id BIGINT
) RETURNS VOID AS $$
BEGIN
    -- Handle Damage Report
    IF p_existing_damage_id IS NOT NULL THEN
        IF p_damage_type IS NULL AND p_photo_urls IS NULL AND COALESCE(p_pieces_damage, 0) = 0 THEN
            -- Delete if everything is empty
            DELETE FROM damage_reports WHERE id = p_existing_damage_id;
        ELSE
            -- Update existing
            UPDATE damage_reports 
            SET damage_type = p_damage_type,
                photo_urls = to_jsonb(p_photo_urls),
                pieces_damage = p_pieces_damage
            WHERE id = p_existing_damage_id;
        END IF;
    ELSE
        -- Insert new if data is provided
        IF p_damage_type IS NOT NULL OR p_photo_urls IS NOT NULL OR COALESCE(p_pieces_damage, 0) > 0 THEN
            INSERT INTO damage_reports (flight_id, uld_id, awb_id, user_id, damage_type, photo_urls, pieces_damage)
            VALUES (p_flight_id, p_uld_id, p_awb_id, p_user_id, p_damage_type, to_jsonb(p_photo_urls), p_pieces_damage);
        END IF;
    END IF;

    -- Handle AWB Split Coordinator Data
    IF p_split_id IS NOT NULL THEN
        UPDATE awb_splits
        SET data_coordinator = p_data_coordinator,
            total_checked = p_checked_pieces,
            not_found = p_not_found,
            required_location = p_location
        WHERE id = p_split_id;
    END IF;
END;
$$ LANGUAGE plpgsql;
