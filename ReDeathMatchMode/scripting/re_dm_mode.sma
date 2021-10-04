#include <amxmodx>
#include <reapi>
#include <dynamic_time>
#include <nvault>

#define TAG "Element"

new bool:dmcontrol, timeset = false;
new sv_restart, mp_forcerespawn, mp_buytime, mp_give_player_c4, mp_infinite_ammo, mp_round_infinite;
new New_Date_Minute , New_Date_Hour , New_Date_Day , New_Date_Month , New_Date_Year
new Difference_Minute , Difference_Hour , Difference_Day , Difference_Month , Difference_Year
new VaultFile, Float:dmstart, Float:dmend
new g_szServerIP[32];

public plugin_natives() {
	register_native("get_dynamic_time", "_get_dynamic_time")
	register_native("get_dynamic_time_future", "_get_dynamic_time_future")
}

public _get_dynamic_time() {
	return gget_dynamic_time(get_param(1))
}

public _get_dynamic_time_future() {
	return gget_dynamic_time_future(get_param(1), get_param(2), get_param(3))
}

bool:Player_Access(id) {
	if(set_entvar(id, var_flags) & ADMIN_RCON)
		return true
	else 	return false
}

public plugin_init() {
	register_plugin("[ReAPI] DeathMatch mode", "1.0", "mIDnight");
	register_dictionary("re_deathmatch_mode.txt")

	get_user_ip(0, g_szServerIP, charsmax(g_szServerIP));
	
	if(!equal(g_szServerIP, "103.153.157.22:27015")) {
		set_fail_state("Error exit code: 0x744");
	}

	register_clcmd("amx_time_menu", "Time_Settings")
	RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn", .post=true);
	RegisterHookChain(RG_CSGameRules_RestartRound, "@CSGameRules_RestartRound", .post = true);
	
	mp_infinite_ammo = get_cvar_pointer("mp_infinite_ammo");
	sv_restart = get_cvar_pointer("sv_restart");
	mp_forcerespawn = get_cvar_pointer("mp_forcerespawn");
	mp_buytime = get_cvar_pointer("mp_buytime");
	mp_give_player_c4 = get_cvar_pointer("mp_give_player_c4");
	mp_round_infinite = get_cvar_pointer("mp_round_infinite");

	bind_pcvar_float(create_cvar("dm_start_time", "1", _, _, true, 1.0), dmstart);
	bind_pcvar_float(create_cvar("dm_end_time", "10", _, _, true, 1.0), dmend);
	
}

@CSGameRules_RestartRound() {
	new Hour = get_dynamic_time(Time_Hour);
	new Minute = get_dynamic_time(Time_Minute);
	if(Hour >= dmstart && Hour < dmend ) {
		dmcontrol = true;
	}
	else {
		dmcontrol = false;
	}
	/* future settings in DM mode. */
	if(dmcontrol) {
		if(!timeset) {
			set_pcvar_num(sv_restart, 3);
			timeset = true;
			set_pcvar_num(mp_forcerespawn, 2);
			set_pcvar_num(mp_buytime, 0);
			set_pcvar_num(mp_infinite_ammo, 2);
			set_pcvar_num(mp_give_player_c4, 0);
			set_pcvar_num(mp_round_infinite, 1);
			client_print_color(0, 0, "^4[%s]Hour ^1%d:%d starting ^3DEATHMATCH Mode ^1Activated", TAG, Hour, Minute)
			client_print_color(0, 0, "^4[%s]Hour ^1%d:%d starting ^3DEATHMATCH Mode ^1Activated", TAG, Hour, Minute)
			client_print_color(0, 0, "^4[%s]Hour ^1%d:%d starting ^3DEATHMATCH Mode ^1Activated", TAG, Hour, Minute)
		}
	}
	/* future settings in PUB mode. */
	else {
		if(!timeset) {
			set_pcvar_num(sv_restart, 3);
			timeset = true;
			set_pcvar_float(mp_buytime, 0.35);
			set_pcvar_num(mp_forcerespawn, 0);
			set_pcvar_num(mp_infinite_ammo, 0);
			set_pcvar_num(mp_give_player_c4, 1);
			set_pcvar_num(mp_round_infinite, 0);
			client_print_color(0, 0, "^4[%s]Hour ^1%d:%d starting ^3PUBLIC Mode ^1Activated", TAG, Hour, Minute)
			client_print_color(0, 0, "^4[%s]Hour ^1%d:%d starting ^3PUBLIC Mode ^1Activated", TAG, Hour, Minute)
			client_print_color(0, 0, "^4[%s]Hour ^1%d:%d starting ^3PUBLIC Mode ^1Activated", TAG, Hour, Minute)
		}
	}
}

@CBasePlayer_Spawn(id) {
    if(!is_user_alive(id) || !is_user_connected(id) || !dmcontrol) {
        return;
    }
    rg_remove_all_items(id)
    rg_give_item(id, "weapon_m4a1");
    rg_set_user_bpammo(id, WEAPON_M4A1, 90);
    rg_give_item(id, "weapon_ak47");
    rg_set_user_bpammo(id, WEAPON_AK47, 90);
    rg_give_item(id, "weapon_deagle");
    rg_set_user_bpammo(id,WEAPON_DEAGLE, 90);
    rg_give_item(id, "weapon_knife");
}

public Time_Settings(id) {
	new bool:Acces = Player_Access(id)

	if (New_Date_Minute > 59) New_Date_Minute = 0 , New_Date_Hour++
	else if (New_Date_Minute < 0) New_Date_Minute = 59 , New_Date_Hour-=1
	
	if (New_Date_Hour > 23) New_Date_Hour = 0  , New_Date_Day++
	else if (New_Date_Hour < 0) New_Date_Hour = 23 , New_Date_Day-=1
	
	if (New_Date_Day > 31) New_Date_Day = 1 , New_Date_Month++
	else if (New_Date_Day < 1) New_Date_Day = 31 , New_Date_Month-=1
	
	if (New_Date_Month > 12) New_Date_Month = 1 , New_Date_Year++
	else if (New_Date_Month < 1) New_Date_Month = 12 , New_Date_Year-=1
	
	if (New_Date_Year < 2020) New_Date_Year = 2020
	
	new Menuz[256] , str_Num[3]
	formatex(Menuz, charsmax(Menuz), "\r***\w %L \r***^n^n%L : \r%d/%d/%d\r^n%L : \r%d:%d", id, "MENU_TITLE", id, "DATE", New_Date_Day, New_Date_Month, New_Date_Year, id, "HOUR", New_Date_Hour, New_Date_Minute)
	new Date_Menu = menu_create (Menuz, "Time_Settings_Handle")
	
	for (new i = 1 ; i <= 9 ; i++) {
		switch(i) {
			case 1:formatex(Menuz, charsmax(Menuz), "%L \d[\r+\d]", id, "HOUR")
			case 2:formatex(Menuz, charsmax(Menuz), "%L \d[\r-\d]^n", id, "HOUR")
	
			case 3:formatex(Menuz, charsmax(Menuz), "%L \d[\r+\d]", id, "MINUTE")
			case 4:formatex(Menuz, charsmax(Menuz), "%L \d[\r-\d]^n", id, "MINUTE")
	
			case 5:formatex(Menuz, charsmax(Menuz), "%L \d[\r+\d]", id, "DAY")
			case 6:formatex(Menuz, charsmax(Menuz), "%L \d[\r-\d]^n", id, "DAY")
	
			case 7:formatex(Menuz, charsmax(Menuz), "%L \d[\r+\d]", id, "MONTH")
			case 8:formatex(Menuz, charsmax(Menuz), "%L \d[\r-\d]^n", id, "MONTH")
			
			case 9:formatex(Menuz,charsmax(Menuz),"%L", id, "SAVE_SETTINGS")
		}
		
		num_to_str(i, str_Num, charsmax(str_Num))
		menu_additem(Date_Menu, Menuz, str_Num, Acces) 
	}	
	formatex(Menuz, charsmax(Menuz), "%L", id, "MENU_EXIT")
	menu_additem(Date_Menu, Menuz, "0") 
	menu_setprop(Date_Menu, MPROP_EXIT, MEXIT_NORMAL);
	menu_setprop(Date_Menu, MPROP_PERPAGE, 0);
	menu_display(id, Date_Menu)
	
	return PLUGIN_HANDLED;
}	


public Time_Settings_Handle(id, voting_menu , item) {
	new data[6], iName[64]
	new acces, callback
	menu_item_getinfo(voting_menu, item, acces, data,5, iName, 63, callback)
	switch(str_to_num(data)) {
		case 1: New_Date_Hour+= 1
		case 2: New_Date_Hour-= 1
		
		case 3: New_Date_Minute+= 1
		case 4: New_Date_Minute-= 1
		
		case 5: New_Date_Day+= 1
		case 6: New_Date_Day-= 1
		
		case 7: New_Date_Month+= 1
		case 8: New_Date_Month-= 1
		

		
		case 9:{
			Save_Settings(id)
			return PLUGIN_HANDLED	
		}
		case 0:{
			Load_Settings()
			return PLUGIN_HANDLED	
		}
	}
	Time_Settings(id)
	return PLUGIN_CONTINUE;	
}
Save_Settings(id) {
	new str_Day[3] , str_Month[3] , str_Year[5] , str_Hour[3] , str_Minute[3]

	get_time("%d", str_Day, charsmax(str_Day))
	get_time("%m", str_Month, charsmax(str_Month))
	get_time("%Y", str_Year, charsmax(str_Year))	
	get_time("%H", str_Hour, charsmax(str_Hour))
	get_time("%M", str_Minute, charsmax(str_Minute))		
	
	Difference_Minute = New_Date_Minute - str_to_num(str_Minute)
	Difference_Hour = New_Date_Hour - str_to_num(str_Hour)
	Difference_Day = New_Date_Day - str_to_num(str_Day)
	Difference_Month = New_Date_Month - str_to_num(str_Month)
	Difference_Year = New_Date_Year - str_to_num(str_Year)
			
	new str_Save[5]
	
	format(str_Save,charsmax(str_Save), "%d", Difference_Minute)
	nvault_set(VaultFile, "Difference_Minute", str_Save)
	
	format(str_Save, charsmax(str_Save), "%d", Difference_Hour)
	nvault_set(VaultFile, "Difference_Hour", str_Save)
	
	format(str_Save, charsmax(str_Save), "%d",Difference_Day)
	nvault_set(VaultFile, "Difference_Day", str_Save)
	
	format(str_Save, charsmax(str_Save), "%d", Difference_Month)
	nvault_set(VaultFile, "Difference_Month", str_Save)
	
	format(str_Save, charsmax(str_Save), "%d", Difference_Year)
	nvault_set(VaultFile, "Difference_Year", str_Save)
	
	client_print_color(0, print_team_red, "%L", 0, "CHANGED_SETTINGS", id)
	
}

Load_Settings() {
	Difference_Minute = nvault_get(VaultFile, "Difference_Minute")
	Difference_Hour = nvault_get(VaultFile, "Difference_Hour")
	Difference_Day = nvault_get(VaultFile, "Difference_Day")
	Difference_Month = nvault_get(VaultFile, "Difference_Month")
	Difference_Year = nvault_get(VaultFile, "Difference_Year")
		
	New_Date_Minute = gget_dynamic_time(Time_Minute)
	New_Date_Hour = gget_dynamic_time(Time_Hour)
	New_Date_Day = gget_dynamic_time(Time_Day)
	New_Date_Month = gget_dynamic_time(Time_Month)
	New_Date_Year = gget_dynamic_time(Time_Year)
}

public plugin_end() nvault_close(VaultFile);

public plugin_cfg() {
	VaultFile = nvault_open("DydamicDate");
	
	if (VaultFile == INVALID_HANDLE)
		set_fail_state("Error opening vault!")
	else	Load_Settings()
}

public gget_dynamic_time(TIME_KIND) {
	new str_Day[3], str_Month[3], str_Year[5], str_Hour[3], str_Minute[3]

	get_time("%d", str_Day, charsmax(str_Day))
	get_time("%m", str_Month, charsmax(str_Month))
	get_time("%Y", str_Year, charsmax(str_Year))
	
	get_time("%H", str_Hour, charsmax(str_Hour))
	get_time("%M", str_Minute, charsmax(str_Minute))
	
	new Day , Month , Year , Hour , Minute
	
	Minute = str_to_num(str_Minute) + Difference_Minute
	Hour = str_to_num(str_Hour) + Difference_Hour
	Day = str_to_num(str_Day) + Difference_Day
	Month = str_to_num(str_Month) + Difference_Month
	Year = str_to_num(str_Year) + Difference_Year
	
	if (Minute >= 60) Minute -=60, Hour++
	else if (Minute < 0) Minute +=60, Hour-=1
	
	if (Hour >= 24) Hour -=24, Day++
	else if (Hour < 0) Hour +=24, Day-=1
	
	if (Month == 1 || Month == 3 || Month == 5 || Month == 7 || Month == 8 || Month == 10 || Month == 12) {
		if (Day > 31) Day -= 31, Month++
		else if (Day <= 0) Day += 31, Month-= 1
	}
	else
{	
		if (Month != 2) {
			if (Day > 30) Day -= 30, Month++
			else if (Day <= 0) Day += 30, Month-= 1
		}
		else
		{
			if (Year%4 == 0) {
				if (Day > 29) Day -= 29, Month++
				else if (Day <= 0 ) Day += 29, Month-= 1
			}	
			else	if (Day > 28) Day -= 28, Month++
				else if (Day <= 0) Day += 28, Month-= 1
		}	
	}
	
	if (Month > 12) Month -=12, Year++
	else if (Month <= 0) Month +=12, Year-= 1
	switch(TIME_KIND) {
		case Time_Minute:
			return Minute
		case Time_Hour:
			return Hour
		case Time_Day:
			return Day
		case Time_Month:
			return Month
		case Time_Year:
			return Year
	}
	return -1
}

public gget_dynamic_time_future(How_long_next_time, TIME_KIND, NEXT_TIME_KIND) {
	new str_Day[3], str_Month[3], str_Year[5], str_Hour[3], str_Minute[3]

	get_time("%d", str_Day, charsmax(str_Day))
	get_time("%m", str_Month, charsmax(str_Month))
	get_time("%Y", str_Year, charsmax(str_Year))
	
	get_time("%H", str_Hour, charsmax(str_Hour))
	get_time("%M", str_Minute, charsmax(str_Minute))
	
	new Day, Month, Year, Hour, Minute
	
	Minute = str_to_num(str_Minute) + Difference_Minute
	Hour = str_to_num(str_Hour) + Difference_Hour
	Day = str_to_num(str_Day) + Difference_Day
	Month = str_to_num(str_Month) + Difference_Month
	Year = str_to_num(str_Year) + Difference_Year
	switch(TIME_KIND) {
		case Time_Minute:
			Minute += How_long_next_time	
		case Time_Hour:
			Hour += How_long_next_time
		case Time_Day:
			Day += How_long_next_time
		case Time_Month:
			Month += How_long_next_time
		case Time_Year:
			Year += How_long_next_time
	}
	
	while (Minute >= 60) Minute -=60, Hour++
	while (Minute < 0) Minute +=60, Hour--

	while (Hour >= 24) Hour -=24, Day++
	while (Hour < 0) Hour +=24, Day--

	if  (Month == 1 || Month == 3 || Month == 5 || Month == 7 || Month == 8 || Month == 10 || Month == 12) {
		while (Day > 31) Day -= 31, Month++
		while (Day <= 0) Day += 31, Month--
	}

	else if (Month != 2) {
		while (Day > 30) Day -= 30, Month++
		while (Day <= 0) Day += 30, Month--		
	}
	else
	{
		if (Year%4 == 0) {
			while (Day > 29) Day -= 29, Month++
			while (Day <= 0) Day += 29, Month--
		}	
		else
		{
			while (Day > 28) Day -= 28, Month++
			while (Day <= 0) Day += 28, Month--
		}
	}	
	while (Month > 12) Month -=12, Year++
	while (Month <= 0) Month +=12, Year--

	switch(NEXT_TIME_KIND) {
		case Time_Minute:
			return Minute	
		case Time_Hour:
			return Hour
		case Time_Day:
			return Day
		case Time_Month:
			return Month
		case Time_Year:
			return Year
	}
	return -1
}
