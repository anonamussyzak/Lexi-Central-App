import 'react-native-url-polyfill/auto';
import { createClient } from '@supabase/supabase-js';

// Use environment variables for Expo
const supabaseUrl = process.env.EXPO_PUBLIC_SUPABASE_URL || 'https://qtxrsgaecxohubhzjtze.supabase.co';
const supabaseAnonKey = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY || 'sb_publishable_gA0nyZfrJrKPx3HRoHAyOQ_5hONZhvL';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
