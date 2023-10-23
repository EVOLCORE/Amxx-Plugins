#include <amxmodx>
#include <reapi>

#define HUDSCORE /* If you don't want the overlay to be clear, put // at the beginning. */

new const iChatTag[] = "^4[HW Competitive]^1";
new iCvars[3], szNextMap[32];

public plugin_init() {
    register_plugin("[REAPI] Competitive mode", "0.0.2", "mIDnight");

    get_cvar_string("amx_nextmap", szNextMap, charsmax(szNextMap));

    RegisterHookChain(RG_RoundEnd, "@RoundEnd_Post", .post = true);
    RegisterHookChain(RG_CSGameRules_RestartRound, "@CSGameRules_RestartRound_Post", .post = false);

    bind_pcvar_num(create_cvar("competitive_swap", "15", _, "In which round should the teams change?", true, 1.0), iCvars[0]);
    bind_pcvar_num(create_cvar("competitive_teamwin", "16", _, "Determines how many rounds will win", true, 1.0), iCvars[1]);
    bind_pcvar_num(create_cvar("competitive_map", "2", _, "1 Restart map after finish match | 2 Changes to nextmap after end match", true, 1.0, true, 2.0), iCvars[2]);

    register_clcmd("chooseteam", "@chooseteam");
}

#if defined HUDSCORE
public client_putinserver(id) {
    set_task(0.5, "@Hud", id + 12383848, .flags = "b");
}

@Hud(Taskid) {
    new id = Taskid - 12383848;
    if(is_user_connected(id)) {
	    set_dhudmessage(255, 255, 255, -1.0, 0.0, 1, 6.0, 12.0)
	    show_dhudmessage(id, "--> HyperWorld Competitive <--^n[%i]^n%i [Players] %i",get_member_game(m_iNumCTWins)+get_member_game(m_iNumTerroristWins)+1,get_member_game(m_iNumTerrorist),get_member_game(m_iNumCT))
	    set_dhudmessage(255, 0, 0, -1.0, 0.0, 3, 6.0, 12.0)
	    show_dhudmessage(id, "^n%i TE                ",get_member_game(m_iNumTerroristWins))
	    set_dhudmessage(0, 0, 255, -1.0, 0.0, 3, 6.0, 12.0)
	    show_dhudmessage(id, "^n                CT %i",get_member_game(m_iNumCTWins))
    }
}
#endif

@chooseteam(const id) {
  if(~get_user_flags(id) & ADMIN_KICK) {
    client_print_color(id, id, "^4[HW]^1 You can't choose team in competitive mode.");
    return PLUGIN_HANDLED;
  }

  return PLUGIN_CONTINUE;
}

@RoundEnd_Post(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay) {
    if(get_member_game(m_iTotalRoundsPlayed)+1 == iCvars[0]) {
        for(new i = 0; i < 3; i++)  {
            client_print_color(0, 0, "%s Round ^3%i ^1swaping teams", iChatTag, iCvars[0]);
        }
    }

    new iTotalWin[2];
    iTotalWin[0] = get_member_game(m_iNumTerroristWins);
    iTotalWin[1] = get_member_game(m_iNumCTWins);

    if(iTotalWin[0] == iCvars[1] || iTotalWin[1] == iCvars[1]) {
        for(new i = 0; i < 3; i++) {
            client_print_color(0, 0, "%s Match has end ^3%s ^1WIN!", iChatTag, iTotalWin[0] == iCvars[1] ? "Terrorists":"Counter-Terrorists");
        }
    }
}

@CSGameRules_RestartRound_Post() {
    if(get_member_game(m_iTotalRoundsPlayed)+1 == iCvars[0]) {
        rg_swap_all_players();
        set_task(0.1, "@Settings", 99865);
    }
    if(get_member_game(m_iNumTerroristWins) == iCvars[1] || get_member_game(m_iNumCTWins) == iCvars[1]) {
        @CheckMap();
    }
}

@CheckMap() {
    switch(iCvars[2]) {
        case 1: {
            set_member_game(m_iNumTerroristWins, 0);
            set_member_game(m_iNumCTWins, 0);
            
            set_pcvar_num(get_cvar_pointer("sv_restart"), 2);
            client_print_color(0, 0, "%s Restarting!", iChatTag);
        }
        case 2: {
            set_task(5.0, "@ChangeToNextMap");
            client_print_color(0,0, "%s Next Map [ ^3%s ^1] rushes!", iChatTag, szNextMap);
        }
    }
}

@ChangeToNextMap() {
    server_cmd("changelevel %s", szNextMap);
}

@Settings() {
    for(new i = 1; i <= MaxClients; i++) {
        if(is_user_connected(i)) {
            rg_round_respawn(i);
            rg_remove_all_items(i);
            rg_add_account(i, 800, AS_SET);
            rg_set_user_armor(i, 0, ARMOR_NONE);
            rg_give_default_items(i);
        }
    }
    remove_task(99865);
}
