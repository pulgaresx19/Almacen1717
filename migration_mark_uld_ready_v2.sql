CREATE OR REPLACE FUNCTION mark_uld_ready_v2(
    p_uld_id uuid,
    p_flight_id uuid,
    p_user_fullname text,
    p_discrepancies jsonb
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_now timestamptz := now();
    v_now_text text;
BEGIN
    -- Obtenemos la hora exacta en formato ISO8601 para mantener consistencia con la App
    v_now_text := to_char(v_now AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"');

    -- Actualizamos el ULD
    UPDATE ulds 
    SET 
        time_checked = v_now,
        user_checked = p_user_fullname,
        discrepancies_summary = p_discrepancies
    WHERE id_uld = p_uld_id;

    -- Actualizamos el vuelo si start_break está nulo
    IF p_flight_id IS NOT NULL THEN
        UPDATE flights 
        SET start_break = v_now
        WHERE id_flight = p_flight_id 
          AND start_break IS NULL;
    END IF;

    -- Devolvemos la hora para que la App pueda actualizar su estado localmente
    RETURN v_now_text;
END;
$$;
