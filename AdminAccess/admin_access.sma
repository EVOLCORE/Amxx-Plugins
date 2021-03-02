#include <amxmodx>

#define PLUGIN "Admin access"
#define VERSION "1.0"
#define AUTHOR "mIDnight"

new g_iIsSelected = 0, g_pAccessFlags;

new const szCommands[][] = {
    "say /admin",
    "say .admin"
}

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);
	
    g_pAccessFlags=register_cvar("cw_flag_bits", "abcdefhijkmnopqrstuv");
    for(new i = 0; i < sizeof(szCommands); i++) {
        register_clcmd(szCommands[i], "set_user_flags_");
    }
}

public set_user_flags_(const id) {
    static bIsRemoving = false; bIsRemoving = false
    if(g_iIsSelected) {
        if(g_iIsSelected != id) {
            client_print(id, print_center, "Someone (%n) already have admin access.", g_iIsSelected);
            return PLUGIN_HANDLED;
        }
        else {
            bIsRemoving = true;
        }
    }

    static szFlags[32], iFlagsBits;
    get_pcvar_string(g_pAccessFlags, szFlags, charsmax(szFlags));

    iFlagsBits = read_flags(szFlags);

    if(!bIsRemoving) {
        if(get_user_flags(id) & ADMIN_USER) remove_user_flags(id, ADMIN_USER);
        set_user_flags(id, iFlagsBits);
    }
    else {
        g_iIsSelected = 0;
        remove_user_flags(id, iFlagsBits);
        client_print_color(0, id, "^4[Element]^1 Admin has leave admin access. Type ^4/admin ^1in chat to get admin.");
        return PLUGIN_HANDLED;
    }
    g_iIsSelected = id;
    client_print_color(0, id, "^4[Element]^1 Player ^3%n ^1got admin access.", g_iIsSelected);
    return PLUGIN_HANDLED;
}

public client_disconnected(id) {
    if(g_iIsSelected && g_iIsSelected == id) {
        g_iIsSelected = 0;
        client_print_color(0, id, "^4[Element]^1 Admin leave the game. Type ^4/admin ^1in chat to get admin access.");
    }
}
