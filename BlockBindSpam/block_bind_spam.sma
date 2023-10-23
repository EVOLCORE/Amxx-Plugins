#pragma semicolon 1

#include <amxmodx>

#define register_cmd_list(%0,%1,%2)            for (new i = 0; i < sizeof(%1); i++) register_%0(%1[i], %2)

new const szSymbols[] = {
	"%",
	"#",
	"",
	"0"
};

public plugin_init() {
	register_plugin("Block symbos", "0.0.1", "mIDnight");

	new szHandleSay[][] = {"say", "say_team", "amx_chat"};

	register_cmd_list(clcmd, szHandleSay, "@handle_say");
}

@handle_say(pPlayer) {
	new szArgs[192];
	read_args(szArgs, charsmax(szArgs));
	remove_quotes(szArgs);
	trim(szArgs);

	if(szArgs[0] =='^0' || !strlen(szArgs))
		return PLUGIN_HANDLED;

	for(new i=0; i < charsmax(szSymbols); i++)
	if(containi(szArgs, szSymbols[i]) != -1) {
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}
