import React, { createContext, useContext, useState, useCallback, ReactNode, useEffect, useMemo } from 'react';
import { AppSettings } from '@/lib/types';
import { DEFAULT_SETTINGS } from '@/constants/themes';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as FileSystem from 'expo-file-system';
import { Alert } from 'react-native';

interface SettingsContextValue {
  settings: AppSettings;
  updateSetting: <K extends keyof AppSettings>(key: K, value: AppSettings[K]) => void;
  saveSettings: (silent?: boolean) => Promise<void>;
  initializeStorage: () => Promise<void>;
  isLoaded: boolean;
}

const SettingsContext = createContext<SettingsContextValue>({
  settings: DEFAULT_SETTINGS,
  updateSetting: () => {},
  saveSettings: async () => {},
  initializeStorage: async () => {},
  isLoaded: false,
});

const STORAGE_KEY = '@lexi_central_settings_v2'; // Bumped version for clean state

export function SettingsProvider({ children }: { children: ReactNode }) {
  const [settings, setSettings] = useState<AppSettings>(DEFAULT_SETTINGS);
  const [isLoaded, setIsLoaded] = useState(false);

  useEffect(() => {
    const loadSettings = async () => {
      try {
        const saved = await AsyncStorage.getItem(STORAGE_KEY);
        if (saved) {
          const parsed = JSON.parse(saved);

          // Data validation and migration
          const validated = { ...DEFAULT_SETTINGS, ...parsed };
          if (!Array.isArray(validated.mediaPaths)) validated.mediaPaths = DEFAULT_SETTINGS.mediaPaths;
          if (!Array.isArray(validated.noteTabs)) validated.noteTabs = DEFAULT_SETTINGS.noteTabs;
          if (!Array.isArray(validated.galleryTabs)) validated.galleryTabs = DEFAULT_SETTINGS.galleryTabs;

          setSettings(validated);
        }
      } catch (e) {
        console.error('Failed to load settings', e);
      } finally {
        setIsLoaded(true);
      }
    };
    loadSettings();
  }, []);

  useEffect(() => {
      if (isLoaded) {
          initializeStorage();
      }
  }, [isLoaded]);

  const initializeStorage = async () => {
      try {
          const kirbyFolder = `${FileSystem.documentDirectory}Kirby/`;
          const dirInfo = await FileSystem.getInfoAsync(kirbyFolder);
          if (!dirInfo.exists) {
              await FileSystem.makeDirectoryAsync(kirbyFolder, { intermediates: true });
          }

          setSettings(prev => {
              if (!prev.mediaPaths || prev.mediaPaths.length === 0) {
                  return { ...prev, mediaPaths: [kirbyFolder] };
              }
              return prev;
          });
      } catch (e) {
          console.error('Failed to init storage', e);
      }
  };

  const updateSetting = useCallback(<K extends keyof AppSettings,>(key: K, value: AppSettings[K]) => {
    setSettings(prev => ({ ...prev, [key]: value }));
  }, []);

  // Auto-persist changes
  useEffect(() => {
      if (isLoaded) {
          AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(settings)).catch((e) => {
              console.error('Failed to save settings', e);
              Alert.alert('Error', 'Failed to save settings automatically.');
          });
      }
  }, [settings, isLoaded]);

  const value = useMemo(() => ({
    settings,
    updateSetting,
    saveSettings: async (silent: boolean = false) => {
        try {
            await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(settings));
            if (!silent) Alert.alert('Success', 'Settings Saved!');
        } catch (e) {
            console.error('Failed to save settings', e);
            Alert.alert('Error', 'Failed to save settings.');
        }
    },
    initializeStorage,
    isLoaded
  }), [settings, updateSetting, isLoaded]);

  return (
    <SettingsContext.Provider value={value}>
      {children}
    </SettingsContext.Provider>
  );
}

export function useSettings() {
  return useContext(SettingsContext);
}
