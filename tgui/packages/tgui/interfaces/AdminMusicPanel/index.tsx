import { useEffect, useRef, useState } from 'react';

import { useBackend } from '../../backend';
import { Button, Stack, Tabs } from '../../components';
import { Window } from '../../layouts';
import { EditTab, PlayTab, SessionSection } from './sections';
import {
  AdminMusicPanelData,
  buildLaunchSettings,
  findTier,
  findVariant,
  getOptionLabel,
  isCurrentSessionForSelection,
  LaunchSettings,
  toSelectOptions,
  useAdminMusicPreview,
} from './shared';

export function AdminMusicPanel() {
  const { act, data } = useBackend<AdminMusicPanelData>();
  const {
    library,
    draft,
    draft_token,
    dirty,
    selected_tier_id,
    selected_variant_id,
    can_delete_saved_preset,
    current_session,
    audience_options,
    sound_type_options,
    preview_command,
  } = data;

  const [activeTab, setActiveTab] = useState<'play' | 'edit'>('play');
  const [librarySearch, setLibrarySearch] = useState('');
  const [selectedLibraryPresetId, setSelectedLibraryPresetId] = useState<
    string | null
  >(draft?.preset_id || library[0]?.preset_id || null);
  const [launchSettings, setLaunchSettings] = useState<LaunchSettings>(() =>
    buildLaunchSettings(draft),
  );

  const initialLibrarySyncRef = useRef(false);
  const { isPreviewActive, previewState, previewVolume, stopPreview } =
    useAdminMusicPreview(preview_command, () => act('stop_preview'));

  useEffect(() => {
    setLaunchSettings(buildLaunchSettings(draft));
  }, [draft_token]);

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

  useEffect(() => {
    if (initialLibrarySyncRef.current) {
      return;
    }
    if (dirty) {
      return;
    }
    if (draft?.preset_id) {
      initialLibrarySyncRef.current = true;
      return;
    }
    if (!library.length) {
      initialLibrarySyncRef.current = true;
      return;
    }

    const initialPresetId = selectedLibraryPresetId || library[0]?.preset_id;
    if (!initialPresetId) {
      initialLibrarySyncRef.current = true;
      return;
    }

    initialLibrarySyncRef.current = true;
    if (selectedLibraryPresetId !== initialPresetId) {
      setSelectedLibraryPresetId(initialPresetId);
    }
    act('load_preset', { preset_id: initialPresetId });
  }, [act, dirty, draft?.preset_id, library, selectedLibraryPresetId]);

  const selectedTier = findTier(draft, selected_tier_id);
  const selectedVariant = findVariant(selectedTier, selected_variant_id);
  const audienceOptions = toSelectOptions(audience_options);
  const soundTypeOptions = toSelectOptions(sound_type_options);
  const hasSelection = Boolean(selectedTier && selectedVariant);
  const selectedTrackIsLive = isCurrentSessionForSelection(
    current_session,
    draft,
    selectedTier,
    selectedVariant,
  );

  const handleImport = (jsonText: string | string[]) => {
    const payload = Array.isArray(jsonText) ? jsonText[0] : jsonText;
    if (payload) {
      act('import_json', { json_text: payload });
    }
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
              draft={draft}
              selectedTier={selectedTier}
              selectedVariant={selectedVariant}
              launchSettings={launchSettings}
              audienceLabel={getOptionLabel(
                audience_options,
                launchSettings.audience_mode,
              )}
              soundTypeLabel={getOptionLabel(
                sound_type_options,
                launchSettings.sound_type,
              )}
              hasSelection={hasSelection}
              selectedTrackIsLive={selectedTrackIsLive}
              onToggleRepeat={() =>
                setLaunchSettings((current) => ({
                  ...current,
                  repeat: !current.repeat,
                }))
              }
              onSetPlaybackMode={(value) =>
                setLaunchSettings((current) => ({
                  ...current,
                  playback_mode: value,
                }))
              }
              onPlaySelected={() => act('play_selected', launchSettings)}
              onStopBroadcast={() => act('stop_broadcast')}
            />
          </Stack.Item>
          <Stack.Item>
            <Tabs fluid>
              <Tabs.Tab
                icon="play"
                selected={activeTab === 'play'}
                onClick={() => setActiveTab('play')}
              >
                Play
              </Tabs.Tab>
              <Tabs.Tab
                icon="edit"
                selected={activeTab === 'edit'}
                onClick={() => setActiveTab('edit')}
              >
                Edit
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          <Stack.Item grow={1}>
            {activeTab === 'play' ? (
              <PlayTab
                library={library}
                librarySearch={librarySearch}
                selectedLibraryPresetId={selectedLibraryPresetId}
                onSearchChange={setLibrarySearch}
                onSelectPreset={setSelectedLibraryPresetId}
                onLoadPreset={handleLoadPreset}
                onOpenEdit={() => setActiveTab('edit')}
                draft={draft}
                dirty={dirty}
                selectedTier={selectedTier}
                selectedTierId={selected_tier_id}
                selectedVariant={selectedVariant}
                selectedVariantId={selected_variant_id}
                onSelectTier={(tier_id) => act('select_tier', { tier_id })}
                onSelectVariant={(tier_id, variant_id) =>
                  act('select_variant', { tier_id, variant_id })
                }
                launchSettings={launchSettings}
                audienceOptions={audienceOptions}
                soundTypeOptions={soundTypeOptions}
                audienceLabel={getOptionLabel(
                  audience_options,
                  launchSettings.audience_mode,
                )}
                soundTypeLabel={getOptionLabel(
                  sound_type_options,
                  launchSettings.sound_type,
                )}
                onSetAudienceMode={(value) =>
                  setLaunchSettings((current) => ({
                    ...current,
                    audience_mode: value,
                  }))
                }
                onSetSoundType={(value) =>
                  setLaunchSettings((current) => ({
                    ...current,
                    sound_type: value,
                  }))
                }
                onToggleShowTitle={() =>
                  setLaunchSettings((current) => ({
                    ...current,
                    show_title_to_players: !current.show_title_to_players,
                  }))
                }
                onResetLaunchSettings={() =>
                  setLaunchSettings(buildLaunchSettings(draft))
                }
                onPreviewSelected={() => act('preview_selected')}
                onStopPreview={stopPreview}
                isPreviewActive={isPreviewActive}
                previewState={previewState}
                previewVolume={previewVolume}
                hasSelection={hasSelection}
              />
            ) : (
              <EditTab
                draft={draft}
                draftToken={draft_token}
                dirty={dirty}
                canDelete={can_delete_saved_preset}
                audienceOptions={audienceOptions}
                soundTypeOptions={soundTypeOptions}
                audienceLabel={getOptionLabel(
                  audience_options,
                  draft.playback.audience_mode,
                )}
                soundTypeLabel={getOptionLabel(
                  sound_type_options,
                  draft.playback.sound_type,
                )}
                selectedTier={selectedTier}
                selectedTierId={selected_tier_id}
                selectedVariant={selectedVariant}
                selectedVariantId={selected_variant_id}
                onSave={() => act('save')}
                onNew={handleNewDraft}
                onSaveAsCopy={() => act('save_as_copy')}
                onDelete={() =>
                  act('delete_preset', { preset_id: draft.preset_id })
                }
                onExport={() => act('export_preset')}
                onImport={handleImport}
                onSetName={(value) => act('set_name', { name: value })}
                onSetDescription={(value) =>
                  act('set_description', { description: value })
                }
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
                onAddTier={() => act('add_tier')}
                onSelectTier={(tier_id) => act('select_tier', { tier_id })}
                onRemoveTier={(tier_id) => act('remove_tier', { tier_id })}
                onMoveTierUp={(tier_id) => act('move_tier_up', { tier_id })}
                onMoveTierDown={(tier_id) => act('move_tier_down', { tier_id })}
                onSetTierName={(tier_id, value) =>
                  act('set_tier_name', { tier_id, name: value })
                }
                onSetTierDescription={(tier_id, value) =>
                  act('set_tier_description', {
                    tier_id,
                    description: value,
                  })
                }
                onAddVariant={() => act('add_variant')}
                onSelectVariant={(tier_id, variant_id) =>
                  act('select_variant', { tier_id, variant_id })
                }
                onRemoveVariant={(tier_id, variant_id) =>
                  act('remove_variant', { tier_id, variant_id })
                }
                onMoveVariantUp={(tier_id, variant_id) =>
                  act('move_variant_up', { tier_id, variant_id })
                }
                onMoveVariantDown={(tier_id, variant_id) =>
                  act('move_variant_down', { tier_id, variant_id })
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
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
}
