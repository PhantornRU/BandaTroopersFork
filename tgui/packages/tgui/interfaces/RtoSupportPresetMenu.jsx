import { useEffect, useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Flex, NoticeBox, Section } from '../components';
import { Window } from '../layouts';

const usesChargePool = (resourceMode) => resourceMode !== 'legacy_cooldown';

const formatResetDelayLabel = (minutes) =>
  minutes <= 0 ? 'сразу' : `${minutes} мин`;

const formatRange = (values, suffix = '') => {
  const safeValues = (values || [])
    .map((value) => Number(value))
    .filter((value) => Number.isFinite(value));

  if (!safeValues.length) {
    return null;
  }

  const minValue = Math.min(...safeValues);
  const maxValue = Math.max(...safeValues);
  return minValue === maxValue
    ? `${minValue}${suffix}`
    : `${minValue}-${maxValue}${suffix}`;
};

const formatRecharge = (template) => {
  if (!usesChargePool(template.resource_mode)) {
    return null;
  }
  if (template.pool_manual_only) {
    return 'вручную';
  }
  if (!template.pool_auto_recharge || template.pool_recharge_interval <= 0) {
    return 'отключено';
  }
  return `+${template.pool_recharge_amount}/${template.pool_recharge_interval}с`;
};

const Badge = ({ text, color = 'rgba(255,255,255,0.08)', bold = false }) => (
  <Box
    backgroundColor={color}
    bold={bold}
    mr={0.5}
    mb={0.5}
    p="2px 6px"
    style={{
      borderRadius: '999px',
      display: 'inline-block',
      lineHeight: 1.3,
      whiteSpace: 'nowrap',
    }}
  >
    {text}
  </Box>
);

const SlotChip = ({ index, template }) => (
  <Badge
    color={template ? 'rgba(90,165,255,0.20)' : 'rgba(255,255,255,0.05)'}
    text={`Слот ${index + 1}: ${template ? template.name : 'Пусто'}`}
  />
);

const HeaderStrip = ({
  canAddTemplate,
  canResetTemplates,
  maxSelectedTemplates,
  resetDelayMinutes,
  resetReadyIn,
  selectedCount,
  selectedTemplates,
}) => {
  const slots = [];
  for (let index = 0; index < maxSelectedTemplates; index++) {
    slots.push(selectedTemplates[index] || null);
  }

  const resetText =
    selectedCount <= 0
      ? `Сброс: ${formatResetDelayLabel(resetDelayMinutes)}`
      : canResetTemplates
        ? 'Сброс готов'
        : `Сброс через ${resetReadyIn}с`;

  return (
    <>
      <Flex align="center" wrap="wrap">
        <Badge
          bold
          color="rgba(90,165,255,0.20)"
          text={`Слоты ${selectedCount}/${maxSelectedTemplates}`}
        />
        {slots.map((template, index) => (
          <SlotChip index={index} key={index} template={template} />
        ))}
        <Badge
          color={
            canResetTemplates && selectedCount > 0
              ? 'rgba(110,190,120,0.20)'
              : 'rgba(255,170,90,0.20)'
          }
          text={resetText}
        />
        {!canAddTemplate && selectedCount >= maxSelectedTemplates && (
          <Badge color="rgba(255,120,120,0.20)" text="Лимит заполнен" />
        )}
      </Flex>
      <Box color="label" fontSize="12px" mt={0.25}>
        Выберите до {maxSelectedTemplates} пакетов. Для боевых пакетов сначала
        разверните сектор, затем вызывайте поддержку через Ctrl+Click в зуме
        RTO-бинокля.
      </Box>
    </>
  );
};

const CompactFacts = ({ template }) => {
  const chargeMode = usesChargePool(template.resource_mode);
  const actions = template.actions || [];

  return (
    <Flex align="center" wrap="wrap" mt={0.25}>
      {chargeMode ? (
        <Badge
          color="rgba(90,165,255,0.20)"
          text={`Заряды ${template.is_selected ? template.pool_current_charges : template.pool_starting_charges}/${template.pool_capacity}`}
        />
      ) : (
        <>
          {!!actions.length && (
            <Badge
              color="rgba(90,165,255,0.20)"
              text={`Общий ${formatRange(
                actions.map((action) => action.shared_cooldown),
                'с',
              )}`}
            />
          )}
          {!!actions.length && (
            <Badge
              color="rgba(255,170,90,0.20)"
              text={`Личный ${formatRange(
                actions.map((action) => action.personal_cooldown),
                'с',
              )}`}
            />
          )}
        </>
      )}
      {chargeMode && !!formatRecharge(template) && (
        <Badge text={`Пополнение ${formatRecharge(template)}`} />
      )}
      <Badge
        color={
          template.requires_visibility_zone
            ? 'rgba(90,165,255,0.20)'
            : 'rgba(110,190,120,0.20)'
        }
        text={
          template.requires_visibility_zone
            ? `Сектор ${template.visibility_zone_radius}т / ${template.visibility_zone_duration}с`
            : 'Прямой вызов'
        }
      />
      {template.visibility_altitude_requirement === 'high' && (
        <Badge color="rgba(255,170,90,0.20)" text="Открытое небо" />
      )}
      {template.is_selected && (
        <Badge
          color="rgba(110,190,120,0.20)"
          text={`Активен: слот ${template.selected_slot}`}
        />
      )}
    </Flex>
  );
};

const buildActionSummary = (template) => {
  const actions = template.actions || [];
  if (!actions.length) {
    return 'Нет способностей';
  }

  if (usesChargePool(template.resource_mode)) {
    return `${actions.length} выз. • цена ${formatRange(
      actions.map((action) => action.support_pool_cost),
      ' зар.',
    )}`;
  }

  return `${actions.length} выз. • общий ${formatRange(
    actions.map((action) => action.shared_cooldown),
    'с',
  )}`;
};

const ActionRow = ({ action, resourceMode }) => {
  const chargeMode = usesChargePool(resourceMode);

  return (
    <Box
      backgroundColor="rgba(255,255,255,0.035)"
      mb={0.5}
      p="5px 7px"
      style={{
        border: '1px solid rgba(255,255,255,0.05)',
        borderRadius: '4px',
      }}
    >
      <Flex align="center" wrap="wrap">
        <Flex.Item basis="26em" grow={1} mr={1}>
          <Box bold>{action.name}</Box>
          <Box color="label" fontSize="12px" style={{ lineHeight: 1.2 }}>
            {action.description}
          </Box>
        </Flex.Item>
        <Flex.Item>
          <Flex justify="flex-end" wrap="wrap">
            {chargeMode ? (
              <Badge
                color="rgba(110,190,120,0.20)"
                text={`Цена ${action.support_pool_cost}`}
              />
            ) : (
              <Badge
                color="rgba(90,165,255,0.20)"
                text={`КД ${action.shared_cooldown}/${action.personal_cooldown}с`}
              />
            )}
            {action.requires_visibility_zone && (
              <Badge color="rgba(90,165,255,0.20)" text="Через сектор" />
            )}
            {!action.allow_closed_turf && <Badge text="Открытый тайл" />}
            {action.altitude_requirement === 'high' && (
              <Badge color="rgba(255,170,90,0.20)" text="Открытое небо" />
            )}
          </Flex>
        </Flex.Item>
      </Flex>
    </Box>
  );
};

const TemplateCard = ({ template, canAddTemplate }) => {
  const { act } = useBackend();
  const [showActions, setShowActions] = useState(template.is_selected);

  useEffect(() => {
    if (template.is_selected) {
      setShowActions(true);
    }
  }, [template.is_selected]);

  const selectDisabled = template.is_selected || !canAddTemplate;
  const buttonLabel = template.is_selected
    ? `Слот ${template.selected_slot}`
    : 'Выбрать';

  return (
    <Section
      title={template.name}
      buttons={
        <Button
          color={template.is_selected ? 'average' : 'good'}
          disabled={selectDisabled}
          icon={template.is_selected ? 'check' : 'crosshairs'}
          onClick={() =>
            act('select_template', {
              template_id: template.template_id,
            })
          }
        >
          {buttonLabel}
        </Button>
      }
    >
      <Box color="label" fontSize="13px" style={{ lineHeight: 1.25 }}>
        {template.description}
      </Box>

      <CompactFacts template={template} />

      <Box mt={0.5}>
        <Button
          fluid
          color={showActions ? 'average' : undefined}
          icon={showActions ? 'chevron-down' : 'chevron-right'}
          onClick={() => setShowActions(!showActions)}
        >
          {buildActionSummary(template)}
        </Button>
      </Box>

      {showActions && (
        <Box mt={0.5}>
          {(template.actions || []).map((action) => (
            <ActionRow
              key={action.action_id}
              action={action}
              resourceMode={template.resource_mode}
            />
          ))}
        </Box>
      )}
    </Section>
  );
};

export const RtoSupportPresetMenu = () => {
  const { act, data } = useBackend();
  const templates = data.templates || [];
  const selectedTemplates = data.selected_templates || [];
  const selectedCount = data.selected_count || 0;
  const maxSelectedTemplates = data.max_selected_templates || 2;
  const canAddTemplate = !!data.can_add_template;
  const canResetTemplates = !!data.can_reset_templates;
  const resetReadyIn = data.reset_ready_in || 0;
  const resetDelayMinutes = data.reset_delay_minutes || 60;

  return (
    <Window width={900} height={720} resizable title="Поддержка RTO">
      <Window.Content scrollable>
        <Section
          title="Пакеты поддержки"
          buttons={
            <Button
              color="average"
              disabled={!canResetTemplates}
              icon="rotate-left"
              onClick={() => act('reset_templates')}
            >
              Сбросить все слоты
            </Button>
          }
        >
          <HeaderStrip
            canAddTemplate={canAddTemplate}
            canResetTemplates={canResetTemplates}
            maxSelectedTemplates={maxSelectedTemplates}
            resetDelayMinutes={resetDelayMinutes}
            resetReadyIn={resetReadyIn}
            selectedCount={selectedCount}
            selectedTemplates={selectedTemplates}
          />
        </Section>

        {!!templates.length &&
          templates.map((template) => (
            <TemplateCard
              canAddTemplate={canAddTemplate}
              key={template.template_id}
              template={template}
            />
          ))}

        {!templates.length && (
          <NoticeBox danger>Нет доступных пакетов поддержки.</NoticeBox>
        )}
      </Window.Content>
    </Window>
  );
};
