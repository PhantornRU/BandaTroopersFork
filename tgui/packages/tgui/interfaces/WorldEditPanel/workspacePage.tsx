import { Box, Section } from '../../components';
import { EditorChrome } from './editorChrome';
import type {
  ActFn,
  BackendData,
  GeneratorEntry,
  UiField,
  WorkspaceTabKey,
} from './types';
import { HistoryWorkspace } from './workspaceHistory';
import { ToolWorkspace } from './workspaceTool';

const WorkspacePage = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
  readonly groupedFields: Record<string, UiField[]>;
  readonly groupNames: string[];
  readonly showPlacementSetup: boolean;
  readonly toolTabs: GeneratorEntry[];
  readonly workspaceTab: WorkspaceTabKey;
  readonly onSelectGenerator: (generatorId: string) => void;
  readonly onSelectWorkspaceTab: (tab: WorkspaceTabKey) => void;
}) => {
  const {
    data,
    act,
    groupedFields,
    groupNames,
    showPlacementSetup,
    toolTabs,
    workspaceTab,
    onSelectGenerator,
    onSelectWorkspaceTab,
  } = props;

  return (
    <Section fill scrollable>
      <EditorChrome
        data={data}
        act={act}
        toolTabs={toolTabs}
        workspaceTab={workspaceTab}
        onSelectGenerator={onSelectGenerator}
        onSelectWorkspaceTab={onSelectWorkspaceTab}
      />

      {!data.has_generator && !!data.categories?.length && (
        <Box color="label" mt={0.1}>
          Загрузка...
        </Box>
      )}

      {!data.has_generator && !data.categories?.length && (
        <Box color="label" mt={0.1}>
          Нет инструментов.
        </Box>
      )}

      {!!data.has_generator &&
        (workspaceTab === 'editor' ? (
          <ToolWorkspace
            data={data}
            act={act}
            groupedFields={groupedFields}
            groupNames={groupNames}
            showPlacementSetup={showPlacementSetup}
          />
        ) : (
          <HistoryWorkspace data={data} act={act} />
        ))}
    </Section>
  );
};

export { WorkspacePage };
