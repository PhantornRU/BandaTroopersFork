import { Box, Button, LabeledList } from '../../components';
import { RADIUS_POLICY_FIELD_IDS } from './constants';
import { FieldControlStack, FieldEditor } from './fieldControls';
import { getField, getFieldsByGroup, getFieldsById } from './helpers';
import { SurfaceCard } from './primitives';
import type { ActFn, BackendData } from './types';

const LAYOUT_GROUP_ALIASES = [
  'Схема',
  'Компоновка',
  'Layout',
  'Профиль и вариант',
  'Тактический профиль и схема',
];

const PERIMETER_GROUP_ALIASES = [
  'Периметр',
  'Perimeter',
  'Баррикады',
  'Barricades',
];

const DEFENSE_GROUP_ALIASES = [
  'Оборона',
  'Defense',
  'Турели',
  'Sentries',
];

const PERIMETER_MATERIAL_FIELD_IDS = [
  'barricade_path',
  'primary_material_path',
  'primary_barricade_path',
  'secondary_material_path',
  'secondary_barricade_path',
  'primary_door_path',
  'secondary_door_path',
  'barricade_pattern',
  'barricade_concentration_percent',
  'primary_material_share_percent',
  'place_barricade_doors',
];

const DEFENSE_DETAIL_FIELD_IDS = [
  'guard_mode',
  'sentry_profile',
  'sentry_path',
  'faction',
  'turned_on',
];

const getFieldsByGroupAliases = (
  fields: BackendData['ui_fields'],
  aliases: string[],
) => {
  const matchedFields: BackendData['ui_fields'] = [];
  const seenLookup = new Set<string>();

  for (const alias of aliases) {
    const matched = getFieldsByGroup(fields, alias);
    for (const field of matched) {
      if (seenLookup.has(field.id)) {
        continue;
      }
      seenLookup.add(field.id);
      matchedFields.push(field);
    }
  }

  return matchedFields;
};

const getFieldByIds = (fields: BackendData['ui_fields'], ids: string[]) => {
  for (const id of ids) {
    const field = getField(fields, id);
    if (field) {
      return field;
    }
  }

  return undefined;
};

const OutpostRadiusWorkspace = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
}) => {
  const { data, act } = props;
  const layoutFields = getFieldsByGroupAliases(
    data.ui_fields,
    LAYOUT_GROUP_ALIASES,
  ).filter(
    (field) =>
      field.id !== 'radius' && !RADIUS_POLICY_FIELD_IDS.includes(field.id),
  );
  const tacticalProfileField =
    getFieldByIds(data.ui_fields, ['defense_profile', 'family']) ||
    getField(layoutFields, 'defense_profile') ||
    getField(layoutFields, 'family');
  const layoutVariantField =
    getFieldByIds(layoutFields, ['layout_variant']) ||
    getField(data.ui_fields, 'layout_variant');
  const openingWidthField =
    getFieldByIds(layoutFields, ['opening_width']) ||
    getField(data.ui_fields, 'opening_width');
  const extraLayoutFields = layoutFields.filter(
    (field) =>
      !['defense_profile', 'family', 'layout_variant', 'opening_width'].includes(
        field.id,
      ),
  );
  const perimeterFields = getFieldsByGroupAliases(
    data.ui_fields,
    PERIMETER_GROUP_ALIASES,
  );
  const perimeterMaterialFields = getFieldsById(
    data.ui_fields,
    PERIMETER_MATERIAL_FIELD_IDS,
  ).filter((field) => field.visible !== false);
  const perimeterExtraFields = perimeterFields.filter(
    (field) =>
      field.visible !== false &&
      !PERIMETER_MATERIAL_FIELD_IDS.includes(field.id),
  );
  const defenseFields = getFieldsByGroupAliases(
    data.ui_fields,
    DEFENSE_GROUP_ALIASES,
  );
  const sentryToggleField =
    getFieldByIds(data.ui_fields, ['place_sentries']) ||
    getField(defenseFields, 'place_sentries');
  const sentryDetailFields = getFieldsById(
    data.ui_fields,
    DEFENSE_DETAIL_FIELD_IDS,
  ).filter((field) => field.visible !== false);
  const extraDefenseFields = defenseFields.filter(
    (field) =>
      field.visible !== false &&
      field.id !== 'place_sentries' &&
      !DEFENSE_DETAIL_FIELD_IDS.includes(field.id),
  );

  return (
    <Box>
      <SurfaceCard
        title="Тактический профиль и схема"
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
          <FieldControlStack field={tacticalProfileField} act={act} />
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
      <SurfaceCard title="Периметр" mt={0.6}>
        {!!perimeterMaterialFields.length && (
          <Box
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(2, minmax(0, 1fr))',
              gap: '0.6rem',
            }}
          >
            {perimeterMaterialFields.map((field) => (
              <FieldControlStack key={field.id} field={field} act={act} />
            ))}
          </Box>
        )}
        {!!perimeterExtraFields.length && (
          <Box mt={0.6}>
            <LabeledList>
              {perimeterExtraFields.map((field) => (
                <FieldEditor key={field.id} field={field} act={act} />
              ))}
            </LabeledList>
          </Box>
        )}
      </SurfaceCard>
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
        {!!extraDefenseFields.length && (
          <Box mt={0.6}>
            <LabeledList>
              {extraDefenseFields.map((field) => (
                <FieldEditor key={field.id} field={field} act={act} />
              ))}
            </LabeledList>
          </Box>
        )}
      </SurfaceCard>
    </Box>
  );
};

export { OutpostRadiusWorkspace };
