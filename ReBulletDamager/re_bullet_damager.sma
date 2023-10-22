#include <amxmodx>
#include <reapi>

static iDamageCoordPos[MAX_CLIENTS + 1];
static const Float: iDamageCoords[][] = { {0.50, 0.43}, {0.55, 0.45}, {0.57, 0.50}, {0.55, 0.55}, {0.50, 0.57}, {0.45, 0.55}, {0.43, 0.50}, {0.45, 0.45} };
new g_iHudSyncObj;

public plugin_init() {
	register_plugin("[ReAPI] Bullet Damage", "1.0", "mIDnight");
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "@CBasePlayer_TakeDamagePost", .post = true);
	g_iHudSyncObj = CreateHudSyncObj();
}

@CBasePlayer_TakeDamagePost(const iVictim, iInflictor, iAttacker, Float:fDamage, bitsDamageType) {
    if (!rg_is_player_can_takedamage(iAttacker, iVictim) || iVictim == iAttacker) {
        return HC_CONTINUE;
    }

    set_hudmessage(64, 64, 0, iDamageCoords[iDamageCoordPos[iAttacker]][0], iDamageCoords[iDamageCoordPos[iAttacker]][1], _, _, 1.0); //0, 144, 200
    ShowSyncHudMsg(iAttacker, g_iHudSyncObj, "%.0f", fDamage);

    iDamageCoordPos[iAttacker] = (iDamageCoordPos[iAttacker] + 1) % sizeof(iDamageCoords);

    return HC_CONTINUE;
}
