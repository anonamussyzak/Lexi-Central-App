package com.example.myapplication

import kotlinx.serialization.Serializable

@Serializable
data class Note(
    val id: String,
    val title: String,
    val content: String,
    val createdAt: String,
    val updatedAt: String,
    val tags: List<String> = emptyList(),
    val isPinned: Boolean = false,
    val categoryId: String? = null
)
