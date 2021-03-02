#include <amxmodx>

#define MSG_COLOR 150, 30, 30
#define MSG_POSITION -1.0, 0.34
#define MSG_DURATION -1.3
#define MSG_TEXT "H E A D S H O T"

new g_iObject

public plugin_init() {
    register_plugin("HeadShot HUD", "1.0", "mIDnight")
    register_event("DeathMsg", "@OnPlayerKilled", "a", "3=1")
    g_iObject = CreateHudSyncObj()
}

@OnPlayerKilled() {
    new iAttacker = read_data(1), iVictim = read_data(2)
    
    if(!is_user_connected(iAttacker) || iAttacker == iVictim)
        return

    set_hudmessage(MSG_COLOR, MSG_POSITION, .holdtime = MSG_DURATION)
    ShowSyncHudMsg(iAttacker, g_iObject, MSG_TEXT)
}
