import { useEffect, useRef, useState } from 'react';

import {
  Box,
  Button,
  Collapsible,
  Dropdown,
  Flex,
  Input,
  LabeledList,
  NumberInput,
  Section,
  Stack,
  TextArea,
} from '../../components';
import {
  COMPACT_CARD_STYLE,
  countTracks,
  CurrentSession,
  DESCRIPTION_FIELD_HEIGHT,
  DISABLED_ACTION_STYLE,
  DraftPreset,
  DraftStatus,
  DraftTier,
  DraftVariant,
  ELLIPSIS_STYLE,
  formatAfterTrackEnds,
  formatDuration,
  formatSourceLabel,
  formatTrackCount,
  getListRowStyle,
  getToggleButtonStyle,
  LABEL_STYLE,
  LaunchSettings,
  LibraryPreset,
  LIST_SCROLL_STYLE,
  LIVE_BADGE_STYLE,
  MUTED_BADGE_STYLE,
  normalizeDurationValue,
  PlaybackMode,
  PlaybackSettings,
  PLAYER_BADGE_STYLE,
  PLAYER_STRIP_STYLE,
  SelectOption,
  STATUS_STRIP_STYLE,
  SUBTLE_PANEL_STYLE,
  TrackLaunchReadiness,
  UNSAVED_BADGE_STYLE,
  WRAPPED_TEXT_STYLE,
} from './shared';

type BufferedTextAreaProps = Readonly<{
  syncKey: string | number | null;
  value: string;
  placeholder: string;
  onCommit: (value: string) => void;
}>;

function BufferedTextArea({
  syncKey,
  value,
  placeholder,
  onCommit,
}: BufferedTextAreaProps) {
  const [draftValue, setDraftValue] = useState(value);
  const skipNextCommitRef = useRef(false);

  useEffect(() => {
    skipNextCommitRef.current = false;
    setDraftValue(value);
  }, [syncKey, value]);

  return (
    <TextArea
      fluid
      height={DESCRIPTION_FIELD_HEIGHT}
      value={draftValue}
      onInput={(e, nextValue) => setDraftValue(nextValue)}
      onChange={(e, nextValue) => {
        if (skipNextCommitRef.current) {
          skipNextCommitRef.current = false;
          setDraftValue(value);
          return;
        }
        setDraftValue(nextValue);
        if (nextValue !== value) {
          onCommit(nextValue);
        }
      }}
      onEscape={() => {
        skipNextCommitRef.current = true;
        setDraftValue(value);
      }}
      placeholder={placeholder}
      scrollbar
    />
  );
}

const WARNING_PANEL_STYLE = {
  ...SUBTLE_PANEL_STYLE,
  border: '1px solid rgba(255, 208, 102, 0.24)',
  backgroundColor: 'rgba(255, 208, 102, 0.06)',
};

const getDraftStatusBadgeStyle = (kind: DraftStatus['kind']) =>
  kind === 'loaded_preset' ? MUTED_BADGE_STYLE : UNSAVED_BADGE_STYLE;

type CompactFactItem = Readonly<{
  label: string;
  value: string;
}>;

type TrackFactBadgesProps = Readonly<{
  items: CompactFactItem[];
}>;

const LIST_BADGE_STYLE = {
  ...PLAYER_BADGE_STYLE,
  padding: '0.05rem 0.35rem',
  marginBottom: '0.15rem',
  fontSize: '0.72rem',
};

const WARNING_BADGE_STYLE = {
  ...LIST_BADGE_STYLE,
  border: '1px solid rgba(255, 208, 102, 0.35)',
  backgroundColor: 'rgba(255, 208, 102, 0.12)',
};

function TrackFactBadges({ items }: TrackFactBadgesProps) {
  return (
    <Box>
      {items.map((item) => (
        <Box key={item.label} style={LIST_BADGE_STYLE}>
          {item.label}: {item.value}
        </Box>
      ))}
    </Box>
  );
}

const getVariantListBadges = (variant: DraftVariant) => {
  const badges: Array<{
    label: string;
    style: Record<string, string>;
  }> = [];

  if (!variant.source_url.trim()) {
    badges.push({
      label: 'No source',
      style: WARNING_BADGE_STYLE,
    });
  }

  if (!normalizeDurationValue(variant.duration_seconds)) {
    badges.push({
      label: 'Unknown duration',
      style: LIST_BADGE_STYLE,
    });
  }

  return badges;
};

type TrackReadinessNoticesProps = Readonly<{
  readiness: TrackLaunchReadiness;
  onOpenEdit?: () => void;
}>;

function TrackReadinessNotices({
  readiness,
  onOpenEdit,
}: TrackReadinessNoticesProps) {
  return (
    <>
      {readiness.reason ? (
        <Box
          mt="0.35rem"
          px={0.55}
          py={0.32}
          style={{
            ...WARNING_PANEL_STYLE,
            padding: '0.32rem 0.55rem',
          }}
        >
          <Flex align="center" justify="space-between" width="100%">
            <Flex.Item grow>
              <Box color="label" fontSize="0.74rem">
                Blocked: {readiness.reason}
              </Box>
            </Flex.Item>
            {onOpenEdit ? (
              <Flex.Item ml={1}>
                <Button
                  compact
                  icon="edit"
                  color="transparent"
                  onClick={onOpenEdit}
                >
                  Fix in Edit
                </Button>
              </Flex.Item>
            ) : null}
          </Flex>
        </Box>
      ) : null}
      {readiness.warnings.map((warning) => (
        <Box
          key={warning}
          mt="0.3rem"
          px={0.55}
          py={0.35}
          style={{
            ...WARNING_PANEL_STYLE,
            padding: '0.35rem 0.55rem',
          }}
        >
          <Box color="label" fontSize="0.74rem">
            Heads up: {warning}
          </Box>
        </Box>
      ))}
    </>
  );
}

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
  if (!current_session) {
    return (
      <Box px={0.85} py={0.5} style={STATUS_STRIP_STYLE}>
        <Stack align="center">
          <Stack.Item>
            <Box bold>Broadcast idle</Box>
          </Stack.Item>
          <Stack.Item grow>
            <Box color="label" fontSize="0.78rem">
              Nothing is live right now. Open Play when you want to preview or
              broadcast a track.
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
  const liveFacts: CompactFactItem[] = [
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

  return (
    <Box
      px={0.85}
      py={0.55}
      style={{
        ...STATUS_STRIP_STYLE,
        border: '1px solid rgba(120, 190, 100, 0.24)',
        backgroundColor: 'rgba(70, 140, 60, 0.08)',
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
  selectedVariant: DraftVariant | null;
  trackReadiness: TrackLaunchReadiness;
  isPreviewActive: boolean;
  previewState: string;
  previewVolume: number;
  selectedTrackIsLive: boolean;
  hasCurrentSession: boolean;
  onOpenEdit: () => void;
  onPreviewSelected: () => void;
  onStopPreview: () => void;
  onPlaySelected: () => void;
  onStopBroadcast: () => void;
  onResetLaunchSettings: () => void;
}>;

function OperatorActionPanel({
  selectedVariant,
  trackReadiness,
  isPreviewActive,
  previewState,
  previewVolume,
  selectedTrackIsLive,
  hasCurrentSession,
  onOpenEdit,
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
  const actionHint = !selectedVariant
    ? 'Select a track below to enable preview and broadcast.'
    : trackReadiness.reason
      ? `Blocked: ${trackReadiness.reason}`
      : isPreviewActive
        ? `Previewing locally at ${Math.round(previewVolume * 100)}% volume.`
        : selectedTrackIsLive
          ? 'The selected track is already on air.'
          : 'Ready to launch with the current settings.';
  const canJumpToEdit = !selectedVariant || Boolean(trackReadiness.reason);
  const hasVisiblePreviewState =
    Boolean(previewState) &&
    previewState.trim().toLowerCase() !== 'idle' &&
    !isPreviewActive;

  return (
    <Box
      style={{
        ...COMPACT_CARD_STYLE,
        padding: '0.55rem 0.65rem',
        height: '100%',
      }}
    >
      <Box color="label" fontSize="0.74rem">
        Actions
      </Box>
      <Box bold fontSize="1.02rem" mt="0.1rem">
        Operator Controls
      </Box>
      <Box mt="0.45rem">
        <Stack fill>
          <Stack.Item grow>
            <Button
              fluid
              color={isPreviewActive ? 'default' : 'transparent'}
              icon={previewIcon}
              disabled={previewDisabled}
              style={previewDisabled ? DISABLED_ACTION_STYLE : undefined}
              onClick={isPreviewActive ? onStopPreview : onPreviewSelected}
            >
              {previewLabel}
            </Button>
          </Stack.Item>
          <Stack.Item grow>
            <Button
              fluid
              icon="play"
              color="good"
              disabled={broadcastDisabled}
              style={broadcastDisabled ? DISABLED_ACTION_STYLE : undefined}
              onClick={onPlaySelected}
            >
              {broadcastLabel}
            </Button>
          </Stack.Item>
          <Stack.Item grow>
            <Button
              fluid
              icon="stop"
              color="bad"
              disabled={!hasCurrentSession}
              style={!hasCurrentSession ? DISABLED_ACTION_STYLE : undefined}
              onClick={onStopBroadcast}
            >
              Stop
            </Button>
          </Stack.Item>
          <Stack.Item grow>
            <Button
              fluid
              color="transparent"
              icon="undo"
              onClick={onResetLaunchSettings}
            >
              Reset
            </Button>
          </Stack.Item>
        </Stack>
      </Box>
      <Box
        color="label"
        fontSize="0.74rem"
        mt="0.35rem"
        style={WRAPPED_TEXT_STYLE}
      >
        {actionHint}
      </Box>
      {hasVisiblePreviewState ? (
        <Box color="label" fontSize="0.74rem" mt="0.25rem">
          Preview state: {previewState}.
        </Box>
      ) : null}
      {canJumpToEdit ? (
        <Box mt="0.35rem">
          <Button compact color="transparent" icon="edit" onClick={onOpenEdit}>
            {selectedVariant ? 'Fix in Edit' : 'Open Edit'}
          </Button>
        </Box>
      ) : null}
    </Box>
  );
}

type LaunchPlaybackPanelProps = Readonly<{
  launchSettings: LaunchSettings;
  audienceOptions: SelectOption[];
  soundTypeOptions: SelectOption[];
  audienceLabel: string;
  soundTypeLabel: string;
  launchBehavior: string;
  onSetAudienceMode: (value: string) => void;
  onSetSoundType: (value: string) => void;
  onToggleShowTitle: () => void;
  onToggleRepeat: () => void;
  onSetPlaybackMode: (value: PlaybackMode) => void;
}>;

function LaunchPlaybackPanel({
  launchSettings,
  audienceOptions,
  soundTypeOptions,
  audienceLabel,
  soundTypeLabel,
  launchBehavior,
  onSetAudienceMode,
  onSetSoundType,
  onToggleShowTitle,
  onToggleRepeat,
  onSetPlaybackMode,
}: LaunchPlaybackPanelProps) {
  return (
    <Box style={SUBTLE_PANEL_STYLE}>
      <PlaybackSettingsControls
        playback={launchSettings}
        audienceOptions={audienceOptions}
        soundTypeOptions={soundTypeOptions}
        audienceLabel={audienceLabel}
        soundTypeLabel={soundTypeLabel}
        onSetAudienceMode={onSetAudienceMode}
        onSetSoundType={onSetSoundType}
        onToggleShowTitle={onToggleShowTitle}
        showRepeatToggle={false}
        visibilityInline
      />
      <Box mt="0.45rem">
        <Stack fill mt={0.25}>
          <Stack.Item basis="42%" grow={1}>
            <Button.Checkbox
              fluid
              checked={launchSettings.repeat}
              style={getToggleButtonStyle(launchSettings.repeat)}
              onClick={onToggleRepeat}
            >
              Repeat current track
            </Button.Checkbox>
          </Stack.Item>
          <Stack.Item basis="58%" grow={1}>
            <PlaybackModeSelector
              playbackMode={launchSettings.playback_mode}
              repeat={launchSettings.repeat}
              onSetPlaybackMode={onSetPlaybackMode}
            />
          </Stack.Item>
        </Stack>
        <Box color="label" fontSize="0.75rem" mt="0.25rem">
          {launchBehavior}
        </Box>
      </Box>
    </Box>
  );
}

type SessionSectionProps = Readonly<{
  current_session: CurrentSession;
  draft: DraftPreset;
  selectedTier: DraftTier | null;
  selectedVariant: DraftVariant | null;
  launchSettings: LaunchSettings;
  audienceOptions: SelectOption[];
  soundTypeOptions: SelectOption[];
  audienceLabel: string;
  soundTypeLabel: string;
  trackReadiness: TrackLaunchReadiness;
  selectedTrackIsLive: boolean;
  onOpenEdit: () => void;
  onSetAudienceMode: (value: string) => void;
  onSetSoundType: (value: string) => void;
  onToggleShowTitle: () => void;
  onToggleRepeat: () => void;
  onSetPlaybackMode: (value: PlaybackMode) => void;
  onResetLaunchSettings: () => void;
  onPreviewSelected: () => void;
  onStopPreview: () => void;
  isPreviewActive: boolean;
  previewState: string;
  previewVolume: number;
  onPlaySelected: () => void;
  onStopBroadcast: () => void;
}>;

export function SessionSection({
  current_session,
  draft,
  selectedTier,
  selectedVariant,
  launchSettings,
  audienceOptions,
  soundTypeOptions,
  audienceLabel,
  soundTypeLabel,
  trackReadiness,
  selectedTrackIsLive,
  onOpenEdit,
  onSetAudienceMode,
  onSetSoundType,
  onToggleShowTitle,
  onToggleRepeat,
  onSetPlaybackMode,
  onResetLaunchSettings,
  onPreviewSelected,
  onStopPreview,
  isPreviewActive,
  previewState,
  previewVolume,
  onPlaySelected,
  onStopBroadcast,
}: SessionSectionProps) {
  const liveTitle = current_session
    ? current_session.variant_title ||
      current_session.resolved_title ||
      'Untitled broadcast'
    : 'Nothing live right now';
  const liveStatusLabel = current_session ? 'Live' : 'Idle';
  const liveBehavior = current_session
    ? formatAfterTrackEnds(
        Boolean(current_session.loop),
        current_session.playback_mode,
      )
    : 'Waiting for the next broadcast';
  const liveOriginParts = current_session
    ? [
        current_session.preset_name
          ? `Preset ${current_session.preset_name}`
          : null,
        current_session.tier_name ? `Scene ${current_session.tier_name}` : null,
        current_session.variant_title
          ? `Track ${current_session.variant_title}`
          : null,
      ].filter(Boolean)
    : [];
  const liveOriginSummary =
    liveOriginParts.join(' | ') ||
    (current_session
      ? `Source ${formatSourceLabel(current_session.source_url)}`
      : 'Pick a track below when you are ready to go live.');
  const selectedTitle = selectedVariant?.title || 'No track selected';
  const selectedStatus = !selectedVariant
    ? 'Choose a track from the list below to prepare the next launch.'
    : trackReadiness.canBroadcast
      ? 'Ready to preview locally or send live with the current launch settings.'
      : 'Needs a small fix before it can be previewed or sent live.';
  const selectedFacts: CompactFactItem[] = [
    {
      label: 'Preset',
      value: draft.name || 'New preset',
    },
    {
      label: 'Scene',
      value: selectedTier?.name || 'None',
    },
    {
      label: 'Track',
      value: selectedVariant?.title || 'None',
    },
    {
      label: 'Duration',
      value: selectedVariant
        ? formatDuration(selectedVariant.duration_seconds)
        : 'Unknown',
    },
    {
      label: 'Source',
      value: selectedVariant
        ? selectedVariant.source_url.trim()
          ? formatSourceLabel(selectedVariant.source_url)
          : 'Not set'
        : 'Not set',
    },
  ];
  const launchBehavior = formatAfterTrackEnds(
    launchSettings.repeat,
    launchSettings.playback_mode,
  );

  return (
    <Box
      style={{
        ...PLAYER_STRIP_STYLE,
        padding: '0.78rem 0.82rem',
      }}
    >
      <Stack vertical>
        <Stack.Item>
          <Stack align="stretch">
            <Stack.Item basis="28%" grow={1}>
              <Box
                style={{
                  ...COMPACT_CARD_STYLE,
                  padding: '0.55rem 0.65rem',
                  border: current_session
                    ? '1px solid rgba(120, 190, 100, 0.24)'
                    : COMPACT_CARD_STYLE.border,
                  backgroundColor: current_session
                    ? 'rgba(70, 140, 60, 0.08)'
                    : COMPACT_CARD_STYLE.backgroundColor,
                }}
              >
                <Box color="label" fontSize="0.74rem">
                  System Status
                </Box>
                <Box mt="0.18rem">
                  <Box
                    style={
                      current_session ? LIVE_BADGE_STYLE : MUTED_BADGE_STYLE
                    }
                  >
                    {liveStatusLabel}
                  </Box>
                </Box>
                <Box
                  bold
                  fontSize="1.05rem"
                  mt="0.18rem"
                  style={ELLIPSIS_STYLE}
                >
                  {liveTitle}
                </Box>
                <Box color="label" fontSize="0.76rem" mt="0.18rem">
                  {current_session
                    ? `${current_session.audience_label} | ${current_session.sound_type_label} | ${liveBehavior}`
                    : 'Idle until the next broadcast starts.'}
                </Box>
                <Box
                  color="label"
                  fontSize="0.74rem"
                  mt="0.3rem"
                  style={WRAPPED_TEXT_STYLE}
                >
                  {liveOriginSummary}
                </Box>
              </Box>
            </Stack.Item>
            <Stack.Item basis="42%" grow={2}>
              <Box
                style={{
                  ...COMPACT_CARD_STYLE,
                  padding: '0.55rem 0.65rem',
                }}
              >
                <Flex align="flex-start" justify="space-between" width="100%">
                  <Flex.Item grow>
                    <Box color="label" fontSize="0.74rem">
                      Selected Track
                    </Box>
                    <Box
                      bold
                      fontSize="1.08rem"
                      mt="0.1rem"
                      style={ELLIPSIS_STYLE}
                    >
                      {selectedTitle}
                    </Box>
                    <Box color="label" fontSize="0.78rem" mt="0.18rem">
                      {selectedStatus}
                    </Box>
                  </Flex.Item>
                  {selectedTrackIsLive ? (
                    <Flex.Item ml={1}>
                      <Box style={LIVE_BADGE_STYLE}>On air</Box>
                    </Flex.Item>
                  ) : null}
                </Flex>
                <Box mt="0.35rem">
                  <TrackFactBadges items={selectedFacts} />
                </Box>
                {selectedVariant ? (
                  <TrackReadinessNotices
                    readiness={trackReadiness}
                    onOpenEdit={
                      !trackReadiness.canPreview ? onOpenEdit : undefined
                    }
                  />
                ) : null}
              </Box>
            </Stack.Item>
            <Stack.Item basis="30%" grow={1}>
              <OperatorActionPanel
                selectedVariant={selectedVariant}
                trackReadiness={trackReadiness}
                isPreviewActive={isPreviewActive}
                previewState={previewState}
                previewVolume={previewVolume}
                selectedTrackIsLive={selectedTrackIsLive}
                hasCurrentSession={Boolean(current_session)}
                onOpenEdit={onOpenEdit}
                onPreviewSelected={onPreviewSelected}
                onStopPreview={onStopPreview}
                onPlaySelected={onPlaySelected}
                onStopBroadcast={onStopBroadcast}
                onResetLaunchSettings={onResetLaunchSettings}
              />
            </Stack.Item>
          </Stack>
        </Stack.Item>
        <Stack.Item>
          <Box
            mt="0.7rem"
            style={{
              ...COMPACT_CARD_STYLE,
              padding: '0.55rem 0.65rem',
            }}
          >
            <Box bold>Launch Settings</Box>
            <Box color="label" fontSize="0.76rem" mt="0.18rem">
              Audience, sound type, player visibility, repeat, and launch mode.
            </Box>
            <Box mt="0.35rem">
              <LaunchPlaybackPanel
                launchSettings={launchSettings}
                audienceOptions={audienceOptions}
                soundTypeOptions={soundTypeOptions}
                audienceLabel={audienceLabel}
                soundTypeLabel={soundTypeLabel}
                launchBehavior={launchBehavior}
                onSetAudienceMode={onSetAudienceMode}
                onSetSoundType={onSetSoundType}
                onToggleShowTitle={onToggleShowTitle}
                onToggleRepeat={onToggleRepeat}
                onSetPlaybackMode={onSetPlaybackMode}
              />
            </Box>
          </Box>
        </Stack.Item>
      </Stack>
    </Box>
  );
}

type PlaybackModeSelectorProps = Readonly<{
  playbackMode: PlaybackMode;
  repeat: boolean;
  onSetPlaybackMode: (value: PlaybackMode) => void;
}>;

function PlaybackModeSelector({
  playbackMode,
  repeat,
  onSetPlaybackMode,
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
    <Stack fill>
      {options.map((option) => (
        <Stack.Item key={option.value} grow>
          <Button
            fluid
            color="transparent"
            selected={playbackMode === option.value}
            disabled={repeat}
            style={getToggleButtonStyle(playbackMode === option.value)}
            onClick={() => onSetPlaybackMode(option.value)}
          >
            {option.label}
          </Button>
        </Stack.Item>
      ))}
    </Stack>
  );
}

type PlayTabProps = Readonly<{
  current_session: CurrentSession;
  draft: DraftPreset;
  launchSettings: LaunchSettings;
  audienceOptions: SelectOption[];
  soundTypeOptions: SelectOption[];
  audienceLabel: string;
  soundTypeLabel: string;
  trackReadiness: TrackLaunchReadiness;
  selectedTrackIsLive: boolean;
  isPreviewActive: boolean;
  previewState: string;
  previewVolume: number;
  library: LibraryPreset[];
  librarySearch: string;
  loadedLibraryPresetId: string | null;
  onSearchChange: (value: string) => void;
  onLoadPreset: (preset_id: string) => void;
  onOpenEdit: () => void;
  dirty: boolean;
  selectedTier: DraftTier | null;
  selectedVariant: DraftVariant | null;
  selectedTierId: string | null;
  selectedVariantId: string | null;
  onSetAudienceMode: (value: string) => void;
  onSetSoundType: (value: string) => void;
  onToggleShowTitle: () => void;
  onToggleRepeat: () => void;
  onSetPlaybackMode: (value: PlaybackMode) => void;
  onResetLaunchSettings: () => void;
  onPreviewSelected: () => void;
  onStopPreview: () => void;
  onPlaySelected: () => void;
  onStopBroadcast: () => void;
  onSelectTier: (tier_id: string) => void;
  onSelectVariant: (tier_id: string, variant_id: string) => void;
}>;

export function PlayTab({
  current_session,
  draft,
  launchSettings,
  audienceOptions,
  soundTypeOptions,
  audienceLabel,
  soundTypeLabel,
  trackReadiness,
  selectedTrackIsLive,
  isPreviewActive,
  previewState,
  previewVolume,
  library,
  librarySearch,
  loadedLibraryPresetId,
  onSearchChange,
  onLoadPreset,
  onOpenEdit,
  dirty,
  selectedTier,
  selectedVariant,
  selectedTierId,
  selectedVariantId,
  onSetAudienceMode,
  onSetSoundType,
  onToggleShowTitle,
  onToggleRepeat,
  onSetPlaybackMode,
  onResetLaunchSettings,
  onPreviewSelected,
  onStopPreview,
  onPlaySelected,
  onStopBroadcast,
  onSelectTier,
  onSelectVariant,
}: PlayTabProps) {
  return (
    <Stack fill vertical>
      <Stack.Item>
        <SessionSection
          current_session={current_session}
          draft={draft}
          selectedTier={selectedTier}
          selectedVariant={selectedVariant}
          launchSettings={launchSettings}
          audienceOptions={audienceOptions}
          soundTypeOptions={soundTypeOptions}
          audienceLabel={audienceLabel}
          soundTypeLabel={soundTypeLabel}
          trackReadiness={trackReadiness}
          selectedTrackIsLive={selectedTrackIsLive}
          onOpenEdit={onOpenEdit}
          onSetAudienceMode={onSetAudienceMode}
          onSetSoundType={onSetSoundType}
          onToggleShowTitle={onToggleShowTitle}
          onToggleRepeat={onToggleRepeat}
          onSetPlaybackMode={onSetPlaybackMode}
          onResetLaunchSettings={onResetLaunchSettings}
          onPreviewSelected={onPreviewSelected}
          onStopPreview={onStopPreview}
          isPreviewActive={isPreviewActive}
          previewState={previewState}
          previewVolume={previewVolume}
          onPlaySelected={onPlaySelected}
          onStopBroadcast={onStopBroadcast}
        />
      </Stack.Item>
      <Stack.Item grow={1}>
        <Box mt="0.8rem">
          <Stack fill>
            <Stack.Item basis="30%" grow={1}>
              <LibrarySection
                library={library}
                librarySearch={librarySearch}
                loadedLibraryPresetId={loadedLibraryPresetId}
                onSearchChange={onSearchChange}
                onLoadPreset={onLoadPreset}
                onOpenEdit={onOpenEdit}
                dirty={dirty}
              />
            </Stack.Item>
            <Stack.Item basis="18%" grow={1}>
              <PlayScenesSection
                draft={draft}
                selectedTierId={selectedTierId}
                onSelectTier={onSelectTier}
              />
            </Stack.Item>
            <Stack.Item basis="52%" grow={2}>
              <PlayTracksSection
                selectedTier={selectedTier}
                selectedVariantId={selectedVariantId}
                onSelectVariant={onSelectVariant}
              />
            </Stack.Item>
          </Stack>
        </Box>
      </Stack.Item>
    </Stack>
  );
}

type EditTabProps = Readonly<{
  draft: DraftPreset;
  draftStatus: DraftStatus;
  draftToken: number;
  canDelete: boolean;
  canRevert: boolean;
  audienceOptions: SelectOption[];
  soundTypeOptions: SelectOption[];
  audienceLabel: string;
  soundTypeLabel: string;
  selectedTier: DraftTier | null;
  selectedTierId: string | null;
  selectedVariant: DraftVariant | null;
  selectedVariantId: string | null;
  onSave: () => void;
  onNew: () => void;
  onSaveAsCopy: () => void;
  onRevert: () => void;
  onDelete: () => void;
  onExport: () => void;
  onImport: (jsonText: string | string[]) => void;
  onSetName: (value: string) => void;
  onSetDescription: (value: string) => void;
  onSetAudienceMode: (value: string) => void;
  onSetSoundType: (value: string) => void;
  onToggleShowTitle: () => void;
  onToggleRepeat: () => void;
  onAddTier: () => void;
  onSelectTier: (tier_id: string) => void;
  onRemoveTier: (tier_id: string) => void;
  onMoveTierUp: (tier_id: string) => void;
  onMoveTierDown: (tier_id: string) => void;
  onSetTierName: (tier_id: string, value: string) => void;
  onSetTierDescription: (tier_id: string, value: string) => void;
  onAddVariant: () => void;
  onSelectVariant: (tier_id: string, variant_id: string) => void;
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
}>;

export function EditTab({
  draft,
  draftStatus,
  draftToken,
  canDelete,
  canRevert,
  audienceOptions,
  soundTypeOptions,
  audienceLabel,
  soundTypeLabel,
  selectedTier,
  selectedTierId,
  selectedVariant,
  selectedVariantId,
  onSave,
  onNew,
  onSaveAsCopy,
  onRevert,
  onDelete,
  onExport,
  onImport,
  onSetName,
  onSetDescription,
  onSetAudienceMode,
  onSetSoundType,
  onToggleShowTitle,
  onToggleRepeat,
  onAddTier,
  onSelectTier,
  onRemoveTier,
  onMoveTierUp,
  onMoveTierDown,
  onSetTierName,
  onSetTierDescription,
  onAddVariant,
  onSelectVariant,
  onRemoveVariant,
  onMoveVariantUp,
  onMoveVariantDown,
  onSetVariantTitle,
  onSetVariantDescription,
  onSetVariantDuration,
  onSetVariantSourceUrl,
}: EditTabProps) {
  return (
    <Stack fill vertical>
      <Stack.Item>
        <EditHeaderSection
          draft={draft}
          draftStatus={draftStatus}
          canRevert={canRevert}
          onSave={onSave}
          onSaveAsCopy={onSaveAsCopy}
          onRevert={onRevert}
        />
      </Stack.Item>
      <Stack.Item grow={1}>
        <Box mt="0.8rem">
          <Stack fill>
            <Stack.Item basis="31%" grow={1}>
              <Stack fill vertical>
                <Stack.Item grow={1}>
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
                  />
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
            </Stack.Item>
            <Stack.Item basis="27%" grow={1}>
              <SceneEditorSection
                draft={draft}
                selectedTier={selectedTier}
                selectedTierId={selectedTierId}
                onAddTier={onAddTier}
                onSelectTier={onSelectTier}
                onRemoveTier={onRemoveTier}
                onMoveTierUp={onMoveTierUp}
                onMoveTierDown={onMoveTierDown}
                onSetTierName={onSetTierName}
                onSetTierDescription={onSetTierDescription}
              />
            </Stack.Item>
            <Stack.Item basis="42%" grow={1}>
              <TrackEditorSection
                selectedTier={selectedTier}
                selectedVariant={selectedVariant}
                selectedVariantId={selectedVariantId}
                onAddVariant={onAddVariant}
                onSelectVariant={onSelectVariant}
                onRemoveVariant={onRemoveVariant}
                onMoveVariantUp={onMoveVariantUp}
                onMoveVariantDown={onMoveVariantDown}
                onSetVariantTitle={onSetVariantTitle}
                onSetVariantDescription={onSetVariantDescription}
                onSetVariantDuration={onSetVariantDuration}
                onSetVariantSourceUrl={onSetVariantSourceUrl}
              />
            </Stack.Item>
          </Stack>
        </Box>
      </Stack.Item>
    </Stack>
  );
}

type LibrarySectionProps = Readonly<{
  library: LibraryPreset[];
  librarySearch: string;
  loadedLibraryPresetId: string | null;
  onSearchChange: (value: string) => void;
  onLoadPreset: (preset_id: string) => void;
  onOpenEdit: () => void;
  dirty: boolean;
}>;

function LibrarySection({
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
    <Section fill title="Library">
      <Stack fill vertical>
        <Stack.Item>
          <Input
            fluid
            placeholder="Search presets..."
            value={librarySearch}
            onInput={(e, value) => onSearchChange(value)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box color="label" fontSize="0.75rem">
            Load a saved preset into the current draft.
          </Box>
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
                  disabled={
                    loadedLibraryPresetId === preset.preset_id && !dirty
                  }
                  onClick={() => onLoadPreset(preset.preset_id)}
                  style={getListRowStyle(
                    loadedLibraryPresetId === preset.preset_id,
                  )}
                >
                  <Box>
                    <Flex align="center" justify="space-between" width="100%">
                      <Flex.Item grow>
                        <Box bold style={ELLIPSIS_STYLE}>
                          {preset.name || 'Unnamed preset'}
                        </Box>
                      </Flex.Item>
                      <Flex.Item ml={1}>
                        <Box fontSize="0.75rem" color="label">
                          {preset.tier_count} scenes | {preset.variant_count}{' '}
                          tracks
                        </Box>
                        {loadedLibraryPresetId === preset.preset_id ? (
                          <Box
                            mt="0.15rem"
                            style={
                              dirty ? UNSAVED_BADGE_STYLE : MUTED_BADGE_STYLE
                            }
                          >
                            {dirty ? 'Unsaved changes' : 'Loaded'}
                          </Box>
                        ) : null}
                      </Flex.Item>
                    </Flex>
                    <Box
                      fontSize="0.75rem"
                      color="label"
                      style={ELLIPSIS_STYLE}
                    >
                      {preset.description || `ID ${preset.preset_id}`}
                    </Box>
                  </Box>
                </Button>
              ))
            )}
          </Box>
        </Stack.Item>
      </Stack>
    </Section>
  );
}

type PlaybackSettingsControlsProps = Readonly<{
  playback: PlaybackSettings;
  audienceOptions: SelectOption[];
  soundTypeOptions: SelectOption[];
  audienceLabel: string;
  soundTypeLabel: string;
  onSetAudienceMode: (value: string) => void;
  onSetSoundType: (value: string) => void;
  onToggleShowTitle: () => void;
  onToggleRepeat?: () => void;
  showRepeatToggle?: boolean;
  visibilityInline?: boolean;
}>;

function PlaybackSettingsControls({
  playback,
  audienceOptions,
  soundTypeOptions,
  audienceLabel,
  soundTypeLabel,
  onSetAudienceMode,
  onSetSoundType,
  onToggleShowTitle,
  onToggleRepeat,
  showRepeatToggle = true,
  visibilityInline = false,
}: PlaybackSettingsControlsProps) {
  return (
    <Stack vertical>
      <Stack.Item>
        <Stack fill>
          <Stack.Item basis={visibilityInline ? '38%' : '50%'} grow={1}>
            <Box style={LABEL_STYLE}>Audience</Box>
            <Dropdown
              width="100%"
              options={audienceOptions}
              selected={playback.audience_mode}
              displayText={audienceLabel}
              onSelected={(value) => onSetAudienceMode(value)}
            />
          </Stack.Item>
          <Stack.Item basis={visibilityInline ? '38%' : '50%'} grow={1}>
            <Box style={LABEL_STYLE}>Sound Type</Box>
            <Dropdown
              width="100%"
              options={soundTypeOptions}
              selected={playback.sound_type}
              displayText={soundTypeLabel}
              onSelected={(value) => onSetSoundType(value)}
            />
          </Stack.Item>
          {visibilityInline ? (
            <Stack.Item basis="24%" grow={1}>
              <Box style={LABEL_STYLE}>Players Visible</Box>
              <Button
                compact
                fluid
                color="transparent"
                icon={
                  playback.show_title_to_players ? 'check-square-o' : 'square-o'
                }
                style={getToggleButtonStyle(playback.show_title_to_players)}
                onClick={onToggleShowTitle}
              >
                {playback.show_title_to_players ? 'Visible' : 'Hidden'}
              </Button>
            </Stack.Item>
          ) : null}
        </Stack>
      </Stack.Item>
      {!visibilityInline || showRepeatToggle ? (
        <Stack.Item>
          <Stack fill>
            {!visibilityInline ? (
              <Stack.Item grow>
                <Button
                  compact
                  fluid
                  color="transparent"
                  icon={
                    playback.show_title_to_players
                      ? 'check-square-o'
                      : 'square-o'
                  }
                  style={getToggleButtonStyle(playback.show_title_to_players)}
                  onClick={onToggleShowTitle}
                >
                  Visible to players
                </Button>
              </Stack.Item>
            ) : null}
            {showRepeatToggle ? (
              <Stack.Item grow>
                <Button
                  compact
                  fluid
                  color="transparent"
                  icon={playback.repeat ? 'check-square-o' : 'square-o'}
                  style={getToggleButtonStyle(playback.repeat)}
                  onClick={onToggleRepeat}
                >
                  Repeat until stopped
                </Button>
              </Stack.Item>
            ) : null}
          </Stack>
        </Stack.Item>
      ) : null}
    </Stack>
  );
}

type PlayScenesSectionProps = Readonly<{
  draft: DraftPreset;
  selectedTierId: string | null;
  onSelectTier: (tier_id: string) => void;
}>;

function PlayScenesSection({
  draft,
  selectedTierId,
  onSelectTier,
}: PlayScenesSectionProps) {
  return (
    <Section fill scrollable title="Scenes">
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
  selectedTier: DraftTier | null;
  selectedVariantId: string | null;
  onSelectVariant: (tier_id: string, variant_id: string) => void;
}>;

function PlayTracksSection({
  selectedTier,
  selectedVariantId,
  onSelectVariant,
}: PlayTracksSectionProps) {
  return (
    <Section fill title="Tracks">
      {!selectedTier ? (
        <Box color="label">Select a scene to browse its tracks.</Box>
      ) : (
        <Stack fill vertical>
          <Stack.Item>
            <Box style={STATUS_STRIP_STYLE}>
              <Box bold style={ELLIPSIS_STYLE}>
                {selectedTier.name || 'Unnamed scene'}
              </Box>
              <Box color="label" fontSize="0.75rem">
                {formatTrackCount(selectedTier.variants.length)}
              </Box>
            </Box>
          </Stack.Item>
          <Stack.Item grow>
            <Box style={LIST_SCROLL_STYLE}>
              {selectedTier.variants.length === 0 ? (
                <Box color="label">No tracks in this scene.</Box>
              ) : (
                selectedTier.variants.map((variant) => (
                  <Button
                    key={variant.variant_id}
                    compact
                    fluid
                    color="transparent"
                    onClick={() =>
                      onSelectVariant(selectedTier.tier_id, variant.variant_id)
                    }
                    style={getListRowStyle(
                      selectedVariantId === variant.variant_id,
                    )}
                  >
                    <Flex align="center" justify="space-between" width="100%">
                      <Flex.Item grow>
                        <Box bold style={ELLIPSIS_STYLE}>
                          {variant.title || 'Unnamed track'}
                        </Box>
                        {getVariantListBadges(variant).length ? (
                          <Box mt="0.1rem">
                            {getVariantListBadges(variant).map((badge) => (
                              <Box key={badge.label} style={badge.style}>
                                {badge.label}
                              </Box>
                            ))}
                          </Box>
                        ) : null}
                      </Flex.Item>
                      <Flex.Item ml={1}>
                        <Box fontSize="0.75rem" color="label">
                          {formatDuration(variant.duration_seconds)}
                        </Box>
                      </Flex.Item>
                    </Flex>
                  </Button>
                ))
              )}
            </Box>
          </Stack.Item>
        </Stack>
      )}
    </Section>
  );
}

type EditHeaderSectionProps = Readonly<{
  draft: DraftPreset;
  draftStatus: DraftStatus;
  canRevert: boolean;
  onSave: () => void;
  onSaveAsCopy: () => void;
  onRevert: () => void;
}>;

function EditHeaderSection({
  draft,
  draftStatus,
  canRevert,
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
      py={0.6}
      style={{
        ...STATUS_STRIP_STYLE,
        border: '1px solid rgba(255, 255, 255, 0.08)',
      }}
    >
      <Stack align="center">
        <Stack.Item grow>
          <Box bold fontSize="1.08rem" style={ELLIPSIS_STYLE}>
            {draft.name || 'New preset'}
          </Box>
          <Box color="label" fontSize="0.78rem" mt="0.15rem">
            {draftStatus.hint}
          </Box>
          <Box mt="0.28rem">
            {statusBadges.map((badge) => (
              <Box key={badge.label} mr={0.35} mb={0.2} style={badge.style}>
                {badge.label}
              </Box>
            ))}
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Stack>
            <Stack.Item>
              <Button icon="save" color="good" onClick={onSave}>
                Save
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button icon="copy" onClick={onSaveAsCopy}>
                Save As
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button
                icon="undo"
                color="transparent"
                disabled={!canRevert}
                style={!canRevert ? DISABLED_ACTION_STYLE : undefined}
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
}: PresetMetaSectionProps) {
  return (
    <Section fill title="Preset">
      <Stack vertical>
        <Stack.Item>
          <Box style={COMPACT_CARD_STYLE}>
            <Box bold fontSize="1rem" style={ELLIPSIS_STYLE}>
              {draft.name || 'New preset'}
            </Box>
            <Box mt="0.3rem">
              <Box style={PLAYER_BADGE_STYLE}>
                ID {draft.preset_id || 'new'}
              </Box>
              <Box style={PLAYER_BADGE_STYLE}>Scenes {draft.tiers.length}</Box>
              <Box style={PLAYER_BADGE_STYLE}>Tracks {countTracks(draft)}</Box>
            </Box>
          </Box>
        </Stack.Item>
        <Stack.Item>
          <LabeledList key={draftToken}>
            <LabeledList.Item label="Name">
              <Input
                fluid
                value={draft.name}
                onInput={(e, value) => onSetName(value)}
              />
            </LabeledList.Item>
            <LabeledList.Item label="Description" verticalAlign="top">
              <BufferedTextArea
                syncKey={draftToken}
                value={draft.description}
                onCommit={onSetDescription}
                placeholder="Short description for admins"
              />
            </LabeledList.Item>
          </LabeledList>
        </Stack.Item>
        <Stack.Item>
          <Box style={COMPACT_CARD_STYLE}>
            <Box bold>Preset Defaults</Box>
            <Box color="label" fontSize="0.78rem" mt="0.18rem" mb={0.4}>
              Saved with the preset and used as the starting point for Play.
            </Box>
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
            />
          </Box>
        </Stack.Item>
      </Stack>
    </Section>
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
    <Collapsible title="Advanced" icon="cog">
      <Box color="label" fontSize="0.8rem" mb={0.5}>
        Import, export, and destructive actions stay here.
      </Box>
      <Stack vertical>
        <Stack.Item>
          <Button fluid icon="plus" onClick={onNew}>
            New Draft
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Button.File
            fluid
            icon="upload"
            accept=".json,application/json"
            onSelectFiles={onImport}
          >
            Import JSON
          </Button.File>
        </Stack.Item>
        <Stack.Item>
          <Button fluid icon="download" onClick={onExport}>
            Export Preset
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Button
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
  );
}

type SceneEditorSectionProps = Readonly<{
  draft: DraftPreset;
  selectedTier: DraftTier | null;
  selectedTierId: string | null;
  onAddTier: () => void;
  onSelectTier: (tier_id: string) => void;
  onRemoveTier: (tier_id: string) => void;
  onMoveTierUp: (tier_id: string) => void;
  onMoveTierDown: (tier_id: string) => void;
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
  onMoveTierUp,
  onMoveTierDown,
  onSetTierName,
  onSetTierDescription,
}: SceneEditorSectionProps) {
  const canDeleteScene = Boolean(selectedTier && draft.tiers.length > 1);
  const selectedTierIndex = selectedTier
    ? draft.tiers.findIndex((tier) => tier.tier_id === selectedTier.tier_id)
    : -1;
  const canMoveSceneUp = selectedTierIndex > 0;
  const canMoveSceneDown =
    selectedTierIndex >= 0 && selectedTierIndex < draft.tiers.length - 1;

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
        <Stack.Item basis="26%">
          <Box style={LIST_SCROLL_STYLE}>
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
                  <Flex align="center" justify="space-between" width="100%">
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
        <Stack.Item grow={1}>
          <Section
            title="Scene Details"
            buttons={
              selectedTier &&
              (canMoveSceneUp || canMoveSceneDown || canDeleteScene) ? (
                <Stack>
                  {canMoveSceneUp ? (
                    <Stack.Item>
                      <Button
                        icon="arrow-up"
                        color="transparent"
                        onClick={() => onMoveTierUp(selectedTier.tier_id)}
                      >
                        Move Up
                      </Button>
                    </Stack.Item>
                  ) : null}
                  {canMoveSceneDown ? (
                    <Stack.Item>
                      <Button
                        icon="arrow-down"
                        color="transparent"
                        onClick={() => onMoveTierDown(selectedTier.tier_id)}
                      >
                        Move Down
                      </Button>
                    </Stack.Item>
                  ) : null}
                  {canDeleteScene ? (
                    <Stack.Item>
                      <Button.Confirm
                        icon="trash"
                        color="transparent"
                        confirmColor="bad"
                        confirmIcon="trash"
                        confirmContent="Delete?"
                        onClick={() => onRemoveTier(selectedTier.tier_id)}
                      >
                        Delete Scene
                      </Button.Confirm>
                    </Stack.Item>
                  ) : null}
                </Stack>
              ) : null
            }
          >
            {!selectedTier ? (
              <Box color="label">Select a scene from the list above.</Box>
            ) : (
              <LabeledList key={selectedTier.tier_id}>
                <LabeledList.Item label="Order">
                  {selectedTierIndex + 1} of {draft.tiers.length}
                </LabeledList.Item>
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
                  <BufferedTextArea
                    syncKey={selectedTier.tier_id}
                    value={selectedTier.description}
                    onCommit={(value) =>
                      onSetTierDescription(selectedTier.tier_id, value)
                    }
                    placeholder="Scene description"
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

type TrackEditorSectionProps = Readonly<{
  selectedTier: DraftTier | null;
  selectedVariant: DraftVariant | null;
  selectedVariantId: string | null;
  onAddVariant: () => void;
  onSelectVariant: (tier_id: string, variant_id: string) => void;
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
}>;

function TrackEditorSection({
  selectedTier,
  selectedVariant,
  selectedVariantId,
  onAddVariant,
  onSelectVariant,
  onRemoveVariant,
  onMoveVariantUp,
  onMoveVariantDown,
  onSetVariantTitle,
  onSetVariantDescription,
  onSetVariantDuration,
  onSetVariantSourceUrl,
}: TrackEditorSectionProps) {
  const canDeleteTrack = Boolean(
    selectedTier && selectedVariant && selectedTier.variants.length > 1,
  );
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
  const normalizedDuration = normalizeDurationValue(
    selectedVariant?.duration_seconds || 0,
  );

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
        <Box color="label">Select a scene to manage its tracks.</Box>
      ) : (
        <Stack fill vertical>
          <Stack.Item>
            <Box style={STATUS_STRIP_STYLE}>
              <Box bold style={ELLIPSIS_STYLE}>
                {selectedTier.name || 'Unnamed scene'}
              </Box>
              <Box color="label" fontSize="0.75rem">
                {formatTrackCount(selectedTier.variants.length)}
              </Box>
            </Box>
          </Stack.Item>
          <Stack.Item basis="22%">
            <Box style={LIST_SCROLL_STYLE}>
              {selectedTier.variants.length === 0 ? (
                <Box color="label">No tracks yet.</Box>
              ) : (
                selectedTier.variants.map((variant, index) => (
                  <Button
                    key={variant.variant_id}
                    compact
                    fluid
                    color="transparent"
                    onClick={() =>
                      onSelectVariant(selectedTier.tier_id, variant.variant_id)
                    }
                    style={getListRowStyle(
                      selectedVariantId === variant.variant_id,
                    )}
                  >
                    <Flex align="center" justify="space-between" width="100%">
                      <Flex.Item grow>
                        <Flex align="center">
                          <Flex.Item mr={1}>
                            <Box color="label" fontSize="0.75rem">
                              {index + 1}.
                            </Box>
                          </Flex.Item>
                          <Flex.Item grow>
                            <Box bold style={ELLIPSIS_STYLE}>
                              {variant.title || 'Unnamed track'}
                            </Box>
                            {getVariantListBadges(variant).length ? (
                              <Box mt="0.1rem">
                                {getVariantListBadges(variant).map((badge) => (
                                  <Box key={badge.label} style={badge.style}>
                                    {badge.label}
                                  </Box>
                                ))}
                              </Box>
                            ) : null}
                          </Flex.Item>
                        </Flex>
                      </Flex.Item>
                      <Flex.Item ml={1}>
                        <Box fontSize="0.75rem" color="label">
                          {formatDuration(variant.duration_seconds)}
                        </Box>
                      </Flex.Item>
                    </Flex>
                  </Button>
                ))
              )}
            </Box>
          </Stack.Item>
          <Stack.Item grow={1}>
            <Section
              title="Track Details"
              buttons={
                selectedTier &&
                selectedVariant &&
                (canMoveTrackUp || canMoveTrackDown || canDeleteTrack) ? (
                  <Stack>
                    {canMoveTrackUp ? (
                      <Stack.Item>
                        <Button
                          icon="arrow-up"
                          color="transparent"
                          onClick={() =>
                            onMoveVariantUp(
                              selectedTier.tier_id,
                              selectedVariant.variant_id,
                            )
                          }
                        >
                          Move Up
                        </Button>
                      </Stack.Item>
                    ) : null}
                    {canMoveTrackDown ? (
                      <Stack.Item>
                        <Button
                          icon="arrow-down"
                          color="transparent"
                          onClick={() =>
                            onMoveVariantDown(
                              selectedTier.tier_id,
                              selectedVariant.variant_id,
                            )
                          }
                        >
                          Move Down
                        </Button>
                      </Stack.Item>
                    ) : null}
                    {canDeleteTrack ? (
                      <Stack.Item>
                        <Button.Confirm
                          icon="trash"
                          color="transparent"
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
                          Delete Track
                        </Button.Confirm>
                      </Stack.Item>
                    ) : null}
                  </Stack>
                ) : null
              }
            >
              {!selectedVariant ? (
                <Box color="label">Select a track from the list above.</Box>
              ) : (
                <Stack vertical key={selectedVariant.variant_id}>
                  <Stack.Item>
                    <Box style={COMPACT_CARD_STYLE}>
                      <Box bold fontSize="1rem" style={ELLIPSIS_STYLE}>
                        {selectedVariant.title || 'Unnamed track'}
                      </Box>
                      <Box
                        color="label"
                        fontSize="0.8rem"
                        style={ELLIPSIS_STYLE}
                      >
                        {selectedVariant.description || 'No description yet'}
                      </Box>
                      <Box
                        color="label"
                        fontSize="0.75rem"
                        mt="0.25rem"
                        style={ELLIPSIS_STYLE}
                      >
                        Length{' '}
                        {formatDuration(selectedVariant.duration_seconds)} |
                        Source{' '}
                        {selectedVariant.source_url.trim()
                          ? formatSourceLabel(selectedVariant.source_url)
                          : 'Not set'}
                      </Box>
                      <Box mt="0.2rem">
                        {getVariantListBadges(selectedVariant).map((badge) => (
                          <Box key={badge.label} style={badge.style}>
                            {badge.label}
                          </Box>
                        ))}
                      </Box>
                    </Box>
                  </Stack.Item>
                  <Stack.Item>
                    <LabeledList>
                      <LabeledList.Item label="Order">
                        {selectedVariantIndex + 1} of{' '}
                        {selectedTier.variants.length}
                      </LabeledList.Item>
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
                        />
                      </LabeledList.Item>
                      <LabeledList.Item label="Duration">
                        <Box>
                          <NumberInput
                            minValue={0}
                            maxValue={86400}
                            step={1}
                            value={normalizedDuration}
                            onChange={(value) =>
                              onSetVariantDuration(
                                selectedTier.tier_id,
                                selectedVariant.variant_id,
                                value,
                              )
                            }
                          />
                          {!normalizedDuration ? (
                            <Box color="label" fontSize="0.75rem" mt="0.2rem">
                              Unknown duration is allowed, but auto-stop may be
                              unreliable in Single mode.
                            </Box>
                          ) : null}
                        </Box>
                      </LabeledList.Item>
                      <LabeledList.Item label="Source URL">
                        <Box>
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
              )}
            </Section>
          </Stack.Item>
        </Stack>
      )}
    </Section>
  );
}
