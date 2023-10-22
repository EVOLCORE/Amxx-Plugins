#include <amxmodx>
#include <reset_score>

#define register_cmd_list(%0,%1,%2)            for (new i = 0; i < sizeof(%1); i++) register_%0(%1[i], %2)

public plugin_init() {
    register_plugin("[ReAPI] Reset Score", "1.0", "mIDnight");

    new szResetScore[][] = {"say /rs", "say_team /rs", "say /resetscore", "say_team /resetscore", "amx_resetscore"};

    register_cmd_list(clcmd, szResetScore, "@clcmd_resetscore");
}

@clcmd_resetscore(const pPlayer) {
    rh_set_score(pPlayer);

    client_print_color(pPlayer, print_team_default, "^4[HW]^1 You successfully reset your score!");

    return PLUGIN_HANDLED;
}
