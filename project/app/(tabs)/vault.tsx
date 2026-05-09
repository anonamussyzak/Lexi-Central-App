import React, { useState, useEffect, useMemo, useCallback } from 'react';
import { View, Text, StyleSheet, FlatList, useWindowDimensions, TextInput, TouchableOpacity, Alert, Modal, Image, Pressable, RefreshControl } from 'react-native';
import { useMedia } from '@/context/MediaContext';
import { useSettings } from '@/context/SettingsContext';
import { THEMES } from '@/constants/themes';
import MediaCard from '@/components/gallery/MediaCard';
import { Lock, ShieldCheck, Fingerprint, LockKeyhole, X, Trash2, Unlock, CheckCircle2, Circle, Layers } from 'lucide-react-native';
import { useRouter } from 'expo-router';
import * as LocalAuthentication from 'expo-local-authentication';

export default function VaultScreen() {
  const { entries, localFiles, isVaultUnlocked, setVaultUnlocked, toggleVault, deleteEntry, refreshEntries, scanLocalPaths } = useMedia();
  const { settings, isLoaded: settingsLoaded } = useSettings();
  const theme = THEMES[settings?.theme || 'kirby'] || THEMES.kirby;
  const { width } = useWindowDimensions();
  const router = useRouter();
  const [pin, setPin] = useState('');
  const [fullscreenImage, setFullscreenImage] = useState<string | null>(null);
  const [refreshing, setRefreshing] = useState(false);

  // Selection Mode State
  const [selectionMode, setSelectionMode] = useState(false);
  const [selectedIds, setSelectedIds] = useState<string[]>([]);

  const vaultedEntries = useMemo(() =>
    [...(entries || []), ...(localFiles || [])].filter(e => e.is_vaulted),
  [entries, localFiles]);

  const cols = settings?.gridColumns || 2;
  const padding = 16;
  const gap = 12;
  const cardWidth = (width - padding * 2 - gap * (cols - 1)) / cols;

  const handleBiometricAuth = async () => {
      try {
          const hasHardware = await LocalAuthentication.hasHardwareAsync();
          const isEnrolled = await LocalAuthentication.isEnrolledAsync();

          if (hasHardware && isEnrolled) {
              const result = await LocalAuthentication.authenticateAsync({
                  promptMessage: 'Unlock Private Vault',
                  fallbackLabel: 'Use PIN',
              });

              if (result.success) {
                  setVaultUnlocked(true);
                  setPin('');
              }
          }
      } catch (e) {
          console.error(e);
      }
  };

  const forceLock = () => {
      setVaultUnlocked(false);
      setSelectionMode(false);
      setSelectedIds([]);
      setPin('');
  };

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await refreshEntries();
    if (settings?.mediaPaths) await scanLocalPaths(settings.mediaPaths);
    setRefreshing(false);
  }, [refreshEntries, scanLocalPaths, settings?.mediaPaths]);

  useEffect(() => {
      if (settings?.vaultEnabled && !isVaultUnlocked && settingsLoaded) {
          handleBiometricAuth();
      }
  }, [settings?.vaultEnabled, settingsLoaded, isVaultUnlocked]);

  const toggleSelect = useCallback((id: string) => {
      setSelectedIds(prev =>
          prev.includes(id) ? prev.filter(i => i !== id) : [...prev, id]
      );
  }, []);

  const handleLongPress = useCallback((id: string) => {
      if (!selectionMode) {
          setSelectionMode(true);
          setSelectedIds([id]);
      }
  }, [selectionMode]);

  const handlePress = useCallback((item: any) => {
      if (selectionMode) {
          toggleSelect(item.id);
      } else {
          if (item.type === 'note' && item.thumbnail_url) {
              setFullscreenImage(item.thumbnail_url);
          } else {
              router.push(`/media/${item.id}`);
          }
      }
  }, [selectionMode, toggleSelect, router]);

  const exitSelection = () => {
      setSelectionMode(false);
      setSelectedIds([]);
  };

  const handleBulkUnvault = async () => {
      if (selectedIds.length === 0) return;
      try {
          await toggleVault(selectedIds);
          exitSelection();
          Alert.alert("Success", `${selectedIds.length} items moved to public gallery.`);
      } catch (e) {
          Alert.alert("Error", "Action failed.");
      }
  };

  const handleBulkDelete = () => {
      if (selectedIds.length === 0) return;
      Alert.alert(
          "Delete Selection",
          `Permanently delete ${selectedIds.length} vaulted items?`,
          [
              { text: "Cancel", style: "cancel" },
              { text: "Delete", style: "destructive", onPress: async () => {
                  for (const id of selectedIds) {
                      await deleteEntry(id);
                  }
                  exitSelection();
              }}
          ]
      );
  };

  if (!isVaultUnlocked) {
      return (
          <View style={[styles.unlockContainer, { backgroundColor: theme.background }]}>
              <View style={[styles.lockCircle, { backgroundColor: theme.primary + '20' }]}>
                <Lock size={64} color={theme.primary} />
              </View>
              <Text style={[styles.unlockTitle, { color: theme.text, fontFamily: 'Nunito-ExtraBold' }]}>Vault is Locked</Text>

              {settings?.vaultPin ? (
                  <TextInput
                    style={[styles.pinInput, { backgroundColor: theme.surface, color: theme.text, borderColor: theme.border, borderRadius: settings?.roundedCorners || 20 }]}
                    placeholder="Enter PIN"
                    placeholderTextColor={theme.textMuted}
                    secureTextEntry
                    value={pin}
                    onChangeText={(text) => {
                        setPin(text);
                        if (text === settings.vaultPin) {
                            setVaultUnlocked(true);
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
            {selectionMode ? (
                <View style={styles.selectionHeader}>
                    <TouchableOpacity onPress={exitSelection} style={styles.iconBtn}>
                        <X size={24} color={theme.text} />
                    </TouchableOpacity>
                    <Text style={[styles.title, { color: theme.text, fontSize: 24, marginLeft: 10 }]}>{selectedIds.length} Selected</Text>
                    <View style={styles.selectionActions}>
                        <TouchableOpacity onPress={handleBulkDelete} style={[styles.actionBtn, { backgroundColor: theme.surfaceElevated }]}>
                            <Trash2 size={20} color={theme.error} />
                        </TouchableOpacity>
                        <TouchableOpacity onPress={handleBulkUnvault} style={[styles.unvaultBtn, { backgroundColor: theme.primary }]}>
                            <Unlock size={18} color="white" />
                            <Text style={styles.unvaultBtnText}>Unvault</Text>
                        </TouchableOpacity>
                    </View>
                </View>
            ) : (
                <>
                    <View style={styles.headerTitleRow}>
                        <ShieldCheck size={32} color={theme.primary} />
                        <Text style={[styles.title, { color: theme.primary, fontFamily: 'Nunito-ExtraBold' }]}>Private Vault</Text>
                    </View>
                    <View style={styles.headerRight}>
                        <TouchableOpacity
                            onPress={() => setSelectionMode(true)}
                            style={[styles.iconBtn, { backgroundColor: theme.surfaceElevated, borderRadius: 12, marginRight: 10 }]}
                        >
                            <Layers size={20} color={theme.primary} />
                        </TouchableOpacity>
                        <TouchableOpacity
                            style={[styles.lockBtn, { backgroundColor: theme.surfaceElevated }]}
                            onPress={forceLock}
                        >
                            <LockKeyhole size={20} color={theme.primary} />
                        </TouchableOpacity>
                    </View>
                </>
            )}
        </View>
        {!selectionMode && <Text style={[styles.subtitle, { color: theme.textMuted }]}>{vaultedEntries.length} hidden memories</Text>}
      </View>

      <FlatList
        data={vaultedEntries}
        keyExtractor={(item) => item.id}
        numColumns={cols}
        key={cols}
        contentContainerStyle={styles.list}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={theme.primary} />}
        renderItem={({ item }) => {
          const isSelected = selectedIds.includes(item.id);
          return (
            <View style={{ marginRight: gap, marginBottom: gap }}>
                <TouchableOpacity
                    onLongPress={() => handleLongPress(item.id)}
                    onPress={() => handlePress(item)}
                    activeOpacity={0.8}
                >
                    <MediaCard
                        entry={item}
                        width={cardWidth}
                        onPress={() => handlePress(item)}
                    />
                    {selectionMode && (
                        <View style={styles.selectionOverlay}>
                            {isSelected ? (
                                <CheckCircle2 size={24} color={theme.primary} fill="white" />
                            ) : (
                                <Circle size={24} color="white" />
                            )}
                        </View>
                    )}
                </TouchableOpacity>
            </View>
          );
        }}
        ListEmptyComponent={
            <View style={styles.empty}>
                <Lock size={60} color={theme.surfaceElevated} />
                <Text style={[styles.emptyText, { color: theme.textMuted, marginTop: 20 }]}>Vault is empty</Text>
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
  headerTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', height: 44 },
  headerTitleRow: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  headerRight: { flexDirection: 'row', alignItems: 'center' },
  title: { fontSize: 30 },
  lockBtn: { width: 44, height: 44, borderRadius: 14, alignItems: 'center', justifyContent: 'center', elevation: 2 },
  subtitle: { fontSize: 14, marginTop: 4, marginLeft: 42 },
  list: { paddingHorizontal: 16, paddingBottom: 100 },
  empty: { marginTop: 150, alignItems: 'center' },
  emptyText: { fontFamily: 'Nunito-SemiBold', fontSize: 18 },
  unlockContainer: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: 40 },
  lockCircle: { width: 120, height: 120, borderRadius: 60, justifyContent: 'center', alignItems: 'center', marginBottom: 20 },
  unlockTitle: { fontSize: 26, marginBottom: 30 },
  pinInput: { width: '80%', height: 60, borderWidth: 1, textAlign: 'center', fontSize: 28, marginBottom: 20, fontFamily: 'Nunito-Bold' },
  biometricBtn: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 25, paddingVertical: 14, borderRadius: 25, gap: 10, elevation: 3 },
  biometricText: { color: 'white', fontFamily: 'Nunito-Bold', fontSize: 16 },
  fullscreenOverlay: { flex: 1, backgroundColor: 'black', justifyContent: 'center', alignItems: 'center' },
  fullscreenImage: { width: '100%', height: '100%' },
  closeFullscreen: { position: 'absolute', top: 50, right: 20 },
  selectionHeader: { flexDirection: 'row', alignItems: 'center', flex: 1 },
  selectionActions: { flexDirection: 'row', gap: 10, marginLeft: 'auto' },
  iconBtn: { padding: 10, justifyContent: 'center', alignItems: 'center' },
  actionBtn: { width: 44, height: 44, borderRadius: 14, justifyContent: 'center', alignItems: 'center' },
  unvaultBtn: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 18, borderRadius: 14, gap: 8 },
  unvaultBtnText: { color: 'white', fontFamily: 'Nunito-Bold', fontSize: 14 },
  selectionOverlay: { position: 'absolute', top: 10, right: 10, zIndex: 10 },
});
