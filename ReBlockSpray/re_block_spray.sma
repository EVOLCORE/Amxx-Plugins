#include <amxmodx>
#include <reapi>

public plugin_init() {
    register_plugin("[ReAPI] Block spray logo", "1.0", "mIDnight")
    RegisterHookChain(RG_CBasePlayer_ImpulseCommands, "@CBasePlayer_ImpulseCommands", .post=false);
}

@CBasePlayer_ImpulseCommands(const id) {
	set_entvar(id, var_impulse, 201);
	return HC_SUPERCEDE;
}
