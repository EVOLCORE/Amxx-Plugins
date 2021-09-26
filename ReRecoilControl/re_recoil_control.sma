#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <reapi>

new const Float:WEAPONS_RECOIL[MAX_WEAPONS] = {
	1.0, // WEAPON_NONE
	0.7, // WEAPON_P228
	0.9, // WEAPON_GLOCK
	1.0, // WEAPON_SCOUT
	1.0, // WEAPON_HEGRENADE
	0.8, // WEAPON_XM1014
	1.0, // WEAPON_C4
	1.0, // WEAPON_MAC10
	0.8, // WEAPON_AUG
	1.0, // WEAPON_SMOKEGRENADE
	0.9, // WEAPON_ELITE
	0.8, // WEAPON_FIVESEVEN
	1.0, // WEAPON_UMP45
	1.0, // WEAPON_SG550
	0.8, // WEAPON_GALIL
	1.0, // WEAPON_FAMAS
	0.9, // WEAPON_USP
	1.0, // WEAPON_GLOCK18
	1.0, // WEAPON_AWP
	1.0, // WEAPON_MP5N
	1.0, // WEAPON_M249
	1.0, // WEAPON_M3
	0.7, // WEAPON_M4A1
	1.0, // WEAPON_TMP
	1.0, // WEAPON_G3SG1
	1.0, // WEAPON_FLASHBANG
	1.0, // WEAPON_DEAGLE
	1.0, // WEAPON_SG552
	0.6, // WEAPON_AK47
	1.0, // WEAPON_KNIFE
	0.8, // WEAPON_P90
};

public plugin_init() {
	register_plugin("[ReAPI] Recoil control", "1.0", "mIDnight");

	new weaponName[24];

	for (new i = 1; i < MAX_WEAPONS - 1; i++) {
		if ((1<<i) & ((1<<2) | (1<<CSW_KNIFE) | (1<<CSW_HEGRENADE) | (1<<CSW_FLASHBANG) | (1<<CSW_SMOKEGRENADE) | (1<<CSW_C4)))
			continue;

		rg_get_weapon_info(WeaponIdType:i, WI_NAME, weaponName, charsmax(weaponName));

		RegisterHam(Ham_Weapon_PrimaryAttack, weaponName, "@CBasePlayerWeapon_PrimaryAttack_Post", .post = true);
	}
}

@CBasePlayerWeapon_PrimaryAttack_Post(id) {
	new weaponId = get_member(id, m_iId);

	if (WEAPONS_RECOIL[weaponId] == 1.0)
		return;

	new player = get_member(id, m_pPlayer);

	new Float:vecPunchAngle[3];
	get_entvar(player, var_punchangle, vecPunchAngle);

	for (new i = 0; i < 3; i++)
		vecPunchAngle[i] *= WEAPONS_RECOIL[weaponId];

	set_entvar(player, var_punchangle, vecPunchAngle);
}
