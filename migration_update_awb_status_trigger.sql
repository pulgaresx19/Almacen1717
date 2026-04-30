-- Trigger para actualizar el status de la tabla awbs basado en la nueva lógica
CREATE OR REPLACE FUNCTION update_awb_status_from_pieces()
RETURNS TRIGGER AS $$
DECLARE
    t_pieces INT;
    r_pieces INT;
    d_pieces INT;
BEGIN
    t_pieces := COALESCE(NEW.total_espected, 0);
    r_pieces := COALESCE(NEW.pieces_received, 0);
    d_pieces := COALESCE(NEW.pieces_delivered, 0);

    -- Lógica de estados sincronizada con la app móvil:
    IF d_pieces >= t_pieces AND t_pieces > 0 THEN
        NEW.status := 'Delivered';
    ELSIF d_pieces > 0 THEN
        NEW.status := 'In Process';
    ELSIF r_pieces > 0 THEN
        NEW.status := 'Received';
    ELSE
        NEW.status := 'Waiting';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_awb_status ON awbs;

CREATE TRIGGER trigger_update_awb_status
BEFORE INSERT OR UPDATE OF pieces_received, pieces_delivered, total_espected
ON awbs
FOR EACH ROW
EXECUTE FUNCTION update_awb_status_from_pieces();
