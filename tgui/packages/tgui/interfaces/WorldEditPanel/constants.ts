import type { ChoiceOption, PlacementOption, ShapeGlyphSpec } from './types';

export const EMPTY_LABEL = 'Не задано';
export const NONE_LABEL = 'Не выбрано';
export const WORKSPACE_GUTTER = 0.35;
export const SMALL_CHOICE_DROPDOWN_THRESHOLD = 5;

export const FIELD_LABELS: Record<string, string> = {
  defense_profile: 'Тактический профиль',
  layout_variant: 'Схема',
  opening_width: 'Ширина проходов',
  radius: 'Радиус',
  primary_material_path: 'Основной материал',
  secondary_material_path: 'Вспомогательный материал',
  primary_door_path: 'Основные двери',
  secondary_door_path: 'Вспомогательные двери',
  primary_material_share_percent: 'Доля основного материала',
  place_barricade_doors: 'Двери в проходах',
  barricade_pattern: 'Раскладка материалов',
  faction: 'IFF',
  sentry_layer_profile: 'Sentry layer',
  sentry_type: 'Sentry type',
  extra_defense_layer_profile: 'Support layer',
  extra_defense_type: 'Support type',
  flag_type: 'Flag',
  wire_layer_profile: 'Wire layer',
  wire_offset: 'Wire offset',
  wire_rows: 'Wire rows',
  wire_row_step: 'Wire row step',
  wire_spacing: 'Wire spacing',
  wire_concentration_percent: 'Wire concentration',
  minefield_profile: 'Minefield',
  mine_type: 'Mine type',
  minefield_offset: 'Mine offset',
  minefield_depth: 'Mine depth',
  minefield_density_percent: 'Mine density',
  minefield_seed: 'Mine seed',
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
  preset_id: 'Пресет',
  material_family: 'Материал',
  material_wired: 'Проволока',
  door_policy: 'Двери',
  door_material_family: 'Материал дверей',
  door_wired: 'Проволока на дверях',
  room_tile_cap: 'Лимит клеток',
  treat_windows_as_boundary: 'Окна как граница',
  fortify_windows: 'Укреплять окна',
  treat_doors_as_boundary: 'Двери как граница',
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
    label: 'Точка',
  },
];

export const OUTPOST_TACTICAL_PROFILE_LABELS: Record<string, string> = {
  none: 'Без обороны',
  outrider_camp: 'Легкий дозор',
  fallback_redoubt: 'Редут отхода',
  lane_fort: 'Линейный форт',
  pocket_defense: 'Карман обороны',
  crossfire_hub: 'Узел перекрестного огня',
  anti_vehicle_stop: 'Противотранспортный стоп',
  forward_medical_cover: 'Передовое медукрытие',
};

export const OUTPOST_LAYOUT_LABELS: Record<string, string> = {
  crossroads: 'Крест',
  wide_crossroads: 'Широкий крест',
  lane: 'Линия',
  gate: 'Ворота',
  corner: 'Угол',
  sealed_redoubt: 'Запечатанный редут',
  t_junction: 'T-перекресток',
  three_side_open: 'Три стороны открыты',
  three_side_lock: 'Три стороны под замком',
  double_gate: 'Двойные ворота',
  funnel_front: 'Фронтальная воронка',
  narrow_funnel: 'Узкая воронка',
  broad_funnel: 'Широкая воронка',
  inner_pocket: 'Внутренний карман',
  fallback_pocket_layout: 'Карман отхода',
  split_mouth: 'Раздвоенный вход',
  split_entry_guard: 'Раздвоенный вход с охраной',
  corner_wide: 'Широкий угол',
  lane_narrow: 'Узкая линия',
  lane_wide: 'Широкая линия',
  bastion_face: 'Фасад бастиона',
  sealed_shell: 'Запечатанная оболочка',
  sealed_redoubt_heavy: 'Тяжелый запечатанный редут',
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
  double_gate_ns: 'Двойные ворота север-юг',
  double_gate_ew: 'Двойные ворота восток-запад',
  corner_ne_wide: 'Широкий угол север-восток',
  corner_se_wide: 'Широкий угол юго-восток',
  corner_sw_wide: 'Широкий угол юго-запад',
  corner_nw_wide: 'Широкий угол северо-запад',
  lane_ns_narrow: 'Узкая линия север-юг',
  lane_ns_wide: 'Широкая линия север-юг',
  lane_ew_narrow: 'Узкая линия восток-запад',
  lane_ew_wide: 'Широкая линия восток-запад',
  bastion_face_north: 'Фасад бастиона север',
  bastion_face_south: 'Фасад бастиона юг',
  bastion_face_east: 'Фасад бастиона восток',
  bastion_face_west: 'Фасад бастиона запад',
};
export const OUTPOST_OPENING_WIDTH_LABELS: Record<string, string> = {
  layout: 'По схеме',
  zero: '0 тайлов',
  narrow: '1 клетка',
  double: '2 клетки',
  wide: '3 клетки',
  quad: '4 клетки',
  broad: '5 клеток',
};

export const OUTPOST_BARRICADE_PATTERN_LABELS: Record<string, string> = {
  uniform: 'Единый материал',
  alternating: 'Чередование',
  paired: 'Парные секции',
};

export const OUTPOST_PERIMETER_PATTERN_LABELS =
  OUTPOST_BARRICADE_PATTERN_LABELS;

export const OUTPOST_LAYER_PROFILE_LABELS: Record<string, string> = {
  none: 'None',
  guard: 'Interior guard',
  rear: 'Rear support',
  corners: 'Corners',
  guard_corners: 'Guard + corners',
  openings: 'Outside openings',
  perimeter: 'Outside perimeter',
};

export const OUTPOST_MINEFIELD_PROFILE_LABELS: Record<string, string> = {
  none: 'None',
  light: 'Light field',
  medium: 'Medium field',
  dense: 'Dense field',
};

export const FORTIFY_PRESET_LABELS: Record<string, string> = {
  legacy_wood: 'Дерево',
  legacy_sandbag: 'Мешки',
  legacy_sandbag_wired: 'Мешки + проволока',
  legacy_metal: 'Металл',
  legacy_metal_wired: 'Металл + проволока',
  legacy_plasteel: 'Пласталь',
  legacy_plasteel_wired: 'Пласталь + проволока',
  custom: 'Свой',
};

export const FORTIFY_MATERIAL_LABELS: Record<string, string> = {
  wood: 'Дерево',
  sandbag: 'Мешки',
  metal: 'Металл',
  plasteel: 'Пласталь',
};

export const FORTIFY_DOOR_POLICY_LABELS: Record<string, string> = {
  auto: 'Авто',
  custom: 'Вручную',
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
