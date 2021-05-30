#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <nvault>

new const iChatTag[] = "^4[Element]";
#define ADMIN_GAG    ADMIN_RESERVATION

#define DEFAULTGAG_TIME   120    //default time gag example amx_gag mIDnight and it will auto gag him.

enum _:intenum {
	iGagTime[MAX_PLAYERS + 1],
	iPickPlayer[MAX_PLAYERS + 1]
};
new g_int[intenum];

enum (+= 1337) {
	TASK_GAG = 1337
}

public plugin_init() {
	register_plugin("[ReAPI] Gag System", "1.0", "mIDnight");

	register_clcmd("say /gagmenu", "@clcmd_gagmenu");
	register_clcmd("say !gagmenu", "@clcmd_gagmenu");
	register_clcmd("say .gagmenu", "@clcmd_gagmenu");
	register_clcmd("SetDuration", "@clcmd_SetDuration");

	register_clcmd("say", "@clcmd_say");
	register_clcmd("say_team", "@clcmd_say");
	register_clcmd("amx_chat", "@clcmd_say");
	register_concmd("amx_gag", "@clcmd_gag", ADMIN_GAG, "<name> <time>, gag the player.");
	register_concmd("amx_ungag", "@clcmd_ungag", ADMIN_GAG, "<name>, ungag the player.");

	RegisterHookChain(RG_CBasePlayer_SetClientUserInfoName, "@CBasePlayer_SetClientUserInfoName");
}

@clcmd_gagmenu(id) {
	if(~get_user_flags(id) & ADMIN_GAG) {
		client_print_color(id, id, "%s ^1You are not authorized to use this command.", iChatTag);
		return PLUGIN_HANDLED;
	}
	new menu = menu_create(fmt("\w[\rElement\w] \ySelect player to gag"), "@clcmd_gagmenu_");

	for(new i = 1; i <= MaxClients; i++) {
		if(!is_user_connected(i) || is_user_bot(i) || get_user_flags(i) & ADMIN_IMMUNITY) {
			continue;
		}
		menu_additem(menu, fmt("%n", i), fmt("%i", i));
	}
	menu_setprop(menu, MPROP_EXITNAME, "\yExit");
	menu_display(id, menu);
	return PLUGIN_HANDLED;
}

@clcmd_gagmenu_(id, menu, item) {
	if(item == MENU_EXIT) {
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	new data[6], key;
	menu_item_getinfo(menu, item, _, data, charsmax(data));
	key = str_to_num(data);

	g_int[iPickPlayer][id] = key;
	client_cmd(id, "messagemode SetDuration");

	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

@clcmd_SetDuration(id) {
	if(~get_user_flags(id) & ADMIN_GAG) {
		client_print_color(id, id, "%s ^1You are not authorized to use this command.", iChatTag);
		return PLUGIN_HANDLED;
	}
	new szArg[32];
	read_args(szArg, charsmax(szArg));
	remove_quotes(szArg);

	if(!g_int[iPickPlayer][id]) {
		client_print_color(id, id, "%s ^1You cannot gag without selecting the player.", iChatTag);
		return PLUGIN_HANDLED;
	}
	new iTime = str_to_num(szArg);
	@GagThePlayer(id, g_int[iPickPlayer][id], iTime);
	return PLUGIN_HANDLED;
}

@clcmd_say(const id) {
	if(g_int[iGagTime][id] > 0) {
		client_print_color(id, id, "%s ^1You are gagged^3 %i^1 Seconds left before ungag.", iChatTag, g_int[iGagTime][id]);
		return PLUGIN_HANDLED;
	}
	new szArg[32];
	read_args(szArg, charsmax(szArg));
	remove_quotes(szArg);

	new szTitle[7], szName[32], iTime[10];
	parse(szArg, szTitle, charsmax(szTitle), szName, charsmax(szName), iTime, charsmax(iTime));

	new iTimes, pPlayer;
	iTimes = str_to_num(iTime);
	pPlayer = find_player("bl", szName);

	if(equal(szTitle, "/gag") || equal(szTitle, "!gag") || equal(szTitle, ".gag")) {
		if(~get_user_flags(id) & ADMIN_GAG) {
			client_print_color(id, id, "%s ^1You are not authorized to use this command.", iChatTag);
			return PLUGIN_HANDLED;
		}
		else if(szName[0] == EOS) {
			client_print_color(id, id, "%s ^1You cannot leave the player name blank.", iChatTag);
			return PLUGIN_HANDLED;
		}
		@GagThePlayer(id, pPlayer, iTime[0] == EOS ? DEFAULTGAG_TIME:iTimes);
		return PLUGIN_HANDLED;
	}
	if(equal(szTitle, "/ungag") || equal(szTitle, "!ungag") || equal(szTitle, ".ungag")) {
		if(~get_user_flags(id) & ADMIN_GAG) {
			client_print_color(id, id, "%s ^1You are not authorized to use this command.", iChatTag);
			return PLUGIN_HANDLED;
		}
		else if(szName[0] == EOS) {
			client_print_color(id, id, "%s ^1You cannot leave the player name blank.", iChatTag);
			return PLUGIN_HANDLED;
		}
		else if(g_int[iGagTime][pPlayer] > 0) {
			remove_task(pPlayer);
			g_int[iGagTime][pPlayer] = 0;
			client_print_color(0, 0, "^1ADMIN: ^4%n^1 has ungagged player ^3%n^1.", id, pPlayer);
			return PLUGIN_HANDLED;
		}
		else {
			client_print_color(id, id, "%s ^1The designated player does not have a gag.", iChatTag);
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;
}

@clcmd_gag(const id) {
	if(~get_user_flags(id) & ADMIN_GAG) {
		client_print_color(id, id, "%s ^1You are not authorized to use this command.", iChatTag);
		return PLUGIN_HANDLED;
	}
	new szArg[32], iArg[10];
	read_argv(1, szArg, charsmax(szArg));
	read_argv(2, iArg, charsmax(iArg));

	new iTime, pPlayer;
	iTime = str_to_num(iArg);
	pPlayer = find_player("bl", szArg);

	if(szArg[0] == EOS) {
		client_print_color(id, id, "%s ^1You cannot leave the player name blank.", iChatTag);
		return PLUGIN_HANDLED;
	}
	@GagThePlayer(id, pPlayer, iArg[0] == EOS ? DEFAULTGAG_TIME:iTime);
	return PLUGIN_HANDLED;
}

@clcmd_ungag(const id) {
	if(~get_user_flags(id) & ADMIN_GAG) {
		client_print_color(id, id, "%s ^1You are not authorized to use this command.", iChatTag);
		return PLUGIN_HANDLED;
	}
	new szArg[32];
	read_argv(1, szArg, charsmax(szArg));

	new pPlayer;
	pPlayer = find_player("bl", szArg);

	if(szArg[0] == EOS) {
		client_print_color(id, id, "%s ^1You cannot leave the player name blank.", iChatTag);
		return PLUGIN_HANDLED;
	}
	if(g_int[iGagTime][pPlayer] > 0) {
		remove_task(pPlayer + TASK_GAG);
		g_int[iGagTime][pPlayer] = 0;
		client_print_color(0, 0, "^1ADMIN: ^4%n^1 has ungagged player ^3%n^1.", id, pPlayer);
		return PLUGIN_HANDLED;
	}
	else {
		client_print_color(id, id, "%s ^1The designated player does not have a gag.", iChatTag);
		return PLUGIN_HANDLED;
	}
}

@GagThePlayer(const id, const pPlayer, iTime) {
	if(GagTermsOfUse(id, pPlayer, true, true, true)) {
		return PLUGIN_HANDLED;
	}
	else if(!(iTime > 0)) {
		client_print_color(id, id, "%s ^1You must enter the time gag greater than 0.", iChatTag);
		return PLUGIN_HANDLED;
	}
	else {
		g_int[iGagTime][pPlayer] = iTime;
		set_task(1.0, "@CountdownGag", pPlayer, .flags = "b");
		client_print_color(0, 0, "^1ADMIN: ^4%n^1 has gagged ^3%n^1 on ^3%i ^1Seconds.", id, pPlayer, iTime);
		return PLUGIN_HANDLED;
	}
}
bool:GagTermsOfUse(const id, const pPlayer, bool:blFlags, bool:blPlayer, bool:blOnGag) {
	if(blPlayer && !pPlayer) {
		client_print_color(id, id, "%s ^1Couldn't find player to ungag.", iChatTag);
		return true;
	}
	if(blFlags && get_user_flags(pPlayer) & ADMIN_IMMUNITY) {
		client_print_color(id, id, "%s ^1The designated player has immunity.", iChatTag);
		return true;
	}
	if(blOnGag && g_int[iGagTime][pPlayer] > 0) {
		client_print_color(id, id, "%s ^1The designated player already has a gag.", iChatTag);
		return true;
	}
	return false;
}

@CountdownGag(const id){
	if(g_int[iGagTime][id] > 0){
		g_int[iGagTime][id]--;
	}
	else {
		g_int[iGagTime][id] = 0;
		remove_task(id);
		client_print_color(0, 0, "%s ^1Gag time for player ^3%n ^1is over, he can talk now.", iChatTag, id);
	}
}

public client_disconnected(id){
	remove_task(id);
	savevault(id);
	g_int[iGagTime][id] = 0;
	g_int[iPickPlayer][id] = 0;
}

@CBasePlayer_SetClientUserInfoName(const id, const iBuffer, const szNewName[]) {
	if(g_int[iGagTime][id] > 0) {
		client_print_color(id, id, "%s ^1Gagged players cannot change their names.", iChatTag);
		SetHookChainReturn(ATYPE_BOOL, 0);
		return HC_SUPERCEDE;
	}
	return HC_CONTINUE;
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

public client_authorized(id, const authid[]){
	g_int[iGagTime][id] = nvault_get(g_vault, fmt("%s-gagtime", authid));
	if(g_int[iGagTime][id] > 0) {
		set_task(1.0, "@CountdownGag", id, .flags = "b");
	}
}

public savevault(id) {
	new authid[MAX_AUTHID_LENGTH];
	get_user_authid(id, authid, charsmax(authid));

	nvault_pset(g_vault, fmt("%s-gagtime", authid), fmt("%i", g_int[iGagTime][id]));
}
