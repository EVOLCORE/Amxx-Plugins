#include <amxmodx>
#include <reapi>

new const Float:g_fCoords[][] = { {0.50, 0.40}, {0.56, 0.44}, {0.60, 0.50}, {0.56, 0.56}, {0.50, 0.60}, {0.44, 0.56}, {0.40, 0.50}, {0.44, 0.44} };
new g_iPlayerPos[33];

public plugin_init() {
	register_plugin("[ReAPI] Bullet Damager", "1.1", "mIDnight");
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "@CBasePlayer_TakeDamage_post", true);
}	

@CBasePlayer_TakeDamage_post(const iVictim, iInflictor, iAttacker, Float:fdamage) {
	if(is_user_connected(iAttacker) && rg_is_player_can_takedamage(iAttacker, iVictim)) {
		static g_iDamage;
		g_iDamage = floatround(fdamage, floatround_floor);
		if(g_iDamage > 0) {
			static iPos;
			iPos = ++g_iPlayerPos[iAttacker];
			if(iPos == sizeof(g_fCoords)) {
				iPos = g_iPlayerPos[iAttacker] = 0;
			}
			switch(get_member(iAttacker, m_iTeam)) {
				case TEAM_CT :
				{
					set_hudmessage(0, 100, 200, Float:g_fCoords[iPos][0], Float:g_fCoords[iPos][1], 0, 0.1, 1.5, 0.02, 0.02);
				}
				case TEAM_TERRORIST :
				{
					set_hudmessage(255, 0, 0, Float:g_fCoords[iPos][0], Float:g_fCoords[iPos][1], 0, 0.1, 1.5, 0.02, 0.02);
				}
			}
			show_hudmessage(iAttacker, "%d", g_iDamage);
		}
	}
}
