import React from 'react';
import { StyleSheet, View, StatusBar } from 'react-native';
import { WebView } from 'react-native-webview';
import { useSettings } from '@/context/SettingsContext';
import { THEMES } from '@/constants/themes';

export default function HubScreen() {
  const { settings } = useSettings();
  const theme = THEMES[settings.theme];

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <StatusBar translucent backgroundColor="transparent" barStyle={settings.theme === 'dark' ? 'light-content' : 'dark-content'} />
      <WebView
        source={{ uri: 'https://sites.google.com/view/zaksawesomeroom/home' }}
        style={styles.webview}
        startInLoadingState={true}
        allowsFullscreenVideo={true}
        domStorageEnabled={true}
        javaScriptEnabled={true}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  webview: {
    flex: 1,
    marginTop: 0,
  },
});
