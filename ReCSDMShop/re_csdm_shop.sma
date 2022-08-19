#pragma semicolon 1

#include <amxmodx>
#include <reapi>

#define ACCESS_DISCOUNT  ADMIN_LEVEL_H  // Provides discouint for VIP players (define your VIP FLAG)

new const iUstTag[]  = "\r[REVENGE]\d -";
new const iChatTag[] = "^4[REVENGE]:";

enum (+= 1337) {
	TASK_GODMODE = 1337,
	TASK_GIVEHEGRENADE,
	TASK_GIVEHEALTH,
	TASK_UNLIMITEDAMMO
}

enum _:intenum {
	iPS,
	iHeLimited,
	iHealthLimited
};
new g_int[intenum][MAX_PLAYERS+1];

enum _:cvarenum {
	cvKillTL,
	cvHealth,
	cvArmor,
	cvFastWalking,
	cvResetHPArmor,
	cvFootsteps,
	cvGodmode,
	cvKillHP,
	cv2xPS,
	cvSecondHegrenade,
	cvSecondHealth,
	cvHighJump,
	cvUnlimitedAmmo
};
new g_cvars[cvarenum];

new bool:g_blOneUse[MAX_PLAYERS+1][14];

public plugin_init() {
	register_plugin("[ReAPI] DeathMatch Shop", "0.1", "mIDnight");

	register_dictionary("re_dm_shop.txt");

	register_clcmd("say /market", "@clcmd_dmshop");
	register_clcmd("nightvision", "@clcmd_dmshop");

	RegisterHookChain(RG_CBasePlayer_Killed, "@CBasePlayer_Killed_Post", .post = true);
	RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Post", .post = true);
	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "@CBasePlayer_ResetMaxSpeed_Pre", .post = false);
	register_event("CurWeapon", "@CurWeapon_", "be", "1=1", "3=1");

	bind_pcvar_num(create_cvar("points_kill", "5"), g_cvars[cvKillTL]);		// points per kill

	bind_pcvar_num(create_cvar("50hp_price", "10"), g_cvars[cvHealth]);			// 150 hp price
	bind_pcvar_num(create_cvar("150armor_price", "8"), g_cvars[cvArmor]);			// 150 armor price
	bind_pcvar_num(create_cvar("fastwalk_price", "12"), g_cvars[cvFastWalking]);	// fast walk price
	bind_pcvar_num(create_cvar("hpapregen_price", "5"), g_cvars[cvResetHPArmor]);	// HP AP regeneration price
	bind_pcvar_num(create_cvar("silentwalk_price", "6"), g_cvars[cvFootsteps]);		// silent walk price
	bind_pcvar_num(create_cvar("godmode_price", "270"), g_cvars[cvGodmode]);			// god mode price
	bind_pcvar_num(create_cvar("hpperkill_price", "12"), g_cvars[cvKillHP]);		// hp per kill price
	bind_pcvar_num(create_cvar("2xpoints_price", "22"), g_cvars[cv2xPS]);				// 2x points price
	bind_pcvar_num(create_cvar("1minutegrenade_price", "12"), g_cvars[cvSecondHegrenade]); // 10 seconds granade price
	bind_pcvar_num(create_cvar("1minutehpregen_price", "11"), g_cvars[cvSecondHealth]);		// regen 10 hp every 10 sec price
	bind_pcvar_num(create_cvar("highjump_price", "8"), g_cvars[cvHighJump]);		// high jump
	bind_pcvar_num(create_cvar("unlimitedammo_price", "32"), g_cvars[cvUnlimitedAmmo]);		// unlimited ammo
}

@clcmd_dmshop(const id) {
	new menu = menu_create(fmt("%s DeathMatch Shop^nStatus: %s^n\dAmount in you:\r %d Points", iUstTag, get_user_flags(id) & ACCESS_DISCOUNT ? "\rVIP player":"\wNormal player", g_int[iPS][id]), "@clcmd_dmshop_");

	menu_additem(menu, fmt("%s50 HP \d[\r%d \yPS\d]", CanUsePlayer(id, isUserVip(id, g_cvars[cvHealth]), 0) ? "":"\d", isUserVip(id, g_cvars[cvHealth])));
	menu_additem(menu, fmt("%s150 AP \d[\r%d \yPS\d]", CanUsePlayer(id, isUserVip(id, g_cvars[cvArmor]), 1) ? "":"\d", isUserVip(id, g_cvars[cvArmor])));
	menu_additem(menu, fmt("%sFast walk \d[\r%d \yPS\d]", CanUsePlayer(id, isUserVip(id, g_cvars[cvFastWalking]), 2) ? "":"\d", isUserVip(id, g_cvars[cvFastWalking])));
	menu_additem(menu, fmt("%sRegenerate HP and AP \d[\r%d \yPS\d]", CanUsePlayer(id, isUserVip(id, g_cvars[cvResetHPArmor]), 3) ? "":"\d", isUserVip(id, g_cvars[cvResetHPArmor])));
	menu_additem(menu, fmt("%sSilent walk \d[\r%d \yPS\d]", CanUsePlayer(id, isUserVip(id, g_cvars[cvFootsteps]), 4) ? "":"\d", isUserVip(id, g_cvars[cvFootsteps])));
	menu_additem(menu, fmt("%sGodMode\d(10 Seconds) \d[\r%d \yPS\d]", CanUsePlayer(id, isUserVip(id, g_cvars[cvGodmode]), 5) ? "":"\d", isUserVip(id, g_cvars[cvGodmode])));
	menu_additem(menu, fmt("%sHP per kill \d[\r%d \yPS\d]", CanUsePlayer(id, isUserVip(id, g_cvars[cvKillHP]), 6) ? "":"\d", isUserVip(id, g_cvars[cvKillHP])));
	menu_additem(menu, fmt("%s2x Points \d[\r%d \yPS\d]", CanUsePlayer(id, isUserVip(id, g_cvars[cv2xPS]), 7) ? "":"\d", isUserVip(id, g_cvars[cv2xPS])));
	menu_additem(menu, fmt("%s1 bomb every 10 seconds\d(1 Minute) \d[\r%d \yPS\d]", CanUsePlayer(id, isUserVip(id, g_cvars[cvSecondHegrenade]), 8) ? "":"\d", isUserVip(id, g_cvars[cvSecondHegrenade])));
	menu_additem(menu, fmt("%s10 HP every 10 seconds\d(1 Minute) \d[\r%d \yPS\d]", CanUsePlayer(id, isUserVip(id, g_cvars[cvSecondHealth]), 9) ? "":"\d", isUserVip(id, g_cvars[cvSecondHealth])));
	menu_additem(menu, fmt("%sHigh jump \d[\r%d \yPS\d]", CanUsePlayer(id, isUserVip(id, g_cvars[cvHighJump]), 10) ? "":"\d", isUserVip(id, g_cvars[cvHighJump])));
	menu_additem(menu, fmt("%sUnlimited bullets\d(30 Seconds) \d[\r%d \yPS\d]", CanUsePlayer(id, isUserVip(id, g_cvars[cvUnlimitedAmmo]), 11) ? "":"\d", isUserVip(id, g_cvars[cvUnlimitedAmmo])));

	menu_setprop(menu, MPROP_EXITNAME, "\rExit");
	menu_setprop(menu, MPROP_SHOWPAGE, 0);
	menu_display(id, menu);
}
@clcmd_dmshop_(const id, menu, item) {
	switch(item) {
		case 0: buyitem(id, "50 HP", isUserVip(id, g_cvars[cvHealth]), 0);
		case 1: buyitem(id, "150 AP", isUserVip(id, g_cvars[cvArmor]), 1);
		case 2: buyitem(id, "Fast walk", isUserVip(id, g_cvars[cvFastWalking]), 2);
		case 3: buyitem(id, "Regenerate HP and AP", isUserVip(id, g_cvars[cvResetHPArmor]), 3);
		case 4: buyitem(id, "Silent walk", isUserVip(id, g_cvars[cvFootsteps]), 4);
		case 5: buyitem(id, "GodMode", isUserVip(id, g_cvars[cvGodmode]), 5);
		case 6: buyitem(id, "HP per kill", isUserVip(id, g_cvars[cvKillHP]), 6);
		case 7: buyitem(id, "2x Points", isUserVip(id, g_cvars[cv2xPS]), 7);
		case 8: buyitem(id, "1 bomb every 10 seconds", isUserVip(id, g_cvars[cvSecondHegrenade]), 8);
		case 9: buyitem(id, "10 HP every 10 seconds", isUserVip(id, g_cvars[cvSecondHealth]), 9);
		case 10: buyitem(id, "High jump", isUserVip(id, g_cvars[cvHighJump]), 10);
		case 11: buyitem(id, "Unlimited bullets", isUserVip(id, g_cvars[cvUnlimitedAmmo]), 11);
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public buyitem(const id, szItem[], iCost, iType) {
	if(g_blOneUse[id][iType]){
		client_print_color(id, id, "%l", "ONE_USE", iChatTag);
		return PLUGIN_HANDLED;
	}
	else if(g_int[iPS][id] >= iCost) {
		g_int[iPS][id] -= iCost;
		g_blOneUse[id][iType] = true;
		client_print_color(id, id, "%l", "BUY_ITEM", iChatTag, szItem);
		switch(iType){
			case 0: {
				set_entvar(id, var_health, Float:get_entvar(id, var_health) +50.0);
				if(Float:get_entvar(id, var_health) > 150.0) {
					set_entvar(id, var_health, 150.0);
				}
			}
			case 1: {
				set_entvar(id, var_armorvalue, Float:get_entvar(id, var_armorvalue) +150.0);
			}
			case 2: {
				set_entvar(id, var_maxspeed, 350.0);
			}
			case 3: {
				set_entvar(id, var_health, 100.0);
				set_entvar(id, var_armorvalue, 100.0);
			}
			case 4: {
				rg_set_user_footsteps(id, true);
			}
			case 5: {
				set_entvar(id, var_takedamage, DAMAGE_NO);
				if(!task_exists(id + TASK_GODMODE)){
					set_task(10.0, "GodmodeClose", id + TASK_GODMODE);
				}
			}
			case 8: {
				rg_give_item(id, "weapon_hegrenade");
				set_task(10.0, "GiveHegrenade", id + TASK_GIVEHEGRENADE, .flags = "b");
			}
			case 9: {
				set_entvar(id, var_health, Float:get_entvar(id, var_health) +10.0);
				set_task(10.0, "GiveHealth", id + TASK_GIVEHEALTH, .flags = "b");
			}
			case 10: {
				set_entvar(id, var_gravity, 0.6);
			}
			case 11: {
				set_task(30.0, "UnlimitedAmmoClose", id + TASK_UNLIMITEDAMMO);
			}
		}
	}
	else {
		client_print_color(id, id, "%l", "INSUFFICIENT_COST", iChatTag);
		return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}

bool:CanUsePlayer(const id, cvCvars, iType) {
	if(g_blOneUse[id][iType]) {
		return false;
	}
	else if(g_int[iPS][id] >= cvCvars) {
		return true;
	}
	return false;
}

public isUserVip(const id, iCost) {
	if(get_user_flags(id) & ACCESS_DISCOUNT) {
		if(iCost > 10){
			iCost = iCost-5;
		}
		else {
			iCost = iCost-2;
		}
	}
	return iCost;
}

@CBasePlayer_ResetMaxSpeed_Pre(const id) {
	if(g_blOneUse[id][2]) {
		set_entvar(id, var_maxspeed, 450.0);
		return HC_SUPERCEDE;
	}
	return HC_CONTINUE;
}

@CBasePlayer_Killed_Post(const this, pevAttacker, iGib) {
	if(!(is_user_connected(this) || is_user_connected(pevAttacker)) || this == pevAttacker) {
		return;
	}

	if(g_blOneUse[pevAttacker][6]) {
		set_entvar(pevAttacker, var_health, Float:get_entvar(pevAttacker, var_health) +10.0);
	}
	if(g_blOneUse[pevAttacker][7]) {
		g_int[iPS][pevAttacker] += g_cvars[cvKillTL]*2;
	}
	else {
		g_int[iPS][pevAttacker] += g_cvars[cvKillTL];
	}
}

@CBasePlayer_Spawn_Post(const id) {
	if(get_member(id, m_bJustConnected)) {
		return;
	}
	ResetData(id);
	rg_reset_user_model(id);
}

@CurWeapon_(const id) {
	if(g_blOneUse[id][11]) {
		set_member(get_member(id, m_pActiveItem), m_Weapon_iClip, rg_get_weapon_info(read_data(2), WI_GUN_CLIP_SIZE));
	}
}

/**************************** Tasks Close ***************************/
public GodmodeClose(Taskid) {
	new id = Taskid - TASK_GODMODE;

	set_entvar(id, var_takedamage, DAMAGE_AIM);
	client_print_color(id, id, "%l", "GODMODE_CLOSE", iChatTag);
}

public GiveHegrenade(Taskid) {
	new id = Taskid - TASK_GIVEHEGRENADE;

	if(rg_has_item_by_name(id, "weapon_hegrenade")) {
		rg_set_user_bpammo(id, WEAPON_HEGRENADE, rg_get_user_bpammo(id, WEAPON_HEGRENADE)+1);
	}
	else {
		rg_give_item(id, "weapon_hegrenade");
		rg_set_user_bpammo(id, WEAPON_HEGRENADE, 1);
	}
	g_int[iHeLimited][id]++;

	if(g_int[iHeLimited][id] >= 6) {
		remove_task(id + TASK_GIVEHEGRENADE);
		client_print_color(id, id, "%l", "GIVE_HEGRENADE_CLOSE", iChatTag);
	}
}

public GiveHealth(Taskid) {
	new id = Taskid - TASK_GIVEHEALTH;

	set_entvar(id, var_health, Float:get_entvar(id, var_health) +10.0);
	g_int[iHealthLimited][id]++;

	if(g_int[iHealthLimited][id] >= 6) {
		remove_task(id + TASK_GIVEHEALTH);
		client_print_color(id, id, "%l", "GIVE_HEALTH_CLOSE", iChatTag);
	}
}

public UnlimitedAmmoClose(Taskid) {
	new id = Taskid - TASK_UNLIMITEDAMMO;

	g_blOneUse[id][11] = false;
	client_print_color(id, id, "%l", "UNLIMITED_AMMO_CLOSE", iChatTag);
}

public client_disconnected(id) {
	ResetData(id);
	g_int[iPS][id] = 0;
}

public client_connect(id) {
	ResetData(id);
}

public ResetData(const id) {
	remove_task(id + TASK_GODMODE);
	remove_task(id + TASK_GIVEHEGRENADE);
	remove_task(id + TASK_GIVEHEALTH);
	remove_task(id + TASK_UNLIMITEDAMMO);

	g_int[iHeLimited][id] = 0;
	g_int[iHealthLimited][id] = 0;

	for(new i = 0; i <= 13; i++) {
		g_blOneUse[id][i] = false;
	}
}
