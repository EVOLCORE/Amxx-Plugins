#include <amxmodx>

new g_iTimer, bool:g_bRoundEnd;

public plugin_init() {
    register_plugin("C4 Timer", "1.1", "mIDnight");
    register_event("HLTV", "eventRoundStart", "a", "1=0", "2=0");
    register_logevent("eventRoundEnd", 2, "1=Round_End");
    register_event("BombDrop", "eventBombPlanted", "a", "4=1");   
    g_iTimer = get_pcvar_num(get_cvar_pointer("mp_c4timer"));
}

public eventRoundStart() {
    g_bRoundEnd = false;
}

public eventRoundEnd() {
    g_bRoundEnd = true;
}

public eventBombPlanted() {
    if(g_iTimer && !g_bRoundEnd) 
        set_task(0.5, "ShowTimer");
}

public ShowTimer() {
    message_begin(MSG_BROADCAST, get_user_msgid("ShowTimer"));
    message_end();
    message_begin(MSG_BROADCAST, get_user_msgid("RoundTime"));
    write_short(g_iTimer);
    message_end();
}
