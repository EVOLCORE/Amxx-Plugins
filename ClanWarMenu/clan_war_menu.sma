#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#define cw_is_user_valid(%0) (%0 && %0 <= g_iMaxPlayers)
#define m_iTeam 114
#define fm_cs_get_user_team_index(%1)	get_pdata_int(%1, m_iTeam)

new bool:Knife = false, bool:Warmup = false, bool:CW;
new iTeam[33], bool:IsUserConnected[33];
new g_iMaxPlayers;

public plugin_init() {
	register_plugin("ClanWar Menu", "1.0b", "mIDnight");
	
	RegisterHam(Ham_Spawn, "player", "Ham_PlayerSpawn_Post", true);
	RegisterHam(Ham_Killed, "player", "Ham_Death");
	
	register_event("HLTV", "Event_HLTV", "a", "1=0", "2=0");
	
	g_iMaxPlayers = get_maxplayers();
	
	register_forward(FM_Voice_SetClientListening, "FakeMeta_Voice_SetListening", false);
	
	register_menucmd(register_menuid("Show_CwMenu"), 			(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_CwMenu");
	register_menucmd(register_menuid("Show_AdminMenu"), 		(1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), 		"Handle_AdminMenu");
	
	register_clcmd("say /menu", "Show_CwMenu");
	register_clcmd("say menu", "Show_CwMenu");
	register_clcmd("menu", "Show_CwMenu");
	register_clcmd("SetPass", "TypePass");
}

public client_putinserver(id) {
	IsUserConnected[id] = true;
}

public client_disconnected(id) {
	IsUserConnected[id] = false;
}

public Event_HLTV() {
	if(Warmup) {
		server_cmd("mp_buytime 10.0");
	}
}

public Ham_Death(iVictim, iAttacker, iCorpse) {
	if (Warmup) {
		if (IsUserConnected[iVictim] && !is_user_alive(iVictim) && cw_is_user_valid(iVictim) && (iTeam[iVictim] == 1 || iTeam[iVictim] == 2)) {
			set_task(0.5, "fnRevivePlayer", iVictim);
		}
	}
}

public fnRevivePlayer(id)
	ExecuteHamB(Ham_Spawn, id);

public FakeMeta_Voice_SetListening(iReceiver, iSender, bool:bListen) {
	if(IsUserConnected[iReceiver] && IsUserConnected[iSender] && iReceiver != iSender) {
		if(Warmup || Knife) {
			engfunc(EngFunc_SetClientListening, iReceiver, iSender, true);
			return FMRES_SUPERCEDE;
		}
		else if(CW) {
			if(iTeam[iSender] == iTeam[iReceiver] && is_user_connected(iSender) && is_user_connected(iReceiver)) {
				engfunc(EngFunc_SetClientListening, iReceiver, iSender, true);
				return FMRES_SUPERCEDE;
			}
			else {
				engfunc(EngFunc_SetClientListening, iReceiver, iSender, false);
				return FMRES_SUPERCEDE;
			}
		}
		else {
			engfunc(EngFunc_SetClientListening, iReceiver, iSender, false);
			return FMRES_SUPERCEDE;
		}
	}
	return FMRES_IGNORED;
}

public Ham_PlayerSpawn_Post(id) {
	if(!IsUserConnected[id] || !is_user_alive(id) || !cw_is_user_valid(id))
		return;
	
	iTeam[id] = fm_cs_get_user_team_index(id);
	
	if(Knife) {
		fm_strip_user_weapons(id);
		fm_give_item(id, "weapon_knife");
		cs_set_user_money(id, 0);
		set_user_health(id, 100);
	}
	if(Warmup) {
		cs_set_user_money(id, 16000);
		set_user_health(id, 100);
		set_user_armor(id, 100);
	}
	if(CW) {
		set_task(0.5, "TeamMoney", id);
	}
}

public TeamMoney(id) {
	new szName[32], szBuffer[64], szMessage[512], iMoney, AllMoney = 0;
	new Players[32], Count; get_players(Players, Count, "ah");
	formatex(szMessage, charsmax(szMessage), "Your Team Money:^n^n");
	
	get_user_name(id, szName, charsmax(szName));
	iMoney = cs_get_user_money(id);
	AllMoney = AllMoney + iMoney;
	formatex(szBuffer, charsmax(szBuffer), "Nick: %s |Money: %d^n", szName, iMoney);
	add(szMessage, charsmax(szMessage), szBuffer, charsmax(szBuffer));
	
	for(new a = 1; a <= Count; a++) {
		if(iTeam[id] == iTeam[Players[a]] && id != a) {
			get_user_name(Players[a], szName, charsmax(szName));
			iMoney = cs_get_user_money(Players[a]);
			AllMoney = AllMoney + iMoney;
			formatex(szBuffer, charsmax(szBuffer), "Nick: %s |Money: %d^n", szName, iMoney);
			add(szMessage, charsmax(szMessage), szBuffer, charsmax(szBuffer));
		}
	}
	formatex(szBuffer, charsmax(szBuffer), "^nTeam money amount: %d", AllMoney);
	add(szMessage, charsmax(szMessage), szBuffer, charsmax(szBuffer));
	set_hudmessage(0, 255, 0, 0.01, -1.0, 0, 6.0, 12.0);
	show_hudmessage(id, szMessage);
}

public Show_CwMenu(id) {
	if(~get_user_flags(id) & ADMIN_RCON)
		return PLUGIN_HANDLED;
	
	new Pass[32]; get_cvar_string("sv_password", Pass, charsmax(Pass));
	new szMenu[512], iKeys = (1<<0|1<<1|1<<2|1<<3|1<<5|1<<6|1<<9), iLen; 
	iLen = formatex(szMenu, charsmax(szMenu), "\rElement \wClanWar Menu^n^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y|\r1\y| \wAdmin Menu^n^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y|\r2\y| \rStart CW^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y|\r3\y| \yStart KNIFE^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y|\r4\y| \yStart WARMUP^n^n");
	if(strlen(Pass) != 0)
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y|\r5\y| \wCurrent Password: \r%s^n", Pass);
	else
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y|\r5\y| \wCurrent Password: \yNo^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y|\r6\y| \wSet password^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y|\r7\y| \wRemove password^n^n^n");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\y|\r0\y| \wExit");
	return show_menu(id, iKeys, szMenu, -1, "Show_CwMenu"); 
}

public Handle_CwMenu(id, iKey) {
	switch(iKey) {
		case 0: return Show_AdminMenu(id);
		case 1:
		{
			set_hudmessage(255, 0, 0, -1.0, -0.55, 0, 6.0, 10.0);
			show_hudmessage(0, "START CW!");
			Knife = false;
			Warmup = false;
			CW = true;
			server_cmd("mp_freezetime 6");
			server_cmd("mp_roundtime 1.75");
			set_task(2.0, "Restart");
		}
		case 2: SetKnife();
		case 3:
		{
			set_hudmessage(255, 0, 0, -1.0, -0.55, 0, 6.0, 10.0);
			show_hudmessage(0, "STARTING A WARM UP!");
			server_cmd("mp_freezetime 0");
			server_cmd("mp_roundtime 10.0");
			Knife = false;
			Warmup = true;
			CW = false;
			set_task(2.0, "Restart");
		}
		case 5: return client_cmd(id, "messagemode SetPass");
		case 6:
		{
			server_cmd("sv_password ^"^"");
			return set_task(0.1, "Show_CwMenu", id);
		}
		case 9: return PLUGIN_HANDLED;
	}
	return Show_CwMenu(id);
}

public Show_AdminMenu(id) {
	new szMenu[512], iKeys = (1<<0|1<<1|1<<2|1<<3|1<<8|1<<9), iLen; 
	iLen = formatex(szMenu, charsmax(szMenu), "\wAdmin Menu^n^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y|\r1\y| \wKick Player^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y|\r2\y| \wBan Player^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y|\r3\y| \wMove Player^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y|\r4\y| \wChange Map^n^n^n^n^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y|\r9\y| \wBack^n");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y|\r0\y| \wExit");
	return show_menu(id, iKeys, szMenu, -1, "Show_AdminMenu"); 
}

public Handle_AdminMenu(id, iKey) {
	switch(iKey) {
		case 0: return client_cmd(id, "amx_kickmenu");
		case 1: return client_cmd(id, "amx_banmenu");
		case 2: return client_cmd(id, "amx_teammenu");
		case 3: return client_cmd(id, "amx_mapmenu");
		case 8: return Show_CwMenu(id);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_AdminMenu(id);
}

public TypePass(id) {
	new szArg[10]; read_argv(1, szArg, charsmax(szArg));
	if(strlen(szArg) > 0) {
		server_cmd("sv_password %s", szArg);
		set_hudmessage(255, 0, 0, -1.0, -0.55, 0, 6.0, 10.0);
		show_hudmessage(id, "Password %s successfully setup!", szArg);
	}
	else
	{
		set_hudmessage(255, 0, 0, -1.0, -0.55, 0, 6.0, 10.0);
		show_hudmessage(id, "Enter correct password!");
	}
	return set_task(0.1, "Show_CwMenu", id);
}

public SetKnife() {
	set_hudmessage(255, 0, 0, -1.0, -0.55, 0, 6.0, 10.0);
	show_hudmessage(0, "STARTING A KNIFE ROUND");
	server_cmd("mp_freezetime 0");
	server_cmd("mp_roundtime 10.0");
	Warmup = false;
	Knife = true;
	CW = false;
	set_task(2.0, "Restart");
}

public Restart() {
	server_cmd("sv_restart 1");
}

stock fm_give_item(pPlayer, const szItem[]) {
	new iEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, szItem));
	if(!pev_valid(iEntity)) return 0;
	new Float:vecOrigin[3];
	pev(pPlayer, pev_origin, vecOrigin);
	set_pev(iEntity, pev_origin, vecOrigin);
	set_pev(iEntity, pev_spawnflags, pev(iEntity, pev_spawnflags) | SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, iEntity);
	dllfunc(DLLFunc_Touch, iEntity, pPlayer);
	if(pev(iEntity, pev_solid) != SOLID_NOT) {
		engfunc(EngFunc_RemoveEntity, iEntity);
		return -1;
	}
	return iEntity;
}

stock fm_strip_user_weapons(pPlayer, iType = 0) {
	static iEntity, iszWeaponStrip = 0;
	if(iszWeaponStrip || (iszWeaponStrip = engfunc(EngFunc_AllocString, "player_weaponstrip"))) iEntity = engfunc(EngFunc_CreateNamedEntity, iszWeaponStrip);
	if(!pev_valid(iEntity)) return 0;
	if(iType && get_user_weapon(pPlayer) != CSW_KNIFE) {
		engclient_cmd(pPlayer, "weapon_knife");
		engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, 66, {0.0, 0.0, 0.0}, pPlayer);
		write_byte(1);
		write_byte(CSW_KNIFE);
		write_byte(0);
		message_end();
	}
	dllfunc(DLLFunc_Spawn, iEntity);
	dllfunc(DLLFunc_Use, iEntity, pPlayer);
	engfunc(EngFunc_RemoveEntity, iEntity);
	set_pdata_int(pPlayer, 116, 0, 5);
	return 1;
}
