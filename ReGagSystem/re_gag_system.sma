#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <nvault>

#define ADMIN_GAG    ADMIN_KICK  // Authorized player to gag.
#define DEFAULT_GAG_TIME   120     //default time gag example amx_gag mIDnight and it will auto gag him.

new const szChatTag[] = "^4[Element]";

new const g_szNames[][] = {
	"Player",
	"gam",
	"war",
	".com",
	"koso",
	"~"
};

enum _:IntData {
	iGagTime[MAX_PLAYERS+1],
	iPickPlayer[MAX_PLAYERS+1]
};
new g_int[IntData];

public plugin_init() {
	register_plugin("[ReAPI] Gag System", "1.4", "mIDnight");

	register_dictionary("GagSystem.txt");

	register_clcmd("say /gagmenu", "@clcmd_gagmenu");
	register_clcmd("say !gagmenu", "@clcmd_gagmenu");
	register_clcmd("say .gagmenu", "@clcmd_gagmenu");
	register_clcmd("SetDuration", "@clcmd_settime");
	register_concmd("amx_gag", "@clcmd_gag", ADMIN_GAG, "<name> <time>, gag the player.");
	register_concmd("amx_ungag", "@clcmd_ungag", ADMIN_GAG, "<name>, ungag the player.");
	register_clcmd("say", "@clcmd_say");
	register_clcmd("say_team", "@clcmd_say");

	RegisterHookChain(RG_CSGameRules_CanPlayerHearPlayer, "@CSGameRules_CanPlayerHearPlayer_Pre", .post = false);
	RegisterHookChain(RG_CBasePlayer_SetClientUserInfoName, "@CBasePlayer_SetClientUserInfoName");
}

public client_putinserver(id) {
	new name[32];
	get_user_name(id, name, 31);
	for(new i; i < sizeof(g_szNames); i++) {	
		if(containi(name, g_szNames[i]) != -1) {
			@rename(id);
			return;
		}
	} 
}

@rename(id) {
        server_cmd("amx_nick #%d ^"ElementPlayer^"", get_user_userid(id));
}

@clcmd_say(const id) {
	if(g_int[iGagTime][id] > 0) {
		client_print_color(id, print_team_red, "%L", LANG_PLAYER, "GAG_PLAYER_HAS_GAG", szChatTag, g_int[iGagTime][id]);
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

@clcmd_gagmenu(const id) {
	if(~get_user_flags(id) & ADMIN_GAG) {
		client_print_color(id, print_team_red, "%L", LANG_PLAYER, "GAG_UNAUTHORIZED", szChatTag);
		return;
	}

	new menu = menu_create("\w[\rElement\w] \ySelect player to gag", "@clcmd_gagmenu_handler");

	for(new i = 1; i <= MaxClients; i++) {
		if(!is_user_connected(i) || is_user_bot(i) || get_user_flags(i) & ADMIN_IMMUNITY) {
			continue;
		}
		menu_additem(menu, fmt("%n", i), fmt("%i", i));
	}

	menu_setprop(menu, MPROP_EXITNAME, "\rExit");
	menu_display(id, menu);
}

@clcmd_gagmenu_handler(const id, const iMenu, const iItem) {
	if(iItem == MENU_EXIT) {
		menu_destroy(iMenu);
		return PLUGIN_HANDLED;
	}

	new iData[6], iKey;
	menu_item_getinfo(iMenu, iItem, _, iData, charsmax(iData));
	iKey = str_to_num(iData);

	g_int[iPickPlayer][id] = iKey;
	client_cmd(id, "messagemode SetDuration");

	menu_destroy(iMenu);
	return PLUGIN_HANDLED;
}

@clcmd_settime(const id) {
	if(~get_user_flags(id) & ADMIN_GAG) {
		client_print_color(id, print_team_red, "%L", LANG_PLAYER, "GAG_UNAUTHORIZED", szChatTag);
		return PLUGIN_HANDLED;
	}

	new szArg[32];

	read_args(szArg, charsmax(szArg));
	remove_quotes(szArg);

	if(!(g_int[iPickPlayer][id])) {
		client_print_color(id, print_team_red, "%L", LANG_PLAYER, "GAG_PLAYER_UNSELECTED", szChatTag);
		return PLUGIN_HANDLED;
	}

	new iTime = str_to_num(szArg);

	@GagThePlayer(id, g_int[iPickPlayer][id], iTime);
	return PLUGIN_HANDLED;
}

@clcmd_gag(const id) {
	if(~get_user_flags(id) & ADMIN_GAG) {
		client_print_color(id, print_team_red, "%L", LANG_PLAYER, "GAG_UNAUTHORIZED", szChatTag);
		return PLUGIN_HANDLED;
	}

	new szArg[32], iArg[10];

	read_argv(1, szArg, charsmax(szArg));
	read_argv(2, iArg, charsmax(iArg));

	new iTime, pPlayer;

	iTime = str_to_num(iArg);
	pPlayer = find_player("bl", szArg);

	if(szArg[0] == EOS) {
		client_print_color(id, print_team_red, "%L", LANG_PLAYER, "GAG_PLAYERNAME_EMPTY", szChatTag);
		return PLUGIN_HANDLED;
	}

	@GagThePlayer(id, pPlayer, iArg[0] == EOS ? DEFAULT_GAG_TIME:iTime);
	return PLUGIN_HANDLED;
}

@clcmd_ungag(const id) {
	if(~get_user_flags(id) & ADMIN_GAG) {
		client_print_color(id, print_team_red, "%L", LANG_PLAYER, "GAG_UNAUTHORIZED", szChatTag);
		return PLUGIN_HANDLED;
	}

	new szArg[32], pPlayer;

	read_argv(1, szArg, charsmax(szArg));
	pPlayer = find_player("bl", szArg);

	if(szArg[0] == EOS) {
		client_print_color(id, print_team_red, "%L", LANG_PLAYER, "GAG_PLAYERNAME_EMPTY", szChatTag);
		return PLUGIN_HANDLED;
	}
	if(g_int[iGagTime][pPlayer] > 0) {
		remove_task(pPlayer);
		g_int[iGagTime][pPlayer] = 0;

		client_print_color(0, print_team_red, "%L", LANG_PLAYER, "GAG_PLAYER_UNGAG", szChatTag, id, pPlayer);
		return PLUGIN_HANDLED;
	}
	else {
		client_print_color(id, print_team_red, "%L", LANG_PLAYER, "GAG_PLAYER_NOGAG", szChatTag);
		return PLUGIN_HANDLED;
	}
}

@GagThePlayer(const id, const pPlayer, const iTime) {
	if(GagTermsOfUse(id, pPlayer, true, true, true)) {
		return PLUGIN_HANDLED;
	}
	else if(!(iTime > 0)) {
		client_print_color(id, print_team_red, "%L", LANG_PLAYER, "GAG_TIME_IS_SMALL", szChatTag);
		return PLUGIN_HANDLED;
	}
	else {
		g_int[iGagTime][pPlayer] = iTime;
		set_task(1.0, "@CountdownGag", pPlayer, .flags = "b");

		client_print_color(0, print_team_red, "%L", LANG_PLAYER, "GAG_PLAYER_GAG", szChatTag, id, pPlayer, iTime);
		return PLUGIN_HANDLED;
	}
}

bool:GagTermsOfUse(const id, const pPlayer, bool:blFlags, bool:blPlayer, bool:blOnGag) {
	if(blPlayer && !pPlayer) {
		client_print_color(id, print_team_red, "%L", LANG_PLAYER, "GAG_NOPLAYER", szChatTag);
		return true;
	}
	if(blFlags && get_user_flags(pPlayer) & ADMIN_IMMUNITY) {
		client_print_color(id, print_team_red, "%L", LANG_PLAYER, "GAG_PLAYER_IMMUNITY", szChatTag);
		return true;
	}
	if(blOnGag && g_int[iGagTime][pPlayer] > 0) {
		client_print_color(id, print_team_red, "%L", LANG_PLAYER, "GAG_ALREADY_ACTIVE", szChatTag);
		return true;
	}
	return false;
}

@CountdownGag(const id) {
	if(g_int[iGagTime][id] > 0) {
		g_int[iGagTime][id]--;
	}
	else {
		g_int[iGagTime][id] = 0;
		remove_task(id);

		client_print_color(0, print_team_red, "%L", LANG_PLAYER, "GAG_TIMEEND", szChatTag, id);
	}
}

@CSGameRules_CanPlayerHearPlayer_Pre(const listener, const sender) {
	if(g_int[iGagTime][sender] > 0) {
		SetHookChainReturn(ATYPE_BOOL, false);
		return HC_SUPERCEDE;
	}
	return HC_CONTINUE;
}

@CBasePlayer_SetClientUserInfoName(const id, const iBuffer, const szNewName[]) {
	if(g_int[iGagTime][id] > 0) {
		client_print_color(id, print_team_red, "%L", LANG_PLAYER, "GAG_NO_NAME_CHANGE", szChatTag); 
		SetHookChainReturn(ATYPE_BOOL, 0);
		return HC_SUPERCEDE;
	}
	return HC_CONTINUE;
}

public client_disconnected(id) {
	remove_task(id);
	SaveNVault(id);

	g_int[iGagTime][id] = 0;
	g_int[iPickPlayer][id] = 0;
}
/******************************** Nvault ****************************/
new g_vault;

public plugin_cfg() {
	g_vault = nvault_open("GagSystemVault");

	if(g_vault == INVALID_HANDLE) {
		set_fail_state("Nvault file not found: GagSystemVault");
	}
}

public plugin_end() {
	nvault_close(g_vault);
}

public client_authorized(id, const authid[]) {
	g_int[iGagTime][id] = nvault_get(g_vault, fmt("%s-[GagTime]", authid));

	if(g_int[iGagTime][id] > 0) {
		set_task(1.0, "@CountdownGag", id, .flags = "b");
	}
}

public SaveNVault(id) {
	new authid[MAX_AUTHID_LENGTH];
	get_user_authid(id, authid, charsmax(authid));

	nvault_pset(g_vault, fmt("%s-[GagTime]", authid), fmt("%i", g_int[iGagTime][id]));
}
