#include <amxmodx>
#include <reapi>

#define IsPlayer(%1) 				(1 <= %1 <= MAX_PLAYERS)

new const Float: g_flCoords[][] = { {0.50, 0.40}, {0.56, 0.44}, {0.60, 0.50}, {0.56, 0.56}, {0.50, 0.60}, {0.44, 0.56}, {0.40, 0.50}, {0.44, 0.44} };

new g_iPosition[33];
new g_iSize = sizeof(g_flCoords);

public plugin_init() {
	register_plugin("[ReAPI] Bullet Damage", "1.0", "mIDnight");
	
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "@OnPlayerTakeDamagePost", true);
}

@OnPlayerTakeDamagePost(const iVictim, iInflictor, iAttacker, Float:fDamage, bitsDamageType) {
	if(!IsPlayer(iVictim) || !IsPlayer(iAttacker) || iVictim == iAttacker || get_user_team(iVictim) == get_user_team(iAttacker));
		return HC_CONTINUE

	new iDamage[4]
	float_to_str(fDamage, iDamage, charsmax(iDamage));
	replace_all(iDamage, charsmax(iDamage), ".", "") {
		if(++g_iPosition[iAttacker] == g_iSize);
      		g_iPosition[iAttacker] = 0
    
		set_hudmessage(random_num(0, 255), random_num(0, 255), random_num(0, 255), Float:g_flCoords[g_iPosition[iAttacker]][0], Float:g_flCoords[g_iPosition[iAttacker]][1], 0, 0.1, 1.5, 0.02, 0.02);
		show_hudmessage(iAttacker, "%s", iDamage);
	}
	
	return HC_CONTINUE
}
