import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, FlatList, TouchableOpacity, TextInput, ScrollView, Modal, Alert, KeyboardAvoidingView, Platform, Image, Pressable } from 'react-native';
import { useSettings } from '@/context/SettingsContext';
import { THEMES } from '@/constants/themes';
import { useMedia } from '@/context/MediaContext';
import { Plus, Search, FileText, Film, Edit2, Check, X, Trash2, Mic, Image as ImageIcon, Lock, Unlock, Maximize2, Filter, Fingerprint } from 'lucide-react-native';
import { useRouter } from 'expo-router';
import * as ImagePicker from 'expo-image-picker';
import * as LocalAuthentication from 'expo-local-authentication';

type FilterType = 'all' | 'voice' | 'note';

export default function NotesScreen() {
  const { settings, updateSetting, saveSettings } = useSettings();
  const theme = THEMES[settings.theme];
  const { entries, addEntry, deleteEntry, updateEntry, toggleVault } = useMedia();
  const router = useRouter();

  const [activeTab, setActiveTab] = useState(settings.noteTabs[0] || 'General');
  const [mediaFilter, setMediaFilter] = useState<FilterType>('all');

  // Vault Security State
  const [isVaultUnlocked, setIsVaultUnlocked] = useState(false);
  const [isPinModalVisible, setIsPinModalVisible] = useState(false);
  const [pinInput, setPinInput] = useState('');

  // Note Modal State
  const [isNoteModalVisible, setIsNoteModalVisible] = useState(false);
  const [editingNoteId, setEditingNoteId] = useState<string | null>(null);
  const [noteTitle, setNoteTitle] = useState('');
  const [noteContent, setNoteContent] = useState('');
  const [noteImage, setNoteImage] = useState<string | null>(null);
  const [isNoteVaulted, setIsNoteVaulted] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState(activeTab);

  // Sync active tab if settings change
  useEffect(() => {
    if (!settings.noteTabs.includes(activeTab) && activeTab !== 'Vault') {
      setActiveTab(settings.noteTabs[0] || 'General');
    }
  }, [settings.noteTabs]);

  // Lock vault when switching away
  useEffect(() => {
    if (activeTab !== 'Vault') {
      setIsVaultUnlocked(false);
    }
  }, [activeTab]);

  const authenticateVault = async () => {
    try {
      const hasHardware = await LocalAuthentication.hasHardwareAsync();
      const isEnrolled = await LocalAuthentication.isEnrolledAsync();

      if (hasHardware && isEnrolled) {
        const result = await LocalAuthentication.authenticateAsync({
          promptMessage: 'Unlock Private Vault',
          fallbackLabel: 'Use PIN',
        });

        if (result.success) {
          setIsVaultUnlocked(true);
          setActiveTab('Vault');
          return;
        }
      }

      // Fallback to PIN if biometrics fail or aren't available
      if (settings.vaultPin) {
        setIsPinModalVisible(true);
      } else {
        // If no PIN set, just allow entry but warn
        setActiveTab('Vault');
        setIsVaultUnlocked(true);
      }
    } catch (e) {
      if (settings.vaultPin) setIsPinModalVisible(true);
    }
  };

  const handlePinSubmit = () => {
    if (pinInput === settings.vaultPin) {
      setIsVaultUnlocked(true);
      setIsPinModalVisible(false);
      setActiveTab('Vault');
      setPinInput('');
    } else {
      Alert.alert('Error', 'Incorrect PIN');
      setPinInput('');
    }
  };

  const handleTabPress = (tab: string) => {
    if (tab === 'Vault' && !isVaultUnlocked) {
      authenticateVault();
    } else {
      setActiveTab(tab);
    }
  };

  // Fullscreen Image State
  const [fullscreenImage, setFullscreenImage] = useState<string | null>(null);

  const [isEditingTabs, setIsEditingTabs] = useState(false);
  const [editingTabIdx, setEditingTabIdx] = useState<number | null>(null);
  const [tabRenameValue, setTabRenameValue] = useState('');

  const displayTabs = [...settings.noteTabs, 'Vault'];

  const filteredNotes = entries.filter(entry => {
    if (entry.type === 'video' || entry.type === 'image') return false;
    if (mediaFilter !== 'all' && entry.type !== mediaFilter) return false;

    if (activeTab === 'Vault') {
      return isVaultUnlocked && entry.is_vaulted;
    }

    if (entry.is_vaulted) return false;
    return entry.tags.some(tag => tag.toLowerCase() === activeTab.toLowerCase());
  });

  const openAddNote = () => {
      setEditingNoteId(null);
      setNoteTitle('');
      setNoteContent('');
      setNoteImage(null);
      setIsNoteVaulted(false);
      setSelectedCategory(activeTab === 'Vault' ? settings.noteTabs[0] || 'General' : activeTab);
      setIsNoteModalVisible(true);
  };

  const openEditNote = (note: any) => {
      setEditingNoteId(note.id);
      setNoteTitle(note.title);
      setNoteContent(note.notes);
      setNoteImage(note.thumbnail_url || null);
      setIsNoteVaulted(note.is_vaulted || false);

      const cat = settings.noteTabs.find(t => note.tags.includes(t.toLowerCase())) || activeTab;
      setSelectedCategory(cat);

      setIsNoteModalVisible(true);
  };

  const pickImage = async () => {
      const { status } = await ImagePicker.requestMediaLibraryPermissionsAsync();
      if (status !== 'granted') {
          Alert.alert('Permission Denied', 'Need access to gallery.');
          return;
      }
      const result = await ImagePicker.launchImageLibraryAsync({
          mediaTypes: ImagePicker.MediaTypeOptions.Images,
          allowsEditing: true,
          quality: 0.8,
      });
      if (!result.canceled) {
          setNoteImage(result.assets[0].uri);
      }
  };

  const handleSaveNote = async () => {
    if (!noteTitle.trim()) {
      Alert.alert('Error', 'Please enter a title');
      return;
    }
    const noteData = {
      title: noteTitle,
      type: 'note' as const,
      notes: noteContent,
      thumbnail_url: noteImage || '',
      source_link: '',
      local_path: noteImage || '',
      is_vaulted: isNoteVaulted,
      tags: [selectedCategory.toLowerCase()],
      media_date: new Date().toISOString(),
      duration_seconds: 0,
      file_size_bytes: 0
    };
    try {
        if (editingNoteId) {
            await updateEntry(editingNoteId, noteData);
        } else {
            await addEntry(noteData);
        }
        setIsNoteModalVisible(false);
    } catch (error) {
        Alert.alert('Save Failed', 'Check connection.');
    }
  };

  const handleDeleteNote = () => {
      if (!editingNoteId) return;
      Alert.alert(
          "Delete Note",
          "Are you sure you want to delete this note?",
          [
              { text: "Cancel", style: "cancel" },
              { text: "Delete", style: "destructive", onPress: async () => {
                  await deleteEntry(editingNoteId);
                  setIsNoteModalVisible(false);
              }}
          ]
      );
  };

  const handleToggleVault = async () => {
      if (!editingNoteId) return;
      await toggleVault(editingNoteId);
      setIsNoteVaulted(!isNoteVaulted);
      if (activeTab !== 'Vault') setIsNoteModalVisible(false);
  };

  const saveTabRename = () => {
      if (editingTabIdx !== null && tabRenameValue.trim()) {
          const newTabs = [...settings.noteTabs];
          newTabs[editingTabIdx] = tabRenameValue.trim();
          updateSetting('noteTabs', newTabs);
          saveSettings();
          setEditingTabIdx(null);
      }
  };

  const mediaTypes: { key: FilterType, label: string }[] = [
      { key: 'all', label: 'All' },
      { key: 'voice', label: 'Memos' },
      { key: 'note', label: 'Notes' },
  ];

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <View style={styles.header}>
        <Text style={[styles.title, { color: theme.primary, fontFamily: 'Nunito-ExtraBold' }]}>Notes</Text>
        <View style={styles.headerButtons}>
            <TouchableOpacity
                style={[styles.iconButton, { backgroundColor: theme.surfaceElevated }]}
                onPress={() => router.push('/voice')}
            >
                <Mic size={20} color={theme.primary} />
            </TouchableOpacity>
            <TouchableOpacity
                style={[styles.iconButton, { backgroundColor: theme.surfaceElevated }]}
                onPress={() => setIsEditingTabs(!isEditingTabs)}
            >
                {isEditingTabs ? <Check size={20} color={theme.success} /> : <Edit2 size={20} color={theme.primary} />}
            </TouchableOpacity>
            <TouchableOpacity
                style={[styles.addButton, { backgroundColor: theme.primary }]}
                onPress={openAddNote}
            >
                <Plus color="white" size={24} />
            </TouchableOpacity>
        </View>
      </View>

      <View style={styles.filterSection}>
          <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.filterScroll}>
              {mediaTypes.map((type) => (
                  <TouchableOpacity
                    key={type.key}
                    onPress={() => setMediaFilter(type.key)}
                    style={[
                        styles.filterChip,
                        { borderColor: theme.border, backgroundColor: mediaFilter === type.key ? theme.primary : theme.surfaceElevated }
                    ]}
                  >
                      <Text style={[styles.filterText, { color: mediaFilter === type.key ? 'white' : theme.textSecondary }]}>{type.label}</Text>
                  </TouchableOpacity>
              ))}
          </ScrollView>
      </View>

      <View style={styles.tabsContainer}>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.tabsScroll}>
          {displayTabs.map((tab, idx) => {
            const isSystemTab = tab === 'Vault';
            const settingsIdx = idx;
            const isSelected = activeTab === tab;
            return (
              <TouchableOpacity
                key={tab + idx}
                onPress={() => !isEditingTabs && handleTabPress(tab)}
                style={[
                  styles.tab,
                  { backgroundColor: isSelected && !isEditingTabs ? theme.primary : theme.surfaceElevated },
                  isEditingTabs && !isSystemTab && { borderColor: theme.primary, borderWidth: 1 }
                ]}
              >
                {isEditingTabs && !isSystemTab && editingTabIdx === settingsIdx ? (
                    <TextInput
                        value={tabRenameValue}
                        onChangeText={setTabRenameValue}
                        style={[styles.tabInput, { color: theme.text }]}
                        autoFocus
                        onSubmitEditing={saveTabRename}
                    />
                ) : (
                    <View style={styles.tabContent}>
                        <Text style={[styles.tabText, { color: isSelected && !isEditingTabs ? 'white' : theme.textSecondary }]}>{tab}</Text>
                        {tab === 'Vault' && !isVaultUnlocked && <Lock size={12} color={isSelected ? 'white' : theme.textMuted} style={{ marginLeft: 5 }} />}
                        {isEditingTabs && !isSystemTab && (
                            <TouchableOpacity onPress={() => { setEditingTabIdx(settingsIdx); setTabRenameValue(tab); }}>
                                <Edit2 size={12} color={theme.textMuted} style={{ marginLeft: 5 }} />
                            </TouchableOpacity>
                        )}
                    </View>
                )}
              </TouchableOpacity>
            );
          })}
        </ScrollView>
      </View>

      <FlatList
        data={filteredNotes}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.listContent}
        renderItem={({ item }) => (
          <TouchableOpacity
            style={[styles.noteCard, { backgroundColor: theme.surface, borderRadius: settings.roundedCorners }]}
            onPress={() => openEditNote(item)}
          >
            <View style={styles.noteHeader}>
              {item.type === 'note' ? <FileText size={18} color={theme.primary} /> : <Mic size={18} color={theme.primary} />}
              <Text style={[styles.noteTitle, { color: theme.text }]} numberOfLines={1}>{item.title}</Text>
              {item.is_vaulted && <Lock size={14} color={theme.textMuted} style={{ marginLeft: 'auto' }} />}
            </View>
            <View style={styles.cardContent}>
                <Text style={[styles.noteExcerpt, { color: theme.textSecondary, flex: 1 }]} numberOfLines={3}>{item.notes}</Text>
                {item.thumbnail_url ? (
                    <Pressable onPress={() => setFullscreenImage(item.thumbnail_url)}>
                        <Image source={{ uri: item.thumbnail_url }} style={styles.cardImage} />
                    </Pressable>
                ) : null}
            </View>
          </TouchableOpacity>
        )}
        ListEmptyComponent={
          activeTab === 'Vault' && !isVaultUnlocked ? (
            <View style={styles.lockedContainer}>
              <Lock size={48} color={theme.textMuted} />
              <Text style={[styles.lockedText, { color: theme.textMuted }]}>Vault is Locked</Text>
              <TouchableOpacity style={[styles.unlockBtn, { backgroundColor: theme.primary }]} onPress={authenticateVault}>
                <Text style={styles.unlockBtnText}>Unlock with Biometrics</Text>
              </TouchableOpacity>
            </View>
          ) : (
            <Text style={{ textAlign: 'center', marginTop: 40, color: theme.textMuted }}>No items found</Text>
          )
        }
      />

      {/* PIN Fallback Modal */}
      <Modal visible={isPinModalVisible} transparent animationType="fade">
        <View style={styles.pinOverlay}>
          <View style={[styles.pinContent, { backgroundColor: theme.surface, borderRadius: settings.roundedCorners }]}>
            <Text style={[styles.pinTitle, { color: theme.text }]}>Enter Vault PIN</Text>
            <TextInput
              style={[styles.pinInput, { color: theme.text, borderBottomColor: theme.primary }]}
              value={pinInput}
              onChangeText={setPinInput}
              keyboardType="numeric"
              maxLength={4}
              secureTextEntry
              autoFocus
            />
            <View style={styles.pinButtons}>
              <TouchableOpacity onPress={() => setIsPinModalVisible(false)} style={styles.pinBtn}>
                <Text style={{ color: theme.textMuted }}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity onPress={handlePinSubmit} style={[styles.pinBtn, { backgroundColor: theme.primary, borderRadius: 10 }]}>
                <Text style={{ color: 'white', fontFamily: 'Nunito-Bold' }}>Unlock</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      <Modal visible={isNoteModalVisible} animationType="slide" transparent>
          <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : 'height'} style={styles.modalOverlay}>
              <View style={[styles.modalContent, { backgroundColor: theme.surface, borderTopLeftRadius: 30, borderTopRightRadius: 30 }]}>
                  <View style={styles.modalHeader}>
                      <Text style={[styles.modalTitle, { color: theme.text }]}>{editingNoteId ? 'Edit Note' : 'New Note'}</Text>
                      <View style={{ flexDirection: 'row', gap: 15, alignItems: 'center' }}>
                          <TouchableOpacity onPress={handleToggleVault} style={styles.vaultToggle}>
                              {isNoteVaulted ? <Lock size={22} color={theme.primary} /> : <Unlock size={22} color={theme.textMuted} />}
                              <Text style={[styles.vaultToggleText, { color: isNoteVaulted ? theme.primary : theme.textMuted }]}>Vault</Text>
                          </TouchableOpacity>
                          <TouchableOpacity onPress={() => setIsNoteModalVisible(false)}><X size={24} color={theme.textMuted} /></TouchableOpacity>
                      </View>
                  </View>
                  <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={styles.modalScroll}>
                      <TextInput placeholder="Title" placeholderTextColor={theme.textMuted} style={[styles.modalInput, { color: theme.text, borderBottomColor: theme.border }]} value={noteTitle} onChangeText={setNoteTitle} />

                      <View style={styles.categoryPicker}>
                          <Text style={[styles.categoryLabel, { color: theme.textMuted }]}>CATEGORY</Text>
                          <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.categoryScroll}>
                              {settings.noteTabs.map(cat => (
                                  <TouchableOpacity
                                    key={cat}
                                    onPress={() => setSelectedCategory(cat)}
                                    style={[styles.categoryBtn, { backgroundColor: selectedCategory === cat ? theme.primary : theme.surfaceElevated }]}
                                  >
                                      <Text style={[styles.categoryText, { color: selectedCategory === cat ? 'white' : theme.textSecondary }]}>{cat}</Text>
                                  </TouchableOpacity>
                              ))}
                          </ScrollView>
                      </View>

                      {noteImage && (
                          <View style={styles.imagePreviewContainer}>
                              <Pressable onPress={() => setFullscreenImage(noteImage)}>
                                <Image source={{ uri: noteImage }} style={styles.imagePreview} />
                              </Pressable>
                              <TouchableOpacity style={styles.removeImageBtn} onPress={() => setNoteImage(null)}><X size={16} color="white" /></TouchableOpacity>
                          </View>
                      )}
                      <TextInput placeholder="Write something..." placeholderTextColor={theme.textMuted} style={[styles.modalTextArea, { color: theme.text }]} value={noteContent} onChangeText={setNoteContent} multiline />
                  </ScrollView>
                  <View style={styles.modalFooter}>
                      <TouchableOpacity style={[styles.footerBtn, { backgroundColor: theme.surfaceElevated }]} onPress={pickImage}>
                          <ImageIcon size={20} color={theme.primary} /><Text style={[styles.footerBtnText, { color: theme.text }]}>Image</Text>
                      </TouchableOpacity>
                      {editingNoteId && (
                          <TouchableOpacity style={[styles.footerBtn, { backgroundColor: theme.surfaceElevated }]} onPress={handleDeleteNote}>
                              <Trash2 size={20} color={theme.error} /><Text style={[styles.footerBtnText, { color: theme.text }]}>Delete</Text>
                          </TouchableOpacity>
                      )}
                      <TouchableOpacity style={[styles.saveButton, { backgroundColor: theme.primary, flex: 1 }]} onPress={handleSaveNote}>
                          <Text style={styles.saveButtonText}>Save</Text>
                      </TouchableOpacity>
                  </View>
              </View>
          </KeyboardAvoidingView>
      </Modal>

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
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 20, marginBottom: 15 },
  headerButtons: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  title: { fontSize: 32 },
  addButton: { width: 44, height: 44, borderRadius: 22, justifyContent: 'center', alignItems: 'center', elevation: 4 },
  iconButton: { width: 40, height: 40, borderRadius: 20, justifyContent: 'center', alignItems: 'center' },
  filterSection: { marginBottom: 15 },
  filterScroll: { paddingHorizontal: 20, gap: 10 },
  filterChip: { paddingHorizontal: 15, paddingVertical: 8, borderRadius: 20, borderWidth: 1 },
  filterText: { fontFamily: 'Nunito-Bold', fontSize: 13 },
  tabsContainer: { marginBottom: 15 },
  tabsScroll: { paddingHorizontal: 20 },
  tab: { paddingHorizontal: 16, paddingVertical: 10, borderRadius: 20, marginRight: 10, justifyContent: 'center' },
  tabContent: { flexDirection: 'row', alignItems: 'center' },
  tabText: { fontFamily: 'Nunito-Bold', fontSize: 14 },
  tabInput: { fontSize: 14, fontFamily: 'Nunito-Bold', padding: 0, minWidth: 60 },
  listContent: { paddingHorizontal: 20, paddingBottom: 100 },
  noteCard: { padding: 16, marginBottom: 12, elevation: 2, shadowColor: '#000', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.1, shadowRadius: 2 },
  noteHeader: { flexDirection: 'row', alignItems: 'center', marginBottom: 8 },
  noteTitle: { fontFamily: 'Nunito-Bold', fontSize: 18, marginLeft: 8, flex: 1 },
  cardContent: { flexDirection: 'row', gap: 10 },
  noteExcerpt: { fontFamily: 'Nunito-Regular', fontSize: 14, lineHeight: 20 },
  cardImage: { width: 60, height: 60, borderRadius: 10 },
  modalOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'flex-end' },
  modalContent: { padding: 25, height: '90%' },
  modalHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 },
  modalTitle: { fontSize: 24, fontFamily: 'Nunito-ExtraBold' },
  vaultToggle: { flexDirection: 'row', alignItems: 'center', gap: 4, paddingHorizontal: 8, paddingVertical: 4, borderRadius: 8, backgroundColor: 'rgba(0,0,0,0.05)' },
  vaultToggleText: { fontSize: 12, fontFamily: 'Nunito-Bold' },
  modalScroll: { paddingBottom: 20 },
  modalInput: { fontSize: 20, fontFamily: 'Nunito-Bold', borderBottomWidth: 1, paddingBottom: 10, marginBottom: 20 },
  categoryPicker: { marginBottom: 20 },
  categoryLabel: { fontSize: 10, fontFamily: 'Nunito-ExtraBold', marginBottom: 8 },
  categoryScroll: { flexDirection: 'row' },
  categoryBtn: { paddingHorizontal: 15, paddingVertical: 8, borderRadius: 15, marginRight: 8 },
  categoryText: { fontSize: 12, fontFamily: 'Nunito-Bold' },
  imagePreviewContainer: { position: 'relative', marginBottom: 20 },
  imagePreview: { width: '100%', height: 200, borderRadius: 15 },
  removeImageBtn: { position: 'absolute', top: 10, right: 10, backgroundColor: 'rgba(0,0,0,0.5)', borderRadius: 12, padding: 4 },
  modalTextArea: { minHeight: 200, fontSize: 16, fontFamily: 'Nunito-Regular', textAlignVertical: 'top' },
  modalFooter: { flexDirection: 'row', gap: 10, marginTop: 10 },
  footerBtn: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 12, borderRadius: 15, gap: 6, height: 50 },
  footerBtnText: { fontFamily: 'Nunito-Bold', fontSize: 13 },
  saveButton: { height: 50, borderRadius: 15, justifyContent: 'center', alignItems: 'center' },
  saveButtonText: { color: 'white', fontSize: 16, fontFamily: 'Nunito-Bold' },
  fullscreenOverlay: { flex: 1, backgroundColor: 'black', justifyContent: 'center', alignItems: 'center' },
  fullscreenImage: { width: '100%', height: '100%' },
  closeFullscreen: { position: 'absolute', top: 50, right: 20 },
  lockedContainer: { alignItems: 'center', marginTop: 100, gap: 20 },
  lockedText: { fontFamily: 'Nunito-Bold', fontSize: 18 },
  unlockBtn: { paddingHorizontal: 25, paddingVertical: 15, borderRadius: 15 },
  unlockBtnText: { color: 'white', fontFamily: 'Nunito-Bold' },
  pinOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.6)', justifyContent: 'center', alignItems: 'center', padding: 40 },
  pinContent: { padding: 30, width: '100%', alignItems: 'center' },
  pinTitle: { fontSize: 20, fontFamily: 'Nunito-ExtraBold', marginBottom: 20 },
  pinInput: { width: '80%', fontSize: 32, textAlign: 'center', borderBottomWidth: 2, paddingBottom: 10, letterSpacing: 15, fontFamily: 'Nunito-ExtraBold' },
  pinButtons: { flexDirection: 'row', gap: 20, marginTop: 30, width: '100%' },
  pinBtn: { flex: 1, height: 50, justifyContent: 'center', alignItems: 'center' },
});
