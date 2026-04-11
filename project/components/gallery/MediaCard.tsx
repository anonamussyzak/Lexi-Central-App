import React from 'react';
import { View, Text, Image, StyleSheet, Pressable } from 'react-native';
import Animated, { useSharedValue, useAnimatedStyle, withSpring } from 'react-native-reanimated';
import { Play, FileImage, Link } from 'lucide-react-native';
import { MediaEntry } from '@/lib/types';
import { formatDuration, isMegaUrl } from '@/lib/utils';
import { useSettings } from '@/context/SettingsContext';
import { THEMES } from '@/constants/themes';

interface MediaCardProps {
  entry: MediaEntry;
  onPress: () => void;
  width: number;
}

export default function MediaCard({ entry, onPress, width }: MediaCardProps) {
  const { settings } = useSettings();
  const theme = THEMES[settings.theme];
  const scale = useSharedValue(1);
  const radius = settings.roundedCorners;

  const animStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }));

  const hasMega = isMegaUrl(entry.source_link);

  return (
    <Pressable
      onPress={onPress}
      onPressIn={() => { scale.value = withSpring(0.96, { damping: 15 }); }}
      onPressOut={() => { scale.value = withSpring(1, { damping: 12 }); }}
    >
      <Animated.View
        style={[
          styles.card,
          animStyle,
          {
            width,
            borderRadius: radius,
            backgroundColor: theme.surface,
            shadowColor: theme.cardShadow,
            shadowOpacity: settings.shadowIntensity / 10,
            elevation: settings.shadowIntensity,
          },
        ]}
      >
        <View style={[styles.thumbnailContainer, { borderRadius: radius }]}>
          {entry.thumbnail_url ? (
            <Image
              source={{ uri: entry.thumbnail_url }}
              style={styles.thumbnail}
              resizeMode="cover"
            />
          ) : (
            <View style={[styles.placeholder, { backgroundColor: theme.surfaceElevated }]}>
              <FileImage size={32} color={theme.textMuted} />
            </View>
          )}

          {entry.type === 'video' && (
            <View style={[styles.playOverlay, { backgroundColor: theme.overlay }]}>
              <View style={[styles.playButton, { backgroundColor: theme.surface }]}>
                <Play size={14} color={theme.tabBarActive} fill={theme.tabBarActive} />
              </View>
            </View>
          )}

          {entry.type === 'video' && entry.duration_seconds > 0 && (
            <View style={[styles.durationBadge, { backgroundColor: 'rgba(0,0,0,0.65)' }]}>
              <Text style={styles.durationText}>{formatDuration(entry.duration_seconds)}</Text>
            </View>
          )}

          {hasMega && (
            <View style={[styles.megaBadge, { backgroundColor: theme.primary }]}>
              <Link size={10} color={theme.text} />
            </View>
          )}
        </View>

        <View style={styles.info}>
          <Text style={[styles.title, { color: theme.text }]} numberOfLines={2}>
            {entry.title}
          </Text>
          {entry.notes.length > 0 && (
            <Text style={[styles.notesPreview, { color: theme.textMuted }]} numberOfLines={1}>
              {entry.notes.replace(/[#*_`]/g, '').trim()}
            </Text>
          )}
        </View>
      </Animated.View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    overflow: 'hidden',
    shadowOffset: { width: 0, height: 4 },
    shadowRadius: 12,
    marginBottom: 12,
  },
  thumbnailContainer: {
    width: '100%',
    aspectRatio: 9 / 13,
    overflow: 'hidden',
    position: 'relative',
  },
  thumbnail: {
    width: '100%',
    height: '100%',
  },
  placeholder: {
    width: '100%',
    height: '100%',
    alignItems: 'center',
    justifyContent: 'center',
  },
  playOverlay: {
    position: 'absolute',
    inset: 0,
    alignItems: 'center',
    justifyContent: 'center',
    opacity: 0.6,
  },
  playButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
    paddingLeft: 3,
    opacity: 0.9,
  },
  durationBadge: {
    position: 'absolute',
    bottom: 8,
    right: 8,
    paddingHorizontal: 6,
    paddingVertical: 3,
    borderRadius: 6,
  },
  durationText: {
    fontFamily: 'Nunito-Bold',
    fontSize: 11,
    color: '#FFFFFF',
  },
  megaBadge: {
    position: 'absolute',
    top: 8,
    left: 8,
    width: 20,
    height: 20,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  info: {
    paddingHorizontal: 10,
    paddingVertical: 8,
  },
  title: {
    fontFamily: 'Nunito-Bold',
    fontSize: 13,
    lineHeight: 18,
  },
  notesPreview: {
    fontFamily: 'Nunito-Regular',
    fontSize: 11,
    marginTop: 3,
  },
});
