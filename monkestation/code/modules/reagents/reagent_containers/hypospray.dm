
/obj/item/reagent_containers/hypospray/medipen/temperature //not a survival subtype, because a low pressure seal on a medipen as harmless as this is pointless
	name = "Temperature Stabilization Injector"
	desc = "A three use medipen with the only purpose being to stabilize body temperature. Handy if you plan to be lit on fire or fight a watcher."
	icon_state = "morphen"
	inhand_icon_state = "morphen"
	base_icon_state = "morphen"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	amount_per_transfer_from_this = 10
	volume = 30
	list_reagents = list(/datum/reagent/medicine/leporazine = 30)

/obj/item/reagent_containers/hypospray/medipen/survival/penthrite
	name = "Rapid Penthrite Injector"
	desc = "An expensive single use injector containing penthrite, allowing your body to keep functioning even with wounds that would make someone collapse. Seems to only be rapid in a low pressure enviorment as well... thats misleading. <b> WARNING: DO NOT MIX WITH EPINEPHRINE OR ATROPINE. </b>"
	icon_state = "atropen"
	inhand_icon_state = "atropen"
	base_icon_state = "atropen"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	amount_per_transfer_from_this = 15
	volume = 15
	list_reagents = list(/datum/reagent/medicine/c2/penthrite = 15)

/obj/item/reagent_containers/hypospray/medipen/survival/speed
	name = "Rush Injector"
	desc = "An experimental medipen containing some mysterious chemical cocktail that allows the user to move incredibly fast for a very short period of time. Takes a second to kick in. <b> SIDE EFFECTS OF USING MANY STIMS IN A SHORT PERIOD UNKNOWN </b>"
	icon_state = "gorillapen"
	inhand_icon_state = "gorillapen"
	base_icon_state = "gorillapen"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	amount_per_transfer_from_this = 4
	volume = 4
	list_reagents = list(/datum/reagent/consumable/monkey_energy = 1, /datum/reagent/medicine/stimulants = 1, /datum/reagent/medicine/ephedrine = 1, /datum/reagent/drug/cocaine = 1)

/obj/item/reagent_containers/hypospray/medipen/magnet
	name = "Magnetization Injector"
	desc = "A single use medipen that gives a long lasting magnetization effect, causing you to pull in ores laying on the ground. <b> WARNING : CONTENTS MAY BE LIGHTLY ALCOHOLIC IN NATURE </b>"
	icon_state = "invispen"
	inhand_icon_state = "invispen"
	base_icon_state = "invispen"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	amount_per_transfer_from_this = 30
	volume = 30
	list_reagents = list(/datum/reagent/consumable/ethanol/fetching_fizz = 30)

