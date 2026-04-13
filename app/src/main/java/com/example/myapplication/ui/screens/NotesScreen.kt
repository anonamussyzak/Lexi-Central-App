package com.example.myapplication.ui.screens

import android.util.Log
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.example.myapplication.Note
import com.example.myapplication.SupabaseManager
import com.example.myapplication.ui.theme.KirbyTheme
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.realtime.Realtime
import io.github.jan.supabase.realtime.realtime
import io.github.jan.supabase.realtime.selectAsFlow
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import java.util.*

@Composable
fun NotesScreen() {
    val notes = remember { mutableStateListOf<Note>() }
    var isLoading by remember { mutableStateOf(true) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()
    var showAddDialog by remember { mutableStateOf(false) }
    
    val supabaseClient by SupabaseManager.clientFlow.collectAsState()

    LaunchedEffect(supabaseClient) {
        val client = supabaseClient
        if (client == null) {
            errorMessage = "Please configure Supabase credentials in Settings."
            isLoading = false
            notes.clear()
            return@LaunchedEffect
        }

        isLoading = true
        errorMessage = null
        
        // Retry logic for connection
        var retryCount = 0
        val maxRetries = 3

        while (retryCount < maxRetries) {
            try {
                client.realtime.connect()
                val channel = client.realtime.createChannel("notes_channel")
                
                channel.selectAsFlow<Note>(
                    table = "notes",
                    primaryKey = Note::id
                ).catch { e ->
                    Log.e("NotesScreen", "Flow error", e)
                    errorMessage = "Connection error: ${e.localizedMessage}"
                    isLoading = false
                }.collectLatest { updatedNotes ->
                    notes.clear()
                    notes.addAll(updatedNotes)
                    isLoading = false
                }
                break // Success
            } catch (e: Exception) {
                Log.e("NotesScreen", "Connection attempt ${retryCount + 1} failed", e)
                retryCount++
                if (retryCount >= maxRetries) {
                    errorMessage = "Failed to connect to Supabase: ${e.localizedMessage}"
                    isLoading = false
                } else {
                    delay(2000L * retryCount)
                }
            }
        }
    }

    Scaffold(
        floatingActionButton = {
            if (errorMessage == null && !isLoading && supabaseClient != null) {
                FloatingActionButton(
                    onClick = { showAddDialog = true },
                    containerColor = MaterialTheme.colorScheme.primary,
                    contentColor = MaterialTheme.colorScheme.onPrimary
                ) {
                    Icon(Icons.Default.Add, contentDescription = "Add Note")
                }
            }
        }
    ) { padding ->
        Box(modifier = Modifier.padding(padding).fillMaxSize().padding(16.dp)) {
            Column {
                Text(
                    text = "Kirby's Notes",
                    style = MaterialTheme.typography.headlineMedium,
                    color = MaterialTheme.colorScheme.primary
                )
                Spacer(modifier = Modifier.height(16.dp))
                
                if (isLoading) {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator(color = MaterialTheme.colorScheme.primary)
                    }
                } else if (errorMessage != null) {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                text = errorMessage!!,
                                color = MaterialTheme.colorScheme.error,
                                style = MaterialTheme.typography.bodyLarge,
                                modifier = Modifier.padding(bottom = 16.dp)
                            )
                            Button(onClick = { 
                                // Resetting the client trigger
                                SupabaseManager.init(SupabaseManager.clientFlow.value?.let { null } ?: return@Button) 
                            }) {
                                Text("Retry")
                            }
                        }
                    }
                } else if (notes.isEmpty()) {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Text(
                            text = "No notes yet. Add one!",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                } else {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(notes, key = { it.id }) { note ->
                            NoteCard(note)
                        }
                    }
                }
            }
        }

        if (showAddDialog) {
            AddNoteDialog(
                onDismiss = { showAddDialog = false },
                onSave = { title, content ->
                    scope.launch {
                        try {
                            val newNote = Note(
                                id = UUID.randomUUID().toString(),
                                title = title,
                                content = content,
                                createdAt = java.time.Instant.now().toString(),
                                updatedAt = java.time.Instant.now().toString()
                            )
                            supabaseClient?.let { client ->
                                client.postgrest["notes"].insert(newNote)
                            }
                            showAddDialog = false
                        } catch (e: Exception) {
                            Log.e("NotesScreen", "Insert failed", e)
                        }
                    }
                }
            )
        }
    }
}

@Composable
fun NoteCard(note: Note) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = note.title,
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.primary
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = note.content,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurface
            )
        }
    }
}

@Composable
fun AddNoteDialog(onDismiss: () -> Unit, onSave: (String, String) -> Unit) {
    var title by remember { mutableStateOf("") }
    var content by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("New Note", color = MaterialTheme.colorScheme.primary) },
        text = {
            Column {
                TextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { Text("Title") },
                    modifier = Modifier.fillMaxWidth(),
                    colors = TextFieldDefaults.colors(
                        focusedContainerColor = MaterialTheme.colorScheme.surface,
                        unfocusedContainerColor = MaterialTheme.colorScheme.surface
                    )
                )
                Spacer(modifier = Modifier.height(8.dp))
                TextField(
                    value = content,
                    onValueChange = { content = it },
                    label = { Text("Content") },
                    modifier = Modifier.fillMaxWidth(),
                    colors = TextFieldDefaults.colors(
                        focusedContainerColor = MaterialTheme.colorScheme.surface,
                        unfocusedContainerColor = MaterialTheme.colorScheme.surface
                    )
                )
            }
        },
        confirmButton = {
            Button(
                onClick = { if (title.isNotBlank()) onSave(title, content) },
                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
            ) {
                Text("Save")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel", color = MaterialTheme.colorScheme.primary)
            }
        },
        containerColor = MaterialTheme.colorScheme.background,
        shape = RoundedCornerShape(28.dp)
    )
}

@Preview(showBackground = true)
@Composable
fun NotesScreenPreview() {
    KirbyTheme {
        NotesScreen()
    }
}
