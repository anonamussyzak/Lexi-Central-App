import React, { useEffect, useRef } from 'react';
import { View, StyleSheet, Dimensions } from 'react-native';
import Animated, { useSharedValue, useAnimatedStyle, withRepeat, withTiming, Easing } from 'react-native-reanimated';
import { useSettings } from '@/context/SettingsContext';
import { THEMES } from '@/constants/themes';

const { width, height } = Dimensions.get('window');

function Blob({ x, y, size, color, duration, delay }: {
  x: number; y: number; size: number; color: string; duration: number; delay: number;
}) {
  const translateY = useSharedValue(0);
  const scale = useSharedValue(1);
  const opacity = useSharedValue(0.12);

  useEffect(() => {
    translateY.value = withRepeat(
      withTiming(-30, { duration, easing: Easing.inOut(Easing.sin) }),
      -1,
      true
    );
    scale.value = withRepeat(
      withTiming(1.15, { duration: duration * 1.3, easing: Easing.inOut(Easing.sin) }),
      -1,
      true
    );
    opacity.value = withRepeat(
      withTiming(0.18, { duration: duration * 0.8, easing: Easing.inOut(Easing.sin) }),
      -1,
      true
    );
  }, []);

  const animStyle = useAnimatedStyle(() => ({
    transform: [{ translateY: translateY.value }, { scale: scale.value }],
    opacity: opacity.value,
  }));

  return (
    <Animated.View
      style={[
        {
          position: 'absolute',
          left: x,
          top: y,
          width: size,
          height: size,
          borderRadius: size / 2,
          backgroundColor: color,
        },
        animStyle,
      ]}
    />
  );
}

export default function AnimatedBackground() {
  const { settings } = useSettings();
  const theme = THEMES[settings.theme];

  const blobs = [
    { x: -60, y: 80, size: 220, color: theme.primary, duration: 5000, delay: 0 },
    { x: width - 100, y: 200, size: 180, color: theme.secondary, duration: 6500, delay: 500 },
    { x: width / 2 - 90, y: height - 280, size: 200, color: theme.accent, duration: 4800, delay: 1000 },
    { x: 40, y: height / 2, size: 150, color: theme.warning, duration: 7000, delay: 1500 },
  ];

  return (
    <View style={StyleSheet.absoluteFillObject} pointerEvents="none">
      {blobs.map((blob, i) => (
        <Blob key={i} {...blob} />
      ))}
    </View>
  );
}
