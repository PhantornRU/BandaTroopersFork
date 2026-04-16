import { useMemo, useState } from 'react';

import { Box, Button, Flex, Input } from '../../components';
import { getDisplayText } from './helpers';
import { SurfaceCard } from './primitives';
import type { ActFn, BackendData } from './types';
import { getBlueprintLibraryMetaText } from './viewModel';

const BlueprintStampWorkspace = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
}) => {
  const { data, act } = props;
  const [searchQuery, setSearchQuery] = useState('');

  const filteredBlueprints = useMemo(() => {
    const query = searchQuery.trim().toLowerCase();
    if (!query) {
      return data.blueprint_entries || [];
    }

    return (data.blueprint_entries || []).filter((entry) => {
      const haystack = [entry.name, entry.source, entry.created_by, entry.id]
        .join(' ')
        .toLowerCase();
      return haystack.includes(query);
    });
  }, [data.blueprint_entries, searchQuery]);
  const totalBlueprints = data.blueprint_entries?.length || 0;

  return (
    <SurfaceCard
      title="Библиотека"
      subtitle={`${filteredBlueprints.length} из ${totalBlueprints}`}
      actions={
        <Button compact onClick={() => act('list_blueprints')}>
          Обновить
        </Button>
      }
      mt={0}
    >
      <Input
        value={searchQuery}
        placeholder="Поиск"
        onChange={(_, value) => setSearchQuery(value)}
      />

      {!data.blueprint_entries?.length && (
        <Box color="label" mt={0.7}>
          Нет шаблонов.
        </Box>
      )}

      {!!data.blueprint_entries?.length && !filteredBlueprints.length && (
        <Box color="label" mt={0.7}>
          Ничего не найдено.
        </Box>
      )}

      {!!filteredBlueprints.length && (
        <Box mt={0.7}>
          {filteredBlueprints.map((blueprint) => {
            const isActive = blueprint.id === data.active_blueprint_id;
            const canLoad = blueprint.valid && !isActive;
            return (
              <Box
                key={blueprint.id}
                p={0.45}
                mb={0.3}
                onClick={() => {
                  if (canLoad) {
                    act('load_blueprint', {
                      blueprint_id: blueprint.id,
                    });
                  }
                }}
                style={{
                  border: isActive
                    ? '1px solid #4c9f39'
                    : '1px solid rgba(70, 107, 150, 0.55)',
                  borderLeft: isActive
                    ? '3px solid #4c9f39'
                    : '3px solid transparent',
                  background: isActive
                    ? 'rgba(76, 159, 57, 0.16)'
                    : 'rgba(70, 107, 150, 0.10)',
                  borderRadius: '4px',
                  cursor: canLoad ? 'pointer' : 'default',
                }}
              >
                <Flex align="center" wrap>
                  <Flex.Item grow basis="14rem" style={{ minWidth: '0' }}>
                    <Box
                      bold
                      color={isActive ? 'good' : 'white'}
                      style={{
                        whiteSpace: 'nowrap',
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                      }}
                    >
                      {getDisplayText(blueprint.name, 'Шаблон без имени')}
                    </Box>
                  </Flex.Item>
                  {isActive && (
                    <Flex.Item style={{ flex: '0 0 auto' }}>
                      <Box
                        color="good"
                        px={0.35}
                        py={0.12}
                        style={{
                          border: '1px solid rgba(76, 159, 57, 0.45)',
                          background: 'rgba(76, 159, 57, 0.14)',
                          borderRadius: '999px',
                          fontSize: '0.82rem',
                          whiteSpace: 'nowrap',
                        }}
                      >
                        Активен
                      </Box>
                    </Flex.Item>
                  )}
                  {blueprint.valid && (
                    <Flex.Item basis="100%" style={{ minWidth: '0' }}>
                      <Box
                        color="label"
                        mt={0.2}
                        style={{ fontSize: '0.92rem' }}
                      >
                        {getBlueprintLibraryMetaText(blueprint)}
                      </Box>
                    </Flex.Item>
                  )}
                </Flex>
                {!blueprint.valid && (
                  <Box color="bad" mt={0.2}>
                    {blueprint.error || 'Шаблон недоступен.'}
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
