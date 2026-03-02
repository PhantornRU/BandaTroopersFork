import { useBackend } from '../backend';
import { Box, Button, Divider, LabeledList, NoticeBox, Section, Stack } from '../components';
import { Window } from '../layouts';

const ActionCard = (props) => {
  const { action } = props;

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
      <Box bold mb={0.5}>
        {action.name}
      </Box>
      <Box color="label" mb={1}>
        {action.description}
      </Box>
      <LabeledList>
        <LabeledList.Item label="Разброс">
          {action.scatter}
        </LabeledList.Item>
        <LabeledList.Item label="Общий КД">
          {action.shared_cooldown} сек.
        </LabeledList.Item>
        <LabeledList.Item label="Личный КД">
          {action.personal_cooldown} сек.
        </LabeledList.Item>
      </LabeledList>
    </Box>
  );
};

const TemplateCard = (props) => {
  const { act, data } = useBackend();
  const { template } = props;

  return (
    <Section
      title={template.name}
      buttons={(
        <Button
          color="good"
          disabled={!data.can_select_template}
          icon="crosshairs"
          onClick={() => act('select_template', {
            template_id: template.template_id,
          })}
        >
          Выбрать
        </Button>
      )}>
      <Box mb={1}>{template.description}</Box>
      <LabeledList>
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
      </LabeledList>
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

export const RtoSupportPresetMenu = () => {
  const { data } = useBackend();
  const templates = data.templates || [];

  return (
    <Window width={720} height={760} resizable>
      <Window.Content scrollable>
        <Stack vertical>
          <Stack.Item>
            <Section title="Пакет поддержки">
              <NoticeBox info>
                Выбор выполняется один раз на жизнь текущего персонажа. После
                выбора появится кнопка сектора наведения и способности пакета.
              </NoticeBox>
              {!!data.active_template_name && (
                <NoticeBox warning mt={1}>
                  Уже выбран пакет: {data.active_template_name}
                </NoticeBox>
              )}
            </Section>
          </Stack.Item>
          {!!templates.length && templates.map((template) => (
            <Stack.Item key={template.template_id}>
              <TemplateCard template={template} />
            </Stack.Item>
          ))}
          {!templates.length && (
            <Stack.Item>
              <NoticeBox danger>
                Нет доступных пресетов поддержки.
              </NoticeBox>
            </Stack.Item>
          )}
        </Stack>
      </Window.Content>
    </Window>
  );
};
