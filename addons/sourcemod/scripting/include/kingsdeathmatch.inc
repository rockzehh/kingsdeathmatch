#if defined _kingsdeathmatch_included
	#endinput
#endif
#define _kingsdeathmatch_included

enum Achivements
{
	ACHIVEMENT_ = 0,
};

native int KDM_GetAllDeaths(int iClient);

native int KDM_GetAllHeadshots(int iClient);

native int KDM_GetAllKills(int iClient);

native int KDM_GetCredits(int iClient);

native int KDM_GetHitgroup(int iClient);

native int KDM_GetRoundDeaths(int iClient);

native int KDM_GetRoundHeadshots(int iClient);

native int KDM_GetRoundKills(int iClient);

forward void KDM_OnAchivementUnlocked(int iClient, Achivements aAchivement);
