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

new g_eBanOptions[MAX_PLAYERS + 1][BanOptions], g_ServerAddress[32];

new Array:g_iLastBanArray;
new Handle:g_hSqlDbTuple;

public plugin_init() {
    register_plugin("Cortex Ban System", "0.0.3", "mIDnight");

    register_concmd("amx_pban", "@ConCmd_PBan", ADMIN_BAN, "<name, steamid, ip, #userid> <reason>");
    register_concmd("amx_ban", "@ConCmd_Ban", ADMIN_BAN, "<name, steamid, ip, #userid> <minutes> <reason>");
    register_concmd("amx_addban", "@ConCmd_AddBan", ADMIN_BAN, "<steamid> <ip> <reason>");
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
    hQueries = SQL_PrepareQuery(hSQLConnection, "CREATE TABLE IF NOT EXISTS %s (name varchar(32) NOT NULL, authid varchar(32) NOT NULL PRIMARY KEY, ip varchar(32) NOT NULL, bantime INT(7) NOT NULL, unbantime varchar(32) NOT NULL, reason varchar(120) NOT NULL, adminname varchar(32) NOT NULL, adminauthid varchar(32), serverip varchar(32) NOT NULL);", Table);

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

        server_cmd("^"wait^";^"wait^";^"wait^";^"kick^"  #%d ^"%L^"", get_user_userid(target), target, "KICK_YOU_ARE_BANNED_CHECK_CONSOLE");
    }

    new szAdminName[32], szAdminAuthID[32];
    get_user_ip(0, g_ServerAddress, 31);

    if(id && is_user_connected(id)) {
        get_user_name(id, szAdminName, charsmax(szAdminName));
        get_user_authid(id, szAdminAuthID, charsmax(szAdminAuthID));
    }
    else {
        formatex(szAdminName, charsmax(szAdminName), "PANEL");
        formatex(szAdminAuthID, charsmax(szAdminAuthID), "PANEL");
    }

    new szQuery[1096];
    formatex(szQuery, charsmax(szQuery), "INSERT INTO %s (name, authid, ip, bantime, unbantime, reason, adminname, adminauthid, serverip) VALUES ('%s', '%s', '%s', %i, '%s', '%s', '%s', '%s', '%s');", Table, szName, szAuthID, szIP, iBanTime, szUnBanTime, szReason, szAdminName, szAdminAuthID, g_ServerAddress);
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
    SendUserCommand(iTarget, "setinfo _sys ^"512^"");

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

@ConCmd_AddBan(const id, const level, const cid) {
    if (!cmd_access(id, level, cid, 3)) {
        return PLUGIN_HANDLED;
    }

    new szAdminName[32], szAdminAuthID[32];
    get_user_ip(0, g_ServerAddress, 31);

    if(id && is_user_connected(id)) {
        get_user_name(id, szAdminName, charsmax(szAdminName));
        get_user_authid(id, szAdminAuthID, charsmax(szAdminAuthID));
    }
    else {
        formatex(szAdminName, charsmax(szAdminName), "PANEL");
        formatex(szAdminAuthID, charsmax(szAdminAuthID), "PANEL");
    }

    new szDataExplode[4][32];
    formatex(szDataExplode[0], charsmax(szDataExplode[]), "OfflineBan");
    read_argv(1, szDataExplode[1], charsmax(szDataExplode[]));
    read_argv(2, szDataExplode[2], charsmax(szDataExplode[]));
    read_argv(3, szDataExplode[3], charsmax(szDataExplode[]));

    new szQuery[1096];
    formatex(szQuery, charsmax(szQuery), "INSERT INTO %s (name, authid, ip, bantime, unbantime, reason, adminname, adminauthid, serverip) VALUES ('%s', '%s', '%s', '-1', 'PERMANENT', '%s', '%s', '%s', '%s');", Table, szDataExplode[0], szDataExplode[1], szDataExplode[2], szDataExplode[3], szAdminName, szAdminAuthID, g_ServerAddress);

    SQL_ThreadQuery(g_hSqlDbTuple, "IgnoreHandle", szQuery);

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

stock GenerateUnbanTime(const bantime, unban_time[], len) {
    new hours, minutes, seconds, month, day, year;
    formatex(unban_time, len, "%02i:%02i:%02i %02i/%02i/%04i", hours, minutes, seconds, month, day, year);
    
    format_time(unban_time, len, "%H:%M:%S %m/%d/%Y", get_systime() + (bantime * 60));
}

GetBanTime(const bantime, length[], len) {
    new days = bantime / 1440;
    new hours = (bantime / 60) % 24;
    new minutes = bantime % 60;

    if (days) {
        formatex(length, len, "%i day%s", days, days == 1 ? "" : "s");
    }
    if (hours) {
        formatex(length, len, "%s%s%i hour%s", length, days ? ", " : "", hours, hours == 1 ? "" : "s");
    }
    if (minutes) {
        formatex(length, len, "%s%s%i minute%s", length, (days || hours) ? ", " : "", minutes, minutes == 1 ? "" : "s");
    }
    if (bantime == -1 || (!days && !hours && !minutes)) {
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

stock SendUserCommand(const id, const szText[], any:...)  {
	#pragma unused szText
	new sz_Message[192];
	format_args(sz_Message, charsmax(sz_Message), 1);
	message_begin(id == 0 ? MSG_ALL : MSG_ONE, 51, _, id);
	write_byte(strlen(sz_Message) + 2);
	write_byte(10);
	write_string(sz_Message);
	message_end();
}
