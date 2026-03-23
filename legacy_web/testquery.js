require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const supabaseUrl = 'https://cleqppfzfuljynhxjlst.supabase.co';
const supabaseKey = 'sb_publishable_GxFV2KWcAm9HggC1u-byFg_53EJfJrH';
const supabase = createClient(supabaseUrl, supabaseKey);

async function checkAwb() {
    console.log("Checking AWB");
    const { data, error } = await supabase.from('AWB').select('*').limit(3);
    console.log(data, error);
    
    // Check if there's an AWWB table
    const { data: data2, error: err2 } = await supabase.from('AWWB').select('*').limit(3);
    console.log("AWWB:", data2, err2);
}
checkAwb();
