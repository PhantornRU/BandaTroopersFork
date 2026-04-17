import {
  DEFAULT_DIRECTION_OPTIONS,
  DEFAULT_PLACEMENT_MODE_OPTIONS,
  DEFAULT_POINT_SHAPE_OPTION,
} from './constants';
import {
  getField,
  getFieldsById,
  getSelectedBlueprint,
  getTranslatedDirection,
  getTranslatedPlacementMode,
  isBlueprintToolBlocked,
} from './helpers';
import type {
  BackendData,
  ChoiceOption,
  PlacementOption,
  ToolbarAction,
  ToolbarActions,
  UiField,
  WorkspaceTabKey,
} from './types';

type EditorChromeViewModel = {
  toolbar: ToolbarActions;
  actionsDisabled: boolean;
  chromeError: string;
  showSharedModeShell: boolean;
  leadingAction?: ToolbarAction;
  centerAction?: ToolbarAction;
  trailingAction?: ToolbarAction;
};

type SharedModeViewModel = {
  sharedFields: UiField[];
  shapeOptions: PlacementOption[];
  modeOptions: ChoiceOption[];
  directionOptions: ChoiceOption[];
  selectedShape: string;
  selectedMode: string;
  selectedDirection: string;
  radiusField?: UiField;
  activeBlueprint?: ReturnType<typeof getSelectedBlueprint>;
  showRadiusSection: boolean;
  showShapeSection: boolean;
  showModeSection: boolean;
  showDirectionSection: boolean;
  hasTopControls: boolean;
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
  const shapeFields = (data.placement_shape_fields || []).filter(
    (field) => field.visible !== false && field.id !== 'radius',
  );

  if (data.current_generator_id === 'blueprint_stamp') {
    return [
      ...getFieldsById(data.ui_fields, ['stamp_spacing']),
      ...shapeFields,
    ];
  }

  return shapeFields;
};

const getPlacementModeChoices = (data: BackendData): ChoiceOption[] => {
  const options: ChoiceOption[] = [];
  const seenValues = new Set<string>();

  for (const option of data.placement_mode_options || []) {
    const normalizedValue = `${option.value || option.label || ''}`
      .trim()
      .toLowerCase();

    if (!['single', 'repeat'].includes(normalizedValue)) {
      continue;
    }

    if (seenValues.has(normalizedValue)) {
      continue;
    }

    seenValues.add(normalizedValue);
    options.push({
      value: normalizedValue,
      displayText: getTranslatedPlacementMode(normalizedValue),
    });
  }

  return options.length ? options : DEFAULT_PLACEMENT_MODE_OPTIONS;
};

const getPlacementShapeOptionsForShell = (
  data: BackendData,
): PlacementOption[] => {
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
) => workspaceTab !== 'history' && !!data.has_generator;

const getEditorChromeViewModel = (
  data: BackendData,
  workspaceTab: WorkspaceTabKey,
): EditorChromeViewModel => {
  const toolbar = getToolbarActions(data);
  const centerAction =
    toolbar.placementAction || toolbar.applyAction || toolbar.collectorAction;

  return {
    toolbar,
    actionsDisabled: !data.has_generator,
    chromeError: `${data.last_ui_error || ''}`.trim(),
    showSharedModeShell: hasSharedModeContent(data, workspaceTab),
    leadingAction: toolbar.previewAction,
    centerAction,
    trailingAction:
      toolbar.collectorAction &&
      toolbar.collectorAction.action !== centerAction?.action
        ? toolbar.collectorAction
        : undefined,
  };
};

const getSharedModeViewModel = (
  data: BackendData,
  workspaceTab: WorkspaceTabKey,
): SharedModeViewModel => {
  const isHistoryTab = workspaceTab === 'history';
  const hasGenerator = !!data.has_generator;
  const shapeOptions = getPlacementShapeOptionsForShell(data);
  const modeOptions = getPlacementModeChoices(data);
  const directionOptions = getPlacementDirectionChoices(data);
  const sharedFields = getSharedChromeFields(data).filter(
    (field) => field.visible !== false,
  );
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
  const showShapeSection =
    !isHistoryTab &&
    hasGenerator &&
    data.placement_shape_supported &&
    !!shapeOptions.length;
  const showModeSection =
    !isHistoryTab && hasGenerator && data.placement_supported;
  const showDirectionSection =
    !isHistoryTab && hasGenerator && !!directionOptions.length;
  const hasTopControls =
    showShapeSection ||
    showModeSection ||
    showDirectionSection ||
    showRadiusSection;
  const selectedMode =
    modeOptions.find(
      (option) =>
        option.value === `${data.placement_mode || ''}`.trim().toLowerCase(),
    )?.value ||
    modeOptions[0]?.value ||
    'single';

  return {
    sharedFields,
    shapeOptions,
    modeOptions,
    directionOptions,
    selectedShape: `${data.placement_shape || shapeOptions[0]?.value || 'point'}`,
    selectedMode,
    selectedDirection:
      `${data.placement_dir || directionOptions[0]?.value || 'north'}`
        .trim()
        .toLowerCase(),
    radiusField,
    activeBlueprint,
    showRadiusSection,
    showShapeSection,
    showModeSection,
    showDirectionSection,
    hasTopControls,
  };
};

export {
  getEditorChromeViewModel,
  getPlacementDirectionChoices,
  getPlacementModeChoices,
  getPlacementShapeOptionsForShell,
  getSharedChromeFields,
  getSharedModeViewModel,
  getToolbarActions,
  hasSharedModeContent,
};
export type { EditorChromeViewModel, SharedModeViewModel };
