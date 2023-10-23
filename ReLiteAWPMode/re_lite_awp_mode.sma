#include <amxmodx>
#include <reapi>

public plugin_init() {
    register_plugin("[ReAPI] AWP Mode", "0.0.1", "mIDnight");

    RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Post", .post = true);
}

@CBasePlayer_Spawn_Post(pPlayer) {
    if (get_member(pPlayer, m_bJustConnected)) {
        return;
    }

    rg_remove_all_items(pPlayer);
    rg_give_item(pPlayer, "weapon_knife");
    rg_give_item(pPlayer, "weapon_awp");
    rg_set_user_bpammo(pPlayer, WEAPON_AWP, 30);
}

public plugin_cfg() {
    new g_szConfigDir[64];
    get_localinfo("amxx_configsdir", g_szConfigDir, charsmax(g_szConfigDir));

    new szConfig[64];
    formatex(szConfig, charsmax(szConfig), "%s/awp_mode.cfg", g_szConfigDir);
    server_cmd("exec %s", szConfig);
    server_exec();
}
