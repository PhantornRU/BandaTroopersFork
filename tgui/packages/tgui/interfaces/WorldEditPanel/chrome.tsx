import { Box, Button, Collapsible, Flex, Tabs } from '../../components';
import {
  DEFAULT_DIRECTION_OPTIONS,
  DEFAULT_PLACEMENT_MODE_OPTIONS,
  DEFAULT_POINT_SHAPE_OPTION,
  TOOL_PICKER_LABELS,
} from './constants';
import {
  CompactChoiceStrip,
  CompactFieldControl,
  ShapeOptionStrip,
} from './fieldControls';
import {
  buildChromeSummaryItems,
  getBlueprintToolbarState,
  getCurrentToolTitle,
  getField,
  getFieldsById,
  getPlacementStateLine,
  getToolbarContextLine,
  getTranslatedDirection,
  getTranslatedPlacementMode,
  getTranslatedShapeLabel,
  getWorkflowHintText,
  isBlueprintToolBlocked,
} from './helpers';
import { StatusPill, TopShellControlGroup, WorkflowTrack } from './primitives';
import type {
  ActFn,
  BackendData,
  ChoiceOption,
  GeneratorEntry,
  PreviewLegendItem,
  ToolbarAction,
  ToolbarState,
  WorkspaceTabKey,
} from './types';

const getToolbarState = (data: BackendData): ToolbarState => {
  const title = getCurrentToolTitle(data);
  if (!data.has_generator && data.categories?.length) {
    return {
      title: 'World Edit',
      state: 'Открываем инструмент...',
      stateColor: 'label',
    };
  }

  if (!data.has_generator) {
    return {
      title: 'World Edit',
      state: 'Инструмент не выбран.',
      stateColor: 'label',
    };
  }

  const blueprintState = getBlueprintToolbarState(data);
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

  const baseState: ToolbarState = {
    title,
    state: 'Готово.',
    stateColor: 'label',
    context: getToolbarContextLine(data),
    previewAction,
    applyAction: effectiveApplyAction,
    placementAction: data.click_mode_active
      ? stopPlacementAction
      : placePreviewAction || startPlacementAction,
    collectorAction,
    undoAction,
  };

  if (data.last_ui_error) {
    return {
      ...baseState,
      state: data.last_ui_error,
      stateColor: 'bad',
    };
  }

  if (blueprintState) {
    return {
      ...baseState,
      state: blueprintState.state,
      stateColor: blueprintState.color,
    };
  }

  if (data.click_mode_active) {
    return {
      ...baseState,
      state: getPlacementStateLine(data),
      stateColor:
        data.placement_interaction_kind === 'collector' &&
        data.can_finish_placement_collection
          ? 'good'
          : 'average',
    };
  }

  if (data.requires_preview_before_apply && !data.preview_valid) {
    return {
      ...baseState,
      state: data.preview_message || 'Нет предпросмотра.',
      stateColor: data.preview_message ? 'bad' : 'label',
    };
  }

  if (data.preview_valid) {
    return {
      ...baseState,
      state: 'Предпросмотр готов.',
      stateColor: 'good',
    };
  }

  if (data.current_generator_supports_preview) {
    return {
      ...baseState,
      state: 'Нет предпросмотра.',
      stateColor: 'label',
    };
  }

  return {
    ...baseState,
    state: 'Можно применить.',
    stateColor: 'good',
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
    value: option.value,
    displayText: getTranslatedDirection(option.value || option.label),
  }));
  return options.length ? options : DEFAULT_DIRECTION_OPTIONS;
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
  const selectedShape =
    data.current_generator_id === 'destruction_pack'
      ? 'point'
      : `${data.placement_shape || shapeOptions[0]?.value || 'point'}`;
  const selectedMode = `${data.placement_mode || modeOptions[0]?.value || 'single'}`;
  const selectedDirection = `${data.placement_dir || directionOptions[0]?.value || 'north'}`;
  const shapeDisabled =
    isHistoryTab ||
    !hasGenerator ||
    !data.placement_shape_supported ||
    data.current_generator_id === 'destruction_pack';
  const modeDisabled =
    isHistoryTab || !hasGenerator || !data.placement_supported;
  const directionDisabled =
    isHistoryTab || !hasGenerator || !data.placement_supports_direction;
  const parametersDisabled =
    isHistoryTab || !hasGenerator || !sharedFields.length;

  return (
    <Box>
      <Flex wrap mx={-0.16}>
        <TopShellControlGroup
          label="Форма"
          value={getTranslatedShapeLabel(selectedShape)}
          basis="15rem"
          minWidth="13.5rem"
          disabled={shapeDisabled}
        >
          <ShapeOptionStrip
            options={shapeOptions}
            selected={selectedShape}
            disabled={shapeDisabled}
            buttonMinWidth="2.05rem"
            onSelected={(value) =>
              act('set_placement_shape', {
                shape: value,
              })
            }
          />
        </TopShellControlGroup>

        <TopShellControlGroup
          label="После клика"
          basis="10.5rem"
          minWidth="10.5rem"
          disabled={modeDisabled}
        >
          <CompactChoiceStrip
            options={modeOptions}
            selected={selectedMode}
            disabled={modeDisabled}
            buttonMinWidth="5rem"
            onSelected={(value) =>
              act('set_placement_mode', {
                mode: value,
              })
            }
          />
        </TopShellControlGroup>

        <TopShellControlGroup
          label="Направление"
          value={
            directionDisabled
              ? 'Недоступно'
              : data.placement_dir_uses_facing
                ? 'Взгляд'
                : getTranslatedDirection(selectedDirection)
          }
          basis="15rem"
          minWidth="14rem"
          disabled={directionDisabled}
        >
          <>
            <Button.Checkbox
              checked={data.placement_dir_uses_facing}
              disabled={directionDisabled}
              onClick={() =>
                act('set_placement_dir_uses_facing', {
                  enabled: !data.placement_dir_uses_facing,
                })
              }
            >
              По направлению взгляда
            </Button.Checkbox>
            <Box mt={0.3}>
              <CompactChoiceStrip
                options={directionOptions}
                selected={selectedDirection}
                disabled={directionDisabled || data.placement_dir_uses_facing}
                buttonMinWidth="4.65rem"
                onSelected={(value) =>
                  act('set_placement_dir', {
                    direction: value,
                  })
                }
              />
            </Box>
          </>
        </TopShellControlGroup>
      </Flex>

      {!!sharedFields.length && (
        <Box mt={0.45}>
          <Collapsible
            title={`Доп. параметры (${sharedFields.length})`}
            color={parametersDisabled ? 'label' : 'average'}
            open={sharedFields.length <= 2 || data.click_mode_active}
          >
            <Box mt={0.1}>
              <Flex wrap mx={-0.18}>
                {sharedFields.map((field) => (
                  <Flex.Item
                    key={field.id}
                    basis="12.5rem"
                    grow
                    m={0.18}
                    style={{ minWidth: '10.5rem' }}
                  >
                    <CompactFieldControl
                      field={field}
                      act={act}
                      disabled={parametersDisabled}
                    />
                  </Flex.Item>
                ))}
              </Flex>
            </Box>
          </Collapsible>
        </Box>
      )}

      {!sharedFields.length && (
        <Box color="label" mt={0.45}>
          Дополнительные параметры для текущего режима не нужны.
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
  const toolbar = getToolbarState(data);
  const actionsDisabled = !data.has_generator;
  const chromeTitle = toolbar.title;
  const chromeContext = toolbar.context;
  const workflowHint = getWorkflowHintText(data, workspaceTab);
  const summaryItems = buildChromeSummaryItems(data, workspaceTab);
  const primaryActions = [
    toolbar.previewAction,
    toolbar.applyAction,
    toolbar.placementAction,
    toolbar.collectorAction,
  ].filter((action): action is ToolbarAction => !!action);

  const renderAction = (action?: ToolbarAction, compact = false) => {
    if (!action) {
      return null;
    }

    return (
      <Button
        compact={compact}
        color={action.color}
        disabled={actionsDisabled || action.disabled}
        selected={action.action === 'clear_preview'}
        onClick={() => act(action.action, action.payload)}
      >
        {action.label}
      </Button>
    );
  };

  return (
    <Box
      mb={0.8}
      style={{
        position: 'sticky',
        top: '0',
        zIndex: '5',
        background: 'rgba(17, 20, 24, 0.97)',
        border: '1px solid rgba(70, 107, 150, 0.75)',
        borderRadius: '4px',
      }}
    >
      <Box px={0.65} py={0.5}>
        <Flex align="stretch" wrap mx={-0.25}>
          <Flex.Item grow basis="18rem" m={0.25}>
            <Box
              p={0.15}
              style={{
                minHeight: '100%',
              }}
            >
              <Box
                bold
                style={{
                  whiteSpace: 'nowrap',
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                }}
              >
                {chromeTitle}
              </Box>
              <Box
                color="label"
                mt={0.1}
                style={{
                  minHeight: '1.1rem',
                }}
              >
                {chromeContext || '\u00a0'}
              </Box>
              <Box mt={0.45}>
                <WorkflowTrack data={data} workspaceTab={workspaceTab} />
              </Box>
            </Box>
          </Flex.Item>

          <Flex.Item basis="15rem" grow m={0.25} style={{ minWidth: '14rem' }}>
            <Box
              px={0.55}
              py={0.45}
              style={{
                minHeight: '100%',
                border: '1px solid rgba(70, 107, 150, 0.45)',
                background: 'rgba(70, 107, 150, 0.10)',
                borderRadius: '4px',
              }}
            >
              <Box color="label">Сейчас</Box>
              <Box color={toolbar.stateColor || 'label'} bold mt={0.15}>
                {toolbar.state}
              </Box>
              <Box color="label" mt={0.3}>
                {workflowHint}
              </Box>
            </Box>
          </Flex.Item>

          <Flex.Item basis="22rem" grow m={0.25} style={{ minWidth: '17rem' }}>
            <Box
              px={0.15}
              py={0.1}
              style={{
                minHeight: '100%',
              }}
            >
              <Box color="label" mb={0.25}>
                Основные действия
              </Box>
              <Flex wrap mx={-0.15}>
                {primaryActions.map((action) => (
                  <Flex.Item key={action.action} m={0.15}>
                    {renderAction(
                      action,
                      action.action === 'finish_placement_collection' ||
                        data.click_mode_active,
                    )}
                  </Flex.Item>
                ))}
              </Flex>
              <Flex wrap align="center" mx={-0.15} mt={0.35}>
                {!!toolbar.undoAction && (
                  <Flex.Item m={0.15}>
                    {renderAction(toolbar.undoAction, true)}
                  </Flex.Item>
                )}
                {data.has_generator && (
                  <Flex.Item m={0.15}>
                    <Button.Checkbox
                      checked={data.confirm_before_apply}
                      disabled={actionsDisabled}
                      onClick={() =>
                        act('set_confirm_before_apply', {
                          enabled: !data.confirm_before_apply,
                        })
                      }
                    >
                      Подтверждать применение
                    </Button.Checkbox>
                  </Flex.Item>
                )}
              </Flex>
            </Box>
          </Flex.Item>
        </Flex>

        {!!summaryItems.length && (
          <Box mt={0.45}>
            <Flex wrap mx={-0.2}>
              {summaryItems.map((item) => (
                <Flex.Item key={item.label} m={0.2}>
                  <StatusPill
                    label={item.label}
                    value={item.value}
                    tone={item.tone}
                  />
                </Flex.Item>
              ))}
            </Flex>
          </Box>
        )}
      </Box>

      <Box
        px={0.65}
        py={0.45}
        style={{
          minHeight: '5rem',
          borderTop: '1px solid rgba(70, 107, 150, 0.35)',
        }}
      >
        <SharedModePanel data={data} act={act} workspaceTab={workspaceTab} />
      </Box>

      <Box
        px={0.5}
        pt={0.45}
        pb={0.3}
        style={{
          minHeight: '2.55rem',
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
