#include <amxmodx>
#include <hamsandwich>
#include <reapi>

new bool:g_blSilencer[MAX_CLIENTS + 1];

public plugin_init() {
	register_plugin("[ReAPI] M4a1 Silencer", "1.0", "mIDnight");

	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_m4a1", "@Ham_Weapon_SecondaryAttack_Post", .Post = true);
	RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "@CBasePlayer_AddPlayerItem_Post", .post = true);
}

@Ham_Weapon_SecondaryAttack_Post(pWeapon) {
	new pPlayer = get_member(pWeapon, m_pPlayer);

	g_blSilencer[pPlayer] = bool:get_member(pWeapon, m_Weapon_bSecondarySilencerOn);
}

@CBasePlayer_AddPlayerItem_Post(const pPlayer, const pItem) {
	if(get_member(pItem, m_iId) != WEAPON_M4A1) {
		return;
	}

	set_member(pItem, m_Weapon_bSecondarySilencerOn, g_blSilencer[pPlayer]);
}
