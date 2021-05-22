#include <amxmodx>
#include <cromchat>
#include <reapi>

new const FILE[] = "addons/amxmodx/configs/forbidden_words.ini";

new Read_All[100][64];
new Reads;
new GaG[33];
new g_pAdminFlag, g_pMaxChanges
new g_iAdminFlag, g_iMaxChanges
new g_iChanges[33];

public plugin_init() {
	register_plugin("[ReAPI] Anti bad words", "1.3", "mIDnight");
	register_dictionary("forbidden_words.txt")
	register_clcmd("say", "@HookSay");
	register_clcmd("say_team", "@HookSay");
	register_clcmd("amx_chat", "@HookSay");
	
	RegisterHookChain(RG_CBasePlayer_SetClientUserInfoName, "@CBasePlayer_SetClientUserInfoName")
	g_pAdminFlag = register_cvar("nnc_admin_flag", "")
	g_pMaxChanges = register_cvar("nnc_max_changes", "3")
	CC_SetPrefix("&x04[Element]")
	
	if(!file_exists(FILE)) {
		set_fail_state("Forbidden Words File Not Found.");
	}
}

public plugin_precache() {
	new TxtLen;
	new Max_Lines = file_size(FILE, 1);
	
	for(new i; i < Max_Lines; i++) {
		read_file(FILE, i, Read_All[i], 31, TxtLen);
		Reads++;
	}
}

public plugin_cfg() {
	new szFlag[2]
	get_pcvar_string(g_pAdminFlag, szFlag, charsmax(szFlag))
	g_iAdminFlag = read_flags(szFlag)
	g_iMaxChanges = get_pcvar_num(g_pMaxChanges)
}

public client_putinserver(id) {
	GaG[id] = false; {
		if(g_iMaxChanges)
		g_iChanges[id] = 0
	}
}

public client_disconnected(id) {
	remove_task(id);
}

@HookSay(id) {
	if(GaG[id]) {
		CC_SendMessage(id, "%L", id, "GAG_MSG")
		return PLUGIN_HANDLED;
	}
	
	new Name[33];
	get_user_name(id, Name, 32);
	
	new Arg[256];
	read_args(Arg, charsmax(Arg));
	remove_quotes(Arg);
	
	for(new i; i < Reads; i++) {
		if(containi(Arg, Read_All[i]) != -1) {
			GaG[id] = true;
			CC_SendMessage(0, "%L", 0, "GAG_WORD",Name)
			CC_SendMessage(id, "%L", id, "GAG_GAGGED")
			set_task(30.0, "@Gag_ID_False", id);
			
			return PLUGIN_CONTINUE;
		}
	}
	return PLUGIN_CONTINUE;
}

@Gag_ID_False(id) {
	GaG[id] = false;
	CC_SendMessage(id, "%L", id, "GAG_EXPIRED")
}

@CBasePlayer_SetClientUserInfoName(const id, const iBuffer, const szNewName[]) {
	if(g_iAdminFlag && get_user_flags(id) & g_iAdminFlag)
	return HC_CONTINUE
	
	if(g_iChanges[id] < g_iMaxChanges) {
		g_iChanges[id]++
		
		new g_iChangesLeft = g_iMaxChanges - g_iChanges[id]
		CC_SendMessage(id, "%L", id, !g_iChangesLeft ? "NNC_CHANGE_ZERO" : g_iChangesLeft == 1 ? "NNC_CHANGE_ONE" : "NNC_CHANGE_MORE", g_iChangesLeft)
		return HC_CONTINUE
	}
	
	CC_SendMessage(id, "%L", id, "NNC_MESSAGE")
	SetHookChainReturn(ATYPE_BOOL, 0)	
	return HC_SUPERCEDE
}
