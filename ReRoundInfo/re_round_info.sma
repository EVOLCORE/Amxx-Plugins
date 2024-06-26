#include <amxmodx>
#include <reapi>

new szMapname[32], g_iRound, nextmap[32], maxrounds;

public plugin_init() {
    register_plugin("[ReAPI] Round info", "1.2", "mIDnight");

    RegisterHookChain(RG_CSGameRules_RestartRound, "@CSGameRules_RestartRound_Pre", .post = false);
    RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd,"@CSGameRules_OnRoundFreezeEnd", .post = true);

    rh_get_mapname(szMapname, charsmax(szMapname));

    bind_pcvar_string(get_cvar_pointer("amx_nextmap"), nextmap, sizeof(nextmap));
    bind_pcvar_num(get_cvar_pointer("mp_maxrounds"), maxrounds);
}

@CSGameRules_RestartRound_Pre() {
    g_iRound = get_member_game(m_bCompleteReset) ? 0 : g_iRound + 1;
}

@CSGameRules_OnRoundFreezeEnd() {
    new message[191];
    formatex(message, sizeof(message), "^4[Respect Gaming 2] [^1Round: ^3%d^1/^3%d ^1| Map: ^3%s ^1| ^1Nextmap: ^3%s ^1| ^1Players: ^3%i^1/^3%i^4]", g_iRound, maxrounds, szMapname, nextmap, get_playersnum(), get_member_game(m_nMaxPlayers));

    client_print_color(0, print_team_default, message);
}
