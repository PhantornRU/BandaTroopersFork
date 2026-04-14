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

type ToolbarAction = {
  label: string;
  action: string;
  color?: 'good' | 'average' | 'bad';
  disabled?: boolean;
  payload?: Record<string, unknown>;
};

type ToolbarState = {
  title: string;
  state: string;
  stateColor?: string;
  primary?: ToolbarAction;
  secondary?: ToolbarAction;
  modeAction?: ToolbarAction;
};

type ActFn = (action: string, payload?: Record<string, unknown>) => void;

const EMPTY_LABEL = 'Не задано';
const NONE_LABEL = 'Не выбрано';
const OFF_LABEL = 'Выключено';

const FIELD_LABELS: Record<string, string> = {
  family: 'Семейство',
  radius: 'Радиус',
  barricade_path: 'Тип баррикад',
  place_sentries: 'Турели по проходам',
  sentry_path: 'Тип турели',
  faction: 'IFF-фракция',
  turned_on: 'Включать сразу',
  shuffle_enabled: 'Перемешать объекты',
  scatter_enabled: 'Разбросать по области',
  scatter_steps: 'Шаги разброса',
  persistent_fire_enabled: 'Постоянный огонь',
  persistent_fire_density: 'Плотность огня',
  blast_enabled: 'Взрыв',
  blast_power: 'Мощность взрыва',
  blast_falloff: 'Спад взрыва',
  damage_profile: 'Профиль урона',
  max_atoms: 'Лимит объектов',
};

const PLACEMENT_MODE_LABELS: Record<string, string> = {
  single: 'Один раз',
  repeat: 'Повторять',
};

const DIRECTION_LABELS: Record<string, string> = {
  north: 'Север',
  east: 'Восток',
  south: 'Юг',
  west: 'Запад',
};

const OUTPOST_FAMILY_LABELS: Record<string, string> = {
  standard: 'Стандартный',
  fortified: 'Укрепленный',
  light: 'Легкий',
};

const DAMAGE_PROFILE_LABELS: Record<string, string> = {
  none: 'Без урона',
  ruin: 'Руины',
  collapse: 'Обрушение',
};

const BARRICADE_LABELS: Record<string, string> = {
  'Metal Barricade': 'Металлическая',
  'Metal Barricade - Wired': 'Металлическая, с проволокой',
  Sandbags: 'Мешки с песком',
  'Plasteel Barricade': 'Пласталевая',
  'Plasteel Barricade - Wired': 'Пласталевая, с проволокой',
  'Wooden Barricade': 'Деревянная',
};

const SENTRY_LABELS: Record<string, string> = {
  'USCM Sentry': 'USCM',
  'USCM Sentry - DMR': 'USCM DMR',
  'USCM Sentry - Shotgun': 'USCM дробовик',
  'USCM Sentry - Mini': 'USCM mini',
  'UPP Sentry': 'UPP',
  'W-Y Sentry': 'W-Y',
};

const UNDO_POLICY_LABELS: Record<string, string> = {
  full: 'Полный',
  partial: 'Частичный',
  none: 'Без отката',
};

const UNDO_STATUS_LABELS: Record<string, string> = {
  available: 'Доступен',
  cleanup_available: 'Доступна очистка',
  not_available: 'Недоступен',
  full: 'Полный',
  partial: 'Частичный',
  none: 'Нет',
};

const boolText = (value: boolean, yes = 'Да', no = 'Нет') => (value ? yes : no);

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

const getSafeFieldList = (fields: UiField[], ids: string[]) =>
  getFieldsById(fields, ids).filter(
    (field) => field.visible !== false && !field.disabled,
  );

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

const toneForHistoryResult = (result?: string) => {
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

const getTranslatedDirection = (value?: unknown) => {
  const key = `${value ?? ''}`.trim().toLowerCase();
  return DIRECTION_LABELS[key] || getDisplayText(value, NONE_LABEL);
};

const getTranslatedPlacementMode = (value?: unknown) => {
  const key = `${value ?? ''}`.trim().toLowerCase();
  return PLACEMENT_MODE_LABELS[key] || getDisplayText(value, NONE_LABEL);
};

const getTranslatedUndoPolicy = (value?: string) => {
  const key = `${value ?? ''}`.trim().toLowerCase();
  return UNDO_POLICY_LABELS[key] || getDisplayText(value, EMPTY_LABEL);
};

const getTranslatedUndoStatus = (value?: string) => {
  const key = `${value ?? ''}`.trim().toLowerCase();
  return UNDO_STATUS_LABELS[key] || getDisplayText(value, EMPTY_LABEL);
};

const getTranslatedFieldLabel = (field: UiField) =>
  FIELD_LABELS[field.id] || field.label;

const translateOptionLabel = (
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

const getFieldOptionLabel = (field?: UiField, fallback = NONE_LABEL) => {
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

const getPlacementOptionLabel = (
  options: PlacementOption[] | undefined,
  value: unknown,
  kind: 'shape' | 'mode' | 'direction',
  fallback = NONE_LABEL,
) => {
  const option = (options || []).find(
    (entry) => `${entry.value}` === `${value}`,
  );
  if (!option) {
    return fallback;
  }

  if (kind === 'mode') {
    return getTranslatedPlacementMode(option.value || option.label);
  }
  if (kind === 'direction') {
    return getTranslatedDirection(option.value || option.label);
  }
  return getDisplayText(option.label, fallback);
};

const getInteractionLabel = (kind?: string) => {
  switch ((kind || '').toLowerCase()) {
    case 'collector':
      return 'Сбор точек';
    case 'anchor_pair':
      return 'Две точки';
    case 'param_only':
      return 'Опора по клику';
    default:
      return 'Один клик';
  }
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

const getHistoryResultText = (value?: string) => {
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

const getSelectedBlueprint = (data: BackendData) =>
  data.blueprint_entries?.find(
    (entry) => entry.id === data.active_blueprint_id,
  );

const isBlueprintToolBlocked = (data: BackendData) => {
  if (data.current_generator_id !== 'blueprint_stamp') {
    return false;
  }

  const activeBlueprint = getSelectedBlueprint(data);
  return (
    !data.active_blueprint_id || (!!activeBlueprint && !activeBlueprint.valid)
  );
};

const getBlueprintToolbarState = (data: BackendData) => {
  if (data.current_generator_id !== 'blueprint_stamp') {
    return null;
  }

  const activeBlueprint = getSelectedBlueprint(data);
  if (!data.active_blueprint_id) {
    return { state: 'Выберите blueprint в библиотеке.', color: 'label' };
  }
  if (activeBlueprint && !activeBlueprint.valid) {
    return {
      state:
        'Выбранный blueprint нельзя использовать, пока его данные не будут исправлены.',
      color: 'bad',
    };
  }
  return null;
};

const getPlacementStateLine = (data: BackendData) => {
  if (!data.click_mode_active) {
    return 'Режим размещения выключен.';
  }

  if (data.placement_interaction_kind === 'collector') {
    if (data.can_finish_placement_collection) {
      return `Форма собрана: ${data.placement_collector_point_count || 0} точек.`;
    }
    return `Сбор формы: ${data.placement_collector_point_count || 0}/${Math.max(
      data.placement_collector_min_points || 0,
      1,
    )}.`;
  }

  if (data.placement_interaction_kind === 'anchor_pair') {
    return data.placement_anchor
      ? 'Ждет вторую точку формы.'
      : 'Ждет первую точку формы.';
  }

  if (data.placement_interaction_kind === 'param_only') {
    return 'Ждет опорный клик для формы.';
  }

  return 'Размещение активно.';
};

const getPlacementNextClickText = (data: BackendData) => {
  if (!data.click_mode_active) {
    switch (data.placement_interaction_kind) {
      case 'collector':
        return 'После запуска первый клик задаст опорную точку, следующие клики будут добавлять вершины формы.';
      case 'anchor_pair':
        return 'После запуска первый клик задаст первую точку, второй завершит форму.';
      case 'param_only':
        return 'После запуска клик по карте возьмет выбранный тайл как опору.';
      default:
        return 'После запуска клик по карте сразу соберет footprint на выбранном тайле.';
    }
  }

  if (data.placement_interaction_kind === 'collector') {
    return data.can_finish_placement_collection
      ? 'Форма готова. Можно завершать сбор или добавить еще точки.'
      : 'Следующий клик добавит точку в форму.';
  }

  if (data.placement_interaction_kind === 'anchor_pair') {
    return data.placement_anchor
      ? 'Следующий клик завершит форму по второй точке.'
      : 'Следующий клик поставит первую точку формы.';
  }

  if (data.placement_interaction_kind === 'param_only') {
    return 'Следующий клик возьмет выбранный тайл как опору текущей формы.';
  }

  return 'Следующий клик сразу создаст footprint и попросит подтверждение.';
};

const getRepeatModeText = (data: BackendData) =>
  data.placement_mode === 'repeat'
    ? 'Режим повторения оставит инструмент активным после каждого подтверждения.'
    : 'После подтверждения инструмент завершит текущий цикл.';

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

const SurfaceCard = (props: {
  readonly title: string;
  readonly subtitle?: ReactNode;
  readonly tone?: 'default' | 'good' | 'average' | 'bad';
  readonly actions?: ReactNode;
  readonly children: ReactNode;
  readonly mt?: number;
}) => {
  const { title, subtitle, tone, actions, children, mt } = props;
  const borderColor =
    tone === 'good'
      ? '#4c9f39'
      : tone === 'average'
        ? '#b98c35'
        : tone === 'bad'
          ? '#8f3c34'
          : '#466b96';
  const background =
    tone === 'good'
      ? 'rgba(76, 159, 57, 0.12)'
      : tone === 'average'
        ? 'rgba(185, 140, 53, 0.12)'
        : tone === 'bad'
          ? 'rgba(143, 60, 52, 0.16)'
          : 'rgba(70, 107, 150, 0.12)';

  return (
    <Box
      mt={mt}
      p={0.8}
      style={{
        border: `1px solid ${borderColor}`,
        background,
        borderRadius: '4px',
      }}
    >
      <Flex align="center" wrap mb={0.5}>
        <Flex.Item grow basis="14rem">
          <Box bold>{title}</Box>
          {!!subtitle && (
            <Box color="label" mt={0.1}>
              {subtitle}
            </Box>
          )}
        </Flex.Item>
        {!!actions && <Flex.Item>{actions}</Flex.Item>}
      </Flex>
      {children}
    </Box>
  );
};

const FieldEditor = (props: {
  readonly field: UiField;
  readonly act: ActFn;
  readonly showHints?: boolean;
}) => {
  const { field, act, showHints } = props;
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
        displayText: translateOptionLabel(field.id, option.label, option.value),
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
    <LabeledList.Item
      label={
        field.required
          ? `${getTranslatedFieldLabel(field)} *`
          : getTranslatedFieldLabel(field)
      }
    >
      {control}
      {!!showHints && !!field.validate_hint && (
        <Box color="average" mt={0.35}>
          {field.validate_hint}
        </Box>
      )}
    </LabeledList.Item>
  );
};

const FieldListCard = (props: {
  readonly title: string;
  readonly fields: UiField[];
  readonly act: ActFn;
  readonly tone?: 'default' | 'good' | 'average' | 'bad';
  readonly subtitle?: ReactNode;
  readonly showHints?: boolean;
  readonly actions?: ReactNode;
}) => {
  const { title, fields, act, tone, subtitle, showHints, actions } = props;
  const visibleFields = (fields || []).filter(
    (field) => field.visible !== false,
  );
  if (!visibleFields.length) {
    return null;
  }

  return (
    <SurfaceCard
      title={title}
      subtitle={subtitle}
      tone={tone}
      actions={actions}
      mt={0.6}
    >
      <LabeledList>
        {visibleFields.map((field) => (
          <FieldEditor
            key={field.id}
            field={field}
            act={act}
            showHints={showHints}
          />
        ))}
      </LabeledList>
    </SurfaceCard>
  );
};

const getToolbarState = (data: BackendData): ToolbarState => {
  const title = data.current_generator_name || 'World Edit';

  if (!data.has_generator) {
    return {
      title: 'World Edit',
      state: 'Выберите инструмент слева.',
      stateColor: 'label',
    };
  }

  const blueprintState = getBlueprintToolbarState(data);
  const canPreview =
    data.can_run_preview &&
    !data.click_mode_active &&
    !isBlueprintToolBlocked(data);
  const canApply =
    data.can_run_apply &&
    !data.click_mode_active &&
    !isBlueprintToolBlocked(data);
  const canStartPlacement =
    data.can_start_placement_mode &&
    !data.click_mode_active &&
    !isBlueprintToolBlocked(data);

  const previewAction: ToolbarAction = {
    label: data.preview_valid ? 'Обновить preview' : 'Предпросмотр',
    action: 'run_preview',
    color: 'average',
    disabled: !canPreview,
  };

  const applyAction: ToolbarAction = {
    label: 'Применить',
    action: 'run_apply',
    color: 'good',
    disabled: !canApply,
  };

  const startPlacementAction: ToolbarAction = {
    label: 'Режим размещения',
    action: 'start_placement_mode',
    color: 'average',
    disabled: !canStartPlacement,
  };

  const stopPlacementAction: ToolbarAction = {
    label: 'Остановить размещение',
    action: 'stop_click_mode',
    color: 'average',
    disabled: !data.can_stop_click_mode,
  };

  const finishCollectorAction: ToolbarAction = {
    label: 'Завершить сбор',
    action: 'finish_placement_collection',
    color: 'good',
    disabled: !data.can_finish_placement_collection,
  };

  if (data.last_ui_error) {
    return {
      title,
      state: data.last_ui_error,
      stateColor: 'bad',
      primary:
        data.requires_preview_before_apply ||
        data.current_generator_supports_preview
          ? previewAction
          : applyAction,
      modeAction:
        data.placement_supported ||
        data.placement_shape_supported ||
        data.placement_supports_direction
          ? startPlacementAction
          : undefined,
    };
  }

  if (blueprintState) {
    return {
      title,
      state: blueprintState.state,
      stateColor: blueprintState.color,
      primary: previewAction,
      modeAction:
        data.placement_supported ||
        data.placement_shape_supported ||
        data.placement_supports_direction
          ? startPlacementAction
          : undefined,
    };
  }

  if (data.click_mode_active) {
    if (
      data.placement_interaction_kind === 'collector' &&
      data.can_finish_placement_collection
    ) {
      return {
        title,
        state: getPlacementStateLine(data),
        stateColor: 'good',
        primary: finishCollectorAction,
        modeAction: stopPlacementAction,
      };
    }

    return {
      title,
      state: getPlacementStateLine(data),
      stateColor: 'average',
      primary: stopPlacementAction,
    };
  }

  if (data.requires_preview_before_apply && !data.preview_valid) {
    return {
      title,
      state:
        data.preview_message ||
        'Предпросмотр еще не собран для текущей конфигурации.',
      stateColor: data.preview_message ? 'bad' : 'average',
      primary: previewAction,
      modeAction:
        data.placement_supported ||
        data.placement_shape_supported ||
        data.placement_supports_direction
          ? startPlacementAction
          : undefined,
    };
  }

  if (data.preview_valid) {
    return {
      title,
      state: data.preview_message || 'Предпросмотр готов к применению.',
      stateColor: 'good',
      primary: applyAction,
      secondary: data.current_generator_supports_preview
        ? previewAction
        : undefined,
      modeAction:
        data.placement_supported ||
        data.placement_shape_supported ||
        data.placement_supports_direction
          ? startPlacementAction
          : undefined,
    };
  }

  if (data.current_generator_supports_preview) {
    return {
      title,
      state: 'Настройте параметры и соберите предпросмотр.',
      stateColor: 'label',
      primary: previewAction,
      modeAction:
        data.placement_supported ||
        data.placement_shape_supported ||
        data.placement_supports_direction
          ? startPlacementAction
          : undefined,
    };
  }

  return {
    title,
    state: 'Конфигурация готова к применению.',
    stateColor: 'good',
    primary: applyAction,
    modeAction:
      data.placement_supported ||
      data.placement_shape_supported ||
      data.placement_supports_direction
        ? startPlacementAction
        : undefined,
  };
};

const PlacementControlsCard = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
  readonly title?: string;
}) => {
  const { data, act, title } = props;
  const hasPlacementControls =
    data.placement_supported ||
    data.placement_shape_supported ||
    data.placement_supports_direction;

  if (!hasPlacementControls) {
    return null;
  }

  const collectorTarget = Math.max(
    data.placement_collector_max_points || 0,
    data.placement_collector_min_points || 0,
    1,
  );

  const placementSummary: SummaryTile[] = [
    {
      label: 'Состояние',
      value: data.click_mode_active ? 'Активен' : OFF_LABEL,
      color: data.click_mode_active ? 'good' : 'label',
    },
    {
      label: 'Ввод',
      value: getInteractionLabel(data.placement_interaction_kind),
    },
  ];

  if (data.placement_supported) {
    placementSummary.push({
      label: 'Режим',
      value: getPlacementOptionLabel(
        data.placement_mode_options,
        data.placement_mode,
        'mode',
      ),
    });
  }

  if (data.placement_shape_supported) {
    placementSummary.push({
      label: 'Форма',
      value: getPlacementOptionLabel(
        data.placement_shape_options,
        data.placement_shape,
        'shape',
      ),
    });
  }

  if (data.placement_supports_direction) {
    placementSummary.push({
      label: 'Направление',
      value: getPlacementOptionLabel(
        data.placement_dir_options,
        data.placement_dir,
        'direction',
      ),
    });
  }

  return (
    <SurfaceCard
      title={title || 'Размещение'}
      subtitle={getPlacementStateLine(data)}
      tone={data.click_mode_active ? 'average' : 'default'}
      mt={0.6}
    >
      <CompactStatusRow items={placementSummary} />

      <Box color="label" mt={0.6}>
        {getPlacementNextClickText(data)}
      </Box>
      <Box color="label" mt={0.2}>
        {getRepeatModeText(data)}
      </Box>

      <Box mt={0.7}>
        <LabeledList>
          {data.placement_shape_supported && (
            <LabeledList.Item label="Форма">
              <Dropdown
                width="100%"
                options={(data.placement_shape_options || []).map((option) => ({
                  value: option.value,
                  displayText: getDisplayText(option.label, NONE_LABEL),
                }))}
                selected={data.placement_shape}
                displayText={getPlacementOptionLabel(
                  data.placement_shape_options,
                  data.placement_shape,
                  'shape',
                )}
                onSelected={(value) =>
                  act('set_placement_shape', {
                    shape: value,
                  })
                }
              />
            </LabeledList.Item>
          )}

          {data.placement_supported && (
            <LabeledList.Item label="Режим">
              <Dropdown
                width="100%"
                options={(data.placement_mode_options || []).map((option) => ({
                  value: option.value,
                  displayText: getTranslatedPlacementMode(
                    option.value || option.label,
                  ),
                }))}
                selected={data.placement_mode}
                displayText={getPlacementOptionLabel(
                  data.placement_mode_options,
                  data.placement_mode,
                  'mode',
                )}
                onSelected={(value) =>
                  act('set_placement_mode', {
                    mode: value,
                  })
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
                  displayText: getTranslatedDirection(
                    option.value || option.label,
                  ),
                }))}
                selected={data.placement_dir}
                displayText={getPlacementOptionLabel(
                  data.placement_dir_options,
                  data.placement_dir,
                  'direction',
                )}
                onSelected={(value) =>
                  act('set_placement_dir', {
                    direction: value,
                  })
                }
              />
            </LabeledList.Item>
          )}
        </LabeledList>
      </Box>

      {!!data.placement_shape_fields?.length && (
        <FieldListCard
          title="Параметры формы"
          fields={data.placement_shape_fields}
          act={act}
        />
      )}

      {data.placement_interaction_kind === 'collector' && (
        <SurfaceCard
          title="Сбор формы"
          subtitle={
            data.can_finish_placement_collection
              ? 'Форма готова к завершению.'
              : 'Добавьте нужное количество точек.'
          }
          tone={data.can_finish_placement_collection ? 'good' : 'average'}
          mt={0.6}
        >
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
                label: 'Минимум',
                value: `${Math.max(data.placement_collector_min_points || 1, 1)}`,
              },
              {
                label: 'Готово',
                value: boolText(data.can_finish_placement_collection),
                color: data.can_finish_placement_collection ? 'good' : 'label',
              },
            ]}
          />
        </SurfaceCard>
      )}
    </SurfaceCard>
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
      setSelectedPresetId('');
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
    data.preset_entries?.find((entry) => entry.id === selectedPresetId) ||
    data.preset_entries?.[0];

  return (
    <SurfaceCard
      title="Пресеты"
      subtitle="Сохраненные наборы параметров для быстрого повторения."
      actions={
        <Button compact onClick={() => act('save_preset')}>
          Сохранить
        </Button>
      }
      mt={0.6}
    >
      {!data.preset_entries?.length && (
        <Box color="label">Сохраненных пресетов пока нет.</Box>
      )}

      {!!data.preset_entries?.length && (
        <>
          <Flex wrap mx={-0.25}>
            {data.preset_entries.map((preset) => {
              const isSelected = preset.id === selectedPreset?.id;
              return (
                <Flex.Item key={preset.id} basis="48%" grow m={0.25}>
                  <Box
                    p={0.55}
                    onClick={() => {
                      setSelectedPresetId(preset.id);
                      act('load_preset', {
                        preset_id: preset.id,
                      });
                    }}
                    style={{
                      border: isSelected
                        ? '1px solid #4c9f39'
                        : '1px solid #466b96',
                      background: isSelected
                        ? 'rgba(76, 159, 57, 0.16)'
                        : 'rgba(70, 107, 150, 0.10)',
                      borderRadius: '4px',
                      cursor: 'pointer',
                    }}
                  >
                    <Box bold color={isSelected ? 'good' : 'white'}>
                      {getDisplayText(preset.name, 'Пресет без имени')}
                    </Box>
                    <Box color="label" mt={0.2}>
                      {preset.params_short ||
                        'Краткое описание появится после сохранения.'}
                    </Box>
                  </Box>
                </Flex.Item>
              );
            })}
          </Flex>

          {!!selectedPreset && (
            <SurfaceCard
              title={getDisplayText(selectedPreset.name, 'Пресет')}
              subtitle={getDisplayText(selectedPreset.created_at, EMPTY_LABEL)}
              mt={0.6}
              actions={
                <Button
                  compact
                  color="average"
                  onClick={() =>
                    act('delete_preset', {
                      preset_id: selectedPreset.id,
                    })
                  }
                >
                  Удалить
                </Button>
              }
            >
              <Box color="label">
                {selectedPreset.params_short ||
                  'Краткое описание параметров не сохранено.'}
              </Box>
            </SurfaceCard>
          )}
        </>
      )}
    </SurfaceCard>
  );
};

const BlueprintExportSection = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
}) => {
  const { data, act } = props;

  return (
    <SurfaceCard
      title="Экспорт в blueprint"
      subtitle={
        data.can_save_blueprint_from_plan
          ? 'Текущий preview можно сохранить как новый blueprint.'
          : 'Экспорт станет доступен после успешного preview форпоста.'
      }
      mt={0.6}
    >
      <Button
        compact
        disabled={!data.can_save_blueprint_from_plan}
        onClick={() => act('save_blueprint')}
      >
        Сохранить preview
      </Button>
    </SurfaceCard>
  );
};

const BlueprintStampWorkspace = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
}) => {
  const { data, act } = props;
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedBlueprintId, setSelectedBlueprintId] = useState('');

  const filteredBlueprints = useMemo(() => {
    const query = searchQuery.trim().toLowerCase();
    if (!query) {
      return data.blueprint_entries || [];
    }

    return (data.blueprint_entries || []).filter((entry) => {
      const haystack = [entry.name, entry.source, entry.created_by, entry.id]
        .join(' ')
        .toLowerCase();
      return haystack.includes(query);
    });
  }, [data.blueprint_entries, searchQuery]);

  useEffect(() => {
    const preferredId =
      data.active_blueprint_id &&
      filteredBlueprints.some((entry) => entry.id === data.active_blueprint_id)
        ? data.active_blueprint_id
        : filteredBlueprints[0]?.id || '';

    if (
      selectedBlueprintId &&
      filteredBlueprints.some((entry) => entry.id === selectedBlueprintId)
    ) {
      return;
    }

    setSelectedBlueprintId(preferredId);
  }, [data.active_blueprint_id, filteredBlueprints, selectedBlueprintId]);

  const selectedBlueprint =
    filteredBlueprints.find((entry) => entry.id === selectedBlueprintId) ||
    data.blueprint_entries?.find(
      (entry) => entry.id === data.active_blueprint_id,
    );

  const nextStepText = !selectedBlueprint
    ? 'Выберите blueprint в библиотеке, чтобы увидеть footprint и запустить placement.'
    : !selectedBlueprint.valid
      ? selectedBlueprint.error ||
        'Этот blueprint нельзя использовать, пока он не будет исправлен.'
      : data.click_mode_active
        ? getPlacementNextClickText(data)
        : data.preview_valid
          ? 'Предпросмотр готов. Следующий шаг — применить stamp или перейти в режим размещения.'
          : 'Следующий шаг — собрать предпросмотр для выбранного blueprint.';

  return (
    <Flex wrap mx={-0.4}>
      <Flex.Item basis="42%" grow m={0.4} style={{ minWidth: '19rem' }}>
        <SurfaceCard
          title="Библиотека blueprint-ов"
          subtitle="Выберите готовый набор построек для stamp."
          actions={
            <Button compact onClick={() => act('list_blueprints')}>
              Обновить
            </Button>
          }
        >
          <Input
            value={searchQuery}
            placeholder="Поиск по имени, источнику или автору"
            onChange={(_, value) => setSearchQuery(value)}
          />

          {!data.blueprint_entries?.length && (
            <Box color="label" mt={0.7}>
              Библиотека пока пуста.
            </Box>
          )}

          {!!data.blueprint_entries?.length && !filteredBlueprints.length && (
            <Box color="label" mt={0.7}>
              По этому запросу ничего не найдено.
            </Box>
          )}

          {!!filteredBlueprints.length && (
            <Box mt={0.7}>
              {filteredBlueprints.map((blueprint) => {
                const isActive = blueprint.id === data.active_blueprint_id;
                const isSelected = blueprint.id === selectedBlueprint?.id;
                return (
                  <Box
                    key={blueprint.id}
                    p={0.55}
                    mb={0.45}
                    onClick={() => {
                      setSelectedBlueprintId(blueprint.id);
                      if (
                        blueprint.valid &&
                        blueprint.id !== data.active_blueprint_id
                      ) {
                        act('load_blueprint', {
                          blueprint_id: blueprint.id,
                        });
                      }
                    }}
                    style={{
                      border: isSelected
                        ? '1px solid #4c9f39'
                        : '1px solid #466b96',
                      background: isSelected
                        ? 'rgba(76, 159, 57, 0.16)'
                        : 'rgba(70, 107, 150, 0.10)',
                      borderRadius: '4px',
                      cursor: 'pointer',
                    }}
                  >
                    <Box bold color={isSelected || isActive ? 'good' : 'white'}>
                      {getDisplayText(blueprint.name, 'Blueprint без имени')}
                    </Box>
                    <Box color={blueprint.valid ? 'label' : 'bad'} mt={0.2}>
                      {blueprint.valid
                        ? `${getPositiveCountText(blueprint.entry_count, '0')} элементов · радиус ${getPositiveCountText(blueprint.radius, '0')}`
                        : 'Содержит ошибки и не может быть применен'}
                    </Box>
                  </Box>
                );
              })}
            </Box>
          )}
        </SurfaceCard>
      </Flex.Item>

      <Flex.Item basis="56%" grow m={0.4} style={{ minWidth: '23rem' }}>
        <SurfaceCard
          title={
            selectedBlueprint
              ? getDisplayText(selectedBlueprint.name, 'Blueprint')
              : 'Blueprint не выбран'
          }
          subtitle={
            selectedBlueprint
              ? selectedBlueprint.valid
                ? selectedBlueprint.active
                  ? 'Активный blueprint для этой сессии.'
                  : 'Готов к предпросмотру и размещению.'
                : 'Требует исправления перед использованием.'
              : 'Выберите blueprint слева.'
          }
          tone={
            !selectedBlueprint
              ? 'default'
              : !selectedBlueprint.valid
                ? 'bad'
                : selectedBlueprint.active
                  ? 'good'
                  : 'default'
          }
        >
          {!selectedBlueprint && (
            <Box color="label">
              Библиотека слева определяет, какой stamp будет использован в этом
              сеансе.
            </Box>
          )}

          {!!selectedBlueprint && (
            <>
              {!selectedBlueprint.valid && (
                <NoticeBox danger>
                  {selectedBlueprint.error || 'Выбранный blueprint невалиден.'}
                </NoticeBox>
              )}
              <CompactStatusRow
                basis="48%"
                items={[
                  {
                    label: 'Элементов',
                    value: getPositiveCountText(
                      selectedBlueprint.entry_count,
                      '0',
                    ),
                  },
                  {
                    label: 'Радиус',
                    value: getPositiveCountText(selectedBlueprint.radius, '0'),
                  },
                  {
                    label: 'Источник',
                    value: getDisplayText(
                      selectedBlueprint.source,
                      EMPTY_LABEL,
                    ),
                    color: 'label',
                  },
                  {
                    label: 'Автор',
                    value: getDisplayText(
                      selectedBlueprint.created_by,
                      EMPTY_LABEL,
                    ),
                    color: 'label',
                  },
                ]}
              />
            </>
          )}
        </SurfaceCard>

        <SurfaceCard
          title="Следующий шаг"
          subtitle={
            data.preview_valid ? 'Preview готов.' : 'Preview еще не собран.'
          }
          tone={data.preview_valid ? 'good' : 'average'}
          mt={0.6}
        >
          <Box>{nextStepText}</Box>
        </SurfaceCard>

        <PlacementControlsCard
          data={data}
          act={act}
          title="Как разместить blueprint"
        />
      </Flex.Item>
    </Flex>
  );
};

const OutpostRadiusWorkspace = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
}) => {
  const { data, act } = props;
  const familyField = getField(data.ui_fields, 'family');
  const radiusField = getField(data.ui_fields, 'radius');
  const barricadeField = getField(data.ui_fields, 'barricade_path');
  const sentryToggleField = getField(data.ui_fields, 'place_sentries');
  const sentryFields = getFieldsByGroup(data.ui_fields, 'Sentries');
  const layoutFields = getFieldsByGroup(data.ui_fields, 'Layout');
  const barricadeFields = getFieldsByGroup(data.ui_fields, 'Barricades');

  const previewMeta = data.preview_meta || {};
  const familySummary =
    (previewMeta.family_label as string) || getFieldOptionLabel(familyField);
  const summaryTiles: SummaryTile[] = [
    {
      label: 'Семейство',
      value: familySummary,
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
  ];

  if (data.preview_valid) {
    summaryTiles.push(
      {
        label: 'Проходы',
        value: getDisplayText(previewMeta.opening_count, '0'),
      },
      {
        label: 'Построек',
        value: `${getDisplayText(previewMeta.barricade_count, '0')} баррикад / ${getDisplayText(previewMeta.sentry_count, '0')} турелей`,
      },
    );
  }

  return (
    <Flex wrap mx={-0.4}>
      <Flex.Item basis="50%" grow m={0.4} style={{ minWidth: '22rem' }}>
        <FieldListCard
          title="Конфигурация форпоста"
          subtitle="Определите семейство, радиус и тип периметра."
          fields={layoutFields}
          act={act}
        />
        <FieldListCard
          title="Периметр"
          subtitle="Выберите основной тип баррикад для кольца."
          fields={barricadeFields}
          act={act}
        />
        <FieldListCard
          title="Оборона"
          subtitle="Настройте внутренние турели только если они действительно нужны."
          fields={sentryFields}
          act={act}
        />
      </Flex.Item>

      <Flex.Item basis="48%" grow m={0.4} style={{ minWidth: '22rem' }}>
        <SurfaceCard
          title="Что будет построено"
          subtitle={
            data.preview_valid
              ? 'Сводка по текущему preview.'
              : 'Точный состав станет виден после preview.'
          }
          tone={data.preview_valid ? 'good' : 'default'}
        >
          <CompactStatusRow basis="48%" items={summaryTiles} />
          {!!previewMeta.family_description && (
            <Box color="label" mt={0.6}>
              {`${previewMeta.family_description}`}
            </Box>
          )}
        </SurfaceCard>

        <PlacementControlsCard data={data} act={act} title="Развертывание" />

        {!!data.can_manage_presets && (
          <PresetLibrarySection data={data} act={act} />
        )}

        <BlueprintExportSection data={data} act={act} />
      </Flex.Item>
    </Flex>
  );
};

const DestructionPackWorkspace = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
}) => {
  const { data, act } = props;
  const areaFields = getFieldsByGroup(data.ui_fields, 'Area');
  const safeMovementFields = [
    ...getFieldsById(data.ui_fields, ['shuffle_enabled', 'scatter_enabled']),
    ...getSafeFieldList(data.ui_fields, ['scatter_steps', 'max_atoms']),
  ];
  const fireFields = [
    ...getFieldsById(data.ui_fields, ['persistent_fire_enabled']),
    ...getFieldsById(data.ui_fields, ['persistent_fire_density']),
  ];
  const blastFields = [
    ...getFieldsById(data.ui_fields, ['blast_enabled']),
    ...getFieldsById(data.ui_fields, ['blast_power', 'blast_falloff']),
  ];
  const damageFields = getFieldsById(data.ui_fields, ['damage_profile']);

  const blastEnabled = !!getField(data.ui_fields, 'blast_enabled')?.value;
  const damageProfile = `${getField(data.ui_fields, 'damage_profile')?.value || 'none'}`;
  const fireEnabled = !!getField(data.ui_fields, 'persistent_fire_enabled')
    ?.value;

  return (
    <>
      <SurfaceCard
        title="Безопасное перемещение"
        subtitle="Сначала задайте область и режимы, которые можно частично откатить."
        tone="good"
      >
        <Flex wrap mx={-0.35}>
          <Flex.Item basis="48%" grow m={0.35} style={{ minWidth: '19rem' }}>
            <FieldListCard
              title="Область"
              subtitle="Какая зона попадет в операцию."
              fields={areaFields}
              act={act}
            />
          </Flex.Item>
          <Flex.Item basis="48%" grow m={0.35} style={{ minWidth: '19rem' }}>
            <FieldListCard
              title="Перемещение и лимиты"
              subtitle="Shuffle и scatter остаются основным безопасным сценарием."
              fields={safeMovementFields}
              act={act}
            />
          </Flex.Item>
        </Flex>
      </SurfaceCard>

      {(blastEnabled || damageProfile !== 'none') && (
        <Box mt={0.6}>
          <NoticeBox danger>
            Взрыв и прямой структурный урон отключают полный undo для этой
            операции.
          </NoticeBox>
        </Box>
      )}

      <Flex wrap mx={-0.35}>
        <Flex.Item basis="32%" grow m={0.35} style={{ minWidth: '18rem' }}>
          <FieldListCard
            title="Огонь"
            subtitle={
              fireEnabled
                ? 'Создаст отдельные fire-эффекты; для них доступна очистка.'
                : 'Неактивен.'
            }
            fields={fireFields}
            act={act}
            tone={fireEnabled ? 'average' : 'default'}
          />
        </Flex.Item>
        <Flex.Item basis="32%" grow m={0.35} style={{ minWidth: '18rem' }}>
          <FieldListCard
            title="Взрыв"
            subtitle={
              blastEnabled
                ? 'Явно разрушительный режим без полного undo.'
                : 'Включайте только для намеренного разрушения.'
            }
            fields={blastFields}
            act={act}
            tone={blastEnabled ? 'bad' : 'default'}
          />
        </Flex.Item>
        <Flex.Item basis="32%" grow m={0.35} style={{ minWidth: '18rem' }}>
          <FieldListCard
            title="Структурный урон"
            subtitle={
              damageProfile !== 'none'
                ? 'Нанесет прямой урон выбранной области и ограничит undo.'
                : 'Можно оставить выключенным для безопасного сценария.'
            }
            fields={damageFields}
            act={act}
            tone={damageProfile !== 'none' ? 'bad' : 'default'}
          />
        </Flex.Item>
      </Flex>
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
    <Flex wrap mx={-0.35}>
      {groupNames.map((groupName) => (
        <Flex.Item
          key={groupName}
          basis="48%"
          grow
          m={0.35}
          style={{ minWidth: '20rem' }}
        >
          <FieldListCard
            title={groupName}
            fields={groupedFields[groupName] || []}
            act={act}
          />
        </Flex.Item>
      ))}
    </Flex>
  );
};

const GenericToolWorkspace = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
  readonly groupedFields: Record<string, UiField[]>;
  readonly groupNames: string[];
  readonly showPlacementSetup: boolean;
}) => {
  const { data, act, groupedFields, groupNames, showPlacementSetup } = props;
  const hasPrimaryContent = data.has_inline_fields || showPlacementSetup;

  return (
    <>
      {!hasPrimaryContent && (
        <Box color="label">
          Для этого инструмента нет inline-настроек в текущей фазе.
        </Box>
      )}

      {!!data.has_inline_fields && (
        <GenericFieldGroups
          groupedFields={groupedFields}
          groupNames={groupNames}
          act={act}
        />
      )}

      {showPlacementSetup && <PlacementControlsCard data={data} act={act} />}
    </>
  );
};

const ToolWorkspace = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
  readonly groupedFields: Record<string, UiField[]>;
  readonly groupNames: string[];
  readonly showPlacementSetup: boolean;
}) => {
  const { data, act, groupedFields, groupNames, showPlacementSetup } = props;

  if (data.current_generator_id === 'blueprint_stamp') {
    return <BlueprintStampWorkspace data={data} act={act} />;
  }

  if (data.current_generator_id === 'outpost_radius') {
    return <OutpostRadiusWorkspace data={data} act={act} />;
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
      showPlacementSetup={showPlacementSetup}
    />
  );
};

const HistoryDetailsSection = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
}) => {
  const { data, act } = props;
  const activeBlueprint = getSelectedBlueprint(data);

  return (
    <>
      <Collapsible title="История и откат" mt={0.8}>
        <Flex wrap mx={-0.25}>
          <Flex.Item m={0.25}>
            <Button
              compact
              color="average"
              disabled={!data.can_undo_last_operation}
              onClick={() => act('undo_last_operation')}
            >
              Откатить
            </Button>
          </Flex.Item>
          <Flex.Item m={0.25}>
            <Button
              compact
              color="average"
              disabled={!data.can_cleanup_last_owned_effects}
              onClick={() => act('cleanup_last_owned_effects')}
            >
              Очистить эффекты
            </Button>
          </Flex.Item>
          <Flex.Item m={0.25}>
            <Button
              compact
              color="average"
              onClick={() => act('clear_history')}
            >
              Очистить историю
            </Button>
          </Flex.Item>
        </Flex>

        {!data.last_changeset && (
          <Box color="label" mt={0.6}>
            Откат пока недоступен: в этой сессии еще нет сохраненной операции.
          </Box>
        )}

        {!!data.last_changeset && (
          <SurfaceCard
            title="Последняя операция"
            subtitle={
              data.last_undo_message
                ? data.last_undo_message
                : 'Последняя записанная операция для отката и очистки.'
            }
            mt={0.6}
          >
            <CompactStatusRow
              basis="32%"
              items={[
                {
                  label: 'Инструмент',
                  value: getGeneratorDisplayName(
                    data,
                    data.last_changeset.generator_id,
                  ),
                },
                {
                  label: 'Политика undo',
                  value: getTranslatedUndoPolicy(
                    data.last_changeset.undo_policy,
                  ),
                },
                {
                  label: 'Статус',
                  value: getTranslatedUndoStatus(
                    data.last_changeset.undo_status,
                  ),
                },
              ]}
            />
            <Box color="label" mt={0.5}>
              ID операции:{' '}
              {getDisplayText(data.last_changeset.operation_id, EMPTY_LABEL)}
            </Box>
            <Box color="label" mt={0.25}>
              Создано: {data.last_changeset.created_entries} | Перемещено:{' '}
              {data.last_changeset.moved_entries} | Собственных эффектов:{' '}
              {data.last_changeset.owned_effect_entries}
            </Box>
          </SurfaceCard>
        )}

        {!data.history_entries?.length && (
          <Box color="label" mt={0.6}>
            История операций пока пуста.
          </Box>
        )}

        {!!data.history_entries?.length && (
          <Box mt={0.6}>
            {data.history_entries.map((entry, index) => (
              <Collapsible
                key={`${entry.time}_${entry.generator_id}_${index}`}
                title={`${entry.time} · ${getGeneratorDisplayName(
                  data,
                  entry.generator_id,
                )} · ${getHistoryResultText(entry.result)}`}
                color={toneForHistoryResult(entry.result)}
                open={index === 0}
              >
                <CompactStatusRow
                  basis="32%"
                  items={[
                    {
                      label: 'Создано',
                      value: `${entry.created_count}`,
                    },
                    {
                      label: 'Удалено',
                      value: `${entry.deleted_count}`,
                    },
                    {
                      label: 'Центр',
                      value: getDisplayText(entry.center_turf, EMPTY_LABEL),
                    },
                    {
                      label: 'Длительность',
                      value: `${entry.duration_ms ?? 0} ms`,
                    },
                    {
                      label: 'Undo',
                      value: entry.undo_policy
                        ? `${getTranslatedUndoPolicy(entry.undo_policy)} / ${getTranslatedUndoStatus(
                            entry.undo_status,
                          )}`
                        : EMPTY_LABEL,
                    },
                    {
                      label: 'Откат / пропуск',
                      value:
                        entry.reverted_count !== undefined ||
                        entry.skipped_count !== undefined
                          ? `${entry.reverted_count ?? 0} / ${entry.skipped_count ?? 0}`
                          : EMPTY_LABEL,
                    },
                  ]}
                />
                <Box color="label" mt={0.5}>
                  {entry.message || 'Подробности операции не сохранены.'}
                </Box>
                <Collapsible title="Технические детали" mt={0.5}>
                  <Box color="label">
                    Параметры: {getDisplayText(entry.params_short, EMPTY_LABEL)}
                  </Box>
                  {!!entry.operation_id && (
                    <Box color="label" mt={0.3}>
                      ID операции: {entry.operation_id}
                    </Box>
                  )}
                  {!!entry.source_operation_id && (
                    <Box color="label" mt={0.3}>
                      Source operation: {entry.source_operation_id}
                    </Box>
                  )}
                </Collapsible>
              </Collapsible>
            ))}
          </Box>
        )}
      </Collapsible>

      <Collapsible title="Технические детали" mt={0.6}>
        <SurfaceCard
          title="Сеанс"
          subtitle="Вся техническая и runtime-информация спрятана сюда по умолчанию."
        >
          <CompactStatusRow
            basis="32%"
            items={[
              {
                label: 'Preview',
                value: data.preview_valid
                  ? 'Готов'
                  : data.preview_success
                    ? 'Есть результат'
                    : 'Нет',
                color: data.preview_valid
                  ? 'good'
                  : data.preview_message
                    ? 'average'
                    : 'label',
              },
              {
                label: 'Применение',
                value: data.can_run_apply ? 'Готово' : 'Не готово',
                color: data.can_run_apply ? 'good' : 'label',
              },
              {
                label: 'Blueprint',
                value:
                  activeBlueprint?.name ||
                  (data.active_blueprint_id ? 'Выбран' : 'Не выбран'),
              },
            ]}
          />

          <Box
            color={
              data.preview_valid
                ? 'good'
                : data.preview_message
                  ? 'average'
                  : 'label'
            }
            mt={0.5}
          >
            {data.preview_message || 'Preview еще не запускался.'}
          </Box>
        </SurfaceCard>

        <Collapsible title="Последнее применение" mt={0.6}>
          <Box color={data.last_apply_success ? 'good' : 'average'}>
            {data.last_apply_message ||
              'Применение в этой сессии еще не запускалось.'}
          </Box>
        </Collapsible>

        {!!data.preview_meta && !!Object.keys(data.preview_meta).length && (
          <Collapsible title="Метаданные preview" mt={0.6}>
            <CompactStatusRow
              basis="32%"
              items={Object.entries(data.preview_meta).map(([key, value]) => ({
                label: key,
                value: renderMetaValue(value),
              }))}
            />
          </Collapsible>
        )}

        {(data.placement_supported ||
          data.placement_shape_supported ||
          data.placement_supports_direction) && (
          <Collapsible title="Диагностика размещения" mt={0.6}>
            <LabeledList>
              <LabeledList.Item label="Тип ввода">
                {getInteractionLabel(data.placement_interaction_kind)}
              </LabeledList.Item>
              <LabeledList.Item label="Первая точка">
                {getDisplayText(data.placement_anchor, EMPTY_LABEL)}
              </LabeledList.Item>
              <LabeledList.Item label="Этап формы">
                {getDisplayText(
                  data.placement_shape_rollout_stage,
                  EMPTY_LABEL,
                )}
              </LabeledList.Item>
              <LabeledList.Item label="Начало сбора">
                {getDisplayText(data.placement_collector_origin, EMPTY_LABEL)}
              </LabeledList.Item>
              <LabeledList.Item label="Точки формы">
                {getDisplayText(
                  data.placement_collector_points_text,
                  EMPTY_LABEL,
                )}
              </LabeledList.Item>
              <LabeledList.Item label="Сводка формы">
                {getDisplayText(data.placement_collector_summary, EMPTY_LABEL)}
              </LabeledList.Item>
            </LabeledList>
          </Collapsible>
        )}

        <Collapsible title="Состояние выполнения" mt={0.6}>
          {!data.runtime_status?.length && (
            <Box color="label">
              Дополнительный runtime status не предоставлен.
            </Box>
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

        <Collapsible title="Текущие параметры" mt={0.6}>
          <Box>{getDisplayText(data.current_params_text, EMPTY_LABEL)}</Box>
        </Collapsible>

        <Collapsible title="Служебные действия" mt={0.6}>
          <Flex wrap mx={-0.25}>
            <Flex.Item m={0.25}>
              <Button
                compact
                disabled={!data.can_refresh_ui}
                onClick={() => act('refresh_ui')}
              >
                Обновить UI
              </Button>
            </Flex.Item>
            <Flex.Item m={0.25}>
              <Button compact onClick={() => act('reset_generator')}>
                Сбросить инструмент
              </Button>
            </Flex.Item>
          </Flex>
        </Collapsible>
      </Collapsible>
    </>
  );
};

const EditorToolbar = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
}) => {
  const { data, act } = props;
  const toolbar = getToolbarState(data);

  const renderAction = (action?: ToolbarAction, compact = false) => {
    if (!action) {
      return null;
    }

    return (
      <Button
        compact={compact}
        color={action.color}
        disabled={action.disabled}
        onClick={() => act(action.action, action.payload)}
      >
        {action.label}
      </Button>
    );
  };

  return (
    <Box
      mb={0.8}
      px={0.5}
      py={0.35}
      style={{
        position: 'sticky',
        top: '0',
        zIndex: '5',
        background: 'rgba(18, 20, 22, 0.96)',
        borderBottom: '1px solid #466b96',
      }}
    >
      <Flex align="center" wrap mx={-0.25}>
        <Flex.Item grow basis="18rem" m={0.25}>
          <Box bold>{toolbar.title}</Box>
          <Box color={toolbar.stateColor || 'label'} mt={0.1}>
            {toolbar.state}
          </Box>
        </Flex.Item>

        {!!toolbar.primary && (
          <Flex.Item m={0.25}>{renderAction(toolbar.primary)}</Flex.Item>
        )}
        {!!toolbar.secondary && (
          <Flex.Item m={0.25}>
            {renderAction(toolbar.secondary, true)}
          </Flex.Item>
        )}
        {!!toolbar.modeAction && (
          <Flex.Item m={0.25}>
            {renderAction(toolbar.modeAction, true)}
          </Flex.Item>
        )}
        {!!data.has_generator && (
          <Flex.Item m={0.25}>
            <Button
              compact
              color="average"
              disabled={!data.can_undo_last_operation}
              onClick={() => act('undo_last_operation')}
            >
              Откатить
            </Button>
          </Flex.Item>
        )}
      </Flex>
    </Box>
  );
};

const Sidebar = (props: {
  readonly data: BackendData;
  readonly activeCategory?: string;
  readonly onSelectCategory: (category: GeneratorCategory) => void;
}) => {
  const { data, activeCategory, onSelectCategory } = props;

  return (
    <Section fill scrollable fitted title="Инструменты">
      <Tabs vertical fluid>
        {(data.categories || []).map((category) => {
          const primaryGenerator = category.generators?.[0];
          const tabLabel = primaryGenerator?.name_ru || category.category;
          return (
            <Tabs.Tab
              key={category.category}
              selected={category.category === activeCategory}
              fontSize={0.9}
              onClick={() => onSelectCategory(category)}
            >
              {tabLabel}
            </Tabs.Tab>
          );
        })}
      </Tabs>
    </Section>
  );
};

const WorkspacePage = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
  readonly groupedFields: Record<string, UiField[]>;
  readonly groupNames: string[];
  readonly showPlacementSetup: boolean;
}) => {
  const { data, act, groupedFields, groupNames, showPlacementSetup } = props;

  return (
    <Section fill scrollable>
      <EditorToolbar data={data} act={act} />

      {!data.has_generator && (
        <SurfaceCard
          title="Выберите инструмент"
          subtitle="Панель работает как редактор: сначала выбираем активный инструмент, потом выполняем одну задачу за раз."
        >
          <Box color="label">
            Слева доступны инструменты World Edit. После выбора сверху появится
            единая панель действий, а в рабочей зоне останутся только нужные
            контролы.
          </Box>
        </SurfaceCard>
      )}

      {!!data.has_generator && (
        <>
          <ToolWorkspace
            data={data}
            act={act}
            groupedFields={groupedFields}
            groupNames={groupNames}
            showPlacementSetup={showPlacementSetup}
          />
          <HistoryDetailsSection data={data} act={act} />
        </>
      )}
    </Section>
  );
};

export const WorldEditPanel = () => {
  const { data, act } = useBackend<BackendData>();
  const [activeCategory, setActiveCategory] = useState('');
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
    <Window title="World Edit Panel" width={1000} height={660}>
      <Window.Content>
        <Stack fill>
          <Stack.Item width={9}>
            <Sidebar
              data={data}
              activeCategory={activeCategory}
              onSelectCategory={handleSelectCategory}
            />
          </Stack.Item>

          <Stack.Item grow basis={0} ml={1}>
            <WorkspacePage
              data={data}
              act={act}
              groupedFields={groupedFields}
              groupNames={groupNames}
              showPlacementSetup={showPlacementSetup}
            />
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
