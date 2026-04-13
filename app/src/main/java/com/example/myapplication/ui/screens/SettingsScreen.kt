package com.example.myapplication.ui.screens

import android.content.Context
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Done
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.example.myapplication.SupabaseManager
import com.example.myapplication.ui.theme.KirbyTheme

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen() {
    val context = LocalContext.current
    
    val prefs = remember(context) { 
        context.getSharedPreferences("app_settings", Context.MODE_PRIVATE) 
    }
    
    var supabaseUrl by remember { 
        mutableStateOf(prefs.getString("supabase_url", "https://qtxrsgaecxohubhzjtze.supabase.co") ?: "https://qtxrsgaecxohubhzjtze.supabase.co") 
    }
    var supabaseKey by remember { 
        mutableStateOf(prefs.getString("supabase_anon_key", "sb_publishable_gA0nyZfrJrKPx3HRoHAyOQ_5hONZhvL") ?: "sb_publishable_gA0nyZfrJrKPx3HRoHAyOQ_5hONZhvL") 
    }
    
    var showSavedMessage by remember { mutableStateOf(false) }

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = MaterialTheme.colorScheme.background
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp)
                .verticalScroll(rememberScrollState())
        ) {
            Text(
                text = "Settings",
                style = MaterialTheme.typography.headlineMedium,
                color = MaterialTheme.colorScheme.primary
            )
            
            Spacer(modifier = Modifier.height(24.dp))

            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(24.dp),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surface,
                ),
                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "Supabase Configuration",
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.primary
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    OutlinedTextField(
                        value = supabaseUrl,
                        onValueChange = { supabaseUrl = it },
                        label = { Text("Supabase URL") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                        shape = RoundedCornerShape(12.dp)
                    )
                    
                    Spacer(modifier = Modifier.height(12.dp))
                    
                    OutlinedTextField(
                        value = supabaseKey,
                        onValueChange = { supabaseKey = it },
                        label = { Text("Anon Key") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                        shape = RoundedCornerShape(12.dp)
                    )
                    
                    Spacer(modifier = Modifier.height(24.dp))
                    
                    Button(
                        onClick = {
                            prefs.edit().apply {
                                putString("supabase_url", supabaseUrl.trim())
                                putString("supabase_anon_key", supabaseKey.trim())
                                apply()
                            }
                            
                            // Re-initialize the manager to update the flow
                            SupabaseManager.init(context)
                            showSavedMessage = true
                        },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(16.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
                    ) {
                        Icon(Icons.Default.Done, contentDescription = null)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Save Configuration")
                    }
                }
            }
            
            if (showSavedMessage) {
                AlertDialog(
                    onDismissRequest = { showSavedMessage = false },
                    confirmButton = {
                        TextButton(onClick = { showSavedMessage = false }) {
                            Text("OK")
                        }
                    },
                    title = { Text("Success") },
                    text = { Text("Settings saved and Supabase client reloaded.") },
                    shape = RoundedCornerShape(28.dp)
                )
            }

            Spacer(modifier = Modifier.height(32.dp))
            
            Text(
                text = "App Version: 1.1.0",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Preview(showBackground = true)
@Composable
fun SettingsScreenPreview() {
    KirbyTheme {
        SettingsScreen()
    }
}
