#include <amxmodx>
#include <reapi>

const BONUS_RND 	= 2;

new playersTurn[33], g_iRCount, bool:hasBombSite, HookChain:g_hookSpawn;

public plugin_init() {
	register_plugin("[ReAPI] Steam Bonus", "1.3", "mIDnight");

	new iMap_Name[32], iMap_Prefix[][] = { "awp_", "fy_", "35hp", "$" };
	rh_get_mapname(iMap_Name, charsmax(iMap_Name));
	for(new i; i < sizeof(iMap_Prefix); i++) {
		if(containi(iMap_Name, iMap_Prefix[i]) != -1)
		pause("ad");
	}

	RegisterHookChain(RG_HandleMenu_ChooseTeam, "@HandleMenu_ChooseTeam_Post", .post = true);
	RegisterHookChain(RG_CSGameRules_RestartRound, 	"@CSGameRules_RestartRound_Pre", .post = false);
	g_hookSpawn = RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Post", .post = true);
	if (rg_find_ent_by_class(-1, "func_bomb_target") > 0 || rg_find_ent_by_class(-1, "info_bomb_target") > 0)
	hasBombSite = true;
}

@HandleMenu_ChooseTeam_Post(const id, const MenuChooseTeam:slot) {
	if (is_user_steam(id))
	client_print_color(id, print_team_default, "^4[HW]^1 Welcome ^3%n^1 you will receive prizes for using STEAM.", id);
}

@CSGameRules_RestartRound_Pre() {
	g_iRCount = get_member_game(m_bCompleteReset) ? 0 : g_iRCount;
	
	if (++g_iRCount % BONUS_RND)
	DisableHookChain(g_hookSpawn);
	else	EnableHookChain(g_hookSpawn);
}

@CBasePlayer_Spawn_Post(id) {
    if (!is_user_alive(id) || !is_user_steam(id)) {
        return;
    }

    switch (playersTurn[id] % 3) {
        case 0:
            GiveGrenades(id);
        case 1:
            GiveArmor(id);
        case 2:
            GiveRandomMoney(id);
    }

    if (hasBombSite && get_member(id, m_iTeam) == TEAM_CT) {
        rg_give_defusekit(id);
    }

    ++playersTurn[id];
}

GiveGrenades(id) {
	rg_give_item(id, "weapon_flashbang", GT_REPLACE);
	rg_set_user_bpammo(id, WEAPON_FLASHBANG, 2);
	rg_give_item(id, "weapon_hegrenade");
	client_print_color(id, print_team_default, "^4[HW] ^1You received^3 grenades ^1for using steam version of game.");
}

GiveArmor(id) {
	rg_set_user_armor(id, 100, ARMOR_VESTHELM);
	client_print_color(id, print_team_default, "^4[HW] ^1You received^3 armor ^1for using steam version of game.");
}

GiveRandomMoney(id) {
	new iMoney = random_num(200, 1000);
	rg_add_account(id, iMoney);
	client_print_color(id, print_team_default, "^4[HW] ^1You received ^3%d$ ^1for using steam version of game.", iMoney);
}
