#include <amxmodx>
#include <reapi>

#define BONUS_NORMAL 10.0
#define BONUS_HS 15.0
#define MAX_HP 100.0

public plugin_init() {
	register_plugin("[ReAPI] Vampire", "1.1", "mIDnight");

	RegisterHookChain(RG_CBasePlayer_Killed, "@CBasePlayer_Killed_Post", .post = true);
}

@CBasePlayer_Killed_Post(const iVictim, iAttacker) {
	if(!is_user_connected(iAttacker) || iVictim == iAttacker) {
		return;
	}
	
	set_entvar(iAttacker, var_health, floatmin(Float:get_entvar(iAttacker, var_health) + (get_member(iVictim, m_bHeadshotKilled) ? BONUS_HS : BONUS_NORMAL), MAX_HP));
}
