#include <amxmodx>
#include <reapi>

#define TIME 63.0

public plugin_init() {
	register_plugin("[ReAPI] Kick random player", "1.0", "mIDnight");
	register_cvar("kick_disable", "0")
	
	set_task(TIME, "@Kick_Random_Player", 0, _, _, "b");
}

@Kick_Random_Player() {
	if(get_cvar_num("kick_disable")) return PLUGIN_HANDLED
	new Players[32], Num_All, Random_ID;
	get_players(Players, Num_All, "chi");
	
	Random_ID = Players[random_num(0, Num_All)];
	
	server_cmd("kick #%d ^"high ping^"", get_user_userid(Random_ID));
	return PLUGIN_HANDLED
}
