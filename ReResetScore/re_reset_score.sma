#include <amxmodx>
#include <reapi>

public plugin_init() {
	register_plugin("[ReAPI] Reset Score", "1.0", "mIDnight");
	register_clcmd("say /rs", "@clcmd_rs"); register_clcmd("say_team /rs", "@clcmd_rs");
}

@clcmd_rs(id) {
	set_entvar(id, var_frags, 0.0); set_member(id, m_iDeaths, 0);
	client_print_color(id, id, "^4[Element]^1 You successfully restarted your score!");
	
	message_begin(MSG_ALL, 85);
	write_byte(id);
	write_short(0); write_short(0); write_short(0); write_short(0);
	message_end();
	
	return PLUGIN_HANDLED;
}
