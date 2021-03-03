//#define TEST_HUD

//#define FADE_SPEED

#define FFA_MODE

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <reapi>

#define PLUGIN  					"[ReAPI] CSDM Menu"
#define VERSION 					"1.0"
#define AUTHOR  					"mIDnight"

#if !defined MAX_PLAYERS
#define MAX_PLAYERS 				32
#endif

#define IsPlayer(%1) 				(1 <= %1 <= MAX_PLAYERS)
#define TASK_KILLS					12023
#define TASK_CHAT					13923

new const HUD_HSPOS[] 		= 		"HUD_HS_POSITION"
new const HUD_HSCOLOR[]		= 		"HUD_HS_COLOR"
new const HUD_KILLS_POS[]	=		"HUD_KILLS_POSITION"
new const HUD_KILLS_COLOR[]	=		"HUD_KILLS_COLOR"
new const FADE_COLOR[] 		= 		"FADE_COLOR"
new const MENU_CMDS[] 		= 		"MENU_COMMANDS"
new const BONUS_HP[]		=		"BONUS_HEALTH"

enum _:Settings
{
	Float:HudHSPosX,
	Float:HudHSPosY,
	HudHSColorR,
	HudHSColorG,
	HudHSColorB,
	Float:HudKillPosX,
	Float:HudKillPosY,
	HudKillColorR,
	HudKillColorG,
	HudKillColorB,
	FadeColorR,
	FadeColorG,
	FadeColorB
}

enum _:CsdmSettings
{
	bool:bHeadshotMode,
	bool:bScreenFade,
	bool:bBulletDamage,
	bool:bHeadshotMsg,
	bool:bKillsCounter,
	bool:bHealing
}

enum _:KillType
{
	Normal = 0,
	Headshot = 1
}

new const Float: g_flCoords[][] = { {0.50, 0.40}, {0.56, 0.44}, {0.60, 0.50}, {0.56, 0.56}, {0.50, 0.60}, {0.44, 0.56}, {0.40, 0.50}, {0.44, 0.44} };

new g_iPosition[33]
new g_iSize = sizeof(g_flCoords)

new g_eFileSettings[Settings]
new g_ePlayerSettings[MAX_PLAYERS + 1][CsdmSettings]
new g_iKillsCounter[MAX_PLAYERS + 1][KillType]
new g_iBonusHP
new bool:g_bIsUserDead[MAX_PLAYERS + 1]
new bool:g_bIsHeadshot[MAX_PLAYERS + 1][MAX_PLAYERS + 1]

#if defined TEST_HUD
new Float:HUD_POS_X = 0.02;
new Float:HUD_POS_Y = 0.90;
#endif

#if defined FADE_SPEED
new g_iFadeDuration
new g_iFadeHold
#endif

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_dictionary("element_csdm_menu.txt")

	RegisterHookChain(RG_CBasePlayer_TakeDamage, "RG_Player_Damage_Post", 1)
	RegisterHookChain(RG_CBasePlayer_TraceAttack, "RG_Player_TraceAttack_Pre")
	RegisterHookChain(RG_CBasePlayer_Killed, "RG_Player_Killed_Post", 1)
	RegisterHookChain(RG_CBasePlayer_Spawn, "RG_Player_Spawn_Post", 1)

	#if defined TEST_HUD
	register_clcmd("say /hudmenu", "clcmd_hudmenu")
	#endif

	#if defined FADE_SPEED
	register_clcmd("amx_duration", "clcmd_duration")
	register_clcmd("amx_hold", "clcmd_hold")
	#endif
}

public plugin_precache()
{
	static szConfigsDir[64], szFileName[64]
	get_configsdir(szConfigsDir, charsmax(szConfigsDir))
	formatex(szFileName, charsmax(szFileName), "%s/CSDMMenu.ini", szConfigsDir)

	new iFile = fopen(szFileName, "rt")

	if(iFile)
	{
		new szData[128], iSection, szString[64], szValue[64]

		while(!feof(iFile))
		{
			fgets(iFile, szData, charsmax(szData))
			trim(szData)

			if(szData[0] == '#' || szData[0] == EOS || szData[0] == ';')
				continue

			if(szData[0] == '[')
			{
				iSection += 1
			}
			switch(iSection)
			{
				case 1:
				{
					strtok2(szData, szString, charsmax(szString), szValue, charsmax(szValue), '=', TRIM_INNER)

					if(szValue[0] == EOS || !szValue[0])
						continue

					if(equal(szString, HUD_HSPOS))
					{
						new szHudHSPosX[5], szHudHSPosY[5]
						parse(szValue, szHudHSPosX, charsmax(szHudHSPosX), szHudHSPosY, charsmax(szHudHSPosY))

						g_eFileSettings[HudHSPosX] = str_to_float(szHudHSPosX)
						g_eFileSettings[HudHSPosY] = str_to_float(szHudHSPosY)
					}
					else if(equal(szString, HUD_HSCOLOR))
					{
						new szHudHSColorR[4], szHudHSColorG[4], szHudHSColorB[4]
						parse(szValue, szHudHSColorR, charsmax(szHudHSColorR), szHudHSColorG, charsmax(szHudHSColorG), szHudHSColorB, charsmax(szHudHSColorB))

						g_eFileSettings[HudHSColorR] = str_to_num(szHudHSColorR)
						g_eFileSettings[HudHSColorG] = str_to_num(szHudHSColorG)
						g_eFileSettings[HudHSColorB] = str_to_num(szHudHSColorB)
					}
					else if(equal(szString, HUD_KILLS_POS))
					{
						new szHudKillPosX[5], szHudKillPosY[5]
						parse(szValue, szHudKillPosX, charsmax(szHudKillPosX), szHudKillPosY, charsmax(szHudKillPosY))

						g_eFileSettings[HudKillPosX] = str_to_float(szHudKillPosX)
						g_eFileSettings[HudKillPosY] = str_to_float(szHudKillPosY)
					}
					else if(equal(szString, HUD_KILLS_COLOR))
					{
						new szHudKillColorR[4], szHudKillColorG[4], szHudKillColorB[4]
						parse(szValue, szHudKillColorR, charsmax(szHudKillColorR), szHudKillColorG, charsmax(szHudKillColorG), szHudKillColorB, charsmax(szHudKillColorB))

						g_eFileSettings[HudKillColorR] = str_to_num(szHudKillColorR)
						g_eFileSettings[HudKillColorG] = str_to_num(szHudKillColorG)
						g_eFileSettings[HudKillColorB] = str_to_num(szHudKillColorB)
					}
					else if(equal(szString, FADE_COLOR))
					{
						new szFadeColorR[4], szFadeColorG[4], szFadeColorB[4]
						parse(szValue, szFadeColorR, charsmax(szFadeColorR), szFadeColorG, charsmax(szFadeColorG), szFadeColorB, charsmax(szFadeColorB))
						
						g_eFileSettings[FadeColorR] = str_to_num(szFadeColorR)
						g_eFileSettings[FadeColorG] = str_to_num(szFadeColorG)
						g_eFileSettings[FadeColorB] = str_to_num(szFadeColorB)
					}
					else if(equal(szString, MENU_CMDS))
					{
						while(szValue[0] != EOS && strtok2(szValue, szString, charsmax(szString), szValue, charsmax(szValue), ',', TRIM_INNER))
						{
							register_clcmd(szString, "Clcmd_CSDM_Menu")
						}
					}
					else if(equal(szString, BONUS_HP))
					{
						if(szValue[0] != EOS)
						{
							g_iBonusHP = str_to_num(szValue)
						}
					}
				}
			}
		}
	}
	fclose(iFile)
}

public client_putinserver(id)
{
	if(task_exists(id + TASK_KILLS))
	{
		remove_task(id + TASK_KILLS)
	}
	if(task_exists(id + TASK_CHAT))
	{
		remove_task(id + TASK_CHAT)
	}
	g_ePlayerSettings[id][bHeadshotMode] = false
	g_ePlayerSettings[id][bScreenFade] = true
	g_ePlayerSettings[id][bBulletDamage] = true
	g_ePlayerSettings[id][bHeadshotMsg] = true
	g_ePlayerSettings[id][bKillsCounter] = true
	g_ePlayerSettings[id][bHealing] = true

	set_task(180.0, "task_show_chat_ad", id + TASK_CHAT, .flags = "b")
}

public RG_Player_Damage_Post(iVictim, iInflictor, iAttacker, Float:fDamage, bitsDamageType)
{
	#if defined FFA_MODE
	if(!IsPlayer(iVictim) || !IsPlayer(iAttacker) || iVictim == iAttacker)
	#else
	if(!IsPlayer(iVictim) || !IsPlayer(iAttacker) || iVictim == iAttacker || get_user_team(iVictim) == get_user_team(iAttacker))
	#endif
		return HC_CONTINUE

	new iDamage[4]
	float_to_str(fDamage, iDamage, charsmax(iDamage))
	replace_all(iDamage, charsmax(iDamage), ".", "")

	if(g_ePlayerSettings[iAttacker][bBulletDamage] && !(g_ePlayerSettings[iAttacker][bHeadshotMode] && get_member( iAttacker , m_LastHitGroup ) == HIT_HEAD))
	{
		if(++g_iPosition[iAttacker] == g_iSize)
      		g_iPosition[iAttacker] = 0
    
		set_hudmessage(random_num(0, 255), random_num(0, 255), random_num(0, 255), Float:g_flCoords[g_iPosition[iAttacker]][0], Float:g_flCoords[g_iPosition[iAttacker]][1], 0, 0.1, 1.5, 0.02, 0.02)
		show_hudmessage(iAttacker, "%s", iDamage)
	}
	
	return HC_CONTINUE
}

public RG_Player_TraceAttack_Pre(iVictim, iAttacker, Float:fDamage, Float:fDirection[3], trhandle)
{
	#if defined FFA_MODE
	if(!IsPlayer(iVictim) || !IsPlayer(iAttacker) || iVictim == iAttacker)
	#else
	if(!IsPlayer(iVictim) || !IsPlayer(iAttacker) || iVictim == iAttacker || get_user_team(iVictim) == get_user_team(iAttacker))
	#endif
		return HC_CONTINUE

	if(g_ePlayerSettings[iAttacker][bHeadshotMode] && get_tr2(trhandle, TR_iHitgroup) != HIT_HEAD && get_user_weapon(iAttacker) != CSW_KNIFE)
	{
		return HC_SUPERCEDE
	}

	g_bIsHeadshot[iAttacker][iVictim] = get_tr2(trhandle, TR_iHitgroup) == HIT_HEAD ? true : false

	return HC_CONTINUE
}

public RG_Player_Killed_Post(iVictim, iAttacker, gibsShould)
{
	if(!IsPlayer(iVictim) || !IsPlayer(iAttacker))
		return HC_CONTINUE

	g_bIsUserDead[iVictim] = true
	if(iVictim == iAttacker)
		return HC_CONTINUE

	if(g_ePlayerSettings[iAttacker][bScreenFade])
	{
		FadeScreen(iAttacker)
	}

	if(g_ePlayerSettings[iAttacker][bHeadshotMsg] && get_member(iVictim, m_bHeadshotKilled))
	{
		#if defined TEST_HUD
		set_dhudmessage(g_eFileSettings[HudHSColorR], g_eFileSettings[HudHSColorG], g_eFileSettings[HudHSColorB], HUD_POS_X, HUD_POS_Y, 0, 0.1, 1.5, 0.02, 0.02)
		#else
		set_dhudmessage(g_eFileSettings[HudHSColorR], g_eFileSettings[HudHSColorG], g_eFileSettings[HudHSColorB], g_eFileSettings[HudHSPosX], g_eFileSettings[HudHSPosY], 0, 0.1, 1.5, 0.02, 0.02)
		#endif
		show_dhudmessage(iAttacker, "HEAD SHOT")
	}

	if(g_ePlayerSettings[iAttacker][bKillsCounter])
	{
		g_iKillsCounter[iAttacker][Normal]++

		if(get_member(iVictim, m_bHeadshotKilled))
		{
			g_iKillsCounter[iAttacker][Headshot]++
		}

		if(g_iKillsCounter[iAttacker][Normal] > 0 || g_iKillsCounter[iAttacker][Headshot] > 0)
		{
			remove_task(iAttacker + TASK_KILLS)
			set_task(1.0, "task_show_hudkills", iAttacker + TASK_KILLS)
		}
	}

	if(g_ePlayerSettings[iAttacker][bHealing] && g_bIsHeadshot[iAttacker][iVictim])
	{
		if(get_user_health(iAttacker) >= 100)
		{
			set_user_health(iAttacker, 100)
		}
		else
		{
			set_user_health(iAttacker, get_user_health(iAttacker) + g_iBonusHP)
		}
	}

	if(g_bIsHeadshot[iAttacker][iVictim])
	{
		g_bIsHeadshot[iAttacker][iVictim] = false
	}

	return HC_CONTINUE
}

public RG_Player_Spawn_Post(iEntity)
{
	if(IsPlayer(iEntity))
	{
		g_bIsUserDead[iEntity] = false
	}
}

public Clcmd_CSDM_Menu(id)
{
	new szTemp[128]
	formatex(szTemp, charsmax(szTemp), "\w%L", LANG_PLAYER, "CSDM_SETTINGS_TITLE")
	new menu = menu_create(szTemp, "settings_menu_handler")

	formatex(szTemp, charsmax(szTemp), "\w%L %s", LANG_PLAYER, "CSDM_ONLY_HS", g_ePlayerSettings[id][bHeadshotMode] ? "\w[\yON\w]" : "\w[\rOFF\w]")
	menu_additem(menu, szTemp)
	formatex(szTemp, charsmax(szTemp), "\w%L %s", LANG_PLAYER, "CSDM_FADE_SCREEN", g_ePlayerSettings[id][bScreenFade] ? "\w[\yON\w]" : "\w[\rOFF\w]")
	menu_additem(menu, szTemp)
	formatex(szTemp, charsmax(szTemp), "\w%L %s", LANG_PLAYER, "CSDM_BULLET_DAMAGE", g_ePlayerSettings[id][bBulletDamage] ? "\w[\yON\w]" : "\w[\rOFF\w]")
	menu_additem(menu, szTemp)
	formatex(szTemp, charsmax(szTemp), "\w%L %s", LANG_PLAYER, "CSDM_HEADSHOT_MSG", g_ePlayerSettings[id][bHeadshotMsg] ? "\w[\yON\w]" : "\w[\rOFF\w]")
	menu_additem(menu, szTemp)
	formatex(szTemp, charsmax(szTemp), "\w%L %s", LANG_PLAYER, "CSDM_ALL_KILLS", g_ePlayerSettings[id][bKillsCounter] ? "\w[\yON\w]" : "\w[\rOFF\w]")
	menu_additem(menu, szTemp)
	formatex(szTemp, charsmax(szTemp), "\w%L %s", LANG_PLAYER, "CSDM_BONUS_HP", g_ePlayerSettings[id][bHealing] ? "\w[\yON\w]" : "\w[\rOFF\w]")
	menu_additem(menu, szTemp)

	menu_display(id, menu)
}

public settings_menu_handler(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_connected(id))
	{
		return MenuExit(menu)
	}

	switch(item)
	{
		case 0:
		{
			if(g_ePlayerSettings[id][bHeadshotMode])
			{
				g_ePlayerSettings[id][bHeadshotMode] = false
			}
			else
			{
				g_ePlayerSettings[id][bHeadshotMode] = true
			}
			Clcmd_CSDM_Menu(id)
		}
		case 1:
		{
			if(g_ePlayerSettings[id][bScreenFade])
			{
				g_ePlayerSettings[id][bScreenFade] = false
			}
			else
			{
				g_ePlayerSettings[id][bScreenFade] = true
			}
			Clcmd_CSDM_Menu(id)
		}
		case 2:
		{
			if(g_ePlayerSettings[id][bBulletDamage])
			{
				g_ePlayerSettings[id][bBulletDamage] = false
			}
			else
			{
				g_ePlayerSettings[id][bBulletDamage] = true
			}
			Clcmd_CSDM_Menu(id)
		}
		case 3:
		{
			if(g_ePlayerSettings[id][bHeadshotMsg])
			{
				g_ePlayerSettings[id][bHeadshotMsg] = false
			}
			else
			{
				g_ePlayerSettings[id][bHeadshotMsg] = true
			}
			Clcmd_CSDM_Menu(id)
		}
		case 4:
		{
			if(g_ePlayerSettings[id][bKillsCounter])
			{
				g_ePlayerSettings[id][bKillsCounter] = false
			}
			else
			{
				g_ePlayerSettings[id][bKillsCounter] = true
			}
			Clcmd_CSDM_Menu(id)
		}
		case 5:
		{
			if(g_ePlayerSettings[id][bHealing])
			{
				g_ePlayerSettings[id][bHealing] = false
			}
			else
			{
				g_ePlayerSettings[id][bHealing] = true
			}
			Clcmd_CSDM_Menu(id)
		}
	}

	return MenuExit(menu)
}

#if defined TEST_HUD
public clcmd_hudmenu(id)
{
	new temp[64];
	formatex(temp, charsmax(temp), "\wHUD POSITION");
	new menu = menu_create(temp, "hudmenu_pos_handler");
	
	formatex(temp, charsmax(temp), "Move HUD Up");
	menu_additem(menu, temp, "0");
	formatex(temp, charsmax(temp), "Move HUD Down");
	menu_additem(menu, temp, "1");
	formatex(temp, charsmax(temp), "Move HUD to the Left");
	menu_additem(menu, temp, "2");
	formatex(temp, charsmax(temp), "Move HUD to the right");
	menu_additem(menu, temp, "3");
	formatex(temp, charsmax(temp), "Move HUD to center");
	menu_additem(menu, temp, "4");
	formatex(temp, charsmax(temp), "Move HUD Default");
	menu_additem(menu, temp, "5");
	formatex(temp, charsmax(temp), "Show Current HUD POS");
	menu_additem(menu, temp, "6");
	
	menu_display(id, menu);
}

public hudmenu_pos_handler(id, menu, item)
{
	switch(item)
	{
		case 0:
		{
			HUD_POS_Y -= 0.03;
			clcmd_hudmenu(id);
		}
		case 1:
		{
			HUD_POS_Y += 0.03;
			clcmd_hudmenu(id);
		}
		case 2:
		{
			HUD_POS_X -= 0.03;
			clcmd_hudmenu(id);
		}
		case 3:
		{
			HUD_POS_X += 0.03;
			clcmd_hudmenu(id);
		}
		case 4:
		{
			HUD_POS_X = -1.0;
			HUD_POS_Y =  0.26;
			clcmd_hudmenu(id);
		}
		case 5:
		{
			HUD_POS_X = 0.02;
			HUD_POS_Y =  0.9;
			clcmd_hudmenu(id);
		}
		case 6:
		{
			client_print(id, print_chat, "Pos X: %f Pos Y: %f", HUD_POS_X, HUD_POS_Y);
			clcmd_hudmenu(id);
		}
	}
	return MenuExit(menu);
}
#endif

#if defined FADE_SPEED
public clcmd_duration(id)
{
	new szArgs[5]
	read_args(szArgs, charsmax(szArgs))
 	g_iFadeDuration = str_to_num(szArgs)

 	client_print(id, print_chat, "Fade Duration: %i", g_iFadeDuration)
}

public clcmd_hold(id)
{
	new szArgs[5]
	read_args(szArgs, charsmax(szArgs))
  	g_iFadeHold = str_to_num(szArgs)

  	client_print(id, print_chat, "Fade Hold time: %i", g_iFadeHold)
}
#endif

public task_show_chat_ad(id)
{
	id -= TASK_CHAT
	if(is_user_connected(id))
	{
		client_print_color(id, print_chat, "^1%L", LANG_PLAYER, "CSDM_CHAT_AD")
	}
}

public task_show_hudkills(id)
{
	id -= TASK_KILLS
	if(g_ePlayerSettings[id][bKillsCounter])
	{
		#if defined TEST_HUD
		set_dhudmessage(g_eFileSettings[HudKillColorR], g_eFileSettings[HudKillColorG], g_eFileSettings[HudKillColorB], HUD_POS_X, HUD_POS_Y, 0, 0.1, 1.5, 0.02, 0.02)
		#else
		set_dhudmessage(g_eFileSettings[HudKillColorR], g_eFileSettings[HudKillColorG], g_eFileSettings[HudKillColorB], g_eFileSettings[HudKillPosX], g_eFileSettings[HudKillPosY], 0, 0.1, 1.5, 0.02, 0.02)
		#endif
		show_dhudmessage(id, "%i (%i)", g_iKillsCounter[id][Normal], g_iKillsCounter[id][Headshot])

		if(g_iKillsCounter[id][Normal] > 0 || g_iKillsCounter[id][Headshot] > 0)
		{
			remove_task(id + TASK_KILLS)
			set_task(1.0, "task_show_hudkills", id + TASK_KILLS)
		}
	}
	else
	{
		remove_task(id + TASK_KILLS)
	}

	if(g_bIsUserDead[id])
	{
		g_iKillsCounter[id][Normal] = 0
		g_iKillsCounter[id][Headshot] = 0
	}

	return PLUGIN_HANDLED
}

stock MenuExit(menu)
{
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

stock FadeScreen(id)
{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), {0,0,0}, id)
	#if defined FADE_SPEED
	write_short(1<<g_iFadeDuration)
	write_short(1<<g_iFadeHold)
	#else
	write_short(1<<10)
	write_short(1<<9)
	#endif
	write_short(0x0000)
	write_byte(52)
	write_byte(g_eFileSettings[FadeColorR])
	write_byte(g_eFileSettings[FadeColorG])
	write_byte(g_eFileSettings[FadeColorB])
	message_end()
}
