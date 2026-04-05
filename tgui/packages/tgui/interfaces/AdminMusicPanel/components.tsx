import { useEffect, useRef, useState } from 'react';

import {
  Box,
  Button,
  Dropdown,
  Flex,
  Input,
  Stack,
  TextArea,
} from '../../components';
import {
  ACCENT_DANGER,
  ACCENT_NEUTRAL,
  BG_CARD,
  BG_PANEL,
  BG_PANEL_ALT,
  BORDER,
  COMPACT_CARD_STYLE,
  DISABLED_ACTION_STYLE,
  DraftStatus,
  DraftVariant,
  ELLIPSIS_STYLE,
  formatDurationInputValue,
  formatSourceLabel,
  getListRowStyle,
  getToggleButtonStyle,
  isVariantDurationUnknown,
  isVariantMissingSource,
  LABEL_STYLE,
  LIST_SCROLL_STYLE,
  LIVE_BADGE_STYLE,
  MUTED_BADGE_STYLE,
  normalizeDurationValue,
  parseDurationInput,
  PlaybackSettings,
  PLAYER_BADGE_STYLE,
  SelectOption,
  STATUS_STRIP_STYLE,
  SUBTLE_PANEL_STYLE,
  TEXT_MUTED,
  TEXT_PRIMARY,
  TEXT_SECONDARY,
  TrackLaunchReadiness,
  UNSAVED_BADGE_STYLE,
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

export {
  ADVANCED_TOGGLE_STYLE,
  BufferedDurationInput,
  BufferedInput,
  BufferedTextArea,
  CONTROL_BUTTON_STYLE,
  EDIT_FIELD_WRAPPER_STYLE,
  EDIT_PANEL_CARD_HEADING_STYLE,
  EDIT_PANEL_CARD_STYLE,
  FocusLaunchFactsColumn,
  FULL_WIDTH_CLAMP_STYLE,
  getCompactToggleStyle,
  getDraftStatusBadgeStyle,
  getLaunchContextFactBadges,
  getLibraryRowStyle,
  getPreviewActionStyle,
  getSegmentedButtonStyle,
  getStopActionStyle,
  getSubtleCompactToggleStyle,
  getTertiaryActionStyle,
  getTrackDetailBadges,
  getTrackRowStyle,
  getVariantListBadges,
  HEADER_ACTION_BUTTON_STYLE,
  INSPECTOR_ACTION_BUTTON_STYLE,
  INSPECTOR_CARD_STYLE,
  INSPECTOR_TARGET_TEXT_STYLE,
  LaunchFactsRow,
  LaunchStatusSummary,
  matchesTrackSearch,
  OPERATOR_STATUS_PANEL_STYLE,
  PLAY_CONTROLS_ROW_STYLE,
  PLAY_TOOLBAR_TOGGLE_STYLE,
  PlaybackSettingsControls,
  RESPONSIVE_ACTION_GROUP_STYLE,
  RESPONSIVE_HEADER_ROW_STYLE,
  SECTION_SURFACE_STYLE,
  SEGMENTED_GROUP_STYLE,
  STRUCTURE_ACTION_BUTTON_STYLE,
  TRACK_LIST_SCROLL_STYLE,
  TRACK_ROW_LEFT_STYLE,
  TrackFactBadges,
  TRACKS_FILTER_BAR_STYLE,
  TrackTextBlock,
};
