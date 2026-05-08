import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { PDFDocument, rgb, StandardFonts, PageSizes } from "https://esm.sh/pdf-lib@1.17.1";

serve(async (req) => {
  // CORS configuration
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  };

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { damage_id, selected_photos } = await req.json();

    if (!damage_id) {
      return new Response(JSON.stringify({ error: 'damage_id is required' }), { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }, 
        status: 400 
      });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
    const authHeader = req.headers.get('Authorization');

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader || '' } }
    });

    // Fetch damage details
    const { data: damage, error } = await supabase
      .from('damage_reports')
      .select('*, flights(*), ulds(*), awbs(*)')
      .eq('id', damage_id)
      .single();

    if (error || !damage) {
      return new Response(JSON.stringify({ error: 'Damage not found or unauthorized' }), { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }, 
        status: 404 
      });
    }

    // Determine which photos to use (client can pass selected_photos to filter)
    let photoUrls = damage.photo_urls || [];
    if (selected_photos && Array.isArray(selected_photos) && selected_photos.length > 0) {
      photoUrls = selected_photos;
    }
    // Hard limit to 9 photos
    photoUrls = photoUrls.slice(0, 9);

    // Create PDF
    const pdfDoc = await PDFDocument.create();
    const page = pdfDoc.addPage(PageSizes.A4);
    const { height } = page.getSize();
    
    const font = await pdfDoc.embedFont(StandardFonts.Helvetica);
    const boldFont = await pdfDoc.embedFont(StandardFonts.HelveticaBold);

    // Draw header and details (basic text layout)
    page.drawText('DAMAGE REPORT', { x: 50, y: height - 50, size: 18, font: boldFont, color: rgb(0.2, 0.2, 0.2) });
    
    const flightInfo = damage.flights?.flight_number ? `${damage.flights.flight_number} - ${damage.flights.destination}` : 'N/A';
    const uldInfo = damage.ulds?.uld_number ?? 'N/A';
    const awbInfo = damage.awbs?.awb_number ?? 'N/A';
    const reportedBy = damage.processed_by ?? 'N/A';
    const damageType = Array.isArray(damage.damage_type) ? damage.damage_type.join(', ') : (damage.damage_type || 'N/A');

    page.drawText(`FLIGHT: ${flightInfo}`, { x: 50, y: height - 90, size: 10, font: boldFont });
    page.drawText(`ULD: ${uldInfo}`, { x: 200, y: height - 90, size: 10, font: boldFont });
    page.drawText(`AWB: ${awbInfo}`, { x: 350, y: height - 90, size: 10, font: boldFont });

    page.drawText(`REPORTED BY: ${reportedBy}`, { x: 50, y: height - 110, size: 10, font: boldFont });
    page.drawText(`DAMAGE TYPE: ${damageType}`, { x: 200, y: height - 110, size: 10, font: boldFont });
    page.drawText(`PIECES DAMAGED: ${damage.pieces_damage || 0}`, { x: 50, y: height - 130, size: 10, font: boldFont });
    
    const remarks = damage.remarks || 'N/A';
    // Quick and dirty line wrapping for remarks
    const wrappedRemarks = remarks.length > 80 ? remarks.substring(0, 80) + '...' : remarks;
    page.drawText(`REMARKS: ${wrappedRemarks}`, { x: 200, y: height - 130, size: 10, font: font });

    // Fetch and embed photos
    const imgSize = 150;
    const padding = 15;
    let yOffset = height - 180;
    let xOffset = 50;

    const imgFetchPromises = photoUrls.map(async (url: string) => {
      try {
        const res = await fetch(url);
        if (!res.ok) return null;
        const arrayBuffer = await res.arrayBuffer();
        const bytes = new Uint8Array(arrayBuffer);
        
        // Simple magic bytes check to determine Jpg vs Png
        // JPEG starts with FF D8
        // PNG starts with 89 50 4E 47
        if (bytes[0] === 0xFF && bytes[1] === 0xD8) {
          return await pdfDoc.embedJpg(bytes);
        } else if (bytes[0] === 0x89 && bytes[1] === 0x50) {
          return await pdfDoc.embedPng(bytes);
        }
        return null;
      } catch (e) {
        console.error('Error fetching image', e);
        return null;
      }
    });

    const embeddedImages = await Promise.all(imgFetchPromises);

    let rowCount = 0;
    let colCount = 0;
    
    for (const image of embeddedImages) {
      if (!image) continue; // skip failed images
      
      // Calculate aspect ratio to fit within imgSize x imgSize bounding box
      const imgDims = image.scaleToFit(imgSize, imgSize);
      
      page.drawImage(image, {
        x: xOffset + (colCount * (imgSize + padding)),
        y: yOffset - (rowCount * (imgSize + padding)) - imgDims.height,
        width: imgDims.width,
        height: imgDims.height,
      });

      colCount++;
      if (colCount >= 3) {
        colCount = 0;
        rowCount++;
      }
    }

    const pdfBytes = await pdfDoc.save();

    return new Response(pdfBytes, {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/octet-stream',
        'Content-Disposition': `attachment; filename="DamageReport_${awbInfo}.pdf"`,
      },
    });

  } catch (error: any) {
    console.error('Edge Function Error:', error);
    return new Response(JSON.stringify({ error: error.message }), { 
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }, 
      status: 500 
    });
  }
});
