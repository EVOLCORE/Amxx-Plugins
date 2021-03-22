#include <amxmodx>
#include <reapi>
#include <nvault>

#pragma semicolon 1
#pragma dynamic 32768	

new const Awp1[] = "models/awp_models/v_awp_dragonlore.mdl";
new const Awp2[] = "models/awp_models/v_awp_abstract.mdl";
new const Awp3[] = "models/awp_models/v_awp_cyrex.mdl";
new const Awp4[] = "models/awp_models/v_awp_phobos.mdl";
new const Awp5[] = "models/awp_models/v_awp_asiimov.mdl";
new const Awp6[] = "models/awp_models/v_awp_tiger.mdl";
new const AwpD[] = "models/v_awp.mdl"; 	//DEFAULT AWP

#define SayTag "^4Element"
new const TAG[] = "Element";

new awp[MAX_CLIENTS+1];
new g_Vault;

public plugin_init() {
	register_plugin("[ReAPI] AWP Menu", "1.0", "mIDnight");

	register_clcmd("nightvision","@AWP_Menu");
	register_clcmd("say /awpmenu", "@AWP_Menu");
	register_event("CurWeapon", "ChangeWeapon", "be", "1=1");
}

public plugin_precache() {
    precache_model(Awp1);
    precache_model(Awp2);
    precache_model(Awp3);
    precache_model(Awp4);
    precache_model(Awp5);
    precache_model(Awp6);
}

public client_connect(id) {
    LoadData(id);
}

public client_disconnected(id) {
    SaveData(id);
}

@AWP_Menu(id) {
	static Item[128];

	formatex(Item, charsmax(Item), "\d[\r%s\d] \w|| \yAWP Skin Menu",TAG);
	new Menu = menu_create(Item, "@Menu_Handler");

	formatex(Item, charsmax(Item), "\y|\r%s\y| \d- \wDragon Lore",TAG),menu_additem(Menu, Item, "1");
	formatex(Item, charsmax(Item), "\y|\r%s\y| \d- \wAbstract",TAG),menu_additem(Menu, Item, "2");
	formatex(Item, charsmax(Item), "\y|\r%s\y| \d- \wCyrex",TAG),menu_additem(Menu, Item, "3");
	formatex(Item, charsmax(Item), "\y|\r%s\y| \d- \wPhobos",TAG),menu_additem(Menu, Item, "4");
	formatex(Item, charsmax(Item), "\y|\r%s\y| \d- \wAsiimov",TAG),menu_additem(Menu, Item, "5");
	formatex(Item, charsmax(Item), "\y|\r%s\y| \d- \wTiger",TAG),menu_additem(Menu, Item, "6"); 
	formatex(Item, charsmax(Item), "\y|\r%s\y| \d- \wAwp Default^n",TAG),menu_additem(Menu, Item, "7"); 
	formatex(Item, charsmax(Item), "\y|\r%s\y| \w- \wExit", TAG), menu_setprop(Menu, MPROP_EXITNAME, Item), menu_display(id, Menu, 0);

	return PLUGIN_HANDLED;
}

@Menu_Handler(id, Menu, Item) {
	if(Item == MENU_EXIT) {
		menu_destroy(Menu);
		return PLUGIN_HANDLED;
	}
	
	new Access, Data[6], Menu_Name[64], Call_Back;
	menu_item_getinfo(Menu, Item, Access, Data, 5, Menu_Name, 63, Call_Back);
	new Key = str_to_num(Data);
	
	switch(Key)
	{
		case 1: {
			awp[id] = 1;
			ChangeWeapon(id);
			client_cmd(id,"spk ^"events/enemy_died^"");
			client_print_color(id, 0, "^4[%s]^1 Successful ^3Dragon Lore ^1Activated!", SayTag);
		}   
		case 2: {
			awp[id] = 2;
			ChangeWeapon(id);
			client_cmd(id,"spk ^"events/enemy_died^"");
			client_print_color(id, 0, "^4[%s]^1 Successful ^3Abstract ^1Activated!", SayTag);
		}
		case 3: {
			awp[id] = 3;
			ChangeWeapon(id);
			client_cmd(id,"spk ^"events/enemy_died^"");
			client_print_color(id, 0, "^4[%s]^1 Successful ^3Cyrex ^1Activated!", SayTag);
		}
		case 4: {
			awp[id] = 4;
			ChangeWeapon(id);
			client_cmd(id,"spk ^"events/enemy_died^"");
			client_print_color(id, 0, "^4[%s]^1 Successful ^3Phobos ^1Activated!", SayTag);
		}
		case 5: {
			awp[id] = 5;
			ChangeWeapon(id);
			client_cmd(id,"spk ^"events/enemy_died^"");
			client_print_color(id, 0, "^4[%s]^1 Successful ^3Asiimov ^1Activated!", SayTag);
		}
		case 6: {
			awp[id] = 6;
			ChangeWeapon(id);
			client_cmd(id,"spk ^"events/enemy_died^"");
			client_print_color(id, 0, "^4[%s]^1 Successful ^3Tiger ^1Activated!", SayTag);
		}
		case 7: {
			awp[id] = 7;
			ChangeWeapon(id);
			client_cmd(id,"spk ^"events/enemy_died^"");
			client_print_color(id, 0, "^4[%s]^1 Successful ^3AWP Default ^1Activated!", SayTag);
		}
	}
	menu_destroy(Menu);
	return PLUGIN_HANDLED;
}

ChangeWeapon(id) {
	new weaponID = get_user_weapon(id);

	if(weaponID == CSW_AWP) {
	switch(awp[id]){
		case 1 : {
				set_entvar(id,var_viewmodel,Awp1);
			}
		case 2 : {
				set_entvar(id,var_viewmodel,Awp2);
			}
		case 3 : {
				set_entvar(id,var_viewmodel,Awp3);
			}
		case 4 : {
				set_entvar(id,var_viewmodel,Awp4);
			}
		case 5 : {
				set_entvar(id,var_viewmodel,Awp5);
			}
		case 6 : {
				set_entvar(id,var_viewmodel,Awp6);
			}
		case 7 : {
				set_entvar(id,var_viewmodel,AwpD);
			}
		}
	}
}

public plugin_cfg() {
    g_Vault = nvault_open("Players_AWP_Models");
    
    if ( g_Vault == INVALID_HANDLE )
        set_fail_state( "File Not Found!" )  ;  
}

public plugin_end() {
    nvault_close(g_Vault);
}

SaveData(id) {
    new szAuth[33],szData[6];
    get_user_authid(id , szAuth , charsmax(szAuth));
    num_to_str(awp[id],szData,5);
    nvault_pset(g_Vault,szAuth ,szData); 
}

LoadData(id) {
    new szAuth[33];
    get_user_authid(id , szAuth , charsmax(szAuth));
    awp[id] = nvault_get(g_Vault,szAuth);
}
