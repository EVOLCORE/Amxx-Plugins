#include <amxmodx>

public plugin_init() {
	register_plugin("Sky changer", "1.1", "mIDnight")
	set_cvar_string("sv_skyname", "waterworld15")
}

public plugin_precache() {
	precache_generic("gfx/env/waterworld15bk.tga")
	precache_generic("gfx/env/waterworld15dn.tga")
	precache_generic("gfx/env/waterworld15ft.tga")
	precache_generic("gfx/env/waterworld15lf.tga")
	precache_generic("gfx/env/waterworld15rt.tga")
	precache_generic("gfx/env/waterworld15up.tga")
}
