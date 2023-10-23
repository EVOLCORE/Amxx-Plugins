#include <amxmodx>
#include <reapi>

#define KILLS_TO_RESTART 3

new totalKills, killCounts[MAX_CLIENTS + 1];

public plugin_init() {
    register_plugin("[ReAPI] CSDM Auto restart", "1.0", "mIDnight");

    RegisterHookChain(RG_CSGameRules_RestartRound, "@CSGameRules_RestartRound", true);
    RegisterHookChain(RG_CBasePlayer_Killed, "@CBasePlayer_Killed", true);
}

@CSGameRules_RestartRound() {
    for (new i = 1; i <= MaxClients; i++)
    killCounts[i] = get_member_game(m_bCompleteReset) ? 0 : killCounts[i];
}

@CBasePlayer_Killed(Victim, Killer) {
    if (is_user_connected(Victim) && is_user_connected(Killer) && Victim != Killer) {
        totalKills++;
        killCounts[Killer]++;

        if (killCounts[Killer] == KILLS_TO_RESTART) {
            new name[32];
            get_user_name(Killer, name, sizeof(name));

            new msg[191];
            formatex(msg, sizeof(msg), "^4[Wagner CSDM] ^1Player ^3%s^1 has reached a total of ^3%d ^1frags.", name, killCounts[Killer]);
            client_print_color(0, print_team_default, msg);

            formatex(msg, sizeof(msg), "^4[Wagner CSDM] ^1Total kills reached: ^3%d", totalKills);
            client_print_color(0, print_team_default, msg);
            
            formatex(msg, sizeof(msg), "^4[Wagner CSDM] ^1Automatically restarting the round.");
            client_print_color(0, print_team_default, msg);

            server_cmd("amx_cvar sv_restart 3");
        }
    }
}
