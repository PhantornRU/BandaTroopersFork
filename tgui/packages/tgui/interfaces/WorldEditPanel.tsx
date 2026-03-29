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
  click_mode_active: boolean;
  can_run_preview: boolean;
  can_run_apply: boolean;
  can_stop_click_mode: boolean;
  can_refresh_ui: boolean;
  history_entries: HistoryEntry[];
};

const PAGES = [
  { title: 'Генераторы', icon: 'list' },
  { title: 'Параметры', icon: 'sliders-h' },
  { title: 'Preview', icon: 'eye' },
  { title: 'Apply', icon: 'play' },
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

export const WorldEditPanel = () => {
  const { data, act } = useBackend<BackendData>();
  const [pageIndex, setPageIndex] = useState(0);

  const currentPage = PAGES[pageIndex]?.title || PAGES[0].title;

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
              <Section fill title="Каталог генераторов (status=ready)">
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

            {currentPage === 'Параметры' && (
              <Section fill title="Параметры генератора">
                {!data.has_generator && (
                  <Box color="label">
                    Сначала выберите генератор на вкладке "Генераторы".
                  </Box>
                )}

                {!!data.has_generator && (
                  <>
                    <Section title="Текущий генератор">
                      <Box>
                        {data.current_generator_category} /{' '}
                        {data.current_generator_name}
                      </Box>
                      <Box color="label">
                        {data.current_generator_description}
                      </Box>
                      <Box color="label">
                        Права: {data.current_generator_required_rights} | Режим:{' '}
                        {data.current_generator_execution_mode}
                      </Box>
                      <Box color="label">
                        Источник параметров:{' '}
                        {data.ui_mode === 'inline'
                          ? 'inline'
                          : 'wizard fallback'}
                      </Box>
                    </Section>

                    {!!data.last_ui_error && (
                      <NoticeBox danger>{data.last_ui_error}</NoticeBox>
                    )}

                    <Section title="Управление настройкой">
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
                          <Button
                            color="average"
                            onClick={() => act('reset_generator')}
                          >
                            Сбросить генератор
                          </Button>
                        </Stack.Item>
                      </Stack>
                    </Section>

                    <Section title="Presets">
                      {!data.can_manage_presets && (
                        <Box color="label">
                          В этой фазе presets доступны только для
                          `outpost_radius` и `destruction_pack`.
                        </Box>
                      )}

                      {!!data.can_manage_presets && (
                        <>
                          <Stack mb={1}>
                            <Stack.Item>
                              <Button onClick={() => act('save_preset')}>
                                Сохранить preset
                              </Button>
                            </Stack.Item>
                          </Stack>

                          {!data.preset_entries?.length && (
                            <Box color="label">
                              Для текущего генератора ещё нет сохранённых
                              preset'ов.
                            </Box>
                          )}

                          {!!data.preset_entries?.length && (
                            <Stack vertical>
                              {data.preset_entries.map((preset) => (
                                <Section key={preset.id} title={preset.name || preset.id}>
                                  <Box color="label">
                                    Сохранён: {preset.created_at || 'n/a'}
                                  </Box>
                                  <Box color="label">
                                    Параметры: {preset.params_short}
                                  </Box>
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
                        </>
                      )}
                    </Section>

                    <Section title="Blueprint Library">
                      <Stack mb={1}>
                        <Stack.Item>
                          <Button onClick={() => act('list_blueprints')}>
                            Обновить библиотеку
                          </Button>
                        </Stack.Item>
                        <Stack.Item>
                          <Button
                            disabled={!data.can_save_blueprint_from_plan}
                            onClick={() => act('save_blueprint')}
                          >
                            Сохранить из outpost preview
                          </Button>
                        </Stack.Item>
                      </Stack>

                      {!data.blueprint_entries?.length && (
                        <Box color="label">
                          В библиотеке пока нет blueprint'ов.
                        </Box>
                      )}

                      {!!data.blueprint_entries?.length && (
                        <Stack vertical>
                          {data.blueprint_entries.map((blueprint) => (
                            <Section
                              key={blueprint.id}
                              title={`${blueprint.name} [r=${blueprint.radius}]`}>
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
                              <Box color="label">
                                Создан: {blueprint.created_at || 'n/a'}
                              </Box>

                              {!blueprint.valid && (
                                <NoticeBox danger>
                                  {blueprint.error || 'Blueprint невалиден.'}
                                </NoticeBox>
                              )}

                              <Stack mt={1}>
                                <Stack.Item>
                                  <Button
                                    disabled={!blueprint.valid}
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
                                    disabled={!blueprint.valid}
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

                    <Section title="Inline-настройка">
                      {!data.has_inline_fields && (
                        <Box color="label">
                          Этот генератор не отдает inline-поля. Используйте
                          мастер настройки.
                        </Box>
                      )}

                      {!!data.has_inline_fields && !groupNames.length && (
                        <Box color="label">
                          Inline-поля временно недоступны.
                        </Box>
                      )}

                      {!!data.has_inline_fields &&
                        groupNames.map((groupName) => {
                          const fields = groupedFields[groupName] || [];
                          return (
                            <Section key={groupName} title={groupName}>
                              <LabeledList>
                                {fields.map((field) => (
                                  <FieldEditor
                                    key={field.id}
                                    field={field}
                                    act={act}
                                  />
                                ))}
                              </LabeledList>
                            </Section>
                          );
                        })}
                    </Section>

                    <Section title="Текущие параметры">
                      <Box>{data.current_params_text}</Box>
                    </Section>

                    <Section title="Runtime-статус">
                      {!data.runtime_status?.length && (
                        <Box color="label">
                          Дополнительный статус не предоставлен.
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
                    </Section>
                  </>
                )}
              </Section>
            )}

            {currentPage === 'Preview' && (
              <Section fill title="Preview">
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
                      color="average"
                      disabled={!data.has_generator}
                      onClick={() => act('clear_preview')}
                    >
                      Очистить preview
                    </Button>
                  </Stack.Item>
                </Stack>

                <Section title="Состояние preview">
                  <Box>
                    Статус: {data.preview_success ? 'успех' : 'ошибка/нет'} |
                    Валиден для apply: {data.preview_valid ? 'да' : 'нет'}
                  </Box>
                  <Box color={data.preview_success ? 'good' : 'average'}>
                    {data.preview_message || 'Нет данных preview.'}
                  </Box>
                </Section>

                <Section title="Meta">
                  {!data.preview_meta ||
                  !Object.keys(data.preview_meta).length ? (
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
              </Section>
            )}

            {currentPage === 'Apply' && (
              <Section fill title="Apply">
                <Stack>
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
                      disabled={!data.can_stop_click_mode}
                      onClick={() => act('stop_click_mode')}
                    >
                      Остановить click-режим
                    </Button>
                  </Stack.Item>
                </Stack>

                <Section title="Требования">
                  <Box>
                    Требуется preview перед apply:{' '}
                    {data.requires_preview_before_apply ? 'да' : 'нет'}
                  </Box>
                  <Box>
                    Click-режим активен: {data.click_mode_active ? 'да' : 'нет'}
                  </Box>
                </Section>

                <Section title="Последний apply">
                  <Box color={data.last_apply_success ? 'good' : 'average'}>
                    {data.last_apply_message ||
                      'Операции apply еще не выполнялись.'}
                  </Box>
                </Section>
              </Section>
            )}

            {currentPage === 'История' && (
              <Section fill title="История операций (session)">
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
                        title={`${entry.time} | ${entry.generator_id} | ${entry.result}`}>
                        <Box>
                          Создано: {entry.created_count} | Удалено:{' '}
                          {entry.deleted_count} | Центр: {entry.center_turf} |
                          Длительность: {entry.duration_ms} ms
                        </Box>
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
