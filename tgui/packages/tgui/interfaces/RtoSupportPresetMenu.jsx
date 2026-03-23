import { useBackend } from '../backend';
import {
  Box,
  Button,
  Divider,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
} from '../components';
import { Window } from '../layouts';

const altitudeLabel = (altitudeRequirement) =>
  altitudeRequirement === 'high'
    ? 'Требуется открытое небо'
    : 'Любая видимая точка';

const targetLabel = (allowClosedTurf) =>
  allowClosedTurf ? 'Можно по закрытым тайлам' : 'Только открытый тайл';

const ModeBadge = ({ color, text }) => (
  <Box
    backgroundColor={color}
    bold
    mr={0.5}
    p="2px 6px"
    style={{
      borderRadius: '999px',
      display: 'inline-block',
    }}
  >
    {text}
  </Box>
);

const ActionCard = ({ action }) => (
  <Box
    backgroundColor="rgba(255, 255, 255, 0.04)"
    mb={1}
    p={1}
    style={{
      border: '1px solid rgba(255, 255, 255, 0.08)',
      borderRadius: '4px',
    }}
  >
    <Box bold mb={0.5}>
      {action.name}
    </Box>
    <Box color="label" mb={1}>
      {action.description}
    </Box>
    <LabeledList>
      <LabeledList.Item label="Разброс">{action.scatter}</LabeledList.Item>
      <LabeledList.Item label="Общий КД">
        {action.shared_cooldown} сек.
      </LabeledList.Item>
      <LabeledList.Item label="Личный КД">
        {action.personal_cooldown} сек.
      </LabeledList.Item>
      <LabeledList.Item label="Сектор">
        {action.requires_visibility_zone ? 'Требуется' : 'Не требуется'}
      </LabeledList.Item>
      <LabeledList.Item label="Высотное окно">
        {altitudeLabel(action.altitude_requirement)}
      </LabeledList.Item>
      <LabeledList.Item label="Тип цели">
        {targetLabel(action.allow_closed_turf)}
      </LabeledList.Item>
    </LabeledList>
  </Box>
);

const TemplateCard = ({ template, canAddTemplate }) => {
  const { act } = useBackend();
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
      <Box mb={1}>{template.description}</Box>
      <Box mb={1}>
        {template.requires_visibility_zone ? (
          <ModeBadge color="rgba(100, 170, 255, 0.25)" text="Через сектор" />
        ) : (
          <ModeBadge color="rgba(110, 190, 120, 0.25)" text="Без сектора" />
        )}
        {template.visibility_altitude_requirement === 'high' && (
          <ModeBadge
            color="rgba(255, 170, 90, 0.25)"
            text="Открытое небо"
          />
        )}
      </Box>
      <NoticeBox mb={1}>
        <Box bold mb={0.5}>
          Роль пакета
        </Box>
        <Box>{template.role_summary}</Box>
      </NoticeBox>
      <NoticeBox info mb={1}>
        <Box bold mb={0.5}>
          Наведение
        </Box>
        <Box>{template.targeting_summary}</Box>
      </NoticeBox>
      {!!template.restriction_summary && (
        <NoticeBox warning mb={1}>
          {template.restriction_summary}
        </NoticeBox>
      )}
      <LabeledList>
        <LabeledList.Item label="Режим">
          {template.requires_visibility_zone
            ? 'Боевой пакет через сектор'
            : 'Прямой логистический сброс'}
        </LabeledList.Item>
        {template.requires_visibility_zone ? (
          <>
            <LabeledList.Item label="Сектор">
              {template.visibility_zone_name}
            </LabeledList.Item>
            <LabeledList.Item label="Тип сектора">
              {template.visibility_zone_type}
            </LabeledList.Item>
            <LabeledList.Item label="Радиус">
              {template.visibility_zone_radius}
            </LabeledList.Item>
            <LabeledList.Item label="Длительность">
              {template.visibility_zone_duration} сек.
            </LabeledList.Item>
            <LabeledList.Item label="Кулдаун сектора">
              {template.visibility_zone_cooldown} сек.
            </LabeledList.Item>
            {template.solo_zone_cooldown_available && (
              <LabeledList.Item label="Соло-КД сектора">
                {template.visibility_zone_cooldown_solo} сек.
              </LabeledList.Item>
            )}
          </>
        ) : (
          <LabeledList.Item label="Сектор">Не используется</LabeledList.Item>
        )}
        <LabeledList.Item label="Высотное окно">
          {altitudeLabel(template.visibility_altitude_requirement)}
        </LabeledList.Item>
      </LabeledList>
      {template.solo_zone_cooldown_available && (
        <NoticeBox mt={1} info={template.solo_zone_cooldown_active}>
          {template.solo_zone_cooldown_active
            ? `Сейчас активен solo-бонус: кулдаун сектора снижен до ${template.visibility_zone_cooldown_current} сек.`
            : `Если оставить только один пакет, кулдаун сектора этого шаблона снизится до ${template.visibility_zone_cooldown_solo} сек. Выбор второго пакета возвращает обычный КД: ${template.visibility_zone_cooldown} сек.`}
        </NoticeBox>
      )}
      <Divider />
      <Box bold mb={1}>
        Способности
      </Box>
      {template.actions.map((action) => (
        <ActionCard key={action.action_id} action={action} />
      ))}
    </Section>
  );
};

const SelectedSlots = ({ selectedTemplates, maxSelectedTemplates }) => {
  const filled = selectedTemplates || [];
  const slots = [];
  for (let index = 0; index < maxSelectedTemplates; index++) {
    slots.push(filled[index] || null);
  }
  return (
    <Section title="Слоты пакетов">
      {slots.map((template, index) => (
        <NoticeBox key={index} mt={index ? 1 : 0} info={!!template}>
          <Box bold>
            Slot {index + 1}: {template ? template.name : 'Пусто'}
          </Box>
        </NoticeBox>
      ))}
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

  return (
    <Window width={820} height={850} resizable>
      <Window.Content scrollable>
        <Stack vertical>
          <Stack.Item>
            <Section
              title="Пакеты поддержки"
              buttons={
                <Button
                  color="average"
                  disabled={!canResetTemplates}
                  icon="rotate-left"
                  onClick={() => act('reset_templates')}
                >
                  Сбросить оба слота
                </Button>
              }
            >
              <NoticeBox info>
                Можно выбрать до двух уникальных пакетов одновременно.
              </NoticeBox>
              <NoticeBox mt={1}>
                1. Выберите до двух пакетов. 2. Для боевых пакетов разверните
                свой сектор. 3. Вооружите нужную кнопку. 4. Наведите точку через
                Ctrl+Click во время зума через RTO-бинокль.
              </NoticeBox>
              <NoticeBox mt={1} warning>
                Полный сброс обоих слотов доступен через 60 минут от первого
                выбора в текущем цикле.
              </NoticeBox>
              {selectedCount === 0 && (
                <NoticeBox mt={1} info>
                  Если взять только один боевой пакет и не занимать второй слот,
                  кулдаун его сектора будет в 2 раза меньше.
                </NoticeBox>
              )}
              {selectedCount === 1 && (
                <NoticeBox mt={1} info>
                  Сейчас solo-бонус активен: пока у вас выбран только один
                  пакет, кулдаун его сектора снижен в 2 раза. Выбор второго
                  пакета вернет обычный КД.
                </NoticeBox>
              )}
              {selectedCount >= 2 && (
                <NoticeBox mt={1}>
                  Выбрано два пакета: для боевых шаблонов действует обычный
                  кулдаун сектора без solo-бонуса.
                </NoticeBox>
              )}
              {selectedCount > 0 && resetReadyIn > 0 && (
                <NoticeBox mt={1}>
                  До сброса слотов: {resetReadyIn} сек.
                </NoticeBox>
              )}
              {selectedCount > 0 && canResetTemplates && (
                <NoticeBox mt={1} info>
                  Слоты готовы к полному сбросу.
                </NoticeBox>
              )}
              {!canAddTemplate && selectedCount >= maxSelectedTemplates && (
                <NoticeBox mt={1} warning>
                  Оба слота уже заняты.
                </NoticeBox>
              )}
            </Section>
          </Stack.Item>

          <Stack.Item>
            <SelectedSlots
              selectedTemplates={selectedTemplates}
              maxSelectedTemplates={maxSelectedTemplates}
            />
          </Stack.Item>

          {!!templates.length &&
            templates.map((template) => (
              <Stack.Item key={template.template_id}>
                <TemplateCard
                  template={template}
                  canAddTemplate={canAddTemplate}
                />
              </Stack.Item>
            ))}
          {!templates.length && (
            <Stack.Item>
              <NoticeBox danger>Нет доступных пресетов поддержки.</NoticeBox>
            </Stack.Item>
          )}
        </Stack>
      </Window.Content>
    </Window>
  );
};
