#define CENTRIFUGE_LIGHTSPECIAL_OFF			0
#define CENTRIFUGE_LIGHTSPECIAL_BLINKING	1
#define CENTRIFUGE_LIGHTSPECIAL_ON			2


/obj/machinery/disease2/centrifuge
	name = "isolation centrifuge"
	desc = "Used to isolate pathogen and antibodies in blood. Make sure to keep the vials balanced when spinning for optimal efficiency."
	icon = 'monkestation/code/modules/virology/icons/virology.dmi'
	icon_state = "centrifuge"
	density = TRUE
	anchored = TRUE

	var/datum/browser/popup = null

	var/on = 0

	var/list/vials = list(null,null,null,null)
	var/list/vial_valid = list(0,0,0,0)
	var/list/vial_task = list(
		list(0,0,0,0,0,),
		list(0,0,0,0,0,),
		list(0,0,0,0,0,),
		list(0,0,0,0,0,),
		)

	light_color = "#8DC6E9"
	light_outer_range = 2
	light_power = 1

	circuit = /obj/item/circuitboard/machine/centrifuge

	idle_power_usage = 100
	active_power_usage = 300

	var/base_efficiency = 1
	var/upgrade_efficiency = 0.3 // the higher, the better will upgrade affect efficiency

	var/efficiency = 1

	var/special = CENTRIFUGE_LIGHTSPECIAL_OFF

/obj/machinery/disease2/centrifuge/New()
	. = ..()

	RefreshParts()

/obj/machinery/disease2/centrifuge/RefreshParts()
	. = ..()
	var/manipcount = 0
	for(var/datum/stock_part/manipulator/M in component_parts)
		manipcount += M.tier
	base_efficiency = 1 + upgrade_efficiency * (manipcount-2)


/obj/machinery/disease2/centrifuge/attackby(obj/item/I, mob/living/user, params)
	. = ..()

	if(machine_stat & (BROKEN))
		to_chat(user, span_warning("\The [src] is broken. Some components will have to be replaced before it can work again.") )
		return FALSE

	if(.)
		return

	if (istype(I, /obj/item/reagent_containers/cup/beaker/vial))
		special = CENTRIFUGE_LIGHTSPECIAL_OFF
		if (on)
			to_chat(user,span_warning("You cannot add or remove vials while the centrifuge is active. Turn it Off first.") )
			return
		var/obj/item/reagent_containers/cup/beaker/vial/vial = I
		for (var/i = 1 to vials.len)
			if(!vials[i])
				vials[i] = vial
				vial_valid[i] = vial_has_antibodies(vial)
				visible_message(span_notice("\The [user] adds \the [vial] to \the [src]."),span_notice("You add \the [vial] to \the [src]."))
				playsound(loc, 'sound/machines/click.ogg', 50, 1)
				user.transferItemToLoc(vial, loc)
				vial.forceMove(src)
				update_appearance()
				updateUsrDialog()
				return TRUE

		to_chat(user,span_warning("There is no room for more vials.") )
		return FALSE


/obj/machinery/disease2/centrifuge/proc/vial_has_antibodies(obj/item/reagent_containers/cup/beaker/vial/vial)
	if (!vial)
		return FALSE

	var/datum/reagent/blood/blood = locate() in vial.reagents.reagent_list
	if (blood && blood.data && blood.data["immunity"])
		var/list/immune_system = blood.data["immunity"]
		if (istype(immune_system) && immune_system.len > 0)
			var/list/antibodies = immune_system[2]
			for (var/antibody in antibodies)
				if (antibodies[antibody] >= 30)
					return TRUE

//Also handles luminosity
/obj/machinery/disease2/centrifuge/update_icon()
	. = ..()
	icon_state = "centrifuge"

	if (machine_stat & (NOPOWER))
		icon_state = "centrifuge0"

	if (machine_stat & (BROKEN))
		icon_state = "centrifugeb"

	if(machine_stat & (BROKEN|NOPOWER))
		set_light(0)
	else
		if (on)
			icon_state = "centrifuge_moving"
			set_light(2,2)
		else
			set_light(2,1)

/obj/machinery/disease2/centrifuge/update_overlays()
	. = ..()
	if(!(machine_stat & (BROKEN|NOPOWER)))
		if(on)
			var/mutable_appearance/centrifuge_light = emissive_appearance(icon,"centrifuge_light",src)
			.+= centrifuge_light
			var/mutable_appearance/centrifuge_glow = emissive_appearance(icon,"centrifuge_glow",src)
			centrifuge_glow.blend_mode = BLEND_ADD
			.+= centrifuge_glow
			var/mutable_appearance/centrifuge_light_n = mutable_appearance(icon,"centrifuge_light",src)
			.+= centrifuge_light_n
			var/mutable_appearance/centrifuge_glow_n = mutable_appearance(icon,"centrifuge_glow",src)
			centrifuge_glow.blend_mode = BLEND_ADD
			.+= centrifuge_glow_n

		switch (special)
			if (CENTRIFUGE_LIGHTSPECIAL_BLINKING)
				.+= emissive_appearance(icon,"centrifuge_special_update",src)
				.+= mutable_appearance(icon,"centrifuge_special_update",src)
				special = CENTRIFUGE_LIGHTSPECIAL_ON
			if (CENTRIFUGE_LIGHTSPECIAL_ON)
				.+= emissive_appearance(icon,"centrifuge_special",src)
				.+= mutable_appearance(icon,"centrifuge_special_update",src)

	for (var/i = 1 to vials.len)
		if(vials[i])
			var/obj/item/reagent_containers/cup/beaker/vial/vial = vials[i]
			.+= mutable_appearance(icon, "centrifuge_vial[i][on ? "_moving" : ""]",src)
			if(vial.reagents.total_volume)
				var/mutable_appearance/filling = mutable_appearance(icon, "centrifuge_vial[i]_filling[on ? "_moving" : ""]",src)
				filling.icon += mix_color_from_reagents(vial.reagents.reagent_list)
				.+= filling

/obj/machinery/disease2/centrifuge/proc/add_vial_dat(obj/item/reagent_containers/cup/beaker/vial/vial, list/vial_task = list(0,0,0,0,0), slot = 1)
	var/dat = ""
	var/valid = vial_valid[slot]

	var/datum/reagent/blood/blood = locate() in vial.reagents.reagent_list
	if (!blood)
		var/datum/reagent/vaccine/vaccine = locate() in vial.reagents.reagent_list
		if (!vaccine)
			dat += "<A href='?src=\ref[src];ejectvial=[slot]'>[vial.name] (no blood detected)</a>"
		else
			var/vaccines = ""
			for (var/A in vaccine.data["antigen"])
				vaccines += "[A]"
			if (vaccines == "")
				vaccines = "blank"
			dat += "<A href='?src=\ref[src];ejectvial=[slot]'>[vial.name] (Vaccine ([vaccines]))</a>"
	else
		if (vial_task[1])
			switch (vial_task[1])
				if ("dish")
					var/target = vial_task[2]
					var/progress = vial_task[3]
					dat += "<A href='?src=\ref[src];ejectvial=[slot]'>[vial.name] (isolating [target]: [round(progress)]%)</a> <A href='?src=\ref[src];interrupt=[slot]'>X</a>"
				if ("vaccine")
					var/target = vial_task[2]
					var/progress = vial_task[3]
					dat += "<A href='?src=\ref[src];ejectvial=[slot]'>[vial.name] (synthesizing vaccine ([target]): [round(progress)]%)</a> <A href='?src=\ref[src];interrupt=[slot]'>X</a>"

		else
			if(blood.data && blood.data["viruses"])
				var/list/blood_diseases = blood.data["viruses"]
				if (blood_diseases && blood_diseases.len > 0)
					dat += "<A href='?src=\ref[src];ejectvial=[slot]'>[vial.name] (pathogen detected)</a> <A href='?src=\ref[src];isolate=[slot]'>ISOLATE TO DISH</a> [valid ? "<A href='?src=\ref[src];synthvaccine=[slot]'>SYNTHESIZE VACCINE</a>" : "(not enough antibodies for a vaccine)"]"
				else
					dat += "<A href='?src=\ref[src];ejectvial=[slot]'>[vial.name] (no pathogen detected)</a> [valid ? "<A href='?src=\ref[src];synthvaccine=[slot]'>SYNTHESIZE VACCINE</a>" : "(not enough antibodies for a vaccine)"]"
	return dat

/obj/machinery/disease2/centrifuge/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(machine_stat & (BROKEN))
		to_chat(user, span_notice("\The [src] is broken. Some components will have to be replaced before it can work again.") )
		return

	if(machine_stat & (NOPOWER))
		to_chat(user, span_notice("Deprived of power, \the [src] is unresponsive.") )
		for (var/i = 1 to vials.len)
			if(vials[i])
				var/obj/item/reagent_containers/cup/beaker/vial/vial = vials[i]
				playsound(loc, 'sound/machines/click.ogg', 50, 1)
				vial.forceMove(loc)
				vials[i] = null
				vial_valid[i] = 0
				vial_task[i] = list(0,0,0,0,0)
				update_appearance()
				sleep(1)
		return

	if(.)
		return

	user.set_machine(src)

	special = CENTRIFUGE_LIGHTSPECIAL_OFF

	var/dat = ""
	dat += "Power status: <A href='?src=\ref[src];power=1'>[on?"On":"Off"]</a>"
	dat += "<hr>"
	for (var/i = 1 to vials.len)
		if(vials[i])
			dat += add_vial_dat(vials[i],vial_task[i],i)
		else
			dat += "<A href='?src=\ref[src];insertvial=[i]'>Insert a vial</a>"
		if(i < vials.len)
			dat += "<BR>"
	dat += "<hr>"

	popup = new(user, "centrifuge", "Isolation Centrifuge", 666, 189)
	popup.set_window_options("can_close=1;can_minimize=1;can_maximize=0;can_resize=1;titlebar=1;")
	popup.set_content(dat)
	popup.open()

/obj/machinery/disease2/centrifuge/process()
	if(machine_stat & (NOPOWER|BROKEN))
		return

	if(on)
		use_power = 2

		//first of all, let's see how (un)balanced are those vials.
		//we're not taking reagent density into account because even my autism has its limits
		var/obj/item/reagent_containers/cup/beaker/vial/vial1 = vials[1]//left
		var/obj/item/reagent_containers/cup/beaker/vial/vial2 = vials[2]//up
		var/obj/item/reagent_containers/cup/beaker/vial/vial3 = vials[3]//right
		var/obj/item/reagent_containers/cup/beaker/vial/vial4 = vials[4]//down
		var/vial_unbalance_X = 0
		if (vial1)
			vial_unbalance_X += 5 + vial1.reagents.total_volume
		if (vial3)
			vial_unbalance_X -= 5 + vial3.reagents.total_volume
		var/vial_unbalance_Y = 0
		if (vial2)
			vial_unbalance_Y += 5 + vial2.reagents.total_volume
		if (vial4)
			vial_unbalance_Y -= 5 + vial4.reagents.total_volume

		var/vial_unbalance = abs(vial_unbalance_X) + abs(vial_unbalance_Y) // vials can contain up to 25 units, so maximal unbalance is 60.

		efficiency = base_efficiency / (1 + vial_unbalance / 60) // which will at most double the time taken.

		for (var/i = 1 to vials.len)
			if(vials[i])
				var/list/v_task = vial_task[i]
				if(v_task[1])
					vial_task[i] = centrifuge_act(vials[i],vial_task[i])
	else
		use_power = 1

	update_appearance()
	updateUsrDialog()

/obj/machinery/disease2/centrifuge/proc/centrifuge_act(obj/item/reagent_containers/cup/beaker/vial/vial, list/vial_task = list(0,0,0,0,0))
	var/list/result = list(0,0,0,0,0)
	if (!vial)
		return result
	result = vial_task
	switch (result[1])
		if ("dish")
			result[3] += (efficiency * 2) / (1 + 0.3 * result[5])//additional pathogen in the sample will lengthen the process
			if (result[3] >= 100)
				print_dish(result[4])
				result = list(0,0,0,0,0)
		if ("vaccine")
			if (result[4] > 50)
				result[3] += (efficiency * 2) * max(1,result[4]-50)
			else if (result[4] < 50)
				result[3] += (efficiency * 2) / max(1,50-result[4])
			else
				result[3] += (efficiency * 2)
			if (result[3] >= 100)
				special = CENTRIFUGE_LIGHTSPECIAL_BLINKING
				var/amt= vial.reagents.get_reagent_amount(/datum/reagent/blood)
				vial.reagents.remove_reagent(/datum/reagent/blood, amt)
				var/data = list("antigen" = list(result[2]))
				vial.reagents.add_reagent(/datum/reagent/vaccine, amt,data)
				result = list(0,0,0,0,0)
	return result

/obj/machinery/disease2/centrifuge/Topic(href, href_list)

	if(..())
		return 1

	special = CENTRIFUGE_LIGHTSPECIAL_OFF

	if (href_list["power"])
		on = !on
		update_appearance()

	else if (href_list["insertvial"])
		var/mob/living/user
		if (isliving(usr))
			user = usr
		if (!user)
			return
		var/obj/item/reagent_containers/cup/beaker/vial/vial = user.get_active_hand()
		if (istype(vial))
			if (on)
				to_chat(user,span_warning("You cannot add or remove vials while the centrifuge is active. Turn it Off first."))
				return
			else
				var/i = text2num(href_list["insertvial"])
				if (!vials[i])
					vials[i] = vial
					vial_valid[i] = vial_has_antibodies(vial)
					visible_message(span_notice("\The [user] adds \the [vial] to \the [src]."),span_notice("You add \the [vial] to \the [src]."))
					playsound(loc, 'sound/machines/click.ogg', 50, 1)
					user.transferItemToLoc(vial, loc)
					vial.forceMove(src)
				else
					to_chat(user,span_warning("There is already a vial in that slot."))
					return

	else if (href_list["ejectvial"])
		if (on)
			to_chat(usr,span_warning("You cannot add or remove vials while the centrifuge is active. Turn it Off first."))
			return
		else
			var/i = text2num(href_list["ejectvial"])
			if (vials[i])
				var/obj/item/reagent_containers/cup/beaker/vial/vial = vials[i]
				vial.forceMove(src.loc)
				if (Adjacent(usr))
					vial.forceMove(usr.loc)
					usr.put_in_hands(vial)
				vials[i] = null
				vial_valid[i] = 0
				vial_task[i] = list(0,0,0,0,0)

	else if (href_list["interrupt"])
		var/i = text2num(href_list["interrupt"])
		vial_task[i] = list(0,0,0,0,0)

	else if (href_list["isolate"])
		var/i = text2num(href_list["isolate"])
		vial_task[i] = isolate(vials[i],usr)

	else if (href_list["synthvaccine"])
		var/i = text2num(href_list["synthvaccine"])
		vial_task[i] = cure(vials[i],usr)

	update_appearance()
	add_fingerprint(usr)
	updateUsrDialog()
	attack_hand(usr)

/obj/machinery/disease2/centrifuge/proc/isolate(obj/item/reagent_containers/cup/beaker/vial/vial, mob/user)
	var/list/result = list(0,0,0,0,0)
	if (!vial)
		return result

	var/datum/reagent/blood/blood = locate() in vial.reagents.reagent_list
	if (blood && blood.data && blood.data["viruses"])
		var/list/blood_viruses = blood.data["viruses"]
		if (istype(blood_viruses) && blood_viruses.len > 0)
			var/list/pathogen_list = list()
			for (var/datum/disease/advanced/D as anything  in blood_viruses)
				if(!istype(D))
					continue
				var/pathogen_name = "Unknown [D.form]"
				pathogen_list[pathogen_name] = D

			popup.close()
			user.unset_machine()
			var/choice = input(user, "Choose a pathogen to isolate on a growth dish.", "Isolate to dish") as null|anything in pathogen_list
			user.set_machine()
			if (!choice)
				return result
			var/datum/disease/advanced/target = pathogen_list[choice]

			result[1] = "dish"
			result[2] = "Unknown [target.form]"
			result[3] = 0
			result[4] = target
			result[5] = length(pathogen_list)

	return result

/obj/machinery/disease2/centrifuge/proc/cure(obj/item/reagent_containers/cup/beaker/vial/vial, mob/user)
	var/list/result = list(0,0,0,0,0)
	if (!vial)
		return result

	var/datum/reagent/blood/blood = locate() in vial.reagents.reagent_list
	if (blood && blood.data && blood.data["immunity"])
		var/list/immune_system = blood.data["immunity"]
		if (istype(immune_system) && immune_system.len > 0)
			if (immune_system[1] < 1)
				to_chat(user,span_warning("Impossible to acquire antibodies from this blood sample. It seems that it came from a donor with a poor immune system, either due to recent cloning or a radium overload.") )
				return result

			var/list/antibodies = immune_system[2]
			var/list/antibody_choices = list()
			for (var/antibody in antibodies)
				if (antibodies[antibody] >= 30)
					if (antibodies[antibody] > 50)
						var/delay = max(1,60 / max(1,(antibodies[antibody] - 50)))
						antibody_choices["[antibody] (Expected Duration: [round(delay)] seconds)"] = antibody
					else if (antibodies[antibody] < 50)
						var/delay = max(1,50 - min(49,antibodies[antibody]))
						antibody_choices["[antibody] (Expected Duration: [round(delay)] minutes)"] = antibody
					else
						antibody_choices["[antibody] (Expected Duration: one minute)"] = antibody

			if (antibody_choices.len <= 0)
				to_chat(user,span_warning("Impossible to create a vaccine from this blood sample. Antibody levels too low. Minimal level = 30%. The higher the concentration, the faster the vaccine is synthesized.") )
				return result

			popup.close()
			user.unset_machine()
			var/choice = input(user, "Choose an antibody to develop into a vaccine. This will destroy the blood sample. The higher the concentration, the faster the vaccine is synthesized.", "Synthesize Vaccine") as null|anything in antibody_choices
			user.set_machine()
			if (!choice)
				return result

			var/antibody = antibody_choices[choice]

			result[1] = "vaccine"
			result[2] = antibody
			result[3] = 0
			result[4] = antibodies[antibody]

	return result

/obj/machinery/disease2/centrifuge/proc/print_dish(var/datum/disease/advanced/D)
	special = CENTRIFUGE_LIGHTSPECIAL_BLINKING
	/*
	anim(target = src, a_icon = icon, flick_anim = "centrifuge_print", sleeptime = 10)
	anim(target = src, a_icon = icon, flick_anim = "centrifuge_print_color", sleeptime = 10, col = D.color)
	*/
	visible_message("\The [src] prints a growth dish.")
	spawn(10)
		var/obj/item/weapon/virusdish/dish = new/obj/item/weapon/virusdish(src.loc)
		dish.contained_virus = D.Copy()
		dish.contained_virus.infectionchance = dish.contained_virus.infectionchance_base
		dish.update_appearance()
		dish.name = "growth dish (Unknown [dish.contained_virus.form])"


/obj/machinery/disease2/centrifuge/Destroy()
	for (var/i = 1 to vials.len)
		if(vials[i])
			var/obj/item/reagent_containers/cup/beaker/vial/vial = vials[i]
			vial.forceMove(loc)
	vials = list(null,null,null,null)
	vial_valid = list(0,0,0,0)
	vial_task = list(
		list(0,0,0,0,0,),
		list(0,0,0,0,0,),
		list(0,0,0,0,0,),
		list(0,0,0,0,0,),
		)
	special = CENTRIFUGE_LIGHTSPECIAL_OFF
	. = ..()

#undef CENTRIFUGE_LIGHTSPECIAL_OFF
#undef CENTRIFUGE_LIGHTSPECIAL_BLINKING
#undef CENTRIFUGE_LIGHTSPECIAL_ON
