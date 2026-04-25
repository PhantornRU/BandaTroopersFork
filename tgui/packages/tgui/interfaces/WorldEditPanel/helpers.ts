import {
  BARRICADE_LABELS,
  DAMAGE_PROFILE_LABELS,
  DIRECTION_LABELS,
  EMPTY_LABEL,
  FIELD_LABELS,
  FORTIFY_DOOR_POLICY_LABELS,
  FORTIFY_MATERIAL_LABELS,
  FORTIFY_PRESET_LABELS,
  NONE_LABEL,
  OUTPOST_LAYER_PROFILE_LABELS,
  OUTPOST_LAYOUT_LABELS,
  OUTPOST_MINEFIELD_PROFILE_LABELS,
  OUTPOST_OPENING_WIDTH_LABELS,
  OUTPOST_PERIMETER_PATTERN_LABELS,
  OUTPOST_TACTICAL_PROFILE_LABELS,
  PLACEMENT_MODE_LABELS,
  PLACEMENT_SHAPE_LABELS,
  PLACEMENT_SHAPE_ORDER,
  UNDO_POLICY_LABELS,
  UNDO_STATUS_LABELS,
} from './constants';
import { getToolTitleLabel } from './toolRegistry';
import type { BackendData, PlacementOption, ToneKey, UiField } from './types';

export const isBlankDisplayValue = (value?: unknown) => {
  const text = `${value ?? ''}`.trim().toLowerCase();
  return !text || text === 'n/a';
};

export const getDisplayText = (value?: unknown, fallback = EMPTY_LABEL) =>
  isBlankDisplayValue(value) ? fallback : `${value}`;

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
  switch (key) {
    case 'single':
      return '1 раз';
    case 'repeat':
      return 'Повт.';
    default:
      return PLACEMENT_MODE_LABELS[key] || getDisplayText(value, NONE_LABEL);
  }
};

export const getTranslatedPlacementModeTooltip = (value?: unknown) => {
  const key = `${value ?? ''}`.trim().toLowerCase();
  switch (key) {
    case 'single':
      return 'Один раз';
    case 'repeat':
      return 'Повторять';
    default:
      return getTranslatedPlacementMode(value);
  }
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

export const getTranslatedFieldDescription = (field?: UiField) => {
  const description = `${field?.description || ''}`.trim();
  if (!description) {
    return '';
  }

  switch (description) {
    case 'Stops radius expansion at blockers, but does not invalidate the clicked tile or selected contour itself.':
      return 'Останавливает расширение радиуса у блокираторов, но не запрещает саму кликнутую клетку или выбранный контур.';
    case 'Keeps only tiles that stay reachable from the drawing start through adjacent non-blocked tiles. This toggle always enables clear-path filtering.':
      return 'Оставляет только клетки, до которых можно дойти от начала рисования через соседние незаблокированные клетки. Этот режим всегда включает фильтрацию чистого пути.';
    case 'Counts windows as blockers while checking clear paths and reachable expansion.':
      return 'Считает окна блокираторами при проверке чистого пути и достижимости.';
    case 'Perimeter offset skips dense tile centers. The selected footprint itself still stays valid.':
      return 'Смещение периметра пропускает плотные тайлы. Выбранный контур остаётся допустимым.';
    case 'Perimeter and sentry candidates must stay reachable through adjacent clear tiles from the selected footprint.':
      return 'Контур, периметр и расширение остаются только в зоне, достижимой от стартовой точки. Этот режим всегда включает чистые клетки.';
    case 'Counts windows as blockers while evaluating clear/reachable perimeter expansion.':
      return 'Окна считаются блокираторами проходимости и достижимости для ограничителей радиуса.';
    case 'Radius expansion skips dense tile centers. The selected footprint stays valid even when it starts on blocked tiles.':
      return 'Контур размещения и радиусное расширение не проходят через заблокированные клетки по текущим правилам ограничителей.';
    case 'Radius expansion keeps only tiles reachable through adjacent clear tiles from the selected footprint.':
      return 'Контур, периметр и расширение остаются только в зоне, достижимой от стартовой точки. Этот режим всегда включает чистые клетки.';
    case 'Counts windows as blockers for clear/reachable radius filtering.':
      return 'Окна считаются блокираторами проходимости и достижимости для ограничителей радиуса.';
    default:
      return description;
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
    case 'preset_id':
      return (
        FORTIFY_PRESET_LABELS[value] || label || getDisplayText(optionValue)
      );
    case 'material_family':
    case 'door_material_family':
      return (
        FORTIFY_MATERIAL_LABELS[value] || label || getDisplayText(optionValue)
      );
    case 'door_policy':
      return (
        FORTIFY_DOOR_POLICY_LABELS[value] ||
        label ||
        getDisplayText(optionValue)
      );
    case 'defense_profile':
      return (
        OUTPOST_TACTICAL_PROFILE_LABELS[value] ||
        label ||
        getDisplayText(optionValue)
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
        OUTPOST_PERIMETER_PATTERN_LABELS[value] ||
        label ||
        getDisplayText(optionValue)
      );
    case 'sentry_layer_profile':
    case 'extra_defense_layer_profile':
    case 'wire_layer_profile':
      return (
        OUTPOST_LAYER_PROFILE_LABELS[value] ||
        label ||
        getDisplayText(optionValue)
      );
    case 'minefield_profile':
      return (
        OUTPOST_MINEFIELD_PROFILE_LABELS[value] ||
        label ||
        getDisplayText(optionValue)
      );
    case 'damage_profile':
      return (
        DAMAGE_PROFILE_LABELS[value] || label || getDisplayText(optionValue)
      );
    case 'primary_material_path':
    case 'secondary_material_path':
    case 'primary_door_path':
    case 'secondary_door_path':
      return BARRICADE_LABELS[label] || label || getDisplayText(optionValue);
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
