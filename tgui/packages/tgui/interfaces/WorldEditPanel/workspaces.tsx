import { type ReactNode, useMemo, useState } from 'react';

import {
  Box,
  Button,
  Collapsible,
  Flex,
  Input,
  LabeledList,
  Section,
} from '../../components';
import { EditorChrome, getDestructionPreviewLegendItems } from './chrome';
import { EMPTY_LABEL } from './constants';
import {
  FieldBlock,
  FieldControlStack,
  FieldEditor,
  FieldListCard,
} from './fieldControls';
import {
  getDisplayText,
  getField,
  getFieldsByGroup,
  getFieldsById,
  getGeneratorDisplayName,
  getHistoryResultText,
  getPositiveCountText,
  getTranslatedUndoPolicy,
  getTranslatedUndoStatus,
  getUndoTone,
  isBlankDisplayValue,
  toneForHistoryResult,
} from './helpers';
import {
  CompactStatusRow,
  getSurfaceColors,
  StatusPill,
  SurfaceCard,
  WorkspaceGrid,
  WorkspacePane,
} from './primitives';
import type {
  ActFn,
  BackendData,
  BlueprintEntry,
  GeneratorEntry,
  UiField,
  WorkspaceTabKey,
} from './types';

const DESTRUCTION_COLOR_GUIDE = [
  {
    label: 'Перемещение',
    color: '#4e8eff',
    description: 'Синий слой показывает клетки, по которым shuffle и scatter будут двигать объекты.',
  },
  {
    label: 'Огонь',
    color: '#ff9438',
    description: 'Оранжевая подсветка отмечает клетки, где будет создан постоянный огонь.',
  },
  {
    label: 'Урон',
    color: '#b85cff',
    description: 'Фиолетовый слой показывает прямой структурный урон без взрывной волны.',
  },
  {
    label: 'Взрыв',
    color: '#ff4e4e',
    description: 'Красная зона отмечает центр и область controlled blast.',
  },
] as const;

const getDestructionRangeSuffix = (field: UiField) => {
  if (typeof field.min !== 'number' || typeof field.max !== 'number') {
    return '';
  }

  const rangeText = `${field.min}-${field.max}`;
  if (field.id === 'persistent_fire_density') {
    return ` [${rangeText}%]`;
  }
  return ` [${rangeText}]`;
};

const getDestructionFieldLabel = (field: UiField) => {
  switch (field.id) {
    case 'scatter_steps':
      return `Шаги разброса${getDestructionRangeSuffix(field)}`;
    case 'max_atoms':
      return `Лимит объектов${getDestructionRangeSuffix(field)}`;
    case 'persistent_fire_density':
      return `Плотность огня${getDestructionRangeSuffix(field)}`;
    case 'blast_power':
      return `Мощность взрыва${getDestructionRangeSuffix(field)}`;
    case 'blast_falloff':
      return `Спад взрыва${getDestructionRangeSuffix(field)}`;
    default:
      return undefined;
  }
};

const getBlueprintLibraryMetaText = (blueprint: BlueprintEntry) => {
  const parts = [
    `${getPositiveCountText(blueprint.entry_count, '0')} объектов`,
    `r${getPositiveCountText(blueprint.radius, '0')}`,
  ];
  if (!isBlankDisplayValue(blueprint.source)) {
    parts.push(`${blueprint.source}`);
  }
  return parts.join(' · ');
};

const DestructionSplitBlock = (props: {
  readonly title: string;
  readonly tone?: 'default' | 'good' | 'average' | 'bad';
  readonly children: ReactNode;
}) => {
  const { title, tone, children } = props;
  const { borderColor } = getSurfaceColors(tone);

  return (
    <Box
      p={0.5}
      style={{
        height: '100%',
        borderTop: `2px solid ${borderColor}`,
        border: `1px solid ${borderColor}`,
        background: 'rgba(70, 107, 150, 0.03)',
        borderRadius: '4px',
      }}
    >
      <Box bold>{title}</Box>
      <Box mt={0.4}>{children}</Box>
    </Box>
  );
};

const DestructionColorGuide = (props: {
  readonly activeItems: { label: string; color: string }[];
}) => {
  const { activeItems } = props;
  const activeLabels = new Set(activeItems.map((item) => item.label));

  return (
    <Box
      style={{
        display: 'grid',
        alignContent: 'start',
        alignSelf: 'start',
        width: '100%',
      }}
    >
      <Box bold>Цвета на карте</Box>
      <Box
        mt={0.35}
        style={{
          display: 'grid',
          rowGap: '0.36rem',
          alignContent: 'start',
        }}
      >
        {DESTRUCTION_COLOR_GUIDE.map((item) => {
          const isActive = activeLabels.has(item.label);
          return (
            <Box
              key={item.label}
              p={0.38}
              style={{
                border: `1px solid ${isActive ? item.color : 'rgba(70, 107, 150, 0.35)'}`,
                background: isActive
                  ? 'rgba(70, 107, 150, 0.12)'
                  : 'rgba(70, 107, 150, 0.05)',
                borderRadius: '4px',
                opacity: isActive ? '1' : '0.72',
              }}
            >
              <Flex align="center">
                <Flex.Item grow basis="10rem" style={{ minWidth: '0' }}>
                  <Box
                    as="span"
                    mr={0.38}
                    style={{
                      display: 'inline-block',
                      width: '0.82rem',
                      height: '0.82rem',
                      borderRadius: '3px',
                      background: item.color,
                      verticalAlign: 'middle',
                    }}
                  />
                  <Box as="span" bold color={isActive ? 'white' : 'label'}>
                    {item.label}
                  </Box>
                </Flex.Item>
              </Flex>
            </Box>
          );
        })}
      </Box>
    </Box>
  );
};

const DestructionMovementBlock = (props: {
  readonly shuffleField?: UiField;
  readonly scatterField?: UiField;
  readonly maxAtomsField?: UiField;
  readonly scatterStepsField?: UiField;
  readonly act: ActFn;
  readonly tone?: 'default' | 'good' | 'average' | 'bad';
  readonly activeItems: { label: string; color: string }[];
}) => {
  const {
    shuffleField,
    scatterField,
    maxAtomsField,
    scatterStepsField,
    act,
    tone,
    activeItems,
  } = props;

  return (
    <DestructionSplitBlock title="Перемещение" tone={tone}>
      <Box
        style={{
          display: 'grid',
          gridTemplateColumns: 'minmax(0, 1.05fr) minmax(15rem, 0.95fr)',
          gridTemplateAreas: `
            "shuffle legend"
            "scatter legend"
            "maxAtoms scatterSteps"
          `,
          columnGap: '0.85rem',
          rowGap: '0.58rem',
          alignItems: 'start',
        }}
      >
        {!!shuffleField && (
          <Box style={{ gridArea: 'shuffle', minWidth: '0' }}>
            <FieldControlStack
              field={shuffleField}
              act={act}
              labelOverride={getDestructionFieldLabel(shuffleField)}
              showHint={false}
            />
          </Box>
        )}
        {!!scatterField && (
          <Box style={{ gridArea: 'scatter', minWidth: '0' }}>
            <FieldControlStack
              field={scatterField}
              act={act}
              labelOverride={getDestructionFieldLabel(scatterField)}
              showHint={false}
            />
          </Box>
        )}
        {!!maxAtomsField && (
          <Box style={{ gridArea: 'maxAtoms', minWidth: '0' }}>
            <FieldControlStack
              field={maxAtomsField}
              act={act}
              labelOverride={getDestructionFieldLabel(maxAtomsField)}
              showHint={false}
            />
          </Box>
        )}
        <Box
          style={{
            gridArea: 'legend',
            minWidth: '0',
            alignSelf: 'start',
          }}
        >
          <DestructionColorGuide activeItems={activeItems} />
        </Box>
        {!!scatterStepsField && (
          <Box
            style={{
              gridArea: 'scatterSteps',
              minWidth: '0',
              alignSelf: 'start',
            }}
          >
            <FieldControlStack
              field={scatterStepsField}
              act={act}
              labelOverride={getDestructionFieldLabel(scatterStepsField)}
              showHint={false}
            />
          </Box>
        )}
      </Box>
    </DestructionSplitBlock>
  );
};

const DestructionModeBlock = (props: {
  readonly title: string;
  readonly fields: UiField[];
  readonly act: ActFn;
  readonly tone?: 'default' | 'good' | 'average' | 'bad';
}) => {
  const { title, fields, act, tone } = props;
  const visibleFields = fields.filter((field) => field.visible !== false);
  if (!visibleFields.length) {
    return null;
  }

  const [primaryField, ...detailFields] = visibleFields;

  return (
    <DestructionSplitBlock title={title} tone={tone}>
      <Box
        style={{
          display: 'grid',
          rowGap: '0.58rem',
          alignContent: 'start',
          height: '100%',
        }}
      >
        {!!primaryField && (
          <FieldControlStack
            field={primaryField}
            act={act}
            labelOverride={getDestructionFieldLabel(primaryField)}
            showHint={false}
          />
        )}
        {!!detailFields.length && (
          <Box
            pt={0.4}
            style={{
              display: 'grid',
              rowGap: '0.58rem',
              borderTop: '1px solid rgba(70, 107, 150, 0.24)',
            }}
          >
            {detailFields.map((field) => (
              <FieldControlStack
                key={field.id}
                field={field}
                act={act}
                labelOverride={getDestructionFieldLabel(field)}
                showHint={false}
              />
            ))}
          </Box>
        )}
      </Box>
    </DestructionSplitBlock>
  );
};

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

const OutpostRadiusWorkspace = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
}) => {
  const { data, act } = props;
  const sentryFields = getFieldsByGroup(data.ui_fields, 'Sentries');
  const barricadeFields = getFieldsByGroup(data.ui_fields, 'Barricades');
  const layoutFields = getFieldsByGroup(data.ui_fields, 'Layout').filter(
    (field) => field.id !== 'radius',
  );
  const familyField = getField(layoutFields, 'family');
  const layoutVariantField = getField(layoutFields, 'layout_variant');
  const openingWidthField = getField(layoutFields, 'opening_width');
  const extraLayoutFields = layoutFields.filter(
    (field) =>
      !['family', 'layout_variant', 'opening_width'].includes(field.id),
  );
  const sentryToggleField = getField(sentryFields, 'place_sentries');
  const sentryDetailFields = getFieldsById(sentryFields, [
    'guard_mode',
    'sentry_path',
    'faction',
    'turned_on',
  ]).filter((field) => field.visible !== false);

  return (
    <Box>
      <SurfaceCard
        title="Профиль и вариант"
        mt={0}
        actions={
          data.can_save_blueprint_from_plan ? (
            <Button compact onClick={() => act('save_blueprint')}>
              Сохранить как шаблон
            </Button>
          ) : undefined
        }
      >
        <Box
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(2, minmax(0, 1fr))',
            gap: '0.6rem',
          }}
        >
          <FieldControlStack field={familyField} act={act} />
          <FieldControlStack field={layoutVariantField} act={act} />
        </Box>
        {!!openingWidthField && (
          <Box mt={0.6}>
            <FieldControlStack
              field={openingWidthField}
              act={act}
              forceChoiceStrip
              choiceStripBasis="15.8%"
            />
          </Box>
        )}
        {!!extraLayoutFields.filter((field) => field.visible !== false)
          .length && (
          <Box mt={0.6}>
            <LabeledList>
              {extraLayoutFields
                .filter((field) => field.visible !== false)
                .map((field) => (
                  <FieldEditor key={field.id} field={field} act={act} />
                ))}
            </LabeledList>
          </Box>
        )}
      </SurfaceCard>
      <FieldListCard title="Периметр" fields={barricadeFields} act={act} />
      <SurfaceCard title="Оборона" mt={0.6}>
        <Box style={{ maxWidth: '16rem' }}>
          <FieldControlStack field={sentryToggleField} act={act} />
        </Box>
        {!!sentryDetailFields.length && (
          <Box
            mt={0.6}
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(2, minmax(0, 1fr))',
              gap: '0.6rem',
            }}
          >
            {sentryDetailFields.map((field) => (
              <FieldControlStack key={field.id} field={field} act={act} />
            ))}
          </Box>
        )}
      </SurfaceCard>
    </Box>
  );
};

const DestructionPackWorkspace = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
}) => {
  const { data, act } = props;
  const areaFields = getFieldsByGroup(data.ui_fields, 'Area').filter(
    (field) => field.id !== 'radius',
  );
  const shuffleField = getField(data.ui_fields, 'shuffle_enabled');
  const scatterField = getField(data.ui_fields, 'scatter_enabled');
  const maxAtomsField = getField(data.ui_fields, 'max_atoms');
  const scatterStepsField = getField(data.ui_fields, 'scatter_steps');
  const fireFields = [
    ...getFieldsById(data.ui_fields, ['persistent_fire_enabled']),
    ...getFieldsById(data.ui_fields, ['persistent_fire_density']),
  ];
  const blastFields = [
    ...getFieldsById(data.ui_fields, ['blast_enabled']),
    ...getFieldsById(data.ui_fields, ['blast_power', 'blast_falloff']),
  ];
  const damageFields = getFieldsById(data.ui_fields, ['damage_profile']);

  const blastEnabled = !!getField(data.ui_fields, 'blast_enabled')?.value;
  const damageProfile = `${getField(data.ui_fields, 'damage_profile')?.value || 'none'}`;
  const fireEnabled = !!getField(data.ui_fields, 'persistent_fire_enabled')
    ?.value;
  const destructiveEnabled = blastEnabled || damageProfile !== 'none';
  const movementEnabled =
    !!getField(data.ui_fields, 'shuffle_enabled')?.value ||
    !!getField(data.ui_fields, 'scatter_enabled')?.value;
  const visibleAreaFields = areaFields.filter(
    (field) => field.visible !== false,
  );
  const visibleShuffleField =
    shuffleField?.visible !== false ? shuffleField : undefined;
  const visibleScatterField =
    scatterField?.visible !== false ? scatterField : undefined;
  const visibleMaxAtomsField =
    maxAtomsField?.visible !== false ? maxAtomsField : undefined;
  const visibleScatterStepsField =
    scatterStepsField?.visible !== false ? scatterStepsField : undefined;
  const visibleMovementFields = [
    visibleShuffleField,
    visibleScatterField,
    visibleMaxAtomsField,
    visibleScatterStepsField,
  ].filter((field): field is UiField => !!field);
  const previewLegendItems = getDestructionPreviewLegendItems(data);

  return (
    <>
      {(!!visibleAreaFields.length || !!visibleMovementFields.length) && (
        <SurfaceCard title="Безопасная зона">
          <WorkspaceGrid>
            {!!visibleMovementFields.length && (
              <WorkspacePane
                basis={visibleAreaFields.length ? '48%' : '100%'}
                minWidth="19rem"
              >
                <DestructionMovementBlock
                  shuffleField={visibleShuffleField}
                  scatterField={visibleScatterField}
                  maxAtomsField={visibleMaxAtomsField}
                  scatterStepsField={visibleScatterStepsField}
                  act={act}
                  tone={movementEnabled ? 'average' : 'default'}
                  activeItems={previewLegendItems}
                />
              </WorkspacePane>
            )}
            {!!visibleAreaFields.length && (
              <WorkspacePane basis="48%" minWidth="19rem">
                <FieldBlock title="Зона" fields={visibleAreaFields} act={act} />
              </WorkspacePane>
            )}
          </WorkspaceGrid>
        </SurfaceCard>
      )}

      <SurfaceCard
        title="Опасные режимы"
        mt={visibleAreaFields.length || visibleMovementFields.length ? 0.6 : 0}
        tone={destructiveEnabled ? 'bad' : fireEnabled ? 'average' : 'default'}
      >
        <WorkspaceGrid>
          <WorkspacePane basis="48%" minWidth="16rem">
            <DestructionModeBlock
              title="Огонь"
              fields={fireFields}
              act={act}
              tone={fireEnabled ? 'average' : 'default'}
            />
          </WorkspacePane>
          <WorkspacePane basis="48%" minWidth="16rem">
            <DestructionModeBlock
              title="Взрыв"
              fields={blastFields}
              act={act}
              tone={blastEnabled ? 'bad' : 'default'}
            />
          </WorkspacePane>
          <WorkspacePane basis="100%" minWidth="16rem">
            <FieldBlock
              title="Структурный урон"
              fields={damageFields}
              act={act}
              tone={damageProfile !== 'none' ? 'bad' : 'default'}
            />
          </WorkspacePane>
        </WorkspaceGrid>
      </SurfaceCard>
    </>
  );
};

const GenericFieldGroups = (props: {
  readonly groupedFields: Record<string, UiField[]>;
  readonly groupNames: string[];
  readonly act: ActFn;
}) => {
  const { groupedFields, groupNames, act } = props;
  if (!groupNames.length) {
    return <Box color="label">Поля временно недоступны.</Box>;
  }

  return (
    <WorkspaceGrid>
      {groupNames.map((groupName) => (
        <WorkspacePane key={groupName} basis="48%" minWidth="20rem">
          <FieldListCard
            title={groupName}
            fields={groupedFields[groupName] || []}
            act={act}
          />
        </WorkspacePane>
      ))}
    </WorkspaceGrid>
  );
};

const GenericToolWorkspace = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
  readonly groupedFields: Record<string, UiField[]>;
  readonly groupNames: string[];
  readonly showPlacementSetup: boolean;
}) => {
  const { data, act, groupedFields, groupNames, showPlacementSetup } = props;
  const hasPrimaryContent = data.has_inline_fields || showPlacementSetup;

  return (
    <>
      {!hasPrimaryContent && <Box color="label">Нет настроек.</Box>}

      {!!data.has_inline_fields && (
        <GenericFieldGroups
          groupedFields={groupedFields}
          groupNames={groupNames}
          act={act}
        />
      )}
    </>
  );
};

const ToolWorkspace = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
  readonly groupedFields: Record<string, UiField[]>;
  readonly groupNames: string[];
  readonly showPlacementSetup: boolean;
}) => {
  const { data, act, groupedFields, groupNames, showPlacementSetup } = props;

  if (data.current_generator_id === 'blueprint_stamp') {
    return <BlueprintStampWorkspace data={data} act={act} />;
  }

  if (data.current_generator_id === 'outpost_radius') {
    return <OutpostRadiusWorkspace data={data} act={act} />;
  }

  if (data.current_generator_id === 'destruction_pack') {
    return <DestructionPackWorkspace data={data} act={act} />;
  }

  return (
    <GenericToolWorkspace
      data={data}
      act={act}
      groupedFields={groupedFields}
      groupNames={groupNames}
      showPlacementSetup={showPlacementSetup}
    />
  );
};

const HistoryWorkspace = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
}) => {
  const { data, act } = props;
  const historyEntries = data.history_entries || [];
  const historyMetrics = historyEntries.reduce(
    (acc, entry) => {
      const tone = toneForHistoryResult(entry.result);
      acc.total += 1;
      if (tone === 'good') {
        acc.good += 1;
      } else if (tone === 'average') {
        acc.average += 1;
      } else if (tone === 'bad') {
        acc.bad += 1;
      }
      return acc;
    },
    {
      total: 0,
      good: 0,
      average: 0,
      bad: 0,
    },
  );

  return (
    <SurfaceCard
      title="Журнал"
      actions={
        <Flex wrap mx={-0.2}>
          <Flex.Item m={0.2}>
            <Button
              compact
              color="average"
              disabled={!data.can_cleanup_last_owned_effects}
              onClick={() => act('cleanup_last_owned_effects')}
            >
              Очистить эффекты
            </Button>
          </Flex.Item>
          <Flex.Item m={0.2}>
            <Button
              compact
              color="average"
              onClick={() => act('clear_history')}
            >
              Очистить журнал
            </Button>
          </Flex.Item>
        </Flex>
      }
    >
      {!data.last_changeset && !historyEntries.length && (
        <Box color="label">Журнал пуст.</Box>
      )}

      {!!historyEntries.length && (
        <Box mb={0.55}>
          <Flex wrap mx={-0.2}>
            <Flex.Item m={0.2}>
              <StatusPill
                label="Записей"
                value={`${historyMetrics.total}`}
                tone="label"
              />
            </Flex.Item>
            <Flex.Item m={0.2}>
              <StatusPill
                label="Успех"
                value={`${historyMetrics.good}`}
                tone="good"
              />
            </Flex.Item>
            <Flex.Item m={0.2}>
              <StatusPill
                label="Частично"
                value={`${historyMetrics.average}`}
                tone="average"
              />
            </Flex.Item>
            <Flex.Item m={0.2}>
              <StatusPill
                label="Проблемы"
                value={`${historyMetrics.bad}`}
                tone="bad"
              />
            </Flex.Item>
            <Flex.Item m={0.2}>
              <StatusPill
                label="Откат"
                value={
                  data.can_undo_last_operation
                    ? 'Доступен'
                    : data.can_cleanup_last_owned_effects
                      ? 'Очистка'
                      : 'Нет'
                }
                tone={
                  data.can_undo_last_operation
                    ? 'good'
                    : data.can_cleanup_last_owned_effects
                      ? 'average'
                      : 'label'
                }
              />
            </Flex.Item>
          </Flex>
        </Box>
      )}

      {!!data.last_changeset && (
        <Box
          p={0.45}
          mb={historyEntries.length ? 0.55 : 0}
          style={{
            border: '1px solid rgba(70, 107, 150, 0.55)',
            background: 'rgba(70, 107, 150, 0.12)',
            borderRadius: '4px',
          }}
        >
          <Flex align="center" wrap mb={0.35}>
            <Flex.Item grow basis="12rem">
              <Box bold>Последняя операция</Box>
            </Flex.Item>
            <Flex.Item>
              <StatusPill
                label="Статус"
                value={getTranslatedUndoStatus(data.last_changeset.undo_status)}
                tone={getUndoTone(data.last_changeset.undo_status)}
              />
            </Flex.Item>
          </Flex>
          <CompactStatusRow
            basis="32%"
            items={[
              {
                label: 'Инструмент',
                value: getGeneratorDisplayName(
                  data,
                  data.last_changeset.generator_id,
                ),
              },
              {
                label: 'Откат',
                value: getTranslatedUndoPolicy(data.last_changeset.undo_policy),
              },
              {
                label: 'Статус',
                value: getTranslatedUndoStatus(data.last_changeset.undo_status),
              },
              {
                label: 'Время',
                value: getDisplayText(
                  data.last_changeset.created_at,
                  EMPTY_LABEL,
                ),
              },
            ]}
          />
          <Box color="label" mt={0.25}>
            Создано: {data.last_changeset.created_entries} · Перемещено:{' '}
            {data.last_changeset.moved_entries} · Эффекты:{' '}
            {data.last_changeset.owned_effect_entries}
          </Box>
        </Box>
      )}

      {!!historyEntries.length && (
        <Box>
          {historyEntries.map((entry, index) => (
            <Collapsible
              key={`${entry.time}_${entry.generator_id}_${index}`}
              title={`${entry.time} · ${getGeneratorDisplayName(
                data,
                entry.generator_id,
              )} · ${getHistoryResultText(entry.result)}`}
              color={toneForHistoryResult(entry.result)}
              open={index === 0}
            >
              <Flex wrap mx={-0.18} mb={0.35}>
                <Flex.Item m={0.18}>
                  <StatusPill
                    label="Результат"
                    value={getHistoryResultText(entry.result)}
                    tone={toneForHistoryResult(entry.result)}
                  />
                </Flex.Item>
                {!!entry.undo_policy && (
                  <Flex.Item m={0.18}>
                    <StatusPill
                      label="Откат"
                      value={getTranslatedUndoStatus(entry.undo_status)}
                      tone={getUndoTone(entry.undo_status)}
                    />
                  </Flex.Item>
                )}
              </Flex>
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
                    value: getDisplayText(entry.center_turf, EMPTY_LABEL),
                  },
                  {
                    label: 'Откат',
                    value: entry.undo_policy
                      ? `${getTranslatedUndoPolicy(entry.undo_policy)} / ${getTranslatedUndoStatus(
                          entry.undo_status,
                        )}`
                      : EMPTY_LABEL,
                  },
                  {
                    label: 'Откат / пропуск',
                    value:
                      entry.reverted_count !== undefined ||
                      entry.skipped_count !== undefined
                        ? `${entry.reverted_count ?? 0} / ${entry.skipped_count ?? 0}`
                        : EMPTY_LABEL,
                  },
                ]}
              />
              <Box color="label" mt={0.45}>
                {entry.message || 'Подробности не сохранены.'}
              </Box>
            </Collapsible>
          ))}
        </Box>
      )}
    </SurfaceCard>
  );
};

const WorkspacePage = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
  readonly groupedFields: Record<string, UiField[]>;
  readonly groupNames: string[];
  readonly showPlacementSetup: boolean;
  readonly toolTabs: GeneratorEntry[];
  readonly workspaceTab: WorkspaceTabKey;
  readonly onSelectGenerator: (generatorId: string) => void;
  readonly onSelectWorkspaceTab: (tab: WorkspaceTabKey) => void;
}) => {
  const {
    data,
    act,
    groupedFields,
    groupNames,
    showPlacementSetup,
    toolTabs,
    workspaceTab,
    onSelectGenerator,
    onSelectWorkspaceTab,
  } = props;

  return (
    <Section fill scrollable>
      <EditorChrome
        data={data}
        act={act}
        toolTabs={toolTabs}
        workspaceTab={workspaceTab}
        onSelectGenerator={onSelectGenerator}
        onSelectWorkspaceTab={onSelectWorkspaceTab}
      />

      {!data.has_generator && !!data.categories?.length && (
        <Box color="label" mt={0.1}>
          Загрузка...
        </Box>
      )}

      {!data.has_generator && !data.categories?.length && (
        <Box color="label" mt={0.1}>
          Нет инструментов.
        </Box>
      )}

      {!!data.has_generator &&
        (workspaceTab === 'editor' ? (
          <ToolWorkspace
            data={data}
            act={act}
            groupedFields={groupedFields}
            groupNames={groupNames}
            showPlacementSetup={showPlacementSetup}
          />
        ) : (
          <HistoryWorkspace data={data} act={act} />
        ))}
    </Section>
  );
};

export { WorkspacePage };
