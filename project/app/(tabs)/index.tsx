import React, { useState, useMemo } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TextInput,
  TouchableOpacity,
  useWindowDimensions,
  RefreshControl,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Search, Film, Image as ImageIcon, SlidersHorizontal } from 'lucide-react-native';
import { useMedia } from '@/context/MediaContext';
import { useSettings } from '@/context/SettingsContext';
import { THEMES } from '@/constants/themes';
import MediaCard from '@/components/gallery/MediaCard';
import AnimatedBackground from '@/components/common/AnimatedBackground';

type FilterType = 'all' | 'video' | 'image';

export default function GalleryScreen() {
  const router = useRouter();
  const { entries } = useMedia();
  const { settings } = useSettings();
  const theme = THEMES[settings.theme];
  const { width } = useWindowDimensions();
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState<FilterType>('all');
  const [refreshing, setRefreshing] = useState(false);

  const cols = settings.gridColumns;
  const gap = 12;
  const padding = 16;
  const cardWidth = (width - padding * 2 - gap * (cols - 1)) / cols;

  const visibleEntries = useMemo(() => {
    return entries
      .filter(e => !e.is_vaulted)
      .filter(e => filter === 'all' ? true : e.type === filter)
      .filter(e => search.length === 0
        ? true
        : e.title.toLowerCase().includes(search.toLowerCase()) ||
          e.notes.toLowerCase().includes(search.toLowerCase())
      );
  }, [entries, filter, search]);

  const columns: typeof visibleEntries[] = Array.from({ length: cols }, () => []);
  visibleEntries.forEach((entry, i) => {
    columns[i % cols].push(entry);
  });

  const onRefresh = () => {
    setRefreshing(true);
    setTimeout(() => setRefreshing(false), 600);
  };

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <AnimatedBackground />

      <View style={[styles.header, { backgroundColor: theme.background }]}>
        <View style={styles.headerTop}>
          <Text style={[styles.headerTitle, { color: theme.text }]}>Lexi Central</Text>
          <TouchableOpacity style={[styles.iconBtn, { backgroundColor: theme.surfaceElevated }]}>
            <SlidersHorizontal size={18} color={theme.textSecondary} />
          </TouchableOpacity>
        </View>

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

        <View style={styles.filters}>
          {(['all', 'video', 'image'] as FilterType[]).map(f => (
            <TouchableOpacity
              key={f}
              style={[
                styles.filterChip,
                {
                  backgroundColor: filter === f ? theme.primary : theme.surface,
                  borderColor: filter === f ? theme.primary : theme.border,
                },
              ]}
              onPress={() => setFilter(f)}
            >
              {f === 'video' && <Film size={12} color={filter === f ? theme.text : theme.textMuted} />}
              {f === 'image' && <ImageIcon size={12} color={filter === f ? theme.text : theme.textMuted} />}
              <Text
                style={[
                  styles.filterText,
                  { color: filter === f ? theme.text : theme.textMuted },
                ]}
              >
                {f === 'all' ? 'All' : f === 'video' ? 'Videos' : 'Images'}
              </Text>
            </TouchableOpacity>
          ))}
          <Text style={[styles.countText, { color: theme.textMuted }]}>
            {visibleEntries.length} items
          </Text>
        </View>
      </View>

      <ScrollView
        style={styles.scroll}
        contentContainerStyle={[styles.grid, { padding }]}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={theme.primary} />
        }
      >
        {visibleEntries.length === 0 ? (
          <View style={styles.empty}>
            <Text style={[styles.emptyText, { color: theme.textMuted }]}>No memories found</Text>
          </View>
        ) : (
          <View style={styles.masonry}>
            {columns.map((col, colIdx) => (
              <View key={colIdx} style={{ width: cardWidth }}>
                {col.map(entry => (
                  <MediaCard
                    key={entry.id}
                    entry={entry}
                    width={cardWidth}
                    onPress={() => router.push(`/media/${entry.id}`)}
                  />
                ))}
              </View>
            ))}
          </View>
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    paddingTop: 60,
    paddingHorizontal: 16,
    paddingBottom: 12,
    zIndex: 10,
  },
  headerTop: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 14,
  },
  headerTitle: {
    fontFamily: 'Nunito-ExtraBold',
    fontSize: 28,
  },
  iconBtn: {
    width: 40,
    height: 40,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
  },
  searchBar: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderRadius: 16,
    borderWidth: 1,
    gap: 10,
    marginBottom: 12,
  },
  searchInput: {
    flex: 1,
    fontFamily: 'Nunito-Regular',
    fontSize: 14,
  },
  filters: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  filterChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 20,
    borderWidth: 1,
  },
  filterText: {
    fontFamily: 'Nunito-Bold',
    fontSize: 12,
  },
  countText: {
    fontFamily: 'Nunito-Regular',
    fontSize: 12,
    marginLeft: 'auto',
  },
  scroll: {
    flex: 1,
  },
  grid: {
    paddingBottom: 100,
  },
  masonry: {
    flexDirection: 'row',
    gap: 12,
  },
  empty: {
    alignItems: 'center',
    paddingTop: 80,
  },
  emptyText: {
    fontFamily: 'Nunito-SemiBold',
    fontSize: 16,
  },
});
