//#define FFA_MODE    // Remove  // in front to enable FFA Mode support

#include <amxmodx>
#include <fakemeta>
#include <reapi>

#pragma compress 1

new PLUGIN_VERSION[] = "1.0.3"

#define IsPlayer(%1)                     (1 <= %1 <= MaxClients)
#define TASK_KILLS                       12023
#define TASK_CHAT                        13923

new const FILE_SETTINGS[][] = {
    "HUD_HS_POSITION",
    "HUD_HS_COLOR",
    "HUD_KILLS_POSITION",
    "HUD_KILLS_COLOR",
    "FADE_COLOR",
    "MENU_COMMANDS",
    "BONUS_MAX_HP",
    "BONUS_HP_NORMAL",
    "BONUS_HP_HS"
}

new const g_iMenuSettings[][] = {
    "CSDM_ONLY_HS",
    "CSDM_KILLFEED",
    "CSDM_FADE_SCREEN",
    "CSDM_BULLET_DAMAGE",
    "CSDM_HEADSHOT_MSG",
    "CSDM_ALL_KILLS",
    "CSDM_BONUS_HP"
}

enum _:Settings {
    Float:HudHSPosX,
    Float:HudHSPosY,
    HudHSColor,
    Float:HudKillPosX,
    Float:HudKillPosY,
    HudKillColor,
    FadeColor,
    Float:g_iBonusHP,
    Float:g_iBonusNormal,
    Float:g_iBonusHS
}

enum _:RGB { R, G, B }

enum _:CsdmSettings {
    bool:bHeadshotMode,
    bool:bKillFeed,
    bool:bScreenFade,
    bool:bBulletDamage,
    bool:bHeadshotMsg,
    bool:bKillsCounter,
    bool:bHealing
}

enum _:KillType {
    Normal = 0,
    Headshot = 1
}

new g_eFileSettings[Settings], g_iHudSyncObj,
    g_ePlayerSettings[MAX_PLAYERS + 1][CsdmSettings],
    g_iKillsCounter[MAX_PLAYERS + 1][KillType],
    g_iSettingColorRender[Settings][RGB]
new bool:g_bIsUserDead[MAX_PLAYERS + 1],
    bool:g_bIsHeadshot[MAX_PLAYERS + 1][MAX_PLAYERS + 1],
    bool:PlayerSettings[CsdmSettings] = {false, false, true, true, true, true, true}

public plugin_init() {
    register_plugin("[ReAPI] CSDM Menu", PLUGIN_VERSION, "mIDnight")
    create_cvar("csdm_menu_ver", PLUGIN_VERSION, FCVAR_SERVER | FCVAR_SPONLY)
 
    register_dictionary("csdm_menu.txt")

    register_message(get_user_msgid("DeathMsg"), "event_MessageDeathMsg")
    RegisterHookChain(RG_CBasePlayer_TakeDamage, "RG_Player_Damage_Post", .post = true)
    RegisterHookChain(RG_CBasePlayer_TraceAttack, "RG_Player_TraceAttack_Pre", .post = false)
    RegisterHookChain(RG_CBasePlayer_Killed, "RG_Player_Killed_Post", .post = true)
    RegisterHookChain(RG_CBasePlayer_Spawn, "RG_Player_Spawn_Post", .post = true)

    g_iHudSyncObj = CreateHudSyncObj()
}

public plugin_precache() {
    new Path[MAX_RESOURCE_PATH_LENGTH]
    get_localinfo("amxx_configsdir", Path, charsmax(Path))
    formatex(Path, charsmax(Path), "%s/CSDMMenu.ini", Path)

    if(!file_exists(Path)) {
        set_fail_state("Missing configuration file: `%s`", Path)
    }
 
    new INIParser: iIniParserHandle = INI_CreateParser()
    
    INI_SetReaders(iIniParserHandle, "@INI_ParseValueHandler")
    INI_ParseFile(iIniParserHandle, Path)
    INI_DestroyParser(iIniParserHandle)
}

bool:@INI_ParseValueHandler(INIParser: handle, const szKey[], const szValue[], bool: invalid_tokens, bool: equal_token, bool: quotes, curtok, any: data) {
    if (szKey[0] == EOS || szKey[0] == '/') {
        return true
    }

    new szBuffer[256], szCmd[64], szParams[4][5]

    for (new i = 0; i < sizeof(FILE_SETTINGS); i++) {
        if (!equal(szKey, FILE_SETTINGS[i])) {
            continue
        }

        switch (i) {
            case 0, 2: {
                parse(szValue, szParams[0], charsmax(szParams[]), szParams[1], charsmax(szParams[]))
                g_eFileSettings[i == 0 ? HudHSPosX : HudKillPosX] = float:str_to_float(szParams[0])
                g_eFileSettings[i == 0 ? HudHSPosY : HudKillPosY] = float:str_to_float(szParams[1])
            }
            case 1, 3, 4: {
                parse(szValue, szParams[R], charsmax(szParams[]), szParams[G], charsmax(szParams[]), szParams[B], charsmax(szParams[]))
                new idx = (i == 1) ? HudHSColor : ((i == 3) ? HudKillColor : FadeColor)
                g_iSettingColorRender[idx][R] = str_to_num(szParams[R])
                g_iSettingColorRender[idx][G] = str_to_num(szParams[G])
                g_iSettingColorRender[idx][B] = str_to_num(szParams[B])
            }
            case 5: {
                copy(szBuffer, charsmax(szBuffer), szValue)
                while (szBuffer[0] != EOS && strtok2(szBuffer, szCmd, charsmax(szCmd), szBuffer, charsmax(szBuffer), ',', TRIM_INNER) != -1) {
                    register_clcmd(szCmd, "Clcmd_CSDM_Menu")
                }
            }
            case 6, 7, 8: {
                g_eFileSettings[i == 6 ? g_iBonusHP : i == 7 ? g_iBonusNormal : g_iBonusHS] = float:str_to_float(szValue)
            }
        }
    }
    return true
}

public client_putinserver(id) {
    if(task_exists(id + TASK_KILLS)) {
        remove_task(id + TASK_KILLS)
    }
    if(task_exists(id + TASK_CHAT)) {
        remove_task(id + TASK_CHAT)
    }
    for (new i = 0; i < CsdmSettings; i++) {
        g_ePlayerSettings[id][i] = PlayerSettings[i];
    }
    g_iKillsCounter[id][Normal] = 0
    g_iKillsCounter[id][Headshot] = 0
    g_bIsUserDead[id] = true

    set_task(180.0, "task_show_chat_ad", id + TASK_CHAT, .flags = "b")
}

public event_MessageDeathMsg(msgid, dest, receiver) {
    enum { arg_killer = 1, arg_victim, arg_headshot, arg_weapon_name }

    new killer = get_msg_arg_int(arg_killer)
    new victim = get_msg_arg_int(arg_victim)
    new headshot = get_msg_arg_int(arg_headshot)
    new killerWeaponName[64]
    get_msg_arg_string(arg_weapon_name, killerWeaponName, charsmax(killerWeaponName))

    if (g_ePlayerSettings[killer][bKillFeed]) {
        UTIL_DeathMsg(msgid, MSG_ONE, killer, killer, victim, headshot, killerWeaponName)
    }
    if (g_ePlayerSettings[victim][bKillFeed]) {
        UTIL_DeathMsg(msgid, MSG_ONE, victim, killer, victim, headshot, killerWeaponName)
    }

    for (new p = 1; p <= MaxClients; p++) {
        if (is_user_connected(p) && !is_user_hltv(p) && !is_user_bot(p) && !g_ePlayerSettings[p][bKillFeed]) {
            UTIL_DeathMsg(msgid, MSG_ONE, p, killer, victim, headshot, killerWeaponName)
        }
    }

    return PLUGIN_HANDLED
}

public RG_Player_Damage_Post(iVictim, iInflictor, iAttacker, Float:fDamage, bitsDamageType) {
#if defined FFA_MODE
    if(!IsPlayer(iVictim) || !IsPlayer(iAttacker) || iVictim == iAttacker)
#else
    if(!IsPlayer(iVictim) || !IsPlayer(iAttacker) || iVictim == iAttacker || get_user_team(iVictim) == get_user_team(iAttacker))
#endif
        return HC_CONTINUE

    static const Float: iDamageCoords[][] = { {0.50, 0.40}, {0.56, 0.44}, {0.60, 0.50}, {0.56, 0.56}, {0.50, 0.60}, {0.44, 0.56}, {0.40, 0.50}, {0.44, 0.44} }
    static iDamageCoordPos[MAX_CLIENTS + 1]

    if(g_ePlayerSettings[iAttacker][bBulletDamage] && !(g_ePlayerSettings[iAttacker][bHeadshotMode] && get_member(iAttacker , m_LastHitGroup) == HIT_HEAD)) {
        set_hudmessage(random_num(0, 255), random_num(0, 255), random_num(0, 255), iDamageCoords[iDamageCoordPos[iAttacker]][0], iDamageCoords[iDamageCoordPos[iAttacker]][1], _, _, 1.0)
        ShowSyncHudMsg(iAttacker, g_iHudSyncObj, "%.0f", fDamage)

        iDamageCoordPos[iAttacker] = (iDamageCoordPos[iAttacker] + 1) % sizeof(iDamageCoords)
    }
    
    return HC_CONTINUE
}

public RG_Player_TraceAttack_Pre(iVictim, iAttacker, Float:fDamage, Float:fDirection[3], trhandle) {
#if defined FFA_MODE
    if(!IsPlayer(iVictim) || !IsPlayer(iAttacker) || iVictim == iAttacker)
#else
    if(!IsPlayer(iVictim) || !IsPlayer(iAttacker) || iVictim == iAttacker || get_user_team(iVictim) == get_user_team(iAttacker))
#endif
        return HC_CONTINUE

    if(g_ePlayerSettings[iAttacker][bHeadshotMode] && get_tr2(trhandle, TR_iHitgroup) != HIT_HEAD && get_user_weapon(iAttacker) != CSW_KNIFE) {
        return HC_SUPERCEDE
    }

    g_bIsHeadshot[iAttacker][iVictim] = get_tr2(trhandle, TR_iHitgroup) == HIT_HEAD ? true : false

    return HC_CONTINUE
}

public RG_Player_Killed_Post(const iVictim, iAttacker, iGibs) {
    g_bIsUserDead[iVictim] = true

    if(!is_user_connected(iAttacker) || iVictim == iAttacker) {
        return HC_CONTINUE
    }

    if(g_ePlayerSettings[iAttacker][bScreenFade]) {
        FadeScreen(iAttacker)
    }

    if(g_ePlayerSettings[iAttacker][bHeadshotMsg] && get_member(iVictim, m_bHeadshotKilled)) {
        set_dhudmessage(g_iSettingColorRender[HudHSColor][R], g_iSettingColorRender[HudHSColor][G], g_iSettingColorRender[HudHSColor][B], g_eFileSettings[HudHSPosX], g_eFileSettings[HudHSPosY], 0, 0.1, 0.5, 0.02, 0.02)
        show_dhudmessage(iAttacker, "HEAD SHOT")
    }

    if (g_ePlayerSettings[iAttacker][bKillsCounter]) {
        g_iKillsCounter[iAttacker][Normal]++
        g_iKillsCounter[iAttacker][Headshot] += get_member(iVictim, m_bHeadshotKilled)

        if (g_iKillsCounter[iAttacker][Normal] | g_iKillsCounter[iAttacker][Headshot]) {
            remove_task(iAttacker + TASK_KILLS)
            set_task(0.1, "task_show_hudkills", iAttacker + TASK_KILLS)
        }
    }

    if (g_ePlayerSettings[iAttacker][bHealing]) {
        set_entvar(iAttacker, var_health, floatmin(Float:get_entvar(iAttacker, var_health) + (get_member(iVictim, m_bHeadshotKilled) ? g_eFileSettings[g_iBonusHS] : g_eFileSettings[g_iBonusNormal]), g_eFileSettings[g_iBonusHP]))
    }

    return HC_CONTINUE
}

public RG_Player_Spawn_Post(iEntity) {
    if (IsPlayer(iEntity) && g_bIsUserDead[iEntity]) {
        g_iKillsCounter[iEntity][Normal] = 0
        g_iKillsCounter[iEntity][Headshot] = 0
        g_bIsUserDead[iEntity] = false
    }
}

public Clcmd_CSDM_Menu(id) {
    new szBuffer[128]
    formatex(szBuffer, charsmax(szBuffer), "\w%L", LANG_PLAYER, "CSDM_SETTINGS_TITLE")
    new menu = menu_create(szBuffer, "settings_menu_handler")

    for (new setting = 0; setting < sizeof(g_iMenuSettings); setting++) {
        formatex(szBuffer, charsmax(szBuffer), "\w%L %s", LANG_PLAYER, g_iMenuSettings[setting],
            g_ePlayerSettings[id][setting] ? "\w[\yON\w]" : "\w[\rOFF\w]")
        menu_additem(menu, szBuffer)
    }

    menu_display(id, menu)

    return PLUGIN_HANDLED
}

public settings_menu_handler(id, menu, item) {
    if (item == MENU_EXIT || !is_user_connected(id)) {
        return MenuExit(menu)
    }

    if (item >= 0 && item < CsdmSettings) {
        g_ePlayerSettings[id][item] = !g_ePlayerSettings[id][item]
        Clcmd_CSDM_Menu(id)
    }

    return MenuExit(menu)
}

public task_show_chat_ad(id) {
    id -= TASK_CHAT
    if(is_user_connected(id)) {
        client_print_color(id, print_chat, "%L", LANG_PLAYER, "CSDM_CHAT_AD")
    }
}

public task_show_hudkills(id) {
    id -= TASK_KILLS
    if(g_ePlayerSettings[id][bKillsCounter]) {
        set_dhudmessage(g_iSettingColorRender[HudKillColor][R], g_iSettingColorRender[HudKillColor][G], g_iSettingColorRender[HudKillColor][B], g_eFileSettings[HudKillPosX], g_eFileSettings[HudKillPosY], 0, 0.1, 1.5, 0.02, 0.02)
        show_dhudmessage(id, "%i (%i)", g_iKillsCounter[id][Normal], g_iKillsCounter[id][Headshot])

        if(g_iKillsCounter[id][Normal] > 0 || g_iKillsCounter[id][Headshot] > 0) {
            remove_task(id + TASK_KILLS)
            set_task(1.0, "task_show_hudkills", id + TASK_KILLS)
        }
    }
    else {
        remove_task(id + TASK_KILLS)
    }

    if(g_bIsUserDead[id]) {
        g_iKillsCounter[id][Normal] = 0
        g_iKillsCounter[id][Headshot] = 0
    }

    return PLUGIN_HANDLED
}

stock MenuExit(menu) {
    menu_destroy(menu)
    return PLUGIN_HANDLED
}

stock UTIL_DeathMsg(const msgid, dest, const receiver, const killer, const victim, const headshot, const weaponName[]) {
    message_begin(dest, msgid, _, receiver)
    write_byte(killer)
    write_byte(victim)
    write_byte(headshot)
    write_string(weaponName)
    message_end()
}

stock FadeScreen(id) {
    message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), {0,0,0}, id)
    write_short(1<<10)
    write_short(1<<9)
    write_short(0x0000)
    write_byte(52)
    write_byte(g_iSettingColorRender[FadeColor][R])
    write_byte(g_iSettingColorRender[FadeColor][G])
    write_byte(g_iSettingColorRender[FadeColor][B])
    message_end()
}
