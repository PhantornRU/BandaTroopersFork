import { type ReactNode } from 'react';

import { Box } from '../../components';
import { FieldControlStack } from './fieldControls';
import { getSurfaceColors } from './primitives';
import type { ActFn, UiField } from './types';
import { getDestructionFieldLabel } from './viewModel';

const DESTRUCTION_COLOR_GUIDE = [
  {
    label: 'Перемещение',
    color: '#4e8eff',
  },
  {
    label: 'Огонь',
    color: '#ff9438',
  },
  {
    label: 'Урон',
    color: '#b85cff',
  },
  {
    label: 'Взрыв',
    color: '#ff4e4e',
  },
] as const;

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
              <Box>
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
              </Box>
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

export { DestructionModeBlock, DestructionMovementBlock };
