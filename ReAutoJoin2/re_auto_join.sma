#include <amxmodx>
#include <reapi>

public plugin_init() {
	register_plugin("[ReAPI] Auto join team", "1.2", "mIDnight");

	RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Post", .post = true);
	RegisterHookChain(RG_ShowVGUIMenu, "@ShowVGUIMenu_Pre", .post = false);
	RegisterHookChain(RG_HandleMenu_ChooseTeam, "@HandleMenu_ChooseTeam_Pre", .post = false);
	RegisterHookChain(RG_HandleMenu_ChooseTeam, "@HandleMenu_ChooseTeam_Post", .post = true);
//	register_clcmd("chooseteam", "@chooseteam");
}

public client_putinserver(pPlayer) {
	if(is_user_bot(pPlayer) || get_user_flags(pPlayer) & ADMIN_KICK) return;
	rg_join_team(pPlayer, rg_get_join_team_priority());
}

/* @chooseteam(const pPlayer) {
  if(~get_user_flags(pPlayer) & ADMIN_KICK) {
    client_print_color(pPlayer, pPlayer, "^4[HW]^1 You have not access to choose team.");
    return PLUGIN_HANDLED;
  }

  return PLUGIN_CONTINUE;
} */

@ShowVGUIMenu_Pre(pPlayer, VGUIMenu:menu_type, bitsSlots, szOldMenu[]) {
	if(menu_type != VGUI_Menu_Team || get_member(pPlayer, m_bJustConnected)
	|| !strcmp(szOldMenu, "#IG_Team_Select") || get_user_flags(pPlayer) & ADMIN_KICK) {
		SetHookChainArg(3, ATYPE_INTEGER, bitsSlots | (1 << 5));
		SetHookChainArg(4, ATYPE_STRING, "#IG_Team_Select_Spect");
		return HC_CONTINUE;
	}
	set_member(pPlayer, m_iMenu, 0);
	return HC_SUPERCEDE;
}

@CBasePlayer_Spawn_Post(pPlayer) {
	set_entvar(pPlayer, var_iuser3, get_entvar(pPlayer, var_iuser3) | (1 << 1));
}

@HandleMenu_ChooseTeam_Pre(pPlayer) {
	if(get_member(pPlayer, m_bJustConnected) || get_user_flags(pPlayer) & ADMIN_KICK) {
		set_member_game(m_bFreezePeriod, 1)
		return HC_CONTINUE;
	}
	SetHookChainReturn(ATYPE_INTEGER, false);
	return HC_SUPERCEDE;
}

@HandleMenu_ChooseTeam_Post(pPlayer) {
	set_member_game(m_bFreezePeriod, 0);
	set_member(pPlayer, m_bTeamChanged, 0);
}
