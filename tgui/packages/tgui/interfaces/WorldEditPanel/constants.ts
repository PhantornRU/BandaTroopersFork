import type { ChoiceOption, PlacementOption, ShapeGlyphSpec } from './types';

export const EMPTY_LABEL = 'Не задано';
export const NONE_LABEL = 'Не выбрано';
export const WORKSPACE_GUTTER = 0.35;
export const SMALL_CHOICE_DROPDOWN_THRESHOLD = 5;

export const EXECUTION_MODE_LABELS: Record<string, string> = {
  batch: 'Пакетный',
  click: 'По клику',
};

export const FIELD_LABELS: Record<string, string> = {
  family: 'Тактический профиль',
  defense_profile: 'Тактический профиль',
  layout_variant: 'Схема',
  opening_width: 'Ширина проходов',
  radius: 'Радиус',
  barricade_path: 'Основной материал',
  primary_material_path: 'Основной материал',
  primary_barricade_path: 'Основной материал',
  secondary_material_path: 'Вспомогательный материал',
  secondary_barricade_path: 'Вспомогательный материал',
  primary_door_path: 'Основные двери',
  secondary_door_path: 'Вспомогательные двери',
  barricade_concentration_percent: 'Доля основного материала',
  primary_material_share_percent: 'Доля основного материала',
  place_barricade_doors: 'Двери в проходах',
  barricade_pattern: 'Раскладка материалов',
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
  radius_only_clear_tiles: 'Только чистые клетки',
  radius_only_reachable_tiles: 'Только достижимые клетки',
  radius_windows_blockers: 'Окна как блокираторы',
};

export const RADIUS_POLICY_FIELD_IDS = [
  'radius_only_clear_tiles',
  'radius_only_reachable_tiles',
  'radius_windows_blockers',
];

export const RADIUS_POLICY_SHORT_LABELS: Record<string, string> = {
  radius_only_clear_tiles: 'Чист.',
  radius_only_reachable_tiles: 'Дост.',
  radius_windows_blockers: 'Окна',
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

export const OUTPOST_TACTICAL_PROFILE_LABELS: Record<string, string> = {
  metal_perimeter: 'Легкий контур',
  wired_metal_perimeter: 'Контур с проволокой',
  plasteel_bastion: 'Тяжелый бастион',
  plasteel_wired_bastion: 'Усиленный бастион',
  sandbag_redoubt: 'Полевой редут',
  wooden_screen: 'Импровизированное прикрытие',
  mixed_standard: 'Сбалансированный опорник',
  mixed_siege: 'Осадный опорник',
  expedition_light: 'Легкий экспедиционный',
  assault_screen: 'Штурмовой экран',
  choke_wall: 'Горловинная стена',
  killbox_wired: 'Killbox с проволокой',
  bastion_heavy: 'Тяжелый бастион',
  mixed_siege_plus: 'Усиленный осадный',
  sandbag_nest: 'Полевое гнездо',
  wooden_emergency: 'Экстренное прикрытие',
  fallback_redoubt: 'Редут отхода',
  lane_fort: 'Линейный форт',
  pocket_defense: 'Карман обороны',
  crossfire_hub: 'Узел перекрестного огня',
  anti_vehicle_stop: 'Противотранспортный стоп',
  outrider_camp: 'Лагерь аутрайдеров',
  forward_medical_cover: 'Передовое медукрытие',
};

export const OUTPOST_FAMILY_LABELS = OUTPOST_TACTICAL_PROFILE_LABELS;

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
  profile: 'По схеме',
  narrow: '1 клетка',
  double: '2 клетки',
  wide: '3 клетки',
  quad: '4 клетки',
  broad: '5 клеток',
};

export const OUTPOST_BARRICADE_PATTERN_LABELS: Record<string, string> = {
  profile: 'По материалам',
  uniform: 'Единый материал',
  alternating: 'Чередование',
  cycle: 'Чередование',
  paired: 'Парные секции',
};

export const OUTPOST_PERIMETER_PATTERN_LABELS = OUTPOST_BARRICADE_PATTERN_LABELS;

export const OUTPOST_GUARD_MODE_LABELS: Record<string, string> = {
  layout: 'По схеме',
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
  'Metal Folding Barricade': 'Складная металлическая',
  'Metal Folding Barricade - Wired': 'Складная металлическая, с проволокой',
  Sandbags: 'Мешки с песком',
  'Plasteel Barricade': 'Пласталевая',
  'Plasteel Barricade - Wired': 'Пласталевая, с проволокой',
  'Plasteel Folding Barricade': 'Складная пласталевая',
  'Plasteel Folding Barricade - Wired': 'Складная пласталевая, с проволокой',
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
