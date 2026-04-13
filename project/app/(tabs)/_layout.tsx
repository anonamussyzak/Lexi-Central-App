import { Tabs } from 'expo-router';
import { View, StyleSheet, Platform } from 'react-native';
import { Grid2x2, Clock, Lock, Settings, ShieldCheck, Globe, FileText } from 'lucide-react-native';
import { useSettings } from '@/context/SettingsContext';
import { THEMES } from '@/constants/themes';
import NetInfo from '@react-native-community/netinfo';
import { useState, useEffect } from 'react';

function TabIcon({ icon: Icon, focused, color }: { icon: any; focused: boolean; color: string }) {
  return (
    <View style={[styles.tabIcon, focused && styles.tabIconActive]}>
      <Icon size={22} color={color} strokeWidth={focused ? 2.5 : 2} />
    </View>
  );
}

export default function TabLayout() {
  const { settings } = useSettings();
  const theme = THEMES[settings.theme];
  const [isConnected, setIsConnected] = useState(true);

  useEffect(() => {
    const unsubscribe = NetInfo.addEventListener(state => {
      setIsConnected(!!state.isConnected);
    });

    NetInfo.fetch().then(state => {
        setIsConnected(!!state.isConnected);
    });

    return () => unsubscribe();
  }, []);

  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarStyle: {
          backgroundColor: theme.tabBar,
          borderTopColor: theme.border,
          borderTopWidth: 1,
          height: Platform.OS === 'ios' ? 88 : 70,
          paddingBottom: Platform.OS === 'ios' ? 28 : 12,
          paddingTop: 10,
          elevation: 0,
          shadowOpacity: 0,
        },
        tabBarActiveTintColor: theme.tabBarActive,
        tabBarInactiveTintColor: theme.tabBarInactive,
        tabBarLabelStyle: {
          fontFamily: 'Nunito-Bold',
          fontSize: 10,
          marginTop: 2,
        },
      }}
    >
      <Tabs.Screen
        name="notes"
        options={{
          title: 'Notes',
          tabBarIcon: ({ focused, color }) => (
            <TabIcon icon={FileText} focused={focused} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="index"
        options={{
          title: 'Gallery',
          tabBarIcon: ({ focused, color }) => (
            <TabIcon icon={Grid2x2} focused={focused} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="hub"
        options={{
          title: 'Hub',
          href: isConnected ? '/hub' : null,
          tabBarIcon: ({ focused, color }) => (
            <TabIcon icon={Globe} focused={focused} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="calendar"
        options={{
          title: 'Time',
          tabBarIcon: ({ focused, color }) => (
            <TabIcon icon={Clock} focused={focused} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="vault"
        options={{
          title: 'Vault',
          tabBarIcon: ({ focused, color }) => (
            <TabIcon icon={ShieldCheck} focused={focused} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="settings"
        options={{
          title: 'Settings',
          tabBarIcon: ({ focused, color }) => (
            <TabIcon icon={Settings} focused={focused} color={color} />
          ),
        }}
      />
      <Tabs.Screen name="voice" options={{ href: null }} />
    </Tabs>
  );
}

const styles = StyleSheet.create({
  tabIcon: {
    width: 36,
    height: 36,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  tabIconActive: {
    backgroundColor: 'rgba(255, 143, 171, 0.15)',
  },
});
