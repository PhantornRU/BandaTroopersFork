import { renderToolWorkspace } from './toolWorkspaceRegistry';
import type { ActFn, BackendData, UiField } from './types';

const ToolWorkspace = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
  readonly groupedFields: Record<string, UiField[]>;
  readonly groupNames: string[];
  readonly showPlacementSetup: boolean;
}) => {
  const { data, act, groupedFields, groupNames, showPlacementSetup } = props;

  return renderToolWorkspace({
    data,
    act,
    groupedFields,
    groupNames,
    showPlacementSetup,
  });
};

export { ToolWorkspace };
