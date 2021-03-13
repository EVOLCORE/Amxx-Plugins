#include <amxmodx>
#include <reapi>

#define VIP_FLAG ADMIN_LEVEL_H

new playersTurn[33]
new bool: hasBombSite

public plugin_init() {
	register_plugin("[ReAPI] Steam Bonus", "1.2", "mIDnight")

	RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Post", true)
	if (rg_find_ent_by_class(-1, "func_bomb_target") > 0 || rg_find_ent_by_class(-1, "info_bomb_target") > 0)
	hasBombSite = true
}

@CBasePlayer_Spawn_Post(id) {
	if (is_user_alive(id) && is_user_steam(id)) {
		if (playersTurn[id] == 0)
		{
			if (get_user_flags(id) & VIP_FLAG) {
				GiveMoney(id, 400)
			}
			else 
			GiveGrenades(id)

			++playersTurn[id]
		}
		else if (playersTurn[id] == 1) {
			GiveArmor(id)
			++playersTurn[id]            
		}
		else if (playersTurn[id] == 2) {
			GiveMoney(id, 400)
			playersTurn[id] = 0
		}

		if (hasBombSite && get_member(id, m_iTeam) == TEAM_CT) {
			rg_give_defusekit(id)
		}
	}
}

GiveGrenades(id) {
	rg_give_item(id, "weapon_flashbang", GT_REPLACE)
	rg_set_user_bpammo(id, WEAPON_FLASHBANG, 2)
	rg_give_item(id, "weapon_hegrenade")

	client_print_color(id, print_team_default, "^x04[Element] ^x01+ steam bonus - ^x03grenades")
}

GiveArmor(id) {
	rg_set_user_armor(id, 100, ARMOR_VESTHELM)
	client_print_color(id, print_team_default, "^x04[Element] ^x01+ steam bonuses - ^x03armor")
}

GiveMoney(id, amount) {
	rg_add_account(id, amount)    
	client_print_color(id, print_team_default, "^x04[Element] ^x01+ steam bonuses - ^x03%d$", amount)
}
