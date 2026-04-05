import { useEffect, useRef, useState } from 'react';

import {
  Box,
  Button,
  Collapsible,
  Dropdown,
  Flex,
  Input,
  LabeledList,
  Section,
  Stack,
  TextArea,
} from '../../components';
import {
  ACCENT_DANGER,
  ACCENT_NEUTRAL,
  ACCENT_SUCCESS,
  BG_CARD,
  BG_PANEL,
  BG_PANEL_ALT,
  BORDER,
  COMPACT_CARD_STYLE,
  countTracks,
  CurrentSession,
  DISABLED_ACTION_STYLE,
  DraftPreset,
  DraftStatus,
  DraftTier,
  DraftVariant,
  ELLIPSIS_STYLE,
  findCurrentSessionVariantInTier,
  formatAfterTrackEnds,
  formatDuration,
  formatDurationCompact,
  formatDurationInputValue,
  formatElapsedCompact,
  formatSourceLabel,
  formatTrackCount,
  getListRowStyle,
  getToggleButtonStyle,
  isCurrentSessionForVariant,
  isVariantDurationUnknown,
  isVariantMissingSource,
  LABEL_STYLE,
  LaunchSettings,
  LibraryPreset,
  LIST_SCROLL_STYLE,
  LIVE_BADGE_STYLE,
  MUTED_BADGE_STYLE,
  normalizeDurationValue,
  parseDurationInput,
  PlaybackMode,
  PlaybackSettings,
  PLAYER_BADGE_STYLE,
  PLAYER_CARD_STYLE,
  SelectOption,
  STATUS_STRIP_STYLE,
  SUBTLE_PANEL_STYLE,
  TEXT_MUTED,
  TEXT_PRIMARY,
  TEXT_SECONDARY,
  TrackLaunchReadiness,
  UNSAVED_BADGE_STYLE,
  useBroadcastElapsed,
} from './shared';

type BufferedTextAreaProps = Readonly<{
  syncKey: string | number | null;
  value: string;
  placeholder: string;
  onCommit: (value: string) => void;
  minRows?: number;
  maxRows?: number;
}>;

type BufferedInputProps = Readonly<{
  syncKey: string | number | null;
  value: string;
  placeholder: string;
  onCommit: (value: string) => void;
  monospace?: boolean;
}>;

type BufferedDurationInputProps = Readonly<{
  syncKey: string | number | null;
  value: number;
  onCommit: (value: number) => void;
}>;

function BufferedInput({
  syncKey,
  value,
  placeholder,
  onCommit,
  monospace = false,
}: BufferedInputProps) {
  const [draftValue, setDraftValue] = useState(value);
  const skipNextCommitRef = useRef(false);

  useEffect(() => {
    skipNextCommitRef.current = false;
    setDraftValue(value);
  }, [syncKey, value]);

  return (
    <Input
      key={`${syncKey ?? 'buffered-input'}:${value}`}
      fluid
      monospace={monospace}
      style={EDIT_INPUT_STYLE}
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
    />
  );
}

function BufferedDurationInput({
  syncKey,
  value,
  onCommit,
}: BufferedDurationInputProps) {
  const formattedValue = formatDurationInputValue(value);
  const [draftValue, setDraftValue] = useState(formattedValue);
  const skipNextCommitRef = useRef(false);

  useEffect(() => {
    skipNextCommitRef.current = false;
    setDraftValue(formattedValue);
  }, [formattedValue, syncKey]);

  const resetValue = () => {
    setDraftValue(formattedValue);
  };

  const handleCommit = (nextValue: string) => {
    if (skipNextCommitRef.current) {
      skipNextCommitRef.current = false;
      resetValue();
      return;
    }

    const parsedDuration = parseDurationInput(nextValue);
    if (parsedDuration === null) {
      resetValue();
      return;
    }

    const normalizedDuration = normalizeDurationValue(parsedDuration);
    setDraftValue(formatDurationInputValue(normalizedDuration));
    if (normalizedDuration !== normalizeDurationValue(value)) {
      onCommit(normalizedDuration);
    }
  };

  return (
    <Input
      key={`${syncKey ?? 'buffered-duration'}:${formattedValue}`}
      fluid
      monospace
      style={EDIT_INPUT_STYLE}
      value={draftValue}
      onInput={(e, nextValue) => setDraftValue(nextValue)}
      onChange={(e, nextValue) => handleCommit(nextValue)}
      onEscape={() => {
        skipNextCommitRef.current = true;
        resetValue();
      }}
      placeholder="Seconds or timecode"
    />
  );
}

function BufferedTextArea({
  syncKey,
  value,
  placeholder,
  onCommit,
  minRows = 3,
  maxRows = 7,
}: BufferedTextAreaProps) {
  const [draftValue, setDraftValue] = useState(value);
  const [heightPx, setHeightPx] = useState(minRows * 17);
  const [scrollbar, setScrollbar] = useState(false);
  const skipNextCommitRef = useRef(false);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  useEffect(() => {
    skipNextCommitRef.current = false;
    setDraftValue(value);
  }, [syncKey, value]);

  useEffect(() => {
    const textarea = textareaRef.current;
    if (!textarea) {
      return;
    }

    const computedStyles = window.getComputedStyle(textarea);
    const lineHeight =
      Number.parseFloat(computedStyles.lineHeight) ||
      Number.parseFloat(computedStyles.fontSize) * 1.35 ||
      17;
    const minHeight = Math.ceil(lineHeight * minRows);
    const maxHeight = Math.ceil(lineHeight * maxRows);
    const previousInlineHeight = textarea.style.height;

    textarea.style.height = '0px';
    const contentHeight = Math.ceil(textarea.scrollHeight);
    textarea.style.height = previousInlineHeight;
    const nextHeight = Math.max(minHeight, Math.min(contentHeight, maxHeight));

    setHeightPx(nextHeight);
    setScrollbar(contentHeight > maxHeight);
  }, [draftValue, minRows, maxRows, syncKey]);

  return (
    <TextArea
      ref={textareaRef}
      fluid
      height={`${heightPx}px`}
      style={EDIT_INPUT_STYLE}
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
      scrollbar={scrollbar}
    />
  );
}

const getDraftStatusBadgeStyle = (kind: DraftStatus['kind']) => {
  switch (kind) {
    case 'loaded_preset':
      return LIVE_BADGE_STYLE;
    case 'modified_copy':
      return UNSAVED_BADGE_STYLE;
    case 'unsaved_draft':
    default:
      return PLAYER_BADGE_STYLE;
  }
};

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
  border: '1px solid rgba(255, 208, 102, 0.4)',
  backgroundColor: 'rgba(255, 208, 102, 0.14)',
};

const SEGMENTED_GROUP_STYLE = {
  display: 'flex',
  alignItems: 'center',
  gap: '0.08rem',
  width: '100%',
  padding: '0.1rem',
  borderRadius: '0.42rem',
  border: `1px solid ${BORDER}`,
  backgroundColor: BG_PANEL,
};

const HEADER_ACTION_BUTTON_STYLE = {
  minWidth: '6rem',
};

const ADVANCED_TOGGLE_STYLE = {
  border: `1px solid rgba(51, 69, 87, 0.78)`,
  backgroundColor: BG_PANEL,
};

const EDIT_PANEL_CARD_STYLE = {
  ...SUBTLE_PANEL_STYLE,
  backgroundColor: BG_PANEL,
  border: '1px solid rgba(51, 69, 87, 0.78)',
  padding: '0.62rem 0.7rem',
};

const EDIT_PANEL_CARD_HEADING_STYLE = {
  marginBottom: '0.45rem',
};

const PLAY_CONTEXT_META_STYLE = {
  display: 'inline-block',
  padding: '0.06rem 0.34rem',
  marginRight: '0.24rem',
  marginBottom: '0.16rem',
  borderRadius: '999px',
  border: `1px solid ${BORDER}`,
  backgroundColor: BG_PANEL_ALT,
  fontSize: '0.71rem',
  color: TEXT_SECONDARY,
};

const PLAY_FACTS_AND_STATUS_ROW_STYLE = {
  display: 'flex',
  flexWrap: 'wrap',
  alignItems: 'center',
  gap: '0.24rem 0.5rem',
  width: '100%',
  minWidth: '0',
};

const PLAY_FACTS_GROUP_STYLE = {
  display: 'flex',
  flexWrap: 'wrap',
  alignItems: 'center',
  gap: '0.16rem 0.24rem',
  minWidth: '0',
  flex: '1 1 auto',
};

const PLAY_STATUS_BAR_ITEM_STYLE = {
  minWidth: '0',
  width: '100%',
  flex: '1 1 100%',
};

const PLAY_CONTROLS_ROW_STYLE = {
  display: 'flex',
  flexWrap: 'wrap',
  alignItems: 'stretch',
  gap: '0.45rem',
  width: '100%',
  minWidth: '0',
};

const PLAY_TOOLBAR_TOGGLE_STYLE = (checked: boolean) => ({
  ...getCompactToggleStyle(checked),
  width: '100%',
  minHeight: '2rem',
  textAlign: 'center',
});

const PLAY_SETTINGS_LABEL_STYLE = {
  ...LABEL_STYLE,
  fontSize: '0.72rem',
  marginBottom: '0.08rem',
};

const CONTROL_BUTTON_STYLE = {
  minHeight: '1.9rem',
};

const getPreviewActionStyle = (
  isActive: boolean,
  disabled: boolean,
): Record<string, string> => ({
  border: isActive ? `1px solid ${ACCENT_NEUTRAL}` : `1px solid ${BORDER}`,
  backgroundColor: isActive ? 'rgba(78, 102, 130, 0.26)' : BG_CARD,
  color: TEXT_PRIMARY,
  ...(disabled ? DISABLED_ACTION_STYLE : {}),
});

const getStopActionStyle = (disabled: boolean): Record<string, string> => ({
  border: `1px solid ${ACCENT_DANGER}`,
  backgroundColor: 'rgba(201, 58, 58, 0.12)',
  color: TEXT_PRIMARY,
  ...(disabled ? DISABLED_ACTION_STYLE : {}),
});

const getTertiaryActionStyle = (disabled = false): Record<string, string> => ({
  border: `1px solid ${BORDER}`,
  backgroundColor: BG_CARD,
  color: TEXT_SECONDARY,
  ...(disabled ? DISABLED_ACTION_STYLE : {}),
});

const getCompactToggleStyle = (checked: boolean): Record<string, string> => ({
  ...getToggleButtonStyle(checked),
  minHeight: '2rem',
  textAlign: 'center',
});

const getSubtleCompactToggleStyle = (
  checked: boolean,
): Record<string, string> => ({
  ...getCompactToggleStyle(checked),
  backgroundColor: checked ? 'rgba(78, 102, 130, 0.14)' : BG_PANEL,
  border: `1px solid ${checked ? ACCENT_NEUTRAL : BORDER}`,
  boxShadow: 'none',
});

const getSegmentedButtonStyle = (
  selected: boolean,
  disabled: boolean,
  subtle = false,
): Record<string, string> => ({
  border: selected ? `1px solid ${ACCENT_NEUTRAL}` : '1px solid transparent',
  backgroundColor: selected
    ? subtle
      ? 'rgba(78, 102, 130, 0.14)'
      : 'rgba(78, 102, 130, 0.26)'
    : subtle
      ? BG_PANEL
      : BG_PANEL,
  color: selected ? TEXT_PRIMARY : TEXT_SECONDARY,
  boxShadow: selected ? 'inset 0 0 0 1px rgba(255, 255, 255, 0.04)' : 'none',
  textAlign: 'center',
  ...(disabled ? DISABLED_ACTION_STYLE : {}),
});

const TRACKS_FILTER_BAR_STYLE = {
  ...STATUS_STRIP_STYLE,
  padding: '0.3rem 0.42rem',
};

const TRACK_LIST_SCROLL_STYLE = {
  ...LIST_SCROLL_STYLE,
  height: 'min(100%, 28rem)',
  maxHeight: '28rem',
};

const LAUNCH_STATUS_PANEL_STYLE = {
  ...SUBTLE_PANEL_STYLE,
  padding: '0.34rem 0.58rem',
  minWidth: '0',
  width: '100%',
};

const OPERATOR_STATUS_PANEL_STYLE = {
  borderTop: `1px solid ${BORDER}`,
  backgroundColor: BG_PANEL_ALT,
  borderRadius: '0.32rem',
  padding: '0.26rem 0.36rem',
};

const RESPONSIVE_HEADER_ROW_STYLE = {
  gap: '0.35rem 0.5rem',
};

const RESPONSIVE_ACTION_GROUP_STYLE = {
  display: 'flex',
  flexWrap: 'wrap',
  justifyContent: 'flex-end',
  alignItems: 'center',
  gap: '0.28rem',
  minWidth: '0',
};

const INSPECTOR_TARGET_TEXT_STYLE = {
  color: TEXT_SECONDARY,
  fontSize: '0.82rem',
  fontWeight: '600',
  lineHeight: '1.2',
};

const LAUNCH_STATUS_SEGMENTS_STYLE = {
  display: 'flex',
  flexWrap: 'wrap',
  alignItems: 'center',
  gap: '0.14rem 0.5rem',
  minWidth: '0',
};

const LAUNCH_STATUS_SEGMENT_STYLE = {
  color: TEXT_SECONDARY,
  fontSize: '0.74rem',
  whiteSpace: 'nowrap',
  lineHeight: '1.22',
};

const FOCUS_FACTS_COLUMN_STYLE = {
  ...SUBTLE_PANEL_STYLE,
  padding: '0.46rem 0.62rem',
  minHeight: '100%',
};

const FOCUS_FACTS_GRID_STYLE = {
  display: 'grid',
  gridTemplateColumns: 'minmax(0, 1fr) minmax(0, 1fr)',
  columnGap: '0.75rem',
  rowGap: '0.18rem',
  width: '100%',
  minWidth: '0',
};

const FOCUS_FACTS_SUBCOLUMN_STYLE = {
  minWidth: '0',
  width: '100%',
};

const FOCUS_FACT_LINE_STYLE = {
  fontSize: '0.76rem',
  color: TEXT_SECONDARY,
  lineHeight: '1.25',
  whiteSpace: 'normal',
  wordBreak: 'break-word',
};

const FOCUS_FACT_VALUE_STYLE = {
  color: TEXT_PRIMARY,
};

const FOCUS_FACTS_STATUS_ROW_STYLE = {
  marginTop: '0.18rem',
  paddingTop: '0.18rem',
  borderTop: `1px solid ${BORDER}`,
};

const WRAPPING_TOGGLE_BUTTON_STYLE = (checked: boolean) => ({
  ...getCompactToggleStyle(checked),
  width: '100%',
  minWidth: '0',
  minHeight: '2.2rem',
  whiteSpace: 'normal',
  lineHeight: '1.2',
  textAlign: 'left',
  justifyContent: 'flex-start',
});

const TRACK_TITLE_TEXT_STYLE = {
  ...ELLIPSIS_STYLE,
  color: TEXT_PRIMARY,
};

const TRACK_DESCRIPTION_BLOCK_STYLE = {
  color: TEXT_MUTED,
  lineHeight: '1.28',
  whiteSpace: 'pre-wrap',
  wordBreak: 'break-word',
  overflowWrap: 'anywhere',
  minWidth: '0',
  width: '100%',
  maxWidth: '100%',
};

const TRACK_DENSE_LINE_STYLE = {
  display: 'flex',
  alignItems: 'baseline',
  width: '100%',
  maxWidth: '100%',
  minWidth: '0',
};

const TRACK_DENSE_TEXT_STYLE = {
  flex: '1 1 auto',
  overflow: 'hidden',
  textOverflow: 'ellipsis',
  whiteSpace: 'nowrap',
  width: '100%',
  maxWidth: '100%',
  minWidth: '0',
};

const TRACK_DENSE_TITLE_SPAN_STYLE = {
  color: TEXT_PRIMARY,
  fontWeight: '700',
};

const TRACK_DENSE_DESCRIPTION_SPAN_STYLE = {
  color: TEXT_MUTED,
};

const SECTION_SURFACE_STYLE = {
  backgroundColor: BG_PANEL,
  border: `1px solid ${BORDER}`,
};

const INSPECTOR_ACTION_BUTTON_STYLE = {
  minWidth: '6.9rem',
  justifyContent: 'center',
};

const STRUCTURE_ACTION_BUTTON_STYLE = {
  minWidth: '5.8rem',
  justifyContent: 'center',
};

const EDIT_FIELD_WRAPPER_STYLE = {
  width: '100%',
  maxWidth: '100%',
  minWidth: '0',
  overflow: 'hidden',
};

const EDIT_INPUT_STYLE = {
  boxSizing: 'border-box',
  width: '100%',
  maxWidth: '100%',
  minWidth: '0',
  backgroundColor: BG_PANEL,
  color: TEXT_PRIMARY,
  border: `1px solid ${BORDER}`,
  borderRadius: '0.32rem',
  boxShadow: 'inset 0 1px 0 rgba(255, 255, 255, 0.015)',
};

const FULL_WIDTH_CLAMP_STYLE = {
  width: '100%',
  maxWidth: '100%',
  minWidth: '0',
  overflow: 'hidden',
};

const TRACK_ROW_LEFT_STYLE = {
  minWidth: '0',
  overflow: 'hidden',
};

const INSPECTOR_CARD_STYLE = {
  ...COMPACT_CARD_STYLE,
  backgroundColor: 'rgba(43, 58, 76, 0.84)',
  border: '1px solid rgba(51, 69, 87, 0.84)',
  width: '100%',
  maxWidth: '100%',
  minWidth: '0',
  overflow: 'hidden',
};

const getTrackRowStyle = (
  selected: boolean,
  dense: boolean,
  isLive: boolean,
): Record<string, string> => ({
  ...getListRowStyle(selected),
  width: '100%',
  maxWidth: '100%',
  minWidth: '0',
  overflow: 'hidden',
  ...(dense
    ? {
        marginBottom: '0.12rem',
        padding: '0.2rem 0.38rem',
      }
    : {}),
  ...(!selected && isLive
    ? {
        border: '1px solid rgba(120, 190, 100, 0.34)',
      }
    : {}),
});

const matchesTrackSearch = (variant: DraftVariant, searchText: string) => {
  const normalizedSearch = searchText.trim().toLowerCase();
  if (!normalizedSearch) {
    return true;
  }

  const haystack = [
    variant.title,
    variant.description,
    variant.source_url,
    formatSourceLabel(variant.source_url),
  ]
    .join(' ')
    .toLowerCase();

  return haystack.includes(normalizedSearch);
};

const getLibraryRowStyle = (loaded: boolean) => ({
  ...getListRowStyle(false),
  ...(loaded
    ? {
        border: '1px solid rgba(137, 171, 214, 0.24)',
        backgroundColor: 'rgba(102, 131, 171, 0.12)',
      }
    : {}),
});

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

type LaunchContextBadge = Readonly<{
  key: string;
  text: string;
  style?: Record<string, string>;
}>;

function getLaunchContextFactBadges(
  contextFacts: CompactFactItem[],
): LaunchContextBadge[] {
  return contextFacts.map((item) => ({
    key: item.label,
    text: `${item.label}: ${item.value}`,
  }));
}

type LaunchStatusSummaryProps = Readonly<{
  launchStateText: string;
  previewStateText: string;
  trackReadiness: TrackLaunchReadiness;
}>;

function LaunchStatusSummary({
  launchStateText,
  previewStateText,
  trackReadiness,
}: LaunchStatusSummaryProps) {
  const segments = [
    `Status: ${launchStateText}`,
    `Preview: ${previewStateText}`,
  ];

  if (trackReadiness.reason) {
    segments.push(`Blocked: ${trackReadiness.reason}`);
  }

  if (trackReadiness.warnings.length) {
    segments.push(`Warning: ${trackReadiness.warnings[0]}`);
  }

  return (
    <Box style={LAUNCH_STATUS_PANEL_STYLE}>
      <Flex wrap width="100%" style={LAUNCH_STATUS_SEGMENTS_STYLE}>
        {segments.map((segment) => (
          <Flex.Item key={segment} style={{ minWidth: '0', flex: '0 1 auto' }}>
            <Box style={LAUNCH_STATUS_SEGMENT_STYLE}>{segment}</Box>
          </Flex.Item>
        ))}
      </Flex>
    </Box>
  );
}

type LaunchFactsAndStatusRowProps = Readonly<{
  facts: LaunchContextBadge[];
  launchStateText: string;
  previewStateText: string;
  trackReadiness: TrackLaunchReadiness;
  mt?: string | number;
}>;

function LaunchFactsAndStatusRow({
  facts,
  launchStateText,
  previewStateText,
  trackReadiness,
  mt = '0.1rem',
}: LaunchFactsAndStatusRowProps) {
  return (
    <Box mt={mt}>
      <Flex width="100%" style={PLAY_FACTS_AND_STATUS_ROW_STYLE}>
        <Flex.Item style={PLAY_FACTS_GROUP_STYLE}>
          {facts.map((item) => (
            <Box
              key={item.key}
              style={item.style ? item.style : PLAY_CONTEXT_META_STYLE}
            >
              {item.text}
            </Box>
          ))}
        </Flex.Item>
        <Flex.Item style={PLAY_STATUS_BAR_ITEM_STYLE}>
          <LaunchStatusSummary
            launchStateText={launchStateText}
            previewStateText={previewStateText}
            trackReadiness={trackReadiness}
          />
        </Flex.Item>
      </Flex>
    </Box>
  );
}

type LaunchFactsRowProps = Readonly<{
  facts: LaunchContextBadge[];
  mt?: string | number;
}>;

function LaunchFactsRow({ facts, mt = '0.1rem' }: LaunchFactsRowProps) {
  return (
    <Box mt={mt}>
      <Flex width="100%" style={PLAY_FACTS_AND_STATUS_ROW_STYLE}>
        <Flex.Item style={PLAY_FACTS_GROUP_STYLE}>
          {facts.map((item) => (
            <Box
              key={item.key}
              style={item.style ? item.style : PLAY_CONTEXT_META_STYLE}
            >
              {item.text}
            </Box>
          ))}
        </Flex.Item>
      </Flex>
    </Box>
  );
}

type FocusLaunchFactsColumnProps = Readonly<{
  facts: CompactFactItem[];
  launchStateText: string;
  previewStateText: string;
  trackReadiness: TrackLaunchReadiness;
}>;

function FocusLaunchFactsColumn({
  facts,
  launchStateText,
  previewStateText,
  trackReadiness,
}: FocusLaunchFactsColumnProps) {
  const sourceFact = facts.find((item) => item.label === 'Source');
  const leftColumnLines = [
    ...facts
      .filter(
        (item) =>
          item.label !== 'Source' &&
          item.label !== 'Status' &&
          item.label !== 'Preview',
      )
      .map((item) => ({ label: item.label, value: item.value })),
  ];
  const rightColumnLines = [
    ...(sourceFact
      ? [{ label: sourceFact.label, value: sourceFact.value }]
      : []),
    { label: 'Preview', value: previewStateText },
  ];

  return (
    <Box style={FOCUS_FACTS_COLUMN_STYLE}>
      <Box style={FOCUS_FACTS_GRID_STYLE}>
        <Box style={FOCUS_FACTS_SUBCOLUMN_STYLE}>
          {leftColumnLines.map((line) => (
            <Box
              key={`${line.label}:${line.value}`}
              mb="0.12rem"
              style={FOCUS_FACT_LINE_STYLE}
            >
              {line.label}:{' '}
              <span style={FOCUS_FACT_VALUE_STYLE}>{line.value}</span>
            </Box>
          ))}
        </Box>
        <Box style={FOCUS_FACTS_SUBCOLUMN_STYLE}>
          {rightColumnLines.map((line) => (
            <Box
              key={`${line.label}:${line.value}`}
              mb="0.12rem"
              style={FOCUS_FACT_LINE_STYLE}
            >
              {line.label}:{' '}
              <span style={FOCUS_FACT_VALUE_STYLE}>{line.value}</span>
            </Box>
          ))}
        </Box>
      </Box>
      <Box style={FOCUS_FACTS_STATUS_ROW_STYLE}>
        <Box style={FOCUS_FACT_LINE_STYLE}>
          Status: <span style={FOCUS_FACT_VALUE_STYLE}>{launchStateText}</span>
        </Box>
        {trackReadiness.reason ? (
          <Box mt="0.1rem" style={FOCUS_FACT_LINE_STYLE}>
            Blocked:{' '}
            <span style={FOCUS_FACT_VALUE_STYLE}>{trackReadiness.reason}</span>
          </Box>
        ) : null}
        {trackReadiness.warnings.length ? (
          <Box mt="0.1rem" style={FOCUS_FACT_LINE_STYLE}>
            Warning:{' '}
            <span style={FOCUS_FACT_VALUE_STYLE}>
              {trackReadiness.warnings[0]}
            </span>
          </Box>
        ) : null}
      </Box>
    </Box>
  );
}

const getVariantListBadges = (variant: DraftVariant, isLive = false) => {
  const badges: Array<{
    label: string;
    style: Record<string, string>;
  }> = [];

  if (isLive) {
    badges.push({
      label: 'Live',
      style: LIVE_BADGE_STYLE,
    });
  }

  if (isVariantMissingSource(variant)) {
    badges.push({
      label: 'No source',
      style: WARNING_BADGE_STYLE,
    });
  }

  if (isVariantDurationUnknown(variant)) {
    badges.push({
      label: 'Unknown duration',
      style: LIST_BADGE_STYLE,
    });
  }

  return badges;
};

const getTrackDetailBadges = (variant: DraftVariant, isLive = false) => {
  const badges = [...getVariantListBadges(variant, isLive)];

  if (!isVariantMissingSource(variant)) {
    badges.unshift({
      label: `Source: ${formatSourceLabel(variant.source_url)}`,
      style: MUTED_BADGE_STYLE,
    });
  }

  return badges;
};

type TrackTextBlockProps = Readonly<{
  title: string;
  description: string;
  dense: boolean;
}>;

function TrackTextBlock({ title, description, dense }: TrackTextBlockProps) {
  if (dense) {
    return (
      <div
        style={{
          ...TRACK_DENSE_LINE_STYLE,
          fontSize: '0.85rem',
        }}
      >
        <div style={TRACK_DENSE_TEXT_STYLE}>
          <span style={TRACK_DENSE_TITLE_SPAN_STYLE}>{title}</span>
          {description ? (
            <span style={TRACK_DENSE_DESCRIPTION_SPAN_STYLE}>
              {' '}
              - {description}
            </span>
          ) : null}
        </div>
      </div>
    );
  }

  return (
    <>
      <Box bold fontSize="0.92rem" style={TRACK_TITLE_TEXT_STYLE}>
        {title}
      </Box>
      {description ? (
        <Box
          fontSize="0.76rem"
          mt="0.04rem"
          style={TRACK_DESCRIPTION_BLOCK_STYLE}
        >
          {description}
        </Box>
      ) : null}
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

function TracksFocusLaunchStrip({
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
  const [trackSearch, setTrackSearch] = useState('');
  const [denseTracks, setDenseTracks] = useState(false);
  const [showOnlyInvalid, setShowOnlyInvalid] = useState(false);
  const [showOnlyUnknown, setShowOnlyUnknown] = useState(false);
  const [tracksFocus, setTracksFocus] = useState(false);
  const canFocusTracks = Boolean(selectedTier?.variants.length);

  useEffect(() => {
    setTrackSearch('');
    setDenseTracks(false);
    setShowOnlyInvalid(false);
    setShowOnlyUnknown(false);
    setTracksFocus(false);
  }, [draft.preset_id, draft.name]);

  const handleSelectTier = (tier_id: string) => {
    setTrackSearch('');
    setShowOnlyInvalid(false);
    setShowOnlyUnknown(false);
    onSelectTier(tier_id);
  };

  const handleToggleTracksFocus = () => {
    if (!canFocusTracks) {
      return;
    }
    setTracksFocus((current) => !current);
  };

  if (tracksFocus) {
    return (
      <Stack fill vertical>
        {current_session ? (
          <Stack.Item>
            <BroadcastStatusStrip
              current_session={current_session}
              onStopBroadcast={onStopBroadcast}
            />
          </Stack.Item>
        ) : null}
        <Stack.Item grow={1}>
          <Box mt="0.38rem" style={{ height: '100%' }}>
            <PlayTracksSection
              draft={draft}
              current_session={current_session}
              selectedTier={selectedTier}
              selectedVariantId={selectedVariantId}
              trackSearch={trackSearch}
              denseTracks={denseTracks}
              showOnlyInvalid={showOnlyInvalid}
              showOnlyUnknown={showOnlyUnknown}
              focusMode
              onTrackSearchChange={setTrackSearch}
              onToggleDenseTracks={() => setDenseTracks((current) => !current)}
              onToggleOnlyInvalid={() =>
                setShowOnlyInvalid((current) => !current)
              }
              onToggleOnlyUnknown={() =>
                setShowOnlyUnknown((current) => !current)
              }
              onToggleTracksFocus={handleToggleTracksFocus}
              onSelectVariant={onSelectVariant}
            />
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Box mt="0.38rem">
            <TracksFocusLaunchStrip
              current_session={current_session}
              draft={draft}
              launchSettings={launchSettings}
              audienceOptions={audienceOptions}
              soundTypeOptions={soundTypeOptions}
              audienceLabel={audienceLabel}
              soundTypeLabel={soundTypeLabel}
              selectedTier={selectedTier}
              selectedVariant={selectedVariant}
              trackReadiness={trackReadiness}
              isPreviewActive={isPreviewActive}
              previewState={previewState}
              selectedTrackIsLive={selectedTrackIsLive}
              onSetAudienceMode={onSetAudienceMode}
              onSetSoundType={onSetSoundType}
              onToggleRepeat={onToggleRepeat}
              onSetPlaybackMode={onSetPlaybackMode}
              onResetLaunchSettings={onResetLaunchSettings}
              onPreviewSelected={onPreviewSelected}
              onStopPreview={onStopPreview}
              onPlaySelected={onPlaySelected}
              onStopBroadcast={onStopBroadcast}
            />
          </Box>
        </Stack.Item>
      </Stack>
    );
  }

  return (
    <Stack fill vertical>
      {current_session ? (
        <Stack.Item>
          <BroadcastStatusStrip
            current_session={current_session}
            onStopBroadcast={onStopBroadcast}
          />
        </Stack.Item>
      ) : null}
      <Stack.Item>
        <Box mt="0.38rem">
          <SessionSection
            current_session={current_session}
            draft={draft}
            launchSettings={launchSettings}
            audienceOptions={audienceOptions}
            soundTypeOptions={soundTypeOptions}
            audienceLabel={audienceLabel}
            soundTypeLabel={soundTypeLabel}
            selectedTier={selectedTier}
            selectedVariant={selectedVariant}
            trackReadiness={trackReadiness}
            selectedTrackIsLive={selectedTrackIsLive}
            onSetAudienceMode={onSetAudienceMode}
            onSetSoundType={onSetSoundType}
            onToggleRepeat={onToggleRepeat}
            onSetPlaybackMode={onSetPlaybackMode}
            onResetLaunchSettings={onResetLaunchSettings}
            onPreviewSelected={onPreviewSelected}
            onStopPreview={onStopPreview}
            isPreviewActive={isPreviewActive}
            previewState={previewState}
            onOpenEdit={onOpenEdit}
            onPlaySelected={onPlaySelected}
            onStopBroadcast={onStopBroadcast}
          />
        </Box>
      </Stack.Item>
      <Stack.Item grow={1}>
        <Box mt="0.38rem" style={{ height: '100%' }}>
          <Stack fill>
            <Stack.Item basis="27%" grow={1} style={{ minWidth: '0' }}>
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
            <Stack.Item basis="21%" grow={1} style={{ minWidth: '0' }}>
              <PlayScenesSection
                draft={draft}
                selectedTierId={selectedTierId}
                onSelectTier={handleSelectTier}
              />
            </Stack.Item>
            <Stack.Item basis="52%" grow={2} style={{ minWidth: '0' }}>
              <PlayTracksSection
                draft={draft}
                current_session={current_session}
                selectedTier={selectedTier}
                selectedVariantId={selectedVariantId}
                trackSearch={trackSearch}
                denseTracks={denseTracks}
                showOnlyInvalid={showOnlyInvalid}
                showOnlyUnknown={showOnlyUnknown}
                onTrackSearchChange={setTrackSearch}
                onToggleDenseTracks={() =>
                  setDenseTracks((current) => !current)
                }
                onToggleOnlyInvalid={() =>
                  setShowOnlyInvalid((current) => !current)
                }
                onToggleOnlyUnknown={() =>
                  setShowOnlyUnknown((current) => !current)
                }
                onToggleTracksFocus={handleToggleTracksFocus}
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
  onResolveVariantMetadata: (tier_id: string, variant_id: string) => void;
}>;

type InspectorTarget = 'scene' | 'track';

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
  onResolveVariantMetadata,
}: EditTabProps) {
  const [inspectorTarget, setInspectorTarget] = useState<InspectorTarget>(
    selectedVariant ? 'track' : 'scene',
  );
  const [trackSearch, setTrackSearch] = useState('');
  const [denseTracks, setDenseTracks] = useState(false);
  const [tracksExpanded, setTracksExpanded] = useState(false);
  const [presetEditorRequest, setPresetEditorRequest] = useState(0);

  useEffect(() => {
    setInspectorTarget(selectedVariant ? 'track' : 'scene');
    setTrackSearch('');
    setDenseTracks(false);
    setTracksExpanded(false);
  }, [draftToken]);

  useEffect(() => {
    if (inspectorTarget === 'track' && !selectedVariant) {
      setInspectorTarget('scene');
    }
  }, [inspectorTarget, selectedVariant]);

  const handleSelectTier = (tierId: string) => {
    setInspectorTarget('scene');
    onSelectTier(tierId);
  };

  const handleAddTier = () => {
    setInspectorTarget('scene');
    onAddTier();
  };

  const handleSelectVariant = (tierId: string, variantId: string) => {
    setInspectorTarget('track');
    onSelectVariant(tierId, variantId);
  };

  const handleAddVariant = () => {
    setInspectorTarget('track');
    onAddVariant();
  };

  return (
    <Stack fill vertical>
      <Stack.Item>
        <EditHeaderSection
          draft={draft}
          draftStatus={draftStatus}
          canRevert={canRevert}
          onEditPreset={() => setPresetEditorRequest((current) => current + 1)}
          onSave={onSave}
          onSaveAsCopy={onSaveAsCopy}
          onRevert={onRevert}
        />
      </Stack.Item>
      <Stack.Item grow={1}>
        <Box mt="0.38rem" style={{ height: '100%' }}>
          <Stack fill>
            <Stack.Item basis="68%" grow={7} style={{ minWidth: '0' }}>
              <StructureSection
                draft={draft}
                selectedTier={selectedTier}
                selectedTierId={selectedTierId}
                selectedVariant={selectedVariant}
                selectedVariantId={selectedVariantId}
                trackSearch={trackSearch}
                denseTracks={denseTracks}
                tracksExpanded={tracksExpanded}
                onAddTier={handleAddTier}
                onSelectTier={handleSelectTier}
                onMoveTierUp={onMoveTierUp}
                onMoveTierDown={onMoveTierDown}
                onAddVariant={handleAddVariant}
                onTrackSearchChange={setTrackSearch}
                onToggleDenseTracks={() =>
                  setDenseTracks((current) => !current)
                }
                onToggleTracksExpanded={() =>
                  setTracksExpanded((current) => !current)
                }
                onSelectVariant={handleSelectVariant}
                onMoveVariantUp={onMoveVariantUp}
                onMoveVariantDown={onMoveVariantDown}
              />
            </Stack.Item>
            <Stack.Item basis="32%" grow={3} style={{ minWidth: '0' }}>
              <EditPanelSection
                draft={draft}
                draftToken={draftToken}
                presetEditorRequest={presetEditorRequest}
                audienceOptions={audienceOptions}
                soundTypeOptions={soundTypeOptions}
                audienceLabel={audienceLabel}
                soundTypeLabel={soundTypeLabel}
                inspectorTarget={inspectorTarget}
                selectedTier={selectedTier}
                selectedVariant={selectedVariant}
                canDelete={canDelete}
                onNew={onNew}
                onDelete={onDelete}
                onExport={onExport}
                onImport={onImport}
                onSetName={onSetName}
                onSetDescription={onSetDescription}
                onSetAudienceMode={onSetAudienceMode}
                onSetSoundType={onSetSoundType}
                onToggleShowTitle={onToggleShowTitle}
                onToggleRepeat={onToggleRepeat}
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
  showVisibilityToggle?: boolean;
  visibilityInline?: boolean;
  wrapToggleRow?: boolean;
  inlineDropdownLabels?: boolean;
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
  showVisibilityToggle = true,
  visibilityInline = false,
  wrapToggleRow = false,
  inlineDropdownLabels = false,
}: PlaybackSettingsControlsProps) {
  return (
    <Stack vertical>
      <Stack.Item>
        <Stack fill>
          <Stack.Item basis={visibilityInline ? '38%' : '50%'} grow={1}>
            {!inlineDropdownLabels ? (
              <Box style={PLAY_SETTINGS_LABEL_STYLE}>Audience</Box>
            ) : null}
            <Dropdown
              width="100%"
              color="transparent"
              className="AdminMusicPanel__dropdownControl"
              options={audienceOptions}
              selected={playback.audience_mode}
              displayText={
                inlineDropdownLabels
                  ? `Audience: ${audienceLabel}`
                  : audienceLabel
              }
              onSelected={(value) => onSetAudienceMode(value)}
            />
          </Stack.Item>
          <Stack.Item basis={visibilityInline ? '38%' : '50%'} grow={1}>
            {!inlineDropdownLabels ? (
              <Box style={PLAY_SETTINGS_LABEL_STYLE}>Sound Type</Box>
            ) : null}
            <Dropdown
              width="100%"
              color="transparent"
              className="AdminMusicPanel__dropdownControl"
              options={soundTypeOptions}
              selected={playback.sound_type}
              displayText={
                inlineDropdownLabels
                  ? `Sound Type: ${soundTypeLabel}`
                  : soundTypeLabel
              }
              onSelected={(value) => onSetSoundType(value)}
            />
          </Stack.Item>
          {visibilityInline && showVisibilityToggle ? (
            <Stack.Item basis="24%" grow={1}>
              <Box style={PLAY_SETTINGS_LABEL_STYLE}>Players Visible</Box>
              <Button.Checkbox
                compact
                fluid
                checked={playback.show_title_to_players}
                style={getCompactToggleStyle(playback.show_title_to_players)}
                onClick={onToggleShowTitle}
              >
                {playback.show_title_to_players ? 'Visible' : 'Hidden'}
              </Button.Checkbox>
            </Stack.Item>
          ) : null}
        </Stack>
      </Stack.Item>
      {(!visibilityInline && showVisibilityToggle) || showRepeatToggle ? (
        <Stack.Item>
          {wrapToggleRow ? (
            <Flex wrap width="100%" style={{ gap: '0.3rem' }}>
              {!visibilityInline && showVisibilityToggle ? (
                <Flex.Item
                  grow
                  basis="13rem"
                  style={{ minWidth: '0', flex: '1 1 13rem' }}
                >
                  <Button.Checkbox
                    compact
                    fluid
                    checked={playback.show_title_to_players}
                    style={WRAPPING_TOGGLE_BUTTON_STYLE(
                      playback.show_title_to_players,
                    )}
                    onClick={onToggleShowTitle}
                  >
                    Visible to players
                  </Button.Checkbox>
                </Flex.Item>
              ) : null}
              {showRepeatToggle ? (
                <Flex.Item
                  grow
                  basis="13rem"
                  style={{ minWidth: '0', flex: '1 1 13rem' }}
                >
                  <Button.Checkbox
                    compact
                    fluid
                    checked={playback.repeat}
                    style={WRAPPING_TOGGLE_BUTTON_STYLE(playback.repeat)}
                    onClick={onToggleRepeat}
                  >
                    Repeat until stopped
                  </Button.Checkbox>
                </Flex.Item>
              ) : null}
            </Flex>
          ) : (
            <Stack fill>
              {!visibilityInline && showVisibilityToggle ? (
                <Stack.Item grow>
                  <Button.Checkbox
                    compact
                    fluid
                    checked={playback.show_title_to_players}
                    style={getCompactToggleStyle(
                      playback.show_title_to_players,
                    )}
                    onClick={onToggleShowTitle}
                  >
                    Visible to players
                  </Button.Checkbox>
                </Stack.Item>
              ) : null}
              {showRepeatToggle ? (
                <Stack.Item grow>
                  <Button.Checkbox
                    compact
                    fluid
                    checked={playback.repeat}
                    style={getCompactToggleStyle(playback.repeat)}
                    onClick={onToggleRepeat}
                  >
                    Repeat until stopped
                  </Button.Checkbox>
                </Stack.Item>
              ) : null}
            </Stack>
          )}
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

function PlayTracksSection({
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

type EditHeaderSectionProps = Readonly<{
  draft: DraftPreset;
  draftStatus: DraftStatus;
  canRevert: boolean;
  onEditPreset: () => void;
  onSave: () => void;
  onSaveAsCopy: () => void;
  onRevert: () => void;
}>;

function EditHeaderSection({
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

function EditPanelSection({
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

function StructureSection({
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
