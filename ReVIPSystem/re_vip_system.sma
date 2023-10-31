#pragma semicolon 1

#include <amxmodx>
#include <reapi>

/* YOU CAN UNDEFINE WHATEVER YOU WANT */
#define VIP_ACCESS      ADMIN_LEVEL_H    // VIP ACCESS
#define ADMIN_LOADER                // ADMIN LOADER SUPPORT
#define DAMAGER                     // DAMAGE THINGS
//#define VIP_MODEL                 // VIP MODELS
#define STEAM_VIP		            // VIP will be free for STEAM players if define is on
#define VAMPIRE                     // GIVE HEALTH PER KILL
#define MAPS_BLOCK                  // MAPS TO BLOCK VIP WORK

#if defined VAMPIRE
    #define BONUS_HS        10.0        // The amount of added HP per kill in the head (set to 0.0 if you don't need to add, since you can't comment out)
    #define BONUS_NORMAL    0.0         // The number of added HP per kill (set to 0.0 if you do not need to add, since you cannot comment out)
    #define MAX_HP          100.0       // Max HP
#endif

#if defined MAPS_BLOCK
    #define BLOCK_MAPS	    "awp_", "aim_", "fy_", "35hp", "$"
#endif    

#if defined STEAM_VIP
    #define rvs_is_user_vip_no_text(%1) (get_user_flags(%1) & VIP_ACCESS || g_blNightMode || is_user_steam(%1))
#else
    #define rvs_is_user_vip_no_text(%1) (get_user_flags(%1) & VIP_ACCESS || g_blNightMode)
#endif

new const g_szTag[] = "HW";         // Chat tag(prefix)

/* Vip Models */
#if defined VIP_MODEL
new const g_szModelNames[][] = {
	"vip_t",   // te model
	"vip_ct"    // ct model
};
#endif

/* Settings */
enum {
    VIPROUND = 3,               // From which round you can open the VIP menu
    ROUND_NADES = 1,            // From which round to give grenades
    ROUND_ARMOR = 2,            // From which round to give armor
    ROUND_DEFUSE = 2,           // From which round to give defuse kit
    START_HOUR = 22,	        // Hour night mode start
    END_HOUR = 10		        // Hour night mode end
}

new g_iHudSyncObj, g_iSwitchDmg[MAX_CLIENTS + 1], bool:g_blNightMode,
g_iPistol[MAX_CLIENTS + 1], bool:g_blWeapon[MAX_CLIENTS + 1], g_iRound, Float:g_flBuyTime;

#if defined MAPS_BLOCK
    new HookChain:g_iHC_Spawn_Post;
#endif    

#if defined ADMIN_LOADER
    native native_Access_GetAccessInfo(id, sPassword[] = "", sAccess[] = "", sDateEnd[] = "", sFullName[] = "", sContacts[] = "");
#endif    

public plugin_init() {
    register_plugin("[ReAPI] VIP system", "0.0.7", "mIDnight");

    register_clcmd("say /vipmenu", "@clcmd_vipmenu");
    register_clcmd("say_team /vipmenu", "@clcmd_vipmenu");

    register_clcmd("say /wantvip", "@clcmd_wantvip");
    register_clcmd("say_team /wantvip", "@clcmd_wantvip");

    RegisterHookChain(RG_CSGameRules_RestartRound, "@CSGameRules_RestartRound_Pre", .post = false);
    RegisterHookChain(RG_CSGameRules_RestartRound, "@CSGameRules_RestartRound_Post", .post = true);

    #if defined MAPS_BLOCK
        g_iHC_Spawn_Post = RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Post", .post = true);
        EnableHookChain(g_iHC_Spawn_Post);
    #else
        RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Post", .post = true);
    #endif

    #if defined VAMPIRE
        RegisterHookChain(RG_CBasePlayer_Killed, "@CBasePlayer_Killed_Post", .post = true);
    #endif    

    #if defined DAMAGER
        RegisterHookChain(RG_CBasePlayer_TakeDamage, "@CBasePlayer_TakeDamage_Post", .post = true);
        g_iHudSyncObj = CreateHudSyncObj();
    #endif

    #if defined VIP_MODEL
        RegisterHookChain(RG_CBasePlayer_SetClientUserInfoModel, "@CBasePlayer_SetClientUserInfoModel_Pre", .post = false);
    #endif

    if (!get_member_game(m_bMapHasVIPSafetyZone)) {
        register_message(get_user_msgid("ScoreAttrib"), "@message_ScoreAttrib");
    }
}

#if defined VIP_MODEL
public plugin_precache() {
	for(new i = 0; i < sizeof(g_szModelNames); i++) {
		precache_model(fmt("models/player/%s/%s.mdl", g_szModelNames[i], g_szModelNames[i]));
	}
}
#endif

public plugin_cfg() {
#if defined MAPS_BLOCK    
    new map[32]; rh_get_mapname(map, charsmax(map));
    new BlockMap[][] = { BLOCK_MAPS };
    for(new i; i < sizeof BlockMap; i++)
    if(containi(map, BlockMap[i]) != -1) {
        DisableHookChain(g_iHC_Spawn_Post);
    }
#endif 

    bind_pcvar_float(get_cvar_pointer("mp_buytime"), g_flBuyTime);
}

#if defined DAMAGER
public client_putinserver(pPlayer) {
    g_iSwitchDmg[pPlayer] = true;
}
#endif

public OnConfigsExecuted() {
    new __hour;
    time(__hour);
    g_blNightMode = bool:(__hour > START_HOUR || __hour < END_HOUR);
}

@clcmd_vipmenu(const pPlayer) {
    if (!rvs_is_user_vip(pPlayer)) {
        return PLUGIN_HANDLED;
    }

    new iMenu, szMenuData[128];

    #if defined ADMIN_LOADER
    new iExp = 0, sDateEnd[128];

    if (native_Access_GetAccessInfo(pPlayer, .sDateEnd = sDateEnd) && !equal(sDateEnd, "lifetime")) {
        iExp = max(parse_time(sDateEnd, "%d:%m:%Y %H:%M:%S") + 86400 - get_systime(), 0);
        formatex(szMenuData, sizeof(szMenuData), "\y|\rHyperWorld\y| VIP Menu: \r[\w%d %s\r]", iExp / 86400, (iExp / 86400 > 1) ? "days" : "day");
    } else {
        formatex(szMenuData, sizeof(szMenuData), "|HyperWorld| VIP Menu: \r[\w%s\r]", (iExp == 0 && is_user_steam(pPlayer)) ? "Lifetime" : (g_blNightMode ? "Free 22-10 hour" : "Steam"));
    }
    #else
    formatex(szMenuData, sizeof(szMenuData), "\y|\rHyperWorld\y| VIP Menu: \r[\w%s\r]", (g_blNightMode ? "Free 22-10 hour" : (is_user_steam(pPlayer) ? "Steam" : "Standard")));
    #endif

    iMenu = menu_create(szMenuData, "@clcmd_vipmenu_handler");

    menu_additem(iMenu, "\yTake \wAK47");
    menu_additem(iMenu, "\yTake \wM4A1^n");
    menu_additem(iMenu, fmt("\yPistol on spawn \y[\r%s\y]", g_iPistol[pPlayer] == 0 ? "Deagle" : g_iPistol[pPlayer] == 1 ? "USP" : "Glock"));

    #if defined DAMAGER
    menu_additem(iMenu, fmt("\yDamager \y[\r%s\y]", g_iSwitchDmg[pPlayer] ? "Enabled" : "Disabled"));
    #endif

    menu_display(pPlayer, iMenu);
    return PLUGIN_HANDLED;
}

@clcmd_vipmenu_handler(const pPlayer, const iMenu, const iItem) {
    if (!rvs_is_user_vip(pPlayer) || !is_user_alive(pPlayer)) {
        menu_destroy(iMenu);
        return PLUGIN_HANDLED;
    }

    switch (iItem) {
        case 0, 1: {
            new szWeaponName[32];
            formatex(szWeaponName, sizeof(szWeaponName), "weapon_%s", (iItem == 0) ? "ak47" : "m4a1");
            UTIL_give_item(pPlayer, szWeaponName, GT_REPLACE, 90);
            g_blWeapon[pPlayer] = true;   
        }
        case 2: {
            g_iPistol[pPlayer] = (g_iPistol[pPlayer] + 1) % 3;
            @clcmd_vipmenu(pPlayer);
        }

        #if defined DAMAGER
        case 3: {
            g_iSwitchDmg[pPlayer] = !g_iSwitchDmg[pPlayer];
            @clcmd_vipmenu(pPlayer);
        }
        #endif
    }
    menu_destroy(iMenu);
    return PLUGIN_HANDLED;
}

@clcmd_wantvip(const pPlayer) {
    show_motd(pPlayer, "http://23.26.247.185/vip/want_vip.html");
    return PLUGIN_HANDLED;
}

@CSGameRules_RestartRound_Pre() {
    g_iRound = get_member_game(m_bCompleteReset) ? 0 : (g_iRound + 1);
    arrayset(g_blWeapon, false, sizeof g_blWeapon);
}

@CSGameRules_RestartRound_Post() {
    if(g_iRound < VIPROUND) {
        return;
    }
}

@CBasePlayer_Spawn_Post(const pPlayer) {
    if (!rvs_is_user_vip_no_text(pPlayer) || get_member(pPlayer, m_bJustConnected) || !is_user_alive(pPlayer)) {
        return;
    }

    if(g_iRound >= ROUND_NADES) {
        UTIL_give_item(pPlayer, "weapon_hegrenade", GT_APPEND, 0);
        UTIL_give_item(pPlayer, "weapon_flashbang", GT_APPEND, 0);
    }
    if(g_iRound >= ROUND_ARMOR) {
        rg_set_user_armor(pPlayer, 100, ARMOR_VESTHELM);
    }
    if(g_iRound >= ROUND_DEFUSE && get_member(pPlayer, m_iTeam) == TEAM_CT) {
        rg_give_defusekit(pPlayer, true);
    }

    switch (g_iPistol[pPlayer]) {
        case 0: UTIL_give_item(pPlayer, "weapon_deagle", GT_REPLACE, 35);
        case 1: UTIL_give_item(pPlayer, "weapon_usp", GT_REPLACE, 100);
        case 2: UTIL_give_item(pPlayer, "weapon_glock18", GT_REPLACE, 120);
    }

    if(g_iRound >= VIPROUND) {
        @clcmd_vipmenu(pPlayer);
    }
}

#if defined VAMPIRE
@CBasePlayer_Killed_Post(const pVictim, pAttacker) {
    if(!is_user_alive(pAttacker) || !rvs_is_user_vip_no_text(pAttacker) || pVictim == pAttacker) {
        return;
    }

    set_entvar(pAttacker, var_health, floatmin(Float:get_entvar(pAttacker, var_health) + (get_member(pVictim, m_bHeadshotKilled) ? BONUS_HS : BONUS_NORMAL), MAX_HP));
}
#endif

#if defined DAMAGER
@CBasePlayer_TakeDamage_Post(const pVictim, iInflictor, pAttacker, Float:flDamage, bitDamageType) {
    if (!is_user_connected(pAttacker) || !g_iSwitchDmg[pAttacker] || pAttacker == pVictim || !rg_is_player_can_takedamage(pVictim, pAttacker)) {
        return;
    }

    static iDamageCoordPos[MAX_CLIENTS + 1];
    static const Float: iDamageCoords[][] = { {0.50, 0.43}, {0.55, 0.45}, {0.57, 0.50}, {0.55, 0.55}, {0.50, 0.57}, {0.45, 0.55}, {0.43, 0.50}, {0.45, 0.45} };

    if (rvs_is_user_vip_no_text(pAttacker)) {
        set_hudmessage(64, 64, 0, iDamageCoords[iDamageCoordPos[pAttacker]][0], iDamageCoords[iDamageCoordPos[pAttacker]][1], _, _, 1.0); //0, 144, 200
        ShowSyncHudMsg(pAttacker, g_iHudSyncObj, "%.0f", flDamage);
    }

    iDamageCoordPos[pAttacker] = (iDamageCoordPos[pAttacker] + 1) % sizeof(iDamageCoords);
}
#endif

#if defined VIP_MODEL
@CBasePlayer_SetClientUserInfoModel_Pre(const pPlayer, infobuffer[], szNewModel[]) {
	if(rvs_is_user_vip_no_text(pPlayer)) {
		SetHookChainArg(3, ATYPE_STRING, g_szModelNames[get_member(pPlayer, m_iTeam) == TEAM_TERRORIST ? 0 : 1]);
	}
}
#endif

@message_ScoreAttrib() {
    new pPlayer = get_msg_arg_int(1);

    if(is_user_alive(pPlayer) && rvs_is_user_vip_no_text(pPlayer)) {
        set_msg_arg_int(2, ARG_BYTE, (1<<2));
    }
}

bool:rvs_is_user_vip(const pPlayer) {
    if (!rvs_is_user_vip_no_text(pPlayer)) {
        client_print_color(pPlayer, pPlayer, "^4[%s] ^1You are not authorized to use this menu.", g_szTag);
        return false;
    }

    if (!is_user_alive(pPlayer)) {
        client_print_color(pPlayer, pPlayer, "^4[%s] ^1You must be alive to use this menu.", g_szTag);
        return false;
    }

    if (!g_iRound) {
        client_print_color(pPlayer, pPlayer, "^4[%s] ^1Warm-up round. It is forbidden to use this menu.", g_szTag);
        return false;
    }

    if (g_blWeapon[pPlayer]) {
        client_print_color(pPlayer, pPlayer, "^4[%s] ^1You have already picked up a weapon in this round.", g_szTag);
        return false;
    }

    if (g_iRound < VIPROUND) {
        client_print_color(pPlayer, pPlayer, "^4[%s] ^1VIP Weapons are available after ^4%i ^1rounds.", g_szTag, VIPROUND);
        return false;
    }

    if(g_flBuyTime == 0.0 || (get_gametime() - Float:get_member_game(m_fRoundStartTime) > (g_flBuyTime * 60))) {
        client_print(pPlayer, print_center, "%0.0f seconds have elapsed.^rYou can't use VIP menu!", g_flBuyTime * 60);
        return false;                                         
    }
    return true;
}

stock UTIL_give_item(const iIndex, const iWeapon[], GiveType:GtState, iAmmount) {
    rg_give_item(iIndex, iWeapon, GtState);

    if(iAmmount)
        rg_set_user_bpammo(iIndex, rg_get_weapon_info(iWeapon, WI_ID), iAmmount);
}
