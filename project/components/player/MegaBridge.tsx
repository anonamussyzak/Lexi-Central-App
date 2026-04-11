import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Linking,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { ExternalLink, Download, HardDrive, FileVideoCamera as FileVideo, CircleAlert as AlertCircle, Zap } from 'lucide-react-native';
import { useSettings } from '@/context/SettingsContext';
import { THEMES } from '@/constants/themes';
import { formatFileSize } from '@/lib/utils';

interface MegaMetadata {
  name: string;
  size: number;
  type: string;
}

interface MegaBridgeProps {
  megaUrl: string;
}

const SUPABASE_URL = process.env.EXPO_PUBLIC_SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY;

export default function MegaBridge({ megaUrl }: MegaBridgeProps) {
  const { settings } = useSettings();
  const theme = THEMES[settings.theme];
  const [metadata, setMetadata] = useState<MegaMetadata | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [fetched, setFetched] = useState(false);

  const fetchMetadata = async () => {
    setLoading(true);
    setError(null);
    try {
      const resp = await fetch(`${SUPABASE_URL}/functions/v1/mega-metadata`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
        },
        body: JSON.stringify({ url: megaUrl }),
      });
      const data = await resp.json();
      if (data.error) throw new Error(data.error);
      setMetadata(data);
      setFetched(true);
    } catch (e: any) {
      setError(e.message || 'Could not fetch MEGA metadata');
      setFetched(true);
    } finally {
      setLoading(false);
    }
  };

  const openInBrowser = async () => {
    const canOpen = await Linking.canOpenURL(megaUrl);
    if (canOpen) {
      Linking.openURL(megaUrl);
    }
  };

  const openInVLC = async () => {
    const vlcUrl = `vlc://${megaUrl}`;
    const canOpen = await Linking.canOpenURL(vlcUrl);
    if (canOpen) {
      Linking.openURL(vlcUrl);
    } else {
      Linking.openURL(megaUrl);
    }
  };

  const radius = settings.roundedCorners;

  return (
    <View style={[styles.container, { backgroundColor: theme.surfaceElevated, borderRadius: radius, borderColor: theme.border }]}>
      <View style={styles.headerRow}>
        <View style={[styles.iconBadge, { backgroundColor: theme.primary }]}>
          <Zap size={14} color={theme.text} />
        </View>
        <View style={styles.headerText}>
          <Text style={[styles.title, { color: theme.text }]}>MEGA Bridge</Text>
          <Text style={[styles.subtitle, { color: theme.textMuted }]} numberOfLines={1}>
            {megaUrl.replace('https://mega.nz/', '')}
          </Text>
        </View>
      </View>

      {!fetched && (
        <TouchableOpacity
          style={[styles.fetchButton, { backgroundColor: theme.primary }]}
          onPress={fetchMetadata}
          disabled={loading}
        >
          {loading ? (
            <ActivityIndicator size="small" color={theme.text} />
          ) : (
            <>
              <HardDrive size={14} color={theme.text} />
              <Text style={[styles.fetchButtonText, { color: theme.text }]}>Fetch File Info</Text>
            </>
          )}
        </TouchableOpacity>
      )}

      {error && (
        <View style={[styles.errorBox, { backgroundColor: theme.error + '30' }]}>
          <AlertCircle size={14} color={theme.error} />
          <Text style={[styles.errorText, { color: theme.error }]}>{error}</Text>
        </View>
      )}

      {metadata && (
        <View style={[styles.metaBox, { backgroundColor: theme.surface }]}>
          <View style={styles.metaRow}>
            <FileVideo size={14} color={theme.textMuted} />
            <Text style={[styles.metaLabel, { color: theme.textSecondary }]}>{metadata.name}</Text>
          </View>
          <View style={styles.metaRow}>
            <Download size={14} color={theme.textMuted} />
            <Text style={[styles.metaValue, { color: theme.textMuted }]}>{formatFileSize(metadata.size)}</Text>
          </View>
        </View>
      )}

      <View style={styles.actions}>
        <TouchableOpacity
          style={[styles.actionBtn, { backgroundColor: theme.secondary, flex: 1 }]}
          onPress={openInVLC}
        >
          <ExternalLink size={14} color={theme.text} />
          <Text style={[styles.actionBtnText, { color: theme.text }]}>External Player</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.actionBtn, { backgroundColor: theme.surface, borderColor: theme.border, borderWidth: 1, flex: 1 }]}
          onPress={openInBrowser}
        >
          <ExternalLink size={14} color={theme.textSecondary} />
          <Text style={[styles.actionBtnText, { color: theme.textSecondary }]}>Open MEGA</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    borderWidth: 1,
    padding: 14,
    gap: 12,
  },
  headerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  iconBadge: {
    width: 32,
    height: 32,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerText: {
    flex: 1,
  },
  title: {
    fontFamily: 'Nunito-Bold',
    fontSize: 14,
  },
  subtitle: {
    fontFamily: 'Nunito-Regular',
    fontSize: 11,
    marginTop: 1,
  },
  fetchButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    paddingVertical: 10,
    borderRadius: 12,
  },
  fetchButtonText: {
    fontFamily: 'Nunito-Bold',
    fontSize: 13,
  },
  errorBox: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    padding: 10,
    borderRadius: 10,
  },
  errorText: {
    fontFamily: 'Nunito-Regular',
    fontSize: 12,
    flex: 1,
  },
  metaBox: {
    padding: 10,
    borderRadius: 10,
    gap: 6,
  },
  metaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  metaLabel: {
    fontFamily: 'Nunito-SemiBold',
    fontSize: 13,
    flex: 1,
  },
  metaValue: {
    fontFamily: 'Nunito-Regular',
    fontSize: 12,
  },
  actions: {
    flexDirection: 'row',
    gap: 8,
  },
  actionBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    paddingVertical: 10,
    paddingHorizontal: 12,
    borderRadius: 12,
  },
  actionBtnText: {
    fontFamily: 'Nunito-Bold',
    fontSize: 12,
  },
});
