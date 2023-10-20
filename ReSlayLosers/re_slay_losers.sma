#include <amxmodx>
#include <reapi>

new g_iMaxClients;

public plugin_init() {
    register_plugin("[ReAPI] Slay Loosers", "1.0", "mIDnight");
    RegisterHookChain(RG_RoundEnd, "RoundEnd", true);
    g_iMaxClients = get_member_game(m_nMaxPlayers);
}

public RoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay) {
    switch(event) {
        case ROUND_TARGET_BOMB, ROUND_VIP_ASSASSINATED, ROUND_CTS_PREVENT_ESCAPE, ROUND_HOSTAGE_NOT_RESCUED, ROUND_VIP_NOT_ESCAPED:
            SlayLosers(2);
        case ROUND_VIP_ESCAPED, ROUND_TERRORISTS_ESCAPED, ROUND_BOMB_DEFUSED, ROUND_TARGET_SAVED, ROUND_ALL_HOSTAGES_RESCUED:
            SlayLosers(1);
    }
}

SlayLosers(team) {
    new szTeam[32], iKilledIndex;
    for(new id = 1; id <= g_iMaxClients; id++) {
        if(is_user_alive(id) && get_member(id, m_iTeam) == team) {
            iKilledIndex = id;
            user_kill(id, 1);
        }   
    }

    if(iKilledIndex) {
        szTeam = (team == 1) ? "Terrorists" : "Counter-Terrorists";
        
        new szMsg[190];
        formatex(szMsg, charsmax(szMsg), "^4[HW] ^3%s ^1has failed complete their objectives!", szTeam);
        message_begin(MSG_ALL, 76);
        write_byte(iKilledIndex);
        write_string(szMsg);
        message_end();
    }   
}
