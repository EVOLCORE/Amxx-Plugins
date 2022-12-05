#pragma semicolon 1

#include <amxmodx>
#include <crs>
#include <reapi>

#define	var_wmodel	var_targetname

#define register_cmd_list(%0,%1,%2)            for (new i = 0; i < sizeof(%1); i++) register_%0(%1[i], %2)

new const g_szWeaponFile[] = "models/awp_models";

enum _:mdl_struct {
	mdl_name[64],
	mdl_value
}

// Model name, min exp to use skin
new const g_szWeaponNames[][mdl_struct] = {
	{"Default", 0},
	{"DragonLore", 1000},
	{"Abstract", 3500},
	{"Cyrex", 5000},
	{"Phobos", 6500},
	{"Asiimov", 8000},
	{"Tiger", 10000}
};

new const g_szTag[] = "Element";

new g_iAwp[MAX_CLIENTS + 1],
	g_iMenu;

public plugin_init() {
	register_plugin("[ReAPI] AWP menu", "1.1", "mIDnight");

	new szAWPMenu[][] = {"say /awp", "say_team /awp", "nightvision", "awp_skin"};

	register_cmd_list(clcmd, szAWPMenu, "@clcmd_awp");

	RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, "@CBasePlayerWeapon_DefaultDeploy_Pre", .post = false);
	RegisterHookChain(RG_CWeaponBox_SetModel, "@CWeaponBox_SetModel_Pre", .post = false);
	RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "@RG_CBasePlayer_AddPlayerItem_Post", .post = true);
}

public plugin_precache() {
	for(new i = 1; i < sizeof(g_szWeaponNames); i++) {
		precache_model(fmt("%s/v_%s.mdl", g_szWeaponFile, g_szWeaponNames[i][mdl_name]));
		precache_model(fmt("%s/p_%s.mdl", g_szWeaponFile, g_szWeaponNames[i][mdl_name]));
		precache_model(fmt("%s/w_%s.mdl", g_szWeaponFile, g_szWeaponNames[i][mdl_name]));
	}
}

@clcmd_awp(const pPlayer) {
	g_iMenu = menu_create(fmt("\d[\r%s\d] \w|| \yAWP Skin Menu", g_szTag), "@menu_awp_handler");

	for(new i = 0; i < sizeof(g_szWeaponNames); i++) {
		if(csd_get_user_xp(pPlayer) >= g_szWeaponNames[i][mdl_value]) {
			menu_additem(g_iMenu, fmt("\w%s", g_szWeaponNames[i][mdl_name]), fmt("%i", i));
		}
	}
	menu_setprop(g_iMenu, MPROP_EXITNAME, fmt("\rExit"));

	menu_display(pPlayer, g_iMenu);
	return PLUGIN_HANDLED;
}


@menu_awp_handler(const pPlayer, const iMenu, const iItem) {
	if(iItem < 0) {
		menu_destroy(iMenu);
		return PLUGIN_HANDLED;
	}

	new szId[6];
	menu_item_getinfo(iMenu, iItem, .info = szId, .infolen = charsmax(szId));
	menu_destroy(iMenu);

	new iIndex = str_to_num(szId);
	g_iAwp[pPlayer] = iIndex;
	rg_send_audio(pPlayer, "events/enemy_died.wav");
	client_print_color(pPlayer, print_team_default, "^4[%s] ^1Model ^3%s ^1has been successfully activated.", g_szTag, g_szWeaponNames[iIndex][mdl_name]);

	if(rg_has_item_by_name(pPlayer, "weapon_awp")) {
		new iAmmo = rg_get_user_ammo(pPlayer, WEAPON_AWP);
		new iBpAmmo = rg_get_user_bpammo(pPlayer, WEAPON_AWP);

		rg_remove_item(pPlayer, "weapon_awp");

		rg_give_custom_item(pPlayer, "weapon_awp", GT_APPEND, iIndex);
		rg_set_user_ammo(pPlayer, WEAPON_AWP, iAmmo);
		rg_set_user_bpammo(pPlayer, WEAPON_AWP, iBpAmmo);
	}

	return PLUGIN_HANDLED;
}

@CBasePlayerWeapon_DefaultDeploy_Pre(const iWeapon, szViewModel[], szWeaponModel[], iAnim, szAnimExt[], skiplocal) {
	if(get_member(iWeapon, m_iId) != WEAPON_AWP) {
		return;
	}

	new pPlayer = get_member(iWeapon, m_pPlayer);

	new iAwpModel = g_iAwp[pPlayer];

	if(iAwpModel > 0) {
		SetHookChainArg(2, ATYPE_STRING, fmt("%s/v_%s.mdl", g_szWeaponFile, g_szWeaponNames[iAwpModel][mdl_name]));
		SetHookChainArg(3, ATYPE_STRING, fmt("%s/p_%s.mdl", g_szWeaponFile, g_szWeaponNames[iAwpModel][mdl_name]));
	}
}

@CWeaponBox_SetModel_Pre(const iWeaponBox, const szModelName[]) {
	new iWeapon = GetWeaponBoxWeapon(iWeaponBox);

	if(iWeapon == NULLENT || get_member(iWeapon, m_iId) != WEAPON_AWP) {
		return;
	}

	new iImpulse = get_entvar(iWeapon, var_impulse);

	if(iImpulse > 0) {
		SetHookChainArg(2, ATYPE_STRING, fmt("%s/w_%s.mdl", g_szWeaponFile, g_szWeaponNames[iImpulse][mdl_name]));
	}
}

GetWeaponBoxWeapon(const iWeaponBox) {
	for(new i = 0, iWeapon; i < MAX_ITEM_TYPES; i++) {

		iWeapon = get_member(iWeaponBox, m_WeaponBox_rgpPlayerItems, i);

		if(!is_nullent(iWeapon)) {
			return iWeapon;
		}
	}
	return NULLENT;
}

@RG_CBasePlayer_AddPlayerItem_Post(const pPlayer, const iWeapon) {
	if(is_nullent(iWeapon) || get_member(iWeapon, m_iId) != WEAPON_AWP) {
		return;
	}

	new wmodel[32];
	get_entvar(iWeapon, var_wmodel, wmodel, charsmax(wmodel));

	if(wmodel[0] == EOS && g_iAwp[pPlayer] > 0) {
		set_entvar(iWeapon, var_wmodel, fmt("%s/w_%s.mdl", g_szWeaponFile, g_szWeaponNames[g_iAwp[pPlayer]][mdl_name]));
	}
}
