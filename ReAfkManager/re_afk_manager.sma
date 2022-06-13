#pragma semicolon 1

#include <amxmodx>
#include <reapi>

new const szChatTag[] = "^4[HW]";

new Float:g_flPlayerOrigin[MAX_PLAYERS+1][3],
	g_iAfkMeter[MAX_PLAYERS+1];

new g_cvar;

public plugin_init() {
	register_plugin("[ReAPI] AFK manager", "0.2", "mIDnight");

	RegisterHookChain(RG_CBasePlayer_Spawn, "@RG_CBasePlayer_Spawn_Post", .post = true);

	bind_pcvar_num(create_cvar("afk_kick_limit", "6", _, "The players kick limit."), g_cvar);
}

@RG_CBasePlayer_Spawn_Post(const id) {
	if(get_member(id, m_bJustConnected)) {
		return;
	}

	remove_task(id);

	get_entvar(id, var_origin, g_flPlayerOrigin[id]);

	set_task(40.0, "@AfkSlay", id);
}

@AfkSlay(const id) {
	if(IsPlayerAfk(id)) {
		if(get_playersnum() > 15) {
			g_iAfkMeter[id]++;

			if(g_iAfkMeter[id] > g_cvar) {
				server_cmd("kick #%d ^"You were kicked out for being afk for a long time.", get_user_userid(id));
			}
			else {
				user_silentkill(id);
				client_print_color(id, print_team_red, "%s ^1You has been slayed because you were AFK limit: ^4[^3 %i^1/^3%i ^4]", szChatTag, g_iAfkMeter[id], g_cvar);
			}	
		}
		else {
			user_silentkill(id);
		}
	}
}

public client_putinserver(id) {
	g_iAfkMeter[id] = 0;
}

bool:IsPlayerAfk(const id) {
	new Float:flOrigin[3];

	get_entvar(id, var_origin, flOrigin);

	for(new i = 0; i < 2; i++) {
		if(flOrigin[i] != g_flPlayerOrigin[id][i]) {
			return false;
		}
	}
	return true;
}
