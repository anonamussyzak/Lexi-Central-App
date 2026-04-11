package com.example.myapplication

import android.net.Uri

data class Video(
    val id: Long,
    val name: String,
    val duration: Int,
    val size: Int,
    val uri: Uri,
    val path: String
)
