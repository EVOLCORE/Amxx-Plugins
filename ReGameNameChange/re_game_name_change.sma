#include <amxmodx>
#include <reapi>

public plugin_init() {
        register_plugin("[ReAPI] Game desc]", "1.0", "mIDnight")
        set_member_game(m_GameDesc,"Counter-Strike")
}
