import { useEffect, useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Flex, NoticeBox, Section } from '../components';
import { Window } from '../layouts';

const usesChargePool = (resourceMode) => resourceMode !== 'legacy_cooldown';

const altitudeLabel = (altitudeRequirement) =>
  altitudeRequirement === 'high'
    ? 'Требуется открытое небо'
    : 'Любая видимая точка';

const compactAltitudeLabel = (altitudeRequirement) =>
  altitudeRequirement === 'high' ? 'Открытое небо' : 'Любая точка';

const compactTargetLabel = (allowClosedTurf) =>
  allowClosedTurf ? 'Закрытые тайлы' : 'Открытый тайл';

const formatResetDelayLabel = (minutes) =>
  minutes <= 0 ? 'сразу после первого выбора' : `${minutes} мин.`;

const resourceModeLabel = (resourceMode) => {
  switch (resourceMode) {
    case 'charges':
      return 'Общие заряды';
    case 'hybrid':
      return 'Гибрид';
    default:
      return 'Кулдауны';
  }
};

const summarizeNumericRange = (values, suffix = '') => {
  const safeValues = (values || [])
    .map((value) => Number(value))
    .filter((value) => Number.isFinite(value));

  if (!safeValues.length) {
    return '—';
  }

  const nonZeroValues = safeValues.filter((value) => value > 0);
  const targetValues = nonZeroValues.length ? nonZeroValues : safeValues;
  const minValue = Math.min(...targetValues);
  const maxValue = Math.max(...targetValues);

  return minValue === maxValue
    ? `${minValue}${suffix}`
    : `${minValue}-${maxValue}${suffix}`;
};

const formatRechargeCompact = (template) => {
  if (!usesChargePool(template.resource_mode)) {
    return 'не используется';
  }
  if (template.pool_manual_only) {
    return 'только GM';
  }
  if (!template.pool_auto_recharge || template.pool_recharge_interval <= 0) {
    return 'отключено';
  }

  const baseSummary = `+${template.pool_recharge_amount}/${template.pool_recharge_interval}с`;
  if (
    template.is_selected &&
    template.pool_current_charges < template.pool_capacity &&
    template.pool_next_recharge_in > 0
  ) {
    return `${baseSummary}, ${template.pool_next_recharge_in}с до тика`;
  }
  return baseSummary;
};

const buildActionSummary = (template) => {
  const actions = template.actions || [];
  if (!actions.length) {
    return 'Способности отсутствуют';
  }

  if (usesChargePool(template.resource_mode)) {
    return `${actions.length} способн. • цена ${summarizeNumericRange(
      actions.map((action) => action.support_pool_cost),
    )} зар. • лок ${summarizeNumericRange(
      actions.map((action) => action.personal_lockout),
      'с',
    )} • ${template.requires_visibility_zone ? 'через сектор' : 'прямой вызов'}`;
  }

  return `${actions.length} способн. • общий ${summarizeNumericRange(
    actions.map((action) => action.shared_cooldown),
    'с',
  )} • личный ${summarizeNumericRange(
    actions.map((action) => action.personal_cooldown),
    'с',
  )}`;
};

const Badge = ({ color = 'rgba(255, 255, 255, 0.08)', text, bold = false }) => (
  <Box
    backgroundColor={color}
    bold={bold}
    mr={0.5}
    mb={0.5}
    p="2px 6px"
    style={{
      borderRadius: '999px',
      display: 'inline-block',
      lineHeight: 1.35,
    }}
  >
    {text}
  </Box>
);

const StatTile = ({ label, value, color = 'rgba(255, 255, 255, 0.04)' }) => (
  <Box
    backgroundColor={color}
    p="4px 6px"
    style={{
      border: '1px solid rgba(255, 255, 255, 0.06)',
      borderRadius: '4px',
      minHeight: '3.35em',
    }}
  >
    <Box color="label" fontSize="11px">
      {label}
    </Box>
    <Box bold style={{ lineHeight: 1.2 }}>
      {value}
    </Box>
  </Box>
);

const SlotChip = ({ index, template }) => (
  <Badge
    color={template ? 'rgba(90, 165, 255, 0.20)' : 'rgba(255, 255, 255, 0.06)'}
    text={`Слот ${index + 1}: ${template ? template.name : 'Пусто'}`}
  />
);

const DetailLine = ({ label, children, tone = 'default' }) => (
  <Box
    mt={0.25}
    color={
      tone === 'warning' ? 'average' : tone === 'good' ? 'good' : undefined
    }
    style={{ lineHeight: 1.25 }}
  >
    <b>{label}:</b> {children}
  </Box>
);

const ActionRow = ({ action, resourceMode }) => {
  const chargeMode = usesChargePool(resourceMode);

  return (
    <Box
      backgroundColor="rgba(255, 255, 255, 0.035)"
      mb={0.5}
      p="6px 8px"
      style={{
        border: '1px solid rgba(255, 255, 255, 0.06)',
        borderRadius: '4px',
      }}
    >
      <Flex align="center" wrap="wrap">
        <Flex.Item basis="24em" grow={1} mr={1} mb={0.25}>
          <Box bold>{action.name}</Box>
          <Box color="label" fontSize="12px" style={{ lineHeight: 1.25 }}>
            {action.description}
          </Box>
        </Flex.Item>
        <Flex.Item basis="18em" grow={1}>
          <Flex justify="flex-end" wrap="wrap">
            <Badge text={`Разброс ${action.scatter}`} />
            {chargeMode ? (
              <>
                <Badge
                  color="rgba(110, 190, 120, 0.20)"
                  text={`Цена ${action.support_pool_cost}`}
                />
                <Badge
                  color="rgba(255, 170, 90, 0.22)"
                  text={`Лок ${action.personal_lockout}с`}
                />
              </>
            ) : (
              <>
                <Badge
                  color="rgba(90, 165, 255, 0.20)"
                  text={`Общий ${action.shared_cooldown}с`}
                />
                <Badge
                  color="rgba(255, 170, 90, 0.22)"
                  text={`Личный ${action.personal_cooldown}с`}
                />
              </>
            )}
            <Badge
              color={
                action.requires_visibility_zone
                  ? 'rgba(90, 165, 255, 0.20)'
                  : 'rgba(110, 190, 120, 0.20)'
              }
              text={
                action.requires_visibility_zone ? 'Нужен сектор' : 'Без сектора'
              }
            />
            <Badge text={compactTargetLabel(action.allow_closed_turf)} />
            {action.altitude_requirement === 'high' && (
              <Badge color="rgba(255, 170, 90, 0.22)" text="Открытое небо" />
            )}
          </Flex>
        </Flex.Item>
      </Flex>
    </Box>
  );
};

const TemplateMetrics = ({ template }) => {
  const chargeMode = usesChargePool(template.resource_mode);
  const actions = template.actions || [];
  const tiles = [];

  if (chargeMode) {
    tiles.push({
      label: template.is_selected ? 'Текущий запас' : 'Стартовый запас',
      value: `${template.is_selected ? template.pool_current_charges : template.pool_starting_charges}/${template.pool_capacity}`,
    });
    tiles.push({
      label: 'Пополнение',
      value: formatRechargeCompact(template),
    });
  } else {
    tiles.push({
      label: 'Общий КД',
      value: summarizeNumericRange(
        actions.map((action) => action.shared_cooldown),
        'с',
      ),
    });
    tiles.push({
      label: 'Личный КД',
      value: summarizeNumericRange(
        actions.map((action) => action.personal_cooldown),
        'с',
      ),
    });
  }

  if (template.requires_visibility_zone) {
    tiles.push({
      label: 'Сектор',
      value: `${template.visibility_zone_radius} т. • ${template.visibility_zone_duration}с`,
    });
    tiles.push({
      label: 'Антиспам',
      value: `${template.visibility_zone_cooldown}с`,
    });
  } else {
    tiles.push({
      label: 'Сектор',
      value: 'не требуется',
    });
  }

  tiles.push({
    label: 'Высота',
    value: compactAltitudeLabel(template.visibility_altitude_requirement),
  });

  if (template.solo_zone_cooldown_available) {
    tiles.push({
      label: 'Solo-бонус',
      value: template.solo_zone_cooldown_active
        ? `${template.visibility_zone_cooldown_current}с сейчас`
        : `${template.visibility_zone_cooldown_solo}с при 1 пакете`,
    });
  }

  return (
    <Flex wrap="wrap">
      {tiles.map((tile) => (
        <Flex.Item basis="10.5em" grow={1} mr={0.5} mb={0.5} key={tile.label}>
          <StatTile label={tile.label} value={tile.value} />
        </Flex.Item>
      ))}
    </Flex>
  );
};

const TemplateCard = ({ template, canAddTemplate }) => {
  const { act } = useBackend();
  const chargeMode = usesChargePool(template.resource_mode);
  const selectDisabled = template.is_selected || !canAddTemplate;
  const buttonLabel = template.is_selected
    ? `Слот ${template.selected_slot}`
    : 'Выбрать';
  const [showActions, setShowActions] = useState(template.is_selected);

  useEffect(() => {
    if (template.is_selected) {
      setShowActions(true);
    }
  }, [template.is_selected]);

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
      <Flex align="flex-start" wrap="wrap">
        <Flex.Item basis="33em" grow={1} mr={1} mb={0.5}>
          <Flex wrap="wrap">
            <Badge
              color={
                template.requires_visibility_zone
                  ? 'rgba(90, 165, 255, 0.20)'
                  : 'rgba(110, 190, 120, 0.20)'
              }
              text={
                template.requires_visibility_zone
                  ? 'Через сектор'
                  : 'Прямой вызов'
              }
              bold
            />
            <Badge
              color="rgba(255, 215, 120, 0.20)"
              text={resourceModeLabel(template.resource_mode)}
            />
            {template.is_selected && (
              <Badge
                color="rgba(110, 190, 120, 0.20)"
                text={`Активно: слот ${template.selected_slot}`}
              />
            )}
            {chargeMode && (
              <Badge
                color="rgba(90, 165, 255, 0.20)"
                text={`${template.is_selected ? 'Заряды' : 'Старт'} ${template.is_selected ? template.pool_current_charges : template.pool_starting_charges}/${template.pool_capacity}`}
              />
            )}
            {template.visibility_altitude_requirement === 'high' && (
              <Badge color="rgba(255, 170, 90, 0.22)" text="Открытое небо" />
            )}
          </Flex>

          <Box color="label" fontSize="13px" style={{ lineHeight: 1.25 }}>
            {template.description}
          </Box>

          <Box
            backgroundColor="rgba(255, 255, 255, 0.035)"
            mt={0.75}
            p="6px 8px"
            style={{
              border: '1px solid rgba(255, 255, 255, 0.06)',
              borderRadius: '4px',
            }}
          >
            <DetailLine label="Роль">{template.role_summary}</DetailLine>
            <DetailLine label="Наведение">
              {template.targeting_summary}
            </DetailLine>
            <DetailLine label="Высотное окно">
              {altitudeLabel(template.visibility_altitude_requirement)}
            </DetailLine>
            {!!template.restriction_summary && (
              <DetailLine label="Важно" tone="warning">
                {template.restriction_summary}
              </DetailLine>
            )}
          </Box>
        </Flex.Item>

        <Flex.Item basis="23em" grow={1} mb={0.5}>
          <TemplateMetrics template={template} />
        </Flex.Item>
      </Flex>

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

  const resetBadgeText =
    selectedCount <= 0
      ? `Полный сброс: ${formatResetDelayLabel(resetDelayMinutes)}`
      : canResetTemplates
        ? 'Сброс готов'
        : `Сброс через ${resetReadyIn}с`;

  return (
    <>
      <Flex align="center" wrap="wrap">
        <Badge
          color="rgba(90, 165, 255, 0.20)"
          text={`Слоты ${selectedCount}/${maxSelectedTemplates}`}
          bold
        />
        {slots.map((template, index) => (
          <SlotChip index={index} key={index} template={template} />
        ))}
        <Badge
          color={
            canResetTemplates && selectedCount > 0
              ? 'rgba(110, 190, 120, 0.20)'
              : 'rgba(255, 170, 90, 0.22)'
          }
          text={resetBadgeText}
        />
        {!canAddTemplate && selectedCount >= maxSelectedTemplates && (
          <Badge color="rgba(255, 120, 120, 0.20)" text="Лимит заполнен" />
        )}
      </Flex>

      <Box color="label" fontSize="12px" style={{ lineHeight: 1.25 }}>
        Выберите до {maxSelectedTemplates} пакетов. Для боевых пакетов сначала
        разверните сектор, затем вызывайте поддержку. Наведение выполняется
        через Ctrl+Click во время зума RTO-бинокля.
      </Box>
    </>
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
    <Window width={960} height={760} resizable>
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
          <NoticeBox danger>Нет доступных пресетов поддержки.</NoticeBox>
        )}
      </Window.Content>
    </Window>
  );
};
