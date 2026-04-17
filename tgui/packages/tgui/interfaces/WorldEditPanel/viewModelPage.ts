import { getOrderedToolTabs } from './toolRegistry';
import type { BackendData, UiField } from './types';

type WorldEditViewModel = {
  showPlacementSetup: boolean;
  groupedFields: Record<string, UiField[]>;
  groupNames: string[];
  toolTabs: ReturnType<typeof getOrderedToolTabs>;
};

const buildGroupedFields = (fields: UiField[] = []) => {
  const groups: Record<string, UiField[]> = {};
  for (const field of fields) {
    const groupName = field.group || 'Основные';
    if (!groups[groupName]) {
      groups[groupName] = [];
    }
    groups[groupName].push(field);
  }
  return groups;
};

const getGroupNames = (groupedFields: Record<string, UiField[]>) =>
  Object.keys(groupedFields);

const buildWorldEditViewModel = (data: BackendData): WorldEditViewModel => {
  const groupedFields = buildGroupedFields(data.ui_fields || []);

  return {
    showPlacementSetup:
      data.placement_supported ||
      data.placement_shape_supported ||
      data.placement_supports_direction,
    groupedFields,
    groupNames: getGroupNames(groupedFields),
    toolTabs: getOrderedToolTabs(data.categories || []),
  };
};

export { buildGroupedFields, buildWorldEditViewModel, getGroupNames };
export type { WorldEditViewModel };
