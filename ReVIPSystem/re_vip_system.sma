#pragma semicolon 1

#include <amxmodx>
#include <reapi>

native admin_expired(index);

/* YOU CAN UNDEFINE WHATEVER YOU WANT */
#define VIP_ACCESS ADMIN_LEVEL_H    // VIP ACCESS    
#define DAMAGER                     // DAMAGE THINGS
#define VIP_MODEL                   // IP MODELS
#define STEAM_VIP		            // STEAM WILL BE VIP EVERYTIME IF DEFINE IS ON
#define BONUS_HS        10.0        // The amount of added HP per kill in the head (set to 0.0 if you don't need to add, since you can't comment out)
#define BONUS_NORMAL    0.0         // The number of added HP per kill (set to 0.0 if you do not need to add, since you cannot comment out)
#define MAX_HP          100.0       // Max HP
#define BLOCK_MAPS	"awp_", "aim_", "fy_", "35hp", "$"

new const g_szTag[] = "HW";         // Chat tag(prefix)

/* Vip Models */
#if defined VIP_MODEL
new const g_szModelNames[][] = {
	"winter_vip_t",   // te model
	"winter_vip_ct"    // ct model
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
g_iPistol[MAX_CLIENTS + 1], bool:g_blWeapon[MAX_CLIENTS + 1], g_iRound, mp_buytime,
g_blBuyzone;

new HookChain:g_iHC_Spawn_Post;

public plugin_init() {
    register_plugin("[ReAPI] VIP system", "0.0.1", "mIDnight");

    #if defined DAMAGER
        register_clcmd("say /damager", "@clcmd_damager");
        register_clcmd("say_team /damager", "@clcmd_damager");
    #endif

    register_clcmd("say /vipmenu", "@clcmd_vipmenu");
    register_clcmd("say_team /vipmenu", "@clcmd_vipmenu");

    register_clcmd("say /wantvip", "@clcmd_wantvip");
    register_clcmd("say_team /wantvip", "@clcmd_wantvip");

    RegisterHookChain(RG_CSGameRules_RestartRound, "@CSGameRules_RestartRound_Pre", .post = false);
    RegisterHookChain(RG_CSGameRules_RestartRound, "@CSGameRules_RestartRound_Post", .post = true);
    g_iHC_Spawn_Post = RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Post", .post = true);
    EnableHookChain(g_iHC_Spawn_Post);
    RegisterHookChain(RG_CBasePlayer_Killed, "@CBasePlayer_Killed_Post", .post = true);

    #if defined DAMAGER
        RegisterHookChain(RG_CBasePlayer_TakeDamage, "@CBasePlayer_TakeDamage_Post", .post = true);
        g_iHudSyncObj = CreateHudSyncObj();
    #endif

    #if defined VIP_MODEL
        RegisterHookChain(RG_CBasePlayer_SetClientUserInfoModel, "@CBasePlayer_SetClientUserInfoModel_Pre", .post = false);
    #endif

    if(!get_member_game(m_bMapHasVIPSafetyZone)) {
        register_message(get_user_msgid("ScoreAttrib"), "@message_ScoreAttrib");
    }

    mp_buytime = get_cvar_pointer("mp_buytime");
}

#if defined VIP_MODEL
public plugin_precache() {
	for(new i = 0; i < sizeof(g_szModelNames); i++) {
		precache_model(fmt("models/player/%s/%s.mdl", g_szModelNames[i], g_szModelNames[i]));
	}
}
#endif

public plugin_cfg() {
	new map[32]; rh_get_mapname(map, charsmax(map));
	new BlockMap[][] = { BLOCK_MAPS };
	for(new i; i < sizeof BlockMap; i++)
	if(containi(map, BlockMap[i]) != -1) {
		DisableHookChain(g_iHC_Spawn_Post);
	}
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
    if(!rvs_is_user_vip(pPlayer)) {
        return PLUGIN_HANDLED;
    }

    new iExp = admin_expired(pPlayer);
    new iMenu;

    if(iExp > 0) {
        iExp -= get_systime();
 
        if(iExp > 0) {
            iMenu = menu_create(fmt("\y|\rHyperWorld\y| VIP Menu: \r[\y%d day.\r]", iExp / 86400), "@clcmd_vipmenu_handler");
        }
        else {
            iMenu = menu_create(fmt("\y|\rHyperWorld\y| VIP Menu: \r[\y%dh. %dmin.\r]", iExp / 3600, ((iExp / 60) - (iExp / 3600) * 60)), "@clcmd_vipmenu_handler");
        }
    }
    else if(iExp == 0) {
        iMenu = menu_create("\y\y|\rHyperWorld\y| VIP Menu: \r[\ylifetime\r]", "@clcmd_vipmenu_handler");
    }
    else {
#if defined STEAM_VIP
        iMenu = menu_create(fmt("\y\y|\rHyperWorld\y| FREE VIP Menu: %s", is_user_steam(pPlayer) ? "\w(\rSteam\w)" : "\w(\r22\w-\r10\w)"), "@clcmd_vipmenu_handler");
#else
        iMenu = menu_create("\y\y|\rHyperWorld\y| FREE VIP Menu: \w(\r22\w-\r10\w)", "@clcmd_vipmenu_handler");
#endif
    }

    menu_additem(iMenu, "\yTake \wAK47");
    menu_additem(iMenu, "\yTake \wM4A1^n");

    menu_additem(iMenu, fmt("\yPistol on spawn \r[\y%s\r]", g_iPistol[pPlayer] == 0 ? "Deagle" : g_iPistol[pPlayer] == 1 ? "USP" : "Glock"));

    #if defined DAMAGER
    menu_additem(iMenu, fmt("\yDamager \r[\y%s\r]", g_iSwitchDmg[pPlayer] ? "Enabled" : "Disabled"));
    #endif

    menu_display(pPlayer, iMenu);
    return PLUGIN_HANDLED;
}

@clcmd_vipmenu_handler(const pPlayer, const iMenu, const iItem) {
    if(!rvs_is_user_vip(pPlayer)) {
        menu_destroy(iMenu);
        return PLUGIN_HANDLED;
    }

    switch(iItem) {
        case 0: {
            rg_give_item(pPlayer, "weapon_ak47", GT_REPLACE);
            rg_set_user_bpammo(pPlayer, WEAPON_AK47, 90);
            g_blWeapon[pPlayer] = true;
        }
        case 1: {
            rg_give_item(pPlayer, "weapon_m4a1", GT_REPLACE);
            rg_set_user_bpammo(pPlayer, WEAPON_M4A1, 90);
            g_blWeapon[pPlayer] = true;
        }
        case 2: {
            g_iPistol[pPlayer] >= 2 ? (g_iPistol[pPlayer] = 0) : g_iPistol[pPlayer]++;
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

#if defined DAMAGER
@clcmd_damager(const pPlayer) {
    if(!rvs_is_user_vip(pPlayer)) {
        return PLUGIN_HANDLED;
    }

    g_iSwitchDmg[pPlayer] = !g_iSwitchDmg[pPlayer];
    client_print_color(pPlayer, pPlayer, "^4[%s] ^1You ^4%s ^1damager for yourself", g_szTag, g_iSwitchDmg ? "Enabled" : "Disabled");
    return PLUGIN_HANDLED;
}
#endif

@clcmd_wantvip(const pPlayer) {
    show_motd(pPlayer, "/addons/amxmodx/configs/want_vip.html");
    return PLUGIN_HANDLED;
}

@CSGameRules_RestartRound_Pre() {
	if(get_member_game(m_bCompleteReset)) {
		g_iRound = 0;
	}
	g_iRound++;
	g_blBuyzone = false;
	arrayset(g_blWeapon, false, sizeof g_blWeapon);
}

@CSGameRules_RestartRound_Post() {
    if(g_iRound < VIPROUND) {
        return;
    }

    remove_task(1337);
    set_task(get_pcvar_float(mp_buytime) * 60.0, "@OffBuyzone", 1337);
}

@OffBuyzone() {
    g_blBuyzone = true;
    show_menu(0, 0, "");
}

@CBasePlayer_Spawn_Post(const pPlayer) {
    if(get_member(pPlayer, m_bJustConnected)) {
        return;
    }

    if(g_iRound >= ROUND_NADES) {
        rg_give_item(pPlayer, "weapon_hegrenade", GT_APPEND);
        rg_give_item(pPlayer, "weapon_flashbang", GT_APPEND);
    }
    if(g_iRound >= ROUND_ARMOR) {
        rg_set_user_armor(pPlayer, 100, ARMOR_VESTHELM);
    }
    if(g_iRound >= ROUND_DEFUSE && get_member(pPlayer, m_iTeam) == TEAM_CT) {
        rg_give_defusekit(pPlayer, true);
    }

    switch(g_iPistol[pPlayer]) {
        case 0: { rg_give_item(pPlayer, "weapon_deagle", GT_REPLACE); rg_set_user_bpammo(pPlayer, WEAPON_DEAGLE, 35); }
        case 1: { rg_give_item(pPlayer, "weapon_usp", GT_REPLACE); rg_set_user_bpammo(pPlayer, WEAPON_USP, 100); }
        case 2: { rg_give_item(pPlayer, "weapon_glock18", GT_REPLACE); rg_set_user_bpammo(pPlayer, WEAPON_GLOCK18, 120); }
    }

    if(g_iRound >= VIPROUND && rvs_is_user_vip_no_text(pPlayer)) {
        @clcmd_vipmenu(pPlayer);
    }
}

@CBasePlayer_Killed_Post(const pVictim, pAttacker) {
	if(!is_user_alive(pAttacker) || !rvs_is_user_vip_no_text(pAttacker) || pVictim == pAttacker) {
		return;
	}

	new Float:oldHP = get_entvar(pAttacker, var_health);
	new Float:newHP = floatclamp(oldHP + (get_member(pVictim, m_bHeadshotKilled) ? BONUS_HS : BONUS_NORMAL), 0.0, MAX_HP);
	set_entvar(pAttacker, var_health, newHP);
}

#if defined DAMAGER
@CBasePlayer_TakeDamage_Post(const pVictim, iInflictor, pAttacker, Float:flDamage, bitDamageType) {
    if(!is_user_connected(pAttacker) || !g_iSwitchDmg[pAttacker]) {
        return;
    }
    if(pAttacker == pVictim || !rg_is_player_can_takedamage(pVictim, pAttacker)) {
        return;
    }

    static iDamageCoordPos[MAX_CLIENTS + 1];
    static const Float: iDamageCoords[][] = { {0.50, 0.43}, {0.55, 0.45}, {0.57, 0.50}, {0.55, 0.55}, {0.50, 0.57}, {0.45, 0.55}, {0.43, 0.50}, {0.45, 0.45} };

    if(rvs_is_user_vip_no_text(pAttacker)) {
        set_hudmessage(0, 144, 200, iDamageCoords[iDamageCoordPos[pAttacker]][0], iDamageCoords[iDamageCoordPos[pAttacker]][1], _, _, 1.0);
        ShowSyncHudMsg(pAttacker, g_iHudSyncObj, "%.0f", flDamage);
    }

    iDamageCoordPos[pAttacker]++;

    if(iDamageCoordPos[pAttacker] == sizeof(iDamageCoords)) {
        iDamageCoordPos[pAttacker] = 0;
    }
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
#if defined STEAM_VIP
    if(~get_user_flags(pPlayer) & ADMIN_LEVEL_H && !g_blNightMode && !is_user_steam(pPlayer)) {
        client_print_color(pPlayer, pPlayer, "^4[%s] ^1You are not authorized to use this menu.", g_szTag);
        return false;
    }
#else
    if(~get_user_flags(pPlayer) & ADMIN_LEVEL_H && !g_blNightMode) {  //Vip Access
        client_print_color(pPlayer, pPlayer, "^4[%s] ^1You are not authorized to use this menu.", g_szTag);
        return false;
    }
#endif

    if(!is_user_alive(pPlayer)) {
        client_print_color(pPlayer, pPlayer, "^4[%s] ^1You must be alive to use this menu.", g_szTag);
        return false;
    }
    if(!g_iRound) {
        client_print_color(pPlayer, pPlayer, "^4[%s] ^1Warm-up round. It is forbidden to use this menu.", g_szTag);
        return false;
    }
    if(g_blWeapon[pPlayer]) {
        client_print_color(pPlayer, pPlayer, "^4[%s] ^1You have already picked up a weapon in this round.", g_szTag);
        return false;
    }
    if(g_iRound < VIPROUND) {
        client_print_color(pPlayer, pPlayer, "^4[%s] ^1VIP Weapons are avaiable after ^4%i ^1rounds.", g_szTag, VIPROUND);
        return false;
    }
    if(g_blBuyzone) {
        client_print_color(pPlayer, pPlayer, "^4[%s] ^1You cannot use this menu after buyzone expired", g_szTag);
    }
    return true;
}

bool:rvs_is_user_vip_no_text(const pPlayer) {
#if defined STEAM_VIP
    return bool:(get_user_flags(pPlayer) & ADMIN_LEVEL_H || g_blNightMode || is_user_steam(pPlayer));
#else
    return bool:(get_user_flags(pPlayer) & ADMIN_LEVEL_H || g_blNightMode);
#endif
}
