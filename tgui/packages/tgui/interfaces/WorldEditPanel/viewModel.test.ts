import type { BackendData, HistoryEntry, UiField } from './types';
import {
  buildWorldEditViewModel,
  getDestructionPreviewLegendItems,
  getDestructionWorkspaceViewModel,
  getHistoryMetrics,
  getSharedModeViewModel,
  getToolbarActions,
} from './viewModel';

const makeField = (overrides: Partial<UiField> & Pick<UiField, 'id'>): UiField => ({
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

const makeHistoryEntry = (
  overrides: Partial<HistoryEntry>,
): HistoryEntry => ({
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
  current_generator_status: '',
  current_generator_supports_preview: true,
  requires_preview_before_apply: false,
  current_params_text: '',
  ui_fields: [],
  has_inline_fields: false,
  ui_mode: 'inline',
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
  placement_shape_rollout_stage: '',
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
              status: '',
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
      label: 'Разместить',
    });
  });

  it('normalizes shared mode shell state and keeps blueprint-specific extras', () => {
    const data = makeData({
      current_generator_id: 'blueprint_stamp',
      placement_shape: 'line',
      placement_shape_options: [],
      placement_dir: 'West',
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
    expect(model.sharedFields.map((field) => field.id)).toContain('stamp_spacing');
    expect(model.activeBlueprint?.radius).toBe(7);
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
          makeField({ id: 'persistent_fire_density', kind: 'number', value: 10 }),
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
    expect(model.movementFields.visibleMovementFields.map((field) => field.id)).toEqual([
      'shuffle_enabled',
      'scatter_enabled',
      'max_atoms',
    ]);
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
});
