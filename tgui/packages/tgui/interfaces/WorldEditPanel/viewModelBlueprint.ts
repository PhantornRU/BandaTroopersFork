import { getPositiveCountText, isBlankDisplayValue } from './helpers';
import type { BlueprintEntry } from './types';

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

export { getBlueprintLibraryMetaText };
