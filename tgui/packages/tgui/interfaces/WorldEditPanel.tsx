import { useMemo, useState } from 'react';

import { useBackend } from '../backend';
import {
  Box,
  Button,
  Dropdown,
  Input,
  LabeledList,
  NoticeBox,
  NumberInput,
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

const PAGES = [
  { title: 'Генераторы', icon: 'list' },
  { title: 'Setup', icon: 'sliders-h' },
  { title: 'Run', icon: 'play' },
  { title: 'История', icon: 'history' },
];

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

const BlueprintLibrarySection = (props: {
  readonly data: BackendData;
  readonly act: (action: string, payload?: Record<string, unknown>) => void;
}) => {
  const { data, act } = props;

  return (
    <Section title="Blueprint Library">
      <Stack mb={1}>
        <Stack.Item>
          <Button onClick={() => act('list_blueprints')}>
            Обновить библиотеку
          </Button>
        </Stack.Item>
      </Stack>

      {!!data.placement_active && (
        <Box color="average" mb={1}>
          Library actions временно заблокированы, пока активен placement mode.
        </Box>
      )}

      {!data.blueprint_entries?.length && (
        <Box color="label">В библиотеке пока нет blueprint-ов.</Box>
      )}

      {!!data.blueprint_entries?.length && (
        <Stack vertical>
          {data.blueprint_entries.map((blueprint) => (
            <Section
              key={blueprint.id}
              title={`${blueprint.name} [r=${blueprint.radius}]`}
            >
              {!!blueprint.active && (
                <Box color="good">
                  Активный blueprint для текущего менеджера.
                </Box>
              )}
              <Box color="label">
                Entries: {blueprint.entry_count} | Source:{' '}
                {blueprint.source || 'n/a'} | Author:{' '}
                {blueprint.created_by || 'n/a'}
              </Box>
              <Box color="label">Создан: {blueprint.created_at || 'n/a'}</Box>

              {!blueprint.valid && (
                <NoticeBox danger>
                  {blueprint.error || 'Blueprint невалиден.'}
                </NoticeBox>
              )}

              <Stack mt={1}>
                <Stack.Item>
                  <Button
                    disabled={!blueprint.valid || data.placement_active}
                    onClick={() =>
                      act('load_blueprint', {
                        blueprint_id: blueprint.id,
                      })
                    }
                  >
                    Загрузить
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    disabled={!blueprint.valid || data.placement_active}
                    onClick={() =>
                      act('preview_blueprint', {
                        blueprint_id: blueprint.id,
                      })
                    }
                  >
                    Preview
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    disabled={
                      !blueprint.valid ||
                      data.placement_active ||
                      !blueprint.active ||
                      !data.preview_valid
                    }
                    onClick={() =>
                      act('apply_blueprint', {
                        blueprint_id: blueprint.id,
                      })
                    }
                  >
                    Apply
                  </Button>
                </Stack.Item>
              </Stack>
            </Section>
          ))}
        </Stack>
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
    <Section title="Blueprint Export">
      <Box color="label" mb={1}>
        Для `outpost_radius` можно сохранить текущий preview как Blueprint Lite.
      </Box>
      <Button
        disabled={!data.can_save_blueprint_from_plan}
        onClick={() => act('save_blueprint')}
      >
        Сохранить из outpost preview
      </Button>
    </Section>
  );
};

const PlacementSetupSection = (props: {
  readonly data: BackendData;
  readonly act: (action: string, payload?: Record<string, unknown>) => void;
}) => {
  const { data, act } = props;

  return (
    <Section title="Placement Setup">
      <LabeledList>
        {data.placement_shape_supported && (
          <LabeledList.Item label="Shape">
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
          <LabeledList.Item label="Placement mode">
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
              onSelected={(value) => act('set_placement_mode', { mode: value })}
            />
          </LabeledList.Item>
        )}

        {data.placement_supports_direction && (
          <LabeledList.Item label="Direction">
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

        <LabeledList.Item label="Status">
          {data.placement_active ? 'active' : 'inactive'}
        </LabeledList.Item>
        <LabeledList.Item label="Interaction">
          {data.placement_interaction_label || 'Single Click'}
        </LabeledList.Item>
        <LabeledList.Item label="Rollout">
          {data.placement_shape_rollout_stage || 'v1'}
        </LabeledList.Item>
        {!!data.placement_interaction_kind &&
          data.placement_interaction_kind === 'collector' && (
            <>
              <LabeledList.Item label="Collector summary">
                {data.placement_collector_summary || 'n/a'}
              </LabeledList.Item>
              <LabeledList.Item label="Collector points">
                {`${data.placement_collector_point_count || 0}/${
                  data.placement_collector_max_points || 0
                }`}
              </LabeledList.Item>
              <LabeledList.Item label="Collector origin">
                {data.placement_collector_origin || 'none'}
              </LabeledList.Item>
              <LabeledList.Item label="Collected text">
                {data.placement_collector_points_text || 'n/a'}
              </LabeledList.Item>
            </>
          )}

        <LabeledList.Item label="Pending anchor">
          {data.placement_anchor || 'none'}
        </LabeledList.Item>
      </LabeledList>

      {!!data.placement_shape_fields?.length && (
        <Section title="Shape Parameters" mt={1}>
          <LabeledList>
            {data.placement_shape_fields.map((field) => (
              <FieldEditor key={field.id} field={field} act={act} />
            ))}
          </LabeledList>
        </Section>
      )}

      <Box color="label" mt={1}>
        Запуск и остановка placement mode находятся на вкладке `Run`.
      </Box>
    </Section>
  );
};

const SetupPage = (props: {
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
    <Section fill scrollable title="Настройка генератора">
      {!data.has_generator && (
        <Box color="label">
          Сначала выберите генератор на вкладке &quot;Генераторы&quot;.
        </Box>
      )}

      {!!data.has_generator && (
        <>
          <Section title="Generator Summary">
            <Box>
              {data.current_generator_category} / {data.current_generator_name}
            </Box>
            <Box color="label">{data.current_generator_description}</Box>
            <Box color="label">
              Права: {data.current_generator_required_rights} | Режим:{' '}
              {data.current_generator_execution_mode}
            </Box>
            <Box color="label">
              Источник параметров:{' '}
              {data.ui_mode === 'inline' ? 'inline' : 'wizard fallback'}
            </Box>
          </Section>

          {!!data.last_ui_error && (
            <NoticeBox danger>{data.last_ui_error}</NoticeBox>
          )}

          <Section title="Generator Tools">
            <Stack>
              <Stack.Item>
                <Button
                  disabled={!data.can_refresh_ui}
                  onClick={() => act('refresh_ui')}
                >
                  Обновить параметры генератора
                </Button>
              </Stack.Item>
              <Stack.Item>
                <Button onClick={() => act('configure_wizard')}>
                  Открыть мастер настройки
                </Button>
              </Stack.Item>
              <Stack.Item>
                <Button color="average" onClick={() => act('reset_generator')}>
                  Сбросить генератор
                </Button>
              </Stack.Item>
            </Stack>
          </Section>

          {!!data.can_manage_presets && (
            <Section title="Presets">
              <Stack mb={1}>
                <Stack.Item>
                  <Button onClick={() => act('save_preset')}>
                    Сохранить preset
                  </Button>
                </Stack.Item>
              </Stack>

              {!data.preset_entries?.length && (
                <Box color="label">
                  Для текущего генератора ещё нет сохранённых preset-ов.
                </Box>
              )}

              {!!data.preset_entries?.length && (
                <Stack vertical>
                  {data.preset_entries.map((preset) => (
                    <Section key={preset.id} title={preset.name || preset.id}>
                      <Box color="label">
                        Сохранён: {preset.created_at || 'n/a'}
                      </Box>
                      <Box color="label">Параметры: {preset.params_short}</Box>
                      <Stack mt={1}>
                        <Stack.Item>
                          <Button
                            onClick={() =>
                              act('load_preset', {
                                preset_id: preset.id,
                              })
                            }
                          >
                            Загрузить
                          </Button>
                        </Stack.Item>
                        <Stack.Item>
                          <Button
                            color="average"
                            onClick={() =>
                              act('delete_preset', {
                                preset_id: preset.id,
                              })
                            }
                          >
                            Удалить
                          </Button>
                        </Stack.Item>
                      </Stack>
                    </Section>
                  ))}
                </Stack>
              )}
            </Section>
          )}

          {showBlueprintExport && (
            <BlueprintExportSection data={data} act={act} />
          )}
          {showBlueprintLibrary && (
            <BlueprintLibrarySection data={data} act={act} />
          )}

          {showPlacementSetup && (
            <PlacementSetupSection data={data} act={act} />
          )}

          <Section title="Parameters">
            {!data.has_inline_fields && (
              <Box color="label">
                Этот генератор не отдает inline-поля. Используйте мастер
                настройки.
              </Box>
            )}

            {!!data.has_inline_fields && !groupNames.length && (
              <Box color="label">Inline-поля временно недоступны.</Box>
            )}

            {!!data.has_inline_fields &&
              groupNames.map((groupName) => {
                const fields = groupedFields[groupName] || [];
                return (
                  <Section key={groupName} title={groupName}>
                    <LabeledList>
                      {fields.map((field) => (
                        <FieldEditor key={field.id} field={field} act={act} />
                      ))}
                    </LabeledList>
                  </Section>
                );
              })}
          </Section>

          <Section title="Diagnostics">
            <Section title="Текущие параметры">
              <Box>{data.current_params_text}</Box>
            </Section>

            <Section title="Runtime-статус">
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
            </Section>
          </Section>
        </>
      )}
    </Section>
  );
};

const RunPage = (props: {
  readonly data: BackendData;
  readonly act: (action: string, payload?: Record<string, unknown>) => void;
}) => {
  const { data, act } = props;

  return (
    <Section fill scrollable title="Run">
      <Section title="Primary Actions">
        <Stack>
          <Stack.Item>
            <Button
              disabled={!data.can_run_preview}
              onClick={() => act('run_preview')}
            >
              Запустить preview
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button
              disabled={!data.can_run_apply}
              onClick={() => act('run_apply')}
            >
              Применить генератор
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button
              color="average"
              disabled={!data.has_generator}
              onClick={() => act('clear_preview')}
            >
              Очистить preview
            </Button>
          </Stack.Item>
        </Stack>
      </Section>

      <Section title="Placement Session">
        <Stack>
          <Stack.Item>
            <Button
              disabled={!data.can_start_placement_mode}
              onClick={() => act('start_placement_mode')}
            >
              Start placement mode
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button
              color="average"
              disabled={!data.can_stop_click_mode}
              onClick={() => act('stop_click_mode')}
            >
              Остановить click-режим
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button
              disabled={!data.can_finish_placement_collection}
              onClick={() => act('finish_placement_collection')}
            >
              Apply collected shape
            </Button>
          </Stack.Item>
        </Stack>

        {(data.placement_supported ||
          data.placement_shape_supported ||
          data.placement_supports_direction) && (
          <Box color="label" mt={1}>
            {data.placement_interaction_kind === 'anchor_pair'
              ? 'LMB ставит первую точку, второй LMB выполняет preview/apply, MMB сбрасывает pending anchor.'
              : data.placement_interaction_kind === 'collector'
                ? 'LMB добавляет точки, MMB удаляет последнюю, а RMB или кнопка Apply collected shape подтверждают и применяют готовый footprint.'
                : data.placement_interaction_kind === 'param_only'
                  ? 'LMB использует выбранный turf как anchor, а footprint берется из текущих параметров shape. Interactive point collection пока не входит в этот проход.'
                  : 'LMB выполняет preview/apply по выбранному turf. Для выхода используйте Stop click-mode.'}
          </Box>
        )}
      </Section>

      <Section title="Ready State">
        <LabeledList>
          <LabeledList.Item label="Generator">
            {data.current_generator_name || 'none'}
          </LabeledList.Item>
          <LabeledList.Item label="Preview required">
            {data.requires_preview_before_apply ? 'yes' : 'no'}
          </LabeledList.Item>
          <LabeledList.Item label="Preview valid">
            {data.preview_valid ? 'yes' : 'no'}
          </LabeledList.Item>
          <LabeledList.Item label="Click mode">
            {data.click_mode_active ? 'active' : 'inactive'}
          </LabeledList.Item>
          <LabeledList.Item label="Interaction">
            {data.placement_interaction_label || 'Single Click'}
          </LabeledList.Item>
          {data.placement_interaction_kind === 'collector' && (
            <>
              <LabeledList.Item label="Collector points">
                {`${data.placement_collector_point_count || 0}/${
                  data.placement_collector_min_points || 0
                }`}
              </LabeledList.Item>
              <LabeledList.Item label="Collector ready">
                {data.can_finish_placement_collection ? 'yes' : 'no'}
              </LabeledList.Item>
            </>
          )}
          {(data.placement_supported || data.placement_shape_supported) && (
            <LabeledList.Item label="Placement mode">
              {data.placement_mode || 'n/a'}
            </LabeledList.Item>
          )}
          {data.placement_shape_supported && (
            <LabeledList.Item label="Shape">
              {data.placement_shape || 'n/a'}
            </LabeledList.Item>
          )}
          {data.placement_supports_direction && (
            <LabeledList.Item label="Direction">
              {data.placement_dir || 'n/a'}
            </LabeledList.Item>
          )}
          <LabeledList.Item label="Pending anchor">
            {data.placement_anchor || 'none'}
          </LabeledList.Item>
          <LabeledList.Item label="Active blueprint">
            {data.active_blueprint_id || 'none'}
          </LabeledList.Item>
        </LabeledList>
      </Section>

      <Section title="Preview State">
        <Box>
          Статус: {data.preview_success ? 'успех' : 'ошибка/нет'} | Валиден для
          apply: {data.preview_valid ? 'да' : 'нет'}
        </Box>
        <Box color={data.preview_success ? 'good' : 'average'}>
          {data.preview_message || 'Нет данных preview.'}
        </Box>
      </Section>

      <Section title="Preview Meta">
        {!data.preview_meta || !Object.keys(data.preview_meta).length ? (
          <Box color="label">Meta отсутствует.</Box>
        ) : (
          <LabeledList>
            {Object.entries(data.preview_meta).map(([key, value]) => (
              <LabeledList.Item key={key} label={key}>
                {`${value}`}
              </LabeledList.Item>
            ))}
          </LabeledList>
        )}
      </Section>

      <Section title="Session Operations">
        <Stack mb={1}>
          <Stack.Item>
            <Button
              color="average"
              disabled={!data.can_undo_last_operation}
              onClick={() => act('undo_last_operation')}
            >
              Undo last operation
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button
              color="average"
              disabled={!data.can_cleanup_last_owned_effects}
              onClick={() => act('cleanup_last_owned_effects')}
            >
              Cleanup owned effects
            </Button>
          </Stack.Item>
        </Stack>

        <Section title="Последний apply">
          <Box color={data.last_apply_success ? 'good' : 'average'}>
            {data.last_apply_message || 'Операции apply еще не выполнялись.'}
          </Box>
        </Section>

        <Section title="Последняя записанная операция">
          {!data.last_changeset && (
            <Box color="label">
              Undo/cleanup-record для текущей session пока отсутствует.
            </Box>
          )}

          {!!data.last_changeset && (
            <>
              <Box>
                Generator: {data.last_changeset.generator_id} | Policy:{' '}
                {data.last_changeset.undo_policy} | Status:{' '}
                {data.last_changeset.undo_status}
              </Box>
              <Box color="label">
                Operation ID: {data.last_changeset.operation_id}
              </Box>
              <Box color="label">
                Created refs: {data.last_changeset.created_entries} | Moved
                refs: {data.last_changeset.moved_entries} | Owned effects:{' '}
                {data.last_changeset.owned_effect_entries}
              </Box>
            </>
          )}
        </Section>

        <Section title="Последний undo / cleanup">
          <Box color={data.last_undo_success ? 'good' : 'average'}>
            {data.last_undo_message ||
              'Undo/cleanup действия еще не выполнялись.'}
          </Box>
          {!!data.last_undo_action && (
            <Box color="label">Тип действия: {data.last_undo_action}</Box>
          )}
        </Section>
      </Section>
    </Section>
  );
};

export const WorldEditPanel = () => {
  const { data, act } = useBackend<BackendData>();
  const [pageIndex, setPageIndex] = useState(0);

  const currentPage = PAGES[pageIndex]?.title || PAGES[0].title;
  const isBlueprintStamp = data.current_generator_id === 'blueprint_stamp';
  const showBlueprintExport = data.current_generator_id === 'outpost_radius';
  const showBlueprintLibrary = isBlueprintStamp;
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
    <Window title="World Edit Panel" width={1040} height={780}>
      <Window.Content>
        <Stack fill>
          <Stack.Item>
            <Section fitted>
              <Tabs vertical>
                {PAGES.map((page, index) => (
                  <Tabs.Tab
                    key={page.title}
                    selected={index === pageIndex}
                    icon={page.icon}
                    onClick={() => setPageIndex(index)}
                  >
                    {page.title}
                  </Tabs.Tab>
                ))}
              </Tabs>
            </Section>
          </Stack.Item>

          <Stack.Item grow basis={0} ml={1}>
            {currentPage === 'Генераторы' && (
              <Section
                fill
                scrollable
                title="Каталог генераторов (status=ready)"
              >
                {!data.categories?.length && (
                  <Box color="label">
                    Нет доступных генераторов для текущих прав.
                  </Box>
                )}
                {data.categories?.map((category) => (
                  <Section key={category.category} title={category.category}>
                    <Stack vertical>
                      {category.generators.map((generator) => (
                        <Stack.Item key={generator.id}>
                          <Button
                            fluid
                            selected={
                              generator.id === data.current_generator_id
                            }
                            onClick={() =>
                              act('select_generator', {
                                generator_id: generator.id,
                              })
                            }
                          >
                            {generator.name_ru} [{generator.execution_mode}]
                          </Button>
                          <Box color="label" mt={0.5}>
                            {generator.description_ru}
                          </Box>
                          <Box color="label">
                            Права: {generator.required_rights} | Preview:{' '}
                            {generator.supports_preview ? 'да' : 'нет'} |
                            Статус: {generator.status}
                          </Box>
                        </Stack.Item>
                      ))}
                    </Stack>
                  </Section>
                ))}
              </Section>
            )}

            {currentPage === 'Setup' && (
              <SetupPage
                data={data}
                act={act}
                groupedFields={groupedFields}
                groupNames={groupNames}
                showBlueprintExport={showBlueprintExport}
                showBlueprintLibrary={showBlueprintLibrary}
                showPlacementSetup={showPlacementSetup}
              />
            )}

            {currentPage === 'Run' && <RunPage data={data} act={act} />}

            {currentPage === 'История' && (
              <Section fill scrollable title="История операций (session)">
                <Stack mb={1}>
                  <Stack.Item>
                    <Button
                      color="average"
                      onClick={() => act('clear_history')}
                    >
                      Очистить историю
                    </Button>
                  </Stack.Item>
                </Stack>

                {!data.history_entries?.length && (
                  <Box color="label">История операций пуста.</Box>
                )}

                {!!data.history_entries?.length && (
                  <Stack vertical fill>
                    {data.history_entries.map((entry, index) => (
                      <Section
                        key={`${entry.time}_${entry.generator_id}_${index}`}
                        title={`${entry.time} | ${entry.generator_id} | ${entry.result}`}
                      >
                        <Box>
                          Создано: {entry.created_count} | Удалено:{' '}
                          {entry.deleted_count} | Центр: {entry.center_turf} |
                          Длительность: {entry.duration_ms} ms
                        </Box>
                        {!!entry.undo_policy && (
                          <Box color="label">
                            Undo policy: {entry.undo_policy} | Undo status:{' '}
                            {entry.undo_status || 'n/a'}
                          </Box>
                        )}
                        {(typeof entry.reverted_count === 'number' ||
                          typeof entry.skipped_count === 'number') && (
                          <Box color="label">
                            Reverted: {entry.reverted_count ?? 0} | Skipped:{' '}
                            {entry.skipped_count ?? 0}
                          </Box>
                        )}
                        <Box color="label">Параметры: {entry.params_short}</Box>
                        <Box color="label">
                          Сообщение: {entry.message || 'n/a'}
                        </Box>
                      </Section>
                    ))}
                  </Stack>
                )}
              </Section>
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
