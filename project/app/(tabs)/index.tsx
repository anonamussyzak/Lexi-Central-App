import React, { useState, useMemo, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TextInput,
  TouchableOpacity,
  useWindowDimensions,
  RefreshControl,
  FlatList,
  Alert,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Search, Film, Image as ImageIcon, CheckCircle2, Circle, Lock, X, Trash2, Filter, Layers } from 'lucide-react-native';
import { useMedia } from '@/context/MediaContext';
import { useSettings } from '@/context/SettingsContext';
import { THEMES } from '@/constants/themes';
import MediaCard from '@/components/gallery/MediaCard';

type FilterType = 'all' | 'video' | 'image';

export default function GalleryScreen() {
  const router = useRouter();
  const { entries, localFiles, refreshEntries, scanLocalPaths, toggleVault, deleteEntry } = useMedia();
  const { settings, isLoaded: settingsLoaded } = useSettings();
  const theme = THEMES[settings?.theme || 'kirby'] || THEMES.kirby;
  const { width } = useWindowDimensions();

  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState<FilterType>('all');
  const [activeGalleryTab, setActiveGalleryTab] = useState('');
  const [refreshing, setRefreshing] = useState(false);

  const [selectionMode, setSelectionMode] = useState(false);
  const [selectedIds, setSelectedIds] = useState<string[]>([]);

  const cols = settings?.gridColumns || 2;
  const gap = 12;
  const padding = 16;
  const cardWidth = (width - padding * 2 - gap * (cols - 1)) / cols;

  useEffect(() => {
    if (settingsLoaded && settings.galleryTabs && settings.galleryTabs.length > 0) {
      if (!activeGalleryTab || !settings.galleryTabs.includes(activeGalleryTab)) {
        setActiveGalleryTab(settings.galleryTabs[0]);
      }
    }
  }, [settings?.galleryTabs, settingsLoaded]);

  const displayTabs = useMemo(() => [...(settings?.galleryTabs || [])], [settings?.galleryTabs]);

  const allMedia = useMemo(() => [...entries, ...localFiles], [entries, localFiles]);

  const visibleEntries = useMemo(() => {
    const searchLower = search.toLowerCase();
    const tabLower = activeGalleryTab.toLowerCase();
    const isFirstTab = activeGalleryTab === settings?.galleryTabs?.[0];

    return allMedia
      .filter(e => {
          if (e.is_vaulted) return false;
          if (e.type === 'note' || e.type === 'voice') return false;
          if (isFirstTab) return true;
          return e.tags.some(tag => tag.toLowerCase() === tabLower);
      })
      .filter(e => filter === 'all' ? true : e.type === filter)
      .filter(e => search.length === 0
        ? true
        : e.title.toLowerCase().includes(searchLower) ||
          e.notes.toLowerCase().includes(searchLower)
      );
  }, [allMedia, filter, search, activeGalleryTab, settings?.galleryTabs]);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await refreshEntries();
    if (settings?.mediaPaths && settings.mediaPaths.length > 0) {
        await scanLocalPaths(settings.mediaPaths);
    }
    setRefreshing(false);
  }, [refreshEntries, scanLocalPaths, settings?.mediaPaths]);

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

  const handlePress = useCallback((id: string) => {
      if (selectionMode) {
          toggleSelect(id);
      } else {
          router.push(`/media/${id}`);
      }
  }, [selectionMode, toggleSelect, router]);

  const exitSelection = useCallback(() => {
      setSelectionMode(false);
      setSelectedIds([]);
  }, []);

  const handleBulkVault = async () => {
      if (selectedIds.length === 0) return;
      try {
          await toggleVault(selectedIds);
          exitSelection();
          Alert.alert("Success", `${selectedIds.length} items moved to Private Vault.`);
      } catch (e) {
          Alert.alert("Error", "Action failed.");
      }
  };

  const handleBulkDelete = () => {
      if (selectedIds.length === 0) return;
      Alert.alert(
          "Delete Selection",
          `Permanently remove ${selectedIds.length} items?`,
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

  const renderMediaItem = useCallback(({ item }: { item: any }) => {
    const isSelected = selectedIds.includes(item.id);
    return (
        <View style={styles.cardWrapper}>
            <TouchableOpacity
                onLongPress={() => handleLongPress(item.id)}
                onPress={() => handlePress(item.id)}
                activeOpacity={0.8}
            >
                <MediaCard
                    entry={item}
                    width={cardWidth}
                    onPress={() => handlePress(item.id)}
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
  }, [selectedIds, handleLongPress, handlePress, cardWidth, selectionMode, theme.primary]);

  const filterOptions: { key: FilterType, icon: any, label: string }[] = [
      { key: 'all', icon: Filter, label: 'All' },
      { key: 'video', icon: Film, label: 'Videos' },
      { key: 'image', icon: ImageIcon, label: 'Images' },
  ];

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <View style={[styles.header, { backgroundColor: theme.background }]}>
        <View style={styles.headerTop}>
          {selectionMode ? (
              <View style={styles.selectionHeader}>
                  <TouchableOpacity onPress={exitSelection} style={styles.iconBtn}>
                      <X size={24} color={theme.text} />
                  </TouchableOpacity>
                  <Text style={[styles.headerTitle, { color: theme.text, marginLeft: 10 }]}>
                      {selectedIds.length} Selected
                  </Text>
                  <View style={{ flexDirection: 'row', gap: 10, marginLeft: 'auto' }}>
                      <TouchableOpacity onPress={handleBulkDelete} style={[styles.actionBtn, { backgroundColor: theme.surfaceElevated }]}>
                          <Trash2 size={18} color={theme.error} />
                      </TouchableOpacity>
                      <TouchableOpacity onPress={handleBulkVault} style={[styles.vaultBtn, { backgroundColor: theme.primary }]}>
                          <Lock size={18} color="white" />
                          <Text style={styles.vaultBtnText}>Vault</Text>
                      </TouchableOpacity>
                  </View>
              </View>
          ) : (
              <View style={styles.normalHeader}>
                  <Text style={[styles.headerTitle, { color: theme.primary, fontFamily: 'Nunito-ExtraBold' }]}>Lexi Central</Text>
                  <View style={styles.headerRightActions}>
                      <TouchableOpacity
                        onPress={() => setSelectionMode(true)}
                        style={[styles.iconBtn, { backgroundColor: theme.surfaceElevated, borderRadius: 10 }]}
                      >
                          <Layers size={18} color={theme.primary} />
                      </TouchableOpacity>
                  </View>
              </View>
          )}
        </View>

        {!selectionMode && (
            <>
                <View style={[styles.searchBar, { backgroundColor: theme.surface, borderColor: theme.border }]}>
                <Search size={16} color={theme.textMuted} />
                <TextInput
                    style={[styles.searchInput, { color: theme.text }]}
                    placeholder="Search memories..."
                    placeholderTextColor={theme.textMuted}
                    value={search}
                    onChangeText={setSearch}
                />
                </View>

                <View style={styles.filterSection}>
                    <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.filterScroll}>
                        {filterOptions.map((opt) => (
                            <TouchableOpacity
                                key={opt.key}
                                onPress={() => setFilter(opt.key)}
                                style={[
                                    styles.filterChip,
                                    { borderColor: theme.border, backgroundColor: filter === opt.key ? theme.primary : theme.surfaceElevated }
                                ]}
                            >
                                <opt.icon size={14} color={filter === opt.key ? 'white' : theme.primary} />
                                <Text style={[styles.filterText, { color: filter === opt.key ? 'white' : theme.textSecondary }]}>{opt.label}</Text>
                            </TouchableOpacity>
                        ))}
                    </ScrollView>
                </View>

                <View style={styles.tabsWrapper}>
                    <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.tabsScroll}>
                        {displayTabs.map((tab, idx) => {
                            const isSelected = activeGalleryTab === tab;
                            return (
                                <TouchableOpacity
                                    key={tab + idx}
                                    onPress={() => setActiveGalleryTab(tab)}
                                    style={[
                                        styles.galleryTab,
                                        isSelected && { backgroundColor: theme.primary },
                                    ]}
                                >
                                    <Text style={[
                                        styles.galleryTabText,
                                        { color: isSelected ? 'white' : theme.textSecondary }
                                    ]}>{tab}</Text>
                                </TouchableOpacity>
                            );
                        })}
                    </ScrollView>
                </View>
            </>
        )}
      </View>

      <FlatList
        data={visibleEntries}
        key={cols}
        numColumns={cols}
        style={styles.scroll}
        contentContainerStyle={[styles.grid, { padding }]}
        columnWrapperStyle={{ gap }}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={theme.primary} />
        }
        renderItem={renderMediaItem}
        keyExtractor={item => item.id}
        removeClippedSubviews={true}
        ListEmptyComponent={
          <View style={styles.empty}>
            <Text style={[styles.emptyText, { color: theme.textMuted }]}>No items found</Text>
          </View>
        }
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  header: { paddingTop: 60, paddingHorizontal: 16, paddingBottom: 12 },
  headerTop: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14, height: 40 },
  normalHeader: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', flex: 1 },
  headerRightActions: { flexDirection: 'row', gap: 10 },
  headerTitle: { fontSize: 28 },
  searchBar: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 14, paddingVertical: 10, borderRadius: 16, borderWidth: 1, gap: 10, marginBottom: 12 },
  searchInput: { flex: 1, fontFamily: 'Nunito-Regular', fontSize: 14 },
  filterSection: { marginBottom: 12 },
  filterScroll: { gap: 8, paddingRight: 20 },
  filterChip: { flexDirection: 'row', alignItems: 'center', gap: 6, paddingHorizontal: 12, paddingVertical: 6, borderRadius: 20, borderWidth: 1 },
  filterText: { fontFamily: 'Nunito-Bold', fontSize: 11 },
  tabsWrapper: { marginBottom: 12 },
  tabsScroll: { gap: 8, paddingRight: 20 },
  galleryTab: { paddingHorizontal: 16, paddingVertical: 8, borderRadius: 20, backgroundColor: 'rgba(0,0,0,0.05)', justifyContent: 'center' },
  galleryTabText: { fontFamily: 'Nunito-Bold', fontSize: 13 },
  scroll: { flex: 1 },
  grid: { paddingBottom: 100 },
  cardWrapper: { marginBottom: 12 },
  empty: { alignItems: 'center', paddingTop: 80 },
  emptyText: { fontFamily: 'Nunito-SemiBold', fontSize: 16 },
  selectionHeader: { flexDirection: 'row', alignItems: 'center', flex: 1 },
  iconBtn: { padding: 8, justifyContent: 'center', alignItems: 'center' },
  actionBtn: { width: 40, height: 40, borderRadius: 12, justifyContent: 'center', alignItems: 'center' },
  vaultBtn: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 15, paddingVertical: 8, borderRadius: 12, gap: 6 },
  vaultBtnText: { color: 'white', fontFamily: 'Nunito-Bold', fontSize: 14 },
  selectionOverlay: { position: 'absolute', top: 10, right: 10, zIndex: 10, shadowColor: '#000', shadowOpacity: 0.2, shadowRadius: 4 },
});
