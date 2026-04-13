package com.example.myapplication

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Note(
    @SerialName("id")
    val id: String,
    @SerialName("title")
    val title: String = "",
    @SerialName("content")
    val content: String = "",
    @SerialName("created_at")
    val createdAt: String? = null,
    @SerialName("updated_at")
    val updatedAt: String? = null,
    @SerialName("tags")
    val tags: List<String>? = emptyList(),
    @SerialName("is_pinned")
    val isPinned: Boolean? = false,
    @SerialName("category_id")
    val categoryId: String? = null
)
