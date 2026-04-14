import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, TextInput, Switch, Alert, Modal, Dimensions } from 'react-native';
import { useSettings } from '@/context/SettingsContext';
import { THEMES } from '@/constants/themes';
import { Palette, Layout, Folder, ChevronRight, Lock, Check, Trash2, Fingerprint, Edit3, Plus, X, ShieldCheck, Monitor, Sliders, Smartphone } from 'lucide-react-native';
import * as FileSystem from 'expo-file-system';
import * as LocalAuthentication from 'expo-local-authentication';

const { width } = Dimensions.get('window');
const { StorageAccessFramework } = FileSystem;

export default function SettingsScreen() {
  const { settings, updateSetting, isLoaded } = useSettings();

  // Use a fallback for theme
  const themeKey = settings?.theme || 'kirby';
  const theme = THEMES[themeKey] || THEMES.kirby;

  const [isThemeModalVisible, setIsThemeModalVisible] = useState(false);
  const [isPinEditable, setIsPinEditable] = useState(!settings?.vaultPin);

  if (!isLoaded || !settings) {
      return (
          <View style={[styles.container, { backgroundColor: '#FFF7FA', justifyContent: 'center', alignItems: 'center' }]}>
              <Text>Loading Settings...</Text>
          </View>
      );
  }

  const SettingItem = ({ icon: Icon, label, value, onPress, type = 'link' }: any) => (
    <TouchableOpacity
      style={[styles.settingItem, { borderBottomColor: theme.border }]}
      onPress={onPress}
      disabled={type === 'none'}
    >
      <View style={styles.settingLeft}>
        <View style={[styles.iconContainer, { backgroundColor: theme.surfaceElevated }]}>
          <Icon size={20} color={theme.primary} />
        </View>
        <View>
            <Text style={[styles.settingLabel, { color: theme.text }]}>{label}</Text>
            {value && <Text style={[styles.settingValue, { color: theme.textMuted }]}>{value}</Text>}
        </View>
      </View>
      {type === 'link' && <ChevronRight size={20} color={theme.textMuted} />}
    </TouchableOpacity>
  );

  const requestPinEdit = async () => {
      try {
          const result = await LocalAuthentication.authenticateAsync({
              promptMessage: 'Authenticate to Change PIN',
          });

          if (result.success) {
              setIsPinEditable(true);
          }
      } catch (e) {
          Alert.alert('Error', 'Authentication failed');
      }
  };

  const pickDirectory = async () => {
    try {
      if (!StorageAccessFramework) {
          Alert.alert('Not Available', 'Folder selection requires a standalone app. Please install the APK from GitHub Actions.');
          return;
      }

      const permissions = await StorageAccessFramework.requestDirectoryPermissionsAsync();
      if (permissions.granted) {
        const directoryUri = permissions.directoryUri;
        if (!settings.mediaPaths.includes(directoryUri)) {
            updateSetting('mediaPaths', [...settings.mediaPaths, directoryUri]);
            Alert.alert('Success', 'Folder added to media paths');
        } else {
            Alert.alert('Info', 'Folder already added');
        }
      }
    } catch (e: any) {
      Alert.alert('Error', 'Could not open folder selector: ' + e.message);
    }
  };

  const removePath = (path: string) => {
      updateSetting('mediaPaths', settings.mediaPaths.filter(p => p !== path));
  };

  const themeList: { key: keyof typeof THEMES; label: string; color: string }[] = [
    { key: 'kirby', label: 'Kirby Pastel', color: '#FFD1DC' },
    { key: 'dark', label: 'Deep Dark', color: '#1A1A24' },
    { key: 'ocean', label: 'Ocean Blue', color: '#7EC8E3' },
    { key: 'forest', label: 'Forest Green', color: '#A8D8A8' },
    { key: 'midnight', label: 'Midnight', color: '#6366F1' },
    { key: 'sunset', label: 'Sunset Glow', color: '#F43F5E' },
    { key: 'lavender', label: 'Lavender', color: '#8B5CF6' },
    { key: 'monochrome', label: 'Monochrome', color: '#000000' },
  ];

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <View style={styles.header}>
        <Text style={[styles.title, { color: theme.primary, fontFamily: 'Nunito-ExtraBold' }]}>Settings</Text>
      </View>

      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>

        {/* APPEARANCE SECTION */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
              <Palette size={16} color={theme.textMuted} />
              <Text style={[styles.sectionTitle, { color: theme.textMuted }]}>APPEARANCE</Text>
          </View>
          <View style={[styles.sectionCard, { backgroundColor: theme.surface, borderRadius: settings.roundedCorners }]}>
            <SettingItem
              icon={Palette}
              label="App Theme"
              value={themeList.find(t => t.key === settings.theme)?.label || 'Kirby Pastel'}
              onPress={() => setIsThemeModalVisible(true)}
            />
            <SettingItem
              icon={Smartphone}
              label="Corner Roundness"
              value={`${settings.roundedCorners}px`}
              onPress={() => updateSetting('roundedCorners', settings.roundedCorners >= 32 ? 0 : settings.roundedCorners + 8)}
            />
            <SettingItem
              icon={Sliders}
              label="Shadow Intensity"
              value={`${settings.shadowIntensity}/10`}
              onPress={() => updateSetting('shadowIntensity', settings.shadowIntensity >= 10 ? 0 : settings.shadowIntensity + 2)}
            />
            <View style={styles.switchItem}>
                <View style={styles.settingLeft}>
                    <View style={[styles.iconContainer, { backgroundColor: theme.surfaceElevated }]}>
                        <Layout size={20} color={theme.primary} />
                    </View>
                    <Text style={[styles.settingLabel, { color: theme.text }]}>Grid Layout</Text>
                </View>
                <TouchableOpacity
                    style={[styles.togglePill, { backgroundColor: theme.surfaceElevated }]}
                    onPress={() => updateSetting('gridColumns', settings.gridColumns === 2 ? 3 : 2)}
                >
                    <Text style={[styles.togglePillText, { color: theme.primary }]}>{settings.gridColumns} Columns</Text>
                </TouchableOpacity>
            </View>
          </View>
        </View>

        {/* MEDIA PLAYER SECTION */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
              <Monitor size={16} color={theme.textMuted} />
              <Text style={[styles.sectionTitle, { color: theme.textMuted }]}>MEDIA PLAYER</Text>
          </View>
          <View style={[styles.sectionCard, { backgroundColor: theme.surface, borderRadius: settings.roundedCorners }]}>
            <View style={styles.switchItem}>
                <View style={styles.settingLeft}>
                    <View style={[styles.iconContainer, { backgroundColor: theme.surfaceElevated }]}>
                        <Edit3 size={20} color={theme.primary} />
                    </View>
                    <Text style={[styles.settingLabel, { color: theme.text }]}>Auto-Play Videos</Text>
                </View>
                <Switch
                    value={!!settings.autoPlay}
                    onValueChange={(val) => updateSetting('autoPlay', val)}
                    trackColor={{ false: theme.border, true: theme.primary }}
                    thumbColor="white"
                />
            </View>
            <View style={[styles.switchItem, { borderTopWidth: 1, borderTopColor: theme.border }]}>
                <View style={styles.settingLeft}>
                    <View style={[styles.iconContainer, { backgroundColor: theme.surfaceElevated }]}>
                        <Check size={20} color={theme.primary} />
                    </View>
                    <Text style={[styles.settingLabel, { color: theme.text }]}>Loop Playback</Text>
                </View>
                <Switch
                    value={!!settings.loopVideos}
                    onValueChange={(val) => updateSetting('loopVideos', val)}
                    trackColor={{ false: theme.border, true: theme.primary }}
                    thumbColor="white"
                />
            </View>
          </View>
        </View>

        {/* STORAGE SECTION */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
              <Folder size={16} color={theme.textMuted} />
              <Text style={[styles.sectionTitle, { color: theme.textMuted }]}>STORAGE & PATHS</Text>
          </View>
          <View style={[styles.sectionCard, { backgroundColor: theme.surface, borderRadius: settings.roundedCorners }]}>
            <View style={styles.inputItem}>
              <View style={styles.settingLeft}>
                <View style={[styles.iconContainer, { backgroundColor: theme.surfaceElevated }]}>
                  <Folder size={20} color={theme.primary} />
                </View>
                <Text style={[styles.settingLabel, { color: theme.text }]}>Scan Paths</Text>
                <TouchableOpacity style={[styles.addBtn, { backgroundColor: theme.primary }]} onPress={pickDirectory}>
                    <Plus size={18} color="white" />
                </TouchableOpacity>
              </View>
              <View style={styles.pathList}>
                {(settings.mediaPaths || []).map(path => (
                    <View key={path} style={[styles.pathRow, { backgroundColor: theme.surfaceElevated }]}>
                        <Text style={[styles.pathText, { color: theme.textSecondary }]} numberOfLines={1}>
                            {typeof path === 'string' ? decodeURIComponent(path).split('/').filter(Boolean).pop() : 'Invalid Path'}
                        </Text>
                        <TouchableOpacity onPress={() => removePath(path)} style={styles.pathRemove}>
                            <X size={14} color={theme.error} />
                        </TouchableOpacity>
                    </View>
                ))}
              </View>
            </View>
          </View>
        </View>

        {/* SECURITY SECTION */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
              <ShieldCheck size={16} color={theme.textMuted} />
              <Text style={[styles.sectionTitle, { color: theme.textMuted }]}>SECURITY</Text>
          </View>
          <View style={[styles.sectionCard, { backgroundColor: theme.surface, borderRadius: settings.roundedCorners }]}>
            <View style={styles.inputItem}>
                <View style={styles.settingLeft}>
                    <View style={[styles.iconContainer, { backgroundColor: theme.surfaceElevated }]}>
                        <Lock size={20} color={theme.primary} />
                    </View>
                    <Text style={[styles.settingLabel, { color: theme.text }]}>Vault PIN</Text>
                    {settings.vaultPin && !isPinEditable && (
                        <TouchableOpacity style={styles.unlockBtn} onPress={requestPinEdit}>
                            <Fingerprint size={18} color={theme.primary} />
                        </TouchableOpacity>
                    )}
                </View>
                <TextInput
                    style={[styles.pinInput, { color: isPinEditable ? theme.text : theme.textMuted, borderBottomColor: theme.border }]}
                    value={settings.vaultPin}
                    onChangeText={(t) => updateSetting('vaultPin', t.replace(/[^0-9]/g, ''))}
                    placeholder="Set 4-digit PIN"
                    placeholderTextColor={theme.textMuted}
                    secureTextEntry
                    editable={isPinEditable}
                    keyboardType="numeric"
                    maxLength={4}
                />
            </View>
          </View>
        </View>

        <View style={styles.footer}>
            <Text style={[styles.versionText, { color: theme.textMuted }]}>Zak</Text>
        </View>
      </ScrollView>

      {/* THEME SELECTOR MODAL */}
      <Modal visible={isThemeModalVisible} transparent animationType="slide">
          <View style={styles.modalOverlay}>
              <View style={[styles.modalContent, { backgroundColor: theme.surface, borderRadius: settings.roundedCorners }]}>
                  <View style={styles.modalHeader}>
                    <Text style={[styles.modalTitle, { color: theme.text }]}>Choose Theme</Text>
                    <TouchableOpacity onPress={() => setIsThemeModalVisible(false)}>
                        <X size={24} color={theme.textMuted} />
                    </TouchableOpacity>
                  </View>

                  <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={styles.themeGrid}>
                      {themeList.map((t) => (
                          <TouchableOpacity
                            key={t.key}
                            style={[
                                styles.themeCard,
                                { backgroundColor: theme.surfaceElevated },
                                settings.theme === t.key && { borderColor: theme.primary, borderWidth: 2 }
                            ]}
                            onPress={() => {
                                updateSetting('theme', t.key);
                                setIsThemeModalVisible(false);
                            }}
                          >
                              <View style={[styles.themePreview, { backgroundColor: t.color }]} />
                              <Text style={[styles.themeCardText, { color: theme.text }]}>{t.label}</Text>
                              {settings.theme === t.key && (
                                  <View style={[styles.themeCheck, { backgroundColor: theme.primary }]}>
                                      <Check size={12} color="white" />
                                  </View>
                              )}
                          </TouchableOpacity>
                      ))}
                  </ScrollView>
              </View>
          </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, paddingTop: 60 },
  header: { paddingHorizontal: 25, marginBottom: 25 },
  title: { fontSize: 36, lineHeight: 40 },
  subtitle: { fontSize: 14, fontFamily: 'Nunito-SemiBold', marginTop: 5 },
  scrollContent: { paddingHorizontal: 20, paddingBottom: 100 },
  section: { marginBottom: 30 },
  sectionHeader: { flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 12, marginLeft: 5 },
  sectionTitle: { fontSize: 13, fontFamily: 'Nunito-ExtraBold', letterSpacing: 1 },
  sectionCard: { overflow: 'hidden', elevation: 4, shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.1, shadowRadius: 8 },
  settingItem: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', padding: 18, borderBottomWidth: 1 },
  switchItem: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', padding: 18 },
  settingLeft: { flexDirection: 'row', alignItems: 'center', flex: 1 },
  iconContainer: { width: 40, height: 40, borderRadius: 12, justifyContent: 'center', alignItems: 'center', marginRight: 15 },
  settingLabel: { fontSize: 16, fontFamily: 'Nunito-Bold' },
  settingValue: { fontSize: 12, fontFamily: 'Nunito-SemiBold', marginTop: 2 },
  togglePill: { paddingHorizontal: 12, paddingVertical: 6, borderRadius: 20 },
  togglePillText: { fontSize: 12, fontFamily: 'Nunito-ExtraBold' },
  inputItem: { padding: 18 },
  addBtn: { width: 32, height: 32, borderRadius: 16, justifyContent: 'center', alignItems: 'center', marginLeft: 'auto' },
  pathList: { marginTop: 15, gap: 8 },
  pathRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', padding: 12, borderRadius: 12 },
  pathText: { flex: 1, fontSize: 12, fontFamily: 'Nunito-Medium', marginRight: 10 },
  pathRemove: { padding: 4 },
  unlockBtn: { marginLeft: 10 },
  pinInput: { marginTop: 15, height: 50, fontSize: 24, textAlign: 'center', borderBottomWidth: 1, fontFamily: 'Nunito-ExtraBold', letterSpacing: 10 },
  footer: { alignItems: 'center', marginTop: 20 },
  versionText: { fontSize: 11, fontFamily: 'Nunito-Bold', opacity: 0.6 },
  modalOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.6)', justifyContent: 'flex-end' },
  modalContent: { padding: 25, height: '70%', elevation: 20 },
  modalHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 25 },
  modalTitle: { fontSize: 24, fontFamily: 'Nunito-ExtraBold' },
  themeGrid: { flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'space-between', gap: 15 },
  themeCard: { width: (width - 80) / 2, padding: 15, borderRadius: 20, alignItems: 'center', position: 'relative' },
  themePreview: { width: 50, height: 50, borderRadius: 25, marginBottom: 10, elevation: 3 },
  themeCardText: { fontSize: 14, fontFamily: 'Nunito-Bold' },
  themeCheck: { position: 'absolute', top: 10, right: 10, width: 20, height: 20, borderRadius: 10, justifyContent: 'center', alignItems: 'center' },
});
