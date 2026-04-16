import type { ActFn, BackendData, UiField } from './types';
import { BlueprintStampWorkspace } from './workspaceBlueprint';
import { DestructionPackWorkspace } from './workspaceDestruction';
import { GenericToolWorkspace } from './workspaceGeneric';
import { OutpostRadiusWorkspace } from './workspaceOutpost';

const ToolWorkspace = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
  readonly groupedFields: Record<string, UiField[]>;
  readonly groupNames: string[];
  readonly showPlacementSetup: boolean;
}) => {
  const { data, act, groupedFields, groupNames, showPlacementSetup } = props;

  if (data.current_generator_id === 'blueprint_stamp') {
    return <BlueprintStampWorkspace data={data} act={act} />;
  }

  if (data.current_generator_id === 'outpost_radius') {
    return <OutpostRadiusWorkspace data={data} act={act} />;
  }

  if (data.current_generator_id === 'destruction_pack') {
    return <DestructionPackWorkspace data={data} act={act} />;
  }

  return (
    <GenericToolWorkspace
      data={data}
      act={act}
      groupedFields={groupedFields}
      groupNames={groupNames}
      showPlacementSetup={showPlacementSetup}
    />
  );
};

export { ToolWorkspace };
