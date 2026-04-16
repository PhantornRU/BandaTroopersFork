import { type ReactNode } from 'react';

import {
  Box,
  Button,
  Dropdown,
  Flex,
  Input,
  LabeledList,
  NumberInput,
} from '../../components';
import {
  PLACEMENT_SHAPE_GLYPHS,
  SMALL_CHOICE_DROPDOWN_THRESHOLD,
} from './constants';
import {
  getFieldOptionLabel,
  getOrderedShapeValues,
  getPlacementOptionValueSet,
  getTranslatedFieldLabel,
  getTranslatedShapeLabel,
  getVisibleFields,
  translateOptionLabel,
} from './helpers';
import { getSurfaceColors, SurfaceCard } from './primitives';
import type {
  ActFn,
  ChoiceOption,
  PlacementOption,
  SurfaceTone,
  UiField,
} from './types';

const ChoiceStrip = (props: {
  readonly options: ChoiceOption[];
  readonly selected: string;
  readonly disabled?: boolean;
  readonly basis?: string;
  readonly onSelected: (value: string) => void;
}) => {
  const { options, selected, disabled, basis, onSelected } = props;
  const itemBasis = basis || (options.length <= 2 ? '45%' : '22%');

  if (!options.length) {
    return <Box color="label">РќРµС‚ РІР°СЂРёР°РЅС‚РѕРІ.</Box>;
  }

  return (
    <Flex wrap mx={-0.15}>
      {options.map((option) => {
        const isSelected = `${option.value}` === `${selected}`;
        return (
          <Flex.Item key={option.value} grow basis={itemBasis} m={0.15}>
            <Button
              compact
              fluid
              selected={isSelected}
              disabled={disabled}
              onClick={() => onSelected(option.value)}
            >
              {option.displayText}
            </Button>
          </Flex.Item>
        );
      })}
    </Flex>
  );
};

const SmartSelect = (props: {
  readonly options: ChoiceOption[];
  readonly selected: string;
  readonly displayText: string;
  readonly disabled?: boolean;
  readonly placeholder?: string;
  readonly forceDropdown?: boolean;
  readonly onSelected: (value: string) => void;
}) => {
  const {
    options,
    selected,
    displayText,
    disabled,
    placeholder,
    forceDropdown,
    onSelected,
  } = props;

  if (forceDropdown || options.length >= SMALL_CHOICE_DROPDOWN_THRESHOLD) {
    return (
      <Dropdown
        width="100%"
        options={options}
        selected={selected}
        displayText={displayText}
        disabled={disabled || !options.length}
        placeholder={placeholder}
        onSelected={(value) => onSelected(`${value}`)}
      />
    );
  }

  return (
    <ChoiceStrip
      options={options}
      selected={selected}
      disabled={disabled || !options.length}
      onSelected={onSelected}
    />
  );
};

type FieldChoiceOption = {
  value: string;
  displayText: string;
  rawValue: unknown;
};

const getFieldChoiceOptions = (field?: UiField): FieldChoiceOption[] =>
  (field?.options || []).map((option) => ({
    value: `${option.value}`,
    displayText: translateOptionLabel(
      field?.id || '',
      option.label,
      option.value,
    ),
    rawValue: option.value,
  }));

const getSelectedFieldChoiceValue = (field?: UiField) =>
  `${field?.value ?? ''}`;

const ShapeOptionStrip = (props: {
  readonly options: PlacementOption[];
  readonly selected: string;
  readonly disabled?: boolean;
  readonly onSelected: (value: string) => void;
  readonly buttonMinWidth?: string;
}) => {
  const {
    options,
    selected,
    disabled,
    onSelected,
    buttonMinWidth = '2rem',
  } = props;
  const availableValues = getPlacementOptionValueSet(options);
  const orderedValues = getOrderedShapeValues(options);

  return (
    <Box
      style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(5, minmax(0, 1fr))',
        gap: '0.25rem',
      }}
    >
      {orderedValues.map((value) => {
        const label = getTranslatedShapeLabel(value);
        const glyph = PLACEMENT_SHAPE_GLYPHS[value]?.glyph || 'вЂў';
        const isAvailable = availableValues.has(value);
        const isSelected = isAvailable && value === selected;

        return (
          <Button
            key={value}
            compact
            selected={isSelected}
            color={isSelected ? 'good' : undefined}
            disabled={disabled || !isAvailable}
            tooltip={label}
            onClick={() => onSelected(value)}
            style={{
              width: '100%',
              minWidth: buttonMinWidth,
              height: '2rem',
              justifyContent: 'center',
            }}
          >
            <Box
              as="span"
              style={{
                fontSize: '1.05rem',
                lineHeight: '1',
                display: 'inline-block',
                minWidth: '1rem',
                textAlign: 'center',
              }}
            >
              {glyph}
            </Box>
          </Button>
        );
      })}
    </Box>
  );
};

const CompactFieldControl = (props: {
  readonly field?: UiField;
  readonly act: ActFn;
  readonly disabled?: boolean;
}) => {
  const { field, act, disabled } = props;
  if (!field || field.visible === false) {
    return null;
  }

  const effectiveField = disabled ? { ...field, disabled: true } : field;

  return (
    <Box style={{ minWidth: '10.5rem' }}>
      <Box color="label" mb={0.2}>
        {getTranslatedFieldLabel(field)}
      </Box>
      {renderFieldControl(effectiveField, act, {
        forceChoiceStrip:
          effectiveField.kind === 'select' &&
          (effectiveField.options || []).length > 0 &&
          (effectiveField.options || []).length <= 4,
        choiceStripBasis: '46%',
      })}
    </Box>
  );
};

const CompactChoiceStrip = (props: {
  readonly options: ChoiceOption[];
  readonly selected: string;
  readonly disabled?: boolean;
  readonly onSelected: (value: string) => void;
  readonly buttonMinWidth?: string;
}) => {
  const {
    options,
    selected,
    disabled,
    onSelected,
    buttonMinWidth = '6rem',
  } = props;

  if (!options.length) {
    return <Box color="label">РќРµС‚ РІР°СЂРёР°РЅС‚РѕРІ.</Box>;
  }

  return (
    <Flex wrap mx={-0.12}>
      {options.map((option) => {
        const isSelected = `${option.value}` === `${selected}`;
        return (
          <Flex.Item key={option.value} m={0.12}>
            <Button
              compact
              selected={isSelected}
              color={isSelected ? 'good' : undefined}
              disabled={disabled}
              onClick={() => onSelected(option.value)}
              style={{
                minWidth: buttonMinWidth,
                justifyContent: 'center',
              }}
            >
              {option.displayText}
            </Button>
          </Flex.Item>
        );
      })}
    </Flex>
  );
};

type FieldControlOptions = {
  readonly forceChoiceStrip?: boolean;
  readonly choiceStripBasis?: string;
};

const renderFieldControl = (
  field: UiField,
  act: ActFn,
  options?: FieldControlOptions,
) => {
  const { forceChoiceStrip, choiceStripBasis } = options || {};
  const isDisabled = !!field.disabled;

  const emitValue = (value: unknown) => {
    act('set_param', {
      param_id: field.id,
      value,
    });
  };

  if (field.kind === 'boolean') {
    return (
      <Button.Checkbox
        checked={!!field.value}
        disabled={isDisabled}
        onClick={() => emitValue(!field.value)}
      >
        {field.value ? 'Р”Р°' : 'РќРµС‚'}
      </Button.Checkbox>
    );
  }

  if (field.kind === 'number') {
    return (
      <NumberInput
        value={Number(field.value) || 0}
        minValue={field.min ?? -1000000}
        maxValue={field.max ?? 1000000}
        step={field.step || 1}
        width="100%"
        disabled={isDisabled}
        onChange={(value) => emitValue(value)}
      />
    );
  }

  if (field.kind === 'text') {
    return (
      <Input
        key={`${field.id}_${String(field.value ?? '')}`}
        value={`${field.value ?? ''}`}
        disabled={isDisabled}
        placeholder={field.placeholder || ''}
        onChange={(_, value) => emitValue(value)}
      />
    );
  }

  if (field.kind === 'select') {
    const choiceOptions = getFieldChoiceOptions(field);
    const selected = getSelectedFieldChoiceValue(field);
    const handleSelected = (selectedOptionValue: string) => {
      const selectedOption = choiceOptions.find(
        (option) => option.value === `${selectedOptionValue}`,
      );
      emitValue(selectedOption?.rawValue);
    };

    return forceChoiceStrip ? (
      <ChoiceStrip
        options={choiceOptions}
        selected={selected}
        basis={choiceStripBasis}
        disabled={isDisabled || !choiceOptions.length}
        onSelected={handleSelected}
      />
    ) : (
      <SmartSelect
        options={choiceOptions}
        selected={selected}
        displayText={getFieldOptionLabel(field)}
        disabled={isDisabled || !choiceOptions.length}
        placeholder="Р’С‹Р±РµСЂРёС‚Рµ Р·РЅР°С‡РµРЅРёРµ"
        onSelected={handleSelected}
      />
    );
  }

  return (
    <Box color="bad">РќРµРїРѕРґРґРµСЂР¶РёРІР°РµРјС‹Р№ С‚РёРї РїРѕР»СЏ.</Box>
  );
};

const FieldEditor = (props: {
  readonly field: UiField;
  readonly act: ActFn;
  readonly showHints?: boolean;
}) => {
  const { field, act, showHints } = props;

  return (
    <LabeledList.Item
      label={
        field.required
          ? `${getTranslatedFieldLabel(field)} *`
          : getTranslatedFieldLabel(field)
      }
    >
      {renderFieldControl(field, act)}
      {!!showHints && !!field.validate_hint && (
        <Box color="average" mt={0.35}>
          {field.validate_hint}
        </Box>
      )}
    </LabeledList.Item>
  );
};

const FieldControl = (props: {
  readonly field: UiField;
  readonly act: ActFn;
  readonly forceChoiceStrip?: boolean;
  readonly choiceStripBasis?: string;
}) => {
  const { field, act, forceChoiceStrip, choiceStripBasis } = props;
  return renderFieldControl(field, act, {
    forceChoiceStrip,
    choiceStripBasis,
  });
};

const FieldControlStack = (props: {
  readonly field?: UiField;
  readonly act: ActFn;
  readonly forceChoiceStrip?: boolean;
  readonly choiceStripBasis?: string;
}) => {
  const { field, act, forceChoiceStrip, choiceStripBasis } = props;
  if (!field || field.visible === false) {
    return null;
  }

  return (
    <Box>
      <Box color="label" mb={0.25}>
        {getTranslatedFieldLabel(field)}
      </Box>
      <FieldControl
        field={field}
        act={act}
        forceChoiceStrip={forceChoiceStrip}
        choiceStripBasis={choiceStripBasis}
      />
      {!!field.validate_hint && (
        <Box color="average" mt={0.25}>
          {field.validate_hint}
        </Box>
      )}
    </Box>
  );
};

const FieldListContent = (props: {
  readonly fields: UiField[];
  readonly act: ActFn;
  readonly showHints?: boolean;
}) => {
  const { fields, act, showHints } = props;
  return (
    <LabeledList>
      {fields.map((field) => (
        <FieldEditor
          key={field.id}
          field={field}
          act={act}
          showHints={showHints}
        />
      ))}
    </LabeledList>
  );
};

const FieldListCard = (props: {
  readonly title: string;
  readonly fields: UiField[];
  readonly act: ActFn;
  readonly tone?: SurfaceTone;
  readonly subtitle?: ReactNode;
  readonly showHints?: boolean;
  readonly actions?: ReactNode;
  readonly mt?: number;
}) => {
  const { title, fields, act, tone, subtitle, showHints, actions, mt } = props;
  const visibleFields = getVisibleFields(fields);
  if (!visibleFields.length) {
    return null;
  }

  return (
    <SurfaceCard
      title={title}
      subtitle={subtitle}
      tone={tone}
      actions={actions}
      mt={mt ?? 0.6}
    >
      <FieldListContent
        fields={visibleFields}
        act={act}
        showHints={showHints}
      />
    </SurfaceCard>
  );
};

const FieldBlock = (props: {
  readonly title: string;
  readonly fields: UiField[];
  readonly act: ActFn;
  readonly tone?: SurfaceTone;
  readonly subtitle?: ReactNode;
  readonly showHints?: boolean;
}) => {
  const { title, fields, act, tone, subtitle, showHints } = props;
  const visibleFields = getVisibleFields(fields);
  if (!visibleFields.length) {
    return null;
  }

  const { borderColor } = getSurfaceColors(tone);

  return (
    <Box
      p={0.5}
      style={{
        borderTop: `2px solid ${borderColor}`,
        border: `1px solid ${borderColor}`,
        background: 'rgba(70, 107, 150, 0.03)',
        borderRadius: '4px',
      }}
    >
      <Box bold>{title}</Box>
      {!!subtitle && (
        <Box color="label" mt={0.1}>
          {subtitle}
        </Box>
      )}
      <Box mt={0.35}>
        <FieldListContent
          fields={visibleFields}
          act={act}
          showHints={showHints}
        />
      </Box>
    </Box>
  );
};

export {
  CompactChoiceStrip,
  CompactFieldControl,
  FieldBlock,
  FieldControl,
  FieldControlStack,
  FieldEditor,
  FieldListCard,
  ShapeOptionStrip,
};
