import { storage } from 'common/storage';
import { useEffect, useRef, useState } from 'react';

import { useBackend } from '../backend';
import {
  Box,
  Button,
  Dropdown,
  Flex,
  Input,
  LabeledList,
  NumberInput,
  Section,
  Stack,
  TextArea,
} from '../components';
import { Window } from '../layouts';

type LibraryPreset = {
  preset_id: string;
  name: string;
  description: string;
  tier_count: number;
  variant_count: number;
};
type DraftVariant = {
  variant_id: string;
  title: string;
  description: string;
  duration_seconds: number;
  source_url: string;
};
type DraftTier = {
  tier_id: string;
  name: string;
  description: string;
  variants: DraftVariant[];
};
type DraftPreset = {
  preset_id: string;
  name: string;
  description: string;
  playback: {
    audience_mode: string;
    sound_type: string;
    show_title_to_players: boolean;
    repeat: boolean;
  };
  tiers: DraftTier[];
};
type CurrentSession = null | {
  source_kind: string;
  owner: string;
  audience_label: string;
  sound_type_label: string;
  show_title_to_players: boolean;
  resolved_title: string;
  source_url: string;
  preset_id?: string;
  preset_name?: string;
  tier_name?: string;
  variant_title?: string;
  loop?: boolean;
};
type OptionEntry = { id: string; label: string };
type PreviewCommand = null | {
  nonce: number | string;
  command: 'play' | 'stop';
  title?: string;
  url?: string;
  start?: number;
  end?: number;
};
type AdminMusicPanelData = {
  library: LibraryPreset[];
  draft: DraftPreset;
  dirty: boolean;
  selected_tier_id: string | null;
  selected_variant_id: string | null;
  can_delete_saved_preset: boolean;
  current_session: CurrentSession;
  audience_options: OptionEntry[];
  sound_type_options: OptionEntry[];
  preview_command: PreviewCommand;
};

const DEFAULT_PREVIEW_VOLUME = 0.2;
const DESCRIPTION_FIELD_HEIGHT = 4.5;
const PLAYER_CARD_STYLE = {
  backgroundColor: 'rgba(255, 255, 255, 0.04)',
  border: '1px solid rgba(255, 255, 255, 0.08)',
  borderRadius: '0.35rem',
  padding: '0.75rem',
};
const PLAYER_STRIP_STYLE = {
  background:
    'linear-gradient(90deg, rgba(70, 140, 60, 0.22) 0%, rgba(25, 40, 25, 0.24) 100%)',
  border: '1px solid rgba(120, 190, 100, 0.3)',
  borderRadius: '0.35rem',
  padding: '0.85rem',
};
const PLAYER_BADGE_STYLE = {
  display: 'inline-block',
  padding: '0.15rem 0.45rem',
  marginRight: '0.35rem',
  marginBottom: '0.35rem',
  borderRadius: '999px',
  border: '1px solid rgba(255, 255, 255, 0.12)',
  backgroundColor: 'rgba(0, 0, 0, 0.18)',
};

const formatDuration = (duration_seconds: number) => {
  if (!Number.isFinite(duration_seconds) || duration_seconds <= 0) {
    return 'Unknown';
  }
  const seconds = Math.floor(duration_seconds);
  const minutes = Math.floor(seconds / 60);
  const remainder = seconds % 60;
  return minutes
    ? `${minutes}m ${String(remainder).padStart(2, '0')}s`
    : `${remainder}s`;
};
const formatSourceLabel = (source_url: string) => {
  if (!source_url) {
    return 'No source URL';
  }
  try {
    return new URL(source_url).hostname.replace(/^www\./, '');
  } catch {
    return source_url;
  }
};

const findTier = (draft: DraftPreset, tierId: string | null) =>
  draft.tiers.find((tier) => tier.tier_id === tierId) || draft.tiers[0] || null;
const findVariant = (tier: DraftTier | null, variantId: string | null) =>
  tier?.variants.find((variant) => variant.variant_id === variantId) ||
  tier?.variants[0] ||
  null;

export const AdminMusicPanel = () => {
  const { act, data } = useBackend<AdminMusicPanelData>();
  const {
    library,
    draft,
    dirty,
    selected_tier_id,
    selected_variant_id,
    can_delete_saved_preset,
    current_session,
    audience_options,
    sound_type_options,
    preview_command,
  } = data;

  const [librarySearch, setLibrarySearch] = useState('');
  const [selectedLibraryPresetId, setSelectedLibraryPresetId] = useState<
    string | null
  >(draft?.preset_id || library[0]?.preset_id || null);
  const [previewVolume, setPreviewVolume] = useState(DEFAULT_PREVIEW_VOLUME);
  const [previewState, setPreviewState] = useState('Idle');

  const previewAudioRef = useRef<HTMLAudioElement | null>(null);
  const previewVolumeRef = useRef(DEFAULT_PREVIEW_VOLUME);
  const previewKeyRef = useRef<string>('');

  useEffect(() => {
    const syncVolume = async () => {
      const settings = await storage.get('panel-settings');
      const nextVolume =
        typeof settings?.adminMusicVolume === 'number'
          ? settings.adminMusicVolume
          : DEFAULT_PREVIEW_VOLUME;
      previewVolumeRef.current = nextVolume;
      setPreviewVolume(nextVolume);
    };
    let cancelled = false;
    const listener = () => {
      if (!cancelled) {
        void syncVolume();
      }
    };
    void syncVolume();
    document.addEventListener('byondstorageupdated', listener);
    return () => {
      cancelled = true;
      document.removeEventListener('byondstorageupdated', listener);
    };
  }, []);

  useEffect(() => {
    if (previewAudioRef.current) {
      previewAudioRef.current.volume = previewVolume;
    }
  }, [previewVolume]);

  useEffect(() => {
    if (draft?.preset_id) {
      setSelectedLibraryPresetId(draft.preset_id);
      return;
    }
    if (
      selectedLibraryPresetId &&
      !library.some((preset) => preset.preset_id === selectedLibraryPresetId)
    ) {
      setSelectedLibraryPresetId(library[0]?.preset_id || null);
    }
  }, [draft?.preset_id, library, selectedLibraryPresetId]);

  useEffect(
    () => () => {
      const audio = previewAudioRef.current;
      if (audio) {
        audio.pause();
        audio.src = '';
        previewAudioRef.current = null;
      }
    },
    [],
  );

  useEffect(() => {
    if (!preview_command) {
      return;
    }
    const key = `${preview_command.nonce}:${preview_command.command}`;
    if (previewKeyRef.current === key) {
      return;
    }
    previewKeyRef.current = key;

    const stopPreviewAudio = (status = 'Preview stopped') => {
      const audio = previewAudioRef.current;
      if (audio) {
        audio.pause();
        audio.src = '';
        previewAudioRef.current = null;
      }
      setPreviewState(status);
    };

    if (preview_command.command === 'stop') {
      stopPreviewAudio();
      return;
    }
    if (!preview_command.url) {
      stopPreviewAudio('Preview unavailable');
      return;
    }

    stopPreviewAudio('Loading preview...');
    const audio = new Audio(preview_command.url);
    previewAudioRef.current = audio;
    audio.volume = previewVolumeRef.current;

    const start = Math.max(0, preview_command.start || 0);
    const end =
      typeof preview_command.end === 'number' && preview_command.end > start
        ? preview_command.end
        : null;
    const seekToStart = () => {
      if (previewAudioRef.current !== audio || start <= 0) {
        return;
      }
      try {
        const duration = Number.isFinite(audio.duration)
          ? audio.duration
          : null;
        audio.currentTime =
          duration !== null
            ? Math.min(start, Math.max(duration - 0.1, 0))
            : start;
      } catch {
        // Best-effort preview seek.
      }
    };
    const finishPreview = (status: string) => {
      if (previewAudioRef.current === audio) {
        previewAudioRef.current = null;
      }
      audio.pause();
      audio.src = '';
      setPreviewState(status);
    };

    audio.addEventListener('loadedmetadata', seekToStart);
    audio.addEventListener('ended', () => finishPreview('Preview ended'));
    audio.addEventListener('error', () => finishPreview('Preview error'));
    if (end !== null) {
      audio.addEventListener('timeupdate', () => {
        if (previewAudioRef.current !== audio || audio.currentTime < end) {
          return;
        }
        finishPreview('Preview ended');
      });
    }

    const startPreview = () => {
      if (previewAudioRef.current !== audio) {
        return;
      }

      audio
        .play()
        .then(() => {
          if (previewAudioRef.current === audio) {
            setPreviewState(preview_command.title || 'Preview playing');
          }
        })
        .catch(() => finishPreview('Preview failed'));
    };

    if (start > 0 && audio.readyState < HTMLMediaElement.HAVE_METADATA) {
      const startAfterMetadata = () => {
        audio.removeEventListener('loadedmetadata', startAfterMetadata);
        if (previewAudioRef.current !== audio) {
          return;
        }
        seekToStart();
        startPreview();
      };

      audio.addEventListener('loadedmetadata', startAfterMetadata);
      audio.load();
      return;
    }

    if (start > 0) {
      seekToStart();
    }

    startPreview();
  }, [preview_command]);

  const selectedTier = findTier(draft, selected_tier_id);
  const selectedVariant = findVariant(selectedTier, selected_variant_id);
  const audienceLabel = audience_options.find(
    (option) => option.id === draft.playback.audience_mode,
  )?.label;
  const soundTypeLabel = sound_type_options.find(
    (option) => option.id === draft.playback.sound_type,
  )?.label;
  const audienceOptions = audience_options.map((option) => ({
    displayText: option.label,
    value: option.id,
  }));
  const soundTypeOptions = sound_type_options.map((option) => ({
    displayText: option.label,
    value: option.id,
  }));

  const handleImport = (jsonText: string | string[]) => {
    const payload = Array.isArray(jsonText) ? jsonText[0] : jsonText;
    if (payload) {
      act('import_json', { json_text: payload });
    }
  };

  const stopPreviewNow = () => {
    const audio = previewAudioRef.current;
    if (audio) {
      audio.pause();
      audio.src = '';
      previewAudioRef.current = null;
    }
    previewKeyRef.current = '';
    setPreviewState('Preview stopped');
    act('stop_preview');
  };

  const handleNewDraft = () => {
    setSelectedLibraryPresetId(null);
    act('new_draft');
  };
  const handleLoadPreset = () => {
    if (selectedLibraryPresetId) {
      act('load_preset', { preset_id: selectedLibraryPresetId });
    }
  };

  return (
    <Window
      title="Admin Music Panel"
      width={1260}
      height={840}
      theme="admin"
      canClose={false}
      buttons={
        <Button
          icon="times"
          color="bad"
          tooltip="Request close"
          onClick={() => act('request_close')}
        >
          Close
        </Button>
      }
    >
      <Window.Content scrollable>
        <Stack fill vertical>
          <Stack.Item>
            <SessionSection
              current_session={current_session}
              onStopBroadcast={() => act('stop_broadcast')}
            />
          </Stack.Item>
          <Stack.Item>
            <Stack fill>
              <Stack.Item basis="34%" grow={1}>
                <Stack fill vertical>
                  <Stack.Item grow={2}>
                    <LibrarySection
                      library={library}
                      librarySearch={librarySearch}
                      selectedLibraryPresetId={selectedLibraryPresetId}
                      onSearchChange={setLibrarySearch}
                      onSelectPreset={setSelectedLibraryPresetId}
                      onLoadPreset={handleLoadPreset}
                      onImport={handleImport}
                    />
                  </Stack.Item>
                  <Stack.Item grow={1}>
                    <PresetEditorSection
                      draft={draft}
                      dirty={dirty}
                      canDelete={can_delete_saved_preset}
                      onNew={handleNewDraft}
                      onSave={() => act('save')}
                      onSaveAsCopy={() => act('save_as_copy')}
                      onDelete={() =>
                        act('delete_preset', { preset_id: draft.preset_id })
                      }
                      onExport={() => act('export_preset')}
                      onSetName={(value) => act('set_name', { name: value })}
                      onSetDescription={(value) =>
                        act('set_description', { description: value })
                      }
                    />
                  </Stack.Item>
                  <Stack.Item grow={2}>
                    <SceneEditorSection
                      draft={draft}
                      selectedTier={selectedTier}
                      selectedTierId={selected_tier_id}
                      onAddTier={() => act('add_tier')}
                      onSelectTier={(tier_id) =>
                        act('select_tier', { tier_id })
                      }
                      onRemoveTier={(tier_id) =>
                        act('remove_tier', { tier_id })
                      }
                      onSetTierName={(tier_id, value) =>
                        act('set_tier_name', { tier_id, name: value })
                      }
                      onSetTierDescription={(tier_id, value) =>
                        act('set_tier_description', {
                          tier_id,
                          description: value,
                        })
                      }
                    />
                  </Stack.Item>
                </Stack>
              </Stack.Item>
              <Stack.Item basis="66%" grow={2}>
                <Stack fill vertical>
                  <Stack.Item>
                    <ControllerSection
                      draft={draft}
                      audienceOptions={audienceOptions}
                      soundTypeOptions={soundTypeOptions}
                      audienceLabel={audienceLabel}
                      soundTypeLabel={soundTypeLabel}
                      selectedTier={selectedTier}
                      selectedVariant={selectedVariant}
                      onSetAudienceMode={(value) =>
                        act('set_audience_mode', { audience_mode: value })
                      }
                      onSetSoundType={(value) =>
                        act('set_sound_type', { sound_type: value })
                      }
                      onToggleShowTitle={() =>
                        act('set_show_title', {
                          show_title_to_players:
                            !draft.playback.show_title_to_players,
                        })
                      }
                      onToggleRepeat={() =>
                        act('set_repeat', {
                          repeat: !draft.playback.repeat,
                        })
                      }
                      onPreviewSelected={() => act('preview_selected')}
                      onStopPreview={stopPreviewNow}
                      onPlaySelected={() => act('play_selected')}
                      previewState={previewState}
                      previewVolume={previewVolume}
                      hasSelection={Boolean(selectedTier && selectedVariant)}
                    />
                  </Stack.Item>
                  <Stack.Item grow={1}>
                    <TrackEditorSection
                      selectedTier={selectedTier}
                      selectedVariant={selectedVariant}
                      selectedVariantId={selected_variant_id}
                      onAddVariant={() => act('add_variant')}
                      onSelectVariant={(tier_id, variant_id) =>
                        act('select_variant', { tier_id, variant_id })
                      }
                      onRemoveVariant={(tier_id, variant_id) =>
                        act('remove_variant', { tier_id, variant_id })
                      }
                      onSetVariantTitle={(tier_id, variant_id, value) =>
                        act('set_variant_title', {
                          tier_id,
                          variant_id,
                          title: value,
                        })
                      }
                      onSetVariantDescription={(tier_id, variant_id, value) =>
                        act('set_variant_description', {
                          tier_id,
                          variant_id,
                          description: value,
                        })
                      }
                      onSetVariantDuration={(tier_id, variant_id, value) =>
                        act('set_variant_duration', {
                          tier_id,
                          variant_id,
                          duration_seconds: value,
                        })
                      }
                      onSetVariantSourceUrl={(tier_id, variant_id, value) =>
                        act('set_variant_source_url', {
                          tier_id,
                          variant_id,
                          source_url: value,
                        })
                      }
                    />
                  </Stack.Item>
                </Stack>
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

type SessionSectionProps = Readonly<{
  current_session: CurrentSession;
  onStopBroadcast: () => void;
}>;

function SessionSection({
  current_session,
  onStopBroadcast,
}: SessionSectionProps) {
  const broadcastTitle =
    current_session?.variant_title ||
    current_session?.resolved_title ||
    'Untitled broadcast';
  const broadcastPath =
    current_session?.preset_name &&
    [current_session.preset_name, current_session.tier_name]
      .filter(Boolean)
      .join(' / ');

  return (
    <Section
      title="Live Broadcast"
      buttons={
        <Button
          icon="stop"
          color="bad"
          disabled={!current_session}
          onClick={onStopBroadcast}
        >
          Stop Broadcast
        </Button>
      }
    >
      {!current_session ? (
        <Box color="label">
          Broadcast deck is idle. Load a preset, cue a scene, and send a track
          live when you are ready.
        </Box>
      ) : (
        <Box style={PLAYER_STRIP_STYLE}>
          <Flex align="center" justify="space-between" width="100%">
            <Flex.Item grow>
              <Box color="label" fontSize="0.8rem">
                On air
              </Box>
              <Box bold fontSize="1.25rem">
                {broadcastTitle}
              </Box>
              <Box color="label">
                {broadcastPath || 'Legacy broadcast session'}
              </Box>
            </Flex.Item>
            <Flex.Item ml={1} textAlign="right">
              <Box style={PLAYER_BADGE_STYLE}>
                Audience {current_session.audience_label}
              </Box>
              <Box style={PLAYER_BADGE_STYLE}>
                Mode {current_session.sound_type_label}
              </Box>
              <Box style={PLAYER_BADGE_STYLE}>
                Repeat {current_session.loop ? 'On' : 'Off'}
              </Box>
            </Flex.Item>
          </Flex>
          <Box style={{ marginTop: '0.45rem' }}>
            <Box style={PLAYER_BADGE_STYLE}>Owner {current_session.owner}</Box>
            <Box style={PLAYER_BADGE_STYLE}>
              Source {current_session.source_kind}
            </Box>
            <Box style={PLAYER_BADGE_STYLE}>
              Show Title {current_session.show_title_to_players ? 'Yes' : 'No'}
            </Box>
            <Box style={PLAYER_BADGE_STYLE}>
              Link {formatSourceLabel(current_session.source_url)}
            </Box>
          </Box>
        </Box>
      )}
    </Section>
  );
}

type LibrarySectionProps = Readonly<{
  library: LibraryPreset[];
  librarySearch: string;
  selectedLibraryPresetId: string | null;
  onSearchChange: (value: string) => void;
  onSelectPreset: (preset_id: string) => void;
  onLoadPreset: () => void;
  onImport: (jsonText: string | string[]) => void;
}>;

function LibrarySection({
  library,
  librarySearch,
  selectedLibraryPresetId,
  onSearchChange,
  onSelectPreset,
  onLoadPreset,
  onImport,
}: LibrarySectionProps) {
  const filteredLibrary = library.filter((preset) => {
    const haystack =
      `${preset.name} ${preset.description} ${preset.preset_id}`.toLowerCase();
    return haystack.includes(librarySearch.toLowerCase());
  });

  return (
    <Section
      title="Library"
      buttons={
        <>
          <Button
            icon="file"
            disabled={!selectedLibraryPresetId}
            onClick={onLoadPreset}
          >
            Load
          </Button>
          <Button.File
            icon="upload"
            accept=".json,application/json"
            onSelectFiles={onImport}
          >
            Import JSON
          </Button.File>
        </>
      }
    >
      <Stack vertical>
        <Stack.Item>
          <Input
            fluid
            placeholder="Search presets..."
            value={librarySearch}
            onInput={(e, value) => onSearchChange(value)}
          />
        </Stack.Item>
        <Stack.Item>
          <Section fill scrollable title="Saved Presets">
            {filteredLibrary.length === 0 ? (
              <Box color="label">No presets found.</Box>
            ) : (
              filteredLibrary.map((preset) => (
                <Button
                  key={preset.preset_id}
                  fluid
                  selected={selectedLibraryPresetId === preset.preset_id}
                  onClick={() => onSelectPreset(preset.preset_id)}
                  style={{ marginBottom: '0.25rem' }}
                >
                  <Flex justify="space-between" width="100%">
                    <Flex.Item grow>
                      <Box bold>{preset.name}</Box>
                      <Box fontSize="0.8rem" color="label">
                        {preset.description || 'No description'}
                      </Box>
                    </Flex.Item>
                    <Flex.Item ml={1} textAlign="right">
                      <Box fontSize="0.8rem">Scenes {preset.tier_count}</Box>
                      <Box fontSize="0.8rem">Tracks {preset.variant_count}</Box>
                    </Flex.Item>
                  </Flex>
                </Button>
              ))
            )}
          </Section>
        </Stack.Item>
      </Stack>
    </Section>
  );
}

type PresetEditorSectionProps = Readonly<{
  draft: DraftPreset;
  dirty: boolean;
  canDelete: boolean;
  onNew: () => void;
  onSave: () => void;
  onSaveAsCopy: () => void;
  onDelete: () => void;
  onExport: () => void;
  onSetName: (value: string) => void;
  onSetDescription: (value: string) => void;
}>;

function PresetEditorSection({
  draft,
  dirty,
  canDelete,
  onNew,
  onSave,
  onSaveAsCopy,
  onDelete,
  onExport,
  onSetName,
  onSetDescription,
}: PresetEditorSectionProps) {
  return (
    <Section
      title="Preset"
      buttons={
        <>
          <Button icon="plus" onClick={onNew}>
            New
          </Button>
          <Button icon="save" onClick={onSave}>
            Save
          </Button>
          <Button icon="copy" onClick={onSaveAsCopy}>
            Save As Copy
          </Button>
          <Button
            icon="trash"
            color="bad"
            disabled={!canDelete}
            onClick={onDelete}
          >
            Delete
          </Button>
          <Button icon="download" onClick={onExport}>
            Export
          </Button>
        </>
      }
    >
      <Stack vertical>
        <Stack.Item>
          <Box style={PLAYER_CARD_STYLE}>
            <Box color="label" fontSize="0.8rem">
              Preset Sheet
            </Box>
            <Box bold fontSize="1.05rem">
              {draft.name || 'New preset'}
            </Box>
            <Box style={{ marginTop: '0.45rem' }}>
              <Box style={PLAYER_BADGE_STYLE}>
                ID {draft.preset_id || 'new'}
              </Box>
              <Box style={PLAYER_BADGE_STYLE}>
                Unsaved {dirty ? 'Yes' : 'No'}
              </Box>
              <Box style={PLAYER_BADGE_STYLE}>Scenes {draft.tiers.length}</Box>
            </Box>
          </Box>
        </Stack.Item>
        <Stack.Item>
          <LabeledList>
            <LabeledList.Item label="Name">
              <Input
                fluid
                value={draft.name}
                onInput={(e, value) => onSetName(value)}
              />
            </LabeledList.Item>
            <LabeledList.Item label="Description" verticalAlign="top">
              <TextArea
                fluid
                height={DESCRIPTION_FIELD_HEIGHT}
                value={draft.description}
                onInput={(e, value) => onSetDescription(value)}
                placeholder="Short description for admins"
                scrollbar
              />
            </LabeledList.Item>
          </LabeledList>
        </Stack.Item>
      </Stack>
    </Section>
  );
}

type SceneEditorSectionProps = Readonly<{
  draft: DraftPreset;
  selectedTier: DraftTier | null;
  selectedTierId: string | null;
  onAddTier: () => void;
  onSelectTier: (tier_id: string) => void;
  onRemoveTier: (tier_id: string) => void;
  onSetTierName: (tier_id: string, value: string) => void;
  onSetTierDescription: (tier_id: string, value: string) => void;
}>;

function SceneEditorSection({
  draft,
  selectedTier,
  selectedTierId,
  onAddTier,
  onSelectTier,
  onRemoveTier,
  onSetTierName,
  onSetTierDescription,
}: SceneEditorSectionProps) {
  return (
    <Section
      fill
      title="Scenes"
      buttons={
        <Button icon="plus" onClick={onAddTier}>
          Add Scene
        </Button>
      }
    >
      <Stack fill vertical>
        <Stack.Item>
          {selectedTier && (
            <Box style={{ ...PLAYER_CARD_STYLE, marginBottom: '0.5rem' }}>
              <Box color="label" fontSize="0.8rem">
                Current Scene
              </Box>
              <Box bold fontSize="1.05rem">
                {selectedTier.name || 'Unnamed scene'}
              </Box>
              <Box color="label">
                {selectedTier.description || 'No scene description'}
              </Box>
            </Box>
          )}
          {draft.tiers.length === 0 ? (
            <Box color="label">No scenes yet.</Box>
          ) : (
            draft.tiers.map((tier) => (
              <Button
                key={tier.tier_id}
                fluid
                selected={selectedTierId === tier.tier_id}
                onClick={() => onSelectTier(tier.tier_id)}
                style={{ marginBottom: '0.25rem' }}
              >
                <Flex justify="space-between" width="100%">
                  <Flex.Item grow>
                    <Box bold>{tier.name || 'Unnamed scene'}</Box>
                    <Box fontSize="0.8rem" color="label">
                      {tier.description || 'No description'}
                    </Box>
                  </Flex.Item>
                  <Flex.Item ml={1} textAlign="right">
                    <Box fontSize="0.8rem">Tracks {tier.variants.length}</Box>
                    <Button
                      icon="trash"
                      color="bad"
                      ml={1}
                      onClick={(event) => {
                        event.stopPropagation();
                        onRemoveTier(tier.tier_id);
                      }}
                    />
                  </Flex.Item>
                </Flex>
              </Button>
            ))
          )}
        </Stack.Item>
        <Stack.Item grow={1}>
          <Section title="Scene Details">
            {!selectedTier ? (
              <Box color="label">Select a scene from the list above.</Box>
            ) : (
              <LabeledList>
                <LabeledList.Item label="Name">
                  <Input
                    fluid
                    value={selectedTier.name}
                    onInput={(e, value) =>
                      onSetTierName(selectedTier.tier_id, value)
                    }
                  />
                </LabeledList.Item>
                <LabeledList.Item label="Description" verticalAlign="top">
                  <TextArea
                    fluid
                    height={DESCRIPTION_FIELD_HEIGHT}
                    value={selectedTier.description}
                    onInput={(e, value) =>
                      onSetTierDescription(selectedTier.tier_id, value)
                    }
                    placeholder="Scene description"
                    scrollbar
                  />
                </LabeledList.Item>
              </LabeledList>
            )}
          </Section>
        </Stack.Item>
      </Stack>
    </Section>
  );
}

type ControllerSectionProps = Readonly<{
  draft: DraftPreset;
  audienceOptions: { displayText: string; value: string }[];
  soundTypeOptions: { displayText: string; value: string }[];
  audienceLabel: string | undefined;
  soundTypeLabel: string | undefined;
  selectedTier: DraftTier | null;
  selectedVariant: DraftVariant | null;
  onSetAudienceMode: (value: string) => void;
  onSetSoundType: (value: string) => void;
  onToggleShowTitle: () => void;
  onToggleRepeat: () => void;
  onPreviewSelected: () => void;
  onStopPreview: () => void;
  onPlaySelected: () => void;
  previewState: string;
  previewVolume: number;
  hasSelection: boolean;
}>;

function ControllerSection({
  draft,
  audienceOptions,
  soundTypeOptions,
  audienceLabel,
  soundTypeLabel,
  selectedTier,
  selectedVariant,
  onSetAudienceMode,
  onSetSoundType,
  onToggleShowTitle,
  onToggleRepeat,
  onPreviewSelected,
  onStopPreview,
  onPlaySelected,
  previewState,
  previewVolume,
  hasSelection,
}: ControllerSectionProps) {
  const selectionTitle = selectedVariant?.title || 'No track selected';
  const selectionDescription =
    selectedVariant?.description ||
    'Pick a scene on the left, then choose a track to cue or broadcast.';

  return (
    <Section title="Deck">
      <Stack vertical>
        <Stack.Item>
          <Box style={PLAYER_CARD_STYLE}>
            <Box color="label" fontSize="0.8rem">
              Cue Selection
            </Box>
            <Box bold fontSize="1.35rem">
              {selectionTitle}
            </Box>
            <Box color="label">{selectionDescription}</Box>
            <Box style={{ marginTop: '0.45rem' }}>
              <Box style={PLAYER_BADGE_STYLE}>
                Preset {draft.name || 'New preset'}
              </Box>
              <Box style={PLAYER_BADGE_STYLE}>
                Scene {selectedTier?.name || 'None'}
              </Box>
              <Box style={PLAYER_BADGE_STYLE}>
                Length{' '}
                {selectedVariant
                  ? formatDuration(selectedVariant.duration_seconds)
                  : 'Unknown'}
              </Box>
              <Box style={PLAYER_BADGE_STYLE}>
                Source{' '}
                {selectedVariant
                  ? formatSourceLabel(selectedVariant.source_url)
                  : 'None'}
              </Box>
              <Box style={PLAYER_BADGE_STYLE}>
                Repeat {draft.playback.repeat ? 'On' : 'Off'}
              </Box>
            </Box>
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Stack fill>
            <Stack.Item grow>
              <Button
                fluid
                color="good"
                icon="eye"
                disabled={!hasSelection}
                onClick={onPreviewSelected}
              >
                Preview
              </Button>
            </Stack.Item>
            <Stack.Item grow>
              <Button fluid color="bad" icon="stop" onClick={onStopPreview}>
                Stop Cue
              </Button>
            </Stack.Item>
            <Stack.Item grow>
              <Button
                fluid
                color="good"
                icon="play"
                disabled={!hasSelection}
                onClick={onPlaySelected}
              >
                Broadcast
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>
        <Stack.Item>
          <Section title="Broadcast Settings">
            <LabeledList>
              <LabeledList.Item label="Audience">
                <Dropdown
                  options={audienceOptions}
                  selected={draft.playback.audience_mode}
                  displayText={audienceLabel}
                  onSelected={(value) => onSetAudienceMode(value)}
                />
              </LabeledList.Item>
              <LabeledList.Item label="Sound Type">
                <Dropdown
                  options={soundTypeOptions}
                  selected={draft.playback.sound_type}
                  displayText={soundTypeLabel}
                  onSelected={(value) => onSetSoundType(value)}
                />
              </LabeledList.Item>
              <LabeledList.Item label="Show Title">
                <Button.Checkbox
                  checked={draft.playback.show_title_to_players}
                  onClick={onToggleShowTitle}
                >
                  Visible to players
                </Button.Checkbox>
              </LabeledList.Item>
              <LabeledList.Item label="Repeat">
                <Button.Checkbox
                  checked={draft.playback.repeat}
                  onClick={onToggleRepeat}
                >
                  Repeat track until stopped
                </Button.Checkbox>
              </LabeledList.Item>
            </LabeledList>
          </Section>
        </Stack.Item>
        <Stack.Item>
          <Section
            title="Cue Output"
            buttons={
              <Box color="label">Volume {Math.round(previewVolume * 100)}%</Box>
            }
          >
            <Box bold>{previewState}</Box>
            <Box color="label">
              Local preview only. Broadcast uses the shared admin music channel.
            </Box>
          </Section>
        </Stack.Item>
      </Stack>
    </Section>
  );
}

type TrackEditorSectionProps = Readonly<{
  selectedTier: DraftTier | null;
  selectedVariant: DraftVariant | null;
  selectedVariantId: string | null;
  onAddVariant: () => void;
  onSelectVariant: (tier_id: string, variant_id: string) => void;
  onRemoveVariant: (tier_id: string, variant_id: string) => void;
  onSetVariantTitle: (
    tier_id: string,
    variant_id: string,
    value: string,
  ) => void;
  onSetVariantDescription: (
    tier_id: string,
    variant_id: string,
    value: string,
  ) => void;
  onSetVariantDuration: (
    tier_id: string,
    variant_id: string,
    value: number,
  ) => void;
  onSetVariantSourceUrl: (
    tier_id: string,
    variant_id: string,
    value: string,
  ) => void;
}>;

function TrackEditorSection({
  selectedTier,
  selectedVariant,
  selectedVariantId,
  onAddVariant,
  onSelectVariant,
  onRemoveVariant,
  onSetVariantTitle,
  onSetVariantDescription,
  onSetVariantDuration,
  onSetVariantSourceUrl,
}: TrackEditorSectionProps) {
  return (
    <Section
      fill
      title="Tracks"
      buttons={
        <Button icon="plus" disabled={!selectedTier} onClick={onAddVariant}>
          Add Track
        </Button>
      }
    >
      {!selectedTier ? (
        <Box color="label">
          Select a scene on the left to manage its tracks.
        </Box>
      ) : (
        <Stack fill vertical>
          <Stack.Item>
            <Box style={{ ...PLAYER_CARD_STYLE, marginBottom: '0.5rem' }}>
              <Flex align="center" justify="space-between" width="100%">
                <Flex.Item grow>
                  <Box color="label" fontSize="0.8rem">
                    Scene Rack
                  </Box>
                  <Box bold fontSize="1.05rem">
                    {selectedTier.name || 'Unnamed scene'}
                  </Box>
                  <Box color="label">
                    {selectedTier.description || 'No scene description'}
                  </Box>
                </Flex.Item>
                <Flex.Item ml={1} textAlign="right">
                  <Box style={PLAYER_BADGE_STYLE}>
                    Tracks {selectedTier.variants.length}
                  </Box>
                </Flex.Item>
              </Flex>
            </Box>
            {selectedTier.variants.length === 0 ? (
              <Box color="label">No tracks yet.</Box>
            ) : (
              selectedTier.variants.map((variant) => (
                <Button
                  key={variant.variant_id}
                  fluid
                  selected={selectedVariantId === variant.variant_id}
                  onClick={() =>
                    onSelectVariant(selectedTier.tier_id, variant.variant_id)
                  }
                  style={{ marginBottom: '0.25rem' }}
                >
                  <Flex justify="space-between" width="100%">
                    <Flex.Item grow>
                      <Box bold>{variant.title || 'Unnamed track'}</Box>
                      <Box fontSize="0.8rem" color="label">
                        {variant.description || 'No description'}
                      </Box>
                      <Box fontSize="0.75rem" color="label">
                        {formatSourceLabel(variant.source_url)}
                      </Box>
                    </Flex.Item>
                    <Flex.Item ml={1} textAlign="right">
                      <Box fontSize="0.8rem">
                        {formatDuration(variant.duration_seconds)}
                      </Box>
                      <Button
                        icon="trash"
                        color="bad"
                        ml={1}
                        onClick={(event) => {
                          event.stopPropagation();
                          onRemoveVariant(
                            selectedTier.tier_id,
                            variant.variant_id,
                          );
                        }}
                      />
                    </Flex.Item>
                  </Flex>
                </Button>
              ))
            )}
          </Stack.Item>

          <Stack.Item grow={1}>
            <Section title="Track Details">
              {!selectedVariant ? (
                <Box color="label">Select a track from the list above.</Box>
              ) : (
                <Stack vertical>
                  <Stack.Item>
                    <Box style={PLAYER_CARD_STYLE}>
                      <Box color="label" fontSize="0.8rem">
                        Loaded Track
                      </Box>
                      <Box bold fontSize="1.1rem">
                        {selectedVariant.title || 'Unnamed track'}
                      </Box>
                      <Box color="label">
                        {selectedVariant.description || 'No track description'}
                      </Box>
                      <Box style={{ marginTop: '0.45rem' }}>
                        <Box style={PLAYER_BADGE_STYLE}>
                          Length{' '}
                          {formatDuration(selectedVariant.duration_seconds)}
                        </Box>
                        <Box style={PLAYER_BADGE_STYLE}>
                          Source {formatSourceLabel(selectedVariant.source_url)}
                        </Box>
                      </Box>
                    </Box>
                  </Stack.Item>
                  <Stack.Item>
                    <LabeledList>
                      <LabeledList.Item label="Title">
                        <Input
                          fluid
                          value={selectedVariant.title}
                          onInput={(e, value) =>
                            onSetVariantTitle(
                              selectedTier.tier_id,
                              selectedVariant.variant_id,
                              value,
                            )
                          }
                        />
                      </LabeledList.Item>
                      <LabeledList.Item label="Description" verticalAlign="top">
                        <TextArea
                          fluid
                          height={DESCRIPTION_FIELD_HEIGHT}
                          value={selectedVariant.description}
                          onInput={(e, value) =>
                            onSetVariantDescription(
                              selectedTier.tier_id,
                              selectedVariant.variant_id,
                              value,
                            )
                          }
                          placeholder="Track description"
                          scrollbar
                        />
                      </LabeledList.Item>
                      <LabeledList.Item label="Duration">
                        <NumberInput
                          minValue={0}
                          maxValue={86400}
                          step={1}
                          value={selectedVariant.duration_seconds}
                          onChange={(value) =>
                            onSetVariantDuration(
                              selectedTier.tier_id,
                              selectedVariant.variant_id,
                              value,
                            )
                          }
                        />
                      </LabeledList.Item>
                      <LabeledList.Item label="Source URL">
                        <Input
                          fluid
                          value={selectedVariant.source_url}
                          onInput={(e, value) =>
                            onSetVariantSourceUrl(
                              selectedTier.tier_id,
                              selectedVariant.variant_id,
                              value,
                            )
                          }
                          placeholder="https://..."
                        />
                      </LabeledList.Item>
                    </LabeledList>
                  </Stack.Item>
                </Stack>
              )}
            </Section>
          </Stack.Item>
        </Stack>
      )}
    </Section>
  );
}
