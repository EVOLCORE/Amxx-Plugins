#include <amxmodx>
#include <reapi>

#define BONUS_NORMAL 0.0
#define BONUS_HS 15.0
#define MAX_HP 100.0

public plugin_init() {
	register_plugin("[ReAPI] Vampire", "1.1", "mIDnight");

	RegisterHookChain(RG_CBasePlayer_Killed, "@RG_Player_Killed_Post", .post = true);
}

@RG_Player_Killed_Post(const iVictim, iAttacker) {
	if(!is_user_connected(iAttacker) || iVictim == iAttacker)
		return;
	
	new Float:oldHP = get_entvar(iAttacker, var_health);
	new Float:newHP = floatclamp(oldHP + (get_member(iVictim, m_bHeadshotKilled) ? BONUS_HS : BONUS_NORMAL), 0.0, MAX_HP);
	set_entvar(iAttacker, var_health, newHP);
}
