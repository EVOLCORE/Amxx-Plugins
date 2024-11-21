#include <amxmodx>
#include <reapi>

// Uncomment to use HUD-based timer display instead of the round timer
//#define HUD_TIMER

new iEnt, bool:isBombPlanted = false;
new Float:gExplodeTime, Float:gC4Time;

const TASK_ID_C4_TIMER = 1337;

public plugin_init() {
    register_plugin("[ReAPI] C4 Timer", "0.1.0", "mIDnight");

    RegisterHookChain(RG_PlantBomb, "@PlantBomb_Post", .post = true);
    RegisterHookChain(RG_RoundEnd, "@RoundEnd_Post", .post = true);
    RegisterHookChain(RG_CSGameRules_RestartRound, "@CSGameRules_RestartRound_Post", .post = true);
}

@CSGameRules_RestartRound_Post() {
    resetBombState();
}

@RoundEnd_Post() {
    resetBombState();
}

@PlantBomb_Post() {
    isBombPlanted = true;
    iEnt = GetHookChainReturn(ATYPE_INTEGER);
    gExplodeTime = get_member(iEnt, m_Grenade_flC4Blow);

    startC4TimerTask();
}

public C4TimerTask() {
    if (!isBombPlanted) {
        resetBombState();
        return;
    }

    gC4Time = gExplodeTime - get_gametime();

#if defined HUD_TIMER
    displayHUDTimer();
#else
    displayRoundTimer();
#endif
}

stock startC4TimerTask() {
    set_task(1.0, "C4TimerTask", TASK_ID_C4_TIMER, .flags = "b");
}

stock resetBombState() {
    isBombPlanted = false;

    if (task_exists(TASK_ID_C4_TIMER)) {
        remove_task(TASK_ID_C4_TIMER);
    }
}

stock displayHUDTimer() {
    set_dhudmessage(100, 100, 100, -1.0, 0.83, 0, 1.0, 1.0, 0.01, 0.01);
    show_dhudmessage(0, "The bomb will explode in: [%0.f seconds]", gC4Time);
}

stock displayRoundTimer() {
    message_begin(MSG_BROADCAST, get_user_msgid("ShowTimer"));
    message_end();

    message_begin(MSG_BROADCAST, get_user_msgid("RoundTime"));
    write_short(floatround(gC4Time));
    message_end();
}
