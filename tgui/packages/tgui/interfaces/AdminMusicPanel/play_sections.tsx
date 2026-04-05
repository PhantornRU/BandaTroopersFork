import { useRef } from 'react';

import { Box, Button, Flex, Input, Section, Stack } from '../../components';
import {
  CONTROL_BUTTON_STYLE,
  FocusLaunchFactsColumn,
  FULL_WIDTH_CLAMP_STYLE,
  getCompactToggleStyle,
  getLaunchContextFactBadges,
  getLibraryRowStyle,
  getPreviewActionStyle,
  getSegmentedButtonStyle,
  getStopActionStyle,
  getSubtleCompactToggleStyle,
  getTertiaryActionStyle,
  getTrackRowStyle,
  getVariantListBadges,
  LaunchFactsRow,
  LaunchStatusSummary,
  matchesTrackSearch,
  OPERATOR_STATUS_PANEL_STYLE,
  PLAY_CONTROLS_ROW_STYLE,
  PLAY_TOOLBAR_TOGGLE_STYLE,
  PlaybackSettingsControls,
  SECTION_SURFACE_STYLE,
  SEGMENTED_GROUP_STYLE,
  TRACK_LIST_SCROLL_STYLE,
  TRACK_ROW_LEFT_STYLE,
  TrackFactBadges,
  TRACKS_FILTER_BAR_STYLE,
  TrackTextBlock,
} from './components';
import {
  ACCENT_SUCCESS,
  BG_PANEL,
  BG_PANEL_ALT,
  CurrentSession,
  DISABLED_ACTION_STYLE,
  DraftPreset,
  DraftTier,
  DraftVariant,
  ELLIPSIS_STYLE,
  findCurrentSessionVariantInTier,
  formatAfterTrackEnds,
  formatDuration,
  formatDurationCompact,
  formatElapsedCompact,
  formatSourceLabel,
  formatTrackCount,
  getListRowStyle,
  isCurrentSessionForVariant,
  isVariantDurationUnknown,
  isVariantMissingSource,
  LaunchSettings,
  LibraryPreset,
  LIST_SCROLL_STYLE,
  LIVE_BADGE_STYLE,
  MUTED_BADGE_STYLE,
  normalizeDurationValue,
  PlaybackMode,
  SelectOption,
  STATUS_STRIP_STYLE,
  TEXT_MUTED,
  TEXT_SECONDARY,
  TrackLaunchReadiness,
  UNSAVED_BADGE_STYLE,
  useBroadcastElapsed,
} from './shared';

type CompactFactItem = Readonly<{
  label: string;
  value: string;
}>;

type BroadcastStatusStripProps = Readonly<{
  current_session: CurrentSession;
  onStopBroadcast: () => void;
  showStopButton?: boolean;
}>;

export function BroadcastStatusStrip({
  current_session,
  onStopBroadcast,
  showStopButton = true,
}: BroadcastStatusStripProps) {
  const broadcastElapsedSeconds = useBroadcastElapsed(current_session);

  if (!current_session) {
    return (
      <Box
        px={0.8}
        py={0.38}
        style={{
          ...STATUS_STRIP_STYLE,
          border: '1px solid rgba(51, 69, 87, 0.72)',
          backgroundColor: BG_PANEL,
        }}
      >
        <Stack align="center">
          <Stack.Item>
            <Box
              color={TEXT_SECONDARY}
              fontSize="0.84rem"
              style={{ fontWeight: '600' }}
            >
              Broadcast idle
            </Box>
          </Stack.Item>
          <Stack.Item grow>
            <Box color={TEXT_MUTED} fontSize="0.76rem">
              No live broadcast. Open Play to preview or broadcast a track.
            </Box>
          </Stack.Item>
        </Stack>
      </Box>
    );
  }

  const broadcastTitle =
    current_session.variant_title ||
    current_session.resolved_title ||
    'Untitled broadcast';
  const liveBehavior = formatAfterTrackEnds(
    Boolean(current_session.loop),
    current_session.playback_mode,
  );
  const broadcastPath = [current_session.preset_name, current_session.tier_name]
    .filter(Boolean)
    .join(' / ');
  const totalDurationSeconds = normalizeDurationValue(
    current_session.duration_seconds || 0,
  );
  const playbackProgressText = totalDurationSeconds
    ? `${formatElapsedCompact(broadcastElapsedSeconds)} / ${formatElapsedCompact(totalDurationSeconds)}`
    : `${formatElapsedCompact(broadcastElapsedSeconds)} / End unknown`;
  const liveFacts: CompactFactItem[] = [
    {
      label: 'Playing',
      value: playbackProgressText,
    },
    {
      label: 'Path',
      value: broadcastPath || 'Legacy broadcast session',
    },
    {
      label: 'Length',
      value: formatDuration(current_session.duration_seconds || 0),
    },
    {
      label: 'Title',
      value: current_session.show_title_to_players ? 'Visible' : 'Hidden',
    },
    {
      label: 'Source',
      value: formatSourceLabel(current_session.source_url),
    },
  ];
  if (totalDurationSeconds > 0 && !current_session.has_known_end_time) {
    liveFacts.push({
      label: 'End',
      value: 'Unknown',
    });
  }

  return (
    <Box
      px={0.85}
      py={0.55}
      style={{
        ...STATUS_STRIP_STYLE,
        border: `1px solid ${ACCENT_SUCCESS}`,
        backgroundColor: BG_PANEL_ALT,
      }}
    >
      <Stack align="center">
        <Stack.Item grow>
          <Box color="label" fontSize="0.72rem">
            On air
          </Box>
          <Box bold style={ELLIPSIS_STYLE}>
            {broadcastTitle}
          </Box>
          <Box color="label" fontSize="0.75rem" style={ELLIPSIS_STYLE}>
            Audience {current_session.audience_label} | Sound Type{' '}
            {current_session.sound_type_label} | {liveBehavior}
          </Box>
          <Box mt="0.3rem">
            <TrackFactBadges items={liveFacts} />
          </Box>
        </Stack.Item>
        {showStopButton ? (
          <Stack.Item>
            <Button compact icon="stop" color="bad" onClick={onStopBroadcast}>
              Stop Broadcast
            </Button>
          </Stack.Item>
        ) : null}
      </Stack>
    </Box>
  );
}

type OperatorActionPanelProps = Readonly<{
  launchSettings: LaunchSettings;
  trackReadiness: TrackLaunchReadiness;
  isPreviewActive: boolean;
  selectedTrackIsLive: boolean;
  hasCurrentSession: boolean;
  onToggleRepeat: () => void;
  onSetPlaybackMode: (value: PlaybackMode) => void;
  onPreviewSelected: () => void;
  onStopPreview: () => void;
  onPlaySelected: () => void;
  onStopBroadcast: () => void;
  onResetLaunchSettings: () => void;
}>;

function OperatorActionPanel({
  launchSettings,
  trackReadiness,
  isPreviewActive,
  selectedTrackIsLive,
  hasCurrentSession,
  onToggleRepeat,
  onSetPlaybackMode,
  onPreviewSelected,
  onStopPreview,
  onPlaySelected,
  onStopBroadcast,
  onResetLaunchSettings,
}: OperatorActionPanelProps) {
  const previewDisabled = !isPreviewActive && !trackReadiness.canPreview;
  const broadcastDisabled = !trackReadiness.canBroadcast;
  const previewLabel = isPreviewActive ? 'Stop Preview' : 'Preview';
  const previewIcon = isPreviewActive ? 'stop' : 'eye';
  const broadcastLabel = selectedTrackIsLive
    ? 'Restart Broadcast'
    : 'Broadcast';

  return (
    <Section fill title="Operator Controls" style={SECTION_SURFACE_STYLE}>
      <Box mt="0.12rem">
        <Stack fill>
          <Stack.Item grow>
            <Button
              compact
              fluid
              className="AdminMusicPanel__centeredButton"
              style={{
                ...CONTROL_BUTTON_STYLE,
              }}
              icon="play"
              color="good"
              disabled={broadcastDisabled}
              onClick={onPlaySelected}
            >
              {broadcastLabel}
            </Button>
          </Stack.Item>
          <Stack.Item grow>
            <Button
              compact
              fluid
              className="AdminMusicPanel__centeredButton"
              icon="stop"
              color="transparent"
              disabled={!hasCurrentSession}
              style={{
                ...getStopActionStyle(!hasCurrentSession),
                ...CONTROL_BUTTON_STYLE,
              }}
              onClick={onStopBroadcast}
            >
              Stop
            </Button>
          </Stack.Item>
        </Stack>
      </Box>
      <Box mt="0.16rem">
        <Stack fill>
          <Stack.Item grow>
            <Button
              compact
              fluid
              className="AdminMusicPanel__centeredButton"
              color="transparent"
              icon={previewIcon}
              disabled={previewDisabled}
              style={{
                ...getPreviewActionStyle(isPreviewActive, previewDisabled),
                ...CONTROL_BUTTON_STYLE,
              }}
              onClick={isPreviewActive ? onStopPreview : onPreviewSelected}
            >
              {previewLabel}
            </Button>
          </Stack.Item>
          <Stack.Item grow>
            <Button
              compact
              fluid
              className="AdminMusicPanel__centeredButton"
              color="transparent"
              icon="undo"
              style={{
                ...getTertiaryActionStyle(),
                ...CONTROL_BUTTON_STYLE,
              }}
              onClick={onResetLaunchSettings}
            >
              Reset
            </Button>
          </Stack.Item>
        </Stack>
      </Box>
      <Box mt="0.28rem" style={OPERATOR_STATUS_PANEL_STYLE}>
        <LaunchPreflightControls
          launchSettings={launchSettings}
          onToggleRepeat={onToggleRepeat}
          onSetPlaybackMode={onSetPlaybackMode}
        />
      </Box>
    </Section>
  );
}

type LaunchPreflightControlsProps = Readonly<{
  launchSettings: LaunchSettings;
  onToggleRepeat: () => void;
  onSetPlaybackMode: (value: PlaybackMode) => void;
  subtle?: boolean;
}>;

function LaunchPreflightControls({
  launchSettings,
  onToggleRepeat,
  onSetPlaybackMode,
  subtle = false,
}: LaunchPreflightControlsProps) {
  return (
    <Stack fill>
      <Stack.Item basis="12.25rem" grow={0}>
        <Button.Checkbox
          compact
          fluid
          className="AdminMusicPanel__centeredButton"
          checked={launchSettings.repeat}
          style={
            subtle
              ? {
                  ...getSubtleCompactToggleStyle(launchSettings.repeat),
                  width: '100%',
                  minHeight: '2rem',
                  textAlign: 'center',
                }
              : PLAY_TOOLBAR_TOGGLE_STYLE(launchSettings.repeat)
          }
          onClick={onToggleRepeat}
        >
          Repeat current track
        </Button.Checkbox>
      </Stack.Item>
      <Stack.Item basis={0} grow={1}>
        <PlaybackModeSelector
          playbackMode={launchSettings.playback_mode}
          repeat={launchSettings.repeat}
          subtle={subtle}
          onSetPlaybackMode={onSetPlaybackMode}
        />
      </Stack.Item>
    </Stack>
  );
}

type SessionSectionProps = Readonly<{
  current_session: CurrentSession;
  launchSettings: LaunchSettings;
  draft: DraftPreset;
  audienceOptions: SelectOption[];
  soundTypeOptions: SelectOption[];
  audienceLabel: string;
  soundTypeLabel: string;
  selectedTier: DraftTier | null;
  selectedVariant: DraftVariant | null;
  trackReadiness: TrackLaunchReadiness;
  selectedTrackIsLive: boolean;
  onSetAudienceMode: (value: string) => void;
  onSetSoundType: (value: string) => void;
  onToggleRepeat: () => void;
  onSetPlaybackMode: (value: PlaybackMode) => void;
  onResetLaunchSettings: () => void;
  onPreviewSelected: () => void;
  onStopPreview: () => void;
  isPreviewActive: boolean;
  previewState: string;
  onOpenEdit: () => void;
  onPlaySelected: () => void;
  onStopBroadcast: () => void;
}>;

export function SessionSection({
  current_session,
  launchSettings,
  draft,
  audienceOptions,
  soundTypeOptions,
  audienceLabel,
  soundTypeLabel,
  selectedTier,
  selectedVariant,
  trackReadiness,
  selectedTrackIsLive,
  onSetAudienceMode,
  onSetSoundType,
  onToggleRepeat,
  onSetPlaybackMode,
  onResetLaunchSettings,
  onPreviewSelected,
  onStopPreview,
  isPreviewActive,
  previewState,
  onOpenEdit,
  onPlaySelected,
  onStopBroadcast,
}: SessionSectionProps) {
  const contextTitle = selectedVariant?.title || 'No track selected';
  const launchStateText = selectedTrackIsLive
    ? 'Live'
    : trackReadiness.reason
      ? 'Blocked'
      : 'Ready to broadcast';
  const previewStateText = isPreviewActive ? 'Preview playing' : previewState;
  const contextFacts: CompactFactItem[] = [
    {
      label: 'Preset',
      value: draft.name || 'New preset',
    },
    {
      label: 'Scene',
      value: selectedTier?.name || 'None',
    },
    {
      label: 'Duration',
      value: selectedVariant
        ? formatDuration(selectedVariant.duration_seconds)
        : 'Unknown',
    },
    {
      label: 'Source',
      value: selectedVariant?.source_url?.trim()
        ? formatSourceLabel(selectedVariant.source_url)
        : 'Not set',
    },
  ];
  const contextBadges = getLaunchContextFactBadges(contextFacts);

  return (
    <Stack fill align="stretch">
      <Stack.Item basis="68%" grow={1}>
        <Section
          fill
          title="Launch Context"
          style={SECTION_SURFACE_STYLE}
          buttons={
            trackReadiness.reason ? (
              <Button
                compact
                icon="edit"
                color="transparent"
                onClick={onOpenEdit}
              >
                Fix in Edit
              </Button>
            ) : undefined
          }
        >
          <Flex align="center" justify="space-between" width="100%" mt={0.12}>
            <Flex.Item grow>
              <Box as="span" bold fontSize="1rem" style={ELLIPSIS_STYLE}>
                {contextTitle}
              </Box>
            </Flex.Item>
            {selectedTrackIsLive ? (
              <Flex.Item ml={1}>
                <Box style={LIVE_BADGE_STYLE}>On air</Box>
              </Flex.Item>
            ) : null}
          </Flex>
          <LaunchFactsRow facts={contextBadges} />
          <Box mt="0.14rem">
            <LaunchStatusSummary
              launchStateText={launchStateText}
              previewStateText={previewStateText}
              trackReadiness={trackReadiness}
            />
          </Box>
          <Box mt="0.18rem">
            <Flex width="100%" style={PLAY_CONTROLS_ROW_STYLE}>
              <Flex.Item
                grow
                basis="22rem"
                style={{ minWidth: '14rem', flex: '1 1 22rem' }}
              >
                <PlaybackSettingsControls
                  playback={launchSettings}
                  audienceOptions={audienceOptions}
                  soundTypeOptions={soundTypeOptions}
                  audienceLabel={audienceLabel}
                  soundTypeLabel={soundTypeLabel}
                  onSetAudienceMode={onSetAudienceMode}
                  onSetSoundType={onSetSoundType}
                  onToggleShowTitle={() => null}
                  showVisibilityToggle={false}
                  showRepeatToggle={false}
                  inlineDropdownLabels
                />
              </Flex.Item>
            </Flex>
          </Box>
        </Section>
      </Stack.Item>
      <Stack.Item basis="32%" grow={1}>
        <OperatorActionPanel
          launchSettings={launchSettings}
          trackReadiness={trackReadiness}
          isPreviewActive={isPreviewActive}
          selectedTrackIsLive={selectedTrackIsLive}
          hasCurrentSession={Boolean(current_session)}
          onToggleRepeat={onToggleRepeat}
          onSetPlaybackMode={onSetPlaybackMode}
          onPreviewSelected={onPreviewSelected}
          onStopPreview={onStopPreview}
          onPlaySelected={onPlaySelected}
          onStopBroadcast={onStopBroadcast}
          onResetLaunchSettings={onResetLaunchSettings}
        />
      </Stack.Item>
    </Stack>
  );
}

type PlaybackModeSelectorProps = Readonly<{
  playbackMode: PlaybackMode;
  repeat: boolean;
  onSetPlaybackMode: (value: PlaybackMode) => void;
  subtle?: boolean;
}>;

function PlaybackModeSelector({
  playbackMode,
  repeat,
  onSetPlaybackMode,
  subtle = false,
}: PlaybackModeSelectorProps) {
  const options: Array<{
    label: string;
    value: PlaybackMode;
  }> = [
    { label: 'Single', value: 'single' },
    { label: 'In order', value: 'ordered' },
    { label: 'Random', value: 'random' },
  ];

  return (
    <Box style={SEGMENTED_GROUP_STYLE}>
      {options.map((option) => (
        <Box key={option.value} mr={0} style={{ flex: '1 1 0', minWidth: '0' }}>
          <Button
            compact
            fluid
            className="AdminMusicPanel__centeredButton"
            color="transparent"
            selected={playbackMode === option.value}
            disabled={repeat}
            style={getSegmentedButtonStyle(
              playbackMode === option.value,
              repeat,
              subtle,
            )}
            onClick={() => onSetPlaybackMode(option.value)}
          >
            {option.label}
          </Button>
        </Box>
      ))}
    </Box>
  );
}

type TracksFocusLaunchStripProps = Readonly<{
  current_session: CurrentSession;
  draft: DraftPreset;
  launchSettings: LaunchSettings;
  audienceOptions: SelectOption[];
  soundTypeOptions: SelectOption[];
  audienceLabel: string;
  soundTypeLabel: string;
  selectedTier: DraftTier | null;
  selectedVariant: DraftVariant | null;
  trackReadiness: TrackLaunchReadiness;
  isPreviewActive: boolean;
  previewState: string;
  selectedTrackIsLive: boolean;
  onSetAudienceMode: (value: string) => void;
  onSetSoundType: (value: string) => void;
  onToggleRepeat: () => void;
  onSetPlaybackMode: (value: PlaybackMode) => void;
  onResetLaunchSettings: () => void;
  onPreviewSelected: () => void;
  onStopPreview: () => void;
  onPlaySelected: () => void;
  onStopBroadcast: () => void;
}>;

export function TracksFocusLaunchStrip({
  current_session,
  draft,
  launchSettings,
  audienceOptions,
  soundTypeOptions,
  audienceLabel,
  soundTypeLabel,
  selectedTier,
  selectedVariant,
  trackReadiness,
  isPreviewActive,
  previewState,
  selectedTrackIsLive,
  onSetAudienceMode,
  onSetSoundType,
  onToggleRepeat,
  onSetPlaybackMode,
  onResetLaunchSettings,
  onPreviewSelected,
  onStopPreview,
  onPlaySelected,
  onStopBroadcast,
}: TracksFocusLaunchStripProps) {
  const previewDisabled = !isPreviewActive && !trackReadiness.canPreview;
  const previewLabel = isPreviewActive ? 'Stop Preview' : 'Preview';
  const previewIcon = isPreviewActive ? 'stop' : 'eye';
  const launchStateText = selectedTrackIsLive
    ? 'Live'
    : trackReadiness.reason
      ? 'Blocked'
      : 'Ready to broadcast';
  const previewStateText = isPreviewActive ? 'Preview playing' : previewState;
  const focusFactItems: CompactFactItem[] = [
    {
      label: 'Preset',
      value: draft.name || 'New preset',
    },
    {
      label: 'Scene',
      value: selectedTier?.name || 'None',
    },
    {
      label: 'Duration',
      value: selectedVariant
        ? formatDuration(selectedVariant.duration_seconds)
        : 'Unknown',
    },
    {
      label: 'Source',
      value: selectedVariant?.source_url?.trim()
        ? formatSourceLabel(selectedVariant.source_url)
        : 'Not set',
    },
  ];

  return (
    <Box
      px={0.82}
      py={0.56}
      style={{ ...STATUS_STRIP_STYLE, backgroundColor: BG_PANEL }}
    >
      <Flex align="stretch" wrap width="100%" style={{ gap: '0.72rem' }}>
        <Flex.Item
          basis="21rem"
          style={{ minWidth: '17.5rem', flex: '0 1 21rem' }}
        >
          <FocusLaunchFactsColumn
            facts={focusFactItems}
            launchStateText={launchStateText}
            previewStateText={previewStateText}
            trackReadiness={trackReadiness}
          />
        </Flex.Item>
        <Flex.Item grow style={{ minWidth: '18rem', flex: '1 1 28rem' }}>
          <Stack fill vertical>
            <Stack.Item>
              <Flex width="100%" style={PLAY_CONTROLS_ROW_STYLE}>
                <Flex.Item
                  grow
                  basis="22rem"
                  style={{ minWidth: '14rem', flex: '1 1 22rem' }}
                >
                  <PlaybackSettingsControls
                    playback={launchSettings}
                    audienceOptions={audienceOptions}
                    soundTypeOptions={soundTypeOptions}
                    audienceLabel={audienceLabel}
                    soundTypeLabel={soundTypeLabel}
                    onSetAudienceMode={onSetAudienceMode}
                    onSetSoundType={onSetSoundType}
                    onToggleShowTitle={() => null}
                    showVisibilityToggle={false}
                    showRepeatToggle={false}
                    inlineDropdownLabels
                  />
                </Flex.Item>
                <Flex.Item
                  basis="18rem"
                  style={{ minWidth: '18rem', flex: '1 1 18rem' }}
                >
                  <Stack fill>
                    <Stack.Item grow>
                      <Button
                        compact
                        fluid
                        className="AdminMusicPanel__centeredButton"
                        color="good"
                        icon="play"
                        disabled={!trackReadiness.canBroadcast}
                        style={CONTROL_BUTTON_STYLE}
                        onClick={onPlaySelected}
                      >
                        {selectedTrackIsLive
                          ? 'Restart Broadcast'
                          : 'Broadcast'}
                      </Button>
                    </Stack.Item>
                    <Stack.Item grow>
                      <Button
                        compact
                        fluid
                        className="AdminMusicPanel__centeredButton"
                        color="transparent"
                        icon="stop"
                        disabled={!current_session}
                        style={{
                          ...getStopActionStyle(!current_session),
                          ...CONTROL_BUTTON_STYLE,
                        }}
                        onClick={onStopBroadcast}
                      >
                        Stop
                      </Button>
                    </Stack.Item>
                  </Stack>
                </Flex.Item>
              </Flex>
            </Stack.Item>
            <Stack.Item mt={0.34}>
              <Flex width="100%" style={PLAY_CONTROLS_ROW_STYLE}>
                <Flex.Item
                  grow
                  basis="22rem"
                  style={{ minWidth: '14rem', flex: '1 1 22rem' }}
                >
                  <LaunchPreflightControls
                    launchSettings={launchSettings}
                    onToggleRepeat={onToggleRepeat}
                    onSetPlaybackMode={onSetPlaybackMode}
                    subtle
                  />
                </Flex.Item>
                <Flex.Item
                  basis="18rem"
                  style={{ minWidth: '18rem', flex: '1 1 18rem' }}
                >
                  <Stack fill>
                    <Stack.Item grow>
                      <Button
                        compact
                        fluid
                        className="AdminMusicPanel__centeredButton"
                        color="transparent"
                        icon={previewIcon}
                        disabled={previewDisabled}
                        style={{
                          ...getPreviewActionStyle(
                            isPreviewActive,
                            previewDisabled,
                          ),
                          ...CONTROL_BUTTON_STYLE,
                        }}
                        onClick={
                          isPreviewActive ? onStopPreview : onPreviewSelected
                        }
                      >
                        {previewLabel}
                      </Button>
                    </Stack.Item>
                    <Stack.Item grow>
                      <Button
                        compact
                        fluid
                        className="AdminMusicPanel__centeredButton"
                        color="transparent"
                        icon="undo"
                        style={{
                          ...getTertiaryActionStyle(),
                          ...CONTROL_BUTTON_STYLE,
                        }}
                        onClick={onResetLaunchSettings}
                      >
                        Reset
                      </Button>
                    </Stack.Item>
                  </Stack>
                </Flex.Item>
              </Flex>
            </Stack.Item>
          </Stack>
        </Flex.Item>
      </Flex>
    </Box>
  );
}

type InspectorTarget = 'scene' | 'track';

type LibrarySectionProps = Readonly<{
  library: LibraryPreset[];
  librarySearch: string;
  loadedLibraryPresetId: string | null;
  onSearchChange: (value: string) => void;
  onLoadPreset: (preset_id: string) => void;
  onOpenEdit: () => void;
  dirty: boolean;
}>;

export function LibrarySection({
  library,
  librarySearch,
  loadedLibraryPresetId,
  onSearchChange,
  onLoadPreset,
  onOpenEdit,
  dirty,
}: LibrarySectionProps) {
  const filteredLibrary = library.filter((preset) => {
    const haystack =
      `${preset.name} ${preset.description} ${preset.preset_id}`.toLowerCase();
    return haystack.includes(librarySearch.toLowerCase());
  });
  const hasSavedPresets = library.length > 0;

  return (
    <Section fill title="Preset Library" style={SECTION_SURFACE_STYLE}>
      <Stack fill vertical>
        <Stack.Item>
          <Input
            fluid
            placeholder="Search presets..."
            value={librarySearch}
            onInput={(e, value) => onSearchChange(value)}
          />
        </Stack.Item>
        <Stack.Item grow={1}>
          <Box style={LIST_SCROLL_STYLE}>
            {filteredLibrary.length === 0 ? (
              hasSavedPresets ? (
                <Box color="label">No presets match search.</Box>
              ) : (
                <Stack vertical>
                  <Stack.Item>
                    <Box color="label">
                      No saved presets yet. You are working in a new draft.
                    </Box>
                  </Stack.Item>
                  <Stack.Item>
                    <Button icon="edit" onClick={onOpenEdit}>
                      Open Edit
                    </Button>
                  </Stack.Item>
                </Stack>
              )
            ) : (
              filteredLibrary.map((preset) => (
                <Button
                  key={preset.preset_id}
                  compact
                  fluid
                  color="transparent"
                  onClick={() => onLoadPreset(preset.preset_id)}
                  style={getLibraryRowStyle(
                    loadedLibraryPresetId === preset.preset_id,
                  )}
                >
                  <Flex align="center" justify="space-between" width="100%">
                    <Flex.Item grow>
                      <Box bold fontSize="0.92rem" style={ELLIPSIS_STYLE}>
                        {preset.name || 'Unnamed preset'}
                      </Box>
                    </Flex.Item>
                    <Flex.Item ml={1}>
                      <Flex align="center">
                        {loadedLibraryPresetId === preset.preset_id ? (
                          <Flex.Item mr={0.5}>
                            <Box
                              style={
                                dirty ? UNSAVED_BADGE_STYLE : MUTED_BADGE_STYLE
                              }
                            >
                              {dirty ? 'Loaded + edits' : 'Loaded'}
                            </Box>
                          </Flex.Item>
                        ) : null}
                        <Flex.Item>
                          <Box
                            fontSize="0.75rem"
                            color="label"
                            style={ELLIPSIS_STYLE}
                          >
                            {preset.tier_count} scenes | {preset.variant_count}{' '}
                            tracks
                          </Box>
                        </Flex.Item>
                      </Flex>
                    </Flex.Item>
                  </Flex>
                </Button>
              ))
            )}
          </Box>
        </Stack.Item>
      </Stack>
    </Section>
  );
}

type PlayScenesSectionProps = Readonly<{
  draft: DraftPreset;
  selectedTierId: string | null;
  onSelectTier: (tier_id: string) => void;
}>;

export function PlayScenesSection({
  draft,
  selectedTierId,
  onSelectTier,
}: PlayScenesSectionProps) {
  return (
    <Section fill scrollable title="Scenes" style={SECTION_SURFACE_STYLE}>
      {draft.tiers.length === 0 ? (
        <Box color="label">No scenes loaded.</Box>
      ) : (
        draft.tiers.map((tier) => (
          <Button
            key={tier.tier_id}
            compact
            fluid
            color="transparent"
            onClick={() => onSelectTier(tier.tier_id)}
            style={getListRowStyle(selectedTierId === tier.tier_id)}
          >
            <Flex align="center" justify="space-between" width="100%">
              <Flex.Item grow>
                <Box bold style={ELLIPSIS_STYLE}>
                  {tier.name || 'Unnamed scene'}
                </Box>
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
    </Section>
  );
}

type PlayTracksSectionProps = Readonly<{
  draft: DraftPreset;
  current_session: CurrentSession;
  selectedTier: DraftTier | null;
  selectedVariantId: string | null;
  trackSearch: string;
  denseTracks: boolean;
  showOnlyInvalid?: boolean;
  showOnlyUnknown?: boolean;
  focusMode?: boolean;
  onTrackSearchChange: (value: string) => void;
  onToggleDenseTracks: () => void;
  onToggleOnlyInvalid?: () => void;
  onToggleOnlyUnknown?: () => void;
  onToggleTracksFocus?: () => void;
  onSelectVariant: (tier_id: string, variant_id: string) => void;
}>;

export function PlayTracksSection({
  draft,
  current_session,
  selectedTier,
  selectedVariantId,
  trackSearch,
  denseTracks,
  showOnlyInvalid = false,
  showOnlyUnknown = false,
  focusMode = false,
  onTrackSearchChange,
  onToggleDenseTracks,
  onToggleOnlyInvalid,
  onToggleOnlyUnknown,
  onToggleTracksFocus,
  onSelectVariant,
}: PlayTracksSectionProps) {
  const rowRefs = useRef<Record<string, HTMLDivElement | null>>({});
  const liveVariant = findCurrentSessionVariantInTier(
    current_session,
    draft,
    selectedTier,
  );
  const filteredVariants =
    selectedTier?.variants
      .map((variant, index) => ({ variant, index }))
      .filter(({ variant }) => {
        if (!matchesTrackSearch(variant, trackSearch)) {
          return false;
        }
        if (showOnlyInvalid && !isVariantMissingSource(variant)) {
          return false;
        }
        if (showOnlyUnknown && !isVariantDurationUnknown(variant)) {
          return false;
        }
        return true;
      }) || [];
  const canJumpToSelected =
    Boolean(selectedVariantId) &&
    filteredVariants.some(
      ({ variant }) => variant.variant_id === selectedVariantId,
    );
  const canJumpToLive =
    Boolean(liveVariant) &&
    filteredVariants.some(
      ({ variant }) => variant.variant_id === liveVariant?.variant_id,
    );

  const scrollToVariant = (variantId: string | null) => {
    if (!variantId) {
      return;
    }
    rowRefs.current[variantId]?.scrollIntoView({
      block: 'center',
      behavior: 'smooth',
    });
  };

  return (
    <Section
      fill
      title={focusMode ? 'Tracks Focus' : 'Tracks'}
      style={SECTION_SURFACE_STYLE}
      buttons={
        onToggleTracksFocus ? (
          <Button
            compact
            icon={focusMode ? 'compress' : 'expand'}
            color="transparent"
            disabled={!selectedTier?.variants.length}
            style={
              !selectedTier?.variants.length ? DISABLED_ACTION_STYLE : undefined
            }
            onClick={onToggleTracksFocus}
          >
            {focusMode ? 'Exit Focus' : 'Focus Tracks'}
          </Button>
        ) : undefined
      }
    >
      {!selectedTier ? (
        <Box color="label">Select a scene to browse its tracks.</Box>
      ) : (
        <Stack fill vertical>
          <Stack.Item>
            <Box style={TRACKS_FILTER_BAR_STYLE}>
              <Stack fill vertical>
                <Stack.Item>
                  <Flex align="center" justify="space-between" width="100%">
                    <Flex.Item grow>
                      <Box bold style={ELLIPSIS_STYLE}>
                        {selectedTier.name || 'Unnamed scene'}
                      </Box>
                    </Flex.Item>
                    <Flex.Item ml={1}>
                      <Box color="label" fontSize="0.75rem">
                        {formatTrackCount(selectedTier.variants.length)}
                      </Box>
                    </Flex.Item>
                  </Flex>
                </Stack.Item>
                <Stack.Item>
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
                        <Button
                          compact
                          color="transparent"
                          disabled={!canJumpToSelected}
                          style={
                            !canJumpToSelected
                              ? DISABLED_ACTION_STYLE
                              : undefined
                          }
                          onClick={() => scrollToVariant(selectedVariantId)}
                        >
                          Jump to selected
                        </Button>
                      </Stack.Item>
                      <Stack.Item>
                        <Button
                          compact
                          color="transparent"
                          disabled={!canJumpToLive}
                          style={
                            !canJumpToLive ? DISABLED_ACTION_STYLE : undefined
                          }
                          onClick={() =>
                            scrollToVariant(liveVariant?.variant_id || null)
                          }
                        >
                          Jump to live
                        </Button>
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
                      {focusMode && onToggleOnlyInvalid ? (
                        <Stack.Item>
                          <Button.Checkbox
                            compact
                            checked={showOnlyInvalid}
                            style={getCompactToggleStyle(showOnlyInvalid)}
                            onClick={onToggleOnlyInvalid}
                          >
                            Only invalid
                          </Button.Checkbox>
                        </Stack.Item>
                      ) : null}
                      {focusMode && onToggleOnlyUnknown ? (
                        <Stack.Item>
                          <Button.Checkbox
                            compact
                            checked={showOnlyUnknown}
                            style={getCompactToggleStyle(showOnlyUnknown)}
                            onClick={onToggleOnlyUnknown}
                          >
                            Only unknown
                          </Button.Checkbox>
                        </Stack.Item>
                      ) : null}
                    </Stack>
                  </Box>
                </Stack.Item>
              </Stack>
            </Box>
          </Stack.Item>
          <Stack.Item grow>
            <Box style={TRACK_LIST_SCROLL_STYLE}>
              {selectedTier.variants.length === 0 ? (
                <Box color="label">No tracks in this scene.</Box>
              ) : filteredVariants.length === 0 ? (
                <Box color="label">No tracks match the current filters.</Box>
              ) : (
                filteredVariants.map(({ variant, index }) => {
                  const isLive = isCurrentSessionForVariant(
                    current_session,
                    draft,
                    selectedTier,
                    variant,
                  );
                  const trackDescription = variant.description.trim();

                  return (
                    <div
                      key={variant.variant_id}
                      ref={(node) => {
                        rowRefs.current[variant.variant_id] = node;
                      }}
                    >
                      <Button
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
                          isLive,
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
                                <Flex.Item mr={denseTracks ? 0.6 : 0.9}>
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
                                  {getVariantListBadges(variant, isLive)
                                    .length ? (
                                    <Box mt="0.08rem">
                                      {getVariantListBadges(
                                        variant,
                                        isLive,
                                      ).map((badge) => (
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
                    </div>
                  );
                })
              )}
            </Box>
          </Stack.Item>
        </Stack>
      )}
    </Section>
  );
}
