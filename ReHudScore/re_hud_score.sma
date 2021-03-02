#include <amxmodx>
#include <reapi>

public plugin_init() {
	register_plugin("[ReAPI] Hud Score", "1.0", "mIDnight");
	RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn",true);
//	set_task(1.00, "@CBasePlayer_Spawn", _, _, _, "b");   // uncomment to stay permanently
}

@CBasePlayer_Spawn(id) {
	set_dhudmessage(255, 255, 255, -1.0, 0.0, 1, 6.0, 12.0)
	show_dhudmessage(id, "--> 87.98.189.86:27015 <--^n[%i]^n%i [Players] %i",get_member_game(m_iNumCTWins)+get_member_game(m_iNumTerroristWins)+1,get_member_game(m_iNumTerrorist),get_member_game(m_iNumCT))
	set_dhudmessage(255, 0, 0, -1.0, 0.0, 3, 6.0, 12.0)
	show_dhudmessage(id, "^n%i TE                ",get_member_game(m_iNumTerroristWins))
	set_dhudmessage(0, 0, 255, -1.0, 0.0, 3, 6.0, 12.0)
	show_dhudmessage(id, "^n                CT %i",get_member_game(m_iNumCTWins))
}
