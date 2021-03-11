#include <amxmodx>
#include <reapi>

public plugin_init() {
	register_plugin("[ReAPI] Swap teams", "1.0", "mIDnight");
	register_clcmd( "say /swap", "@clcmd_swap");
}

@clcmd_swap(pPlayer) {
	if(get_user_flags(pPlayer) & ADMIN_BAN) {
		rg_swap_all_players();
		rg_round_respawn(pPlayer);
		rg_remove_all_items(pPlayer);
		rg_add_account(pPlayer, 800, AS_SET);
		rg_set_user_armor(pPlayer, 0, ARMOR_NONE);
		rg_give_default_items(pPlayer);
		client_print_color(0, pPlayer, "^4[Element]^1 Admin ^3%n^1 swaped teams.", pPlayer);
	}
	return PLUGIN_HANDLED;
}
