import { Box } from '../../components';
import { FieldListCard } from './fieldControls';
import { WorkspaceGrid, WorkspacePane } from './primitives';
import type { ActFn, BackendData, UiField } from './types';

const GenericFieldGroups = (props: {
  readonly groupedFields: Record<string, UiField[]>;
  readonly groupNames: string[];
  readonly act: ActFn;
}) => {
  const { groupedFields, groupNames, act } = props;
  if (!groupNames.length) {
    return <Box color="label">Поля временно недоступны.</Box>;
  }

  return (
    <WorkspaceGrid>
      {groupNames.map((groupName) => (
        <WorkspacePane key={groupName} basis="48%" minWidth="20rem">
          <FieldListCard
            title={groupName}
            fields={groupedFields[groupName] || []}
            act={act}
          />
        </WorkspacePane>
      ))}
    </WorkspaceGrid>
  );
};

const GenericToolWorkspace = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
  readonly groupedFields: Record<string, UiField[]>;
  readonly groupNames: string[];
  readonly showPlacementSetup: boolean;
}) => {
  const { data, act, groupedFields, groupNames, showPlacementSetup } = props;
  const hasPrimaryContent = data.has_inline_fields || showPlacementSetup;

  return (
    <>
      {!hasPrimaryContent && <Box color="label">Нет настроек.</Box>}

      {!!data.has_inline_fields && (
        <GenericFieldGroups
          groupedFields={groupedFields}
          groupNames={groupNames}
          act={act}
        />
      )}
    </>
  );
};

export { GenericFieldGroups, GenericToolWorkspace };
