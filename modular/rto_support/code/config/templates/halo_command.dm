/datum/rto_support_template/halo_command
	parent_type = /datum/rto_support_template/halo
	template_id = "halo_command"
	name = "Командование UNSC"
	description = "Пакет командной поддержки UNSC для разведки, связи и снабжения RTO."
	role_summary = "Вызывает командные ящики со средствами связи, разведки и координации поля боя."
	targeting_summary = "Сектор не нужен: отметьте открытую точку посадки через RTO-бинокль."
	restriction_summary = "Доступен только RTO сил UNSC. Командные сбросы требуют открытого неба и работают как единое семейство поддержки."
	action_template_types = list(
		/datum/rto_support_action_template/halo_signal_drop,
		/datum/rto_support_action_template/halo_recon_drop,
		/datum/rto_support_action_template/halo_rto_command_drop,
	)
	support_action_icon_state = "radio"
