import { ReactNode, useEffect, useMemo, useState } from 'react';

import { useBackend } from '../backend';
import {
  Box,
  Button,
  Collapsible,
  Dropdown,
  Flex,
  Input,
  LabeledList,
  NoticeBox,
  NumberInput,
  ProgressBar,
  Section,
  Stack,
  Tabs,
} from '../components';
import { Window } from '../layouts';

type GeneratorEntry = {
  id: string;
  name_ru: string;
  description_ru: string;
  execution_mode: string;
  required_rights: string;
  supports_preview: boolean;
  status: string;
};

type GeneratorCategory = {
  category: string;
  generators: GeneratorEntry[];
};

type UiFieldOption = {
  label: string;
  value: unknown;
  description?: string;
};

type UiField = {
  id: string;
  label: string;
  kind: 'select' | 'number' | 'boolean' | 'text';
  value: unknown;
  options?: UiFieldOption[];
  min?: number;
  max?: number;
  step?: number;
  description?: string;
  placeholder?: string;
  group?: string;
  visible?: boolean;
  disabled?: boolean;
  required?: boolean;
  validate_hint?: string;
};

type RuntimeStatusEntry = {
  label: string;
  value: string;
};

type HistoryEntry = {
  time: string;
  generator_id: string;
  result: string;
  created_count: number;
  deleted_count: number;
  center_turf: string;
  duration_ms: number;
  params_short: string;
  message: string;
  undo_policy?: string;
  undo_status?: string;
  reverted_count?: number;
  skipped_count?: number;
  operation_id?: string;
  source_operation_id?: string;
  source_generator_id?: string;
};

type ChangesetSummary = {
  operation_id: string;
  generator_id: string;
  undo_policy: string;
  created_entries: number;
  moved_entries: number;
  owned_effect_entries: number;
  created_at: string;
  can_undo: boolean;
  can_cleanup: boolean;
  undo_status: string;
};

type PlacementOption = {
  label: string;
  value: string;
  description?: string;
};

type PresetEntry = {
  id: string;
  name: string;
  generator_id: string;
  params_short: string;
  created_at: string;
};

type BlueprintEntry = {
  id: string;
  name: string;
  entry_count: number;
  radius: number;
  created_at: string;
  created_by: string;
  source: string;
  valid: boolean;
  error: string;
  active?: boolean;
};

type BackendData = {
  categories: GeneratorCategory[];
  has_generator: boolean;
  current_generator_id?: string;
  current_generator_name?: string;
  current_generator_category?: string;
  current_generator_description?: string;
  current_generator_execution_mode?: string;
  current_generator_required_rights?: string;
  current_generator_status?: string;
  current_generator_supports_preview: boolean;
  requires_preview_before_apply: boolean;
  current_params_text: string;
  ui_fields: UiField[];
  has_inline_fields: boolean;
  ui_mode: 'inline' | 'wizard_fallback';
  runtime_status: RuntimeStatusEntry[];
  placement_supported: boolean;
  placement_active: boolean;
  placement_mode: string;
  placement_mode_options: PlacementOption[];
  placement_shape_supported: boolean;
  placement_shape: string;
  placement_shape_options: PlacementOption[];
  placement_shape_fields: UiField[];
  placement_shape_uses_anchor_pair: boolean;
  placement_interaction_kind: string;
  placement_interaction_label: string;
  placement_shape_rollout_stage: string;
  placement_collector_point_count: number;
  placement_collector_min_points: number;
  placement_collector_max_points: number;
  placement_collector_origin: string;
  placement_collector_points_text: string;
  placement_collector_summary: string;
  can_finish_placement_collection: boolean;
  placement_supports_direction: boolean;
  placement_dir: string;
  placement_dir_options: PlacementOption[];
  placement_anchor?: string;
  can_start_placement_mode: boolean;
  can_manage_presets: boolean;
  preset_entries: PresetEntry[];
  blueprint_entries: BlueprintEntry[];
  active_blueprint_id?: string;
  can_save_blueprint_from_plan: boolean;
  last_ui_error: string;
  preview_valid: boolean;
  preview_success: boolean;
  preview_message: string;
  preview_meta: Record<string, unknown>;
  last_apply_success: boolean;
  last_apply_message: string;
  last_undo_success: boolean;
  last_undo_message: string;
  last_undo_action?: string;
  last_changeset?: ChangesetSummary;
  click_mode_active: boolean;
  can_run_preview: boolean;
  can_run_apply: boolean;
  can_stop_click_mode: boolean;
  can_undo_last_operation: boolean;
  can_cleanup_last_owned_effects: boolean;
  can_refresh_ui: boolean;
  history_entries: HistoryEntry[];
};

type SummaryTile = {
  label: string;
  value: ReactNode;
  color?: string;
};

type WorkflowState = {
  label: string;
  description: string;
  color?: string;
};

type PreviewState = {
  label: string;
  message: string;
  color?: string;
};

type ActFn = (action: string, payload?: Record<string, unknown>) => void;

const boolText = (value: boolean, yes = 'Да', no = 'Нет') => (value ? yes : no);

const EMPTY_LABEL = 'Не задано';
const NONE_LABEL = 'Не выбрано';
const OFF_LABEL = 'Выключено';

const isBlankDisplayValue = (value?: unknown) => {
  const text = `${value ?? ''}`.trim().toLowerCase();
  return !text || text === '0' || text === 'none' || text === 'n/a';
};

const getDisplayText = (value?: unknown, fallback = EMPTY_LABEL) =>
  isBlankDisplayValue(value) ? fallback : `${value}`;

const getPositiveCountText = (value?: number, fallback = EMPTY_LABEL) =>
  value && value > 0 ? `${value}` : fallback;

const getField = (fields: UiField[], id: string) =>
  (fields || []).find((field) => field.id === id);

const getFieldsById = (fields: UiField[], ids: string[]) =>
  ids
    .map((id) => getField(fields, id))
    .filter((field): field is UiField => !!field);

const getFieldsByGroup = (fields: UiField[], groupName: string) =>
  (fields || []).filter((field) => field.group === groupName);

const getFieldOptionLabel = (field?: UiField, fallback = NONE_LABEL) => {
  if (!field) {
    return fallback;
  }
  const option = (field.options || []).find(
    (entry) => `${entry.value}` === `${field.value}`,
  );
  return getDisplayText(option?.label, fallback);
};

const getPlacementOptionLabel = (
  options: PlacementOption[] | undefined,
  value?: string,
  fallback = NONE_LABEL,
) => {
  const option = (options || []).find(
    (entry) => `${entry.value}` === `${value}`,
  );
  return getDisplayText(option?.label, fallback);
};

const getSafeFieldList = (fields: UiField[], ids: string[]) =>
  getFieldsById(fields, ids).filter(
    (field) => field.visible !== false && !field.disabled,
  );

const toneForHistoryResult = (result?: string) => {
  switch ((result || '').toLowerCase()) {
    case 'ok':
    case 'success':
      return 'good';
    case 'warn':
    case 'warning':
      return 'average';
    case 'error':
    case 'failed':
      return 'bad';
    default:
      return 'label';
  }
};

const renderMetaValue = (value: unknown) => {
  if (value === undefined || value === null || value === '') {
    return EMPTY_LABEL;
  }
  if (Array.isArray(value)) {
    return value.map((entry) => `${entry}`).join(', ');
  }
  if (typeof value === 'object') {
    return JSON.stringify(value);
  }
  return `${value}`;
};

const interactionHelpText = (data: BackendData) => {
  if (data.placement_interaction_kind === 'anchor_pair') {
    return 'ЛКМ задает первую точку, второй ЛКМ завершает линию или рамку. СКМ сбрасывает текущую точку.';
  }
  if (data.placement_interaction_kind === 'collector') {
    return 'ЛКМ добавляет точки, СКМ снимает последнюю, ПКМ завершает сбор.';
  }
  if (data.placement_interaction_kind === 'param_only') {
    return 'Клик использует выбранный тайл как опору, а форма берется из текущих параметров.';
  }
  return 'ЛКМ работает по выбранному тайлу. Для выхода остановите режим размещения.';
};

const getPreviewBlockReason = (data: BackendData) => {
  if (!data.has_generator) {
    return 'Сначала выберите инструмент.';
  }
  if (!data.current_generator_supports_preview) {
    return 'Для этого инструмента предпросмотр не используется.';
  }
  if (data.click_mode_active) {
    return 'Предпросмотр из панели недоступен, пока активен режим размещения.';
  }
  return '';
};

const getApplyBlockReason = (data: BackendData) => {
  if (!data.has_generator) {
    return 'Сначала выберите инструмент.';
  }
  if (data.click_mode_active) {
    return 'Применение из панели недоступно, пока активен режим размещения.';
  }
  if (data.requires_preview_before_apply && !data.preview_valid) {
    return 'Сначала создайте корректный предпросмотр.';
  }
  return '';
};

const getPlacementBlockReason = (data: BackendData) => {
  if (!data.has_generator) {
    return 'Сначала выберите инструмент.';
  }
  if (data.placement_active) {
    return 'Режим размещения уже активен.';
  }
  if (!data.can_start_placement_mode) {
    return 'Для этого инструмента режим размещения недоступен.';
  }
  return '';
};

const getFinishCollectionReason = (data: BackendData) => {
  if (!data.click_mode_active) {
    return 'Сначала включите режим размещения.';
  }
  if (data.placement_interaction_kind !== 'collector') {
    return 'Для текущей формы завершение коллектора не используется.';
  }
  if (data.can_finish_placement_collection) {
    return '';
  }
  return `Нужно минимум ${data.placement_collector_min_points || 0} точек для завершения.`;
};

const getWorkflowState = (data: BackendData): WorkflowState => {
  if (!data.has_generator) {
    return {
      label: 'Выберите инструмент',
      description: 'Откройте нужный инструмент из списка слева.',
      color: 'label',
    };
  }

  if (data.last_ui_error) {
    return {
      label: 'Параметры требуют внимания',
      description: data.last_ui_error,
      color: 'bad',
    };
  }

  if (data.placement_active) {
    if (data.placement_interaction_kind === 'collector') {
      return data.can_finish_placement_collection
        ? {
            label: 'Форма готова',
            description:
              'Сбор завершен. Теперь можно перейти к предпросмотру и применению.',
            color: 'good',
          }
        : {
            label: 'Идет сбор формы',
            description: interactionHelpText(data),
            color: 'average',
          };
    }

    return {
      label: 'Активно живое размещение',
      description: interactionHelpText(data),
      color: 'average',
    };
  }

  if (data.requires_preview_before_apply && !data.preview_valid) {
    return {
      label: 'Нужен preview',
      description: 'Сначала создайте предпросмотр для текущей конфигурации.',
      color: 'average',
    };
  }

  if (data.preview_valid) {
    return {
      label: 'Готово к применению',
      description:
        data.preview_message ||
        'Текущая конфигурация прошла preview и готова к apply.',
      color: 'good',
    };
  }

  if (!data.has_inline_fields) {
    return {
      label: 'Настройка через мастер',
      description: 'У этого инструмента настройка идет через мастер.',
      color: 'label',
    };
  }

  return {
    label: 'Проверьте параметры',
    description:
      'Подготовьте параметры и при необходимости настройте размещение.',
    color: 'label',
  };
};

const getPreviewState = (data: BackendData): PreviewState => {
  if (!data.has_generator) {
    return {
      label: 'нет инструмента',
      message: 'Сначала выберите инструмент.',
      color: 'label',
    };
  }

  if (data.preview_valid) {
    return {
      label: 'готов',
      message:
        data.preview_message ||
        'Предпросмотр готов, конфигурацию можно применять.',
      color: 'good',
    };
  }

  if (data.preview_success) {
    return {
      label: 'готовится',
      message:
        data.preview_message ||
        'Предпросмотр выполнен, но применить его пока нельзя.',
      color: 'average',
    };
  }

  if (data.preview_message) {
    return {
      label: 'ошибка',
      message: data.preview_message,
      color: 'average',
    };
  }

  return {
    label: 'нет',
    message: 'Предпросмотр еще не запускался.',
    color: 'label',
  };
};

const CompactStatusRow = (props: {
  readonly items: SummaryTile[];
  readonly basis?: string;
}) => {
  const { items, basis } = props;

  return (
    <Flex wrap mx={-0.25}>
      {items.map((item) => (
        <Flex.Item key={item.label} basis={basis || '24%'} grow m={0.15}>
          <Box>
            <Box as="span" color="label">
              {item.label}:{' '}
            </Box>
            <Box as="span" color={item.color || 'white'}>
              {item.value}
            </Box>
          </Box>
        </Flex.Item>
      ))}
    </Flex>
  );
};

const ActionRow = (props: { readonly children: ReactNode }) => (
  <Flex wrap mx={-0.25}>
    {props.children}
  </Flex>
);

const ActionItem = (props: { readonly children: ReactNode }) => (
  <Flex.Item m={0.25}>{props.children}</Flex.Item>
);

const buildDetailItems = (
  items: Array<{
    label: string;
    value: ReactNode;
    color?: string;
  }>,
) => (
  <CompactStatusRow
    basis="32%"
    items={items.map((item) => ({
      label: item.label,
      value: item.value,
      color: item.color,
    }))}
  />
);

const getApplyReadinessLabel = (data: BackendData) => {
  if (!data.has_generator) {
    return 'нет инструмента';
  }
  if (data.can_run_apply) {
    return 'готово';
  }
  if (data.requires_preview_before_apply && !data.preview_valid) {
    return 'нужен preview';
  }
  return 'недоступно';
};

const getBlueprintSelectionHint = (data: BackendData) => {
  if (data.placement_active) {
    return 'Клик выбирает blueprint; активное размещение можно остановить в верхней панели.';
  }
  return 'Выбор в списке сразу делает blueprint текущим.';
};

const getPresetSelectionHint = () =>
  'Клик по пресету сразу подставляет его параметры в текущий инструмент.';

const getOperationSummary = (entry?: HistoryEntry) => {
  if (!entry?.message) {
    return 'Подробности по операции пока недоступны.';
  }
  return entry.message;
};

const getGeneratorDisplayName = (data: BackendData, generatorId?: string) => {
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

const getOperationHeader = (data: BackendData, entry: HistoryEntry) => {
  const result = getDisplayText(entry.result, 'без результата');
  return `${entry.time} | ${getGeneratorDisplayName(
    data,
    entry.generator_id,
  )} | ${result}`;
};

const getOperationResultLabel = (entry?: HistoryEntry) => {
  if (!entry?.result) {
    return 'без результата';
  }
  return entry.result;
};

const getWorkHeaderDescription = (data: BackendData) => {
  if (!data.has_generator) {
    return 'Сначала выберите инструмент.';
  }
  return (
    data.current_generator_description ||
    'Настройте параметры и выполните предпросмотр.'
  );
};

const getActionHintText = (data: BackendData) => {
  const previewBlockReason = getPreviewBlockReason(data);
  const applyBlockReason = getApplyBlockReason(data);

  if (!data.can_run_preview && previewBlockReason) {
    return previewBlockReason;
  }
  if (!data.can_run_apply && applyBlockReason) {
    return applyBlockReason;
  }
  return '';
};

const getHistoryTitle = () => 'История операций';

const getWorkspaceTitle = (data: BackendData) =>
  data.has_generator
    ? `Инструмент / ${data.current_generator_name}`
    : 'Инструменты';

const getActionLabel = (action: 'preview' | 'apply' | 'clear') => {
  switch (action) {
    case 'preview':
      return 'Предпросмотр';
    case 'apply':
      return 'Применить';
    case 'clear':
      return 'Очистить';
    default:
      return '';
  }
};

const getHistoryResultTone = (entry?: HistoryEntry) =>
  toneForHistoryResult(entry?.result);

const getParamEmptyText = () =>
  'Для этого инструмента настройка доступна только через мастер.';

const getWorkEmptyText = () => 'Выберите инструмент слева.';

const getHistoryEmptyText = () => 'История операций пока пуста.';

const getPreviewMetaTitle = () => 'Сводка preview';

const getDiagnosticsTitle = () => 'Технические детали';

const getCurrentParamsTitle = () => 'Текущие параметры';

const getRuntimeStatusTitle = (count: number) => `Служебный статус (${count})`;

const getHistoryDetailsTitle = () => 'Технические детали';

const getUndoSummaryTitle = () => 'Откат и очистка';

const getLastApplyTitle = () => 'Последнее применение';

const getLibraryTitle = () => 'Библиотека blueprint';

const getPresetTitle = () => 'Пресеты';

const getExportTitle = () => 'Экспорт';

const getActiveBlueprintText = () => 'Текущий blueprint для этой сессии.';

const getInvalidBlueprintText = () => 'Blueprint невалиден.';

const getCreatedLabel = () => 'Создан';

const getItemsLabel = () => 'Элементов';

const getSourceLabel = () => 'Источник';

const getAuthorLabel = () => 'Автор';

const getRefreshLabel = () => 'Обновить';

const getResetLabel = () => 'Сброс';

const getWizardLabel = () => 'Мастер';

const getFormRefreshLabel = () => 'Обновить форму';

const getHistoryButtonLabel = () => 'История';

const getUndoLabel = () => 'Откатить';

const getCleanupLabel = () => 'Очистить эффекты';

const getNoBlueprintsLabel = () => 'В библиотеке пока нет blueprint-ов.';

const getNoPresetsLabel = () =>
  'Для текущего инструмента еще нет сохраненных пресетов.';

const getSaveLabel = () => 'Сохранить';

const getSavePreviewLabel = () => 'Сохранить preview';

const getDeleteLabel = () => 'Удалить';

const getSelectableCardStyle = (selected: boolean) => ({
  border: selected ? '1px solid #4c9f39' : '1px solid #466b96',
  background: selected ? 'rgba(76, 159, 57, 0.16)' : 'rgba(70, 107, 150, 0.14)',
  borderRadius: '4px',
  cursor: 'pointer',
});

const getSelectedAssetId = (id?: string) => id || '';

const getBlueprintDetailsTitle = (entry: BlueprintEntry) =>
  `${getDisplayText(entry.name, 'Blueprint без имени')} · ${
    entry.radius > 0 ? `радиус ${entry.radius}` : 'радиус не задан'
  }`;

const getPresetDetailsTitle = (entry: PresetEntry) =>
  getDisplayText(entry.name, 'Пресет без имени');

const getWorkStatusText = (workflow: WorkflowState) => workflow.label;

const getWorkStatusDescription = (workflow: WorkflowState) =>
  workflow.description;

const getTechnicalParamText = (params?: string) =>
  getDisplayText(params, EMPTY_LABEL);

const getOperationIdText = (operationId?: string) =>
  getDisplayText(operationId, EMPTY_LABEL);

const getOperationCenterText = (center?: string) =>
  getDisplayText(center, EMPTY_LABEL);

const getOperationDurationText = (durationMs?: number) =>
  `${durationMs ?? 0} ms`;

const getUndoStatusText = (entry: HistoryEntry) =>
  entry.undo_policy
    ? `${entry.undo_policy} / ${getDisplayText(entry.undo_status, EMPTY_LABEL)}`
    : EMPTY_LABEL;

const getRevertedText = (entry: HistoryEntry) =>
  `${entry.reverted_count ?? 0} / ${entry.skipped_count ?? 0}`;

const getHistoryCenterLabel = () => 'Центр';

const getHistoryResultLabel = () => 'Результат';

const getHistoryCountLabel = () => 'Записей';

const getCreatedCountLabel = () => 'Создано';

const getDeletedCountLabel = () => 'Удалено';

const getDurationLabel = () => 'Длительность';

const getUndoPolicyLabel = () => 'Откат';

const getRevertedLabel = () => 'Откат / пропуск';

const getOperationMessageLabel = () => 'Сообщение';

const getOperationParamsLabel = () => 'Параметры';

const getOperationIdLabel = () => 'ID операции';

const getHistoryGeneratorLabel = () => 'Инструмент';

const getHistorySummaryText = (entry?: HistoryEntry) =>
  entry?.message || 'Сообщение по операции отсутствует.';

const getPreviewMessageText = (data: BackendData) =>
  getPreviewState(data).message;

const getPreviewLabelText = (data: BackendData) => getPreviewState(data).label;

const getPreviewTone = (data: BackendData) =>
  getPreviewState(data).color || 'label';

const getHistorySummaryItems = (
  data: BackendData,
  latestEntry?: HistoryEntry,
): SummaryTile[] => [
  {
    label: getHistoryCountLabel(),
    value: `${data.history_entries?.length || 0}`,
  },
  {
    label: getHistoryGeneratorLabel(),
    value: getGeneratorDisplayName(data, latestEntry?.generator_id),
  },
  {
    label: getHistoryResultLabel(),
    value: getOperationResultLabel(latestEntry),
    color: getHistoryResultTone(latestEntry),
  },
  {
    label: getHistoryCenterLabel(),
    value: getOperationCenterText(latestEntry?.center_turf),
  },
];

const getWorkspacePageTitle = (data: BackendData) => getWorkspaceTitle(data);

const getHistoryPageTitle = () => getHistoryTitle();

const getCurrentGeneratorDescription = (data: BackendData) =>
  getWorkHeaderDescription(data);

const getStatusExplanation = (workflow: WorkflowState) =>
  getWorkStatusDescription(workflow);

const getShortStatus = (workflow: WorkflowState) => getWorkStatusText(workflow);

const getActionHint = (data: BackendData) => getActionHintText(data);

const getBlueprintTitle = () => getLibraryTitle();

const getPresetSectionTitle = () => getPresetTitle();

const getExportSectionTitle = () => getExportTitle();

const getSelectedBlueprintTitle = (selectedBlueprint: BlueprintEntry) =>
  getBlueprintDetailsTitle(selectedBlueprint);

const getSelectedPresetTitle = (selectedPreset: PresetEntry) =>
  getPresetDetailsTitle(selectedPreset);

const getBlueprintInvalidText = (selectedBlueprint: BlueprintEntry) =>
  selectedBlueprint.error || getInvalidBlueprintText();

const getHistoryEntryTitle = (data: BackendData, entry: HistoryEntry) =>
  getOperationHeader(data, entry);

const getHistoryEntryMessage = (entry: HistoryEntry) =>
  getHistorySummaryText(entry);

const getHistoryEntryTone = (entry: HistoryEntry) =>
  getHistoryResultTone(entry);

const getParamEmptyLabel = () => getParamEmptyText();

const getWorkEmptyLabel = () => getWorkEmptyText();

const getHistoryEmptyLabel = () => getHistoryEmptyText();

const getPreviewMetaSectionTitle = () => getPreviewMetaTitle();

const getDiagnosticsSectionTitle = () => getDiagnosticsTitle();

const getCurrentParamsSectionTitle = () => getCurrentParamsTitle();

const getRuntimeStatusSectionTitle = (count: number) =>
  getRuntimeStatusTitle(count);

const getHistoryDetailsSectionTitle = () => getHistoryDetailsTitle();

const getUndoSummarySectionTitle = () => getUndoSummaryTitle();

const getLastApplySectionTitle = () => getLastApplyTitle();

const getBlueprintSelectionState = (data: BackendData) =>
  getSelectedAssetId(data.active_blueprint_id);

const getPresetSelectionState = (selectedPresetId: string) =>
  getSelectedAssetId(selectedPresetId);

const getSecondaryButtonLabel = (
  kind: 'refresh' | 'wizard' | 'reset' | 'undo' | 'cleanup',
) => {
  switch (kind) {
    case 'refresh':
      return getFormRefreshLabel();
    case 'wizard':
      return getWizardLabel();
    case 'reset':
      return getResetLabel();
    case 'undo':
      return getUndoLabel();
    case 'cleanup':
      return getCleanupLabel();
    default:
      return '';
  }
};

const getAssetSelectionHint = (
  kind: 'preset' | 'blueprint',
  data?: BackendData,
) => {
  if (kind === 'preset') {
    return getPresetSelectionHint();
  }
  return getBlueprintSelectionHint(data as BackendData);
};

const getLibraryEmptyLabel = (kind: 'preset' | 'blueprint') =>
  kind === 'preset' ? getNoPresetsLabel() : getNoBlueprintsLabel();

const getActionButtonLabel = (
  kind: 'save' | 'savePreview' | 'delete' | 'refresh',
) => {
  switch (kind) {
    case 'save':
      return getSaveLabel();
    case 'savePreview':
      return getSavePreviewLabel();
    case 'delete':
      return getDeleteLabel();
    case 'refresh':
      return getRefreshLabel();
    default:
      return '';
  }
};

const getDetailLabel = (kind: 'created' | 'items' | 'source' | 'author') => {
  switch (kind) {
    case 'created':
      return getCreatedLabel();
    case 'items':
      return getItemsLabel();
    case 'source':
      return getSourceLabel();
    case 'author':
      return getAuthorLabel();
    default:
      return '';
  }
};

const getHistoryDetailItems = (entry: HistoryEntry): SummaryTile[] => [
  {
    label: getCreatedCountLabel(),
    value: `${entry.created_count}`,
  },
  {
    label: getDeletedCountLabel(),
    value: `${entry.deleted_count}`,
  },
  {
    label: getHistoryCenterLabel(),
    value: getOperationCenterText(entry.center_turf),
  },
  {
    label: getDurationLabel(),
    value: getOperationDurationText(entry.duration_ms),
  },
  {
    label: getUndoPolicyLabel(),
    value: getUndoStatusText(entry),
  },
  {
    label: getRevertedLabel(),
    value: getRevertedText(entry),
  },
];

const getHistoryTechnicalDetails = (entry: HistoryEntry) => ({
  params: getTechnicalParamText(entry.params_short),
  operationId: getOperationIdText(entry.operation_id),
});

const getHistoryMessageColor = () => 'label';

const getBlueprintActiveText = () => getActiveBlueprintText();

const getCommonButtonColor = (
  kind: 'primary' | 'danger' | 'good' | 'average',
) => {
  switch (kind) {
    case 'good':
      return 'good';
    case 'average':
      return 'average';
    case 'danger':
      return 'bad';
    default:
      return undefined;
  }
};

const getSelectedBlueprintMessage = (selectedBlueprint: BlueprintEntry) =>
  selectedBlueprint.active ? getBlueprintActiveText() : 'Выбранный blueprint.';

const FieldEditor = (props: {
  readonly field: UiField;
  readonly act: ActFn;
  readonly showHelp?: boolean;
}) => {
  const { field, act, showHelp } = props;
  const isDisabled = !!field.disabled;

  const emitValue = (value: unknown) => {
    act('set_param', {
      param_id: field.id,
      value,
    });
  };

  let control = <Box color="bad">Неподдерживаемый тип поля.</Box>;

  if (field.kind === 'boolean') {
    control = (
      <Button.Checkbox
        checked={!!field.value}
        disabled={isDisabled}
        onClick={() => emitValue(!field.value)}
      >
        {field.value ? 'Да' : 'Нет'}
      </Button.Checkbox>
    );
  }

  if (field.kind === 'number') {
    control = (
      <NumberInput
        value={Number(field.value) || 0}
        minValue={field.min ?? -1000000}
        maxValue={field.max ?? 1000000}
        step={field.step || 1}
        width="100%"
        disabled={isDisabled}
        onChange={(value) => emitValue(value)}
      />
    );
  }

  if (field.kind === 'text') {
    control = (
      <Input
        key={`${field.id}_${String(field.value ?? '')}`}
        value={`${field.value ?? ''}`}
        disabled={isDisabled}
        placeholder={field.placeholder || ''}
        onChange={(_, value) => emitValue(value)}
      />
    );
  }

  if (field.kind === 'select') {
    const options = field.options || [];
    const valueByKey = new Map<string, unknown>();
    const dropdownOptions = options.map((option, index) => {
      const key = `${index}`;
      valueByKey.set(key, option.value);

      return {
        value: key,
        displayText: option.description ? (
          <Box>
            <Box>{option.label}</Box>
            <Box color="label" fontSize={0.85}>
              {option.description}
            </Box>
          </Box>
        ) : (
          option.label
        ),
      };
    });

    let selectedKey = '';
    for (let index = 0; index < options.length; index++) {
      if (`${options[index].value}` === `${field.value}`) {
        selectedKey = `${index}`;
        break;
      }
    }

    control = (
      <Dropdown
        width="100%"
        options={dropdownOptions}
        selected={selectedKey}
        displayText={getFieldOptionLabel(field)}
        disabled={isDisabled || !options.length}
        placeholder="Выберите значение"
        onSelected={(selectedOptionKey) => {
          const mappedValue = valueByKey.get(`${selectedOptionKey}`);
          emitValue(mappedValue);
        }}
      />
    );
  }

  return (
    <LabeledList.Item label={field.required ? `${field.label} *` : field.label}>
      {control}
      {!!showHelp && !!field.description && (
        <Box color="label" mt={0.5}>
          {field.description}
        </Box>
      )}
      {!!showHelp && !!field.validate_hint && (
        <Box color="average" mt={0.5}>
          {field.validate_hint}
        </Box>
      )}
    </LabeledList.Item>
  );
};

const FieldGroupSection = (props: {
  readonly title: string;
  readonly fields: UiField[];
  readonly act: ActFn;
  readonly showHelp?: boolean;
}) => {
  const { title, fields, act, showHelp } = props;
  const visibleFields = (fields || []).filter(
    (field) => field.visible !== false,
  );

  if (!visibleFields.length) {
    return null;
  }

  return (
    <Section fitted title={title}>
      <LabeledList>
        {visibleFields.map((field) => (
          <FieldEditor
            key={field.id}
            field={field}
            act={act}
            showHelp={showHelp}
          />
        ))}
      </LabeledList>
    </Section>
  );
};

const CompactStateCard = (props: {
  readonly title: string;
  readonly children: ReactNode;
  readonly color?: string;
}) => {
  const { title, children, color } = props;

  return (
    <Box
      p={0.75}
      mb={0.75}
      style={{
        border: `1px solid ${color === 'bad' ? '#8f3c34' : '#466b96'}`,
        background:
          color === 'bad'
            ? 'rgba(143, 60, 52, 0.16)'
            : 'rgba(70, 107, 150, 0.12)',
        borderRadius: '4px',
      }}
    >
      <Box bold color={color || 'white'} mb={0.5}>
        {title}
      </Box>
      {children}
    </Box>
  );
};

const PresetLibrarySection = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
}) => {
  const { data, act } = props;
  const [selectedPresetId, setSelectedPresetId] = useState('');

  useEffect(() => {
    if (!data.preset_entries?.length) {
      if (selectedPresetId) {
        setSelectedPresetId('');
      }
      return;
    }

    if (
      !selectedPresetId ||
      !data.preset_entries.some((preset) => preset.id === selectedPresetId)
    ) {
      setSelectedPresetId(data.preset_entries[0].id);
    }
  }, [data.preset_entries, selectedPresetId]);

  const selectedPreset =
    data.preset_entries?.find((preset) => preset.id === selectedPresetId) ||
    data.preset_entries?.[0];

  return (
    <Section
      title={getPresetSectionTitle()}
      buttons={
        <Button compact onClick={() => act('save_preset')}>
          {getActionButtonLabel('save')}
        </Button>
      }
    >
      <Box color="label" mb={1}>
        {getAssetSelectionHint('preset')}
      </Box>
      {!data.preset_entries?.length && (
        <Box color="label">{getLibraryEmptyLabel('preset')}</Box>
      )}

      {!!data.preset_entries?.length && (
        <>
          <Flex wrap mx={-0.5}>
            {data.preset_entries.map((preset) => (
              <Flex.Item key={preset.id} basis="48%" grow m={0.5}>
                <Box
                  p={0.6}
                  onClick={() => {
                    setSelectedPresetId(preset.id);
                    act('load_preset', {
                      preset_id: preset.id,
                    });
                  }}
                  style={getSelectableCardStyle(
                    preset.id ===
                      getPresetSelectionState(selectedPreset?.id || ''),
                  )}
                >
                  <Box
                    bold
                    color={preset.id === selectedPreset?.id ? 'good' : 'white'}
                  >
                    {getDisplayText(preset.name, 'Пресет без имени')}
                  </Box>
                  <Box color="label" mt={0.25}>
                    {preset.params_short || 'Без краткого описания параметров.'}
                  </Box>
                </Box>
              </Flex.Item>
            ))}
          </Flex>

          {!!selectedPreset && (
            <Section title={getSelectedPresetTitle(selectedPreset)} mt={1}>
              <Box color="label">
                {getDetailLabel('created')}:{' '}
                {getDisplayText(selectedPreset.created_at, EMPTY_LABEL)}
              </Box>
              <Box color="label" mt={0.5}>
                {getOperationParamsLabel()}:{' '}
                {getDisplayText(selectedPreset.params_short, EMPTY_LABEL)}
              </Box>

              <ActionRow>
                <ActionItem>
                  <Button
                    compact
                    color="average"
                    onClick={() =>
                      act('delete_preset', {
                        preset_id: selectedPreset.id,
                      })
                    }
                  >
                    {getActionButtonLabel('delete')}
                  </Button>
                </ActionItem>
              </ActionRow>
            </Section>
          )}
        </>
      )}
    </Section>
  );
};

const BlueprintLibrarySection = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
}) => {
  const { data, act } = props;
  const [selectedBlueprintId, setSelectedBlueprintId] = useState('');

  useEffect(() => {
    if (!data.blueprint_entries?.length) {
      if (selectedBlueprintId) {
        setSelectedBlueprintId('');
      }
      return;
    }

    const preferredId =
      data.active_blueprint_id &&
      data.blueprint_entries.some(
        (entry) => entry.id === data.active_blueprint_id,
      )
        ? data.active_blueprint_id
        : data.blueprint_entries[0].id;

    if (
      !selectedBlueprintId ||
      !data.blueprint_entries.some(
        (blueprint) => blueprint.id === selectedBlueprintId,
      )
    ) {
      setSelectedBlueprintId(preferredId);
    }
  }, [data.active_blueprint_id, data.blueprint_entries, selectedBlueprintId]);

  const selectedBlueprint =
    data.blueprint_entries?.find(
      (blueprint) => blueprint.id === selectedBlueprintId,
    ) || data.blueprint_entries?.[0];

  return (
    <Section
      title={getBlueprintTitle()}
      buttons={
        <Button compact onClick={() => act('list_blueprints')}>
          {getActionButtonLabel('refresh')}
        </Button>
      }
    >
      {!data.blueprint_entries?.length && (
        <Box color="label">{getLibraryEmptyLabel('blueprint')}</Box>
      )}

      {!!data.blueprint_entries?.length && (
        <Flex wrap mx={-0.5}>
          <Flex.Item basis="46%" grow m={0.5} style={{ minWidth: '18rem' }}>
            <Box color="label" mb={0.5}>
              {getAssetSelectionHint('blueprint', data)}
            </Box>
            {data.blueprint_entries.map((blueprint) => {
              const isActive = blueprint.id === data.active_blueprint_id;
              const isSelected = blueprint.id === selectedBlueprint?.id;
              return (
                <Box
                  key={blueprint.id}
                  p={0.6}
                  mb={0.5}
                  onClick={() => {
                    setSelectedBlueprintId(blueprint.id);
                    if (!isActive) {
                      act('load_blueprint', {
                        blueprint_id: blueprint.id,
                      });
                    }
                  }}
                  style={getSelectableCardStyle(isActive)}
                >
                  <Box bold color={isSelected || isActive ? 'good' : 'white'}>
                    {getDisplayText(blueprint.name, 'Blueprint без имени')}
                  </Box>
                  <Box color={isActive ? 'good' : 'label'} mt={0.25}>
                    {isActive ? 'Текущий blueprint' : 'Клик выбирает blueprint'}
                  </Box>
                  <Box color="label" mt={0.25}>
                    {getPositiveCountText(
                      blueprint.entry_count,
                      'нет элементов',
                    )}
                    {' элементов'}
                    {blueprint.radius > 0
                      ? ` · радиус ${blueprint.radius}`
                      : ''}
                  </Box>
                </Box>
              );
            })}
          </Flex.Item>

          <Flex.Item basis="48%" grow m={0.5} style={{ minWidth: '20rem' }}>
            {!!selectedBlueprint && (
              <CompactStateCard
                title={getSelectedBlueprintTitle(selectedBlueprint)}
                color={
                  !selectedBlueprint.valid
                    ? 'bad'
                    : selectedBlueprint.active
                      ? 'good'
                      : undefined
                }
              >
                {!!selectedBlueprint.active && (
                  <Box color="good" mb={0.5}>
                    {getSelectedBlueprintMessage(selectedBlueprint)}
                  </Box>
                )}

                {!selectedBlueprint.valid && (
                  <NoticeBox danger>
                    {getBlueprintInvalidText(selectedBlueprint)}
                  </NoticeBox>
                )}

                <CompactStatusRow
                  basis="48%"
                  items={[
                    {
                      label: getDetailLabel('items'),
                      value: getPositiveCountText(
                        selectedBlueprint.entry_count,
                        'нет',
                      ),
                    },
                    {
                      label: 'Радиус',
                      value:
                        selectedBlueprint.radius > 0
                          ? selectedBlueprint.radius
                          : EMPTY_LABEL,
                    },
                    {
                      label: getDetailLabel('source'),
                      value: getDisplayText(
                        selectedBlueprint.source,
                        EMPTY_LABEL,
                      ),
                      color: 'label',
                    },
                    {
                      label: getDetailLabel('author'),
                      value: getDisplayText(
                        selectedBlueprint.created_by,
                        EMPTY_LABEL,
                      ),
                      color: 'label',
                    },
                  ]}
                />

                <Box color="label" mt={0.75}>
                  Предпросмотр, применение и размещение выполняются через
                  верхнюю панель.
                </Box>
              </CompactStateCard>
            )}
          </Flex.Item>
        </Flex>
      )}
    </Section>
  );
};

const BlueprintExportSection = (props: {
  readonly data: BackendData;
  readonly act: (action: string, payload?: Record<string, unknown>) => void;
}) => {
  const { data, act } = props;

  return (
    <Section title={getExportSectionTitle()}>
      <Box color="label" mb={1}>
        Текущий предпросмотр можно сохранить как компактный blueprint.
      </Box>
      <Button
        compact
        disabled={!data.can_save_blueprint_from_plan}
        onClick={() => act('save_blueprint')}
      >
        {getActionButtonLabel('savePreview')}
      </Button>
    </Section>
  );
};

const PlacementSetupSection = (props: {
  readonly data: BackendData;
  readonly act: (action: string, payload?: Record<string, unknown>) => void;
}) => {
  const { data, act } = props;
  const isCollector = data.placement_interaction_kind === 'collector';
  const collectorTarget = Math.max(
    data.placement_collector_max_points || 0,
    data.placement_collector_min_points || 0,
    1,
  );
  const placementTiles: SummaryTile[] = [
    {
      label: 'Состояние',
      value: data.click_mode_active ? 'Активно' : OFF_LABEL,
      color: data.click_mode_active ? 'good' : 'label',
    },
  ];

  if (data.placement_supported) {
    placementTiles.push({
      label: 'Режим',
      value: getPlacementOptionLabel(
        data.placement_mode_options,
        data.placement_mode,
      ),
    });
  }

  if (data.placement_shape_supported) {
    placementTiles.push({
      label: 'Форма',
      value: getPlacementOptionLabel(
        data.placement_shape_options,
        data.placement_shape,
      ),
    });
  }

  if (data.placement_interaction_label) {
    placementTiles.push({
      label: 'Ввод',
      value: getDisplayText(data.placement_interaction_label, 'Один клик'),
    });
  }

  if (data.placement_supports_direction) {
    placementTiles.push({
      label: 'Направление',
      value: getPlacementOptionLabel(
        data.placement_dir_options,
        data.placement_dir,
      ),
    });
  }

  return (
    <Section title="Размещение">
      <CompactStatusRow items={placementTiles} />

      <Section title="Настройки" mt={0.5}>
        <LabeledList>
          {data.placement_shape_supported && (
            <LabeledList.Item label="Форма">
              <Dropdown
                width="100%"
                options={(data.placement_shape_options || []).map((option) => ({
                  value: option.value,
                  displayText: option.description ? (
                    <Box>
                      <Box>{option.label}</Box>
                      <Box color="label" fontSize={0.85}>
                        {option.description}
                      </Box>
                    </Box>
                  ) : (
                    option.label
                  ),
                }))}
                selected={data.placement_shape}
                displayText={getPlacementOptionLabel(
                  data.placement_shape_options,
                  data.placement_shape,
                )}
                onSelected={(value) =>
                  act('set_placement_shape', { shape: value })
                }
              />
            </LabeledList.Item>
          )}

          {data.placement_supported && (
            <LabeledList.Item label="Режим размещения">
              <Dropdown
                width="100%"
                options={(data.placement_mode_options || []).map((option) => ({
                  value: option.value,
                  displayText: option.description ? (
                    <Box>
                      <Box>{option.label}</Box>
                      <Box color="label" fontSize={0.85}>
                        {option.description}
                      </Box>
                    </Box>
                  ) : (
                    option.label
                  ),
                }))}
                selected={data.placement_mode}
                displayText={getPlacementOptionLabel(
                  data.placement_mode_options,
                  data.placement_mode,
                )}
                onSelected={(value) =>
                  act('set_placement_mode', { mode: value })
                }
              />
            </LabeledList.Item>
          )}

          {data.placement_supports_direction && (
            <LabeledList.Item label="Направление">
              <Dropdown
                width="100%"
                options={(data.placement_dir_options || []).map((option) => ({
                  value: option.value,
                  displayText: option.label,
                }))}
                selected={data.placement_dir}
                displayText={getPlacementOptionLabel(
                  data.placement_dir_options,
                  data.placement_dir,
                )}
                onSelected={(value) =>
                  act('set_placement_dir', { direction: value })
                }
              />
            </LabeledList.Item>
          )}
        </LabeledList>
      </Section>

      <Box color="label" mt={0.5} mb={0.5}>
        {interactionHelpText(data)}
      </Box>

      {isCollector && (
        <>
          <Section title="Коллектор" mt={0.5}>
            <ProgressBar
              value={data.placement_collector_point_count || 0}
              maxValue={collectorTarget}
              ranges={{
                average: [
                  0,
                  Math.max(data.placement_collector_min_points || 1, 1),
                ],
                good: [
                  Math.max(data.placement_collector_min_points || 1, 1),
                  collectorTarget,
                ],
              }}
            >
              {`${data.placement_collector_point_count || 0}/${collectorTarget}`}
            </ProgressBar>

            <CompactStatusRow
              basis="32%"
              items={[
                {
                  label: 'Готово',
                  value: boolText(data.can_finish_placement_collection),
                  color: data.can_finish_placement_collection
                    ? 'good'
                    : 'label',
                },
                {
                  label: 'Минимум',
                  value: `${data.placement_collector_min_points || 0}`,
                },
              ]}
            />

            <Box color="label" mt={1}>
              {getDisplayText(
                data.placement_collector_summary,
                'Точки пока не выбраны.',
              )}
            </Box>
          </Section>

          <Collapsible title="Технические точки коллектора" mt={0.5}>
            <LabeledList>
              <LabeledList.Item label="Источник">
                {getDisplayText(data.placement_collector_origin, EMPTY_LABEL)}
              </LabeledList.Item>
              <LabeledList.Item label="Точки">
                {getDisplayText(
                  data.placement_collector_points_text,
                  EMPTY_LABEL,
                )}
              </LabeledList.Item>
            </LabeledList>
          </Collapsible>
        </>
      )}

      {!!data.placement_shape_fields?.length && (
        <Section title="Параметры формы" mt={0.5}>
          <LabeledList>
            {data.placement_shape_fields.map((field) => (
              <FieldEditor key={field.id} field={field} act={act} showHelp />
            ))}
          </LabeledList>
        </Section>
      )}

      <Collapsible title="Технический статус размещения" mt={0.5}>
        <LabeledList>
          <LabeledList.Item label="Anchor">
            {getDisplayText(data.placement_anchor, EMPTY_LABEL)}
          </LabeledList.Item>
          <LabeledList.Item label="Stage">
            {getDisplayText(data.placement_shape_rollout_stage, EMPTY_LABEL)}
          </LabeledList.Item>
        </LabeledList>
      </Collapsible>
    </Section>
  );
};

const WorkspaceCommandBar = (props: {
  readonly data: BackendData;
  readonly act: (action: string, payload?: Record<string, unknown>) => void;
}) => {
  const { data, act } = props;
  const workflow = getWorkflowState(data);
  const actionHint = getActionHint(data);
  const showPlacementActions =
    data.placement_supported ||
    data.placement_shape_supported ||
    data.placement_supports_direction;
  const placementBlockReason = getPlacementBlockReason(data);
  const finishCollectionReason = getFinishCollectionReason(data);
  const canPreviewFromPanel = data.can_run_preview && !data.click_mode_active;
  const canApplyFromPanel = data.can_run_apply && !data.click_mode_active;
  const showStartPlacement =
    showPlacementActions &&
    !data.click_mode_active &&
    data.can_start_placement_mode;
  const showStopPlacement = showPlacementActions && data.click_mode_active;
  const showFinishCollection =
    data.click_mode_active && data.placement_interaction_kind === 'collector';

  return (
    <Box
      mb={1}
      style={{
        position: 'sticky',
        top: '0',
        zIndex: '5',
        background: 'rgba(18, 20, 22, 0.96)',
        borderBottom: '1px solid #466b96',
      }}
    >
      <Section fitted>
        <Flex align="center" wrap mx={-0.5}>
          <Flex.Item grow m={0.5} basis="18rem">
            <Box bold>{getShortStatus(workflow)}</Box>
            <Box color="label" mt={0.1}>
              {getStatusExplanation(workflow)}
            </Box>
          </Flex.Item>

          <Flex.Item m={0.5}>
            <CompactStatusRow
              basis="auto"
              items={[
                {
                  label: 'Предпросмотр',
                  value: getPreviewLabelText(data),
                  color: getPreviewTone(data),
                },
                {
                  label: 'Размещение',
                  value: data.click_mode_active ? 'Активно' : OFF_LABEL,
                  color: data.click_mode_active ? 'good' : 'label',
                },
              ]}
            />
          </Flex.Item>
        </Flex>

        <ActionRow>
          <ActionItem>
            <Button
              compact
              disabled={!canPreviewFromPanel}
              onClick={() => act('run_preview')}
            >
              {getActionLabel('preview')}
            </Button>
          </ActionItem>
          <ActionItem>
            <Button
              compact
              color={getCommonButtonColor('good')}
              disabled={!canApplyFromPanel}
              onClick={() => act('run_apply')}
            >
              {getActionLabel('apply')}
            </Button>
          </ActionItem>
          <ActionItem>
            <Button
              compact
              color={getCommonButtonColor('average')}
              disabled={!data.can_undo_last_operation}
              onClick={() => act('undo_last_operation')}
            >
              {getSecondaryButtonLabel('undo')}
            </Button>
          </ActionItem>
          <ActionItem>
            <Button
              compact
              color={getCommonButtonColor('average')}
              disabled={!data.has_generator}
              onClick={() => act('clear_preview')}
            >
              {getActionLabel('clear')}
            </Button>
          </ActionItem>
        </ActionRow>

        {showPlacementActions && (
          <ActionRow>
            {showStartPlacement && (
              <ActionItem>
                <Button compact onClick={() => act('start_placement_mode')}>
                  Старт размещения
                </Button>
              </ActionItem>
            )}

            {showStopPlacement && (
              <ActionItem>
                <Button
                  compact
                  color="average"
                  disabled={!data.can_stop_click_mode}
                  onClick={() => act('stop_click_mode')}
                >
                  Остановить размещение
                </Button>
              </ActionItem>
            )}

            {showFinishCollection && (
              <ActionItem>
                <Button
                  compact
                  disabled={!data.can_finish_placement_collection}
                  onClick={() => act('finish_placement_collection')}
                >
                  Завершить сбор
                </Button>
              </ActionItem>
            )}
          </ActionRow>
        )}

        {showPlacementActions &&
          !showStartPlacement &&
          !data.click_mode_active &&
          !!placementBlockReason && (
            <Box color="label" mt={0.25}>
              Размещение: {placementBlockReason}
            </Box>
          )}

        {showFinishCollection &&
          !data.can_finish_placement_collection &&
          !!finishCollectionReason && (
            <Box color="label" mt={0.25}>
              Сбор формы: {finishCollectionReason}
            </Box>
          )}

        <Collapsible title="Дополнительно" mt={0.5}>
          <ActionRow>
            <ActionItem>
              <Button
                compact
                disabled={!data.can_refresh_ui}
                onClick={() => act('refresh_ui')}
              >
                {getSecondaryButtonLabel('refresh')}
              </Button>
            </ActionItem>
            <ActionItem>
              <Button compact onClick={() => act('configure_wizard')}>
                {getSecondaryButtonLabel('wizard')}
              </Button>
            </ActionItem>
            <ActionItem>
              <Button
                compact
                color={getCommonButtonColor('average')}
                onClick={() => act('reset_generator')}
              >
                {getSecondaryButtonLabel('reset')}
              </Button>
            </ActionItem>
          </ActionRow>
        </Collapsible>

        {!!actionHint && (
          <Box color="label" mt={0.5}>
            {actionHint}
          </Box>
        )}
      </Section>
    </Box>
  );
};

const WorkspaceSessionSection = (props: {
  readonly data: BackendData;
  readonly act: (action: string, payload?: Record<string, unknown>) => void;
}) => {
  const { data, act } = props;

  return (
    <>
      <CompactStatusRow
        items={[
          {
            label: 'Предпросмотр',
            value: getPreviewLabelText(data),
            color: getPreviewTone(data),
          },
          {
            label: 'Применение',
            value: getApplyReadinessLabel(data),
            color: data.can_run_apply ? 'good' : 'average',
          },
          {
            label: 'Блюпринт',
            value: data.active_blueprint_id || 'не выбран',
          },
        ]}
      />

      <Box color={getPreviewTone(data)}>{getPreviewMessageText(data)}</Box>

      <ActionRow>
        <ActionItem>
          <Button
            compact
            color={getCommonButtonColor('average')}
            disabled={!data.can_undo_last_operation}
            onClick={() => act('undo_last_operation')}
          >
            {getSecondaryButtonLabel('undo')}
          </Button>
        </ActionItem>
        <ActionItem>
          <Button
            compact
            color={getCommonButtonColor('average')}
            disabled={!data.can_cleanup_last_owned_effects}
            onClick={() => act('cleanup_last_owned_effects')}
          >
            {getSecondaryButtonLabel('cleanup')}
          </Button>
        </ActionItem>
      </ActionRow>

      {!!data.preview_meta && !!Object.keys(data.preview_meta).length && (
        <Collapsible title={getPreviewMetaSectionTitle()} mt={0.5}>
          <CompactStatusRow
            basis="32%"
            items={Object.entries(data.preview_meta).map(([key, value]) => ({
              label: key,
              value: renderMetaValue(value),
            }))}
          />
        </Collapsible>
      )}

      <Collapsible title={getLastApplySectionTitle()} mt={0.5}>
        <Box color={data.last_apply_success ? 'good' : 'average'}>
          {data.last_apply_message ||
            'Применение для этой сессии еще не запускалось.'}
        </Box>
      </Collapsible>

      <Collapsible title={getUndoSummarySectionTitle()} mt={0.5}>
        {!data.last_changeset && (
          <Box color="label">Запись для отката и очистки пока не создана.</Box>
        )}

        {!!data.last_changeset && (
          <>
            <CompactStatusRow
              basis="32%"
              items={[
                {
                  label: 'Генератор',
                  value: data.last_changeset.generator_id,
                },
                {
                  label: 'Политика',
                  value: data.last_changeset.undo_policy,
                },
                {
                  label: 'Статус',
                  value: data.last_changeset.undo_status,
                },
              ]}
            />
            <Box color="label" mt={0.5}>
              {getOperationIdLabel()}: {data.last_changeset.operation_id}
            </Box>
            <Box color="label" mt={0.5}>
              Создано ссылок: {data.last_changeset.created_entries} | Перемещено
              ссылок: {data.last_changeset.moved_entries} | Собственных
              эффектов: {data.last_changeset.owned_effect_entries}
            </Box>
          </>
        )}
      </Collapsible>

      <Collapsible title={getDiagnosticsSectionTitle()} mt={0.5}>
        <Collapsible title={getCurrentParamsSectionTitle()}>
          <Box>{getDisplayText(data.current_params_text, EMPTY_LABEL)}</Box>
        </Collapsible>

        <Collapsible
          title={getRuntimeStatusSectionTitle(data.runtime_status?.length || 0)}
        >
          {!data.runtime_status?.length && (
            <Box color="label">Дополнительный статус не предоставлен.</Box>
          )}
          {!!data.runtime_status?.length && (
            <LabeledList>
              {data.runtime_status.map((entry, index) => (
                <LabeledList.Item
                  key={`${entry.label}_${index}`}
                  label={entry.label}
                >
                  {entry.value}
                </LabeledList.Item>
              ))}
            </LabeledList>
          )}
        </Collapsible>
      </Collapsible>
    </>
  );
};

const GenericFieldGroups = (props: {
  readonly groupedFields: Record<string, UiField[]>;
  readonly groupNames: string[];
  readonly act: ActFn;
}) => {
  const { groupedFields, groupNames, act } = props;

  if (!groupNames.length) {
    return <Box color="label">Поля временно недоступны.</Box>;
  }

  return (
    <Flex wrap mx={-0.5}>
      {groupNames.map((groupName) => (
        <Flex.Item
          key={groupName}
          basis="48%"
          grow
          m={0.5}
          style={{ minWidth: '20rem' }}
        >
          <FieldGroupSection
            title={groupName}
            fields={groupedFields[groupName] || []}
            act={act}
          />
        </Flex.Item>
      ))}
    </Flex>
  );
};

const BlueprintStampWorkspace = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
  readonly showPlacementSetup: boolean;
}) => {
  const { data, act, showPlacementSetup } = props;

  return (
    <Flex wrap mx={-0.5}>
      <Flex.Item basis="56%" grow m={0.5} style={{ minWidth: '24rem' }}>
        <BlueprintLibrarySection data={data} act={act} />
      </Flex.Item>

      <Flex.Item basis="38%" grow m={0.5} style={{ minWidth: '20rem' }}>
        {showPlacementSetup && <PlacementSetupSection data={data} act={act} />}
      </Flex.Item>
    </Flex>
  );
};

const OutpostRadiusWorkspace = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
  readonly showPlacementSetup: boolean;
}) => {
  const { data, act, showPlacementSetup } = props;
  const familyField = getField(data.ui_fields, 'family');
  const radiusField = getField(data.ui_fields, 'radius');
  const barricadeField = getField(data.ui_fields, 'barricade_path');
  const sentryToggleField = getField(data.ui_fields, 'place_sentries');

  return (
    <Flex wrap mx={-0.5}>
      <Flex.Item basis="52%" grow m={0.5} style={{ minWidth: '24rem' }}>
        <CompactStateCard title="Текущий форпост">
          <CompactStatusRow
            basis="48%"
            items={[
              {
                label: 'Шаблон',
                value: getFieldOptionLabel(familyField),
              },
              {
                label: 'Радиус',
                value: getDisplayText(radiusField?.value, EMPTY_LABEL),
              },
              {
                label: 'Баррикады',
                value: getFieldOptionLabel(barricadeField),
              },
              {
                label: 'Турели',
                value: sentryToggleField?.value ? 'Включены' : OFF_LABEL,
                color: sentryToggleField?.value ? 'good' : 'label',
              },
            ]}
          />
        </CompactStateCard>

        <FieldGroupSection
          title="Планировка"
          fields={getFieldsByGroup(data.ui_fields, 'Layout')}
          act={act}
          showHelp
        />
        <FieldGroupSection
          title="Оборона"
          fields={[
            ...getFieldsByGroup(data.ui_fields, 'Barricades'),
            ...getFieldsByGroup(data.ui_fields, 'Sentries'),
          ]}
          act={act}
          showHelp
        />
      </Flex.Item>

      <Flex.Item basis="42%" grow m={0.5} style={{ minWidth: '22rem' }}>
        {!!data.can_manage_presets && (
          <PresetLibrarySection data={data} act={act} />
        )}
        <BlueprintExportSection data={data} act={act} />
        {showPlacementSetup && <PlacementSetupSection data={data} act={act} />}
      </Flex.Item>
    </Flex>
  );
};

const DestructionPackWorkspace = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
}) => {
  const { data, act } = props;
  const fireFields = [
    ...getFieldsById(data.ui_fields, ['persistent_fire_enabled']),
    ...getSafeFieldList(data.ui_fields, ['persistent_fire_density']),
  ];
  const blastFields = [
    ...getFieldsById(data.ui_fields, ['blast_enabled']),
    ...getSafeFieldList(data.ui_fields, ['blast_power', 'blast_falloff']),
  ];
  const damageFields = getFieldsById(data.ui_fields, ['damage_profile']);
  const modeFields = [
    ...getFieldsById(data.ui_fields, ['shuffle_enabled', 'scatter_enabled']),
    ...getSafeFieldList(data.ui_fields, ['scatter_steps']),
  ];

  return (
    <Flex wrap mx={-0.5}>
      <Flex.Item basis="48%" grow m={0.5} style={{ minWidth: '22rem' }}>
        <FieldGroupSection
          title="Область"
          fields={getFieldsByGroup(data.ui_fields, 'Area')}
          act={act}
          showHelp
        />
        <FieldGroupSection
          title="Перемещение"
          fields={modeFields}
          act={act}
          showHelp
        />
      </Flex.Item>

      <Flex.Item basis="48%" grow m={0.5} style={{ minWidth: '22rem' }}>
        <FieldGroupSection
          title="Огонь"
          fields={fireFields}
          act={act}
          showHelp
        />

        {!!blastFields.length && (
          <Collapsible title="Взрыв" mt={0.5}>
            <CompactStateCard title="Опасный режим" color="bad">
              <Box color="average" mb={0.75}>
                Взрыв разрушает область и отключает полный откат.
              </Box>
              <FieldGroupSection fields={blastFields} title="Взрыв" act={act} />
            </CompactStateCard>
          </Collapsible>
        )}

        {!!damageFields.length && (
          <Collapsible title="Урон" mt={0.5}>
            <CompactStateCard title="Структурный урон" color="bad">
              <Box color="average" mb={0.75}>
                Урон ограничивает откат и должен использоваться отдельно от
                безопасного перемещения.
              </Box>
              <FieldGroupSection
                fields={damageFields}
                title="Профиль урона"
                act={act}
              />
            </CompactStateCard>
          </Collapsible>
        )}

        <Collapsible title="Лимиты" mt={0.5}>
          <FieldGroupSection
            title="Лимиты"
            fields={getFieldsByGroup(data.ui_fields, 'Limits')}
            act={act}
            showHelp
          />
        </Collapsible>
      </Flex.Item>
    </Flex>
  );
};

const GenericToolWorkspace = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
  readonly groupedFields: Record<string, UiField[]>;
  readonly groupNames: string[];
  readonly showBlueprintExport: boolean;
  readonly showBlueprintLibrary: boolean;
  readonly showPlacementSetup: boolean;
}) => {
  const {
    data,
    act,
    groupedFields,
    groupNames,
    showBlueprintExport,
    showBlueprintLibrary,
    showPlacementSetup,
  } = props;
  const hasAssets =
    data.can_manage_presets || showBlueprintExport || showBlueprintLibrary;
  const hasPrimaryContent =
    data.has_inline_fields || hasAssets || showPlacementSetup;

  return (
    <>
      {!hasPrimaryContent && (
        <Section mt={1}>
          <Box color="label">{getParamEmptyLabel()}</Box>
        </Section>
      )}

      {!!data.has_inline_fields && (
        <Section mt={1} title="Настройки">
          <GenericFieldGroups
            groupedFields={groupedFields}
            groupNames={groupNames}
            act={act}
          />
        </Section>
      )}

      {hasAssets && (
        <>
          {!!data.can_manage_presets && (
            <PresetLibrarySection data={data} act={act} />
          )}
          {showBlueprintExport && (
            <BlueprintExportSection data={data} act={act} />
          )}
          {showBlueprintLibrary && (
            <BlueprintLibrarySection data={data} act={act} />
          )}
        </>
      )}

      {showPlacementSetup && <PlacementSetupSection data={data} act={act} />}
    </>
  );
};

const ToolWorkspace = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
  readonly groupedFields: Record<string, UiField[]>;
  readonly groupNames: string[];
  readonly showBlueprintExport: boolean;
  readonly showBlueprintLibrary: boolean;
  readonly showPlacementSetup: boolean;
}) => {
  const {
    data,
    act,
    groupedFields,
    groupNames,
    showBlueprintExport,
    showBlueprintLibrary,
    showPlacementSetup,
  } = props;

  if (data.current_generator_id === 'blueprint_stamp') {
    return (
      <BlueprintStampWorkspace
        data={data}
        act={act}
        showPlacementSetup={showPlacementSetup}
      />
    );
  }

  if (data.current_generator_id === 'outpost_radius') {
    return (
      <OutpostRadiusWorkspace
        data={data}
        act={act}
        showPlacementSetup={showPlacementSetup}
      />
    );
  }

  if (data.current_generator_id === 'destruction_pack') {
    return <DestructionPackWorkspace data={data} act={act} />;
  }

  return (
    <GenericToolWorkspace
      data={data}
      act={act}
      groupedFields={groupedFields}
      groupNames={groupNames}
      showBlueprintExport={showBlueprintExport}
      showBlueprintLibrary={showBlueprintLibrary}
      showPlacementSetup={showPlacementSetup}
    />
  );
};

const WorkspacePage = (props: {
  readonly data: BackendData;
  readonly act: (action: string, payload?: Record<string, unknown>) => void;
  readonly groupedFields: Record<string, UiField[]>;
  readonly groupNames: string[];
  readonly showBlueprintExport: boolean;
  readonly showBlueprintLibrary: boolean;
  readonly showPlacementSetup: boolean;
}) => {
  const {
    data,
    act,
    groupedFields,
    groupNames,
    showBlueprintExport,
    showBlueprintLibrary,
    showPlacementSetup,
  } = props;

  return (
    <Section fill scrollable title={getWorkspacePageTitle(data)}>
      {!data.has_generator && (
        <Box color="label" mb={1}>
          {getWorkEmptyLabel()}
        </Box>
      )}

      {!!data.has_generator && (
        <>
          {!!data.last_ui_error && (
            <NoticeBox danger>{data.last_ui_error}</NoticeBox>
          )}

          <WorkspaceCommandBar data={data} act={act} />

          <Box color="label" mb={0.5}>
            {getCurrentGeneratorDescription(data)}
          </Box>

          <ToolWorkspace
            data={data}
            act={act}
            groupedFields={groupedFields}
            groupNames={groupNames}
            showBlueprintExport={showBlueprintExport}
            showBlueprintLibrary={showBlueprintLibrary}
            showPlacementSetup={showPlacementSetup}
          />
        </>
      )}
    </Section>
  );
};

const HistoryPage = (props: {
  readonly data: BackendData;
  readonly act: (action: string, payload?: Record<string, unknown>) => void;
}) => {
  const { data, act } = props;
  const latestEntry = data.history_entries?.[0];

  return (
    <Section
      fill
      scrollable
      title={getHistoryPageTitle()}
      buttons={
        <Button
          compact
          color={getCommonButtonColor('average')}
          onClick={() => act('clear_history')}
        >
          {getActionLabel('clear')}
        </Button>
      }
    >
      <Collapsible title="Сессия и откат">
        <WorkspaceSessionSection data={data} act={act} />
      </Collapsible>

      {!data.history_entries?.length && (
        <Box color="label" mt={1}>
          {getHistoryEmptyLabel()}
        </Box>
      )}

      {!!data.history_entries?.length && (
        <>
          <Box mt={1}>
            <CompactStatusRow
              items={getHistorySummaryItems(data, latestEntry)}
            />
          </Box>

          {data.history_entries.map((entry, index) => (
            <Collapsible
              key={`${entry.time}_${entry.generator_id}_${index}`}
              title={getHistoryEntryTitle(data, entry)}
              open={index === 0}
              color={getHistoryEntryTone(entry)}
            >
              <CompactStatusRow
                basis="32%"
                items={getHistoryDetailItems(entry)}
              />

              <Box color="label" mt={0.5}>
                {getOperationMessageLabel()}: {getHistoryEntryMessage(entry)}
              </Box>
              <Collapsible title={getHistoryDetailsSectionTitle()} mt={0.5}>
                <Box color={getHistoryMessageColor()}>
                  {getOperationParamsLabel()}:{' '}
                  {getHistoryTechnicalDetails(entry).params}
                </Box>
                {!!entry.operation_id && (
                  <Box color={getHistoryMessageColor()} mt={0.5}>
                    {getOperationIdLabel()}:{' '}
                    {getHistoryTechnicalDetails(entry).operationId}
                  </Box>
                )}
              </Collapsible>
            </Collapsible>
          ))}
        </>
      )}
    </Section>
  );
};

const Sidebar = (props: {
  readonly data: BackendData;
  readonly activeCategory?: string;
  readonly historyActive: boolean;
  readonly onSelectCategory: (category: GeneratorCategory) => void;
  readonly onOpenHistory: () => void;
}) => {
  const {
    data,
    activeCategory,
    historyActive,
    onSelectCategory,
    onOpenHistory,
  } = props;

  return (
    <Section fill scrollable fitted title="World Edit">
      <Tabs vertical fluid>
        {(data.categories || []).map((category) => (
          <Tabs.Tab
            key={category.category}
            selected={!historyActive && category.category === activeCategory}
            fontSize={0.9}
            onClick={() => onSelectCategory(category)}
          >
            {category.category}
          </Tabs.Tab>
        ))}
        <Tabs.Tab
          key="history"
          selected={historyActive}
          icon="history"
          fontSize={0.9}
          onClick={onOpenHistory}
        >
          {getHistoryButtonLabel()}
        </Tabs.Tab>
      </Tabs>
    </Section>
  );
};

export const WorldEditPanel = () => {
  const { data, act } = useBackend<BackendData>();
  const [showHistory, setShowHistory] = useState(false);
  const [activeCategory, setActiveCategory] = useState('');
  const showBlueprintExport = data.current_generator_id === 'outpost_radius';
  const showBlueprintLibrary = data.current_generator_id === 'blueprint_stamp';
  const showPlacementSetup =
    data.placement_supported ||
    data.placement_shape_supported ||
    data.placement_supports_direction;

  const groupedFields = useMemo(() => {
    const groups: Record<string, UiField[]> = {};
    for (const field of data.ui_fields || []) {
      const groupName = field.group || 'Основные';
      if (!groups[groupName]) {
        groups[groupName] = [];
      }
      groups[groupName].push(field);
    }
    return groups;
  }, [data.ui_fields]);

  const groupNames = useMemo(() => Object.keys(groupedFields), [groupedFields]);

  useEffect(() => {
    if (data.current_generator_category) {
      setActiveCategory(data.current_generator_category);
      return;
    }

    if (
      !data.has_generator ||
      !data.categories?.some((category) => category.category === activeCategory)
    ) {
      setActiveCategory('');
    }
  }, [
    activeCategory,
    data.categories,
    data.current_generator_category,
    data.has_generator,
  ]);

  const handleSelectCategory = (category: GeneratorCategory) => {
    setShowHistory(false);
    setActiveCategory(category.category);

    const nextGenerator =
      category.generators?.find(
        (generator) => generator.id === data.current_generator_id,
      ) || category.generators?.[0];

    if (nextGenerator && nextGenerator.id !== data.current_generator_id) {
      act('select_generator', {
        generator_id: nextGenerator.id,
      });
    }
  };

  return (
    <Window title="World Edit Panel" width={950} height={620}>
      <Window.Content>
        <Stack fill>
          <Stack.Item width={8}>
            <Sidebar
              data={data}
              activeCategory={activeCategory}
              historyActive={showHistory}
              onSelectCategory={handleSelectCategory}
              onOpenHistory={() => setShowHistory(true)}
            />
          </Stack.Item>

          <Stack.Item grow basis={0} ml={1}>
            {!showHistory && (
              <WorkspacePage
                data={data}
                act={act}
                groupedFields={groupedFields}
                groupNames={groupNames}
                showBlueprintExport={showBlueprintExport}
                showBlueprintLibrary={showBlueprintLibrary}
                showPlacementSetup={showPlacementSetup}
              />
            )}

            {showHistory && <HistoryPage data={data} act={act} />}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
