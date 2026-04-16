import { useMemo, useState } from 'react';

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
  getSafeFieldList,
  getTranslatedUndoPolicy,
  getTranslatedUndoStatus,
  getUndoTone,
  isBlankDisplayValue,
  toneForHistoryResult,
} from './helpers';
import {
  CompactStatusRow,
  PreviewLegend,
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
const getBlueprintLibraryMetaText = (blueprint: BlueprintEntry) => {
  const parts = [
    `${getPositiveCountText(blueprint.entry_count, '0')} РѕР±СЉРµРєС‚РѕРІ`,
    `r${getPositiveCountText(blueprint.radius, '0')}`,
  ];
  if (!isBlankDisplayValue(blueprint.source)) {
    parts.push(`${blueprint.source}`);
  }
  return parts.join(' В· ');
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
      title="Р‘РёР±Р»РёРѕС‚РµРєР°"
      subtitle={`${filteredBlueprints.length} РёР· ${totalBlueprints}`}
      actions={
        <Button compact onClick={() => act('list_blueprints')}>
          РћР±РЅРѕРІРёС‚СЊ
        </Button>
      }
      mt={0}
    >
      <Input
        value={searchQuery}
        placeholder="РџРѕРёСЃРє"
        onChange={(_, value) => setSearchQuery(value)}
      />

      {!data.blueprint_entries?.length && (
        <Box color="label" mt={0.7}>
          РќРµС‚ С€Р°Р±Р»РѕРЅРѕРІ.
        </Box>
      )}

      {!!data.blueprint_entries?.length && !filteredBlueprints.length && (
        <Box color="label" mt={0.7}>
          РќРёС‡РµРіРѕ РЅРµ РЅР°Р№РґРµРЅРѕ.
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
                      {getDisplayText(
                        blueprint.name,
                        'РЁР°Р±Р»РѕРЅ Р±РµР· РёРјРµРЅРё',
                      )}
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
                        РђРєС‚РёРІРµРЅ
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
                    {blueprint.error || 'РЁР°Р±Р»РѕРЅ РЅРµРґРѕСЃС‚СѓРїРµРЅ.'}
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
        title="РџСЂРѕС„РёР»СЊ Рё РІР°СЂРёР°РЅС‚"
        mt={0}
        actions={
          data.can_save_blueprint_from_plan ? (
            <Button compact onClick={() => act('save_blueprint')}>
              РЎРѕС…СЂР°РЅРёС‚СЊ РєР°Рє С€Р°Р±Р»РѕРЅ
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
      <FieldListCard
        title="РџРµСЂРёРјРµС‚СЂ"
        fields={barricadeFields}
        act={act}
      />
      <SurfaceCard title="РћР±РѕСЂРѕРЅР°" mt={0.6}>
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
  const safeMovementFields = [
    ...getFieldsById(data.ui_fields, ['shuffle_enabled', 'scatter_enabled']),
    ...getSafeFieldList(data.ui_fields, ['scatter_steps', 'max_atoms']),
  ];
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
  const visibleMovementFields = safeMovementFields.filter(
    (field) => field.visible !== false,
  );
  const previewLegendItems = getDestructionPreviewLegendItems(data);

  return (
    <>
      {!!previewLegendItems.length && (
        <PreviewLegend items={previewLegendItems} mt={0} />
      )}

      {(!!visibleAreaFields.length || !!visibleMovementFields.length) && (
        <SurfaceCard
          title="Р‘РµР·РѕРїР°СЃРЅР°СЏ Р·РѕРЅР°"
          subtitle="Р‘РµР· РІР·СЂС‹РІР° Рё СѓСЂРѕРЅР°"
        >
          <WorkspaceGrid>
            {!!visibleMovementFields.length && (
              <WorkspacePane
                basis={visibleAreaFields.length ? '48%' : '100%'}
                minWidth="19rem"
              >
                <FieldBlock
                  title="РџРµСЂРµРјРµС‰РµРЅРёРµ"
                  fields={visibleMovementFields}
                  act={act}
                  tone={movementEnabled ? 'average' : 'default'}
                />
              </WorkspacePane>
            )}
            {!!visibleAreaFields.length && (
              <WorkspacePane basis="48%" minWidth="19rem">
                <FieldBlock
                  title="Р—РѕРЅР°"
                  fields={visibleAreaFields}
                  act={act}
                />
              </WorkspacePane>
            )}
          </WorkspaceGrid>
        </SurfaceCard>
      )}

      <SurfaceCard
        title="РћРїР°СЃРЅС‹Рµ СЂРµР¶РёРјС‹"
        mt={visibleAreaFields.length || visibleMovementFields.length ? 0.6 : 0}
        tone={destructiveEnabled ? 'bad' : fireEnabled ? 'average' : 'default'}
      >
        <WorkspaceGrid>
          <WorkspacePane basis="33%" minWidth="16rem">
            <FieldBlock
              title="РћРіРѕРЅСЊ"
              fields={fireFields}
              act={act}
              tone={fireEnabled ? 'average' : 'default'}
            />
          </WorkspacePane>
          <WorkspacePane basis="33%" minWidth="16rem">
            <FieldBlock
              title="Р’Р·СЂС‹РІ"
              subtitle={
                blastEnabled ? 'РћС‚РєР°С‚ РѕРіСЂР°РЅРёС‡РµРЅ' : undefined
              }
              fields={blastFields}
              act={act}
              tone={blastEnabled ? 'bad' : 'default'}
            />
          </WorkspacePane>
          <WorkspacePane basis="33%" minWidth="16rem">
            <FieldBlock
              title="РЎС‚СЂСѓРєС‚СѓСЂРЅС‹Р№ СѓСЂРѕРЅ"
              subtitle={
                damageProfile !== 'none'
                  ? 'РћС‚РєР°С‚ РѕРіСЂР°РЅРёС‡РµРЅ'
                  : undefined
              }
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
    return (
      <Box color="label">РџРѕР»СЏ РІСЂРµРјРµРЅРЅРѕ РЅРµРґРѕСЃС‚СѓРїРЅС‹.</Box>
    );
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
      {!hasPrimaryContent && <Box color="label">РќРµС‚ РЅР°СЃС‚СЂРѕРµРє.</Box>}

      {!!data.has_inline_fields && (
        <GenericFieldGroups
          groupedFields={groupedFields}
          groupNames={groupNames}
          act={act}
        />
      )}

      {!data.has_inline_fields && showPlacementSetup && (
        <Box color="label">
          РЈРїСЂР°РІР»РµРЅРёРµ СЂРµР¶РёРјРѕРј РЅР°С…РѕРґРёС‚СЃСЏ РІС‹С€Рµ.
        </Box>
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
      title="Р–СѓСЂРЅР°Р»"
      actions={
        <Flex wrap mx={-0.2}>
          <Flex.Item m={0.2}>
            <Button
              compact
              color="average"
              disabled={!data.can_cleanup_last_owned_effects}
              onClick={() => act('cleanup_last_owned_effects')}
            >
              РћС‡РёСЃС‚РёС‚СЊ СЌС„С„РµРєС‚С‹
            </Button>
          </Flex.Item>
          <Flex.Item m={0.2}>
            <Button
              compact
              color="average"
              onClick={() => act('clear_history')}
            >
              РћС‡РёСЃС‚РёС‚СЊ Р¶СѓСЂРЅР°Р»
            </Button>
          </Flex.Item>
        </Flex>
      }
    >
      {!data.last_changeset && !historyEntries.length && (
        <Box color="label">Р–СѓСЂРЅР°Р» РїСѓСЃС‚.</Box>
      )}

      {!!historyEntries.length && (
        <Box mb={0.55}>
          <Flex wrap mx={-0.2}>
            <Flex.Item m={0.2}>
              <StatusPill
                label="Р—Р°РїРёСЃРµР№"
                value={`${historyMetrics.total}`}
                tone="label"
              />
            </Flex.Item>
            <Flex.Item m={0.2}>
              <StatusPill
                label="РЈСЃРїРµС…"
                value={`${historyMetrics.good}`}
                tone="good"
              />
            </Flex.Item>
            <Flex.Item m={0.2}>
              <StatusPill
                label="Р§Р°СЃС‚РёС‡РЅРѕ"
                value={`${historyMetrics.average}`}
                tone="average"
              />
            </Flex.Item>
            <Flex.Item m={0.2}>
              <StatusPill
                label="РџСЂРѕР±Р»РµРјС‹"
                value={`${historyMetrics.bad}`}
                tone="bad"
              />
            </Flex.Item>
            <Flex.Item m={0.2}>
              <StatusPill
                label="РћС‚РєР°С‚"
                value={
                  data.can_undo_last_operation
                    ? 'Р”РѕСЃС‚СѓРїРµРЅ'
                    : data.can_cleanup_last_owned_effects
                      ? 'РћС‡РёСЃС‚РєР°'
                      : 'РќРµС‚'
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
              <Box bold>РџРѕСЃР»РµРґРЅСЏСЏ РѕРїРµСЂР°С†РёСЏ</Box>
              <Box color="label" mt={0.1}>
                Р‘С‹СЃС‚СЂС‹Р№ СЃСЂРµР· РїРѕ undo/callback surface.
              </Box>
            </Flex.Item>
            <Flex.Item>
              <StatusPill
                label="РЎС‚Р°С‚СѓСЃ"
                value={getTranslatedUndoStatus(data.last_changeset.undo_status)}
                tone={getUndoTone(data.last_changeset.undo_status)}
              />
            </Flex.Item>
          </Flex>
          <CompactStatusRow
            basis="32%"
            items={[
              {
                label: 'РРЅСЃС‚СЂСѓРјРµРЅС‚',
                value: getGeneratorDisplayName(
                  data,
                  data.last_changeset.generator_id,
                ),
              },
              {
                label: 'РћС‚РєР°С‚',
                value: getTranslatedUndoPolicy(data.last_changeset.undo_policy),
              },
              {
                label: 'РЎС‚Р°С‚СѓСЃ',
                value: getTranslatedUndoStatus(data.last_changeset.undo_status),
              },
              {
                label: 'Р’СЂРµРјСЏ',
                value: getDisplayText(
                  data.last_changeset.created_at,
                  EMPTY_LABEL,
                ),
              },
            ]}
          />
          <Box color="label" mt={0.25}>
            РЎРѕР·РґР°РЅРѕ: {data.last_changeset.created_entries} В·
            РџРµСЂРµРјРµС‰РµРЅРѕ: {data.last_changeset.moved_entries} В·
            Р­С„С„РµРєС‚С‹: {data.last_changeset.owned_effect_entries}
          </Box>
        </Box>
      )}

      {!!historyEntries.length && (
        <Box>
          {historyEntries.map((entry, index) => (
            <Collapsible
              key={`${entry.time}_${entry.generator_id}_${index}`}
              title={`${entry.time} В· ${getGeneratorDisplayName(
                data,
                entry.generator_id,
              )} В· ${getHistoryResultText(entry.result)}`}
              color={toneForHistoryResult(entry.result)}
              open={index === 0}
            >
              <Flex wrap mx={-0.18} mb={0.35}>
                <Flex.Item m={0.18}>
                  <StatusPill
                    label="Р РµР·СѓР»СЊС‚Р°С‚"
                    value={getHistoryResultText(entry.result)}
                    tone={toneForHistoryResult(entry.result)}
                  />
                </Flex.Item>
                {!!entry.undo_policy && (
                  <Flex.Item m={0.18}>
                    <StatusPill
                      label="РћС‚РєР°С‚"
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
                    label: 'РЎРѕР·РґР°РЅРѕ',
                    value: `${entry.created_count}`,
                  },
                  {
                    label: 'РЈРґР°Р»РµРЅРѕ',
                    value: `${entry.deleted_count}`,
                  },
                  {
                    label: 'Р¦РµРЅС‚СЂ',
                    value: getDisplayText(entry.center_turf, EMPTY_LABEL),
                  },
                  {
                    label: 'РћС‚РєР°С‚',
                    value: entry.undo_policy
                      ? `${getTranslatedUndoPolicy(entry.undo_policy)} / ${getTranslatedUndoStatus(
                          entry.undo_status,
                        )}`
                      : EMPTY_LABEL,
                  },
                  {
                    label: 'РћС‚РєР°С‚ / РїСЂРѕРїСѓСЃРє',
                    value:
                      entry.reverted_count !== undefined ||
                      entry.skipped_count !== undefined
                        ? `${entry.reverted_count ?? 0} / ${entry.skipped_count ?? 0}`
                        : EMPTY_LABEL,
                  },
                ]}
              />
              <Box color="label" mt={0.45}>
                {entry.message ||
                  'РџРѕРґСЂРѕР±РЅРѕСЃС‚Рё РЅРµ СЃРѕС…СЂР°РЅРµРЅС‹.'}
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
        <SurfaceCard title="РћС‚РєСЂС‹РІР°РµРј РёРЅСЃС‚СЂСѓРјРµРЅС‚">
          <Box color="label">
            РџРµСЂРІС‹Р№ РґРѕСЃС‚СѓРїРЅС‹Р№ РёРЅСЃС‚СЂСѓРјРµРЅС‚
            РїРѕРґРіСЂСѓР¶Р°РµС‚СЃСЏ Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРё.
          </Box>
        </SurfaceCard>
      )}

      {!data.has_generator && !data.categories?.length && (
        <SurfaceCard title="Р’С‹Р±РµСЂРёС‚Рµ РёРЅСЃС‚СЂСѓРјРµРЅС‚">
          <Box color="label">
            РЁР°Р±Р»РѕРЅ, С„РѕСЂРїРѕСЃС‚, СЂР°Р·СЂСѓС€РµРЅРёРµ.
          </Box>
        </SurfaceCard>
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
