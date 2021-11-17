#include <amxmodx>
#include <reapi>

#if AMXX_VERSION_NUM < 183
	#include <colorchat>
#endif

#define VIP_ACCESS      ADMIN_LEVEL_H      // VIP access flag (default flag "t" ADMIN_LEVEL_H)
#define PREFIX          "^4[Element]^1"    // Prefix before messages (^ 1 - yellow ^ 3 - command color ^ 4 - green)
#define NIGHT_MODE			               // Night mode free vip
#define VIPROUND        3                  // From which round you can open the VIP menu
#define BONUS_HS        10.0               // The amount of added HP per kill in the head (set to 0.0 if you don't need to add, since you can't comment out)
#define BONUS_NORMAL    0.0                // The number of added HP per kill (set to 0.0 if you do not need to add, since you cannot comment out)
#define MAX_HP          100.0              // Max HP
#define VIPAUTOGRENADE                     // Give grenades at the beginning of each round (comment if not necessary)
#define ROUND_NADES     1                  // From which round to give grenades (if VIPAUTOGRENADE is uncommented, otherwise it makes no sense to change it will not work)
#define ROUND_ARMOR     2                  // From which round to give armor
#define ROUND_DEFUSE    2                  // From which round to give defuse kit
#define AUTOVIPMENU                        // Automatically open the VIP menu at the beginning of the round (disabled by default)
#define VIPTAB                             // Show VIP status in the table on the tab (comment if not necessary)
#define ADMIN_LOADER                       // Deadline to end with Admin Loader by mIDnight (comment if not needed)
#define DAMAGER                            // damager ladder (comment if necessary)
#define DAMAGER_MENU                       // Damager switch off/on from VIP menu

#if defined NIGHT_MODE
#define START_HOUR 		22	   // Hour night mode start
#define END_HOUR 		10	  // Hour night mode end

new bool:IsNightMode;
#endif

#define IsPlayer(%1)  (1 <= %1 <= g_iMaxPlayers)

#if defined ADMIN_LOADER
	native admin_expired(index);
#endif

#if defined DAMAGER
#define HUD_ATTACKER_COLOR 0, 144, 200
#define HUD_VICTIM_COLOR 200, 0, 0
const Float: HUD_HOLD_TIME	=	1.0
const RESET_VALUE =	0

new const Float: DAMAGE_COORDS[][] = { {0.50, 0.43}, {0.55, 0.45}, {0.57, 0.50}, {0.55, 0.55}, {0.50, 0.57}, {0.45, 0.55}, {0.43, 0.50}, {0.45, 0.45} }

new g_hHudSyncObj
new const POS_X	=	0
new const POS_Y	=	1
new g_iDamageCoordPos[MAX_PLAYERS + 1]
#endif

new g_iRoundCount;
new iPistol[MAX_CLIENTS+1];
new bool:g_bUseWeapon[33];
new bool:g_bUserVip[33];
new g_isSwitchDmg[33] = {0, ...};
new g_szText[3] = "";

public plugin_init() {
	register_plugin("[ReAPI] Vip System", "1.2", "mIDnight");
#if defined DAMAGER
	register_clcmd("say /damager", "@clcmd_SwitchDmg"); register_clcmd("say_team /damager", "@clcmd_SwitchDmg");
#endif
	register_clcmd("say /vipmenu", "@clcmd_VipMenu"); register_clcmd("say_team /vipmenu", "@clcmd_VipMenu");
	register_clcmd("say /wantvip", "@clcmd_WantVip"); register_clcmd("say_team /wantvip", "@clcmd_WantVip");
	register_clcmd("say", "@hook_say"); register_clcmd("say_team", "@hook_say");
#if defined DAMAGER_MENU
	register_menucmd(register_menuid("@VipMenu"), MENU_KEY_0|MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4, "@VipMenuHandler");
#else
	register_menucmd(register_menuid("@VipMenu"), MENU_KEY_0|MENU_KEY_1|MENU_KEY_2|MENU_KEY_3, "@VipMenuHandler");
#endif
	RegisterHookChain(RG_CSGameRules_RestartRound, "@CSGameRules_RestartRound_Pre", .post = false);
	RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Post", .post = true);
	RegisterHookChain(RG_CBasePlayer_Killed, "@CBasePlayer_Killed_Post", .post = true);
#if defined DAMAGER
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "@CBasePlayer_TakeDamage_Post", .post = true);
	g_hHudSyncObj = CreateHudSyncObj()
#endif
	new iMap_Name[32], iMap_Prefix[][] = { "awp_", "fy_", "35hp", "$" }
	get_mapname(iMap_Name, charsmax(iMap_Name))
	for(new i; i < sizeof(iMap_Prefix); i++) {
		if(containi(iMap_Name, iMap_Prefix[i]) != -1)
		pause("ad")
	}
#if defined VIPTAB
	if(!get_member_game(m_bMapHasVIPSafetyZone)) {
		register_message(get_user_msgid("ScoreAttrib"), "@msgScoreAttrib");
	}
#endif
}

#if defined VIPTAB
	@msgScoreAttrib() {
	if(isUserVip(get_msg_arg_int(1)) && !get_msg_arg_int(2)) {
		set_msg_arg_int(2, ARG_BYTE, (1<<2));
	}
}
#endif

@CSGameRules_RestartRound_Pre() {
	if(get_member_game(m_bCompleteReset)) {
		g_iRoundCount = 0;
	}
	g_iRoundCount++;
	arrayset(g_bUseWeapon, false, sizeof g_bUseWeapon);
}

#if defined NIGHT_MODE
public OnConfigsExecuted() {
	new __hour; time(__hour);	IsNightMode = bool:(__hour > START_HOUR || __hour < END_HOUR);
}
#endif

public client_putinserver(id) {
#if defined DAMAGER
	if(id > 0 || id < 33) {
		new sUserInfo[16]; get_user_info(id, "_damager", sUserInfo, charsmax(sUserInfo));
		if(sUserInfo[0] && equal(sUserInfo, "off")) g_isSwitchDmg[id] = false;
		else g_isSwitchDmg[id] = true;
	}
	#endif
}

@CBasePlayer_Killed_Post(const iVictim, iAttacker) {
	if(!isUserVip(iAttacker) || iVictim == iAttacker) {
		return;
	}
	
	new Float:oldHP = get_entvar(iAttacker, var_health);
	new Float:newHP = floatclamp(oldHP + (get_member(iVictim, m_bHeadshotKilled) ? BONUS_HS : BONUS_NORMAL), 0.0, MAX_HP);
	set_entvar(iAttacker, var_health, newHP);
}

#if defined DAMAGER
@CBasePlayer_TakeDamage_Post(const iVictim, iInflictor, iAttacker, Float:fDamage, bitDamageType) {
	if(!(g_isSwitchDmg[iAttacker] == g_isSwitchDmg[iVictim]) || fDamage < 1.0) return;
	if(rg_is_player_can_takedamage(iAttacker, iVictim)) {

		new iPos = ++g_iDamageCoordPos[iAttacker]
	
		if(iPos == sizeof(DAMAGE_COORDS)) {
			iPos = g_iDamageCoordPos[iAttacker] = RESET_VALUE
		}

		if(isUserVip(iAttacker)) {
			set_hudmessage(HUD_ATTACKER_COLOR, DAMAGE_COORDS[iPos][POS_X], DAMAGE_COORDS[iPos][POS_Y], _, _, HUD_HOLD_TIME)
			ShowSyncHudMsg(iAttacker, g_hHudSyncObj, "%.0f", fDamage)
		}

		if(isUserVip(iVictim)) {
			set_hudmessage(HUD_VICTIM_COLOR, DAMAGE_COORDS[iPos][POS_X], DAMAGE_COORDS[iPos][POS_Y], _, _, HUD_HOLD_TIME)
			ShowSyncHudMsg(iVictim, g_hHudSyncObj, "%.0f", fDamage)
		}	
	}	
}
#endif

@CBasePlayer_Spawn_Post(id) {
    if(!is_user_alive(id)) {
        return 0;
    }
    if(isUserVip(id)) { 
        g_bUserVip[id] = true;
    } else { 
        return g_bUserVip[id] = false;
    }	
#if defined VIPAUTOGRENADE
    if(g_iRoundCount >= ROUND_NADES) {
        rg_give_item(id, "weapon_hegrenade", GT_APPEND);
        rg_give_item(id, "weapon_flashbang", GT_APPEND);
    }
#endif
    switch(iPistol[id]) {
        case 0: { rg_give_item(id, "weapon_deagle", GT_REPLACE); rg_set_user_bpammo(id, WEAPON_DEAGLE, 35); }
        case 1: { rg_give_item(id, "weapon_usp", GT_REPLACE); rg_set_user_bpammo(id, WEAPON_USP, 100); }
        case 2: { rg_give_item(id, "weapon_glock18", GT_REPLACE); rg_set_user_bpammo(id, WEAPON_GLOCK18, 120); }
    }
    if(g_iRoundCount >= ROUND_ARMOR) {
        rg_set_user_armor(id, 100, ARMOR_VESTHELM);
    }
    if(g_iRoundCount >= ROUND_DEFUSE) {
        new TeamName:team = get_member(id, m_iTeam);
        if(team == TEAM_CT) {
            rg_give_defusekit(id, true);
        }
    }
#if defined AUTOVIPMENU
    return @clcmd_VipMenu(id);
#else
    return 0;
#endif
}

@hook_say(id) {
	static szMsg[128];
	read_args(szMsg, 127);
	remove_quotes(szMsg);
	if(szMsg[0] != '/') {
		return 0;
	}
	static const szChoosedWP[][] = { "/ak47", "/m4a1" };
	for(new i; i < sizeof szChoosedWP; i++) {
		if(!strcmp(szMsg, szChoosedWP[i])) {
			if(!isAllowToUse(id)) { 
				break;
			}
			return @VipMenuHandler(id, i);
		}
	}
	return 0;
}

@clcmd_VipMenu(id) {
	if(!isAllowToUse(id)) {
		return 0;
	}
	static szMenu[512], iLen, iKey;
	iKey = MENU_KEY_0;
#if defined ADMIN_LOADER
	new iExp = admin_expired(id);
	if(iExp > 0) {
		new sysTime = get_systime();
		if(iExp - sysTime > 0) {
			if((iExp - sysTime) / 86400 > 0) {
				iLen = formatex(szMenu, charsmax(szMenu), "\y|\rElement\y| VIP Menu: \r[\y%d day.\r]^n^n", ((iExp - sysTime) / 86400));
			} else {
				iLen = formatex(szMenu, charsmax(szMenu), "\y|\rElement\y| VIP Menu: \r[\y%dh. %dmin.\r]^n^n", ((iExp - sysTime) / 3600), (((iExp - sysTime) / 60) - (((iExp - sysTime) / 3600) * 60)));
			}
		}
	} else if(iExp == 0) {
		iLen = formatex(szMenu, charsmax(szMenu), "\y\y|\rElement\y| VIP Menu: \r[\ylifetime\r]^n^n");
	} else if(IsNightMode) {
		iLen = formatex(szMenu, charsmax(szMenu), "\y\y|\rElement\y| FREE VIP Menu: \w(\r22\w-\r10\w)^n^n");
	}	
#endif
	iKey |= MENU_KEY_1|MENU_KEY_2;
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1. \wTake \yAK47^n\r2. \wTake \yM4A1^n^n");
	iKey |= MENU_KEY_3;
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3. \wPistol on spawn \r[\y%s\r]^n", iPistol[id] == 0 ? "Deagle" : iPistol[id] == 1 ? "USP" : "Glock");
#if defined DAMAGER_MENU
	iKey |= MENU_KEY_4;
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r4. \wDamager \r[\y%s\r]^n^n", g_isSwitchDmg[id] ? "Enabled" : "Disabled");
#endif
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r0. \wExit");
	show_menu(id, iKey, szMenu, -1, "@VipMenu");
	return PLUGIN_HANDLED;
}

@VipMenuHandler(id, iKey) {
#if defined DAMAGER_MENU
	if(iKey > 4 || g_bUseWeapon[id]) {
		return 0;
	}
#else
	if(iKey > 3 || g_bUseWeapon[id]) {
		return 0;
	}
#endif
	switch(iKey) {
		case 0..1: {
			static const szChoosedBP[] = { 90, 90 };
			static const szChoosedWP[][] = { "weapon_ak47", "weapon_m4a1" };
			g_bUseWeapon[id] = true;
			return give_item_ex(id, szChoosedWP[iKey], szChoosedBP[iKey]);
		}
        case 2: {
			@GivePistol(id);
		}
#if defined DAMAGER_MENU
		case 3: {
			g_isSwitchDmg[id] = (g_isSwitchDmg[id]) ? 0 : 1;
			num_to_str(g_isSwitchDmg[id], g_szText, charsmax(g_szText));
			client_cmd(id, "setinfo _damager %s", g_szText);
			return @clcmd_VipMenu(id);
		}
#endif
	}
	return PLUGIN_HANDLED;
}

stock give_item_ex(id, currWeaponName[], ammoAmount) {
	rg_give_item(id, currWeaponName, GT_REPLACE);
	rg_set_user_bpammo(id, rg_get_weapon_info(currWeaponName, WI_ID), ammoAmount);
	engclient_cmd(id, currWeaponName);
	return PLUGIN_HANDLED;
}

@GivePistol(id) {
	iPistol[id] >= 2 ? (iPistol[id] = 0) : iPistol[id]++;
	@clcmd_VipMenu(id);
	return PLUGIN_HANDLED;
}

bool:isAllowToUse(id) {
	if(!g_bUserVip[id]) {
		client_print_color(id, print_team_default, "%s This command can only be used by a VIP player!", PREFIX);
		return false;
	}
	if(!is_user_alive(id)) {
		client_print_color(id, print_team_default, "%s You must be alive to use this command!", PREFIX);
		return false;
	}
	if(!g_iRoundCount) {
		client_print_color(id, print_team_default, "%s Warm-up round. It is forbidden to use that command!", PREFIX);
		return false;
	}
	if(g_bUseWeapon[id]) {
		client_print_color(id, print_team_default, "%s You've already picked up a weapon this round!", PREFIX);
		return false;
	}
	if(g_iRoundCount < VIPROUND) {
		client_print_color(id, print_team_default, "%s VIP Weapons are available after ^3%d ^1round!", PREFIX, VIPROUND);
		return false;
	}
	return true;
}

@clcmd_WantVip(id) {
   show_motd(id, "/addons/amxmodx/configs/want_vip.html");
}

@clcmd_SwitchDmg(id) {
	if(!isUserVip(id)) {
		client_print_color(id, print_team_default, "%s This command can only be used by a VIP player.", PREFIX);
		return 0;
	}
	g_isSwitchDmg[id] = !g_isSwitchDmg[id];
	if(g_isSwitchDmg[id]) client_cmd(id, "setinfo _damager on");
	else client_cmd(id, "setinfo _damager off");

	client_print_color(id, 0, "%s You ^3%s ^1damager for yourself", PREFIX, g_isSwitchDmg[id] ? "Enabled" : "Disabled");
	return PLUGIN_CONTINUE;
}

stock isUserVip(const id) {
#if defined NIGHT_MODE
	return bool:(get_user_flags(id) & VIP_ACCESS || IsNightMode);
#else
	return bool:(get_user_flags(id) & VIP_ACCESS);
#endif
}