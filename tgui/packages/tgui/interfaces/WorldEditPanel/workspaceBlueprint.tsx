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
        <Button compact onClick={() => act('list_blueprints')}>
          Обновить
        </Button>
      }
      mt={0}
    >
      <Box
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(3, minmax(0, 1fr))',
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
            displayText={`Фильтр: ${
              FILTER_OPTIONS.find((option) => option.value === filterMode)
                ?.displayText || 'Все'
            }`}
            onSelected={(value) => setFilterMode(value as BlueprintFilterMode)}
          />
        </Box>
        <Box>
          <Dropdown
            className="WorldEditPanel__compactDropdown"
            width="100%"
            options={[...SORT_OPTIONS]}
            selected={sortMode}
            displayText={`Сорт: ${
              SORT_OPTIONS.find((option) => option.value === sortMode)
                ?.displayText || 'Последние'
            }`}
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
                <Flex align="center">
                  <Flex.Item grow basis="14rem" style={{ minWidth: '0' }}>
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
                  <Flex.Item style={{ flex: '0 0 auto' }}>
                    <Box
                      color={blueprint.valid ? 'label' : 'bad'}
                      style={{
                        fontSize: '0.92rem',
                        whiteSpace: 'nowrap',
                      }}
                    >
                      {getBlueprintFootprintText(blueprint)}
                    </Box>
                  </Flex.Item>
                </Flex>
                {!!outpostSummary && (
                  <Box
                    color="label"
                    style={{
                      fontSize: '0.82rem',
                      whiteSpace: 'nowrap',
                      overflow: 'hidden',
                      textOverflow: 'ellipsis',
                    }}
                  >
                    {outpostSummary}
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
