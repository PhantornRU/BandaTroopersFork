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
  confirm_before_apply: boolean;
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

type SurfaceTone = 'default' | 'good' | 'average' | 'bad';

type ChoiceOption = {
  value: string;
  displayText: string;
};

type WorkspaceTabKey = 'editor' | 'history';

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
  context?: string;
  previewAction?: ToolbarAction;
  applyAction?: ToolbarAction;
  placementAction?: ToolbarAction;
  collectorAction?: ToolbarAction;
  undoAction?: ToolbarAction;
};

type ActFn = (action: string, payload?: Record<string, unknown>) => void;

const EMPTY_LABEL = 'Не задано';
const NONE_LABEL = 'Не выбрано';
const OFF_LABEL = 'Выключено';
const WORKSPACE_GUTTER = 0.35;
const SMALL_CHOICE_DROPDOWN_THRESHOLD = 5;

const TOOL_TITLE_LABELS: Record<string, string> = {
  blueprint_stamp: 'Штамп по шаблону',
  outpost_radius: 'Форпост',
  destruction_pack: 'Разрушение зоны',
};

const TOOL_PICKER_LABELS: Record<string, string> = {
  blueprint_stamp: 'Шаблон',
  outpost_radius: 'Форпост',
  destruction_pack: 'Разрушение',
};

const FIELD_LABELS: Record<string, string> = {
  family: 'Профиль форпоста',
  radius: 'Радиус',
  barricade_path: 'Материал баррикад',
  place_sentries: 'Турели у проходов',
  sentry_path: 'Турель',
  faction: 'IFF',
  turned_on: 'Включить сразу',
  shuffle_enabled: 'Перемешать объекты',
  scatter_enabled: 'Разбросать по области',
  scatter_steps: 'Шаги разброса',
  persistent_fire_enabled: 'Постоянный огонь',
  persistent_fire_density: 'Плотность огня',
  blast_enabled: 'Взрыв',
  blast_power: 'Мощность взрыва',
  blast_falloff: 'Спад взрыва',
  damage_profile: 'Структурный урон',
  max_atoms: 'Лимит объектов',
  stamp_spacing: 'Шаг между шаблонами',
  shape_line_length: 'Длина линии',
  shape_line_spacing: 'Шаг линии',
  shape_rect_width: 'Ширина',
  shape_rect_height: 'Высота',
  shape_radius: 'Радиус',
  shape_thickness: 'Толщина',
  shape_sector_angle: 'Угол',
  shape_radius_x: 'Радиус X',
  shape_radius_y: 'Радиус Y',
  shape_triangle_size: 'Размер',
  shape_points_text: 'Точки',
  shape_polygon_filled: 'Заполнить',
  shape_close_loop: 'Замкнуть контур',
  shape_brush_radius: 'Радиус кисти',
  shape_scatter_radius: 'Радиус разброса',
  shape_scatter_count: 'Количество',
  shape_scatter_seed: 'Сид',
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

const PLACEMENT_SHAPE_LABELS: Record<string, string> = {
  point: 'Точка',
  line: 'Линия',
  rectangle: 'Рамка',
  filled_rectangle: 'Заполненный прямоугольник',
  circle: 'Круг',
  ring: 'Кольцо',
  ellipse: 'Эллипс',
  diamond: 'Ромб',
  triangle: 'Треугольник',
  sector: 'Сектор',
  polygon: 'Многоугольник',
  polyline: 'Ломаная',
  custom_mask: 'Своя маска',
  brush_path: 'Кисть по пути',
  scatter_cluster: 'Кластер разброса',
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

const isBlankDisplayValue = (value?: unknown) => {
  const text = `${value ?? ''}`.trim().toLowerCase();
  return !text || text === '0' || text === 'none' || text === 'n/a';
};

const getDisplayText = (value?: unknown, fallback = EMPTY_LABEL) =>
  isBlankDisplayValue(value) ? fallback : `${value}`;

const renderMetaValue = (value?: unknown): ReactNode => {
  if (value === null || typeof value === 'undefined') {
    return EMPTY_LABEL;
  }

  if (typeof value === 'boolean') {
    return value ? 'Да' : 'Нет';
  }

  if (Array.isArray(value)) {
    const items = value
      .map((entry) => renderMetaValue(entry))
      .filter((entry) => `${entry}` !== EMPTY_LABEL);
    return items.length ? items.join(', ') : EMPTY_LABEL;
  }

  if (typeof value === 'object') {
    const pairs = Object.entries(value as Record<string, unknown>)
      .map(([key, entryValue]) => `${key}: ${renderMetaValue(entryValue)}`)
      .filter((entry) => !entry.endsWith(`: ${EMPTY_LABEL}`));
    return pairs.length ? pairs.join(', ') : EMPTY_LABEL;
  }

  if (typeof value === 'number') {
    return Number.isFinite(value) ? `${value}` : EMPTY_LABEL;
  }

  return getDisplayText(value, EMPTY_LABEL);
};

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

const getTranslatedShapeLabel = (value?: unknown) => {
  const key = `${value ?? ''}`.trim().toLowerCase();
  return PLACEMENT_SHAPE_LABELS[key] || getDisplayText(value, NONE_LABEL);
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
  if (kind === 'shape') {
    return getTranslatedShapeLabel(option.value || option.label);
  }
  return getDisplayText(option.label, fallback);
};

const getGeneratorDisplayName = (data: BackendData, generatorId?: string) => {
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

const getCurrentToolTitle = (data: BackendData) =>
  TOOL_TITLE_LABELS[data.current_generator_id || ''] ||
  getDisplayText(data.current_generator_name, 'World Edit');

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

const getPlacementStateLine = (data: BackendData) => {
  if (!data.click_mode_active) {
    return 'Размещение выключено.';
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

  return 'Размещение активно.';
};

const getPlacementNextClickText = (data: BackendData) => {
  if (!data.click_mode_active) {
    switch (data.placement_interaction_kind) {
      case 'collector':
        return 'Клик: начать форму.';
      case 'anchor_pair':
        return 'Клик: первая точка.';
      case 'param_only':
        return 'Клик: опорная клетка.';
      default:
        return 'Клик: точка размещения.';
    }
  }

  if (data.placement_interaction_kind === 'collector') {
    return data.can_finish_placement_collection
      ? 'Сбор готов. Можно добавить точку.'
      : 'Клик: добавить точку.';
  }

  if (data.placement_interaction_kind === 'anchor_pair') {
    return data.placement_anchor
      ? 'Клик: вторая точка.'
      : 'Клик: первая точка.';
  }

  if (data.placement_interaction_kind === 'param_only') {
    return 'Клик: опорная клетка.';
  }

  return 'Клик: разместить.';
};

const getPlacementContextItems = (data: BackendData) => {
  const items: string[] = [];
  if (data.placement_shape_supported) {
    items.push(`Форма: ${getTranslatedShapeLabel(data.placement_shape)}`);
  }
  if (data.placement_supported) {
    items.push(`Клик: ${getTranslatedPlacementMode(data.placement_mode)}`);
  }
  if (data.placement_supports_direction) {
    items.push(`Напр.: ${getTranslatedDirection(data.placement_dir)}`);
  }
  return items;
};

const getToolbarContextLine = (data: BackendData) => {
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
      `Радиус: ${getDisplayText(getField(data.ui_fields, 'radius')?.value)}`,
    );
  } else if (data.current_generator_id === 'destruction_pack') {
    const activeModes = [
      getField(data.ui_fields, 'shuffle_enabled')?.value ? 'перемешивание' : '',
      getField(data.ui_fields, 'scatter_enabled')?.value ? 'разброс' : '',
      getField(data.ui_fields, 'persistent_fire_enabled')?.value ? 'огонь' : '',
      getField(data.ui_fields, 'blast_enabled')?.value ? 'взрыв' : '',
      `${getField(data.ui_fields, 'damage_profile')?.value || 'none'}` !==
      'none'
        ? 'урон'
        : '',
    ].filter(Boolean);
    items.push(
      `Радиус: ${getDisplayText(getField(data.ui_fields, 'radius')?.value)}`,
    );
    items.push(
      activeModes.length
        ? `Режим: ${activeModes.join(', ')}`
        : 'Режим не задан',
    );
  }

  items.push(...getPlacementContextItems(data));
  return items.slice(0, 3).join(' · ');
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

const WorkspaceGrid = (props: {
  readonly children: ReactNode;
  readonly gutter?: number;
}) => {
  const { children, gutter = WORKSPACE_GUTTER } = props;
  return (
    <Flex wrap mx={-gutter}>
      {children}
    </Flex>
  );
};

const WorkspacePane = (props: {
  readonly children: ReactNode;
  readonly basis: string;
  readonly minWidth: string;
  readonly gutter?: number;
  readonly grow?: boolean;
}) => {
  const {
    children,
    basis,
    minWidth,
    gutter = WORKSPACE_GUTTER,
    grow = true,
  } = props;
  return (
    <Flex.Item basis={basis} grow={grow} m={gutter} style={{ minWidth }}>
      {children}
    </Flex.Item>
  );
};

const ChoiceStrip = (props: {
  readonly options: ChoiceOption[];
  readonly selected: string;
  readonly disabled?: boolean;
  readonly onSelected: (value: string) => void;
}) => {
  const { options, selected, disabled, onSelected } = props;
  const basis = options.length <= 2 ? '45%' : '22%';

  if (!options.length) {
    return <Box color="label">Нет вариантов.</Box>;
  }

  return (
    <Flex wrap mx={-0.15}>
      {options.map((option) => {
        const isSelected = `${option.value}` === `${selected}`;
        return (
          <Flex.Item key={option.value} grow basis={basis} m={0.15}>
            <Button
              compact
              fluid
              selected={isSelected}
              disabled={disabled}
              onClick={() => onSelected(option.value)}
            >
              {option.displayText}
            </Button>
          </Flex.Item>
        );
      })}
    </Flex>
  );
};

const SmartSelect = (props: {
  readonly options: ChoiceOption[];
  readonly selected: string;
  readonly displayText: string;
  readonly disabled?: boolean;
  readonly placeholder?: string;
  readonly forceDropdown?: boolean;
  readonly onSelected: (value: string) => void;
}) => {
  const {
    options,
    selected,
    displayText,
    disabled,
    placeholder,
    forceDropdown,
    onSelected,
  } = props;

  if (forceDropdown || options.length >= SMALL_CHOICE_DROPDOWN_THRESHOLD) {
    return (
      <Dropdown
        width="100%"
        options={options}
        selected={selected}
        displayText={displayText}
        disabled={disabled || !options.length}
        placeholder={placeholder}
        onSelected={(value) => onSelected(`${value}`)}
      />
    );
  }

  return (
    <ChoiceStrip
      options={options}
      selected={selected}
      disabled={disabled || !options.length}
      onSelected={onSelected}
    />
  );
};

const getSurfaceColors = (tone?: SurfaceTone) => ({
  borderColor:
    tone === 'good'
      ? '#4c9f39'
      : tone === 'average'
        ? '#b98c35'
        : tone === 'bad'
          ? '#8f3c34'
          : '#466b96',
  background:
    tone === 'good'
      ? 'rgba(76, 159, 57, 0.12)'
      : tone === 'average'
        ? 'rgba(185, 140, 53, 0.12)'
        : tone === 'bad'
          ? 'rgba(143, 60, 52, 0.16)'
          : 'rgba(70, 107, 150, 0.12)',
});

const SurfaceCard = (props: {
  readonly title: string;
  readonly subtitle?: ReactNode;
  readonly tone?: SurfaceTone;
  readonly actions?: ReactNode;
  readonly children: ReactNode;
  readonly mt?: number;
}) => {
  const { title, subtitle, tone, actions, children, mt } = props;
  const { borderColor, background } = getSurfaceColors(tone);

  return (
    <Box
      mt={mt}
      p={0.65}
      style={{
        border: `1px solid ${borderColor}`,
        background,
        borderRadius: '4px',
      }}
    >
      <Flex align="center" wrap mb={0.4}>
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
      <SmartSelect
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
  readonly tone?: SurfaceTone;
  readonly subtitle?: ReactNode;
  readonly showHints?: boolean;
  readonly actions?: ReactNode;
  readonly mt?: number;
}) => {
  const { title, fields, act, tone, subtitle, showHints, actions, mt } = props;
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
      mt={mt ?? 0.6}
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

const FieldBlock = (props: {
  readonly title: string;
  readonly fields: UiField[];
  readonly act: ActFn;
  readonly tone?: SurfaceTone;
  readonly subtitle?: ReactNode;
  readonly showHints?: boolean;
}) => {
  const { title, fields, act, tone, subtitle, showHints } = props;
  const visibleFields = (fields || []).filter(
    (field) => field.visible !== false,
  );
  if (!visibleFields.length) {
    return null;
  }

  const { borderColor } = getSurfaceColors(tone);

  return (
    <Box
      p={0.5}
      style={{
        borderTop: `2px solid ${borderColor}`,
        background: 'rgba(70, 107, 150, 0.06)',
        borderRadius: '4px',
      }}
    >
      <Box bold>{title}</Box>
      {!!subtitle && (
        <Box color="label" mt={0.1}>
          {subtitle}
        </Box>
      )}
      <Box mt={0.35}>
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
      </Box>
    </Box>
  );
};

const getToolbarState = (data: BackendData): ToolbarState => {
  const title = getCurrentToolTitle(data);

  if (!data.has_generator) {
    return {
      title: 'World Edit',
      state: 'Инструмент не выбран.',
      stateColor: 'label',
    };
  }

  const blueprintState = getBlueprintToolbarState(data);
  const isToolBlocked = isBlueprintToolBlocked(data);
  const hasPlacementControls =
    data.placement_supported ||
    data.placement_shape_supported ||
    data.placement_supports_direction;
  const hasVisiblePreview = !!data.preview_valid;
  const canPreview =
    data.can_run_preview && !data.click_mode_active && !isToolBlocked;
  const canApply =
    data.can_run_apply && !data.click_mode_active && !isToolBlocked;
  const canStartPlacement =
    data.can_start_placement_mode && !data.click_mode_active && !isToolBlocked;

  const previewAction: ToolbarAction | undefined =
    data.current_generator_supports_preview
      ? {
          label: 'Предпросмотр',
          action: 'run_preview',
          color: 'average',
          disabled: !canPreview,
        }
      : undefined;

  if (previewAction) {
    previewAction.action = hasVisiblePreview ? 'clear_preview' : 'run_preview';
    previewAction.color = hasVisiblePreview ? 'good' : 'average';
    previewAction.disabled = hasVisiblePreview ? false : !canPreview;
  }

  const applyAction: ToolbarAction = {
    label: 'Применить',
    action: 'run_apply',
    color: 'good',
    disabled: !canApply,
  };

  const effectiveApplyAction = hasPlacementControls ? undefined : applyAction;

  const startPlacementAction: ToolbarAction | undefined = hasPlacementControls
    ? {
        label: 'Начать размещение',
        action: 'start_placement_mode',
        color: 'average',
        disabled: !canStartPlacement,
      }
    : undefined;

  if (startPlacementAction) {
    startPlacementAction.label = 'Разместить на карте';
    startPlacementAction.color = 'good';
  }

  const stopPlacementAction: ToolbarAction = {
    label: 'Остановить размещение',
    action: 'stop_click_mode',
    color: 'average',
    disabled: !data.can_stop_click_mode,
  };

  const collectorAction: ToolbarAction | undefined =
    data.click_mode_active && data.placement_interaction_kind === 'collector'
      ? {
          label: 'Завершить сбор',
          action: 'finish_placement_collection',
          color: 'good',
          disabled: !data.can_finish_placement_collection,
        }
      : undefined;

  const undoAction: ToolbarAction = {
    label: 'Откатить последнее',
    action: 'undo_last_operation',
    color: 'average',
    disabled: !data.can_undo_last_operation,
  };

  const baseState: ToolbarState = {
    title,
    state: 'Готово.',
    stateColor: 'label',
    context: getToolbarContextLine(data),
    previewAction,
    applyAction: effectiveApplyAction,
    placementAction: data.click_mode_active
      ? stopPlacementAction
      : startPlacementAction,
    collectorAction,
    undoAction,
  };

  if (data.last_ui_error) {
    return {
      ...baseState,
      state: data.last_ui_error,
      stateColor: 'bad',
    };
  }

  if (blueprintState) {
    return {
      ...baseState,
      state: blueprintState.state,
      stateColor: blueprintState.color,
    };
  }

  if (data.click_mode_active) {
    return {
      ...baseState,
      state: getPlacementStateLine(data),
      stateColor:
        data.placement_interaction_kind === 'collector' &&
        data.can_finish_placement_collection
          ? 'good'
          : 'average',
    };
  }

  if (data.requires_preview_before_apply && !data.preview_valid) {
    return {
      ...baseState,
      state: data.preview_message || 'Нет предпросмотра.',
      stateColor: data.preview_message ? 'bad' : 'label',
    };
  }

  if (data.preview_valid) {
    return {
      ...baseState,
      state: 'Предпросмотр готов.',
      stateColor: 'good',
    };
  }

  if (data.current_generator_supports_preview) {
    return {
      ...baseState,
      state: 'Нет предпросмотра.',
      stateColor: 'label',
    };
  }

  return {
    ...baseState,
    state: 'Можно применить.',
    stateColor: 'good',
  };
};

const hasPlacementControlsForTool = (data: BackendData) =>
  data.placement_supported ||
  data.placement_shape_supported ||
  data.placement_supports_direction;

const PlacementControlsBody = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
  readonly extraFields?: UiField[];
}) => {
  const { data, act, extraFields } = props;
  const hasPlacementControls =
    data.placement_supported ||
    data.placement_shape_supported ||
    data.placement_supports_direction;
  const visibleExtraFields = (extraFields || []).filter(
    (field) => field.visible !== false,
  );

  if (!hasPlacementControls && !visibleExtraFields.length) {
    return null;
  }

  const collectorTarget = Math.max(
    data.placement_collector_max_points || 0,
    data.placement_collector_min_points || 0,
    1,
  );
  const visibleShapeFields = (data.placement_shape_fields || []).filter(
    (field) => field.visible !== false,
  );

  return (
    <>
      <Box color={data.click_mode_active ? 'white' : 'label'}>
        {getPlacementNextClickText(data)}
      </Box>

      <Box mt={0.45}>
        <LabeledList>
          {!!data.placement_shape_supported && (
            <LabeledList.Item label="Форма">
              <SmartSelect
                options={(data.placement_shape_options || []).map((option) => ({
                  value: option.value,
                  displayText: getTranslatedShapeLabel(
                    option.value || option.label,
                  ),
                }))}
                selected={data.placement_shape}
                displayText={getPlacementOptionLabel(
                  data.placement_shape_options,
                  data.placement_shape,
                  'shape',
                )}
                forceDropdown={
                  (data.placement_shape_options || []).length >=
                  SMALL_CHOICE_DROPDOWN_THRESHOLD
                }
                onSelected={(value) =>
                  act('set_placement_shape', {
                    shape: value,
                  })
                }
              />
            </LabeledList.Item>
          )}

          {!!data.placement_supported && (
            <LabeledList.Item label="После клика">
              <SmartSelect
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

          {!!data.placement_supports_direction && (
            <LabeledList.Item label="Направление">
              <SmartSelect
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

          {visibleExtraFields.map((field) => (
            <FieldEditor key={field.id} field={field} act={act} />
          ))}
        </LabeledList>
      </Box>

      {!!visibleShapeFields.length && (
        <Collapsible title="Параметры формы" mt={0.6} open={false}>
          <LabeledList>
            {visibleShapeFields.map((field) => (
              <FieldEditor key={field.id} field={field} act={act} />
            ))}
          </LabeledList>
        </Collapsible>
      )}

      {data.placement_interaction_kind === 'collector' &&
        (data.click_mode_active ||
          data.placement_collector_point_count > 0) && (
          <Box mt={0.6}>
            <Box
              bold
              color={data.can_finish_placement_collection ? 'good' : 'average'}
              mb={0.25}
            >
              Сбор формы
            </Box>
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
            <Box color="label" mt={0.35}>
              Минимум: {Math.max(data.placement_collector_min_points || 1, 1)}
            </Box>
          </Box>
        )}
    </>
  );
};

const PlacementControlsCard = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
  readonly title?: string;
  readonly extraFields?: UiField[];
}) => {
  const { data, act, title, extraFields } = props;

  if (
    !hasPlacementControlsForTool(data) &&
    !(extraFields || []).some((field) => field.visible !== false)
  ) {
    return null;
  }

  return (
    <SurfaceCard
      title={title || 'Размещение на карте'}
      subtitle={
        data.click_mode_active ? getPlacementStateLine(data) : undefined
      }
      tone={
        data.click_mode_active && data.can_finish_placement_collection
          ? 'good'
          : data.click_mode_active
            ? 'average'
            : 'default'
      }
      mt={0.6}
    >
      <PlacementControlsBody data={data} act={act} extraFields={extraFields} />
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
  const blueprintPlacementFields = getFieldsById(data.ui_fields, [
    'stamp_spacing',
  ]);
  const isSelectedBlueprintActive =
    !!selectedBlueprint && selectedBlueprint.id === data.active_blueprint_id;
  const totalBlueprints = data.blueprint_entries?.length || 0;

  return (
    <WorkspaceGrid>
      <WorkspacePane basis="42%" minWidth="19rem">
        <SurfaceCard
          title="Библиотека"
          subtitle={`${filteredBlueprints.length} из ${totalBlueprints}`}
          actions={
            <Button compact onClick={() => act('list_blueprints')}>
              Обновить
            </Button>
          }
        >
          <Input
            value={searchQuery}
            placeholder="Поиск"
            onChange={(_, value) => setSearchQuery(value)}
          />

          {!data.blueprint_entries?.length && (
            <Box color="label" mt={0.7}>
              Нет шаблонов.
            </Box>
          )}

          {!!data.blueprint_entries?.length && !filteredBlueprints.length && (
            <Box color="label" mt={0.7}>
              Ничего не найдено.
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
                    p={0.45}
                    mb={0.3}
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
                      border: isActive
                        ? '1px solid #4c9f39'
                        : isSelected
                          ? '1px solid #7696c5'
                          : '1px solid rgba(70, 107, 150, 0.55)',
                      borderLeft: isActive
                        ? '3px solid #4c9f39'
                        : isSelected
                          ? '3px solid #7696c5'
                          : '3px solid transparent',
                      background: isActive
                        ? 'rgba(76, 159, 57, 0.16)'
                        : isSelected
                          ? 'rgba(118, 150, 197, 0.14)'
                          : 'rgba(70, 107, 150, 0.10)',
                      borderRadius: '4px',
                      cursor: 'pointer',
                    }}
                  >
                    <Box
                      bold
                      color={isActive ? 'good' : isSelected ? 'white' : 'white'}
                    >
                      {getDisplayText(blueprint.name, 'Шаблон без имени')}
                    </Box>
                    <Box color={blueprint.valid ? 'label' : 'bad'} mt={0.2}>
                      {blueprint.valid
                        ? `${getPositiveCountText(blueprint.entry_count, '0')} объектов · радиус ${getPositiveCountText(blueprint.radius, '0')}`
                        : 'Шаблон недоступен'}
                    </Box>
                    {(!blueprint.valid || isActive) && (
                      <Box
                        color={
                          !blueprint.valid
                            ? 'bad'
                            : isActive
                              ? 'good'
                              : 'average'
                        }
                        mt={0.2}
                      >
                        {!blueprint.valid
                          ? 'Недоступен'
                          : isActive
                            ? 'Выбран'
                            : ''}
                      </Box>
                    )}
                  </Box>
                );
              })}
            </Box>
          )}
        </SurfaceCard>
      </WorkspacePane>

      <WorkspacePane basis="56%" minWidth="23rem">
        <SurfaceCard
          title="Рабочий шаблон"
          subtitle={
            selectedBlueprint
              ? !selectedBlueprint.valid
                ? 'Недоступен'
                : isSelectedBlueprintActive
                  ? 'Выбран'
                  : 'Подготовлен'
              : undefined
          }
          tone={
            !selectedBlueprint
              ? 'default'
              : !selectedBlueprint.valid
                ? 'bad'
                : isSelectedBlueprintActive
                  ? 'good'
                  : 'average'
          }
        >
          {!selectedBlueprint && (
            <Box color="label">Выберите шаблон слева.</Box>
          )}

          {!!selectedBlueprint && (
            <>
              <Box bold style={{ fontSize: '1.15em' }}>
                {getDisplayText(selectedBlueprint.name, 'Шаблон без имени')}
              </Box>
              {!selectedBlueprint.valid && (
                <NoticeBox danger>
                  {selectedBlueprint.error || 'Шаблон недоступен.'}
                </NoticeBox>
              )}
              <CompactStatusRow
                basis="48%"
                items={[
                  {
                    label: 'Объектов',
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
              {selectedBlueprint.valid &&
                isSelectedBlueprintActive &&
                hasPlacementControlsForTool(data) && (
                  <Box
                    mt={0.7}
                    pt={0.55}
                    style={{ borderTop: '1px solid rgba(70, 107, 150, 0.45)' }}
                  >
                    <Box bold mb={0.35}>
                      Размещение
                    </Box>
                    <PlacementControlsBody
                      data={data}
                      act={act}
                      extraFields={blueprintPlacementFields}
                    />
                  </Box>
                )}
            </>
          )}
        </SurfaceCard>
      </WorkspacePane>
    </WorkspaceGrid>
  );
};

const OutpostRadiusWorkspace = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
}) => {
  const { data, act } = props;
  const familyField = getField(data.ui_fields, 'family');
  const radiusField = getField(data.ui_fields, 'radius');
  const sentryToggleField = getField(data.ui_fields, 'place_sentries');
  const sentryFields = getFieldsByGroup(data.ui_fields, 'Sentries');
  const layoutFields = getFieldsByGroup(data.ui_fields, 'Layout');

  const previewMeta = data.preview_meta || {};
  const familySummary = getFieldOptionLabel(familyField);
  const summaryTiles: SummaryTile[] = [
    {
      label: 'Профиль',
      value: familySummary,
    },
    {
      label: 'Радиус',
      value: getDisplayText(radiusField?.value, EMPTY_LABEL),
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
    <WorkspaceGrid>
      <WorkspacePane basis="50%" minWidth="22rem">
        <FieldListCard
          title="Профиль и радиус"
          fields={layoutFields}
          act={act}
          mt={0}
        />
        <FieldListCard title="Оборона" fields={sentryFields} act={act} />
      </WorkspacePane>

      <WorkspacePane basis="48%" minWidth="22rem">
        <SurfaceCard
          title="План форпоста"
          subtitle={
            data.preview_valid ? 'Предпросмотр готов' : 'Без предпросмотра'
          }
          tone={data.preview_valid ? 'good' : 'default'}
          actions={
            data.can_save_blueprint_from_plan ? (
              <Button compact onClick={() => act('save_blueprint')}>
                Сохранить как шаблон
              </Button>
            ) : undefined
          }
        >
          <CompactStatusRow basis="48%" items={summaryTiles} />
          {hasPlacementControlsForTool(data) && (
            <Box mt={0.7}>
              <Box bold mb={0.35}>
                Размещение
              </Box>
              <PlacementControlsBody data={data} act={act} />
            </Box>
          )}
        </SurfaceCard>
      </WorkspacePane>
    </WorkspaceGrid>
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
  const destructiveEnabled = blastEnabled || damageProfile !== 'none';
  const dangerEnabled = destructiveEnabled || fireEnabled;

  return (
    <>
      <SurfaceCard title="Безопасная зона" subtitle="Без взрыва и урона">
        <WorkspaceGrid>
          <WorkspacePane basis="56%" minWidth="19rem">
            <FieldBlock title="Зона" fields={areaFields} act={act} />
          </WorkspacePane>
          <WorkspacePane basis="42%" minWidth="19rem">
            <FieldBlock
              title="Перемещение"
              fields={safeMovementFields}
              act={act}
            />
          </WorkspacePane>
        </WorkspaceGrid>
      </SurfaceCard>

      <Collapsible
        title={dangerEnabled ? 'Опасные режимы включены' : 'Опасные режимы'}
        mt={0.6}
        open={dangerEnabled}
      >
        <SurfaceCard
          title="Опасное воздействие"
          tone={
            destructiveEnabled ? 'bad' : fireEnabled ? 'average' : 'default'
          }
        >
          {destructiveEnabled ? (
            <NoticeBox danger>Взрыв и урон ограничивают откат.</NoticeBox>
          ) : (
            <Box color="label">Взрыв и структурный урон выключены.</Box>
          )}

          <WorkspaceGrid>
            <WorkspacePane basis="34%" minWidth="18rem">
              <FieldBlock
                title="Огонь"
                fields={fireFields}
                act={act}
                tone={fireEnabled ? 'average' : 'default'}
              />
            </WorkspacePane>
            <WorkspacePane basis="31%" minWidth="18rem">
              <FieldBlock
                title="Взрыв"
                subtitle={blastEnabled ? 'Откат ограничен' : undefined}
                fields={blastFields}
                act={act}
                tone={blastEnabled ? 'bad' : 'default'}
              />
            </WorkspacePane>
            <WorkspacePane basis="31%" minWidth="18rem">
              <FieldBlock
                title="Структурный урон"
                subtitle={
                  damageProfile !== 'none' ? 'Откат ограничен' : undefined
                }
                fields={damageFields}
                act={act}
                tone={damageProfile !== 'none' ? 'bad' : 'default'}
              />
            </WorkspacePane>
          </WorkspaceGrid>
        </SurfaceCard>
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
    <WorkspaceGrid>
      {groupNames.map((groupName) => (
        <WorkspacePane key={groupName} basis="48%" minWidth="20rem">
          <FieldListCard
            title={groupName}
            fields={groupedFields[groupName] || []}
            act={act}
          />
        </WorkspacePane>
      ))}
    </WorkspaceGrid>
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
      {!hasPrimaryContent && <Box color="label">Нет настроек.</Box>}

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

const HistoryWorkspace = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
}) => {
  const { data, act } = props;

  return (
    <SurfaceCard
      title="Журнал"
      actions={
        <Flex wrap mx={-0.2}>
          <Flex.Item m={0.2}>
            <Button
              compact
              color="average"
              disabled={!data.can_cleanup_last_owned_effects}
              onClick={() => act('cleanup_last_owned_effects')}
            >
              Очистить эффекты
            </Button>
          </Flex.Item>
          <Flex.Item m={0.2}>
            <Button
              compact
              color="average"
              onClick={() => act('clear_history')}
            >
              Очистить журнал
            </Button>
          </Flex.Item>
        </Flex>
      }
    >
      {!data.last_changeset && !data.history_entries?.length && (
        <Box color="label">Журнал пуст.</Box>
      )}

      {!!data.last_changeset && (
        <Box
          p={0.45}
          style={{
            border: '1px solid rgba(70, 107, 150, 0.45)',
            background: 'rgba(70, 107, 150, 0.08)',
            borderRadius: '4px',
          }}
        >
          <Box bold mb={0.3}>
            Последняя операция
          </Box>
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
                label: 'Откат',
                value: getTranslatedUndoPolicy(data.last_changeset.undo_policy),
              },
              {
                label: 'Статус',
                value: getTranslatedUndoStatus(data.last_changeset.undo_status),
              },
              {
                label: 'Время',
                value: getDisplayText(
                  data.last_changeset.created_at,
                  EMPTY_LABEL,
                ),
              },
            ]}
          />
          <Box color="label" mt={0.25}>
            Создано: {data.last_changeset.created_entries} · Перемещено:{' '}
            {data.last_changeset.moved_entries} · Эффекты:{' '}
            {data.last_changeset.owned_effect_entries}
          </Box>
        </Box>
      )}

      {!!data.history_entries?.length && (
        <Box mt={0.55}>
          {data.history_entries.map((entry, index) => (
            <Collapsible
              key={`${entry.time}_${entry.generator_id}_${index}`}
              title={`${entry.time} · ${getGeneratorDisplayName(
                data,
                entry.generator_id,
              )} · ${getHistoryResultText(entry.result)}`}
              color={toneForHistoryResult(entry.result)}
              open={false}
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
                    label: 'Откат',
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
              <Box color="label" mt={0.45}>
                {entry.message || 'Подробности не сохранены.'}
              </Box>
            </Collapsible>
          ))}
        </Box>
      )}
    </SurfaceCard>
  );
};

const ServiceDetailsSection = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
}) => {
  const { data, act } = props;
  const activeBlueprint = getSelectedBlueprint(data);
  const placementDiagnostics = [
    data.click_mode_active
      ? {
          label: 'Состояние',
          value: getPlacementStateLine(data),
        }
      : null,
    data.placement_interaction_kind === 'collector' &&
    (data.click_mode_active || data.placement_collector_point_count > 0)
      ? {
          label: 'Собрано точек',
          value: `${data.placement_collector_point_count || 0}/${Math.max(
            data.placement_collector_max_points || 0,
            data.placement_collector_min_points || 0,
            1,
          )}`,
        }
      : null,
    data.placement_anchor
      ? {
          label: 'Первая точка',
          value: getDisplayText(data.placement_anchor, EMPTY_LABEL),
        }
      : null,
  ].filter(Boolean) as SummaryTile[];

  return (
    <Collapsible title="Служебно" mt={0.75} open={false}>
      <SurfaceCard title="Сеанс">
        <CompactStatusRow
          basis="32%"
          items={[
            {
              label: 'Предпросмотр',
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
              label: 'Шаблон',
              value:
                activeBlueprint?.name ||
                (data.active_blueprint_id ? 'Выбран' : 'Не выбран'),
            },
          ]}
        />

        {!!data.preview_message && !data.preview_valid && (
          <Box color="average" mt={0.45}>
            {data.preview_message}
          </Box>
        )}

        {!!data.last_apply_message && !data.last_apply_success && (
          <Box color="average" mt={0.45}>
            {data.last_apply_message}
          </Box>
        )}

        {!!placementDiagnostics.length && (
          <Box mt={0.45}>
            <CompactStatusRow basis="48%" items={placementDiagnostics} />
          </Box>
        )}
      </SurfaceCard>

      {!!data.preview_meta && !!Object.keys(data.preview_meta).length && (
        <Collapsible title="Данные предпросмотра" mt={0.55} open={false}>
          <CompactStatusRow
            basis="32%"
            items={Object.entries(data.preview_meta).map(([key, value]) => ({
              label: key,
              value: renderMetaValue(value),
            }))}
          />
        </Collapsible>
      )}

      {!!data.runtime_status?.length && (
        <Collapsible title="Состояние выполнения" mt={0.55} open={false}>
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
        </Collapsible>
      )}

      <SurfaceCard title="Действия" mt={0.55}>
        <Flex wrap mx={-0.25}>
          <Flex.Item m={0.25}>
            <Button
              compact
              disabled={!data.can_refresh_ui}
              onClick={() => act('refresh_ui')}
            >
              Обновить данные
            </Button>
          </Flex.Item>
          <Flex.Item m={0.25}>
            <Button compact onClick={() => act('reset_generator')}>
              Сбросить настройки
            </Button>
          </Flex.Item>
        </Flex>
      </SurfaceCard>
    </Collapsible>
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
        selected={action.action === 'clear_preview'}
        onClick={() => act(action.action, action.payload)}
      >
        {action.label}
      </Button>
    );
  };

  return (
    <Box
      mb={0.8}
      px={0.65}
      py={0.45}
      style={{
        position: 'sticky',
        top: '0',
        zIndex: '5',
        background: 'rgba(17, 20, 24, 0.97)',
        border: '1px solid rgba(70, 107, 150, 0.75)',
        borderRadius: '4px',
      }}
    >
      <Flex align="center" wrap mx={-0.25}>
        <Flex.Item grow basis="17rem" m={0.25}>
          <Box bold>{toolbar.title}</Box>
          {!!toolbar.context && (
            <Box color="label" mt={0.1}>
              {toolbar.context}
            </Box>
          )}
        </Flex.Item>

        <Flex.Item basis="12rem" m={0.25}>
          <Box
            color={toolbar.stateColor || 'label'}
            px={0.5}
            py={0.25}
            style={{
              border: '1px solid rgba(70, 107, 150, 0.45)',
              background: 'rgba(70, 107, 150, 0.10)',
              borderRadius: '4px',
            }}
          >
            {toolbar.state}
          </Box>
        </Flex.Item>

        <Flex.Item m={0.25}>
          <Flex align="center" wrap mx={-0.15}>
            {!!toolbar.previewAction && (
              <Flex.Item m={0.15}>
                {renderAction(toolbar.previewAction)}
              </Flex.Item>
            )}
            {!!toolbar.applyAction && (
              <Flex.Item m={0.15}>
                {renderAction(toolbar.applyAction)}
              </Flex.Item>
            )}
            {!!toolbar.placementAction && (
              <Flex.Item m={0.15} ml={0.35}>
                {renderAction(toolbar.placementAction, data.click_mode_active)}
              </Flex.Item>
            )}
            {!!toolbar.collectorAction && (
              <Flex.Item m={0.15}>
                {renderAction(toolbar.collectorAction, true)}
              </Flex.Item>
            )}
            {!!toolbar.undoAction && (
              <Flex.Item m={0.15} ml={0.35}>
                {renderAction(toolbar.undoAction, true)}
              </Flex.Item>
            )}
            {data.has_generator && (
              <Flex.Item m={0.15} ml={0.35}>
                <Button.Checkbox
                  checked={data.confirm_before_apply}
                  onClick={() =>
                    act('set_confirm_before_apply', {
                      enabled: !data.confirm_before_apply,
                    })
                  }
                >
                  Спрашивать перед применением
                </Button.Checkbox>
              </Flex.Item>
            )}
          </Flex>
        </Flex.Item>
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
      <Box p={0.25}>
        {(data.categories || []).map((category) => {
          const primaryGenerator = category.generators?.[0];
          const tabLabel =
            TOOL_PICKER_LABELS[primaryGenerator?.id || ''] ||
            primaryGenerator?.name_ru ||
            category.category;
          const isActive = category.category === activeCategory;
          return (
            <Box
              key={category.category}
              px={0.5}
              py={0.4}
              mb={0.15}
              onClick={() => onSelectCategory(category)}
              style={{
                borderLeft: isActive
                  ? '3px solid #4c9f39'
                  : '3px solid transparent',
                borderBottom: '1px solid rgba(70, 107, 150, 0.22)',
                background: isActive
                  ? 'rgba(76, 159, 57, 0.14)'
                  : 'rgba(70, 107, 150, 0.03)',
                borderRadius: '2px',
                cursor: 'pointer',
              }}
            >
              <Box bold color={isActive ? 'good' : 'white'}>
                {tabLabel}
              </Box>
              {isActive && (
                <Box color="label" mt={0.1} style={{ fontSize: '0.82em' }}>
                  Активен
                </Box>
              )}
            </Box>
          );
        })}
      </Box>
    </Section>
  );
};

const WorkspacePage = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
  readonly groupedFields: Record<string, UiField[]>;
  readonly groupNames: string[];
  readonly showPlacementSetup: boolean;
  readonly workspaceTab: WorkspaceTabKey;
  readonly onSelectWorkspaceTab: (tab: WorkspaceTabKey) => void;
}) => {
  const {
    data,
    act,
    groupedFields,
    groupNames,
    showPlacementSetup,
    workspaceTab,
    onSelectWorkspaceTab,
  } = props;

  return (
    <Section fill scrollable>
      <EditorToolbar data={data} act={act} />

      {!data.has_generator && (
        <SurfaceCard title="Выберите инструмент">
          <Box color="label">Шаблон, форпост, разрушение.</Box>
        </SurfaceCard>
      )}

      {!!data.has_generator && (
        <>
          <Tabs mb={0.55}>
            <Tabs.Tab
              selected={workspaceTab === 'editor'}
              onClick={() => onSelectWorkspaceTab('editor')}
            >
              Редактор
            </Tabs.Tab>
            <Tabs.Tab
              selected={workspaceTab === 'history'}
              onClick={() => onSelectWorkspaceTab('history')}
            >
              Журнал
            </Tabs.Tab>
          </Tabs>

          {workspaceTab === 'editor' ? (
            <>
              <ToolWorkspace
                data={data}
                act={act}
                groupedFields={groupedFields}
                groupNames={groupNames}
                showPlacementSetup={showPlacementSetup}
              />
              <ServiceDetailsSection data={data} act={act} />
            </>
          ) : (
            <HistoryWorkspace data={data} act={act} />
          )}
        </>
      )}
    </Section>
  );
};

export const WorldEditPanel = () => {
  const { data, act } = useBackend<BackendData>();
  const [activeCategory, setActiveCategory] = useState('');
  const [workspaceTab, setWorkspaceTab] = useState<WorkspaceTabKey>('editor');
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

  useEffect(() => {
    if (!data.has_generator && workspaceTab !== 'editor') {
      setWorkspaceTab('editor');
    }
  }, [data.has_generator, workspaceTab]);

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
    <Window title="World Edit Panel" width={1040} height={680}>
      <Window.Content>
        <Stack fill>
          <Stack.Item width={11}>
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
              workspaceTab={workspaceTab}
              onSelectWorkspaceTab={setWorkspaceTab}
            />
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
