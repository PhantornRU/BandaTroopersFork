import { BooleanLike, classes } from 'common/react';
import { useState } from 'react';

import { useBackend } from '../backend';
import {
  Box,
  Button,
  Collapsible,
  Divider,
  Dropdown,
  Section,
  Stack,
} from '../components';
import { Window } from '../layouts';

type Defense = {
  name: string;
  path: string;
  description: string;
  image: string;
  uses_faction: BooleanLike;
  uses_turned_on: BooleanLike;
};

type BackendContext = {
  valid_factions: string[];
  defenses: { [key: string]: Defense[] };
  selected_faction: string;
  selected_place_dir: string;
  selected_turned_on: BooleanLike;
  spawn_click_intercept: BooleanLike;
  current_path: string | null;
};

export const HumanDefenseManager = (props) => {
  const { data, act } = useBackend<BackendContext>();
  const { defenses, valid_factions } = data;
  const [chosenDefense, setDefense] = useState<Defense | null>(null);
  const activeDefense =
    (chosenDefense && chosenDefense.path === data.current_path
      ? chosenDefense
      : Object.values(defenses)
          .flat()
          .find((defense) => defense.path === data.current_path)) ||
    chosenDefense;

  return (
    <Window title="Human Defense Creator" width={800} height={900}>
      <Window.Content>
        <Stack fill vertical>
          <Stack fill>
            <Stack.Item grow mr={1}>
              <Section fill height="100%">
                {Object.keys(defenses).map((dictKey) => (
                  <Collapsible title={dictKey} key={dictKey} color="good">
                    {defenses[dictKey].map((defense) => (
                      <div style={{ paddingBottom: '12px' }} key={defense.path}>
                        <Button
                          fontSize="15px"
                          textAlign="center"
                          selected={defense.path === activeDefense?.path}
                          width="100%"
                          key={defense.path}
                          onClick={() => {
                            setDefense(defense);
                            act('remember_path', {
                              path: defense.path,
                            });
                          }}
                        >
                          {defense.name}
                        </Button>
                      </div>
                    ))}
                  </Collapsible>
                ))}
              </Section>
            </Stack.Item>
            <Divider vertical />
            <Stack.Item width="30%">
              <Section title="Selected Defense">
                {activeDefense !== null && (
                  <Stack vertical>
                    <Stack.Item>
                      <div
                        style={{
                          display: 'flex',
                          justifyContent: 'center',
                          alignItems: 'center',
                        }}
                      >
                        <Box key={activeDefense.path}>
                          <span
                            className={classes([
                              'defensemenu128x128',
                              `${activeDefense.image}`,
                            ])}
                          />
                        </Box>
                      </div>
                    </Stack.Item>
                    <Stack.Item>{activeDefense.description}</Stack.Item>
                    <Stack.Item>
                      <div style={{ textAlign: 'center' }}>
                        <div
                          style={{
                            display: 'inline-block',
                            verticalAlign: 'middle',
                          }}
                        >
                          <Button.Checkbox
                            onClick={() => act('toggle_selected_turned_on')}
                            checked={!!data.selected_turned_on}
                            disabled={!activeDefense.uses_turned_on}
                          >
                            Turned On
                          </Button.Checkbox>
                        </div>
                        <div
                          style={{
                            display: 'inline-block',
                            verticalAlign: 'middle',
                          }}
                        >
                          <Dropdown
                            options={valid_factions}
                            selected={data.selected_faction}
                            onSelected={(value) =>
                              act('set_selected_faction', {
                                selected_faction: value,
                              })
                            }
                            width={10}
                            disabled={!activeDefense.uses_faction}
                          />
                        </div>
                        <div
                          style={{
                            display: 'inline-block',
                            verticalAlign: 'middle',
                          }}
                        >
                          <Dropdown
                            options={[
                              'Default',
                              'North',
                              'East',
                              'South',
                              'West',
                            ]}
                            selected={data.selected_place_dir}
                            onSelected={(value) =>
                              act('set_selected_place_dir', {
                                place_dir: value,
                              })
                            }
                            width={10}
                            placeholder="Direction..."
                          />
                        </div>
                      </div>
                    </Stack.Item>
                    <Stack.Item>
                      <Stack>
                        <Stack.Item grow>
                          <Button
                            textAlign="center"
                            width="100%"
                            onClick={() =>
                              act('spawn_defense_here', {
                                path: activeDefense.path,
                                turned_on: data.selected_turned_on,
                                faction: data.selected_faction,
                                place_dir: data.selected_place_dir,
                              })
                            }
                          >
                            Spawn Here
                          </Button>
                        </Stack.Item>
                        <Stack.Item grow>
                          <Button
                            textAlign="center"
                            width="100%"
                            selected={!!data.spawn_click_intercept}
                            onClick={() =>
                              act('toggle_click_spawn', {
                                path: activeDefense.path,
                                turned_on: data.selected_turned_on,
                                faction: data.selected_faction,
                                place_dir: data.selected_place_dir,
                              })
                            }
                          >
                            Click Spawn
                          </Button>
                        </Stack.Item>
                      </Stack>
                    </Stack.Item>
                  </Stack>
                )}
              </Section>
            </Stack.Item>
          </Stack>
        </Stack>
      </Window.Content>
    </Window>
  );
};
