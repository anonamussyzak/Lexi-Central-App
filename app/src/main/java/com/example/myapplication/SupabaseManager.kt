package com.example.myapplication

import android.content.Context
import android.util.Log
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.postgrest.Postgrest
import io.github.jan.supabase.realtime.Realtime
import io.github.jan.supabase.realtime.realtime
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

object SupabaseManager {
    private const val TAG = "SupabaseManager"
    
    private const val DEFAULT_URL = "https://qtxrsgaecxohubhzjtze.supabase.co"
    private const val DEFAULT_KEY = "sb_publishable_gA0nyZfrJrKPx3HRoHAyOQ_5hONZhvL"

    private val _clientFlow = MutableStateFlow<SupabaseClient?>(null)
    val clientFlow = _clientFlow.asStateFlow()

    val client: SupabaseClient?
        get() = _clientFlow.value

    private val scope = CoroutineScope(Dispatchers.Main)

    fun init(context: Context) {
        val prefs = context.getSharedPreferences("app_settings", Context.MODE_PRIVATE)
        val url = prefs.getString("supabase_url", DEFAULT_URL)?.trim() ?: DEFAULT_URL
        val key = prefs.getString("supabase_anon_key", DEFAULT_KEY)?.trim() ?: DEFAULT_KEY

        try {
            if (url.startsWith("https://") && url.length > 20) {
                // Clean up previous connection if any
                _clientFlow.value?.let { oldClient ->
                    scope.launch {
                        try {
                            oldClient.realtime.disconnect()
                        } catch (e: Exception) {
                            Log.e(TAG, "Error disconnecting old client", e)
                        }
                    }
                }

                val newClient = createSupabaseClient(
                    supabaseUrl = url,
                    supabaseKey = key
                ) {
                    install(Postgrest)
                    install(Realtime)
                }
                _clientFlow.value = newClient
                Log.d(TAG, "Supabase initialized successfully with: $url")
            } else {
                Log.w(TAG, "Supabase credentials invalid")
                _clientFlow.value = null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Initialization failed", e)
            _clientFlow.value = null
        }
    }
}
