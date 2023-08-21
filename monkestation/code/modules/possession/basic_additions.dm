/mob/living/basic
	hud_type = /datum/hud/living/basic
	///rendered overlays
	var/list/possession_overlays[1]
	/// do we have hands created?
	var/dexterous = FALSE

	/// OFFSET SECTION - This is controllable by admins if they want
	var/uses_directional_offsets = TRUE
	///the shifted y offset of the left hand
	var/list/l_y_shift
	///the shifted y offset of the right hand
	var/list/r_y_shift
	///the shifted x offset of the right hand
	var/list/r_x_shift
	///the shifted x offset of the left hand
	var/list/l_x_shift
	/// base amount of pixels this offsets upwards for each set of additional arms past 2
	var/base_vertical_shift = 0
	///the shifted y offset of the head
	var/list/head_y_shift
	/// the shifted x offset of the head
	var/list/head_x_shift

/mob/living/basic/proc/create_overlay_index()
	var/list/overlays[1]
	possession_overlays = overlays
	return

/mob/living/basic/proc/populate_shift_list() // we can add manual offsets as we create them overtime
	l_y_shift = list(0, 0, 0, 0)
	r_y_shift = list(0, 0, 0, 0)
	r_x_shift = list(0, 0, 0, 0)
	l_x_shift = list(0, 0, 0, 0)
	head_y_shift = list(0, 0, 0, 0)
	head_x_shift = list(0, 0, 0, 0)

/mob/living/basic/regenerate_icons()
	update_held_items()

/mob/living/basic/update_held_items()
	remove_overlay(1)
	var/list/hands_overlays = list()

	for(var/obj/item/I in held_items)
		if(client && hud_used && hud_used.hud_version != HUD_STYLE_NOHUD)
			I.screen_loc = ui_hand_position(get_held_index_of_item(I))
			client.screen += I
			if(length(observers))
				for(var/mob/dead/observe as anything in observers)
					if(observe.client && observe.client.eye == src)
						observe.client.screen += I
					else
						observers -= observe
						if(!observers.len)
							observers = null
							break

		var/used_list_index = dir
		if(dir == WEST)
			used_list_index = 4
		if(dir == EAST)
			used_list_index = 3
		if(!uses_directional_offsets)
			used_list_index = 1

		var/icon_file = I.lefthand_file
		var/x_offset = l_x_shift[used_list_index]
		var/y_offset = l_y_shift[used_list_index]
		var/vertical_offset = 0
		vertical_offset = CEILING(get_held_index_of_item(I) / 2, 1) - 1
		if(get_held_index_of_item(I) % 2 == 0)
			icon_file = I.righthand_file
			y_offset = r_y_shift[used_list_index]
			x_offset = r_x_shift[used_list_index]

		var/mutable_appearance/hand_overlay = I.build_worn_icon(default_layer = HANDS_LAYER, default_icon_file = icon_file, isinhands = TRUE)
		hand_overlay.pixel_y += y_offset  + (vertical_offset * base_vertical_shift)
		hand_overlay.pixel_x += x_offset

		hands_overlays += hand_overlay

	if(hands_overlays.len)
		possession_overlays[1] = hands_overlays
	apply_overlay(1)

/mob/living/basic/proc/apply_overlay(cache_index)
	if((. = possession_overlays[cache_index]))
		add_overlay(.)

/mob/living/basic/proc/remove_overlay(cache_index)
	var/I = possession_overlays[cache_index]
	if(I)
		cut_overlay(I)
		possession_overlays[cache_index] = null

/mob/living/basic/proc/adjust_hand_count(number = 2)
	held_items = list()
	for(var/num=1 to number)
		held_items += null
	usable_hands = number
	hud_used.build_hand_slots()
	if(number > 0)
		dexterous = TRUE
		advanced_simple = TRUE
		add_traits(list(TRAIT_ADVANCEDTOOLUSER, TRAIT_CAN_STRIP, TRAIT_LITERATE), ROUNDSTART_TRAIT)
	else
		dexterous = FALSE
		advanced_simple = FALSE
		remove_traits(list(TRAIT_ADVANCEDTOOLUSER, TRAIT_CAN_STRIP, TRAIT_LITERATE), ROUNDSTART_TRAIT)

//general disarm proc
/mob/living/proc/disarm(mob/living/carbon/target)
	do_attack_animation(target, ATTACK_EFFECT_DISARM)
	playsound(target, 'sound/weapons/thudswoosh.ogg', 50, TRUE, -1)
	if (ishuman(target))
		var/mob/living/carbon/human/human_target = target
		human_target.w_uniform?.add_fingerprint(src)

	SEND_SIGNAL(target, COMSIG_HUMAN_DISARM_HIT, src, zone_selected)
	var/shove_dir = get_dir(loc, target.loc)
	var/turf/target_shove_turf = get_step(target.loc, shove_dir)
	var/shove_blocked = FALSE //Used to check if a shove is blocked so that if it is knockdown logic can be applied
	var/turf/target_old_turf = target.loc

	//Are we hitting anything? or
	if(SEND_SIGNAL(target_shove_turf, COMSIG_CARBON_DISARM_PRESHOVE) & COMSIG_CARBON_ACT_SOLID)
		shove_blocked = TRUE
	else
		target.Move(target_shove_turf, shove_dir)
		if(get_turf(target) == target_old_turf)
			shove_blocked = TRUE

	if(!shove_blocked)
		target.setGrabState(GRAB_PASSIVE)

	if(target.IsKnockdown() && !target.IsParalyzed()) //KICK HIM IN THE NUTS
		target.Paralyze(SHOVE_CHAIN_PARALYZE)
		target.visible_message(span_danger("[name] kicks [target.name] onto [target.p_their()] side!"),
						span_userdanger("You're kicked onto your side by [name]!"), span_hear("You hear aggressive shuffling followed by a loud thud!"), COMBAT_MESSAGE_RANGE, src)
		to_chat(src, span_danger("You kick [target.name] onto [target.p_their()] side!"))
		addtimer(CALLBACK(target, TYPE_PROC_REF(/mob/living, SetKnockdown), 0), SHOVE_CHAIN_PARALYZE)
		log_combat(src, target, "kicks", "onto their side (paralyzing)")

	var/directional_blocked = FALSE
	var/can_hit_something = (!target.is_shove_knockdown_blocked() && !target.buckled)

	//Directional checks to make sure that we're not shoving through a windoor or something like that
	if(shove_blocked && can_hit_something && (shove_dir in GLOB.cardinals))
		var/target_turf = get_turf(target)
		for(var/obj/obj_content in target_turf)
			if(obj_content.flags_1 & ON_BORDER_1 && obj_content.dir == shove_dir && obj_content.density)
				directional_blocked = TRUE
				break
		if(target_turf != target_shove_turf && !directional_blocked) //Make sure that we don't run the exact same check twice on the same tile
			for(var/obj/obj_content in target_shove_turf)
				if(obj_content.flags_1 & ON_BORDER_1 && obj_content.dir == turn(shove_dir, 180) && obj_content.density)
					directional_blocked = TRUE
					break

	if(can_hit_something)
		//Don't hit people through windows, ok?
		if(!directional_blocked && SEND_SIGNAL(target_shove_turf, COMSIG_CARBON_DISARM_COLLIDE, src, target, shove_blocked) & COMSIG_CARBON_SHOVE_HANDLED)
			return
		if(directional_blocked || shove_blocked)
			target.Knockdown(SHOVE_KNOCKDOWN_SOLID)
			target.visible_message(span_danger("[name] shoves [target.name], knocking [target.p_them()] down!"),
				span_userdanger("You're knocked down from a shove by [name]!"), span_hear("You hear aggressive shuffling followed by a loud thud!"), COMBAT_MESSAGE_RANGE, src)
			to_chat(src, span_danger("You shove [target.name], knocking [target.p_them()] down!"))
			log_combat(src, target, "shoved", "knocking them down")
			return

	target.visible_message(span_danger("[name] shoves [target.name]!"),
		span_userdanger("You're shoved by [name]!"), span_hear("You hear aggressive shuffling!"), COMBAT_MESSAGE_RANGE, src)
	to_chat(src, span_danger("You shove [target.name]!"))

	//Take their lunch money
	var/target_held_item = target.get_active_held_item()
	var/append_message = ""
	if(!is_type_in_typecache(target_held_item, GLOB.shove_disarming_types)) //It's too expensive we'll get caught
		target_held_item = null

	if(!target.has_movespeed_modifier(/datum/movespeed_modifier/shove))
		target.add_movespeed_modifier(/datum/movespeed_modifier/shove)
		if(target_held_item)
			append_message = "loosening [target.p_their()] grip on [target_held_item]"
			target.visible_message(span_danger("[target.name]'s grip on \the [target_held_item] loosens!"), //He's already out what are you doing
				span_warning("Your grip on \the [target_held_item] loosens!"), null, COMBAT_MESSAGE_RANGE)
		addtimer(CALLBACK(target, TYPE_PROC_REF(/mob/living/carbon, clear_shove_slowdown)), SHOVE_SLOWDOWN_LENGTH)

	else if(target_held_item)
		target.dropItemToGround(target_held_item)
		append_message = "causing [target.p_them()] to drop [target_held_item]"
		target.visible_message(span_danger("[target.name] drops \the [target_held_item]!"),
			span_warning("You drop \the [target_held_item]!"), null, COMBAT_MESSAGE_RANGE)

	log_combat(src, target, "shoved", append_message)


/// ALL THE PROCS RELATED TO GETTING HANDS TO FUNCTION

/mob/living/basic/can_hold_items(obj/item/I)
	return dexterous && ..()

/mob/living/basic/activate_hand(selhand)
	if(!dexterous)
		return ..()
	if(!selhand)
		selhand = (active_hand_index % held_items.len)+1
	if(istext(selhand))
		selhand = lowertext(selhand)
		if(selhand == "right" || selhand == "r")
			selhand = 2
		if(selhand == "left" || selhand == "l")
			selhand = 1
	if(selhand != active_hand_index)
		swap_hand(selhand)
	else
		mode()

/mob/living/basic/perform_hand_swap(hand_index)
	. = ..()
	if(!.)
		return
	if(!dexterous)
		return
	if(!hand_index)
		hand_index = (active_hand_index % held_items.len)+1
	var/oindex = active_hand_index
	active_hand_index = hand_index
	if(hud_used)
		var/atom/movable/screen/inventory/hand/H
		H = hud_used.hand_slots["[hand_index]"]
		if(H)
			H.update_appearance()
		H = hud_used.hand_slots["[oindex]"]
		if(H)
			H.update_appearance()

/mob/living/basic/put_in_hands(obj/item/I, del_on_fail = FALSE, merge_stacks = TRUE, ignore_animation = TRUE)
	. = ..()
	update_held_items()

/mob/living/basic/setDir(newdir)
	. = ..()
	update_held_items()

#define VV_HK_OFFSET_EDITOR "offset_editor"
#define VV_HK_ADJUST_HANDS "hand_count"
/mob/living/basic/vv_get_dropdown()
	. = ..()
	VV_DROPDOWN_OPTION("", "-------------") //monkestation edit
	VV_DROPDOWN_OPTION(VV_HK_OFFSET_EDITOR, "Edit Offsets") //monkestation edit
	VV_DROPDOWN_OPTION(VV_HK_ADJUST_HANDS, "Adjust Hand Count") //monkestation edit

/mob/living/basic/vv_do_topic(list/href_list)
	. = ..()

	if(!.)
		return

	if(href_list[VV_HK_OFFSET_EDITOR] && check_rights(R_FUN))
		if(!usr.client)
			return
		if(!usr.client.offset_editor)
			usr.client.offset_editor = new
		usr.client.offset_editor.open_ui(usr, src)

	if(href_list[VV_HK_ADJUST_HANDS] && check_rights(R_FUN))
		var/number = tgui_input_number(usr, "How many hands should this mob have?", "Adjust Hand Count")
		if(!number)
			adjust_hand_count(0)
			return
		adjust_hand_count(number)

#undef VV_HK_OFFSET_EDITOR
#undef VV_HK_ADJUST_HANDS
