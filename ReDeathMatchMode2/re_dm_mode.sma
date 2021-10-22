#include <amxmodx>
#include <hamsandwich>
#include <cstrike>
#include <reapi>

new stock SayTag[] = "HW";

#define START_HOUR 		01					// Hour night mode start
#define END_HOUR 		10					// Hour night mode end

new bool:CSDM_Mode = true;

new stock pPrimaryGun[][][] = {
	{"",""},
	{"M4A1","weapon_m4a1"},{"AK47","weapon_ak47"},{"AWP","weapon_awp"},{"FAMAS","weapon_famas"},{"GALIL","weapon_galil"}
}

new stock pSecondaryGun[][][] = {
	{"",""},
	{"USP","weapon_usp"},{"GLOCK","weapon_glock18"},{"DEAGLE","weapon_deagle"}
}

new pPrimarySave[33],pSecondarySave[33],bool:pDontOpenMenu[33]
new bool:g_blSilencer[MAX_CLIENTS + 1];

public plugin_init() {
    register_plugin("[ReAPI] Mode switch", "1.0", "mIDnight");

    RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Post", .post = true);
    RegisterHookChain(RG_CBasePlayer_ImpulseCommands, "@CBasePlayer_ImpulseCommands_Pre", .post = false);
    RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "@CBasePlayer_AddPlayerItem_Pre", .post = false);
    register_clcmd("say /guns", "@pOpenMenu"); register_clcmd("say /weapons", "@pOpenMenu");

    RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_m4a1", "@Ham_Weapon_SecondaryAttack_Post", .Post = true);

    set_task(0.1, "OnConfigsExecuted");
}

public OnConfigsExecuted() {
    new hours[32];
    get_time("%H", hours, 31);
    new h_num = str_to_num(hours);
    if((h_num >= START_HOUR) && (h_num <= END_HOUR)) {
        CSDM_Mode = true;
//        set_pcvar_num(get_cvar_pointer("sv_restart"), 3);
        set_pcvar_num(get_cvar_pointer("mp_forcerespawn"), 1);
        set_pcvar_num(get_cvar_pointer("mp_buytime"), 0);
        set_pcvar_num(get_cvar_pointer("mp_infinite_ammo"), 2);
        set_pcvar_num(get_cvar_pointer("mp_give_player_c4"), 0);
        set_pcvar_num(get_cvar_pointer("mp_round_infinite"), 1);
        set_pcvar_num(get_cvar_pointer("mp_roundtime"), 0);
        set_pcvar_num(get_cvar_pointer("mp_item_staytime"), 0);
        client_print_color(0, 0, "^4[%s] ^1DeathMatch mode activated. Hour: ^3%d:00", SayTag, START_HOUR);
    }
    else {
        CSDM_Mode = false;
//        set_pcvar_num(get_cvar_pointer("sv_restart"), 3);
        set_pcvar_num(get_cvar_pointer("mp_forcerespawn"), 0);
        set_pcvar_float(get_cvar_pointer("mp_buytime"), 0.25);
        set_pcvar_num(get_cvar_pointer("mp_infinite_ammo"), 0);
        set_pcvar_num(get_cvar_pointer("mp_give_player_c4"), 1);
        set_pcvar_num(get_cvar_pointer("mp_round_infinite"), 0);
        set_pcvar_num(get_cvar_pointer("mp_roundtime"), 2);
        set_pcvar_num(get_cvar_pointer("mp_item_staytime"), 300);
        client_print_color(0, 0, "^4[%s] ^1Public mode activated. Hour: ^3%d:00", SayTag, END_HOUR);
    }
    set_task(300.0, "OnConfigsExecuted");
    return PLUGIN_HANDLED;
}

public client_putinserver(pPlayer) {
	g_blSilencer[pPlayer] = false;
	client_cmd(pPlayer, "hideradar");
}

@CBasePlayer_Spawn_Post(const pPlayer) {
	set_member(pPlayer, m_iHideHUD, get_member(pPlayer, m_iHideHUD) | (HIDEHUD_TIMER | HIDEHUD_MONEY));
	if(!is_user_alive(pPlayer) || !CSDM_Mode) return;
	rg_remove_all_items(pPlayer);
	rg_give_item(pPlayer,"weapon_knife");
	set_entvar(pPlayer,var_armorvalue,Float:100.0); //rg_set_user_armor(id, 100, ARMOR_VESTHELM)
	switch(pDontOpenMenu[pPlayer]) {
		case true:pOldWeapon(pPlayer);
		case false:pStartMenu(pPlayer);
	}
}

@pOpenMenu(pPlayer) {
	switch(pDontOpenMenu[pPlayer]) {
		case true: {
			pDontOpenMenu[pPlayer] = false;
			client_print_color(pPlayer, pPlayer, "^4[%s]^1 You have activated the weapon menu. Next time you can choose a new weapon again.",SayTag);
		}
	}
	return PLUGIN_HANDLED;
}

public pStartMenu(pPlayer){
	static Item[256]
	formatex(Item, charsmax(Item),"\y|\rHyperWorld\y| \d- \yWeapons Menu");new Menu = menu_create(Item, "pStartMenu_");
	
	formatex(Item, charsmax(Item),"\r|\wNew Weapons\r|");menu_additem(Menu, Item, "1");
	formatex(Item, charsmax(Item),"\r|\wPrevious Weapons\r|");menu_additem(Menu, Item, "2");
	formatex(Item, charsmax(Item),"\r|\w2+Don't show menu again\r|");menu_additem(Menu, Item, "3");
	
	menu_setprop(Menu, MPROP_EXIT, MEXIT_NEVER); menu_display(pPlayer, Menu);
}

public pStartMenu_(pPlayer, menu, item) {
	new data[6], iName[64], access, callback,key;
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);
	key = str_to_num(data)
	switch(key) {
		case 1:pPrimaryMenu(pPlayer);
		case 2:pOldWeapon(pPlayer);
		case 3:client_print_color(pPlayer, pPlayer, "^4[%s]^1 You will no longer be shown the Weapon Menu. Type: ^3/guns ^1or ^3/weapons^1 if you want to be shown again.",SayTag),pOldWeapon(pPlayer),pDontOpenMenu[pPlayer] = true;
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public pPrimaryMenu(pPlayer) {
	if(!is_user_alive(pPlayer)) return;
	static Item[256],NumToString[5];
	formatex(Item, charsmax(Item),"\y|\rHyperWorld\y| \d- \yPrimary Weapon Selection");new Menu = menu_create(Item, "pPrimaryMenu_");
	for(new i=1; i < sizeof(pPrimaryGun); i++) {
		num_to_str(i, NumToString, 5);
		formatex(Item, charsmax(Item), "\r|\w%s\r|",pPrimaryGun[i][0][0]);menu_additem(Menu, Item, NumToString);
	}	
	menu_setprop(Menu, MPROP_EXIT, MEXIT_NEVER); menu_display(pPlayer, Menu);
}

public pPrimaryMenu_(pPlayer, menu, item) {
	new data[6], iName[64], access, callback,key;
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);
	key = str_to_num(data);
	pPrimarySave[pPlayer] = key;
	rg_give_item(pPlayer,pPrimaryGun[key][1][0]);
	pSecondaryMenu(pPlayer);
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public pSecondaryMenu(pPlayer) {
	if(!is_user_alive(pPlayer)) return;
	static Item[256],NumToString[5];
	formatex(Item, charsmax(Item),"\y|\rHyperWorld\y| \d- \ySecondary Weapon Selection");new Menu = menu_create(Item, "pSecondaryMenu_");
	for(new i=1; i < sizeof(pSecondaryGun); i++) {
		num_to_str(i, NumToString, 5);
		formatex(Item, charsmax(Item), "\r|\w%s\r|",pSecondaryGun[i][0][0]);menu_additem(Menu, Item, NumToString);
	}	
	menu_setprop(Menu, MPROP_EXIT, MEXIT_NEVER); menu_display(pPlayer, Menu);
}

public pSecondaryMenu_(pPlayer, menu, item) {
	new data[6], iName[64], access, callback,key;
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);
	key = str_to_num(data);
	pSecondarySave[pPlayer] = key;
	rg_give_item(pPlayer,pSecondaryGun[key][1][0]);
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

stock pOldWeapon(pPlayer){
	rg_give_item(pPlayer,pPrimaryGun[pPrimarySave[pPlayer]][1][0])
	rg_give_item(pPlayer,pSecondaryGun[pSecondarySave[pPlayer]][1][0])
}

@CBasePlayer_ImpulseCommands_Pre(const pPlayer) {
	static iImpulse;
	iImpulse = get_entvar(pPlayer, var_impulse);

	if(iImpulse == 201) {
		set_entvar(pPlayer, var_impulse, 0);
		return HC_SUPERCEDE;
	}
	return HC_CONTINUE;
}

@Ham_Weapon_SecondaryAttack_Post(pWeapon) {
	new pPlayer = get_member(pWeapon, m_pPlayer);

	g_blSilencer[pPlayer] = bool:cs_get_weapon_silen(pWeapon);
}

@CBasePlayer_AddPlayerItem_Pre(const pPlayer, const pItem) {
	if(get_member(pItem, m_iId) != WEAPON_M4A1) {
		return;
	}

	cs_set_weapon_silen(pItem, g_blSilencer[pPlayer]);
}
