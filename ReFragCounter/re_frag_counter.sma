#pragma semicolon 1

#include <amxmodx>
#include <reapi>

new g_iKills[MAX_CLIENTS + 1], g_iHSKills[MAX_CLIENTS + 1], bool:blShowHud[MAX_CLIENTS + 1];

public plugin_init() {
	register_plugin("[ReAPI] Frag counter", "0.0.1", "mIDnight");

	RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Post", .post = true);
	RegisterHookChain(RG_CBasePlayer_Killed, "@CBasePlayer_Killed_Post", .post = true);
}

public client_disconnected(pPlayer) {
	RemoveHud(pPlayer);
}

@CBasePlayer_Spawn_Post(const pPlayer) {
	if(!is_user_alive(pPlayer)) {
		return;
	}

	RemoveHud(pPlayer);
}

@CBasePlayer_Killed_Post(const pVictim, pAttacker, iGib) {
	RemoveHud(pVictim);

	if(!is_user_alive(pAttacker)) {
		return;
	}

	if(!blShowHud[pAttacker]) {
		set_task(1.0, "@ShowHudmessage", pAttacker, .flags = "b");
		blShowHud[pAttacker] = true;
	}

	g_iKills[pAttacker]++;

	if(get_member(pVictim, m_bHeadshotKilled)) {
		g_iHSKills[pAttacker]++;
	}
}

@ShowHudmessage(const pPlayer) {
	set_dhudmessage(0, 255, 0, 0.02, 0.35, 0, _, 1.1);
	show_dhudmessage(pPlayer, "Kills: %i (%i HS)", g_iKills[pPlayer], g_iHSKills[pPlayer]);
}

RemoveHud(const pPlayer) {
	if(blShowHud[pPlayer]) {
		g_iKills[pPlayer] = 0;
		g_iHSKills[pPlayer] = 0;
		remove_task(pPlayer);
		blShowHud[pPlayer] = false;
	}
}
