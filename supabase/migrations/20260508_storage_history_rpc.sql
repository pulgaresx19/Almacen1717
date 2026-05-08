-- 1. Agregar la columna time_deliver a la tabla awbs si no existe
ALTER TABLE awbs ADD COLUMN IF NOT EXISTS time_deliver TIMESTAMPTZ;

-- 2. Actualizar el trigger para que guarde la fecha al cambiar a Delivered
CREATE OR REPLACE FUNCTION update_awb_status_from_pieces()
RETURNS TRIGGER AS $$
DECLARE
    t_pieces INT;
    r_pieces INT;
    d_pieces INT;
    a_pieces INT;
BEGIN
    t_pieces := COALESCE(NEW.total_espected, 0);
    r_pieces := COALESCE(NEW.pieces_received, 0);
    d_pieces := COALESCE(NEW.pieces_delivered, 0);
    a_pieces := COALESCE(NEW.pieces_arrived, 0);

    -- Lógica de la Escalera de 7 Estados:
    IF d_pieces >= t_pieces AND t_pieces > 0 THEN
        NEW.status := 'Delivered';
        IF NEW.time_deliver IS NULL THEN
            NEW.time_deliver := NOW();
        END IF;
    ELSIF d_pieces > 0 THEN
        NEW.status := 'In Process';
        NEW.time_deliver := NULL;
    ELSIF r_pieces >= t_pieces AND t_pieces > 0 THEN
        NEW.status := 'Checked';
        NEW.time_deliver := NULL;
    ELSIF r_pieces > 0 THEN
        NEW.status := 'Checking';
        NEW.time_deliver := NULL;
    ELSIF a_pieces >= t_pieces AND t_pieces > 0 THEN
        NEW.status := 'Received';
        NEW.time_deliver := NULL;
    ELSIF a_pieces > 0 THEN
        NEW.status := 'Receiving';
        NEW.time_deliver := NULL;
    ELSE
        NEW.status := 'Waiting';
        NEW.time_deliver := NULL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Crear el RPC unificado para el resumen de Storage (AWBs y ULDs)
CREATE OR REPLACE FUNCTION rpc_get_storage_deliveries_summary()
RETURNS TABLE (date_group DATE, delivery_count BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.delivered_date AS date_group,
        COUNT(*) AS delivery_count
    FROM (
        -- Seleccionar ULDs entregados
        SELECT DATE("time_deliver") AS delivered_date 
        FROM ulds 
        WHERE status = 'Delivered' AND "time_deliver" IS NOT NULL
        
        UNION ALL
        
        -- Seleccionar AWBs entregados
        SELECT DATE("time_deliver") AS delivered_date 
        FROM awbs 
        WHERE status = 'Delivered' AND "time_deliver" IS NOT NULL
    ) AS d
    GROUP BY d.delivered_date
    ORDER BY d.delivered_date DESC;
END;
$$ LANGUAGE plpgsql;
