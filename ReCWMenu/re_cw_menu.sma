#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <reapi>

new HookChain:g_iHC_AddPlayerItem_Pre,
HookChain:g_iHC_RoundEnd_Pre,
HookChain:g_iHC_RoundEnd_Post,
HookChain:g_iHC_RestartRound_Post,
HookChain:g_iHC_ShowVGUIMenu_Pre,
HookChain:g_iHC_HandleMenu_ChooseTeam_Pre,
HookChain:g_iHC_Spawn_Post;

new Array:g_aWarmUp,
Array:g_aCW;

new g_szCvar_Sv_Password[32],
g_iVotes[2];

new bool:b_talk = false;

public plugin_init() {
	register_plugin("CW Core", "1.2", "mIDnight");
	register_dictionary("cw_core.txt");

	register_clcmd("say /menu", "@clcmd_cw");
	register_clcmd("nightvision", "@clcmd_cw");

	register_clcmd("changemap", "@clcmd_changemap");
	register_clcmd("setpassword", "@clcmd_setpassword");
	register_clcmd("joinclass", "@clcmd_joinedclass");
	register_clcmd("say","@clcmd_say");

	register_forward(FM_ClientKill, "@ClientKill_Pre", ._post = false);

	DisableHookChain((g_iHC_AddPlayerItem_Pre = RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "@CBasePlayer_AddPlayerItem_Pre", .post = false)));
	DisableHookChain((g_iHC_RoundEnd_Pre = RegisterHookChain(RG_RoundEnd, "@RoundEnd_Pre", .post = false)));
	DisableHookChain((g_iHC_RoundEnd_Post = RegisterHookChain(RG_RoundEnd, "@RoundEnd_Post", .post = true)));
	DisableHookChain((g_iHC_RestartRound_Post = RegisterHookChain(RG_CSGameRules_RestartRound, "@RG_CSGameRules_RestartRound_Post", .post = true)));
	DisableHookChain((g_iHC_ShowVGUIMenu_Pre = RegisterHookChain(RG_ShowVGUIMenu, "@ShowVGUIMenu_Pre", .post = false)));
	DisableHookChain((g_iHC_HandleMenu_ChooseTeam_Pre = RegisterHookChain(RG_HandleMenu_ChooseTeam, "@HandleMenu_ChooseTeam_Pre", .post = false)));
	DisableHookChain((g_iHC_Spawn_Post = RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Post", .post = true)));

	bind_pcvar_string(get_cvar_pointer("sv_password"), g_szCvar_Sv_Password, charsmax(g_szCvar_Sv_Password));

	g_aWarmUp = ArrayCreate(32);
	g_aCW = ArrayCreate(32);
}

public client_disconnected(id) {
	if(g_szCvar_Sv_Password[0] == EOS) {
		return;
	}

	new iCount;
	for(new pPlayer = 1; pPlayer <= MaxClients; pPlayer++) {
		if(!is_user_connected(pPlayer) || pPlayer == id || is_user_bot(pPlayer)) {
			continue;
		}

		iCount++;
	}

	if(!iCount) {
		set_pcvar_string(get_cvar_pointer("sv_password"), "");
	}		
}

@clcmd_say(const pPlayer) {
	if(b_talk) {
		client_print_color(pPlayer, pPlayer, "%L", LANG_PLAYER, "CW_PRINT_ID_SAY");
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}		

@clcmd_cw(const pPlayer) {
	if(~get_user_flags(pPlayer) & ADMIN_KICK) {
		client_print_color(pPlayer, pPlayer, "%L", LANG_PLAYER, "CW_PRINT_ID_MENU_OPEN");
		return PLUGIN_CONTINUE;
	}

	new iMenu = menu_create("\yCW Menu", "@clcmd_cw_handler");

	menu_additem(iMenu, "Admin Menu^n");

	menu_additem(iMenu, "\rStart CW");
	menu_additem(iMenu, "\rStop CW");
	menu_additem(iMenu, "\rChange Map^n");

	menu_additem(iMenu, fmt("Current Password: \y%s", g_szCvar_Sv_Password[0] == EOS ? "NO" : g_szCvar_Sv_Password));
	menu_additem(iMenu, "Set Password");
	menu_additem(iMenu, "Remove Password");

	menu_display(pPlayer, iMenu);
	return PLUGIN_HANDLED;
}

@clcmd_cw_handler(const pPlayer, const iMenu, const iItem) {
	switch(iItem) {
		case 0: {
			if(get_user_flags(pPlayer) & ADMIN_RCON) {
				@cw_adminmenu(pPlayer);
			}
			else {
				menu_display(pPlayer, iMenu);
				return PLUGIN_HANDLED;
			}
		}
		case 1: {
			if(get_member_game(m_bGameStarted)) {
				client_print_color(pPlayer, pPlayer, "%L", LANG_PLAYER, "CW_PRINT_ID_GAME_ALREADY_STARTED");
				menu_display(pPlayer, iMenu);
				return PLUGIN_HANDLED;
			}

			@StartCw_Settings();
			client_print_color(0, 0, "%L", LANG_PLAYER, "CW_PRINT_ALL_KNIFE_ROUND_STARTED");
		}
		case 2: {
			if(!get_member_game(m_bGameStarted)) {
				client_print_color(pPlayer, pPlayer, "%L", LANG_PLAYER, "CW_PRINT_ID_GAME_NOT_STARTED");
				menu_display(pPlayer, iMenu);
				return PLUGIN_HANDLED;
			}

			@StartWarmup_Settings();
			client_print_color(0, 0, "%L", LANG_PLAYER, "CW_PRINT_ALL_WARMUP_STARTED");
		}
		case 3: {
			client_cmd(pPlayer, "messagemode changemap");
		}
		case 4: {
			menu_display(pPlayer, iMenu);
			return PLUGIN_HANDLED;
		}
		case 5: {
			client_cmd(pPlayer, "messagemode setpassword");
		}
		case 6: {
			set_pcvar_string(get_cvar_pointer("sv_password"), "");
			client_print_color(0, 0, "%L", LANG_PLAYER, "CW_PRINT_ALL_REMOVE_PASSWORD", pPlayer);
		}
	}
	menu_destroy(iMenu);
	return PLUGIN_HANDLED;
}

@cw_adminmenu(const pPlayer) {
	new iMenu = menu_create("Admin Menu", "@cw_adminmenu_handler");

	menu_additem(iMenu, "Kick Player");
	menu_additem(iMenu, "Ban Player");
	menu_additem(iMenu, "Move Player");
	if(b_talk) menu_additem(iMenu, "Enable say");
	else menu_additem(iMenu, "Disable say");
	
	menu_display(pPlayer, iMenu);
}

@cw_adminmenu_handler(const pPlayer, const iMenu, const iItem) {
	switch(iItem) {
		case 0: {
			client_cmd(pPlayer, "amx_kickmenu");
		}
		case 1: {
			client_cmd(pPlayer, "amx_banmenu");
		}
		case 2: {
			client_cmd(pPlayer, "amx_teammenu");
		}
		case 3: {
			if(b_talk) {
				b_talk = false;
				client_print_color(pPlayer, pPlayer, "%L", LANG_PLAYER, "CW_PRINT_ID_SAY_ENABLED");
			}
			else {
				b_talk = true;
				client_print_color(pPlayer, pPlayer, "%L", LANG_PLAYER, "CW_PRINT_ID_SAY_DISABLED");
			}
			@cw_adminmenu(pPlayer);
		}
	}
	menu_destroy(iMenu);
	return PLUGIN_HANDLED;
}

@StartCw_Settings() {
	set_pcvar_num(get_cvar_pointer("sv_restart"), 3);
	EnableHookChain(g_iHC_AddPlayerItem_Pre);
	EnableHookChain(g_iHC_RoundEnd_Pre);
	EnableHookChain(g_iHC_ShowVGUIMenu_Pre);
	EnableHookChain(g_iHC_HandleMenu_ChooseTeam_Pre);
	DisableHookChain(g_iHC_Spawn_Post);
	@SetSettings(g_aCW);
	set_member_game(m_bGameStarted, true);
}

@StartWarmup_Settings() {
	set_pcvar_num(get_cvar_pointer("sv_restart"), 3);
	DisableHookChain(g_iHC_AddPlayerItem_Pre);
	DisableHookChain(g_iHC_RoundEnd_Pre);
	DisableHookChain(g_iHC_RoundEnd_Post);
	DisableHookChain(g_iHC_RestartRound_Post);
	DisableHookChain(g_iHC_ShowVGUIMenu_Pre);
	DisableHookChain(g_iHC_HandleMenu_ChooseTeam_Pre);
	EnableHookChain(g_iHC_Spawn_Post);
	@SetSettings(g_aWarmUp);
	set_member_game(m_bGameStarted, false);
}

@clcmd_changemap(const pPlayer) {
	if(~get_user_flags(pPlayer) & ADMIN_IMMUNITY) {
		return PLUGIN_HANDLED;
	}

	new szArg[32];
	read_args(szArg, charsmax(szArg));
	remove_quotes(szArg);

	if(!is_map_valid(szArg)) {
		return PLUGIN_HANDLED;
	}

	client_print_color(0, 0, "%L", LANG_PLAYER, "CW_PRINT_ALL_CHANGE_MAP", pPlayer, szArg);
	server_cmd("changelevel %s", szArg);
	return PLUGIN_HANDLED;
}

@clcmd_setpassword(const pPlayer) {
	if(~get_user_flags(pPlayer) & ADMIN_IMMUNITY) {
		return PLUGIN_HANDLED;
	}

	new szArg[32];
	read_args(szArg, charsmax(szArg));
	remove_quotes(szArg);

	set_pcvar_string(get_cvar_pointer("sv_password"), szArg);
	client_print_color(0, 0, "%L", LANG_PLAYER, "CW_PRINT_ALL_SET_PASSWORD", pPlayer, szArg);
	return PLUGIN_HANDLED;
}

@ClientKill_Pre(pPlayer) {
	return FMRES_SUPERCEDE;
}

@CBasePlayer_AddPlayerItem_Pre(const pPlayer, const iItem) {
	if(get_member(iItem, m_iId) != WEAPON_KNIFE) {
		SetHookChainReturn(ATYPE_INTEGER, false);
		return HC_SUPERCEDE;
	}
	return HC_CONTINUE;
}

@RoundEnd_Pre(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay) {
	if(event == ROUND_GAME_RESTART) {
		return HC_CONTINUE;
	}

	new Float:flHealth[TeamName];
	for(new pPlayer = 1, TeamName:iTeam; pPlayer <= MaxClients; pPlayer++) {
		if(!is_user_alive(pPlayer)) {
			continue;
		}

		iTeam = get_member(pPlayer, m_iTeam);
		flHealth[iTeam] += Float:get_entvar(pPlayer, var_health);
	}

	if(flHealth[TEAM_CT] > flHealth[TEAM_TERRORIST]) {
		@RoundEnd_Winner(TEAM_CT, WINSTATUS_CTS, ROUND_CTS_WIN, "CW_PRINT_ALL_KNIFEROUND_CTWIN");
	}
	else if(flHealth[TEAM_TERRORIST] > flHealth[TEAM_CT]) {
		@RoundEnd_Winner(TEAM_TERRORIST, WINSTATUS_TERRORISTS, ROUND_TERRORISTS_WIN, "CW_PRINT_ALL_KNIFEROUND_TWIN");
	}
	else {
		switch(random_num(1,2)) {
			case 1: @RoundEnd_Winner(TEAM_CT, WINSTATUS_CTS, ROUND_CTS_WIN, "CW_PRINT_ALL_KNIFEROUND_CTWIN");
			case 2: @RoundEnd_Winner(TEAM_TERRORIST, WINSTATUS_TERRORISTS, ROUND_TERRORISTS_WIN, "CW_PRINT_ALL_KNIFEROUND_TWIN");
		}
	}

	SetHookChainReturn(ATYPE_BOOL, false);
	return HC_SUPERCEDE;
}

@RoundEnd_Winner(const TeamName:iTeam, WinStatus:status, ScenarioEventEndRound:event, const szText[]) {
	rg_round_end(0.0, status, event);
	client_print_color(0, 0, "%L", LANG_PLAYER, szText);

	set_task(13.0, "@Task_Stop_Vote");
	g_iVotes[0] = g_iVotes[1] = 0;

	new iMenu = menu_create("\ySwitch teams?", "@Vote_Switch_Teams_Handler");

	menu_additem(iMenu, "\yYes");
	menu_additem(iMenu, "\yNo");

	for(new pPlayer = 1; pPlayer <= MaxClients; pPlayer++) {
		if(!is_user_connected(pPlayer) || get_member(pPlayer, m_iTeam) != iTeam) {
			continue;
		}

		menu_display(pPlayer, iMenu);
	}
}

@Vote_Switch_Teams_Handler(const pPlayer, const iMenu, const iItem) {
	switch(iItem) {
		case 0: {
			g_iVotes[0]++;
			client_print_team(pPlayer, "CW_PRINT_ALL_CHOSE_SWITCH");
		}
		case 1: {
			g_iVotes[1]++;
			client_print_team(pPlayer, "CW_PRINT_ALL_CHOSE_STAY");
		}
	}

	menu_destroy(iMenu);
	return PLUGIN_HANDLED;
}

client_print_team(const pPlayer, const szMessage[]) {
	new TeamName:iTeam = get_member(pPlayer, m_iTeam);

	for(new id = 1; id <= MaxClients; id++) {
		if(is_user_connected(id) && get_member(id, m_iTeam) == iTeam) {
			client_print_color(id, id, "%L", LANG_PLAYER, szMessage, pPlayer);
		}
	}
}

@Task_Stop_Vote() {
	if(g_iVotes[0] > g_iVotes[1]) {
		rg_swap_all_players();
		set_pcvar_num(get_cvar_pointer("sv_restart"), 2);
		client_print_color(0, 0, "%L", LANG_PLAYER, "CW_PRINT_ALL_SWAP_TEAMS");
	}
	else {
		set_pcvar_num(get_cvar_pointer("sv_restart"), 2);
		client_print_color(0, 0, "%L", LANG_PLAYER, "CW_PRINT_ALL_NOT_SWAP_TEAMS");
	}

	DisableHookChain(g_iHC_AddPlayerItem_Pre);
	DisableHookChain(g_iHC_RoundEnd_Pre);
	EnableHookChain(g_iHC_RoundEnd_Post);
	EnableHookChain(g_iHC_RestartRound_Post);
	DisableHookChain(g_iHC_Spawn_Post);
}

@RoundEnd_Post(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay) {
	new iCTWin = get_member_game(m_iNumCTWins);
	new iTWin = get_member_game(m_iNumTerroristWins);

	set_dhudmessage(255, 0, 0, -1.0, -0.55, 0, 6.0, 10.0);

	if(iCTWin + iTWin == 15) {
		for(new pPlayer = 1; pPlayer <= MaxClients; pPlayer++) {
			if(!is_user_alive(pPlayer)) {
				continue;
			}

			set_entvar(pPlayer, var_flags, get_entvar(pPlayer, var_flags) | FL_FROZEN);
		}
		return;
	}

	if(iTWin > 15 && (iTWin - iCTWin >= 2)) {
		client_print_color(0, 0, "%L", LANG_PLAYER, "CW_PRINT_ALL_TERRS_WIN");
		show_dhudmessage(0, "%L", LANG_PLAYER, "CW_DHUD_ALL_TERRS_WIN");
		set_pcvar_num(get_cvar_pointer("sv_restart"), 3);
		@StartWarmup_Settings();
		client_print_color(0, 0, "%L", LANG_PLAYER, "CW_PRINT_ALL_MATCH_END");
	}
	else if(iCTWin > 15 && (iCTWin - iTWin >= 2)) {
		client_print_color(0, 0, "%L", LANG_PLAYER, "CW_PRINT_ALL_CTS_WIN");
		show_dhudmessage(0, "%L", LANG_PLAYER, "CW_DHUD_ALL_CTS_WIN");
		set_pcvar_num(get_cvar_pointer("sv_restart"), 3);
		@StartWarmup_Settings();
		client_print_color(0, 0, "%L", LANG_PLAYER, "CW_PRINT_ALL_MATCH_END");
	}
	else if(iTWin == iCTWin && iTWin == 15) {
		show_dhudmessage(0, "%L", LANG_PLAYER, "CW_DHUD_ALL_OVERTIME");
	}
}

@RG_CSGameRules_RestartRound_Post() {
	new iCTWin = get_member_game(m_iNumCTWins);
	new iTWin = get_member_game(m_iNumTerroristWins);
	new iRound = iCTWin + iTWin;

	switch(iRound) {
		case 0: {
			for(new i = 0; i < 3; i++) {
				client_print_color(0, 0, "%L", LANG_PLAYER, "CW_PRINT_ALL_LIVE");
			}
		}
		case 15: {
			client_print_color(0, 0, "%L", LANG_PLAYER, "CW_PRINT_ALL_SECOND_HALF");
			rg_swap_all_players();
			client_print_color(0, 0, "%L", LANG_PLAYER, "CW_PRINT_ALL_SWAP_TEAMS");

			for(new pPlayer = 1; pPlayer <= MaxClients; pPlayer++) {
				if(!is_user_alive(pPlayer)) {
					continue;
				}

				rg_round_respawn(pPlayer);
				rg_remove_all_items(pPlayer);
				rg_add_account(pPlayer, 800, AS_SET);
				rg_set_user_armor(pPlayer, 0, ARMOR_NONE);
				rg_give_default_items(pPlayer);
			}
		}
		case 32,34,36,38,40,42,44,46,48,50,52,54,56,58,60: {
			rg_swap_all_players();
			client_print_color(0, 0, "%L", LANG_PLAYER, "CW_PRINT_ALL_SWAP_TEAMS");

			for(new pPlayer = 1; pPlayer <= MaxClients; pPlayer++) {
				if(!is_user_alive(pPlayer)) {
					continue;
				}

				rg_round_respawn(pPlayer);
				rg_remove_all_items(pPlayer);
				rg_add_account(pPlayer, 16000, AS_SET);
				rg_set_user_armor(pPlayer, 0, ARMOR_NONE);
				rg_give_default_items(pPlayer);
			}
		}
		default: {
			if(iTWin > iCTWin) {
				client_print_color(0, print_team_red, "%L", LANG_PLAYER, "CW_PRINT_ALL_ROUNDSTART_TWIN", iTWin, iCTWin);
			}
			else if(iCTWin > iTWin) {
				client_print_color(0, print_team_blue, "%L", LANG_PLAYER, "CW_PRINT_ALL_ROUNDSTART_CTWIN", iTWin, iCTWin);
			}
			else {
				client_print_color(0, print_team_grey, "%L", LANG_PLAYER, "CW_PRINT_ALL_ROUNDSTART_DRAW", iTWin, iCTWin);
			}
		}
	}
}

@ShowVGUIMenu_Pre(const pPlayer, const VGUIMenu:menuType) {
	if(menuType != VGUI_Menu_Team || get_member(pPlayer, m_bJustConnected)) {
		return HC_CONTINUE;
	}

	set_member(pPlayer, m_iMenu, 0);
	return HC_SUPERCEDE;
}

@HandleMenu_ChooseTeam_Pre(const pPlayer) {
	if(get_member(pPlayer, m_bJustConnected)) {
		return HC_CONTINUE;
	}
	
	SetHookChainReturn(ATYPE_INTEGER, false);
	return HC_SUPERCEDE;
}

@CBasePlayer_Spawn_Post(const pPlayer) {
	if(get_member(pPlayer, m_bJustConnected)) {
		return;
	}

	set_member(pPlayer, m_iHideHUD, get_member(pPlayer, m_iHideHUD) | HIDEHUD_MONEY);
}

@clcmd_joinedclass(pPlayer) {
	set_task(2.0, "@JoinMessage", pPlayer);
}

@JoinMessage(pPlayer) {
	if(is_user_connected(pPlayer)) {
		client_print_color(pPlayer, pPlayer, "%L", LANG_PLAYER, "CW_PRINT_ID_TAKE_ADMIN");
		client_print_color(pPlayer, pPlayer, "%L", LANG_PLAYER, "CW_PRINT_ID_OPEN_MENU");
	}
}

public plugin_cfg() {
	new szFileName[35];
	get_localinfo("amxx_configsdir", szFileName, charsmax(szFileName));
	add(szFileName, charsmax(szFileName), "/cw_core.cfg");

	server_print("%s", szFileName);
	if(!file_exists(szFileName)) {
		pause("d");
		return;
	}

	new iFile = fopen(szFileName, "r");

	if(iFile) {
		new szBuffer[MAX_FMT_LENGTH], szData[64], iLen;

		while(!feof(iFile)) {
			fgets(iFile, szBuffer, charsmax(szBuffer));
			trim(szBuffer);

			if(szBuffer[0] == EOS || szBuffer[0] == ';') {
				continue;
			}

			if(szBuffer[0] == '[') {
				iLen = strlen(szBuffer);
				copyc(szData, charsmax(szData), szBuffer[1], szBuffer[iLen - 1]);
				continue;
			}

			switch(szData[0]) {
				case 'W': {
					ArrayPushString(g_aWarmUp, szBuffer);
				}
				case 'C': {
					ArrayPushString(g_aCW, szBuffer);
				}
			}
		}
		fclose(iFile);

		@StartWarmup_Settings();
	}
}

@SetSettings(const Array:aArray) {
	new iArraySize = ArraySize(aArray);

	for(new i = 0, szArrayData[MAX_FMT_LENGTH]; i < iArraySize; i++) {
		ArrayGetString(aArray, i, szArrayData, charsmax(szArrayData));

		server_cmd("%s", szArrayData);
	}
}
