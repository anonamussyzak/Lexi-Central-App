import React, { useState, useEffect, useMemo } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, Alert, Modal, TextInput } from 'react-native';
import { useSettings } from '@/context/SettingsContext';
import { THEMES } from '@/constants/themes';
import { ChevronLeft, ChevronRight, X, Pin, PinOff, Play, RotateCcw, Timer as TimerIcon, Pause, Settings as SettingsIcon, Edit2, Check } from 'lucide-react-native';
import { format, startOfMonth, endOfMonth, eachDayOfInterval, isSameMonth, isSameDay, addMonths, subMonths, differenceInSeconds, addSeconds } from 'date-fns';

export default function TimeScreen() {
  const { settings, updateSetting, saveSettings } = useSettings();
  const theme = THEMES[settings.theme || 'kirby'] || THEMES.kirby;

  const [activeView, setActiveView] = useState<'calendar' | 'tools'>('calendar');
  const [currentDate, setCurrentDate] = useState(new Date());
  const [selectedDates, setSelectedDates] = useState<Date[]>([]);
  const [now, setNow] = useState(new Date());

  // Stopwatch State (Non-persistent)
  const [stopwatchTime, setStopwatchTime] = useState(0);
  const [isStopwatchRunning, setIsStopwatchRunning] = useState(false);

  // Simple Timer State (Non-persistent)
  const [timerLeft, setTimerLeft] = useState(0);
  const [isTimerRunning, setIsTimerRunning] = useState(false);

  // Persistent Big Timer Logic (Uses target timestamp to prevent disk lag)
  const [bigTimerDisplay, setBigTimerLeft] = useState(0);
  const [isBigTimerRunning, setIsBigTimerRunning] = useState(false);
  const [isSetModalVisible, setIsSetModalVisible] = useState(false);
  const [customMinutes, setCustomMinutes] = useState('');
  const [editingName, setEditingName] = useState(false);
  const [tempTimerName, setTempTimerName] = useState(settings.bigTimerName || 'BIG PERSISTENT TIMER');

  const monthStart = startOfMonth(currentDate);
  const monthEnd = endOfMonth(monthStart);
  const days = eachDayOfInterval({ start: monthStart, end: monthEnd });

  // Master Clock
  useEffect(() => {
    const interval = setInterval(() => {
        const d = new Date();
        setNow(d);

        // Update Big Timer Display
        if (settings.bigTimerTarget) {
            const target = new Date(settings.bigTimerTarget);
            const diff = differenceInSeconds(target, d);
            if (diff <= 0) {
                if (isBigTimerRunning) {
                    setIsBigTimerRunning(false);
                    updateSetting('bigTimerTarget', null);
                }
                setBigTimerLeft(0);
            } else {
                setBigTimerLeft(diff);
                if (!isBigTimerRunning) setIsBigTimerRunning(true);
            }
        } else {
            setBigTimerLeft(0);
            setIsBigTimerRunning(false);
        }
    }, 1000);
    return () => clearInterval(interval);
  }, [settings.bigTimerTarget, isBigTimerRunning]);

  // Stopwatch Effect
  useEffect(() => {
      let interval: any;
      if (isStopwatchRunning) {
          interval = setInterval(() => setStopwatchTime(prev => prev + 1), 1000);
      }
      return () => clearInterval(interval);
  }, [isStopwatchRunning]);

  // Simple Timer Effect
  useEffect(() => {
      let interval: any;
      if (isTimerRunning && timerLeft > 0) {
          interval = setInterval(() => setTimerLeft(prev => prev - 1), 1000);
      } else if (timerLeft === 0 && isTimerRunning) {
          setIsTimerRunning(false);
          Alert.alert("Timer", "Simple timer finished!");
      }
      return () => clearInterval(interval);
  }, [isTimerRunning, timerLeft]);

  const formatTime = (totalSeconds: number) => {
      const h = Math.floor(totalSeconds / 3600);
      const m = Math.floor((totalSeconds % 3600) / 60);
      const s = totalSeconds % 60;
      return `${h > 0 ? h + ':' : ''}${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
  };

  const addTimeToBigTimer = (minutes: number) => {
      const currentTarget = settings.bigTimerTarget ? new Date(settings.bigTimerTarget) : new Date();
      const newTarget = addSeconds(currentTarget, minutes * 60);
      updateSetting('bigTimerTarget', newTarget.toISOString());
  };

  const handleSetBigTimer = () => {
      const mins = parseInt(customMinutes);
      if (!isNaN(mins) && mins >= 0) {
          const newTarget = addSeconds(new Date(), mins * 60);
          updateSetting('bigTimerTarget', newTarget.toISOString());
          setIsSetModalVisible(false);
          setCustomMinutes('');
      }
  };

  const toggleBigTimer = () => {
      if (isBigTimerRunning) {
          updateSetting('bigTimerTarget', null);
      } else if (bigTimerDisplay > 0) {
          const newTarget = addSeconds(new Date(), bigTimerDisplay);
          updateSetting('bigTimerTarget', newTarget.toISOString());
      } else {
          setIsSetModalVisible(true);
      }
  };

  const resetBigTimer = () => {
      updateSetting('bigTimerTarget', null);
      setBigTimerLeft(0);
  };

  const saveTimerName = () => {
      updateSetting('bigTimerName', tempTimerName);
      setEditingName(false);
  };

  const toggleDateSelection = (day: Date) => {
    setSelectedDates(prev => {
      if (prev.some(d => isSameDay(d, day))) {
        return prev.filter(d => !isSameDay(d, day));
      }
      if (prev.length >= 2) return [prev[1], day];
      return [...prev, day];
    });
  };

  const calculateInterval = () => {
    if (selectedDates.length === 0) return null;
    let start = selectedDates.length === 1 ? (now < selectedDates[0] ? now : selectedDates[0]) : (selectedDates[0] < selectedDates[1] ? selectedDates[0] : selectedDates[1]);
    let end = selectedDates.length === 1 ? (now < selectedDates[0] ? selectedDates[0] : now) : (selectedDates[0] < selectedDates[1] ? selectedDates[1] : selectedDates[0]);
    const totalSeconds = differenceInSeconds(end, start);
    return {
        d: Math.floor(totalSeconds / (3600 * 24)),
        h: Math.floor((totalSeconds % (3600 * 24)) / 3600),
        m: Math.floor((totalSeconds % 3600) / 60),
        s: totalSeconds % 60
    };
  };

  const interval = calculateInterval();

  return (
    <View style={[styles.container, { backgroundColor: theme.background }]}>
      <View style={styles.header}>
        <Text style={[styles.title, { color: theme.primary, fontFamily: 'Nunito-ExtraBold' }]}>Time</Text>
        <View style={styles.viewToggle}>
            <TouchableOpacity style={[styles.toggleBtn, activeView === 'calendar' && { backgroundColor: theme.primary }]} onPress={() => setActiveView('calendar')}>
                <Text style={[styles.toggleText, { color: activeView === 'calendar' ? 'white' : theme.textMuted }]}>Calendar</Text>
            </TouchableOpacity>
            <TouchableOpacity style={[styles.toggleBtn, activeView === 'tools' && { backgroundColor: theme.primary }]} onPress={() => setActiveView('tools')}>
                <Text style={[styles.toggleText, { color: activeView === 'tools' ? 'white' : theme.textMuted }]}>Tools</Text>
            </TouchableOpacity>
        </View>
      </View>

      {activeView === 'calendar' ? (
          <ScrollView style={{ flex: 1 }}>
              <View style={styles.calendarHeader}>
                <TouchableOpacity onPress={() => setCurrentDate(subMonths(currentDate, 1))}><ChevronLeft color={theme.primary} size={28} /></TouchableOpacity>
                <Text style={[styles.monthText, { color: theme.text, fontFamily: 'Nunito-Bold' }]}>{format(currentDate, 'MMMM yyyy')}</Text>
                <TouchableOpacity onPress={() => setCurrentDate(addMonths(currentDate, 1))}><ChevronRight color={theme.primary} size={28} /></TouchableOpacity>
              </View>
              <View style={styles.daysWrapper}>
                  {days.map(day => {
                      const isSelected = selectedDates.some(d => isSameDay(d, day));
                      const isToday = isSameDay(day, new Date());
                      return (
                        <TouchableOpacity key={day.toString()} style={styles.dayCell} onPress={() => toggleDateSelection(day)}>
                            <View style={[styles.dayCircle, isToday && { borderColor: theme.secondary, borderWidth: 2 }, isSelected && { backgroundColor: theme.primary }]}>
                                <Text style={{ color: isSelected ? 'white' : (isSameMonth(day, monthStart) ? theme.text : theme.textMuted) }}>{format(day, 'd')}</Text>
                            </View>
                        </TouchableOpacity>
                      );
                  })}
              </View>

              {interval && (
                  <View style={[styles.diffPanel, { backgroundColor: theme.surface, borderRadius: settings.roundedCorners }]}>
                      <View style={styles.diffHeader}>
                          <TimerIcon size={18} color={theme.primary} />
                          <Text style={[styles.diffTitle, { color: theme.text }]}>{selectedDates.length === 1 ? 'Countdown' : 'Interval'}</Text>
                          <TouchableOpacity onPress={() => setSelectedDates([])}><X size={18} color={theme.textMuted} /></TouchableOpacity>
                      </View>
                      <View style={styles.statsRow}>
                          {[{v: interval.d, l: 'Days'}, {v: interval.h, l: 'Hours'}, {v: interval.m, l: 'Mins'}, {v: interval.s, l: 'Secs'}].map(s => (
                              <View key={s.l} style={styles.stat}><Text style={[styles.statValue, { color: theme.primary }]}>{s.v}</Text><Text style={styles.statLabel}>{s.l}</Text></View>
                          ))}
                      </View>
                  </View>
              )}
          </ScrollView>
      ) : (
          <ScrollView style={styles.toolsScroll} contentContainerStyle={{ paddingBottom: 40 }}>
              <View style={[styles.toolCard, { backgroundColor: theme.surface, borderRadius: settings.roundedCorners }]}>
                  <View style={styles.toolHeaderRow}>
                    <TimerIcon size={16} color={theme.primary} />
                    {editingName ? (
                        <TextInput style={[styles.nameInput, { color: theme.primary, borderBottomColor: theme.primary }]} value={tempTimerName} onChangeText={setTempTimerName} autoFocus onBlur={saveTimerName} onSubmitEditing={saveTimerName} />
                    ) : (
                        <TouchableOpacity style={{ flex: 1, flexDirection: 'row', alignItems: 'center', gap: 6 }} onPress={() => setEditingName(true)}>
                            <Text style={[styles.toolLabel, { color: theme.primary }]}>{settings.bigTimerName || 'BIG PERSISTENT TIMER'}</Text>
                            <Edit2 size={12} color={theme.textMuted} />
                        </TouchableOpacity>
                    )}
                    <TouchableOpacity onPress={() => setIsSetModalVisible(true)}><SettingsIcon size={16} color={theme.textMuted} /></TouchableOpacity>
                  </View>
                  <Text style={[styles.bigClockText, { color: theme.text }]}>{formatTime(bigTimerDisplay)}</Text>
                  <View style={styles.btnRow}>
                      {[5, 10, 20].map(m => (
                          <TouchableOpacity key={m} style={[styles.quickBtn, { backgroundColor: theme.primary + '20' }]} onPress={() => addTimeToBigTimer(m)}><Text style={{ color: theme.primary }}>+{m}m</Text></TouchableOpacity>
                      ))}
                  </View>
                  <View style={styles.controlRow}>
                      <TouchableOpacity style={[styles.mainBtn, { backgroundColor: theme.primary }]} onPress={toggleBigTimer}>
                          {isBigTimerRunning ? <Pause color="white" fill="white" /> : <Play color="white" fill="white" />}
                      </TouchableOpacity>
                      <TouchableOpacity style={styles.resetBtn} onPress={resetBigTimer}><RotateCcw color={theme.textMuted} /></TouchableOpacity>
                  </View>
              </View>

              <View style={[styles.toolCard, { backgroundColor: theme.surface, borderRadius: settings.roundedCorners }]}>
                  <Text style={[styles.toolLabel, { color: theme.secondary }]}>STOPWATCH</Text>
                  <Text style={[styles.clockText, { color: theme.text }]}>{formatTime(stopwatchTime)}</Text>
                  <View style={styles.controlRow}>
                      <TouchableOpacity style={[styles.mainBtn, { backgroundColor: theme.secondary }]} onPress={() => setIsStopwatchRunning(!isStopwatchRunning)}>
                          {isStopwatchRunning ? <Pause color="white" fill="white" /> : <Play color="white" fill="white" />}
                      </TouchableOpacity>
                      <TouchableOpacity style={styles.resetBtn} onPress={() => setStopwatchTime(0)}><RotateCcw color={theme.textMuted} /></TouchableOpacity>
                  </View>
              </View>
          </ScrollView>
      )}

      <Modal visible={isSetModalVisible} transparent animationType="fade">
          <View style={styles.modalOverlay}>
              <View style={[styles.modalContent, { backgroundColor: theme.surface, borderRadius: settings.roundedCorners }]}>
                  <Text style={[styles.modalTitle, { color: theme.text }]}>Set Big Timer (Minutes)</Text>
                  <TextInput style={[styles.modalInput, { backgroundColor: theme.surfaceElevated, color: theme.text }]} placeholder="Minutes..." value={customMinutes} onChangeText={setCustomMinutes} keyboardType="numeric" autoFocus />
                  <View style={styles.modalButtons}>
                      <TouchableOpacity style={styles.modalBtn} onPress={() => setIsSetModalVisible(false)}><Text style={{ color: theme.textMuted }}>Cancel</Text></TouchableOpacity>
                      <TouchableOpacity style={[styles.modalBtn, { backgroundColor: theme.primary }]} onPress={handleSetBigTimer}><Text style={{ color: 'white', fontFamily: 'Nunito-Bold' }}>Set</Text></TouchableOpacity>
                  </View>
              </View>
          </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, paddingTop: 60 },
  header: { paddingHorizontal: 20, marginBottom: 20, flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  title: { fontSize: 32 },
  viewToggle: { flexDirection: 'row', backgroundColor: 'rgba(0,0,0,0.05)', borderRadius: 12, padding: 4 },
  toggleBtn: { paddingHorizontal: 12, paddingVertical: 6, borderRadius: 10 },
  toggleText: { fontSize: 12, fontFamily: 'Nunito-Bold' },
  calendarHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 30, marginBottom: 20 },
  monthText: { fontSize: 20 },
  daysWrapper: { flexDirection: 'row', flexWrap: 'wrap', paddingHorizontal: 10 },
  dayCell: { width: '14.28%', aspectRatio: 1, justifyContent: 'center', alignItems: 'center' },
  dayCircle: { width: 40, height: 40, borderRadius: 20, justifyContent: 'center', alignItems: 'center' },
  toolsScroll: { paddingHorizontal: 20 },
  toolCard: { padding: 20, marginBottom: 20, elevation: 2, alignItems: 'center' },
  toolHeaderRow: { flexDirection: 'row', alignItems: 'center', gap: 6, marginBottom: 10, width: '100%' },
  toolLabel: { fontSize: 12, fontFamily: 'Nunito-ExtraBold' },
  nameInput: { fontSize: 12, fontFamily: 'Nunito-ExtraBold', flex: 1, borderBottomWidth: 1, padding: 0 },
  bigClockText: { fontSize: 48, fontFamily: 'Nunito-ExtraBold', marginVertical: 10 },
  clockText: { fontSize: 36, fontFamily: 'Nunito-ExtraBold', marginVertical: 10 },
  btnRow: { flexDirection: 'row', gap: 10, marginBottom: 20 },
  quickBtn: { paddingHorizontal: 15, paddingVertical: 8, borderRadius: 10 },
  controlRow: { flexDirection: 'row', alignItems: 'center', gap: 20 },
  mainBtn: { width: 50, height: 50, borderRadius: 25, justifyContent: 'center', alignItems: 'center' },
  resetBtn: { padding: 10 },
  diffPanel: { margin: 20, padding: 20, elevation: 4 },
  diffHeader: { flexDirection: 'row', alignItems: 'center', marginBottom: 15, gap: 8 },
  diffTitle: { flex: 1, fontFamily: 'Nunito-ExtraBold', fontSize: 16 },
  statsRow: { flexDirection: 'row', justifyContent: 'space-between' },
  stat: { alignItems: 'center' },
  statValue: { fontSize: 22, fontFamily: 'Nunito-ExtraBold' },
  statLabel: { fontSize: 10, color: '#999', fontFamily: 'Nunito-Bold', marginTop: 2 },
  modalOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'center', padding: 30 },
  modalContent: { padding: 25 },
  modalTitle: { fontSize: 20, fontFamily: 'Nunito-ExtraBold', marginBottom: 20 },
  modalInput: { height: 50, borderRadius: 12, paddingHorizontal: 15, fontSize: 16, marginBottom: 20 },
  modalButtons: { flexDirection: 'row', gap: 10 },
  modalBtn: { flex: 1, height: 50, borderRadius: 12, justifyContent: 'center', alignItems: 'center' },
});
