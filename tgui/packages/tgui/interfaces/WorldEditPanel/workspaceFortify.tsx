import { Box } from '../../components';
import { FieldControlStack } from './fieldControls';
import { SurfaceCard, WorkspaceGrid, WorkspacePane } from './primitives';
import type { ActFn, BackendData } from './types';
import { getFortifyWorkspaceViewModel } from './viewModelFortify';

const FortifyRoomWorkspace = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
}) => {
  const { data, act } = props;
  const viewModel = getFortifyWorkspaceViewModel(data);

  return (
    <Box>
      {!!viewModel.primaryConfigFields.length && (
        <SurfaceCard title="Конфиг" mt={0}>
          <WorkspaceGrid>
            {viewModel.primaryConfigFields.map((field) => (
              <WorkspacePane key={field.id} basis="48%" minWidth="12.5rem">
                <FieldControlStack field={field} act={act} />
              </WorkspacePane>
            ))}
          </WorkspaceGrid>
          {!!viewModel.extraConfigFields.length && (
            <WorkspaceGrid>
              {viewModel.extraConfigFields.map((field) => (
                <WorkspacePane key={field.id} basis="48%" minWidth="12.5rem">
                  <FieldControlStack field={field} act={act} />
                </WorkspacePane>
              ))}
            </WorkspaceGrid>
          )}
        </SurfaceCard>
      )}

      {!!viewModel.boundsFields.length && (
        <SurfaceCard title="Границы/лимиты" mt={0.6}>
          <WorkspaceGrid>
            {viewModel.boundsFields.map((field) => (
              <WorkspacePane key={field.id} basis="48%" minWidth="12.5rem">
                <FieldControlStack field={field} act={act} />
              </WorkspacePane>
            ))}
          </WorkspaceGrid>
        </SurfaceCard>
      )}
    </Box>
  );
};

export { FortifyRoomWorkspace };
