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
  NumberInput,
  Section,
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
  placement_dir_uses_facing: boolean;
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

type PreviewLegendItem = {
  label: string;
  color: string;
};

type SurfaceTone = 'default' | 'good' | 'average' | 'bad';

type ChoiceOption = {
  value: string;
  displayText: string;
};

type ShapeGlyphSpec = {
  glyph: string;
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
const TOOL_TAB_ORDER = [
  'blueprint_stamp',
  'outpost_radius',
  'destruction_pack',
];

const buildOrderedToolTabs = (categories: GeneratorCategory[] = []) => {
  const entryById = new Map<string, GeneratorEntry>();

  for (const category of categories || []) {
    for (const generator of category.generators || []) {
      entryById.set(generator.id, generator);
    }
  }

  const ordered: GeneratorEntry[] = [];
  for (const generatorId of TOOL_TAB_ORDER) {
    const entry = entryById.get(generatorId);
    if (entry) {
      ordered.push(entry);
      entryById.delete(generatorId);
    }
  }

  const remaining = Array.from(entryById.values()).sort((a, b) =>
    `${a.name_ru}`.localeCompare(`${b.name_ru}`),
  );
  ordered.push(...remaining);
  return ordered;
};

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
  layout_variant: 'Вариант',
  opening_width: 'Ширина проходов',
  radius: 'Радиус',
  barricade_path: 'Материал баррикад',
  barricade_pattern: 'Раскладка баррикад',
  place_sentries: 'Турели у проходов',
  guard_mode: 'Схема турелей',
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

const PLACEMENT_SHAPE_GLYPHS: Record<string, ShapeGlyphSpec> = {
  point: { glyph: '•' },
  line: { glyph: '─' },
  rectangle: { glyph: '□' },
  filled_rectangle: { glyph: '■' },
  circle: { glyph: '○' },
  ring: { glyph: '◎' },
  ellipse: { glyph: '⬭' },
  diamond: { glyph: '◇' },
  triangle: { glyph: '△' },
  sector: { glyph: '◔' },
  polygon: { glyph: '⬡' },
  polyline: { glyph: '〰' },
  custom_mask: { glyph: '▦' },
  brush_path: { glyph: '✎' },
  scatter_cluster: { glyph: '✳' },
};

const PLACEMENT_SHAPE_ORDER = Object.keys(PLACEMENT_SHAPE_LABELS);
const CHROME_CONTROL_GROUP_HEIGHT = '4.9rem';

const DEFAULT_PLACEMENT_MODE_OPTIONS: ChoiceOption[] = [
  {
    value: 'single',
    displayText: PLACEMENT_MODE_LABELS.single,
  },
  {
    value: 'repeat',
    displayText: PLACEMENT_MODE_LABELS.repeat,
  },
];

const DEFAULT_DIRECTION_OPTIONS: ChoiceOption[] = [
  {
    value: 'north',
    displayText: DIRECTION_LABELS.north,
  },
  {
    value: 'east',
    displayText: DIRECTION_LABELS.east,
  },
  {
    value: 'south',
    displayText: DIRECTION_LABELS.south,
  },
  {
    value: 'west',
    displayText: DIRECTION_LABELS.west,
  },
];

const DEFAULT_POINT_SHAPE_OPTION: PlacementOption[] = [
  {
    value: 'point',
    label: 'point',
  },
];

const OUTPOST_FAMILY_LABELS: Record<string, string> = {
  metal_perimeter: 'Металл, контур',
  wired_metal_perimeter: 'Металл с проволокой',
  plasteel_bastion: 'Пласталь, бастион',
  plasteel_wired_bastion: 'Пласталь с проволокой',
  sandbag_redoubt: 'Мешки с песком',
  wooden_screen: 'Деревянное прикрытие',
  mixed_standard: 'Смешанный стандарт',
  mixed_siege: 'Смешанный осадный',
};

const OUTPOST_LAYOUT_LABELS: Record<string, string> = {
  crossroads: 'Крест',
  wide_crossroads: 'Широкий крест',
  lane_ns: 'Коридор север-юг',
  lane_ew: 'Коридор восток-запад',
  north_gate: 'Северные ворота',
  south_gate: 'Южные ворота',
  east_gate: 'Восточные ворота',
  west_gate: 'Западные ворота',
  corner_ne: 'Угол север-восток',
  corner_se: 'Угол юго-восток',
  corner_sw: 'Угол юго-запад',
  corner_nw: 'Угол северо-запад',
  sealed_redoubt: 'Закрытый редут',
};

const OUTPOST_OPENING_WIDTH_LABELS: Record<string, string> = {
  profile: 'По варианту',
  narrow: '1 клетка',
  double: '2 клетки',
  wide: '3 клетки',
  quad: '4 клетки',
  broad: '5 клеток',
};

const OUTPOST_BARRICADE_PATTERN_LABELS: Record<string, string> = {
  profile: 'По профилю',
  uniform: 'Единый материал',
  cycle: 'Чередование',
  paired: 'Парные секции',
};

const OUTPOST_GUARD_MODE_LABELS: Record<string, string> = {
  layout: 'По варианту',
  openings: 'Только проходы',
  all_sides: 'Все стороны',
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

const getVisibleFields = (fields: UiField[] = []) =>
  (fields || []).filter((field) => field.visible !== false);

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

const getPlacementOptionValueSet = (options?: PlacementOption[]) =>
  new Set((options || []).map((option) => `${option.value}`));

const getOrderedShapeValues = (options?: PlacementOption[]) => {
  const extraValues = (options || [])
    .map((option) => `${option.value}`)
    .filter((value, index, values) => values.indexOf(value) === index)
    .filter((value) => !PLACEMENT_SHAPE_ORDER.includes(value));

  return [...PLACEMENT_SHAPE_ORDER, ...extraValues];
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
      `Вариант: ${getFieldOptionLabel(getField(data.ui_fields, 'layout_variant'))}`,
    );
  }

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

const PreviewLegend = (props: {
  readonly title?: string;
  readonly items: PreviewLegendItem[];
  readonly mt?: number;
}) => {
  const { title = 'Цвета на карте', items, mt = 0.6 } = props;
  if (!items.length) {
    return null;
  }

  return (
    <Box mt={mt}>
      <Box bold mb={0.3}>
        {title}
      </Box>
      <Flex wrap mx={-0.2}>
        {items.map((item) => (
          <Flex.Item key={item.label} m={0.2}>
            <Box
              px={0.45}
              py={0.25}
              style={{
                border: '1px solid rgba(70, 107, 150, 0.45)',
                borderRadius: '4px',
                background: 'rgba(70, 107, 150, 0.10)',
              }}
            >
              <Box
                as="span"
                mr={0.35}
                style={{
                  display: 'inline-block',
                  width: '0.8rem',
                  height: '0.8rem',
                  borderRadius: '3px',
                  background: item.color,
                  verticalAlign: 'middle',
                }}
              />
              <Box as="span">{item.label}</Box>
            </Box>
          </Flex.Item>
        ))}
      </Flex>
    </Box>
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
  readonly basis?: string;
  readonly onSelected: (value: string) => void;
}) => {
  const { options, selected, disabled, basis, onSelected } = props;
  const itemBasis = basis || (options.length <= 2 ? '45%' : '22%');

  if (!options.length) {
    return <Box color="label">Нет вариантов.</Box>;
  }

  return (
    <Flex wrap mx={-0.15}>
      {options.map((option) => {
        const isSelected = `${option.value}` === `${selected}`;
        return (
          <Flex.Item key={option.value} grow basis={itemBasis} m={0.15}>
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

type FieldChoiceOption = {
  value: string;
  displayText: string;
  rawValue: unknown;
};

const getFieldChoiceOptions = (field?: UiField): FieldChoiceOption[] =>
  (field?.options || []).map((option) => ({
    value: `${option.value}`,
    displayText: translateOptionLabel(
      field?.id || '',
      option.label,
      option.value,
    ),
    rawValue: option.value,
  }));

const getSelectedFieldChoiceValue = (field?: UiField) =>
  `${field?.value ?? ''}`;

const ShapeOptionStrip = (props: {
  readonly options: PlacementOption[];
  readonly selected: string;
  readonly disabled?: boolean;
  readonly onSelected: (value: string) => void;
  readonly buttonMinWidth?: string;
}) => {
  const {
    options,
    selected,
    disabled,
    onSelected,
    buttonMinWidth = '2rem',
  } = props;
  const availableValues = getPlacementOptionValueSet(options);
  const orderedValues = getOrderedShapeValues(options);

  return (
    <Box
      style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(5, minmax(0, 1fr))',
        gap: '0.25rem',
      }}
    >
      {orderedValues.map((value) => {
        const label = getTranslatedShapeLabel(value);
        const glyph = PLACEMENT_SHAPE_GLYPHS[value]?.glyph || '•';
        const isAvailable = availableValues.has(value);
        const isSelected = isAvailable && value === selected;

        return (
          <Button
            key={value}
            compact
            selected={isSelected}
            color={isSelected ? 'good' : undefined}
            disabled={disabled || !isAvailable}
            tooltip={label}
            onClick={() => onSelected(value)}
            style={{
              width: '100%',
              minWidth: buttonMinWidth,
              height: '2rem',
              justifyContent: 'center',
            }}
          >
            <Box
              as="span"
              style={{
                fontSize: '1.05rem',
                lineHeight: '1',
                display: 'inline-block',
                minWidth: '1rem',
                textAlign: 'center',
              }}
            >
              {glyph}
            </Box>
          </Button>
        );
      })}
    </Box>
  );
};

const CompactFieldControl = (props: {
  readonly field?: UiField;
  readonly act: ActFn;
  readonly disabled?: boolean;
}) => {
  const { field, act, disabled } = props;
  if (!field || field.visible === false) {
    return null;
  }

  const effectiveField = disabled ? { ...field, disabled: true } : field;

  return (
    <Box style={{ minWidth: '10.5rem' }}>
      <Box color="label" mb={0.2}>
        {getTranslatedFieldLabel(field)}
      </Box>
      {renderFieldControl(effectiveField, act, {
        forceChoiceStrip:
          effectiveField.kind === 'select' &&
          (effectiveField.options || []).length > 0 &&
          (effectiveField.options || []).length <= 4,
        choiceStripBasis: '46%',
      })}
    </Box>
  );
};

const CompactChoiceStrip = (props: {
  readonly options: ChoiceOption[];
  readonly selected: string;
  readonly disabled?: boolean;
  readonly onSelected: (value: string) => void;
  readonly buttonMinWidth?: string;
}) => {
  const {
    options,
    selected,
    disabled,
    onSelected,
    buttonMinWidth = '6rem',
  } = props;

  if (!options.length) {
    return <Box color="label">Нет вариантов.</Box>;
  }

  return (
    <Flex mx={-0.12}>
      {options.map((option) => {
        const isSelected = `${option.value}` === `${selected}`;
        return (
          <Flex.Item key={option.value} m={0.12}>
            <Button
              compact
              selected={isSelected}
              color={isSelected ? 'good' : undefined}
              disabled={disabled}
              onClick={() => onSelected(option.value)}
              style={{
                minWidth: buttonMinWidth,
                justifyContent: 'center',
              }}
            >
              {option.displayText}
            </Button>
          </Flex.Item>
        );
      })}
    </Flex>
  );
};

const TopShellControlGroup = (props: {
  readonly label: string;
  readonly value?: ReactNode;
  readonly basis: string;
  readonly disabled?: boolean;
  readonly children: ReactNode;
}) => {
  const { label, value, basis, disabled, children } = props;

  return (
    <Flex.Item basis={basis} grow={false} shrink={0} m={0.16}>
      <Box
        px={0.45}
        py={0.4}
        style={{
          minHeight: CHROME_CONTROL_GROUP_HEIGHT,
          border: '1px solid rgba(70, 107, 150, 0.55)',
          background: disabled
            ? 'rgba(70, 107, 150, 0.06)'
            : 'rgba(70, 107, 150, 0.10)',
          borderRadius: '4px',
          opacity: disabled ? '0.82' : '1',
        }}
      >
        <Flex align="center" mb={0.35}>
          <Flex.Item grow>
            <Box color="label">{label}</Box>
          </Flex.Item>
          {!!value && (
            <Flex.Item>
              <Box color={disabled ? 'label' : 'white'} bold>
                {value}
              </Box>
            </Flex.Item>
          )}
        </Flex>
        {children}
      </Box>
    </Flex.Item>
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

type FieldControlOptions = {
  readonly forceChoiceStrip?: boolean;
  readonly choiceStripBasis?: string;
};

const renderFieldControl = (
  field: UiField,
  act: ActFn,
  options?: FieldControlOptions,
) => {
  const { forceChoiceStrip, choiceStripBasis } = options || {};
  const isDisabled = !!field.disabled;

  const emitValue = (value: unknown) => {
    act('set_param', {
      param_id: field.id,
      value,
    });
  };

  if (field.kind === 'boolean') {
    return (
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
    return (
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
    return (
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
    const choiceOptions = getFieldChoiceOptions(field);
    const selected = getSelectedFieldChoiceValue(field);
    const handleSelected = (selectedOptionValue: string) => {
      const selectedOption = choiceOptions.find(
        (option) => option.value === `${selectedOptionValue}`,
      );
      emitValue(selectedOption?.rawValue);
    };

    return forceChoiceStrip ? (
      <ChoiceStrip
        options={choiceOptions}
        selected={selected}
        basis={choiceStripBasis}
        disabled={isDisabled || !choiceOptions.length}
        onSelected={handleSelected}
      />
    ) : (
      <SmartSelect
        options={choiceOptions}
        selected={selected}
        displayText={getFieldOptionLabel(field)}
        disabled={isDisabled || !choiceOptions.length}
        placeholder="Выберите значение"
        onSelected={handleSelected}
      />
    );
  }

  return <Box color="bad">Неподдерживаемый тип поля.</Box>;
};

const FieldEditor = (props: {
  readonly field: UiField;
  readonly act: ActFn;
  readonly showHints?: boolean;
}) => {
  const { field, act, showHints } = props;

  return (
    <LabeledList.Item
      label={
        field.required
          ? `${getTranslatedFieldLabel(field)} *`
          : getTranslatedFieldLabel(field)
      }
    >
      {renderFieldControl(field, act)}
      {!!showHints && !!field.validate_hint && (
        <Box color="average" mt={0.35}>
          {field.validate_hint}
        </Box>
      )}
    </LabeledList.Item>
  );
};

const FieldControl = (props: {
  readonly field: UiField;
  readonly act: ActFn;
  readonly forceChoiceStrip?: boolean;
  readonly choiceStripBasis?: string;
}) => {
  const { field, act, forceChoiceStrip, choiceStripBasis } = props;
  return renderFieldControl(field, act, {
    forceChoiceStrip,
    choiceStripBasis,
  });
};

const FieldControlStack = (props: {
  readonly field?: UiField;
  readonly act: ActFn;
  readonly forceChoiceStrip?: boolean;
  readonly choiceStripBasis?: string;
}) => {
  const { field, act, forceChoiceStrip, choiceStripBasis } = props;
  if (!field || field.visible === false) {
    return null;
  }

  return (
    <Box>
      <Box color="label" mb={0.25}>
        {getTranslatedFieldLabel(field)}
      </Box>
      <FieldControl
        field={field}
        act={act}
        forceChoiceStrip={forceChoiceStrip}
        choiceStripBasis={choiceStripBasis}
      />
      {!!field.validate_hint && (
        <Box color="average" mt={0.25}>
          {field.validate_hint}
        </Box>
      )}
    </Box>
  );
};

const FieldListContent = (props: {
  readonly fields: UiField[];
  readonly act: ActFn;
  readonly showHints?: boolean;
}) => {
  const { fields, act, showHints } = props;
  return (
    <LabeledList>
      {fields.map((field) => (
        <FieldEditor
          key={field.id}
          field={field}
          act={act}
          showHints={showHints}
        />
      ))}
    </LabeledList>
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
  const visibleFields = getVisibleFields(fields);
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
      <FieldListContent
        fields={visibleFields}
        act={act}
        showHints={showHints}
      />
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
  const visibleFields = getVisibleFields(fields);
  if (!visibleFields.length) {
    return null;
  }

  const { borderColor } = getSurfaceColors(tone);

  return (
    <Box
      p={0.5}
      style={{
        borderTop: `2px solid ${borderColor}`,
        border: `1px solid ${borderColor}`,
        background: 'rgba(70, 107, 150, 0.03)',
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
        <FieldListContent
          fields={visibleFields}
          act={act}
          showHints={showHints}
        />
      </Box>
    </Box>
  );
};

const getToolbarState = (data: BackendData): ToolbarState => {
  const title = getCurrentToolTitle(data);
  if (!data.has_generator && data.categories?.length) {
    return {
      title: 'World Edit',
      state: 'Открываем инструмент...',
      stateColor: 'label',
    };
  }

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
        label: 'Разместить',
        action: 'start_placement_mode',
        color: 'good',
        disabled: !canStartPlacement,
      }
    : undefined;

  const placePreviewAction: ToolbarAction | undefined =
    hasPlacementControls && hasVisiblePreview
      ? {
          label: 'Разместить',
          action: 'run_apply',
          color: 'good',
          disabled: !canApply,
        }
      : undefined;

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
      : placePreviewAction || startPlacementAction,
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

const getSharedChromeFields = (data: BackendData) => {
  if (data.current_generator_id === 'blueprint_stamp') {
    return [
      ...getFieldsById(data.ui_fields, ['stamp_spacing']),
      ...(data.placement_shape_fields || []).filter(
        (field) => field.visible !== false,
      ),
    ];
  }

  return (data.placement_shape_fields || []).filter(
    (field) => field.visible !== false,
  );
};

const getDestructionPreviewLegendItems = (
  data: BackendData,
): PreviewLegendItem[] => {
  const previewMeta = data.preview_meta || {};
  const fireEnabled = !!getField(data.ui_fields, 'persistent_fire_enabled')
    ?.value;
  const blastEnabled = !!getField(data.ui_fields, 'blast_enabled')?.value;
  const damageProfile = `${getField(data.ui_fields, 'damage_profile')?.value || 'none'}`;
  const moveEnabled = data.preview_valid
    ? Number(previewMeta.moved_count || 0) > 0
    : !!getField(data.ui_fields, 'shuffle_enabled')?.value ||
      !!getField(data.ui_fields, 'scatter_enabled')?.value;
  const previewFireEnabled = data.preview_valid
    ? Number(previewMeta.fire_count || 0) > 0
    : fireEnabled;
  const previewBlastEnabled = data.preview_valid
    ? Number(previewMeta.blast_count || 0) > 0
    : blastEnabled;
  const previewDamageEnabled = data.preview_valid
    ? Number(previewMeta.damage_count || 0) > 0
    : damageProfile !== 'none';

  return [
    ...(moveEnabled ? [{ label: 'Перемещение', color: '#4e8eff' }] : []),
    ...(previewFireEnabled ? [{ label: 'Огонь', color: '#ff9438' }] : []),
    ...(previewDamageEnabled ? [{ label: 'Урон', color: '#b85cff' }] : []),
    ...(previewBlastEnabled ? [{ label: 'Взрыв', color: '#ff4e4e' }] : []),
  ];
};

const getPlacementModeChoices = (data: BackendData): ChoiceOption[] => {
  const options = (data.placement_mode_options || []).map((option) => ({
    value: option.value,
    displayText: getTranslatedPlacementMode(option.value || option.label),
  }));
  return options.length ? options : DEFAULT_PLACEMENT_MODE_OPTIONS;
};

const getPlacementShapeOptionsForShell = (data: BackendData) => {
  if (data.placement_shape_options?.length) {
    return data.placement_shape_options;
  }

  if (data.placement_shape) {
    return [
      {
        value: data.placement_shape,
        label: data.placement_shape,
      },
    ];
  }

  return DEFAULT_POINT_SHAPE_OPTION;
};

const getPlacementDirectionChoices = (data: BackendData): ChoiceOption[] => {
  const options = (data.placement_dir_options || []).map((option) => ({
    value: option.value,
    displayText: getTranslatedDirection(option.value || option.label),
  }));
  return options.length ? options : DEFAULT_DIRECTION_OPTIONS;
};

const SharedModePanel = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
  readonly workspaceTab: WorkspaceTabKey;
}) => {
  const { data, act, workspaceTab } = props;
  const isHistoryTab = workspaceTab === 'history';
  const hasGenerator = !!data.has_generator;
  const shapeOptions = getPlacementShapeOptionsForShell(data);
  const modeOptions = getPlacementModeChoices(data);
  const directionOptions = getPlacementDirectionChoices(data);
  const sharedFields = getSharedChromeFields(data).filter(
    (field) => field.visible !== false,
  );
  const selectedShape =
    data.current_generator_id === 'destruction_pack'
      ? 'point'
      : `${data.placement_shape || shapeOptions[0]?.value || 'point'}`;
  const selectedMode = `${data.placement_mode || modeOptions[0]?.value || 'single'}`;
  const selectedDirection = `${data.placement_dir || directionOptions[0]?.value || 'north'}`;
  const shapeDisabled =
    isHistoryTab ||
    !hasGenerator ||
    !data.placement_shape_supported ||
    data.current_generator_id === 'destruction_pack';
  const modeDisabled =
    isHistoryTab || !hasGenerator || !data.placement_supported;
  const directionDisabled =
    isHistoryTab || !hasGenerator || !data.placement_supports_direction;
  const parametersDisabled =
    isHistoryTab || !hasGenerator || !sharedFields.length;

  return (
    <Box style={{ overflowX: 'auto', overflowY: 'hidden' }}>
      <Flex style={{ width: 'max-content', minWidth: '100%' }} mx={-0.16}>
        <TopShellControlGroup
          label="Форма"
          value={getTranslatedShapeLabel(selectedShape)}
          basis="23rem"
          disabled={shapeDisabled}
        >
          <Box style={{ overflowX: 'auto', overflowY: 'hidden' }}>
            <ShapeOptionStrip
              options={shapeOptions}
              selected={selectedShape}
              disabled={shapeDisabled}
              buttonMinWidth="2.05rem"
              onSelected={(value) =>
                act('set_placement_shape', {
                  shape: value,
                })
              }
            />
          </Box>
        </TopShellControlGroup>

        <TopShellControlGroup
          label="После клика"
          basis="12rem"
          disabled={modeDisabled}
        >
          <CompactChoiceStrip
            options={modeOptions}
            selected={selectedMode}
            disabled={modeDisabled}
            buttonMinWidth="5rem"
            onSelected={(value) =>
              act('set_placement_mode', {
                mode: value,
              })
            }
          />
        </TopShellControlGroup>

        <TopShellControlGroup
          label="Направление"
          value={
            directionDisabled
              ? 'Недоступно'
              : data.placement_dir_uses_facing
                ? 'Взгляд'
                : getTranslatedDirection(selectedDirection)
          }
          basis="20.5rem"
          disabled={directionDisabled}
        >
          <>
            <Button.Checkbox
              checked={data.placement_dir_uses_facing}
              disabled={directionDisabled}
              onClick={() =>
                act('set_placement_dir_uses_facing', {
                  enabled: !data.placement_dir_uses_facing,
                })
              }
            >
              По направлению взгляда
            </Button.Checkbox>
            <Box mt={0.3}>
              <CompactChoiceStrip
                options={directionOptions}
                selected={selectedDirection}
                disabled={directionDisabled || data.placement_dir_uses_facing}
                buttonMinWidth="4.65rem"
                onSelected={(value) =>
                  act('set_placement_dir', {
                    direction: value,
                  })
                }
              />
            </Box>
          </>
        </TopShellControlGroup>

        <TopShellControlGroup
          label="Параметры"
          value={sharedFields.length ? `${sharedFields.length}` : 'Нет'}
          basis="22rem"
          disabled={parametersDisabled}
        >
          {sharedFields.length ? (
            <Box style={{ overflowX: 'auto', overflowY: 'hidden' }}>
              <Flex wrap={false} mx={-0.18}>
                {sharedFields.map((field) => (
                  <Flex.Item key={field.id} m={0.18}>
                    <CompactFieldControl
                      field={field}
                      act={act}
                      disabled={parametersDisabled}
                    />
                  </Flex.Item>
                ))}
              </Flex>
            </Box>
          ) : (
            <Box color="label" mt={0.35}>
              Доп. параметры не нужны.
            </Box>
          )}
        </TopShellControlGroup>
      </Flex>
    </Box>
  );
};

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

const BlueprintStampWorkspace = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
}) => {
  const { data, act } = props;
  const [searchQuery, setSearchQuery] = useState('');

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
  const totalBlueprints = data.blueprint_entries?.length || 0;

  return (
    <SurfaceCard
      title="Библиотека"
      subtitle={`${filteredBlueprints.length} из ${totalBlueprints}`}
      actions={
        <Button compact onClick={() => act('list_blueprints')}>
          Обновить
        </Button>
      }
      mt={0}
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
            const canLoad = blueprint.valid && !isActive;
            return (
              <Box
                key={blueprint.id}
                p={0.45}
                mb={0.3}
                onClick={() => {
                  if (canLoad) {
                    act('load_blueprint', {
                      blueprint_id: blueprint.id,
                    });
                  }
                }}
                style={{
                  border: isActive
                    ? '1px solid #4c9f39'
                    : '1px solid rgba(70, 107, 150, 0.55)',
                  borderLeft: isActive
                    ? '3px solid #4c9f39'
                    : '3px solid transparent',
                  background: isActive
                    ? 'rgba(76, 159, 57, 0.16)'
                    : 'rgba(70, 107, 150, 0.10)',
                  borderRadius: '4px',
                  cursor: canLoad ? 'pointer' : 'default',
                }}
              >
                <Flex align="center" wrap>
                  <Flex.Item grow basis="14rem" style={{ minWidth: '0' }}>
                    <Box
                      bold
                      color={isActive ? 'good' : 'white'}
                      style={{
                        whiteSpace: 'nowrap',
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                      }}
                    >
                      {getDisplayText(blueprint.name, 'Шаблон без имени')}
                    </Box>
                  </Flex.Item>
                  {isActive && (
                    <Flex.Item style={{ flex: '0 0 auto' }}>
                      <Box
                        color="good"
                        px={0.35}
                        py={0.12}
                        style={{
                          border: '1px solid rgba(76, 159, 57, 0.45)',
                          background: 'rgba(76, 159, 57, 0.14)',
                          borderRadius: '999px',
                          fontSize: '0.82rem',
                          whiteSpace: 'nowrap',
                        }}
                      >
                        Активен
                      </Box>
                    </Flex.Item>
                  )}
                  {blueprint.valid && (
                    <Flex.Item basis="100%" style={{ minWidth: '0' }}>
                      <Box
                        color="label"
                        mt={0.2}
                        style={{ fontSize: '0.92rem' }}
                      >
                        {getBlueprintLibraryMetaText(blueprint)}
                      </Box>
                    </Flex.Item>
                  )}
                </Flex>
                {!blueprint.valid && (
                  <Box color="bad" mt={0.2}>
                    {blueprint.error || 'Шаблон недоступен.'}
                  </Box>
                )}
              </Box>
            );
          })}
        </Box>
      )}
    </SurfaceCard>
  );
};

const OutpostRadiusWorkspace = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
}) => {
  const { data, act } = props;
  const sentryFields = getFieldsByGroup(data.ui_fields, 'Sentries');
  const barricadeFields = getFieldsByGroup(data.ui_fields, 'Barricades');
  const layoutFields = getFieldsByGroup(data.ui_fields, 'Layout').filter(
    (field) => field.id !== 'radius',
  );
  const familyField = getField(layoutFields, 'family');
  const layoutVariantField = getField(layoutFields, 'layout_variant');
  const openingWidthField = getField(layoutFields, 'opening_width');
  const extraLayoutFields = layoutFields.filter(
    (field) =>
      !['family', 'layout_variant', 'opening_width'].includes(field.id),
  );
  const sentryToggleField = getField(sentryFields, 'place_sentries');
  const sentryDetailFields = getFieldsById(sentryFields, [
    'guard_mode',
    'sentry_path',
    'faction',
    'turned_on',
  ]).filter((field) => field.visible !== false);

  return (
    <Box>
      <SurfaceCard
        title="Профиль и вариант"
        mt={0}
        actions={
          data.can_save_blueprint_from_plan ? (
            <Button compact onClick={() => act('save_blueprint')}>
              Сохранить как шаблон
            </Button>
          ) : undefined
        }
      >
        <Box
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(2, minmax(0, 1fr))',
            gap: '0.6rem',
          }}
        >
          <FieldControlStack field={familyField} act={act} />
          <FieldControlStack field={layoutVariantField} act={act} />
        </Box>
        {!!openingWidthField && (
          <Box mt={0.6}>
            <FieldControlStack
              field={openingWidthField}
              act={act}
              forceChoiceStrip
              choiceStripBasis="15.8%"
            />
          </Box>
        )}
        {!!extraLayoutFields.filter((field) => field.visible !== false)
          .length && (
          <Box mt={0.6}>
            <LabeledList>
              {extraLayoutFields
                .filter((field) => field.visible !== false)
                .map((field) => (
                  <FieldEditor key={field.id} field={field} act={act} />
                ))}
            </LabeledList>
          </Box>
        )}
      </SurfaceCard>
      <FieldListCard title="Периметр" fields={barricadeFields} act={act} />
      <SurfaceCard title="Оборона" mt={0.6}>
        <Box style={{ maxWidth: '16rem' }}>
          <FieldControlStack field={sentryToggleField} act={act} />
        </Box>
        {!!sentryDetailFields.length && (
          <Box
            mt={0.6}
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(2, minmax(0, 1fr))',
              gap: '0.6rem',
            }}
          >
            {sentryDetailFields.map((field) => (
              <FieldControlStack key={field.id} field={field} act={act} />
            ))}
          </Box>
        )}
      </SurfaceCard>
    </Box>
  );
};

const DestructionPackWorkspace = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
}) => {
  const { data, act } = props;
  const areaFields = getFieldsByGroup(data.ui_fields, 'Area').filter(
    (field) => field.id !== 'radius',
  );
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
  const movementEnabled =
    !!getField(data.ui_fields, 'shuffle_enabled')?.value ||
    !!getField(data.ui_fields, 'scatter_enabled')?.value;
  const visibleAreaFields = areaFields.filter(
    (field) => field.visible !== false,
  );
  const visibleMovementFields = safeMovementFields.filter(
    (field) => field.visible !== false,
  );
  const previewLegendItems = getDestructionPreviewLegendItems(data);

  return (
    <>
      {!!previewLegendItems.length && (
        <PreviewLegend items={previewLegendItems} mt={0} />
      )}

      {(!!visibleAreaFields.length || !!visibleMovementFields.length) && (
        <SurfaceCard title="Безопасная зона" subtitle="Без взрыва и урона">
          <WorkspaceGrid>
            {!!visibleMovementFields.length && (
              <WorkspacePane
                basis={visibleAreaFields.length ? '48%' : '100%'}
                minWidth="19rem"
              >
                <FieldBlock
                  title="Перемещение"
                  fields={visibleMovementFields}
                  act={act}
                  tone={movementEnabled ? 'average' : 'default'}
                />
              </WorkspacePane>
            )}
            {!!visibleAreaFields.length && (
              <WorkspacePane basis="48%" minWidth="19rem">
                <FieldBlock title="Зона" fields={visibleAreaFields} act={act} />
              </WorkspacePane>
            )}
          </WorkspaceGrid>
        </SurfaceCard>
      )}

      <SurfaceCard
        title="Опасные режимы"
        mt={visibleAreaFields.length || visibleMovementFields.length ? 0.6 : 0}
        tone={destructiveEnabled ? 'bad' : fireEnabled ? 'average' : 'default'}
      >
        <WorkspaceGrid>
          <WorkspacePane basis="33%" minWidth="16rem">
            <FieldBlock
              title="Огонь"
              fields={fireFields}
              act={act}
              tone={fireEnabled ? 'average' : 'default'}
            />
          </WorkspacePane>
          <WorkspacePane basis="33%" minWidth="16rem">
            <FieldBlock
              title="Взрыв"
              subtitle={blastEnabled ? 'Откат ограничен' : undefined}
              fields={blastFields}
              act={act}
              tone={blastEnabled ? 'bad' : 'default'}
            />
          </WorkspacePane>
          <WorkspacePane basis="33%" minWidth="16rem">
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

      {!data.has_inline_fields && showPlacementSetup && (
        <Box color="label">Управление режимом находится выше.</Box>
      )}
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

const EditorChrome = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
  readonly toolTabs: GeneratorEntry[];
  readonly workspaceTab: WorkspaceTabKey;
  readonly onSelectGenerator: (generatorId: string) => void;
  readonly onSelectWorkspaceTab: (tab: WorkspaceTabKey) => void;
}) => {
  const {
    data,
    act,
    toolTabs,
    workspaceTab,
    onSelectGenerator,
    onSelectWorkspaceTab,
  } = props;
  const toolbar = getToolbarState(data);
  const actionsDisabled = !data.has_generator;
  const chromeTitle = toolbar.title;
  const chromeContext = toolbar.context;

  const renderAction = (action?: ToolbarAction, compact = false) => {
    if (!action) {
      return null;
    }

    return (
      <Button
        compact={compact}
        color={action.color}
        disabled={actionsDisabled || action.disabled}
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
      style={{
        position: 'sticky',
        top: '0',
        zIndex: '5',
        background: 'rgba(17, 20, 24, 0.97)',
        border: '1px solid rgba(70, 107, 150, 0.75)',
        borderRadius: '4px',
      }}
    >
      <Box px={0.65} py={0.45} style={{ minHeight: '4.25rem' }}>
        <Box style={{ overflowX: 'auto', overflowY: 'hidden' }}>
          <Flex
            align="center"
            mx={-0.25}
            style={{ width: 'max-content', minWidth: '100%' }}
          >
            <Flex.Item grow basis="15rem" m={0.25}>
              <Box
                bold
                style={{
                  whiteSpace: 'nowrap',
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                }}
              >
                {chromeTitle}
              </Box>
              <Box
                color="label"
                mt={0.1}
                style={{
                  minHeight: '1.1rem',
                  whiteSpace: 'nowrap',
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                }}
              >
                {chromeContext || '\u00a0'}
              </Box>
            </Flex.Item>

            <Flex.Item basis="11.5rem" grow={false} shrink={0} m={0.25}>
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

            <Flex.Item grow={false} shrink={0} m={0.25}>
              <Flex
                align="center"
                mx={-0.15}
                style={{ width: 'max-content', minWidth: '31rem' }}
              >
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
                  <Flex.Item m={0.15}>
                    {renderAction(
                      toolbar.placementAction,
                      data.click_mode_active,
                    )}
                  </Flex.Item>
                )}
                {!!toolbar.collectorAction && (
                  <Flex.Item m={0.15}>
                    {renderAction(toolbar.collectorAction, true)}
                  </Flex.Item>
                )}
                {!!toolbar.undoAction && (
                  <Flex.Item m={0.15}>
                    {renderAction(toolbar.undoAction, true)}
                  </Flex.Item>
                )}
                {data.has_generator && (
                  <Flex.Item m={0.15}>
                    <Button.Checkbox
                      checked={data.confirm_before_apply}
                      disabled={actionsDisabled}
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
      </Box>

      <Box
        px={0.65}
        py={0.45}
        style={{
          minHeight: '6rem',
          borderTop: '1px solid rgba(70, 107, 150, 0.35)',
        }}
      >
        <SharedModePanel data={data} act={act} workspaceTab={workspaceTab} />
      </Box>

      <Box
        px={0.5}
        pt={0.45}
        pb={0.3}
        style={{
          minHeight: '2.55rem',
          borderTop: '1px solid rgba(70, 107, 150, 0.35)',
        }}
      >
        <NavigationTabs
          toolTabs={toolTabs}
          activeGeneratorId={data.current_generator_id}
          workspaceTab={workspaceTab}
          onSelectGenerator={onSelectGenerator}
          onSelectWorkspaceTab={onSelectWorkspaceTab}
        />
      </Box>
    </Box>
  );
};

const NavigationTabs = (props: {
  readonly toolTabs: GeneratorEntry[];
  readonly activeGeneratorId?: string;
  readonly workspaceTab: WorkspaceTabKey;
  readonly onSelectGenerator: (generatorId: string) => void;
  readonly onSelectWorkspaceTab: (tab: WorkspaceTabKey) => void;
}) => {
  const {
    toolTabs,
    activeGeneratorId,
    workspaceTab,
    onSelectGenerator,
    onSelectWorkspaceTab,
  } = props;

  if (!toolTabs.length && workspaceTab !== 'history') {
    return null;
  }

  return (
    <Tabs mb={0}>
      {toolTabs.map((generator) => (
        <Tabs.Tab
          key={generator.id}
          selected={
            workspaceTab === 'editor' && generator.id === activeGeneratorId
          }
          onClick={() => onSelectGenerator(generator.id)}
        >
          {TOOL_PICKER_LABELS[generator.id] || generator.name_ru}
        </Tabs.Tab>
      ))}
      <Tabs.Tab
        selected={workspaceTab === 'history'}
        onClick={() => onSelectWorkspaceTab('history')}
      >
        Журнал
      </Tabs.Tab>
    </Tabs>
  );
};

const WorkspacePage = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
  readonly groupedFields: Record<string, UiField[]>;
  readonly groupNames: string[];
  readonly showPlacementSetup: boolean;
  readonly toolTabs: GeneratorEntry[];
  readonly workspaceTab: WorkspaceTabKey;
  readonly onSelectGenerator: (generatorId: string) => void;
  readonly onSelectWorkspaceTab: (tab: WorkspaceTabKey) => void;
}) => {
  const {
    data,
    act,
    groupedFields,
    groupNames,
    showPlacementSetup,
    toolTabs,
    workspaceTab,
    onSelectGenerator,
    onSelectWorkspaceTab,
  } = props;

  return (
    <Section fill scrollable>
      <EditorChrome
        data={data}
        act={act}
        toolTabs={toolTabs}
        workspaceTab={workspaceTab}
        onSelectGenerator={onSelectGenerator}
        onSelectWorkspaceTab={onSelectWorkspaceTab}
      />

      {!data.has_generator && !!data.categories?.length && (
        <SurfaceCard title="Открываем инструмент">
          <Box color="label">
            Первый доступный инструмент подгружается автоматически.
          </Box>
        </SurfaceCard>
      )}

      {!data.has_generator && !data.categories?.length && (
        <SurfaceCard title="Выберите инструмент">
          <Box color="label">Шаблон, форпост, разрушение.</Box>
        </SurfaceCard>
      )}

      {!!data.has_generator &&
        (workspaceTab === 'editor' ? (
          <ToolWorkspace
            data={data}
            act={act}
            groupedFields={groupedFields}
            groupNames={groupNames}
            showPlacementSetup={showPlacementSetup}
          />
        ) : (
          <HistoryWorkspace data={data} act={act} />
        ))}
    </Section>
  );
};

export const WorldEditPanel = () => {
  const { data, act } = useBackend<BackendData>();
  const [workspaceTab, setWorkspaceTab] = useState<WorkspaceTabKey>('editor');
  const showPlacementSetup =
    data.placement_supported ||
    data.placement_shape_supported ||
    data.placement_supports_direction;
  const toolTabs = useMemo(
    () => buildOrderedToolTabs(data.categories || []),
    [data.categories],
  );

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
    if (!data.has_generator && workspaceTab !== 'editor') {
      setWorkspaceTab('editor');
    }
  }, [data.has_generator, workspaceTab]);

  const handleSelectGenerator = (generatorId: string) => {
    if (workspaceTab !== 'editor') {
      setWorkspaceTab('editor');
    }
    if (generatorId && generatorId !== data.current_generator_id) {
      act('select_generator', {
        generator_id: generatorId,
      });
    }
  };

  return (
    <Window title="World Edit Panel" width={920} height={620}>
      <Window.Content>
        <WorkspacePage
          data={data}
          act={act}
          groupedFields={groupedFields}
          groupNames={groupNames}
          showPlacementSetup={showPlacementSetup}
          toolTabs={toolTabs}
          workspaceTab={workspaceTab}
          onSelectGenerator={handleSelectGenerator}
          onSelectWorkspaceTab={setWorkspaceTab}
        />
      </Window.Content>
    </Window>
  );
};
