import { type ReactNode } from 'react';

import { Box, Flex } from '../../components';
import { WORKSPACE_GUTTER } from './constants';
import type {
  PreviewLegendItem,
  SummaryTile,
  SurfaceTone,
  ToneKey,
} from './types';

const CompactStatusRow = (props: {
  readonly items: SummaryTile[];
  readonly basis?: string;
}) => {
  const { items, basis } = props;
  return (
    <Flex wrap mx={-0.25}>
      {items.map((item) => (
        <Flex.Item key={item.label} basis={basis || '24%'} grow m={0.15}>
          <Box>
            <Box as="span" color="label">
              {item.label}:{' '}
            </Box>
            <Box as="span" color={item.color || 'white'}>
              {item.value}
            </Box>
          </Box>
        </Flex.Item>
      ))}
    </Flex>
  );
};

const getToneColors = (tone?: ToneKey) => {
  if (tone === 'good') {
    return {
      borderColor: 'rgba(76, 159, 57, 0.55)',
      background: 'rgba(76, 159, 57, 0.14)',
      textColor: 'good',
    };
  }
  if (tone === 'average') {
    return {
      borderColor: 'rgba(185, 140, 53, 0.55)',
      background: 'rgba(185, 140, 53, 0.14)',
      textColor: 'average',
    };
  }
  if (tone === 'bad') {
    return {
      borderColor: 'rgba(143, 60, 52, 0.62)',
      background: 'rgba(143, 60, 52, 0.18)',
      textColor: 'bad',
    };
  }
  return {
    borderColor: 'rgba(70, 107, 150, 0.45)',
    background: 'rgba(70, 107, 150, 0.10)',
    textColor: 'label',
  };
};

const StatusPill = (props: {
  readonly label: string;
  readonly value: ReactNode;
  readonly tone?: ToneKey;
}) => {
  const { label, value, tone } = props;
  const colors = getToneColors(tone);

  return (
    <Box
      px={0.45}
      py={0.28}
      style={{
        border: `1px solid ${colors.borderColor}`,
        background: colors.background,
        borderRadius: '999px',
      }}
    >
      <Box as="span" color="label">
        {label}:{' '}
      </Box>
      <Box as="span" color={colors.textColor}>
        {value}
      </Box>
    </Box>
  );
};

const PreviewLegend = (props: {
  readonly title?: string;
  readonly items: PreviewLegendItem[];
  readonly mt?: number;
}) => {
  const { title = 'Цвета на карте', items, mt = 0.6 } = props;
  if (!items.length) {
    return null;
  }

  return (
    <Box mt={mt}>
      <Box bold mb={0.3}>
        {title}
      </Box>
      <Flex wrap mx={-0.2}>
        {items.map((item) => (
          <Flex.Item key={item.label} m={0.2}>
            <Box
              px={0.45}
              py={0.25}
              style={{
                border: '1px solid rgba(70, 107, 150, 0.45)',
                borderRadius: '4px',
                background: 'rgba(70, 107, 150, 0.10)',
              }}
            >
              <Box
                as="span"
                mr={0.35}
                style={{
                  display: 'inline-block',
                  width: '0.8rem',
                  height: '0.8rem',
                  borderRadius: '3px',
                  background: item.color,
                  verticalAlign: 'middle',
                }}
              />
              <Box as="span">{item.label}</Box>
            </Box>
          </Flex.Item>
        ))}
      </Flex>
    </Box>
  );
};

const WorkspaceGrid = (props: {
  readonly children: ReactNode;
  readonly gutter?: number;
}) => {
  const { children, gutter = WORKSPACE_GUTTER } = props;
  return (
    <Flex wrap mx={-gutter}>
      {children}
    </Flex>
  );
};

const WorkspacePane = (props: {
  readonly children: ReactNode;
  readonly basis: string;
  readonly minWidth: string;
  readonly gutter?: number;
  readonly grow?: boolean;
}) => {
  const {
    children,
    basis,
    minWidth,
    gutter = WORKSPACE_GUTTER,
    grow = true,
  } = props;
  return (
    <Flex.Item basis={basis} grow={grow} m={gutter} style={{ minWidth }}>
      {children}
    </Flex.Item>
  );
};

const getSurfaceColors = (tone?: SurfaceTone) => ({
  borderColor:
    tone === 'good'
      ? '#4c9f39'
      : tone === 'average'
        ? '#b98c35'
        : tone === 'bad'
          ? '#8f3c34'
          : '#466b96',
  background:
    tone === 'good'
      ? 'rgba(76, 159, 57, 0.12)'
      : tone === 'average'
        ? 'rgba(185, 140, 53, 0.12)'
        : tone === 'bad'
          ? 'rgba(143, 60, 52, 0.16)'
          : 'rgba(70, 107, 150, 0.12)',
});

const SurfaceCard = (props: {
  readonly title?: ReactNode;
  readonly subtitle?: ReactNode;
  readonly tone?: SurfaceTone;
  readonly actions?: ReactNode;
  readonly children: ReactNode;
  readonly mt?: number;
}) => {
  const { title, subtitle, tone, actions, children, mt } = props;
  const { borderColor, background } = getSurfaceColors(tone);
  const hasHeader = !!title || !!subtitle || !!actions;

  return (
    <Box
      mt={mt}
      p={0.65}
      style={{
        border: `1px solid ${borderColor}`,
        background,
        borderRadius: '4px',
      }}
    >
      {hasHeader && (
        <Flex align="center" wrap mb={0.4}>
          <Flex.Item grow basis="14rem">
            {!!title && <Box bold>{title}</Box>}
            {!!subtitle && (
              <Box color="label" mt={title ? 0.1 : 0}>
                {subtitle}
              </Box>
            )}
          </Flex.Item>
          {!!actions && <Flex.Item>{actions}</Flex.Item>}
        </Flex>
      )}
      {children}
    </Box>
  );
};

export {
  CompactStatusRow,
  getSurfaceColors,
  PreviewLegend,
  StatusPill,
  SurfaceCard,
  WorkspaceGrid,
  WorkspacePane,
};
