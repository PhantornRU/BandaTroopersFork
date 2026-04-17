import { getPositiveCountText, isBlankDisplayValue } from './helpers';
import type { BackendData, BlueprintEntry } from './types';

type BlueprintFilterMode = 'all' | 'valid' | 'invalid' | 'active';
type BlueprintSortMode = 'activity' | 'name' | 'newest' | 'size';

const compareBlueprintNames = (left: BlueprintEntry, right: BlueprintEntry) =>
  `${left.name || ''}`.localeCompare(`${right.name || ''}`);

const getBlueprintLibraryMetaText = (blueprint: BlueprintEntry) => {
  const parts = [
    `${getPositiveCountText(blueprint.entry_count, '0')} объектов`,
    `r${getPositiveCountText(blueprint.radius, '0')}`,
  ];
  if (!isBlankDisplayValue(blueprint.source)) {
    parts.push(`${blueprint.source}`);
  }
  return parts.join(' · ');
};

const getBlueprintActionState = (
  data: BackendData,
  blueprint: BlueprintEntry,
) => {
  const isActive = blueprint.id === data.active_blueprint_id;
  const canLoad = blueprint.valid && !isActive;
  const canPreview = blueprint.valid && !data.click_mode_active;
  const canApply =
    blueprint.valid && isActive && data.preview_valid && data.can_run_apply;

  return {
    isActive,
    canLoad,
    canPreview,
    canApply,
  };
};

const filterAndSortBlueprintEntries = (
  data: BackendData,
  entries: BlueprintEntry[],
  filterMode: BlueprintFilterMode,
  sortMode: BlueprintSortMode,
) => {
  const filteredEntries = (entries || []).filter((entry) => {
    if (filterMode === 'valid') {
      return entry.valid;
    }
    if (filterMode === 'invalid') {
      return !entry.valid;
    }
    if (filterMode === 'active') {
      return entry.id === data.active_blueprint_id;
    }
    return true;
  });

  return [...filteredEntries].sort((left, right) => {
    if (sortMode === 'name') {
      return compareBlueprintNames(left, right);
    }
    if (sortMode === 'newest') {
      return `${right.created_at || ''}`.localeCompare(
        `${left.created_at || ''}`,
      );
    }
    if (sortMode === 'size') {
      const entryDiff = (right.entry_count || 0) - (left.entry_count || 0);
      if (entryDiff !== 0) {
        return entryDiff;
      }
      return compareBlueprintNames(left, right);
    }

    const leftState = getBlueprintActionState(data, left);
    const rightState = getBlueprintActionState(data, right);
    if (leftState.isActive !== rightState.isActive) {
      return leftState.isActive ? -1 : 1;
    }
    if (left.valid !== right.valid) {
      return left.valid ? -1 : 1;
    }
    return compareBlueprintNames(left, right);
  });
};

export {
  filterAndSortBlueprintEntries,
  getBlueprintActionState,
  getBlueprintLibraryMetaText,
};
export type { BlueprintFilterMode, BlueprintSortMode };
