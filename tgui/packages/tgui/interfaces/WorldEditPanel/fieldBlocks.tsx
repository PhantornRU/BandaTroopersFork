import { type ReactNode } from 'react';

import { Box, LabeledList } from '../../components';
import { renderFieldControl } from './fieldRenderers';
import { getTranslatedFieldLabel, getVisibleFields } from './helpers';
import { getSurfaceColors, SurfaceCard } from './primitives';
import type { ActFn, SurfaceTone, UiField } from './types';

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
  readonly labelOverride?: string;
  readonly showHint?: boolean;
}) => {
  const {
    field,
    act,
    forceChoiceStrip,
    choiceStripBasis,
    labelOverride,
    showHint = true,
  } = props;
  if (!field || field.visible === false) {
    return null;
  }

  return (
    <Box>
      <Box color="label" mb={0.25}>
        {labelOverride || getTranslatedFieldLabel(field)}
      </Box>
      <FieldControl
        field={field}
        act={act}
        forceChoiceStrip={forceChoiceStrip}
        choiceStripBasis={choiceStripBasis}
      />
      {!!showHint && !!field.validate_hint && (
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
  CompactFieldControl,
  FieldBlock,
  FieldControl,
  FieldControlStack,
  FieldEditor,
  FieldListCard,
};
