//King's Deathmatch: Developed by King Nothing.

#pragma semicolon 1

//#define DEBUG

#define PLUGIN_AUTHOR "RockZehh"
#define PLUGIN_VERSION "1.2.0"

#include <sourcemod>
#include <morecolors>
#include <sdktools>
#include <sdkhooks>
#include <smlib/clients>
#include <geoip>
#undef REQUIRE_PLUGIN
#include <updater>

#pragma newdecls required

#define Grenade 10
#define RPG_Round 8

#define SUIT_DEVICE_BREATHER	0x00000004
#define SUIT_DEVICE_FLASHLIGHT	0x00000002
#define SUIT_DEVICE_SPRINT		0x00000001

#define UPDATE_URL    "https://raw.githubusercontent.com/rockzehh/kingsdeathmatch/master/addons/sourcemod/updater.txt"

bool g_bAllKills;
bool g_bDefault357;
bool g_bJumpBoost[MAXPLAYERS + 1];
bool g_bNoFallDamage;
bool g_bPlayer[MAXPLAYERS + 1];
bool g_bRPG;

char g_sClientsDatabase[PLATFORM_MAX_PATH];

ConVar g_cvCrowbarDamage;
ConVar g_cvDefault357;
ConVar g_cvHealthBoost;
ConVar g_cvHealthModifier;
ConVar g_cvJumpBoost;
ConVar g_cvNoFallDamage;
ConVar g_cvShowAllKills;
ConVar g_cvSpawnRPG;
ConVar g_cvUpgradePriceDistort;
ConVar g_cvUpgradePriceHealthBoost;
ConVar g_cvUpgradePriceJumpBoost;

float g_fCommand_Duration[] = 
{
	60.0, //Distort
	120.0, //Jump Boost
};
float g_fHealthModifier;
float g_fJumpBoost;

Handle g_hAdvertisments;
Handle g_hStatHud[MAXPLAYERS + 1];

int g_iAdvertisment = 1;
int g_iAllDeaths[MAXPLAYERS + 1];
int g_iAllKills[MAXPLAYERS + 1];
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
int g_iCrowbarDamage;
int g_iDeaths[MAXPLAYERS + 1];
int g_iHealthBoost;
int g_iKills[MAXPLAYERS + 1];
int g_iUpgrade_Prices[] = 
{
	125, //Distort
	500, //Health Boost
	200, //Jump Boost
};

//Plugin Information
public Plugin myinfo = 
{
	name = "King's Deathmatch", 
	author = PLUGIN_AUTHOR, 
	description = "A custom deathmatch plugin for Half-Life 2: Deathmatch.", 
	version = PLUGIN_VERSION, 
	url = "https://github.com/rockzehh/kings-deathmatch"
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
	char sPath[PLATFORM_MAX_PATH];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}

	BuildPath(Path_SM, sPath, sizeof(sPath), "data/kingsdeathmatch");
	if (!DirExists(sPath))
	{
		CreateDirectory(sPath, 511);
	}

	BuildPath(Path_SM, g_sClientsDatabase, PLATFORM_MAX_PATH, "data/kingsdeathmatch/clients.txt");

	CreateConVar("kings-deathmatch", "1", "Notifies the server that the plugin is running.");
	g_cvCrowbarDamage = CreateConVar("kdm_crowbar_damage", "250", "Will be added later.");
	g_cvDefault357 = CreateConVar("kdm_default_weapon_357", "1", "Will be added later.", _, true, 0.1, true, 1.0);
	g_cvHealthBoost = CreateConVar("kdm_credits_healthboost", "75", "Will be added later.");
	g_cvHealthModifier = CreateConVar("kdm_health_modifier", "0.5", "Will be added later.");
	g_cvJumpBoost = CreateConVar("kdm_credits_jumpboost", "500.0", "Will be added later.");
	g_cvNoFallDamage = CreateConVar("kdm_npfalldamage", "1", "Will be added later.", _, true, 0.1, true, 1.0);
	g_cvShowAllKills = CreateConVar("kdm_hud_showallkills", "1", "Will be added later.", _, true, 0.1, true, 1.0);
	g_cvSpawnRPG = CreateConVar("kdm_allow_rpg", "1", "Will be added later.", _, true, 0.1, true, 1.0);
	g_cvUpgradePriceDistort = CreateConVar("kdm_credits_distort_price", "125", "Will be added later.");
	g_cvUpgradePriceHealthBoost = CreateConVar("kdm_credits_healthboost_price", "350", "Will be added later.");
	g_cvUpgradePriceJumpBoost = CreateConVar("kdm_credits_jumpboost_price", "175", "Will be added later.");
	CreateConVar("kdm_version", PLUGIN_VERSION, "The version of the plugin the server is running.");

	g_bAllKills = g_cvShowAllKills.BoolValue;
	g_iCrowbarDamage = g_cvCrowbarDamage.IntValue;
	g_bDefault357 = g_cvDefault357.BoolValue;
	g_iHealthBoost = g_cvHealthBoost.IntValue;
	g_fHealthModifier = g_cvHealthModifier.FloatValue;
	g_fJumpBoost = g_cvJumpBoost.FloatValue;
	g_bNoFallDamage = g_cvNoFallDamage.BoolValue;
	g_bRPG = g_cvSpawnRPG.BoolValue;

	g_iUpgrade_Prices[0] = g_cvUpgradePriceDistort.IntValue;
	g_iUpgrade_Prices[1] = g_cvUpgradePriceHealthBoost.IntValue;
	g_iUpgrade_Prices[2] = g_cvUpgradePriceJumpBoost.IntValue;

	g_cvCrowbarDamage.AddChangeHook(OnConVarsChanged);
	g_cvDefault357.AddChangeHook(OnConVarsChanged);
	g_cvHealthBoost.AddChangeHook(OnConVarsChanged);
	g_cvHealthModifier.AddChangeHook(OnConVarsChanged);
	g_cvJumpBoost.AddChangeHook(OnConVarsChanged);
	g_cvNoFallDamage.AddChangeHook(OnConVarsChanged);
	g_cvShowAllKills.AddChangeHook(OnConVarsChanged);
	g_cvSpawnRPG.AddChangeHook(OnConVarsChanged);
	g_cvUpgradePriceDistort.AddChangeHook(OnConVarsChanged);
	g_cvUpgradePriceHealthBoost.AddChangeHook(OnConVarsChanged);
	g_cvUpgradePriceJumpBoost.AddChangeHook(OnConVarsChanged);

	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	RegConsoleCmd("sm_boost", Command_JumpBoost, "Gives you a big jump boost.");
	RegConsoleCmd("sm_credits", Command_Credits, "Brings up the credit menu.");
	RegConsoleCmd("sm_distort", Command_Distort, "Distorts your player model.");
	RegConsoleCmd("sm_healthboost", Command_HealthBoost, "Adds a small boost of health.");
	
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
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
	
	g_hStatHud[iClient] = CreateTimer(0.1, Timer_StatHud, iClient, TIMER_REPEAT);
	
	g_iAllDeaths[iClient] = 0;
	g_iAllKills[iClient] = 0;
	g_iCredits[iClient] = 0;
	g_iDeaths[iClient] = 0;
	g_iKills[iClient] = 0;
	
	GetClientIP(iClient, sIP, sizeof(sIP));
	
	GeoipCode3(sIP, sCountry);
	
	Format(sName, sizeof(sName), "[%s] %N", StrEqual(sCountry, "") ? "USA" : sCountry, iClient);
	
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
	
	CloseHandle(g_hStatHud[iClient]);
	
	SaveClient(iClient);

	g_iAllDeaths[iClient] = 0;
	g_iAllKills[iClient] = 0;
	g_iCredits[iClient] = 0;
	g_iDeaths[iClient] = 0;
	g_iKills[iClient] = 0;
}

public void OnConVarsChanged(ConVar convar, char[] oldValue, char[] newValue)
{
	g_bAllKills = g_cvShowAllKills.BoolValue;
	g_iCrowbarDamage = g_cvCrowbarDamage.IntValue;
	g_bDefault357 = g_cvDefault357.BoolValue;
	g_iHealthBoost = g_cvHealthBoost.IntValue;
	g_fHealthModifier = g_cvHealthModifier.FloatValue;
	g_fJumpBoost = g_cvJumpBoost.FloatValue;
	g_bNoFallDamage = g_cvNoFallDamage.BoolValue;
	g_bRPG = g_cvSpawnRPG.BoolValue;

	g_iUpgrade_Prices[0] = g_cvUpgradePriceDistort.IntValue;
	g_iUpgrade_Prices[1] = g_cvUpgradePriceHealthBoost.IntValue;
	g_iUpgrade_Prices[2] = g_cvUpgradePriceJumpBoost.IntValue;
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVel[3], float fAngles[3], int &iWeapon, int &iSubtype, int &iCmdnum, int &iTickcount, int &iSeed, int iMouse[2])
{
	int iFlags = GetEntityFlags(iClient);
	float fVelocity[3];
	
	if (iButtons & IN_JUMP && iFlags & FL_ONGROUND)
	{
		GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", fVelocity);
		
		fVelocity[2] = g_bJumpBoost[iClient] ? g_fJumpBoost : 100.0;
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
	char sDescription[128];
	Menu hMenu = new Menu(Menu_Credits, MENU_ACTIONS_ALL);
	
	hMenu.SetTitle("Credit Menu (%i credits)", g_iCredits[iClient]);
	
	Format(sDescription, sizeof(sDescription), "Distort | %i Credits", g_iUpgrade_Prices[0]);
	hMenu.AddItem("opt_distort", sDescription);

	Format(sDescription, sizeof(sDescription), "Health Boost +%ihp | %i Credits", g_iHealthBoost, g_iUpgrade_Prices[1]);
	hMenu.AddItem("opt_healthboost", sDescription);

	Format(sDescription, sizeof(sDescription), "Jump Boost | %i Credits", g_iUpgrade_Prices[2]);
	hMenu.AddItem("opt_boost", sDescription);
	
	hMenu.ExitButton = true;
	
	hMenu.Display(iClient, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public Action Command_Distort(int iClient, int iArgs)
{
	if (g_iCredits[iClient] <= g_iUpgrade_Prices[0])
	{
		CPrintToChat(iClient, "You do not have enough credits.");
	} else {
		g_iCredits[iClient] -= g_iUpgrade_Prices[0];

		int iCommandDuration = view_as<int>(g_fCommand_Duration[0]);
		
		CPrintToChat(iClient, "You have bought {green}distort{default} for {green}%i{default} credits for {green}%i{default} seconds.", g_iUpgrade_Prices[0], iCommandDuration);
		
		SetEntityRenderFx(iClient, RENDERFX_DISTORT);
		
		CreateTimer(g_fCommand_Duration[0], Timer_Visible, iClient);
		
		SaveClient(iClient);
	}
	
	return Plugin_Handled;
}

public Action Command_HealthBoost(int iClient, int iArgs)
{
	if (g_iCredits[iClient] <= g_iUpgrade_Prices[1])
	{
		CPrintToChat(iClient, "You do not have enough credits.");
	} else {
		g_iCredits[iClient] -= g_iUpgrade_Prices[1];
		
		CPrintToChat(iClient, "You have bought {green}health boost{default} for {green}%i{default} credits. {green}%ihp{default} has been added to your health.", g_iUpgrade_Prices[1], g_iHealthBoost);
		
		int iNewHealth = (GetClientHealth(iClient) + g_iHealthBoost);
		
		SetEntityHealth(iClient, iNewHealth);
		
		SaveClient(iClient);
	}
	
	return Plugin_Handled;
}

public Action Command_JumpBoost(int iClient, int iArgs)
{
	if (g_iCredits[iClient] <= g_iUpgrade_Prices[2])
	{
		CPrintToChat(iClient, "You do not have enough credits.");
	} else {
		g_iCredits[iClient] -= g_iUpgrade_Prices[2];

		int iCommandDuration = view_as<int>(g_fCommand_Duration[0]);
		
		CPrintToChat(iClient, "You have bought {green}jump boost{default} for {green}%i{default} credits for {green}%i{default} seconds.", g_iUpgrade_Prices[2], iCommandDuration);
		
		g_bJumpBoost[iClient] = true;
		
		CreateTimer(g_fCommand_Duration[1], Timer_JumpBoost, iClient);
		
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
	
	int iCredits = LoadInteger(kvVault, sAuthID, "credits", 1500);
	
	g_iAllDeaths[iClient] = LoadInteger(kvVault, sAuthID, "all_deaths", 0);
	
	g_iAllKills[iClient] = LoadInteger(kvVault, sAuthID, "all_kills", 0);
	
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
	if(iDamagetype == DMG_FALL && g_bNoFallDamage)
	{
		return Plugin_Handled;
	}
	
	int iNewHealth = (GetClientHealth(iClient) - RoundFloat((fDamage * g_fHealthModifier)));
	
	if (StrEqual(sWeapon, "weapon_crowbar"))
	{
		iNewHealth += g_iCrowbarDamage;
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
	
	SaveInteger(kvVault, sAuthID, "credits", g_iCredits[iClient]);
	SaveInteger(kvVault, sAuthID, "all_deaths", g_iDeaths[iClient]);
	SaveInteger(kvVault, sAuthID, "all_Kills", g_iKills[iClient]);
	
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
		if (iAttacker == -1 || iAttacker == 0)
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
	if (g_bRPG)
		GivePlayerItem(iClient, "weapon_rpg");

	GivePlayerItem(iClient, "weapon_stunstick");
	GivePlayerItem(iClient, "weapon_shotgun");
	GivePlayerItem(iClient, "weapon_pistol");
	GivePlayerItem(iClient, "weapon_physcannon");
	GivePlayerItem(iClient, "weapon_smg1");
	GivePlayerItem(iClient, "weapon_crossbow");
	GivePlayerItem(iClient, "weapon_frag");
	GivePlayerItem(iClient, "weapon_ar2");
	GivePlayerItem(iClient, "weapon_357");

	if(g_bDefault357)
		Client_ChangeWeapon(iClient, "weapon_357");
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
	char sStatsHud[2][128];
	
	float fAllKTD, fRoundKTD;
	
	int iTimeleft;
	
	GetMapTimeLeft(iTimeleft);
	
	if (IsClientInGame(iClient))
	{
		fAllKTD = ((g_iAllDeaths[iClient] == 0) ? 0.0 : view_as<float>(g_iAllKills[iClient]) / view_as<float>(g_iAllDeaths[iClient]));//FloatDiv(float(g_iKills[iClient]), float(g_iDeaths[iClient])));
		fRoundKTD = ((g_iDeaths[iClient] == 0) ? 0.0 : view_as<float>(g_iKills[iClient]) / view_as<float>(g_iDeaths[iClient]));//FloatDiv(float(g_iKills[iClient]), float(g_iDeaths[iClient])));
		
		if(g_bAllKills)
		{
			Format(sStatsHud[0], sizeof(sStatsHud[]), "Name: %N\nCredits: %i\n%.1f All-Time KTD", iClient, g_iCredits[iClient], fAllKTD);
		}else{
			Format(sStatsHud[0], sizeof(sStatsHud[]), "Name: %N\nCredits: %i", iClient, g_iCredits[iClient]);
		}
		Format(sStatsHud[1], sizeof(sStatsHud[]), "Stats:\n%i Kills\n%i Deaths\n%.1f Round KTD\nTimeleft: %d:%02d", g_iKills[iClient], g_iDeaths[iClient], fRoundKTD, iTimeleft <= 0 ? 00 : (iTimeleft / 60), iTimeleft <= 0 ? 00 : (iTimeleft % 60));
		
		SetHudTextParams(0.010, 0.010, 0.5, 255, 128, 0, 128, 0, 0.1, 0.1, 0.1);
		ShowHudText(iClient, -1, sStatsHud[0]);
		SetHudTextParams(-0.010, 0.010, 0.5, 255, 128, 0, 128, 0, 0.1, 0.1, 0.1);
		ShowHudText(iClient, -1, sStatsHud[1]);
		
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