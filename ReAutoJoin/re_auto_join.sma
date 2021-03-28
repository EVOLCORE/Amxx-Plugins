#include <amxmodx>
#include <reapi>

public plugin_init() {
	register_plugin("[ReAPI] Auto join team", "1.0", "mIDnight");

	register_clcmd("say /spec", "@clcmd_spec");
	register_clcmd("say /back", "@clcmd_back");

	RegisterHookChain(RG_ShowVGUIMenu, "@ShowVGUIMenu_Pre", .post = false);
	RegisterHookChain(RG_HandleMenu_ChooseTeam, "@HandleMenu_ChooseTeam_Pre", .post = false);
}

public client_putinserver(pPlayer) {
	if(get_user_flags(pPlayer) & ADMIN_KICK) {
		return PLUGIN_CONTINUE;
	}
	rg_join_team(pPlayer, rg_get_join_team_priority());
	return PLUGIN_CONTINUE;
}

@clcmd_spec(const pPlayer) {
	if(get_user_flags(pPlayer) & ADMIN_KICK && get_member(pPlayer, m_iTeam) != TEAM_SPECTATOR) {
		if(is_user_alive(pPlayer)) {
			user_silentkill(pPlayer, 0);
			rg_set_user_team(pPlayer, TEAM_SPECTATOR);
		}
	}
	return PLUGIN_HANDLED;
}

@clcmd_back(const pPlayer) {
	if(get_user_flags(pPlayer) & ADMIN_KICK && get_member(pPlayer, m_iTeam) == TEAM_SPECTATOR) {
		rg_set_user_team(pPlayer, random_num(1, 2) == 1 ? TEAM_TERRORIST : TEAM_CT, MODEL_AUTO, true, true);
		rg_round_respawn(pPlayer);
	}
	return PLUGIN_HANDLED;
}

@ShowVGUIMenu_Pre(const pPlayer, const VGUIMenu:menuType) {
	if(menuType != VGUI_Menu_Team || get_member(pPlayer, m_bJustConnected) || get_user_flags(pPlayer) & ADMIN_KICK) {
		return HC_CONTINUE;
	}

	set_member(pPlayer, m_iMenu, 0);
	client_print_color(pPlayer, pPlayer, "^4[Element]^1 You have not access to choose team.");
	return HC_SUPERCEDE;
}

@HandleMenu_ChooseTeam_Pre(const pPlayer) {
	if(get_member(pPlayer, m_bJustConnected) || get_user_flags(pPlayer) & ADMIN_KICK) {
		return HC_CONTINUE;
	}

	SetHookChainReturn(ATYPE_INTEGER, false);
	client_print_color(pPlayer, pPlayer, "^4[Element]^1 You have not access to choose team.");
	return HC_SUPERCEDE;
}
