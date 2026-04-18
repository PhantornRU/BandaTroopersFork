import type { ReactNode } from 'react';

import { Box, Button, Icon } from '../../components';
import {
  CHROME_CONTROL_BUTTON_HEIGHT,
  CHROME_CONTROL_BUTTON_STYLE,
  CHROME_CONTROL_COLUMN_PADDING,
  CHROME_DIRECTION_BUTTON_GAP,
  CHROME_DIRECTION_COMPASS_WIDTH,
  CHROME_ICON_BUTTON_STYLE,
  CHROME_PLACEMENT_SECTION_GAP,
  CHROME_SHARED_CENTER_STYLE,
  CHROME_SQUARE_BUTTON_SIZE,
  DIRECTION_BUTTON_LABELS,
} from './chromeLayout';
import { getTranslatedDirection } from './helpers';
import type { ChoiceOption } from './types';

const ControlSectionLabel = (props: { readonly children: ReactNode }) => (
  <Box color="label" mb={0.18}>
    {props.children}
  </Box>
);

const ToolbarControlColumn = (props: {
  readonly label: ReactNode;
  readonly width: string;
  readonly separated?: boolean;
  readonly align?: 'stretch' | 'center';
  readonly children: ReactNode;
}) => {
  const {
    label,
    width,
    separated = false,
    align = 'stretch',
    children,
  } = props;

  return (
    <Box
      style={{
        width,
        minWidth: width,
        paddingLeft: separated ? CHROME_CONTROL_COLUMN_PADDING : '0',
        borderLeft: separated ? '1px solid rgba(70, 107, 150, 0.35)' : 'none',
        display: 'grid',
        rowGap: CHROME_PLACEMENT_SECTION_GAP,
        alignContent: 'start',
        justifyItems: align === 'center' ? 'center' : 'stretch',
      }}
    >
      <ControlSectionLabel>{label}</ControlSectionLabel>
      {children}
    </Box>
  );
};

const ToolbarReadOnlyValue = (props: {
  readonly value: ReactNode;
  readonly disabled?: boolean;
}) => {
  const { value, disabled } = props;

  return (
    <Box
      px={0.35}
      color={disabled ? 'label' : 'white'}
      style={{
        ...CHROME_SHARED_CENTER_STYLE,
        width: '100%',
        minHeight: CHROME_CONTROL_BUTTON_HEIGHT,
        height: CHROME_CONTROL_BUTTON_HEIGHT,
        border: `1px solid ${
          disabled ? 'rgba(70, 107, 150, 0.25)' : 'rgba(70, 107, 150, 0.45)'
        }`,
        background: disabled
          ? 'rgba(70, 107, 150, 0.05)'
          : 'rgba(70, 107, 150, 0.12)',
        borderRadius: '4px',
      }}
    >
      {value}
    </Box>
  );
};

const FillButtonText = (props: { readonly children: string }) => (
  <Box
    as="span"
    style={{
      display: 'block',
      width: '100%',
      lineHeight: '1',
      textAlign: 'center',
      whiteSpace: 'nowrap',
    }}
  >
    {props.children}
  </Box>
);

const InlineButtonText = (props: { readonly children: string }) => (
  <Box
    as="span"
    style={{
      display: 'inline-block',
      lineHeight: '1',
      textAlign: 'center',
      whiteSpace: 'nowrap',
    }}
  >
    {props.children}
  </Box>
);

const CenteredIcon = (props: { readonly name: string }) => (
  <Box
    as="span"
    style={{
      display: 'flex',
      width: '100%',
      height: '100%',
      alignItems: 'center',
      justifyContent: 'center',
      textAlign: 'center',
    }}
  >
    <Icon
      name={props.name}
      style={{
        marginLeft: '0',
        marginRight: '0',
        minWidth: '0',
      }}
    />
  </Box>
);

const CompactIconLabel = (props: {
  readonly icon: string;
  readonly label: string;
}) => (
  <Box
    as="span"
    style={{
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      gap: '0.25rem',
      width: '100%',
      whiteSpace: 'nowrap',
    }}
  >
    <Icon
      name={props.icon}
      style={{
        marginLeft: '0',
        marginRight: '0',
        minWidth: '1rem',
      }}
    />
    <InlineButtonText>{props.label}</InlineButtonText>
  </Box>
);

const CompactToggleButton = (props: {
  readonly checked: boolean;
  readonly label: string;
  readonly disabled?: boolean;
  readonly tooltip?: string;
  readonly onClick: () => void;
}) => (
  <Button
    compact
    verticalAlignContent="middle"
    selected={props.checked}
    color={props.checked ? 'good' : 'transparent'}
    disabled={props.disabled}
    tooltip={props.tooltip}
    onClick={props.onClick}
    style={CHROME_CONTROL_BUTTON_STYLE}
  >
    <CompactIconLabel
      icon={props.checked ? 'check-square-o' : 'square-o'}
      label={props.label}
    />
  </Button>
);

const CompactStackedChoiceButtons = (props: {
  readonly options: ChoiceOption[];
  readonly selected: string;
  readonly disabled?: boolean;
  readonly onSelected: (value: string) => void;
}) => (
  <Box
    style={{
      display: 'grid',
      rowGap: '0.18rem',
      justifyItems: 'stretch',
    }}
  >
    {props.options.map((option) => {
      const isSelected = `${option.value}` === `${props.selected}`;
      return (
        <Button
          key={option.value}
          compact
          verticalAlignContent="middle"
          selected={isSelected}
          color={isSelected ? 'good' : undefined}
          disabled={props.disabled}
          tooltip={option.tooltip || option.displayText}
          onClick={() => props.onSelected(option.value)}
          style={CHROME_CONTROL_BUTTON_STYLE}
        >
          <FillButtonText>{option.displayText}</FillButtonText>
        </Button>
      );
    })}
  </Box>
);

const DirectionCompass = (props: {
  readonly options: ChoiceOption[];
  readonly selected: string;
  readonly usesFacing: boolean;
  readonly disabled?: boolean;
  readonly onSelected: (value: string) => void;
}) => {
  const { options, selected, usesFacing, disabled, onSelected } = props;
  const availableValues = new Set(
    options.map((option) => `${option.value}`.trim().toLowerCase()),
  );
  const effectiveSelected = `${selected}`.trim().toLowerCase();

  const renderDirectionButton = (value: string) => {
    if (!availableValues.has(value)) {
      return null;
    }

    return (
      <Button
        key={value}
        compact
        verticalAlignContent="middle"
        selected={!usesFacing && effectiveSelected === value}
        color={!usesFacing && effectiveSelected === value ? 'good' : undefined}
        disabled={disabled}
        tooltip={getTranslatedDirection(value)}
        onClick={() => onSelected(value)}
        style={CHROME_ICON_BUTTON_STYLE}
      >
        <Box
          as="span"
          style={{
            display: 'flex',
            width: '100%',
            height: '100%',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: '1rem',
            lineHeight: '1',
          }}
        >
          {DIRECTION_BUTTON_LABELS[value] || getTranslatedDirection(value)}
        </Box>
      </Button>
    );
  };

  return (
    <Box
      style={{
        width: CHROME_DIRECTION_COMPASS_WIDTH,
        minWidth: CHROME_DIRECTION_COMPASS_WIDTH,
        display: 'grid',
        gridTemplateColumns: `repeat(3, ${CHROME_SQUARE_BUTTON_SIZE})`,
        gridTemplateRows: `repeat(3, ${CHROME_SQUARE_BUTTON_SIZE})`,
        justifyContent: 'center',
        justifyItems: 'center',
        alignItems: 'center',
        columnGap: CHROME_DIRECTION_BUTTON_GAP,
        rowGap: CHROME_DIRECTION_BUTTON_GAP,
      }}
    >
      <Box style={{ gridColumn: '2', gridRow: '1' }}>
        {renderDirectionButton('north')}
      </Box>
      <Box style={{ gridColumn: '1', gridRow: '2' }}>
        {renderDirectionButton('west')}
      </Box>
      <Box style={{ gridColumn: '3', gridRow: '2' }}>
        {renderDirectionButton('east')}
      </Box>
      <Box style={{ gridColumn: '2', gridRow: '3' }}>
        {renderDirectionButton('south')}
      </Box>
    </Box>
  );
};

export {
  CenteredIcon,
  CompactStackedChoiceButtons,
  CompactToggleButton,
  DirectionCompass,
  ToolbarControlColumn,
  ToolbarReadOnlyValue,
};
