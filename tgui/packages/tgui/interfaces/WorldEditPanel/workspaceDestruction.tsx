import { FieldBlock } from './fieldControls';
import { SurfaceCard, WorkspaceGrid, WorkspacePane } from './primitives';
import type { ActFn, BackendData } from './types';
import { getDestructionWorkspaceViewModel } from './viewModel';
import {
  DestructionModeBlock,
  DestructionMovementBlock,
} from './workspaceDestructionBlocks';

const DestructionPackWorkspace = (props: {
  readonly data: BackendData;
  readonly act: ActFn;
}) => {
  const { data, act } = props;
  const viewModel = getDestructionWorkspaceViewModel(data);

  return (
    <>
      {(!!viewModel.areaFields.length ||
        !!viewModel.movementFields.visibleMovementFields.length) && (
        <SurfaceCard>
          <WorkspaceGrid>
            {!!viewModel.movementFields.visibleMovementFields.length && (
              <WorkspacePane
                basis={viewModel.areaFields.length ? '48%' : '100%'}
                minWidth="19rem"
              >
                <DestructionMovementBlock
                  shuffleField={viewModel.movementFields.shuffleField}
                  scatterField={viewModel.movementFields.scatterField}
                  maxAtomsField={viewModel.movementFields.maxAtomsField}
                  scatterStepsField={viewModel.movementFields.scatterStepsField}
                  act={act}
                  tone={viewModel.movementEnabled ? 'average' : 'default'}
                  activeItems={viewModel.previewLegendItems}
                />
              </WorkspacePane>
            )}
            {!!viewModel.areaFields.length && (
              <WorkspacePane basis="48%" minWidth="19rem">
                <FieldBlock
                  title="Зона"
                  fields={viewModel.areaFields}
                  act={act}
                />
              </WorkspacePane>
            )}
          </WorkspaceGrid>
        </SurfaceCard>
      )}

      <SurfaceCard
        mt={
          viewModel.areaFields.length ||
          viewModel.movementFields.visibleMovementFields.length
            ? 0.6
            : 0
        }
        tone={
          viewModel.destructiveEnabled
            ? 'bad'
            : viewModel.fireEnabled
              ? 'average'
              : 'default'
        }
      >
        <WorkspaceGrid>
          <WorkspacePane basis="48%" minWidth="16rem">
            <DestructionModeBlock
              title="Огонь"
              fields={viewModel.fireFields}
              act={act}
              tone={viewModel.fireEnabled ? 'average' : 'default'}
            />
          </WorkspacePane>
          <WorkspacePane basis="48%" minWidth="16rem">
            <DestructionModeBlock
              title="Взрыв"
              fields={viewModel.blastFields}
              act={act}
              tone={viewModel.blastEnabled ? 'bad' : 'default'}
            />
          </WorkspacePane>
          <WorkspacePane basis="100%" minWidth="16rem">
            <FieldBlock
              title="Структурный урон"
              fields={viewModel.damageFields}
              act={act}
              tone={viewModel.damageProfile !== 'none' ? 'bad' : 'default'}
            />
          </WorkspacePane>
        </WorkspaceGrid>
      </SurfaceCard>
    </>
  );
};

export { DestructionPackWorkspace };
