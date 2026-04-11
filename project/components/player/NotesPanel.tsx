import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  TextInput,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
} from 'react-native';
import { CreditCard as Edit3, Eye, Save, Check } from 'lucide-react-native';
import { useSettings } from '@/context/SettingsContext';
import { THEMES } from '@/constants/themes';

interface NotesPanelProps {
  notes: string;
  onSave: (notes: string) => void;
}

function MarkdownPreview({ text, theme }: { text: string; theme: any }) {
  const lines = text.split('\n');

  return (
    <ScrollView style={{ flex: 1 }} showsVerticalScrollIndicator={false}>
      {lines.map((line, i) => {
        if (line.startsWith('## ')) {
          return (
            <Text key={i} style={[styles.mdH2, { color: theme.text }]}>
              {line.slice(3)}
            </Text>
          );
        }
        if (line.startsWith('# ')) {
          return (
            <Text key={i} style={[styles.mdH1, { color: theme.text }]}>
              {line.slice(2)}
            </Text>
          );
        }
        if (line.startsWith('### ')) {
          return (
            <Text key={i} style={[styles.mdH3, { color: theme.text }]}>
              {line.slice(4)}
            </Text>
          );
        }
        if (line.startsWith('> ')) {
          return (
            <View key={i} style={[styles.mdBlockquote, { borderLeftColor: theme.primary, backgroundColor: theme.surfaceElevated }]}>
              <Text style={[styles.mdBlockquoteText, { color: theme.textSecondary }]}>
                {line.slice(2)}
              </Text>
            </View>
          );
        }
        if (line.startsWith('- ')) {
          return (
            <View key={i} style={styles.mdListItem}>
              <Text style={[styles.mdBullet, { color: theme.primary }]}>●</Text>
              <Text style={[styles.mdBody, { color: theme.text }]}>{line.slice(2)}</Text>
            </View>
          );
        }
        if (line.startsWith('**') && line.endsWith('**')) {
          return (
            <Text key={i} style={[styles.mdBold, { color: theme.text }]}>
              {line.slice(2, -2)}
            </Text>
          );
        }
        if (line === '') {
          return <View key={i} style={{ height: 8 }} />;
        }
        return (
          <Text key={i} style={[styles.mdBody, { color: theme.text }]}>
            {line}
          </Text>
        );
      })}
      <View style={{ height: 40 }} />
    </ScrollView>
  );
}

export default function NotesPanel({ notes, onSave }: NotesPanelProps) {
  const { settings } = useSettings();
  const theme = THEMES[settings.theme];
  const [mode, setMode] = useState<'edit' | 'preview'>(settings.defaultEditorMode);
  const [draft, setDraft] = useState(notes);
  const [saved, setSaved] = useState(false);
  const radius = settings.roundedCorners;

  const handleSave = useCallback(() => {
    onSave(draft);
    setSaved(true);
    setTimeout(() => setSaved(false), 2000);
  }, [draft, onSave]);

  return (
    <View style={styles.container}>
      <View style={styles.toolbar}>
        <Text style={[styles.label, { color: theme.text }]}>Notes</Text>
        <View style={styles.toolbarRight}>
          <View style={[styles.modeToggle, { backgroundColor: theme.surfaceElevated }]}>
            <TouchableOpacity
              style={[styles.modeBtn, mode === 'edit' && { backgroundColor: theme.primary, borderRadius: radius - 4 }]}
              onPress={() => setMode('edit')}
            >
              <Edit3 size={13} color={mode === 'edit' ? theme.text : theme.textMuted} />
              <Text style={[styles.modeText, { color: mode === 'edit' ? theme.text : theme.textMuted }]}>Edit</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.modeBtn, mode === 'preview' && { backgroundColor: theme.primary, borderRadius: radius - 4 }]}
              onPress={() => setMode('preview')}
            >
              <Eye size={13} color={mode === 'preview' ? theme.text : theme.textMuted} />
              <Text style={[styles.modeText, { color: mode === 'preview' ? theme.text : theme.textMuted }]}>Preview</Text>
            </TouchableOpacity>
          </View>
          <TouchableOpacity
            style={[styles.saveBtn, { backgroundColor: saved ? theme.success : theme.primary }]}
            onPress={handleSave}
          >
            {saved ? (
              <Check size={14} color={theme.text} />
            ) : (
              <Save size={14} color={theme.text} />
            )}
          </TouchableOpacity>
        </View>
      </View>

      <View style={[styles.editor, { backgroundColor: theme.surface, borderColor: theme.border }]}>
        {mode === 'edit' ? (
          <TextInput
            style={[styles.textInput, { color: theme.text, fontSize: settings.notesFontSize }]}
            value={draft}
            onChangeText={setDraft}
            multiline
            placeholder="Add notes, thoughts, memories..."
            placeholderTextColor={theme.textMuted}
            textAlignVertical="top"
          />
        ) : (
          <View style={styles.preview}>
            {draft.length === 0 ? (
              <Text style={[styles.placeholder, { color: theme.textMuted }]}>No notes yet. Switch to Edit mode to add some.</Text>
            ) : (
              <MarkdownPreview text={draft} theme={theme} />
            )}
          </View>
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    gap: 10,
  },
  toolbar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  label: {
    fontFamily: 'Nunito-Bold',
    fontSize: 16,
  },
  toolbarRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  modeToggle: {
    flexDirection: 'row',
    borderRadius: 12,
    padding: 3,
    gap: 2,
  },
  modeBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 10,
    paddingVertical: 5,
  },
  modeText: {
    fontFamily: 'Nunito-Bold',
    fontSize: 11,
  },
  saveBtn: {
    width: 32,
    height: 32,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  editor: {
    flex: 1,
    borderRadius: 16,
    borderWidth: 1,
    overflow: 'hidden',
  },
  textInput: {
    flex: 1,
    fontFamily: 'Nunito-Regular',
    lineHeight: 22,
    padding: 14,
  },
  preview: {
    flex: 1,
    padding: 14,
  },
  placeholder: {
    fontFamily: 'Nunito-Regular',
    fontSize: 14,
    fontStyle: 'italic',
  },
  mdH1: {
    fontFamily: 'Nunito-ExtraBold',
    fontSize: 22,
    marginBottom: 6,
    lineHeight: 28,
  },
  mdH2: {
    fontFamily: 'Nunito-Bold',
    fontSize: 18,
    marginBottom: 4,
    lineHeight: 24,
  },
  mdH3: {
    fontFamily: 'Nunito-Bold',
    fontSize: 15,
    marginBottom: 4,
  },
  mdBody: {
    fontFamily: 'Nunito-Regular',
    fontSize: 14,
    lineHeight: 21,
  },
  mdBold: {
    fontFamily: 'Nunito-Bold',
    fontSize: 14,
    lineHeight: 21,
  },
  mdBlockquote: {
    borderLeftWidth: 3,
    paddingLeft: 12,
    paddingVertical: 6,
    borderRadius: 4,
    marginVertical: 4,
  },
  mdBlockquoteText: {
    fontFamily: 'Nunito-SemiBold',
    fontSize: 13,
    fontStyle: 'italic',
    lineHeight: 20,
  },
  mdListItem: {
    flexDirection: 'row',
    gap: 8,
    alignItems: 'flex-start',
    marginBottom: 3,
  },
  mdBullet: {
    fontSize: 8,
    marginTop: 6,
  },
});
