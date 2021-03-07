#include <amxmodx>

new rounds_elapsed

public plugin_init() { 
	register_plugin("Server info", "1.2", "mIDnight")
	
	register_event("HLTV", "@round_start", "a", "1=0", "2=0")
	register_event("TextMsg", "@round_restart", "a", "2=#Game_will_restart_in")
	register_event("TextMsg", "@evGameCommencing", "a", "2=#Game_Commencing")
} 

@evGameCommencing()
	rounds_elapsed = 0

@round_restart() 
	rounds_elapsed = 0 
	
@round_start() { 
	rounds_elapsed += 1
     
	new mapname[32], nextmap[32], players[32], player ,maxrounds, maxplayers
	
	maxrounds=get_cvar_num("mp_maxrounds")
	maxplayers=get_maxplayers()
	get_cvar_string("amx_nextmap",nextmap,31) 
	get_mapname(mapname,31 ) 
	get_players(players, player) 
	
	client_print_color(0, 0, "^4[Element] [^1Round: ^3%d^1/^3%d ^1| Map: ^3%s ^1| ^1Nextmap: ^3%s ^1| Players: ^3%d^1/^3%d^4]",rounds_elapsed,maxrounds,mapname, nextmap, player,maxplayers)
}
