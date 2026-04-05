import { useEffect, useRef, useState } from 'react';

import {
  Box,
  Button,
  Collapsible,
  Flex,
  Input,
  LabeledList,
  Section,
  Stack,
} from '../../components';
import {
  ADVANCED_TOGGLE_STYLE,
  BufferedDurationInput,
  BufferedInput,
  BufferedTextArea,
  CONTROL_BUTTON_STYLE,
  EDIT_FIELD_WRAPPER_STYLE,
  EDIT_PANEL_CARD_HEADING_STYLE,
  EDIT_PANEL_CARD_STYLE,
  FULL_WIDTH_CLAMP_STYLE,
  getCompactToggleStyle,
  getDraftStatusBadgeStyle,
  getTrackDetailBadges,
  getTrackRowStyle,
  getVariantListBadges,
  HEADER_ACTION_BUTTON_STYLE,
  INSPECTOR_ACTION_BUTTON_STYLE,
  INSPECTOR_CARD_STYLE,
  INSPECTOR_TARGET_TEXT_STYLE,
  matchesTrackSearch,
  PlaybackSettingsControls,
  RESPONSIVE_ACTION_GROUP_STYLE,
  RESPONSIVE_HEADER_ROW_STYLE,
  SECTION_SURFACE_STYLE,
  STRUCTURE_ACTION_BUTTON_STYLE,
  TRACK_LIST_SCROLL_STYLE,
  TRACK_ROW_LEFT_STYLE,
  TrackTextBlock,
} from './components';
import {
  BORDER,
  countTracks,
  DISABLED_ACTION_STYLE,
  DraftPreset,
  DraftStatus,
  DraftTier,
  DraftVariant,
  ELLIPSIS_STYLE,
  formatDuration,
  formatDurationCompact,
  formatSourceLabel,
  formatTrackCount,
  getListRowStyle,
  getToggleButtonStyle,
  LIST_SCROLL_STYLE,
  MUTED_BADGE_STYLE,
  normalizeDurationValue,
  PLAYER_BADGE_STYLE,
  PLAYER_CARD_STYLE,
  SelectOption,
  STATUS_STRIP_STYLE,
  SUBTLE_PANEL_STYLE,
  TEXT_MUTED,
} from './shared';

type InspectorTarget = 'scene' | 'track';

type EditHeaderSectionProps = Readonly<{
  draft: DraftPreset;
  draftStatus: DraftStatus;
  canRevert: boolean;
  onEditPreset: () => void;
  onSave: () => void;
  onSaveAsCopy: () => void;
  onRevert: () => void;
}>;

export function EditHeaderSection({
  draft,
  draftStatus,
  canRevert,
  onEditPreset,
  onSave,
  onSaveAsCopy,
  onRevert,
}: EditHeaderSectionProps) {
  const statusBadges: Array<{ label: string; style: Record<string, string> }> =
    [
      {
        label: `ID ${draft.preset_id || 'new'}`,
        style: PLAYER_BADGE_STYLE,
      },
      ...(draft.preset_id
        ? [
            {
              label: 'Loaded preset',
              style: MUTED_BADGE_STYLE,
            },
          ]
        : []),
      {
        label: draftStatus.label,
        style: getDraftStatusBadgeStyle(draftStatus.kind),
      },
    ];

  return (
    <Box
      px={0.9}
      py={0.42}
      style={{
        ...STATUS_STRIP_STYLE,
        border: `1px solid ${BORDER}`,
      }}
    >
      <Stack align="center">
        <Stack.Item basis="70%" grow>
          <Box bold fontSize="1.02rem" style={ELLIPSIS_STYLE}>
            {draft.name || 'New preset'}
          </Box>
          <Box color="label" fontSize="0.75rem" mt="0.12rem">
            {draftStatus.hint}
          </Box>
          <Box mt="0.22rem">
            {statusBadges.map((badge) => (
              <Box key={badge.label} mr={0.35} mb={0.2} style={badge.style}>
                {badge.label}
              </Box>
            ))}
          </Box>
        </Stack.Item>
        <Stack.Item basis="30%">
          <Stack>
            <Stack.Item>
              <Button
                icon="edit"
                color="transparent"
                style={HEADER_ACTION_BUTTON_STYLE}
                onClick={onEditPreset}
              >
                Edit Preset
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button
                icon="save"
                color="good"
                style={HEADER_ACTION_BUTTON_STYLE}
                onClick={onSave}
              >
                Save
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button
                icon="copy"
                style={HEADER_ACTION_BUTTON_STYLE}
                onClick={onSaveAsCopy}
              >
                Save As
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button
                icon="undo"
                color="transparent"
                disabled={!canRevert}
                style={{
                  ...HEADER_ACTION_BUTTON_STYLE,
                  ...(!canRevert ? DISABLED_ACTION_STYLE : {}),
                }}
                onClick={onRevert}
              >
                Revert
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
    </Box>
  );
}

type EditPanelSectionProps = Readonly<{
  draft: DraftPreset;
  draftToken: number;
  presetEditorRequest: number;
  audienceOptions: SelectOption[];
  soundTypeOptions: SelectOption[];
  audienceLabel: string;
  soundTypeLabel: string;
  inspectorTarget: InspectorTarget;
  selectedTier: DraftTier | null;
  selectedVariant: DraftVariant | null;
  canDelete: boolean;
  onNew: () => void;
  onDelete: () => void;
  onExport: () => void;
  onImport: (jsonText: string | string[]) => void;
  onSetName: (value: string) => void;
  onSetDescription: (value: string) => void;
  onSetAudienceMode: (value: string) => void;
  onSetSoundType: (value: string) => void;
  onToggleShowTitle: () => void;
  onToggleRepeat: () => void;
  onRemoveTier: (tier_id: string) => void;
  onMoveTierUp: (tier_id: string) => void;
  onMoveTierDown: (tier_id: string) => void;
  onSetTierName: (tier_id: string, value: string) => void;
  onSetTierDescription: (tier_id: string, value: string) => void;
  onRemoveVariant: (tier_id: string, variant_id: string) => void;
  onMoveVariantUp: (tier_id: string, variant_id: string) => void;
  onMoveVariantDown: (tier_id: string, variant_id: string) => void;
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
  onResolveVariantMetadata: (tier_id: string, variant_id: string) => void;
}>;

export function EditPanelSection({
  draft,
  draftToken,
  presetEditorRequest,
  audienceOptions,
  soundTypeOptions,
  audienceLabel,
  soundTypeLabel,
  inspectorTarget,
  selectedTier,
  selectedVariant,
  canDelete,
  onNew,
  onDelete,
  onExport,
  onImport,
  onSetName,
  onSetDescription,
  onSetAudienceMode,
  onSetSoundType,
  onToggleShowTitle,
  onToggleRepeat,
  onRemoveTier,
  onMoveTierUp,
  onMoveTierDown,
  onSetTierName,
  onSetTierDescription,
  onRemoveVariant,
  onMoveVariantUp,
  onMoveVariantDown,
  onSetVariantTitle,
  onSetVariantDescription,
  onSetVariantDuration,
  onSetVariantSourceUrl,
  onResolveVariantMetadata,
}: EditPanelSectionProps) {
  const [showPresetEditor, setShowPresetEditor] = useState(false);
  const presetEditorRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    setShowPresetEditor(false);
  }, [draftToken]);

  useEffect(() => {
    if (!presetEditorRequest) {
      return;
    }
    setShowPresetEditor(true);
    window.requestAnimationFrame(() => {
      presetEditorRef.current?.scrollIntoView({
        block: 'start',
        behavior: 'smooth',
      });
    });
  }, [presetEditorRequest]);

  return (
    <Section fill title="Edit Panel" style={SECTION_SURFACE_STYLE}>
      <Stack fill vertical>
        <Stack.Item grow={1}>
          <SelectedItemSection
            inspectorTarget={inspectorTarget}
            draft={draft}
            selectedTier={selectedTier}
            selectedVariant={selectedVariant}
            onRemoveTier={onRemoveTier}
            onMoveTierUp={onMoveTierUp}
            onMoveTierDown={onMoveTierDown}
            onSetTierName={onSetTierName}
            onSetTierDescription={onSetTierDescription}
            onRemoveVariant={onRemoveVariant}
            onMoveVariantUp={onMoveVariantUp}
            onMoveVariantDown={onMoveVariantDown}
            onSetVariantTitle={onSetVariantTitle}
            onSetVariantDescription={onSetVariantDescription}
            onSetVariantDuration={onSetVariantDuration}
            onSetVariantSourceUrl={onSetVariantSourceUrl}
            onResolveVariantMetadata={onResolveVariantMetadata}
          />
        </Stack.Item>
        <Stack.Item>
          <div ref={presetEditorRef}>
            <Box style={EDIT_PANEL_CARD_STYLE}>
              <Button
                fluid
                color="transparent"
                icon={showPresetEditor ? 'chevron-down' : 'chevron-right'}
                style={ADVANCED_TOGGLE_STYLE}
                onClick={() => setShowPresetEditor((current) => !current)}
              >
                Preset Settings
              </Button>
              {showPresetEditor ? (
                <Box mt={1}>
                  <PresetMetaSection
                    draft={draft}
                    draftToken={draftToken}
                    audienceOptions={audienceOptions}
                    soundTypeOptions={soundTypeOptions}
                    audienceLabel={audienceLabel}
                    soundTypeLabel={soundTypeLabel}
                    onSetName={onSetName}
                    onSetDescription={onSetDescription}
                    onSetAudienceMode={onSetAudienceMode}
                    onSetSoundType={onSetSoundType}
                    onToggleShowTitle={onToggleShowTitle}
                    onToggleRepeat={onToggleRepeat}
                    embedded
                  />
                </Box>
              ) : null}
            </Box>
          </div>
        </Stack.Item>
        <Stack.Item>
          <AdvancedSection
            canDelete={canDelete}
            onNew={onNew}
            onDelete={onDelete}
            onExport={onExport}
            onImport={onImport}
          />
        </Stack.Item>
      </Stack>
    </Section>
  );
}

type PresetMetaSectionProps = Readonly<{
  draft: DraftPreset;
  draftToken: number;
  audienceOptions: SelectOption[];
  soundTypeOptions: SelectOption[];
  audienceLabel: string;
  soundTypeLabel: string;
  onSetName: (value: string) => void;
  onSetDescription: (value: string) => void;
  onSetAudienceMode: (value: string) => void;
  onSetSoundType: (value: string) => void;
  onToggleShowTitle: () => void;
  onToggleRepeat: () => void;
  embedded?: boolean;
}>;

function PresetMetaSection({
  draft,
  draftToken,
  audienceOptions,
  soundTypeOptions,
  audienceLabel,
  soundTypeLabel,
  onSetName,
  onSetDescription,
  onSetAudienceMode,
  onSetSoundType,
  onToggleShowTitle,
  onToggleRepeat,
  embedded = false,
}: PresetMetaSectionProps) {
  const content = (
    <Stack fill vertical>
      <Stack.Item>
        <Box style={PLAYER_CARD_STYLE}>
          <Box bold fontSize="1rem" style={ELLIPSIS_STYLE}>
            {draft.name || 'New preset'}
          </Box>
          <Box mt="0.3rem">
            <Box style={PLAYER_BADGE_STYLE}>ID {draft.preset_id || 'new'}</Box>
            <Box style={PLAYER_BADGE_STYLE}>Scenes {draft.tiers.length}</Box>
            <Box style={PLAYER_BADGE_STYLE}>Tracks {countTracks(draft)}</Box>
          </Box>
        </Box>
      </Stack.Item>
      <Stack.Item>
        <LabeledList key={draftToken}>
          <LabeledList.Item label="Name">
            <Box style={EDIT_FIELD_WRAPPER_STYLE}>
              <BufferedInput
                syncKey={`preset-name:${draftToken}`}
                value={draft.name}
                onCommit={onSetName}
                placeholder="Preset name"
              />
            </Box>
          </LabeledList.Item>
          <LabeledList.Item label="Description" verticalAlign="top">
            <Box style={EDIT_FIELD_WRAPPER_STYLE}>
              <BufferedTextArea
                syncKey={draftToken}
                value={draft.description}
                onCommit={onSetDescription}
                placeholder="Short description for admins"
                minRows={3}
                maxRows={6}
              />
            </Box>
          </LabeledList.Item>
        </LabeledList>
      </Stack.Item>
      <Stack.Item grow={1}>
        <Box style={PLAYER_CARD_STYLE}>
          <Box bold>Preset Defaults</Box>
          <PlaybackSettingsControls
            playback={draft.playback}
            audienceOptions={audienceOptions}
            soundTypeOptions={soundTypeOptions}
            audienceLabel={audienceLabel}
            soundTypeLabel={soundTypeLabel}
            onSetAudienceMode={onSetAudienceMode}
            onSetSoundType={onSetSoundType}
            onToggleShowTitle={onToggleShowTitle}
            onToggleRepeat={onToggleRepeat}
            wrapToggleRow
          />
        </Box>
      </Stack.Item>
    </Stack>
  );

  if (embedded) {
    return content;
  }

  return (
    <Box style={EDIT_PANEL_CARD_STYLE}>
      <Box bold style={EDIT_PANEL_CARD_HEADING_STYLE}>
        Preset Settings
      </Box>
      {content}
    </Box>
  );
}

type AdvancedSectionProps = Readonly<{
  canDelete: boolean;
  onNew: () => void;
  onDelete: () => void;
  onExport: () => void;
  onImport: (jsonText: string | string[]) => void;
}>;

function AdvancedSection({
  canDelete,
  onNew,
  onDelete,
  onExport,
  onImport,
}: AdvancedSectionProps) {
  return (
    <Box style={EDIT_PANEL_CARD_STYLE}>
      <Collapsible
        title="Advanced"
        icon="cog"
        color="transparent"
        style={ADVANCED_TOGGLE_STYLE}
      >
        <Stack vertical>
          <Stack.Item>
            <Button compact fluid icon="plus" onClick={onNew}>
              New Draft
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button.File
              compact
              fluid
              icon="upload"
              accept=".json,application/json"
              onSelectFiles={onImport}
            >
              Import JSON
            </Button.File>
          </Stack.Item>
          <Stack.Item>
            <Button compact fluid icon="download" onClick={onExport}>
              Export Preset
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button
              compact
              fluid
              icon="trash"
              color="bad"
              disabled={!canDelete}
              style={!canDelete ? DISABLED_ACTION_STYLE : undefined}
              onClick={onDelete}
            >
              Delete Preset
            </Button>
          </Stack.Item>
        </Stack>
      </Collapsible>
    </Box>
  );
}

type StructureSectionProps = Readonly<{
  draft: DraftPreset;
  selectedTier: DraftTier | null;
  selectedTierId: string | null;
  selectedVariant: DraftVariant | null;
  selectedVariantId: string | null;
  trackSearch: string;
  denseTracks: boolean;
  tracksExpanded: boolean;
  onAddTier: () => void;
  onSelectTier: (tier_id: string) => void;
  onMoveTierUp: (tier_id: string) => void;
  onMoveTierDown: (tier_id: string) => void;
  onAddVariant: () => void;
  onTrackSearchChange: (value: string) => void;
  onToggleDenseTracks: () => void;
  onToggleTracksExpanded: () => void;
  onSelectVariant: (tier_id: string, variant_id: string) => void;
  onMoveVariantUp: (tier_id: string, variant_id: string) => void;
  onMoveVariantDown: (tier_id: string, variant_id: string) => void;
}>;

type EditTrackActionButtonsProps = Readonly<{
  selectedTier: DraftTier | null;
  selectedVariant: DraftVariant | null;
  canMoveTrackUp: boolean;
  canMoveTrackDown: boolean;
  tracksExpanded: boolean;
  onMoveVariantUp: (tier_id: string, variant_id: string) => void;
  onMoveVariantDown: (tier_id: string, variant_id: string) => void;
  onToggleTracksExpanded: () => void;
  onAddVariant: () => void;
}>;

function EditTrackActionButtons({
  selectedTier,
  selectedVariant,
  canMoveTrackUp,
  canMoveTrackDown,
  tracksExpanded,
  onMoveVariantUp,
  onMoveVariantDown,
  onToggleTracksExpanded,
  onAddVariant,
}: EditTrackActionButtonsProps) {
  return (
    <Flex wrap justify="flex-end" style={RESPONSIVE_ACTION_GROUP_STYLE}>
      {selectedTier && selectedVariant ? (
        <>
          <Flex.Item>
            <Button
              compact
              icon="arrow-up"
              color="transparent"
              disabled={!canMoveTrackUp}
              style={{
                ...STRUCTURE_ACTION_BUTTON_STYLE,
                ...(!canMoveTrackUp ? DISABLED_ACTION_STYLE : {}),
              }}
              onClick={() =>
                onMoveVariantUp(
                  selectedTier.tier_id,
                  selectedVariant.variant_id,
                )
              }
            >
              Up
            </Button>
          </Flex.Item>
          <Flex.Item>
            <Button
              compact
              icon="arrow-down"
              color="transparent"
              disabled={!canMoveTrackDown}
              style={{
                ...STRUCTURE_ACTION_BUTTON_STYLE,
                ...(!canMoveTrackDown ? DISABLED_ACTION_STYLE : {}),
              }}
              onClick={() =>
                onMoveVariantDown(
                  selectedTier.tier_id,
                  selectedVariant.variant_id,
                )
              }
            >
              Down
            </Button>
          </Flex.Item>
        </>
      ) : null}
      <Flex.Item>
        <Button.Checkbox
          compact
          checked={tracksExpanded}
          icon="list"
          style={{
            ...STRUCTURE_ACTION_BUTTON_STYLE,
            ...getToggleButtonStyle(tracksExpanded),
          }}
          onClick={onToggleTracksExpanded}
        >
          Track Details
        </Button.Checkbox>
      </Flex.Item>
      <Flex.Item>
        <Button
          compact
          icon="plus"
          disabled={!selectedTier}
          style={{
            ...STRUCTURE_ACTION_BUTTON_STYLE,
            ...(!selectedTier ? DISABLED_ACTION_STYLE : {}),
          }}
          onClick={onAddVariant}
        >
          Add Track
        </Button>
      </Flex.Item>
    </Flex>
  );
}

type EditTrackSearchToolbarProps = Readonly<{
  trackSearch: string;
  denseTracks: boolean;
  onTrackSearchChange: (value: string) => void;
  onToggleDenseTracks: () => void;
}>;

function EditTrackSearchToolbar({
  trackSearch,
  denseTracks,
  onTrackSearchChange,
  onToggleDenseTracks,
}: EditTrackSearchToolbarProps) {
  return (
    <Box mt="0.2rem">
      <Stack fill>
        <Stack.Item grow>
          <Input
            fluid
            placeholder="Search tracks..."
            value={trackSearch}
            onInput={(e, value) => onTrackSearchChange(value)}
          />
        </Stack.Item>
        <Stack.Item>
          <Button.Checkbox
            compact
            checked={denseTracks}
            style={getCompactToggleStyle(denseTracks)}
            onClick={onToggleDenseTracks}
          >
            Dense
          </Button.Checkbox>
        </Stack.Item>
      </Stack>
    </Box>
  );
}

export function StructureSection({
  draft,
  selectedTier,
  selectedTierId,
  selectedVariant,
  selectedVariantId,
  trackSearch,
  denseTracks,
  tracksExpanded,
  onAddTier,
  onSelectTier,
  onMoveTierUp,
  onMoveTierDown,
  onAddVariant,
  onTrackSearchChange,
  onToggleDenseTracks,
  onToggleTracksExpanded,
  onSelectVariant,
  onMoveVariantUp,
  onMoveVariantDown,
}: StructureSectionProps) {
  const selectedTierIndex = selectedTier
    ? draft.tiers.findIndex((tier) => tier.tier_id === selectedTier.tier_id)
    : -1;
  const canMoveSceneUp = selectedTierIndex > 0;
  const canMoveSceneDown =
    selectedTierIndex >= 0 && selectedTierIndex < draft.tiers.length - 1;
  const selectedVariantIndex =
    selectedTier && selectedVariant
      ? selectedTier.variants.findIndex(
          (variant) => variant.variant_id === selectedVariant.variant_id,
        )
      : -1;
  const canMoveTrackUp = selectedVariantIndex > 0;
  const canMoveTrackDown =
    selectedVariantIndex >= 0 &&
    selectedTier !== null &&
    selectedVariantIndex < selectedTier.variants.length - 1;
  const filteredVariants =
    selectedTier?.variants
      .map((variant, index) => ({ variant, index }))
      .filter(({ variant }) => matchesTrackSearch(variant, trackSearch)) || [];

  return (
    <Section fill title="Structure" style={SECTION_SURFACE_STYLE}>
      <Stack fill>
        <Stack.Item basis="30%" grow={3} style={{ minWidth: '0' }}>
          <Box style={{ ...SUBTLE_PANEL_STYLE, height: '100%' }}>
            <Stack fill vertical>
              <Stack.Item>
                <Flex
                  align="flex-start"
                  justify="space-between"
                  wrap
                  width="100%"
                  style={RESPONSIVE_HEADER_ROW_STYLE}
                >
                  <Flex.Item grow basis="10rem" style={{ minWidth: '0' }}>
                    <Box bold>Scenes</Box>
                  </Flex.Item>
                  <Flex.Item style={{ minWidth: '0', flex: '0 0 auto' }}>
                    <Flex
                      wrap
                      justify="flex-end"
                      style={RESPONSIVE_ACTION_GROUP_STYLE}
                    >
                      {selectedTier ? (
                        <>
                          <Flex.Item>
                            <Button
                              compact
                              icon="arrow-up"
                              color="transparent"
                              disabled={!canMoveSceneUp}
                              style={
                                !canMoveSceneUp
                                  ? DISABLED_ACTION_STYLE
                                  : undefined
                              }
                              onClick={() => onMoveTierUp(selectedTier.tier_id)}
                            >
                              Up
                            </Button>
                          </Flex.Item>
                          <Flex.Item>
                            <Button
                              compact
                              icon="arrow-down"
                              color="transparent"
                              disabled={!canMoveSceneDown}
                              style={
                                !canMoveSceneDown
                                  ? DISABLED_ACTION_STYLE
                                  : undefined
                              }
                              onClick={() =>
                                onMoveTierDown(selectedTier.tier_id)
                              }
                            >
                              Down
                            </Button>
                          </Flex.Item>
                        </>
                      ) : null}
                      <Flex.Item>
                        <Button compact icon="plus" onClick={onAddTier}>
                          Add Scene
                        </Button>
                      </Flex.Item>
                    </Flex>
                  </Flex.Item>
                </Flex>
              </Stack.Item>
              <Stack.Item grow={1}>
                <Box mt="0.35rem" style={LIST_SCROLL_STYLE}>
                  {draft.tiers.length === 0 ? (
                    <Box color="label">No scenes yet.</Box>
                  ) : (
                    draft.tiers.map((tier, index) => (
                      <Button
                        key={tier.tier_id}
                        compact
                        fluid
                        color="transparent"
                        onClick={() => onSelectTier(tier.tier_id)}
                        style={getListRowStyle(selectedTierId === tier.tier_id)}
                      >
                        <Flex
                          align="center"
                          justify="space-between"
                          width="100%"
                        >
                          <Flex.Item grow>
                            <Flex align="center">
                              <Flex.Item mr={1}>
                                <Box color="label" fontSize="0.75rem">
                                  {index + 1}.
                                </Box>
                              </Flex.Item>
                              <Flex.Item grow>
                                <Box bold style={ELLIPSIS_STYLE}>
                                  {tier.name || 'Unnamed scene'}
                                </Box>
                              </Flex.Item>
                            </Flex>
                          </Flex.Item>
                          <Flex.Item ml={1}>
                            <Box fontSize="0.75rem" color="label">
                              {formatTrackCount(tier.variants.length)}
                            </Box>
                          </Flex.Item>
                        </Flex>
                      </Button>
                    ))
                  )}
                </Box>
              </Stack.Item>
            </Stack>
          </Box>
        </Stack.Item>
        <Stack.Item basis="70%" grow={7} style={{ minWidth: '0' }}>
          <Box style={{ ...SUBTLE_PANEL_STYLE, height: '100%' }}>
            <Stack fill vertical>
              <Stack.Item>
                <Stack fill vertical>
                  <Stack.Item>
                    <Flex
                      align="flex-start"
                      justify="space-between"
                      wrap
                      width="100%"
                      style={RESPONSIVE_HEADER_ROW_STYLE}
                    >
                      <Flex.Item grow basis="14rem" style={{ minWidth: '0' }}>
                        <Box bold>Tracks</Box>
                        <Box
                          color="label"
                          fontSize="0.74rem"
                          style={ELLIPSIS_STYLE}
                        >
                          {selectedTier
                            ? `Tracks in ${selectedTier.name || 'selected scene'}.`
                            : 'Select a scene to manage its tracks.'}
                        </Box>
                        <Box color={TEXT_MUTED} fontSize="0.7rem" mt="0.06rem">
                          {tracksExpanded
                            ? 'Track Details shows source and status chips.'
                            : 'Dense keeps descriptions on one compact line. Track Details shows source and status chips.'}
                        </Box>
                      </Flex.Item>
                      <Flex.Item style={{ minWidth: '0', flex: '0 0 auto' }}>
                        <EditTrackActionButtons
                          selectedTier={selectedTier}
                          selectedVariant={selectedVariant}
                          canMoveTrackUp={canMoveTrackUp}
                          canMoveTrackDown={canMoveTrackDown}
                          tracksExpanded={tracksExpanded}
                          onMoveVariantUp={onMoveVariantUp}
                          onMoveVariantDown={onMoveVariantDown}
                          onToggleTracksExpanded={onToggleTracksExpanded}
                          onAddVariant={onAddVariant}
                        />
                      </Flex.Item>
                    </Flex>
                  </Stack.Item>
                  <Stack.Item>
                    <EditTrackSearchToolbar
                      trackSearch={trackSearch}
                      denseTracks={denseTracks}
                      onTrackSearchChange={onTrackSearchChange}
                      onToggleDenseTracks={onToggleDenseTracks}
                    />
                  </Stack.Item>
                </Stack>
              </Stack.Item>
              <Stack.Item grow={1}>
                <Box mt="0.35rem" style={TRACK_LIST_SCROLL_STYLE}>
                  {!selectedTier ? (
                    <Box color="label">No scene selected yet.</Box>
                  ) : selectedTier.variants.length === 0 ? (
                    <Box color="label">No tracks in this scene yet.</Box>
                  ) : filteredVariants.length === 0 ? (
                    <Box color="label">No tracks match search.</Box>
                  ) : (
                    filteredVariants.map(({ variant, index }) => {
                      const trackDescription = variant.description.trim();
                      const detailBadges = tracksExpanded
                        ? getTrackDetailBadges(variant)
                        : [];

                      return (
                        <Button
                          key={variant.variant_id}
                          compact
                          fluid
                          color="transparent"
                          onClick={() =>
                            onSelectVariant(
                              selectedTier.tier_id,
                              variant.variant_id,
                            )
                          }
                          style={getTrackRowStyle(
                            selectedVariantId === variant.variant_id,
                            denseTracks,
                            false,
                          )}
                        >
                          <Box style={FULL_WIDTH_CLAMP_STYLE}>
                            <Flex
                              align="center"
                              justify="space-between"
                              width="100%"
                              style={{ minWidth: '0' }}
                            >
                              <Flex.Item
                                grow
                                basis={0}
                                shrink={1}
                                style={TRACK_ROW_LEFT_STYLE}
                              >
                                <Flex
                                  align="center"
                                  width="100%"
                                  style={{ minWidth: '0' }}
                                >
                                  <Flex.Item mr={1}>
                                    <Box color="label" fontSize="0.75rem">
                                      {index + 1}.
                                    </Box>
                                  </Flex.Item>
                                  <Flex.Item
                                    grow
                                    basis={0}
                                    shrink={1}
                                    style={TRACK_ROW_LEFT_STYLE}
                                  >
                                    <TrackTextBlock
                                      title={variant.title || 'Unnamed track'}
                                      description={trackDescription}
                                      dense={denseTracks}
                                    />
                                    {detailBadges.length ? (
                                      <Box mt="0.1rem">
                                        {detailBadges.map((badge) => (
                                          <Box
                                            key={badge.label}
                                            style={badge.style}
                                          >
                                            {badge.label}
                                          </Box>
                                        ))}
                                      </Box>
                                    ) : null}
                                  </Flex.Item>
                                </Flex>
                              </Flex.Item>
                              <Flex.Item ml={1} shrink={0} width="3.6rem">
                                <Box
                                  fontSize="0.75rem"
                                  color="label"
                                  textAlign="right"
                                >
                                  {formatDurationCompact(
                                    variant.duration_seconds,
                                  )}
                                </Box>
                              </Flex.Item>
                            </Flex>
                          </Box>
                        </Button>
                      );
                    })
                  )}
                </Box>
              </Stack.Item>
            </Stack>
          </Box>
        </Stack.Item>
      </Stack>
    </Section>
  );
}

type SelectedItemSectionProps = Readonly<{
  inspectorTarget: InspectorTarget;
  draft: DraftPreset;
  selectedTier: DraftTier | null;
  selectedVariant: DraftVariant | null;
  onRemoveTier: (tier_id: string) => void;
  onMoveTierUp: (tier_id: string) => void;
  onMoveTierDown: (tier_id: string) => void;
  onSetTierName: (tier_id: string, value: string) => void;
  onSetTierDescription: (tier_id: string, value: string) => void;
  onRemoveVariant: (tier_id: string, variant_id: string) => void;
  onMoveVariantUp: (tier_id: string, variant_id: string) => void;
  onMoveVariantDown: (tier_id: string, variant_id: string) => void;
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
  onResolveVariantMetadata: (tier_id: string, variant_id: string) => void;
}>;

function SelectedItemSection({
  inspectorTarget,
  draft,
  selectedTier,
  selectedVariant,
  onRemoveTier,
  onMoveTierUp,
  onMoveTierDown,
  onSetTierName,
  onSetTierDescription,
  onRemoveVariant,
  onMoveVariantUp,
  onMoveVariantDown,
  onSetVariantTitle,
  onSetVariantDescription,
  onSetVariantDuration,
  onSetVariantSourceUrl,
  onResolveVariantMetadata,
}: SelectedItemSectionProps) {
  const showTrackInspector =
    inspectorTarget === 'track' && Boolean(selectedTier && selectedVariant);

  return (
    <Box
      style={{
        ...EDIT_PANEL_CARD_STYLE,
        height: '100%',
        minWidth: '0',
        overflow: 'hidden',
      }}
    >
      <Flex
        align="flex-start"
        justify="space-between"
        wrap
        width="100%"
        style={RESPONSIVE_HEADER_ROW_STYLE}
      >
        <Flex.Item grow basis="12rem" style={{ minWidth: '0' }}>
          <Box bold style={EDIT_PANEL_CARD_HEADING_STYLE}>
            Selected Item
          </Box>
          <Box color={TEXT_MUTED} fontSize="0.74rem" mb="0.34rem">
            Follows the current selection in Structure.
          </Box>
        </Flex.Item>
        {selectedTier ? (
          <Flex.Item style={{ minWidth: '0', flex: '0 0 auto' }}>
            <Box style={INSPECTOR_TARGET_TEXT_STYLE}>
              {showTrackInspector ? 'Track' : 'Scene'}
            </Box>
          </Flex.Item>
        ) : null}
      </Flex>
      {!selectedTier ? (
        <Box color="label">
          Select a scene or track in Structure to inspect it.
        </Box>
      ) : showTrackInspector ? (
        <TrackInspectorSection
          selectedTier={selectedTier}
          selectedVariant={selectedVariant}
          onRemoveVariant={onRemoveVariant}
          onMoveVariantUp={onMoveVariantUp}
          onMoveVariantDown={onMoveVariantDown}
          onSetVariantTitle={onSetVariantTitle}
          onSetVariantDescription={onSetVariantDescription}
          onSetVariantDuration={onSetVariantDuration}
          onSetVariantSourceUrl={onSetVariantSourceUrl}
          onResolveVariantMetadata={onResolveVariantMetadata}
        />
      ) : (
        <SceneInspectorSection
          draft={draft}
          selectedTier={selectedTier}
          onRemoveTier={onRemoveTier}
          onMoveTierUp={onMoveTierUp}
          onMoveTierDown={onMoveTierDown}
          onSetTierName={onSetTierName}
          onSetTierDescription={onSetTierDescription}
        />
      )}
    </Box>
  );
}

type SceneInspectorSectionProps = Readonly<{
  draft: DraftPreset;
  selectedTier: DraftTier;
  onRemoveTier: (tier_id: string) => void;
  onMoveTierUp: (tier_id: string) => void;
  onMoveTierDown: (tier_id: string) => void;
  onSetTierName: (tier_id: string, value: string) => void;
  onSetTierDescription: (tier_id: string, value: string) => void;
}>;

function SceneInspectorSection({
  draft,
  selectedTier,
  onRemoveTier,
  onMoveTierUp,
  onMoveTierDown,
  onSetTierName,
  onSetTierDescription,
}: SceneInspectorSectionProps) {
  const selectedTierIndex = draft.tiers.findIndex(
    (tier) => tier.tier_id === selectedTier.tier_id,
  );
  const canDeleteScene = draft.tiers.length > 1;
  const canMoveSceneUp = selectedTierIndex > 0;
  const canMoveSceneDown = selectedTierIndex < draft.tiers.length - 1;

  return (
    <Stack fill vertical key={selectedTier.tier_id}>
      <Stack.Item>
        <Box style={INSPECTOR_CARD_STYLE}>
          <Box bold fontSize="1rem" style={ELLIPSIS_STYLE}>
            {selectedTier.name || 'Unnamed scene'}
          </Box>
          <Box color="label" fontSize="0.8rem" style={ELLIPSIS_STYLE}>
            {selectedTier.description || 'No description yet'}
          </Box>
          <Box mt="0.25rem">
            <Box style={PLAYER_BADGE_STYLE}>
              Order {selectedTierIndex + 1} of {draft.tiers.length}
            </Box>
            <Box style={PLAYER_BADGE_STYLE}>
              {formatTrackCount(selectedTier.variants.length)}
            </Box>
          </Box>
        </Box>
      </Stack.Item>
      <Stack.Item>
        <Flex
          align="flex-start"
          justify="space-between"
          wrap
          width="100%"
          style={RESPONSIVE_HEADER_ROW_STYLE}
        >
          <Flex.Item grow basis="12rem" style={{ minWidth: '0' }}>
            <Box bold>Scene Properties</Box>
          </Flex.Item>
          <Flex.Item style={{ minWidth: '0', flex: '0 0 auto' }}>
            <Flex wrap justify="flex-end" style={RESPONSIVE_ACTION_GROUP_STYLE}>
              <Flex.Item>
                <Button
                  compact
                  icon="arrow-up"
                  color="transparent"
                  disabled={!canMoveSceneUp}
                  style={{
                    ...INSPECTOR_ACTION_BUTTON_STYLE,
                    ...(!canMoveSceneUp ? DISABLED_ACTION_STYLE : {}),
                  }}
                  onClick={() => onMoveTierUp(selectedTier.tier_id)}
                >
                  Move Up
                </Button>
              </Flex.Item>
              <Flex.Item>
                <Button
                  compact
                  icon="arrow-down"
                  color="transparent"
                  disabled={!canMoveSceneDown}
                  style={{
                    ...INSPECTOR_ACTION_BUTTON_STYLE,
                    ...(!canMoveSceneDown ? DISABLED_ACTION_STYLE : {}),
                  }}
                  onClick={() => onMoveTierDown(selectedTier.tier_id)}
                >
                  Move Down
                </Button>
              </Flex.Item>
              <Flex.Item>
                <Button.Confirm
                  compact
                  icon="trash"
                  color="transparent"
                  disabled={!canDeleteScene}
                  style={{
                    ...INSPECTOR_ACTION_BUTTON_STYLE,
                    ...(!canDeleteScene ? DISABLED_ACTION_STYLE : {}),
                  }}
                  confirmColor="bad"
                  confirmIcon="trash"
                  confirmContent="Delete?"
                  onClick={() => onRemoveTier(selectedTier.tier_id)}
                >
                  Delete
                </Button.Confirm>
              </Flex.Item>
            </Flex>
          </Flex.Item>
        </Flex>
      </Stack.Item>
      <Stack.Item grow={1}>
        <LabeledList>
          <LabeledList.Item label="Name">
            <Box style={EDIT_FIELD_WRAPPER_STYLE}>
              <BufferedInput
                syncKey={`${selectedTier.tier_id}:name`}
                value={selectedTier.name}
                onCommit={(value) => onSetTierName(selectedTier.tier_id, value)}
                placeholder="Scene name"
              />
            </Box>
          </LabeledList.Item>
          <LabeledList.Item label="Description" verticalAlign="top">
            <Box style={EDIT_FIELD_WRAPPER_STYLE}>
              <BufferedTextArea
                syncKey={selectedTier.tier_id}
                value={selectedTier.description}
                onCommit={(value) =>
                  onSetTierDescription(selectedTier.tier_id, value)
                }
                placeholder="Scene description"
                minRows={4}
                maxRows={8}
              />
            </Box>
          </LabeledList.Item>
        </LabeledList>
      </Stack.Item>
    </Stack>
  );
}

type TrackInspectorSectionProps = Readonly<{
  selectedTier: DraftTier;
  selectedVariant: DraftVariant | null;
  onRemoveVariant: (tier_id: string, variant_id: string) => void;
  onMoveVariantUp: (tier_id: string, variant_id: string) => void;
  onMoveVariantDown: (tier_id: string, variant_id: string) => void;
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
  onResolveVariantMetadata: (tier_id: string, variant_id: string) => void;
}>;

function TrackInspectorSection({
  selectedTier,
  selectedVariant,
  onRemoveVariant,
  onMoveVariantUp,
  onMoveVariantDown,
  onSetVariantTitle,
  onSetVariantDescription,
  onSetVariantDuration,
  onSetVariantSourceUrl,
  onResolveVariantMetadata,
}: TrackInspectorSectionProps) {
  if (!selectedVariant) {
    return <Box color="label">Select a track in Structure to inspect it.</Box>;
  }

  const selectedVariantIndex = selectedTier.variants.findIndex(
    (variant) => variant.variant_id === selectedVariant.variant_id,
  );
  const canDeleteTrack = selectedTier.variants.length > 1;
  const canMoveTrackUp = selectedVariantIndex > 0;
  const canMoveTrackDown =
    selectedVariantIndex < selectedTier.variants.length - 1;
  const normalizedDuration = normalizeDurationValue(
    selectedVariant.duration_seconds,
  );
  const sourceLabel = selectedVariant.source_url.trim()
    ? formatSourceLabel(selectedVariant.source_url)
    : 'Not set';

  return (
    <Stack fill vertical key={selectedVariant.variant_id}>
      <Stack.Item>
        <Box style={INSPECTOR_CARD_STYLE}>
          <Box bold fontSize="1rem" style={ELLIPSIS_STYLE}>
            {selectedVariant.title || 'Unnamed track'}
          </Box>
          <Box color="label" fontSize="0.8rem" style={ELLIPSIS_STYLE}>
            {selectedVariant.description || 'No description yet'}
          </Box>
          <Box mt="0.25rem">
            <Box style={PLAYER_BADGE_STYLE}>
              Order {selectedVariantIndex + 1} of {selectedTier.variants.length}
            </Box>
            <Box style={PLAYER_BADGE_STYLE}>
              {formatDuration(selectedVariant.duration_seconds)}
            </Box>
            <Box style={PLAYER_BADGE_STYLE}>{sourceLabel}</Box>
          </Box>
          {getVariantListBadges(selectedVariant).length ? (
            <Box mt="0.12rem">
              {getVariantListBadges(selectedVariant).map((badge) => (
                <Box key={badge.label} style={badge.style}>
                  {badge.label}
                </Box>
              ))}
            </Box>
          ) : null}
        </Box>
      </Stack.Item>
      <Stack.Item>
        <Flex
          align="flex-start"
          justify="space-between"
          wrap
          width="100%"
          style={RESPONSIVE_HEADER_ROW_STYLE}
        >
          <Flex.Item grow basis="12rem" style={{ minWidth: '0' }}>
            <Box bold>Track Properties</Box>
          </Flex.Item>
          <Flex.Item style={{ minWidth: '0', flex: '0 0 auto' }}>
            <Flex wrap justify="flex-end" style={RESPONSIVE_ACTION_GROUP_STYLE}>
              <Flex.Item>
                <Button
                  compact
                  icon="arrow-up"
                  color="transparent"
                  disabled={!canMoveTrackUp}
                  style={{
                    ...INSPECTOR_ACTION_BUTTON_STYLE,
                    ...(!canMoveTrackUp ? DISABLED_ACTION_STYLE : {}),
                  }}
                  onClick={() =>
                    onMoveVariantUp(
                      selectedTier.tier_id,
                      selectedVariant.variant_id,
                    )
                  }
                >
                  Move Up
                </Button>
              </Flex.Item>
              <Flex.Item>
                <Button
                  compact
                  icon="arrow-down"
                  color="transparent"
                  disabled={!canMoveTrackDown}
                  style={{
                    ...INSPECTOR_ACTION_BUTTON_STYLE,
                    ...(!canMoveTrackDown ? DISABLED_ACTION_STYLE : {}),
                  }}
                  onClick={() =>
                    onMoveVariantDown(
                      selectedTier.tier_id,
                      selectedVariant.variant_id,
                    )
                  }
                >
                  Move Down
                </Button>
              </Flex.Item>
              <Flex.Item>
                <Button.Confirm
                  compact
                  icon="trash"
                  color="transparent"
                  disabled={!canDeleteTrack}
                  style={{
                    ...INSPECTOR_ACTION_BUTTON_STYLE,
                    ...(!canDeleteTrack ? DISABLED_ACTION_STYLE : {}),
                  }}
                  confirmColor="bad"
                  confirmIcon="trash"
                  confirmContent="Delete?"
                  onClick={() =>
                    onRemoveVariant(
                      selectedTier.tier_id,
                      selectedVariant.variant_id,
                    )
                  }
                >
                  Delete
                </Button.Confirm>
              </Flex.Item>
            </Flex>
          </Flex.Item>
        </Flex>
      </Stack.Item>
      <Stack.Item grow={1}>
        <LabeledList>
          <LabeledList.Item label="Title">
            <Box style={EDIT_FIELD_WRAPPER_STYLE}>
              <BufferedInput
                syncKey={selectedVariant.variant_id}
                value={selectedVariant.title}
                onCommit={(value) =>
                  onSetVariantTitle(
                    selectedTier.tier_id,
                    selectedVariant.variant_id,
                    value,
                  )
                }
                placeholder="Track title"
              />
            </Box>
          </LabeledList.Item>
          <LabeledList.Item label="Description" verticalAlign="top">
            <Box style={EDIT_FIELD_WRAPPER_STYLE}>
              <BufferedTextArea
                syncKey={selectedVariant.variant_id}
                value={selectedVariant.description}
                onCommit={(value) =>
                  onSetVariantDescription(
                    selectedTier.tier_id,
                    selectedVariant.variant_id,
                    value,
                  )
                }
                placeholder="Track description"
                minRows={4}
                maxRows={8}
              />
            </Box>
          </LabeledList.Item>
          <LabeledList.Item label="Duration">
            <Box style={EDIT_FIELD_WRAPPER_STYLE}>
              <Flex align="center" width="100%" style={{ gap: '0.35rem' }}>
                <Flex.Item
                  shrink={0}
                  basis="6.5rem"
                  style={{ minWidth: '6.5rem', maxWidth: '6.5rem' }}
                >
                  <BufferedDurationInput
                    syncKey={`${selectedVariant.variant_id}:duration`}
                    value={normalizedDuration}
                    onCommit={(value) =>
                      onSetVariantDuration(
                        selectedTier.tier_id,
                        selectedVariant.variant_id,
                        value,
                      )
                    }
                  />
                </Flex.Item>
                <Flex.Item grow basis={0} style={{ minWidth: '0' }}>
                  <Button
                    compact
                    fluid
                    className="AdminMusicPanel__centeredButton"
                    icon="sync"
                    color="transparent"
                    disabled={!selectedVariant.source_url.trim()}
                    style={CONTROL_BUTTON_STYLE}
                    onClick={() =>
                      onResolveVariantMetadata(
                        selectedTier.tier_id,
                        selectedVariant.variant_id,
                      )
                    }
                  >
                    Resolve metadata
                  </Button>
                </Flex.Item>
              </Flex>
              {!normalizedDuration ? (
                <Box color="label" fontSize="0.75rem" mt="0.2rem">
                  Use seconds or timecode (mm:ss or hh:mm:ss). Unknown duration
                  is allowed, but Single mode may not stop automatically.
                </Box>
              ) : null}
            </Box>
          </LabeledList.Item>
          <LabeledList.Item label="Source URL">
            <Box style={EDIT_FIELD_WRAPPER_STYLE}>
              <BufferedInput
                syncKey={`${selectedVariant.variant_id}:source`}
                value={selectedVariant.source_url}
                onCommit={(value) =>
                  onSetVariantSourceUrl(
                    selectedTier.tier_id,
                    selectedVariant.variant_id,
                    value,
                  )
                }
                placeholder="https://..."
                monospace
              />
              {!selectedVariant.source_url.trim() ? (
                <Box color="label" fontSize="0.75rem" mt="0.2rem">
                  Required for preview and broadcast.
                </Box>
              ) : null}
            </Box>
          </LabeledList.Item>
        </LabeledList>
      </Stack.Item>
    </Stack>
  );
}
