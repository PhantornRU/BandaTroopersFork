import { RADIUS_POLICY_FIELD_IDS } from './constants';
import { getField, getFieldsByGroup, getFieldsById } from './helpers';
import type { BackendData } from './types';

const OUTPOST_LAYOUT_GROUP_ALIASES = [
  'Схема',
  'Компоновка',
  'Layout',
  'Профиль и вариант',
  'Тактический профиль и схема',
];

const OUTPOST_PERIMETER_GROUP_ALIASES = [
  'Периметр',
  'Perimeter',
  'Баррикады',
  'Barricades',
];

const OUTPOST_PERIMETER_MATERIAL_FIELD_IDS = [
  'primary_material_path',
  'secondary_material_path',
  'primary_door_path',
  'secondary_door_path',
  'barricade_pattern',
  'primary_material_share_percent',
  'place_barricade_doors',
];

const getFieldsByGroupAliases = (
  fields: BackendData['ui_fields'],
  aliases: string[],
) => {
  const matchedFields: BackendData['ui_fields'] = [];
  const seenLookup = new Set<string>();

  for (const alias of aliases) {
    const matched = getFieldsByGroup(fields, alias);
    for (const field of matched) {
      if (seenLookup.has(field.id)) {
        continue;
      }
      seenLookup.add(field.id);
      matchedFields.push(field);
    }
  }

  return matchedFields;
};

const getFieldByIds = (fields: BackendData['ui_fields'], ids: string[]) => {
  for (const id of ids) {
    const field = getField(fields, id);
    if (field) {
      return field;
    }
  }

  return undefined;
};

const getOutpostWorkspaceViewModel = (fields: BackendData['ui_fields']) => {
  const rawLayoutFields = getFieldsByGroupAliases(
    fields,
    OUTPOST_LAYOUT_GROUP_ALIASES,
  );
  const layoutFields = rawLayoutFields.filter(
    (field) =>
      field.id !== 'radius' && !RADIUS_POLICY_FIELD_IDS.includes(field.id),
  );
  const tacticalProfileField =
    getFieldByIds(fields, ['defense_profile']) ||
    getField(layoutFields, 'defense_profile');
  const layoutVariantField =
    getFieldByIds(layoutFields, ['layout_variant']) ||
    getField(fields, 'layout_variant');
  const openingWidthField =
    getFieldByIds(layoutFields, ['opening_width']) ||
    getField(fields, 'opening_width');
  const extraLayoutFields = layoutFields.filter(
    (field) =>
      !['defense_profile', 'layout_variant', 'opening_width'].includes(
        field.id,
      ),
  );
  const perimeterFields = getFieldsByGroupAliases(
    fields,
    OUTPOST_PERIMETER_GROUP_ALIASES,
  );
  const perimeterMaterialFields = getFieldsById(
    fields,
    OUTPOST_PERIMETER_MATERIAL_FIELD_IDS,
  ).filter((field) => field.visible !== false);
  const perimeterExtraFields = perimeterFields.filter(
    (field) =>
      field.visible !== false &&
      !OUTPOST_PERIMETER_MATERIAL_FIELD_IDS.includes(field.id),
  );
  const handledFieldIds = new Set([
    ...rawLayoutFields.map((field) => field.id),
    ...perimeterFields.map((field) => field.id),
  ]);
  const extraFieldGroups = fields.reduce<
    Record<string, BackendData['ui_fields']>
  >((groups, field) => {
    if (field.visible === false || handledFieldIds.has(field.id)) {
      return groups;
    }
    const groupName = field.group || 'Other';
    groups[groupName] = groups[groupName] || [];
    groups[groupName].push(field);
    return groups;
  }, {});
  const extraGroupNames = Object.keys(extraFieldGroups);

  return {
    rawLayoutFields,
    layoutFields,
    tacticalProfileField,
    layoutVariantField,
    openingWidthField,
    extraLayoutFields,
    perimeterFields,
    perimeterMaterialFields,
    perimeterExtraFields,
    extraFieldGroups,
    extraGroupNames,
  };
};

export { getOutpostWorkspaceViewModel, OUTPOST_PERIMETER_MATERIAL_FIELD_IDS };
