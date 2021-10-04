
#if defined new_time
  #endinput
#endif
#define new_time

#define Time_Minute 0
#define Time_Hour 1
#define Time_Day 2
#define Time_Month 3
#define Time_Year 4

native get_dynamic_time( TIME_KIND )
native get_dynamic_time_future( How_long_next_time , TIME_KIND , NEXT_TIME_KIND )
