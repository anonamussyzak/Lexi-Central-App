import 'react-native-url-polyfill/auto';
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://qtxrsgaecxohubhzjtze.supabase.co';
const supabaseAnonKey = 'sb_publishable_gA0nyZfrJrKPx3HRoHAyOQ_5hONZhvL';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
