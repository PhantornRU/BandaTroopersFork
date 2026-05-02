import { useEffect, useMemo, useState } from 'react';

import { useBackend } from '../../backend';
import { Window } from '../../layouts';
import type { BackendData, WorkspaceTabKey } from './types';
import { buildWorldEditViewModel } from './viewModel';
import { WorkspacePage } from './workspaces';

export const WorldEditPanel = () => {
  const { data, act } = useBackend<BackendData>();
  const [workspaceTab, setWorkspaceTab] = useState<WorkspaceTabKey>('editor');
  const viewModel = useMemo(() => buildWorldEditViewModel(data), [data]);

  useEffect(() => {
    if (!data.has_generator && workspaceTab !== 'editor') {
      setWorkspaceTab('editor');
    }
  }, [data.has_generator, workspaceTab]);

  const handleSelectGenerator = (generatorId: string) => {
    if (workspaceTab !== 'editor') {
      setWorkspaceTab('editor');
    }
    if (generatorId && generatorId !== data.current_generator_id) {
      act('select_generator', {
        generator_id: generatorId,
      });
    }
  };

  return (
    <Window title="Панель редактирования мира" width={450} height={600}>
      <Window.Content>
        <WorkspacePage
          data={data}
          act={act}
          groupedFields={viewModel.groupedFields}
          groupNames={viewModel.groupNames}
          showPlacementSetup={viewModel.showPlacementSetup}
          toolTabs={viewModel.toolTabs}
          workspaceTab={workspaceTab}
          onSelectGenerator={handleSelectGenerator}
          onSelectWorkspaceTab={setWorkspaceTab}
        />
      </Window.Content>
    </Window>
  );
};
