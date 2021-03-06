#include <amxmodx>

public plugin_init() {
	register_plugin("Simple hud adv", "1.0", "mIDnight");
	set_task(2.0, "@hud_info", _, _, _, "b");
}

@hud_info(id) {
	if(get_playersnum() > 0) {
		set_dhudmessage(255, 255, 255, -1.0, 0.0, 0, 6.0, 10000.0)
		show_dhudmessage(id, "ADD IP: 87.98.189.86:27015")
	}
}
