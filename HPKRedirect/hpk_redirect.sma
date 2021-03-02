#include <amxmodx> 

new g_Ping[33], g_Samples[33];

public plugin_init() {
	register_plugin("HPK redirect", "1.0", "mIDnight");
	
	register_cvar("amx_hpk_ping","120");
	register_cvar("amx_hpk_tests","1");
	register_cvar("amx_hpk_immunity","1")
	register_cvar("amx_hpk_delay","20");
}

public client_putinserver(id) {
	if(is_user_bot(id) || get_user_flags(id) & ADMIN_IMMUNITY) {
		return;
	}

	g_Ping[id] = 0;
	g_Samples[id] = 0;

	new param[1];
	param[0] = id;

	set_task(float(get_cvar_num("amx_hpk_delay")), "@taskSetting", id, param , 1);
} 

@taskSetting(param[]) {
	set_task(float(get_cvar_num("amx_hpk_tests")) , "@checkPing" , param[0] , param , 1 , "b");
}

@checkPing(param[]) {
	new id = param[0];

	new p, l;

	get_user_ping(id, p, l);

	g_Ping[id] += p;
	++g_Samples[id];

	if ( (g_Samples[id] > get_cvar_num("amx_hpk_tests")) && (g_Ping[id] / g_Samples[id] > get_cvar_num("amx_hpk_ping")) ) {
		client_cmd(id, "Connect 87.98.189.86:27015");
	}
}

public client_disconnected(id) {
	remove_task(id);
}
