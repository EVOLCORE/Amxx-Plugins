#pragma semicolon 1

#include <amxmodx>
#include <reapi>

#define MAX_MODELS_LENGTH 128

enum _:ArrayData
{
    SaveType: iWmType,
    WeaponIdType: iWmWeapon,
    iWmModelW,
    szWmParam[64],
    szWmModelP[MAX_MODELS_LENGTH],
    szWmModelV[MAX_MODELS_LENGTH],
    szWmModelW[MAX_MODELS_LENGTH]
}

enum _:PlayerModels
{
    SaveType: iPriority,
    iModelW,
    szModelP[MAX_MODELS_LENGTH],
    szModelV[MAX_MODELS_LENGTH],
    szModelW[MAX_MODELS_LENGTH]
}

enum SaveType
{
    WM_NONE,
    WM_ALL,
    WM_ONLY_STEAM,
    WM_FLAGS,
    WM_STEAM,
    WM_NICK
}

new Array: g_aWeapons, SaveType: g_iType;
new g_aPlayerWeapon[MAX_PLAYERS + 1][WeaponIdType][PlayerModels];
new bool: is_replace_guns[MAX_PLAYERS + 1];

public plugin_init() {
    register_plugin("[ReAPI] Weapon Models", "0.0.1", "mIDnight");

    register_clcmd("say /skins", "@Skins");
    register_clcmd("say_team /skins", "@Skins");

    RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, "@CBasePlayerWeapon_DefaultDeploy_Pre");
    RegisterHookChain(RG_CWeaponBox_SetModel, "@CWeaponBox_SetModel_Pre");
    RegisterHookChain(RG_CBasePlayer_ThrowGrenade, "@CBasePlayer_ThrowGrenade_Post", true);
    RegisterHookChain(RG_PlantBomb, "@PlantBomb_Post", true);

    register_dictionary("re_weapon_models.txt");
}

public plugin_precache() {
    new szDir[128];
    get_localinfo("amxx_configsdir", szDir, charsmax(szDir));
    add(szDir, charsmax(szDir), "/plugins/weapon_models.ini");

    g_aWeapons = ArrayCreate(ArrayData);

    new INIParser: hParser = INI_CreateParser();
    INI_SetReaders(hParser, "parse_key_value", "parse_new_section");

    if (!INI_ParseFile(hParser, szDir))
    {
        INI_DestroyParser(hParser);
        set_fail_state("%l %l", "WM_FILE_CANT", file_exists(szDir) ? "WM_READ" : "WM_FIND", szDir);
    }

    INI_DestroyParser(hParser);
}

@Skins(const iPlayer) {
    if (is_replace_guns[iPlayer]) {  
        is_replace_guns[iPlayer] = true;
        client_print_color(iPlayer, print_team_blue, "%l", "WM_REPLACE_ON");
    }
    else 
    {
        is_replace_guns[iPlayer] = false;
        client_print_color(iPlayer, print_team_red, "%l", "WM_REPLACE_OFF");
    }
}

@CBasePlayerWeapon_DefaultDeploy_Pre(const iEnt) {
    if (is_nullent(iEnt)) return HC_CONTINUE;

    new iPlayer = get_member(iEnt, m_pPlayer);
    if (!is_replace_guns[iPlayer]) return HC_CONTINUE;

    new WeaponIdType: iWeapon = WeaponIdType: get_member(iEnt, m_iId);

    if (g_aPlayerWeapon[iPlayer][iWeapon][szModelV]) SetHookChainArg(2, ATYPE_STRING, g_aPlayerWeapon[iPlayer][iWeapon][szModelV]);
    if (g_aPlayerWeapon[iPlayer][iWeapon][szModelP]) SetHookChainArg(3, ATYPE_STRING, g_aPlayerWeapon[iPlayer][iWeapon][szModelP]);

    return HC_CONTINUE;
}

@CWeaponBox_SetModel_Pre(const iWeaponBox) {
    new iEnt = func_GetWeaponBoxWeapon(iWeaponBox);
    if (iEnt == NULLENT) return HC_CONTINUE;

    new WeaponIdType: iWeapon = WeaponIdType: get_member(iEnt, m_iId);
    new iPlayer = get_entvar(iWeaponBox, var_owner);
    if (!is_replace_guns[iPlayer]) return HC_CONTINUE;

    if (g_aPlayerWeapon[iPlayer][iWeapon][szModelW]) SetHookChainArg(2, ATYPE_STRING, g_aPlayerWeapon[iPlayer][iWeapon][szModelW]);

    return HC_CONTINUE;
}

@CBasePlayer_ThrowGrenade_Post(const iPlayer, const iGrenade) {
    if (!is_replace_guns[iPlayer]) return HC_CONTINUE;
    new iEnt = GetHookChainReturn(ATYPE_INTEGER);
    if (is_nullent(iEnt)) return HC_CONTINUE;

    new WeaponIdType: iWeapon = WeaponIdType: get_member(iGrenade, m_iId);

    if (g_aPlayerWeapon[iPlayer][iWeapon][szModelW]) {
        set_entvar(iEnt, var_modelindex, g_aPlayerWeapon[iPlayer][iWeapon][iModelW]);
        set_entvar(iEnt, var_model, g_aPlayerWeapon[iPlayer][iWeapon][szModelW]);
    }

    return HC_CONTINUE;
}

@PlantBomb_Post(const iPlayer) {
    if (!is_replace_guns[iPlayer]) return HC_CONTINUE;
    new iEnt = GetHookChainReturn(ATYPE_INTEGER);

    if (g_aPlayerWeapon[iPlayer][WEAPON_C4][szModelW]) {
        set_entvar(iEnt, var_modelindex, g_aPlayerWeapon[iPlayer][WEAPON_C4][iModelW]);
        set_entvar(iEnt, var_model, g_aPlayerWeapon[iPlayer][WEAPON_C4][szModelW]);
    }

    return HC_CONTINUE;
}

public client_putinserver(iPlayer) {
    is_replace_guns[iPlayer] = true;
    
    for (new WeaponIdType: i = WEAPON_P228; i <= WEAPON_P90; i++) {
        g_aPlayerWeapon[iPlayer][i][iPriority] = WM_NONE;
        g_aPlayerWeapon[iPlayer][i][szModelP][0] = EOS;
        g_aPlayerWeapon[iPlayer][i][szModelV][0] = EOS;
        g_aPlayerWeapon[iPlayer][i][szModelW][0] = EOS;
    }

    new iSize = ArraySize(g_aWeapons);
    new aData[ArrayData], WeaponIdType: iWeapon;

    for (new i; i < iSize; i++) {
        ArrayGetArray(g_aWeapons, i, aData);
        iWeapon = aData[iWmWeapon];

        if (g_aPlayerWeapon[iPlayer][iWeapon][iPriority] < aData[iWmType]) {
            if (is_replace(iPlayer, aData[iWmType], aData[szWmParam])) {
                g_aPlayerWeapon[iPlayer][iWeapon][iPriority] = aData[iWmType];
                if (aData[szWmModelP]) copy(g_aPlayerWeapon[iPlayer][iWeapon][szModelP], MAX_MODELS_LENGTH - 1, aData[szWmModelP]);
                if (aData[szWmModelV]) copy(g_aPlayerWeapon[iPlayer][iWeapon][szModelV], MAX_MODELS_LENGTH - 1,  aData[szWmModelV]);
                if (aData[szWmModelW]) copy(g_aPlayerWeapon[iPlayer][iWeapon][szModelW], MAX_MODELS_LENGTH - 1, aData[szWmModelW]);
                if (aData[iWmModelW]) g_aPlayerWeapon[iPlayer][iWeapon][iModelW] = aData[iWmModelW];
            }
        }
        else
        if (aData[iWmType] == WM_ONLY_STEAM && is_user_steam(iPlayer)) {
            if (!g_aPlayerWeapon[iPlayer][iWeapon][szModelP] && aData[szWmModelP]) copy(g_aPlayerWeapon[iPlayer][iWeapon][szModelP], MAX_MODELS_LENGTH - 1, aData[szWmModelP]);
            if (!g_aPlayerWeapon[iPlayer][iWeapon][szModelV] && aData[szWmModelV]) copy(g_aPlayerWeapon[iPlayer][iWeapon][szModelV], MAX_MODELS_LENGTH - 1, aData[szWmModelV]);
            if (!g_aPlayerWeapon[iPlayer][iWeapon][szModelW] && aData[szWmModelW]) copy(g_aPlayerWeapon[iPlayer][iWeapon][szModelW], MAX_MODELS_LENGTH - 1, aData[szWmModelW]);
            if (aData[iWmModelW]) g_aPlayerWeapon[iPlayer][iWeapon][iModelW] = aData[iWmModelW];
        }
        else
        if (aData[iWmType] == WM_ALL) {
            if (!g_aPlayerWeapon[iPlayer][iWeapon][szModelP] && aData[szWmModelP]) copy(g_aPlayerWeapon[iPlayer][iWeapon][szModelP], MAX_MODELS_LENGTH - 1, aData[szWmModelP]);
            if (!g_aPlayerWeapon[iPlayer][iWeapon][szModelV] && aData[szWmModelV]) copy(g_aPlayerWeapon[iPlayer][iWeapon][szModelV], MAX_MODELS_LENGTH - 1, aData[szWmModelV]);
            if (!g_aPlayerWeapon[iPlayer][iWeapon][szModelW] && aData[szWmModelW]) copy(g_aPlayerWeapon[iPlayer][iWeapon][szModelW], MAX_MODELS_LENGTH - 1, aData[szWmModelW]);
            if (aData[iWmModelW]) g_aPlayerWeapon[iPlayer][iWeapon][iModelW] = aData[iWmModelW];
        }
    }
}

stock func_GetWeaponBoxWeapon(const iWeaponBox) {
    for (new i, iWeapon; i < MAX_ITEM_TYPES; i++) {
        iWeapon = get_member(iWeaponBox, m_WeaponBox_rgpPlayerItems, i);
        if (!is_nullent(iWeapon)) return iWeapon;
    }

    return NULLENT;
}

stock bool: is_replace(const iPlayer, const SaveType: szType, const szParam[]) {
    if (szType == WM_ALL) return true;
    if (szType == WM_ONLY_STEAM && is_user_steam(iPlayer)) return true;
    
    new szCopy[MAX_AUTHID_LENGTH];
    if (szType == WM_NICK) get_user_name(iPlayer, szCopy, charsmax(szCopy));
    else if (szType == WM_STEAM) get_user_authid(iPlayer, szCopy, charsmax(szCopy));
    if (equal(szParam, szCopy)) return true;

    if (szType == WM_FLAGS && get_user_flags(iPlayer) & read_flags(szParam)) return true;

    return false;
}

public bool: parse_key_value(INIParser: hParser, const szBuffer[]) {
    if (g_iType == WM_NONE) return true;

    new aData[ArrayData], szWeapon[16];
    aData[iWmType] = g_iType;

    if (g_iType < WM_FLAGS) {
        parse(szBuffer, szWeapon, charsmax(szWeapon),
        aData[szWmModelP], MAX_MODELS_LENGTH - 1,
        aData[szWmModelV], MAX_MODELS_LENGTH - 1,
        aData[szWmModelW], MAX_MODELS_LENGTH - 1);
    }
    else 
    {
        parse(szBuffer, aData[szWmParam], charsmax(aData[szWmParam]),
        szWeapon, charsmax(szWeapon),
        aData[szWmModelP], MAX_MODELS_LENGTH - 1,
        aData[szWmModelV], MAX_MODELS_LENGTH - 1,
        aData[szWmModelW], MAX_MODELS_LENGTH - 1);
    }

    if (!aData[szWmModelP] && !aData[szWmModelV] && !aData[szWmModelW]) return true;

    if ((aData[iWmWeapon] = rg_get_weapon_info(fmt("weapon_%s", szWeapon), WI_ID)) == WEAPON_NONE) {
        log_amx("%l", "WM_BAD_WEAPON", szWeapon);
        return true;
    }
    
    if (g_iType >= WM_FLAGS && !aData[szWmParam]) {
        log_amx("%l", "WM_NONE_PARAM_FOR_TYPE", g_iType, szBuffer);
        return true;
    }

    if (aData[szWmModelP]) precache_model(aData[szWmModelP]);
    if (aData[szWmModelV]) precache_model(aData[szWmModelV]);
    if (aData[szWmModelW]) {
        switch (aData[iWmWeapon]) {
            case WEAPON_FLASHBANG, WEAPON_HEGRENADE, WEAPON_SMOKEGRENADE, WEAPON_C4: {aData[iWmModelW] = precache_model(aData[szWmModelW]);}
            default : {precache_model(aData[szWmModelW]);}
        }   
        
    }

    ArrayPushArray(g_aWeapons, aData);
    return true;
}

public bool: parse_new_section(INIParser: hParser, const szSection[]) {
    if (equal(szSection, "ALL STEAMS")) g_iType = WM_ONLY_STEAM;
    else
    {
        switch (szSection[0]) {
            case 'A': {g_iType = WM_ALL;}
            case 'F': {g_iType = WM_FLAGS;}
            case 'S': {g_iType = WM_STEAM;}
            case 'N': {g_iType = WM_NICK;}
            default: {g_iType = WM_NONE; log_amx("%l", "WM_BAD_TYPE", szSection);}
        }
    }

    return true;
}
