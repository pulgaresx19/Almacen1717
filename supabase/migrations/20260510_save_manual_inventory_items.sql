-- rpc_save_manual_inventory_items_v2.sql
CREATE OR REPLACE FUNCTION public.save_manual_inventory_items(payload jsonb)
RETURNS void AS $$
DECLARE
  -- Variables for ULD processing
  uld_record jsonb;
  v_uld_id uuid;
  v_uld_pieces int;
  v_uld_weight float;
  
  -- Variables for AWB processing
  awb_record jsonb;
  v_awb_id uuid;
  v_awb_pieces int;
  v_awb_total_pieces int;
  v_awb_weight float;
BEGIN
  -- 1. PROCESS STANDALONE AWBS
  IF payload ? 'awbs' THEN
    FOR awb_record IN SELECT * FROM jsonb_array_elements(payload->'awbs')
    LOOP
      v_awb_pieces := COALESCE((awb_record->>'pieces')::int, 0);
      v_awb_total_pieces := COALESCE((awb_record->>'total_pieces')::int, 0);
      v_awb_weight := COALESCE((awb_record->>'weight')::float, 0);
      
      -- Upsert AWB and dynamically add expected/arrived pieces
      INSERT INTO public.awbs (
          awb_number, total_pieces, total_espected, pieces_received, pieces_arrived, total_weight, created_at
      ) VALUES (
          awb_record->>'awb_number', v_awb_total_pieces, v_awb_pieces, 0, v_awb_pieces, 0, NOW()
      )
      ON CONFLICT (awb_number) DO UPDATE
      SET 
          total_espected = COALESCE(awbs.total_espected, 0) + EXCLUDED.total_espected,
          pieces_arrived = COALESCE(awbs.pieces_arrived, 0) + EXCLUDED.pieces_arrived
      RETURNING id INTO v_awb_id;
      
      -- Insert into awb_splits with origin MANUAL
      INSERT INTO public.awb_splits (
        awb_id, pieces, pieces_arrived, weight, origin, flight_id, uld_id, remarks, data_coordinator, data_location, created_at
      )
      VALUES (
        v_awb_id, v_awb_pieces, v_awb_pieces, v_awb_weight, 'MANUAL', NULL, NULL, awb_record->>'remarks', awb_record->'data_coordinator', awb_record->'data_location', NOW()
      );
      
      -- Update the pieces to the correct values AFTER the awb_splits trigger
      UPDATE public.awbs
      SET pieces_received = (SELECT COALESCE(SUM(pieces), 0) FROM public.awb_splits WHERE awb_id = v_awb_id),
          total_weight = (SELECT COALESCE(SUM(weight), 0) FROM public.awb_splits WHERE awb_id = v_awb_id)
      WHERE id = v_awb_id;
      
    END LOOP;
  END IF;

  -- 2. PROCESS ULDS AND THEIR AWBS
  IF payload ? 'ulds' THEN
    FOR uld_record IN SELECT * FROM jsonb_array_elements(payload->'ulds')
    LOOP
      v_uld_pieces := COALESCE((uld_record->>'pieces')::int, 0);
      v_uld_weight := COALESCE((uld_record->>'weight')::float, 0);
      
      INSERT INTO public.ulds (
         uld_number, 
         pieces_total, 
         weight_total, 
         origin, 
         id_flight, 
         is_break,
         remarks,
         created_at
      )
      VALUES (
         uld_record->>'uld_number',
         v_uld_pieces,
         v_uld_weight,
         'MANUAL',
         NULL,
         false,
         uld_record->>'remarks',
         NOW()
      )
      RETURNING id_uld INTO v_uld_id;
      
      -- Process nested AWBs
      IF uld_record ? 'awbs' THEN
        FOR awb_record IN SELECT * FROM jsonb_array_elements(uld_record->'awbs')
        LOOP
          v_awb_pieces := COALESCE((awb_record->>'pieces')::int, 0);
          v_awb_total_pieces := COALESCE((awb_record->>'total_pieces')::int, 0);
          v_awb_weight := COALESCE((awb_record->>'weight')::float, 0);
          
          -- Upsert AWB and dynamically add expected/arrived pieces
          INSERT INTO public.awbs (
              awb_number, total_pieces, total_espected, pieces_received, pieces_arrived, total_weight, created_at
          ) VALUES (
              awb_record->>'awb_number', v_awb_total_pieces, v_awb_pieces, 0, v_awb_pieces, 0, NOW()
          )
          ON CONFLICT (awb_number) DO UPDATE
          SET 
              total_espected = COALESCE(awbs.total_espected, 0) + EXCLUDED.total_espected,
              pieces_arrived = COALESCE(awbs.pieces_arrived, 0) + EXCLUDED.pieces_arrived
          RETURNING id INTO v_awb_id;
          
          -- Insert into awb_splits linked to ULD
          INSERT INTO public.awb_splits (
            awb_id, pieces, pieces_arrived, weight, origin, flight_id, uld_id, remarks, data_coordinator, data_location, created_at
          )
          VALUES (
            v_awb_id, v_awb_pieces, v_awb_pieces, v_awb_weight, 'MANUAL', NULL, v_uld_id, awb_record->>'remarks', awb_record->'data_coordinator', awb_record->'data_location', NOW()
          );
          
          -- Update the pieces to the correct values AFTER the awb_splits trigger
          UPDATE public.awbs
          SET pieces_received = (SELECT COALESCE(SUM(pieces), 0) FROM public.awb_splits WHERE awb_id = v_awb_id),
              total_weight = (SELECT COALESCE(SUM(weight), 0) FROM public.awb_splits WHERE awb_id = v_awb_id)
          WHERE id = v_awb_id;
          
        END LOOP;
      END IF;
    END LOOP;
  END IF;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
