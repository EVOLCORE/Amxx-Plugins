#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <reapi>

new const SayTag[] = "HW";

#define register_cmd_list(%0,%1,%2)            for (new i = 0; i < sizeof(%1); i++) register_%0(%1[i], %2)

enum MenuNames {
    WeaponMenu,
    PrimaryMenu,
    SecondaryMenu
}
new g_iMenu[MenuNames];

new const g_szPrimaryWeapons[][][] = {
    {"M4A1","weapon_m4a1"},
    {"AK47","weapon_ak47"},
    {"AWP","weapon_awp"},
    {"FAMAS","weapon_famas"},
    {"GALIL","weapon_galil"}
};

new const g_szSecondaryWeapons[][][] = {
    {"USP","weapon_usp"},
    {"GLOCK","weapon_glock18"},
    {"DEAGLE","weapon_deagle"}
};

new g_iPrimaryWeaponSave[MAX_CLIENTS + 1],
    g_iSecondaryWeaponSave[MAX_CLIENTS + 1],
    bool:g_blChosenWeapon[MAX_CLIENTS + 1],
    bool:g_blM4a1Silencer[MAX_CLIENTS + 1];

public plugin_init() {
	register_plugin("[ReAPI] CSDM Weapons menu", "0.0.3", "mIDnight");

	new szWeaponMenu[][] = {"say /guns", "say_team /guns", "say /weapons", "say_team /weapons"};

	register_cmd_list(clcmd, szWeaponMenu, "@clcmd_weaponmenu");

	RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Post", .post = true);
	RegisterHookChain(RG_CBasePlayer_ImpulseCommands, "@CBasePlayer_ImpulseCommands_Pre", .post = false);
	RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "@CBasePlayer_AddPlayerItem_Pre", .post = false);
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_m4a1", "@Ham_Weapon_SecondaryAttack_Post", .Post = true);
	@RegisterMenus();
}

public client_disconnected(pPlayer) {
   g_blChosenWeapon[pPlayer] = false;
   g_blM4a1Silencer[pPlayer] = false;
}

@clcmd_weaponmenu(const pPlayer) {
   if(g_blChosenWeapon[pPlayer]) {
      g_blChosenWeapon[pPlayer] = false;
      client_print_color(pPlayer, pPlayer, "^4[%s]^1 You have activated the weapon menu. Next time you can choose a new weapon again.", SayTag);
   }
}

@CBasePlayer_Spawn_Post(const pPlayer) {
   if(get_member(pPlayer, m_bJustConnected)) {
      return;
   }
   
   set_member(pPlayer, m_iHideHUD, get_member(pPlayer, m_iHideHUD) | (HIDEHUD_TIMER | HIDEHUD_MONEY));
   rg_remove_all_items(pPlayer);
   rg_give_item(pPlayer, "weapon_knife");
   set_entvar(pPlayer, var_armorvalue, 100.0);

   g_blChosenWeapon[pPlayer] ? @GiveOldWeapons(pPlayer) : menu_display(pPlayer, g_iMenu[WeaponMenu]);
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

@CBasePlayer_AddPlayerItem_Pre(const pPlayer, const pItem) {
   if(get_member(pItem, m_iId) != WEAPON_M4A1) {
      return;
   }
   cs_set_weapon_silen(pItem, g_blM4a1Silencer[pPlayer]);
}

@Ham_Weapon_SecondaryAttack_Post(pWeapon) {
   g_blM4a1Silencer[get_member(pWeapon, m_pPlayer)] = bool:cs_get_weapon_silen(pWeapon);
}

@RegisterMenus() {
   //Weapon Menu
   g_iMenu[WeaponMenu] = menu_create("\y|\rHyperWorld\y| \d- \yWeapons Menu", "@WeaponMenu_Handler");

   menu_additem(g_iMenu[WeaponMenu], "\r|\wNew Weapons\r|");
   menu_additem(g_iMenu[WeaponMenu], "\r|\wPrevious Weapons\r|");
   menu_additem(g_iMenu[WeaponMenu], "\r|\w2+Don't show menu again\r|");

   menu_setprop(g_iMenu[WeaponMenu], MPROP_EXIT, MEXIT_NEVER);

   //Primary Menu
   g_iMenu[PrimaryMenu] = menu_create("\y|\rHyperWorld\y| \d- \yPrimary Weapon Selection", "@PrimaryMenu_Handler");

   for(new i = 0; i < sizeof(g_szPrimaryWeapons); i++) {
      menu_additem(g_iMenu[PrimaryMenu], fmt("\r|\w%s\r|", g_szPrimaryWeapons[i][0][0]));
   }
   menu_setprop(g_iMenu[PrimaryMenu], MPROP_EXIT, MEXIT_NEVER);

   //Second Menu
   g_iMenu[SecondaryMenu] = menu_create("\y|\rHyperWorld\y| \d- \ySecondary Weapon Selection", "@SecondaryMenu_Handler");

   for(new i = 0; i < sizeof(g_szSecondaryWeapons); i++) {
      menu_additem(g_iMenu[SecondaryMenu], fmt("\r|\w%s\r|", g_szSecondaryWeapons[i][0][0]));
   }
   menu_setprop(g_iMenu[SecondaryMenu], MPROP_EXIT, MEXIT_NEVER);
}

@WeaponMenu_Handler(const pPlayer, const iMenu, const iItem) {
   if(!is_user_alive(pPlayer) || iItem == MENU_EXIT) {
      return;
   }
   switch(iItem) {
      case 0: {
         menu_display(pPlayer, g_iMenu[PrimaryMenu]);
      }
      case 1: {
         @GiveOldWeapons(pPlayer);
      }
      case 2: {
         client_print_color(pPlayer, pPlayer, "^4[%s]^1 You will no longer be shown the Weapon Menu. Type: ^3/guns ^1or ^3/weapons^1 if you want to be shown again.", SayTag);
         @GiveOldWeapons(pPlayer);
         g_blChosenWeapon[pPlayer] = true;
      }
   }
}

@PrimaryMenu_Handler(const pPlayer, const iMenu, const iItem) {
   if(!is_user_alive(pPlayer) || iItem == MENU_EXIT) {
      return;
   }

   g_iPrimaryWeaponSave[pPlayer] = iItem;
   rg_give_item(pPlayer, g_szPrimaryWeapons[iItem][1][0]);
   menu_display(pPlayer, g_iMenu[SecondaryMenu]);
}

@SecondaryMenu_Handler(const pPlayer, const iMenu, const iItem) {
   if(!is_user_alive(pPlayer) || iItem == MENU_EXIT) {
      return;
   }

   g_iSecondaryWeaponSave[pPlayer] = iItem;
   rg_give_item(pPlayer, g_szSecondaryWeapons[iItem][1][0]);
}

@GiveOldWeapons(const pPlayer) {
   rg_give_item(pPlayer, g_szPrimaryWeapons[g_iPrimaryWeaponSave[pPlayer]][1][0]);
   rg_give_item(pPlayer, g_szSecondaryWeapons[g_iSecondaryWeaponSave[pPlayer]][1][0]);
}
