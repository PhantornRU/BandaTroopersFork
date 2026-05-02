import { Box } from '../../components';
import { NavigationTabs, ToolbarActionRow } from './chromeComponents';
import { SharedModePanel } from './chromeSharedMode';
import type {
  ActFn,
  BackendData,
  GeneratorEntry,
  WorkspaceTabKey,
} from './types';
import { getEditorChromeViewModel } from './viewModel';

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
  const chrome = getEditorChromeViewModel(data, workspaceTab);

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
      <ToolbarActionRow
        leadingAction={chrome.leadingAction}
        centerAction={chrome.centerAction}
        trailingAction={chrome.trailingAction}
        undoAction={chrome.toolbar.undoAction}
        actionsDisabled={chrome.actionsDisabled}
        hasGenerator={data.has_generator}
        confirmBeforeApply={data.confirm_before_apply}
        onRunAction={(action) => act(action.action, action.payload)}
        onToggleConfirmBeforeApply={() =>
          act('set_confirm_before_apply', {
            enabled: !data.confirm_before_apply,
          })
        }
      />

      {!!chrome.chromeError && (
        <Box
          px={0.5}
          py={0.22}
          color="bad"
          style={{
            borderTop: '1px solid rgba(143, 60, 52, 0.45)',
            background: 'rgba(143, 60, 52, 0.14)',
          }}
        >
          {chrome.chromeError}
        </Box>
      )}

      {chrome.showSharedModeShell && (
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

export { EditorChrome };
