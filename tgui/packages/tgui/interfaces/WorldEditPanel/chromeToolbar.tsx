import { Box, Button, Tabs } from '../../components';
import { CenteredIcon } from './chromeBits';
import {
  CHROME_ACTION_BUTTON_STYLE,
  CHROME_ICON_BUTTON_STYLE,
} from './chromeLayout';
import { getToolPickerLabel } from './toolRegistry';
import type { GeneratorEntry, ToolbarAction, WorkspaceTabKey } from './types';

const ToolbarActionRow = (props: {
  readonly leadingAction?: ToolbarAction;
  readonly centerAction?: ToolbarAction;
  readonly trailingAction?: ToolbarAction;
  readonly undoAction?: ToolbarAction;
  readonly actionsDisabled: boolean;
  readonly hasGenerator: boolean;
  readonly confirmBeforeApply: boolean;
  readonly onRunAction: (action: ToolbarAction) => void;
  readonly onToggleConfirmBeforeApply: () => void;
}) => {
  const {
    leadingAction,
    centerAction,
    trailingAction,
    undoAction,
    actionsDisabled,
    hasGenerator,
    confirmBeforeApply,
    onRunAction,
    onToggleConfirmBeforeApply,
  } = props;

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
        tooltip={compact ? action.tooltip || action.label : undefined}
        onClick={() => onRunAction(action)}
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
        tooltip={action.tooltip || action.label}
        onClick={() => onRunAction(action)}
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
      selected={confirmBeforeApply}
      color={confirmBeforeApply ? 'good' : 'transparent'}
      disabled={actionsDisabled}
      tooltip="Подтверждать применение"
      onClick={onToggleConfirmBeforeApply}
      style={CHROME_ICON_BUTTON_STYLE}
    >
      <CenteredIcon name={confirmBeforeApply ? 'check-square-o' : 'square-o'} />
    </Button>
  );

  return (
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

        {!!undoAction && (
          <Box style={{ flex: '0 0 auto' }}>{renderUndoAction(undoAction)}</Box>
        )}

        {hasGenerator && (
          <Box style={{ flex: '0 0 auto' }}>{renderConfirmAction()}</Box>
        )}
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
          {getToolPickerLabel(generator.id) || generator.name_ru}
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

export { NavigationTabs, ToolbarActionRow };
