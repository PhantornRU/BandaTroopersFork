import { storage } from 'common/storage';
import { useEffect, useRef, useState } from 'react';

export type LibraryPreset = {
  preset_id: string;
  name: string;
  description: string;
  tier_count: number;
  variant_count: number;
};

export type DraftVariant = {
  variant_id: string;
  title: string;
  description: string;
  duration_seconds: number;
  source_url: string;
};

export type DraftTier = {
  tier_id: string;
  name: string;
  description: string;
  variants: DraftVariant[];
};

export type PlaybackMode = 'single' | 'ordered' | 'random';

export type PlaybackSettings = {
  audience_mode: string;
  sound_type: string;
  show_title_to_players: boolean;
  repeat: boolean;
};

export type LaunchSettings = PlaybackSettings & {
  playback_mode: PlaybackMode;
};

export type DraftPreset = {
  preset_id: string;
  name: string;
  description: string;
  playback: PlaybackSettings;
  tiers: DraftTier[];
};

export type CurrentSession = null | {
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
  variant_description?: string;
  duration_seconds?: number;
  loop?: boolean;
  playback_mode?: PlaybackMode;
  playback_mode_label?: string;
};

export type OptionEntry = { id: string; label: string };

export type PreviewCommand = null | {
  nonce: number | string;
  command: 'play' | 'stop';
  title?: string;
  url?: string;
  start?: number;
  end?: number;
};

export type AdminMusicPanelData = {
  library: LibraryPreset[];
  draft: DraftPreset;
  draft_token: number;
  dirty: boolean;
  selected_tier_id: string | null;
  selected_variant_id: string | null;
  can_delete_saved_preset: boolean;
  current_session: CurrentSession;
  audience_options: OptionEntry[];
  sound_type_options: OptionEntry[];
  preview_command: PreviewCommand;
};

export type SelectOption = { displayText: string; value: string };

export type DraftStatusKind =
  | 'unsaved_draft'
  | 'loaded_preset'
  | 'modified_copy';

export type DraftStatus = {
  kind: DraftStatusKind;
  label: string;
  hint: string;
};

export type TrackLaunchReadiness = {
  canPreview: boolean;
  canBroadcast: boolean;
  reason: string | null;
  warnings: string[];
};

export const DEFAULT_PREVIEW_VOLUME = 0.2;
export const DESCRIPTION_FIELD_HEIGHT = 4.5;
export const PLAYER_CARD_STYLE = {
  backgroundColor: 'rgba(255, 255, 255, 0.04)',
  border: '1px solid rgba(255, 255, 255, 0.08)',
  borderRadius: '0.35rem',
  padding: '0.75rem',
};
export const COMPACT_CARD_STYLE = {
  backgroundColor: 'rgba(255, 255, 255, 0.035)',
  border: '1px solid rgba(255, 255, 255, 0.07)',
  borderRadius: '0.35rem',
  padding: '0.5rem 0.6rem',
};
export const PLAYER_STRIP_STYLE = {
  background:
    'linear-gradient(90deg, rgba(70, 140, 60, 0.22) 0%, rgba(25, 40, 25, 0.24) 100%)',
  border: '1px solid rgba(120, 190, 100, 0.3)',
  borderRadius: '0.35rem',
  padding: '0.85rem',
};
export const PLAYER_BADGE_STYLE = {
  display: 'inline-block',
  padding: '0.15rem 0.45rem',
  marginRight: '0.35rem',
  marginBottom: '0.35rem',
  borderRadius: '999px',
  border: '1px solid rgba(255, 255, 255, 0.12)',
  backgroundColor: 'rgba(0, 0, 0, 0.18)',
};
export const STATUS_STRIP_STYLE = {
  backgroundColor: 'rgba(255, 255, 255, 0.03)',
  border: '1px solid rgba(255, 255, 255, 0.07)',
  borderRadius: '0.35rem',
  padding: '0.45rem 0.55rem',
};
export const SUBTLE_PANEL_STYLE = {
  backgroundColor: 'rgba(255, 255, 255, 0.02)',
  border: '1px solid rgba(255, 255, 255, 0.05)',
  borderRadius: '0.35rem',
  padding: '0.45rem 0.55rem',
};
export const UNSAVED_BADGE_STYLE = {
  display: 'inline-block',
  padding: '0.15rem 0.45rem',
  borderRadius: '999px',
  border: '1px solid rgba(255, 208, 102, 0.45)',
  backgroundColor: 'rgba(255, 208, 102, 0.12)',
};
export const MUTED_BADGE_STYLE = {
  display: 'inline-block',
  padding: '0.15rem 0.45rem',
  borderRadius: '999px',
  border: '1px solid rgba(255, 255, 255, 0.1)',
  backgroundColor: 'rgba(255, 255, 255, 0.03)',
};
export const LIVE_BADGE_STYLE = {
  display: 'inline-block',
  padding: '0.15rem 0.45rem',
  borderRadius: '999px',
  border: '1px solid rgba(120, 190, 100, 0.35)',
  backgroundColor: 'rgba(70, 140, 60, 0.12)',
};
export const LABEL_STYLE = {
  fontSize: '0.8rem',
  color: 'rgba(214, 223, 233, 0.75)',
};
export const ELLIPSIS_STYLE = {
  overflow: 'hidden',
  textOverflow: 'ellipsis',
  whiteSpace: 'nowrap',
};
export const WRAPPED_TEXT_STYLE = {
  whiteSpace: 'normal',
  wordBreak: 'break-word',
  lineHeight: '1.3',
};
export const LIST_SCROLL_STYLE = {
  height: '100%',
  overflowY: 'auto',
  paddingRight: '0.1rem',
};
export const DISABLED_ACTION_STYLE = {
  opacity: '0.45',
  filter: 'saturate(0.6)',
};

export const getToggleButtonStyle = (checked: boolean) => ({
  border: checked
    ? '1px solid rgba(137, 171, 214, 0.45)'
    : '1px solid rgba(255, 255, 255, 0.07)',
  backgroundColor: checked
    ? 'rgba(102, 131, 171, 0.16)'
    : 'rgba(255, 255, 255, 0.025)',
  color: checked ? 'rgba(244, 248, 252, 0.96)' : 'rgba(214, 223, 233, 0.92)',
});

export const getListRowStyle = (selected: boolean) => ({
  marginBottom: '0.2rem',
  padding: '0.28rem 0.45rem',
  borderRadius: '0.32rem',
  border: selected
    ? '1px solid rgba(137, 171, 214, 0.55)'
    : '1px solid rgba(255, 255, 255, 0.06)',
  backgroundColor: selected
    ? 'rgba(102, 131, 171, 0.22)'
    : 'rgba(255, 255, 255, 0.025)',
});

export const normalizeDurationValue = (duration_seconds: number) => {
  if (!Number.isFinite(duration_seconds) || duration_seconds < 0) {
    return 0;
  }
  return Object.is(duration_seconds, -0) ? 0 : duration_seconds;
};

export const formatDuration = (duration_seconds: number) => {
  const normalizedDuration = normalizeDurationValue(duration_seconds);
  if (!normalizedDuration) {
    return 'Unknown';
  }
  const seconds = Math.floor(normalizedDuration);
  const minutes = Math.floor(seconds / 60);
  const remainder = seconds % 60;
  return minutes
    ? `${minutes}m ${String(remainder).padStart(2, '0')}s`
    : `${remainder}s`;
};

export const formatSourceLabel = (source_url: string) => {
  if (!source_url) {
    return 'Source not set';
  }
  try {
    return new URL(source_url).hostname.replace(/^www\./, '');
  } catch {
    return source_url;
  }
};

export const countTracks = (draft: DraftPreset) =>
  draft.tiers.reduce((total, tier) => total + tier.variants.length, 0);

export const findTier = (draft: DraftPreset, tierId: string | null) =>
  draft.tiers.find((tier) => tier.tier_id === tierId) || draft.tiers[0] || null;

export const findVariant = (tier: DraftTier | null, variantId: string | null) =>
  tier?.variants.find((variant) => variant.variant_id === variantId) ||
  tier?.variants[0] ||
  null;

export const buildLaunchSettings = (draft: DraftPreset): LaunchSettings => ({
  audience_mode: draft.playback.audience_mode,
  sound_type: draft.playback.sound_type,
  show_title_to_players: draft.playback.show_title_to_players,
  repeat: draft.playback.repeat,
  playback_mode: 'single',
});

export const getDraftStatus = (
  draft: DraftPreset,
  dirty: boolean,
): DraftStatus => {
  if (!draft.preset_id) {
    return {
      kind: 'unsaved_draft',
      label: 'Draft',
      hint: 'Not saved to the preset library yet',
    };
  }

  if (dirty) {
    return {
      kind: 'modified_copy',
      label: 'Unsaved changes',
      hint: `Loaded preset ${draft.preset_id} has local edits`,
    };
  }

  return {
    kind: 'loaded_preset',
    label: 'Saved',
    hint: `Loaded preset ${draft.preset_id} is ready to edit`,
  };
};

export const getOptionLabel = (options: OptionEntry[], value: string) =>
  options.find((option) => option.id === value)?.label || value;

export const toSelectOptions = (options: OptionEntry[]): SelectOption[] =>
  options.map((option) => ({
    displayText: option.label,
    value: option.id,
  }));

export const formatTrackCount = (count: number) =>
  `${count} track${count === 1 ? '' : 's'}`;

export const formatVisibilitySummary = (showTitleToPlayers: boolean) =>
  showTitleToPlayers ? 'Title visible to players' : 'Title hidden from players';

export const getPlaybackModeLabel = (
  playbackMode: PlaybackMode | string | undefined,
) => {
  switch (playbackMode) {
    case 'random':
      return 'Random';
    case 'ordered':
      return 'In order';
    case 'single':
    default:
      return 'Single';
  }
};

export const formatAfterTrackEnds = (
  repeat: boolean,
  playbackMode: PlaybackMode | string | undefined,
) =>
  repeat
    ? 'Repeat the current track'
    : playbackMode === 'single'
      ? 'Stop after this track'
      : `Continue ${getPlaybackModeLabel(playbackMode).toLowerCase()}`;

export const getTrackLaunchReadiness = (
  selectedVariant: DraftVariant | null,
  launchSettings: LaunchSettings,
): TrackLaunchReadiness => {
  if (!selectedVariant) {
    return {
      canPreview: false,
      canBroadcast: false,
      reason: 'Select a track to preview or broadcast.',
      warnings: [],
    };
  }

  const sourceUrl = selectedVariant.source_url.trim();
  if (!sourceUrl) {
    return {
      canPreview: false,
      canBroadcast: false,
      reason: 'Source URL is missing.',
      warnings: [],
    };
  }

  const warnings: string[] = [];
  if (!normalizeDurationValue(selectedVariant.duration_seconds)) {
    warnings.push(
      launchSettings.playback_mode === 'single' && !launchSettings.repeat
        ? 'Duration is unknown, so Single may not stop automatically.'
        : 'Duration is unknown.',
    );
  }

  return {
    canPreview: true,
    canBroadcast: true,
    reason: null,
    warnings,
  };
};

export const isCurrentSessionForSelection = (
  currentSession: CurrentSession,
  draft: DraftPreset,
  selectedTier: DraftTier | null,
  selectedVariant: DraftVariant | null,
) => {
  if (!currentSession || !selectedTier || !selectedVariant) {
    return false;
  }

  const matchesByPreset =
    Boolean(currentSession.preset_id) &&
    Boolean(draft.preset_id) &&
    currentSession.preset_id === draft.preset_id &&
    currentSession.tier_name === selectedTier.name &&
    currentSession.variant_title === selectedVariant.title;

  const matchesBySource =
    Boolean(currentSession.source_url) &&
    Boolean(selectedVariant.source_url) &&
    currentSession.source_url === selectedVariant.source_url;

  return matchesByPreset || matchesBySource;
};

export const useAdminMusicPreview = (
  previewCommand: PreviewCommand,
  onStopPreviewCommand: () => void,
) => {
  const [previewVolume, setPreviewVolume] = useState(DEFAULT_PREVIEW_VOLUME);
  const [previewState, setPreviewState] = useState('Idle');
  const [isPreviewActive, setIsPreviewActive] = useState(false);

  const previewAudioRef = useRef<HTMLAudioElement | null>(null);
  const previewVolumeRef = useRef(DEFAULT_PREVIEW_VOLUME);
  const previewKeyRef = useRef<string>('');

  const clearPreviewAudio = () => {
    const audio = previewAudioRef.current;
    if (audio) {
      audio.pause();
      audio.src = '';
      previewAudioRef.current = null;
    }
  };

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

  useEffect(
    () => () => {
      clearPreviewAudio();
    },
    [],
  );

  useEffect(() => {
    if (!previewCommand) {
      return;
    }

    const key = `${previewCommand.nonce}:${previewCommand.command}`;
    if (previewKeyRef.current === key) {
      return;
    }
    previewKeyRef.current = key;

    const stopPreviewAudio = (status = 'Preview stopped') => {
      clearPreviewAudio();
      setIsPreviewActive(false);
      setPreviewState(status);
    };

    if (previewCommand.command === 'stop') {
      stopPreviewAudio();
      return;
    }

    if (!previewCommand.url) {
      stopPreviewAudio('Preview unavailable');
      return;
    }

    clearPreviewAudio();
    setIsPreviewActive(true);
    setPreviewState('Loading preview...');
    const audio = new Audio(previewCommand.url);
    previewAudioRef.current = audio;
    audio.volume = previewVolumeRef.current;

    const start = Math.max(0, previewCommand.start || 0);
    const end =
      typeof previewCommand.end === 'number' && previewCommand.end > start
        ? previewCommand.end
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
      setIsPreviewActive(false);
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
            setIsPreviewActive(true);
            setPreviewState(previewCommand.title || 'Preview playing');
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
  }, [previewCommand]);

  const stopPreview = () => {
    clearPreviewAudio();
    previewKeyRef.current = '';
    setIsPreviewActive(false);
    setPreviewState('Preview stopped');
    onStopPreviewCommand();
  };

  return {
    isPreviewActive,
    previewState,
    previewVolume,
    stopPreview,
  };
};
