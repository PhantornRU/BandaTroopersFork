import type {
  ChoiceOption,
  GeneratorCategory,
  GeneratorEntry,
  PlacementOption,
  ShapeGlyphSpec,
} from './types';

export const EMPTY_LABEL = 'Не задано';
export const NONE_LABEL = 'Не выбрано';
export const WORKSPACE_GUTTER = 0.35;
export const SMALL_CHOICE_DROPDOWN_THRESHOLD = 5;

const TOOL_TAB_ORDER = [
  'blueprint_stamp',
  'outpost_radius',
  'destruction_pack',
];

export const buildOrderedToolTabs = (categories: GeneratorCategory[] = []) => {
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

export const TOOL_TITLE_LABELS: Record<string, string> = {
  blueprint_stamp: 'Штамп по шаблону',
  outpost_radius: 'Форпост',
  destruction_pack: 'Разрушение зоны',
};

export const TOOL_PICKER_LABELS: Record<string, string> = {
  blueprint_stamp: 'Шаблон',
  outpost_radius: 'Форпост',
  destruction_pack: 'Разрушение',
};

export const FIELD_LABELS: Record<string, string> = {
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

export const PLACEMENT_MODE_LABELS: Record<string, string> = {
  single: 'Один раз',
  repeat: 'Повторять',
};

export const DIRECTION_LABELS: Record<string, string> = {
  north: 'Север',
  east: 'Восток',
  south: 'Юг',
  west: 'Запад',
};

export const PLACEMENT_SHAPE_LABELS: Record<string, string> = {
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

export const PLACEMENT_SHAPE_GLYPHS: Record<string, ShapeGlyphSpec> = {
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

export const PLACEMENT_SHAPE_ORDER = Object.keys(PLACEMENT_SHAPE_LABELS);
export const DEFAULT_PLACEMENT_MODE_OPTIONS: ChoiceOption[] = [
  {
    value: 'single',
    displayText: PLACEMENT_MODE_LABELS.single,
  },
  {
    value: 'repeat',
    displayText: PLACEMENT_MODE_LABELS.repeat,
  },
];

export const DEFAULT_DIRECTION_OPTIONS: ChoiceOption[] = [
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

export const DEFAULT_POINT_SHAPE_OPTION: PlacementOption[] = [
  {
    value: 'point',
    label: 'point',
  },
];

export const OUTPOST_FAMILY_LABELS: Record<string, string> = {
  metal_perimeter: 'Металл, контур',
  wired_metal_perimeter: 'Металл с проволокой',
  plasteel_bastion: 'Пласталь, бастион',
  plasteel_wired_bastion: 'Пласталь с проволокой',
  sandbag_redoubt: 'Мешки с песком',
  wooden_screen: 'Деревянное прикрытие',
  mixed_standard: 'Смешанный стандарт',
  mixed_siege: 'Смешанный осадный',
};

export const OUTPOST_LAYOUT_LABELS: Record<string, string> = {
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

export const OUTPOST_OPENING_WIDTH_LABELS: Record<string, string> = {
  profile: 'По варианту',
  narrow: '1 клетка',
  double: '2 клетки',
  wide: '3 клетки',
  quad: '4 клетки',
  broad: '5 клеток',
};

export const OUTPOST_BARRICADE_PATTERN_LABELS: Record<string, string> = {
  profile: 'По профилю',
  uniform: 'Единый материал',
  cycle: 'Чередование',
  paired: 'Парные секции',
};

export const OUTPOST_GUARD_MODE_LABELS: Record<string, string> = {
  layout: 'По варианту',
  openings: 'Только проходы',
  all_sides: 'Все стороны',
};

export const DAMAGE_PROFILE_LABELS: Record<string, string> = {
  none: 'Без урона',
  ruin: 'Руины',
  collapse: 'Обрушение',
};

export const BARRICADE_LABELS: Record<string, string> = {
  'Metal Barricade': 'Металлическая',
  'Metal Barricade - Wired': 'Металлическая, с проволокой',
  Sandbags: 'Мешки с песком',
  'Plasteel Barricade': 'Пласталевая',
  'Plasteel Barricade - Wired': 'Пласталевая, с проволокой',
  'Wooden Barricade': 'Деревянная',
};

export const SENTRY_LABELS: Record<string, string> = {
  'USCM Sentry': 'USCM',
  'USCM Sentry - DMR': 'USCM DMR',
  'USCM Sentry - Shotgun': 'USCM дробовик',
  'USCM Sentry - Mini': 'USCM mini',
  'UPP Sentry': 'UPP',
  'W-Y Sentry': 'W-Y',
};

export const UNDO_POLICY_LABELS: Record<string, string> = {
  full: 'Полный',
  partial: 'Частичный',
  none: 'Без отката',
};

export const UNDO_STATUS_LABELS: Record<string, string> = {
  available: 'Доступен',
  cleanup_available: 'Доступна очистка',
  not_available: 'Недоступен',
  full: 'Полный',
  partial: 'Частичный',
  none: 'Нет',
};
