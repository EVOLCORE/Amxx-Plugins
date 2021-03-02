#pragma semicolon 1

#include <amxmodx>
#include <reapi>

new const g_szModelNames[][] = {
	"leet",   // te model
	"gign"    // ct model
};

public plugin_init() {
	register_plugin("[ReAPI] Models Change", "1.0", "mIDnight");

	RegisterHookChain(RG_CBasePlayer_SetClientUserInfoModel, "@CBasePlayer_SetClientUserInfoModel_Pre", .post = false);
}

public plugin_precache() {
	for(new i = 0; i < sizeof(g_szModelNames); i++) {
		precache_model(fmt("models/player/%s/%s.mdl", g_szModelNames[i], g_szModelNames[i]));
	}
}

@CBasePlayer_SetClientUserInfoModel_Pre(const pPlayer, infobuffer[], szNewModel[]) {
	SetHookChainArg(3, ATYPE_STRING, g_szModelNames[get_member(pPlayer, m_iTeam) == TEAM_TERRORIST ? 0 : 1]);
}
