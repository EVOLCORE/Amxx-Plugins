#include <amxmodx>

public plugin_init() {
	register_plugin("Simple hud adv", "1.0", "mIDnight");
}	

public client_putinserver(id) {
	set_task(2.5, "@hud_info");
}

@hud_info(id) {
	if(get_playersnum() > 0) {
		set_hudmessage(255, 255, 255, -1.0, 0.0, 1, 6.0, 10000.0)
		show_hudmessage(id, "87.98.189.86:27015")
	}
}	
