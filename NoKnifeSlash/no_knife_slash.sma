#include <amxmodx>
#include <hamsandwich>

new g_pNoslash;

public plugin_init() {
	register_plugin("No knife slash", "1.0", "mIDnight");
	   
	g_pNoslash = register_cvar("kn_noslash", "1");
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "@HamKnifePrimAttack");
}

@HamKnifePrimAttack(iEnt) {
	if(get_pcvar_num(g_pNoslash)) {
		ExecuteHamB(Ham_Weapon_SecondaryAttack, iEnt);
		return HAM_SUPERCEDE;
	}
	return HAM_IGNORED;
}
