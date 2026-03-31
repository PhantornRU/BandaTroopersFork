import { storage } from 'common/storage';
import { useEffect, useRef, useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Dropdown, Flex, Input, LabeledList, NumberInput, Section, Stack, TextArea } from '../components';
import { Window } from '../layouts';

type LibraryPreset = { preset_id: string; name: string; description: string; tier_count: number; variant_count: number };
type DraftVariant = { variant_id: string; title: string; description: string; duration_seconds: number; source_url: string };
type DraftTier = { tier_id: string; name: string; description: string; variants: DraftVariant[] };
type DraftPreset = {
  preset_id: string;
  name: string;
  description: string;
  playback: { audience_mode: string; sound_type: string; show_title_to_players: boolean };
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
type PreviewCommand = null | { nonce: number | string; command: 'play' | 'stop'; title?: string; url?: string; start?: number; end?: number };
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

const formatDuration = (duration_seconds: number) => {
  if (!Number.isFinite(duration_seconds) || duration_seconds <= 0) {
    return 'Unknown';
  }
  const seconds = Math.floor(duration_seconds);
  const minutes = Math.floor(seconds / 60);
  const remainder = seconds % 60;
  return minutes ? `${minutes}m ${String(remainder).padStart(2, '0')}s` : `${remainder}s`;
};

const findTier = (draft: DraftPreset, tierId: string | null) =>
  draft.tiers.find((tier) => tier.tier_id === tierId) || draft.tiers[0] || null;
const findVariant = (tier: DraftTier | null, variantId: string | null) =>
  tier?.variants.find((variant) => variant.variant_id === variantId) || tier?.variants[0] || null;

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
  const [selectedLibraryPresetId, setSelectedLibraryPresetId] = useState<string | null>(
    draft?.preset_id || library[0]?.preset_id || null,
  );
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
    const end = typeof preview_command.end === 'number' && preview_command.end > start ? preview_command.end : null;
    const seekToStart = () => {
      if (previewAudioRef.current !== audio || start <= 0) {
        return;
      }
      try {
        const duration = Number.isFinite(audio.duration) ? audio.duration : null;
        audio.currentTime = duration !== null ? Math.min(start, Math.max(duration - 0.1, 0)) : start;
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
    audio
      .play()
      .then(() => {
        if (previewAudioRef.current === audio) {
          setPreviewState(preview_command.title || 'Preview playing');
        }
      })
      .catch(() => finishPreview('Preview failed'));
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
              <Stack.Item basis="31%" grow={1}>
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
              <Stack.Item basis="69%" grow={2}>
                <Stack vertical>
                  <Stack.Item>
                    <DraftGeneralSection
                      draft={draft}
                      dirty={dirty}
                      audienceOptions={audienceOptions}
                      soundTypeOptions={soundTypeOptions}
                      audienceLabel={audienceLabel}
                      soundTypeLabel={soundTypeLabel}
                      onNew={handleNewDraft}
                      onSave={() => act('save')}
                      onSaveAsCopy={() => act('save_as_copy')}
                      onDelete={() => act('delete_preset', { preset_id: draft.preset_id })}
                      onExport={() => act('export_preset')}
                      onSetName={(value) => act('set_name', { name: value })}
                      onSetDescription={(value) =>
                        act('set_description', { description: value })
                      }
                      onSetAudienceMode={(value) =>
                        act('set_audience_mode', { audience_mode: value })
                      }
                      onSetSoundType={(value) => act('set_sound_type', { sound_type: value })}
                      onToggleShowTitle={() =>
                        act('set_show_title', {
                          show_title_to_players: !draft.playback.show_title_to_players,
                        })
                      }
                      onPreviewSelected={() => act('preview_selected')}
                      onStopPreview={stopPreviewNow}
                      onPlaySelected={() => act('play_selected')}
                      canDelete={can_delete_saved_preset}
                      previewState={previewState}
                      previewVolume={previewVolume}
                      hasSelection={Boolean(selectedTier && selectedVariant)}
                    />
                  </Stack.Item>
                  <Stack.Item>
                    <TierEditorSection
                      draft={draft}
                      selectedTier={selectedTier}
                      selectedVariant={selectedVariant}
                      selectedTierId={selected_tier_id}
                      selectedVariantId={selected_variant_id}
                      onAddTier={() => act('add_tier')}
                      onSelectTier={(tier_id) => act('select_tier', { tier_id })}
                      onRemoveTier={(tier_id) => act('remove_tier', { tier_id })}
                      onAddVariant={() => act('add_variant')}
                      onSelectVariant={(tier_id, variant_id) =>
                        act('select_variant', { tier_id, variant_id })
                      }
                      onRemoveVariant={(tier_id, variant_id) =>
                        act('remove_variant', { tier_id, variant_id })
                      }
                      onSetTierName={(tier_id, value) =>
                        act('set_tier_name', { tier_id, name: value })
                      }
                      onSetTierDescription={(tier_id, value) =>
                        act('set_tier_description', { tier_id, description: value })
                      }
                      onSetVariantTitle={(tier_id, variant_id, value) =>
                        act('set_variant_title', { tier_id, variant_id, title: value })
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

type SessionSectionProps = {
  current_session: CurrentSession;
  onStopBroadcast: () => void;
};

function SessionSection({ current_session, onStopBroadcast }: SessionSectionProps) {
  return (
    <Section
      title="Current Session"
      buttons={
        <Button icon="stop" color="bad" disabled={!current_session} onClick={onStopBroadcast}>
          Stop Broadcast
        </Button>
      }
    >
      {!current_session ? (
        <Box color="label">No active broadcast.</Box>
      ) : (
        <LabeledList>
          <LabeledList.Item label="Source">{current_session.source_kind}</LabeledList.Item>
          <LabeledList.Item label="Owner">{current_session.owner}</LabeledList.Item>
          <LabeledList.Item label="Audience">{current_session.audience_label}</LabeledList.Item>
          <LabeledList.Item label="Sound Type">{current_session.sound_type_label}</LabeledList.Item>
          <LabeledList.Item label="Show Title">
            {current_session.show_title_to_players ? 'Yes' : 'No'}
          </LabeledList.Item>
          <LabeledList.Item label="Title">{current_session.resolved_title}</LabeledList.Item>
          <LabeledList.Item label="URL">{current_session.source_url}</LabeledList.Item>
          {current_session.preset_name && (
            <LabeledList.Item label="Preset">{current_session.preset_name}</LabeledList.Item>
          )}
          {current_session.tier_name && (
            <LabeledList.Item label="Tier">{current_session.tier_name}</LabeledList.Item>
          )}
          {current_session.variant_title && (
            <LabeledList.Item label="Variant">{current_session.variant_title}</LabeledList.Item>
          )}
          <LabeledList.Item label="Loop">{current_session.loop ? 'Yes' : 'No'}</LabeledList.Item>
        </LabeledList>
      )}
    </Section>
  );
}

type LibrarySectionProps = {
  library: LibraryPreset[];
  librarySearch: string;
  selectedLibraryPresetId: string | null;
  onSearchChange: (value: string) => void;
  onSelectPreset: (preset_id: string) => void;
  onLoadPreset: () => void;
  onImport: (jsonText: string | string[]) => void;
};

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
    const haystack = `${preset.name} ${preset.description} ${preset.preset_id}`.toLowerCase();
    return haystack.includes(librarySearch.toLowerCase());
  });

  return (
    <Section
      title="Library"
      buttons={
        <>
          <Button icon="file" disabled={!selectedLibraryPresetId} onClick={onLoadPreset}>
            Load
          </Button>
          <Button.File icon="upload" accept=".json,application/json" onSelectFiles={onImport}>
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
                      <Box fontSize="0.8rem">Tiers {preset.tier_count}</Box>
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

type DraftGeneralSectionProps = {
  draft: DraftPreset;
  dirty: boolean;
  audienceOptions: { displayText: string; value: string }[];
  soundTypeOptions: { displayText: string; value: string }[];
  audienceLabel: string | undefined;
  soundTypeLabel: string | undefined;
  onNew: () => void;
  onSave: () => void;
  onSaveAsCopy: () => void;
  onDelete: () => void;
  onExport: () => void;
  onSetName: (value: string) => void;
  onSetDescription: (value: string) => void;
  onSetAudienceMode: (value: string) => void;
  onSetSoundType: (value: string) => void;
  onToggleShowTitle: () => void;
  onPreviewSelected: () => void;
  onStopPreview: () => void;
  onPlaySelected: () => void;
  canDelete: boolean;
  previewState: string;
  previewVolume: number;
  hasSelection: boolean;
};

function DraftGeneralSection({
  draft,
  dirty,
  audienceOptions,
  soundTypeOptions,
  audienceLabel,
  soundTypeLabel,
  onNew,
  onSave,
  onSaveAsCopy,
  onDelete,
  onExport,
  onSetName,
  onSetDescription,
  onSetAudienceMode,
  onSetSoundType,
  onToggleShowTitle,
  onPreviewSelected,
  onStopPreview,
  onPlaySelected,
  canDelete,
  previewState,
  previewVolume,
  hasSelection,
}: DraftGeneralSectionProps) {
  return (
    <Section
      title="Draft"
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
          <Button icon="trash" color="bad" disabled={!canDelete} onClick={onDelete}>
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
          <LabeledList>
            <LabeledList.Item label="Preset ID">{draft.preset_id || 'New preset'}</LabeledList.Item>
            <LabeledList.Item label="Dirty">{dirty ? 'Yes' : 'No'}</LabeledList.Item>
          </LabeledList>
        </Stack.Item>
        <Stack.Item>
          <LabeledList>
            <LabeledList.Item label="Name">
              <Input fluid value={draft.name} onInput={(e, value) => onSetName(value)} />
            </LabeledList.Item>
            <LabeledList.Item label="Description">
              <TextArea
                fluid
                value={draft.description}
                onInput={(e, value) => onSetDescription(value)}
                placeholder="Short description for admins"
                scrollbar
              />
            </LabeledList.Item>
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
              <Button.Checkbox checked={draft.playback.show_title_to_players} onClick={onToggleShowTitle}>
                Visible to players
              </Button.Checkbox>
            </LabeledList.Item>
          </LabeledList>
        </Stack.Item>
        <Stack.Item>
          <Stack>
            <Stack.Item>
              <Button color="good" icon="eye" disabled={!hasSelection} onClick={onPreviewSelected}>
                Preview Selected
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button color="bad" icon="stop" onClick={onStopPreview}>
                Stop Preview
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button color="good" icon="play" disabled={!hasSelection} onClick={onPlaySelected}>
                Play Selected
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>
        <Stack.Item>
          <Section
            title="Preview"
            buttons={<Box color="label">Volume {Math.round(previewVolume * 100)}%</Box>}
          >
            <Box>{previewState}</Box>
          </Section>
        </Stack.Item>
      </Stack>
    </Section>
  );
}

type TierEditorSectionProps = {
  draft: DraftPreset;
  selectedTier: DraftTier | null;
  selectedVariant: DraftVariant | null;
  selectedTierId: string | null;
  selectedVariantId: string | null;
  onAddTier: () => void;
  onSelectTier: (tier_id: string) => void;
  onRemoveTier: (tier_id: string) => void;
  onAddVariant: () => void;
  onSelectVariant: (tier_id: string, variant_id: string) => void;
  onRemoveVariant: (tier_id: string, variant_id: string) => void;
  onSetTierName: (tier_id: string, value: string) => void;
  onSetTierDescription: (tier_id: string, value: string) => void;
  onSetVariantTitle: (tier_id: string, variant_id: string, value: string) => void;
  onSetVariantDescription: (
    tier_id: string,
    variant_id: string,
    value: string,
  ) => void;
  onSetVariantDuration: (tier_id: string, variant_id: string, value: number) => void;
  onSetVariantSourceUrl: (tier_id: string, variant_id: string, value: string) => void;
};

function TierEditorSection({
  draft,
  selectedTier,
  selectedVariant,
  selectedTierId,
  selectedVariantId,
  onAddTier,
  onSelectTier,
  onRemoveTier,
  onAddVariant,
  onSelectVariant,
  onRemoveVariant,
  onSetTierName,
  onSetTierDescription,
  onSetVariantTitle,
  onSetVariantDescription,
  onSetVariantDuration,
  onSetVariantSourceUrl,
}: TierEditorSectionProps) {
  return (
    <Section
      title="Tiers"
      buttons={<Button icon="plus" onClick={onAddTier}>Add Tier</Button>}
    >
      <Stack vertical>
        <Stack.Item>
          {draft.tiers.length === 0 ? (
            <Box color="label">No tiers yet.</Box>
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
                    <Box bold>{tier.name || 'Unnamed tier'}</Box>
                    <Box fontSize="0.8rem" color="label">
                      {tier.description || 'No description'}
                    </Box>
                  </Flex.Item>
                  <Flex.Item ml={1} textAlign="right">
                    <Box fontSize="0.8rem">Variants {tier.variants.length}</Box>
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

        {selectedTier && (
          <Stack.Item>
            <Section title={`Tier: ${selectedTier.name || 'Unnamed tier'}`} buttons={<Button icon="plus" onClick={onAddVariant}>Add Variant</Button>}>
              <LabeledList>
                <LabeledList.Item label="Name">
                  <Input
                    fluid
                    value={selectedTier.name}
                    onInput={(e, value) => onSetTierName(selectedTier.tier_id, value)}
                  />
                </LabeledList.Item>
                <LabeledList.Item label="Description">
                  <TextArea
                    fluid
                    value={selectedTier.description}
                    onInput={(e, value) => onSetTierDescription(selectedTier.tier_id, value)}
                    placeholder="Tier description"
                    scrollbar
                  />
                </LabeledList.Item>
              </LabeledList>

              <Section title="Variants">
                <Stack vertical>
                  <Stack.Item>
                    {selectedTier.variants.length === 0 ? (
                      <Box color="label">No variants yet.</Box>
                    ) : (
                      selectedTier.variants.map((variant) => (
                        <Button
                          key={variant.variant_id}
                          fluid
                          selected={selectedVariantId === variant.variant_id}
                          onClick={() => onSelectVariant(selectedTier.tier_id, variant.variant_id)}
                          style={{ marginBottom: '0.25rem' }}
                        >
                          <Flex justify="space-between" width="100%">
                            <Flex.Item grow>
                              <Box bold>{variant.title || 'Unnamed variant'}</Box>
                              <Box fontSize="0.8rem" color="label">
                                {variant.description || 'No description'}
                              </Box>
                            </Flex.Item>
                            <Flex.Item ml={1} textAlign="right">
                              <Box fontSize="0.8rem">{formatDuration(variant.duration_seconds)}</Box>
                              <Button
                                icon="trash"
                                color="bad"
                                ml={1}
                                onClick={(event) => {
                                  event.stopPropagation();
                                  onRemoveVariant(selectedTier.tier_id, variant.variant_id);
                                }}
                              />
                            </Flex.Item>
                          </Flex>
                        </Button>
                      ))
                    )}
                  </Stack.Item>

                  {selectedVariant && (
                    <Stack.Item>
                      <Section title={`Variant: ${selectedVariant.title || 'Unnamed variant'}`}>
                        <LabeledList>
                          <LabeledList.Item label="Title">
                            <Input
                              fluid
                              value={selectedVariant.title}
                              onInput={(e, value) =>
                                onSetVariantTitle(selectedTier.tier_id, selectedVariant.variant_id, value)
                              }
                            />
                          </LabeledList.Item>
                          <LabeledList.Item label="Description">
                            <TextArea
                              fluid
                              value={selectedVariant.description}
                              onInput={(e, value) =>
                                onSetVariantDescription(
                                  selectedTier.tier_id,
                                  selectedVariant.variant_id,
                                  value,
                                )
                              }
                              placeholder="Variant description"
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
                                onSetVariantDuration(selectedTier.tier_id, selectedVariant.variant_id, value)
                              }
                            />
                          </LabeledList.Item>
                          <LabeledList.Item label="Source URL">
                            <Input
                              fluid
                              value={selectedVariant.source_url}
                              onInput={(e, value) =>
                                onSetVariantSourceUrl(selectedTier.tier_id, selectedVariant.variant_id, value)
                              }
                              placeholder="https://..."
                            />
                          </LabeledList.Item>
                        </LabeledList>
                      </Section>
                    </Stack.Item>
                  )}
                </Stack>
              </Section>
            </Section>
          </Stack.Item>
        )}
      </Stack>
    </Section>
  );
}
