import { useBackend } from '../backend';
import {
  Box,
  Button,
  Collapsible,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
} from '../components';
import { Window } from '../layouts';

const usesChargePool = (resourceMode) => resourceMode !== 'legacy_cooldown';

const altitudeLabel = (altitudeRequirement) =>
  altitudeRequirement === 'high'
    ? 'Требуется открытое небо'
    : 'Любая видимая точка';

const targetLabel = (allowClosedTurf) =>
  allowClosedTurf ? 'Можно по закрытым тайлам' : 'Только открытый тайл';

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

const formatTemplateMode = (template) =>
  template.requires_visibility_zone
    ? 'Боевой пакет через сектор'
    : 'Прямой логистический сброс';

const formatHeaderRecharge = (template) => {
  if (!usesChargePool(template.resource_mode)) {
    return null;
  }
  if (template.pool_manual_only) {
    return 'Ручной режим';
  }
  if (!template.pool_auto_recharge || template.pool_recharge_interval <= 0) {
    return 'Без пополнения';
  }
  return `+${template.pool_recharge_amount}/${template.pool_recharge_interval}с`;
};

const formatRechargeSummary = (template) => {
  if (!usesChargePool(template.resource_mode)) {
    return 'Не используется';
  }
  if (template.pool_manual_only) {
    return 'Только вручную через ГМ';
  }
  if (!template.pool_auto_recharge || template.pool_recharge_interval <= 0) {
    return 'Отключено';
  }

  const summary = `+${template.pool_recharge_amount} каждые ${template.pool_recharge_interval} сек.`;
  if (
    template.is_selected &&
    template.pool_current_charges < template.pool_capacity &&
    template.pool_next_recharge_in > 0
  ) {
    return `${summary} След. тик через ${template.pool_next_recharge_in} сек.`;
  }
  return summary;
};

const ToneChip = ({ color, text }) => (
  <Box
    backgroundColor={color}
    bold
    mb={0.25}
    mr={0.35}
    px={0.6}
    py={0.2}
    style={{
      borderRadius: '999px',
      display: 'inline-block',
      fontSize: '11px',
      lineHeight: 1.2,
    }}
  >
    {text}
  </Box>
);

const CompactMetric = ({ label, value, tone }) => (
  <Box
    mb={0.35}
    mr={1.25}
    style={{
      display: 'inline-flex',
      gap: '0.35em',
      alignItems: 'baseline',
      fontSize: '12px',
      lineHeight: 1.2,
    }}
  >
    <Box color="label">{label}:</Box>
    <Box bold color={tone}>
      {value}
    </Box>
  </Box>
);

const InfoPanel = ({ title, text, tone = 'rgba(255, 255, 255, 0.07)' }) => (
  <Box
    backgroundColor="rgba(255, 255, 255, 0.03)"
    mb={0.5}
    p={0.75}
    style={{
      borderLeft: `3px solid ${tone}`,
      borderRadius: '4px',
    }}
  >
    <Box bold color="label" fontSize="11px" mb={0.2}>
      {title}
    </Box>
    <Box fontSize="12px" lineHeight={1.25}>
      {text}
    </Box>
  </Box>
);

const ChargeMeter = ({ template, compact = false }) => {
  if (!usesChargePool(template.resource_mode)) {
    return null;
  }

  return (
    <Box width={compact ? '11em' : '100%'}>
      <ProgressBar
        color={template.pool_current_charges > 0 ? 'good' : 'bad'}
        height={compact ? '18px' : '20px'}
        maxValue={Math.max(1, template.pool_capacity)}
        value={template.pool_current_charges}
      >
        <Box fontSize={compact ? '11px' : '12px'} textAlign="center">
          {template.pool_current_charges}/{template.pool_capacity} зарядов
        </Box>
      </ProgressBar>
      <Box
        color="label"
        fontSize="11px"
        mt={0.25}
        textAlign={compact ? 'right' : 'left'}
      >
        {formatHeaderRecharge(template) || formatRechargeSummary(template)}
      </Box>
    </Box>
  );
};

const ActionRow = ({ action, resourceMode }) => (
  <Box
    backgroundColor="rgba(255, 255, 255, 0.03)"
    mb={0.4}
    p={0.7}
    style={{
      border: '1px solid rgba(255, 255, 255, 0.06)',
      borderRadius: '4px',
    }}
  >
    <Stack align="center">
      <Stack.Item grow>
        <Box bold fontSize="13px">
          {action.name}
        </Box>
      </Stack.Item>
      <Stack.Item>
        {usesChargePool(resourceMode) ? (
          <ToneChip
            color="rgba(255, 215, 120, 0.20)"
            text={`${action.support_pool_cost} заряд.`}
          />
        ) : (
          <ToneChip
            color="rgba(255, 215, 120, 0.20)"
            text={`ОКД ${action.shared_cooldown}с`}
          />
        )}
      </Stack.Item>
      <Stack.Item>
        <ToneChip
          color="rgba(100, 170, 255, 0.22)"
          text={
            usesChargePool(resourceMode)
              ? `Лок ${action.personal_lockout}с`
              : `ЛКД ${action.personal_cooldown}с`
          }
        />
      </Stack.Item>
    </Stack>
    <Box color="label" fontSize="12px" lineHeight={1.2} mt={0.15}>
      {action.description}
    </Box>
    <Box mt={0.4}>
      <CompactMetric label="Разброс" value={action.scatter} />
      <CompactMetric
        label="Сектор"
        value={action.requires_visibility_zone ? 'Требуется' : 'Не нужен'}
      />
      <CompactMetric
        label="Окно"
        value={altitudeLabel(action.altitude_requirement)}
      />
      <CompactMetric
        label="Цель"
        value={targetLabel(action.allow_closed_turf)}
      />
    </Box>
  </Box>
);

const TemplateHeader = ({ template }) => (
  <Stack align="center">
    <Stack.Item grow>
      <Box bold fontSize="15px">
        {template.name}
      </Box>
      <Box mt={0.2}>
        <ToneChip
          color={
            template.requires_visibility_zone
              ? 'rgba(100, 170, 255, 0.22)'
              : 'rgba(110, 190, 120, 0.22)'
          }
          text={
            template.requires_visibility_zone ? 'Через сектор' : 'Без сектора'
          }
        />
        <ToneChip
          color="rgba(255, 215, 120, 0.20)"
          text={resourceModeLabel(template.resource_mode)}
        />
        <ToneChip
          color="rgba(255, 255, 255, 0.12)"
          text={`${template.actions.length} способн.`}
        />
        {template.visibility_altitude_requirement === 'high' && (
          <ToneChip color="rgba(255, 170, 90, 0.25)" text="Открытое небо" />
        )}
        {template.is_selected && (
          <ToneChip
            color="rgba(120, 210, 120, 0.24)"
            text={`Слот ${template.selected_slot}`}
          />
        )}
      </Box>
      <Box color="label" fontSize="11px" mt={0.15}>
        {template.requires_visibility_zone
          ? `${template.visibility_zone_name}, радиус ${template.visibility_zone_radius}, длительность ${template.visibility_zone_duration}с`
          : 'Прямой вызов без разворота сектора'}
      </Box>
    </Stack.Item>
    {usesChargePool(template.resource_mode) && (
      <Stack.Item shrink={0}>
        <ChargeMeter compact template={template} />
      </Stack.Item>
    )}
  </Stack>
);

const TemplateDetails = ({ template }) => (
  <Box>
    <Box color="label" fontSize="12px" lineHeight={1.25} mb={0.6}>
      {template.description}
    </Box>

    <Stack wrap>
      <Stack.Item basis="60%" grow>
        <InfoPanel
          title="Роль пакета"
          text={template.role_summary}
          tone="rgba(255, 215, 120, 0.45)"
        />
        <InfoPanel
          title="Наведение"
          text={template.targeting_summary}
          tone="rgba(100, 170, 255, 0.45)"
        />
        {!!template.restriction_summary && (
          <InfoPanel
            title="Ограничения"
            text={template.restriction_summary}
            tone="rgba(255, 140, 90, 0.55)"
          />
        )}
      </Stack.Item>
      <Stack.Item basis="38%" grow>
        <Box
          backgroundColor="rgba(255, 255, 255, 0.03)"
          mb={0.5}
          p={0.75}
          style={{
            border: '1px solid rgba(255, 255, 255, 0.06)',
            borderRadius: '4px',
          }}
        >
          <Box bold color="label" fontSize="11px" mb={0.35}>
            Параметры
          </Box>
          <CompactMetric label="Режим" value={formatTemplateMode(template)} />
          <CompactMetric
            label="Ресурс"
            value={resourceModeLabel(template.resource_mode)}
          />
          {usesChargePool(template.resource_mode) && (
            <>
              <CompactMetric
                label="Старт"
                value={`${template.pool_starting_charges}/${template.pool_capacity}`}
              />
              <CompactMetric
                label="Пополнение"
                value={formatRechargeSummary(template)}
              />
            </>
          )}
          <CompactMetric
            label="Окно"
            value={altitudeLabel(template.visibility_altitude_requirement)}
          />
          {template.requires_visibility_zone ? (
            <>
              <CompactMetric
                label="Тип сектора"
                value={template.visibility_zone_type}
              />
              <CompactMetric
                label="КД сектора"
                value={`${template.visibility_zone_cooldown}с`}
              />
            </>
          ) : (
            <CompactMetric label="Сектор" value="Не используется" />
          )}
        </Box>

        {usesChargePool(template.resource_mode) && (
          <ChargeMeter template={template} />
        )}
      </Stack.Item>
    </Stack>

    <Box
      backgroundColor="rgba(255, 255, 255, 0.02)"
      mt={0.4}
      p={0.7}
      style={{
        borderRadius: '4px',
      }}
    >
      <CompactMetric
        label="Текущий запас"
        value={
          usesChargePool(template.resource_mode)
            ? `${template.pool_current_charges}/${template.pool_capacity}`
            : 'По кулдаунам'
        }
      />
      {template.requires_visibility_zone && (
        <>
          <CompactMetric
            label="Радиус"
            value={template.visibility_zone_radius}
          />
          <CompactMetric
            label="Длительность"
            value={`${template.visibility_zone_duration}с`}
          />
        </>
      )}
    </Box>

    <Box bold fontSize="12px" mt={0.7} mb={0.4}>
      Способности
    </Box>
    {template.actions.map((action) => (
      <ActionRow
        key={action.action_id}
        action={action}
        resourceMode={template.resource_mode}
      />
    ))}
  </Box>
);

const TemplateCard = ({ template, canAddTemplate }) => {
  const { act } = useBackend();
  const selectDisabled = template.is_selected || !canAddTemplate;
  const buttonLabel = template.is_selected
    ? `Слот ${template.selected_slot}`
    : 'Выбрать';

  return (
    <Box
      backgroundColor={
        template.is_selected
          ? 'rgba(90, 140, 90, 0.08)'
          : 'rgba(255, 255, 255, 0.02)'
      }
      mb={0.6}
      p={0.6}
      style={{
        border: template.is_selected
          ? '1px solid rgba(120, 210, 120, 0.35)'
          : '1px solid rgba(255, 255, 255, 0.06)',
        borderRadius: '6px',
      }}
    >
      <Collapsible
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
        open={template.is_selected}
        title={<TemplateHeader template={template} />}
      >
        <TemplateDetails template={template} />
      </Collapsible>
    </Box>
  );
};

const SlotBadge = ({ slotNumber, template }) => (
  <Box
    backgroundColor={
      template ? 'rgba(100, 170, 255, 0.12)' : 'rgba(255, 255, 255, 0.04)'
    }
    minWidth="12em"
    mr={0.5}
    mt={0.4}
    px={0.75}
    py={0.55}
    style={{
      border: template
        ? '1px solid rgba(100, 170, 255, 0.25)'
        : '1px solid rgba(255, 255, 255, 0.08)',
      borderRadius: '4px',
    }}
  >
    <Box color="label" fontSize="11px">
      Слот {slotNumber}
    </Box>
    <Box bold fontSize="13px">
      {template ? template.name : 'Пусто'}
    </Box>
  </Box>
);

const PresetSummary = ({
  canResetTemplates,
  maxSelectedTemplates,
  resetDelayMinutes,
  resetReadyIn,
  selectedCount,
  selectedTemplates,
}) => {
  const { act } = useBackend();
  const totalResetSeconds = Math.max(1, resetDelayMinutes * 60);
  const resetProgress = Math.max(0, totalResetSeconds - resetReadyIn);

  return (
    <Section
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
      title="Пакеты поддержки"
    >
      <Stack align="center" justify="space-between" wrap>
        <Stack.Item grow>
          <Box bold fontSize="13px">
            Выбрано {selectedCount}/{maxSelectedTemplates}
          </Box>
          <Box color="label" fontSize="12px" mt={0.2}>
            Выберите до {maxSelectedTemplates} пакетов. Для боевых пакетов
            разверните сектор, затем наводите через Ctrl+Click в RTO-бинокль.
          </Box>
        </Stack.Item>
        <Stack.Item>
          <ToneChip
            color="rgba(255, 215, 120, 0.20)"
            text={`Сброс: ${formatResetDelayLabel(resetDelayMinutes)}`}
          />
        </Stack.Item>
        {selectedCount > 0 && resetReadyIn > 0 && (
          <Stack.Item>
            <ToneChip
              color="rgba(100, 170, 255, 0.22)"
              text={`До сброса ${resetReadyIn}с`}
            />
          </Stack.Item>
        )}
        {selectedCount > 0 && canResetTemplates && (
          <Stack.Item>
            <ToneChip color="rgba(120, 210, 120, 0.24)" text="Сброс доступен" />
          </Stack.Item>
        )}
      </Stack>

      <Stack mt={0.2} wrap>
        {Array.from({ length: maxSelectedTemplates }, (_, index) => (
          <Stack.Item key={index}>
            <SlotBadge
              slotNumber={index + 1}
              template={selectedTemplates[index]}
            />
          </Stack.Item>
        ))}
      </Stack>

      {selectedCount > 0 && (
        <Box mt={0.7}>
          <ProgressBar
            color={canResetTemplates ? 'good' : 'average'}
            maxValue={totalResetSeconds}
            value={canResetTemplates ? totalResetSeconds : resetProgress}
          >
            <Box fontSize="12px" textAlign="center">
              {canResetTemplates
                ? 'Полный сброс слотов уже доступен'
                : `До полного сброса слотов: ${resetReadyIn} сек.`}
            </Box>
          </ProgressBar>
        </Box>
      )}
    </Section>
  );
};

export const RtoSupportPresetMenu = () => {
  const { data } = useBackend();
  const templates = data.templates || [];
  const selectedCount = data.selected_count || 0;
  const maxSelectedTemplates = data.max_selected_templates || 2;
  const canAddTemplate = !!data.can_add_template;
  const canResetTemplates = !!data.can_reset_templates;
  const resetReadyIn = data.reset_ready_in || 0;
  const resetDelayMinutes = data.reset_delay_minutes || 60;
  const selectedTemplates = [...templates]
    .filter((template) => template.is_selected)
    .sort(
      (left, right) => (left.selected_slot || 0) - (right.selected_slot || 0),
    );

  return (
    <Window height={760} resizable width={940}>
      <Window.Content scrollable>
        <PresetSummary
          canResetTemplates={canResetTemplates}
          maxSelectedTemplates={maxSelectedTemplates}
          resetDelayMinutes={resetDelayMinutes}
          resetReadyIn={resetReadyIn}
          selectedCount={selectedCount}
          selectedTemplates={selectedTemplates}
        />

        {!canAddTemplate && selectedCount >= maxSelectedTemplates && (
          <NoticeBox mt={0.6} warning>
            Все слоты уже заняты. Раскрывайте карточки только тех пакетов,
            которые хотите сверить или заменить позже через полный сброс.
          </NoticeBox>
        )}

        <Box mt={0.6}>
          {!!templates.length &&
            templates.map((template) => (
              <TemplateCard
                key={`${template.template_id}-${template.is_selected ? 'selected' : 'idle'}`}
                canAddTemplate={canAddTemplate}
                template={template}
              />
            ))}
          {!templates.length && (
            <NoticeBox danger>Нет доступных пресетов поддержки.</NoticeBox>
          )}
        </Box>
      </Window.Content>
    </Window>
  );
};
