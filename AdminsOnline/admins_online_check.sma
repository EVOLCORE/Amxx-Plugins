#include <amxmodx>

const FLAGS = ADMIN_KICK;

const MAX_NUM = 3; 							// maximum names (further than numbers)

stock const g_szPluginCommand[] 	= 		"/admins";
stock const g_szPrefix[] 			= 		"^4[HW]";

public plugin_init() {
	register_plugin("Say Admins", "1.1", "mIDnight");
	
	register_clcmd(fmt("say %s", g_szPluginCommand), "clcmd_handle");
	register_clcmd(fmt("say_team %s", g_szPluginCommand), "clcmd_handle");
}

public clcmd_handle(id) {
	new pArray[MAX_PLAYERS], pNum, pCount, szStr[100];		get_players(pArray, pNum, "ch");
	
	for(new i, pPlayer; i < pNum; i++) {
		pPlayer = pArray[i];
		
		if(~get_user_flags(pPlayer) & FLAGS) continue;
		
		if(++pCount == 1) strcat(szStr, fmt("%n", pPlayer), charsmax(szStr));
		
		else if(pCount <= MAX_NUM) strcat(szStr, fmt(", %n", pPlayer), charsmax(szStr));
	}
	
	if (pCount) {
		if (pCount > MAX_NUM) strcat(szStr, fmt(pCount - MAX_NUM == 1 ? " and 1 more" : " and %d others", pCount - MAX_NUM), charsmax(szStr));
		
		client_print_color(id, print_team_blue, "%s ^1Admins online: ^3%s", g_szPrefix, szStr);
	}	else	client_print_color(id, print_team_red, "%s ^1Admins online: ^3Currently there is no admins online.", g_szPrefix);
	return PLUGIN_HANDLED;
}
