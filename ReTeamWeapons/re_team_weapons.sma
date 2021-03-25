#include <amxmodx>
#include <reapi>

public plugin_init() {
	register_plugin("[ReAPI] Team Weapons", "1.0", "mIDnight");
	RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_post", .post = true);
	register_cvar("tw_disable", "0");
}

@CBasePlayer_Spawn_post(id) {
	if(!is_user_alive(id) || get_cvar_num("tw_disable")) return;
	rg_give_item(id, "weapon_awp");
	rg_set_user_bpammo(id, WEAPON_AWP, 30);
	rg_give_item(id, "weapon_deagle", GT_REPLACE);
	rg_set_user_bpammo(id, WEAPON_DEAGLE, 35);
	rg_give_item(id, "weapon_hegrenade");
	switch(get_member(id, m_iTeam)) {
		case TEAM_CT : {
			rg_give_item(id, "weapon_m4a1");
			rg_set_user_bpammo(id, WEAPON_M4A1, 90);
		}
		case TEAM_TERRORIST : {
			rg_give_item(id, "weapon_ak47");
			rg_set_user_bpammo(id, WEAPON_AK47, 90);
		}
	}
}