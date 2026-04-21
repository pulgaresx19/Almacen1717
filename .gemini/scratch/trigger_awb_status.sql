-- Trigger para actualizar el status de la tabla awbs basado en la nueva lógica

CREATE OR REPLACE FUNCTION update_awb_status_from_pieces()
RETURNS TRIGGER AS $$
DECLARE
    row_data JSON := row_to_json(NEW);
    t_pieces INT;
    r_pieces INT;
    d_pieces INT;
BEGIN
    -- Obtenemos el total de piezas buscando en las posibles columnas (total_pieces, total o total_espected)
    t_pieces := COALESCE(
        (row_data->>'total_pieces')::INT, 
        (row_data->>'total')::INT, 
        (row_data->>'total_espected')::INT, 
        0
    );
    
    r_pieces := COALESCE(NEW.pieces_received, 0);
    d_pieces := COALESCE(NEW.pieces_delivered, 0);

    -- Lógica de estados solicitada:
    IF t_pieces > 0 AND d_pieces >= t_pieces THEN
        -- 1. Cuando el total de piezas corresponda con las entregadas
        NEW.status := 'Ready';
    ELSIF t_pieces > 0 AND r_pieces >= t_pieces THEN
        -- 2. Cuando el total de piezas corresponda con las recibidas
        NEW.status := 'Received';
    ELSIF r_pieces = 0 THEN
        -- 3. Cuando no se ha recibido ninguna pieza
        NEW.status := 'Waiting';
    ELSE
        -- 4. Cuando ya empezaron a recibirse pero aún no llegan al total
        NEW.status := 'Pending';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_awb_status ON awbs;

CREATE TRIGGER trigger_update_awb_status
BEFORE INSERT OR UPDATE OF pieces_received, pieces_delivered
ON awbs
FOR EACH ROW
EXECUTE FUNCTION update_awb_status_from_pieces();
