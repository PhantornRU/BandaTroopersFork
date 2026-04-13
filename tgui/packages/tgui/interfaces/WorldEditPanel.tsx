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

type PageDefinition = {
  id: 'browse' | 'work' | 'history';
  title: string;
  icon: string;
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

type WorkTabId = 'params' | 'assets' | 'placement' | 'session';

const PAGES: PageDefinition[] = [
  { id: 'browse', title: 'Выбор', icon: 'list' },
  { id: 'work', title: 'Работа', icon: 'sliders-h' },
  { id: 'history', title: 'История', icon: 'history' },
];

const boolText = (value: boolean, yes = 'Да', no = 'Нет') => (value ? yes : no);

const toneForGeneratorStatus = (status?: string) => {
  switch ((status || '').toLowerCase()) {
    case 'ready':
      return 'good';
    case 'deprecated':
      return 'average';
    case 'blocked':
      return 'bad';
    default:
      return 'label';
  }
};

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
    return 'n/a';
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
      label: 'n/a',
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

const CompactGeneratorRow = (props: {
  readonly generator: GeneratorEntry;
  readonly selected: boolean;
  readonly onActivate: () => void;
}) => <GeneratorListRow {...props} />;

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
    return 'n/a';
  }
  if (data.can_run_apply) {
    return 'готово';
  }
  if (data.requires_preview_before_apply && !data.preview_valid) {
    return 'нужен preview';
  }
  return 'недоступно';
};

const getPlacementStateLabel = (data: BackendData) => {
  if (
    !(
      data.placement_supported ||
      data.placement_shape_supported ||
      data.placement_supports_direction
    )
  ) {
    return 'n/a';
  }
  return data.click_mode_active ? 'вкл' : 'выкл';
};

const getHistoryStateLabel = (data: BackendData) => {
  const count = data.history_entries?.length || 0;
  return count ? `${count}` : 'пусто';
};

const getGeneratorDetailLabel = (generator: GeneratorEntry) => {
  if (generator.status?.toLowerCase() === 'ready') {
    return 'Готов к работе';
  }
  return `Статус: ${generator.status || 'n/a'}`;
};

const getGeneratorSelectionHint = (
  data: BackendData,
  totalGenerators: number,
) => {
  if (!totalGenerators) {
    return 'Нет доступных инструментов для текущих прав.';
  }
  if (data.current_generator_name) {
    return `Клик по элементу сразу открывает его в работе. Текущий инструмент: ${data.current_generator_name}.`;
  }
  return 'Клик по элементу сразу открывает его в работе.';
};

const getBlueprintSelectionHint = (data: BackendData) => {
  if (data.placement_active) {
    return 'Пока активен режим размещения, список можно смотреть, но действия временно недоступны.';
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

const getOperationHeader = (entry: HistoryEntry) => {
  const result = entry.result || 'n/a';
  return `${entry.time} | ${entry.generator_id} | ${result}`;
};

const getOperationResultLabel = (entry?: HistoryEntry) => {
  if (!entry?.result) {
    return 'n/a';
  }
  return entry.result;
};

const getSidebarDescription = (data: BackendData, workflow: WorkflowState) => {
  if (!data.has_generator) {
    return workflow.description;
  }
  return workflow.label;
};

const getHistorySummaryLabel = (data: BackendData) => {
  const count = data.history_entries?.length || 0;
  if (!count) {
    return 'История пока пуста.';
  }
  return `Записей: ${count}`;
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

const getBrowseTitle = (data: BackendData) =>
  data.current_generator_name
    ? `Инструменты / ${data.current_generator_name}`
    : 'Инструменты';

const getHistoryTitle = () => 'История операций';

const getWorkspaceTitle = (data: BackendData) =>
  data.has_generator ? `Работа / ${data.current_generator_name}` : 'Работа';

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

const getCommonStatusItems = (data: BackendData): SummaryTile[] => [
  {
    label: 'Предпросмотр',
    value: getPreviewState(data).label,
    color: getPreviewState(data).color,
  },
  {
    label: 'Применение',
    value: getApplyReadinessLabel(data),
    color: getToolbarStatusColor(data, 'apply'),
  },
  {
    label: 'Размещение',
    value: getPlacementStateLabel(data),
    color: getToolbarStatusColor(data, 'placement'),
  },
  {
    label: 'История',
    value: getHistoryStateLabel(data),
    color: getToolbarStatusColor(data, 'history'),
  },
];

const getHistoryResultTone = (entry?: HistoryEntry) =>
  toneForHistoryResult(entry?.result);

const getHistoryResultText = (entry?: HistoryEntry) => entry?.result || 'n/a';

const getSelectionEmptyText = () =>
  'Нет доступных инструментов для текущих прав.';

const getAssetEmptyText = () =>
  'Для текущего инструмента дополнительные библиотеки и пресеты не используются.';

const getParamEmptyText = () =>
  'Для этого инструмента настройка доступна только через мастер.';

const getPlacementEmptyText = () =>
  'Для текущего инструмента режим размещения не используется.';

const getWorkEmptyText = () =>
  'Сначала выберите инструмент на странице «Выбор».';

const getHistoryEmptyText = () => 'История операций пока пуста.';

const getPreviewMetaTitle = () => 'Сводка preview';

const getDiagnosticsTitle = () => 'Технические детали';

const getCurrentParamsTitle = () => 'Текущие параметры';

const getRuntimeStatusTitle = (count: number) => `Служебный статус (${count})`;

const getHistoryDetailsTitle = () => 'Технические детали';

const getSessionSummaryTitle = (count: number) =>
  `Последние операции (${count})`;

const getUndoSummaryTitle = () => 'Откат и очистка';

const getLastApplyTitle = () => 'Последнее применение';

const getPlacementTabTitle = () => 'Размещение';

const getAssetsTabTitle = () => 'Ресурсы';

const getParamsTabTitle = () => 'Параметры';

const getSessionTabTitle = () => 'Сессия';

const getLibraryTitle = () => 'Библиотека blueprint';

const getPresetTitle = () => 'Пресеты';

const getExportTitle = () => 'Экспорт';

const getGeneratorOpenLabel = () => 'Открыть';

const getSelectedLabel = () => 'Текущий';

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

const getBackToWorkLabel = () => 'Вернуться к работе';

const getChooseGeneratorLabel = () => 'Перейти к выбору инструмента';

const getNoBlueprintsLabel = () => 'В библиотеке пока нет blueprint-ов.';

const getNoPresetsLabel = () =>
  'Для текущего инструмента еще нет сохраненных пресетов.';

const getSaveLabel = () => 'Сохранить';

const getSavePreviewLabel = () => 'Сохранить preview';

const getDeleteLabel = () => 'Удалить';

const getGeneratorRowActionLabel = (selected: boolean) =>
  selected ? getSelectedLabel() : getGeneratorOpenLabel();

const getGeneratorRowStyle = (selected: boolean) => ({
  border: selected ? '1px solid #4c9f39' : '1px solid #466b96',
  background: selected ? 'rgba(76, 159, 57, 0.16)' : 'rgba(70, 107, 150, 0.14)',
  borderRadius: '4px',
  cursor: 'pointer',
});

const getSelectedAssetId = (id?: string) => id || '';

const getBlueprintDetailsTitle = (entry: BlueprintEntry) =>
  `${entry.name} [r=${entry.radius}]`;

const getPresetDetailsTitle = (entry: PresetEntry) => entry.name || entry.id;

const getWorkStatusText = (workflow: WorkflowState) => workflow.label;

const getWorkStatusDescription = (workflow: WorkflowState) =>
  workflow.description;

const getTechnicalParamText = (params?: string) => params || 'n/a';

const getOperationIdText = (operationId?: string) => operationId || 'n/a';

const getOperationCenterText = (center?: string) => center || 'n/a';

const getOperationDurationText = (durationMs?: number) =>
  `${durationMs ?? 0} ms`;

const getUndoStatusText = (entry: HistoryEntry) =>
  entry.undo_policy
    ? `${entry.undo_policy} / ${entry.undo_status || 'n/a'}`
    : 'n/a';

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

const getCurrentGeneratorLabel = (name?: string) => name || 'Без инструмента';

const getBrowseHint = (data: BackendData, totalGenerators: number) =>
  getGeneratorSelectionHint(data, totalGenerators);

const getPreviewMessageText = (data: BackendData) =>
  getPreviewState(data).message;

const getPreviewLabelText = (data: BackendData) => getPreviewState(data).label;

const getPreviewTone = (data: BackendData) =>
  getPreviewState(data).color || 'label';

const getWorkspaceSummaryItems = (data: BackendData): SummaryTile[] =>
  getCommonStatusItems(data);

const getSidebarSummaryText = (data: BackendData) =>
  getSidebarDescription(data, getWorkflowState(data));

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
    value: latestEntry?.generator_id || 'n/a',
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

const getSelectionPageTitle = (data: BackendData) => getBrowseTitle(data);

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

const getSelectionIntroText = (data: BackendData, totalGenerators: number) =>
  getBrowseHint(data, totalGenerators);

const getSelectedBlueprintTitle = (selectedBlueprint: BlueprintEntry) =>
  getBlueprintDetailsTitle(selectedBlueprint);

const getSelectedPresetTitle = (selectedPreset: PresetEntry) =>
  getPresetDetailsTitle(selectedPreset);

const getBlueprintInvalidText = (selectedBlueprint: BlueprintEntry) =>
  selectedBlueprint.error || getInvalidBlueprintText();

const getHistoryEntryTitle = (entry: HistoryEntry) => getOperationHeader(entry);

const getHistoryEntryMessage = (entry: HistoryEntry) =>
  getHistorySummaryText(entry);

const getHistoryEntryTone = (entry: HistoryEntry) =>
  getHistoryResultTone(entry);

const getSelectionEmptyLabel = () => getSelectionEmptyText();

const getAssetEmptyLabel = () => getAssetEmptyText();

const getParamEmptyLabel = () => getParamEmptyText();

const getPlacementEmptyLabel = () => getPlacementEmptyText();

const getWorkEmptyLabel = () => getWorkEmptyText();

const getHistoryEmptyLabel = () => getHistoryEmptyText();

const getPreviewMetaSectionTitle = () => getPreviewMetaTitle();

const getDiagnosticsSectionTitle = () => getDiagnosticsTitle();

const getCurrentParamsSectionTitle = () => getCurrentParamsTitle();

const getRuntimeStatusSectionTitle = (count: number) =>
  getRuntimeStatusTitle(count);

const getHistoryDetailsSectionTitle = () => getHistoryDetailsTitle();

const getSessionSummarySectionTitle = (count: number) =>
  getSessionSummaryTitle(count);

const getUndoSummarySectionTitle = () => getUndoSummaryTitle();

const getLastApplySectionTitle = () => getLastApplyTitle();

const getPlacementTabLabel = () => getPlacementTabTitle();

const getAssetsTabLabel = () => getAssetsTabTitle();

const getParamsTabLabel = () => getParamsTabTitle();

const getSessionTabLabel = () => getSessionTabTitle();

const getGeneratorActionText = (selected: boolean) =>
  getGeneratorRowActionLabel(selected);

const getGeneratorCardStyle = (selected: boolean) =>
  getGeneratorRowStyle(selected);

const getBlueprintSelectionState = (data: BackendData) =>
  getSelectedAssetId(data.active_blueprint_id);

const getPresetSelectionState = (selectedPresetId: string) =>
  getSelectedAssetId(selectedPresetId);

const getGeneratorDescriptionText = (description?: string) =>
  description || 'Описание пока не заполнено.';

const getPreviewSupportText = (supportsPreview: boolean) =>
  supportsPreview ? 'Есть предпросмотр' : 'Работает без предпросмотра';

const getCurrentGeneratorStatusText = (
  selected: boolean,
  generator: GeneratorEntry,
) => (selected ? 'Текущий инструмент' : getGeneratorDetailLabel(generator));

const getSecondaryButtonLabel = (
  kind:
    | 'refresh'
    | 'wizard'
    | 'reset'
    | 'history'
    | 'undo'
    | 'cleanup'
    | 'back'
    | 'browse',
) => {
  switch (kind) {
    case 'refresh':
      return getFormRefreshLabel();
    case 'wizard':
      return getWizardLabel();
    case 'reset':
      return getResetLabel();
    case 'history':
      return getHistoryButtonLabel();
    case 'undo':
      return getUndoLabel();
    case 'cleanup':
      return getCleanupLabel();
    case 'back':
      return getBackToWorkLabel();
    case 'browse':
      return getChooseGeneratorLabel();
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

const getCommandBarItems = (data: BackendData) =>
  getWorkspaceSummaryItems(data);

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

const getToolbarStatusColor = (
  data: BackendData,
  kind: 'apply' | 'placement' | 'history',
) => {
  switch (kind) {
    case 'apply':
      return data.can_run_apply ? 'good' : 'average';
    case 'placement':
      return data.click_mode_active ? 'good' : 'label';
    case 'history':
      return data.history_entries?.length ? 'good' : 'label';
    default:
      return 'label';
  }
};

const getSelectedBlueprintMessage = (selectedBlueprint: BlueprintEntry) =>
  selectedBlueprint.active ? getBlueprintActiveText() : 'Выбранный blueprint.';

const getGeneratorRowSummary = (
  generator: GeneratorEntry,
  selected: boolean,
) => (
  <>
    <Box color="label" mt={0.25}>
      {getGeneratorDescriptionText(generator.description_ru)}
    </Box>
    <Box color={selected ? 'good' : 'label'} mt={0.25}>
      {getCurrentGeneratorStatusText(selected, generator)}
      {' • '}
      {getPreviewSupportText(generator.supports_preview)}
    </Box>
  </>
);

const GeneratorListRow = (props: {
  readonly generator: GeneratorEntry;
  readonly selected: boolean;
  readonly onActivate: () => void;
}) => {
  const { generator, selected, onActivate } = props;

  return (
    <Box
      mb={0.5}
      p={0.75}
      onClick={onActivate}
      style={getGeneratorCardStyle(selected)}
    >
      <Box>
        <Box>
          <Box bold color={selected ? 'good' : 'white'}>
            {generator.name_ru}
          </Box>
          {getGeneratorRowSummary(generator, selected)}
        </Box>
        <Box mt={0.25}>
          <Box
            color={selected ? 'good' : toneForGeneratorStatus(generator.status)}
          >
            {getGeneratorActionText(selected)}
          </Box>
        </Box>
      </Box>
    </Box>
  );
};

const FieldEditor = (props: {
  readonly field: UiField;
  readonly act: (action: string, payload?: Record<string, unknown>) => void;
}) => {
  const { field, act } = props;
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
      {!!field.description && (
        <Box color="label" mt={0.5}>
          {field.description}
        </Box>
      )}
      {!!field.validate_hint && (
        <Box color="average" mt={0.5}>
          {field.validate_hint}
        </Box>
      )}
    </LabeledList.Item>
  );
};

const PresetLibrarySection = (props: {
  readonly data: BackendData;
  readonly act: (action: string, payload?: Record<string, unknown>) => void;
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
                  style={getGeneratorCardStyle(
                    preset.id ===
                      getPresetSelectionState(selectedPreset?.id || ''),
                  )}
                >
                  <Box
                    bold
                    color={preset.id === selectedPreset?.id ? 'good' : 'white'}
                  >
                    {preset.name || preset.id}
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
                {selectedPreset.created_at || 'n/a'}
              </Box>
              <Box color="label" mt={0.5}>
                {getOperationParamsLabel()}:{' '}
                {selectedPreset.params_short || 'n/a'}
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
  readonly act: (action: string, payload?: Record<string, unknown>) => void;
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
      <Box color="label" mb={1}>
        {getAssetSelectionHint('blueprint', data)}
      </Box>

      {!data.blueprint_entries?.length && (
        <Box color="label">{getLibraryEmptyLabel('blueprint')}</Box>
      )}

      {!!data.blueprint_entries?.length && (
        <>
          <Flex wrap mx={-0.5}>
            {data.blueprint_entries.map((blueprint) => (
              <Flex.Item key={blueprint.id} basis="48%" grow m={0.5}>
                <Box
                  p={0.6}
                  onClick={() => {
                    setSelectedBlueprintId(blueprint.id);
                    if (
                      !data.placement_active &&
                      blueprint.id !== data.active_blueprint_id
                    ) {
                      act('load_blueprint', {
                        blueprint_id: blueprint.id,
                      });
                    }
                  }}
                  style={getGeneratorCardStyle(
                    blueprint.id === getBlueprintSelectionState(data),
                  )}
                >
                  <Box
                    bold
                    color={
                      blueprint.id === selectedBlueprint?.id ? 'good' : 'white'
                    }
                  >
                    {blueprint.name}
                  </Box>
                  <Box color="label" mt={0.25}>
                    {getDetailLabel('items')}: {blueprint.entry_count} | r=
                    {blueprint.radius}
                  </Box>
                </Box>
              </Flex.Item>
            ))}
          </Flex>

          {!!selectedBlueprint && (
            <Section
              title={getSelectedBlueprintTitle(selectedBlueprint)}
              mt={1}
            >
              {!!selectedBlueprint.active && (
                <Box color="good" mb={1}>
                  {getSelectedBlueprintMessage(selectedBlueprint)}
                </Box>
              )}

              {!selectedBlueprint.valid && (
                <NoticeBox danger>
                  {getBlueprintInvalidText(selectedBlueprint)}
                </NoticeBox>
              )}

              {buildDetailItems([
                {
                  label: getDetailLabel('items'),
                  value: selectedBlueprint.entry_count,
                },
                {
                  label: getDetailLabel('source'),
                  value: selectedBlueprint.source || 'n/a',
                  color: 'label',
                },
                {
                  label: getDetailLabel('author'),
                  value: selectedBlueprint.created_by || 'n/a',
                  color: 'label',
                },
              ])}

              <Box color="label" mt={1}>
                {getDetailLabel('created')}:{' '}
                {selectedBlueprint.created_at || 'n/a'}
              </Box>

              <ActionRow>
                <ActionItem>
                  <Button
                    compact
                    disabled={!selectedBlueprint.valid || data.placement_active}
                    onClick={() =>
                      act('preview_blueprint', {
                        blueprint_id: selectedBlueprint.id,
                      })
                    }
                  >
                    {getActionLabel('preview')}
                  </Button>
                </ActionItem>
                <ActionItem>
                  <Button
                    compact
                    color="good"
                    disabled={
                      !selectedBlueprint.valid ||
                      data.placement_active ||
                      !selectedBlueprint.active ||
                      !data.preview_valid
                    }
                    onClick={() =>
                      act('apply_blueprint', {
                        blueprint_id: selectedBlueprint.id,
                      })
                    }
                  >
                    {getActionLabel('apply')}
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

const BlueprintExportSection = (props: {
  readonly data: BackendData;
  readonly act: (action: string, payload?: Record<string, unknown>) => void;
}) => {
  const { data, act } = props;

  return (
    <Section title={getExportSectionTitle()}>
      <Box color="label" mb={1}>
        Для `outpost_radius` можно сохранить текущий preview как Blueprint Lite.
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
  const collectorTarget = Math.max(
    data.placement_collector_max_points || 0,
    data.placement_collector_min_points || 0,
    1,
  );

  const placementTiles: SummaryTile[] = [
    {
      label: 'Форма',
      value: data.placement_shape || 'n/a',
    },
    {
      label: 'Режим',
      value: data.placement_mode || 'n/a',
    },
    {
      label: 'Взаимодействие',
      value: data.placement_interaction_label || 'Один клик',
    },
    {
      label: 'Этап rollout',
      value: data.placement_shape_rollout_stage || 'v1',
    },
  ];

  if (data.placement_supports_direction) {
    placementTiles.push({
      label: 'Направление',
      value: data.placement_dir || 'n/a',
    });
  }

  placementTiles.push({
    label: 'Статус',
    value: data.placement_active ? 'вкл' : 'выкл',
    color: data.placement_active ? 'good' : 'label',
  });

  const placementBlockReason = getPlacementBlockReason(data);
  const finishCollectionReason = getFinishCollectionReason(data);

  return (
    <Section title="Размещение">
      <CompactStatusRow items={placementTiles} />

      <ActionRow>
        <ActionItem>
          <Button
            compact
            disabled={!data.can_start_placement_mode}
            onClick={() => act('start_placement_mode')}
          >
            Старт
          </Button>
        </ActionItem>
        <ActionItem>
          <Button
            compact
            color="average"
            disabled={!data.can_stop_click_mode}
            onClick={() => act('stop_click_mode')}
          >
            Остановить
          </Button>
        </ActionItem>
        <ActionItem>
          <Button
            compact
            disabled={!data.can_finish_placement_collection}
            onClick={() => act('finish_placement_collection')}
          >
            Готово
          </Button>
        </ActionItem>
      </ActionRow>

      {!data.can_start_placement_mode && !!placementBlockReason && (
        <Box color="label" mt={0.5}>
          Размещение: {placementBlockReason}
        </Box>
      )}

      {!data.can_finish_placement_collection &&
        data.placement_interaction_kind === 'collector' &&
        !!finishCollectionReason && (
          <Box color="label" mt={0.25}>
            Сбор формы: {finishCollectionReason}
          </Box>
        )}

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
                onSelected={(value) =>
                  act('set_placement_dir', { direction: value })
                }
              />
            </LabeledList.Item>
          )}

          <LabeledList.Item label="Текущий anchor">
            {data.placement_anchor || 'none'}
          </LabeledList.Item>
          <LabeledList.Item label="Источник коллектора">
            {data.placement_collector_origin || 'none'}
          </LabeledList.Item>
        </LabeledList>
      </Section>

      <Box color="label" mt={0.5} mb={0.5}>
        {interactionHelpText(data)}
      </Box>

      {!!data.placement_interaction_kind &&
        data.placement_interaction_kind === 'collector' && (
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
                {
                  label: 'Источник',
                  value: data.placement_collector_origin || 'none',
                  color: 'label',
                },
              ]}
            />

            <Box color="label" mt={1}>
              {data.placement_collector_summary || 'Collector summary not set.'}
            </Box>

            {!!data.placement_collector_points_text && (
              <Box color="label" mt={0.5}>
                {data.placement_collector_points_text}
              </Box>
            )}
          </Section>
        )}

      {!!data.placement_shape_fields?.length && (
        <Collapsible title="Форма" open>
          <LabeledList>
            {data.placement_shape_fields.map((field) => (
              <FieldEditor key={field.id} field={field} act={act} />
            ))}
          </LabeledList>
        </Collapsible>
      )}
    </Section>
  );
};

const GeneratorCatalogPage = (props: {
  readonly data: BackendData;
  readonly act: (action: string, payload?: Record<string, unknown>) => void;
  readonly onOpenWork: () => void;
}) => {
  const { data, act, onOpenWork } = props;
  const totalGenerators = (data.categories || []).reduce(
    (sum, category) => sum + (category.generators?.length || 0),
    0,
  );

  return (
    <Section fill scrollable title={getSelectionPageTitle(data)}>
      <Box color="label" mb={1}>
        {getSelectionIntroText(data, totalGenerators)}
      </Box>

      {!data.categories?.length && (
        <Box color="label">{getSelectionEmptyLabel()}</Box>
      )}

      {data.categories?.map((category) => (
        <Collapsible
          key={category.category}
          title={`${category.category} (${category.generators.length})`}
          open
        >
          {category.generators.map((generator) => (
            <CompactGeneratorRow
              key={generator.id}
              generator={generator}
              selected={generator.id === data.current_generator_id}
              onActivate={() => {
                if (generator.id !== data.current_generator_id) {
                  act('select_generator', {
                    generator_id: generator.id,
                  });
                }
                onOpenWork();
              }}
            />
          ))}
        </Collapsible>
      ))}
    </Section>
  );
};

const WorkspaceCommandBar = (props: {
  readonly data: BackendData;
  readonly act: (action: string, payload?: Record<string, unknown>) => void;
  readonly onOpenHistory: () => void;
}) => {
  const { data, act, onOpenHistory } = props;
  const workflow = getWorkflowState(data);
  const actionHint = getActionHint(data);

  return (
    <Section fitted>
      <CompactStatusRow items={getCommandBarItems(data)} />

      <ActionRow>
        <ActionItem>
          <Button
            compact
            disabled={!data.can_run_preview}
            onClick={() => act('run_preview')}
          >
            {getActionLabel('preview')}
          </Button>
        </ActionItem>
        <ActionItem>
          <Button
            compact
            color={getCommonButtonColor('good')}
            disabled={!data.can_run_apply}
            onClick={() => act('run_apply')}
          >
            {getActionLabel('apply')}
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
        <ActionItem>
          <Button compact icon="history" onClick={onOpenHistory}>
            {getSecondaryButtonLabel('history')}
          </Button>
        </ActionItem>
      </ActionRow>

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

      <Box color={workflow.color || 'label'} mt={0.25}>
        {getShortStatus(workflow)}
      </Box>
      <Box color="label" mt={0.1}>
        {getStatusExplanation(workflow)}
      </Box>

      {!!actionHint && (
        <Box color="label" mt={0.5}>
          {actionHint}
        </Box>
      )}
    </Section>
  );
};

const WorkspaceSessionSection = (props: {
  readonly data: BackendData;
  readonly act: (action: string, payload?: Record<string, unknown>) => void;
}) => {
  const { data, act } = props;
  const recentHistoryEntries = (data.history_entries || []).slice(0, 3);

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
            label: 'Blueprint',
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

      <Collapsible title={getLastApplySectionTitle()} open mt={0.5}>
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

      <Collapsible
        title={getSessionSummarySectionTitle(recentHistoryEntries.length)}
        mt={0.5}
      >
        {!recentHistoryEntries.length && (
          <Box color="label">История текущей сессии пока пуста.</Box>
        )}

        {!!recentHistoryEntries.length &&
          recentHistoryEntries.map((entry) => (
            <Section
              key={`${entry.time}_${entry.operation_id || entry.message}`}
              fitted
              title={getHistoryEntryTitle(entry)}
            >
              <Box color={getHistoryEntryTone(entry)}>
                {getHistoryResultText(entry)}
              </Box>
              <Box color="label">{getHistoryEntryMessage(entry)}</Box>
            </Section>
          ))}
      </Collapsible>

      <Collapsible title={getDiagnosticsSectionTitle()} mt={0.5}>
        <Collapsible title={getCurrentParamsSectionTitle()} open>
          <Box>{data.current_params_text || 'n/a'}</Box>
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

const WorkspacePage = (props: {
  readonly data: BackendData;
  readonly act: (action: string, payload?: Record<string, unknown>) => void;
  readonly groupedFields: Record<string, UiField[]>;
  readonly groupNames: string[];
  readonly showBlueprintExport: boolean;
  readonly showBlueprintLibrary: boolean;
  readonly showPlacementSetup: boolean;
  readonly onOpenBrowse: () => void;
  readonly onOpenHistory: () => void;
}) => {
  const {
    data,
    act,
    groupedFields,
    groupNames,
    showBlueprintExport,
    showBlueprintLibrary,
    showPlacementSetup,
    onOpenBrowse,
    onOpenHistory,
  } = props;
  const [workTab, setWorkTab] = useState<WorkTabId>('params');
  const hasAssets =
    data.can_manage_presets || showBlueprintExport || showBlueprintLibrary;

  useEffect(() => {
    if (workTab === 'assets' && !hasAssets) {
      setWorkTab('params');
      return;
    }
    if (workTab === 'placement' && !showPlacementSetup) {
      setWorkTab('params');
    }
  }, [hasAssets, showPlacementSetup, workTab]);

  return (
    <Section fill scrollable title={getWorkspacePageTitle(data)}>
      {!data.has_generator && (
        <>
          <Box color="label" mb={1}>
            {getWorkEmptyLabel()}
          </Box>
          <Button compact icon="list" onClick={onOpenBrowse}>
            {getSecondaryButtonLabel('browse')}
          </Button>
        </>
      )}

      {!!data.has_generator && (
        <>
          {!!data.last_ui_error && (
            <NoticeBox danger>{data.last_ui_error}</NoticeBox>
          )}

          <WorkspaceCommandBar
            data={data}
            act={act}
            onOpenHistory={onOpenHistory}
          />

          <Box color="label" mb={0.5}>
            {getCurrentGeneratorDescription(data)}
          </Box>

          <Tabs mt={0.25}>
            <Tabs.Tab
              selected={workTab === 'params'}
              fontSize={0.9}
              onClick={() => setWorkTab('params')}
            >
              {getParamsTabLabel()}
            </Tabs.Tab>
            {hasAssets && (
              <Tabs.Tab
                selected={workTab === 'assets'}
                fontSize={0.9}
                onClick={() => setWorkTab('assets')}
              >
                {getAssetsTabLabel()}
              </Tabs.Tab>
            )}
            {showPlacementSetup && (
              <Tabs.Tab
                selected={workTab === 'placement'}
                fontSize={0.9}
                onClick={() => setWorkTab('placement')}
              >
                {getPlacementTabLabel()}
              </Tabs.Tab>
            )}
            <Tabs.Tab
              selected={workTab === 'session'}
              fontSize={0.9}
              onClick={() => setWorkTab('session')}
            >
              {getSessionTabLabel()}
            </Tabs.Tab>
          </Tabs>

          {workTab === 'params' && (
            <Section mt={1}>
              {!data.has_inline_fields && (
                <Box color="label">{getParamEmptyLabel()}</Box>
              )}

              {!!data.has_inline_fields && !groupNames.length && (
                <Box color="label">Поля временно недоступны.</Box>
              )}

              {!!data.has_inline_fields && !!groupNames.length && (
                <Flex wrap mx={-0.5}>
                  {groupNames.map((groupName) => (
                    <Flex.Item
                      key={groupName}
                      basis="48%"
                      grow
                      m={0.5}
                      style={{ minWidth: '20rem' }}
                    >
                      <Section title={groupName}>
                        <LabeledList>
                          {(groupedFields[groupName] || []).map((field) => (
                            <FieldEditor
                              key={field.id}
                              field={field}
                              act={act}
                            />
                          ))}
                        </LabeledList>
                      </Section>
                    </Flex.Item>
                  ))}
                </Flex>
              )}
            </Section>
          )}

          {workTab === 'assets' && (
            <>
              {!hasAssets && (
                <Section mt={1}>
                  <Box color="label">{getAssetEmptyLabel()}</Box>
                </Section>
              )}

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

          {workTab === 'placement' && (
            <>
              {!showPlacementSetup && (
                <Section mt={1}>
                  <Box color="label">{getPlacementEmptyLabel()}</Box>
                </Section>
              )}

              {showPlacementSetup && (
                <PlacementSetupSection data={data} act={act} />
              )}
            </>
          )}

          {workTab === 'session' && (
            <Box mt={1}>
              <WorkspaceSessionSection data={data} act={act} />
            </Box>
          )}
        </>
      )}
    </Section>
  );
};

const HistoryPage = (props: {
  readonly data: BackendData;
  readonly act: (action: string, payload?: Record<string, unknown>) => void;
  readonly onOpenWork: () => void;
}) => {
  const { data, act, onOpenWork } = props;
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
      {!data.history_entries?.length && (
        <>
          <Box color="label">{getHistoryEmptyLabel()}</Box>
          {!!data.has_generator && (
            <Button compact icon="sliders-h" mt={1} onClick={onOpenWork}>
              {getSecondaryButtonLabel('back')}
            </Button>
          )}
        </>
      )}

      {!!data.history_entries?.length && (
        <>
          <CompactStatusRow items={getHistorySummaryItems(data, latestEntry)} />

          {data.history_entries.map((entry, index) => (
            <Collapsible
              key={`${entry.time}_${entry.generator_id}_${index}`}
              title={getHistoryEntryTitle(entry)}
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
  readonly pageIndex: number;
  readonly setPageIndex: (pageIndex: number) => void;
}) => {
  const { data, pageIndex, setPageIndex } = props;
  const workflow = getWorkflowState(data);

  return (
    <Section fill scrollable fitted title="World Edit">
      <Box bold>{getCurrentGeneratorLabel(data.current_generator_name)}</Box>
      <Box color={workflow.color || 'label'} mt={0.25}>
        {getSidebarSummaryText(data)}
      </Box>
      <Box color="label" mt={0.25}>
        {getHistorySummaryLabel(data)}
      </Box>

      <Tabs vertical fluid mt={1}>
        {PAGES.map((page, index) => (
          <Tabs.Tab
            key={page.title}
            selected={index === pageIndex}
            icon={page.icon}
            fontSize={0.9}
            onClick={() => setPageIndex(index)}
          >
            {page.title}
          </Tabs.Tab>
        ))}
      </Tabs>
    </Section>
  );
};

export const WorldEditPanel = () => {
  const { data, act } = useBackend<BackendData>();
  const [pageIndex, setPageIndex] = useState(0);

  const currentPage = PAGES[pageIndex]?.id || PAGES[0].id;
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

  return (
    <Window title="World Edit Panel" width={950} height={620}>
      <Window.Content>
        <Stack fill>
          <Stack.Item width={8}>
            <Sidebar
              data={data}
              pageIndex={pageIndex}
              setPageIndex={setPageIndex}
            />
          </Stack.Item>

          <Stack.Item grow basis={0} ml={1}>
            {currentPage === 'browse' && (
              <GeneratorCatalogPage
                data={data}
                act={act}
                onOpenWork={() => setPageIndex(1)}
              />
            )}

            {currentPage === 'work' && (
              <WorkspacePage
                data={data}
                act={act}
                groupedFields={groupedFields}
                groupNames={groupNames}
                showBlueprintExport={showBlueprintExport}
                showBlueprintLibrary={showBlueprintLibrary}
                showPlacementSetup={showPlacementSetup}
                onOpenBrowse={() => setPageIndex(0)}
                onOpenHistory={() => setPageIndex(2)}
              />
            )}

            {currentPage === 'history' && (
              <HistoryPage
                data={data}
                act={act}
                onOpenWork={() => setPageIndex(1)}
              />
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
