#include <amxmodx>
#include <reapi>

#define HUD_ATTACKER_COLOR 0, 144, 200
#define HUD_VICTIM_COLOR 200, 0, 0
const Float: HUD_HOLD_TIME	=	1.0
const RESET_VALUE =	0

new const Float: DAMAGE_COORDS[][] = { {0.50, 0.43}, {0.55, 0.45}, {0.57, 0.50}, {0.55, 0.55}, {0.50, 0.57}, {0.45, 0.55}, {0.43, 0.50}, {0.45, 0.45} }

new g_hHudSyncObj
new const POS_X	=	0
new const POS_Y	=	1
new g_iDamageCoordPos[MAX_PLAYERS + 1]

public plugin_init() {
	register_plugin("[ReAPI] Bullet Damager", "1.1", "mIDnight")
	
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "@CBasePlayer_TakeDamage_Post", .post = true)

	g_hHudSyncObj = CreateHudSyncObj()
}	

@CBasePlayer_TakeDamage_Post(iVictim, iInflictor, iAttacker, Float:fDamage, bitDamageType) {
	if(!is_user_connected(iAttacker) || fDamage < 1.0 || get_member(iAttacker, m_iTeam) == get_member(iVictim, m_iTeam)) {
		return
	}

	new iPos = ++g_iDamageCoordPos[iAttacker]
	
	if(iPos == sizeof(DAMAGE_COORDS)) {
		iPos = g_iDamageCoordPos[iAttacker] = RESET_VALUE
	}

	set_hudmessage(HUD_ATTACKER_COLOR, DAMAGE_COORDS[iPos][POS_X], DAMAGE_COORDS[iPos][POS_Y], _, _, HUD_HOLD_TIME)
	ShowSyncHudMsg(iAttacker, g_hHudSyncObj, "%.0f", fDamage)

	set_hudmessage(HUD_VICTIM_COLOR, DAMAGE_COORDS[iPos][POS_X], DAMAGE_COORDS[iPos][POS_Y], _, _, HUD_HOLD_TIME)
	ShowSyncHudMsg(iVictim, g_hHudSyncObj, "%.0f", fDamage)
}
