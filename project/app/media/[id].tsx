import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Image,
  TouchableOpacity,
  ScrollView,
  TextInput,
  KeyboardAvoidingView,
  Platform,
  Alert,
} from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { X, ArrowLeft, Lock, Clock as Unlock, Trash2, Share2, Tag, Calendar, Clock, HardDrive, Link as LinkIcon, Save } from 'lucide-react-native';
import { useMedia } from '@/context/MediaContext';
import { useSettings } from '@/context/SettingsContext';
import { THEMES } from '@/constants/themes';
import { formatDate, formatDuration, formatFileSize, isMegaUrl } from '@/lib/utils';
import NotesPanel from '@/components/player/NotesPanel';
import MegaBridge from '@/components/player/MegaBridge';

export default function MediaDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { entries, updateEntry, toggleVault, deleteEntry, syncEntry } = useMedia();
  const { settings } = useSettings();
  const theme = THEMES[settings.theme];

  const entry = entries.find(e => e.id === id);
  const [activeTab, setActiveTab] = useState<'info' | 'notes' | 'source'>('info');
  const [editingTitle, setEditingTitle] = useState(false);
  const [titleDraft, setTitleDraft] = useState(entry?.title ?? '');
  const [sourceLink, setSourceLink] = useState(entry?.source_link ?? '');
  const [editingSource, setEditingSource] = useState(false);
  const [syncing, setSyncing] = useState(false);

  const radius = settings.roundedCorners;

  if (!entry) {
    return (
      <View style={[styles.notFound, { backgroundColor: theme.background }]}>
        <Text style={[styles.notFoundText, { color: theme.text }]}>Entry not found</Text>
        <TouchableOpacity onPress={() => router.back()}>
          <Text style={[styles.backLink, { color: theme.primary }]}>Go back</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const handleSaveNotes = useCallback((notes: string) => {
    updateEntry(entry.id, { notes });
  }, [entry.id, updateEntry]);

  const handleSaveTitle = useCallback(() => {
    if (titleDraft.trim()) {
      updateEntry(entry.id, { title: titleDraft.trim() });
    }
    setEditingTitle(false);
  }, [titleDraft, entry.id, updateEntry]);

  const handleSaveSource = useCallback(() => {
    updateEntry(entry.id, { source_link: sourceLink });
    setEditingSource(false);
  }, [sourceLink, entry.id, updateEntry]);

  const handleVaultToggle = useCallback(() => {
    toggleVault(entry.id);
  }, [entry.id, toggleVault]);

  const handleDelete = useCallback(() => {
    Alert.alert('Delete Memory', 'This action cannot be undone.', [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Delete', style: 'destructive', onPress: () => { deleteEntry(entry.id); router.back(); } },
    ]);
  }, [entry.id, deleteEntry, router]);

  const handleSync = useCallback(async () => {
    setSyncing(true);
    await syncEntry(entry);
    setSyncing(false);
  }, [entry, syncEntry]);

  const hasMega = isMegaUrl(entry.source_link);

  const tabs = [
    { key: 'info', label: 'Info' },
    { key: 'notes', label: 'Notes' },
    { key: 'source', label: 'Source' },
  ] as const;

  return (
    <KeyboardAvoidingView
      style={[styles.container, { backgroundColor: theme.background }]}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <View style={[styles.hero, { backgroundColor: theme.surface }]}>
        {entry.thumbnail_url ? (
          <Image source={{ uri: entry.thumbnail_url }} style={styles.heroImage} resizeMode="cover" />
        ) : (
          <View style={[styles.heroPlaceholder, { backgroundColor: theme.surfaceElevated }]} />
        )}
        <View style={[styles.heroOverlay, { backgroundColor: theme.overlay }]} />

        <View style={styles.heroHeader}>
          <TouchableOpacity style={[styles.backBtn, { backgroundColor: 'rgba(255,255,255,0.2)' }]} onPress={() => router.back()}>
            <ArrowLeft size={20} color="#FFFFFF" />
          </TouchableOpacity>
          <View style={styles.heroActions}>
            <TouchableOpacity style={[styles.heroActionBtn, { backgroundColor: 'rgba(255,255,255,0.2)' }]} onPress={handleVaultToggle}>
              {entry.is_vaulted ? <Unlock size={18} color="#FFFFFF" /> : <Lock size={18} color="#FFFFFF" />}
            </TouchableOpacity>
            <TouchableOpacity style={[styles.heroActionBtn, { backgroundColor: 'rgba(255,255,255,0.2)' }]} onPress={handleDelete}>
              <Trash2 size={18} color="#FFFFFF" />
            </TouchableOpacity>
          </View>
        </View>

        <View style={styles.heroFooter}>
          {editingTitle ? (
            <View style={styles.titleEditRow}>
              <TextInput
                style={[styles.titleInput, { color: '#FFFFFF', borderBottomColor: theme.primary }]}
                value={titleDraft}
                onChangeText={setTitleDraft}
                autoFocus
                onBlur={handleSaveTitle}
                onSubmitEditing={handleSaveTitle}
              />
              <TouchableOpacity onPress={handleSaveTitle}>
                <Save size={18} color="#FFFFFF" />
              </TouchableOpacity>
            </View>
          ) : (
            <TouchableOpacity onPress={() => { setEditingTitle(true); setTitleDraft(entry.title); }}>
              <Text style={styles.heroTitle}>{entry.title}</Text>
            </TouchableOpacity>
          )}
          <Text style={styles.heroDate}>{formatDate(entry.media_date)}</Text>
        </View>
      </View>

      <View style={[styles.tabBar, { backgroundColor: theme.surface, borderBottomColor: theme.border }]}>
        {tabs.map(tab => (
          <TouchableOpacity
            key={tab.key}
            style={[
              styles.tab,
              activeTab === tab.key && [styles.tabActive, { borderBottomColor: theme.tabBarActive }],
            ]}
            onPress={() => setActiveTab(tab.key)}
          >
            <Text style={[
              styles.tabText,
              { color: activeTab === tab.key ? theme.tabBarActive : theme.textMuted }
            ]}>
              {tab.label}
            </Text>
          </TouchableOpacity>
        ))}
        <TouchableOpacity
          style={[styles.syncBtn, { backgroundColor: theme.primary, marginLeft: 'auto', marginRight: 12 }]}
          onPress={handleSync}
        >
          <Share2 size={13} color={theme.text} />
          <Text style={[styles.syncBtnText, { color: theme.text }]}>{syncing ? 'Syncing...' : 'Sync'}</Text>
        </TouchableOpacity>
      </View>

      {activeTab === 'info' && (
        <ScrollView style={styles.content} contentContainerStyle={styles.contentInner} showsVerticalScrollIndicator={false}>
          <View style={styles.metaGrid}>
            {entry.type === 'video' && entry.duration_seconds > 0 && (
              <View style={[styles.metaItem, { backgroundColor: theme.surface, borderRadius: radius }]}>
                <Clock size={16} color={theme.primary} />
                <Text style={[styles.metaLabel, { color: theme.textMuted }]}>Duration</Text>
                <Text style={[styles.metaValue, { color: theme.text }]}>{formatDuration(entry.duration_seconds)}</Text>
              </View>
            )}
            <View style={[styles.metaItem, { backgroundColor: theme.surface, borderRadius: radius }]}>
              <Calendar size={16} color={theme.secondary} />
              <Text style={[styles.metaLabel, { color: theme.textMuted }]}>Date</Text>
              <Text style={[styles.metaValue, { color: theme.text }]}>{formatDate(entry.media_date)}</Text>
            </View>
            {entry.file_size_bytes > 0 && (
              <View style={[styles.metaItem, { backgroundColor: theme.surface, borderRadius: radius }]}>
                <HardDrive size={16} color={theme.accent} />
                <Text style={[styles.metaLabel, { color: theme.textMuted }]}>Size</Text>
                <Text style={[styles.metaValue, { color: theme.text }]}>{formatFileSize(entry.file_size_bytes)}</Text>
              </View>
            )}
            <View style={[styles.metaItem, { backgroundColor: theme.surface, borderRadius: radius }]}>
              <Tag size={16} color={theme.warning} />
              <Text style={[styles.metaLabel, { color: theme.textMuted }]}>Type</Text>
              <Text style={[styles.metaValue, { color: theme.text }]}>{entry.type}</Text>
            </View>
          </View>

          {entry.tags.length > 0 && (
            <View style={styles.tagsSection}>
              <Text style={[styles.sectionLabel, { color: theme.text }]}>Tags</Text>
              <View style={styles.tags}>
                {entry.tags.map(tag => (
                  <View key={tag} style={[styles.tag, { backgroundColor: theme.primary + '40' }]}>
                    <Text style={[styles.tagText, { color: theme.text }]}>#{tag}</Text>
                  </View>
                ))}
              </View>
            </View>
          )}
        </ScrollView>
      )}

      {activeTab === 'notes' && (
        <View style={styles.notesContainer}>
          <NotesPanel notes={entry.notes} onSave={handleSaveNotes} />
        </View>
      )}

      {activeTab === 'source' && (
        <ScrollView style={styles.content} contentContainerStyle={styles.contentInner} showsVerticalScrollIndicator={false}>
          <Text style={[styles.sectionLabel, { color: theme.text }]}>Media Source</Text>
          <Text style={[styles.sectionHint, { color: theme.textMuted }]}>
            Link to external media (e.g. MEGA.nz). Only this URL is stored — no files are uploaded.
          </Text>

          <View style={[styles.sourceInputContainer, { borderColor: theme.border, backgroundColor: theme.surface }]}>
            <LinkIcon size={16} color={theme.textMuted} />
            {editingSource ? (
              <TextInput
                style={[styles.sourceInput, { color: theme.text }]}
                value={sourceLink}
                onChangeText={setSourceLink}
                autoFocus
                autoCapitalize="none"
                autoCorrect={false}
                placeholder="https://mega.nz/file/..."
                placeholderTextColor={theme.textMuted}
                onBlur={handleSaveSource}
              />
            ) : (
              <TouchableOpacity style={{ flex: 1 }} onPress={() => { setEditingSource(true); setSourceLink(entry.source_link); }}>
                <Text style={[styles.sourceText, { color: entry.source_link ? theme.text : theme.textMuted }]} numberOfLines={2}>
                  {entry.source_link || 'Tap to add a source link...'}
                </Text>
              </TouchableOpacity>
            )}
            {editingSource && (
              <TouchableOpacity onPress={handleSaveSource}>
                <Save size={16} color={theme.primary} />
              </TouchableOpacity>
            )}
          </View>

          {hasMega && (
            <View style={{ marginTop: 16 }}>
              <MegaBridge megaUrl={entry.source_link} />
            </View>
          )}

          {!hasMega && entry.source_link.length > 0 && (
            <View style={[styles.externalBox, { backgroundColor: theme.surfaceElevated, borderRadius: radius }]}>
              <Text style={[styles.externalHint, { color: theme.textMuted }]}>
                Non-MEGA URL detected. You can still open it in the browser.
              </Text>
            </View>
          )}
        </ScrollView>
      )}
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  notFound: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 12,
  },
  notFoundText: {
    fontFamily: 'Nunito-Bold',
    fontSize: 18,
  },
  backLink: {
    fontFamily: 'Nunito-SemiBold',
    fontSize: 14,
  },
  hero: {
    height: 280,
    position: 'relative',
  },
  heroImage: {
    width: '100%',
    height: '100%',
  },
  heroPlaceholder: {
    width: '100%',
    height: '100%',
  },
  heroOverlay: {
    ...StyleSheet.absoluteFillObject,
  },
  heroHeader: {
    position: 'absolute',
    top: 52,
    left: 16,
    right: 16,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  backBtn: {
    width: 40,
    height: 40,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
  },
  heroActions: {
    flexDirection: 'row',
    gap: 8,
  },
  heroActionBtn: {
    width: 40,
    height: 40,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
  },
  heroFooter: {
    position: 'absolute',
    bottom: 16,
    left: 16,
    right: 16,
  },
  heroTitle: {
    fontFamily: 'Nunito-ExtraBold',
    fontSize: 22,
    color: '#FFFFFF',
    lineHeight: 28,
    textShadowColor: 'rgba(0,0,0,0.4)',
    textShadowOffset: { width: 0, height: 1 },
    textShadowRadius: 4,
  },
  heroDate: {
    fontFamily: 'Nunito-SemiBold',
    fontSize: 13,
    color: 'rgba(255,255,255,0.8)',
    marginTop: 4,
  },
  titleEditRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  titleInput: {
    flex: 1,
    fontFamily: 'Nunito-ExtraBold',
    fontSize: 22,
    borderBottomWidth: 2,
    paddingBottom: 4,
  },
  tabBar: {
    flexDirection: 'row',
    borderBottomWidth: 1,
    alignItems: 'center',
  },
  tab: {
    paddingHorizontal: 20,
    paddingVertical: 14,
    borderBottomWidth: 2,
    borderBottomColor: 'transparent',
  },
  tabActive: {},
  tabText: {
    fontFamily: 'Nunito-Bold',
    fontSize: 13,
  },
  syncBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 10,
    marginVertical: 8,
  },
  syncBtnText: {
    fontFamily: 'Nunito-Bold',
    fontSize: 11,
  },
  content: {
    flex: 1,
  },
  contentInner: {
    padding: 16,
    paddingBottom: 60,
    gap: 16,
  },
  metaGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10,
  },
  metaItem: {
    flex: 1,
    minWidth: 130,
    padding: 12,
    gap: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 6,
    elevation: 3,
  },
  metaLabel: {
    fontFamily: 'Nunito-Regular',
    fontSize: 11,
  },
  metaValue: {
    fontFamily: 'Nunito-Bold',
    fontSize: 14,
  },
  tagsSection: {
    gap: 8,
  },
  sectionLabel: {
    fontFamily: 'Nunito-Bold',
    fontSize: 16,
  },
  sectionHint: {
    fontFamily: 'Nunito-Regular',
    fontSize: 13,
    lineHeight: 19,
    marginTop: -8,
  },
  tags: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  tag: {
    paddingHorizontal: 12,
    paddingVertical: 5,
    borderRadius: 20,
  },
  tagText: {
    fontFamily: 'Nunito-Bold',
    fontSize: 12,
  },
  notesContainer: {
    flex: 1,
    padding: 16,
  },
  sourceInputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    padding: 14,
    borderRadius: 14,
    borderWidth: 1,
  },
  sourceInput: {
    flex: 1,
    fontFamily: 'Nunito-Regular',
    fontSize: 13,
  },
  sourceText: {
    fontFamily: 'Nunito-Regular',
    fontSize: 13,
    lineHeight: 19,
  },
  externalBox: {
    padding: 14,
  },
  externalHint: {
    fontFamily: 'Nunito-Regular',
    fontSize: 13,
  },
});
