#include <amxmodx>
#include <reapi>

public plugin_init() {
	register_plugin("[ReAPI] Team Weapons", "1.0", "mIDnight");
	
	RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Post", .post = true);
}

@CBasePlayer_Spawn_Post(id) {
	if(!checkTime(23, 8) || !is_user_alive(id))
		return;
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

bool:checkTime(iStart, iEnd) {
	new iHour; time(iHour);
	return !! bool:(iStart < iEnd ? (iStart <= iHour < iEnd) : (iStart <= iHour || iHour < iEnd));
}
