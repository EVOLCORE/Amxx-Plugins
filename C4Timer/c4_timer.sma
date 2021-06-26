#include <amxmodx>

new g_mShowTimer, g_mRoundTime;
new g_pcvTimer, g_iTimer;
new bool:g_bRoundEnd;

public plugin_init() {
	register_plugin("C4 Timer", "1.1", "mIDnight");
	
	register_event("HLTV", "eventRoundStart", "a", "1=0", "2=0");
	register_logevent("eventRoundEnd", 2, "1=Round_End");
	register_event("BombDrop", "eventBombPlanted", "a", "4=1");   
	
	g_mShowTimer= get_user_msgid("ShowTimer");
	g_mRoundTime= get_user_msgid("RoundTime");
	g_pcvTimer  = get_cvar_pointer("mp_c4timer");
	g_iTimer = get_pcvar_num(g_pcvTimer);
}

public eventRoundStart() {
	g_iTimer = get_pcvar_num(g_pcvTimer);
	g_bRoundEnd = false;
}

public eventRoundEnd()
	g_bRoundEnd = true;
	
public eventBombPlanted() {
	if(g_iTimer) {
		if(!g_bRoundEnd) 
			set_task(0.5, "ShowTimer");
	}
}

public ShowTimer() {
	message_begin(MSG_BROADCAST, g_mShowTimer);
	message_end();

	message_begin(MSG_BROADCAST, g_mRoundTime);
	write_short(g_iTimer);
	message_end();
}
