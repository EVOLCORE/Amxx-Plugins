#include <amxmodx>
#include <reapi>

//#define ROUNDS_LEFT_HUD                 // Define/Undefine to show how many rounds left at end of round via HUD message.

#if defined ROUNDS_LEFT_HUD
    #define HUD_COLOR 0, 255, 0         // Edit here Rounds left HUD message color
    #define HUD_POSITION -1.0, 0.34     // Edit here Rounds left HUD message position
    #define HUD_DURATION 2.0            // Edit here Rounds left HUD message duration
#endif

#if defined ROUNDS_LEFT_HUD
    #define eventBit(%0) (1 << _:%0)

    const ROUND_EVENTS = eventBit(ROUND_GAME_COMMENCE) | eventBit(ROUND_GAME_RESTART) | eventBit(ROUND_GAME_OVER);
#endif

new g_iRound, maxrounds;

public plugin_init() {
    register_plugin("[ReAPI] Time & Rounds left", "0.0.1", "mIDnight");

    register_clcmd("say roundsleft", "@cmd_roundsleft");
    register_clcmd("say_team roundsleft", "@cmd_roundsleft");

    register_clcmd("say timeleft", "@cmd_timeleft");
    register_clcmd("say_team timeleft", "@cmd_timeleft");

    register_clcmd("say thetime", "@cmd_thetime");
    register_clcmd("say_team thetime", "@cmd_thetime");

    register_clcmd("say currentmap", "@cmd_currentmap");
    register_clcmd("say_team currentmap", "@cmd_currentmap");

    RegisterHookChain(RG_CSGameRules_RestartRound, "@CSGameRules_RestartRound_Pre", .post = false);
#if defined ROUNDS_LEFT_HUD
    RegisterHookChain(RG_RoundEnd, "@RoundEnd_Post", .post = true);
#endif

    bind_pcvar_num(get_cvar_pointer("mp_maxrounds"), maxrounds);
}

@CSGameRules_RestartRound_Pre() {
    g_iRound = get_member_game(m_bCompleteReset) ? 0 : g_iRound + 1;
}

#if defined ROUNDS_LEFT_HUD
@RoundEnd_Post(WinStatus:status, ScenarioEventEndRound:event) {
    new hudMessage[64];
    
    if (eventBit(event) & ROUND_EVENTS == 0 && event != ROUND_NONE) {
        formatex(hudMessage, sizeof(hudMessage), maxrounds <= 0 ? "Rounds left: Unlimited" : "Rounds left: %d", maxrounds <= 0 ? -1 : maxrounds - g_iRound);

        set_hudmessage(HUD_COLOR, HUD_POSITION, .holdtime = HUD_DURATION);
        show_hudmessage(0, "%s", hudMessage);
    }    
    return PLUGIN_HANDLED;
}
#endif

@cmd_roundsleft(pPlayer) {
    new message[192];
    
    formatex(message, sizeof(message), maxrounds <= 0 ? "Rounds left: ^3Unlimited" : "Rounds left: ^3%d", maxrounds <= 0 ? -1 : maxrounds - g_iRound);
    client_print_color(pPlayer, print_team_default, message);
    
    return PLUGIN_HANDLED;
}

@cmd_timeleft(const pPlayer) {
    new message[192];
    new gtimelimit = get_timeleft();

    formatex(message, sizeof(message), get_cvar_float("mp_timelimit") ? "Time left: ^3%d minutes and ^3%d seconds" : "Time limit is not set", (gtimelimit / 60), (gtimelimit % 60));
    client_print_color(pPlayer, print_team_default, message);

    return PLUGIN_HANDLED;
}

@cmd_thetime(const pPlayer) {
    new message[192];
    new ctime[64];
    get_time("%H:%M", ctime, charsmax(ctime));
    new hrs = (str_to_num(ctime[0]) * 10 + str_to_num(ctime[1])) % 12;
    
    formatex(message, sizeof(message), "The current time is: ^3%s %s", ctime, (hrs >= 12) ? "pm" : "am");
    client_print_color(pPlayer, print_team_default, message);

    return PLUGIN_HANDLED;
}

@cmd_currentmap(const pPlayer) {
    new CurrentMap[32];
    rh_get_mapname(CurrentMap, charsmax(CurrentMap));
    new message[192];

    formatex(message, sizeof(message), "The current map is: ^3%s", CurrentMap);
    client_print_color(pPlayer, print_team_default, message);

    return PLUGIN_HANDLED;
}
