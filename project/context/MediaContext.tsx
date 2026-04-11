import React, { createContext, useContext, useState, useCallback, ReactNode, useEffect } from 'react';
import { MediaEntry } from '@/lib/types';
import { supabase } from '@/lib/supabase';
import AsyncStorage from '@react-native-async-storage/async-storage';

interface MediaContextValue {
  entries: MediaEntry[];
  isLoading: boolean;
  addEntry: (entry: Omit<MediaEntry, 'id' | 'created_at' | 'updated_at'>) => Promise<void>;
  updateEntry: (id: string, updates: Partial<MediaEntry>) => Promise<void>;
  deleteEntry: (id: string) => Promise<void>;
  toggleVault: (id: string) => Promise<void>;
  refreshEntries: () => Promise<void>;
}

const MediaContext = createContext<MediaContextValue>({
  entries: [],
  isLoading: false,
  addEntry: async () => {},
  updateEntry: async () => {},
  deleteEntry: async () => {},
  toggleVault: async () => {},
  refreshEntries: async () => {},
});

const STORAGE_KEY = '@lexi_central_notes';

export function MediaProvider({ children }: { children: ReactNode }) {
  const [entries, setEntries] = useState<MediaEntry[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Load from local cache first
  useEffect(() => {
    const loadCachedData = async () => {
      try {
        const cached = await AsyncStorage.getItem(STORAGE_KEY);
        if (cached) {
          setEntries(JSON.parse(cached));
        }
      } catch (e) {
        console.error('Failed to load cache', e);
      } finally {
        setIsLoading(false);
      }
    };
    loadCachedData();
  }, []);

  // Set up Supabase Realtime
  useEffect(() => {
    const channel = supabase
      .channel('schema-db-changes')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'media_entries' },
        (payload) => {
          refreshEntries();
        }
      )
      .subscribe();

    refreshEntries();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  const refreshEntries = useCallback(async () => {
    try {
      const { data, error } = await supabase
        .from('media_entries')
        .select('*')
        .order('created_at', { ascending: false });

      if (data) {
        setEntries(data);
        await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(data));
      }
    } catch (e) {
      console.error('Failed to fetch from Supabase', e);
    }
  }, []);

  const addEntry = useCallback(async (entry: Omit<MediaEntry, 'id' | 'created_at' | 'updated_at'>) => {
    const { data, error } = await supabase
      .from('media_entries')
      .insert([entry])
      .select();

    if (!error && data) {
      // Local state will be updated via Realtime listener
    }
  }, []);

  const updateEntry = useCallback(async (id: string, updates: Partial<MediaEntry>) => {
    const { error } = await supabase
      .from('media_entries')
      .update(updates)
      .eq('id', id);
  }, []);

  const deleteEntry = useCallback(async (id: string) => {
    const { error } = await supabase
      .from('media_entries')
      .delete()
      .eq('id', id);
  }, []);

  const toggleVault = useCallback(async (id: string) => {
    const entry = entries.find(e => e.id === id);
    if (entry) {
      await updateEntry(id, { is_vaulted: !entry.is_vaulted });
    }
  }, [entries, updateEntry]);

  return (
    <MediaContext.Provider value={{ entries, isLoading, addEntry, updateEntry, deleteEntry, toggleVault, refreshEntries }}>
      {children}
    </MediaContext.Provider>
  );
}

export function useMedia() {
  return useContext(MediaContext);
}
