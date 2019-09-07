//Raging Scout Deathmatch

#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "RockZehh"
#define PLUGIN_VERSION "1.0.0.0-0"

#include <sourcemod>
#include <morecolors>
#include <sdktools>
#include <sdkhooks>
#include <geoip>
#include <smlib>
#undef REQUIRE_PLUGIN
#include <updater>

#pragma newdecls required

#define Grenade 10
#define RPG_Round 8
#define SUIT_DEVICE_BREATHER	0x00000004
#define SUIT_DEVICE_FLASHLIGHT	0x00000002
#define SUIT_DEVICE_SPRINT		0x00000001
#define UPDATE_URL    "https://bitbucket.org/rockzehh/ragingscout-dm/raw/master/addons/sourcemod/updater.txt"

bool g_bJumpBoost[MAXPLAYERS + 1];
bool g_bPlayer[MAXPLAYERS + 1];

char g_sClientsDatabase[PLATFORM_MAX_PATH];

Handle g_hAdvertisments;
Handle g_hCreditHud[MAXPLAYERS + 1];
Handle g_hStatHud[MAXPLAYERS + 1];

int g_iAdvertisment = 1;
int g_iClip_Sizes[] = 
{
	0,  //skip
	30,  //AR2            pri
	255,  //AR2AltFire    sec
	18,  //Pistol        pri
	45,  //SMG1            pri
	6,  //357            pri
	1,  //XBowBolt        pri
	6,  //Buckshot        pri
	255,  //RPG_Round        pri
	255,  //SMG1_Grenade    sec
	255,  //Grenade        pri
	255,  //Slam            sec
};
int g_iCredits[MAXPLAYERS + 1];
int g_iDeaths[MAXPLAYERS + 1];
int g_iKills[MAXPLAYERS + 1];

//Plugin Information
public Plugin myinfo = 
{
	name = "Raging Scout", 
	author = PLUGIN_AUTHOR, 
	description = "The backbone behind Raging Scout Deathmatch.", 
	version = PLUGIN_VERSION, 
	url = "https://bitbucket.org/rockzehh/ragingscout-dm"
};

//When a library is added
public void OnLibraryAdded(const char[] sName)
{
	if (StrEqual(sName, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

//Plugin Voids
public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	RegConsoleCmd("sm_credits", Command_Credits, "Brings up the credit menu.");
	RegConsoleCmd("sm_distort", Command_Distort, "Distorts your player model.");
	RegConsoleCmd("sm_healthboost", Command_HealthBoost, "Adds 50hp to your health.");
	RegConsoleCmd("sm_boost", Command_JumpBoost, "Gives you a big jump boost.");
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
	
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	
	BuildPath(Path_SM, g_sClientsDatabase, PLATFORM_MAX_PATH, "data/ragingscout/clients.txt");
}

public void OnPluginEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public void OnMapStart()
{
	char sClassname[64];
	
	for (int i = 0; i < GetMaxEntities(); i++)
	{
		if (IsValidEntity(i))
		{
			GetEntityClassname(i, sClassname, sizeof(sClassname));
			
			if (StrEqual(sClassname, "weapon_rpg") || StrEqual(sClassname, "item_rpg_round"))
			{
				AcceptEntityInput(i, "kill");
			}
		}
	}
	
	g_hAdvertisments = CreateTimer(45.0, Timer_Advertisment, _, TIMER_REPEAT);
	
	CreateTimer(60.0, Timer_RPGRemove, _, TIMER_REPEAT);
}

public void OnMapEnd()
{
	CloseHandle(g_hAdvertisments);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public void OnClientPutInServer(int iClient)
{
	char sIP[32], sCountry[4], sName[64];
	
	g_bJumpBoost[iClient] = false;
	g_bPlayer[iClient] = true;
	
	g_hCreditHud[iClient] = CreateTimer(0.1, Timer_CreditHud, iClient, TIMER_REPEAT);
	g_hStatHud[iClient] = CreateTimer(0.1, Timer_StatHud, iClient, TIMER_REPEAT);
	
	g_iDeaths[iClient] = 0;
	g_iKills[iClient] = 0;
	
	GetClientIP(iClient, sIP, sizeof(sIP));
	
	GeoipCode3(sIP, sCountry);
	
	Format(sName, sizeof(sName), "[%s] %N", sCountry, iClient);
	
	SetClientName(iClient, sName);
	
	SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHookEx(iClient, SDKHook_FireBulletsPost, FireBulletsPost);
	SDKHookEx(iClient, SDKHook_WeaponSwitchPost, WeaponSwitchPost);
	
	LoadClient(iClient);
}

public void OnClientDisconnect(int iClient)
{
	g_bJumpBoost[iClient] = false;
	g_bPlayer[iClient] = false;
	
	SDKUnhook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
	
	CloseHandle(g_hCreditHud[iClient]);
	CloseHandle(g_hStatHud[iClient]);
	
	SaveClient(iClient);
	
	g_iCredits[iClient] = 0;
	g_iDeaths[iClient] = 0;
	g_iKills[iClient] = 0;
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVel[3], float fAngles[3], int &iWeapon, int &iSubtype, int &iCmdnum, int &iTickcount, int &iSeed, int iMouse[2])
{
	int iFlags = GetEntityFlags(iClient);
	float fVelocity[3];
	
	if (iButtons & IN_JUMP && iFlags & FL_ONGROUND)
	{
		GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", fVelocity);
		
		fVelocity[2] = g_bJumpBoost[iClient] ? 450.0 : 100.0;
		TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, fVelocity);
	}
	
	int iBitsActiveDevices = GetEntProp(iClient, Prop_Send, "m_bitsActiveDevices");
	
	if (iBitsActiveDevices & SUIT_DEVICE_SPRINT)
	{
		SetEntPropFloat(iClient, Prop_Data, "m_flSuitPowerLoad", 0.0);
		SetEntProp(iClient, Prop_Send, "m_bitsActiveDevices", iBitsActiveDevices & ~SUIT_DEVICE_SPRINT);
	}
	
	if (iBitsActiveDevices & SUIT_DEVICE_BREATHER)
	{
		SetEntPropFloat(iClient, Prop_Data, "m_flSuitPowerLoad", 0.0);
		SetEntProp(iClient, Prop_Send, "m_bitsActiveDevices", iBitsActiveDevices & ~SUIT_DEVICE_BREATHER);
	}
}

//Plugin Commands
public Action Command_Credits(int iClient, int iArgs)
{
	Menu hMenu = new Menu(Menu_Credits, MENU_ACTIONS_ALL);
	
	hMenu.SetTitle("Credit Menu (%i credits)", g_iCredits[iClient]);
	
	hMenu.AddItem("opt_distort", "Distort | 125 Credits");
	hMenu.AddItem("opt_healthboost", "Health Boost | 500 Credits");
	hMenu.AddItem("opt_boost", "Jump Boost | 250 Credits");
	
	hMenu.ExitButton = true;
	
	hMenu.Display(iClient, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public Action Command_Distort(int iClient, int iArgs)
{
	if (g_iCredits[iClient] <= 125)
	{
		CPrintToChat(iClient, "You do not have enough credits.");
	} else {
		g_iCredits[iClient] -= 125;
		
		CPrintToChat(iClient, "You have bought {green}distort{default} for {green}125{default} credits for {green}60{default} seconds.");
		
		SetEntityRenderFx(iClient, RENDERFX_DISTORT);
		
		CreateTimer(60.0, Timer_Visible, iClient);
		
		SaveClient(iClient);
	}
	
	return Plugin_Handled;
}

public Action Command_HealthBoost(int iClient, int iArgs)
{
	if (g_iCredits[iClient] <= 500)
	{
		CPrintToChat(iClient, "You do not have enough credits.");
	} else {
		g_iCredits[iClient] -= 500;
		
		CPrintToChat(iClient, "You have bought {green}health boost{default} for {green}500{default} credits. {green}50hp{default} has been added to your health.");
		
		int iNewHealth = (GetClientHealth(iClient) + 50);
		
		SetEntityHealth(iClient, iNewHealth);
		
		SaveClient(iClient);
	}
	
	return Plugin_Handled;
}

public Action Command_JumpBoost(int iClient, int iArgs)
{
	if (g_iCredits[iClient] <= 250)
	{
		CPrintToChat(iClient, "You do not have enough credits.");
	} else {
		g_iCredits[iClient] -= 250;
		
		CPrintToChat(iClient, "You have bought {green}jump boost{default} for {green}250{default} credits for {green}120{default} seconds.");
		
		g_bJumpBoost[iClient] = true;
		
		CreateTimer(120.0, Timer_JumpBoost, iClient);
		
		SaveClient(iClient);
	}
	
	return Plugin_Handled;
}

//Plugin Stocks/Extra Voids

//SDKHooks
public void FireBulletsPost(int iClient, int iShots, char[] sWeaponname)
{
	int iWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	
	if (iWeapon != -1)
	{
		ReFillWeapon(iClient, iWeapon);
	}
}

public int LoadInteger(KeyValues kvVault, char[] sKey, char[] sSaveKey, int iDefaultValue)
{
	kvVault.JumpToKey(sKey, false);
	
	int iVariable = kvVault.GetNum(sSaveKey, iDefaultValue);
	
	kvVault.Rewind();
	
	return iVariable;
}

public void LoadClient(int iClient)
{
	char sAuthID[64];
	
	GetClientAuthId(iClient, AuthId_Steam2, sAuthID, sizeof(sAuthID));
	
	KeyValues kvVault = new KeyValues("Credits");
	
	kvVault.ImportFromFile(g_sClientsDatabase);
	
	kvVault.JumpToKey(sAuthID, false);
	
	int iCredits = LoadInteger(kvVault, sAuthID, "Credits", 1500);
	
	g_iDeaths[iClient] = LoadInteger(kvVault, sAuthID, "Deaths", 0);
	
	g_iKills[iClient] = LoadInteger(kvVault, sAuthID, "Kills", 0);
	
	kvVault.Rewind();
	
	g_iCredits[iClient] = iCredits;
	
	kvVault.Close();
}

//SDKHooks
public Action OnTakeDamage(int iClient, int &iAttacker, int &iInflictor, float &fDamage, int &iDamagetype)
{
	bool bSuicide;
	char sWeapon[64];
	
	if (iAttacker == iClient)
		bSuicide = true;
	
	if(g_bPlayer[iClient] && g_bPlayer[iAttacker])
	{
		GetClientWeapon(bSuicide ? iClient : iAttacker, sWeapon, sizeof(sWeapon));
	}
	
	if(iDamagetype == DMG_FALL)
	{
		return Plugin_Handled;
	}
	
	int iNewHealth = (GetClientHealth(iClient) - RoundFloat((fDamage * 0.5)));
	
	if (StrEqual(sWeapon, "weapon_crowbar"))
	{
		iNewHealth = -250;
	}
	
	SetEntityHealth(iClient, iNewHealth);
	
	return Plugin_Continue;
}

public void ReFillWeapon(int iClient, int iWeapon)
{
	int iPrimaryAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
	
	if (iPrimaryAmmoType != -1)
	{
		if (iPrimaryAmmoType != RPG_Round && iPrimaryAmmoType != Grenade)
		{
			SetEntProp(iWeapon, Prop_Send, "m_iClip1", g_iClip_Sizes[iPrimaryAmmoType]);
		}
		SetEntProp(iClient, Prop_Send, "m_iAmmo", 255, _, iPrimaryAmmoType);
	}
	
	int iSecondaryAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iSecondaryAmmoType");
	
	if (iSecondaryAmmoType != -1)
	{
		SetEntProp(iClient, Prop_Send, "m_iAmmo", 255, _, iSecondaryAmmoType);
	}
}

public void SaveClient(int iClient)
{
	char sAuthID[64];
	
	GetClientAuthId(iClient, AuthId_Steam2, sAuthID, sizeof(sAuthID));
	
	KeyValues kvVault = new KeyValues("Credits");
	
	kvVault.ImportFromFile(g_sClientsDatabase);
	
	SaveInteger(kvVault, sAuthID, "Credits", g_iCredits[iClient]);
	SaveInteger(kvVault, sAuthID, "Deaths", g_iDeaths[iClient]);
	SaveInteger(kvVault, sAuthID, "Kills", g_iKills[iClient]);
	
	kvVault.ExportToFile(g_sClientsDatabase);
	
	kvVault.Close();
}

public void SaveInteger(KeyValues kvVault, char[] sKey, char[] sSaveKey, int iVariable)
{
	if (iVariable == -1)
	{
		kvVault.JumpToKey(sKey, true);
		
		kvVault.DeleteKey(sSaveKey);
		
		kvVault.Rewind();
		
	} else {
		kvVault.JumpToKey(sKey, true);
		
		kvVault.SetNum(sSaveKey, iVariable);
		
		kvVault.Rewind();
	}
}

//SDKHooks
public void WeaponSwitchPost(int iClient, int iWeapon)
{
	if (iWeapon != -1)
	{
		ReFillWeapon(iClient, iWeapon);
	}
}

//Plugin Menus
public int Menu_Credits(Menu hMenu, MenuAction iAction, int iParam1, int iParam2)
{
	switch (iAction)
	{
		case MenuAction_Start:
		{
			PrintToServer("Displaying menu");
		}
		
		case MenuAction_Display:
		{  }
		
		case MenuAction_Select:
		{
			char sInfo[64];
			
			hMenu.GetItem(iParam2, sInfo, sizeof(sInfo));
			
			if (StrEqual(sInfo, "opt_distort"))
			{
				FakeClientCommand(iParam1, "sm_distort");
			} else if (StrEqual(sInfo, "opt_boost"))
			{
				FakeClientCommand(iParam1, "sm_boost");
			} else if (StrEqual(sInfo, "opt_healthboost"))
			{
				FakeClientCommand(iParam1, "sm_healthboost");
			}
		}
		
		case MenuAction_Cancel:
		{  }
		
		case MenuAction_End:
		{
			delete hMenu;
		}
		
		case MenuAction_DrawItem:
		{  }
		
		case MenuAction_DisplayItem:
		{  }
	}
	
	return 0;
}

//Plugin Events
public Action Event_PlayerDeath(Handle hEvent, char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	
	int iRandom = GetRandomInt(7, 16);
	
	if (iAttacker != iClient)
	{
		if (iAttacker == -1)
		{
			g_iDeaths[iClient]++;
		} else {
			g_iKills[iAttacker]++;
			g_iDeaths[iClient]++;
			
			g_iCredits[iAttacker] += iRandom;
			
			CPrintToChatAll("{green}%N{default} got {green}%i{default} credits for killing {green}%N{default}!", iAttacker, iRandom, iClient);
			
			SaveClient(iClient);
		}
	} else {
		g_iKills[iClient]--;
		g_iDeaths[iClient]++;
		
		g_iCredits[iClient] -= iRandom;
		
		CPrintToChatAll("{green}%N{default} has lost {green}%i{default} credits for killing themselves.", iClient, iRandom);
	}
	
	SaveClient(iClient);
	
	CreateTimer(0.1, Timer_Fire, iClient);
	
	CreateTimer(1.5, Timer_Dissolve, iClient);
}

public Action Event_PlayerSpawn(Handle hEvent, char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	CreateTimer(0.1, Timer_Guns, iClient);
}

//Plugin Timers
public Action Timer_Advertisment(Handle hTimer)
{
	char sAdvertisment[256];
	
	switch (g_iAdvertisment)
	{
		case 1:
		{
			Format(sAdvertisment, sizeof(sAdvertisment), "We have a {green}credits{default} system. Type {green}!credits{default} to use it.");
			
			g_iAdvertisment = 2;
		}
		
		case 2:
		{
			Format(sAdvertisment, sizeof(sAdvertisment), "Latest Update [{green}10/23/18{default}]: We have added a buyable {green}health boost{default}. Type {green}!credits{default} for more information.");
			
			g_iAdvertisment = 3;
		}
		
		case 3:
		{
			Format(sAdvertisment, sizeof(sAdvertisment), "Type {green}rtv{default} to vote to change the map.");
			
			g_iAdvertisment = 1;
		}
	}
	
	CPrintToChatAll(sAdvertisment);
}

public Action Timer_CreditHud(Handle hTimer, any iClient)
{
	char sCreditHud[128];
	
	if (IsClientInGame(iClient))
	{
		Format(sCreditHud, sizeof(sCreditHud), "Name: %N\nCredits: %i", iClient, g_iCredits[iClient]);
		
		SetHudTextParams(-0.010, 0.010, 0.5, 255, 128, 0, 128, 0, 0.1, 0.1, 0.1);
		ShowHudText(iClient, -1, sCreditHud);
	}
}

public Action Timer_Dissolve(Handle hTimer, any iClient)
{
	int iRagdoll = GetEntPropEnt(iClient, Prop_Send, "m_hRagdoll");
	
	int iDissolver = CreateEntityByName("env_entity_dissolver");
	
	DispatchKeyValue(iRagdoll, "targetname", "dissolved");
	
	DispatchKeyValue(iDissolver, "dissolvetype", "3");
	DispatchKeyValue(iDissolver, "target", "dissolved");
	AcceptEntityInput(iDissolver, "Dissolve");
	
	AcceptEntityInput(iDissolver, "Kill");
}

public Action Timer_Fire(Handle hTimer, any iClient)
{
	int iRagdoll = GetEntPropEnt(iClient, Prop_Send, "m_hRagdoll");
	
	IgniteEntity(iRagdoll, 5.0);
}

public Action Timer_Guns(Handle hTimer, any iClient)
{
	GivePlayerItem(iClient, "weapon_crowbar");
	//GivePlayerItem(iClient, "weapon_rpg");
	GivePlayerItem(iClient, "weapon_stunstick");
	GivePlayerItem(iClient, "weapon_shotgun");
	GivePlayerItem(iClient, "weapon_pistol");
	GivePlayerItem(iClient, "weapon_physcannon");
	GivePlayerItem(iClient, "weapon_smg1");
	GivePlayerItem(iClient, "weapon_crossbow");
	GivePlayerItem(iClient, "weapon_frag");
	GivePlayerItem(iClient, "weapon_ar2");
	GivePlayerItem(iClient, "weapon_357");
}

public Action Timer_JumpBoost(Handle hTimer, any iClient)
{
	if (IsClientConnected(iClient))
	{
		g_bJumpBoost[iClient] = false;
		
		CPrintToChat(iClient, "Your {green}jump-boost{default} has worn off.");
	}
}

public Action Timer_StatHud(Handle hTimer, any iClient)
{
	char sStatsHud[128];
	
	float fKTD;
	
	int iTimeleft;
	
	GetMapTimeLeft(iTimeleft);
	
	if (IsClientInGame(iClient))
	{
		fKTD = ((g_iDeaths[iClient] == 0) ? 0.0 : FloatDiv(float(g_iKills[iClient]), float(g_iDeaths[iClient])));
		
		Format(sStatsHud, sizeof(sStatsHud), "Stats:\n%i Kills\n%i Deaths\n%.1f KTD Ratio\n\nTimeleft: %d:%02d", g_iKills[iClient], g_iDeaths[iClient], fKTD, (iTimeleft / 60), (iTimeleft % 60));
		
		SetHudTextParams(0.010, 0.010, 0.5, 255, 128, 0, 128, 0, 0.1, 0.1, 0.1);
		ShowHudText(iClient, -1, sStatsHud);
	}
}

public Action Timer_RPGRemove(Handle hTimer)
{
	char sClassname[64];
	
	for (int i = 0; i < GetMaxEntities(); i++)
	{
		if (IsValidEntity(i))
		{
			GetEntityClassname(i, sClassname, sizeof(sClassname));
			
			if (StrEqual(sClassname, "weapon_rpg") || StrEqual(sClassname, "item_rpg_round"))
			{
				AcceptEntityInput(i, "kill");
			}
		}
	}
}

public Action Timer_Visible(Handle hTimer, any iClient)
{
	if (IsClientConnected(iClient))
	{
		SetEntityRenderFx(iClient, RENDERFX_NONE);
		
		CPrintToChat(iClient, "Your {green}distort{default} has worn off.");
	}
} 