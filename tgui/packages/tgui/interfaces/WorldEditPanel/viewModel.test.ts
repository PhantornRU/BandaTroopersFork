import { PLACEMENT_SHAPE_ORDER } from './constants';
import type { BackendData, HistoryEntry, UiField } from './types';
import {
  buildWorldEditViewModel,
  filterAndSortBlueprintEntries,
  getBlueprintActionState,
  getDestructionPreviewLegendItems,
  getDestructionWorkspaceViewModel,
  getHistoryMetrics,
  getSharedModeViewModel,
  getToolbarActions,
} from './viewModel';

const makeField = (
  overrides: Partial<UiField> & Pick<UiField, 'id'>,
): UiField => ({
  id: overrides.id,
  label: overrides.label || overrides.id,
  kind: overrides.kind || 'boolean',
  value: overrides.value ?? false,
  options: overrides.options,
  min: overrides.min,
  max: overrides.max,
  step: overrides.step,
  description: overrides.description,
  placeholder: overrides.placeholder,
  group: overrides.group,
  visible: overrides.visible,
  disabled: overrides.disabled,
  required: overrides.required,
  validate_hint: overrides.validate_hint,
});

const makeHistoryEntry = (overrides: Partial<HistoryEntry>): HistoryEntry => ({
  time: overrides.time || '12:00',
  generator_id: overrides.generator_id || 'blueprint_stamp',
  result: overrides.result || 'success',
  created_count: overrides.created_count ?? 0,
  deleted_count: overrides.deleted_count ?? 0,
  center_turf: overrides.center_turf || '1,1,1',
  duration_ms: overrides.duration_ms ?? 0,
  params_short: overrides.params_short || '',
  message: overrides.message || '',
  undo_policy: overrides.undo_policy,
  undo_status: overrides.undo_status,
  reverted_count: overrides.reverted_count,
  skipped_count: overrides.skipped_count,
  operation_id: overrides.operation_id,
  source_operation_id: overrides.source_operation_id,
  source_generator_id: overrides.source_generator_id,
});

const BASE_BACKEND_DATA: BackendData = {
  categories: [],
  has_generator: true,
  current_generator_id: 'blueprint_stamp',
  current_generator_name: 'Blueprint',
  current_generator_category: 'Tools',
  current_generator_description: '',
  current_generator_execution_mode: '',
  current_generator_required_rights: '',
  current_generator_supports_preview: true,
  requires_preview_before_apply: false,
  current_params_text: '',
  ui_fields: [],
  runtime_status: [],
  placement_supported: true,
  placement_active: false,
  placement_mode: 'single',
  placement_mode_options: [],
  placement_shape_supported: true,
  placement_shape: 'point',
  placement_shape_options: [],
  placement_shape_fields: [],
  placement_shape_uses_anchor_pair: false,
  placement_interaction_kind: '',
  placement_interaction_label: '',
  placement_collector_point_count: 0,
  placement_collector_min_points: 0,
  placement_collector_max_points: 0,
  placement_collector_origin: '',
  placement_collector_points_text: '',
  placement_collector_summary: '',
  can_finish_placement_collection: false,
  placement_supports_direction: true,
  placement_dir: 'North',
  placement_dir_uses_facing: false,
  placement_dir_options: [],
  placement_anchor: undefined,
  placement_hover: undefined,
  placement_preview_shape_tiles: 0,
  placement_preview_effect_tiles: 0,
  can_start_placement_mode: true,
  can_manage_presets: false,
  preset_entries: [],
  blueprint_entries: [],
  active_blueprint_id: undefined,
  can_save_blueprint_from_plan: false,
  confirm_before_apply: false,
  last_ui_error: '',
  preview_valid: false,
  preview_success: false,
  preview_message: '',
  preview_meta: {},
  last_apply_success: false,
  last_apply_message: '',
  last_undo_success: false,
  last_undo_message: '',
  last_undo_action: undefined,
  last_changeset: undefined,
  click_mode_active: false,
  can_run_preview: true,
  can_run_apply: true,
  can_stop_click_mode: true,
  can_undo_last_operation: true,
  can_cleanup_last_owned_effects: false,
  can_refresh_ui: true,
  history_entries: [],
};

const makeData = (overrides: Partial<BackendData> = {}): BackendData => ({
  ...BASE_BACKEND_DATA,
  ...overrides,
});

describe('WorldEditPanel view model', () => {
  it('builds grouped fields and tool tabs for the page entry model', () => {
    const data = makeData({
      categories: [
        {
          category: 'Tools',
          generators: [
            {
              id: 'destruction_pack',
              name_ru: 'Разрушение',
              description_ru: '',
              execution_mode: '',
              required_rights: '',
              supports_preview: true,
            },
          ],
        },
      ],
      ui_fields: [
        makeField({ id: 'a', group: 'First' }),
        makeField({ id: 'b', group: 'Second' }),
      ],
    });

    const model = buildWorldEditViewModel(data);

    expect(model.showPlacementSetup).toBe(true);
    expect(model.groupNames).toEqual(['First', 'Second']);
    expect(model.groupedFields.First.map((field) => field.id)).toEqual(['a']);
    expect(model.toolTabs.map((tab) => tab.id)).toEqual(['destruction_pack']);
  });

  it('derives toolbar actions from preview and placement state', () => {
    const actions = getToolbarActions(
      makeData({
        preview_valid: true,
        placement_supported: true,
        placement_shape_supported: true,
        placement_supports_direction: true,
      }),
    );

    expect(actions.previewAction).toMatchObject({
      action: 'clear_preview',
      color: 'good',
    });
    expect(actions.applyAction).toBeUndefined();
    expect(actions.placementAction).toMatchObject({
      action: 'run_apply',
      label: 'Разм.',
    });
  });

  it('normalizes shared mode shell state and keeps blueprint-specific extras', () => {
    const data = makeData({
      current_generator_id: 'blueprint_stamp',
      placement_shape: 'line',
      placement_shape_options: [],
      placement_dir: 'west',
      ui_fields: [
        makeField({ id: 'stamp_spacing', kind: 'number', value: 3 }),
        makeField({ id: 'radius', kind: 'number', value: 5 }),
      ],
      blueprint_entries: [
        {
          id: 'bp-1',
          name: 'Test',
          entry_count: 1,
          radius: 7,
          created_at: '',
          created_by: '',
          source: '',
          valid: true,
          error: '',
        },
      ],
      active_blueprint_id: 'bp-1',
    });

    const model = getSharedModeViewModel(data, 'editor');

    expect(model.shapeOptions).toEqual([{ value: 'line', label: 'line' }]);
    expect(model.selectedDirection).toBe('west');
    expect(model.showRadiusSection).toBe(true);
    expect(model.sharedFields.map((field) => field.id)).toContain(
      'stamp_spacing',
    );
    expect(model.activeBlueprint?.radius).toBe(7);
    expect(model.radiusToggleFields.map((field) => field.id)).toEqual([
      'radius_only_clear_tiles',
      'radius_only_reachable_tiles',
      'radius_windows_blockers',
    ]);
    expect(model.radiusToggleFields.every((field) => field.disabled)).toBe(
      true,
    );
  });

  it('keeps top radius unique and makes shape radius labels explicit', () => {
    const { getTranslatedFieldLabel } = require('./helpers');
    const model = getSharedModeViewModel(
      makeData({
        current_generator_id: 'outpost_radius',
        ui_fields: [
          makeField({
            id: 'radius',
            kind: 'number',
            value: 5,
          }),
        ],
        placement_shape_fields: [
          makeField({
            id: 'radius',
            kind: 'number',
            value: 5,
          }),
          makeField({
            id: 'shape_radius',
            kind: 'number',
            value: 3,
          }),
          makeField({
            id: 'shape_radius_x',
            kind: 'number',
            value: 4,
          }),
          makeField({
            id: 'shape_radius_y',
            kind: 'number',
            value: 2,
          }),
        ],
      }),
      'editor',
    );

    expect(model.showRadiusSection).toBe(true);
    expect(model.sharedFields.map((field) => field.id)).toEqual([
      'shape_radius',
      'shape_radius_x',
      'shape_radius_y',
    ]);
    expect(
      model.sharedFields.map((field) => getTranslatedFieldLabel(field)),
    ).toEqual(['Радиус формы', 'Горизонтальный радиус', 'Вертикальный радиус']);
  });

  it('surfaces radius policy toggles only in the shared radius chrome', () => {
    const model = getSharedModeViewModel(
      makeData({
        current_generator_id: 'destruction_pack',
        ui_fields: [
          makeField({
            id: 'radius',
            kind: 'number',
            value: 3,
            group: 'Area',
          }),
          makeField({
            id: 'radius_only_clear_tiles',
            value: true,
            group: 'Area',
          }),
          makeField({
            id: 'radius_only_reachable_tiles',
            value: false,
            group: 'Area',
          }),
          makeField({
            id: 'radius_windows_blockers',
            value: true,
            group: 'Area',
          }),
        ],
        placement_shape_fields: [
          makeField({
            id: 'shape_radius',
            kind: 'number',
            value: 2,
          }),
        ],
      }),
      'editor',
    );

    expect(model.showRadiusSection).toBe(true);
    expect(model.radiusToggleFields.map((field) => field.id)).toEqual([
      'radius_only_clear_tiles',
      'radius_only_reachable_tiles',
      'radius_windows_blockers',
    ]);
    expect(model.sharedFields.map((field) => field.id)).toEqual([
      'shape_radius',
    ]);
  });

  it('keeps tool-specific radius labels distinct in the shared controller', () => {
    const { getTranslatedFieldLabel } = require('./helpers');

    expect(
      getTranslatedFieldLabel(
        makeField({
          id: 'radius',
          kind: 'number',
          label: 'Perimeter Offset',
          value: 2,
        }),
      ),
    ).toBe('Отступ периметра');

    expect(
      getTranslatedFieldLabel(
        makeField({
          id: 'radius',
          kind: 'number',
          label: 'Impact Radius',
          value: 3,
        }),
      ),
    ).toBe('Радиус воздействия');
  });

  it('exposes the full shared shape catalog for outpost and destruction tools', () => {
    const shapeOptions = PLACEMENT_SHAPE_ORDER.map((shapeId) => ({
      value: shapeId,
      label: shapeId,
    }));

    for (const generatorId of ['outpost_radius', 'destruction_pack']) {
      const shared = getSharedModeViewModel(
        makeData({
          current_generator_id: generatorId,
          placement_shape_supported: true,
          placement_shape: 'sector',
          placement_shape_options: shapeOptions,
          placement_supports_direction: true,
        }),
        'editor',
      );

      expect(shared.showShapeSection).toBe(true);
      expect(shared.shapeOptions.map((option) => `${option.value}`)).toEqual(
        PLACEMENT_SHAPE_ORDER,
      );
      expect(shared.showDirectionSection).toBe(true);
      expect(shared.selectedShape).toBe('sector');
    }
  });

  it('keeps direction chrome visible but disabled-ready for unsupported tools', () => {
    const data = makeData({
      current_generator_id: 'destruction_pack',
      placement_supported: false,
      placement_shape_supported: false,
      placement_supports_direction: false,
    });

    const shared = getSharedModeViewModel(data, 'editor');

    expect(shared.showShapeSection).toBe(false);
    expect(shared.showModeSection).toBe(false);
    expect(shared.showDirectionSection).toBe(true);
    expect(shared.hasTopControls).toBe(true);
  });

  it('falls back to valid placement mode choices when backend sends garbage', () => {
    const shared = getSharedModeViewModel(
      makeData({
        current_generator_id: 'destruction_pack',
        placement_supported: true,
        placement_mode: '0',
        placement_mode_options: [
          {
            value: '0',
            label: '0',
          },
        ],
      }),
      'editor',
    );

    expect(shared.modeOptions).toEqual([
      {
        value: 'single',
        displayText: '1 раз',
        tooltip: 'Один раз',
      },
      {
        value: 'repeat',
        displayText: 'Повт.',
        tooltip: 'Повторять',
      },
    ]);
    expect(shared.selectedMode).toBe('single');
  });

  it('sorts blueprint entries by activity and tracks activation state', () => {
    const data = makeData({
      active_blueprint_id: 'bp-2',
      preview_valid: true,
      can_run_apply: true,
      blueprint_entries: [
        {
          id: 'bp-1',
          name: 'Alpha',
          entry_count: 4,
          radius: 3,
          created_at: '2026-04-10',
          created_by: '',
          source: '',
          valid: true,
          error: '',
        },
        {
          id: 'bp-2',
          name: 'Bravo',
          entry_count: 2,
          radius: 2,
          created_at: '2026-04-12',
          created_by: '',
          source: '',
          valid: true,
          error: '',
        },
        {
          id: 'bp-3',
          name: 'Corrupt',
          entry_count: 9,
          radius: 6,
          created_at: '2026-04-11',
          created_by: '',
          source: '',
          valid: false,
          error: 'broken',
        },
      ],
    });

    const sorted = filterAndSortBlueprintEntries(
      data,
      data.blueprint_entries,
      'all',
      'activity',
    );
    const activeState = getBlueprintActionState(data, sorted[0]);
    const inactiveState = getBlueprintActionState(data, sorted[1]);
    const invalidState = getBlueprintActionState(data, sorted[2]);

    expect(sorted.map((entry) => entry.id)).toEqual(['bp-2', 'bp-1', 'bp-3']);
    expect(activeState).toMatchObject({
      isActive: true,
      canLoad: false,
      canPreview: true,
      canApply: true,
    });
    expect(inactiveState).toMatchObject({
      isActive: false,
      canLoad: true,
      canPreview: true,
      canApply: false,
    });
    expect(invalidState).toMatchObject({
      canLoad: false,
      canPreview: false,
      canApply: false,
    });
  });

  it('uses preview meta to derive destruction legend state', () => {
    const items = getDestructionPreviewLegendItems(
      makeData({
        preview_valid: true,
        preview_meta: {
          moved_count: 2,
          fire_count: 0,
          damage_count: 1,
          blast_count: 3,
        },
        ui_fields: [
          makeField({ id: 'persistent_fire_enabled', value: true }),
          makeField({ id: 'blast_enabled', value: false }),
          makeField({
            id: 'damage_profile',
            kind: 'select',
            value: 'none',
          }),
        ],
      }),
    );

    expect(items.map((item) => item.label)).toEqual([
      'Перемещение',
      'Урон',
      'Взрыв',
    ]);
  });

  it('partitions destruction fields and hides invisible scatter steps', () => {
    const model = getDestructionWorkspaceViewModel(
      makeData({
        ui_fields: [
          makeField({ id: 'radius', kind: 'number', value: 3, group: 'Area' }),
          makeField({
            id: 'radius_only_clear_tiles',
            group: 'Area',
            value: true,
          }),
          makeField({
            id: 'radius_only_reachable_tiles',
            group: 'Area',
            value: false,
          }),
          makeField({
            id: 'radius_windows_blockers',
            group: 'Area',
            value: true,
          }),
          makeField({ id: 'safe', group: 'Area' }),
          makeField({ id: 'shuffle_enabled', value: true }),
          makeField({ id: 'scatter_enabled', value: true }),
          makeField({ id: 'max_atoms', kind: 'number', value: 10 }),
          makeField({
            id: 'scatter_steps',
            kind: 'number',
            value: 2,
            visible: false,
          }),
          makeField({ id: 'persistent_fire_enabled', value: false }),
          makeField({
            id: 'persistent_fire_density',
            kind: 'number',
            value: 10,
          }),
          makeField({ id: 'blast_enabled', value: false }),
          makeField({ id: 'blast_power', kind: 'number', value: 100 }),
          makeField({ id: 'blast_falloff', kind: 'number', value: 200 }),
          makeField({
            id: 'damage_profile',
            kind: 'select',
            value: 'none',
          }),
        ],
      }),
    );

    expect(model.areaFields.map((field) => field.id)).toEqual(['safe']);
    expect(
      model.movementFields.visibleMovementFields.map((field) => field.id),
    ).toEqual(['shuffle_enabled', 'scatter_enabled', 'max_atoms']);
    expect(model.movementFields.scatterStepsField).toBeUndefined();
  });

  it('counts history entries by tone buckets', () => {
    const metrics = getHistoryMetrics([
      makeHistoryEntry({ result: 'success' }),
      makeHistoryEntry({ result: 'warning' }),
      makeHistoryEntry({ result: 'error' }),
      makeHistoryEntry({ result: 'success' }),
    ]);

    expect(metrics).toEqual({
      total: 4,
      good: 2,
      average: 1,
      bad: 1,
    });
  });

  it('surfaces tactical profile and perimeter material labels without profile semantics', () => {
    const { getTranslatedFieldLabel, translateOptionLabel } = require('./helpers');

    expect(
      getTranslatedFieldLabel(makeField({ id: 'family' })),
    ).toBe('Тактический профиль');
    expect(
      getTranslatedFieldLabel(makeField({ id: 'defense_profile' })),
    ).toBe('Тактический профиль');
    expect(
      getTranslatedFieldLabel(makeField({ id: 'layout_variant' })),
    ).toBe('Схема');
    expect(getTranslatedFieldLabel(makeField({ id: 'barricade_path' }))).toBe(
      'Основной материал',
    );
    expect(
      getTranslatedFieldLabel(
        makeField({ id: 'primary_material_path' }),
      ),
    ).toBe('Основной материал');
    expect(
      getTranslatedFieldLabel(
        makeField({ id: 'secondary_material_path' }),
      ),
    ).toBe('Вспомогательный материал');
    expect(
      getTranslatedFieldLabel(makeField({ id: 'primary_door_path' })),
    ).toBe('Основные двери');
    expect(
      getTranslatedFieldLabel(makeField({ id: 'secondary_door_path' })),
    ).toBe('Вспомогательные двери');
    expect(
      getTranslatedFieldLabel(
        makeField({ id: 'barricade_concentration_percent', kind: 'number' }),
      ),
    ).toBe('Доля основного материала');
    expect(
      getTranslatedFieldLabel(makeField({ id: 'place_barricade_doors' })),
    ).toBe('Двери в проходах');
    expect(
      translateOptionLabel('family', '', 'mixed_standard'),
    ).toBe('Сбалансированный опорник');
    expect(
      translateOptionLabel('defense_profile', '', 'mixed_standard'),
    ).toBe('Сбалансированный опорник');
    expect(
      translateOptionLabel('barricade_pattern', '', 'uniform'),
    ).toBe('Единый материал');
    expect(
      translateOptionLabel('barricade_pattern', '', 'alternating'),
    ).toBe('Чередование');
    expect(
      translateOptionLabel('barricade_pattern', '', 'paired'),
    ).toBe('Парные секции');
    expect(
      translateOptionLabel('barricade_pattern', '', 'profile'),
    ).toBe('По материалам');
  });
});
