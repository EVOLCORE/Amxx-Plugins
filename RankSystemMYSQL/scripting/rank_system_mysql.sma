#include <amxmodx>
#include <amxmisc>
#include <sqlx>
#include <curl>
#include <geoip>
#include <reapi>
#include <ranksmysql_const>

#define DIRECTORY_NAME	    "rank_system_mysql.txt"

new g_eTeamWin[eWinData - 2][TeamWinData] = {
	{ TABLE_TWIN_ID,	"RSM_TERR_WIN" 		},
	{ TABLE_CTWIN_ID,	"RSM_CT_WIN"	 	},
	{ TABLE_DRAW_ID,	"RSM_MATCH_DRAW" 	}
}

new g_eWeapon[MAX_WEAPONS_EX][WeaponsInfo] = {
	{ "", 			"RSM_NA" 		},
	{ "knife", 		"RSM_KNIFE" 	},
	{ "glock18", 	"RSM_GLOCK18" 	},
	{ "usp", 		"RSM_USP" 		},
	{ "p228", 		"RSM_P228" 		},
	{ "deagle", 	"RSM_DEAGLE" 	},
	{ "fiveseven", 	"RSM_FIVESEVEN" },
	{ "elite", 		"RSM_ELITE" 	},
	{ "m3", 		"RSM_M3" 		},
	{ "xm1014", 	"RSM_XM1014" 	},
	{ "tmp", 		"RSM_TMP" 		},
	{ "mac10", 		"RSM_MAC10" 	},
	{ "mp5navy", 	"RSM_MP5" 		},
	{ "ump45", 		"RSM_UMP45" 	},
	{ "p90", 		"RSM_P90" 		},
	{ "m249", 		"RSM_M249" 		},
	{ "galil", 		"RSM_GALIL" 	},
	{ "famas",		"RSM_FAMAS" 	},
	{ "ak47", 		"RSM_AK47" 		},
	{ "m4a1", 		"RSM_M4A1" 		},
	{ "sg552", 		"RSM_SG552" 	},
	{ "aug", 		"RSM_AUG" 		},
	{ "scout", 		"RSM_SCOUT" 	},
	{ "awp", 		"RSM_AWP" 		},
	{ "g3sg1", 		"RSM_G3SG1" 	},
	{ "sg550", 		"RSM_SG550" 	},
	{ "grenade", 	"RSM_HEGRENADE" }
}

new g_szOrder[MAX_ORDERS][MAX_NAME_LENGTH] = { "RSM_XP", "RSM_KILLS_C", "RSM_MVP", "RSM_ROUNDS_WON", "RSM_BOMBS_PLANTED", "RSM_BOMBS_DEFUSED", "RSM_PLAYED_TIME", "RSM_SKILL" }

new g_eSetting[Settings]
new Handle:g_iSqlTuple
new Array:g_aRanks, Array:g_aSkills
new Trie:g_tRewards, Trie:g_tTeamRewards
new g_pPlayerData[MAX_PLAYERS + 1][PlayerData], g_pMapData[MAX_PLAYERS + 1][MapData], g_szSaveInfo[MAX_PLAYERS + 1][MAX_INFO_LENGTH], g_iRoundKills[MAX_PLAYERS + 1]
new g_iWeaponKills[MAX_PLAYERS + 1][MAX_WEAPONS_EX], g_iOrder[MAX_PLAYERS + 1], g_pAssistData[MAX_PLAYERS + 1][AssistData]
new g_iTop5Weapons[MAX_PLAYERS + 1][Top5Info][5], g_iOldRank[MAX_PLAYERS + 1], g_szPlayerFile[MAX_PLAYERS + 1][MAX_USER_INFO_LENGTH], g_iRoundHs[MAX_PLAYERS + 1]
new g_iTotalXp[MAX_PLAYERS + 1], g_iTotalTeamXp[MAX_PLAYERS + 1], g_iTeamScore[eWinData - 2]
new g_szTop15[MAX_MOTD_LENGTH], g_szHS15[MAX_MOTD_LENGTH], g_szStats[MAX_MOTD_LENGTH], g_szMapend[MAX_PLAYERS + 1][MAX_MOTD_LENGTH]
new g_szStatsTitle[MAX_RESOURCE_PATH_LENGTH], g_szSteamData[MAX_DATA_LENGTH], g_szDeathString[MAX_NAME_LENGTH]
new bool:g_blGoodKill[MAX_PLAYERS + 1], bool:g_blLoggedTop15[MAX_PLAYERS + 1], g_blLoaded[MAX_PLAYERS + 1], bool:g_blMVP
new g_iObject, g_iObject2, g_iObject3, g_iScreenFade, g_iRows, g_iPlantID, g_iRanks, g_iSkills, g_iAssistKiller, g_iMaxPlayers
new HookChain:g_pCBasePlayer_Killed_Post, HookChain:g_pSV_WriteFullClientUpdate

public plugin_init() {
	register_plugin("Rank System", "0.0.3", "mIDnight")
	register_dictionary(DIRECTORY_NAME)

	RegisterHookChain(RG_CBasePlayer_Spawn, 				"CBase_Player_Spawn",				true)
	RegisterHookChain(RG_CBasePlayer_SetClientUserInfoName, "SetClientUserInfoName", 			false)
	RegisterHookChain(RG_RoundEnd, 							"RG__RoundEnd", 					false)
	RegisterHookChain(RG_CBaseEntity_FireBullets3, 			"CBaseEntity_FireBullets", 			true)
	RegisterHookChain(RG_CBaseEntity_FireBuckshots, 		"CBaseEntity_FireBullets", 			true)
	RegisterHookChain(RG_CBasePlayer_TakeDamage, 			"CBasePlayer_TakeDamage", 			true)
	RegisterHookChain(RG_PlayerBlind, 						"RG__PlayerBlind", 					false)
	RegisterHookChain(RG_CBasePlayer_Killed, 				"CBasePlayer_Killed_Pre", 			false)
	RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, 		"CSGameRules_OnRoundFreezeEnd", 	false)
	RegisterHookChain(RG_PlantBomb, 						"RG_PlantBomb_Hook", 				true)
	RegisterHookChain(RG_CGrenade_DefuseBombEnd, 			"RG_CGrenade_DefuseBombEnd_Hook", 	true)
	RegisterHookChain(RG_CGrenade_ExplodeBomb, 				"RG_CGrenade_ExplodeBomb_Hook", 	true)
	RegisterHookChain(RG_CSGameRules_GoToIntermission, 		"CSGameRules_GoToIntermission", 	true)

	DisableHookChain((g_pCBasePlayer_Killed_Post = 	RegisterHookChain(RG_CBasePlayer_Killed, 		"CBasePlayer_Killed_Post", 	true)))
	DisableHookChain((g_pSV_WriteFullClientUpdate = RegisterHookChain(RH_SV_WriteFullClientUpdate, 	"SV_WriteFullClientUpdate", false)))

	register_concmd("rsm_give_xp", 		"cmdGiveXP", 		ADMIN_RCON, 	"<nick|#userid> <amount>")
	register_concmd("rsm_reset_stats", 	"cmdResetStats", 	ADMIN_RCON, 	"<nick>")
	register_concmd("rsm_reset_tables", "cmdResetTable", 	ADMIN_RCON)
	
	g_iMaxPlayers = get_maxplayers() + 1
	g_iScreenFade = get_user_msgid("ScreenFade")
	register_message(get_user_msgid("DeathMsg"), "Message_DeathMsg")

	SqlInit()
}

public plugin_natives() {
	register_library("ranksmysql")
	register_native("rsm_get_user_xp", 				"native_rsm_get_user_xp")
	register_native("rsm_get_user_level", 			"native_rsm_get_user_level")
	register_native("rsm_get_user_kills", 			"native_rsm_get_user_kills")
	register_native("rsm_get_user_deaths", 			"native_rsm_get_user_deaths")
	register_native("rsm_get_user_headshots", 		"native_rsm_get_user_headshots")
	register_native("rsm_get_user_assists", 		"native_rsm_get_user_assists")
	register_native("rsm_get_user_shots", 			"native_rsm_get_user_shots")
	register_native("rsm_get_user_hits", 			"native_rsm_get_user_hits")
	register_native("rsm_get_user_damage", 			"native_rsm_get_user_damage")
	register_native("rsm_get_user_mvp", 			"native_rsm_get_user_mvp")
	register_native("rsm_get_user_rounds_won", 		"native_rsm_get_user_rounds_won")
	register_native("rsm_get_user_bombs_planted", 	"native_rsm_get_user_bombs_planted")
	register_native("rsm_get_user_bombs_defused", 	"native_rsm_get_user_bombs_defused")
	register_native("rsm_get_user_played_time", 	"native_rsm_get_user_played_time")
	register_native("rsm_get_user_rank", 			"native_rsm_get_user_rank")
	register_native("rsm_get_user_skill", 			"native_rsm_get_user_skill")
	register_native("rsm_get_user_skill_range", 	"native_rsm_get_user_skill_range")
	register_native("rsm_get_max_levels", 			"native_rsm_get_max_levels")
	register_native("rsm_get_user_server_rank", 	"native_rsm_get_user_server_rank")
	register_native("rsm_get_max_server_ranks", 	"native_rsm_get_max_server_ranks")
	register_native("rsm_give_user_xp",				"native_rsm_give_user_xp")
	register_native("rsm_give_team_xp",				"native_rsm_give_team_xp")
	register_native("rsm_reset_stats", 				"native_rsm_reset_stats")
}

public native_rsm_get_user_xp(iPlugin, iParams) {
	return g_pPlayerData[get_param(1)][Xp]
}

public native_rsm_get_user_level(iPlugin, iParams) {
	return g_pPlayerData[get_param(1)][Level] + 1
}

public native_rsm_get_user_kills(iPlugin, iParams) {
	return g_pPlayerData[get_param(1)][Kills]
}

public native_rsm_get_user_deaths(iPlugin, iParams) {
	return g_pPlayerData[get_param(1)][Deaths]
}

public native_rsm_get_user_headshots(iPlugin, iParams) {
	return g_pPlayerData[get_param(1)][Headshots]
}

public native_rsm_get_user_assists(iPlugin, iParams) {
	return g_pPlayerData[get_param(1)][Assists]
}

public native_rsm_get_user_shots(iPlugin, iParams) {
	return g_pPlayerData[get_param(1)][Shots]
}

public native_rsm_get_user_hits(iPlugin, iParams) {
	return g_pPlayerData[get_param(1)][Hits]
}

public native_rsm_get_user_damage(iPlugin, iParams) {
	return g_pPlayerData[get_param(1)][Damage]
}

public native_rsm_get_user_mvp(iPlugin, iParams) {
	return g_pPlayerData[get_param(1)][MVP]
}

public native_rsm_get_user_rounds_won(iPlugin, iParams) {
	return g_pPlayerData[get_param(1)][RoundsWon]
}

public native_rsm_get_user_bombs_planted(iPlugin, iParams) {
	return g_pPlayerData[get_param(1)][Planted]
}

public native_rsm_get_user_bombs_defused(iPlugin, iParams) {
	return g_pPlayerData[get_param(1)][Defused]
}

public native_rsm_get_user_played_time(iPlugin, iParams) {
	return g_pPlayerData[get_param(1)][PlayedTime]
}

public native_rsm_get_user_rank(iPlugin, iParams) {
	new iLevel, eMaxRanks[RankInfo]
	for(new i = 1; i < g_iRanks - 1; i++) {
		ArrayGetArray(g_aRanks, i, eMaxRanks)

		if(g_pPlayerData[get_param(1)][Xp] >= eMaxRanks[RankXp]) {
			iLevel++
		}
	}

	static eRank[RankInfo]
	ArrayGetArray(g_aRanks, iLevel, eRank)

	set_string(2, eRank[RankName], get_param(3))
}

public native_rsm_get_user_skill(iPlugin, iParams) {
	new iSkill, eMaxSkills[SkillInfo]
	for(new i = 1; i < g_iSkills; i++) {
		ArrayGetArray(g_aSkills, i, eMaxSkills)

		if(GetSkillRange(get_param(1)) >= eMaxSkills[SkillRange]) {
			iSkill++
		}
	}

	static eSkill[SkillInfo]
	ArrayGetArray(g_aSkills, iSkill, eSkill)
	
	set_string(2, eSkill[SkillName], get_param(3))
}

public native_rsm_get_user_skill_range(iPlugin, iParams) {
	return _:GetSkillRange(get_param(1))
}

public native_rsm_get_max_levels(iPlugin, iParams) {
	return g_iRanks
}

public native_rsm_get_user_server_rank(iPlugin, iParams) {
	return g_pPlayerData[get_param(1)][RankID]
}

public native_rsm_get_max_server_ranks(iPlugin, iParams) {
	return g_iRows
}

public native_rsm_give_user_xp(iPlugin, iParams) {
	new id =  get_param(1)
	new iXp = get_param(2)

	UpdateXpAndRank(id, iXp, false)
	return iXp
}

public native_rsm_give_team_xp(iPlugin, iParams) {
	new iPlayers[MAX_PLAYERS], iPnum
	new iXp = get_param(2)

	switch(get_param(1)) {
		case TEAM_T: {
			get_players_ex(iPlayers, iPnum, GetPlayers_MatchTeam, "TERRORIST")

			for(new i; i < iPnum; i++) {
				UpdateXpAndRank(iPlayers[i], iXp, true)
				return iXp
			}
		}
		case TEAM_CT: {
			get_players_ex(iPlayers, iPnum, GetPlayers_MatchTeam, "CT")

			for(new i; i < iPnum; i++) {
				UpdateXpAndRank(iPlayers[i], iXp, true)
				return iXp
			}
		}
		case TEAM_SPEC: {
			get_players_ex(iPlayers, iPnum, GetPlayers_MatchTeam, "SPECTATOR")

			for(new i; i < iPnum; i++) {
				UpdateXpAndRank(iPlayers[i], iXp, true)
				return iXp
			}
		}
	}

	return iXp
}

public native_rsm_reset_stats(iPlugin, iParams) {
	ResetMySQLTables()
}

public plugin_precache() {
	g_aRanks = ArrayCreate(RankInfo)
	g_aSkills = ArrayCreate(SkillInfo)

	g_tRewards = TrieCreate()
	g_tTeamRewards = TrieCreate()

	ReadFile()
}

public plugin_end() {
	SQL_FreeHandle(g_iSqlTuple)

	ArrayDestroy(g_aRanks)
	ArrayDestroy(g_aSkills)

	TrieDestroy(g_tRewards)
	TrieDestroy(g_tTeamRewards)
}

public SqlInit() {
	g_iSqlTuple = SQL_MakeDbTuple(g_eSetting[MYSQL_HOST], g_eSetting[MYSQL_USER], g_eSetting[MYSQL_PASSWORD], g_eSetting[MYSQL_DATABASE])

	static szError[MAX_ITEM_LENGTH], iErrorCode
	new Handle:iSqlConnection = SQL_Connect(g_iSqlTuple, iErrorCode, szError, charsmax(szError))
	
	if(iSqlConnection == Empty_Handle) {
		set_fail_state(szError)
	}
	else {
		SQL_FreeHandle(iSqlConnection)
	}

	static szQuery[2][MAX_QUERY_LENGTH]
	formatex(szQuery[0], charsmax(szQuery[]), "CREATE TABLE IF NOT EXISTS `%s` (Player VARCHAR(%i) NOT NULL, Nick VARCHAR(%i) NOT NULL, XP INT(%i) NOT NULL, Level INT(%i) NOT NULL, Kills INT(%i) NOT NULL,\
	Deaths INT(%i) NOT NULL, Headshots INT(%i) NOT NULL, Assists INT(%i) NOT NULL, Shots INT(%i) NOT NULL, Hits INT(%i) NOT NULL, Damage INT(%i) NOT NULL, Planted INT(%i) NOT NULL,\
	Defused INT(%i) NOT NULL, MVP INT(%i) NOT NULL, `Rounds Won` INT(%i) NOT NULL, `Played Time` INT(%i) NOT NULL, PRIMARY KEY (Player));", g_eSetting[MYSQL_TABLE], MAX_INFO_LENGTH, MAX_NAME_LENGTH,
	MAX_INT_LENGTH, MAX_INT_LENGTH, MAX_INT_LENGTH, MAX_INT_LENGTH, MAX_INT_LENGTH, MAX_INT_LENGTH, MAX_INT_LENGTH, MAX_INT_LENGTH, MAX_INT_LENGTH, MAX_INT_LENGTH, MAX_INT_LENGTH, MAX_INT_LENGTH,
	MAX_INT_LENGTH, MAX_INT_LENGTH, MAX_INT_LENGTH)
	SQL_ThreadQuery(g_iSqlTuple, "QueryHandler", szQuery[0])

	formatex(szQuery[1], charsmax(szQuery[]), "CREATE TABLE IF NOT EXISTS `%s` (Player VARCHAR(%i) NOT NULL, `Weapon ID` INT(%i) NOT NULL, `Weapon Kills` INT(%i) NOT NULL);", g_eSetting[MYSQL_TABLE2],
	MAX_INFO_LENGTH, MAX_INT_LENGTH, MAX_INT_LENGTH)
	SQL_ThreadQuery(g_iSqlTuple, "QueryHandler", szQuery[1])
}

public QueryHandler(iFailState, Handle:iQuery, szError[], iErrorCode) {
	SQL_IsFail(iFailState, iErrorCode, szError)
}

ReadFile() {
	get_datadir(g_szSteamData, charsmax(g_szSteamData))
	format(g_szSteamData, charsmax(g_szSteamData), "%s/%s", g_szSteamData, "steamdata")

	if(!dir_exists(g_szSteamData)) {
	    mkdir(g_szSteamData)
	}

	static szFile[MAX_USER_INFO_LENGTH]
	get_configsdir(szFile, charsmax(szFile))
	add(szFile, charsmax(szFile), "/rank_system_mysql.ini")
	
	new iFile = fopen(szFile, "rt")
	
	if(iFile) {
		static szData[MAX_DATA_LENGTH + MAX_RESOURCE_PATH_LENGTH], szKey[MAX_RESOURCE_PATH_LENGTH], szValue[MAX_DATA_LENGTH], eRanks[RankInfo], eSkills[SkillInfo], iSection = SECTION_NONE

		while(!feof(iFile)) {
			fgets(iFile, szData, charsmax(szData))
			trim(szData)
		
			switch(szData[0]) {
				case ';', EOS, '#': continue
				case '[': {
					if(szData[strlen(szData) - 1] == ']') {
						switch(szData[1]) {
							case 'M': iSection = SECTION_MYSQL
							case 'R': iSection = SECTION_RANKS
							case 'S': iSection = SECTION_SETTINGS
							case 'C': iSection = SECTION_COMMANDS
							case 'X': iSection = SECTION_REWARDS
						}

						if(szData[3] == 'i') {
							iSection = SECTION_SKILLS
						}
					}
					else continue
				}
				default: {
					if(iSection == SECTION_NONE) {
						continue
					}

					strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
					trim(szKey)
					trim(szValue)
					
					switch(iSection) {
						case SECTION_MYSQL: {
							if(equal(szKey, "MYSQL_HOST")) {
								copy(g_eSetting[MYSQL_HOST], charsmax(g_eSetting[MYSQL_HOST]), szValue)
							}
							else if(equal(szKey, "MYSQL_USER")) {
								copy(g_eSetting[MYSQL_USER], charsmax(g_eSetting[MYSQL_USER]), szValue)
							}
							else if(equal(szKey, "MYSQL_PASSWORD")) {
								copy(g_eSetting[MYSQL_PASSWORD], charsmax(g_eSetting[MYSQL_PASSWORD]), szValue)
							}
							else if(equal(szKey, "MYSQL_DATABASE")) {
								copy(g_eSetting[MYSQL_DATABASE], charsmax(g_eSetting[MYSQL_DATABASE]), szValue)
							}	
							else if(equal(szKey, "MYSQL_TABLE")) {
								copy(g_eSetting[MYSQL_TABLE], charsmax(g_eSetting[MYSQL_TABLE]), szValue)
							}
							else if(equal(szKey, "MYSQL_TABLE2")) {
								copy(g_eSetting[MYSQL_TABLE2], charsmax(g_eSetting[MYSQL_TABLE2]), szValue)
							}
						}
						case SECTION_SETTINGS: {
							if(equal(szKey, "HTTP_TOP15_LINK")) {
								copy(g_eSetting[HTTP_TOP15_LINK], charsmax(g_eSetting[HTTP_TOP15_LINK]), szValue)
							}
							else if(equal(szKey, "HTTP_HS15_LINK")) {
								copy(g_eSetting[HTTP_HS15_LINK], charsmax(g_eSetting[HTTP_HS15_LINK]), szValue)
							}
							else if(equal(szKey, "HTTP_STATS_LINK")) {
								copy(g_eSetting[HTTP_STATS_LINK], charsmax(g_eSetting[HTTP_STATS_LINK]), szValue)
							}
							else if(equal(szKey, "HTTP_MAPEND_LINK")) {
								copy(g_eSetting[HTTP_MAPEND_LINK], charsmax(g_eSetting[HTTP_MAPEND_LINK]), szValue)
							}
							if(equal(szKey, "HTTP_TOP15_LINK2")) {
								copy(g_eSetting[HTTP_TOP15_LINK2], charsmax(g_eSetting[HTTP_TOP15_LINK2]), szValue)
							}
							else if(equal(szKey, "HTTP_HS15_LINK2")) {
								copy(g_eSetting[HTTP_HS15_LINK2], charsmax(g_eSetting[HTTP_HS15_LINK2]), szValue)
							}
							else if(equal(szKey, "HTTP_STATS_LINK2")) {
								copy(g_eSetting[HTTP_STATS_LINK2], charsmax(g_eSetting[HTTP_STATS_LINK2]), szValue)
							}
							else if(equal(szKey, "HTTP_MAPEND_LINK2")) {
								copy(g_eSetting[HTTP_MAPEND_LINK2], charsmax(g_eSetting[HTTP_MAPEND_LINK2]), szValue)
							}
							else if(equal(szKey, "STEAM_API_KEY")) {
								copy(g_eSetting[STEAM_API_KEY], charsmax(g_eSetting[STEAM_API_KEY]), szValue)
							}
							else if(equal(szKey, "DEFAULT_AVATAR_LINK")) {
								copy(g_eSetting[DEFAULT_AVATAR_LINK], charsmax(g_eSetting[DEFAULT_AVATAR_LINK]), szValue)
							}
							else if(equal(szKey, "SAVE_TYPE")) {
								g_eSetting[SAVE_TYPE] = str_to_num(szValue)
							}
							else if(equal(szKey, "CHAT_PREFIX")) {
								copy(g_eSetting[CHAT_PREFIX], charsmax(g_eSetting[CHAT_PREFIX]), szValue)
								replace_string(g_eSetting[CHAT_PREFIX], charsmax(g_eSetting[CHAT_PREFIX]), "$1", "^1")
								replace_string(g_eSetting[CHAT_PREFIX], charsmax(g_eSetting[CHAT_PREFIX]), "$3", "^3")
								replace_string(g_eSetting[CHAT_PREFIX], charsmax(g_eSetting[CHAT_PREFIX]), "$4", "^4")
							}
							else if(equal(szKey, "RANK_INFO")) {
								g_eSetting[RANK_INFO] = str_to_num(szValue)
							}
							else if(equal(szKey, "RANK_BOTS")) {
								g_eSetting[RANK_BOTS] = str_to_num(szValue)
							}
							else if(equal(szKey, "HUD_ENABLE")) {
								g_eSetting[HUD_ENABLE] = str_to_num(szValue)
							}
							else if(equal(szKey, "HUD_TYPE")) {
								g_eSetting[HUD_TYPE] = str_to_num(szValue)

								if(!g_eSetting[HUD_TYPE]) {
									g_iObject = CreateHudSyncObj()
								}
							}
							else if(equal(szKey, "HUD_INFO")) {
								copy(g_eSetting[HUD_INFO], charsmax(g_eSetting[HUD_INFO]), szValue)
							}
							else if(equal(szKey, "HUD_INFO_MAX")) {
								copy(g_eSetting[HUD_INFO_MAX], charsmax(g_eSetting[HUD_INFO_MAX]), szValue)
							}
							else if(equal(szKey, "HUD_VALUES")) {
								new szHudValues[5][6]
								parse(szValue, szHudValues[0], charsmax(szHudValues[]), szHudValues[1], charsmax(szHudValues[]), szHudValues[2], charsmax(szHudValues[]),
								szHudValues[3], charsmax(szHudValues[]), szHudValues[4], charsmax(szHudValues[]))
								
								for(new i; i < 5; i++) {
									g_eSetting[HUD_VALUES][i] = _:str_to_float(szHudValues[i])
								}
							}
							else if(equal(szKey, "LEVEL_MESSAGE_TYPE")) {
								g_eSetting[LEVEL_MESSAGE_TYPE] = str_to_num(szValue)
							}
							else if(equal(szKey, "LEVELUP_EFFECTS")) {
								new szFade[5][4]
								parse(szValue, szFade[0], charsmax(szFade[]), szFade[1], charsmax(szFade[]), szFade[2], charsmax(szFade[]), szFade[3], charsmax(szFade[]), szFade[4], charsmax(szFade[]))
								
								for(new i; i < 5; i++) {
									g_eSetting[LEVELUP_EFFECTS][i] = _:str_to_float(szFade[i])
								}
							}
							else if(equal(szKey, "LEVELUP_SOUND")) {
								copy(g_eSetting[LEVELUP_SOUND], charsmax(g_eSetting[LEVELUP_SOUND]), szValue)
								if(szValue[0] != EOS) precache_sound(szValue)
							}
							else if(equal(szKey, "LEVELDN_EFFECTS")) {
								new szFade[5][4]
								parse(szValue, szFade[0], charsmax(szFade[]), szFade[1], charsmax(szFade[]), szFade[2], charsmax(szFade[]), szFade[3], charsmax(szFade[]), szFade[4], charsmax(szFade[]))
								
								for(new i; i < 5; i++) {
									g_eSetting[LEVELDN_EFFECTS][i] = _:str_to_float(szFade[i])
								}
							}
							else if(equal(szKey, "LEVELDN_SOUND")) {
								copy(g_eSetting[LEVELDN_SOUND], charsmax(g_eSetting[LEVELDN_SOUND]), szValue)
								if(szValue[0] != EOS) precache_sound(szValue)
							}
							else if(equal(szKey, "ASSIST_VALUES")) {
								new szAssist[2][6]
								parse(szValue, szAssist[0], charsmax(szAssist[]), szAssist[1], charsmax(szAssist[]))
								
								for(new i; i < 2; i++) {
									g_eSetting[ASSIST_VALUES][i] = str_to_num(szAssist[i])
								}
							}
							else if(equal(szKey, "XP_HUD_ENABLE")) {
								g_eSetting[XP_HUD_ENABLE] = str_to_num(szValue)
							}
							else if(equal(szKey, "XP_HUD_TEAM_ENABLE")) {
								g_eSetting[XP_HUD_TEAM_ENABLE] = str_to_num(szValue)
							}
							else if(equal(szKey, "XP_HUD_TYPE")) {
								g_eSetting[XP_HUD_TYPE] = str_to_num(szValue)

								if(!g_eSetting[XP_HUD_TYPE]) {
									g_iObject2 = CreateHudSyncObj()
								}
							}
							else if(equal(szKey, "XP_HUD_TEAM_TYPE")) {
								g_eSetting[XP_HUD_TEAM_TYPE] = str_to_num(szValue)

								if(!g_eSetting[XP_HUD_TEAM_TYPE]) {
									g_iObject3 = CreateHudSyncObj()
								}
							}
							else if(equal(szKey, "XP_HUD_GET")) {
								copy(g_eSetting[XP_HUD_GET], charsmax(g_eSetting[XP_HUD_GET]), szValue)
							}
							else if(equal(szKey, "XP_HUD_TEAM_GET")) {
								copy(g_eSetting[XP_HUD_TEAM_GET], charsmax(g_eSetting[XP_HUD_TEAM_GET]), szValue)
							}
							else if(equal(szKey, "XP_HUD_LOSE")) {
								copy(g_eSetting[XP_HUD_LOSE], charsmax(g_eSetting[XP_HUD_LOSE]), szValue)
							}
							else if(equal(szKey, "XP_HUD_TEAM_LOSE")) {
								copy(g_eSetting[XP_HUD_TEAM_LOSE], charsmax(g_eSetting[XP_HUD_TEAM_LOSE]), szValue)
							}
							else if(equal(szKey, "XP_HUD_VALUES")) {
								new szHudValues[7][6]
								parse(szValue, szHudValues[0], charsmax(szHudValues[]), szHudValues[1], charsmax(szHudValues[]), szHudValues[2], charsmax(szHudValues[]),
								szHudValues[3], charsmax(szHudValues[]), szHudValues[4], charsmax(szHudValues[]), szHudValues[5], charsmax(szHudValues[]), szHudValues[6], charsmax(szHudValues[]))
								
								for(new i; i < 7; i++) {
									g_eSetting[XP_HUD_VALUES][i] = _:str_to_float(szHudValues[i])
								}
							}
							else if(equal(szKey, "XP_HUD_TEAM_VALUES")) {
								new szHudValues[7][6]
								parse(szValue, szHudValues[0], charsmax(szHudValues[]), szHudValues[1], charsmax(szHudValues[]), szHudValues[2], charsmax(szHudValues[]),
								szHudValues[3], charsmax(szHudValues[]), szHudValues[4], charsmax(szHudValues[]), szHudValues[5], charsmax(szHudValues[]), szHudValues[6], charsmax(szHudValues[]))
								
								for(new i; i < 7; i++) {
									g_eSetting[XP_HUD_TEAM_VALUES][i] = _:str_to_float(szHudValues[i])
								}
							}
							else if(equal(szKey, "MVP_HUD_ENABLE")) {
								g_eSetting[MVP_HUD_ENABLE] = str_to_num(szValue)
							}
							else if(equal(szKey, "MVP_HUD_TYPE")) {
								g_eSetting[MVP_HUD_TYPE] = str_to_num(szValue)
							}
							else if(equal(szKey, "MVP_HUD_VALUES")) {
								new szHudValues[5][6]
								parse(szValue, szHudValues[0], charsmax(szHudValues[]), szHudValues[1], charsmax(szHudValues[]), szHudValues[2], charsmax(szHudValues[]),
								szHudValues[3], charsmax(szHudValues[]), szHudValues[4], charsmax(szHudValues[]))
								
								for(new i; i < 5; i++) {
									g_eSetting[MVP_HUD_VALUES][i] = _:str_to_float(szHudValues[i])
								}
							}
						}
						case SECTION_COMMANDS: {
							if(equal(szKey, "STATS_COMMANDS")) {
								while(szValue[0] != 0 && strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ',')) {
									trim(szKey)
									trim(szValue)
									register_clcmd(szKey, "cmdStats")
								}
							}
							else if(equal(szKey, "TOP15_COMMANDS")) {
								while(szValue[0] != 0 && strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ',')) {
									trim(szKey)
									trim(szValue)
									register_clcmd(szKey, "cmdTop15")
								}
							}
							else if(equal(szKey, "HS15_COMMANDS")) {
								while(szValue[0] != 0 && strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ',')) {
									trim(szKey)
									trim(szValue)
									register_clcmd(szKey, "cmdHS15")
								}
							}
							else if(equal(szKey, "XP_COMMANDS")) {
								while(szValue[0] != 0 && strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ',')) {
									trim(szKey)
									trim(szValue)
									register_clcmd(szKey, "cmdXp")
								}
							}
							else if(equal(szKey, "RANK_COMMANDS")) {
								while(szValue[0] != 0 && strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ',')) {
									trim(szKey)
									trim(szValue)
									register_clcmd(szKey, "cmdRank")
								}
							}
							else if(equal(szKey, "STATSVIEWER_COMMANDS")) {
								while(szValue[0] != 0 && strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ',')) {
									trim(szKey)
									trim(szValue)
									register_clcmd(szKey, "menuStatsViewer")
								}
							}
						}
						case SECTION_RANKS: {
							if(g_iRanks) {
								ArrayPushArray(g_aRanks, eRanks)
							}
							
							g_iRanks++
							copy(eRanks[RankName], charsmax(eRanks[RankName]), szKey)
							eRanks[RankXp] = str_to_num(szValue)
						}
						case SECTION_SKILLS: {
							if(g_iSkills) {
								ArrayPushArray(g_aSkills, eSkills)
							}

							g_iSkills++
							copy(eSkills[SkillName], charsmax(eSkills[SkillName]), szKey)
							eSkills[SkillRange] = _:str_to_float(szValue)
						}
						case SECTION_REWARDS: {
							new szReward[2][MAX_NUM_LENGTH]
							parse(szValue, szReward[0], charsmax(szReward[]), szReward[1], charsmax(szReward[]))

							TrieSetCell(g_tRewards, szKey, str_to_num(szReward[0]))
							TrieSetCell(g_tTeamRewards, szKey, str_to_num(szReward[1]))
							
							if(equal(szKey, "vip_flags")) {
								copy(g_eSetting[VIP_FLAGS], charsmax(g_eSetting[VIP_FLAGS]), szValue)
							}
						}
					}
				}
			}
		}

		if(g_iRanks) {
			ArrayPushArray(g_aRanks, eRanks)
		}

		if(g_iSkills) {
			ArrayPushArray(g_aSkills, eSkills)
		}

		fclose(iFile)
	}
}

public client_connect(id) {
	static szAuthID64[MAX_INFO_LENGTH]
	get_user_info(id, "*sid", szAuthID64, charsmax(szAuthID64))
	formatex(g_szPlayerFile[id], charsmax(g_szPlayerFile[]), "%s/%s.txt", g_szSteamData, szAuthID64)
	curl_save_player_info(g_szPlayerFile[id], szAuthID64)
	
	GetRows()
}

public client_putinserver(id) {
	if(!g_eSetting[RANK_BOTS] && is_user_bot(id)) {
		return  
	}

	ResetStats(id)
	switch(g_eSetting[SAVE_TYPE]) {
		case SAVE_NAME: 	get_user_name(id, g_szSaveInfo[id], charsmax(g_szSaveInfo[]))
		case SAVE_IP: 		get_user_ip(id, g_szSaveInfo[id], charsmax(g_szSaveInfo[]), 1)
		case SAVE_STEAMID: 	get_user_authid(id, g_szSaveInfo[id], charsmax(g_szSaveInfo[]))
	}

	SqlSaveOrLoad(id, MYSQL_LOAD)
	SqlSaveOrLoadKills(id, MYSQL_LOAD)
	GetTop5Weapons(id)

	set_task(1.0, "taskShowRank", id + TASK_RANK, .flags = "b")
	set_task(0.1, "taskShowHud",  id + TASK_HUD,  .flags = "b")
}

public client_disconnected(id) {
	if(!g_eSetting[RANK_BOTS] && is_user_bot(id)) {
		return  
	}

	new iTask =  id + TASK_RANK
	new iTask2 = id + TASK_HUD

	if(task_exists(iTask)) {
		remove_task(iTask)
	}
	
	if(task_exists(iTask2)) {
		remove_task(iTask2)
	}

	arrayset(g_pAssistData[id][AssistDamage], 0, sizeof g_pAssistData[][AssistDamage])
	for(new i = 1; i < g_iMaxPlayers; i++) g_pAssistData[i][AssistDamage][id] = 0
}

public client_infochanged(id) {
	get_user_info(id, "name", g_pAssistData[id][AssistName], charsmax(g_pAssistData[][AssistName]))
}

public curl_save_player_info(szFile[], szAuthID64[]) {
	new iData[1]; iData[0] = fopen(szFile, "wb")

	new CURL:iCurl = curl_easy_init()
	curl_easy_setopt(iCurl, CURLOPT_BUFFERSIZE, MAX_CURL_LENGTH)

	new szLink[MAX_USER_INFO_LENGTH]
	format(szLink, charsmax(szLink), "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=%s&steamids=%s&format=vdf", g_eSetting[STEAM_API_KEY], szAuthID64)
	curl_easy_setopt(iCurl, CURLOPT_URL, szLink)
	curl_easy_setopt(iCurl, CURLOPT_WRITEDATA, iData[0])
	curl_easy_setopt(iCurl, CURLOPT_WRITEFUNCTION, "write")
	curl_easy_perform(iCurl, "complite", iData, sizeof(iData))
}

public write(iData[], iSize, iNmemb, iFile) {
	new iCurrentSize = iSize * iNmemb
	fwrite_blocks(iFile, iData, iCurrentSize, BLOCK_CHAR)
	return iCurrentSize
}

public complite(CURL:iCurl, CURLcode:iCode, iData[]) {
	fclose(iData[0])
	curl_easy_cleanup(iCurl)
}

public get_steamdata(const id, szBuffer[], iLen, szAttribute[]) {
	new iFile = fopen(g_szPlayerFile[id], "r")
	while(!feof(iFile)) {
		static szFileData[MAX_DATA_LENGTH], szData[2][MAX_USER_INFO_LENGTH]

		fgets(iFile, szFileData, charsmax(szFileData))
		parse(szFileData, szData[0], charsmax(szData[]), szData[1], charsmax(szData[]))

		if(szData[0][0] == '{' || szData[0][0] == '}' || szData[0][0] == ' ' || equal(szData[0], "response") || equal(szData[0], "players") || equal(szData[0], "0")) {
			continue
		}

		if(equal(szAttribute, szData[0])) {
			formatex(szBuffer, iLen, szData[1])
		}
	}

	fclose(iFile)
}

public CBase_Player_Spawn(id) {
	if(is_user_alive(id)) {
		g_blGoodKill[id] = true

		if(g_eSetting[RANK_INFO]) {
			set_task(0.1, "taskCheckRank", id)
		}

		arrayset(g_pAssistData[id][AssistDamage], 0, sizeof g_pAssistData[][AssistDamage])
		for(new i = 1; i < g_iMaxPlayers; i++) g_pAssistData[i][AssistDamage][id] = 0
	}
}

public taskCheckRank(id) {
	set_task(0.1, "taskSetRank", id)

	if(g_iOldRank[id] == g_pPlayerData[id][RankID] || !g_iOldRank[id] || !g_blLoaded[id] || !g_pPlayerData[id][RankID]) {
		return
	}

	new bool:blTop15 = g_pPlayerData[id][RankID] <= 15
	if(g_iOldRank[id] > g_pPlayerData[id][RankID]) {
		CPC(id, "%L", id, "RSM_GOT_UP_WITH", (g_iOldRank[id] - g_pPlayerData[id][RankID]))
	}
	else if(g_iOldRank[id] < g_pPlayerData[id][RankID]) {
		CPC(id, "%L", id, "RSM_GOT_DOWN_WITH", (g_pPlayerData[id][RankID] - g_iOldRank[id]))
	}

	if(blTop15 && !g_blLoggedTop15[id]) {
		CPC(id, "%L", id, "RSM_TOP15_LOGGED_IN")
		g_blLoggedTop15[id] = true
	}
	else if(!blTop15 && g_blLoggedTop15[id]) {
		CPC(id, "%L", id, "RSM_TOP15_LOGGED_OUT")
		g_blLoggedTop15[id] = false
	}

	CPC(id, "%L", id, "RSM_RANK_NOW", g_pPlayerData[id][RankID], g_iRows)
}

public taskSetRank(id) {
	g_iOldRank[id] = g_pPlayerData[id][RankID]
}

public SetClientUserInfoName(id, const szInfoBuffer[], const szNewName[]) {
	if(g_eSetting[SAVE_TYPE] == SAVE_NAME) {
		if(!g_eSetting[RANK_BOTS] && is_user_bot(id)) {
			return  
		}

		static szOldName[MAX_NAME_LENGTH]
		get_entvar(id, var_netname, szOldName, charsmax(szOldName))
		copy(g_szSaveInfo[id], charsmax(g_szSaveInfo[]), szOldName)
		SqlSaveOrLoad(id, MYSQL_SAVE)
		SqlSaveOrLoadKills(id, MYSQL_SAVE)

		ResetStats(id)
		copy(g_szSaveInfo[id], charsmax(g_szSaveInfo[]), szNewName)

		SqlSaveOrLoad(id, MYSQL_LOAD)
		GetPlayerInfo(id)
		SqlSaveOrLoadKills(id, MYSQL_LOAD)
		GetTop5Weapons(id)
	}
}

public CSGameRules_OnRoundFreezeEnd() {
	new iPlayers[MAX_PLAYERS], iNum
	get_players_ex(iPlayers, iNum)
	
	for (--iNum; iNum >= 0; iNum--) {
		g_iRoundKills[iPlayers[iNum]] = 0
		g_iRoundHs[iPlayers[iNum]] = 0
	}

	g_blMVP = false
}

public RG__RoundEnd(WinStatus:iStatus, ScenarioEventEndRound:iEvent, Float:tmDelay) {
	new i_Xp[eWinData], bWinTeam[TeamName], iPlayers[MAX_PLAYERS], iNum, id
	switch (iEvent) {
		case ROUND_TERRORISTS_WIN, ROUND_HOSTAGE_NOT_RESCUED: {
			i_Xp[TERR_WIN] = GetXpReward("t_win", XP_REWARD)
			i_Xp[CTs_LOSE] = GetXpReward("ct_lose", XP_REWARD)

			bWinTeam[TEAM_TERRORIST] = true
			bWinTeam[TEAM_CT] = false

			g_iTeamScore[TERR_WIN]++
		}
		case ROUND_CTS_WIN: {
			i_Xp[TERR_LOSE] = GetXpReward("t_lose", XP_REWARD)
			i_Xp[CTs_WIN] = GetXpReward("ct_win", XP_REWARD)

			bWinTeam[TEAM_TERRORIST] = false
			bWinTeam[TEAM_CT] = true

			g_iTeamScore[CTs_WIN]++
		}
	}

	get_players_ex(iPlayers, iNum, GetPlayers_MatchTeam, "TERRORIST")

	for (--iNum; iNum >= 0; iNum--) {
		id = iPlayers[iNum]

		g_pPlayerData[id][RoundsWon]++
		UpdateXpAndRank(id, bWinTeam[TEAM_TERRORIST] ? i_Xp[TERR_WIN] : i_Xp[TERR_LOSE], true)
	}

	get_players_ex(iPlayers, iNum, GetPlayers_MatchTeam, "CT")

	for (--iNum; iNum >= 0; iNum--) {
		id = iPlayers[iNum]

		g_pPlayerData[id][RoundsWon]++
		UpdateXpAndRank(id, bWinTeam[TEAM_CT] ? i_Xp[CTs_WIN] : i_Xp[CTs_LOSE], true)
	}

	set_task(0.1, "ShowMVP")
}

public CBaseEntity_FireBullets(const iEnt) {
	if(is_user_connected(iEnt)) {
		g_pPlayerData[iEnt][Shots]++
	}

	return HC_CONTINUE
}

public CBasePlayer_TakeDamage(iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamageType) {
	if(!is_user_connected(iAttacker) || !is_user_connected(iVictim) || !rg_is_player_can_takedamage(iAttacker, iVictim) || iAttacker == iVictim) {
		return HC_CONTINUE
	}

	g_pPlayerData[iAttacker][Hits]++
	g_pPlayerData[iAttacker][Damage] += floatround(flDamage)

	new Float:fHealth; get_entvar(iVictim, var_health, fHealth)
	if(flDamage > fHealth) flDamage = fHealth

	g_pAssistData[iAttacker][AssistDamage][iVictim] += floatround(flDamage)
	g_pAssistData[iAttacker][AssistDamageOnTime][iVictim] = get_gametime()

	return HC_CONTINUE
}

public RG__PlayerBlind(const iVictim, const Inflictor, const iAttacker, const Float:flFadeTime, const Float:flFadeHold, iAlpha, Float:flColor[3]) {
	if(!rg_is_user_blinded(iVictim)) {
		g_pAssistData[iAttacker][IsFlashed][iVictim] = true

		new iArg[1]; iArg[0] = iVictim
		set_task(flFadeHold, "taskResetFlash", iAttacker, iArg, sizeof(iArg))
	}
	return HC_CONTINUE
}

public taskResetFlash(iArg[1], iAttacker) {
	g_pAssistData[iAttacker][IsFlashed][iArg[0]] = false
}

public CBasePlayer_Killed_Pre(iVictim, iKiller, iShouldGib) {
	new iTotalDamage, iAssistant, iMaxDamage
	for(new iMax = 1; iMax < g_iMaxPlayers; iMax++) {
		if(is_user_connected(iMax)) {
			if(iMax != iKiller) {
				if(g_pAssistData[iMax][AssistDamage][iVictim] > 0) {
					if(g_pAssistData[iMax][AssistDamage][iVictim] > iMaxDamage) {
						iAssistant = iMax
						iMaxDamage = g_pAssistData[iMax][AssistDamage][iVictim]
					}
				}

				if(g_pAssistData[iMax][IsFlashed][iVictim]) iAssistant = iMax
			}
			else if(g_pAssistData[iMax][AssistDamage][iVictim] == iMaxDamage) {
				iAssistant = g_pAssistData[iMax][AssistDamageOnTime][iVictim] > g_pAssistData[iAssistant][AssistDamageOnTime][iVictim] ? iMax : iAssistant
			}

			iTotalDamage += g_pAssistData[iMax][AssistDamage][iVictim]
		}
	}
	if((float(iMaxDamage) / float(iTotalDamage)) * 100.0 < g_eSetting[ASSIST_VALUES][ASSIST_MIN_DMG]) iAssistant = 0

	if(iAssistant && iKiller != iVictim) {	
		new szName[2][MAX_NAME_LENGTH], iLen[2], iExcess
		copy(szName[1], charsmax(szName[]), g_pAssistData[iAssistant][AssistName])
		iLen[1] = strlen(szName[1])

		EnableHookChain(g_pSV_WriteFullClientUpdate)
		
		static const szWorldName[] = "world"
		new bool:bIsAssistantConnected = bool:is_user_connected(iAssistant)

		if(!is_user_valid(iKiller)) {
			if(bIsAssistantConnected) {
				iExcess = iLen[1] - NAMES_LENGTH - (sizeof szWorldName)
				if(iExcess > 0) strclip(szName[1], iExcess)
				formatex(g_szDeathString, charsmax(g_szDeathString), "%s + %s", szWorldName, szName[1])

				g_iAssistKiller = iAssistant
				rh_update_user_info(iAssistant)
			}
		}
		else if(is_user_connected(iKiller)) {
			g_pAssistData[iKiller][AssistDamage][iVictim] = 0
			
			copy(szName[0], charsmax(szName[]), g_pAssistData[iKiller][AssistName])
			iLen[0] = strlen(szName[0])

			new iLenSum = (iLen[0] + iLen[1])
			iExcess = iLenSum - NAMES_LENGTH

			if(iExcess > 0) {
				new iLongest = iLen[0] > iLen[1] ? 0 : 1
				new iShortest = iLongest == 1 ? 0 : 1

				if(float(iExcess) / float(iLen[iLongest]) > 0.60) {
					new iNewLongest = floatround(float(iLen[iLongest]) / float(iLenSum) * float(iExcess))
					strclip(szName[iLongest], iNewLongest)
					strclip(szName[iShortest], iExcess - iNewLongest)
				}
				else strclip(szName[iLongest], iExcess)
			}
			formatex(g_szDeathString, charsmax(g_szDeathString), "%s + %s", szName[0], szName[1])

			g_iAssistKiller = iKiller
			rh_update_user_info(g_iAssistKiller)
		}
		if(bIsAssistantConnected) {   
			g_pAssistData[iAssistant][AssistDamage][iVictim] = 0
			g_pAssistData[iAssistant][IsFlashed][iVictim] = false

			if(g_eSetting[ASSIST_VALUES][ASSIST_MONEY]) {
				rg_add_account(iAssistant, g_eSetting[ASSIST_VALUES][ASSIST_MONEY])
			}

			g_pPlayerData[iAssistant][Assists]++
			UpdateXpAndRank(iAssistant, GetXpReward("assist", XP_REWARD), false)

			new iPlayers[MAX_PLAYERS], iNum, id
			for (--iNum; iNum >= 0; iNum--) {
				id = iPlayers[iNum]
				UpdateXpAndRank(id, GetXpReward("assist", XP_TEAM_REWARD), true)
			}
		}

		DisableHookChain(g_pSV_WriteFullClientUpdate)
		if(g_iAssistKiller) EnableHookChain(g_pCBasePlayer_Killed_Post)
 	}

	if (!is_user_connected(iKiller) || !is_user_connected(iVictim) || !g_eSetting[RANK_BOTS] && is_user_bot(iKiller)) {
		return HC_CONTINUE
	}

	new iXp, iTeamXp, iPlayers[MAX_PLAYERS], iNum, id, szWeapon[MAX_NAME_LENGTH]

	new WeaponIdType:iWeapon = rg_get_user_active_weapon(iKiller)
	if(iWeapon != WEAPON_NONE) {
		rg_get_weapon_info(iWeapon, WI_NAME, szWeapon, charsmax(szWeapon))
		replace_string(szWeapon, charsmax(szWeapon), "weapon_", "")
	}

	if (rg_get_user_team(iKiller) == rg_get_user_team(iVictim)) {
		iXp += GetXpReward("teamkill", XP_REWARD)
		iTeamXp += GetXpReward("teamkill", XP_TEAM_REWARD)
		g_blGoodKill[iKiller] = false
	}

	if (iKiller == iVictim) {
		iXp += GetXpReward("suicide", XP_REWARD)
		iTeamXp += GetXpReward("suicide", XP_TEAM_REWARD)
		g_blGoodKill[iKiller] = false
	}

	if(g_blGoodKill[iKiller]) {
		iXp += GetXpReward("kill", XP_REWARD)
		iTeamXp += GetXpReward("kill", XP_TEAM_REWARD)
		iXp += GetXpReward(szWeapon, XP_REWARD)
		iTeamXp += GetXpReward(szWeapon, XP_TEAM_REWARD)

		if(rg_user_killed_by_headshot(iVictim)) {
			iXp += GetXpReward("headshot", XP_REWARD)
			iTeamXp += GetXpReward("headshot", XP_TEAM_REWARD)

			g_pPlayerData[iKiller][Headshots]++
			g_iRoundHs[iKiller]++
		}

		if(get_user_flags(iKiller) & read_flags(g_eSetting[VIP_FLAGS])) {
			iXp += GetXpReward("vip", XP_REWARD)
			iTeamXp += GetXpReward("vip", XP_TEAM_REWARD)
		}

		if(rg_is_user_blinded(iKiller)) {
			iXp += GetXpReward("blind", XP_REWARD)
			iTeamXp += GetXpReward("blind", XP_TEAM_REWARD)
		}

		for(new i; i < MAX_WEAPONS_EX; i++) {
			if(equal(szWeapon, g_eWeapon[i][WpnName])) {
				g_iWeaponKills[iKiller][i]++
			}
		}

		g_pPlayerData[iKiller][Kills]++
		g_iRoundKills[iKiller]++
	}

	g_pPlayerData[iVictim][Deaths]++

	UpdateXpAndRank(iKiller, iXp, false)
	SqlSaveOrLoadKills(iKiller, MYSQL_SAVE)
	GetTop5Weapons(iKiller)

	get_players_ex(iPlayers, iNum, GetPlayers_MatchTeam, rg_get_user_team(iKiller) == TEAM_TERRORIST ? "TERRORIST" : rg_get_user_team(iKiller) == TEAM_CT ? "CT" : "")

	for (--iNum; iNum >= 0; iNum--) {
		id = iPlayers[iNum]
		UpdateXpAndRank(id, iTeamXp, true)
	}

	GetPlayerInfo(iVictim)
	return HC_CONTINUE
}

public CBasePlayer_Killed_Post(iVictim, iKiller) {
	DisableHookChain(g_pCBasePlayer_Killed_Post)

	new iAssistKiller = g_iAssistKiller; g_iAssistKiller = 0
	rh_update_user_info(iAssistKiller)
}

public SV_WriteFullClientUpdate(id, pBuffer) {
	if(id == g_iAssistKiller) {
		set_key_value(pBuffer, "name", g_szDeathString)
	}
}

public Message_DeathMsg() {
	new iWorld = get_msg_arg_int(1)
	if(iWorld == 0 && g_iAssistKiller) {
		set_msg_arg_int(1, ARG_BYTE, g_iAssistKiller)
	}
}

public RG_PlantBomb_Hook(const id) {
	new iPlayers[MAX_PLAYERS], iPnum
	get_players_ex(iPlayers, iPnum, GetPlayers_MatchTeam, "TERRORIST")
	
	new iXp = GetXpReward("bomb_plant", XP_REWARD)
	new iTeamXp = GetXpReward("bomb_plant", XP_TEAM_REWARD)

	for(new i; i < iPnum; i++) {
		UpdateXpAndRank(iPlayers[i], iTeamXp, true)
	}

	g_iPlantID = id
	g_pPlayerData[id][Planted]++
	UpdateXpAndRank(id, iXp, false)
}

public RG_CGrenade_DefuseBombEnd_Hook(const this, id, bool:blDefused) {
	if(g_blMVP || !blDefused) {
		return
	}

	new iPlayers[MAX_PLAYERS], iPnum
	get_players_ex(iPlayers, iPnum, GetPlayers_MatchTeam, "CT")
	
	new iXp = GetXpReward("bomb_defuse", XP_REWARD)
	new iTeamXp = GetXpReward("bomb_defuse", XP_TEAM_REWARD)

	for(new i; i < iPnum; i++) {
		UpdateXpAndRank(iPlayers[i], iTeamXp, true)
	}

	g_pPlayerData[id][Defused]++
	GetMVP(id, BOMB_DEFUSE)
	UpdateXpAndRank(id, iXp, false)
}

public RG_CGrenade_ExplodeBomb_Hook(const this) {
	if(g_blMVP) {
		return
	}
	
	new iPlayers[MAX_PLAYERS], iPnum
	get_players_ex(iPlayers, iPnum, GetPlayers_MatchTeam, "TERRORIST")
	
	new iXp = GetXpReward("bomb_explode", XP_REWARD)
	new iTeamXp = GetXpReward("bomb_explode", XP_TEAM_REWARD)

	for(new i; i < iPnum; i++) {
		UpdateXpAndRank(iPlayers[i], iTeamXp, true)
	}

	GetMVP(g_iPlantID, BOMB_EXPLODE)
	UpdateXpAndRank(g_iPlantID, iXp, false)
}

public taskShowRank(id) {
	if(!g_eSetting[HUD_ENABLE]) {
		return
	}

	id -= TASK_RANK
	
	new iTarget = id
	if(!is_user_alive(id)) {
		iTarget = get_entvar(id, var_iuser2)
	}
	
	if(!iTarget) {
		return
	}
	
	new iRed = 			floatround(g_eSetting[HUD_VALUES][HUD_COLOR1])
	new iGreen = 		floatround(g_eSetting[HUD_VALUES][HUD_COLOR2])
	new iBlue = 		floatround(g_eSetting[HUD_VALUES][HUD_COLOR3])
	new Float:flPosX = 	g_eSetting[HUD_VALUES][HUD_POS_X]
	new Float:flPosY = 	g_eSetting[HUD_VALUES][HUD_POS_Y]

	if(iRed < 0) 	iRed = 		random(256)
	if(iGreen < 0) 	iGreen = 	random(256)
	if(iBlue < 0) 	iBlue = 	random(256)

	static szHudInfo[MAX_DATA_LENGTH], szReplace[MAX_RESOURCE_PATH_LENGTH]
	new bool:blMaxLevel = g_pPlayerData[iTarget][Level] == g_iRanks - 1

	if(blMaxLevel) {
		copy(szHudInfo, charsmax(szHudInfo), g_eSetting[HUD_INFO_MAX])
	}
	else {
		copy(szHudInfo, charsmax(szHudInfo), g_eSetting[HUD_INFO])
	}
	
	new iLevel, eMaxRanks[RankInfo]
	for(new i = 1; i < g_iRanks - 1; i++) {
		ArrayGetArray(g_aRanks, i, eMaxRanks)

		if(g_pPlayerData[iTarget][Xp] >= eMaxRanks[RankXp]) {
			iLevel++
		}
	}

	static eRank[RankInfo], eNextRank[RankInfo]
	ArrayGetArray(g_aRanks, iLevel, eRank)
	ArrayGetArray(g_aRanks, iLevel + 1, eNextRank)

	new iSkill, eMaxSkills[SkillInfo], eLastSkill[SkillInfo]
	for(new i = 1; i < g_iSkills - 1; i++) {
		ArrayGetArray(g_aSkills, i, eMaxSkills)
		ArrayGetArray(g_aSkills, i + 1, eLastSkill)

		if(GetSkillRange(iTarget) >= eMaxSkills[SkillRange])
		{
			iSkill++
		}
	}

	static eSkill[SkillInfo], eNextSkill[SkillInfo]
	ArrayGetArray(g_aSkills, iSkill, eSkill)
	ArrayGetArray(g_aSkills, iSkill + 1, eNextSkill)

	if(contain(szHudInfo, "%name%") != -1) {
		static szName[MAX_NAME_LENGTH]
		get_user_name(iTarget, szName, charsmax(szName))
		replace_string(szHudInfo, charsmax(szHudInfo), "%name%", szName)
	}

	if(contain(szHudInfo, "%xp%") != -1) {
		num_to_str(g_pPlayerData[iTarget][Xp], szReplace, charsmax(szReplace))
		replace_string(szHudInfo, charsmax(szHudInfo), "%xp%", szReplace)
	}

	if(contain(szHudInfo, "%level%") != -1) {
		num_to_str(g_pPlayerData[iTarget][Level] + 1, szReplace, charsmax(szReplace))
		replace_string(szHudInfo, charsmax(szHudInfo), "%level%", szReplace)
	}

	if(contain(szHudInfo, "%rank%") != -1) {
		formatex(szReplace, charsmax(szReplace), "%s", eRank[RankName])
		replace_string(szHudInfo, charsmax(szHudInfo), "%rank%", blMaxLevel ? "%next_rank%" : szReplace)
	}

	if(contain(szHudInfo, "%next_xp%") != -1) {
		num_to_str(eNextRank[RankXp], szReplace, charsmax(szReplace))
		replace_string(szHudInfo, charsmax(szHudInfo), "%next_xp%", szReplace)
	}

	if(contain(szHudInfo, "%next_level%") != -1) {
		num_to_str(g_pPlayerData[iTarget][Level] + 2, szReplace, charsmax(szReplace))
		replace_string(szHudInfo, charsmax(szHudInfo), "%next_level%", szReplace)
	}
	
	if(contain(szHudInfo, "%next_rank%") != -1) {
		replace_string(szHudInfo, charsmax(szHudInfo), "%next_rank%", eNextRank[RankName])
	}
	
	if(contain(szHudInfo, "%max_levels%") != -1) {
		num_to_str(g_iRanks, szReplace, charsmax(szReplace))
		replace_string(szHudInfo, charsmax(szHudInfo), "%max_levels%", szReplace)
	}
	
	if(contain(szHudInfo, "%server_rank%") != -1) {
		num_to_str(g_pPlayerData[iTarget][RankID], szReplace, charsmax(szReplace))
		replace_string(szHudInfo, charsmax(szHudInfo), "%server_rank%", szReplace)
	}

	if(contain(szHudInfo, "%max_server_ranks%") != -1) {
		num_to_str(g_iRows, szReplace, charsmax(szReplace))
		replace_string(szHudInfo, charsmax(szHudInfo), "%max_server_ranks%", szReplace)
	}

	if(contain(szHudInfo, "%skill%") != -1) {
		formatex(szReplace, charsmax(szReplace), "%s", eSkill[SkillName])
		replace_string(szHudInfo, charsmax(szHudInfo), "%skill%", GetSkillRange(id) >= eLastSkill[SkillRange] ? "%next_skill%" : szReplace)
	}
	
	if(contain(szHudInfo, "%skill_range%") != -1) {
		formatex(szReplace, charsmax(szReplace), "%.2f", GetSkillRange(iTarget))
		replace_string(szHudInfo, charsmax(szHudInfo), "%skill_range%", szReplace)
	}
	
	if(contain(szHudInfo, "%next_skill%") != -1) {
		replace_string(szHudInfo, charsmax(szHudInfo), "%next_skill%", eNextSkill[SkillName])
	}
	
	if(contain(szHudInfo, "%next_skill_range%") != -1) {
		formatex(szReplace, charsmax(szReplace), "%.2f", eNextSkill[SkillRange])
		replace_string(szHudInfo, charsmax(szHudInfo), "%next_skill_range%", szReplace)
	}

	if(contain(szHudInfo, "%minutes%") != -1) {
		num_to_str(((get_user_time(iTarget, 1) / 60) % 60), szReplace, charsmax(szReplace))
		replace_string(szHudInfo, charsmax(szHudInfo), "%minutes%", szReplace)
	}

	if(contain(szHudInfo, "%seconds%") != -1) {
		num_to_str((get_user_time(iTarget, 1) % 60), szReplace, charsmax(szReplace))
		replace_string(szHudInfo, charsmax(szHudInfo), "%seconds%", szReplace)
	}

	if(contain(szHudInfo, "%newline%") != -1) {
		replace_string(szHudInfo, charsmax(szHudInfo), "%newline%", "^n")
	}

	switch(g_eSetting[HUD_TYPE]) {
		case 0: {
			set_hudmessage(iRed, iGreen, iBlue, flPosX, flPosY, 0, 0.1, 1.0, 0.1, 0.1, -1)
			ShowSyncHudMsg(id, g_iObject, szHudInfo)
		}
		case 1: {
			set_dhudmessage(iRed, iGreen, iBlue, flPosX, flPosY, 0, 0.1, 1.0, 0.1, 0.1)
			show_dhudmessage(id, szHudInfo)
		}
	}
}

public taskShowHud(id) {
	id -= TASK_HUD

	new iXp = g_iTotalXp[id]
	new iTeamXp = g_iTotalTeamXp[id]

	if(iXp != 0 && g_eSetting[XP_HUD_ENABLE]) {
		ShowHudMessage(id, iXp, false)
	}

	if(iTeamXp != 0 && g_eSetting[XP_HUD_TEAM_ENABLE]) {
		ShowHudMessage(id, iTeamXp, true)
	}
}

public CSGameRules_GoToIntermission() {
	new iPlayers[MAX_PLAYERS], iPnum
	get_players_ex(iPlayers, iPnum)

	for(new i; i < iPnum; i++) {
		MakeMapEnd(iPlayers[i])
		set_task(0.01, "taskDelayMapEnd", iPlayers[i], .flags = "b")
	}

	message_begin(MSG_ALL, SVC_FINALE)
	write_string("")
	message_end()

	return HC_CONTINUE
}

public taskDelayMapEnd(id) {
	static szTitle[MAX_RESOURCE_PATH_LENGTH]
	formatex(szTitle, charsmax(szTitle), "%L", id, "RSM_MATCH_END")
	show_motd(id, g_szMapend[id], szTitle)
}

public cmdTop15(id) {
	MakeTop15(id)
	set_task(0.01, "taskDelayTop15", id)
	return PLUGIN_HANDLED
}

public taskDelayTop15(id) {
	static szTitle[MAX_RESOURCE_PATH_LENGTH]
	formatex(szTitle, charsmax(szTitle), "%L", id, "RSM_TOP15_HEADER")
	show_motd(id, g_szTop15, szTitle)
}

public cmdHS15(id) {
	MakeHS15(id)
	set_task(0.01, "taskDelayHS15", id)
	return PLUGIN_HANDLED
}

public taskDelayHS15(id) {
	static szTitle[MAX_RESOURCE_PATH_LENGTH]
	formatex(szTitle, charsmax(szTitle), "%L", id, "RSM_HS15_HEADER")
	show_motd(id, g_szHS15, szTitle)
}

public cmdXp(id) {
	new eMaxRanks[RankInfo], iLevel
	for(new i = 1; i < g_iRanks - 1; i++) {
		ArrayGetArray(g_aRanks, i, eMaxRanks)

		if(g_pPlayerData[id][Xp] >= eMaxRanks[RankXp]) {
			iLevel++
		}
	}

	static eRank[RankInfo], eNextRank[RankInfo]
	ArrayGetArray(g_aRanks, iLevel, eRank)
	ArrayGetArray(g_aRanks, iLevel + 1, eNextRank)

	if(g_pPlayerData[id][Level] != g_iRanks -1) {
		CPC(id, "%L", id, "RSM_XP_INFO", g_pPlayerData[id][Level] + 1, eRank[RankName], g_pPlayerData[id][Xp], eNextRank[RankXp], eNextRank[RankName])
	}
	else {
		CPC(id, "%L", id, "RSM_XP_INFO_MAX", g_pPlayerData[id][Level] + 1, eNextRank[RankName], g_pPlayerData[id][Xp])
	}

	return PLUGIN_HANDLED
}

public cmdRank(id) {
	new iSkill, eMaxSkills[SkillInfo]
	for(new i = 1; i < g_iSkills; i++) {
		ArrayGetArray(g_aSkills, i, eMaxSkills)
		if(GetSkillRange(id) >= eMaxSkills[SkillRange]) {
			iSkill = i
		}
	}

	static eSkill[SkillInfo]
	ArrayGetArray(g_aSkills, iSkill, eSkill)
	CPC(id, "%L", id, "RSM_RANK_INFO", g_pPlayerData[id][RankID], g_iRows, g_pPlayerData[id][Kills], g_pPlayerData[id][Headshots], eSkill[SkillName], GetSkillRange(id))

	return PLUGIN_HANDLED
}

public cmdStats(id) {
	GetPlayerInfo(id)
	GetPlayerStats(id, id)
	formatex(g_szStatsTitle, charsmax(g_szStatsTitle), "%L", id, "RSM_STATS_HEADER")
	set_task(0.01, "taskDelayStats", id)

	return PLUGIN_HANDLED
}

public taskDelayStats(id) {
	show_motd(id, g_szStats, g_szStatsTitle)
}

public cmdGiveXP(id, iLevel, iCid) {
	if (!cmd_access(id, iLevel, iCid, 1)) {
		return PLUGIN_HANDLED
	}
	
	static szPlayer[MAX_PLAYERS], szXp[MAX_NUM_LENGTH]
	read_argv(1, szPlayer, charsmax(szPlayer))
	read_argv(2, szXp, charsmax(szXp))
	
	new iPlayer = cmd_target(id, szPlayer, 0)
	new iXp = str_to_num(szXp)

	if(!iPlayer) {
		return PLUGIN_HANDLED
	}
 
 	if(szXp[0] != '-') {
		client_print(id, print_console, "%L", id, "RSM_GIVE_XP_CONSOLE", iXp, iPlayer)
		CPC(0, "%L", id, "RSM_GIVE_XP", id, iXp, iPlayer)
	}
	else {
		client_print(id, print_console, "%L", id, "RSM_TAKE_XP_CONSOLE", iXp, iPlayer)
		CPC(0, "%L", id, "RSM_TAKE_XP", id, iXp, iPlayer)
	}

	UpdateXpAndRank(iPlayer, iXp, false)
	return PLUGIN_HANDLED
}

public cmdResetStats(id, iLevel, iCid) {
	if (!cmd_access(id, iLevel, iCid, 1)) {
		return PLUGIN_HANDLED
	}
	
	static szPlayer[MAX_PLAYERS]
	read_argv(1, szPlayer, charsmax(szPlayer))
	
	new iPlayer = cmd_target(id, szPlayer, 0)

	if(!iPlayer) {
		return PLUGIN_HANDLED
	}

	client_print(id, print_console, "%L", id, "RSM_RESET_STATS_CONSOLE", iPlayer)
	CPC(0, "%L", id, "RSM_RESET_STATS", id, iPlayer)

	ResetStats(iPlayer)
	UpdateRank(iPlayer)
	GetPlayerInfo(iPlayer)
	
	return PLUGIN_HANDLED
}

public cmdResetTable(id, iLevel, iCid) {
	if (!cmd_access(id, iLevel, iCid, 1)) {
		return PLUGIN_HANDLED
	}
	
	ResetMySQLTables()
	client_print(id, print_console, "%L", id, "RSM_RESET_TABLES")

	return PLUGIN_HANDLED
}

public menuStatsViewer(id) {
	new szItem[MAX_ITEM_LENGTH], iPlayers[MAX_PLAYERS], iPnum, eMaxSkills[SkillInfo], iSkill, eSkill[SkillInfo], szSkill[MAX_NUM_LENGTH], iOrderNum, szKey[5]
	static szTitle[MAX_ITEM_LENGTH], szOrder[MAX_RESOURCE_PATH_LENGTH]
	formatex(szTitle, charsmax(szTitle), "%L", id, "RSM_STATS_TITLE")

	new iMenu = menu_create(szTitle, "handlerStats")

	formatex(szOrder, charsmax(szOrder), "%L", id, "RSM_ORDER_BY", id, g_szOrder[g_iOrder[id]])
	menu_additem(iMenu, szOrder)
	menu_addblank(iMenu, 0)

	get_players_ex(iPlayers, iPnum)

	switch(g_iOrder[id]) {
		case ORDER_XP: 				SortCustom1D(iPlayers, iPnum, "SortPlayersByXp")
		case ORDER_KILLS: 			SortCustom1D(iPlayers, iPnum, "SortPlayersByTotalKills")
		case ORDER_MVPS: 			SortCustom1D(iPlayers, iPnum, "SortPlayersByMVPs")
		case ORDER_ROUNDS_WON: 		SortCustom1D(iPlayers, iPnum, "SortPlayersByRoundsWon")
		case ORDER_BOMBS_PLANTED: 	SortCustom1D(iPlayers, iPnum, "SortPlayersByBombsPlanted")
		case ORDER_BOMBS_DEFUSED: 	SortCustom1D(iPlayers, iPnum, "SortPlayersByBombsDefused")
		case ORDER_PLAYED_TIME: 	SortCustom1D(iPlayers, iPnum, "SortPlayersByPlayedTime")
		case ORDER_SKILL: 			SortCustom1D(iPlayers, iPnum, "SortPlayersBySkill")
	}

	for(new i; i < iPnum; i++) {
		switch(g_iOrder[id]) {
			case ORDER_XP: 				iOrderNum = g_pPlayerData[iPlayers[i]][Xp]
			case ORDER_KILLS: 			iOrderNum = g_pPlayerData[iPlayers[i]][Kills]
			case ORDER_MVPS: 			iOrderNum = g_pPlayerData[iPlayers[i]][MVP]
			case ORDER_ROUNDS_WON: 		iOrderNum = g_pPlayerData[iPlayers[i]][RoundsWon]
			case ORDER_BOMBS_PLANTED: 	iOrderNum = g_pPlayerData[iPlayers[i]][Planted]
			case ORDER_BOMBS_DEFUSED: 	iOrderNum = g_pPlayerData[iPlayers[i]][Defused]
			case ORDER_PLAYED_TIME: 	iOrderNum = g_pPlayerData[iPlayers[i]][PlayedTime]
			case ORDER_SKILL: {
				for(new j = 1; j < g_iSkills; j++) {
					ArrayGetArray(g_aSkills, j, eMaxSkills)
					if(GetSkillRange(iPlayers[i]) >= eMaxSkills[SkillRange])
					{
						iSkill = j
					}
				}

				if(!GetSkillRange(iPlayers[i])) {
					iSkill = 0
				}

				ArrayGetArray(g_aSkills, iSkill, eSkill)
				copy(szSkill, charsmax(szSkill), eSkill[SkillName])
			}
		}

		num_to_str(iPlayers[i], szKey, charsmax(szKey))

		switch(g_iOrder[id]) {
			case ORDER_PLAYED_TIME: formatex(szItem, charsmax(szItem), "\w%n \r[\y%d%L %d%L\r]", iPlayers[i], (iOrderNum + get_user_time(iPlayers[i], 1))/3600, id, "RSM_HOURS",((iOrderNum + get_user_time(iPlayers[i], 1))/60)%60, id, "RSM_MINUTES")
			case ORDER_SKILL: 		formatex(szItem, charsmax(szItem), "\w%n \r[\y%s %.2f\r]", iPlayers[i], szSkill, GetSkillRange(iPlayers[i]))
			default: 				formatex(szItem, charsmax(szItem), "\w%n \r[\y%d %L\r]", iPlayers[i], iOrderNum, id, g_szOrder[g_iOrder[id]])
		}

		menu_additem(iMenu, szItem, szKey)
	}
	
	if(menu_pages(iMenu) > 1) {
		static szPage[MAX_RESOURCE_PATH_LENGTH]
		formatex(szPage, charsmax(szPage), "%L", id, "RSM_STATS_PAGE")
		add(szTitle, charsmax(szTitle), szPage)
		menu_setprop(iMenu, MPROP_TITLE, szTitle)
	}

	menu_display(id, iMenu)
	return PLUGIN_HANDLED
}

public handlerStats(id, iMenu, iItem) {
	if(iItem == MENU_EXIT) {
		goto @MENU_DESTROY
	}
	
	if(!iItem) {
		if(g_iOrder[id] == MAX_ORDERS - 1) {
			g_iOrder[id] = 0
		}
		else g_iOrder[id]++

		menuStatsViewer(id)
		goto @MENU_DESTROY
	}

	static szData[MAX_NAME_LENGTH], iAccess, iCallback
	menu_item_getinfo(iMenu, iItem, iAccess, szData, charsmax(szData), .callback = iCallback)
	
	new iPlayer = str_to_num(szData)
	
	GetPlayerInfo(iPlayer)
	GetPlayerStats(iPlayer, id)
	menuStatsViewer(id)

	formatex(g_szStatsTitle, charsmax(g_szStatsTitle), "%L", id, iPlayer == id ? "RSM_STATS_HEADER" : "RSM_STATS_HEADER_PLAYER", iPlayer)
	set_task(0.01, "taskDelayStats", id)
	
	@MENU_DESTROY:
	menu_destroy(iMenu)
	return PLUGIN_HANDLED
}

public SortPlayersByXp(id1, id2) {
	return g_pPlayerData[id2][Xp] - g_pPlayerData[id1][Xp]
}

public SortPlayersByTotalKills(id1, id2) {
	return g_pPlayerData[id2][Kills] - g_pPlayerData[id1][Kills]
}

public SortPlayersByMVPs(id1, id2) {
	return g_pPlayerData[id2][MVP] - g_pPlayerData[id1][MVP]
}

public SortPlayersByRoundsWon(id1, id2) {
	return g_pPlayerData[id2][RoundsWon] - g_pPlayerData[id1][RoundsWon]
}

public SortPlayersByBombsPlanted(id1, id2) {
	return g_pPlayerData[id2][Planted] - g_pPlayerData[id1][Planted]
}

public SortPlayersByBombsDefused(id1, id2) {
	return g_pPlayerData[id2][Defused] - g_pPlayerData[id1][Defused]
}

public SortPlayersByPlayedTime(id1, id2) {
	return g_pPlayerData[id2][PlayedTime] - g_pPlayerData[id1][PlayedTime]
}

public SortPlayersBySkill(id1, id2) {
    return _:GetSkillRange(id2) - _:GetSkillRange(id1)
}

public ShowMVP() {	
	if(g_blMVP) {
		return
	}
	
	new iBest, iMostKills
	for(new i = 1; i < g_iMaxPlayers; i++) {
		if(g_iRoundKills[i] >= iMostKills) {
			iBest = i
			iMostKills = g_iRoundKills[i]
		}
	}
	
	if(iMostKills && is_user_valid(iBest)) {
		GetMVP(iBest, MOST_KILLS)
	}
}

public GetRows() {
	static szQuery[MAX_USER_INFO_LENGTH]
	formatex(szQuery, charsmax(szQuery), "SELECT COUNT(*) from `%s`;", g_eSetting[MYSQL_TABLE])
	SQL_ThreadQuery(g_iSqlTuple, "GetRows_QueryHandler", szQuery)
}

public GetRows_QueryHandler(iFailState, Handle:iQuery, szError[], iErrcode, iData[], iDataSize) {
	if(SQL_NumResults(iQuery)) {
		g_iRows = SQL_ReadResult(iQuery, 0)
	}
}

public MakeMapEnd(id) {
	new szHeader[MAX_DATA_LENGTH], szPlayers[MAX_USER_INFO_LENGTH], szSteamData[2][MAX_USER_INFO_LENGTH], szStats[MAX_USER_INFO_LENGTH], szMap[MAX_MAPNAME_LENGTH], iTeamWin, bool:blTable

	new iWinT = get_member_game(m_iNumTerroristWins)
	new iWinCT = get_member_game(m_iNumCTWins)

	if(iWinT > iWinCT) 			iTeamWin = TERR_WIN
	else if(iWinT == iWinCT) 	iTeamWin = ROUND_DRAW
	else if(iWinT < iWinCT) 	iTeamWin = CTs_WIN

	static szMapEndLink[MAX_USER_INFO_LENGTH]
	if(IsUserSteam(id)) copy(szMapEndLink, charsmax(szMapEndLink), g_eSetting[HTTP_MAPEND_LINK])
	else 				copy(szMapEndLink, charsmax(szMapEndLink), g_eSetting[HTTP_MAPEND_LINK2])

	get_mapname(szMap, charsmax(szMap))
	formatex(g_szMapend[id], charsmax(g_szMapend[]), "<meta charset=^"utf-8^"/><link rel='stylesheet' href='%s'>", szMapEndLink)
	formatex(szHeader, charsmax(szHeader), "<table id=t2><tr><th id=th1>%L<hr id=hr1><tr><th id=th2>%L:<div id=th3>%s<hr id=hr3></table><table id=t4><tr><th id=th%i><p>%L</table><table id=t1><tr><th><th>\
	<th id=t>%L<th id=k><th id=d><th>%L<th id=m><th id=r>%L", LANG_SERVER, "RSM_MATCH_END", LANG_SERVER, "RSM_MAP", szMap, g_eTeamWin[iTeamWin][TableId], LANG_SERVER, g_eTeamWin[iTeamWin][TeamLang],
	LANG_SERVER, "RSM_MATCH_TOP", LANG_SERVER, "RSM_KD", LANG_SERVER, "RSM_RANK_C")
	add(g_szMapend[id], charsmax(g_szMapend[]), szHeader)

	new iPlayers[MAX_PLAYERS], iPnum
	get_players_ex(iPlayers, iPnum)
	SortCustom1D(iPlayers, iPnum, "SortPlayersByKills")

	for(new i; i < 5; i++) {
		if(i == iPnum) {
			break
		}

		new iKills = floatround(get_entvar(iPlayers[i], var_frags))
		new iDeaths = get_member(iPlayers[i], m_iDeaths)

		new szPosition[4][MAX_NAME_LENGTH]
		formatex(szPosition[0], charsmax(szPosition[]), " id=z>")
		formatex(szPosition[1], charsmax(szPosition[]), " id=w>")
		formatex(szPosition[2], charsmax(szPosition[]), " id=y>")
		formatex(szPosition[3], charsmax(szPosition[]), " id=p>%d", i + 1)

		GetSteamInfo(iPlayers[i], szSteamData, charsmax(szSteamData[]))

		if(blTable) {
			blTable = false
			formatex(szPlayers, charsmax(szPlayers), "<tr id=b><td%s<td id=g><img src='%s'/><td><p>%n<td>%d<td>%d<td>%.1f<td id=s>★<p>%i<td id=r%i>", i < 4 ? szPosition[i] : szPosition[3],
			szSteamData[STEAM_AVATAR], iPlayers[i], iKills, iDeaths, (float(iKills) / float(iDeaths)), g_pMapData[iPlayers[i]][MAP_MVP], g_pPlayerData[iPlayers[i]][Level] + 1)
		}
		else {
			blTable = true
			formatex(szPlayers, charsmax(szPlayers), "<tr><td%s<td id=g><img src='%s'/><td><p>%n<td>%d<td>%d<td>%.1f<td id=s>★<p>%i<td id=r%i>", i < 4 ? szPosition[i] : szPosition[3],
			szSteamData[STEAM_AVATAR], iPlayers[i], iKills, iDeaths, (float(iKills) / float(iDeaths)), g_pMapData[iPlayers[i]][MAP_MVP], g_pPlayerData[iPlayers[i]][Level] + 1)
		}

		add(g_szMapend[id], charsmax(g_szMapend[]), szPlayers)
	}

	formatex(szStats, charsmax(szStats), "</table><hr id=hr2><table id=t3><tr><th id=th4>%L<tr><td id=td2>%L<div id=td3>%d<tr><td id=td2>%L<div id=td3>%d<tr><td id=td2>\
	%L<div id=td3>%s%d %L", LANG_SERVER, "RSM_MATCH_STATS", LANG_SERVER, "RSM_TOTAL_KILLS", floatround(get_entvar(id, var_frags)), LANG_SERVER, "RSM_TOTAL_DEATHS", get_member(id, m_iDeaths),
	LANG_SERVER, "RSM_XP_ACQUIRED", g_pMapData[id][MAP_XP] >= 0 ? "+" : "", g_pMapData[id][MAP_XP], LANG_SERVER, "RSM_XP")
	add(g_szMapend[id], charsmax(g_szMapend[]), szStats)
}

public SortPlayersByKills(id1, id2) {
	new iKills2 = floatround(get_entvar(id2, var_frags))
	new iKills1 = floatround(get_entvar(id1, var_frags))
	new iDeaths2 = get_member(id2, m_iDeaths)
	new iDeaths1 = get_member(id1, m_iDeaths)

	if(iKills1 > iKills2 || iKills1 == iKills2 && iDeaths1 < iDeaths2) 		return -1
	else if(iKills1 < iKills2 || iKills1 == iKills2 && iDeaths1 > iDeaths2) return 1
	return 0
}

public MakeTop15(id) {	
	new iData[1]; iData[0] = id
	static szQuery[MAX_USER_INFO_LENGTH]
	formatex(szQuery, charsmax(szQuery), "SELECT Nick, XP, Level, Kills, Assists, Deaths, Planted, Defused FROM `%s` ORDER BY XP DESC LIMIT 15;", g_eSetting[MYSQL_TABLE])
	SQL_ThreadQuery(g_iSqlTuple, "MakeTop15_QueryHandler", szQuery, iData, sizeof(iData))
}

public MakeTop15_QueryHandler(iFailState, Handle:iQuery, szError[], iErrcode, iData[], iDataSize) {
	new szName[MAX_NAME_LENGTH], szHeader[MAX_USER_INFO_LENGTH], iXp, iKills, iAssists, iDeaths, iPlanted, iDefused, iRank, i = 1, szTable[MAX_USER_INFO_LENGTH], bool:blTable

	static szTop15Link[MAX_USER_INFO_LENGTH]
	if(IsUserSteam(iData[0])) 	copy(szTop15Link, charsmax(szTop15Link), g_eSetting[HTTP_TOP15_LINK])
	else 						copy(szTop15Link, charsmax(szTop15Link), g_eSetting[HTTP_TOP15_LINK2])

	formatex(g_szTop15, charsmax(g_szTop15), "<meta charset=^"utf-8^"/><link rel='stylesheet' href='%s'>", szTop15Link)
	formatex(szHeader, charsmax(szHeader), "<table><tr id=a><th>%L<th>%L<th>%L<th>%L<th>%L<th id=c><th id=d><th>%L<th>%L", LANG_SERVER, "RSM_TOP", LANG_SERVER, "RSM_NAME", LANG_SERVER, "RSM_KILLS_C",
	LANG_SERVER, "RSM_ASSISTS", LANG_SERVER, "RSM_DEATHS", LANG_SERVER, "RSM_XP", LANG_SERVER, "RSM_RANK_C")
	add(g_szTop15, charsmax(g_szTop15), szHeader)

	while(SQL_MoreResults(iQuery)) {
		SQL_ReadResult(iQuery, 0, szName, charsmax(szName))

		replace_all(szName, charsmax(szName), "<", "[")
		replace_all(szName, charsmax(szName), ">", "]")

		iXp = 		SQL_ReadResult(iQuery, 1)
		iRank = 	SQL_ReadResult(iQuery, 2)
		iKills = 	SQL_ReadResult(iQuery, 3)
		iAssists =  SQL_ReadResult(iQuery, 4)
		iDeaths = 	SQL_ReadResult(iQuery, 5)
		iPlanted = 	SQL_ReadResult(iQuery, 6)
		iDefused = 	SQL_ReadResult(iQuery, 7)
		
		new szPosition[4][MAX_NAME_LENGTH]
		formatex(szPosition[0], charsmax(szPosition[]), ">%d", i)
		formatex(szPosition[1], charsmax(szPosition[]), " id=z>")
		formatex(szPosition[2], charsmax(szPosition[]), " id=w>")
		formatex(szPosition[3], charsmax(szPosition[]), " id=y>")

		if(blTable) {
			blTable = false
			formatex(szTable, charsmax(szTable), "<tr id=b><td%s<td><p>%s<td>%d<td>%d<td>%d<td>%d<td>%d<td>%d<td id=r%i>", i < 4 ? szPosition[i] : szPosition[0], szName, iKills, iAssists, iDeaths,
			iPlanted, iDefused, iXp, iRank + 1)
		}
		else {
			blTable = true
			formatex(szTable, charsmax(szTable), "<tr><td%s<td><p>%s<td>%d<td>%d<td>%d<td>%d<td>%d<td>%d<td id=r%i>", i < 4 ? szPosition[i] : szPosition[0], szName, iKills, iAssists, iDeaths, iPlanted,
			iDefused, iXp, iRank + 1)
		}
		
		add(g_szTop15, charsmax(g_szTop15), szTable)
		
		i++	
		SQL_NextRow(iQuery)
	}
}

public MakeHS15(id) {	
	new iData[1]; iData[0] = id
	static szQuery[MAX_USER_INFO_LENGTH]
	formatex(szQuery, charsmax(szQuery), "SELECT Nick, Headshots, Kills, Deaths, MVP, `Rounds Won` FROM `%s` ORDER BY Headshots DESC LIMIT 15;", g_eSetting[MYSQL_TABLE])
	SQL_ThreadQuery(g_iSqlTuple, "MakeHS15_QueryHandler", szQuery, iData, sizeof(iData))
}

public MakeHS15_QueryHandler(iFailState, Handle:iQuery, szError[], iErrcode, iData[], iDataSize) {
	new szName[MAX_NAME_LENGTH], szHeader[MAX_USER_INFO_LENGTH], iHS, iKills, iDeaths, iMVP, iRoundsWon, eMaxSkills[SkillInfo], szTable[MAX_USER_INFO_LENGTH], bool:blTable, i = 1

	static szHs15Link[MAX_USER_INFO_LENGTH]
	if(IsUserSteam(iData[0])) 	copy(szHs15Link, charsmax(szHs15Link), g_eSetting[HTTP_HS15_LINK])
	else 						copy(szHs15Link, charsmax(szHs15Link), g_eSetting[HTTP_HS15_LINK2])

	formatex(g_szHS15, charsmax(g_szHS15), "<meta charset=^"utf-8^"/><link rel='stylesheet' href='%s'>", szHs15Link)
	formatex(szHeader, charsmax(szHeader), "<table><tr id=a><th>%L<th>%L<th>%L<th>%L<th id=c><th id=f><th>%L", LANG_SERVER, "RSM_TOP", LANG_SERVER, "RSM_NAME", LANG_PLAYER, "RSM_HEADSHOTS",
	LANG_SERVER, "RSM_HS_PERCENTAGE", LANG_SERVER, "RSM_SKILL")
	add(g_szHS15, charsmax(g_szHS15), szHeader)

	while(SQL_MoreResults(iQuery)) {
		SQL_ReadResult(iQuery, 0, szName, charsmax(szName))

		replace_all(szName, charsmax(szName), "<", "[")
		replace_all(szName, charsmax(szName), ">", "]")

		iHS = 			SQL_ReadResult(iQuery, 1)
		iKills = 		SQL_ReadResult(iQuery, 2)
		iDeaths = 		SQL_ReadResult(iQuery, 3)
		iMVP = 			SQL_ReadResult(iQuery, 4)
		iRoundsWon = 	SQL_ReadResult(iQuery, 5)

		new iSkill
		new Float:flSkillRange = (100.0 * float(iKills) / (float(iKills) + float(iDeaths)))
		for(new j = 1; j < g_iSkills; j++) {
			ArrayGetArray(g_aSkills, j, eMaxSkills)

			if(flSkillRange >= eMaxSkills[SkillRange]) {
				iSkill = j
			}
		}

		if(!flSkillRange) {
			iSkill = 0
		}

		new eSkill[SkillInfo]
		ArrayGetArray(g_aSkills, iSkill, eSkill)

		new Float:flHsPrecentage = (100.0 * float(iHS) / float(iKills))

		new szPosition[4][MAX_NAME_LENGTH]
		formatex(szPosition[0], charsmax(szPosition[]), ">%d", i)
		formatex(szPosition[1], charsmax(szPosition[]), " id=z>")
		formatex(szPosition[2], charsmax(szPosition[]), " id=w>")
		formatex(szPosition[3], charsmax(szPosition[]), " id=y>")

		if(blTable) {
			blTable = false
			formatex(szTable, charsmax(szTable), "<tr id=b><td%s<td><p>%s<td>%d<td>%.2f%%<td>%d<td>%d<td><div id=e>%s<a>%.2f", i < 4 ? szPosition[i] : szPosition[0], szName, iHS, flHsPrecentage, iMVP,
			iRoundsWon, eSkill[SkillName], flSkillRange)
		}
		else {
			blTable = true
			formatex(szTable, charsmax(szTable), "<tr><td%s<td><p>%s<td>%d<td>%.2f%%<td>%d<td>%d<td><div id=e>%s<a>%.2f", i < 4 ? szPosition[i] : szPosition[0], szName, iHS, flHsPrecentage, iMVP,
			iRoundsWon, eSkill[SkillName], flSkillRange)
		}
		
		add(g_szHS15, charsmax(g_szHS15), szTable)
		
		i++	
		SQL_NextRow(iQuery)
	}
}

ResetMySQLTables() {
	static szQuery[2][MAX_USER_INFO_LENGTH]
	formatex(szQuery[0], charsmax(szQuery[]), "TRUNCATE TABLE `%s`;", g_eSetting[MYSQL_TABLE])
	formatex(szQuery[1], charsmax(szQuery[]), "TRUNCATE TABLE `%s`;", g_eSetting[MYSQL_TABLE2])

	SQL_ThreadQuery(g_iSqlTuple, "QueryHandler", szQuery[0])
	SQL_ThreadQuery(g_iSqlTuple, "QueryHandler", szQuery[1])

	new iPlayers[MAX_PLAYERS], iPnum
	get_players_ex(iPlayers, iPnum)

	for(new i; i < iPnum; i++) {
		ResetStats(iPlayers[i])

		for(new j; j < MAX_WEAPONS_EX; j++) {
			g_iWeaponKills[iPlayers[i]][j] = 0
		}

		for(new j; j < 5; j++) {
			g_iTop5Weapons[iPlayers[i]][WEAPON_ID][j] = 0
			g_iTop5Weapons[iPlayers[i]][WEAPON_KILLS][j] = 0
		}
	}
}

public GetPlayerRank(id) {
	new iData[1]; iData[0] = id
	static szQuery[MAX_USER_INFO_LENGTH], szPlayer[MAX_NAME_LENGTH * 2]
	SQL_QuoteString(Empty_Handle, szPlayer, charsmax(szPlayer), g_szSaveInfo[id])

	formatex(szQuery, charsmax(szQuery), "SELECT * FROM (SELECT @rank := @rank + 1 as Level, XP, Player FROM `%s`, (SELECT @rank := 0) r ORDER BY XP DESC) k WHERE k.Player='%s';",
	g_eSetting[MYSQL_TABLE], szPlayer)
	SQL_ThreadQuery(g_iSqlTuple, "GetPlayerRank_QueryHandler", szQuery, iData, sizeof(iData))
}

public GetPlayerRank_QueryHandler(iFailState, Handle:iQuery, szError[], iErrcode, iData[], iDataSize) {
	new id = iData[0]
	if(SQL_NumResults(iQuery)) {
		g_pPlayerData[id][RankID] = SQL_ReadResult(iQuery, 0)
	}
}

public SqlSaveOrLoad(id, iType) {	
	static szQuery[MAX_DATA_LENGTH], szPlayer[2][MAX_NAME_LENGTH * 2]
	SQL_QuoteString(Empty_Handle, szPlayer[0], charsmax(szPlayer[]), g_szSaveInfo[id])

	switch(iType) {
		case MYSQL_SAVE: {
			static szName[MAX_NAME_LENGTH]
			get_user_name(id, szName, charsmax(szName))
			SQL_QuoteString(Empty_Handle, szPlayer[1], charsmax(szPlayer[]), szName)

			formatex(szQuery, charsmax(szQuery), "REPLACE INTO `%s` (Player, Nick, XP, Level, Kills, Deaths, Headshots, Assists, Shots, Hits, Damage, Planted, Defused, MVP, `Rounds Won`, `Played Time`)\
			VALUES ('%s', '%s', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i');",
			g_eSetting[MYSQL_TABLE], szPlayer[0], szPlayer[1], g_pPlayerData[id][Xp], g_pPlayerData[id][Level], g_pPlayerData[id][Kills], g_pPlayerData[id][Deaths], g_pPlayerData[id][Headshots],
			g_pPlayerData[id][Assists], g_pPlayerData[id][Shots], g_pPlayerData[id][Hits], g_pPlayerData[id][Damage], g_pPlayerData[id][Planted], g_pPlayerData[id][Defused], g_pPlayerData[id][MVP],
			g_pPlayerData[id][RoundsWon], (g_pPlayerData[id][PlayedTime] + get_user_time(id)))
			
			SQL_ThreadQuery(g_iSqlTuple, "QueryHandler", szQuery)
		}
		case MYSQL_LOAD: {
			new iData[1]; iData[0] = id
			formatex(szQuery, charsmax(szQuery), "SELECT XP, Level, Kills, Deaths, Headshots, Assists, Shots, Hits, Damage, Planted, Defused, MVP, `Rounds Won`, `Played Time` FROM `%s` WHERE Player = '%s';",
			g_eSetting[MYSQL_TABLE], szPlayer[0])
			SQL_ThreadQuery(g_iSqlTuple, "LoadPoints_QueryHandler", szQuery, iData, sizeof(iData))
		}
	}
}

public LoadPoints_QueryHandler(iFailState, Handle:iQuery, szError[], iErrcode, iData[], iDataSize) {
	new id = iData[0]
	if(SQL_NumResults(iQuery)) {
		g_pPlayerData[id][Xp] = 			SQL_ReadResult(iQuery, 0)
		g_pPlayerData[id][Level] = 			SQL_ReadResult(iQuery, 1)
		g_pPlayerData[id][Kills] = 			SQL_ReadResult(iQuery, 2)
		g_pPlayerData[id][Deaths] = 		SQL_ReadResult(iQuery, 3)
		g_pPlayerData[id][Headshots] = 		SQL_ReadResult(iQuery, 4)
		g_pPlayerData[id][Assists] = 		SQL_ReadResult(iQuery, 5)
		g_pPlayerData[id][Shots] = 			SQL_ReadResult(iQuery, 6)
		g_pPlayerData[id][Hits] = 			SQL_ReadResult(iQuery, 7)
		g_pPlayerData[id][Damage] = 		SQL_ReadResult(iQuery, 8)
		g_pPlayerData[id][Planted] = 		SQL_ReadResult(iQuery, 9)
		g_pPlayerData[id][Defused] = 		SQL_ReadResult(iQuery, 10)
		g_pPlayerData[id][MVP] = 			SQL_ReadResult(iQuery, 11)
		g_pPlayerData[id][RoundsWon] = 		SQL_ReadResult(iQuery, 12)
		g_pPlayerData[id][PlayedTime] = 	SQL_ReadResult(iQuery, 13)
	}

	g_blLoaded[id] = true
	GetPlayerInfo(id)
}

public SqlSaveOrLoadKills(id, iType) {	
	static szQuery[2][MAX_USER_INFO_LENGTH], szPlayer[MAX_NAME_LENGTH * 2]
	SQL_QuoteString(Empty_Handle, szPlayer, charsmax(szPlayer), g_szSaveInfo[id])

	switch(iType) {
		case MYSQL_SAVE: {
			formatex(szQuery[0], charsmax(szQuery[]), "DELETE FROM `%s` WHERE Player = '%s';", g_eSetting[MYSQL_TABLE2], szPlayer)
			SQL_ThreadQuery(g_iSqlTuple, "QueryHandler", szQuery[0])

			for(new i; i < MAX_WEAPONS_EX; i++) {
				formatex(szQuery[1], charsmax(szQuery[]), "REPLACE INTO `%s` (Player, `Weapon ID`, `Weapon Kills`) VALUES ('%s', '%i', '%i');", g_eSetting[MYSQL_TABLE2], szPlayer, i,
				g_iWeaponKills[id][i])
				SQL_ThreadQuery(g_iSqlTuple, "QueryHandler", szQuery[1])
			}
		}
		case MYSQL_LOAD: {
			new iData[1]; iData[0] = id
			formatex(szQuery[0], charsmax(szQuery[]), "SELECT `Weapon Kills` FROM `%s` WHERE Player = '%s' ORDER BY `Weapon ID` ASC;", g_eSetting[MYSQL_TABLE2], szPlayer)
			SQL_ThreadQuery(g_iSqlTuple, "LoadKills_QueryHandler", szQuery[0], iData, sizeof(iData))
		}
	}
}

public LoadKills_QueryHandler(iFailState, Handle:iQuery, szError[], iErrcode, iData[], iDataSize) {
	new id = iData[0], i
	if(SQL_NumResults(iQuery)) {
		while(SQL_MoreResults(iQuery)) {
			g_iWeaponKills[id][i] = SQL_ReadResult(iQuery, 0)
			i++
			SQL_NextRow(iQuery)
		}
	}
}

public taskResetXp(id) {
	id -= TASK_RESETXP
	g_iTotalXp[id] = 0
}

public taskResetTeamXp(id) {
	id -= TASK_TEAM_XP
	g_iTotalTeamXp[id] = 0
}

GetMVP(const id, iType) {
	if(!is_user_connected(id)) {
		return  
	}

	g_blMVP = true
	g_pPlayerData[id][MVP]++
	g_pMapData[id][MAP_MVP]++

	if(g_eSetting[MVP_HUD_ENABLE]) {
		new iArg[1]; iArg[0] = iType
		set_task(0.1, "taskShowMVP", id, iArg, sizeof(iArg))
	}
}

public taskShowMVP(iArg[1], id) {
	if(!g_blMVP) {
		return
	}

	new iRed = 			floatround(g_eSetting[MVP_HUD_VALUES][HUD_COLOR1])
	new iGreen = 		floatround(g_eSetting[MVP_HUD_VALUES][HUD_COLOR2])
	new iBlue = 		floatround(g_eSetting[MVP_HUD_VALUES][HUD_COLOR3])
	new Float:flPosX = 	g_eSetting[MVP_HUD_VALUES][HUD_POS_X]
	new Float:flPosY = 	g_eSetting[MVP_HUD_VALUES][HUD_POS_Y]

	if(iRed < 0) 	iRed = 		random(256)
	if(iGreen < 0) 	iGreen = 	random(256)
	if(iBlue < 0) 	iBlue = 	random(256)

	static szHudMessage[MAX_DATA_LENGTH]
	switch(iArg[0]) {
		case MOST_KILLS: 	formatex(szHudMessage, charsmax(szHudMessage), "%L", id, "RSM_MVP_MOST_KILLS", id, g_iRoundKills[id], g_iRoundHs[id])
		case BOMB_EXPLODE: 	formatex(szHudMessage, charsmax(szHudMessage), "%L", id, "RSM_MVP_BOMB_EXPLODE", id)
		case BOMB_DEFUSE: 	formatex(szHudMessage, charsmax(szHudMessage), "%L", id, "RSM_MVP_BOMB_DEFUSE", id)
	}

	switch(g_eSetting[MVP_HUD_TYPE]) {
		case 0: {
			set_hudmessage(iRed, iGreen, iBlue, flPosX, flPosY, .holdtime = 1.0)
			show_hudmessage(0, szHudMessage)
		}
		case 1: {
			set_dhudmessage(iRed, iGreen, iBlue, flPosX, flPosY, .holdtime = 1.0)
			show_dhudmessage(0, szHudMessage)
		}
	}

	set_task(1.0, "taskShowMVP", id, iArg, sizeof(iArg))
}

GetPlayerStats(const id, const id2) {
	new eMaxRanks[RankInfo], eMaxSkills[SkillInfo], iLevel, iSkill
	for(new i = 1; i < g_iRanks - 1; i++) {
		ArrayGetArray(g_aRanks, i, eMaxRanks)

		if(g_pPlayerData[id][Xp] >= eMaxRanks[RankXp]) {
			iLevel++
		}
	}

	static eRank[RankInfo], eNextRank[RankInfo]
	ArrayGetArray(g_aRanks, iLevel, eRank)
	ArrayGetArray(g_aRanks, iLevel + 1, eNextRank)

	for(new i = 1; i < g_iSkills; i++) {
		ArrayGetArray(g_aSkills, i, eMaxSkills)
		if(GetSkillRange(id) >= eMaxSkills[SkillRange]) {
			iSkill = i
		}
	}

	static eSkill[SkillInfo]
	ArrayGetArray(g_aSkills, iSkill, eSkill)

	static szSteamData[2][MAX_USER_INFO_LENGTH], szSteamDiv[MAX_USER_INFO_LENGTH + MAX_NAME_LENGTH]
	GetSteamInfo(id, szSteamData, charsmax(szSteamData[]))
	formatex(szSteamDiv, charsmax(szSteamDiv), "<div id=s onclick=location.href='%s'><a>%L</a></div>", szSteamData[STEAM_PROFILE_URL], id, "RSM_PROFILE")

	static szIP[MAX_IP_LENGTH], szCode[3], szCity[MAX_NAME_LENGTH], szCountry[MAX_NAME_LENGTH]
	get_user_ip(id, szIP, charsmax(szIP))
	formatex(szCode, charsmax(szCode), "nn")
	geoip_code2_ex(szIP, szCode); strtolower(szCode)
	geoip_city(szIP, szCity, charsmax(szCity))
	geoip_country_ex(szIP, szCountry, charsmax(szCountry))
	if(szCity[0] != EOS && szCountry[0] != EOS) add(szCity, charsmax(szCity), ",")
	else if(szCity[0] == EOS && szCountry[0] == EOS) add(szCity, charsmax(szCity), "n/a")

	new iProgressXp = (100 * (g_pPlayerData[id][Xp] - eRank[RankXp]) / (eNextRank[RankXp] - eRank[RankXp]))
	new iHours = ((g_pPlayerData[id][PlayedTime] + get_user_time(id, 1)) / 3600)
	new iMinutes = (((g_pPlayerData[id][PlayedTime] + get_user_time(id, 1)) / 60) % 60)
	new Float:flKdRatio = (float(g_pPlayerData[id][Kills]) / float(g_pPlayerData[id][Deaths]))
	new Float:flHsPrecentage = (100.0 * float(g_pPlayerData[id][Headshots]) / float(g_pPlayerData[id][Kills]))
	new Float:flAcurracy = (100.0 * float(g_pPlayerData[id][Hits]) / float(g_pPlayerData[id][Shots]))
	new Float:flEfficiency = (100.0 * float(g_pPlayerData[id][Kills]) / float(g_pPlayerData[id][Kills] + g_pPlayerData[id][Deaths]))

	static szStatsLink[MAX_USER_INFO_LENGTH]
	if(IsUserSteam(id2)) 	copy(szStatsLink, charsmax(szStatsLink), g_eSetting[HTTP_STATS_LINK])
	else 					copy(szStatsLink, charsmax(szStatsLink), g_eSetting[HTTP_STATS_LINK2])

	if(g_pPlayerData[id][Level] != g_iRanks - 1) {
		formatex(g_szStats, charsmax(g_szStats), "<meta charset=^"utf-8^"/><link rel='stylesheet' href='%s'><table><td id=a><div id=d><img src='%s'/><div id=%s><div id=u>%s %s</div><div id=f>%n<div id=g>\
		%L %d %L %d</div></div></div><div id=sk1>%s<a>%.2f</a></div>%s</div><div id=c><div id=r%d><a>%L</a></div><style>#c #h #j::before {width: %d%%}</style><div id=h><p id=i>%L %d<p id=j><p id=k>\
		%L: %d/%d</div><div id=rn%d><a>%L</a></div></div><div id=c><p id=mv>%L<a id=g>%d</a><p id=rw>%L<a id=g>%d</a><p id=bi>%L<a id=g>%d</a><p id=di>%L<a id=g>%d</a><p id=pd>%L<a id=g>%d%L %d%L</a>\
		</div></td><td id=n><div id=d><div id=f>%L</div></div><div id=l><p>%L<a>%d</a><p>%L<a>%d</a><p>%L<a>%d</a><p>%L<a>%d</a><p>%L<a>%.1f</a></div><div id=l><p>%L<a>%.1f %%</a><p>%L<a>%.1f %%</a><p>\
		%L<a>%.1f %%</a></div><div id=l><p>%L<a>%d</a><p>%L<a>%d</a><p>%L<a>%d</a></div></td><td id=o><div id=d><div id=f>%L</div></div><div id=m><p>%L<div id=w%d>%d %L</div></div><div id=m><p>%L\
		<div id=w%d>%d %L</div></div><div id=m><p>%L<div id=w%d>%d %L</div></div><div id=m><p>%L<div id=w%d>%d %L</div></div><div id=m><p>%L<div id=w%d>%d %L", szStatsLink, szSteamData[STEAM_AVATAR], 
		szCode, szCity, szCountry, id, id2, "RSM_RANK", g_pPlayerData[id][RankID], id2, "RSM_FROM", g_iRows, eSkill[SkillName], GetSkillRange(id), IsUserSteam(id) ? szSteamDiv : "",
		g_pPlayerData[id][Level] + 1, id2, "RSM_CURRENT", iProgressXp, id2, "RSM_RANK_C", g_pPlayerData[id][Level] + 1, id2, "RSM_XP", g_pPlayerData[id][Xp], eNextRank[RankXp],
		g_pPlayerData[id][Level] + 2, id2, "RSM_NEXT", id2, "RSM_MVP", g_pPlayerData[id][MVP], id2, "RSM_ROUNDS_WON", g_pPlayerData[id][RoundsWon], id2, "RSM_BOMBS_PLANTED", g_pPlayerData[id][Planted],
		id2, "RSM_BOMBS_DEFUSED", g_pPlayerData[id][Defused], id2, "RSM_PLAYED_TIME", iHours, id2, "RSM_HOURS", iMinutes, id2, "RSM_MINUTES", id2, "RSM_STATISTICS", id2, "RSM_KILLS_C",
		g_pPlayerData[id][Kills], id2, "RSM_DEATHS", g_pPlayerData[id][Deaths], id2, "RSM_HEADSHOTS", g_pPlayerData[id][Headshots], id2, "RSM_ASSISTS", g_pPlayerData[id][Assists], id2, "RSM_KD_RATIO",
		flKdRatio, id2, "RSM_HS_PERCENTAGE", flHsPrecentage, id2, "RSM_ACCURACY", flAcurracy, id2, "RSM_EFFICIENCY", flEfficiency, id2, "RSM_SHOTS", g_pPlayerData[id][Shots], id2, "RSM_HITS",
		g_pPlayerData[id][Hits], id2, "RSM_DAMAGE", g_pPlayerData[id][Damage], id2, "RSM_FAV_WEAPON", id, g_eWeapon[g_iTop5Weapons[id][WEAPON_ID][0]][LangName], g_iTop5Weapons[id][WEAPON_ID][0],
		g_iTop5Weapons[id][WEAPON_KILLS][0], id2, "RSM_KILLS", id, g_eWeapon[g_iTop5Weapons[id][WEAPON_ID][1]][LangName], g_iTop5Weapons[id][WEAPON_ID][1], g_iTop5Weapons[id][WEAPON_KILLS][1], id2,
		"RSM_KILLS", id, g_eWeapon[g_iTop5Weapons[id][WEAPON_ID][2]][LangName], g_iTop5Weapons[id][WEAPON_ID][2], g_iTop5Weapons[id][WEAPON_KILLS][2], id2, "RSM_KILLS", id,
		g_eWeapon[g_iTop5Weapons[id][WEAPON_ID][3]][LangName], g_iTop5Weapons[id][WEAPON_ID][3], g_iTop5Weapons[id][WEAPON_KILLS][3], id2, "RSM_KILLS", id,
		g_eWeapon[g_iTop5Weapons[id][WEAPON_ID][4]][LangName], g_iTop5Weapons[id][WEAPON_ID][4], g_iTop5Weapons[id][WEAPON_KILLS][4], id2, "RSM_KILLS")
	}
	else
	{
		formatex(g_szStats, charsmax(g_szStats), "<meta charset=^"utf-8^"/><link rel='stylesheet' href='%s'><table><td id=a><div id=d><img src='%s'/><div id=%s><div id=u>%s %s</div><div id=f>%n<div id=g>\
		%L %d %L %d</div></div></div><div id=sk1>%s<a>%.2f</a></div>%s</div><div id=c><div id=r%d><a>%L</a></div><style>#c #h #j::before {width: 0%}</style><div id=h><p id=i>%L %d<p id=j><p id=k>%L: %d\
		</div></div><div id=c><p id=mv>%L<a id=g>%d</a><p id=rw>%L<a id=g>%d</a><p id=bi>%L<a id=g>%d</a><p id=di>%L<a id=g>%d</a><p id=pd>%L<a id=g>%d%L %d%L</a></div></td><td id=n><div id=d><div id=f>\
		%L</div></div><div id=l><p>%L<a>%d</a><p>%L<a>%d</a><p>%L<a>%d</a><p>%L<a>%d</a><p>%L<a>%.1f</a></div><div id=l><p>%L<a>%.1f %%</a><p>%L<a>%.1f %%</a><p>%L<a>%.1f %%</a></div><div id=l><p>%L<a>%d\
		</a><p>%L<a>%d</a><p>%L<a>%d</a></div></td><td id=o><div id=d><div id=f>%L</div></div><div id=m><p>%L<div id=w%d>%d %L</div></div><div id=m><p>%L<div id=w%d>%d %L</div></div><div id=m><p>%L\
		<div id=w%d>%d %L</div></div><div id=m><p>%L<div id=w%d>%d %L</div></div><div id=m><p>%L<div id=w%d>%d %L", szStatsLink, szSteamData[STEAM_AVATAR], szCode, szCity, szCountry, id, id2, "RSM_RANK", 
		g_pPlayerData[id][RankID], id2, "RSM_FROM", g_iRows, eSkill[SkillName], GetSkillRange(id), IsUserSteam(id) ? szSteamDiv : "", g_pPlayerData[id][Level] + 1, id2, "RSM_CURRENT", id2, "RSM_RANK_C",
		g_pPlayerData[id][Level] + 1, id2, "RSM_XP", g_pPlayerData[id][Xp], id2, "RSM_MVP", g_pPlayerData[id][MVP], id2, "RSM_ROUNDS_WON", g_pPlayerData[id][RoundsWon], id2, "RSM_BOMBS_PLANTED",
		g_pPlayerData[id][Planted], id2, "RSM_BOMBS_DEFUSED", g_pPlayerData[id][Defused], id2, "RSM_PLAYED_TIME", iHours, id2, "RSM_HOURS", iMinutes, id2, "RSM_MINUTES", id2, "RSM_STATISTICS", id2,
		"RSM_KILLS_C", g_pPlayerData[id][Kills], id2, "RSM_DEATHS", g_pPlayerData[id][Deaths], id2, "RSM_HEADSHOTS", g_pPlayerData[id][Headshots], id2, "RSM_ASSISTS", g_pPlayerData[id][Assists], id2,
		"RSM_KD_RATIO", flKdRatio, id2, "RSM_HS_PERCENTAGE", flHsPrecentage, id2, "RSM_ACCURACY", flAcurracy, id2, "RSM_EFFICIENCY", flEfficiency, id2, "RSM_SHOTS", g_pPlayerData[id][Shots], id2,
		"RSM_HITS", g_pPlayerData[id][Hits], id2, "RSM_DAMAGE", g_pPlayerData[id][Damage], id2, "RSM_FAV_WEAPON", id, g_eWeapon[g_iTop5Weapons[id][WEAPON_ID][0]][LangName], g_iTop5Weapons[id][WEAPON_ID][0],
		g_iTop5Weapons[id][WEAPON_KILLS][0], id2, "RSM_KILLS", id, g_eWeapon[g_iTop5Weapons[id][WEAPON_ID][1]][LangName], g_iTop5Weapons[id][WEAPON_ID][1], g_iTop5Weapons[id][WEAPON_KILLS][1], id2,
		"RSM_KILLS", id, g_eWeapon[g_iTop5Weapons[id][WEAPON_ID][2]][LangName], g_iTop5Weapons[id][WEAPON_ID][2], g_iTop5Weapons[id][WEAPON_KILLS][2], id2, "RSM_KILLS", id,
		g_eWeapon[g_iTop5Weapons[id][WEAPON_ID][3]][LangName], g_iTop5Weapons[id][WEAPON_ID][3], g_iTop5Weapons[id][WEAPON_KILLS][3], id2, "RSM_KILLS", id,
		g_eWeapon[g_iTop5Weapons[id][WEAPON_ID][4]][LangName], g_iTop5Weapons[id][WEAPON_ID][4], g_iTop5Weapons[id][WEAPON_KILLS][4], id2, "RSM_KILLS")
	}
}

GetTop5Weapons(id) {
	new iData[1]; iData[0] = id
	static szQuery[MAX_DATA_LENGTH], szPlayer[MAX_NAME_LENGTH * 2]
	SQL_QuoteString(Empty_Handle, szPlayer, charsmax(szPlayer), g_szSaveInfo[id])

	formatex(szQuery, charsmax(szQuery), "SELECT `Weapon ID`, `Weapon Kills` FROM `%s` WHERE Player = '%s' ORDER BY `Weapon Kills` DESC LIMIT 5;", g_eSetting[MYSQL_TABLE2], szPlayer)
	SQL_ThreadQuery(g_iSqlTuple, "GetTop5Weapons_QueryHandler", szQuery, iData, sizeof(iData))
}

public GetTop5Weapons_QueryHandler(iFailState, Handle:iQuery, szError[], iErrcode, iData[], iDataSize) {
	new id = iData[0], i
	if(SQL_NumResults(iQuery)) {
		while(SQL_MoreResults(iQuery)) {
			if(SQL_ReadResult(iQuery, 1) > 0) {
				g_iTop5Weapons[id][WEAPON_ID][i] = SQL_ReadResult(iQuery, 0)
				g_iTop5Weapons[id][WEAPON_KILLS][i] = SQL_ReadResult(iQuery, 1)
			}

			i++
			SQL_NextRow(iQuery)
		}
	}
}

GetPlayerInfo(const id) {
	if(!g_eSetting[RANK_BOTS] && is_user_bot(id)) {
		return  
	}

	SqlSaveOrLoad(id, MYSQL_SAVE)
	GetPlayerRank(id)
}

ResetStats(const id) {
	arrayset(g_pPlayerData[id], 0, sizeof g_pPlayerData[])
	for(new i; i < MAX_WEAPONS_EX; i++) {
		g_iWeaponKills[id][i] = 0
	}

	for(new i; i < 5; i++) {
		g_iTop5Weapons[id][WEAPON_ID][i] = 0
		g_iTop5Weapons[id][WEAPON_KILLS][i] = 0
	}
}

GetXpReward(const szTrie[], iType) {
	new iReward
	switch(iType) {
		case XP_REWARD: {
			if(TrieKeyExists(g_tRewards, szTrie)) {
				TrieGetCell(g_tRewards, szTrie, iReward)
				return iReward
			}
		}
		case XP_TEAM_REWARD: {
			if(TrieKeyExists(g_tTeamRewards, szTrie)) {
				TrieGetCell(g_tTeamRewards, szTrie, iReward)
				return iReward
			}
		}
	}
	return 0
}

UpdateXpAndRank(const id, iXp, bool:blTeam) {
	if(!g_eSetting[RANK_BOTS] && is_user_bot(id)) {
		return  
	}

	g_pPlayerData[id][Xp] += iXp
	g_pMapData[id][MAP_XP] += iXp

	if(iXp != 0) {
		UpdateRank(id)
		GetPlayerInfo(id)
	}

	switch(blTeam) {
		case true: {
			g_iTotalTeamXp[id] += iXp
			ResetTotalTeamXp(id)
		}
		case false: {
			g_iTotalXp[id] += iXp
			ResetTotalXp(id)
		}
	}
}

ResetTotalXp(const id) {
	new iTask = id + TASK_RESETXP
	if(task_exists(iTask)) {
		remove_task(iTask)
	}
	set_task(g_eSetting[XP_HUD_VALUES][HUD_HOLD_TIME], "taskResetXp", iTask)
}

ResetTotalTeamXp(const id) {
	new iTask = id + TASK_TEAM_XP
	if(task_exists(iTask)) {
		remove_task(iTask)
	}

	set_task(g_eSetting[XP_HUD_TEAM_VALUES][HUD_HOLD_TIME], "taskResetTeamXp", iTask)
}

ShowHudMessage(const id, iXp, bool:blTeam) {
	new iRed = 			blTeam ? floatround(g_eSetting[XP_HUD_TEAM_VALUES][HUD_COLOR1]) : floatround(g_eSetting[XP_HUD_VALUES][HUD_COLOR1])
	new iGreen =  		blTeam ? floatround(g_eSetting[XP_HUD_TEAM_VALUES][HUD_COLOR2]) : floatround(g_eSetting[XP_HUD_VALUES][HUD_COLOR2]) 
	new iBlue =  		blTeam ? floatround(g_eSetting[XP_HUD_VALUES][HUD_COLOR3]) 		: floatround(g_eSetting[XP_HUD_VALUES][HUD_COLOR3])
	new Float:flPosX =  blTeam ? g_eSetting[XP_HUD_TEAM_VALUES][HUD_POS_X] 				: g_eSetting[XP_HUD_VALUES][HUD_POS_X]
	new Float:flPosY =  blTeam ? g_eSetting[XP_HUD_TEAM_VALUES][HUD_POS_Y] 				: g_eSetting[XP_HUD_VALUES][HUD_POS_Y]
	new iEffects =  	blTeam ? floatround(g_eSetting[XP_HUD_TEAM_VALUES][HUD_EFFECT]) : floatround(g_eSetting[XP_HUD_VALUES][HUD_EFFECT])

	if(iRed < 0) 	iRed = 		random(256)
	if(iGreen < 0) 	iGreen = 	random(256)
	if(iBlue < 0) 	iBlue = 	random(256)

	static szHudInfo[MAX_DATA_LENGTH]
	new blGetXp = iXp >= 0

	switch(blGetXp) {
		case true: 	blTeam ? copy(szHudInfo, charsmax(szHudInfo), g_eSetting[XP_HUD_TEAM_GET]) 	: copy(szHudInfo, charsmax(szHudInfo), g_eSetting[XP_HUD_GET])
		case false: blTeam ? copy(szHudInfo, charsmax(szHudInfo), g_eSetting[XP_HUD_TEAM_LOSE]) : copy(szHudInfo, charsmax(szHudInfo), g_eSetting[XP_HUD_LOSE])
	}

	if(contain(szHudInfo, "%xp%") != -1) {
		replace_string(szHudInfo, charsmax(szHudInfo), "-", "")
		replace_string(szHudInfo, charsmax(szHudInfo), "%xp%", "%d")
	}

	new iType = blTeam ? g_eSetting[XP_HUD_TEAM_TYPE] : g_eSetting[XP_HUD_TYPE]
	switch(iType) {
		case 0: {
			set_hudmessage(iRed, iGreen, iBlue, flPosX, flPosY, iEffects, 1.0, iEffects != 1 ? 0.15 : 0.05, 0.01, 0.01, -1)
			ShowSyncHudMsg(id, blTeam ? g_iObject3 : g_iObject2, szHudInfo, iXp)
		}
		case 1: {
			set_dhudmessage(iRed, iGreen, iBlue, flPosX, flPosY, iEffects, 1.0, iEffects != 1 ? 0.15 : 0.05, 0.01, 0.01)
			show_dhudmessage(id, szHudInfo, iXp)
		}
	}
}

UpdateRank(const id) {
	new iLevel, eMaxRanks[RankInfo]
	for(new i; i < g_iRanks - 1; i++) {
		ArrayGetArray(g_aRanks, i + 1, eMaxRanks)

		if(g_pPlayerData[id][Xp] >= eMaxRanks[RankXp]) {
			iLevel++
		}
	}

	if(iLevel != g_pPlayerData[id][Level]) {
		new bool:blLevelUp = iLevel > g_pPlayerData[id][Level]
		static eRank[RankInfo]
		ArrayGetArray(g_aRanks, iLevel, eRank)

		if(blLevelUp) {
			g_pPlayerData[id][Level] = iLevel
			CPC(g_eSetting[LEVEL_MESSAGE_TYPE] ? 0 : id, "%L", id, "RSM_RANK_UP", id, g_pPlayerData[id][Level] + 1, eRank[RankName])
			LevelEffect(id, LEVEL_UP)
		}
		else {
			g_pPlayerData[id][Level] = iLevel
			CPC(g_eSetting[LEVEL_MESSAGE_TYPE] ? 0 : id, "%L", id, "RSM_RANK_DN", id, g_pPlayerData[id][Level] + 1, eRank[RankName])
			LevelEffect(id, LEVEL_DN)
		}
	}
}

LevelEffect(const id, iType) {
	new iRed = 		iType == LEVEL_UP ? floatround(g_eSetting[LEVELUP_EFFECTS][SCREEN_COLOR1]) : floatround(g_eSetting[LEVELDN_EFFECTS][SCREEN_COLOR1])
	new iGreen = 	iType == LEVEL_UP ? floatround(g_eSetting[LEVELUP_EFFECTS][SCREEN_COLOR2]) : floatround(g_eSetting[LEVELDN_EFFECTS][SCREEN_COLOR2])
	new iBlue = 	iType == LEVEL_UP ? floatround(g_eSetting[LEVELUP_EFFECTS][SCREEN_COLOR3]) : floatround(g_eSetting[LEVELDN_EFFECTS][SCREEN_COLOR3])

	if(iRed < 0) 	iRed = 		random(256)
	if(iGreen < 0) 	iGreen = 	random(256)
	if(iBlue < 0) 	iBlue = 	random(256)

	message_begin(MSG_ONE, g_iScreenFade, {0, 0, 0}, id)
	write_short(floatround(4096.0 * (iType == LEVEL_UP ? g_eSetting[LEVELUP_EFFECTS][SCREEN_HOLD_TIME] : g_eSetting[LEVELDN_EFFECTS][SCREEN_HOLD_TIME]), floatround_round))
	write_short(floatround(4096.0 * (iType == LEVEL_UP ? g_eSetting[LEVELUP_EFFECTS][SCREEN_HOLD_TIME] : g_eSetting[LEVELDN_EFFECTS][SCREEN_HOLD_TIME]), floatround_round))
	write_short(0x0000)
	write_byte(iRed)
	write_byte(iGreen)
	write_byte(iBlue)
	write_byte(iType == LEVEL_UP ? floatround(g_eSetting[LEVELUP_EFFECTS][SCREEN_ALPHA]) : floatround(g_eSetting[LEVELDN_EFFECTS][SCREEN_ALPHA]))
	message_end()

	if(iType == LEVEL_UP) {
		emit_sound(id, CHAN_AUTO, g_eSetting[LEVELUP_SOUND], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	else {
		emit_sound(id, CHAN_AUTO, g_eSetting[LEVELDN_SOUND], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
}

GetSteamInfo(const id, szData[2][], iLen) {
	formatex(szData[STEAM_AVATAR], iLen, g_eSetting[DEFAULT_AVATAR_LINK])

	get_steamdata(id, szData[STEAM_AVATAR], 		iLen, "avatarfull")
	get_steamdata(id, szData[STEAM_PROFILE_URL], 	iLen, "profileurl")

	if(contain(szData[STEAM_AVATAR], "http") != -1) {
		replace_string(szData[STEAM_AVATAR], iLen, "https", "http")
	}

	replace_string(szData[STEAM_PROFILE_URL], iLen, "https", "http")
}

SQL_IsFail(iFailState, iErrcode, const szError[]) {
	switch(iFailState) {
		case TQUERY_CONNECT_FAILED: log_amx("%L", LANG_PLAYER, "RSM_CONNECT_FAILED", szError)
		case TQUERY_QUERY_FAILED: 	log_amx("%L", LANG_PLAYER, "RSM_QUERY_FAILED", szError)
	}

	if(iErrcode) {
		log_amx("%L", LANG_PLAYER, "RSM_QUERY_ERROR", szError)
	}

	return false
}

strclip(szString[], iClip, szEnding[] = "..") {
	new iLen = strlen(szString) - 1 - strlen(szEnding) - iClip
	format(szString[iLen], iLen, szEnding)
}

stock CPC(const pPlayer, const szInputMessage[], any:...) {
	static szMessage[191]
	new iLen = formatex(szMessage, charsmax(szMessage), "%s ", g_eSetting[CHAT_PREFIX])
	vformat(szMessage[iLen], charsmax(szMessage) - iLen, szInputMessage, 3)
	client_print_color(pPlayer, print_team_default, szMessage)
}

stock bool:IsUserSteam(const id) {
	new iFile = fopen(g_szPlayerFile[id], "r")
	while(!feof(iFile))  {
		static szData[MAX_USER_INFO_LENGTH]
		fgets(iFile, szData, charsmax(szData))

		if(szData[0] == '{' || szData[0] == '}' || szData[0] == ' ' || equal(szData, "response") || equal(szData, "players") || equal(szData, "0")) {
			continue
		}

		if(contain(szData, "steamid") != -1) {
			return true
		}
	}
	return false
}
