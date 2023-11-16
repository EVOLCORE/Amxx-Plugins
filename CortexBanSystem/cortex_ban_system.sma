#pragma semicolon 1

#include <amxmodx>
#include <amxmisc>
#include <sqlx>

new const Host[]        = "";
new const User[]        = "";
new const Pass[]        = "";
new const Db[]          = "";
new const Table[]       = "cortex_bans";

enum eLastBan {
    name[32],
    authid[32],
    ip[32]
};

enum _:BanOptions {
    Target,
    TargetName[32],
    TargetAuthid[32],
    TargetIP[32],
    eBanTime,
    UnBanTime[32],
    Reason[32]
}

new g_eBanOptions[MAX_PLAYERS + 1][BanOptions];

new Array:g_iLastBanArray;
new Handle:g_hSqlDbTuple;

public plugin_init() {
    register_plugin("Cortex Ban System", "0.0.3", "mIDnight");

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
    formatex(szQuery, charsmax(szQuery), "SELECT * FROM %s WHERE authid = '%s' OR ip = '%s';", Table, szAuthID, szIP);
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
    hQueries = SQL_PrepareQuery(hSQLConnection, "CREATE TABLE IF NOT EXISTS %s (name varchar(32) NOT NULL, authid varchar(32) NOT NULL PRIMARY KEY, ip varchar(32) NOT NULL, bantime INT(7) NOT NULL, unbantime varchar(32) NOT NULL, reason varchar(32) NOT NULL, adminname varchar(32) NOT NULL, adminauthid varchar(32));", Table);

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

        UTIL_console_print(target, "------------------%L------------------", target, "CONSOLE_TAG");
        UTIL_console_print(target, "||| %L", target, "CONSOLE_YOU_ARE_BANNED");
        UTIL_console_print(target, "||| %L", target, "CONSOLE_NICK", szName);
        UTIL_console_print(target, "||| %L", target, "CONSOLE_STEAMID", szAuthID);
        UTIL_console_print(target, "||| %L", target, "CONSOLE_IP", szIP);
        UTIL_console_print(target, "||| %L", target, "CONSOLE_BY_ADMIN", id);
        UTIL_console_print(target, "||| %L", target, "CONSOLE_REASON", szReason);
        UTIL_console_print(target, "||| %L", target, "CONSOLE_BAN_TIME", szBanTime);
        UTIL_console_print(target, "||| %L", target, "CONSOLE_UNBAN_TIME", szUnBanTime);
        UTIL_console_print(target, "||| %L", target, "CONSOLE_DATE", szDate);
        UTIL_console_print(target, "||| %L", target, "CONSOLE_FOR_UNBAN");
        UTIL_console_print(target, "------------------%L------------------", target, "CONSOLE_TAG");

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
    formatex(szQuery, charsmax(szQuery), "INSERT INTO %s (name, authid, ip, bantime, unbantime, reason, adminname, adminauthid) VALUES ('%s', '%s', '%s', %i, '%s', '%s', '%s', '%s');", Table, szName, szAuthID, szIP, iBanTime, szUnBanTime, szReason, szAdminName, szAdminAuthID);
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

    formatex(szQuery, charsmax(szQuery), "DELETE FROM %s WHERE authid = '%s' OR ip = '%s';", Table, szArg, szArg);
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

    formatex(szQuery, charsmax(szQuery), "UPDATE %s SET bantime = bantime - 1 WHERE unbantime != 'PERMANENT';", Table);
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

    formatex(szQuery, charsmax(szQuery), "DELETE FROM %s WHERE bantime < 1 AND unbantime != 'PERMANENT';", Table);
    SQL_ThreadQuery(g_hSqlDbTuple, "IgnoreHandle", szQuery);
}

@ConCmd_PBan(const id, const level, const cid) {
    if (!cmd_access(id, level, cid, 3)) {
        return PLUGIN_HANDLED;
    }

    new szArg[32];
    read_argv(1, szArg, sizeof(szArg));
    new iTarget = cmd_target(id, szArg, 9);

    if (!is_user_connected(iTarget)) {
        return PLUGIN_HANDLED;
    }

    get_user_name(iTarget, g_eBanOptions[id][TargetName], sizeof(g_eBanOptions[][TargetName]));
    get_user_authid(iTarget, g_eBanOptions[id][TargetAuthid], sizeof(g_eBanOptions[][TargetAuthid]));
    get_user_ip(iTarget, g_eBanOptions[id][TargetIP], sizeof(g_eBanOptions[][TargetIP]), 1);

    read_argv(2, g_eBanOptions[id][Reason], sizeof(g_eBanOptions[][Reason]));

    set_user_info(iTarget, "cl_dmax", "512");

    formatex(g_eBanOptions[id][UnBanTime], sizeof(g_eBanOptions[][UnBanTime]), "PERMANENT");

    AddBan(id, iTarget, g_eBanOptions[id][TargetName], g_eBanOptions[id][TargetAuthid], g_eBanOptions[id][TargetIP], -1, g_eBanOptions[id][UnBanTime], g_eBanOptions[id][Reason], sizeof(g_eBanOptions[][Reason]));

    return PLUGIN_HANDLED;
}

@ConCmd_Ban(const id, const level, const cid) {
    if (!cmd_access(id, level, cid, 3)) {
        return PLUGIN_HANDLED;
    }

    new szArg[32];
    read_argv(1, szArg, sizeof(szArg));

    new iTarget = cmd_target(id, szArg, 9);

    if (!is_user_connected(iTarget)) {
        return PLUGIN_HANDLED;
    }

    new szDataExplode[2][32];
    get_user_name(iTarget, g_eBanOptions[id][TargetName], sizeof(g_eBanOptions[][TargetName]));
    get_user_authid(iTarget, g_eBanOptions[id][TargetAuthid], sizeof(g_eBanOptions[][TargetAuthid]));
    get_user_ip(iTarget, g_eBanOptions[id][TargetIP], sizeof(g_eBanOptions[][TargetIP]), 1);

    read_argv(2, szDataExplode[0], sizeof(szDataExplode[]));

    new iBanTime = str_to_num(szDataExplode[0]);

    g_eBanOptions[id][eBanTime] = iBanTime;

    if (!g_eBanOptions[id][eBanTime]) {
        g_eBanOptions[id][eBanTime] = -1;
        formatex(g_eBanOptions[id][UnBanTime], sizeof(g_eBanOptions[][UnBanTime]), "PERMANENT");
    } else {
        GenerateUnbanTime(g_eBanOptions[id][eBanTime], g_eBanOptions[id][UnBanTime], sizeof(g_eBanOptions[][UnBanTime]));
    }

    read_argv(3, g_eBanOptions[id][Reason], sizeof(g_eBanOptions[][Reason]));

    AddBan(id, iTarget, g_eBanOptions[id][TargetName], g_eBanOptions[id][TargetAuthid], g_eBanOptions[id][TargetIP], g_eBanOptions[id][eBanTime], g_eBanOptions[id][UnBanTime], g_eBanOptions[id][Reason], sizeof(g_eBanOptions[][Reason]));

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

    g_eBanOptions[id][Target] = str_to_num(szData);

    if(!is_user_connected(g_eBanOptions[id][Target])) {
        return;
    }

    get_user_name(g_eBanOptions[id][Target], g_eBanOptions[id][TargetName], charsmax(g_eBanOptions[][TargetName]));
    get_user_authid(g_eBanOptions[id][Target], g_eBanOptions[id][TargetAuthid], charsmax(g_eBanOptions[][TargetAuthid]));
    get_user_ip(g_eBanOptions[id][Target], g_eBanOptions[id][TargetIP], charsmax(g_eBanOptions[][TargetIP]), 1);

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

    g_eBanOptions[id][eBanTime] = str_to_num(szData);

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

    formatex(g_eBanOptions[id][Reason], charsmax(g_eBanOptions[][Reason]), szData);

    if(!is_user_connected(g_eBanOptions[id][Target])) {
        return;
    }

    if(!g_eBanOptions[id][eBanTime]) {
        g_eBanOptions[id][eBanTime] = -1;
        formatex(g_eBanOptions[id][UnBanTime], charsmax(g_eBanOptions[][UnBanTime]), "PERMANENT");
    }
    else {
        GenerateUnbanTime(g_eBanOptions[id][eBanTime], g_eBanOptions[id][UnBanTime], charsmax(g_eBanOptions[][UnBanTime]));
    }

    AddBan(id, g_eBanOptions[id][Target], g_eBanOptions[id][TargetName],  g_eBanOptions[id][TargetAuthid],  g_eBanOptions[id][TargetIP],  g_eBanOptions[id][eBanTime], g_eBanOptions[id][UnBanTime],  g_eBanOptions[id][Reason], sizeof(g_eBanOptions[][Reason]));
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

    g_eBanOptions[id][Target] = -1;
    formatex(g_eBanOptions[id][TargetName], charsmax(g_eBanOptions[][TargetName]), iData[name]);
    formatex(g_eBanOptions[id][TargetAuthid], charsmax(g_eBanOptions[][TargetAuthid]), iData[authid]);
    formatex(g_eBanOptions[id][TargetIP], charsmax(g_eBanOptions[][TargetIP]), iData[ip]);

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

    g_eBanOptions[id][eBanTime] = str_to_num(szData);

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

    formatex(g_eBanOptions[id][Reason], charsmax(g_eBanOptions[][Reason]), szData);

    if(!g_eBanOptions[id][eBanTime]) {
        g_eBanOptions[id][eBanTime] = -1;
        formatex(g_eBanOptions[id][UnBanTime], charsmax(g_eBanOptions[][UnBanTime]), "PERMANENT");
    }
    else {
        GenerateUnbanTime(g_eBanOptions[id][eBanTime], g_eBanOptions[id][UnBanTime], charsmax(g_eBanOptions[][UnBanTime]));
    }

    AddBan(id, g_eBanOptions[id][Target], g_eBanOptions[id][TargetName],  g_eBanOptions[id][TargetAuthid],  g_eBanOptions[id][TargetIP],  g_eBanOptions[id][eBanTime], g_eBanOptions[id][UnBanTime],  g_eBanOptions[id][Reason], sizeof(g_eBanOptions[][Reason]));
    return PLUGIN_HANDLED;
}

@ConCmd_ClearBans(const id, const level, const cid) {
    if(!cmd_access(id, level, cid, 0)) {
        return PLUGIN_HANDLED;
    }

    client_print_color(0, 0, "%L", LANG_PLAYER, "ADMIN_CLEAR_BANS", id);

    new szQuery[1096];

    formatex(szQuery, charsmax(szQuery), "DELETE FROM %s;", Table);
    SQL_ThreadQuery(g_hSqlDbTuple, "IgnoreHandle", szQuery);
    return PLUGIN_HANDLED;
}

GetClientTeamName(const pPlayer, szTeamName[], iTeamNameLength) {
    new iTeam = get_user_team(pPlayer);

    formatex(szTeamName, iTeamNameLength, (iTeam == 1) ? "T" : (iTeam == 2) ? "CT" : "SPEC");
}

GenerateUnbanTime(const bantime, unban_time[], len) {
    static _hours[3], _minutes[3], _seconds[3], _month[3], _day[3], _year[5];

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

    while (minutes >= 60) {
        minutes -= 60;
        hours++;
    }

    while (hours >= 24) {
        hours -= 24;
        day++;
    }

    new max_days = GetDaysInMonth(month, year);

    while (day > max_days) {
        day -= max_days;
        month++;
    }

    while (month > 12) {
        month -= 12;
        year++;
    }

    formatex(unban_time, len, "%02i:%02i:%02i %02i/%02i/%04i", hours, minutes, seconds, month, day, year);
}

GetDaysInMonth(month, year=0) {
    switch(month) {
        case 1, 3, 5, 7, 8, 10, 12:
            return 31; // months with 31 days
        case 4, 6, 9, 11:
            return 30; // months with 30 days
        case 2:
            return ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0) ? 29 : 28; // february
        default:
            return 30; // default to 30 days
    }
    return PLUGIN_HANDLED;
}

GetBanTime(const bantime, length[], len) {
    new minutes = bantime;
    new hours, days;

    if (minutes >= 1440) {
        days = minutes / 1440;
        minutes %= 1440;
    }

    if (minutes >= 60) {
        hours = minutes / 60;
        minutes %= 60;
    }

    if (days) {
        formatex(length, len, "%i day%s", days, days == 1 ? "" : "s");
        if (hours) {
            format(length, len, ", %i hour%s", hours, hours == 1 ? "" : "s");
        }
    } else if (hours) {
        formatex(length, len, "%i hour%s", hours, hours == 1 ? "" : "s");
    } else if (minutes) {
        formatex(length, len, "%i minute%s", minutes, minutes == 1 ? "" : "s");
    } else {
        copy(length, len, "Permanent Ban");
    }
}

stock UTIL_console_print(const id, const szFmt[], any:...) {
	static szMessage[256], iLen;
	vformat(szMessage, charsmax(szMessage), szFmt, 3);

	iLen = strlen(szMessage);
	szMessage[iLen++] = '^n';
	szMessage[iLen] = 0;

	if(is_user_connected(id)) {
		message_begin(MSG_ONE, SVC_PRINT, .player = id);
		write_string(szMessage);
		message_end();
	}
	else	server_print(szMessage);

	return PLUGIN_HANDLED;
}
