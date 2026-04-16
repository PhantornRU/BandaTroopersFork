import type { ReactNode } from 'react';

import { Box, Button, Collapsible, Flex, Icon, Tabs } from '../../components';
import {
  DEFAULT_DIRECTION_OPTIONS,
  DEFAULT_PLACEMENT_MODE_OPTIONS,
  DEFAULT_POINT_SHAPE_OPTION,
  TOOL_PICKER_LABELS,
} from './constants';
import { CompactFieldControl, FieldControl, ShapeOptionStrip } from './fieldControls';
import {
  getField,
  getFieldsById,
  getSelectedBlueprint,
  getTranslatedDirection,
  getTranslatedPlacementMode,
  isBlueprintToolBlocked,
} from './helpers';
import type {
  ActFn,
  BackendData,
  ChoiceOption,
  GeneratorEntry,
  PreviewLegendItem,
  ToolbarAction,
  ToolbarActions,
  WorkspaceTabKey,
} from './types';

const CHROME_SQUARE_BUTTON_REM = 1.9;
const CHROME_ACTION_BUTTON_MIN_WIDTH = '6.25rem';
const CHROME_CONTROL_BUTTON_WIDTH_REM = 6.6;
const CHROME_CONTROL_BUTTON_HEIGHT_REM = 1.45;
const CHROME_DIRECTION_BUTTON_GAP_REM = 0.25;
const CHROME_CONTROL_COLUMN_PADDING_REM = 0.7;
const CHROME_PLACEMENT_COLUMN_GAP_REM = 0.9;
const CHROME_PLACEMENT_SECTION_GAP_REM = 0.22;
const CHROME_SHAPE_GRID_COLUMNS = 5;
const CHROME_RADIUS_COLUMN_WIDTH_REM = 5.2;
const toRem = (value: number) => `${value}rem`;
const CHROME_SQUARE_BUTTON_SIZE = toRem(CHROME_SQUARE_BUTTON_REM);
const CHROME_CONTROL_BUTTON_WIDTH = toRem(CHROME_CONTROL_BUTTON_WIDTH_REM);
const CHROME_CONTROL_BUTTON_HEIGHT = toRem(CHROME_CONTROL_BUTTON_HEIGHT_REM);
const CHROME_DIRECTION_BUTTON_GAP = toRem(CHROME_DIRECTION_BUTTON_GAP_REM);
const CHROME_DIRECTION_COMPASS_WIDTH = toRem(
  CHROME_SQUARE_BUTTON_REM * 3 + CHROME_DIRECTION_BUTTON_GAP_REM * 2,
);
const CHROME_DIRECTION_COLUMN_WIDTH = toRem(
  Math.max(
    CHROME_CONTROL_BUTTON_WIDTH_REM,
    CHROME_SQUARE_BUTTON_REM * 3 + CHROME_DIRECTION_BUTTON_GAP_REM * 2,
  ),
);
const CHROME_CONTROL_COLUMN_PADDING = toRem(CHROME_CONTROL_COLUMN_PADDING_REM);
const CHROME_PLACEMENT_COLUMN_GAP = toRem(CHROME_PLACEMENT_COLUMN_GAP_REM);
const CHROME_PLACEMENT_SECTION_GAP = toRem(CHROME_PLACEMENT_SECTION_GAP_REM);
const CHROME_SHAPE_COLUMN_WIDTH = toRem(
  CHROME_SQUARE_BUTTON_REM * CHROME_SHAPE_GRID_COLUMNS +
    CHROME_DIRECTION_BUTTON_GAP_REM * (CHROME_SHAPE_GRID_COLUMNS - 1),
);
const CHROME_RADIUS_COLUMN_WIDTH = toRem(CHROME_RADIUS_COLUMN_WIDTH_REM);
const CHROME_SHARED_CENTER_STYLE = {
  display: 'inline-flex',
  alignItems: 'center',
  justifyContent: 'center',
  textAlign: 'center' as const,
  lineHeight: '1',
};
const CHROME_ACTION_BUTTON_STYLE = {
  ...CHROME_SHARED_CENTER_STYLE,
  minWidth: CHROME_ACTION_BUTTON_MIN_WIDTH,
  minHeight: CHROME_SQUARE_BUTTON_SIZE,
  height: CHROME_SQUARE_BUTTON_SIZE,
  padding: '0 0.55rem',
  marginRight: '0',
  marginBottom: '0',
};
const CHROME_ICON_BUTTON_STYLE = {
  ...CHROME_SHARED_CENTER_STYLE,
  width: CHROME_SQUARE_BUTTON_SIZE,
  minWidth: CHROME_SQUARE_BUTTON_SIZE,
  height: CHROME_SQUARE_BUTTON_SIZE,
  minHeight: CHROME_SQUARE_BUTTON_SIZE,
  padding: '0',
  marginRight: '0',
  marginBottom: '0',
};
const CHROME_CONTROL_BUTTON_STYLE = {
  ...CHROME_SHARED_CENTER_STYLE,
  width: CHROME_CONTROL_BUTTON_WIDTH,
  minWidth: CHROME_CONTROL_BUTTON_WIDTH,
  maxWidth: CHROME_CONTROL_BUTTON_WIDTH,
  minHeight: CHROME_CONTROL_BUTTON_HEIGHT,
  height: CHROME_CONTROL_BUTTON_HEIGHT,
  padding: '0 0.4rem',
  fontSize: '0.92rem',
  marginRight: '0',
  marginBottom: '0',
};
const DIRECTION_BUTTON_LABELS: Record<string, string> = {
  north: 'С',
  east: 'В',
  south: 'Ю',
  west: 'З',
};

const getToolbarActions = (data: BackendData): ToolbarActions => {
  if (!data.has_generator) {
    return {};
  }

  const isToolBlocked = isBlueprintToolBlocked(data);
  const hasPlacementControls =
    data.placement_supported ||
    data.placement_shape_supported ||
    data.placement_supports_direction;
  const hasVisiblePreview = !!data.preview_valid;
  const canPreview =
    data.can_run_preview && !data.click_mode_active && !isToolBlocked;
  const canApply =
    data.can_run_apply && !data.click_mode_active && !isToolBlocked;
  const canStartPlacement =
    data.can_start_placement_mode && !data.click_mode_active && !isToolBlocked;

  const previewAction: ToolbarAction | undefined =
    data.current_generator_supports_preview
      ? {
          label: 'Предпросмотр',
          action: 'run_preview',
          color: 'average',
          disabled: !canPreview,
        }
      : undefined;

  if (previewAction) {
    previewAction.action = hasVisiblePreview ? 'clear_preview' : 'run_preview';
    previewAction.color = hasVisiblePreview ? 'good' : 'average';
    previewAction.disabled = hasVisiblePreview ? false : !canPreview;
  }

  const applyAction: ToolbarAction = {
    label: 'Применить',
    action: 'run_apply',
    color: 'good',
    disabled: !canApply,
  };

  const effectiveApplyAction = hasPlacementControls ? undefined : applyAction;

  const startPlacementAction: ToolbarAction | undefined = hasPlacementControls
    ? {
        label: 'Разместить',
        action: 'start_placement_mode',
        color: 'good',
        disabled: !canStartPlacement,
      }
    : undefined;

  const placePreviewAction: ToolbarAction | undefined =
    hasPlacementControls && hasVisiblePreview
      ? {
          label: 'Разместить',
          action: 'run_apply',
          color: 'good',
          disabled: !canApply,
        }
      : undefined;

  const stopPlacementAction: ToolbarAction = {
    label: 'Остановить размещение',
    action: 'stop_click_mode',
    color: 'average',
    disabled: !data.can_stop_click_mode,
  };

  const collectorAction: ToolbarAction | undefined =
    data.click_mode_active && data.placement_interaction_kind === 'collector'
      ? {
          label: 'Завершить сбор',
          action: 'finish_placement_collection',
          color: 'good',
          disabled: !data.can_finish_placement_collection,
        }
      : undefined;

  const undoAction: ToolbarAction = {
    label: 'Откатить последнее',
    action: 'undo_last_operation',
    color: 'average',
    disabled: !data.can_undo_last_operation,
  };

  return {
    previewAction,
    applyAction: effectiveApplyAction,
    placementAction: data.click_mode_active
      ? stopPlacementAction
      : placePreviewAction || startPlacementAction,
    collectorAction,
    undoAction,
  };
};

const getSharedChromeFields = (data: BackendData) => {
  if (data.current_generator_id === 'blueprint_stamp') {
    return [
      ...getFieldsById(data.ui_fields, ['stamp_spacing']),
      ...(data.placement_shape_fields || []).filter(
        (field) => field.visible !== false,
      ),
    ];
  }

  return (data.placement_shape_fields || []).filter(
    (field) => field.visible !== false,
  );
};

const getDestructionPreviewLegendItems = (
  data: BackendData,
): PreviewLegendItem[] => {
  const previewMeta = data.preview_meta || {};
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
    ...(previewFireEnabled ? [{ label: 'Огонь', color: '#ff9438' }] : []),
    ...(previewDamageEnabled ? [{ label: 'Урон', color: '#b85cff' }] : []),
    ...(previewBlastEnabled ? [{ label: 'Взрыв', color: '#ff4e4e' }] : []),
  ];
};

const getPlacementModeChoices = (data: BackendData): ChoiceOption[] => {
  const options = (data.placement_mode_options || []).map((option) => ({
    value: option.value,
    displayText: getTranslatedPlacementMode(option.value || option.label),
  }));
  return options.length ? options : DEFAULT_PLACEMENT_MODE_OPTIONS;
};

const getPlacementShapeOptionsForShell = (data: BackendData) => {
  if (data.placement_shape_options?.length) {
    return data.placement_shape_options;
  }

  if (data.placement_shape) {
    return [
      {
        value: data.placement_shape,
        label: data.placement_shape,
      },
    ];
  }

  return DEFAULT_POINT_SHAPE_OPTION;
};

const getPlacementDirectionChoices = (data: BackendData): ChoiceOption[] => {
  const options = (data.placement_dir_options || []).map((option) => ({
    value: `${option.value || option.label || ''}`.trim().toLowerCase(),
    displayText: getTranslatedDirection(option.value || option.label),
  }));
  return options.length ? options : DEFAULT_DIRECTION_OPTIONS;
};

const hasSharedModeContent = (
  data: BackendData,
  workspaceTab: WorkspaceTabKey,
) => {
  return workspaceTab !== 'history' && !!data.has_generator;
};

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
        borderLeft: separated
          ? '1px solid rgba(70, 107, 150, 0.35)'
          : 'none',
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
          disabled
            ? 'rgba(70, 107, 150, 0.25)'
            : 'rgba(70, 107, 150, 0.45)'
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
  readonly onClick: () => void;
}) => (
  <Button
    compact
    verticalAlignContent="middle"
    selected={props.checked}
    color={props.checked ? 'good' : 'transparent'}
    disabled={props.disabled}
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

const SharedModePanel = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
  readonly workspaceTab: WorkspaceTabKey;
}) => {
  const { data, act, workspaceTab } = props;
  const isHistoryTab = workspaceTab === 'history';
  const hasGenerator = !!data.has_generator;
  const shapeOptions = getPlacementShapeOptionsForShell(data);
  const modeOptions = getPlacementModeChoices(data);
  const directionOptions = getPlacementDirectionChoices(data);
  const sharedFields = getSharedChromeFields(data).filter(
    (field) => field.visible !== false,
  );
  const selectedShape = `${data.placement_shape || shapeOptions[0]?.value || 'point'}`;
  const selectedMode = `${data.placement_mode || modeOptions[0]?.value || 'single'}`;
  const selectedDirection =
    `${data.placement_dir || directionOptions[0]?.value || 'north'}`
      .trim()
      .toLowerCase();
  const radiusField = getField(data.ui_fields, 'radius');
  const activeBlueprint =
    data.current_generator_id === 'blueprint_stamp'
      ? getSelectedBlueprint(data)
      : undefined;
  const showRadiusSection =
    !isHistoryTab &&
    hasGenerator &&
    (data.current_generator_id === 'blueprint_stamp' ||
      (!!radiusField && radiusField.visible !== false));
  const showShapeSection = !isHistoryTab && hasGenerator;
  const showModeSection = !isHistoryTab && hasGenerator;
  const showDirectionSection = !isHistoryTab && hasGenerator;
  const hasTopControls =
    showShapeSection ||
    showModeSection ||
    showDirectionSection ||
    showRadiusSection;

  if (!hasTopControls && !sharedFields.length) {
    return null;
  }

  return (
    <Box>
      {hasTopControls && (
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
              {showShapeSection && !!selectedShape && (
                <ToolbarControlColumn
                  label="Форма"
                  width={CHROME_SHAPE_COLUMN_WIDTH}
                >
                  <ShapeOptionStrip
                    options={shapeOptions}
                    selected={selectedShape}
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

              {showModeSection && (
                <ToolbarControlColumn
                  label="После клика"
                  width={CHROME_CONTROL_BUTTON_WIDTH}
                  separated
                >
                  <CompactStackedChoiceButtons
                    options={modeOptions}
                    selected={selectedMode}
                    disabled={!data.placement_supported}
                    onSelected={(value) =>
                      act('set_placement_mode', {
                        mode: value,
                      })
                    }
                  />
                </ToolbarControlColumn>
              )}

              {showDirectionSection && (
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
                      label="По взгляду"
                      disabled={!data.placement_supports_direction}
                      onClick={() =>
                        act('set_placement_dir_uses_facing', {
                          enabled: !data.placement_dir_uses_facing,
                        })
                      }
                    />
                    <DirectionCompass
                      options={directionOptions}
                      selected={selectedDirection}
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

              {showRadiusSection && (
                <ToolbarControlColumn
                  label="Радиус"
                  width={CHROME_RADIUS_COLUMN_WIDTH}
                  separated
                >
                  {data.current_generator_id === 'blueprint_stamp' ? (
                    <ToolbarReadOnlyValue
                      value={
                        activeBlueprint ? `${activeBlueprint.radius ?? 0}` : '—'
                      }
                      disabled={!activeBlueprint || !activeBlueprint.valid}
                    />
                  ) : radiusField && radiusField.visible !== false ? (
                    <FieldControl field={radiusField} act={act} />
                  ) : (
                    <ToolbarReadOnlyValue value="—" disabled />
                  )}
                </ToolbarControlColumn>
              )}
            </Box>
          </Box>
        </Box>
      )}

      {!!sharedFields.length && (
        <Box mt={0.35}>
          <Collapsible
            title={`Доп. параметры (${sharedFields.length})`}
            color="average"
            open={sharedFields.length <= 2 || data.click_mode_active}
          >
            <Box mt={0.1}>
              <Flex wrap mx={-0.16}>
                {sharedFields.map((field) => (
                  <Flex.Item
                    key={field.id}
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

const EditorChrome = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
  readonly toolTabs: GeneratorEntry[];
  readonly workspaceTab: WorkspaceTabKey;
  readonly onSelectGenerator: (generatorId: string) => void;
  readonly onSelectWorkspaceTab: (tab: WorkspaceTabKey) => void;
}) => {
  const {
    data,
    act,
    toolTabs,
    workspaceTab,
    onSelectGenerator,
    onSelectWorkspaceTab,
  } = props;
  const toolbar = getToolbarActions(data);
  const actionsDisabled = !data.has_generator;
  const showSharedModeShell = hasSharedModeContent(data, workspaceTab);
  const chromeError = `${data.last_ui_error || ''}`.trim();
  const leadingAction = toolbar.previewAction;
  const centerAction =
    toolbar.placementAction || toolbar.applyAction || toolbar.collectorAction;
  const trailingAction =
    toolbar.collectorAction &&
    toolbar.collectorAction.action !== centerAction?.action
      ? toolbar.collectorAction
      : undefined;

  const renderAction = (
    action?: ToolbarAction,
    compact = false,
    options?: {
      readonly fluid?: boolean;
    },
  ) => {
    if (!action) {
      return null;
    }

    return (
      <Button
        compact={compact}
        fluid={options?.fluid}
        verticalAlignContent="middle"
        color={action.color}
        disabled={actionsDisabled || action.disabled}
        selected={action.action === 'clear_preview'}
        tooltip={compact ? action.label : undefined}
        onClick={() => act(action.action, action.payload)}
        style={{
          ...CHROME_ACTION_BUTTON_STYLE,
          ...(options?.fluid
            ? {
                width: '100%',
              }
            : {}),
        }}
      >
        {action.label}
      </Button>
    );
  };

  const renderUndoAction = (action?: ToolbarAction) => {
    if (!action) {
      return null;
    }

    return (
      <Button
        compact
        verticalAlignContent="middle"
        color={action.color}
        disabled={actionsDisabled || action.disabled}
        tooltip={action.label}
        onClick={() => act(action.action, action.payload)}
        style={CHROME_ICON_BUTTON_STYLE}
      >
        <CenteredIcon name="undo" />
      </Button>
    );
  };

  const renderConfirmAction = () => (
    <Button
      compact
      verticalAlignContent="middle"
      selected={data.confirm_before_apply}
      color={data.confirm_before_apply ? 'good' : 'transparent'}
      disabled={actionsDisabled}
      tooltip="Подтверждать применение"
      onClick={() =>
        act('set_confirm_before_apply', {
          enabled: !data.confirm_before_apply,
        })
      }
      style={CHROME_ICON_BUTTON_STYLE}
    >
      <CenteredIcon
        name={data.confirm_before_apply ? 'check-square-o' : 'square-o'}
      />
    </Button>
  );

  return (
    <Box
      mb={0.8}
      style={{
        width: '100%',
        position: 'sticky',
        top: '0',
        zIndex: '5',
        background: 'rgba(17, 20, 24, 0.97)',
        border: '1px solid rgba(70, 107, 150, 0.75)',
        borderRadius: '4px',
      }}
    >
      <Box px={0.35} py={0.3}>
        <Box
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '0.2rem',
            width: '100%',
          }}
        >
          {!!leadingAction && (
            <Box style={{ flex: '0 0 auto' }}>
              {renderAction(leadingAction, true)}
            </Box>
          )}

          {!!centerAction && (
            <Box style={{ flex: '1 1 auto', minWidth: '0' }}>
              {renderAction(centerAction, true, {
                fluid: true,
              })}
            </Box>
          )}

          {!!trailingAction && (
            <Box style={{ flex: '0 0 auto' }}>
              {renderAction(trailingAction, true)}
            </Box>
          )}

          {!!toolbar.undoAction && (
            <Box style={{ flex: '0 0 auto' }}>
              {renderUndoAction(toolbar.undoAction)}
            </Box>
          )}

          {data.has_generator && (
            <Box style={{ flex: '0 0 auto' }}>{renderConfirmAction()}</Box>
          )}
        </Box>
      </Box>

      {!!chromeError && (
        <Box
          px={0.5}
          py={0.22}
          color="bad"
          style={{
            borderTop: '1px solid rgba(143, 60, 52, 0.45)',
            background: 'rgba(143, 60, 52, 0.14)',
          }}
        >
          {chromeError}
        </Box>
      )}

      {showSharedModeShell && (
        <Box
          px={0.4}
          py={0.3}
          style={{
            borderTop: '1px solid rgba(70, 107, 150, 0.35)',
          }}
        >
          <SharedModePanel data={data} act={act} workspaceTab={workspaceTab} />
        </Box>
      )}

      <Box
        px={0.45}
        pt={0.3}
        pb={0.2}
        style={{
          minHeight: '2.15rem',
          borderTop: '1px solid rgba(70, 107, 150, 0.35)',
        }}
      >
        <NavigationTabs
          toolTabs={toolTabs}
          activeGeneratorId={data.current_generator_id}
          workspaceTab={workspaceTab}
          onSelectGenerator={onSelectGenerator}
          onSelectWorkspaceTab={onSelectWorkspaceTab}
        />
      </Box>
    </Box>
  );
};

const NavigationTabs = (props: {
  readonly toolTabs: GeneratorEntry[];
  readonly activeGeneratorId?: string;
  readonly workspaceTab: WorkspaceTabKey;
  readonly onSelectGenerator: (generatorId: string) => void;
  readonly onSelectWorkspaceTab: (tab: WorkspaceTabKey) => void;
}) => {
  const {
    toolTabs,
    activeGeneratorId,
    workspaceTab,
    onSelectGenerator,
    onSelectWorkspaceTab,
  } = props;

  if (!toolTabs.length && workspaceTab !== 'history') {
    return null;
  }

  return (
    <Tabs mb={0}>
      {toolTabs.map((generator) => (
        <Tabs.Tab
          key={generator.id}
          selected={
            workspaceTab === 'editor' && generator.id === activeGeneratorId
          }
          onClick={() => onSelectGenerator(generator.id)}
        >
          {TOOL_PICKER_LABELS[generator.id] || generator.name_ru}
        </Tabs.Tab>
      ))}
      <Tabs.Tab
        selected={workspaceTab === 'history'}
        onClick={() => onSelectWorkspaceTab('history')}
      >
        Журнал
      </Tabs.Tab>
    </Tabs>
  );
};

export {
  EditorChrome,
  getDestructionPreviewLegendItems,
  NavigationTabs,
  SharedModePanel,
};
