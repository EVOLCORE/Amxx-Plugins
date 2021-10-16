#include <amxmodx>
#include <reapi>

#define TAG "HW"

#define START_HOUR 		15					// Hour night mode start
#define END_HOUR 		16					// Hour night mode end

new bool:IsNightMode;

public plugin_init() {
    register_plugin("[ReAPI] Mode switch", "1.0", "mIDnight");

    RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn", .post = true);
//    RegisterHookChain(RG_CSGameRules_RestartRound, "@CSGameRules_RestartRound", .post = true);
}

public OnConfigsExecuted() {
    new __hour; time(__hour);	IsNightMode = bool:(__hour > START_HOUR || __hour < END_HOUR);
    if(IsNightMode) {
        set_pcvar_num(get_cvar_pointer("sv_restart"), 3);
        set_pcvar_num(get_cvar_pointer("mp_forcerespawn"), 1);
        set_pcvar_num(get_cvar_pointer("mp_buytime"), 0);
        set_pcvar_num(get_cvar_pointer("mp_infinite_ammo"), 2);
        set_pcvar_num(get_cvar_pointer("mp_give_player_c4"), 0);
        set_pcvar_num(get_cvar_pointer("mp_round_infinite"), 1);
        set_pcvar_num(get_cvar_pointer("mp_roundtime"), 1);
        set_pcvar_num(get_cvar_pointer("mp_item_staytime"), 0);
        client_print_color(0, 0, "^4[%s] ^1DeathMatch mode activated. Hour: ^3%d:00", TAG, START_HOUR);
    }
    else {
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
}

/*@CSGameRules_RestartRound() {
    if(IsNightMode) {
        set_pcvar_num(get_cvar_pointer("mp_forcerespawn"), 1);
        set_pcvar_num(get_cvar_pointer("mp_buytime"), 0);
        set_pcvar_num(get_cvar_pointer("mp_infinite_ammo"), 2);
        set_pcvar_num(get_cvar_pointer("mp_give_player_c4"), 0);
        set_pcvar_num(get_cvar_pointer("mp_round_infinite"), 1);
        set_pcvar_num(get_cvar_pointer("mp_roundtime"), 1);
        set_pcvar_num(get_cvar_pointer("mp_item_staytime"), 0);
        client_print_color(0, 0, "^4[%s] ^1DeathMatch mode activated. Hour: ^3%d:00", TAG, START_HOUR)
    }
    else {
        set_pcvar_num(get_cvar_pointer("mp_forcerespawn"), 0);
        set_pcvar_float(get_cvar_pointer("mp_buytime"), 0.25);
        set_pcvar_num(get_cvar_pointer("mp_infinite_ammo"), 0);
        set_pcvar_num(get_cvar_pointer("mp_give_player_c4"), 1);
        set_pcvar_num(get_cvar_pointer("mp_round_infinite"), 0);
        set_pcvar_num(get_cvar_pointer("mp_roundtime"), 2);
        set_pcvar_num(get_cvar_pointer("mp_item_staytime"), 300);
        client_print_color(0, 0, "^4[%s] ^1Public mode activated. Hour: ^3%d:00", TAG, START_HOUR)
    }
} */

@CBasePlayer_Spawn(id) {
    if(!is_user_alive(id) || !is_user_connected(id) || !IsNightMode) {
        return;
    }
    rg_remove_all_items(id)
    rg_give_item(id, "weapon_m4a1");
    rg_set_user_bpammo(id, WEAPON_M4A1, 90);
    rg_give_item(id, "weapon_ak47");
    rg_set_user_bpammo(id, WEAPON_AK47, 90);
    rg_give_item(id, "weapon_deagle");
    rg_set_user_bpammo(id,WEAPON_DEAGLE, 35);
    rg_give_item(id, "weapon_knife");
}
