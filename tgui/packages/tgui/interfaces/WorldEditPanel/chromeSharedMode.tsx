import { Box, Collapsible, Flex } from '../../components';
import {
  CompactStackedChoiceButtons,
  CompactToggleButton,
  DirectionCompass,
  ToolbarControlColumn,
  ToolbarReadOnlyValue,
} from './chromeComponents';
import {
  CHROME_CONTROL_BUTTON_WIDTH,
  CHROME_DIRECTION_COLUMN_WIDTH,
  CHROME_PLACEMENT_COLUMN_GAP,
  CHROME_PLACEMENT_SECTION_GAP,
  CHROME_RADIUS_COLUMN_WIDTH,
  CHROME_SHAPE_COLUMN_WIDTH,
  CHROME_SHAPE_GRID_COLUMNS,
  CHROME_SQUARE_BUTTON_SIZE,
} from './chromeLayout';
import { RADIUS_POLICY_SHORT_LABELS } from './constants';
import {
  CompactFieldControl,
  FieldControl,
  ShapeOptionStrip,
} from './fieldControls';
import {
  getTranslatedFieldDescription,
  getTranslatedFieldLabel,
} from './helpers';
import type { ActFn, BackendData, WorkspaceTabKey } from './types';
import { getSharedModeViewModel } from './viewModel';

const getRadiusToggleTooltip = (label?: string, description?: string) =>
  [label, description].filter(Boolean).join(': ');

const SharedModePanel = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
  readonly workspaceTab: WorkspaceTabKey;
}) => {
  const { data, act, workspaceTab } = props;
  const viewModel = getSharedModeViewModel(data, workspaceTab);
  const sharedFieldContextKey = `${data.current_generator_id || 'no-generator'}:${data.placement_shape || 'point'}`;

  if (!viewModel.hasTopControls && !viewModel.sharedFields.length) {
    return null;
  }

  return (
    <Box>
      {viewModel.hasTopControls && (
        <Box style={{ overflowX: 'auto' }}>
          <Box
            p={0.25}
            style={{
              display: 'inline-grid',
              width: 'max-content',
              minWidth: '100%',
              border: '1px solid rgba(70, 107, 150, 0.55)',
              background: 'rgba(70, 107, 150, 0.10)',
              borderRadius: '4px',
            }}
          >
            <Box
              style={{
                display: 'grid',
                gridAutoFlow: 'column',
                gridAutoColumns: 'max-content',
                columnGap: CHROME_PLACEMENT_COLUMN_GAP,
                alignItems: 'start',
              }}
            >
              {viewModel.showShapeSection && !!viewModel.selectedShape && (
                <ToolbarControlColumn
                  label="Форма"
                  width={CHROME_SHAPE_COLUMN_WIDTH}
                >
                  <ShapeOptionStrip
                    options={viewModel.shapeOptions}
                    selected={viewModel.selectedShape}
                    disabled={!data.placement_shape_supported}
                    buttonMinWidth={CHROME_SQUARE_BUTTON_SIZE}
                    buttonSize={CHROME_SQUARE_BUTTON_SIZE}
                    columns={CHROME_SHAPE_GRID_COLUMNS}
                    onSelected={(value) =>
                      act('set_placement_shape', {
                        shape: value,
                      })
                    }
                  />
                </ToolbarControlColumn>
              )}

              {viewModel.showModeSection && (
                <ToolbarControlColumn
                  label="После клика"
                  width={CHROME_CONTROL_BUTTON_WIDTH}
                  separated
                >
                  <CompactStackedChoiceButtons
                    options={viewModel.modeOptions}
                    selected={viewModel.selectedMode}
                    disabled={!data.placement_supported}
                    onSelected={(value) =>
                      act('set_placement_mode', {
                        mode: value,
                      })
                    }
                  />
                </ToolbarControlColumn>
              )}

              {viewModel.showDirectionSection && (
                <ToolbarControlColumn
                  label="Направление"
                  width={CHROME_DIRECTION_COLUMN_WIDTH}
                  separated
                  align="center"
                >
                  <Box
                    style={{
                      display: 'grid',
                      rowGap: CHROME_PLACEMENT_SECTION_GAP,
                      justifyItems: 'center',
                    }}
                  >
                    <CompactToggleButton
                      checked={!!data.placement_dir_uses_facing}
                      label="Взгляд"
                      tooltip="Использовать направление взгляда"
                      disabled={!data.placement_supports_direction}
                      onClick={() =>
                        act('set_placement_dir_uses_facing', {
                          enabled: !data.placement_dir_uses_facing,
                        })
                      }
                    />
                    <DirectionCompass
                      options={viewModel.directionOptions}
                      selected={viewModel.selectedDirection}
                      usesFacing={data.placement_dir_uses_facing}
                      disabled={!data.placement_supports_direction}
                      onSelected={(value) =>
                        act('set_placement_dir', {
                          direction: value,
                        })
                      }
                    />
                  </Box>
                </ToolbarControlColumn>
              )}

              {viewModel.showRadiusSection && (
                <ToolbarControlColumn
                  label="Радиус"
                  width={CHROME_RADIUS_COLUMN_WIDTH}
                  separated
                >
                  {data.current_generator_id === 'blueprint_stamp' ||
                  (viewModel.radiusField &&
                    viewModel.radiusField.visible !== false) ||
                  viewModel.radiusToggleFields.length ? (
                    <Box
                      style={{
                        display: 'grid',
                        rowGap: '0.18rem',
                      }}
                    >
                      {data.current_generator_id === 'blueprint_stamp' ? (
                        <ToolbarReadOnlyValue
                          value={
                            viewModel.activeBlueprint
                              ? `${viewModel.activeBlueprint.radius ?? 0}`
                              : '—'
                          }
                          disabled={
                            !viewModel.activeBlueprint ||
                            !viewModel.activeBlueprint.valid
                          }
                        />
                      ) : viewModel.radiusField &&
                        viewModel.radiusField.visible !== false ? (
                        <FieldControl
                          key={`${sharedFieldContextKey}:radius:${viewModel.radiusField.id}:${viewModel.radiusField.label || ''}`}
                          field={viewModel.radiusField}
                          act={act}
                        />
                      ) : (
                        <ToolbarReadOnlyValue value="—" disabled />
                      )}
                      {!!viewModel.radiusToggleFields.length && (
                        <Box
                          color="label"
                          style={{
                            lineHeight: '1',
                            paddingTop: '0.08rem',
                          }}
                        >
                          Ограничители
                        </Box>
                      )}
                      {viewModel.radiusToggleFields.map((field) => (
                        <CompactToggleButton
                          key={`${sharedFieldContextKey}:radius-toggle:${field.id}`}
                          checked={!!field.value}
                          label={
                            RADIUS_POLICY_SHORT_LABELS[field.id] || field.label
                          }
                          tooltip={getRadiusToggleTooltip(
                            getTranslatedFieldLabel(field),
                            getTranslatedFieldDescription(field),
                          )}
                          disabled={field.disabled}
                          onClick={() =>
                            act('set_param', {
                              param_id: field.id,
                              value: !field.value,
                            })
                          }
                        />
                      ))}
                    </Box>
                  ) : (
                    <ToolbarReadOnlyValue value="—" disabled />
                  )}
                </ToolbarControlColumn>
              )}
            </Box>
          </Box>
        </Box>
      )}

      {!!viewModel.sharedFields.length && (
        <Box mt={0.35}>
          <Collapsible
            title={`Доп. параметры (${viewModel.sharedFields.length})`}
            color="average"
            open={
              viewModel.sharedFields.length <= 2 || !!data.click_mode_active
            }
          >
            <Box mt={0.1}>
              <Flex wrap mx={-0.16}>
                {viewModel.sharedFields.map((field) => (
                  <Flex.Item
                    key={`${sharedFieldContextKey}:${field.id}`}
                    basis="12.5rem"
                    grow
                    m={0.16}
                    style={{ minWidth: '10.5rem' }}
                  >
                    <CompactFieldControl field={field} act={act} />
                  </Flex.Item>
                ))}
              </Flex>
            </Box>
          </Collapsible>
        </Box>
      )}
    </Box>
  );
};

export { SharedModePanel };
