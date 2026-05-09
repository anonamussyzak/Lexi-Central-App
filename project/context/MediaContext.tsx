import React, { createContext, useContext, useState, useCallback, ReactNode, useEffect, useRef } from 'react';
import { MediaEntry, MediaType } from '@/lib/types';
import { supabase } from '@/lib/supabase';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as FileSystem from 'expo-file-system';
import { Alert, AppState } from 'react-native';
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
  toggleVault: (id: string | string[]) => Promise<void>;
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

const STORAGE_KEY = '@lexi_central_notes_v10';
const LOCAL_FILES_KEY = '@lexi_central_local_files_v10';
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
        return name.replace(/ \(\d+\)$/, '').trim();
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

  const entriesRef = useRef(entries);
  const localFilesRef = useRef(localFiles);
  const isScanning = useRef(false);
  const lockTimer = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => { entriesRef.current = entries; }, [entries]);
  useEffect(() => { localFilesRef.current = localFiles; }, [localFiles]);

  const saveToDisk = async (local: MediaEntry[], cloud: MediaEntry[]) => {
      try {
          await AsyncStorage.setItem(LOCAL_FILES_KEY, JSON.stringify(local));
          await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(cloud));
      } catch (e) {}
  };

  // Auto-lock logic
  const resetLockTimer = useCallback(() => {
    if (lockTimer.current) clearTimeout(lockTimer.current);
    if (settings.autoLockMinutes > 0 && isVaultUnlocked) {
      lockTimer.current = setTimeout(() => {
        setIsVaultUnlocked(false);
      }, settings.autoLockMinutes * 60 * 1000);
    }
  }, [settings.autoLockMinutes, isVaultUnlocked]);

  useEffect(() => {
    resetLockTimer();
    const subscription = AppState.addEventListener('change', nextAppState => {
      if (nextAppState === 'background' || nextAppState === 'inactive') {
        setIsVaultUnlocked(false);
      }
    });
    return () => {
      if (lockTimer.current) clearTimeout(lockTimer.current);
      subscription.remove();
    };
  }, [resetLockTimer]);

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
        console.error('Failed to load cache', e);
      } finally {
        setIsLoading(false);
      }
    };
    init();
  }, []);

  useEffect(() => {
      if (settingsLoaded && settings.mediaPaths && settings.mediaPaths.length > 0) {
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
        saveToDisk(localFilesRef.current, data);
      }
    } catch (e) {}
  }, []);

  const scanDirectoryRecursive = async (dirUri: string, isSAF: boolean, depth: number = 0): Promise<{uri: string, folder: string}[]> => {
    if (depth > 3) return [];
    let results: {uri: string, folder: string}[] = [];
    try {
      let content: string[] = [];
      if (isSAF) {
        content = await StorageAccessFramework.readDirectoryAsync(dirUri);
      } else {
        const dirContent = await FileSystem.readDirectoryAsync(dirUri);
        content = dirContent.map(f => dirUri + (dirUri.endsWith('/') ? '' : '/') + f);
      }

      const currentFolderName = getCleanFolderName(dirUri);

      for (const entry of content) {
        if (entry.includes('VaultedMedia')) continue;
        const isMedia = entry.toLowerCase().match(/\.(mp4|mkv|mov|avi|3gp|webm|flv|ts|m4v|wmv|mpg|mpeg|jpg|jpeg|png|gif|webp|bmp|heic|svg|tiff|tif)$/i);
        if (isMedia) {
          results.push({ uri: entry, folder: currentFolderName });
        } else {
          const segments = entry.split('/');
          const last = segments[segments.length - 1];
          if (!last.includes('.') || depth === 0) {
            try {
              const subResults = await scanDirectoryRecursive(entry, isSAF, depth + 1);
              results = results.concat(subResults);
            } catch {}
          }
        }
      }
    } catch (e) {}
    return results;
  };

  const scanLocalPaths = useCallback(async (pathUris: string[]) => {
    if (!pathUris || pathUris.length === 0 || isScanning.current) return;
    isScanning.current = true;

    try {
      let allFound: {uri: string, folder: string}[] = [];
      for (const pathUri of pathUris) {
          if (!pathUri) continue;
          const isSAF = pathUri.startsWith('content://');
          const found = await scanDirectoryRecursive(pathUri, isSAF);
          allFound = allFound.concat(found);
      }

      const mappedLocal: MediaEntry[] = allFound.map(item => {
          const name = decodeURIComponent(item.uri).split('/').pop() || 'Unknown';
          const isVideo = item.uri.toLowerCase().match(/\.(mp4|mkv|mov|avi|3gp|webm)$/i);
          return {
            id: `local_${sanitizeId(item.uri, name)}`,
            title: name,
            type: isVideo ? 'video' : 'image',
            notes: '',
            source_link: '',
            thumbnail_url: isVideo ? '' : item.uri,
            local_path: item.uri,
            is_vaulted: false,
            tags: [item.folder.toLowerCase(), 'general'],
            media_date: new Date().toISOString(),
            duration_seconds: 0,
            file_size_bytes: 0,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
          };
      });

      const vaultedItems: MediaEntry[] = [];
      try {
          const vaultedFiles = await FileSystem.readDirectoryAsync(VAULT_DIR);
          for (const filename of vaultedFiles) {
              const fileUri = VAULT_DIR + filename;
              const isVideo = filename.toLowerCase().match(/\.(mp4|mkv|mov|avi|3gp|webm)$/i);
              vaultedItems.push({
                  id: `vaulted_${sanitizeId(fileUri, filename)}`,
                  title: filename,
                  type: isVideo ? 'video' : 'image',
                  notes: '',
                  source_link: '',
                  thumbnail_url: isVideo ? '' : fileUri,
                  local_path: fileUri,
                  is_vaulted: true,
                  tags: ['vaulted'],
                  media_date: new Date().toISOString(),
                  duration_seconds: 0,
                  file_size_bytes: 0,
                  created_at: new Date().toISOString(),
                  updated_at: new Date().toISOString(),
              });
          }
      } catch (e) {}

      const unique = [...mappedLocal, ...vaultedItems].filter((v, i, a) => a.findIndex(t => t.local_path === v.local_path) === i);
      setLocalFiles(unique);
      saveToDisk(unique, entriesRef.current);
    } catch (e) {
        console.error("Scan error", e);
    } finally {
      isScanning.current = false;
    }
  }, []);

  const addEntry = useCallback(async (entry: Omit<MediaEntry, 'id' | 'created_at' | 'updated_at'>) => {
    const tempId = `cloud_${Date.now()}`;
    const now = new Date().toISOString();
    const optimisticEntry: MediaEntry = { ...entry, id: tempId, created_at: now, updated_at: now };
    setEntries(prev => {
        const newList = [optimisticEntry, ...prev];
        saveToDisk(localFilesRef.current, newList);
        return newList;
    });
    try {
        await supabase.from('media_entries').insert([{ ...entry, id: undefined }]);
        await refreshEntries();
    } catch (e) {}
  }, [refreshEntries]);

  const updateEntry = useCallback(async (id: string, updates: Partial<MediaEntry>) => {
    if (id.startsWith('local_') || id.startsWith('vaulted_')) {
        setLocalFiles(prev => {
            const newList = prev.map(e => e.id === id ? { ...e, ...updates } : e);
            saveToDisk(newList, entriesRef.current);
            return newList;
        });
    } else {
        setEntries(prev => {
            const newList = prev.map(e => e.id === id ? { ...e, ...updates } : e);
            saveToDisk(localFilesRef.current, newList);
            return newList;
        });
        try {
            await supabase.from('media_entries').update(updates).eq('id', id);
            await refreshEntries();
        } catch (e) {}
    }
  }, [refreshEntries]);

  const deleteEntry = useCallback(async (id: string) => {
    const entry = [...localFilesRef.current, ...entriesRef.current].find(e => e.id === id);
    if (!entry) return;
    if (id.startsWith('local_') || id.startsWith('vaulted_')) {
        try {
            if (entry.local_path.startsWith('content://')) await StorageAccessFramework.deleteAsync(entry.local_path);
            else await FileSystem.deleteAsync(entry.local_path);
        } catch(e) {}
        setLocalFiles(prev => {
            const newList = prev.filter(e => e.id !== id);
            saveToDisk(newList, entriesRef.current);
            return newList;
        });
    } else {
        setEntries(prev => {
            const newList = prev.filter(e => e.id !== id);
            saveToDisk(localFilesRef.current, newList);
            return newList;
        });
        try {
            await supabase.from('media_entries').delete().eq('id', id);
            await refreshEntries();
        } catch (e) {}
    }
  }, [refreshEntries]);

  const toggleVault = useCallback(async (ids: string | string[]) => {
    const targetIds = Array.isArray(ids) ? ids : [ids];
    if (targetIds.length === 0) return;

    let updatedEntries = [...entriesRef.current];
    let updatedLocalFiles = [...localFilesRef.current];
    let hasChanges = false;

    for (const id of targetIds) {
        const entry = [...updatedEntries, ...updatedLocalFiles].find(e => e.id === id);
        if (!entry) continue;
        const isLocal = id.startsWith('local_') || id.startsWith('vaulted_');
        const willBeVaulted = !entry.is_vaulted;

        if (entry.local_path) {
            try {
                if (willBeVaulted) {
                    const filename = entry.local_path.split('/').pop() || `hidden_${Date.now()}`;
                    const newPath = VAULT_DIR + filename;
                    await FileSystem.copyAsync({ from: entry.local_path, to: newPath });

                    const check = await FileSystem.getInfoAsync(newPath);
                    if (!check.exists || check.size === 0) throw new Error("Move failed");

                    if (entry.local_path.startsWith('content://')) await StorageAccessFramework.deleteAsync(entry.local_path);
                    else await FileSystem.deleteAsync(entry.local_path);

                    const newId = isLocal ? `vaulted_${sanitizeId(newPath, filename)}` : id;
                    const updated = {
                        ...entry,
                        id: newId,
                        is_vaulted: true,
                        local_path: newPath,
                        thumbnail_url: (entry.type === 'image' || entry.type === 'note') ? newPath : entry.thumbnail_url
                    };

                    if (isLocal) {
                        updatedLocalFiles = updatedLocalFiles.map(e => e.id === id ? updated : e);
                    } else {
                        updatedEntries = updatedEntries.map(e => e.id === id ? updated : e);
                        await supabase.from('media_entries').update({
                            is_vaulted: true,
                            local_path: newPath,
                            thumbnail_url: updated.thumbnail_url
                        }).eq('id', id);
                    }
                    hasChanges = true;
                } else {
                    // UNVAULTING
                    const targetDir = settings.mediaPaths[0] || `${FileSystem.documentDirectory}Kirby/`;

                    if (!targetDir.startsWith('content://')) {
                        const dirInfo = await FileSystem.getInfoAsync(targetDir);
                        if (!dirInfo.exists) await FileSystem.makeDirectoryAsync(targetDir, { intermediates: true });
                    }

                    let newUri = '';
                    if (targetDir.startsWith('content://')) {
                        newUri = await StorageAccessFramework.createFileAsync(targetDir, entry.title, entry.type === 'video' ? 'video/mp4' : 'image/jpeg');
                        await FileSystem.copyAsync({ from: entry.local_path, to: newUri });
                    } else {
                        newUri = targetDir + (targetDir.endsWith('/') ? '' : '/') + entry.title;
                        await FileSystem.copyAsync({ from: entry.local_path, to: newUri });
                    }

                    await FileSystem.deleteAsync(entry.local_path);
                    const newId = isLocal ? `local_${sanitizeId(newUri, entry.title)}` : id;
                    const updated = {
                        ...entry,
                        id: newId,
                        is_vaulted: false,
                        local_path: newUri,
                        thumbnail_url: (entry.type === 'image' || entry.type === 'note') ? newUri : entry.thumbnail_url
                    };

                    if (isLocal) {
                        updatedLocalFiles = updatedLocalFiles.map(e => e.id === id ? updated : e);
                    } else {
                        updatedEntries = updatedEntries.map(e => e.id === id ? updated : e);
                        await supabase.from('media_entries').update({
                            is_vaulted: false,
                            local_path: newUri,
                            thumbnail_url: updated.thumbnail_url
                        }).eq('id', id);
                    }
                    hasChanges = true;
                }
            } catch (e) {
                console.error("Vault op failed", e);
                Alert.alert("Error", "Security operation failed for " + entry.title);
            }
        } else {
            // PURELY CLOUD ENTRY WITHOUT LOCAL FILE
            const updated = { ...entry, is_vaulted: willBeVaulted };
            updatedEntries = updatedEntries.map(e => e.id === id ? updated : e);
            hasChanges = true;
            try { await supabase.from('media_entries').update({ is_vaulted: willBeVaulted }).eq('id', id); } catch (e) {}
        }
    }

    if (hasChanges) {
        setEntries(updatedEntries);
        setLocalFiles(updatedLocalFiles);
        saveToDisk(updatedLocalFiles, updatedEntries);
    }
  }, [settings.mediaPaths]);

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
