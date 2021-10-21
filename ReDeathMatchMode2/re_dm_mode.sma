#include <amxmodx>
#include <reapi>

#define TAG "HW"

#define START_HOUR 		01					// Hour night mode start
#define END_HOUR 		12					// Hour night mode end

new bool:CSDM_Mode = true;
new g_iMenu;

public plugin_init() {
    register_plugin("[ReAPI] Mode switch", "1.0", "mIDnight");

    RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn", .post = true);

    set_task(0.1, "OnConfigsExecuted");

    g_iMenu = menu_create("\r[HyperWorld] \yChoose your free guns", "@Menu_Handler");
    menu_additem(g_iMenu, "AK47");
    menu_additem(g_iMenu, "M4A1");
}

public OnConfigsExecuted() {
    new hours[32];
    get_time("%H", hours, 31);
    new h_num = str_to_num(hours);
    if((h_num >= START_HOUR) && (h_num <= END_HOUR)) {
        CSDM_Mode = true;
        set_pcvar_num(get_cvar_pointer("sv_restart"), 3);
        set_pcvar_num(get_cvar_pointer("mp_forcerespawn"), 1);
        set_pcvar_num(get_cvar_pointer("mp_buytime"), 0);
        set_pcvar_num(get_cvar_pointer("mp_infinite_ammo"), 2);
        set_pcvar_num(get_cvar_pointer("mp_give_player_c4"), 0);
        set_pcvar_num(get_cvar_pointer("mp_round_infinite"), 1);
        set_pcvar_num(get_cvar_pointer("mp_roundtime"), 0);
        set_pcvar_num(get_cvar_pointer("mp_item_staytime"), 0);
        client_print_color(0, 0, "^4[%s] ^1DeathMatch mode activated. Hour: ^3%d:00", TAG, START_HOUR);
    }
    else {
        CSDM_Mode = false;
        set_pcvar_num(get_cvar_pointer("sv_restart"), 3);
        set_pcvar_num(get_cvar_pointer("mp_forcerespawn"), 0);
        set_pcvar_float(get_cvar_pointer("mp_buytime"), 0.25);
        set_pcvar_num(get_cvar_pointer("mp_infinite_ammo"), 0);
        set_pcvar_num(get_cvar_pointer("mp_give_player_c4"), 1);
        set_pcvar_num(get_cvar_pointer("mp_round_infinite"), 0);
        set_pcvar_num(get_cvar_pointer("mp_roundtime"), 2);
        set_pcvar_num(get_cvar_pointer("mp_item_staytime"), 300);
        client_print_color(0, 0, "^4[%s] ^1Public mode activated. Hour: ^3%d:00", TAG, END_HOUR);
    }
    set_task(300.0, "OnConfigsExecuted");
    return PLUGIN_HANDLED;
}

@CBasePlayer_Spawn(id) {
    if(!is_user_alive(id) || !is_user_connected(id) || !CSDM_Mode) {
        return;
    }
    menu_display(id, g_iMenu);
}

@Menu_Handler(id, iMenu, iItem) {
	if(!is_user_connected(id)) {
		return;
	}
	switch(iItem) {
		case MENU_EXIT: {
			menu_cancel(id);
			return;
		}
		case 0: {
			rg_give_item(id, "weapon_ak47", GT_REPLACE);
			rg_set_user_bpammo(id, WEAPON_AK47, 90);
		}
		case 1: {
			rg_give_item(id, "weapon_m4a1", GT_REPLACE);
			rg_set_user_bpammo(id, WEAPON_M4A1, 90);
		}
	}
	rg_give_item(id, "weapon_deagle", GT_REPLACE);
	rg_set_user_bpammo(id, WEAPON_DEAGLE, 35);
}
