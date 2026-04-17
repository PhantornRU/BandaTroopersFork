import {
  BARRICADE_LABELS,
  DAMAGE_PROFILE_LABELS,
  DIRECTION_LABELS,
  EMPTY_LABEL,
  EXECUTION_MODE_LABELS,
  FIELD_LABELS,
  NONE_LABEL,
  OUTPOST_BARRICADE_PATTERN_LABELS,
  OUTPOST_FAMILY_LABELS,
  OUTPOST_GUARD_MODE_LABELS,
  OUTPOST_LAYOUT_LABELS,
  OUTPOST_OPENING_WIDTH_LABELS,
  PLACEMENT_MODE_LABELS,
  PLACEMENT_SHAPE_LABELS,
  PLACEMENT_SHAPE_ORDER,
  SENTRY_LABELS,
  UNDO_POLICY_LABELS,
  UNDO_STATUS_LABELS,
} from './constants';
import { getToolTitleLabel } from './toolRegistry';
import type { BackendData, PlacementOption, ToneKey, UiField } from './types';

export const isBlankDisplayValue = (value?: unknown) => {
  const text = `${value ?? ''}`.trim().toLowerCase();
  return !text || text === '0' || text === 'none' || text === 'n/a';
};

export const getDisplayText = (value?: unknown, fallback = EMPTY_LABEL) =>
  isBlankDisplayValue(value) ? fallback : `${value}`;

export const getPositiveCountText = (value?: number, fallback = EMPTY_LABEL) =>
  value && value > 0 ? `${value}` : fallback;

export const getField = (fields: UiField[], id: string) =>
  (fields || []).find((field) => field.id === id);

export const getFieldsById = (fields: UiField[], ids: string[]) =>
  ids
    .map((id) => getField(fields, id))
    .filter((field): field is UiField => !!field);

export const getFieldsByGroup = (fields: UiField[], groupName: string) =>
  (fields || []).filter((field) => field.group === groupName);

export const getVisibleFields = (fields: UiField[] = []) =>
  (fields || []).filter((field) => field.visible !== false);

export const getSafeFieldList = (fields: UiField[], ids: string[]) =>
  getFieldsById(fields, ids).filter(
    (field) => field.visible !== false && !field.disabled,
  );

export const toneForHistoryResult = (result?: string): ToneKey => {
  switch ((result || '').toLowerCase()) {
    case 'ok':
    case 'success':
    case 'undo_ok':
    case 'cleanup_ok':
      return 'good';
    case 'warn':
    case 'warning':
    case 'undo_partial':
    case 'cleanup_partial':
      return 'average';
    case 'error':
    case 'failed':
    case 'undo_skipped':
    case 'cleanup_skipped':
      return 'bad';
    default:
      return 'label';
  }
};

export const getTranslatedDirection = (value?: unknown) => {
  const key = `${value ?? ''}`.trim().toLowerCase();
  return DIRECTION_LABELS[key] || getDisplayText(value, NONE_LABEL);
};

export const getTranslatedShapeLabel = (value?: unknown) => {
  const key = `${value ?? ''}`.trim().toLowerCase();
  return PLACEMENT_SHAPE_LABELS[key] || getDisplayText(value, NONE_LABEL);
};

export const getTranslatedPlacementMode = (value?: unknown) => {
  const key = `${value ?? ''}`.trim().toLowerCase();
  return PLACEMENT_MODE_LABELS[key] || getDisplayText(value, NONE_LABEL);
};

export const getTranslatedExecutionMode = (value?: unknown) => {
  const key = `${value ?? ''}`.trim().toLowerCase();
  return EXECUTION_MODE_LABELS[key] || getDisplayText(value, NONE_LABEL);
};

export const getTranslatedUndoPolicy = (value?: string) => {
  const key = `${value ?? ''}`.trim().toLowerCase();
  return UNDO_POLICY_LABELS[key] || getDisplayText(value, EMPTY_LABEL);
};

export const getTranslatedUndoStatus = (value?: string) => {
  const key = `${value ?? ''}`.trim().toLowerCase();
  return UNDO_STATUS_LABELS[key] || getDisplayText(value, EMPTY_LABEL);
};

const getTranslatedRadiusFieldLabel = (field: UiField) => {
  const backendLabel = `${field.label || ''}`.trim().toLowerCase();

  switch (backendLabel) {
    case 'perimeter offset':
      return 'Отступ периметра';
    case 'impact radius':
      return 'Радиус воздействия';
    default:
      return FIELD_LABELS[field.id] || field.label;
  }
};

export const getTranslatedFieldLabel = (field: UiField) => {
  if (field.id === 'radius') {
    return getTranslatedRadiusFieldLabel(field);
  }

  switch (field.id) {
    case 'shape_radius':
      return 'Радиус формы';
    case 'shape_radius_x':
      return 'Горизонтальный радиус';
    case 'shape_radius_y':
      return 'Вертикальный радиус';
    case 'shape_brush_radius':
      return 'Ширина кисти';
    case 'shape_scatter_radius':
      return 'Радиус кластера';
    default:
      return FIELD_LABELS[field.id] || field.label;
  }
};

export const translateOptionLabel = (
  fieldId: string,
  optionLabel?: string,
  optionValue?: unknown,
) => {
  const label = `${optionLabel ?? ''}`.trim();
  const value = `${optionValue ?? ''}`.trim().toLowerCase();

  switch (fieldId) {
    case 'family':
      return (
        OUTPOST_FAMILY_LABELS[value] || label || getDisplayText(optionValue)
      );
    case 'layout_variant':
      return (
        OUTPOST_LAYOUT_LABELS[value] || label || getDisplayText(optionValue)
      );
    case 'opening_width':
      return (
        OUTPOST_OPENING_WIDTH_LABELS[value] ||
        label ||
        getDisplayText(optionValue)
      );
    case 'barricade_pattern':
      return (
        OUTPOST_BARRICADE_PATTERN_LABELS[value] ||
        label ||
        getDisplayText(optionValue)
      );
    case 'guard_mode':
      return (
        OUTPOST_GUARD_MODE_LABELS[value] || label || getDisplayText(optionValue)
      );
    case 'damage_profile':
      return (
        DAMAGE_PROFILE_LABELS[value] || label || getDisplayText(optionValue)
      );
    case 'barricade_path':
      return BARRICADE_LABELS[label] || label || getDisplayText(optionValue);
    case 'sentry_path':
      return SENTRY_LABELS[label] || label || getDisplayText(optionValue);
    default:
      return label || getDisplayText(optionValue);
  }
};

export const getFieldOptionLabel = (field?: UiField, fallback = NONE_LABEL) => {
  if (!field) {
    return fallback;
  }

  const option = (field.options || []).find(
    (entry) => `${entry.value}` === `${field.value}`,
  );
  if (!option) {
    return getDisplayText(field.value, fallback);
  }

  return translateOptionLabel(field.id, option.label, option.value);
};

export const getPlacementOptionValueSet = (options?: PlacementOption[]) =>
  new Set((options || []).map((option) => `${option.value}`));

export const getOrderedShapeValues = (options?: PlacementOption[]) => {
  const extraValues = (options || [])
    .map((option) => `${option.value}`)
    .filter((value, index, values) => values.indexOf(value) === index)
    .filter((value) => !PLACEMENT_SHAPE_ORDER.includes(value));

  return [...PLACEMENT_SHAPE_ORDER, ...extraValues];
};

export const getGeneratorDisplayName = (
  data: BackendData,
  generatorId?: string,
) => {
  const titleLabel = getToolTitleLabel(generatorId);
  if (titleLabel) {
    return titleLabel;
  }

  for (const category of data.categories || []) {
    const generator = category.generators?.find(
      (entry) => entry.id === generatorId,
    );
    if (generator?.name_ru) {
      return generator.name_ru;
    }
  }
  return getDisplayText(generatorId, EMPTY_LABEL);
};

export const getHistoryResultText = (value?: string) => {
  switch ((value || '').toLowerCase()) {
    case 'ok':
    case 'success':
      return 'Успех';
    case 'undo_ok':
      return 'Откат выполнен';
    case 'cleanup_ok':
      return 'Очистка выполнена';
    case 'undo_partial':
      return 'Откат частичный';
    case 'cleanup_partial':
      return 'Очистка частичная';
    case 'undo_skipped':
      return 'Откат пропущен';
    case 'cleanup_skipped':
      return 'Очистка пропущена';
    case 'error':
    case 'failed':
      return 'Ошибка';
    default:
      return getDisplayText(value, 'Без статуса');
  }
};

export const getSelectedBlueprint = (data: BackendData) =>
  data.blueprint_entries?.find(
    (entry) => entry.id === data.active_blueprint_id,
  );

export const isBlueprintToolBlocked = (data: BackendData) => {
  if (data.current_generator_id !== 'blueprint_stamp') {
    return false;
  }

  const activeBlueprint = getSelectedBlueprint(data);
  return (
    !data.active_blueprint_id || (!!activeBlueprint && !activeBlueprint.valid)
  );
};

export const getUndoTone = (status?: string): ToneKey => {
  switch ((status || '').toLowerCase()) {
    case 'available':
    case 'full':
      return 'good';
    case 'cleanup_available':
    case 'partial':
      return 'average';
    case 'not_available':
    case 'none':
      return 'label';
    default:
      return 'label';
  }
};
