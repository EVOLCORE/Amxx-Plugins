#pragma semicolon 1

#include <amxmodx>
#include <nvault>
#include <reapi>

#define	var_wmodel	var_targetname

new const g_szWeaponFile[] = "models/awp_models";

new const g_szWeaponNames[][] = {
	"Default",
	"DragonLore",
	"Abstract",
	"Cyrex",
	"Phobos",
	"Asiimov",
	"Tiger"
};

new const g_szTag[] = "Element";

new g_iAwp[MAX_CLIENTS + 1],
	g_iMenu,
	g_iVault;

public plugin_init() {
	register_plugin("[ReAPI] AWP menu", "1.1", "mIDnight");

	register_clcmd("say /awp", "@clcmd_awp"); register_clcmd("nightvision", "@clcmd_awp");

	RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, "@CBasePlayerWeapon_DefaultDeploy_Pre", .post = false);
	RegisterHookChain(RG_CWeaponBox_SetModel, "@CWeaponBox_SetModel_Pre", .post = false);
	RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "@RG_CBasePlayer_AddPlayerItem_Post", .post = true);

	@menu_awp();
}

public plugin_precache() {
	for(new i = 1; i < sizeof(g_szWeaponNames); i++) {
		precache_model(fmt("%s/v_%s.mdl", g_szWeaponFile, g_szWeaponNames[i]));
		precache_model(fmt("%s/p_%s.mdl", g_szWeaponFile, g_szWeaponNames[i]));
		precache_model(fmt("%s/w_%s.mdl", g_szWeaponFile, g_szWeaponNames[i]));
	}
}

@clcmd_awp(const pPlayer) {
	menu_display(pPlayer, g_iMenu);
	return PLUGIN_HANDLED;
}

@menu_awp() {
	g_iMenu = menu_create(fmt("\d[\r%s\d] \w|| \yAWP Skin Menu", g_szTag), "@menu_awp_handler");

	for(new i = 0; i < sizeof(g_szWeaponNames); i++) {
		menu_additem(g_iMenu, fmt("\y|\r%s\y| \d- \w%s", g_szTag, g_szWeaponNames[i]));
	}

	menu_setprop(g_iMenu, MPROP_EXITNAME, fmt("\y|\r%s\y| \w- \wExit", g_szTag));
}

@menu_awp_handler(const pPlayer, const iMenu, const iItem) {
	if(iItem == MENU_EXIT) {
		return PLUGIN_HANDLED;
	}

	g_iAwp[pPlayer] = iItem;
	rg_send_audio(pPlayer, "events/enemy_died.wav");
	client_print_color(pPlayer, 0, "^4[%s] ^1Model ^3%s ^1has been successfully activated.", g_szTag, g_szWeaponNames[iItem]);

	if(rg_has_item_by_name(pPlayer, "weapon_awp")) {
		new iAmmo = rg_get_user_ammo(pPlayer, WEAPON_AWP);
		new iBpAmmo = rg_get_user_bpammo(pPlayer, WEAPON_AWP);

		rg_remove_item(pPlayer, "weapon_awp");

		new iWeapon = rg_give_custom_item(pPlayer, "weapon_awp", GT_APPEND, iItem);
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
		SetHookChainArg(2, ATYPE_STRING, fmt("%s/v_%s.mdl", g_szWeaponFile, g_szWeaponNames[iAwpModel]));
		SetHookChainArg(3, ATYPE_STRING, fmt("%s/p_%s.mdl", g_szWeaponFile, g_szWeaponNames[iAwpModel]));
	}
}

@CWeaponBox_SetModel_Pre(const iWeaponBox, const szModelName[]) {
	new iWeapon = GetWeaponBoxWeapon(iWeaponBox);

	if(iWeapon == NULLENT || get_member(iWeapon, m_iId) != WEAPON_AWP) {
		return;
	}

	new iImpulse = get_entvar(iWeapon, var_impulse);

	if(iImpulse > 0) {
		SetHookChainArg(2, ATYPE_STRING, fmt("%s/w_%s.mdl", g_szWeaponFile, g_szWeaponNames[iImpulse]));
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
		set_entvar(iWeapon, var_wmodel, fmt("%s/w_%s.mdl", g_szWeaponFile, g_szWeaponNames[g_iAwp[pPlayer]]));
	}
}

public plugin_cfg() {
	g_iVault = nvault_open("Players_AWP_Models");

	if(g_iVault == INVALID_HANDLE) {
		set_fail_state("Vault error");
	}
}

public plugin_end() {
	nvault_close(g_iVault);
}

public client_authorized(pPlayer, const szAuthid[]) {
	g_iAwp[pPlayer] = nvault_get(g_iVault, szAuthid);
}

public client_disconnected(pPlayer) {
	new szAuthid[MAX_AUTHID_LENGTH];
	get_user_authid(pPlayer, szAuthid, charsmax(szAuthid));

	nvault_pset(g_iVault, szAuthid, fmt("%i", g_iAwp[pPlayer]));
}
