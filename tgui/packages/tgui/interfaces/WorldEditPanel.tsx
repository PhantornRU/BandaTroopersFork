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
    return 'LMB задает первую точку, второй LMB завершает линию или рамку. MMB сбрасывает pending anchor.';
  }
  if (data.placement_interaction_kind === 'collector') {
    return 'LMB добавляет точки, MMB снимает последнюю, RMB или finish закрывают собранный footprint.';
  }
  if (data.placement_interaction_kind === 'param_only') {
    return 'Клик использует выбранный turf как anchor, а сама форма берется из текущих shape-параметров.';
  }
  return 'LMB выполняет preview/apply по выбранному turf. Для выхода используйте stop click-mode.';
};

const getPreviewBlockReason = (data: BackendData) => {
  if (!data.has_generator) {
    return 'Сначала выберите генератор.';
  }
  if (!data.current_generator_supports_preview) {
    return 'Текущий генератор не поддерживает preview.';
  }
  if (data.click_mode_active) {
    return 'Preview через панель недоступен, пока активен placement mode.';
  }
  return '';
};

const getApplyBlockReason = (data: BackendData) => {
  if (!data.has_generator) {
    return 'Сначала выберите генератор.';
  }
  if (data.click_mode_active) {
    return 'Apply через панель недоступен, пока активен placement mode.';
  }
  if (data.requires_preview_before_apply && !data.preview_valid) {
    return 'Для текущего генератора нужен валидный preview.';
  }
  return '';
};

const getPlacementBlockReason = (data: BackendData) => {
  if (!data.has_generator) {
    return 'Сначала выберите генератор.';
  }
  if (data.placement_active) {
    return 'Режим размещения уже активен.';
  }
  if (!data.can_start_placement_mode) {
    return 'Текущий генератор не поддерживает live placement.';
  }
  return '';
};

const getFinishCollectionReason = (data: BackendData) => {
  if (!data.click_mode_active) {
    return 'Сначала запустите placement mode.';
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
      label: 'Выбор генератора',
      description: 'Выберите ready-генератор, чтобы открыть рабочую станцию.',
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
            label: 'Форма собрана',
            description:
              'Можно завершить сбор и перейти к preview/apply для собранного footprint.',
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
      description: 'Сначала выполните preview для текущей конфигурации.',
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
      description:
        'Inline-поля недоступны, используйте мастер настройки как основной путь.',
      color: 'label',
    };
  }

  return {
    label: 'Настройка рабочей конфигурации',
    description:
      'Проверьте параметры и placement-настройки, затем переходите к preview/apply.',
    color: 'label',
  };
};

const getPreviewState = (data: BackendData): PreviewState => {
  if (!data.has_generator) {
    return {
      label: 'n/a',
      message: 'Сначала выберите генератор.',
      color: 'label',
    };
  }

  if (data.preview_valid) {
    return {
      label: 'готов',
      message:
        data.preview_message ||
        'Текущая конфигурация прошла preview и готова к apply.',
      color: 'good',
    };
  }

  if (data.preview_success) {
    return {
      label: 'проверен',
      message:
        data.preview_message ||
        'Preview выполнен, но результат пока не готов к apply.',
      color: 'average',
    };
  }

  if (data.preview_message) {
    return {
      label: 'нет/ошибка',
      message: data.preview_message,
      color: 'average',
    };
  }

  return {
    label: 'не запускался',
    message: 'Preview еще не запускался для текущей конфигурации.',
    color: 'label',
  };
};

const getSidebarTiles = (data: BackendData): SummaryTile[] => [
  {
    label: 'Preview',
    value: data.has_generator ? (data.preview_valid ? 'ready' : 'idle') : 'n/a',
    color: data.preview_valid ? 'good' : 'label',
  },
  {
    label: 'Apply',
    value: data.has_generator ? (data.can_run_apply ? 'ready' : 'hold') : 'n/a',
    color: data.can_run_apply
      ? 'good'
      : data.has_generator
        ? 'average'
        : 'label',
  },
  {
    label: 'Ops',
    value: `${data.history_entries?.length || 0}`,
    color: data.history_entries?.length ? 'good' : 'label',
  },
];

const SummaryTileGrid = (props: {
  readonly items: SummaryTile[];
  readonly compact?: boolean;
  readonly tileBasis?: string;
}) => {
  const { items, compact, tileBasis } = props;

  return (
    <Flex wrap mx={-0.25}>
      {items.map((item) => (
        <Flex.Item
          key={item.label}
          basis={tileBasis || (compact ? '31%' : '48%')}
          grow
          m={0.25}
        >
          <Section fitted title={item.label}>
            <Box color={item.color || 'white'}>{item.value}</Box>
          </Section>
        </Flex.Item>
      ))}
    </Flex>
  );
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
  readonly onSelect: () => void;
  readonly onOpenWork: () => void;
}) => {
  const { generator, selected, onSelect, onOpenWork } = props;

  return (
    <LabeledList.Item
      label={<Box color={selected ? 'good' : 'white'}>{generator.name_ru}</Box>}
      buttons={
        <Button
          compact
          selected={selected}
          onClick={selected ? onOpenWork : onSelect}
        >
          {selected ? 'Открыть' : 'Выбрать'}
        </Button>
      }
    >
      <Box color="label">
        {generator.execution_mode} | preview{' '}
        {boolText(generator.supports_preview)} | статус {generator.status}
      </Box>
    </LabeledList.Item>
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
      title="Пресеты"
      buttons={
        <Button compact onClick={() => act('save_preset')}>
          Сохранить
        </Button>
      }
    >
      {!data.preset_entries?.length && (
        <Box color="label">
          Для текущего генератора ещё нет сохранённых preset-ов.
        </Box>
      )}

      {!!data.preset_entries?.length && (
        <>
          <Flex wrap mx={-0.5}>
            {data.preset_entries.map((preset) => (
              <Flex.Item key={preset.id} basis="48%" grow m={0.5}>
                <Button
                  compact
                  fluid
                  selected={preset.id === selectedPreset?.id}
                  onClick={() => setSelectedPresetId(preset.id)}
                >
                  {preset.name || preset.id}
                </Button>
              </Flex.Item>
            ))}
          </Flex>

          {!!selectedPreset && (
            <Section title={selectedPreset.name || selectedPreset.id} mt={1}>
              <Box color="label">
                Сохранён: {selectedPreset.created_at || 'n/a'}
              </Box>
              <Box color="label" mt={0.5}>
                Параметры: {selectedPreset.params_short || 'n/a'}
              </Box>

              <ActionRow>
                <ActionItem>
                  <Button
                    compact
                    onClick={() =>
                      act('load_preset', {
                        preset_id: selectedPreset.id,
                      })
                    }
                  >
                    Загрузить
                  </Button>
                </ActionItem>
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
                    Удалить
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
      title="Библиотека blueprint"
      buttons={
        <Button compact onClick={() => act('list_blueprints')}>
          Обновить
        </Button>
      }
    >
      {!!data.placement_active && (
        <Box color="average" mb={1}>
          Library actions временно заблокированы, пока активен placement mode.
        </Box>
      )}

      {!data.blueprint_entries?.length && (
        <Box color="label">В библиотеке пока нет blueprint-ов.</Box>
      )}

      {!!data.blueprint_entries?.length && (
        <>
          <Flex wrap mx={-0.5}>
            {data.blueprint_entries.map((blueprint) => (
              <Flex.Item key={blueprint.id} basis="48%" grow m={0.5}>
                <Button
                  compact
                  fluid
                  selected={blueprint.id === selectedBlueprint?.id}
                  onClick={() => setSelectedBlueprintId(blueprint.id)}
                >
                  {blueprint.name}
                </Button>
              </Flex.Item>
            ))}
          </Flex>

          {!!selectedBlueprint && (
            <Section
              title={`${selectedBlueprint.name} [r=${selectedBlueprint.radius}]`}
              mt={1}
            >
              {!!selectedBlueprint.active && (
                <Box color="good" mb={1}>
                  Активный blueprint для текущего менеджера.
                </Box>
              )}

              {!selectedBlueprint.valid && (
                <NoticeBox danger>
                  {selectedBlueprint.error || 'Blueprint невалиден.'}
                </NoticeBox>
              )}

              <CompactStatusRow
                basis="32%"
                items={[
                  {
                    label: 'Элементы',
                    value: selectedBlueprint.entry_count,
                  },
                  {
                    label: 'Source',
                    value: selectedBlueprint.source || 'n/a',
                    color: 'label',
                  },
                  {
                    label: 'Author',
                    value: selectedBlueprint.created_by || 'n/a',
                    color: 'label',
                  },
                ]}
              />

              <Box color="label" mt={1}>
                Создан: {selectedBlueprint.created_at || 'n/a'}
              </Box>

              <ActionRow>
                <ActionItem>
                  <Button
                    compact
                    disabled={!selectedBlueprint.valid || data.placement_active}
                    onClick={() =>
                      act('load_blueprint', {
                        blueprint_id: selectedBlueprint.id,
                      })
                    }
                  >
                    Загрузить
                  </Button>
                </ActionItem>
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
                    Preview
                  </Button>
                </ActionItem>
                <ActionItem>
                  <Button
                    compact
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
                    Apply
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
    <Section title="Экспорт">
      <Box color="label" mb={1}>
        Для `outpost_radius` можно сохранить текущий preview как Blueprint Lite.
      </Box>
      <Button
        compact
        disabled={!data.can_save_blueprint_from_plan}
        onClick={() => act('save_blueprint')}
      >
        Сохранить preview
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
      value: data.placement_interaction_label || 'Single Click',
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
    value: data.placement_active ? 'active' : 'inactive',
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
            Stop
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
            Collector: {finishCollectionReason}
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
  const workflow = getWorkflowState(data);

  return (
    <Stack fill>
      <Stack.Item grow basis={0}>
        <Section fill scrollable title="Выбор генератора">
          {!data.categories?.length && (
            <Box color="label">Нет доступных генераторов для текущих прав.</Box>
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
                  onSelect={() =>
                    act('select_generator', {
                      generator_id: generator.id,
                    })
                  }
                  onOpenWork={onOpenWork}
                />
              ))}
            </Collapsible>
          ))}
        </Section>
      </Stack.Item>

      {!!data.has_generator && (
        <Stack.Item width="15%" ml={1}>
          <Section fill scrollable title="Инспектор">
            <Box bold>
              {data.current_generator_category} / {data.current_generator_name}
            </Box>
            <Box color="label" mt={0.25}>
              {data.current_generator_description}
            </Box>
            <Box color="label" mt={0.5}>
              <Box
                as="span"
                color={toneForGeneratorStatus(data.current_generator_status)}
              >
                {data.current_generator_status || 'n/a'}
              </Box>{' '}
              | {data.current_generator_execution_mode || 'n/a'} | preview{' '}
              {boolText(data.current_generator_supports_preview)} | place{' '}
              {boolText(
                !!(
                  data.placement_supported ||
                  data.placement_shape_supported ||
                  data.placement_supports_direction
                ),
              )}
            </Box>
            <Box color="label" mt={0.25}>
              {data.current_generator_required_rights} |{' '}
              {data.ui_mode === 'inline' ? 'inline' : 'wizard'}
            </Box>

            <ActionRow>
              <ActionItem>
                <Button compact icon="sliders-h" onClick={onOpenWork}>
                  Работа
                </Button>
              </ActionItem>
              <ActionItem>
                <Button
                  compact
                  color="average"
                  icon="undo"
                  onClick={() => act('reset_generator')}
                >
                  Сброс
                </Button>
              </ActionItem>
            </ActionRow>
            <Box color={workflow.color || 'label'} mt={0.25}>
              {workflow.label}
            </Box>
          </Section>
        </Stack.Item>
      )}
    </Stack>
  );
};

const WorkspaceCommandBar = (props: {
  readonly data: BackendData;
  readonly act: (action: string, payload?: Record<string, unknown>) => void;
  readonly onOpenHistory: () => void;
}) => {
  const { data, act, onOpenHistory } = props;
  const workflow = getWorkflowState(data);
  const previewState = getPreviewState(data);
  const previewBlockReason = getPreviewBlockReason(data);
  const applyBlockReason = getApplyBlockReason(data);
  const actionHint =
    (!data.can_run_preview && previewBlockReason) ||
    (!data.can_run_apply && applyBlockReason) ||
    '';

  return (
    <Section fitted>
      <CompactStatusRow
        items={[
          {
            label: 'Preview',
            value: previewState.label,
            color: previewState.color,
          },
          {
            label: 'Apply',
            value: data.can_run_apply ? 'ready' : 'hold',
            color: data.can_run_apply ? 'good' : 'average',
          },
          {
            label: 'Place',
            value:
              data.placement_supported ||
              data.placement_shape_supported ||
              data.placement_supports_direction
                ? data.click_mode_active
                  ? 'active'
                  : 'off'
                : 'n/a',
            color: data.click_mode_active ? 'good' : 'label',
          },
          {
            label: 'Ops',
            value: `${data.history_entries?.length || 0}`,
            color: data.history_entries?.length ? 'good' : 'label',
          },
        ]}
      />

      <ActionRow>
        <ActionItem>
          <Button
            compact
            disabled={!data.can_run_preview}
            onClick={() => act('run_preview')}
          >
            Preview
          </Button>
        </ActionItem>
        <ActionItem>
          <Button
            compact
            color="good"
            disabled={!data.can_run_apply}
            onClick={() => act('run_apply')}
          >
            Apply
          </Button>
        </ActionItem>
        <ActionItem>
          <Button
            compact
            color="average"
            disabled={!data.has_generator}
            onClick={() => act('clear_preview')}
          >
            Очистить
          </Button>
        </ActionItem>
      </ActionRow>

      <Box color={workflow.color || 'label'} mt={0.25}>
        {workflow.label}
      </Box>

      <Collapsible title="Еще" mt={0.5}>
        <ActionRow>
          <ActionItem>
            <Button
              compact
              disabled={!data.can_refresh_ui}
              onClick={() => act('refresh_ui')}
            >
              Поля
            </Button>
          </ActionItem>
          <ActionItem>
            <Button compact onClick={() => act('configure_wizard')}>
              Мастер
            </Button>
          </ActionItem>
          <ActionItem>
            <Button
              compact
              color="average"
              onClick={() => act('reset_generator')}
            >
              Сброс
            </Button>
          </ActionItem>
          <ActionItem>
            <Button compact icon="history" onClick={onOpenHistory}>
              История
            </Button>
          </ActionItem>
        </ActionRow>
      </Collapsible>

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
  const previewState = getPreviewState(data);
  const recentHistoryEntries = (data.history_entries || []).slice(0, 3);

  return (
    <>
      <CompactStatusRow
        items={[
          {
            label: 'Preview',
            value: previewState.label,
            color: previewState.color,
          },
          {
            label: 'Apply',
            value: boolText(data.preview_valid),
            color: data.preview_valid ? 'good' : 'average',
          },
          {
            label: 'Blueprint',
            value: data.active_blueprint_id || 'none',
          },
        ]}
      />

      <Box color={previewState.color || 'label'}>{previewState.message}</Box>

      <ActionRow>
        <ActionItem>
          <Button
            compact
            color="average"
            disabled={!data.can_undo_last_operation}
            onClick={() => act('undo_last_operation')}
          >
            Undo
          </Button>
        </ActionItem>
        <ActionItem>
          <Button
            compact
            color="average"
            disabled={!data.can_cleanup_last_owned_effects}
            onClick={() => act('cleanup_last_owned_effects')}
          >
            Cleanup
          </Button>
        </ActionItem>
      </ActionRow>

      {!!data.preview_meta && !!Object.keys(data.preview_meta).length && (
        <Collapsible title="Метаданные preview" mt={0.5}>
          <CompactStatusRow
            basis="32%"
            items={Object.entries(data.preview_meta).map(([key, value]) => ({
              label: key,
              value: renderMetaValue(value),
            }))}
          />
        </Collapsible>
      )}

      <Collapsible title="Последний apply" open mt={0.5}>
        <Box color={data.last_apply_success ? 'good' : 'average'}>
          {data.last_apply_message || 'Операции apply еще не выполнялись.'}
        </Box>
      </Collapsible>

      <Collapsible title="Undo / cleanup" mt={0.5}>
        {!data.last_changeset && (
          <Box color="label">
            Undo/cleanup-record для текущей session пока отсутствует.
          </Box>
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
              ID операции: {data.last_changeset.operation_id}
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
        title={`Последние операции (${recentHistoryEntries.length})`}
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
              title={`${entry.time} | ${entry.generator_id}`}
            >
              <Box color={toneForHistoryResult(entry.result)}>
                {entry.result || 'n/a'}
              </Box>
              <Box color="label">{entry.message || 'n/a'}</Box>
            </Section>
          ))}
      </Collapsible>

      <Collapsible title="Диагностика" mt={0.5}>
        <Collapsible title="Текущие параметры" open>
          <Box>{data.current_params_text || 'n/a'}</Box>
        </Collapsible>

        <Collapsible
          title={`Служебный статус (${data.runtime_status?.length || 0})`}
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
    <Section
      fill
      scrollable
      title={
        data.has_generator
          ? `Работа / ${data.current_generator_name}`
          : 'Работа'
      }
    >
      {!data.has_generator && (
        <>
          <Box color="label" mb={1}>
            Сначала выберите генератор на странице `Выбор`.
          </Box>
          <Button compact icon="list" onClick={onOpenBrowse}>
            Перейти к выбору генератора
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

          <Tabs mt={0.25}>
            <Tabs.Tab
              selected={workTab === 'params'}
              fontSize={0.9}
              onClick={() => setWorkTab('params')}
            >
              Параметры
            </Tabs.Tab>
            {hasAssets && (
              <Tabs.Tab
                selected={workTab === 'assets'}
                fontSize={0.9}
                onClick={() => setWorkTab('assets')}
              >
                Ресурсы
              </Tabs.Tab>
            )}
            {showPlacementSetup && (
              <Tabs.Tab
                selected={workTab === 'placement'}
                fontSize={0.9}
                onClick={() => setWorkTab('placement')}
              >
                Размещение
              </Tabs.Tab>
            )}
            <Tabs.Tab
              selected={workTab === 'session'}
              fontSize={0.9}
              onClick={() => setWorkTab('session')}
            >
              Сессия
            </Tabs.Tab>
          </Tabs>

          {workTab === 'params' && (
            <Section mt={1}>
              {!data.has_inline_fields && (
                <Box color="label">
                  Этот генератор не отдает inline-поля. Используйте мастер
                  настройки сверху.
                </Box>
              )}

              {!!data.has_inline_fields && !groupNames.length && (
                <Box color="label">Inline-поля временно недоступны.</Box>
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
                  <Box color="label">
                    Для текущего генератора дополнительные библиотеки и пресеты
                    не используются.
                  </Box>
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
                  <Box color="label">
                    Для текущего генератора live placement не используется.
                  </Box>
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
      title="История операций (session)"
      buttons={
        <Button compact color="average" onClick={() => act('clear_history')}>
          Очистить
        </Button>
      }
    >
      {!data.history_entries?.length && (
        <>
          <Box color="label">История операций пуста.</Box>
          {!!data.has_generator && (
            <Button compact icon="sliders-h" mt={1} onClick={onOpenWork}>
              Вернуться к работе
            </Button>
          )}
        </>
      )}

      {!!data.history_entries?.length && (
        <>
          <CompactStatusRow
            items={[
              {
                label: 'Записи',
                value: `${data.history_entries?.length || 0}`,
              },
              {
                label: 'Генератор',
                value: latestEntry?.generator_id || 'none',
              },
              {
                label: 'Результат',
                value: latestEntry?.result || 'n/a',
                color: toneForHistoryResult(latestEntry?.result),
              },
              {
                label: 'Центр',
                value: latestEntry?.center_turf || 'n/a',
              },
            ]}
          />

          {data.history_entries.map((entry, index) => (
            <Collapsible
              key={`${entry.time}_${entry.generator_id}_${index}`}
              title={`${entry.time} | ${entry.generator_id} | ${entry.result}`}
              open={index === 0}
              color={toneForHistoryResult(entry.result)}
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
                    value: entry.center_turf || 'n/a',
                  },
                  {
                    label: 'Длительность',
                    value: `${entry.duration_ms} ms`,
                  },
                  {
                    label: 'Undo',
                    value: entry.undo_policy
                      ? `${entry.undo_policy} / ${entry.undo_status || 'n/a'}`
                      : 'n/a',
                  },
                  {
                    label: 'Reverted / skipped',
                    value: `${entry.reverted_count ?? 0} / ${
                      entry.skipped_count ?? 0
                    }`,
                  },
                ]}
              />

              <Box color="label" mt={0.5}>
                Параметры: {entry.params_short || 'n/a'}
              </Box>
              <Box color="label" mt={0.5}>
                Сообщение: {entry.message || 'n/a'}
              </Box>
              {!!entry.operation_id && (
                <Box color="label" mt={0.5}>
                  ID операции: {entry.operation_id}
                </Box>
              )}
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
  const statusText = getSidebarTiles(data)
    .map((item) => `${item.label} ${item.value}`)
    .join(' | ');

  return (
    <Section fill scrollable fitted title="World Edit">
      <Box bold>{data.current_generator_name || 'Без генератора'}</Box>
      <Box color="label" mt={0.25}>
        <Box as="span" color={workflow.color || 'label'}>
          {workflow.label}
        </Box>{' '}
        | {statusText}
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
