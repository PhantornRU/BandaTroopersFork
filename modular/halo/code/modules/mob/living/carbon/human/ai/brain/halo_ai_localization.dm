#define HALO_AI_LINE_ENTER "enter_combat_lines"
#define HALO_AI_LINE_EXIT "exit_combat_lines"
#define HALO_AI_LINE_DEATH "squad_member_death_lines"
#define HALO_AI_LINE_GRENADE "grenade_thrown_lines"
#define HALO_AI_LINE_RELOAD "reload_lines"
#define HALO_AI_LINE_RELOAD_INTERNAL "reload_internal_mag_lines"
#define HALO_AI_LINE_HEAL "need_healing_lines"

/proc/halo_ai_line_pack_keys()
	return list(
		HALO_AI_LINE_ENTER,
		HALO_AI_LINE_EXIT,
		HALO_AI_LINE_DEATH,
		HALO_AI_LINE_GRENADE,
		HALO_AI_LINE_RELOAD,
		HALO_AI_LINE_RELOAD_INTERNAL,
		HALO_AI_LINE_HEAL,
	)

/proc/halo_ai_build_line_pack(list/enter_lines = null, list/exit_lines = null, list/death_lines = null, list/grenade_lines = null, list/reload_lines = null, list/reload_internal_lines = null, list/heal_lines = null)
	var/list/pack = list()
	if(islist(enter_lines))
		pack[HALO_AI_LINE_ENTER] = enter_lines.Copy()
	if(islist(exit_lines))
		pack[HALO_AI_LINE_EXIT] = exit_lines.Copy()
	if(islist(death_lines))
		pack[HALO_AI_LINE_DEATH] = death_lines.Copy()
	if(islist(grenade_lines))
		pack[HALO_AI_LINE_GRENADE] = grenade_lines.Copy()
	if(islist(reload_lines))
		pack[HALO_AI_LINE_RELOAD] = reload_lines.Copy()
	if(islist(reload_internal_lines))
		pack[HALO_AI_LINE_RELOAD_INTERNAL] = reload_internal_lines.Copy()
	if(islist(heal_lines))
		pack[HALO_AI_LINE_HEAL] = heal_lines.Copy()
	return pack

/proc/halo_ai_copy_line_pack(list/source_pack)
	var/list/copied_pack = list()
	if(!islist(source_pack))
		return copied_pack

	for(var/key in halo_ai_line_pack_keys())
		if(islist(source_pack[key]))
			copied_pack[key] = source_pack[key].Copy()

	return copied_pack

/proc/halo_ai_merge_line_pack(list/base_pack, list/extra_pack)
	var/list/merged_pack = halo_ai_copy_line_pack(base_pack)
	if(!islist(extra_pack))
		return merged_pack

	for(var/key in halo_ai_line_pack_keys())
		if(!islist(extra_pack[key]))
			continue

		if(!islist(merged_pack[key]))
			merged_pack[key] = extra_pack[key].Copy()
			continue

		var/list/combined_lines = merged_pack[key]
		combined_lines += extra_pack[key]
		merged_pack[key] = combined_lines

	return merged_pack

/proc/halo_ai_apply_line_pack(datum/target, list/pack, append = FALSE)
	if(!target || !islist(pack))
		return

	for(var/key in halo_ai_line_pack_keys())
		if(!islist(pack[key]))
			continue

		if(!append || !islist(target.vars[key]))
			target.vars[key] = pack[key].Copy()
			continue

		var/list/existing_lines = target.vars[key]
		existing_lines = existing_lines.Copy()
		existing_lines += pack[key]
		target.vars[key] = existing_lines

/proc/halo_ai_get_default_fallback_pack()
	return halo_ai_build_line_pack(
		list(
			"Контакт!",
			"Цель впереди!",
			"Вижу врага!",
			"Огонь!",
			"Работаем!",
			"Вон они!",
			"Сектор горячий!",
			"Держать строй!",
			"В бой!",
			"*warcry",
		),
		list(
			"Огонь прекратить!",
			"Чисто.",
			"Пока тихо.",
			"Осмотреться.",
			"Проверить сектор.",
			"Вроде всё.",
			"Не расслабляться.",
		),
		list(
			"Чёрт!",
			"Потеря!",
			"Свои ранены!",
			"Они его сняли!",
			"Нет!",
			"Это им не сойдёт с рук!",
			"Медика сюда!",
		),
		list(
			"Граната!",
			"Бросаю гранату!",
			"Ложись!",
			"Подарок им!",
			"Пошла!",
		),
		list(
			"Перезаряжаюсь!",
			"Смена магазина!",
			"Я пуст!",
			"Прикрой!",
			"Нужен огонь прикрытия!",
		),
		list(
			"Перезаряжаюсь!",
			"Заряжаю!",
			"Пусто!",
			"Прикрой!",
			"Секунду!",
		),
		list(
			"Ранен!",
			"Кровь идёт!",
			"Нужен укол!",
			"Нужен бинт!",
			"Я задет!",
			"Латаюсь!",
		),
	)

/proc/halo_ai_get_militia_pack()
	return halo_ai_build_line_pack(
		list(
			"Контакт!",
			"Там кто-то есть!",
			"Они здесь!",
			"Огонь по ним!",
			"Не подпускайте их!",
			"Держать их на расстоянии!",
			"Вот они!",
			"*warcry",
		),
		list(
			"Тихо...",
			"Пока чисто.",
			"Осмотреться.",
			"Не разбредаться.",
			"Похоже, отбились.",
		),
		list(
			"Нет!",
			"Они убили своего!",
			"Медика сюда!",
			"Чёрт, он упал!",
			"Держитесь!",
		),
		list(
			"Граната!",
			"Лови!",
			"Бросаю!",
			"Пошла!",
		),
		list(
			"Перезаряжаюсь!",
			"Магазин меняю!",
			"Прикрой меня!",
			"Я пуст!",
		),
		list(
			"Перезаряжаюсь!",
			"Заряжаю!",
			"Пусто!",
			"Прикрой!",
		),
		list(
			"Меня задело!",
			"Кровь идёт!",
			"Мне нужен бинт!",
			"Я ранен!",
			"Нужен укол!",
		),
	)

/proc/halo_ai_get_merc_pack()
	return halo_ai_build_line_pack(
		list(
			"Контакт!",
			"Вижу цель!",
			"Работаем!",
			"Срезать их!",
			"Открыть огонь!",
			"Дави!",
			"Не щадить!",
			"*warcry",
		),
		list(
			"Чисто.",
			"Пока тихо.",
			"Не зевать.",
			"Проверить углы.",
			"Передохнули и дальше.",
		),
		list(
			"Чёрт!",
			"Потеря!",
			"Они сняли нашего!",
			"Медика сюда!",
			"Ответить им тем же!",
		),
		list(
			"Граната!",
			"Держите подарок!",
			"Пошла!",
			"Ложись!",
		),
		list(
			"Перезаряжаюсь!",
			"Меняю магазин!",
			"Я пуст!",
			"Прикрой!",
			"Прижми их огнём!",
		),
		list(
			"Перезаряжаюсь!",
			"Заряжаю!",
			"Пусто!",
			"Прикрой!",
		),
		list(
			"Ранен!",
			"Меня пробили!",
			"Нужен укол!",
			"Кровь идёт!",
			"Латаюсь!",
		),
	)

/proc/halo_ai_get_rebel_people_pack()
	return halo_ai_build_line_pack(
		list(
			"Контакт!",
			"Враг впереди!",
			"Огонь по угнетателям!",
			"Не отступать!",
			"За народ!",
			"За наших семей!",
			"Сломите их!",
			"*warcry",
		),
		list(
			"Пока чисто.",
			"Огонь прекратить.",
			"Не терять бдительность.",
			"Ещё могут вернуться.",
			"Держать позиции.",
		),
		list(
			"Нет!",
			"Они убили товарища!",
			"Это не останется без ответа!",
			"Товарищ пал!",
			"За него!",
		),
		list(
			"Граната!",
			"За народ!",
			"Лови!",
			"Пошла!",
		),
		list(
			"Перезаряжаюсь!",
			"Смена магазина!",
			"Прикрой меня!",
			"Нужен огонь прикрытия!",
		),
		list(
			"Перезаряжаюсь!",
			"Заряжаю!",
			"Прикрой!",
			"Пусто!",
		),
		list(
			"Ранен!",
			"Истекаю кровью!",
			"Нужен укол!",
			"Товарищи, помогите!",
			"Латаюсь!",
		),
	)

/proc/halo_ai_get_rebel_liberty_pack()
	return halo_ai_build_line_pack(
		list(
			"Контакт!",
			"Вижу противника!",
			"Огонь!",
			"Свободу не задушить!",
			"Не сдавайтесь!",
			"Дави их!",
			"За свободу!",
			"*warcry",
		),
		list(
			"Огонь прекратить.",
			"Пока чисто.",
			"Не расслабляться.",
			"Свобода дорого стоит...",
			"Проверить сектор.",
		),
		list(
			"Чёрт!",
			"Они сняли нашего!",
			"За него ответят!",
			"Медика сюда!",
			"Нет, только не так!",
		),
		list(
			"Граната!",
			"Держи!",
			"Свобода летит!",
			"Пошла!",
		),
		list(
			"Перезаряжаюсь!",
			"Смена магазина!",
			"Прикрой!",
			"Я пуст!",
		),
		list(
			"Перезаряжаюсь!",
			"Заряжаю!",
			"Пусто!",
			"Прикрой!",
		),
		list(
			"Ранен!",
			"Кровь идёт!",
			"Мне нужен укол!",
			"Я задет!",
			"Латаюсь!",
		),
	)

/proc/halo_ai_get_law_pack()
	return halo_ai_build_line_pack(
		list(
			"Оружие вниз!",
			"Контакт!",
			"Вижу нарушителя!",
			"Работаем!",
			"Вперёд!",
			"Нейтрализовать угрозу!",
			"Не дайте им уйти!",
		),
		list(
			"Сектор чист.",
			"Огонь прекратить.",
			"Проверить периметр.",
			"Держать строй.",
			"Пока всё тихо.",
		),
		list(
			"Чёрт!",
			"Сотрудник ранен!",
			"Медика сюда!",
			"Они сняли нашего!",
			"Не дать им пройти!",
		),
		list(
			"Граната!",
			"Бросаю гранату!",
			"Очистить зону!",
			"Пошла!",
		),
		list(
			"Перезаряжаюсь!",
			"Смена магазина!",
			"Прикрой меня!",
			"Я пуст!",
		),
		list(
			"Перезаряжаюсь!",
			"Заряжаю!",
			"Прикрой!",
			"Пусто!",
		),
		list(
			"Ранен!",
			"Истекаю кровью!",
			"Нужен медик!",
			"Нужен укол!",
			"Латаюсь!",
		),
	)

/proc/halo_ai_get_marine_pack()
	return halo_ai_build_line_pack(
		list(
			"Контакт!",
			"Цель впереди!",
			"Огонь по ним!",
			"Разнести их!",
			"Прижать к земле!",
			"Не щадить!",
			"Работаем, морпехи!",
			"*warcry",
		),
		list(
			"Чисто.",
			"Огонь прекратить.",
			"Проверить сектор.",
			"Не расслабляться.",
			"Передохнуть и дальше.",
		),
		list(
			"Чёрт!",
			"Морпех пал!",
			"Медика сюда!",
			"Они сняли нашего!",
			"Вернуть им долг!",
			"Держись, не умирай!",
		),
		list(
			"Граната!",
			"Пошла граната!",
			"Ложись!",
			"Получайте!",
		),
		list(
			"Перезаряжаюсь!",
			"Меняю магазин!",
			"Я пуст!",
			"Прикрой!",
			"Нужен огонь прикрытия!",
		),
		list(
			"Перезаряжаюсь!",
			"Заряжаю!",
			"Пусто!",
			"Прикрой!",
		),
		list(
			"Ранен!",
			"Кровь идёт!",
			"Мне нужен укол!",
			"Нужна марля!",
			"Я задет!",
			"Латаюсь!",
		),
	)

/proc/halo_ai_get_army_pack()
	return halo_ai_build_line_pack(
		list(
			"Контакт!",
			"Вижу цель!",
			"Огонь!",
			"Дави их!",
			"Вперёд!",
			"Работаем!",
			"*warcry",
		),
		list(
			"Чисто.",
			"Огонь прекратить.",
			"Проверить сектор.",
			"Пока тихо.",
			"Не терять бдительность.",
		),
		list(
			"Чёрт!",
			"Наш пал!",
			"Медика сюда!",
			"Они сняли нашего!",
			"За него!",
		),
		list(
			"Граната!",
			"Бросаю!",
			"Ложись!",
			"Пошла!",
		),
		list(
			"Перезаряжаюсь!",
			"Смена магазина!",
			"Прикрой!",
			"Я пуст!",
		),
		list(
			"Перезаряжаюсь!",
			"Заряжаю!",
			"Пусто!",
			"Прикрой!",
		),
		list(
			"Ранен!",
			"Кровь идёт!",
			"Мне нужен укол!",
			"Я задет!",
			"Нужен бинт!",
		),
	)

/proc/halo_ai_get_navy_pack()
	return halo_ai_build_line_pack(
		list(
			"Контакт!",
			"Вижу угрозу!",
			"Огонь!",
			"По местам!",
			"Работаем!",
			"Не дайте им пройти!",
			"*warcry",
		),
		list(
			"Пока чисто.",
			"Огонь прекратить.",
			"Проверить отсеки.",
			"Сектор чист.",
			"Не расслабляться.",
		),
		list(
			"Чёрт!",
			"Наш пал!",
			"Медика сюда!",
			"Они сняли своего!",
			"За него!",
		),
		list(
			"Граната!",
			"Бросаю гранату!",
			"Очистить сектор!",
			"Пошла!",
		),
		list(
			"Перезаряжаюсь!",
			"Меняю магазин!",
			"Прикрой!",
			"Я пуст!",
		),
		list(
			"Перезаряжаюсь!",
			"Заряжаю!",
			"Пусто!",
			"Прикрой!",
		),
		list(
			"Ранен!",
			"Кровь идёт!",
			"Мне нужен медик!",
			"Я задет!",
			"Латаюсь!",
		),
	)

/proc/halo_ai_get_upp_pack()
	return halo_ai_build_line_pack(
		list(
			"Контакт!",
			"Враг впереди!",
			"Огонь!",
			"Дави их!",
			"Не отступать!",
			"За Союз!",
			"Товарищи, вперёд!",
			"*warcry",
		),
		list(
			"Чисто.",
			"Огонь прекратить.",
			"Тихо.",
			"Не терять строй.",
			"Ещё могут вернуться.",
		),
		list(
			"Чёрт!",
			"Товарищ пал!",
			"Санитара сюда!",
			"Они сняли нашего!",
			"Отомстить за товарища!",
		),
		list(
			"Граната!",
			"Лови!",
			"За Союз!",
			"Пошла!",
		),
		list(
			"Перезаряжаюсь!",
			"Смена магазина!",
			"Прикрой!",
			"Я пуст!",
		),
		list(
			"Перезаряжаюсь!",
			"Заряжаю!",
			"Пусто!",
			"Прикрой!",
		),
		list(
			"Ранен!",
			"Кровь идёт!",
			"Нужен санитар!",
			"Мне нужен укол!",
			"Латаюсь!",
		),
	)

/proc/halo_ai_get_corporate_pack()
	return halo_ai_build_line_pack(
		list(
			"Контакт.",
			"Визуальный контакт.",
			"Вступаю в бой.",
			"Устранить угрозу.",
			"Работаем.",
			"Подавить цель.",
		),
		list(
			"Угроза подавлена.",
			"Прекратить огонь.",
			"Зона временно чиста.",
			"Сохранять готовность.",
		),
		list(
			"Потеря союзника.",
			"Боец выведен из строя.",
			"Запрашиваю медика.",
			"Ответить огнём.",
		),
		list(
			"Граната.",
			"Метание гранаты.",
			"Очистить сектор.",
		),
		list(
			"Перезаряжаюсь.",
			"Смена магазина.",
			"Требуется прикрытие.",
		),
		list(
			"Перезаряжаюсь.",
			"Заряжаю.",
			"Требуется прикрытие.",
		),
		list(
			"Повреждение.",
			"Запрашиваю медицинскую помощь.",
			"Провожу самопомощь.",
		),
	)

/proc/halo_ai_get_deathsquad_pack()
	return halo_ai_build_line_pack(
		list(
			"Контакт подтверждён.",
			"Вступаю в бой.",
			"Устраняю цель.",
			"Подтверждён враждебный контакт.",
			"Приступаю к ликвидации.",
		),
		list(
			"Боестолкновение завершено.",
			"Прекращаю огонь.",
			"Угроза устранена.",
		),
		list(
			"Союзный модуль выведен из строя.",
			"Союзная единица потеряна.",
			"Фиксирую потерю союзника.",
		),
		list(),
		list(),
		list(),
		list(),
	)

/proc/halo_ai_get_twe_pack()
	return halo_ai_build_line_pack(
		list(
			"Контакт!",
			"Вижу противника!",
			"Открыть огонь!",
			"Срезать мерзавцев!",
			"Держать строй!",
			"За Корону!",
			"Вперёд!",
			"*warcry",
		),
		list(
			"Чисто.",
			"Огонь прекратить.",
			"Пока тихо.",
			"Не терять бдительность.",
			"Чёрт побери...",
		),
		list(
			"Проклятье!",
			"Они сняли нашего!",
			"Медика сюда!",
			"Не умирай, слышишь?!",
			"За него ответят!",
		),
		list(
			"Граната!",
			"Бросаю гранату!",
			"Ложись!",
			"Пошла!",
		),
		list(
			"Перезаряжаюсь!",
			"Смена магазина!",
			"Прикрой меня!",
			"Я пуст!",
		),
		list(
			"Перезаряжаюсь!",
			"Заряжаю!",
			"Пусто!",
			"Прикрой!",
		),
		list(
			"Ранен!",
			"Кровь идёт!",
			"Мне нужен медик!",
			"Нужен укол!",
			"Латаюсь!",
		),
	)

/proc/halo_ai_get_cultist_pack()
	return halo_ai_build_line_pack(
		list(
			"Вот ты где.",
			"Нарушитель!",
			"Нечестивец!",
			"Осквернитель!",
			"Не дать им пройти!",
			"Во имя Вознесённого!",
			"Во имя Улья!",
			"Изгнать их!",
		),
		list(
			"Тихо...",
			"Ничего.",
			"Пока всё кончено.",
			"Слушайте тишину.",
			"...",
		),
		list(
			"Что ты наделал?!",
			"Отмстите за них!",
			"Этого не может быть!",
			"...",
		),
		list(
			"Я принёс вам дар...",
			"Примите подношение...",
			"Это вам...",
		),
		list(
			"Пусто.",
			"Щёлк.",
			"...",
		),
		list(
			"Пусто.",
			"Щёлк.",
			"...",
		),
		list(
			"Боль...",
			"Кровь...",
			"Я истекаю...",
			"...",
		),
	)

/proc/halo_ai_get_zombie_pack()
	return halo_ai_build_line_pack(
		list(
			"Агхх...",
			"Уууу...",
			"Гррраа...",
			"Мммяа...",
			"Пом...ог...",
			"*pain",
			"*scream",
		),
		list(
			"Уууу...",
			"Гррр...",
			"Ммхх...",
			"...",
			"*pain",
			"*scream",
		),
		list(
			"Гррра...",
			"Ууугх...",
			"Мммх...",
			"*pain",
			"*scream",
		),
		list(
			"Гррааа...",
			"Ууух...",
			"*pain",
			"*scream",
		),
		list(
			"Агхх...",
			"Ууу...",
			"*pain",
			"*scream",
		),
		list(
			"Агхх...",
			"Ууу...",
			"*pain",
			"*scream",
		),
		list(
			"Ууугх...",
			"Ммх...",
			"*pain",
			"*scream",
		),
	)

/proc/halo_ai_get_halo_unsc_pack()
	return halo_ai_build_line_pack(
		list(
			"Контакт!",
			"ККОН, огонь!",
			"Вижу врага!",
			"Держать линию!",
			"Прижать их!",
			"Работаем!",
			"*warcry",
		),
		list(
			"Чисто.",
			"Огонь прекратить.",
			"Проверить сектор.",
			"Пока всё тихо.",
			"Не расслабляться.",
		),
		list(
			"Чёрт!",
			"Наш пал!",
			"Корпсмена сюда!",
			"Они сняли нашего!",
			"За него!",
		),
		list(
			"Граната!",
			"Пошла граната!",
			"Ложись!",
			"Получайте!",
		),
		list(
			"Перезаряжаюсь!",
			"Смена магазина!",
			"Прикрой!",
			"Я пуст!",
		),
		list(
			"Перезаряжаюсь!",
			"Заряжаю!",
			"Пусто!",
			"Прикрой!",
		),
		list(
			"Ранен!",
			"Кровь идёт!",
			"Нужен медик!",
			"Мне нужен укол!",
			"Латаюсь!",
		),
	)

/proc/halo_ai_get_halo_unscn_pack()
	return halo_ai_build_line_pack(
		list(
			"Контакт!",
			"Вижу угрозу!",
			"Огонь!",
			"Закрыть проход!",
			"Не дайте им на борт!",
			"Работаем!",
		),
		list(
			"Палуба чиста.",
			"Огонь прекратить.",
			"Проверить отсеки.",
			"Пока тихо.",
		),
		list(
			"Чёрт!",
			"Наш пал!",
			"Медика сюда!",
			"Они сняли своего!",
		),
		list(
			"Граната!",
			"Очистить палубу!",
			"Пошла!",
		),
		list(
			"Перезаряжаюсь!",
			"Меняю магазин!",
			"Прикрой!",
		),
		list(
			"Перезаряжаюсь!",
			"Заряжаю!",
			"Прикрой!",
		),
		list(
			"Ранен!",
			"Кровь идёт!",
			"Нужен медик!",
		),
	)

/proc/halo_ai_get_halo_oni_pack()
	return halo_ai_build_line_pack(
		list(
			"Контакт.",
			"Цель подтверждена.",
			"Устраняю.",
			"Работаем тихо.",
			"Подавить угрозу.",
		),
		list(
			"Зона чиста.",
			"Контакт потерян.",
			"Продолжаем зачистку.",
		),
		list(
			"Потеря союзника.",
			"Цель ответит за это.",
			"Нужен медик.",
		),
		list(
			"Граната.",
			"Очистить сектор.",
			"Пошла.",
		),
		list(
			"Перезаряжаюсь.",
			"Смена магазина.",
			"Прикрытие.",
		),
		list(
			"Перезаряжаюсь.",
			"Заряжаю.",
			"Прикрытие.",
		),
		list(
			"Ранен.",
			"Провожу самопомощь.",
			"Нужен укол.",
		),
	)

/proc/halo_ai_get_halo_police_pack()
	return halo_ai_build_line_pack(
		list(
			"Контакт!",
			"Полиция! Оружие вниз!",
			"Вижу нарушителя!",
			"Работаем!",
			"Не дайте им уйти!",
		),
		list(
			"Сектор чист.",
			"Огонь прекратить.",
			"Проверить улицу.",
			"Пока тихо.",
		),
		list(
			"Чёрт!",
			"Офицер ранен!",
			"Медика сюда!",
			"Они сняли нашего!",
		),
		list(
			"Граната!",
			"Бросаю гранату!",
			"Очистить зону!",
		),
		list(
			"Перезаряжаюсь!",
			"Смена магазина!",
			"Прикрой!",
		),
		list(
			"Перезаряжаюсь!",
			"Заряжаю!",
			"Прикрой!",
		),
		list(
			"Ранен!",
			"Нужен медик!",
			"Кровь идёт!",
		),
	)

/proc/halo_ai_get_halo_insurgent_pack()
	return halo_ai_build_line_pack(
		list(
			"Контакт!",
			"ККОН идёт!",
			"Не дайте им взять нас!",
			"Огонь!",
			"За колонию!",
			"Дави их!",
			"*warcry",
		),
		list(
			"Пока чисто.",
			"Огонь прекратить.",
			"Не терять бдительность.",
			"Ещё вернутся.",
		),
		list(
			"Чёрт!",
			"Они сняли нашего!",
			"За него ответят!",
			"Медика сюда!",
		),
		list(
			"Граната!",
			"Лови!",
			"Пошла!",
		),
		list(
			"Перезаряжаюсь!",
			"Смена магазина!",
			"Прикрой!",
		),
		list(
			"Перезаряжаюсь!",
			"Заряжаю!",
			"Прикрой!",
		),
		list(
			"Ранен!",
			"Кровь идёт!",
			"Мне нужен укол!",
		),
	)

/proc/halo_ai_get_halo_covenant_pack()
	return halo_ai_build_line_pack(
		list(
			"Контакт.",
			"Нечестивцы.",
			"Сломите их.",
			"За Ковенант!",
			"Осквернители замечены.",
		),
		list(
			"Поле боя тихо.",
			"Бой завершён.",
			"Сохранять бдительность.",
		),
		list(
			"Воин пал.",
			"Отомстите за него.",
			"Их смерть будет напрасной.",
		),
		list(
			"Плазменная граната!",
			"Примите дар плазмы.",
		),
		list(
			"Перезаряжаюсь.",
			"Смена элемента.",
		),
		list(
			"Перезаряжаюсь.",
			"Заряжаю.",
		),
		list(
			"Я ранен.",
			"Нужна передышка.",
		),
	)

/proc/halo_ai_get_faction_localization_pack(faction_name)
	switch(faction_name)
		if(FACTION_NEUTRAL)
			return halo_ai_get_default_fallback_pack()
		if(FACTION_COLONIST)
			return halo_ai_get_militia_pack()
		if(FACTION_CONTRACTOR)
			return halo_ai_get_merc_pack()
		if(FACTION_MERCENARY)
			return halo_ai_get_merc_pack()
		if(FACTION_FREELANCER)
			return halo_ai_get_merc_pack()
		if(FACTION_TWE_REBEL)
			return halo_ai_get_rebel_people_pack()
		if(FACTION_UA_REBEL)
			return halo_ai_get_rebel_liberty_pack()
		if(FACTION_MARSHAL)
			return halo_ai_get_law_pack()
		if(FACTION_UACG)
			return halo_ai_get_law_pack()
		if(FACTION_MARINE)
			return halo_ai_get_marine_pack()
		if(FACTION_ARMY)
			return halo_ai_get_army_pack()
		if(FACTION_NAVY)
			return halo_ai_get_navy_pack()
		if(FACTION_UPP)
			return halo_ai_get_upp_pack()
		if(FACTION_WY)
			return halo_ai_get_corporate_pack()
		if(FACTION_PMC)
			return halo_ai_get_corporate_pack()
		if(FACTION_WY_DEATHSQUAD)
			return halo_ai_get_deathsquad_pack()
		if(FACTION_TWE)
			return halo_ai_get_twe_pack()
		if(FACTION_XENOMORPH)
			return halo_ai_get_cultist_pack()
		if(FACTION_ZOMBIE)
			return halo_ai_get_zombie_pack()
		if(FACTION_XENOMORPH_CORRPUTED)
			return halo_ai_get_cultist_pack()
		if(FACTION_UNSC)
			return halo_ai_get_halo_unsc_pack()
		if(FACTION_UNSCN)
			return halo_ai_get_halo_unscn_pack()
		if(FACTION_ONI)
			return halo_ai_get_halo_oni_pack()
		if(FACTION_UEG_POLICE)
			return halo_ai_get_halo_police_pack()
		if(FACTION_INSURGENT)
			return halo_ai_get_halo_insurgent_pack()
		if(FACTION_COVENANT)
			return halo_ai_get_halo_covenant_pack()

/proc/halo_ai_localize_human_ai_factions(datum/controller/subsystem/human_ai/subsystem)
	if(!subsystem)
		return

	for(var/faction_name in subsystem.human_ai_factions)
		var/list/localized_pack = halo_ai_get_faction_localization_pack(faction_name)
		if(!islist(localized_pack))
			continue

		var/datum/human_ai_faction/faction_datum = subsystem.human_ai_factions[faction_name]
		halo_ai_apply_line_pack(faction_datum, localized_pack)
		faction_datum.reapply_faction_data()

/proc/halo_ai_apply_default_fallback_to_brain(datum/human_ai_brain/brain)
	if(!brain)
		return

	var/datum/human_ai_faction/faction_datum
	if(SShuman_ai && brain.tied_human?.faction)
		faction_datum = SShuman_ai.human_ai_factions[brain.tied_human.faction]

	var/list/default_pack = halo_ai_get_default_fallback_pack()
	for(var/key in halo_ai_line_pack_keys())
		if(length(faction_datum?.vars[key]))
			continue
		brain.vars[key] = default_pack[key].Copy()

/datum/component/human_ai/Initialize()
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE || !ai_brain)
		return .

	halo_ai_apply_default_fallback_to_brain(ai_brain)

/proc/halo_ai_get_sangheili_base_pack()
	return halo_ai_build_line_pack(
		list(
			"Враг замечен.",
			"Сломите их.",
			"За Ковенант!",
			"Недостойные.",
			"Держать строй.",
			"Покажите честь в бою.",
			"Я вижу осквернителей.",
			"Уничтожить их.",
		),
		list(
			"Поле боя чисто.",
			"Бой окончен.",
			"Сохраняйте достоинство.",
			"Не теряйте бдительности.",
			"Пока тихо.",
		),
		list(
			"Воин пал.",
			"Почтите павшего.",
			"Его смерть будет отомщена.",
			"Нет... воин!",
			"Они ответят за это.",
		),
		list(
			"Плазменная граната!",
			"Примите дар плазмы.",
			"Сгорите в очищающем свете.",
			"Граната пошла.",
		),
		list(
			"Перезаряжаюсь.",
			"Смена элемента.",
			"Прикройте меня.",
			"Оружие разряжено.",
		),
		list(
			"Перезаряжаюсь.",
			"Заряжаю.",
			"Прикройте.",
			"Пусто.",
		),
		list(
			"Я ранен.",
			"Щит сорван.",
			"Нужна передышка.",
			"Восстанавливаюсь.",
		),
	)

/proc/halo_ai_get_sangheili_rank_extra_pack(rank_value, sword_only = FALSE)
	var/list/rank_pack = list()
	switch(rank_value)
		if(JOB_COV_MAJOR, "major")
			rank_pack = halo_ai_build_line_pack(
				list(
					"По моему слову.",
					"Держать линию.",
					"Низшие, не дрогнуть.",
				),
				null,
				list(
					"Командир пал!",
				),
			)
		if(JOB_COV_ULTRA, "ultra")
			rank_pack = halo_ai_build_line_pack(
				list(
					"За Иерархов!",
					"Низшие, не отставать.",
					"Сломите их волю.",
				),
				list(
					"Ультра удерживает строй.",
				),
				list(
					"Ультра пал!",
				),
				list(
					"Пусть плазма завершит суд.",
				),
			)
		if(JOB_COV_ZEALOT, "zealot")
			rank_pack = halo_ai_build_line_pack(
				list(
					"Во имя Священного Круга!",
					"Очистите их!",
					"Покажите истинную веру.",
				),
				list(
					"Священный долг исполнен.",
				),
				list(
					"Зилот пал!",
				),
				list(
					"Сгорите во славе Ковенанта!",
				),
			)

	if(sword_only)
		rank_pack = halo_ai_merge_line_pack(rank_pack, halo_ai_build_line_pack(
			list(
				"Клинки к бою!",
				"Разрубите их!",
				"Ни шага назад.",
			),
			list(
				"Клинок остаётся поднят.",
			),
			null,
			null,
			list(
				"Клинок готов.",
			),
			list(
				"Клинок готов.",
			),
		))

	return rank_pack

/proc/halo_ai_apply_sangheili_speech_profile(datum/human_ai_brain/brain, rank_value, sword_only = FALSE)
	if(!brain)
		return

	halo_ai_apply_line_pack(brain, halo_ai_get_sangheili_base_pack())
	halo_ai_apply_line_pack(brain, halo_ai_get_sangheili_rank_extra_pack(rank_value, sword_only), TRUE)

/proc/halo_ai_get_unggoy_base_pack()
	return halo_ai_build_line_pack(
		list(
			"Контакт! Контакт!",
			"Ой-ой, враг!",
			"Они идут!",
			"Стреляйте уже!",
			"Не дайте им подойти!",
			"Я вижу врага!",
			"Эй, тут горячо!",
			"Начальник, помоги!",
		),
		list(
			"Живы... вроде.",
			"Тихо? Правда тихо?",
			"Фух...",
			"Не бросайте меня.",
			"Пока никого.",
		),
		list(
			"Нет! Нет!",
			"Они убили нашего!",
			"Не хочу умирать!",
			"Наш упал!",
			"Начальник, помоги!",
		),
		list(
			"Плазма пошла!",
			"Лови!",
			"Только бы не в меня!",
			"Подарок!",
		),
		list(
			"Пусто!",
			"Перезаряжаюсь!",
			"Секунду!",
			"Прикройте меня!",
			"Не стреляйте в меня!",
		),
		list(
			"Пусто!",
			"Заряжаю!",
			"Секунду!",
			"Прикрой!",
		),
		list(
			"Я ранен!",
			"Мне больно!",
			"Мне нужен укол!",
			"Я весь дырявый!",
			"Помогите!",
		),
	)

/proc/halo_ai_get_unggoy_role_extra_pack(role_name)
	switch(role_name)
		if("support")
			return halo_ai_build_line_pack(
				list(
					"Не толкайтесь, я нужен живым!",
					"Я ещё вас всех залатаю!",
				),
				null,
				list(
					"Медик упал!",
				),
				null,
				null,
				null,
				list(
					"Сейчас-сейчас, укол уже и себе, и вам!",
					"Не дайте мне умереть, я же медик!",
				),
			)
		if("deacon")
			return halo_ai_build_line_pack(
				list(
					"Не дрожать! За мной!",
					"Слушать деакона!",
				),
				list(
					"Тихо. Я сказал тихо.",
				),
				list(
					"Деакон пал!",
				),
			)
		if("specops", "specops_ultra")
			return halo_ai_build_line_pack(
				list(
					"Тихо-тихо, сейчас мы их снимем.",
					"Они нас даже не увидят!",
				),
				list(
					"Чисто. Хорошо.",
				),
				list(
					"Спецотряд теряет бойца!",
				),
				list(
					"Сюрприз!",
				),
			)
		if("bomber")
			return halo_ai_build_line_pack(
				list(
					"Слишком поздно бежать!",
					"Сейчас всем будет жарко!",
					"Я вас с собой заберу!",
				),
				list(
					"Жаль, никого не подорвал...",
				),
				list(
					"Не успел...",
				),
				list(
					"Сгорите!",
					"Ловите свет Ковенанта!",
				),
				list(
					"Мне и не нужно перезаряжаться!",
				),
				list(
					"Мне и не нужно перезаряжаться!",
				),
				list(
					"Всё равно скоро бахну!",
				),
			)

/proc/halo_ai_apply_unggoy_speech_profile(datum/human_ai_brain/brain, role_name)
	if(!brain)
		return

	halo_ai_apply_line_pack(brain, halo_ai_get_unggoy_base_pack())
	halo_ai_apply_line_pack(brain, halo_ai_get_unggoy_role_extra_pack(role_name), TRUE)

#undef HALO_AI_LINE_ENTER
#undef HALO_AI_LINE_EXIT
#undef HALO_AI_LINE_DEATH
#undef HALO_AI_LINE_GRENADE
#undef HALO_AI_LINE_RELOAD
#undef HALO_AI_LINE_RELOAD_INTERNAL
#undef HALO_AI_LINE_HEAL
