package com.example.myapplication

import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.postgrest.Postgrest
import io.github.jan.supabase.realtime.Realtime

object SupabaseManager {
    // TODO: Replace with your actual Supabase credentials
    private const val SUPABASE_URL = "https://your-project-id.supabase.co"
    private const val SUPABASE_ANON_KEY = "your-anon-key"

    val client: SupabaseClient by lazy {
        createSupabaseClient(
            supabaseUrl = SUPABASE_URL,
            supabaseKey = SUPABASE_ANON_KEY
        ) {
            install(Postgrest)
            install(Realtime)
        }
    }
}
