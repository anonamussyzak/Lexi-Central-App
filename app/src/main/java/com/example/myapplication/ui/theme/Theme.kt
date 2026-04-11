package com.example.myapplication.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val LightColorScheme = lightColorScheme(
    primary = KirbyPink,
    onPrimary = White,
    primaryContainer = KirbyPink,
    onPrimaryContainer = KirbyPinkDark,
    secondary = KirbyBlue,
    onSecondary = KirbyBlueDark,
    tertiary = KirbyYellow,
    background = KirbyBackground,
    surface = White,
    onBackground = KirbyText,
    onSurface = KirbyText
)

@Composable
fun KirbyTheme(
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = LightColorScheme,
        content = content
    )
}
