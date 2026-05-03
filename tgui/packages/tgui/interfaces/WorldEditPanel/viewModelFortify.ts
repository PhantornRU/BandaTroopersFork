import { getFieldsById, getVisibleFields } from './helpers';
import type { BackendData, UiField } from './types';

const CONFIG_PRIMARY_FIELD_IDS = [
  'preset_id',
  'material_family',
  'material_wired',
  'door_policy',
];

const CONFIG_EXTRA_FIELD_IDS = ['door_material_family', 'door_wired'];

const BOUNDS_FIELD_IDS = [
  'room_tile_cap',
  'treat_windows_as_boundary',
  'fortify_windows',
  'treat_doors_as_boundary',
];

const getVisibleByIds = (fields: UiField[], ids: string[]) =>
  getVisibleFields(getFieldsById(fields, ids));

export type FortifyWorkspaceViewModel = {
  primaryConfigFields: UiField[];
  extraConfigFields: UiField[];
  boundsFields: UiField[];
};

export const getFortifyWorkspaceViewModel = (
  data: BackendData,
): FortifyWorkspaceViewModel => ({
  primaryConfigFields: getVisibleByIds(
    data.ui_fields,
    CONFIG_PRIMARY_FIELD_IDS,
  ),
  extraConfigFields: getVisibleByIds(data.ui_fields, CONFIG_EXTRA_FIELD_IDS),
  boundsFields: getVisibleByIds(data.ui_fields, BOUNDS_FIELD_IDS),
});
