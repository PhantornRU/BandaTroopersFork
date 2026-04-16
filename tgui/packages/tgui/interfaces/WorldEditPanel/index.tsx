import { useEffect, useMemo, useState } from 'react';

import { useBackend } from '../../backend';
import { Window } from '../../layouts';
import { buildOrderedToolTabs } from './constants';
import type { BackendData, UiField, WorkspaceTabKey } from './types';
import { WorkspacePage } from './workspaces';
export const WorldEditPanel = () => {
  const { data, act } = useBackend<BackendData>();
  const [workspaceTab, setWorkspaceTab] = useState<WorkspaceTabKey>('editor');
  const showPlacementSetup =
    data.placement_supported ||
    data.placement_shape_supported ||
    data.placement_supports_direction;
  const toolTabs = useMemo(
    () => buildOrderedToolTabs(data.categories || []),
    [data.categories],
  );

  const groupedFields = useMemo(() => {
    const groups: Record<string, UiField[]> = {};
    for (const field of data.ui_fields || []) {
      const groupName = field.group || 'РћСЃРЅРѕРІРЅС‹Рµ';
      if (!groups[groupName]) {
        groups[groupName] = [];
      }
      groups[groupName].push(field);
    }
    return groups;
  }, [data.ui_fields]);

  const groupNames = useMemo(() => Object.keys(groupedFields), [groupedFields]);

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
    <Window title="World Edit Panel" width={980} height={690}>
      <Window.Content>
        <WorkspacePage
          data={data}
          act={act}
          groupedFields={groupedFields}
          groupNames={groupNames}
          showPlacementSetup={showPlacementSetup}
          toolTabs={toolTabs}
          workspaceTab={workspaceTab}
          onSelectGenerator={handleSelectGenerator}
          onSelectWorkspaceTab={setWorkspaceTab}
        />
      </Window.Content>
    </Window>
  );
};
