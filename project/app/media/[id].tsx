import React, { useState, useCallback, useEffect, useMemo, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Image,
  TouchableOpacity,
  ScrollView,
  Dimensions,
  Animated,
  PanResponder,
  Pressable,
  StatusBar,
} from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { ArrowLeft, Lock, LockKeyhole as Unlock, Tag, Calendar, FastForward, Play, Square, Maximize, ChevronDown, ChevronUp, ChevronLeft, ChevronRight, Rewind, Pause } from 'lucide-react-native';
import { useMedia } from '@/context/MediaContext';
import { useSettings } from '@/context/SettingsContext';
import { THEMES } from '@/constants/themes';
import { formatDate } from '@/lib/utils';
import { Audio, Video, ResizeMode } from 'expo-av';
import * as ScreenOrientation from 'expo-screen-orientation';

const { width: SCREEN_WIDTH, height: SCREEN_HEIGHT } = Dimensions.get('window');

export default function MediaDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { entries, localFiles, toggleVault, isVaultUnlocked } = useMedia();
  const { settings } = useSettings();
  const theme = THEMES[settings.theme || 'kirby'] || THEMES.kirby;

  const allMedia = useMemo(() => [...entries, ...localFiles], [entries, localFiles]);

  const entry = useMemo(() => {
      return allMedia.find(e => e.id === id);
  }, [id, allMedia]);

  const filteredSortedMedia = useMemo(() => {
    if (!entry) return [];
    return allMedia
      .filter(e => e.type === entry.type && e.is_vaulted === entry.is_vaulted)
      .sort((a, b) => a.title.localeCompare(b.title));
  }, [allMedia, entry]);

  const currentIndex = useMemo(() => {
    return filteredSortedMedia.findIndex(e => e.id === id);
  }, [filteredSortedMedia, id]);

  const goToPrevious = () => {
    if (currentIndex > 0) {
      const prevId = filteredSortedMedia[currentIndex - 1].id;
      router.replace(`/media/${prevId}`);
    }
  };

  const goToNext = () => {
    if (currentIndex < filteredSortedMedia.length - 1) {
      const nextId = filteredSortedMedia[currentIndex + 1].id;
      router.replace(`/media/${nextId}`);
    }
  };

  const videoRef = useRef<Video>(null);
  const [playbackRate, setPlaybackRate] = useState(1.0);
  const [sound, setSound] = useState<Audio.Sound | null>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [isFullScreen, setIsFullScreen] = useState(false);
  const [showControls, setShowControls] = useState(true);

  // Seek Animation State
  const [lastTap, setLastTap] = useState<{ time: number, side: 'left' | 'right' | null }>({ time: 0, side: null });
  const seekAnim = useRef(new Animated.Value(0)).current;
  const [seekType, setSeekType] = useState<'forward' | 'backward' | null>(null);

  const triggerSeekAnim = (type: 'forward' | 'backward') => {
    setSeekType(type);
    seekAnim.setValue(0);
    Animated.sequence([
      Animated.timing(seekAnim, { toValue: 1, duration: 200, useNativeDriver: true }),
      Animated.timing(seekAnim, { toValue: 0, duration: 400, useNativeDriver: true })
    ]).start(() => setSeekType(null));
  };

  const togglePlayPause = async () => {
    if (!videoRef.current) return;
    const status = await videoRef.current.getStatusAsync();
    if (status.isLoaded) {
      if (status.isPlaying) {
        await videoRef.current.pauseAsync();
        setIsPlaying(false);
      } else {
        await videoRef.current.playAsync();
        setIsPlaying(true);
      }
    }
  };

  const handleDoubleTapSeek = async (side: 'left' | 'right') => {
    if (entry?.type !== 'video') return;
    const now = Date.now();
    const DOUBLE_TAP_DELAY = 300;

    if (lastTap.side === side && (now - lastTap.time) < DOUBLE_TAP_DELAY) {
      const videoStatus = await videoRef.current?.getStatusAsync();
      if (videoStatus?.isLoaded) {
        const seekAmount = 10000;
        const newPos = side === 'left'
          ? Math.max(0, videoStatus.positionMillis - seekAmount)
          : videoStatus.positionMillis + seekAmount;

        videoRef.current?.setPositionAsync(newPos);
        triggerSeekAnim(side === 'left' ? 'backward' : 'forward');
      }
      setLastTap({ time: 0, side: null });
    } else {
      setLastTap({ time: now, side });
      setShowControls(!showControls);
    }
  };

  // Pull-down info panel
  const panelTranslateY = useRef(new Animated.Value(0)).current;
  const [isPanelExpanded, setIsPanelExpanded] = useState(true);

  const togglePanel = (expand: boolean) => {
    Animated.spring(panelTranslateY, {
      toValue: expand ? 0 : 600, // Move it completely off screen
      useNativeDriver: true,
      friction: 10,
    }).start(() => setIsPanelExpanded(expand));
  };

  const panResponder = useRef(
    PanResponder.create({
      onMoveShouldSetPanResponder: (_, gestureState) => Math.abs(gestureState.dy) > 10,
      onPanResponderMove: (_, gestureState) => {
        if (gestureState.dy > 0 && isPanelExpanded) {
           panelTranslateY.setValue(gestureState.dy);
        }
      },
      onPanResponderRelease: (_, gestureState) => {
        if (gestureState.dy > 100) {
          togglePanel(false);
        } else {
          togglePanel(true);
        }
      },
    })
  ).current;

  useEffect(() => {
    return () => {
        if (sound) sound.unloadAsync();
        ScreenOrientation.lockAsync(ScreenOrientation.OrientationLock.PORTRAIT_UP);
    };
  }, [sound]);

  if (!entry) return null;

  const toggleFullscreen = async () => {
      if (isFullScreen) {
          await ScreenOrientation.lockAsync(ScreenOrientation.OrientationLock.PORTRAIT_UP);
      } else {
          await ScreenOrientation.lockAsync(ScreenOrientation.OrientationLock.LANDSCAPE);
      }
      setIsFullScreen(!isFullScreen);
  };

  // Dynamically calculate media height based on panel state
  const mediaTranslateY = panelTranslateY.interpolate({
      inputRange: [0, 600],
      outputRange: [0, (SCREEN_HEIGHT - SCREEN_HEIGHT * 0.45) / 2],
      extrapolate: 'clamp'
  });

  return (
    <View style={[styles.container, { backgroundColor: '#000' }]}>
      <StatusBar hidden={isFullScreen} />

      <Animated.View style={[
          styles.mediaContainer,
          isFullScreen && styles.fullScreenMedia,
          !isFullScreen && { transform: [{ translateY: mediaTranslateY }] }
      ]}>
        {entry.type === 'video' ? (
            <View style={styles.playerWrapper}>
                <Video
                    ref={videoRef}
                    source={{ uri: entry.local_path }}
                    style={styles.videoPlayer}
                    useNativeControls={false}
                    resizeMode={ResizeMode.CONTAIN}
                    onPlaybackStatusUpdate={status => {
                        if (status.isLoaded) setIsPlaying(status.isPlaying);
                    }}
                    isLooping={settings.loopVideos}
                    shouldPlay={settings.autoPlay}
                    rate={playbackRate}
                />

                {showControls && (
                    <View style={styles.customControlsOverlay}>
                        <TouchableOpacity style={styles.mainPlayBtn} onPress={togglePlayPause}>
                            {isPlaying ? <Pause size={50} color="white" fill="white" /> : <Play size={50} color="white" fill="white" />}
                        </TouchableOpacity>
                    </View>
                )}

                <View style={styles.touchOverlay}>
                    <Pressable style={styles.touchHalf} onPress={() => handleDoubleTapSeek('left')} />
                    <Pressable style={styles.touchHalf} onPress={() => handleDoubleTapSeek('right')} />
                </View>

                {seekType && (
                    <Animated.View style={[
                        styles.seekPulse,
                        seekType === 'backward' ? { left: '10%' } : { right: '10%' },
                        { opacity: seekAnim, transform: [{ scale: seekAnim.interpolate({ inputRange: [0, 1], outputRange: [0.5, 1.5] }) }] }
                    ]}>
                        {seekType === 'backward' ? <Rewind size={40} color="white" fill="white" /> : <FastForward size={40} color="white" fill="white" />}
                        <Text style={styles.seekLabel}>10s</Text>
                    </Animated.View>
                )}
            </View>
        ) : (
          <View style={styles.imageWrapper}>
            <Image source={{ uri: entry.local_path || entry.thumbnail_url }} style={styles.imageViewer} resizeMode="contain" />
            <Pressable style={StyleSheet.absoluteFill} onPress={() => setShowControls(!showControls)} />
          </View>
        )}

        {/* Floating Player UI Controls */}
        {showControls && (
            <Animated.View style={[styles.headerOverlay, isFullScreen && { top: 20 }]}>
                <TouchableOpacity style={styles.circBtn} onPress={() => router.back()}>
                    <ArrowLeft size={24} color="#FFF" />
                </TouchableOpacity>

                <View style={styles.headerRight}>
                    <TouchableOpacity style={styles.circBtn} onPress={toggleFullscreen}>
                        <Maximize size={20} color="#FFF" />
                    </TouchableOpacity>
                    <TouchableOpacity style={styles.circBtn} onPress={() => toggleVault(entry.id)}>
                        {entry.is_vaulted ? <Unlock size={20} color="#FFF" /> : <Lock size={20} color="#FFF" />}
                    </TouchableOpacity>
                </View>
            </Animated.View>
        )}

        {/* Side Nav Chevrons */}
        {showControls && !seekType && (
            <>
                {currentIndex > 0 && (
                    <TouchableOpacity style={[styles.navArrow, styles.leftArrow]} onPress={goToPrevious}>
                        <ChevronLeft size={40} color="white" />
                    </TouchableOpacity>
                )}
                {currentIndex < filteredSortedMedia.length - 1 && (
                    <TouchableOpacity style={[styles.navArrow, styles.rightArrow]} onPress={goToNext}>
                        <ChevronRight size={40} color="white" />
                    </TouchableOpacity>
                )}
            </>
        )}
      </Animated.View>

      {/* Info Panel */}
      {!isFullScreen && (
          <Animated.View
            style={[
                styles.detailsSheet,
                { backgroundColor: theme.background, transform: [{ translateY: panelTranslateY }] }
            ]}
            {...panResponder.panHandlers}
          >
              <View style={styles.sheetHandleContainer}>
                  <View style={[styles.sheetHandle, { backgroundColor: theme.border }]} />
              </View>

              {!isPanelExpanded && (
                  <TouchableOpacity style={styles.expandTrigger} onPress={() => togglePanel(true)}>
                      <ChevronUp size={24} color={theme.primary} />
                      <Text style={[styles.expandLabel, { color: theme.primary }]}>View Details</Text>
                  </TouchableOpacity>
              )}

              <ScrollView style={styles.sheetContent} showsVerticalScrollIndicator={false}>
                  <View style={styles.sheetHeader}>
                    <Text style={[styles.mediaTitle, { color: theme.text }]}>{entry.title}</Text>
                    <TouchableOpacity onPress={() => togglePanel(false)}>
                        <ChevronDown size={24} color={theme.textMuted} />
                    </TouchableOpacity>
                  </View>

                  <Text style={[styles.mediaDate, { color: theme.textMuted }]}>{formatDate(entry.media_date)}</Text>

                  <View style={styles.badgeRow}>
                      <View style={[styles.typeBadge, { backgroundColor: theme.surfaceElevated }]}>
                          <Tag size={14} color={theme.primary} />
                          <Text style={[styles.badgeText, { color: theme.text }]}>{entry.type.toUpperCase()}</Text>
                      </View>
                      <View style={[styles.typeBadge, { backgroundColor: theme.surfaceElevated }]}>
                          <Calendar size={14} color={theme.secondary} />
                          <Text style={[styles.badgeText, { color: theme.text }]}>SAVED</Text>
                      </View>
                  </View>

                  {entry.notes ? (
                      <View style={styles.memoSection}>
                          <Text style={[styles.memoHeader, { color: theme.textMuted }]}>MEMORY NOTES</Text>
                          <Text style={[styles.memoText, { color: theme.text }]}>{entry.notes}</Text>
                      </View>
                  ) : null}
              </ScrollView>
          </Animated.View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  mediaContainer: { width: '100%', height: SCREEN_HEIGHT * 0.45, backgroundColor: '#000', justifyContent: 'center' },
  fullScreenMedia: { height: '100%', width: '100%' },
  playerWrapper: { flex: 1, position: 'relative' },
  videoPlayer: { flex: 1 },
  imageWrapper: { flex: 1, width: '100%' },
  imageViewer: { flex: 1, width: '100%' },
  customControlsOverlay: { ...StyleSheet.absoluteFillObject, justifyContent: 'center', alignItems: 'center', zIndex: 15 },
  mainPlayBtn: { width: 80, height: 80, borderRadius: 40, backgroundColor: 'rgba(0,0,0,0.4)', justifyContent: 'center', alignItems: 'center' },
  touchOverlay: { ...StyleSheet.absoluteFillObject, flexDirection: 'row', zIndex: 10 },
  touchHalf: { flex: 1 },
  seekPulse: { position: 'absolute', top: '40%', zIndex: 50, alignItems: 'center' },
  seekLabel: { color: 'white', fontSize: 14, fontFamily: 'Nunito-Bold', marginTop: 5 },
  headerOverlay: { position: 'absolute', top: 50, left: 0, right: 0, flexDirection: 'row', justifyContent: 'space-between', paddingHorizontal: 20, zIndex: 100 },
  circBtn: { width: 44, height: 44, borderRadius: 22, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'center', alignItems: 'center' },
  headerRight: { flexDirection: 'row', gap: 12 },
  navArrow: { position: 'absolute', top: '50%', marginTop: -30, zIndex: 80, padding: 10 },
  leftArrow: { left: 5 },
  rightArrow: { right: 5 },
  detailsSheet: {
      position: 'absolute', bottom: 0, left: 0, right: 0, height: 500,
      borderTopLeftRadius: 35, borderTopRightRadius: 35,
      elevation: 25, shadowColor: '#000', shadowOpacity: 0.2, shadowRadius: 15,
  },
  sheetHandleContainer: { alignItems: 'center', paddingVertical: 15 },
  sheetHandle: { width: 50, height: 6, borderRadius: 3 },
  expandTrigger: {
      position: 'absolute', top: -45, alignSelf: 'center',
      paddingHorizontal: 20, height: 45, backgroundColor: 'rgba(255,255,255,0.95)',
      borderTopLeftRadius: 20, borderTopRightRadius: 20,
      flexDirection: 'row', alignItems: 'center', gap: 8, elevation: 5
  },
  expandLabel: { fontSize: 13, fontFamily: 'Nunito-Bold' },
  sheetContent: { paddingHorizontal: 25 },
  sheetHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 },
  mediaTitle: { fontSize: 26, fontFamily: 'Nunito-ExtraBold', flex: 1 },
  mediaDate: { fontSize: 15, fontFamily: 'Nunito-SemiBold', marginBottom: 20 },
  badgeRow: { flexDirection: 'row', gap: 12, marginBottom: 30 },
  typeBadge: { paddingHorizontal: 15, paddingVertical: 10, borderRadius: 15, flexDirection: 'row', alignItems: 'center', gap: 8 },
  badgeText: { fontSize: 12, fontFamily: 'Nunito-ExtraBold' },
  memoSection: { marginTop: 10 },
  memoHeader: { fontSize: 11, fontFamily: 'Nunito-ExtraBold', marginBottom: 10, letterSpacing: 1 },
  memoText: { fontSize: 17, fontFamily: 'Nunito-Regular', lineHeight: 26 },
});
