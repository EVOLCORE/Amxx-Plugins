#if defined _crs_included
	#endinput
#endif
#define _crs_included

/**
 * Called just after client rank up
 *
 * @noreturn
 */
forward csd_rank_up(const id);

 /**
  * Called just after client rank down
  *
  * @noreturn
  */
 forward csd_rank_down(const id);

 /**
 * Gets xp value from client
 *
 * @param index		Client index
 *
 * @return Amount of xp value the client has. Also returns 0 if
 *         the client is not connected or the index is not within the
 *         range of 1 to MaxClients
 */
native csd_get_user_xp(const id);

 /**
 * Gets rank value from client
 *
 * @param index		Client index
 *
 * @return Amount of rank value the client has. Also returns 0 if
 *         the client is not connected or the index is not within the
 *         range of 1 to MaxClients
 */
 native csd_get_user_rank(const id);

 /**
 * Gets rank name from client
 *
 * @param index		Client index
 * @param rank		Buffer to copy rank name to
 * @param len		Maximum buffer size
 *
 * @noreturn
 */
 native csd_get_user_rankname(const id, const rankname[], const len);
