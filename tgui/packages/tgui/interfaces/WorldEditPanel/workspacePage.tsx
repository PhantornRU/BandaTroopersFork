import { Box, Section } from '../../components';
import { EditorChrome } from './editorChrome';
import { CompactStatusRow, SurfaceCard } from './primitives';
import type {
  ActFn,
  BackendData,
  GeneratorEntry,
  UiField,
  WorkspaceTabKey,
} from './types';
import { HistoryWorkspace } from './workspaceHistory';
import { ToolWorkspace } from './workspaceTool';

const RuntimeStatusCard = (props: { readonly data: BackendData }) => {
  const items = (props.data.runtime_status || [])
    .filter((entry) => `${entry.label || ''}`.trim().length > 0)
    .map((entry) => ({
      label: entry.label,
      value: entry.value,
    }));

  if (!items.length) {
    return null;
  }

  return (
    <SurfaceCard
      title="Runtime"
      subtitle="Live hover/clamp/render counters for the current tool session."
      mt={0.6}
    >
      <CompactStatusRow items={items} basis="31%" />
    </SurfaceCard>
  );
};

const RuntimeTraceCard = (props: { readonly data: BackendData }) => {
  const items = (props.data.runtime_trace || [])
    .map((entry) => `${entry || ''}`.trim())
    .filter((entry) => entry.length > 0);

  if (!items.length) {
    return null;
  }

  return (
    <SurfaceCard
      title="Trace"
      subtitle="Last confirmed runtime stages for the current tool session."
      mt={0.6}
    >
      {items.map((entry, index) => (
        <Box key={`${index}-${entry}`} color="label">
          {entry}
        </Box>
      ))}
    </SurfaceCard>
  );
};

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

      {!!data.has_generator && <RuntimeStatusCard data={data} />}
      {!!data.has_generator && <RuntimeTraceCard data={data} />}
    </Section>
  );
};

export { WorkspacePage };
