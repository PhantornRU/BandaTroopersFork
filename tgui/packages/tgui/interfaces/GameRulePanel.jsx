// SS220 EDIT - START: Game Rule Panel TGUI interface
import { useEffect, useState } from 'react';

import { useBackend } from '../backend';
import {
  Box,
  Button,
  NoticeBox,
  NumberInput,
  Section,
  Stack,
  Tabs,
} from '../components';
import { Window } from '../layouts';

const PAGES = [
  {
    id: 'rto',
    title: 'RTO Support',
    color: 'blue',
    icon: 'satellite-dish',
  },
  {
    id: 'fire_support',
    title: 'Fire Support',
    color: 'orange',
    icon: 'crosshairs',
  },
  {
    id: 'player_survival',
    title: 'Player Survival',
    color: 'red',
    icon: 'heartbeat',
  },
];

const sanitizeNumberInputValue = (value, fallback) =>
  typeof value === 'number' && Number.isFinite(value) ? value : fallback;

const getPoolFieldKey = (targetCkey, templateId, field) =>
  `${targetCkey || 'unknown'}:${templateId}:${field}`;

const getPoolFieldValue = (
  poolFormValues,
  targetCkey,
  templateId,
  field,
  fallback,
) =>
  sanitizeNumberInputValue(
    poolFormValues[getPoolFieldKey(targetCkey, templateId, field)],
    fallback,
  );

const FactionBadge = ({ faction }) => (
  <Box
    backgroundColor="rgba(255, 255, 255, 0.08)"
    inline
    mr={0.5}
    p="2px 6px"
    style={{
      borderRadius: '999px',
    }}
  >
    {faction}
  </Box>
);

const FireSupportEntryButton = ({ entry, enabled }) => {
  const { act } = useBackend();

  return (
    <Button
      fluid
      mb={0.5}
      textAlign="left"
      color={enabled ? 'good' : 'average'}
      onClick={() =>
        act('set_fire_support_type_enabled', {
          type_id: entry.type_id,
          enabled: enabled ? 0 : 1,
        })
      }
    >
      <Box bold>{entry.name}</Box>
      <Box color="label">
        <FactionBadge faction={entry.faction} />
        Cost: {entry.cost} | Cooldown: {entry.cooldown_duration}s
        {!!entry.fire_support_firer && ` | Firer: ${entry.fire_support_firer}`}
      </Box>
    </Button>
  );
};

const RtoChargePoolCard = ({
  player,
  pool,
  poolFormValues,
  setPoolFormValues,
}) => {
  const { act } = useBackend();
  const targetCkey = player.ckey;
  const setValue = getPoolFieldValue(
    poolFormValues,
    targetCkey,
    pool.template_id,
    'set',
    pool.current_charges,
  );
  const adjustValue = getPoolFieldValue(
    poolFormValues,
    targetCkey,
    pool.template_id,
    'adjust',
    1,
  );
  const capacityValue = getPoolFieldValue(
    poolFormValues,
    targetCkey,
    pool.template_id,
    'capacity',
    pool.capacity,
  );

  const updateField = (field, value, fallback) =>
    setPoolFormValues((prev) => ({
      ...prev,
      [getPoolFieldKey(targetCkey, pool.template_id, field)]:
        sanitizeNumberInputValue(value, fallback),
    }));

  return (
    <Box
      backgroundColor="rgba(255, 255, 255, 0.04)"
      mb={1}
      p={1}
      style={{
        border: '1px solid rgba(255, 255, 255, 0.08)',
        borderRadius: '4px',
      }}
    >
      <Box bold>
        {pool.template_name} ({pool.template_id})
      </Box>
      <Box color="label" mb={1}>
        Mode: {pool.resource_mode} | Charges: {pool.current_charges}/
        {pool.capacity} | Recharge:{' '}
        {pool.manual_only || !pool.auto_recharge_enabled
          ? 'disabled'
          : pool.next_recharge_in > 0
            ? `${pool.next_recharge_in}s`
            : 'ready'}
      </Box>
      <Box color="label" mb={1}>
        Start: {pool.starting_charges} | Tick: +{pool.recharge_amount} every{' '}
        {pool.recharge_interval}s | Last GM edit:{' '}
        {pool.last_modified_by_admin_ckey || 'none'}
      </Box>

      <Stack vertical>
        <Stack.Item>
          <Stack align="center">
            <Stack.Item grow>
              <Box bold>Set current charges</Box>
            </Stack.Item>
            <Stack.Item>
              <NumberInput
                minValue={0}
                maxValue={999}
                step={1}
                stepPixelSize={10}
                value={setValue}
                width="6em"
                onChange={(value) =>
                  updateField('set', value, pool.current_charges)
                }
              />
            </Stack.Item>
            <Stack.Item>
              <Button
                color="good"
                onClick={() =>
                  act('set_rto_player_pool_current_charges', {
                    target_ckey: targetCkey,
                    template_id: pool.template_id,
                    value: setValue,
                  })
                }
              >
                Set
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>

        <Stack.Item>
          <Stack align="center">
            <Stack.Item grow>
              <Box bold>Add or subtract charges</Box>
            </Stack.Item>
            <Stack.Item>
              <NumberInput
                minValue={0}
                maxValue={999}
                step={1}
                stepPixelSize={10}
                value={adjustValue}
                width="6em"
                onChange={(value) => updateField('adjust', value, 1)}
              />
            </Stack.Item>
            <Stack.Item>
              <Button
                color="good"
                onClick={() =>
                  act('adjust_rto_player_pool_current_charges', {
                    target_ckey: targetCkey,
                    template_id: pool.template_id,
                    value: adjustValue,
                  })
                }
              >
                Add
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button
                color="average"
                onClick={() =>
                  act('adjust_rto_player_pool_current_charges', {
                    target_ckey: targetCkey,
                    template_id: pool.template_id,
                    value: -adjustValue,
                  })
                }
              >
                Subtract
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>

        <Stack.Item>
          <Stack align="center">
            <Stack.Item grow>
              <Box bold>Set max charges</Box>
            </Stack.Item>
            <Stack.Item>
              <NumberInput
                minValue={0}
                maxValue={999}
                step={1}
                stepPixelSize={10}
                value={capacityValue}
                width="6em"
                onChange={(value) =>
                  updateField('capacity', value, pool.capacity)
                }
              />
            </Stack.Item>
            <Stack.Item>
              <Button
                color="good"
                onClick={() =>
                  act('set_rto_player_pool_capacity', {
                    target_ckey: targetCkey,
                    template_id: pool.template_id,
                    value: capacityValue,
                  })
                }
              >
                Apply
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>

        <Stack.Item>
          <Stack>
            <Stack.Item>
              <Button
                color="good"
                onClick={() =>
                  act('set_rto_player_pool_current_charges', {
                    target_ckey: targetCkey,
                    template_id: pool.template_id,
                    value: pool.capacity,
                  })
                }
              >
                Refill
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button
                color="average"
                onClick={() =>
                  act('set_rto_player_pool_current_charges', {
                    target_ckey: targetCkey,
                    template_id: pool.template_id,
                    value: 0,
                  })
                }
              >
                Empty
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button.Checkbox
                checked={!!pool.auto_recharge_enabled}
                onClick={() =>
                  act('set_rto_player_pool_auto_recharge', {
                    target_ckey: targetCkey,
                    template_id: pool.template_id,
                    enabled: pool.auto_recharge_enabled ? 0 : 1,
                  })
                }
              >
                Auto Recharge
              </Button.Checkbox>
            </Stack.Item>
            <Stack.Item>
              <Button.Checkbox
                checked={!!pool.manual_only}
                onClick={() =>
                  act('set_rto_player_pool_manual_only', {
                    target_ckey: targetCkey,
                    template_id: pool.template_id,
                    enabled: pool.manual_only ? 0 : 1,
                  })
                }
              >
                Manual Only
              </Button.Checkbox>
            </Stack.Item>
            <Stack.Item>
              <Button
                color="average"
                onClick={() =>
                  act('reset_rto_player_pool', {
                    target_ckey: targetCkey,
                    template_id: pool.template_id,
                  })
                }
              >
                Reset Pool
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
    </Box>
  );
};

const RtoActivePlayerCard = ({ player, poolFormValues, setPoolFormValues }) => {
  const { act } = useBackend();
  const selectedTemplates = player.selected_templates || [];
  const selectedTemplateEntries = player.selected_template_entries || [];
  const pools = player.pools || [];

  return (
    <Section
      key={player.ckey || player.name}
      level={3}
      title={`${player.name} (${player.ckey || 'no ckey'})`}
    >
      <Box color="label" mb={1}>
        Job: {player.job || 'unknown'} | Profile: {player.support_profile} |
        Selected packages:{' '}
        {selectedTemplates.length ? selectedTemplates.join(', ') : 'none'}
      </Box>

      {!!selectedTemplateEntries.length && (
        <Stack mb={1} wrap>
          {selectedTemplateEntries.map((template) => (
            <Stack.Item key={`${player.ckey}:${template.template_id}`}>
              <Button
                color="average"
                icon="trash"
                onClick={() =>
                  act('remove_rto_player_template', {
                    target_ckey: player.ckey,
                    template_id: template.template_id,
                  })
                }
              >
                Убрать {template.name}
              </Button>
            </Stack.Item>
          ))}
        </Stack>
      )}

      {!!pools.length && (
        <Stack mb={1}>
          <Stack.Item>
            <Button
              color="good"
              onClick={() =>
                act('refill_rto_player_pools', {
                  target_ckey: player.ckey,
                })
              }
            >
              Refill All
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button
              color="average"
              onClick={() =>
                act('empty_rto_player_pools', {
                  target_ckey: player.ckey,
                })
              }
            >
              Empty All
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button
              color="good"
              onClick={() =>
                act('set_rto_player_pools_auto_recharge', {
                  target_ckey: player.ckey,
                  enabled: 1,
                })
              }
            >
              Enable Recharge
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button
              color="average"
              onClick={() =>
                act('set_rto_player_pools_auto_recharge', {
                  target_ckey: player.ckey,
                  enabled: 0,
                })
              }
            >
              Disable Recharge
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button
              color="average"
              onClick={() =>
                act('set_rto_player_pools_manual_only', {
                  target_ckey: player.ckey,
                  enabled: 1,
                })
              }
            >
              Manual Issue Mode
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button
              color="good"
              onClick={() =>
                act('set_rto_player_pools_manual_only', {
                  target_ckey: player.ckey,
                  enabled: 0,
                })
              }
            >
              Resume Auto Mode
            </Button>
          </Stack.Item>
        </Stack>
      )}

      {!pools.length && (
        <NoticeBox warning>
          This RTO has no active support pools yet. They will appear here after
          the player selects at least one support package.
        </NoticeBox>
      )}

      {pools.map((pool) => (
        <RtoChargePoolCard
          key={`${player.ckey}:${pool.template_id}`}
          player={player}
          pool={pool}
          poolFormValues={poolFormValues}
          setPoolFormValues={setPoolFormValues}
        />
      ))}
    </Section>
  );
};

const RtoSupportPage = ({
  data,
  sharedMultiplier,
  personalMultiplier,
  rechargeMultiplier,
  capacityMultiplier,
  templateSlotCount,
  templateResetMinutes,
  setSharedMultiplier,
  setPersonalMultiplier,
  setRechargeMultiplier,
  setCapacityMultiplier,
  setTemplateSlotCount,
  setTemplateResetMinutes,
}) => {
  const { act } = useBackend();
  const safeSharedMultiplier = sanitizeNumberInputValue(sharedMultiplier, 1);
  const safePersonalMultiplier = sanitizeNumberInputValue(
    personalMultiplier,
    1,
  );
  const safeRechargeMultiplier = sanitizeNumberInputValue(
    rechargeMultiplier,
    1,
  );
  const safeCapacityMultiplier = sanitizeNumberInputValue(
    capacityMultiplier,
    1,
  );
  const safeTemplateSlotCount = sanitizeNumberInputValue(templateSlotCount, 2);
  const safeTemplateResetMinutes = sanitizeNumberInputValue(
    templateResetMinutes,
    60,
  );
  const templateSlotCountCap = data.rto_template_slot_count_cap || 2;
  const activeRtoPlayers = data.rto_active_players || [];
  const [poolFormValues, setPoolFormValues] = useState({});

  useEffect(() => {
    setPoolFormValues((prev) => {
      const next = {};
      activeRtoPlayers.forEach((player) => {
        (player.pools || []).forEach((pool) => {
          next[getPoolFieldKey(player.ckey, pool.template_id, 'set')] =
            sanitizeNumberInputValue(
              prev[getPoolFieldKey(player.ckey, pool.template_id, 'set')],
              pool.current_charges,
            );
          next[getPoolFieldKey(player.ckey, pool.template_id, 'adjust')] =
            sanitizeNumberInputValue(
              prev[getPoolFieldKey(player.ckey, pool.template_id, 'adjust')],
              1,
            );
          next[getPoolFieldKey(player.ckey, pool.template_id, 'capacity')] =
            sanitizeNumberInputValue(
              prev[getPoolFieldKey(player.ckey, pool.template_id, 'capacity')],
              pool.capacity,
            );
        });
      });
      return next;
    });
  }, [activeRtoPlayers]);

  return (
    <Section fill title="RTO Support">
      <Section level={2} title="General">
        <Button.Checkbox
          checked={!!data.rto_support_enabled}
          fluid
          onClick={() =>
            act('set_rto_support_enabled', {
              enabled: data.rto_support_enabled ? 0 : 1,
            })
          }
        >
          Enable RTO Support
        </Button.Checkbox>
        <Button.Checkbox
          checked={!!data.support_underground_enabled}
          fluid
          mt={0.5}
          onClick={() =>
            act('set_support_underground_enabled', {
              enabled: data.support_underground_enabled ? 0 : 1,
            })
          }
        >
          Allow underground support
        </Button.Checkbox>
      </Section>

      <Section level={2} title="Cooldown Modifiers">
        <Stack vertical>
          <Stack.Item>
            <Stack align="center">
              <Stack.Item grow>
                <Box bold>Shared cooldown multiplier</Box>
              </Stack.Item>
              <Stack.Item>
                <NumberInput
                  minValue={0.1}
                  maxValue={10}
                  step={0.1}
                  stepPixelSize={20}
                  value={safeSharedMultiplier}
                  width="6em"
                  onChange={(value) =>
                    setSharedMultiplier(sanitizeNumberInputValue(value, 1))
                  }
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  color="good"
                  onClick={() =>
                    act('set_rto_shared_multiplier', {
                      value: safeSharedMultiplier,
                    })
                  }
                >
                  Apply
                </Button>
              </Stack.Item>
            </Stack>
          </Stack.Item>

          <Stack.Item>
            <Stack align="center">
              <Stack.Item grow>
                <Box bold>Personal cooldown multiplier (legacy)</Box>
              </Stack.Item>
              <Stack.Item>
                <NumberInput
                  minValue={0.1}
                  maxValue={10}
                  step={0.1}
                  stepPixelSize={20}
                  value={safePersonalMultiplier}
                  width="6em"
                  onChange={(value) =>
                    setPersonalMultiplier(sanitizeNumberInputValue(value, 1))
                  }
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  color="good"
                  onClick={() =>
                    act('set_rto_personal_multiplier', {
                      value: safePersonalMultiplier,
                    })
                  }
                >
                  Apply
                </Button>
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>

        <NoticeBox mt={1}>
          Current cooldowns are not recalculated. Charge-model anti-spam
          lockouts keep their configured duration.
        </NoticeBox>
      </Section>

      <Section level={2} title="Charge Rules">
        <Stack vertical>
          <Stack.Item>
            <Box bold mb={0.5}>
              Resource mode
            </Box>
            <Stack>
              {['legacy_cooldown', 'hybrid', 'charges'].map((mode) => (
                <Stack.Item key={mode}>
                  <Button
                    color={
                      data.rto_support_resource_mode === mode
                        ? 'good'
                        : 'average'
                    }
                    onClick={() =>
                      act('set_rto_support_resource_mode', {
                        value: mode,
                      })
                    }
                  >
                    {mode}
                  </Button>
                </Stack.Item>
              ))}
            </Stack>
          </Stack.Item>

          <Stack.Item>
            <Button.Checkbox
              checked={!!data.rto_charge_recharge_enabled}
              fluid
              onClick={() =>
                act('set_rto_charge_recharge_enabled', {
                  enabled: data.rto_charge_recharge_enabled ? 0 : 1,
                })
              }
            >
              Enable charge auto-recharge
            </Button.Checkbox>
          </Stack.Item>

          <Stack.Item>
            <Button.Checkbox
              checked={!!data.rto_charge_manual_only}
              fluid
              onClick={() =>
                act('set_rto_charge_manual_only', {
                  enabled: data.rto_charge_manual_only ? 0 : 1,
                })
              }
            >
              Manual-only charge mode
            </Button.Checkbox>
          </Stack.Item>

          <Stack.Item>
            <Stack align="center">
              <Stack.Item grow>
                <Box bold>Charge recharge multiplier</Box>
              </Stack.Item>
              <Stack.Item>
                <NumberInput
                  minValue={0.1}
                  maxValue={10}
                  step={0.1}
                  stepPixelSize={20}
                  value={safeRechargeMultiplier}
                  width="6em"
                  onChange={(value) =>
                    setRechargeMultiplier(sanitizeNumberInputValue(value, 1))
                  }
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  color="good"
                  onClick={() =>
                    act('set_rto_charge_recharge_multiplier', {
                      value: safeRechargeMultiplier,
                    })
                  }
                >
                  Apply
                </Button>
              </Stack.Item>
            </Stack>
          </Stack.Item>

          <Stack.Item>
            <Stack align="center">
              <Stack.Item grow>
                <Box bold>Charge capacity multiplier</Box>
              </Stack.Item>
              <Stack.Item>
                <NumberInput
                  minValue={0.1}
                  maxValue={10}
                  step={0.1}
                  stepPixelSize={20}
                  value={safeCapacityMultiplier}
                  width="6em"
                  onChange={(value) =>
                    setCapacityMultiplier(sanitizeNumberInputValue(value, 1))
                  }
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  color="good"
                  onClick={() =>
                    act('set_rto_charge_capacity_multiplier', {
                      value: safeCapacityMultiplier,
                    })
                  }
                >
                  Apply
                </Button>
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>

        <NoticeBox mt={1}>
          Global charge rules propagate into active RTO controllers immediately.
          Manual-only mode can be used to stop natural refill and issue charges
          per player below.
        </NoticeBox>
      </Section>

      <Section
        level={2}
        title={`Active RTO Charge Pools (${activeRtoPlayers.length})`}
      >
        <NoticeBox>
          This section is live-updating. Use it to inspect active RTO charge
          pools, disable refill for specific players, and issue charges
          manually.
        </NoticeBox>

        {!activeRtoPlayers.length && (
          <NoticeBox mt={1}>No active RTO controllers found.</NoticeBox>
        )}

        {activeRtoPlayers.map((player) => (
          <RtoActivePlayerCard
            key={player.ckey || player.name}
            player={player}
            poolFormValues={poolFormValues}
            setPoolFormValues={setPoolFormValues}
          />
        ))}
      </Section>

      <Section level={2} title="Package Selection">
        <Stack vertical>
          <Stack.Item>
            <Stack align="center">
              <Stack.Item grow>
                <Box bold>Package slots</Box>
                <Box color="label">
                  Controls how many unique RTO packages may be selected at once.
                </Box>
              </Stack.Item>
              <Stack.Item>
                <NumberInput
                  minValue={1}
                  maxValue={templateSlotCountCap}
                  step={1}
                  stepPixelSize={10}
                  value={safeTemplateSlotCount}
                  width="6em"
                  onChange={(value) =>
                    setTemplateSlotCount(sanitizeNumberInputValue(value, 2))
                  }
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  color="good"
                  onClick={() =>
                    act('set_rto_template_slot_count', {
                      value: safeTemplateSlotCount,
                    })
                  }
                >
                  Apply
                </Button>
              </Stack.Item>
            </Stack>
          </Stack.Item>

          <Stack.Item>
            <Stack align="center">
              <Stack.Item grow>
                <Box bold>Package reset delay (minutes)</Box>
                <Box color="label">
                  Time from the first package pick until a full slot reset
                  unlocks.
                </Box>
              </Stack.Item>
              <Stack.Item>
                <NumberInput
                  minValue={0}
                  maxValue={1440}
                  step={1}
                  stepPixelSize={10}
                  value={safeTemplateResetMinutes}
                  width="6em"
                  onChange={(value) =>
                    setTemplateResetMinutes(sanitizeNumberInputValue(value, 60))
                  }
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  color="good"
                  onClick={() =>
                    act('set_rto_template_reset_minutes', {
                      value: safeTemplateResetMinutes,
                    })
                  }
                >
                  Apply
                </Button>
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>

        <NoticeBox mt={1}>
          A lower slot cap trims excess selected packages immediately. A reset
          delay of `0` unlocks full package reset right away.
        </NoticeBox>
      </Section>

      <Section level={2} title="Reset">
        <Button
          color="average"
          icon="undo"
          onClick={() => act('reset_rto_rules')}
        >
          Reset to defaults
        </Button>
      </Section>
    </Section>
  );
};

const FireSupportPage = ({ data, grantAmounts, setGrantAmounts }) => {
  const { act } = useBackend();
  const fireSupportPoints = data.fire_support_points || [];
  const enabledEntries = data.fire_support_enabled_entries || [];
  const disabledEntries = data.fire_support_disabled_entries || [];

  return (
    <Section fill title="Fire Support">
      <Section level={2} title="General">
        <Button.Checkbox
          checked={!!data.fire_support_enabled}
          fluid
          onClick={() =>
            act('set_fire_support_enabled', {
              enabled: data.fire_support_enabled ? 0 : 1,
            })
          }
        >
          Enable Fire Support
        </Button.Checkbox>
      </Section>

      <Section level={2} title="Support Points">
        <Stack vertical>
          {fireSupportPoints.map((entry) => {
            const safeGrantAmount = sanitizeNumberInputValue(
              grantAmounts[entry.faction],
              0,
            );

            return (
              <Stack.Item key={entry.faction}>
                <Stack align="center">
                  <Stack.Item grow>
                    <Box bold>{entry.faction}</Box>
                    <Box color="label">Current points: {entry.points}</Box>
                  </Stack.Item>
                  <Stack.Item>
                    <NumberInput
                      minValue={0}
                      maxValue={9999}
                      step={1}
                      stepPixelSize={10}
                      value={safeGrantAmount}
                      width="6em"
                      onChange={(value) =>
                        setGrantAmounts((prev) => ({
                          ...prev,
                          [entry.faction]: sanitizeNumberInputValue(value, 0),
                        }))
                      }
                    />
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      color="good"
                      onClick={() => {
                        act('grant_fire_support_points', {
                          faction: entry.faction,
                          amount: safeGrantAmount,
                        });
                        setGrantAmounts((prev) => ({
                          ...prev,
                          [entry.faction]: 0,
                        }));
                      }}
                    >
                      Grant
                    </Button>
                  </Stack.Item>
                </Stack>
              </Stack.Item>
            );
          })}
        </Stack>
      </Section>

      <Section level={2} title="Support Pool">
        <Stack>
          <Stack.Item grow={1} basis={0}>
            <Section fill title={`Disabled (${disabledEntries.length})`}>
              {disabledEntries.map((entry) => (
                <FireSupportEntryButton
                  key={entry.type_id}
                  entry={entry}
                  enabled={false}
                />
              ))}
              {!disabledEntries.length && (
                <NoticeBox>No disabled entries.</NoticeBox>
              )}
            </Section>
          </Stack.Item>
          <Stack.Item grow={1} basis={0}>
            <Section fill title={`Enabled (${enabledEntries.length})`}>
              {enabledEntries.map((entry) => (
                <FireSupportEntryButton
                  key={entry.type_id}
                  entry={entry}
                  enabled
                />
              ))}
              {!enabledEntries.length && (
                <NoticeBox>No enabled entries.</NoticeBox>
              )}
            </Section>
          </Stack.Item>
        </Stack>
      </Section>

      <Section level={2} title="Reset">
        <Button
          color="average"
          icon="undo"
          onClick={() => act('reset_fire_support_rules')}
        >
          Reset to defaults
        </Button>
      </Section>
    </Section>
  );
};

const PlayerSurvivalPage = ({
  data,
  critGraceSeconds,
  antigibLimbLossChance,
  setCritGraceSeconds,
  setAntigibLimbLossChance,
}) => {
  const { act } = useBackend();
  const safeCritGraceSeconds = sanitizeNumberInputValue(critGraceSeconds, 15);
  const safeAntigibLimbLossChance = sanitizeNumberInputValue(
    antigibLimbLossChance,
    30,
  );

  return (
    <Section fill title="Player Survival">
      <Section level={2} title="Save Before Death">
        <Stack vertical>
          <Stack.Item>
            <Button.Checkbox
              checked={!!data.player_survival_enabled}
              fluid
              onClick={() =>
                act('set_player_survival_enabled', {
                  enabled: data.player_survival_enabled ? 0 : 1,
                })
              }
            >
              Enable Save Before Death
            </Button.Checkbox>
          </Stack.Item>

          <Stack.Item>
            <Stack align="center">
              <Stack.Item grow>
                <Box bold>Critical Grace Duration (seconds)</Box>
                <Box color="label">
                  Controls the post-hardcrit grace window before final death.
                </Box>
              </Stack.Item>
              <Stack.Item>
                <NumberInput
                  disabled={!data.player_survival_enabled}
                  minValue={0}
                  maxValue={300}
                  step={1}
                  stepPixelSize={10}
                  value={safeCritGraceSeconds}
                  width="6em"
                  onChange={(value) =>
                    setCritGraceSeconds(sanitizeNumberInputValue(value, 15))
                  }
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  color="good"
                  disabled={!data.player_survival_enabled}
                  onClick={() =>
                    act('set_player_survival_crit_grace_seconds', {
                      value: safeCritGraceSeconds,
                    })
                  }
                >
                  Apply
                </Button>
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Section>

      <Section level={2} title="Anti-Gib Fallback">
        <Stack vertical>
          <Stack.Item>
            <Button.Checkbox
              checked={!!data.player_survival_antigib_enabled}
              fluid
              onClick={() =>
                act('set_player_survival_antigib_enabled', {
                  enabled: data.player_survival_antigib_enabled ? 0 : 1,
                })
              }
            >
              Enable Anti-Gib Fallback
            </Button.Checkbox>
          </Stack.Item>

          <Stack.Item>
            <Stack align="center">
              <Stack.Item grow>
                <Box bold>Anti-Gib Limb Loss Chance (%)</Box>
                <Box color="label">
                  Applied only when Anti-Gib Fallback is enabled.
                </Box>
              </Stack.Item>
              <Stack.Item>
                <NumberInput
                  disabled={!data.player_survival_antigib_enabled}
                  minValue={0}
                  maxValue={100}
                  step={1}
                  stepPixelSize={10}
                  value={safeAntigibLimbLossChance}
                  width="6em"
                  onChange={(value) =>
                    setAntigibLimbLossChance(
                      sanitizeNumberInputValue(value, 30),
                    )
                  }
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  color="good"
                  disabled={!data.player_survival_antigib_enabled}
                  onClick={() =>
                    act('set_player_survival_antigib_limb_loss_chance', {
                      value: safeAntigibLimbLossChance,
                    })
                  }
                >
                  Apply
                </Button>
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Section>

      <Section level={2} title="Reset">
        <Button
          color="average"
          icon="undo"
          onClick={() => act('reset_player_survival_rules')}
        >
          Reset to defaults
        </Button>
      </Section>
    </Section>
  );
};

export const GameRulePanel = () => {
  const { data } = useBackend();
  const [page, setPage] = useState('rto');
  const [sharedMultiplier, setSharedMultiplier] = useState(
    sanitizeNumberInputValue(data.rto_shared_cooldown_multiplier, 1),
  );
  const [personalMultiplier, setPersonalMultiplier] = useState(
    sanitizeNumberInputValue(data.rto_personal_cooldown_multiplier, 1),
  );
  const [rechargeMultiplier, setRechargeMultiplier] = useState(
    sanitizeNumberInputValue(data.rto_charge_recharge_multiplier, 1),
  );
  const [capacityMultiplier, setCapacityMultiplier] = useState(
    sanitizeNumberInputValue(data.rto_charge_capacity_multiplier, 1),
  );
  const [templateSlotCount, setTemplateSlotCount] = useState(
    sanitizeNumberInputValue(data.rto_template_slot_count, 2),
  );
  const [templateResetMinutes, setTemplateResetMinutes] = useState(
    sanitizeNumberInputValue(data.rto_template_reset_minutes, 60),
  );
  const [critGraceSeconds, setCritGraceSeconds] = useState(
    sanitizeNumberInputValue(data.player_survival_crit_grace_seconds, 15),
  );
  const [antigibLimbLossChance, setAntigibLimbLossChance] = useState(
    sanitizeNumberInputValue(data.player_survival_antigib_limb_loss_chance, 30),
  );
  const [grantAmounts, setGrantAmounts] = useState({});

  useEffect(() => {
    setSharedMultiplier(
      sanitizeNumberInputValue(data.rto_shared_cooldown_multiplier, 1),
    );
  }, [data.rto_shared_cooldown_multiplier]);

  useEffect(() => {
    setPersonalMultiplier(
      sanitizeNumberInputValue(data.rto_personal_cooldown_multiplier, 1),
    );
  }, [data.rto_personal_cooldown_multiplier]);

  useEffect(() => {
    setTemplateSlotCount(
      sanitizeNumberInputValue(data.rto_template_slot_count, 2),
    );
  }, [data.rto_template_slot_count]);

  useEffect(() => {
    setRechargeMultiplier(
      sanitizeNumberInputValue(data.rto_charge_recharge_multiplier, 1),
    );
  }, [data.rto_charge_recharge_multiplier]);

  useEffect(() => {
    setCapacityMultiplier(
      sanitizeNumberInputValue(data.rto_charge_capacity_multiplier, 1),
    );
  }, [data.rto_charge_capacity_multiplier]);

  useEffect(() => {
    setTemplateResetMinutes(
      sanitizeNumberInputValue(data.rto_template_reset_minutes, 60),
    );
  }, [data.rto_template_reset_minutes]);

  useEffect(() => {
    setCritGraceSeconds(
      sanitizeNumberInputValue(data.player_survival_crit_grace_seconds, 15),
    );
  }, [data.player_survival_crit_grace_seconds]);

  useEffect(() => {
    setAntigibLimbLossChance(
      sanitizeNumberInputValue(
        data.player_survival_antigib_limb_loss_chance,
        30,
      ),
    );
  }, [data.player_survival_antigib_limb_loss_chance]);

  useEffect(() => {
    setGrantAmounts((prev) => {
      const next = {};
      (data.fire_support_points || []).forEach((entry) => {
        next[entry.faction] = sanitizeNumberInputValue(prev[entry.faction], 0);
      });
      return next;
    });
  }, [data.fire_support_points]);

  return (
    <Window title="Game Rule Panel" width={980} height={720} resizable>
      <Window.Content scrollable>
        <Stack grow>
          <Stack.Item>
            <Section fitted>
              <Tabs vertical>
                {PAGES.map((entry) => (
                  <Tabs.Tab
                    key={entry.id}
                    color={entry.color}
                    icon={entry.icon}
                    selected={page === entry.id}
                    onClick={() => setPage(entry.id)}
                  >
                    {entry.title}
                  </Tabs.Tab>
                ))}
              </Tabs>
            </Section>
          </Stack.Item>
          <Stack.Item grow={1} basis={0} ml={1}>
            {page === 'rto' && (
              <RtoSupportPage
                data={data}
                sharedMultiplier={sharedMultiplier}
                personalMultiplier={personalMultiplier}
                rechargeMultiplier={rechargeMultiplier}
                capacityMultiplier={capacityMultiplier}
                templateSlotCount={templateSlotCount}
                templateResetMinutes={templateResetMinutes}
                setSharedMultiplier={setSharedMultiplier}
                setPersonalMultiplier={setPersonalMultiplier}
                setRechargeMultiplier={setRechargeMultiplier}
                setCapacityMultiplier={setCapacityMultiplier}
                setTemplateSlotCount={setTemplateSlotCount}
                setTemplateResetMinutes={setTemplateResetMinutes}
              />
            )}
            {page === 'fire_support' && (
              <FireSupportPage
                data={data}
                grantAmounts={grantAmounts}
                setGrantAmounts={setGrantAmounts}
              />
            )}
            {page === 'player_survival' && (
              <PlayerSurvivalPage
                data={data}
                critGraceSeconds={critGraceSeconds}
                antigibLimbLossChance={antigibLimbLossChance}
                setCritGraceSeconds={setCritGraceSeconds}
                setAntigibLimbLossChance={setAntigibLimbLossChance}
              />
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
// SS220 EDIT - END
