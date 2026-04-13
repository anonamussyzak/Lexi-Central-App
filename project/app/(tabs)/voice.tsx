import React, { useState, useEffect, useRef } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, FlatList, Alert, Animated, ScrollView } from 'react-native';
import { useSettings } from '@/context/SettingsContext';
import { THEMES } from '@/constants/themes';
import { useMedia } from '@/context/MediaContext';
import { Mic, Play, Square, Trash2, Pause, Lock } from 'lucide-react-native';
import { Audio } from 'expo-av';

export default function VoiceScreen() {
  const { settings } = useSettings();
  const theme = THEMES[settings.theme];
  const { entries, localFiles, addEntry, deleteEntry, toggleVault } = useMedia();
  const [recording, setRecording] = useState<Audio.Recording | null>(null);
  const [isRecording, setIsRecording] = useState(false);
  const [playingId, setPlayingId] = useState<string | null>(null);
  const [sound, setSound] = useState<Audio.Sound | null>(null);
  const [selectedCategory, setSelectedCategory] = useState(settings.noteTabs[0] || 'General');

  const [meterLevels, setMeterLevels] = useState<number[]>(new Array(20).fill(0));
  const animationRefs = useRef<Animated.Value[]>(new Array(20).fill(0).map(() => new Animated.Value(4)));

  const allVoices = [...entries, ...localFiles].filter(e => e.type === 'voice' && !e.is_vaulted);

  useEffect(() => {
    return () => {
      if (sound) sound.unloadAsync();
    };
  }, [sound]);

  // Audio Visualizer Simulation Logic
  useEffect(() => {
      let interval: any;
      if (isRecording) {
          interval = setInterval(() => {
              const newLevels = meterLevels.map(() => Math.floor(Math.random() * 26) + 4);
              newLevels.forEach((val, i) => {
                  Animated.spring(animationRefs.current[i], {
                      toValue: val,
                      useNativeDriver: false,
                      tension: 100,
                      friction: 5
                  }).start();
              });
          }, 100);
      } else {
          animationRefs.current.forEach((anim) => {
              Animated.spring(anim, {
                  toValue: 4,
                  useNativeDriver: false
              }).start();
          });
      }
      return () => clearInterval(interval);
  }, [isRecording]);

  async function startRecording() {
    try {
      const { status } = await Audio.requestPermissionsAsync();
      if (status !== 'granted') {
        Alert.alert('Permission denied');
        return;
      }

      await Audio.setAudioModeAsync({
        allowsRecordingIOS: true,
        playsInSilentModeIOS: true,
      });

      const { recording } = await Audio.Recording.createAsync(
        Audio.RecordingOptionsPresets.HIGH_QUALITY
      );
      setRecording(recording);
      setIsRecording(true);
    } catch (err) {
      console.error(err);
      Alert.alert('Failed to start recording');
    }
  }

  async function stopRecording() {
    setIsRecording(false);
    if (!recording) return;
    try {
        await recording.stopAndUnloadAsync();
        const uri = recording.getURI();
        setRecording(null);

        if (uri) {
          const fileName = `Memo_${Date.now()}.m4a`;
          await addEntry({
            title: fileName,
            type: 'voice',
            notes: '',
            source_link: '',
            thumbnail_url: '',
            local_path: uri,
            is_vaulted: false,
            tags: [selectedCategory.toLowerCase()], // Tagging with persistent tab
            media_date: new Date().toISOString(),
            duration_seconds: 0,
            file_size_bytes: 0
          });
          Alert.alert("Success", `Memo saved to ${selectedCategory}`);
        }
    } catch (e) {
        console.error(e);
    }
  }

  const togglePlayback = async (id: string, uri: string) => {
    try {
        if (playingId === id && sound) {
            const status = await sound.getStatusAsync();
            if (status.isLoaded && status.isPlaying) {
                await sound.pauseAsync();
                setPlayingId(null);
            } else {
                await sound.playAsync();
                setPlayingId(id);
            }
            return;
        }

        if (sound) await sound.unloadAsync();

        const { sound: newSound } = await Audio.Sound.createAsync(
            { uri },
            { shouldPlay: true }
        );

        setSound(newSound);
        setPlayingId(id);

        newSound.setOnPlaybackStatusUpdate((status) => {
            if (status.isLoaded && status.didJustFinish) {
                setPlayingId(null);
            }
        });
    } catch (e) {
        Alert.alert('Error', 'Playback failed');
    }
  };

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <View style={styles.header}>
        <Text style={[styles.title, { color: theme.primary, fontFamily: 'Nunito-ExtraBold' }]}>Voice Memos</Text>
      </View>

      <View style={styles.recorderContainer}>
        <View style={styles.visualizerContainer}>
            {animationRefs.current.map((anim, i) => (
                <Animated.View
                    key={i}
                    style={[
                        styles.visualizerBar,
                        {
                            height: anim,
                            backgroundColor: isRecording ? theme.primary : theme.textMuted + '40'
                        }
                    ]}
                />
            ))}
        </View>

        <View style={styles.categoryPicker}>
            <Text style={[styles.catLabel, { color: theme.textMuted }]}>SAVE TO CATEGORY</Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.catScroll}>
                {settings.noteTabs.map(cat => (
                    <TouchableOpacity
                        key={cat}
                        onPress={() => setSelectedCategory(cat)}
                        style={[styles.catBtn, { backgroundColor: selectedCategory === cat ? theme.primary : theme.surfaceElevated }]}
                    >
                        <Text style={[styles.catText, { color: selectedCategory === cat ? 'white' : theme.textSecondary }]}>{cat}</Text>
                    </TouchableOpacity>
                ))}
            </ScrollView>
        </View>

        <TouchableOpacity
          style={[styles.recordButton, { backgroundColor: isRecording ? theme.error : theme.primary }]}
          onPress={isRecording ? stopRecording : startRecording}
        >
          {isRecording ? <Square color="white" size={32} fill="white" /> : <Mic color="white" size={32} />}
        </TouchableOpacity>

        <Text style={[styles.statusText, { color: isRecording ? theme.error : theme.textMuted }]}>
          {isRecording ? 'Recording Live...' : 'Tap to Record'}
        </Text>
      </View>

      <FlatList
        data={allVoices}
        keyExtractor={item => item.id}
        contentContainerStyle={styles.list}
        renderItem={({ item }) => (
          <View style={[styles.memoCard, { backgroundColor: theme.surface, borderRadius: settings.roundedCorners }]}>
            <View style={styles.memoInfo}>
              <Mic size={20} color={theme.primary} />
              <View style={styles.memoTextContainer}>
                <Text style={[styles.memoTitle, { color: theme.text }]} numberOfLines={1}>{item.title}</Text>
                <View style={styles.tagRow}>
                    <Text style={[styles.memoDate, { color: theme.textMuted }]}>{new Date(item.media_date).toLocaleDateString()}</Text>
                    {item.tags.map(t => (
                        <View key={t} style={[styles.tagBadge, { backgroundColor: theme.surfaceElevated }]}><Text style={[styles.tagText, { color: theme.primary }]}>{t.toUpperCase()}</Text></View>
                    ))}
                </View>
              </View>
            </View>
            <View style={styles.actions}>
              <TouchableOpacity
                onPress={() => togglePlayback(item.id, item.local_path)}
                style={styles.actionButton}
              >
                {playingId === item.id ? (
                    <Pause size={20} color={theme.secondary} fill={theme.secondary} />
                ) : (
                    <Play size={20} color={theme.secondary} fill={theme.secondary} />
                )}
              </TouchableOpacity>
              <TouchableOpacity onPress={() => toggleVault(item.id)} style={styles.actionButton}>
                <Lock size={20} color={theme.textMuted} />
              </TouchableOpacity>
              <TouchableOpacity onPress={() => deleteEntry(item.id)} style={styles.actionButton}>
                <Trash2 size={20} color={theme.error} />
              </TouchableOpacity>
            </View>
          </View>
        )}
        ListEmptyComponent={<Text style={{ textAlign: 'center', marginTop: 40, color: theme.textMuted }}>No voice memos yet</Text>}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, paddingTop: 60 },
  header: { paddingHorizontal: 20, marginBottom: 20 },
  title: { fontSize: 32 },
  recorderContainer: { alignItems: 'center', marginBottom: 30 },
  visualizerContainer: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 3, height: 40, marginBottom: 15 },
  visualizerBar: { width: 3, borderRadius: 2 },
  categoryPicker: { width: '100%', paddingHorizontal: 20, marginBottom: 20 },
  catLabel: { fontSize: 10, fontFamily: 'Nunito-ExtraBold', marginBottom: 8, textAlign: 'center' },
  catScroll: { gap: 8, justifyContent: 'center' },
  catBtn: { paddingHorizontal: 12, paddingVertical: 6, borderRadius: 12 },
  catText: { fontSize: 11, fontFamily: 'Nunito-Bold' },
  recordButton: { width: 80, height: 80, borderRadius: 40, justifyContent: 'center', alignItems: 'center', elevation: 8, shadowColor: '#000', shadowOpacity: 0.2, shadowRadius: 5 },
  statusText: { marginTop: 12, fontFamily: 'Nunito-Bold', fontSize: 16 },
  list: { paddingHorizontal: 20, paddingBottom: 100 },
  memoCard: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', padding: 15, marginBottom: 12, elevation: 2, shadowColor: '#000', shadowOpacity: 0.05, shadowRadius: 5 },
  memoInfo: { flexDirection: 'row', alignItems: 'center', flex: 1 },
  memoTextContainer: { marginLeft: 12, flex: 1 },
  memoTitle: { fontFamily: 'Nunito-Bold', fontSize: 16 },
  tagRow: { flexDirection: 'row', alignItems: 'center', gap: 8, marginTop: 2 },
  memoDate: { fontSize: 11, fontFamily: 'Nunito-Regular' },
  tagBadge: { paddingHorizontal: 6, paddingVertical: 2, borderRadius: 4 },
  tagText: { fontSize: 8, fontFamily: 'Nunito-ExtraBold' },
  actions: { flexDirection: 'row', alignItems: 'center' },
  actionButton: { padding: 8, marginLeft: 4 },
});
