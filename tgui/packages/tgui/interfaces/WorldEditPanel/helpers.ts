import { type ReactNode } from 'react';

import {
  BARRICADE_LABELS,
  DAMAGE_PROFILE_LABELS,
  DIRECTION_LABELS,
  EMPTY_LABEL,
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
  TOOL_TITLE_LABELS,
  UNDO_POLICY_LABELS,
  UNDO_STATUS_LABELS,
} from './constants';
import type {
  BackendData,
  PlacementOption,
  ToneKey,
  UiField,
  WorkflowStepKey,
  WorkspaceTabKey,
} from './types';

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

export const getTranslatedUndoPolicy = (value?: string) => {
  const key = `${value ?? ''}`.trim().toLowerCase();
  return UNDO_POLICY_LABELS[key] || getDisplayText(value, EMPTY_LABEL);
};

export const getTranslatedUndoStatus = (value?: string) => {
  const key = `${value ?? ''}`.trim().toLowerCase();
  return UNDO_STATUS_LABELS[key] || getDisplayText(value, EMPTY_LABEL);
};

export const getTranslatedFieldLabel = (field: UiField) =>
  FIELD_LABELS[field.id] || field.label;

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
  if (generatorId && TOOL_TITLE_LABELS[generatorId]) {
    return TOOL_TITLE_LABELS[generatorId];
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

export const getCurrentToolTitle = (data: BackendData) =>
  TOOL_TITLE_LABELS[data.current_generator_id || ''] ||
  getDisplayText(data.current_generator_name, 'World Edit');

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

export const getBlueprintToolbarState = (data: BackendData) => {
  if (data.current_generator_id !== 'blueprint_stamp') {
    return null;
  }

  const activeBlueprint = getSelectedBlueprint(data);
  if (!data.active_blueprint_id) {
    return { state: 'Выберите шаблон слева.', color: 'label' };
  }
  if (activeBlueprint && !activeBlueprint.valid) {
    return {
      state: 'Выбранный шаблон недоступен.',
      color: 'bad',
    };
  }
  return null;
};

export const getPlacementStateLine = (data: BackendData) => {
  if (!data.click_mode_active) {
    return data.current_generator_id === 'destruction_pack'
      ? 'Выбор центра зоны выключен.'
      : 'Размещение выключено.';
  }

  if (data.placement_interaction_kind === 'collector') {
    if (data.can_finish_placement_collection) {
      return `Форма собрана: ${data.placement_collector_point_count || 0}.`;
    }
    return `Сбор: ${data.placement_collector_point_count || 0}/${Math.max(
      data.placement_collector_min_points || 0,
      1,
    )}.`;
  }

  if (data.placement_interaction_kind === 'anchor_pair') {
    return data.placement_anchor ? 'Ждет вторую точку.' : 'Ждет первую точку.';
  }

  if (data.placement_interaction_kind === 'param_only') {
    return 'Ждет опорную точку.';
  }

  return data.current_generator_id === 'destruction_pack'
    ? 'Выбор центра зоны активен.'
    : 'Размещение активно.';
};

export const getToolbarContextLine = (data: BackendData) => {
  if (!data.has_generator) {
    return '';
  }

  const items: string[] = [];
  if (data.current_generator_id === 'blueprint_stamp') {
    const activeBlueprint = getSelectedBlueprint(data);
    items.push(
      `Шаблон: ${
        activeBlueprint?.name ||
        getDisplayText(data.active_blueprint_id, 'не выбран')
      }`,
    );
  } else if (data.current_generator_id === 'outpost_radius') {
    items.push(
      `Профиль: ${getFieldOptionLabel(getField(data.ui_fields, 'family'))}`,
    );
    items.push(
      `Вариант: ${getFieldOptionLabel(
        getField(data.ui_fields, 'layout_variant'),
      )}`,
    );
  }

  return items.slice(0, 3).join(' · ');
};

export const getWorkflowStepKey = (
  data: BackendData,
  workspaceTab: WorkspaceTabKey,
): WorkflowStepKey => {
  if (workspaceTab === 'history') {
    return 'history';
  }

  if (!data.has_generator) {
    return 'select';
  }

  if (data.click_mode_active) {
    return data.can_finish_placement_collection ? 'apply' : 'preview';
  }

  if (
    data.current_generator_id === 'blueprint_stamp' &&
    !data.active_blueprint_id
  ) {
    return 'configure';
  }

  if (data.requires_preview_before_apply) {
    return data.preview_valid ? 'apply' : 'preview';
  }

  if (data.preview_valid) {
    return 'apply';
  }

  return 'configure';
};

export const getWorkflowHintText = (
  data: BackendData,
  workspaceTab: WorkspaceTabKey,
) => {
  if (workspaceTab === 'history') {
    return data.history_entries?.length
      ? 'Проверьте последнюю операцию и при необходимости выполните откат.'
      : 'История появится после первого применения.';
  }

  if (!data.has_generator) {
    return 'Выберите доступный инструмент и начните настройку.';
  }

  if (data.click_mode_active) {
    return getPlacementStateLine(data);
  }

  if (
    data.current_generator_id === 'blueprint_stamp' &&
    !data.active_blueprint_id
  ) {
    return 'Сначала выберите шаблон из библиотеки слева.';
  }

  if (data.last_ui_error) {
    return data.last_ui_error;
  }

  if (data.requires_preview_before_apply && !data.preview_valid) {
    return 'Соберите безопасный предпросмотр перед применением.';
  }

  if (data.preview_valid) {
    return 'Предпросмотр готов: можно применить или скорректировать параметры.';
  }

  if (data.current_generator_supports_preview) {
    return 'Настройте параметры и соберите предпросмотр.';
  }

  return 'Настройте параметры и применяйте, когда будете готовы.';
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

export const getWorkflowTone = (
  data: BackendData,
  workspaceTab: WorkspaceTabKey,
): ToneKey => {
  if (workspaceTab === 'history') {
    return data.history_entries?.length ? 'good' : 'label';
  }
  if (data.last_ui_error) {
    return 'bad';
  }
  if (data.click_mode_active) {
    return data.can_finish_placement_collection ? 'good' : 'average';
  }
  if (data.preview_valid) {
    return 'good';
  }
  if (data.requires_preview_before_apply) {
    return 'average';
  }
  return 'label';
};

export const buildChromeSummaryItems = (
  data: BackendData,
  workspaceTab: WorkspaceTabKey,
): Array<{
  label: string;
  value: ReactNode;
  tone?: ToneKey;
}> => {
  const items: Array<{
    label: string;
    value: ReactNode;
    tone?: ToneKey;
  }> = [];

  const contextLine = getToolbarContextLine(data);
  if (contextLine) {
    items.push({
      label: 'Контекст',
      value: contextLine,
      tone: 'label',
    });
  }

  items.push({
    label: workspaceTab === 'history' ? 'Фокус' : 'Дальше',
    value: getWorkflowHintText(data, workspaceTab),
    tone: getWorkflowTone(data, workspaceTab),
  });

  if (
    data.click_mode_active &&
    data.placement_interaction_kind === 'collector'
  ) {
    items.push({
      label: 'Сбор',
      value: `${data.placement_collector_point_count || 0}/${Math.max(
        data.placement_collector_min_points || 0,
        1,
      )}`,
      tone: data.can_finish_placement_collection ? 'good' : 'average',
    });
  } else if (data.preview_valid) {
    items.push({
      label: 'Предпросмотр',
      value: 'Готов',
      tone: 'good',
    });
  } else if (data.requires_preview_before_apply) {
    items.push({
      label: 'Предпросмотр',
      value: 'Нужен',
      tone: 'average',
    });
  }

  if (data.can_undo_last_operation) {
    items.push({
      label: 'Откат',
      value: 'Доступен',
      tone: 'good',
    });
  } else if (data.can_cleanup_last_owned_effects) {
    items.push({
      label: 'Очистка',
      value: 'Доступна',
      tone: 'average',
    });
  }

  return items.slice(0, 4);
};
