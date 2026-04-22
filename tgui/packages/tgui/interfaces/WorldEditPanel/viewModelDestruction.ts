import { RADIUS_POLICY_FIELD_IDS } from './constants';
import { getField, getFieldsByGroup, getFieldsById } from './helpers';
import type { BackendData, PreviewLegendItem, UiField } from './types';

type DestructionMovementFields = {
  shuffleField?: UiField;
  scatterField?: UiField;
  maxAtomsField?: UiField;
  scatterStepsField?: UiField;
  visibleMovementFields: UiField[];
};

type DestructionWorkspaceViewModel = {
  areaFields: UiField[];
  fireFields: UiField[];
  blastFields: UiField[];
  damageFields: UiField[];
  movementFields: DestructionMovementFields;
  previewLegendItems: PreviewLegendItem[];
  movementEnabled: boolean;
  fireEnabled: boolean;
  blastEnabled: boolean;
  damageProfile: string;
  destructiveEnabled: boolean;
};

const getDestructionPreviewLegendItems = (
  data: BackendData,
): PreviewLegendItem[] => {
  const previewMeta = data.preview_meta || {};
  const firePreviewColor = data.preview_valid
    ? `${previewMeta.persistent_fire_preview_color || '#ff9438'}`
    : '#ff9438';
  const fireEnabled = !!getField(data.ui_fields, 'persistent_fire_enabled')
    ?.value;
  const blastEnabled = !!getField(data.ui_fields, 'blast_enabled')?.value;
  const damageProfile = `${getField(data.ui_fields, 'damage_profile')?.value || 'none'}`;
  const moveEnabled = data.preview_valid
    ? Number(previewMeta.moved_count || 0) > 0
    : !!getField(data.ui_fields, 'shuffle_enabled')?.value ||
      !!getField(data.ui_fields, 'scatter_enabled')?.value;
  const previewFireEnabled = data.preview_valid
    ? Number(previewMeta.fire_count || 0) > 0
    : fireEnabled;
  const previewBlastEnabled = data.preview_valid
    ? Number(previewMeta.blast_count || 0) > 0
    : blastEnabled;
  const previewDamageEnabled = data.preview_valid
    ? Number(previewMeta.damage_count || 0) > 0
    : damageProfile !== 'none';

  return [
    ...(moveEnabled ? [{ label: 'Перемещение', color: '#4e8eff' }] : []),
    ...(previewFireEnabled
      ? [{ label: 'Огонь', color: firePreviewColor }]
      : []),
    ...(previewDamageEnabled ? [{ label: 'Урон', color: '#b85cff' }] : []),
    ...(previewBlastEnabled ? [{ label: 'Взрыв', color: '#ff4e4e' }] : []),
  ];
};

const getDestructionRangeSuffix = (field: UiField) => {
  if (typeof field.min !== 'number' || typeof field.max !== 'number') {
    return '';
  }

  const rangeText = `${field.min}-${field.max}`;
  if (field.id === 'persistent_fire_density') {
    return ` [${rangeText}%]`;
  }
  return ` [${rangeText}]`;
};

const getDestructionFieldLabel = (field: UiField) => {
  switch (field.id) {
    case 'scatter_steps':
      return `Шаги разброса${getDestructionRangeSuffix(field)}`;
    case 'max_atoms':
      return `Лимит объектов${getDestructionRangeSuffix(field)}`;
    case 'persistent_fire_density':
      return `Плотность огня${getDestructionRangeSuffix(field)}`;
    case 'blast_power':
      return `Мощность взрыва${getDestructionRangeSuffix(field)}`;
    case 'blast_falloff':
      return `Спад взрыва${getDestructionRangeSuffix(field)}`;
    default:
      return undefined;
  }
};

const getDestructionMovementFields = (
  fields: UiField[],
): DestructionMovementFields => {
  const shuffleField = getField(fields, 'shuffle_enabled');
  const scatterField = getField(fields, 'scatter_enabled');
  const maxAtomsField = getField(fields, 'max_atoms');
  const scatterStepsField = getField(fields, 'scatter_steps');
  const visibleShuffleField =
    shuffleField?.visible !== false ? shuffleField : undefined;
  const visibleScatterField =
    scatterField?.visible !== false ? scatterField : undefined;
  const visibleMaxAtomsField =
    maxAtomsField?.visible !== false ? maxAtomsField : undefined;
  const visibleScatterStepsField =
    scatterStepsField?.visible !== false ? scatterStepsField : undefined;

  return {
    shuffleField: visibleShuffleField,
    scatterField: visibleScatterField,
    maxAtomsField: visibleMaxAtomsField,
    scatterStepsField: visibleScatterStepsField,
    visibleMovementFields: [
      visibleShuffleField,
      visibleScatterField,
      visibleMaxAtomsField,
      visibleScatterStepsField,
    ].filter((field): field is UiField => !!field),
  };
};

const getDestructionWorkspaceViewModel = (
  data: BackendData,
): DestructionWorkspaceViewModel => {
  const areaFields = getFieldsByGroup(data.ui_fields, 'Area').filter(
    (field) =>
      field.id !== 'radius' &&
      !RADIUS_POLICY_FIELD_IDS.includes(field.id) &&
      field.visible !== false,
  );
  const fireFields = getFieldsById(data.ui_fields, [
    'persistent_fire_enabled',
    'persistent_fire_density',
    'persistent_fire_mode',
    'persistent_fire_color',
    'persistent_fire_custom_color',
  ]);
  const blastFields = getFieldsById(data.ui_fields, [
    'blast_enabled',
    'blast_power',
    'blast_falloff',
  ]);
  const damageFields = getFieldsById(data.ui_fields, ['damage_profile']);
  const blastEnabled = !!getField(data.ui_fields, 'blast_enabled')?.value;
  const damageProfile = `${getField(data.ui_fields, 'damage_profile')?.value || 'none'}`;
  const fireEnabled = !!getField(data.ui_fields, 'persistent_fire_enabled')
    ?.value;

  return {
    areaFields,
    fireFields,
    blastFields,
    damageFields,
    movementFields: getDestructionMovementFields(data.ui_fields),
    previewLegendItems: getDestructionPreviewLegendItems(data),
    movementEnabled:
      !!getField(data.ui_fields, 'shuffle_enabled')?.value ||
      !!getField(data.ui_fields, 'scatter_enabled')?.value,
    fireEnabled,
    blastEnabled,
    damageProfile,
    destructiveEnabled: blastEnabled || damageProfile !== 'none',
  };
};

export {
  getDestructionFieldLabel,
  getDestructionMovementFields,
  getDestructionPreviewLegendItems,
  getDestructionWorkspaceViewModel,
};
export type { DestructionMovementFields, DestructionWorkspaceViewModel };
