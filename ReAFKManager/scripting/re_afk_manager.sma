
#include <amxmodx>
#include <reapi>

new g_iCvarMaxWarnings, g_iCvarPunishment, g_iCvarSamples, g_iCvarBombTransfer, Float:g_fCvarTime, g_szCvarReason[32];

new g_iPlayWarnings[MAX_CLIENTS + 1];

public plugin_init() {
	register_plugin("[ReGameDLL] AFK Control", "0.0.3", "mIDnight");
	register_dictionary("re_afk_control.txt");
	
	RegisterHookChain(RG_CBasePlayer_DropIdlePlayer, "@CBasePlayer_DropIdlePlayer", false);
	
	bind_pcvar_float(create_cvar("afk_time", "10.0", .description = "Time in seconds after which the player will receive a warning for idle", .has_min = true, .min_val = 5.0, .has_max = true, .max_val = 60.0), g_fCvarTime);
	bind_pcvar_num(create_cvar("afk_max_warns", "3", .description = "Maximum number of warnings per downtime", .has_min = true, .min_val = 1.0), g_iCvarMaxWarnings);
	bind_pcvar_num(create_cvar("afk_punishment_method", "0", .description = "Punishment option for downtime (1 - kick | 0 - transfer to observers)"), g_iCvarPunishment);
	bind_pcvar_num(create_cvar("afk_samples", "1", .description = "Sound alerts during events!"), g_iCvarSamples);
	bind_pcvar_num(create_cvar("afk_bomb_transfer_mode", "2", .description = "What to do with the bomb if the person is AFK ^n0 - nothing ^n1 - throw it in front of him as a weapon ^n2 - transfer it to another player (if possible)"), g_iCvarBombTransfer);
	bind_pcvar_string(create_cvar("afk_reason", "AFK", .description = "The reason for kick"), g_szCvarReason, charsmax(g_szCvarReason));
	
	AutoExecConfig(.name = "re_afk_kicker");
}

public plugin_cfg() {
	set_cvar_num("mp_autokick", 1);
}

public OnConfigsExecuted() {
	// set_member_game(m_fMaxIdlePeriod, -1.0);
	set_cvar_float("mp_autokick_timeout", g_fCvarTime);
	
	if (g_iCvarBombTransfer > 0) {
		set_cvar_float("mp_afk_bomb_drop_time", 0.0);
		
		if (!get_member_game(m_bMapHasBombTarget))
			g_iCvarBombTransfer = 0;
	}
}

public client_disconnected(pPlayer) {
	g_iPlayWarnings[pPlayer] = 0;
}

@CBasePlayer_DropIdlePlayer(const pPlayer, const szReason[]) {
	new Float:flLastMovement = get_gametime();
	static Float:flFirstMovementTime[MAX_PLAYERS + 1];
	if (flLastMovement - flFirstMovementTime[pPlayer] > g_fCvarTime + 1.0) {
		g_iPlayWarnings[pPlayer] = 0;
	}
	
	flFirstMovementTime[pPlayer] = flLastMovement;
	
	if (g_iCvarBombTransfer > 0 && get_member(pPlayer, m_bHasC4) && rg_get_alive_terrorists() > 1) {
		if (g_iCvarBombTransfer == 1 || g_iCvarBombTransfer == 2 && !rg_transfer_c4(pPlayer))
			rg_drop_item(pPlayer, "weapon_c4");
	}
	
	if (++g_iPlayWarnings[pPlayer] < g_iCvarMaxWarnings) {
		if (g_iCvarSamples) {
			rg_send_audio(pPlayer, "sound/events/tutor_msg.wav");
		}
		
		client_print_color(pPlayer, print_team_red, "%L %L", LANG_PLAYER, "AFK_PREFIX", LANG_PLAYER, "AFK_WARNS", g_iPlayWarnings[pPlayer], g_iCvarMaxWarnings);
	}
	// Punishment
	else
	{
		if (g_iCvarPunishment) {
			client_print_color(0, pPlayer, "%L %L", LANG_PLAYER, "AFK_PREFIX", LANG_PLAYER, "AFK_KICKED", pPlayer, g_szCvarReason);
			SetHookChainArg(2, ATYPE_STRING, g_szCvarReason);
			return HC_CONTINUE;
		}

		rg_join_team(pPlayer, TEAM_SPECTATOR);
		
		if (g_iCvarSamples) {
			rg_send_audio(pPlayer, "sound/events/friend_died.wav");
		}
		
		client_print_color(0, pPlayer, "%L %L", LANG_PLAYER, "AFK_PREFIX", LANG_PLAYER, "AFK_TRANSFERED", pPlayer, g_szCvarReason);
	}
	
	return HC_SUPERCEDE;
}

stock rg_get_alive_terrorists() {
	new iNumAliveT;
	rg_initialize_player_counts(iNumAliveT, _, _, _);
	
	return iNumAliveT;
}
