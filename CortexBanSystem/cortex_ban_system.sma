#pragma semicolon 1

#include <amxmodx>
#include <amxmisc>
#include <sqlx>

new const Host[]        = "127.0.0.1";
new const User[]        = "midnight";
new const Pass[]        = "2233051337";
new const Db[]          = "midnight";

enum eLastBan {
    name[32],
    authid[32],
    ip[32]
};

enum eMenuBans {
    Target,
    TargetName[32],
    TargetAuthid[32],
    TargetIP[32],
    eBanTime,
    UnBanTime[32],
    Reason[32]
}

new g_eMenuBans[MAX_PLAYERS + 1][eMenuBans];

new Array:g_iLastBanArray;
new Handle:g_hSqlDbTuple;

public plugin_init() {
    register_plugin("Cortex Ban System", "0.0.1", "mIDnight");

    register_concmd("amx_pban", "@ConCmd_PBan", ADMIN_BAN, "<name, steamid, ip, #userid> <reason>");
    register_concmd("amx_ban", "@ConCmd_Ban", ADMIN_BAN, "<name, steamid, ip, #userid> <minutes> <reason>");
    register_concmd("amx_unban", "@ConCmd_UnBan", ADMIN_BAN, "<steamid, ip>");
    register_concmd("amx_banmenu", "@ConCmd_BanMenu", ADMIN_BAN, "Opens ban menu");
    register_concmd("amx_lastban", "@ConCmd_LastBan", ADMIN_BAN, "Opens lastban menu");
    register_concmd("amx_clearbans", "@ConCmd_ClearBans", ADMIN_RCON, "Removes all bans");

    g_iLastBanArray = ArrayCreate(eLastBan);

    set_task(1.0, "@Task_Mysql");
    set_task(60.0, "@Task_Unban", .flags = "b");

    register_dictionary("cortex_ban_system.txt");
}

public client_putinserver(id) {
    new szDMax[32];
    get_user_info(id, "cl_dmax", szDMax, charsmax(szDMax));

    if(szDMax[0] != EOS) {
        server_cmd("kick #%d ^"%L^"", get_user_userid(id), id, "KICK_YOU_ARE_BANNED");
        return;
    }

    new szAuthID[32], szIP[32], szQuery[1096], iData[1];
    get_user_authid(id, szAuthID, charsmax(szAuthID));
    get_user_ip(id, szIP, charsmax(szIP));

    new iArraySize = ArraySize(g_iLastBanArray);

    for(new i = 0, iData[eLastBan]; i < iArraySize; i++) {
        ArrayGetArray(g_iLastBanArray, i, iData);

        if(equali(szAuthID, iData[authid])) {
            ArrayDeleteItem(g_iLastBanArray, i);
            break;
        }
    }

    iData[0] = id;
    formatex(szQuery, charsmax(szQuery), "SELECT * FROM cortex_bans WHERE authid = '%s' OR ip = '%s';", szAuthID, szIP);
    SQL_ThreadQuery(g_hSqlDbTuple, "check_client_putinserver", szQuery, iData, sizeof(iData));
}

public client_disconnected(id) {
    new iData[eLastBan];
    get_user_name(id, iData[name], charsmax(iData[name]));
    get_user_authid(id, iData[authid], charsmax(iData[authid]));
    get_user_ip(id, iData[ip], charsmax(iData[ip]));
    ArrayPushArray(g_iLastBanArray, iData);
}

public check_client_putinserver(iFailState, Handle:hQuery, szError[], iErrcode, iData[], iDataSize) {
    if(iFailState == TQUERY_CONNECT_FAILED) {
        log_amx("Load - Could not connect to SQL database.  [%d] %s", iErrcode, szError);
    }
    else if(iFailState == TQUERY_QUERY_FAILED) {
        log_amx("Load Query failed. [%d] %s", iErrcode, szError);
    }

    if(SQL_NumResults(hQuery)) {
        new id = iData[0];

        server_cmd("kick #%d ^"%L^"", get_user_userid(id), id, "KICK_YOU_ARE_BANNED");
    }

    return PLUGIN_HANDLED;
}

@Task_Mysql() {
    g_hSqlDbTuple = SQL_MakeDbTuple(Host, User, Pass, Db);

    new szError[512], iErrorCode;
    new Handle:hSQLConnection = SQL_Connect(g_hSqlDbTuple, iErrorCode, szError, charsmax(szError));

    if(hSQLConnection == Empty_Handle) {
        set_fail_state(szError);
    }

    new Handle:hQueries;
    hQueries = SQL_PrepareQuery(hSQLConnection, "CREATE TABLE IF NOT EXISTS cortex_bans (name varchar(32) NOT NULL, authid varchar(32) NOT NULL PRIMARY KEY, ip varchar(32) NOT NULL, bantime INT(7) NOT NULL, unbantime varchar(32) NOT NULL, reason varchar(32) NOT NULL, adminname varchar(32) NOT NULL, adminauthid varchar(32));");

    if(!SQL_Execute(hQueries)) {
        SQL_QueryError(hQueries, szError, charsmax(szError));
        set_fail_state(szError);
    }

    SQL_FreeHandle(hQueries);
    SQL_FreeHandle(hSQLConnection);
}

public plugin_end() {
    SQL_FreeHandle(g_hSqlDbTuple);
}

stock AddBan(const id, const target, const szName[], const szAuthID[], const szIP[], iBanTime, const szUnBanTime[], szReason[], iReasonLength) {
    if(szReason[0] == EOS) {
        formatex(szReason, iReasonLength, "NO REASON");
    }

    if(target != -1 && is_user_connected(target)) {
        new szDate[32], szBanTime[32];
        format_time(szDate, charsmax(szDate), "%m/%d/%Y - %H:%M:%S");
        GetBanTime(iBanTime, szBanTime, charsmax(szBanTime));

        console_print(target, "------------------%L------------------", target, "CONSOLE_TAG");
        console_print(target, "||| %L", target, "CONSOLE_YOU_ARE_BANNED");
        console_print(target, "||| %L", target, "CONSOLE_NICK", szName);
        console_print(target, "||| %L", target, "CONSOLE_STEAMID", szAuthID);
        console_print(target, "||| %L", target, "CONSOLE_IP", szIP);
        console_print(target, "||| %L", target, "CONSOLE_BY_ADMIN", id);
        console_print(target, "||| %L", target, "CONSOLE_REASON", szReason);
        console_print(target, "||| %L", target, "CONSOLE_BAN_DATE", szDate);
        console_print(target, "||| %L", target, "CONSOLE_BAN_TIME", szBanTime);
        console_print(target, "||| %L", target, "CONSOLE_EXPIRE_DATE", szUnBanTime);
        console_print(target, "------------------%L------------------", target, "CONSOLE_TAG");

        server_cmd("kick #%d ^"%L^"", get_user_userid(target), target, "KICK_YOU_ARE_BANNED_CHECK_CONSOLE");
    }

    new szAdminName[32], szAdminAuthID[32];

    if(id && is_user_connected(id)) {
        get_user_name(id, szAdminName, charsmax(szAdminName));
        get_user_authid(id, szAdminAuthID, charsmax(szAdminAuthID));
    }
    else {
        formatex(szAdminName, charsmax(szAdminName), "PANEL");
        formatex(szAdminAuthID, charsmax(szAdminAuthID), "PANEL");
    }

    new szQuery[1096];
    formatex(szQuery, charsmax(szQuery), "INSERT INTO cortex_bans (name, authid, ip, bantime, unbantime, reason, adminname, adminauthid) VALUES ('%s', '%s', '%s', %i, '%s', '%s', '%s', '%s');", szName, szAuthID, szIP, iBanTime, szUnBanTime, szReason, szAdminName, szAdminAuthID);
    SQL_ThreadQuery(g_hSqlDbTuple, "IgnoreHandle", szQuery);

    new szBanTime[32];

    if(iBanTime == -1) {
        formatex(szBanTime, charsmax(szBanTime), "%L", LANG_PLAYER, "PERMANENT");
    }
    else {
        formatex(szBanTime, charsmax(szBanTime), "%L", LANG_PLAYER, "MINUTES", iBanTime);
    }

    client_print_color(0, 0, "%L", LANG_PLAYER, "ADMIN_BANNED_PLAYER", id, szName, szBanTime, szReason);
}

stock RemoveBan(const id, const szArg[]) {
    new szQuery[1096];

    formatex(szQuery, charsmax(szQuery), "DELETE FROM cortex_bans WHERE authid = '%s' OR ip = '%s';", szArg, szArg);
    SQL_ThreadQuery(g_hSqlDbTuple, "IgnoreHandle", szQuery);

    client_print_color(0, 0, "%L", LANG_PLAYER, "ADMIN_UNBANNED_PLAYER", id, szArg);
}

public IgnoreHandle(iFailState, Handle:hQuery, szError[], iErrcode, iData[], iDataSize) {
    if(iFailState == TQUERY_CONNECT_FAILED) {
        log_amx("Load - Could not connect to SQL database.  [%d] %s", iErrcode, szError);
    }
    else if(iFailState == TQUERY_QUERY_FAILED) {
        log_amx("Load Query failed. [%d] %s", iErrcode, szError);
    }

    SQL_FreeHandle(hQuery);
    return PLUGIN_HANDLED;
}

@Task_Unban() {
    new szQuery[1096];

    formatex(szQuery, charsmax(szQuery), "UPDATE cortex_bans SET bantime = bantime - 1 WHERE unbantime != 'PERMANENT';");
    SQL_ThreadQuery(g_hSqlDbTuple, "check_client_bantime", szQuery);
}

public check_client_bantime(iFailState, Handle:hQuery, szError[], iErrcode, iData[], iDataSize) {
    if(iFailState == TQUERY_CONNECT_FAILED) {
        log_amx("Load - Could not connect to SQL database.  [%d] %s", iErrcode, szError);
    }
    else if(iFailState == TQUERY_QUERY_FAILED) {
        log_amx("Load Query failed. [%d] %s", iErrcode, szError);
    }

    new szQuery[1096];

    formatex(szQuery, charsmax(szQuery), "DELETE FROM cortex_bans WHERE bantime < 1 AND unbantime != 'PERMANENT';");
    SQL_ThreadQuery(g_hSqlDbTuple, "IgnoreHandle", szQuery);
}

@ConCmd_PBan(const id, const level, const cid) {
    if(!cmd_access(id, level, cid, 3)) {
        return PLUGIN_HANDLED;
    }

    new szArg[32];
    read_argv(1, szArg, charsmax(szArg));
    new iTarget = cmd_target(id, szArg, 9);

    if(!iTarget) {
        return PLUGIN_HANDLED;
    }

    new szDataExplode[4][32];

    get_user_name(iTarget, szDataExplode[0], charsmax(szDataExplode[]));
    get_user_authid(iTarget, szDataExplode[1], charsmax(szDataExplode[]));
    get_user_ip(iTarget, szDataExplode[2], charsmax(szDataExplode[]));

    read_argv(2, szDataExplode[3], charsmax(szDataExplode[]));

    set_user_info(iTarget, "cl_dmax", "512");

    AddBan(id, iTarget, szDataExplode[0], szDataExplode[1], szDataExplode[2], -1, "PERMANENT", szDataExplode[3], sizeof(szDataExplode[]));
    return PLUGIN_HANDLED;
}

@ConCmd_Ban(const id, const level, const cid) {
    if(!cmd_access(id, level, cid, 3)) {
        return PLUGIN_HANDLED;
    }

    new szArg[32];
    read_argv(1, szArg, charsmax(szArg));
    new iTarget = cmd_target(id, szArg, 9);

    if(!iTarget) {
        return PLUGIN_HANDLED;
    }

    new szDataExplode[5][32];

    get_user_name(iTarget, szDataExplode[0], charsmax(szDataExplode[]));
    get_user_authid(iTarget, szDataExplode[1], charsmax(szDataExplode[]));
    get_user_ip(iTarget, szDataExplode[2], charsmax(szDataExplode[]));

    read_argv(2, szDataExplode[3], charsmax(szDataExplode[]));

    new iBanTime = str_to_num(szDataExplode[3]);

    if(!iBanTime) {
        iBanTime = -1;
        formatex(szDataExplode[3], charsmax(szDataExplode[]), "PERMANENT");
    }
    else {
        GenerateUnbanTime(iBanTime, szDataExplode[3], charsmax(szDataExplode[]));
    }

    read_argv(3, szDataExplode[4], charsmax(szDataExplode[]));

    AddBan(id, iTarget, szDataExplode[0], szDataExplode[1], szDataExplode[2], iBanTime, szDataExplode[3], szDataExplode[4], sizeof(szDataExplode[]));
    return PLUGIN_HANDLED;
}

@ConCmd_UnBan(const id, const level, const cid) {
    if(!cmd_access(id, level, cid, 2)) {
        return PLUGIN_HANDLED;
    }

    new szArg[32];
    read_argv(1, szArg, charsmax(szArg));

    RemoveBan(id, szArg);
    return PLUGIN_HANDLED;
}

@ConCmd_BanMenu(const id, const level, const cid) {
    if(!cmd_access(id, level, cid, 0)) {
        return PLUGIN_HANDLED;
    }

    new iMenu = menu_create("Players for ban", "@ConCmd_BanMenu_Handler");

    for(new pPlayer = 1, szTeamName[32]; pPlayer <= MaxClients; pPlayer++) {
        if(!is_user_connected(pPlayer) || is_user_bot(pPlayer) || get_user_flags(pPlayer) & ADMIN_IMMUNITY) {
            continue;
        }

        GetClientTeamName(pPlayer, szTeamName, charsmax(szTeamName));
        menu_additem(iMenu, fmt("%n (%s)", pPlayer, szTeamName), fmt("%i", pPlayer));
    }

    menu_display(id, iMenu);
    return PLUGIN_HANDLED;
}

@ConCmd_BanMenu_Handler(const id, const menu, const item) {
    if(item == MENU_EXIT) {
        menu_destroy(menu);
        return;
    }

    new szData[256];
    menu_item_getinfo(menu, item, _, szData, charsmax(szData));

    g_eMenuBans[id][Target] = str_to_num(szData);

    if(!is_user_connected(g_eMenuBans[id][Target])) {
        return;
    }

    get_user_name(g_eMenuBans[id][Target], g_eMenuBans[id][TargetName], charsmax(g_eMenuBans[][TargetName]));
    get_user_authid(g_eMenuBans[id][Target], g_eMenuBans[id][TargetAuthid], charsmax(g_eMenuBans[][TargetAuthid]));
    get_user_ip(g_eMenuBans[id][Target], g_eMenuBans[id][TargetIP], charsmax(g_eMenuBans[][TargetIP]), 1);

    new iMenu = menu_create("Choose Time", "@BanMenu_Time_Handler");

    menu_additem(iMenu, "5 Minutes", "5");
    menu_additem(iMenu, "10 Minutes", "10");
    menu_additem(iMenu, "30 Minutes", "30");
    menu_additem(iMenu, "1 Hour", "60");
    menu_additem(iMenu, "Permanently", "0");

    menu_display(id, iMenu);
}

@BanMenu_Time_Handler(const id, const menu, const item) {
    if(item == MENU_EXIT) {
        menu_destroy(menu);
        return;
    }

    new szData[256];
    menu_item_getinfo(menu, item, _, szData, charsmax(szData));

    g_eMenuBans[id][eBanTime] = str_to_num(szData);

    new iMenu = menu_create("Choose Reason", "@BanMenu_Reason_Handler");

    menu_additem(iMenu, "Aimbot", "Aimbot");
    menu_additem(iMenu, "Wallhack", "Wallhack");
    menu_additem(iMenu, "Speedhack", "Speedhack");
    menu_additem(iMenu, "Insult", "Insult");

    menu_display(id, iMenu);
}

@BanMenu_Reason_Handler(const id, const menu, const item) {
    if(item == MENU_EXIT) {
        menu_destroy(menu);
        return;
    }

    new szData[256];
    menu_item_getinfo(menu, item, _, szData, charsmax(szData));

    formatex(g_eMenuBans[id][Reason], charsmax(g_eMenuBans[][Reason]), szData);

    if(!is_user_connected(g_eMenuBans[id][Target])) {
        return;
    }

    if(!g_eMenuBans[id][eBanTime]) {
        g_eMenuBans[id][eBanTime] = -1;
        formatex(g_eMenuBans[id][UnBanTime], charsmax(g_eMenuBans[][UnBanTime]), "PERMANENT");
    }
    else {
        GenerateUnbanTime(g_eMenuBans[id][eBanTime], g_eMenuBans[id][UnBanTime], charsmax(g_eMenuBans[][UnBanTime]));
    }

    AddBan(id, g_eMenuBans[id][Target], g_eMenuBans[id][TargetName],  g_eMenuBans[id][TargetAuthid],  g_eMenuBans[id][TargetIP],  g_eMenuBans[id][eBanTime], g_eMenuBans[id][UnBanTime],  g_eMenuBans[id][Reason], sizeof(g_eMenuBans[][Reason]));
}

@ConCmd_LastBan(const id, const level, const cid) {
    if(!cmd_access(id, level, cid, 0)) {
        return PLUGIN_HANDLED;
    }

    new iMenu = menu_create("LastBan", "@ConCmd_LastBan_Handler");

    new iArraySize = ArraySize(g_iLastBanArray);

    for(new i = 0, iData[eLastBan]; i < iArraySize; i++) {
        ArrayGetArray(g_iLastBanArray, i, iData);

        menu_additem(iMenu, fmt("[%s][%s][%s]", iData[name], iData[authid], iData[ip]), fmt("%i", i));
    }

    menu_display(id, iMenu);
    return PLUGIN_HANDLED;
}

@ConCmd_LastBan_Handler(const id, const menu, const item) {
    if(item == MENU_EXIT) {
        menu_destroy(menu);
        return;
    }

    new szData[256], iData[eLastBan];
    menu_item_getinfo(menu, item, _, szData, charsmax(szData));
    ArrayGetArray(g_iLastBanArray, str_to_num(szData), iData);

    g_eMenuBans[id][Target] = -1;
    formatex(g_eMenuBans[id][TargetName], charsmax(g_eMenuBans[][TargetName]), iData[name]);
    formatex(g_eMenuBans[id][TargetAuthid], charsmax(g_eMenuBans[][TargetAuthid]), iData[authid]);
    formatex(g_eMenuBans[id][TargetIP], charsmax(g_eMenuBans[][TargetIP]), iData[ip]);

    new iMenu = menu_create("Choose Time", "@LastBan_Time_Handler");

    menu_additem(iMenu, "5 Minutes", "5");
    menu_additem(iMenu, "10 Minutes", "10");
    menu_additem(iMenu, "30 Minutes", "30");
    menu_additem(iMenu, "1 Hour", "60");
    menu_additem(iMenu, "Permanently", "0");

    menu_display(id, iMenu);
}

@LastBan_Time_Handler(const id, const menu, const item) {
    if(item == MENU_EXIT) {
        menu_destroy(menu);
        return;
    }

    new szData[256];
    menu_item_getinfo(menu, item, _, szData, charsmax(szData));

    g_eMenuBans[id][eBanTime] = str_to_num(szData);

    new iMenu = menu_create("Choose Reason", "@LastBan_Reason_Handler");

    menu_additem(iMenu, "Aimbot", "Aimbot");
    menu_additem(iMenu, "Wallhack", "Wallhack");
    menu_additem(iMenu, "Speedhack", "Speedhack");
    menu_additem(iMenu, "Insult", "Insult");

    menu_display(id, iMenu);
}

@LastBan_Reason_Handler(const id, const menu, const item) {
    if(item == MENU_EXIT) {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    new szData[256];
    menu_item_getinfo(menu, item, _, szData, charsmax(szData));

    formatex(g_eMenuBans[id][Reason], charsmax(g_eMenuBans[][Reason]), szData);

    if(!g_eMenuBans[id][eBanTime]) {
        g_eMenuBans[id][eBanTime] = -1;
        formatex(g_eMenuBans[id][UnBanTime], charsmax(g_eMenuBans[][UnBanTime]), "PERMANENT");
    }
    else {
        GenerateUnbanTime(g_eMenuBans[id][eBanTime], g_eMenuBans[id][UnBanTime], charsmax(g_eMenuBans[][UnBanTime]));
    }

    AddBan(id, g_eMenuBans[id][Target], g_eMenuBans[id][TargetName],  g_eMenuBans[id][TargetAuthid],  g_eMenuBans[id][TargetIP],  g_eMenuBans[id][eBanTime], g_eMenuBans[id][UnBanTime],  g_eMenuBans[id][Reason], sizeof(g_eMenuBans[][Reason]));
    return PLUGIN_HANDLED;
}

@ConCmd_ClearBans(const id, const level, const cid) {
    if(!cmd_access(id, level, cid, 0)) {
        return PLUGIN_HANDLED;
    }

    client_print_color(0, 0, "%L", LANG_PLAYER, "ADMIN_CLEAR_BANS", id);

    new szQuery[1096];

    formatex(szQuery, charsmax(szQuery), "DELETE FROM cortex_bans;");
    SQL_ThreadQuery(g_hSqlDbTuple, "IgnoreHandle", szQuery);
    return PLUGIN_HANDLED;
}

GetClientTeamName(const pPlayer, szTeamName[], iTeamNameLength) {
    new iTeam = get_user_team(pPlayer);

    switch(iTeam) {
        case 1: {
            formatex(szTeamName, iTeamNameLength, "T");
        }
        case 2: {
            formatex(szTeamName, iTeamNameLength, "CT");
        }
        default: {
            formatex(szTeamName, iTeamNameLength, "SPEC");
        }
    }
}

GenerateUnbanTime(const bantime, unban_time[], len) {
	static _hours[5], _minutes[5], _seconds[5], _month[5], _day[5], _year[7];

	format_time(_hours, sizeof(_hours) - 1, "%H");
	format_time(_minutes, sizeof(_minutes) - 1, "%M");
	format_time(_seconds, sizeof(_seconds) - 1, "%S");
	format_time(_month, sizeof(_month) - 1, "%m");
	format_time(_day, sizeof(_day) - 1, "%d");
	format_time(_year, sizeof(_year) - 1, "%Y");

	new hours = str_to_num(_hours);
	new minutes = str_to_num(_minutes);
	new seconds = str_to_num(_seconds);
	new month = str_to_num(_month);
	new day = str_to_num(_day);
	new year = str_to_num(_year);
	
	minutes += bantime;

	while(minutes >= 60) {
		minutes -= 60;
		hours++;
	}
	
	while(hours >= 24) {
		hours -= 24;
		day++;
	}

	new max_days = GetDaysInMonth(month, year);

	while(day > max_days) {
		day -= max_days;
		month++;
	}

	while(month > 12) {
		month -= 12;
		year++;
	}

	formatex(unban_time, len, "%i:%02i:%02i %i/%i/%i", hours, minutes, seconds, month, day, year);
}

GetDaysInMonth(month, year=0) {
	switch(month) {
		case 1:		return 31; // january
		case 2:		return ((year % 4) == 0) ? 29 : 28; // february
		case 3:		return 31; // march
		case 4:		return 30; // april
		case 5:		return 31; // may
		case 6:		return 30; // june
		case 7:		return 31; // july
		case 8:		return 31; // august
		case 9:		return 30; // september
		case 10:	return 31; // october
		case 11:	return 30; // november
		case 12:	return 31; // december
	}

	return 30;
}

GetBanTime(const bantime, length[], len) {
	new minutes = bantime;
	new hours = 0;
	new days = 0;

	while(minutes >= 60) {
		minutes -= 60;
		hours++;
	}

	while(hours >= 24) {
		hours -= 24;
		days++;
	}

	new bool:add_before;

	if(minutes) {
		formatex(length, len, "%i minute%s", minutes, minutes == 1 ? "" : "s");

		add_before = true;
	}

	if(hours) {
		if(add_before) {
			format(length, len, "%i hour%s, %s", hours, hours == 1 ? "" : "s", length);
		}
		else {
			formatex(length, len, "%i hour%s", hours, hours == 1 ? "" : "s");

			add_before = true;
		}
	}

	if(days) {
		if(add_before) {
			format(length, len, "%i day%s, %s", days, days == 1 ? "" : "s", length);
		}
		else {
			formatex(length, len, "%i day%s", days, days == 1 ? "" : "s");

			add_before = true;
		}
	}

	if(!add_before) {
		copy(length, len, "Permanent Ban");
	}
}
