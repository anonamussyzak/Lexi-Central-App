import React, { createContext, useContext, useState, useCallback, ReactNode, useEffect, useRef } from 'react';
import { MediaEntry, MediaType } from '@/lib/types';
import { supabase } from '@/lib/supabase';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as FileSystem from 'expo-file-system';
import { Alert } from 'react-native';
import { useSettings } from './SettingsContext';

const { StorageAccessFramework } = FileSystem;

interface MediaContextValue {
  entries: MediaEntry[];
  localFiles: MediaEntry[];
  isLoading: boolean;
  isVaultUnlocked: boolean;
  setVaultUnlocked: (unlocked: boolean) => void;
  addEntry: (entry: Omit<MediaEntry, 'id' | 'created_at' | 'updated_at'>) => Promise<void>;
  updateEntry: (id: string, updates: Partial<MediaEntry>) => Promise<void>;
  deleteEntry: (id: string) => Promise<void>;
  toggleVault: (id: string) => Promise<void>;
  refreshEntries: () => Promise<void>;
  scanLocalPaths: (pathUris: string[]) => Promise<void>;
}

const MediaContext = createContext<MediaContextValue>({
  entries: [],
  localFiles: [],
  isLoading: false,
  isVaultUnlocked: false,
  setVaultUnlocked: () => {},
  addEntry: async () => {},
  updateEntry: async () => {},
  deleteEntry: async () => {},
  toggleVault: async () => {},
  refreshEntries: async () => {},
  scanLocalPaths: async () => {},
});

const STORAGE_KEY = '@lexi_central_notes';
const LOCAL_FILES_KEY = '@lexi_central_local_files';
const VAULT_DIR = `${FileSystem.documentDirectory}VaultedMedia/`;

const sanitizeId = (uri: string, name: string) => {
    const combined = `${uri}_${name}`;
    return combined.replace(/[^a-zA-Z0-9]/g, '_').substring(Math.max(0, combined.length - 80));
};

const getCleanFolderName = (uri: string) => {
    try {
        const decoded = decodeURIComponent(uri);
        const parts = decoded.split(/[:/]/);
        const cleanParts = parts.filter(p =>
            p &&
            !p.includes('content') &&
            !p.includes('com.android') &&
            p.toLowerCase() !== 'primary' &&
            p.toLowerCase() !== 'tree' &&
            p.toLowerCase() !== 'document'
        );
        let name = cleanParts.pop() || 'General';
        if (name === '0') return 'Internal Storage';
        return name.replace(/^primary:/i, '').replace(/ \(\d+\)$/, '').trim();
    } catch (e) {
        return 'General';
    }
};

export function MediaProvider({ children }: { children: ReactNode }) {
  const { settings, isLoaded: settingsLoaded } = useSettings();
  const [entries, setEntries] = useState<MediaEntry[]>([]);
  const [localFiles, setLocalFiles] = useState<MediaEntry[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isVaultUnlocked, setIsVaultUnlocked] = useState(false);
  const isScanning = useRef(false);

  // Sync to disk on state change
  useEffect(() => {
      if (!isLoading) {
          AsyncStorage.setItem(LOCAL_FILES_KEY, JSON.stringify(localFiles)).catch(() => {});
      }
  }, [localFiles, isLoading]);

  useEffect(() => {
      if (!isLoading) {
          AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(entries)).catch(() => {});
      }
  }, [entries, isLoading]);

  useEffect(() => {
    const init = async () => {
      try {
        const dirInfo = await FileSystem.getInfoAsync(VAULT_DIR);
        if (!dirInfo.exists) {
            await FileSystem.makeDirectoryAsync(VAULT_DIR, { intermediates: true });
        }
        const cached = await AsyncStorage.getItem(STORAGE_KEY);
        const cachedLocal = await AsyncStorage.getItem(LOCAL_FILES_KEY);
        if (cached) setEntries(JSON.parse(cached));
        if (cachedLocal) setLocalFiles(JSON.parse(cachedLocal));
      } catch (e) {
        console.error('Cache load failed', e);
      } finally {
        setIsLoading(false);
      }
    };
    init();
  }, []);

  useEffect(() => {
      if (settingsLoaded && settings.mediaPaths?.length > 0) {
          scanLocalPaths(settings.mediaPaths);
      }
  }, [settings.mediaPaths, settingsLoaded]);

  useEffect(() => {
    let channel: any;
    const setupRealtime = () => {
        channel = supabase
          .channel('schema-db-changes')
          .on(
            'postgres_changes',
            { event: '*', schema: 'public', table: 'media_entries' },
            () => refreshEntries()
          )
          .subscribe();
    };
    setupRealtime();
    return () => { if (channel) supabase.removeChannel(channel); };
  }, []);

  const refreshEntries = useCallback(async () => {
    try {
      const { data, error } = await supabase.from('media_entries').select('*').order('created_at', { ascending: false });
      if (!error && data) {
        setEntries(data);
      }
    } catch (e) {}
  }, []);

  const scanLocalPaths = useCallback(async (pathUris: string[]) => {
    if (!pathUris || pathUris.length === 0 || isScanning.current) return;
    isScanning.current = true;
    try {
      let allScannedFiles: MediaEntry[] = [];
      for (const pathUri of pathUris) {
          if (!pathUri) continue;
          const isSAF = pathUri.startsWith('content://');
          const folderName = getCleanFolderName(pathUri);
          let files: string[] = [];
          try {
              if (isSAF) {
                  files = await StorageAccessFramework.readDirectoryAsync(pathUri);
              } else {
                  files = await FileSystem.readDirectoryAsync(pathUri);
                  files = files.map(f => pathUri + (pathUri.endsWith('/') ? '' : '/') + f);
              }
              const scannedPromises = files.slice(0, 300).map(async (fileUri) => {
                const name = decodeURIComponent(fileUri).split('/').pop() || 'Unknown';
                const lowerName = name.toLowerCase();
                const isVideo = lowerName.match(/\.(mp4|mkv|mov|avi|3gp|webm|flv|ts|m4v|wmv|mpg|mpeg)$/);
                const isImage = lowerName.match(/\.(jpg|jpeg|png|gif|webp|bmp|heic|svg|tiff|tif)$/);
                if (!isVideo && !isImage) return null;

                // EXCLUDE vaulted dir from public scan to avoid duplication
                if (fileUri.includes('VaultedMedia')) return null;

                const type: MediaType = isVideo ? 'video' : 'image';
                return {
                  id: `local_${sanitizeId(fileUri, name)}`,
                  title: name,
                  type,
                  notes: '',
                  source_link: '',
                  thumbnail_url: type === 'image' ? fileUri : '',
                  local_path: fileUri,
                  is_vaulted: false,
                  tags: [folderName.toLowerCase()],
                  media_date: new Date().toISOString(),
                  duration_seconds: 0,
                  file_size_bytes: 0,
                  created_at: new Date().toISOString(),
                  updated_at: new Date().toISOString(),
                };
              });
              const scannedResults = await Promise.all(scannedPromises);
              allScannedFiles = [...allScannedFiles, ...scannedResults.filter((f): f is MediaEntry => f !== null)];
          } catch (e) {}
      }
      try {
          const vaultedFiles = await FileSystem.readDirectoryAsync(VAULT_DIR);
          const vaultedPromises = vaultedFiles.map(async filename => {
              const fileUri = VAULT_DIR + filename;
              const isVideo = filename.toLowerCase().match(/\.(mp4|mkv|mov|avi|3gp|webm)$/i);
              const isImage = filename.toLowerCase().match(/\.(jpg|jpeg|png|gif|webp|bmp|heic|svg|tiff|tif)$/i);
              if (!isVideo && !isImage) return null;
              const type = isVideo ? 'video' : 'image';
              return {
                  id: `vaulted_${sanitizeId(fileUri, filename)}`,
                  title: filename,
                  type,
                  notes: '',
                  source_link: '',
                  thumbnail_url: type === 'image' ? fileUri : '',
                  local_path: fileUri,
                  is_vaulted: true,
                  tags: ['vaulted'],
                  media_date: new Date().toISOString(),
                  duration_seconds: 0,
                  file_size_bytes: 0,
                  created_at: new Date().toISOString(),
                  updated_at: new Date().toISOString(),
              };
          });
          const vaultedEntries = await Promise.all(vaultedPromises);
          allScannedFiles = [...allScannedFiles, ...vaultedEntries.filter((f): f is MediaEntry => f !== null)];
      } catch (e) {}

      const uniqueFiles = allScannedFiles.filter((v, i, a) => a.findIndex(t => t.local_path === v.local_path) === i);
      setLocalFiles(uniqueFiles);
    } catch (e) {
    } finally {
      isScanning.current = false;
    }
  }, []);

  const addEntry = useCallback(async (entry: Omit<MediaEntry, 'id' | 'created_at' | 'updated_at'>) => {
    const tempId = `cloud_${Date.now()}`;
    const now = new Date().toISOString();
    const optimisticEntry: MediaEntry = { ...entry, id: tempId, created_at: now, updated_at: now };
    setEntries(prev => [optimisticEntry, ...prev]);
    try {
        await supabase.from('media_entries').insert([{ ...entry, id: undefined }]);
        await refreshEntries();
    } catch (e) {}
  }, [refreshEntries]);

  const updateEntry = useCallback(async (id: string, updates: Partial<MediaEntry>) => {
    const updater = (prev: MediaEntry[]) => prev.map(e => e.id === id ? { ...e, ...updates } : e);
    if (id.startsWith('local_') || id.startsWith('vaulted_')) {
        setLocalFiles(prev => updater(prev));
    } else {
        setEntries(prev => updater(prev));
        try {
            await supabase.from('media_entries').update(updates).eq('id', id);
            await refreshEntries();
        } catch (e) {}
    }
  }, [refreshEntries]);

  const deleteEntry = useCallback(async (id: string) => {
    const entry = [...localFiles, ...entries].find(e => e.id === id);
    if (!entry) return;

    if (id.startsWith('local_') || id.startsWith('vaulted_')) {
        try {
            if (entry.local_path.startsWith('content://')) {
                await StorageAccessFramework.deleteAsync(entry.local_path);
            } else {
                await FileSystem.deleteAsync(entry.local_path);
            }
        } catch(e) {}
        setLocalFiles(prev => prev.filter(e => e.id !== id));
    } else {
        setEntries(prev => prev.filter(e => e.id !== id));
        try {
            await supabase.from('media_entries').delete().eq('id', id);
            await refreshEntries();
        } catch (e) {}
    }
  }, [localFiles, entries, refreshEntries]);

  const toggleVault = useCallback(async (id: string) => {
    const all = [...entries, ...localFiles];
    const entry = all.find(e => e.id === id);
    if (!entry) return;
    const willBeVaulted = !entry.is_vaulted;

    if (entry.local_path) {
        try {
            if (willBeVaulted) {
                const filename = entry.local_path.split('/').pop() || `hidden_${Date.now()}`;
                const newPath = VAULT_DIR + filename;

                await FileSystem.copyAsync({ from: entry.local_path, to: newPath });
                const check = await FileSystem.getInfoAsync(newPath);
                if (!check.exists || check.size === 0) throw new Error("Verification failed");

                try {
                    if (entry.local_path.startsWith('content://')) {
                        await StorageAccessFramework.deleteAsync(entry.local_path);
                    } else {
                        await FileSystem.deleteAsync(entry.local_path);
                    }
                } catch (e) {}

                const newId = `vaulted_${sanitizeId(newPath, filename)}`;
                const updated = { ...entry, id: newId, is_vaulted: true, local_path: newPath, thumbnail_url: entry.type === 'image' ? newPath : '' };

                setLocalFiles(prev => prev.map(e => e.id === id ? updated : e));
                setEntries(prev => prev.map(e => e.id === id ? updated : e));
            } else {
                // Unvaulting logic remains strictly marking visible
                const updated = { ...entry, is_vaulted: false };
                setLocalFiles(prev => prev.map(e => e.id === id ? updated : e));
                setEntries(prev => prev.map(e => e.id === id ? updated : e));
            }
        } catch (e) {
            Alert.alert("Error", "Security move failed. File is safe.");
        }
    } else {
        const updated = { ...entry, is_vaulted: willBeVaulted };
        setEntries(prev => prev.map(e => e.id === id ? updated : e));
        try { await supabase.from('media_entries').update({ is_vaulted: willBeVaulted }).eq('id', id); } catch (e) {}
    }
  }, [entries, localFiles]);

  return (
    <MediaContext.Provider value={{
        entries, localFiles, isLoading, isVaultUnlocked, setVaultUnlocked: setIsVaultUnlocked,
        addEntry, updateEntry, deleteEntry, toggleVault, refreshEntries, scanLocalPaths
    }}>
      {children}
    </MediaContext.Provider>
  );
}

export function useMedia() { return useContext(MediaContext); }
