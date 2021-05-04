#include <amxmodx>
#include <reapi>

new const Float: g_flCoords[][] = { {0.50, 0.40}, {0.56, 0.44}, {0.60, 0.50}, {0.56, 0.56}, {0.50, 0.60}, {0.44, 0.56}, {0.40, 0.50}, {0.44, 0.44} };

new g_iPosition[33];
new g_iSize = sizeof(g_flCoords);

public plugin_init() {
	register_plugin("[ReAPI] Bullet Damage", "1.0", "mIDnight");
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "@CBasePlayer_TakeDamagePost", .post = true);
}

@CBasePlayer_TakeDamagePost(const iVictim, iInflictor, iAttacker, Float:fDamage, bitsDamageType) {
	if(!rg_is_player_can_takedamage(iAttacker, iVictim) || iVictim == iAttacker)
	return HC_CONTINUE;

	new iDamage[4];
	float_to_str(fDamage, iDamage, charsmax(iDamage));
	replace_all(iDamage, charsmax(iDamage), ".", "");
	{
		if(++g_iPosition[iAttacker] == g_iSize)
		g_iPosition[iAttacker] = 0;

		set_hudmessage(random_num(0, 255), random_num(0, 255), random_num(0, 255), Float:g_flCoords[g_iPosition[iAttacker]][0], Float:g_flCoords[g_iPosition[iAttacker]][1], 0, 0.1, 1.5, 0.02, 0.02);
		show_hudmessage(iAttacker, "%s", iDamage);
	}
	return HC_CONTINUE;
}
