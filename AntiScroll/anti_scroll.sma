#include <amxmodx>
#include <fakemeta>

new bool:g_bUseScroll[MAX_PLAYERS];

public plugin_init() {
    register_plugin("Anti Scroll", "1.0", "mIDnight");
    
    register_forward(FM_CmdStart, "@fw_CmdStart", 1);
}

@fw_CmdStart(id, pCmd, seed) {
    if (!is_user_alive(id)) return PLUGIN_CONTINUE;

    new iButton = get_uc(pCmd, UC_Buttons);

    if (iButton & IN_DUCK) {
        g_bUseScroll[id] = true;
    } else if (g_bUseScroll[id]) {
        g_bUseScroll[id] = false;
        
        new Float:fVelocity[3];
        pev(id, pev_velocity, fVelocity);
        fVelocity[0] *= 0.5; // Halve the X-axis velocity
        fVelocity[1] *= 0.5; // Halve the Y-axis velocity
        set_pev(id, pev_velocity, fVelocity);
        set_pev(id, pev_bInDuck, false);
    }
    
    return PLUGIN_CONTINUE;
}
