/**
 * Set the score for players.
 *
 * @note    rh_set_score(pPlayer, 3, 4) - set the score.
 *          rh_set_score(pPlayer)       - reset to zero.
 *
 * @param frags   - kills.
 * @param deaths  - deaths.
 *
 * @return  nothing.
 */

#include <reapi>

#define MSG_SCORE 85

stock rh_set_score(const pPlayer, const frags = 0, const deaths = 0) {
    set_entvar(pPlayer, var_frags, float(frags));
    set_member(pPlayer, m_iDeaths, deaths);

    message_begin(MSG_BROADCAST, MSG_SCORE);
    write_byte(pPlayer);
    write_short(frags);
    write_short(deaths);
    write_short(0);
    write_short(0);
    message_end();
}
