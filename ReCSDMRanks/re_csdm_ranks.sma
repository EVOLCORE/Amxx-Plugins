#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <nvault>

enum _:szRank {
	Rank_Name,
	Rank_MaxXp,
}

/* {"RankName", Maximum XP to level up} */
new const szRankNames[][][] = {
	{"Unranked", 400},
	{"Silver I", 800},
	{"Silver II", 1000},
	{"Silver III", 1400},
	{"Silver IV", 1800},
	{"Silver Elite", 2500},
	{"Silver Elite Master", 3000},
	{"Gold Nova I", 3500},
	{"Gold Nova II", 4000},
	{"Gold Nova III", 4500},
	{"Gold Nova Master", 5000},
	{"Master Guardian I", 5500},
	{"Master Guardian II", 6000},
	{"Master Guardian Elite", 6500},
	{"Distinguished Master Guardian", 7000},
	{"Legendary Eagle", 7500},
	{"Legendary Eagle Master", 8000},
	{"Supreme Master First Class", 9000},
	{"The Global Elite", 10000}
};

new bool:g_PlayerRankedUp[MAX_CLIENTS + 1],
	g_rank[MAX_CLIENTS + 1],
	g_xp[MAX_CLIENTS + 1],
	pCvars[3],
	pForward[2],
	hud_sync;

public plugin_init() {
	register_plugin("[ReAPI] Cortex Rank System", "0.0.4", "mIDnight");

	RegisterHookChain(RG_CBasePlayer_Killed, "@CBasePlayer_Killed", .post = true);

	bind_pcvar_num(create_cvar("crs_dead_xp", "-2"), pCvars[0]);
	bind_pcvar_num(create_cvar("crs_kill_xp", "3"), pCvars[1]);
	bind_pcvar_num(create_cvar("crs_kill_hs_xp", "2"), pCvars[2]);

	pForward[0] = CreateMultiForward("crs_rank_up", ET_IGNORE, FP_CELL);
	pForward[1] = CreateMultiForward("crs_rank_down", ET_IGNORE, FP_CELL);

	hud_sync = CreateHudSyncObj();
}

public plugin_natives() {
	register_native("crs_get_user_xp", "@crs_get_user_xp");
	register_native("crs_get_user_rank", "@crs_get_user_rank");
	register_native("crs_get_user_rankname", "@crs_get_user_rankname");
}

@crs_get_user_xp() {
	new pPlayer = get_param(1);

	return g_xp[pPlayer];
}

@crs_get_user_rank() {
	new pPlayer = get_param(1);

	return g_rank[pPlayer];
}

@crs_get_user_rankname() {
	new pPlayer = get_param(1);

	set_array(2, szRankNames[g_rank[pPlayer]][Rank_Name], get_param(3));
}

public client_putinserver(pPlayer) {
	if(is_user_bot(pPlayer)) {
		return;
	}

	set_task(1.0, "@ShowHudmessage", pPlayer, .flags = "b");
}	

@ShowHudmessage(const pPlayer) {
	set_hudmessage(210, 105, 30, 0.01, 0.15, 0, _, 1.0, 0.1, 0.1);
	ShowSyncHudMsg(pPlayer, hud_sync, "[ Name: %n ]^n[ Rank: %s ]^n[ Rank XP: %i/%i ]", pPlayer, szRankNames[g_rank[pPlayer]][Rank_Name], g_xp[pPlayer], szRankNames[g_rank[pPlayer]][Rank_MaxXp]);
}

@CBasePlayer_Killed(const pVictim, pAttacker, iGib) {
	if(pVictim == pAttacker || !is_user_connected(pAttacker)) {
		return;
	}

	g_xp[pVictim] += pCvars[0];
	g_xp[pAttacker] += pCvars[1];

	if(get_member(pVictim, m_bHeadshotKilled)) {
		g_xp[pAttacker] += pCvars[2];
	}

	RankCheck(pAttacker);
	RankCheck(pVictim);
}

const TASKID_CRS = 1337;

RankCheck(const pPlayer) {
	if(g_xp[pPlayer] >= szRankNames[g_rank[pPlayer]][Rank_MaxXp][0]) {
		if(g_rank[pPlayer] == sizeof(szRankNames) - 1) {
			g_xp[pPlayer] = szRankNames[g_rank[pPlayer]][Rank_MaxXp][0];
			return;
		}
	//	g_xp[pPlayer] -= szRankNames[g_rank[pPlayer]][Rank_MaxXp][0];
		g_rank[pPlayer]++;
		g_PlayerRankedUp[pPlayer] = true;
		remove_task(pPlayer + TASKID_CRS);

		ExecuteForward(pForward[0], _, pPlayer);
	}
	else if(g_xp[pPlayer] <= 0) {
		if(g_rank[pPlayer] < 2) {
			g_xp[pPlayer] = 0;
			return;
		}

		g_rank[pPlayer]--;
		g_xp[pPlayer] = szRankNames[g_rank[pPlayer]][Rank_MaxXp][0] - g_xp[pPlayer];
		ExecuteForward(pForward[1], _, pPlayer);
	}
}

new g_vault;

public plugin_cfg() {
	g_vault = nvault_open("CortexRankSystem");

	if(g_vault == INVALID_HANDLE) {
		set_fail_state("Unknown nvault for CortexRankSystem");
	}
}

public plugin_end() {
	nvault_close(g_vault);
}

public client_authorized(pPlayer, const authid[]) {
	g_xp[pPlayer] = nvault_get(g_vault, fmt("%s_xp", authid));
	g_rank[pPlayer] = nvault_get(g_vault, fmt("%s_rank", authid));
}

public client_disconnected(pPlayer) {
	new authid[MAX_AUTHID_LENGTH], data[MAX_AUTHID_LENGTH+10];
	get_user_authid(pPlayer, authid, charsmax(authid));

	num_to_str(g_xp[pPlayer], data, charsmax(data));
	nvault_pset(g_vault, fmt("%s_xp", authid), data);

	num_to_str(g_rank[pPlayer], data, charsmax(data));
	nvault_pset(g_vault, fmt("%s_rank", authid), data);

	remove_task(pPlayer);
	remove_task(pPlayer + TASKID_CRS);
}
