-- 20260510_execute_driver_delivery_fix.sql
-- Fixes the function overloading error by dropping the incorrect signature 
-- and re-creating the function with the exact original signature.

-- 1. DROP the incorrect function we just created (the one where p_id_delivery is TEXT and driver_name is last)
DROP FUNCTION IF EXISTS public.execute_driver_delivery(
    UUID, TEXT, BOOLEAN, INT, JSONB, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TIMESTAMPTZ, TEXT
);

-- 2. CREATE OR REPLACE the function with the EXACT original signature 
--    (p_driver_name is 7th, p_id_delivery is UUID)
CREATE OR REPLACE FUNCTION public.execute_driver_delivery(
    p_item_id UUID,
    p_item_number TEXT,
    p_is_uld BOOLEAN,
    p_pieces INT,
    p_reject_data JSONB,
    p_company TEXT,
    p_driver_name TEXT,
    p_door TEXT,
    p_type TEXT,
    p_id_pickup TEXT,
    p_id_delivery UUID,
    p_user_name TEXT,
    p_time TIMESTAMPTZ
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_awb_number TEXT;
    v_uld_number TEXT;
    v_delivery_id UUID;
    v_current_delivered JSONB;
BEGIN
    -- 1. Identify the delivery record using the UUID or pickup string
    IF p_id_delivery IS NOT NULL THEN
        v_delivery_id := p_id_delivery;
    ELSE
        SELECT id_delivery INTO v_delivery_id FROM public.deliveries WHERE id_pickup = p_id_pickup LIMIT 1;
    END IF;

    -- 2. Update delivered_items in deliveries
    IF v_delivery_id IS NOT NULL THEN
        SELECT delivered_items INTO v_current_delivered FROM public.deliveries WHERE id_delivery = v_delivery_id;
        
        UPDATE public.deliveries
        SET delivered_items = COALESCE(v_current_delivered, '[]'::jsonb) || jsonb_build_object(
            'item_id', COALESCE(p_item_id::text, p_item_number),
            'number', p_item_number,
            'pieces', p_pieces,
            'reject_data', p_reject_data,
            'time', p_time,
            'user', p_user_name,
            'driver', p_driver_name
        )
        WHERE id_delivery = v_delivery_id;
    END IF;

    -- 3. Update inventory tables (AWBs / ULDs)
    IF p_is_uld = false THEN
        -- It's an AWB
        v_awb_number := REPLACE(REPLACE(p_item_number, 'AWB: ', ''), 'ULD: ', '');
        
        -- Subtract from pieces_in_process and add to pieces_delivered
        UPDATE public.awbs
        SET 
            pieces_in_process = GREATEST(COALESCE(pieces_in_process, 0) - p_pieces, 0),
            pieces_delivered = COALESCE(pieces_delivered, 0) + p_pieces
        WHERE id = p_item_id OR awb_number = v_awb_number;

    ELSE
        -- It's a ULD
        v_uld_number := REPLACE(REPLACE(p_item_number, 'ULD: ', ''), 'AWB: ', '');
        
        -- Update ULD status and remove in_process flag
        UPDATE public.ulds
        SET 
            status = 'Delivered',
            in_process = false,
            time_deliver = p_time
        WHERE id_uld = p_item_id OR uld_number = v_uld_number;
        
        -- For all AWBs inside this ULD, mark their pieces as delivered and subtract from process
        UPDATE public.awbs
        SET 
            pieces_in_process = GREATEST(COALESCE(pieces_in_process, 0) - COALESCE(pieces_arrived, 0), 0),
            pieces_delivered = COALESCE(pieces_delivered, 0) + COALESCE(pieces_arrived, 0)
        WHERE uld_id = p_item_id;
    END IF;
END;
$$;
