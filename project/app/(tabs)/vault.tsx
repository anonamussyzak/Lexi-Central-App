import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, FlatList, useWindowDimensions, TextInput, TouchableOpacity, Alert, Modal, Image, Pressable } from 'react-native';
import { useMedia } from '@/context/MediaContext';
import { useSettings } from '@/context/SettingsContext';
import { THEMES } from '@/constants/themes';
import MediaCard from '@/components/gallery/MediaCard';
import { Lock, ShieldCheck, Fingerprint, LockKeyhole, X } from 'lucide-react-native';
import { useRouter } from 'expo-router';
import * as LocalAuthentication from 'expo-local-authentication';

export default function VaultScreen() {
  const { entries, localFiles } = useMedia();
  const { settings } = useSettings();
  const theme = THEMES[settings.theme];
  const { width } = useWindowDimensions();
  const router = useRouter();
  const [pin, setPin] = useState('');
  const [isUnlocked, setIsUnlocked] = useState(false);
  const [fullscreenImage, setFullscreenImage] = useState<string | null>(null);

  const vaultedEntries = [...entries, ...localFiles].filter(e => e.is_vaulted);

  const cols = settings.gridColumns;
  const padding = 16;
  const gap = 12;
  const cardWidth = (width - padding * 2 - gap * (cols - 1)) / cols;

  const handleBiometricAuth = async () => {
      try {
          const hasHardware = await LocalAuthentication.hasHardwareAsync();
          const isEnrolled = await LocalAuthentication.isEnrolledAsync();

          if (hasHardware && isEnrolled) {
              const result = await LocalAuthentication.authenticateAsync({
                  promptMessage: 'Unlock Kirby Vault',
                  fallbackLabel: 'Use PIN',
              });

              if (result.success) {
                  setIsUnlocked(true);
                  setPin('');
              }
          }
      } catch (e) {
          console.error(e);
      }
  };

  const forceLock = () => {
      setIsUnlocked(false);
      setPin('');
  };

  useEffect(() => {
      if (settings.vaultEnabled && !isUnlocked) {
          handleBiometricAuth();
      }
  }, [settings.vaultEnabled]);

  if (!isUnlocked && settings.vaultEnabled) {
      return (
          <View style={[styles.unlockContainer, { backgroundColor: theme.background }]}>
              <View style={[styles.lockCircle, { backgroundColor: theme.primary + '20' }]}>
                <Lock size={64} color={theme.primary} />
              </View>
              <Text style={[styles.unlockTitle, { color: theme.text }]}>Vault is Locked</Text>

              {settings.vaultPin ? (
                  <TextInput
                    style={[styles.pinInput, { backgroundColor: theme.surface, color: theme.text, borderColor: theme.border, borderRadius: settings.roundedCorners }]}
                    placeholder="Enter PIN"
                    placeholderTextColor={theme.textMuted}
                    secureTextEntry
                    value={pin}
                    onChangeText={(text) => {
                        setPin(text);
                        if (text === settings.vaultPin) {
                            setIsUnlocked(true);
                            setPin('');
                        }
                    }}
                    keyboardType="numeric"
                    maxLength={4}
                  />
              ) : null}

              <TouchableOpacity
                style={[styles.biometricBtn, { backgroundColor: theme.primary }]}
                onPress={handleBiometricAuth}
              >
                  <Fingerprint size={24} color="white" />
                  <Text style={styles.biometricText}>Use Biometrics</Text>
              </TouchableOpacity>
          </View>
      );
  }

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <View style={styles.header}>
        <View style={styles.headerTop}>
            <View style={styles.headerTitleRow}>
                <ShieldCheck size={32} color={theme.primary} />
                <Text style={[styles.title, { color: theme.primary, fontFamily: 'Nunito-ExtraBold' }]}>Vault</Text>
            </View>
            <TouchableOpacity
                style={[styles.lockBtn, { backgroundColor: theme.surfaceElevated }]}
                onPress={forceLock}
            >
                <LockKeyhole size={20} color={theme.primary} />
            </TouchableOpacity>
        </View>
        <Text style={[styles.subtitle, { color: theme.textMuted }]}>{vaultedEntries.length} hidden memories</Text>
      </View>

      <FlatList
        data={vaultedEntries}
        keyExtractor={(item) => item.id}
        numColumns={cols}
        key={cols}
        contentContainerStyle={styles.list}
        renderItem={({ item }) => (
          <View style={{ marginRight: gap, marginBottom: gap }}>
            <MediaCard
              entry={item}
              width={cardWidth}
              onPress={() => {
                  if (item.type === 'note' && item.thumbnail_url) {
                      setFullscreenImage(item.thumbnail_url);
                  } else {
                      router.push(`/media/${item.id}`);
                  }
              }}
            />
          </View>
        )}
        ListEmptyComponent={
            <View style={styles.empty}>
                <Text style={[styles.emptyText, { color: theme.textMuted }]}>No items in the vault</Text>
            </View>
        }
      />

      <Modal visible={!!fullscreenImage} transparent animationType="fade">
          <Pressable style={styles.fullscreenOverlay} onPress={() => setFullscreenImage(null)}>
              {fullscreenImage && <Image source={{ uri: fullscreenImage }} style={styles.fullscreenImage} resizeMode="contain" />}
              <TouchableOpacity style={styles.closeFullscreen} onPress={() => setFullscreenImage(null)}>
                  <X size={30} color="white" />
              </TouchableOpacity>
          </Pressable>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, paddingTop: 60 },
  header: { paddingHorizontal: 20, marginBottom: 20 },
  headerTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  headerTitleRow: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  title: { fontSize: 32 },
  lockBtn: { width: 44, height: 44, borderRadius: 14, alignItems: 'center', justifyContent: 'center', elevation: 2 },
  subtitle: { fontSize: 14, marginTop: 4, marginLeft: 42 },
  list: { paddingHorizontal: 16, paddingBottom: 100 },
  empty: { marginTop: 100, alignItems: 'center' },
  emptyText: { fontFamily: 'Nunito-SemiBold', fontSize: 16 },
  unlockContainer: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: 40 },
  lockCircle: { width: 120, height: 120, borderRadius: 60, justifyContent: 'center', alignItems: 'center', marginBottom: 20 },
  unlockTitle: { fontSize: 24, fontFamily: 'Nunito-Bold', marginBottom: 30 },
  pinInput: { width: '80%', height: 60, borderWidth: 1, textAlign: 'center', fontSize: 24, marginBottom: 20 },
  biometricBtn: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 20, paddingVertical: 12, borderRadius: 20, gap: 10 },
  biometricText: { color: 'white', fontFamily: 'Nunito-Bold', fontSize: 16 },
  fullscreenOverlay: { flex: 1, backgroundColor: 'black', justifyContent: 'center', alignItems: 'center' },
  fullscreenImage: { width: '100%', height: '100%' },
  closeFullscreen: { position: 'absolute', top: 50, right: 20 },
});
