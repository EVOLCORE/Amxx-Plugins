#include <amxmodx>
#include <fakemeta>

new bool:g_bUseScroll[MAX_PLAYERS]
new Float:g_fDuckTime[MAX_PLAYERS]

public plugin_init() {
	register_plugin("Anti Scroll", "1.0", "mIDnight")
	
	register_forward(FM_CmdStart, "fw_CmdStart", 1)
}

public fw_CmdStart(id, pUC, seed) {
	if(is_user_alive(id)) {
		static iButton; iButton = get_uc(pUC, UC_Buttons)
		if(iButton & IN_DUCK) {
			if(g_bUseScroll[id]) {
				g_fDuckTime[id] = get_gametime()
				g_bUseScroll[id] = false
			}
		}
		else
		{
			if(!g_bUseScroll[id])
			{
				static Float:fGameTime; fGameTime = get_gametime()
				if(fGameTime - g_fDuckTime[id] < 0.02) // 0.015, 0.02, 0.03
				{
					static Float:fVelocity[3]
					
					pev(id, pev_velocity, fVelocity)
					
					fVelocity[0] = fVelocity[0] / 2
					fVelocity[1] = fVelocity[1] / 2
					
					set_pev(id, pev_velocity, fVelocity)
					set_pev(id, pev_bInDuck, false)
				}
			}
			g_bUseScroll[id] = true
		}
	}
	return PLUGIN_CONTINUE
}
