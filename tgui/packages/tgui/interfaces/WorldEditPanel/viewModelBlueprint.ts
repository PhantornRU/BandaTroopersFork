import type { BackendData, BlueprintEntry } from './types';

type BlueprintFilterMode = 'all' | 'valid' | 'invalid' | 'active';
type BlueprintSortMode = 'activity' | 'name' | 'newest' | 'size';

const compareBlueprintNames = (left: BlueprintEntry, right: BlueprintEntry) =>
  `${left.name || ''}`.localeCompare(`${right.name || ''}`);

const getBlueprintFootprintText = (blueprint: BlueprintEntry) => {
  const width = Math.max(Number(blueprint.footprint_width) || 0, 0);
  const height = Math.max(Number(blueprint.footprint_height) || 0, 0);
  if (width > 0 && height > 0) {
    return `${width}x${height}`;
  }

  const fallbackSpan = Math.max((Number(blueprint.radius) || 0) * 2 + 1, 0);
  if (fallbackSpan > 0) {
    return `${fallbackSpan}x${fallbackSpan}`;
  }

  return '0x0';
};

const getBlueprintFootprintArea = (blueprint: BlueprintEntry) => {
  const width = Number(blueprint.footprint_width) || 0;
  const height = Number(blueprint.footprint_height) || 0;
  if (width > 0 && height > 0) {
    return width * height;
  }
  return Number(blueprint.entry_count) || 0;
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
      const leftArea = getBlueprintFootprintArea(left);
      const rightArea = getBlueprintFootprintArea(right);
      const areaDiff = rightArea - leftArea;
      if (areaDiff !== 0) {
        return areaDiff;
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
  getBlueprintFootprintText,
};
export type { BlueprintFilterMode, BlueprintSortMode };
