import { Box, Button, LabeledList } from '../../components';
import { FieldControlStack, FieldEditor } from './fieldControls';
import { SurfaceCard } from './primitives';
import type { ActFn, BackendData } from './types';
import { getOutpostWorkspaceViewModel } from './viewModelOutpost';

const OutpostRadiusWorkspace = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
}) => {
  const { data, act } = props;
  const {
    tacticalProfileField,
    layoutVariantField,
    openingWidthField,
    extraLayoutFields,
    perimeterMaterialFields,
    perimeterExtraFields,
    extraFieldGroups,
    extraGroupNames,
  } = getOutpostWorkspaceViewModel(data.ui_fields);

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
              choiceStripBasis="13.6%"
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
      {extraGroupNames.map((groupName) => (
        <SurfaceCard key={groupName} title={groupName} mt={0.6}>
          <LabeledList>
            {extraFieldGroups[groupName].map((field) => (
              <FieldEditor key={field.id} field={field} act={act} />
            ))}
          </LabeledList>
        </SurfaceCard>
      ))}
    </Box>
  );
};

export { OutpostRadiusWorkspace };
