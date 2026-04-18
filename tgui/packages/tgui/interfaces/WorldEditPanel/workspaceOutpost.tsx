import { Box, Button, LabeledList } from '../../components';
import { RADIUS_POLICY_FIELD_IDS } from './constants';
import { FieldControlStack, FieldEditor, FieldListCard } from './fieldControls';
import { getField, getFieldsByGroup, getFieldsById } from './helpers';
import { SurfaceCard } from './primitives';
import type { ActFn, BackendData } from './types';

const getFieldsByGroupAliases = (
  fields: BackendData['ui_fields'],
  aliases: string[],
) => {
  for (const alias of aliases) {
    const matched = getFieldsByGroup(fields, alias);
    if (matched.length) {
      return matched;
    }
  }

  return [];
};

const OutpostRadiusWorkspace = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
}) => {
  const { data, act } = props;
  const sentryFields = getFieldsByGroupAliases(data.ui_fields, [
    'Турели',
    'Sentries',
  ]);
  const barricadeFields = getFieldsByGroupAliases(data.ui_fields, [
    'Баррикады',
    'Barricades',
  ]);
  const layoutFields = getFieldsByGroupAliases(data.ui_fields, [
    'Компоновка',
    'Layout',
  ]).filter(
    (field) =>
      field.id !== 'radius' && !RADIUS_POLICY_FIELD_IDS.includes(field.id),
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

export { OutpostRadiusWorkspace };
