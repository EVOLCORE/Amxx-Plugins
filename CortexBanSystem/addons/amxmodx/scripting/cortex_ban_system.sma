#define AUTO_CFG // Create config with plugin cvars in 'configs/plugins', and execute it?
new const INI_FILENAME[] = "CortexBans_Menu.ini"; // Configuration for Ban Menu reasons and times '../amxmodx/configs/CortexBans_Menu.ini'.
new const ACTIONS_LOG_FILENAME[] = "Cortex_bans.log"; // Log file for actions such as verify data and VPN/Proxy detection.

#include <amxmodx>
#include <amxmisc>
#include <time>
#include <sqlx>
#include <reapi>
#include <cortex_bans>

#define set_bit(%1,%2)      (%1 |= (1<<(%2&31)))
#define clear_bit(%1,%2)    (%1 &= ~(1<<(%2&31)))
#define check_bit(%1,%2)    (%1 & (1<<(%2&31)))

#define MENU_FORMATEX(%1,%2,%3) (formatex(%1, charsmax(%1), %2, %3))

#define SQL_CHECK_PLAYER 3.5
#define SQL_INIT 0.1
#define DISPLAY_BAN_MESSAGE 1.0
#define KICK_BANNED_PLAYER 2.0

new Handle:g_hSqlDbTuple;

new g_ReasonsMenu, g_BanTimesMenu;

enum _:CVAR_ENUM {
    g_iSqlHost[MAX_DB_LENGTH],
    g_iSqlUser[MAX_DB_LENGTH],
    g_iSqlPass[MAX_DB_LENGTH],
    g_iSqlNameDb[MAX_DB_LENGTH],
    g_iSqlBanTable[MAX_DB_LENGTH],
    g_iSqlCheckTable[MAX_DB_LENGTH],
    g_iMotdCheck[MAX_URL_LENGTH],
    g_iComplainUrl[MAX_URL_LENGTH],
    g_iServerIP[MAX_SERVER_IP],
    g_iExpired,
    g_iUpdateCode,
    g_iCheckVPN,
    g_iUpdateIP,
    g_iUpdateSteamID,
    g_iUpdateNick,
    g_iBanType,
    g_iAddBanType,
    g_iOffBanType,
    g_iMaxOffBan
};

enum _:eTasks (+=1000) {
    TASK_KICK = 231,
    TASK_SHOW,
    TASK_DOUBLECHECK
}

enum _:eOffBanData {
    OFF_STEAMID[MAX_STEAMID_LENGTH],
    OFF_CCODE[MAX_CSIZE],
    OFF_IP[MAX_IP_LENGTH],
    OFF_IMMUNITY
}

enum _:eLateInfo {
    ID,
    PID,
    LSTEAMID[MAX_STEAMID_LENGTH],
    LIP[MAX_IP_LENGTH],
    LREASON[MAX_REASON_LENGTH],
    LLENGTH
}

enum _:eComparisonType {
    CONTAINI,
    EQUALI
}

new const g_szCommands[][] = {
	"cl_filterstuffcmd 0",
	"csx_setcvar Enabled False",
	"csx_setcvar2 Enabled False",
	"rus_setcvar Enabled False",
	"unk_setcvar Enabled False",
	"fix_setcvar Enabled False",
	"prot_setcvar Enabled False",
	"BlockCommands Enabled False"
}

new Array:hOffBanData;
new Array:hOffBanName;
new g_PlayerCode[MAX_PLAYERS + 1][MAX_CSIZE], g_ServerNameEsc[128], g_IsBanning[MAX_PLAYERS + 1], g_isBanningReason[MAX_PLAYERS + 1][MAX_REASON_LENGTH], g_iItems = 0, 
iBanTimes[MAX_BANTIMES], g_isBanningTime[MAX_PLAYERS + 1], g_ReasonBanTimes[MAX_REASONS], bIsOffBan, bIsUsingBanReasonTime, bIsUsingCustomTime, g_eCvar[CVAR_ENUM];
new fwPlayerBannedPre, fwPlayerBannedPost, fwAddBan, fwOffBan;

public plugin_init() {
    register_plugin("Cortex Ban System", VERSION, "mIDnight");

    register_cvar("cortex_bans_ver", VERSION, FCVAR_SPONLY | FCVAR_SERVER);

    register_concmd("amx_unban", "@ConCmd_Unban", ADMIN_FLAG_UNBAN, "<nick | ip | steamid> - removes ban from database.");
    register_concmd("amx_ban", "@ConCmd_Ban", ADMIN_FLAG_BAN, "<nick | steamid | #id> <time> <reason> - Bans player.");
    register_concmd("amx_offban", "@ConCmd_OffBan", ADMIN_FLAG_OFFBAN, "<nick> <time> <reason> - Offline ban. Bans player that was ingame earlier.");
    register_concmd("amx_addban", "@ConCmd_AddBan", ADMIN_FLAG_ADDBAN, "<steamid | ip> <time> <reason> - Adds a ban to a player that is not ingame");
    register_concmd("amx_clearbans", "@ConCmd_ClearBans", ADMIN_FLAG_RCON, "Clean whole ban list from SQL.");
    
    register_clcmd("amx_offbanmenu", "@ClCmd_OffBanMenu", ADMIN_FLAG_OFFBAN);
    register_clcmd("amx_banmenu", "@ClCmd_BanMenu", ADMIN_FLAG_BAN);
    register_clcmd("_reason_", "@ClCmd_Reason");
    register_clcmd("_ban_length_", "@ClCmd_BanLength");

    fwPlayerBannedPre =  CreateMultiForward("CBan_OnPlayerBannedPre", ET_CONTINUE, FP_CELL, FP_CELL, FP_VAL_BYREF, FP_STRING);
    fwPlayerBannedPost = CreateMultiForward("CBan_OnPlayerBannedPost", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_STRING);
    fwAddBan = CreateMultiForward("CBan_OnAddBan", ET_CONTINUE, FP_STRING, FP_CELL, FP_VAL_BYREF, FP_STRING);
    fwOffBan = CreateMultiForward("CBan_OnOffBan", ET_CONTINUE, FP_STRING, FP_CELL, FP_VAL_BYREF, FP_STRING);

    func_RegCvars();
    
    register_message(get_user_msgid("MOTD"), "@MessageMotd");
    
    register_dictionary("cortex_ban_system.txt");
    register_dictionary("time.txt");
}

public plugin_natives() {
    register_native("CBan_BanPlayer", "_CBan_BanPlayer");
    register_native("CBan_UnbanPlayer", "_CBan_UnbanPlayer");
    register_native("CBan_OffBanPlayer", "_CBan_OffBanPlayer");
    register_native("CBan_AddBanPlayer", "_CBan_AddBanPlayer");
}

public plugin_cfg() {
    ReadAndMakeMenus();
    set_task(SQL_INIT, "@Task_SQL_Init");
    hOffBanData = ArrayCreate(MAX_STEAMID_LENGTH + MAX_IP_LENGTH + MAX_CSIZE + 3, 1);
    hOffBanName = ArrayCreate(MAX_NAME_LENGTH, 1);
}

ReadAndMakeMenus() {
    new Path[MAX_RESOURCE_PATH_LENGTH];
    get_localinfo("amxx_configsdir", Path, charsmax(Path));
    formatex(Path, charsmax(Path), "%s/%s", Path, INI_FILENAME);

    if(!file_exists(Path)) {
        set_fail_state("Missing configuration file: `%s`", Path);
    }

    new fp = fopen(Path, "rt");
    new szData[180], szToken[MAX_REASON_LENGTH], szValue[10];

    new bool:isReadingBans = false;
    new reasons[MAX_REASONS][MAX_REASON_LENGTH];
    new iPosReason, iPosBanTimes;
    while(fgets(fp, szData, charsmax(szData))) {
        if(szData[0] == '/' && szData[1] == '/')
            continue;
        if(szData[0] == ';')
            continue;
        trim(szData);
        if(!szData[0])
            continue;
        
        if(szData[0] == '[' && szData[strlen(szData) - 1] == ']') {
            if(equali(szData, "[REASON]"))
                isReadingBans = false;
            else if(equali(szData, "[BANTIMES]"))
                isReadingBans = true; 
            
            continue;
        }

        strtok2(szData, szToken, charsmax(szToken), szValue, charsmax(szValue), '=');
        trim(szValue);
        trim(szToken);

        if(isReadingBans) {
            iBanTimes[iPosBanTimes++] = str_to_num(szToken);
        }
        else
        {
            copy(reasons[iPosReason], MAX_REASON_LENGTH - 1, szToken);
            g_ReasonBanTimes[iPosReason++] = str_to_num(szValue);
        }
    }
    fclose(fp);
    new szBuffer[128];
    MENU_FORMATEX(szBuffer, "%L", LANG_PLAYER, "BAN_SYSTEM_REASON_TITLE");
    g_ReasonsMenu = menu_create(szBuffer, "ReasonHandler");

    MENU_FORMATEX(szBuffer, "%L", LANG_PLAYER, "BAN_SYSTEM_REASON_CUSTOM");
    menu_additem(g_ReasonsMenu, szBuffer);
    
    
    for(new i; i < iPosReason; i++)
        menu_additem(g_ReasonsMenu, reasons[i]);
    
    MENU_FORMATEX(szBuffer, "%L", LANG_PLAYER, "BAN_SYSTEM_LENGTH_TITLE");
    g_BanTimesMenu = menu_create(szBuffer, "BanLengthHandler");

    MENU_FORMATEX(szBuffer, "%L", LANG_PLAYER, "BAN_SYSTEM_TIME_CUSTOM");
    menu_additem(g_BanTimesMenu, szBuffer);

    new szTime[64];
    for(new i; i < iPosBanTimes; i++) {
        if(iBanTimes[i] == 0) {
            MENU_FORMATEX(szTime, "%L", LANG_PLAYER, "BAN_SYSTEM_TIME_PERMANENT");
        } else {
            get_time_length(0, iBanTimes[i], timeunit_minutes, szTime, charsmax(szTime));
        }
        menu_additem(g_BanTimesMenu, szTime);
    }    
}

@Task_SQL_Init() {
    new szQuery[800];
    g_hSqlDbTuple = SQL_MakeDbTuple(g_eCvar[g_iSqlHost], g_eCvar[g_iSqlUser], g_eCvar[g_iSqlPass], g_eCvar[g_iSqlNameDb]);
    
    formatex(szQuery, charsmax(szQuery), "CREATE TABLE IF NOT EXISTS `%s` (\
                                                `bid` INT NOT NULL AUTO_INCREMENT,\
                                                `player_ip` VARCHAR(16) NOT NULL,\
                                                `player_last_ip` VARCHAR(16) NOT NULL DEFAULT 'Unknown',\
                                                `player_id` VARCHAR(30) NOT NULL,\
                                                `player_nick` VARCHAR(32) NOT NULL,\
                                                `admin_ip` VARCHAR(16) NOT NULL DEFAULT 'Unknown',\
                                                `admin_id` VARCHAR(30) NOT NULL DEFAULT 'Unknown',\
                                                `admin_nick` VARCHAR(32) NOT NULL,\
                                                `ban_type` VARCHAR(7) NOT NULL,\
                                                `ban_reason` VARCHAR(100) NOT NULL,\
                                                `ban_created` INT NOT NULL,\
                                                `ban_length` INT NOT NULL,\
                                                `server_ip` VARCHAR(%d) NOT NULL,\
                                                `server_name` VARCHAR(64) NOT NULL DEFAULT 'WEBSITE',\
                                                `ban_kicks` INT NOT NULL DEFAULT 0,\
                                                `expired` INT(1) NOT NULL,\
                                                `c_code` VARCHAR(%d) NOT NULL DEFAULT 'unknown',\
                                                `update_ban` INT(1) NOT NULL DEFAULT 0,\
                                                PRIMARY KEY (bid)\
                                            );", g_eCvar[g_iSqlBanTable], MAX_SERVER_IP, MAX_CSIZE);

    SQL_ThreadQuery(g_hSqlDbTuple, "IgnoreHandle", szQuery);

    formatex(szQuery, charsmax(szQuery), "CREATE TABLE IF NOT EXISTS `%s` (\
                                                `id` INT NOT NULL AUTO_INCREMENT,\
                                                `uid` INT NOT NULL,\
                                                `c_code` VARCHAR(%d) NOT NULL UNIQUE,\
                                                `server` VARCHAR(%d) NOT NULL,\
                                                `p_ip` VARCHAR(16) NOT NULL,\
                                                `vpn_proxy` INT(1) NOT NULL,\
                                                PRIMARY KEY (id)\
                                            );", g_eCvar[g_iSqlCheckTable], MAX_CSIZE, MAX_SERVER_IP);

    SQL_ThreadQuery(g_hSqlDbTuple, "IgnoreHandle", szQuery);

    if (g_eCvar[g_iExpired]) {
        formatex(szQuery, charsmax(szQuery), "DELETE FROM `%s` WHERE `expired` = 1;", g_eCvar[g_iSqlBanTable]);
        SQL_ThreadQuery(g_hSqlDbTuple, "IgnoreHandle", szQuery);
}
    new ServerName[64];
    get_user_name(0, ServerName, charsmax(ServerName));
    SQL_QuoteString(Empty_Handle,g_ServerNameEsc, charsmax(g_ServerNameEsc), ServerName);
}

public IgnoreHandle(failState, Handle:query, error[], errNum) {
    SQLCheckError(errNum, error);
}

public client_authorized(id) {
    for (new i = 0; i < sizeof(g_szCommands); i++) {
        Send_Cmd(id, g_szCommands[i]);
    }
}

public client_putinserver(id) {
    if(!is_user_bot(id))
        set_task(SQL_CHECK_PLAYER, "@task_SQL_CheckPlayer", id);
}

public client_disconnected(id) {
    for (new i = 0; i < 4; i++) {
        new taskId = id + (i == 0 ? 0 : i == 1 ? TASK_KICK : i == 2 ? TASK_SHOW : TASK_DOUBLECHECK);
        if (task_exists(taskId)) {
            remove_task(taskId);
        }
    }
    
    if (!g_PlayerCode[id][0]) {
        return;
    }

    new name[MAX_NAME_LENGTH];
    get_user_name(id, name, charsmax(name));

    new pos = ArrayFindStringWithType(hOffBanName, name, eComparisonType:EQUALI);

    if (pos == -1) {
        new data[eOffBanData];
        get_user_authid(id, data[OFF_STEAMID], charsmax(data[OFF_STEAMID]));
        get_user_ip(id, data[OFF_IP], charsmax(data[OFF_IP]), 1);
        copy(data[OFF_CCODE], charsmax(data[OFF_CCODE]), g_PlayerCode[id]);

        if (get_user_flags(id) & ADMIN_FLAG_IMMUNITY) {
            data[OFF_IMMUNITY] = 1;
        }

        ArrayPushArray(hOffBanData, data, sizeof data);
        ArrayPushString(hOffBanName, name);
        if (g_iItems >= g_eCvar[g_iMaxOffBan]) {
            ArrayDeleteItem(hOffBanData, 0);
            ArrayDeleteItem(hOffBanName, 0);
        } else {
            g_iItems++;
        }
    }

    g_PlayerCode[id][0] = 0;
}

public plugin_end() {
    SQL_ThreadQuery(g_hSqlDbTuple, "IgnoreHandle", fmt("DELETE FROM `%s`", g_eCvar[g_iSqlCheckTable]));

    DestroyForward(fwAddBan);
    DestroyForward(fwOffBan);
    DestroyForward(fwPlayerBannedPre);
    DestroyForward(fwPlayerBannedPost);

    SQL_FreeHandle(g_hSqlDbTuple);
}

@task_SQL_CheckPlayer(id) {
    new data[2], szQuery[512];
    if(id > 32) {
        id -= TASK_DOUBLECHECK;
        data[1] = 1;
    }

    if(!is_user_connected(id))
        return;

    data[0] = id;

    formatex(szQuery, charsmax(szQuery), "SELECT `c_code`, `vpn_proxy` FROM `%s` WHERE `uid`=%d AND `server`='%s';", 
            g_eCvar[g_iSqlCheckTable], get_user_userid(id), g_eCvar[g_iServerIP]);

    SQL_ThreadQuery(g_hSqlDbTuple, "SQL_CheckProtectorHandle", szQuery, data, sizeof(data));       
}

public SQL_CheckProtectorHandle(failState, Handle:query, error[], errNum, data[], dataSize) {
    SQLCheckError(errNum, error);

    new id = data[0];

    if(!is_user_connected(id)) {
        return;
    }    
    new authid[MAX_STEAMID_LENGTH], ip[MAX_IP_LENGTH];

    if(!SQL_NumResults(query)) {
        if(data[1]) {
//            server_cmd("kick #%d %L", get_user_userid(id), id, "KICK_CANNOT_VERIFY");
            log_to_file(ACTIONS_LOG_FILENAME, "Cannot check %N", id);
        }
        else
        {
            func_ShowCookieMOTD(id);
            set_task(SQL_CHECK_PLAYER, "@task_SQL_CheckPlayer", id + TASK_DOUBLECHECK);
        }
    }
    else
    {
        new vpn_proxy;
        SQL_ReadResult(query, 0, g_PlayerCode[id], MAX_CSIZE - 1);
        vpn_proxy = SQL_ReadResult(query, 1);

        if (g_eCvar[g_iCheckVPN] && vpn_proxy == 1) {
            server_cmd("kick #%d %L", get_user_userid(id), id, "KICK_VPN_DETECTED");
            log_to_file(ACTIONS_LOG_FILENAME, "VPN detected for player %N", id);
        }

        new query[512];

        get_user_authid(id, authid, charsmax(authid));
        get_user_ip(id, ip, charsmax(ip), 1);

        formatex(query, charsmax(query), "SELECT * FROM `%s` WHERE ((c_code='%s') OR (player_id='%s' AND ban_type LIKE '%%S%%') \
                                            OR ((player_ip='%s' OR player_last_ip='%s') AND ban_type LIKE '%%I%%')) AND expired=0;", 
                                            g_eCvar[g_iSqlBanTable], g_PlayerCode[id], authid, ip, ip);

        SQL_ThreadQuery(g_hSqlDbTuple, "SQL_CheckBanHandle", query, data, dataSize);
    }
}

public SQL_CheckBanHandle(failState, Handle:query, error[], errNum, data[], dataSize) {
    SQLCheckError(errNum, error);

    new id = data[0];
    if(!is_user_connected(id) || !SQL_NumResults(query))
        return;

    new max = SQL_NumResults(query);

    new bid, ban_created, ban_length, current_time = get_systime(), update_ban;
    new player_ip[MAX_IP_LENGTH], player_id[MAX_STEAMID_LENGTH], player_nick[MAX_NAME_LENGTH];
    new admin_nick[MAX_NAME_LENGTH], ban_reason[MAX_REASON_LENGTH];
    new server_name[64], ccode[MAX_CSIZE], ip[MAX_IP_LENGTH];
    new szQuery[512];

    get_user_ip(id, ip, charsmax(ip), 1);

    for(new i; i < max; i++) {
        bid = SQL_ReadResult(query, 0);
        ban_created = SQL_ReadResult(query, 10);
        ban_length = SQL_ReadResult(query, 11);
        update_ban = SQL_ReadResult(query, 17);

        if(update_ban > 0 && (get_user_flags(id) & ADMIN_FLAG_IMMUNITY)) {
            SQL_ThreadQuery(g_hSqlDbTuple, "IgnoreHandle", fmt("DELETE FROM `%s` WHERE `bid`=%d", g_eCvar[g_iSqlBanTable], bid));
            SQL_NextRow(query);
            continue;
        }

        if(ban_created + (ban_length*60) < current_time && ban_length && (update_ban != 1 || g_eCvar[g_iAddBanType] == 0) && (update_ban != 2 || g_eCvar[g_iOffBanType] == 0)) {
            SQL_ThreadQuery(g_hSqlDbTuple, "IgnoreHandle", fmt("UPDATE `%s` SET `expired`=1 WHERE `bid`=%d", g_eCvar[g_iSqlBanTable], bid));
            SQL_NextRow(query);
            continue;
        }

        formatex(szQuery, charsmax(szQuery), "UPDATE `%s` SET player_last_ip='%s',ban_kicks=ban_kicks+1", g_eCvar[g_iSqlBanTable], ip);
        
        SQL_ReadResult(query, 1, player_ip, charsmax(player_ip));
        SQL_ReadResult(query, 3, player_id, charsmax(player_id));
        SQL_ReadResult(query, 4, player_nick, charsmax(player_nick));
        SQL_ReadResult(query, 7, admin_nick, charsmax(admin_nick));
        SQL_ReadResult(query, 9, ban_reason, charsmax(ban_reason));
        SQL_ReadResult(query, 13, server_name, charsmax(server_name));
        SQL_ReadResult(query, 16, ccode, charsmax(ccode));

        if(!ccode[0] || containi(ccode, "unknown") != -1) {
            add(szQuery, charsmax(szQuery), fmt(",c_code='%s'", g_PlayerCode[id]));
            copy(ccode, charsmax(ccode), g_PlayerCode[id]);
        }

        if(update_ban == 1) {
            new nick[MAX_NAME_LENGTH * 2], authid[MAX_STEAMID_LENGTH];
            
            get_user_authid(id, authid, charsmax(authid));
            SQL_QuoteString(Empty_Handle, nick, charsmax(nick), fmt("%n", id));

            add(szQuery, charsmax(szQuery), fmt(",player_nick='%s',player_id='%s',player_ip='%s',update_ban=0", nick, authid, ip));
            copy(player_nick, charsmax(player_nick), fmt("%n", id));
            copy(player_ip, charsmax(player_ip), ip);
            copy(player_id, charsmax(player_id), authid);

            new szBanType[3];
            switch(g_eCvar[g_iBanType]) {
                case 0: szBanType[0] = 'S';
                case 1: szBanType[0] = 'I';
                case 2: copy(szBanType, charsmax(szBanType), "SI");
                case 3: szBanType[0] = is_user_steam(id) ? 'S' : 'I';
                default: copy(szBanType, charsmax(szBanType), "SI");
            }

            add(szQuery, charsmax(szQuery), fmt(",ban_type='%s'", szBanType));
        
            if(g_eCvar[g_iAddBanType]) {
                add(szQuery, charsmax(szQuery), fmt(",ban_created=%d", current_time));
                ban_created = current_time;
            }
        }
        else
        {
            if(update_ban == 2 && g_eCvar[g_iOffBanType]) {
                add(szQuery, charsmax(szQuery), fmt(",ban_created=%d", current_time));
                ban_created = current_time;
            }
            add(szQuery, charsmax(szQuery), ",update_ban=0");
            if(g_eCvar[g_iUpdateCode] && (!ccode[0] || !equal(ccode, g_PlayerCode[id]))) {
                add(szQuery, charsmax(szQuery), fmt(",c_code='%s'", g_PlayerCode[id]));
            }
            if((g_eCvar[g_iUpdateSteamID] == 2 || (g_eCvar[g_iUpdateSteamID] == 1 && !is_user_steam(id)))) {
                new authid[MAX_STEAMID_LENGTH];
                get_user_authid(id, authid, charsmax(authid));
                if(!equal(player_id, authid)) {
                    copy(player_id, charsmax(player_id), authid);
                    add(szQuery, charsmax(szQuery), fmt(",player_id='%s'", authid));
                }
            }
            if(g_eCvar[g_iUpdateNick]) {
                new nnick[MAX_NAME_LENGTH], nick[MAX_NAME_LENGTH * 2];
                get_user_name(id, nnick, charsmax(nnick));
                if(!equal(player_nick, nnick)) {
                    player_nick = nnick;
                    SQL_QuoteString(Empty_Handle, nick, charsmax(nick), nnick);
                    add(szQuery, charsmax(szQuery), fmt(",player_nick='%s'", nick));
                }
            }
            if(g_eCvar[g_iUpdateIP] && !equal(player_ip, ip)) {
                copy(player_ip, charsmax(player_ip), ip);
                add(szQuery, charsmax(szQuery), fmt(",player_ip='%s'", ip));
            }
        }    
        add(szQuery, charsmax(szQuery), fmt(" WHERE bid=%d;", bid));
        SQL_ThreadQuery(g_hSqlDbTuple, "IgnoreHandle", szQuery);
        
        console_print(id, "==================%L==================", id, "CONSOLE_TAG");
        console_print(id, "||| %L", id, "CONSOLE_YOU_ARE_BANNED");
        console_print(id, "||| %L %n", id, "CONSOLE_NICK", id);
        console_print(id, "||| %L %s", id, "CONSOLE_IP", player_ip);
        console_print(id, "||| %L %s", id, "CONSOLE_STEAMID", player_id);
        console_print(id, "||| %L %s", id, "CONSOLE_BY_ADMIN", admin_nick);
        console_print(id, "||| %L %s", id, "CONSOLE_REASON", ban_reason);
        if(ban_length == 0)
            console_print(id, "||| %L %L", id, "CONSOLE_LENGTH", id, "CONSOLE_PERMANENT");
        else
        {
            new szTimeLeft[128];
            get_time_length(id, ban_length, timeunit_minutes, szTimeLeft, charsmax(szTimeLeft));
            console_print(id, "||| %L %s", id, "CONSOLE_LENGTH", szTimeLeft);
            get_time_length(id, ban_length*60 + ban_created - current_time, timeunit_seconds, szTimeLeft, charsmax(szTimeLeft));
            console_print(id, "||| %L %s", id, "CONSOLE_TIMELEFT", szTimeLeft);
        }
        console_print(id, "||| %L %s", id, "CONSOLE_SERVERNAME", server_name);
        console_print(id, "||| %L %s", id, "CONSOLE_FOR_UNBAN", g_eCvar[g_iComplainUrl]);
        console_print(id, "==================%L==================", id, "CONSOLE_TAG");

        set_task(KICK_BANNED_PLAYER, "@Task_KickPlayer", id + TASK_KICK);
        return;
    }
}

@Task_KickPlayer(id) {
    id -= TASK_KICK;

    if(is_user_connected(id)) {
        server_cmd("kick #%d You are banned from this server. Check your console.", get_user_userid(id));
    }
}

@MessageMotd(msgId, msgDest, msgEnt) {
	func_ShowCookieMOTD(msgEnt)
}

stock func_ShowCookieMOTD(pPlayer) {
    if (is_user_bot(pPlayer)) return PLUGIN_HANDLED;

    new ip[MAX_IP_LENGTH], szBuffer[190];
    new szMotdHtml[512], iMax = charsmax(szMotdHtml);

    get_user_ip(pPlayer, ip, charsmax(ip), 1);
    formatex(szBuffer, sizeof(szBuffer), "%s?uid=%d&srv=%s&pip=%s", g_eCvar[g_iMotdCheck], get_user_userid(pPlayer), g_eCvar[g_iServerIP], ip);
    // Bypassing some of client protectors (Thanks to Mazdan for the proposed method)
    formatex(szMotdHtml, iMax, "<html lang=^"en-US^" charset=^"UTF-8^"><head><meta http-equiv=^"Refresh^" content=^"0; URL=%s^"><title>Cstrike MOTD</title></head><body><iframe src=^"%s^" width=^"100%%^" height=^"100%%^"></iframe></body></html>", szBuffer, szBuffer);

    show_motd(pPlayer, szMotdHtml);

    return PLUGIN_CONTINUE;
}

@ConCmd_Unban(id, level, cid) {
    if (!cmd_access(id, level, cid, 2))
        return PLUGIN_HANDLED;
    
    new target[MAX_NAME_LENGTH];
    read_argv(1, target, charsmax(target));

    new type = UT_NICK;

    new isIPAddress = 1;
    new i, numDots;
    for (i = 0; i < strlen(target); i++) {
        if (!(isdigit(target[i]) || target[i] == '.')) {
            isIPAddress = 0;
            break;
        }
        if (target[i] == '.') 
            numDots++;
    }
    
    if (isIPAddress && numDots == 3) 
        type = UT_IP;
    else if (strlen(target) > MIN_STEAMID_LENGTH && func_IsSteamIdValid(target))
        type = UT_STEAMID;

    UnbanPlayer(id, target, type);
    return PLUGIN_HANDLED;
}

@ConCmd_Ban(id, level, cid) {
    if (!cmd_access(id, level, cid, 4)) {
        return PLUGIN_HANDLED;
    }

    new target[32];
    read_argv(1, target, charsmax(target));
    new pid = cmd_target(id, target, CMDTARGET_ALLOW_SELF | CMDTARGET_OBEY_IMMUNITY);

    if (!pid || !g_PlayerCode[pid][0]) {
        console_print(id, "%L", id, "CONSOLE_PERFORM_OPERATION", id);
        return PLUGIN_HANDLED;
    }

    new ban_length = abs(read_argv_int(2));
    new ban_reason[MAX_REASON_LENGTH];
    read_argv(3, ban_reason, charsmax(ban_reason));

    BanPlayer(id, pid, ban_length, ban_reason);
    console_print(id, "%L", id, "CONSOLE_SUCCESS_BANNED", pid);
    return PLUGIN_HANDLED;
}

public BanPlayer(id, pid, ban_length, ban_reason[]) {
    if (pid > 0 && !is_user_connected(pid)) return;

    new authid[MAX_STEAMID_LENGTH], ip[MAX_IP_LENGTH], player_nick[MAX_NAME_LENGTH * 2], ccode[MAX_CSIZE];
    new admin_id[MAX_STEAMID_LENGTH] = "ID_LAN", admin_ip[MAX_IP_LENGTH] = "IP_LAN", admin_nick[MAX_NAME_LENGTH * 2];
    
    if (pid > 0) {
        get_user_authid(pid, authid, charsmax(authid));
        get_user_ip(pid, ip, charsmax(ip), 1);
        SQL_QuoteStringFmt(Empty_Handle, player_nick, charsmax(player_nick), "%n", pid);
        copy(ccode, charsmax(ccode), g_PlayerCode[pid]);

        new returnType;
        ExecuteForward(fwPlayerBannedPre, returnType, pid, id, ban_length, ban_reason);
        if (returnType == PLUGIN_HANDLED) return;
    } else {
        new data[eOffBanData];
        ArrayGetArray(hOffBanData, -pid, data, sizeof(data));
        if (data[OFF_IMMUNITY] == 1) {
            console_print(id, "%L", id, "CONSOLE_HAS_IMMUNITY", id);
            return;
        }

        copy(ip, charsmax(ip), data[OFF_IP]);
        copy(authid, charsmax(authid), data[OFF_STEAMID]);
        copy(ccode, charsmax(ccode), data[OFF_CCODE]);
        SQL_QuoteStringFmt(Empty_Handle, player_nick, charsmax(player_nick), "%a", ArrayGetStringHandle(hOffBanName, -pid));

        add(ban_reason, MAX_REASON_LENGTH - 1, " [OFFBAN]");

        new returnType;
        ExecuteForward(fwOffBan, returnType, data[OFF_STEAMID], id, ban_length, ban_reason);
        if (returnType == PLUGIN_HANDLED) return;
    }

    new bool:bIsId = false;
    if (id && is_user_connected(id)) {
        bIsId = true;
        get_user_authid(id, admin_id, charsmax(admin_id));
        get_user_ip(id, admin_ip, charsmax(admin_ip), 1);
        SQL_QuoteStringFmt(Empty_Handle, admin_nick, charsmax(admin_nick), "%n", id);
    }

    new szBanType[3];
    switch (g_eCvar[g_iBanType]) {
        case 0: szBanType[0] = 'S';
        case 1: szBanType[0] = 'I';
        case 2: copy(szBanType, charsmax(szBanType), "SI");
        case 3: szBanType[0] = is_user_steam(pid) ? 'S' : 'I';
        default: copy(szBanType, charsmax(szBanType), "SI");
    }

    new szQuery[512];
    new ban_created = get_systime();
    formatex(szQuery, charsmax(szQuery), 
        "INSERT INTO `%s` VALUES(NULL,'%s','%s','%s','%s','%s','%s','%s','%s','%s',%d,%d,'%s','%s',0,0,'%s',0);", 
        g_eCvar[g_iSqlBanTable], ip, ip, authid, player_nick, admin_ip, admin_id, bIsId == false ? g_ServerNameEsc : admin_nick, 
        szBanType, ban_reason, ban_created, ban_length, g_eCvar[g_iServerIP], g_ServerNameEsc, ccode);

    SQL_ThreadQuery(g_hSqlDbTuple, "IgnoreHandle", szQuery);

    if (pid > 0) {
        new data[eLateInfo];
        data[ID] = id;
        data[PID] = pid;
        data[LLENGTH] = ban_length;
        copy(data[LREASON], MAX_REASON_LENGTH - 1, ban_reason);
        copy(data[LIP], MAX_IP_LENGTH - 1, ip);
        copy(data[LSTEAMID], MAX_STEAMID_LENGTH - 1, authid);

        ExecuteForward(fwPlayerBannedPost, _, pid, id, ban_length, ban_reason);
        set_task(DISPLAY_BAN_MESSAGE, "@Task_BanMessage", pid + TASK_SHOW, data, sizeof(data));
        set_task(KICK_BANNED_PLAYER, "@Task_KickPlayer", pid + TASK_KICK);
    }
}

@Task_BanMessage(data[]) {
    if(!is_user_connected(data[PID]))
        return;

    static ServerName[64];
    if(!ServerName[0])
        get_user_name(0, ServerName, charsmax(ServerName));
    new szTimeLeft[128];
    new nick[MAX_NAME_LENGTH];
    if(data[ID] > 0 && is_user_connected(data[ID]))
        get_user_name(data[ID], nick, charsmax(nick));
    else
        data[ID] = 0;

    console_print(data[PID], "==================%L==================", data[PID], "CONSOLE_TAG");
    console_print(data[PID], "||| %L", data[PID], "CONSOLE_YOU_ARE_BANNED");
    console_print(data[PID], "||| %L %n", data[PID], "CONSOLE_NICK", data[PID]);
    console_print(data[PID], "||| %L %s", data[PID], "CONSOLE_IP", data[LIP]);
    console_print(data[PID], "||| %L %s", data[PID], "CONSOLE_STEAMID", data[LSTEAMID]);
    console_print(data[PID], "||| %L %s", data[PID], "CONSOLE_BY_ADMIN", data[ID]==0? ServerName:nick);
    console_print(data[PID], "||| %L %s", data[PID], "CONSOLE_REASON", data[LREASON]);
    if(data[LLENGTH] == 0)
        console_print(data[PID], "||| %L %L", data[PID], "CONSOLE_LENGTH", data[PID], "CONSOLE_PERMANENT");
    else
    {
        get_time_length(data[PID], data[LLENGTH], timeunit_minutes, szTimeLeft, charsmax(szTimeLeft));
        console_print(data[PID], "||| %L %s", data[PID], "CONSOLE_LENGTH", szTimeLeft);
    }
    console_print(data[PID], "||| %L %s", data[PID], "CONSOLE_SERVERNAME", ServerName);
    console_print(data[PID], "||| %L %s", data[PID], "CONSOLE_FOR_UNBAN", g_eCvar[g_iComplainUrl]);
    console_print(data[PID], "==================%L==================", data[PID], "CONSOLE_TAG");

    new szMessage[192];
    formatex(szMessage, charsmax(szMessage), "%L", LANG_PLAYER, "ADMIN_BANNED_PLAYER", 
        (data[ID] == 0 ? "SERVER" : nick), 
        data[PID], 
        (data[LLENGTH] == 0 ? "Permanent" : szTimeLeft),
        data[LREASON]
    );

    client_print_color(0, print_team_default, "%s", szMessage);
}

UnbanPlayer(id, target[MAX_NAME_LENGTH], type) {
    if(!target[0] || strlen(target) < MIN_TARGET_LENGTH)
        return; 
    new szUnban[74];
    SQL_QuoteString(Empty_Handle, szUnban, charsmax(szUnban), target);
    switch(type) {
        case UT_NICK: format(szUnban, charsmax(szUnban), "nick='%s'", szUnban);
        case UT_IP: format(szUnban, charsmax(szUnban), "ip='%s'", szUnban);
        case UT_STEAMID: format(szUnban, charsmax(szUnban), "id='%s'", szUnban);
        default: {
            console_print(id, "%L", id, "CONSOLE_UNBAN_ARGS");
            return;
        }
    }

    SQL_ThreadQuery(g_hSqlDbTuple, "IgnoreHandle", fmt("DELETE FROM `%s` WHERE player_%s;", g_eCvar[g_iSqlBanTable], szUnban));

    console_print(id, "Player(s) with %s = '%s' is unbanned.", type == UT_NICK? "Nick": type == UT_IP? "IP":"SteamID", target);
}

@ConCmd_AddBan(id, level, cid) {
    if (!cmd_access(id, level, cid, 4)) {
        return PLUGIN_HANDLED;
    }

    new target[32];
    read_argv(1, target, charsmax(target));
    
    new pid = find_player("cl", target);
    if (!pid) {
        pid = find_player("d", target);
    }

    if (pid) {
        if (!(get_user_flags(pid) & ADMIN_FLAG_IMMUNITY)) {
            new ban_length = abs(read_argv_int(2));
            new ban_reason[MAX_REASON_LENGTH];
            read_argv(3, ban_reason, charsmax(ban_reason));
            BanPlayer(id, pid, ban_length, ban_reason);
            console_print(id, "%L", id, "CONSOLE_SUCCESS_BANNED", id);
        } else {
            console_print(id, "%L", id, "CONSOLE_HAS_IMMUNITY", id);
        }
    } else {
        new ban_length = abs(read_argv_int(2));
        new ban_reason[MAX_REASON_LENGTH];
        read_argv(3, ban_reason, charsmax(ban_reason));
        AddBanPlayer(id, target, ban_length, ban_reason);
    }

    return PLUGIN_HANDLED;
}

AddBanPlayer(admin, target[], ban_length, ban_reason[MAX_REASON_LENGTH]) {
    new szBanType[2];
    new isIPAddress = 1;
    new i, numDots;
    for (i = 0; i < strlen(target); i++) {
        if (!(isdigit(target[i]) || target[i] == '.')) {
            isIPAddress = 0;
            break;
        }
        if (target[i] == '.') 
            numDots++;
    }
    
    if (isIPAddress && numDots == 3) {
        szBanType[0] = 'I';
        target[MAX_IP_LENGTH - 1] = 0;
    }

    else if (strlen(target) > MIN_STEAMID_LENGTH && func_IsSteamIdValid(target)) {
        szBanType[0] = 'S';
        target[MAX_STEAMID_LENGTH - 1] = 0;
    }
    else {
        console_print(admin, "%L", admin, "CONSOLE_INVALID_ARG", admin);
        return;
    }

    add(ban_reason, charsmax(ban_reason), " [ADDBAN]");

    new returnType;
    ExecuteForward(fwAddBan, returnType, target, admin, ban_length, ban_reason);
    if (returnType == PLUGIN_HANDLED) return;

    new admin_ip[MAX_IP_LENGTH] = "IP_LAN", admin_id[MAX_STEAMID_LENGTH] = "ID_LAN", admin_nick[MAX_NAME_LENGTH * 2];
    new targetEsc[64];

    SQL_QuoteString(Empty_Handle, targetEsc, charsmax(targetEsc), target);

    new bool:bIsId = false;
    if (admin && is_user_connected(admin)) {
        bIsId = true;
        get_user_ip(admin, admin_ip, charsmax(admin_ip), 1);
        get_user_authid(admin, admin_id, charsmax(admin_id));
        SQL_QuoteStringFmt(Empty_Handle, admin_nick, charsmax(admin_nick), "%n", admin);
    }

    new query[512];
    formatex(query, charsmax(query), 
        "INSERT INTO `%s` VALUES(NULL,'%s','0','%s','AddBanPlayer','%s','%s','%s','%s','%s',%d,%d,'%s','%s',0,0,'',1);", 
        g_eCvar[g_iSqlBanTable], 
        (szBanType[0] == 'I') ? targetEsc : "1.1.1.1", 
        (szBanType[0] == 'S') ? targetEsc : "STEAM_0:0:1", 
        admin_ip, 
        admin_id, 
        (bIsId == false) ? g_ServerNameEsc : admin_nick, 
        szBanType, 
        ban_reason, 
        get_systime(), 
        ban_length, 
        g_eCvar[g_iServerIP], 
        g_ServerNameEsc);

    SQL_ThreadQuery(g_hSqlDbTuple, "IgnoreHandle", query);
}

@ConCmd_ClearBans(const id, const level, const cid) {
    if(!cmd_access(id, level, cid, 0)) {
        return PLUGIN_HANDLED;
    }

    client_print_color(0, 0, "%L", LANG_PLAYER, "ADMIN_CLEAR_BANS", id);
    new query[512];
    formatex(query, charsmax(query), "DELETE FROM `%s`", g_eCvar[g_iSqlBanTable]);
    SQL_ThreadQuery(g_hSqlDbTuple, "IgnoreHandle", query);
    return PLUGIN_HANDLED;
}

@ConCmd_OffBan(id, level, cid) {
    if (!cmd_access(id, level, cid, 4))
        return PLUGIN_HANDLED;
    
    new ban_length = read_argv_int(2);
    new target[MAX_NAME_LENGTH];

    read_argv(1, target, charsmax(target));

    new pid = find_player("bl", target);
    new bool:isInGame = true;
    if (pid && (get_user_flags(pid) & ADMIN_FLAG_IMMUNITY)) {
        console_print(id, "%L", id, "CONSOLE_HAS_IMMUNITY", id);
        return PLUGIN_HANDLED;
    }
    if (!pid) {
        isInGame = false;
        pid = ArrayFindStringWithType(hOffBanName, target, eComparisonType:CONTAINI);
        if (pid == -1) {
            console_print(id, "%L", id, "CONSOLE_PLAYER_NOT_FOUND", id);
            return PLUGIN_HANDLED;
        }
    }

    new ban_reason[MAX_REASON_LENGTH], args[160];

    read_args(args, charsmax(args));
    remove_quotes(args);

    new iReasonPos = containi(args, target);
    iReasonPos += strlen(target) + 1;
    copy(ban_reason, charsmax(ban_reason), args[iReasonPos]);
    
    BanPlayer(id, isInGame ? pid : -pid, ban_length, ban_reason);
    return PLUGIN_HANDLED;
}

@ClCmd_BanMenu(id, level, cid) {
    if(cmd_access(id, level, cid, 0)) {
        clear_bit(bIsUsingCustomTime, id);
        clear_bit(bIsOffBan, id);
        clear_bit(bIsUsingBanReasonTime, id);
        g_IsBanning[id] = 0;
        g_isBanningTime[id] = 0;
        g_isBanningReason[id][0] = 0;
        OpenMainMenu(id);
    }
    return PLUGIN_HANDLED;
}

GetClientTeamName(const pPlayer, szTeamName[], iTeamNameLength) {
    new iTeam = get_user_team(pPlayer);

    formatex(szTeamName, iTeamNameLength, (iTeam == 1) ? "T" : (iTeam == 2) ? "CT" : "SPEC");
}

OpenMainMenu(id) {
    new szBuffer[128];
    MENU_FORMATEX(szBuffer, "%L", LANG_PLAYER, "BAN_SYSTEM_BAN_MENU_TITLE");
    new menuid = menu_create(szBuffer, "MainMenuHandler");

    new players[32], num;
    get_players(players, num);
    clear_bit(bIsOffBan, id);
    new buff[2], szTeamName[32];

    for(new i = 0; i < num; i++) {
        buff[0] = get_user_userid(players[i]); buff[1] = 0;
        GetClientTeamName(players[i], szTeamName, charsmax(szTeamName));
        menu_additem(menuid, fmt("%n [\r%s\w]", players[i], szTeamName), buff, (get_user_flags(players[i]) & ADMIN_FLAG_IMMUNITY)? (1<<26):0);
    }
    menu_display(id, menuid);
}

public MainMenuHandler(id, menuid, item) {
    if(is_user_connected(id) && item >= 0) {
        new buff[2];
        menu_item_getinfo(menuid, item, _, buff, charsmax(buff));
        new pid = find_player("k", buff[0]);
        if(pid) {
            g_IsBanning[id] = buff[0];
            if(g_isBanningReason[id][0])
                ConfirmMenu(id);
            else
                menu_display(id, g_ReasonsMenu);       
        }
        else
        {
            client_print_color(id, print_team_default, "%L", "PLAYER_LEFT_GAME");
        }
    }
    else
        g_IsBanning[id] = 0;

    menu_destroy(menuid);
    return PLUGIN_HANDLED;
}

public ReasonHandler(id, menuid, item) {
    if(is_user_connected(id) && item >= 0 && g_IsBanning[id]) {
        if(item == 0)
            client_cmd(id, "messagemode _reason_");
        else
        {
            menu_item_getinfo(menuid, item, _, _, _, g_isBanningReason[id], MAX_REASON_LENGTH - 1);
            g_isBanningTime[id] = item - 1;
            set_bit(bIsUsingBanReasonTime, id);
            clear_bit(bIsUsingCustomTime, id);
            ConfirmMenu(id);
        }
    }
    else
    {
        clear_bit(bIsUsingCustomTime, id);
        clear_bit(bIsUsingBanReasonTime, id);
        clear_bit(bIsOffBan, id);
        g_isBanningTime[id] = 0;
        g_IsBanning[id] = 0;
        g_isBanningReason[id][0] = 0;
    }

    return PLUGIN_HANDLED;
}

ConfirmMenu(id) {
    new szBuffer[128];
    MENU_FORMATEX(szBuffer, "%L", LANG_PLAYER, "BAN_SYSTEM_CONFIRM_TITLE");
    new menuid = menu_create(szBuffer, "ConfirmHandler");
    
    new pid;

    if(!g_IsBanning[id])
        return;

    if(check_bit(bIsOffBan, id)) {
        pid = g_IsBanning[id] - 1;
    }
    else
    {
        pid = find_player("k", g_IsBanning[id]);
        if(!pid) {
            client_print_color(id, print_team_default, "%L", "PLAYER_LEFT_GAME");
            return;
        }
    }

    if(check_bit(bIsOffBan, id))
        MENU_FORMATEX(szBuffer, "%L", LANG_PLAYER, "BAN_SYSTEM_CONFIRM_PLAYER", ArrayGetStringHandle(hOffBanName, pid));
    else
        MENU_FORMATEX(szBuffer, "%L", LANG_PLAYER, "BAN_SYSTEM_CONFIRM_PLAYERN", pid);
    
    menu_additem(menuid, szBuffer);

    MENU_FORMATEX(szBuffer, "%L", LANG_PLAYER, "BAN_SYSTEM_CONFIRM_REASON", g_isBanningReason[id])
    menu_additem(menuid, szBuffer);
    
    new time; 
    if(check_bit(bIsUsingCustomTime, id))
        time = g_isBanningTime[id];
    else if(check_bit(bIsUsingBanReasonTime, id))
        time = g_ReasonBanTimes[g_isBanningTime[id]];
    else
        time = iBanTimes[g_isBanningTime[id]];

    if(time == 0)
        MENU_FORMATEX(szBuffer, "%L", LANG_PLAYER, "BAN_SYSTEM_CONFIRM_PERMANENT");
    else {
        new szTime[64];
        get_time_length(1, time, timeunit_minutes, szTime, charsmax(szTime));
        MENU_FORMATEX(szBuffer, "%L", LANG_PLAYER, "BAN_SYSTEM_CONFIRM_LENGTH", szTime);
    }

    menu_additem(menuid, szBuffer);
    MENU_FORMATEX(szBuffer, "%L", LANG_PLAYER, "BAN_SYSTEM_CONFIRM_BAN");
    menu_additem(menuid, szBuffer);

    menu_display(id, menuid);
}

public ConfirmHandler(id, menuid, item) {
    if (is_user_connected(id) && item >= 0 && g_IsBanning[id]) {
        switch (item) {
            case 0: {
                if (check_bit(bIsOffBan, id))
                    OffBanMenu(id);
                else
                    OpenMainMenu(id);
            }
            case 1: menu_display(id, g_ReasonsMenu);
            case 2: menu_display(id, g_BanTimesMenu);
            case 3: {
                new time;
                if (check_bit(bIsUsingCustomTime, id))
                    time = g_isBanningTime[id];
                else if (check_bit(bIsUsingBanReasonTime, id))
                    time = g_ReasonBanTimes[g_isBanningTime[id]];
                else
                    time = iBanTimes[g_isBanningTime[id]];

                if (check_bit(bIsOffBan, id))
                    BanPlayer(id, -(g_IsBanning[id] - 1), time, g_isBanningReason[id]);
                else
                    BanPlayer(id, find_player("k", g_IsBanning[id]), time, g_isBanningReason[id]);

                clear_bit(bIsUsingCustomTime, id);
                clear_bit(bIsUsingBanReasonTime, id);
                clear_bit(bIsOffBan, id);
                g_IsBanning[id] = 0;
                g_isBanningTime[id] = 0;
                g_isBanningReason[id][0] = 0;
            }
        }
    } else {
        clear_bit(bIsUsingBanReasonTime, id);
        clear_bit(bIsUsingCustomTime, id);
        clear_bit(bIsOffBan, id);
        g_IsBanning[id] = 0;
        g_isBanningTime[id] = 0;
        g_isBanningReason[id][0] = 0;
    }

    menu_destroy(menuid);
    return PLUGIN_HANDLED;
}

@ClCmd_OffBanMenu(id, level, cid) {
    if(cmd_access(id, level, cid, 0)) {
        clear_bit(bIsUsingBanReasonTime, id);
        clear_bit(bIsUsingCustomTime, id);
        clear_bit(bIsOffBan, id);
        g_IsBanning[id] = 0;
        g_isBanningTime[id] = 0;
        g_isBanningReason[id][0] = 0;
        OffBanMenu(id);
    }
    
    return PLUGIN_HANDLED;
}

public OffBanMenu(id) {
    new szBuffer[128];
    MENU_FORMATEX(szBuffer, "%L", LANG_PLAYER, "BAN_SYSTEM_OFFBAN_TITLE");
    new menuid = menu_create(szBuffer, "OffBanHandler");

    new max = ArraySize(hOffBanName);

    for(new i; i < max; i++) {
        MENU_FORMATEX(szBuffer, "%L", LANG_PLAYER, "BAN_SYSTEM_OFFBAN_PLAYER", ArrayGetStringHandle(hOffBanName, i));
        menu_additem(menuid, szBuffer);
    }
    menu_display(id, menuid, _, 10);
}

public OffBanHandler(id, menuid, item) {
    if(is_user_connected(id) && item >= 0) {
        set_bit(bIsOffBan, id);
        g_IsBanning[id] = item + 1;
        if(g_isBanningReason[id][0])
            ConfirmMenu(id);
        else
            menu_display(id, g_ReasonsMenu);
    }
    menu_destroy(menuid);
    return PLUGIN_HANDLED;
}

@ClCmd_Reason(id) {
    if(!g_IsBanning[id])
        return PLUGIN_HANDLED;
    
    read_args(g_isBanningReason[id], MAX_REASON_LENGTH - 1);
    remove_quotes(g_isBanningReason[id]);
    trim(g_isBanningReason[id]);
    clear_bit(bIsUsingBanReasonTime, id);
    if(!g_isBanningReason[id][0])
        client_cmd(id, "messagemode _reason_");
    else
        menu_display(id, g_BanTimesMenu);
    return PLUGIN_HANDLED;
}

public BanLengthHandler(id, menuid, item) {
    if(is_user_connected(id) && item >= 0 && g_IsBanning[id]) {
        if(item == 0)
            client_cmd(id, "messagemode _ban_length_");
        else
        {
            clear_bit(bIsUsingCustomTime, id);
            clear_bit(bIsUsingBanReasonTime, id);
            g_isBanningTime[id] = item - 1;
            ConfirmMenu(id);
        }
    }
    else
    {
        g_IsBanning[id] = 0;
        g_isBanningReason[id][0] = 0;
    }

    return PLUGIN_HANDLED;
}

@ClCmd_BanLength(id) {
    if(!g_IsBanning[id])
        return PLUGIN_HANDLED;
    
    new time[12];
    read_args(time, charsmax(time));
    remove_quotes(time);
    trim(time);

    set_bit(bIsUsingCustomTime, id);
    g_isBanningTime[id] = str_to_num(time);
    ConfirmMenu(id);
    return PLUGIN_HANDLED;
}

stock bool:func_IsSteamIdValid(const szSteamID[]) {
    if(strlen(szSteamID) < 11)
        return false;

    if(!(equal(szSteamID, "STEAM_", 6) || equal(szSteamID, "VALVE_", 6)))
        return false;

    if(!isdigit(szSteamID[6]) || szSteamID[7] != ':' || !isdigit(szSteamID[8]) || szSteamID[9] != ':')
        return false;

    for(new i = 10; szSteamID[i] != EOS; i++) {
        if(!isdigit(szSteamID[i]))
            return false;
    }

    return true;
}

SQLCheckError(errNum, error[]) {
    if(errNum)
        log_amx(error);
}

stock Send_Cmd(id, szText[]) {
	message_begin(MSG_ONE, SVC_STUFFTEXT, {0, 0, 0}, id)
	write_byte(strlen(szText) + 2)
	write_byte(10)
	write_string(szText)
	message_end()
}

// admin, player, ban_length, ban reason 
public _CBan_BanPlayer(plugin, argc) {
    if(argc <= 4) {
        log_error(1, "CBan_BanPlayer needs at least 4 parameters (%d).", argc);
        return;   
    }
    new pid = get_param(2);
    if(!is_user_connected(pid)) {
        log_error(1, "CBan_BanPlayer: Player not connected (%d).", pid);
        return;
    }
    new ban_length = abs(get_param(3));
    new ban_reason[MAX_REASON_LENGTH];
    get_string(4, ban_reason, charsmax(ban_reason));

    BanPlayer(get_param(1), pid, ban_length, ban_reason);
}
// admin, target[], targetType 
public _CBan_UnbanPlayer(plugin, argc) {
    if(argc <= 3) {
        log_error(1, "CBan_BanPlayer needs 3 parameters (%d).", argc);
        return;  
    }

    new target[MAX_NAME_LENGTH];
    get_string(2, target, charsmax(target));

    UnbanPlayer(get_param(1), target, get_param(3));
}

// admin, target[], ban_length, ban_reason[]
public _CBan_OffBanPlayer(plugin, argc) {
    if(argc <= 4) {
        log_error(1, "CBan_BanPlayer needs at least 4 parameters (%d).", argc);
        return 0;
    }
    new target[MAX_NAME_LENGTH];
    get_string(2, target, charsmax(target));

    new pid = find_player("bl", target);
    if(pid && (get_user_flags(pid) & ADMIN_FLAG_IMMUNITY))
        return 0;
    new bool:isInGame = true;
    if(!pid) {
        isInGame = false;
        pid = ArrayFindStringWithType(hOffBanName, target, eComparisonType:CONTAINI);
        if(pid == -1)
            return 0;
    }

    new ban_reason[MAX_REASON_LENGTH];
    get_string(4, ban_reason, charsmax(ban_reason));
    
    BanPlayer(get_param(1), isInGame? pid:-pid, abs(get_param(3)), ban_reason);
    return 1;
}

// admin, target[], ban_length, ban_reason
public _CBan_AddBanPlayer(plugin, argc) {
    if(argc <= 4) {
        log_error(1, "CBan_BanPlayer needs at least 4 parameters (%d).", argc);
        return 0;
    }
    
    new target[MAX_NAME_LENGTH];
    get_string(2, target, charsmax(target));
    
    new ban_reason[MAX_REASON_LENGTH];
    get_string(4, ban_reason, charsmax(ban_reason));

    new pid = find_player("cl", target);

    if(!pid)
        pid = find_player("d", target);

    if(pid) {
        if(get_user_flags(pid) & ADMIN_FLAG_IMMUNITY)
            return 0;
        else
            BanPlayer(get_param(1), pid, abs(get_param(3)), ban_reason);
    }
    else
        AddBanPlayer(get_param(1), target, abs(get_param(3)), ban_reason);
    
    return 1;
}

func_RegCvars() {
    bind_cvar_string("cortex_bans_sql_host", "127.0.0.1",
        .flags = FCVAR_PROTECTED,
        .desc = "IP/Host from Database.",
        .bind = g_eCvar[g_iSqlHost],
        .maxlen = charsmax(g_eCvar[g_iSqlHost])
    );

    bind_cvar_string("cortex_bans_sql_user", "root",
        .flags = FCVAR_PROTECTED,
        .desc = "Login (Username) from the Database.",
        .bind = g_eCvar[g_iSqlUser],
        .maxlen = charsmax(g_eCvar[g_iSqlUser])
    );

    bind_cvar_string("cortex_bans_sql_password", "",
        .flags =FCVAR_PROTECTED,
        .desc = "Login (password) Database password.",
        .bind = g_eCvar[g_iSqlPass],
        .maxlen = charsmax(g_eCvar[g_iSqlPass])
    );

    bind_cvar_string("cortex_bans_sql_dbname", "CortexBans",
        .flags = FCVAR_PROTECTED,
        .desc = "Database name.",
        .bind = g_eCvar[g_iSqlNameDb],
        .maxlen = charsmax(g_eCvar[g_iSqlNameDb])
    );

    bind_cvar_string("cortex_bans_sql_bantable", "cortex_bans",
        .flags = FCVAR_PROTECTED,
        .desc = "Database table name.",
        .bind = g_eCvar[g_iSqlBanTable],
        .maxlen = charsmax(g_eCvar[g_iSqlBanTable])
    );

    bind_cvar_string("cortex_bans_sql_checktable", "db_ccheck",
        .flags = FCVAR_PROTECTED,
        .desc = "Database check table name.",
        .bind = g_eCvar[g_iSqlCheckTable],
        .maxlen = charsmax(g_eCvar[g_iSqlCheckTable])
    );

    bind_cvar_string("cortex_bans_motd_link", "http://test.com/bans/CookieCheck/",
        .flags = FCVAR_PROTECTED,
        .desc = "MOTD link. Must be a http link.",
        .bind = g_eCvar[g_iMotdCheck],
        .maxlen = charsmax(g_eCvar[g_iMotdCheck])
    );

    bind_cvar_string("cortex_bans_complain_url", "https://test.com/",
        .flags = FCVAR_PROTECTED,
        .desc = "Complain URL. Leave empty if you don't want it.",
        .bind = g_eCvar[g_iComplainUrl],
        .maxlen = charsmax(g_eCvar[g_iComplainUrl])
    );

    bind_cvar_string("cortex_bans_server_ip", "0.0.0.0:27015",
        .flags = FCVAR_PROTECTED,
        .desc = "Server IP thats server is running on.",
        .bind = g_eCvar[g_iServerIP],
        .maxlen = charsmax(g_eCvar[g_iServerIP])
    );

    bind_cvar_num("cortex_bans_delete_expired", "1",
        .has_min = true, .min_val = 0.0,
        .has_max = true, .max_val = 1.0,
        .desc = "Delete expired bans. 0 = Disabled, 1 = Enabled.",
        .bind = g_eCvar[g_iExpired]
    );

    bind_cvar_num("cortex_bans_update_code", "1",
        .has_min = true, .min_val = 0.0,
        .has_max = true, .max_val = 1.0,
        .desc = "The 'ccode' is what makes this plugin effective more than others. 0 = Disabled, 1 = Enabled.",
        .bind = g_eCvar[g_iUpdateCode]
    );

    bind_cvar_num("cortex_bans_anti_vpn", "1",
        .has_min = true, .min_val = 0.0,
        .has_max = true, .max_val = 1.0,
        .desc = "Checks player's IP for VPN-Proxy. 0 = Disabled, 1 = Enabled.",
        .bind = g_eCvar[g_iCheckVPN]
    ); 

    bind_cvar_num("cortex_bans_update_ip", "1",
        .has_min = true, .min_val = 0.0,
        .has_max = true, .max_val = 1.0,
        .desc = "Update IP setting. 0 = Disabled, 1 = Enabled.",
        .bind = g_eCvar[g_iUpdateIP]
    ); 

    bind_cvar_num("cortex_bans_update_steamid", "2",
        .has_min = true, .min_val = 0.0,
        .has_max = true, .max_val = 2.0,
        .desc = "Update steam ID setting. 0 = Disabled, 1 = Only non-steamers, 2 = Enabled for all.",
        .bind = g_eCvar[g_iUpdateSteamID]
    );

    bind_cvar_num("cortex_bans_update_nick", "0",
        .has_min = true, .min_val = 0.0,
        .has_max = true, .max_val = 1.0,
        .desc = "Update nick setting. 0 = Disabled, 1 = Enabled.",
        .bind = g_eCvar[g_iUpdateNick]
    );

    bind_cvar_num("cortex_bans_ban_type", "2",
        .has_min = true, .min_val = 0.0,
        .has_max = true, .max_val = 3.0,
        .desc = "Ban type. 0 = Steam ID, 1 = IP, 2 = Both, 3 = IP for non-steam and Steam ID for steamers.",
        .bind = g_eCvar[g_iBanType]
    );

    bind_cvar_num("cortex_bans_addban_type", "1",
        .has_min = true, .min_val = 0.0,
        .has_max = true, .max_val = 1.0,
        .desc = "Add ban type. 0 = Consider from when ban is received, 1 = Consider from when player joins the first time after the ban.",
        .bind = g_eCvar[g_iAddBanType]
    );

    bind_cvar_num("cortex_bans_offban_type", "1",
        .has_min = true, .min_val = 0.0,
        .has_max = true, .max_val = 1.0,
        .desc = "Offline ban type. 0 = Consider from when ban is received, 1 = Consider from when player joins the first time after the ban.",
        .bind = g_eCvar[g_iOffBanType]
    );

    bind_cvar_num("cortex_bans_max_offban_save", "30",
        .has_min = true, .min_val = 0.0,
        .has_max = true, .max_val = 30.0,
        .desc = "Max records that can be saved for the offban (after reaching thas limit, the first player to be saved will be removed).",
        .bind = g_eCvar[g_iMaxOffBan]
    );

#if defined AUTO_CFG
    AutoExecConfig();
#endif
}

ArrayFindStringWithType(Array:which, const item[], eComparisonType:type) {
    new max_size = ArraySize(which);
    for (new i, val[MAX_NAME_LENGTH]; i < max_size; i++) {
        ArrayGetString(which, i, val, charsmax(val));
        
        switch (type) {
            case CONTAINI: {
                if (containi(val, item) != -1) {
                    return i;
                }
            }
            case EQUALI: {
                if (equali(val, item)) {
                    return i;
                }
            }
        }
    }
    return -1;
}
