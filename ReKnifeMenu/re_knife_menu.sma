#include <amxmodx>
#include <reapi>

new const tag[]="Element";

new view [MAX_CLIENTS + 1];

new knifemodel[][][]={
	{"Default", "models/v_knife.mdl"},
	{"Ursus Knife", "models/knifemodels/v_ursus_crimson.mdl"},
	{"M9 Bayonet", "models/knifemodels/v_m9_doppler.mdl"},
	{"Karambit", "models/knifemodels/v_karambit_auto.mdl"},
	{"Kelebek", "models/knifemodels/v_butterfly_marble.mdl"},
	{"Flip Knife", "models/knifemodels/v_flip_lore.mdl"}
};

public plugin_init() {
	register_plugin("[ReAPI] Knife Menu", "0.1", "mIDnight");
	
	new const menuclcmd[][]={
		"say /knifemenu", "say /knife"
	};
	for(new i;i<sizeof(menuclcmd);i++){
		register_clcmd(menuclcmd[i],"@mainmenu");
	}
	
	RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, "@CBasePlayerWeapon_DefaultDeploy_Pre", .post = false);
}

public plugin_precache() {
	for(new i = 0; i < sizeof(knifemodel); i++) {
		precache_model(knifemodel[i][1]);
	}
}

@CBasePlayerWeapon_DefaultDeploy_Pre(const pEntity, szViewModel[], szWeaponModel[], iAnim, szAnimExt[], skiplocal) {
	if(get_member(pEntity, m_iId) != WEAPON_KNIFE) {
		return;
	}
	new pPlayer = get_member(pEntity, m_pPlayer);
	
	SetHookChainArg(2, ATYPE_STRING, knifemodel[view[pPlayer]][1]);
}

@mainmenu(const id){
	new menu = menu_create(fmt("\d%s \w| \yKnife Menu", tag), "@mainmenu_continue");
	
	for(new i = 0; i < sizeof(knifemodel); i++) {
		menu_additem(menu, fmt("\d%s \w| \y%s", tag, knifemodel[i][0]), fmt("%d", i));
	}
	
	menu_setprop(menu, MPROP_EXITNAME, fmt("\d%s \w| \yExit", tag));
	menu_display(id, menu);
}

@mainmenu_continue(const id, const menu, const item) {
	if(item == MENU_EXIT) {
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	new data[6]; menu_item_getinfo(menu, item, _, data, charsmax(data));
	new key = str_to_num(data);  
	view[id] = key;
	rg_remove_item(id, "weapon_knife"); rg_give_item(id,"weapon_knife");
	menu_destroy(menu); return PLUGIN_HANDLED;
}
