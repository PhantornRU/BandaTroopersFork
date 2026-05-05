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

const DESTRUCTION_MOVEMENT_GRID_COLUMNS =
  'minmax(0, 1.05fr) minmax(15rem, 0.95fr)';
const DESTRUCTION_MOVEMENT_COLUMN_GAP = '0.85rem';
const DESTRUCTION_MOVEMENT_ROW_GAP = '0.58rem';

const DestructionSplitBlock = (props: {
  readonly title: string;
  readonly tone?: 'default' | 'good' | 'average' | 'bad';
  readonly headerAside?: ReactNode;
  readonly headerColumns?: string;
  readonly headerColumnGap?: string;
  readonly children: ReactNode;
}) => {
  const { title, tone, headerAside, headerColumns, headerColumnGap, children } =
    props;
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
      {headerAside ? (
        <Box
          style={{
            display: 'grid',
            gridTemplateColumns: headerColumns || 'minmax(0, 1fr) auto',
            columnGap: headerColumnGap || DESTRUCTION_MOVEMENT_COLUMN_GAP,
            alignItems: 'start',
          }}
        >
          <Box bold>{title}</Box>
          <Box bold style={{ minWidth: '0' }}>
            {headerAside}
          </Box>
        </Box>
      ) : (
        <Box bold>{title}</Box>
      )}
      <Box mt={0.4}>{children}</Box>
    </Box>
  );
};

const DestructionColorGuide = (props: {
  readonly activeItems: { label: string; color: string }[];
  readonly showTitle?: boolean;
}) => {
  const { activeItems, showTitle = true } = props;
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
      {showTitle && <Box bold>Цвета на карте</Box>}
      <Box
        mt={showTitle ? 0.35 : 0}
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
  const leftFieldEntries: { key: string; field: UiField }[] = [
    ...(shuffleField ? [{ key: 'shuffle', field: shuffleField }] : []),
    ...(scatterField ? [{ key: 'scatter', field: scatterField }] : []),
    ...(maxAtomsField ? [{ key: 'maxAtoms', field: maxAtomsField }] : []),
  ];
  const scatterStepsRow = scatterStepsField
    ? leftFieldEntries.length > 1
      ? leftFieldEntries.length
      : 2
    : undefined;
  const legendRowSpan = scatterStepsField
    ? Math.max((scatterStepsRow || 1) - 1, 1)
    : Math.max(leftFieldEntries.length, 1);

  return (
    <DestructionSplitBlock
      title="Перемещение"
      tone={tone}
      headerAside="Цвета на карте"
      headerColumns={DESTRUCTION_MOVEMENT_GRID_COLUMNS}
      headerColumnGap={DESTRUCTION_MOVEMENT_COLUMN_GAP}
    >
      <Box
        style={{
          display: 'grid',
          gridTemplateColumns: DESTRUCTION_MOVEMENT_GRID_COLUMNS,
          columnGap: DESTRUCTION_MOVEMENT_COLUMN_GAP,
          rowGap: DESTRUCTION_MOVEMENT_ROW_GAP,
          alignItems: 'start',
        }}
      >
        {leftFieldEntries.map((entry, index) => (
          <Box
            key={entry.key}
            style={{
              minWidth: '0',
              gridColumn: '1',
              gridRow: `${index + 1}`,
            }}
          >
            <FieldControlStack
              field={entry.field}
              act={act}
              labelOverride={getDestructionFieldLabel(entry.field)}
              showHint={false}
            />
          </Box>
        ))}
        <Box
          style={{
            minWidth: '0',
            gridColumn: '2',
            gridRow: `1 / span ${legendRowSpan}`,
            alignSelf: 'start',
          }}
        >
          <DestructionColorGuide activeItems={activeItems} showTitle={false} />
        </Box>
        {!!scatterStepsField && (
          <Box
            style={{
              minWidth: '0',
              gridColumn: '2',
              gridRow: `${scatterStepsRow}`,
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
