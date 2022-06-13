#include <amxmodx>
#include <reapi>

new szMapname[32], g_iRound;

public plugin_init() {
	register_plugin("[ReAPI] Round info", "1.0", "mIDnight");

	RegisterHookChain(RG_CSGameRules_RestartRound, "@CSGameRules_RestartRound_Pre", .post = false);
	RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd,"@CSGameRules_OnRoundFreezeEnd", .post = true);

	get_mapname(szMapname, charsmax(szMapname));
}

@CSGameRules_RestartRound_Pre() {
	if(get_member_game(m_bCompleteReset)) {
		g_iRound = 0;
	}
	g_iRound++;
}

@CSGameRules_OnRoundFreezeEnd() {
	new nextmap[32], maxrounds;
	maxrounds = get_cvar_num("mp_maxrounds");
	get_cvar_string("amx_nextmap", nextmap, 31);

	client_print_color(0, print_team_grey, "^4[HW] [^1Round: ^3%d^1/^3%d ^1| Map: ^3%s ^1| ^1Nextmap: ^3%s ^1| ^1Players: ^3%i^1/^3%i^4]", g_iRound,maxrounds, szMapname, nextmap, get_playersnum(),get_member_game(m_nMaxPlayers));
}
