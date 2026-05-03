import { useMemo, useState } from 'react';

import { Box, Button, Dropdown, Flex, Input } from '../../components';
import { getDisplayText, translateOptionLabel } from './helpers';
import { SurfaceCard } from './primitives';
import type { ActFn, BackendData, BlueprintEntry } from './types';
import type { BlueprintFilterMode, BlueprintSortMode } from './viewModel';
import {
  filterAndSortBlueprintEntries,
  getBlueprintActionState,
  getBlueprintFootprintText,
  getBlueprintPreviewMode,
} from './viewModel';

const FILTER_OPTIONS = [
  { value: 'all', displayText: 'Все' },
  { value: 'valid', displayText: 'Валидные' },
  { value: 'invalid', displayText: 'Ошибки' },
  { value: 'active', displayText: 'Активный' },
] as const;

const SORT_OPTIONS = [
  { value: 'recent', displayText: 'Последние' },
  { value: 'status', displayText: 'Статус' },
  { value: 'name_asc', displayText: 'Имя А-Я' },
  { value: 'name_desc', displayText: 'Имя Я-А' },
  { value: 'newest', displayText: 'Новые' },
  { value: 'oldest', displayText: 'Старые' },
  { value: 'size_desc', displayText: 'Размер ↓' },
  { value: 'size_asc', displayText: 'Размер ↑' },
  { value: 'entries_desc', displayText: 'Объекты ↓' },
  { value: 'entries_asc', displayText: 'Объекты ↑' },
] as const;

const getBlueprintOutpostSummary = (blueprint: BlueprintEntry) => {
  if (!blueprint.has_outpost_recipe) {
    return '';
  }

  const summaryParts = [
    blueprint.outpost_defense_profile
      ? translateOptionLabel(
          'defense_profile',
          '',
          blueprint.outpost_defense_profile,
        )
      : '',
    blueprint.outpost_layout_variant
      ? translateOptionLabel(
          'layout_variant',
          '',
          blueprint.outpost_layout_variant,
        )
      : '',
  ].filter(Boolean);

  return summaryParts.join(' / ');
};

const BLUEPRINT_ACTION_BUTTON_STYLE = {
  width: '1.55rem',
  minWidth: '1.55rem',
  height: '1.45rem',
  padding: '0',
  textAlign: 'center' as const,
};

const BlueprintActionButton = (props: {
  readonly icon: string;
  readonly tooltip: string;
  readonly disabled?: boolean;
  readonly color?: string;
  readonly onClick: (event: any) => void;
}) => {
  const { icon, tooltip, disabled, color, onClick } = props;

  return (
    <Button
      compact
      icon={icon}
      color={color}
      disabled={disabled}
      tooltip={tooltip}
      tooltipPosition="top"
      onClick={onClick}
      style={BLUEPRINT_ACTION_BUTTON_STYLE}
    />
  );
};

const BlueprintStampWorkspace = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
}) => {
  const { data, act } = props;
  const [searchQuery, setSearchQuery] = useState('');
  const [filterMode, setFilterMode] = useState<BlueprintFilterMode>('all');
  const [sortMode, setSortMode] = useState<BlueprintSortMode>('recent');

  const filteredBlueprints = useMemo(() => {
    const query = searchQuery.trim().toLowerCase();
    const queryEntries = !query
      ? data.blueprint_entries || []
      : (data.blueprint_entries || []).filter((entry) => {
          const haystack = [
            entry.name,
            entry.source,
            entry.created_by,
            entry.id,
          ]
            .join(' ')
            .toLowerCase();
          return haystack.includes(query);
        });

    return filterAndSortBlueprintEntries(
      data,
      queryEntries,
      filterMode,
      sortMode,
    );
  }, [data, filterMode, searchQuery, sortMode]);
  const totalBlueprints = data.blueprint_entries?.length || 0;

  return (
    <SurfaceCard
      title={`Библиотека (${filteredBlueprints.length} из ${totalBlueprints})`}
      actions={
        <Flex>
          <Flex.Item mr={0.3}>
            <Button
              compact
              icon="upload"
              onClick={() => act('import_blueprint')}
            >
              Импорт
            </Button>
          </Flex.Item>
          <Flex.Item>
            <Button
              compact
              icon="refresh"
              onClick={() => act('list_blueprints')}
            >
              Обновить
            </Button>
          </Flex.Item>
        </Flex>
      }
      mt={0}
    >
      <Box
        style={{
          display: 'grid',
          gridTemplateColumns:
            'minmax(7rem, 1.35fr) minmax(5.5rem, 0.82fr) minmax(6.25rem, 0.95fr)',
          gap: '0.4rem',
          alignItems: 'center',
        }}
      >
        <Box>
          <Input
            className="WorldEditPanel__compactInput"
            fluid
            value={searchQuery}
            placeholder="Поиск"
            onChange={(_, value) => setSearchQuery(value)}
          />
        </Box>
        <Box>
          <Dropdown
            className="WorldEditPanel__compactDropdown"
            width="100%"
            options={[...FILTER_OPTIONS]}
            selected={filterMode}
            displayText={
              FILTER_OPTIONS.find((option) => option.value === filterMode)
                ?.displayText || 'Все'
            }
            onSelected={(value) => setFilterMode(value as BlueprintFilterMode)}
          />
        </Box>
        <Box>
          <Dropdown
            className="WorldEditPanel__compactDropdown"
            width="100%"
            options={[...SORT_OPTIONS]}
            selected={sortMode}
            displayText={
              SORT_OPTIONS.find((option) => option.value === sortMode)
                ?.displayText || 'Последние'
            }
            onSelected={(value) => setSortMode(value as BlueprintSortMode)}
          />
        </Box>
      </Box>

      {!data.blueprint_entries?.length && (
        <Box color="label" mt={0.55}>
          Нет шаблонов.
        </Box>
      )}

      {!!data.blueprint_entries?.length && !filteredBlueprints.length && (
        <Box color="label" mt={0.55}>
          Ничего не найдено.
        </Box>
      )}

      {!!filteredBlueprints.length && (
        <Box mt={0.55}>
          {filteredBlueprints.map((blueprint) => {
            const actionState = getBlueprintActionState(data, blueprint);
            const outpostSummary = getBlueprintOutpostSummary(blueprint);
            const isCompactPreview =
              getBlueprintPreviewMode(blueprint) === 'compact';
            return (
              <Box
                key={blueprint.id}
                p={0.45}
                mb={0.3}
                onClick={() => {
                  if (actionState.canLoad) {
                    act('load_blueprint', {
                      blueprint_id: blueprint.id,
                    });
                  }
                }}
                style={{
                  border: actionState.isActive
                    ? '1px solid #4c9f39'
                    : '1px solid rgba(70, 107, 150, 0.55)',
                  borderLeft: actionState.isActive
                    ? '3px solid #4c9f39'
                    : '3px solid transparent',
                  background: actionState.isActive
                    ? 'rgba(76, 159, 57, 0.16)'
                    : 'rgba(70, 107, 150, 0.10)',
                  borderRadius: '4px',
                  cursor: actionState.canLoad ? 'pointer' : 'default',
                }}
              >
                <Box
                  style={{
                    display: 'grid',
                    gridTemplateColumns: 'minmax(0, 1fr) auto',
                    gap: '0.45rem',
                    alignItems: 'center',
                  }}
                >
                  <Box style={{ minWidth: '0' }}>
                    <Flex align="center">
                      <Flex.Item grow style={{ minWidth: '0' }}>
                        <Box
                          bold
                          color={actionState.isActive ? 'good' : 'white'}
                          style={{
                            whiteSpace: 'nowrap',
                            overflow: 'hidden',
                            textOverflow: 'ellipsis',
                          }}
                        >
                          {getDisplayText(blueprint.name, 'Шаблон без имени')}
                        </Box>
                      </Flex.Item>
                      <Flex.Item ml={0.35} style={{ flex: '0 0 auto' }}>
                        <Box
                          color={blueprint.valid ? 'label' : 'bad'}
                          style={{
                            fontSize: '0.9rem',
                            whiteSpace: 'nowrap',
                          }}
                        >
                          {getBlueprintFootprintText(blueprint)}
                        </Box>
                      </Flex.Item>
                    </Flex>
                    <Flex align="center" mt={0.2}>
                      <Flex.Item style={{ minWidth: '0' }}>
                        <Box
                          color="label"
                          style={{
                            fontSize: '0.78rem',
                            whiteSpace: 'nowrap',
                            overflow: 'hidden',
                            textOverflow: 'ellipsis',
                          }}
                        >
                          {blueprint.valid
                            ? `${blueprint.entry_count || 0} объектов`
                            : 'ошибка'}
                          {isCompactPreview ? ' / компактный предпросмотр' : ''}
                          {!!outpostSummary ? ` / ${outpostSummary}` : ''}
                        </Box>
                      </Flex.Item>
                    </Flex>
                  </Box>
                  <Box
                    style={{
                      display: 'grid',
                      gridTemplateColumns: 'repeat(6, 1.55rem)',
                      gap: '0.18rem',
                      justifyContent: 'end',
                    }}
                  >
                    <BlueprintActionButton
                      icon="sign-in"
                      tooltip="Загрузить"
                      disabled={!actionState.canLoad}
                      onClick={(event) => {
                        event.stopPropagation();
                        act('load_blueprint', {
                          blueprint_id: blueprint.id,
                        });
                      }}
                    />
                    <BlueprintActionButton
                      icon="eye"
                      tooltip="Предпросмотр"
                      disabled={!actionState.canPreview}
                      onClick={(event) => {
                        event.stopPropagation();
                        act('preview_blueprint', {
                          blueprint_id: blueprint.id,
                        });
                      }}
                    />
                    <BlueprintActionButton
                      icon="check"
                      tooltip="Применить"
                      color={actionState.canApply ? 'good' : undefined}
                      disabled={!actionState.canApply}
                      onClick={(event) => {
                        event.stopPropagation();
                        act('apply_blueprint', {
                          blueprint_id: blueprint.id,
                        });
                      }}
                    />
                    <BlueprintActionButton
                      icon="download"
                      tooltip="Экспорт .dmm"
                      color="transparent"
                      disabled={!blueprint.valid}
                      onClick={(event) => {
                        event.stopPropagation();
                        act('export_blueprint', {
                          blueprint_id: blueprint.id,
                        });
                      }}
                    />
                    <BlueprintActionButton
                      icon="edit"
                      tooltip="Переименовать"
                      color="transparent"
                      disabled={!blueprint.valid}
                      onClick={(event) => {
                        event.stopPropagation();
                        act('rename_blueprint', {
                          blueprint_id: blueprint.id,
                        });
                      }}
                    />
                    <BlueprintActionButton
                      icon="trash"
                      tooltip="Удалить"
                      color="bad"
                      disabled={!blueprint.valid}
                      onClick={(event) => {
                        event.stopPropagation();
                        act('delete_blueprint', {
                          blueprint_id: blueprint.id,
                        });
                      }}
                    />
                  </Box>
                </Box>
                {!!blueprint.error && !blueprint.valid && (
                  <Box
                    color="bad"
                    style={{
                      fontSize: '0.82rem',
                      whiteSpace: 'nowrap',
                      overflow: 'hidden',
                      textOverflow: 'ellipsis',
                    }}
                  >
                    {blueprint.error}
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

export { BlueprintStampWorkspace };
