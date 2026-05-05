-- Función RPC para Auto-Chequear los ULDs No-Break al recibirlos
CREATE OR REPLACE FUNCTION rpc_autocheck_nobreak_uld(
    p_uld_id UUID,
    p_is_received BOOLEAN
)
RETURNS void AS $$
BEGIN
    -- Si el ULD es marcado como "Recibido"
    IF p_is_received THEN
        UPDATE awb_splits
        SET total_checked = pieces
        WHERE uld_id = p_uld_id;
    -- Si el usuario desmarca el "Recibido"
    ELSE
        UPDATE awb_splits
        SET total_checked = 0
        WHERE uld_id = p_uld_id;
    END IF;
END;
$$ LANGUAGE plpgsql;
