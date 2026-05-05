-- Función RPC para procesar la llegada de CUALQUIER ULD a la puerta
CREATE OR REPLACE FUNCTION rpc_receive_uld(
    p_uld_id UUID,
    p_is_received BOOLEAN,
    p_is_break BOOLEAN
)
RETURNS void AS $$
BEGIN
    IF p_is_received THEN
        -- 1. Para TODOS los ULDs, marcamos que sus piezas ya llegaron a la puerta
        UPDATE awb_splits
        SET pieces_arrived = pieces
        WHERE uld_id = p_uld_id;

        -- 2. Si resulta que es No-Break, ADEMÁS saltamos directo a "Checked"
        IF p_is_break = false THEN
            UPDATE awb_splits
            SET total_checked = pieces
            WHERE uld_id = p_uld_id;
        END IF;

    ELSE
        -- Revertimos si el usuario quita el Check por error
        UPDATE awb_splits
        SET pieces_arrived = 0
        WHERE uld_id = p_uld_id;

        IF p_is_break = false THEN
            UPDATE awb_splits
            SET total_checked = 0
            WHERE uld_id = p_uld_id;
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;
