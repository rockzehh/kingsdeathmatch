//King's Deathmatch: Developed by King Nothing.

#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "RockZehh"
#define PLUGIN_VERSION "1.2.1"

#define MAX_BUTTONS 26

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
bool g_bDistort[MAXPLAYERS + 1];
bool g_bJumpBoost[MAXPLAYERS + 1];
bool g_bLongJump[MAXPLAYERS + 1][2];
bool g_bLongJumpPressed[MAXPLAYERS + 1];
bool g_bLongJumpSound;
bool g_bMenu;
bool g_bNoAdvertisements;
bool g_bNoFallDamage;
bool g_bPlayer[MAXPLAYERS + 1];
bool g_bPreferPrivateMatches[MAXPLAYERS + 1];
bool g_bPrivateMatchRunning;
bool g_bPrivateMatches;
bool g_bRPG;

char g_sAdvertisementsDatabase[PLATFORM_MAX_PATH];
char g_sClientsDatabase[PLATFORM_MAX_PATH];
char g_sDefaultWeapon[MAXPLAYERS + 1][64];
char g_sServerPassword[128];

ConVar g_cvAllowPrivateMatches;
ConVar g_cvCrowbarDamage;
ConVar g_cvDisableAdvertisements;
ConVar g_cvHealthBoost;
ConVar g_cvHealthModifier;
ConVar g_cvJumpBoost;
ConVar g_cvLongJumpPush;
ConVar g_cvLongJumpSound;
ConVar g_cvNoFallDamage;
ConVar g_cvPassword;
ConVar g_cvShowAllKills;
ConVar g_cvSpawnRPG;
ConVar g_cvUpgradePriceDistort;
ConVar g_cvUpgradePriceHealthBoost;
ConVar g_cvUpgradePriceJumpBoost;
ConVar g_cvUpgradePriceLongJump;
ConVar g_cvUseSourceMenus;

float g_fCommand_Duration[] = 
{
	60.0, //Distort
	120.0, //Jump Boost
};
float g_fHealthModifier;
float g_fJumpBoost;
float g_fPushForce;

Handle g_hAdvertisements;
Handle g_hStatHud[MAXPLAYERS + 1];

int g_iAdvertisement = 1;
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
int g_iLastButton[MAXPLAYERS + 1];
int g_iUpgrade_Prices[] = 
{
	125, //Distort
	500, //Health Boost
	200, //Jump Boost
	2500, //Long Jump
};

KeyValues g_kvAdvertisements;

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
	CreateConVar("kings-deathmatch", "1", "Notifies the server that the plugin is running.");
	g_cvAllowPrivateMatches = CreateConVar("kdm_allow_private_matches", "1", "Will be added later.", _, true, 0.1, true, 1.0);
	g_cvCrowbarDamage = CreateConVar("kdm_crowbar_damage", "500", "Will be added later.");
	g_cvDisableAdvertisements = CreateConVar("kdm_disable_advertisements", "0", "Will be added later.", _, true, 0.1, true, 1.0);
	g_cvHealthBoost = CreateConVar("kdm_credits_healthboost", "75", "Will be added later.");
	g_cvHealthModifier = CreateConVar("kdm_health_modifier", "0.5", "Will be added later.");
	g_cvJumpBoost = CreateConVar("kdm_credits_jumpboost", "500.0", "Will be added later.");
	g_cvLongJumpPush = CreateConVar("kdm_longjump_push_force", "500.0", "Will be added later.");
	g_cvLongJumpSound = CreateConVar("kdm_longjump_play_sound", "1", "Will be added later.", _, true, 0.1, true, 1.0);
	g_cvNoFallDamage = CreateConVar("kdm_no_fall_damage", "1", "Will be added later.", _, true, 0.1, true, 1.0);
	g_cvPassword = FindConVar("sv_password");
	g_cvShowAllKills = CreateConVar("kdm_hud_showallkills", "1", "Will be added later.", _, true, 0.1, true, 1.0);
	g_cvSpawnRPG = CreateConVar("kdm_allow_rpg", "0", "Will be added later.", _, true, 0.1, true, 1.0);
	g_cvUpgradePriceDistort = CreateConVar("kdm_credits_distort_price", "125", "Will be added later.");
	g_cvUpgradePriceHealthBoost = CreateConVar("kdm_credits_healthboost_price", "350", "Will be added later.");
	g_cvUpgradePriceJumpBoost = CreateConVar("kdm_credits_jumpboost_price", "175", "Will be added later.");
	g_cvUpgradePriceLongJump = CreateConVar("kdm_credits_longjump_price", "2500", "Will be added later.");
	g_cvUseSourceMenus = CreateConVar("kdm_use_source_menus", "0", "Will be added later.", _, true, 0.1, true, 1.0);

	CreateConVar("kdm_version", PLUGIN_VERSION, "The version of the plugin the server is running.");

	g_bAllKills = g_cvShowAllKills.BoolValue;
	g_iCrowbarDamage = g_cvCrowbarDamage.IntValue;
	g_iHealthBoost = g_cvHealthBoost.IntValue;
	g_fHealthModifier = g_cvHealthModifier.FloatValue;
	g_fJumpBoost = g_cvJumpBoost.FloatValue;
	g_bLongJumpSound = g_cvLongJumpSound.BoolValue;
	g_fPushForce = g_cvLongJumpPush.FloatValue;
	g_bMenu = g_cvUseSourceMenus.BoolValue;
	g_bNoAdvertisements = g_cvDisableAdvertisements.BoolValue;
	g_bNoFallDamage = g_cvNoFallDamage.BoolValue;
	g_cvPassword.SetString("");
	g_bPrivateMatches = g_cvAllowPrivateMatches.BoolValue;
	g_bRPG = g_cvSpawnRPG.BoolValue;

	g_iUpgrade_Prices[0] = g_cvUpgradePriceDistort.IntValue;
	g_iUpgrade_Prices[1] = g_cvUpgradePriceHealthBoost.IntValue;
	g_iUpgrade_Prices[2] = g_cvUpgradePriceJumpBoost.IntValue;
	g_iUpgrade_Prices[3] = g_cvUpgradePriceLongJump.IntValue;

	g_cvAllowPrivateMatches.AddChangeHook(OnConVarsChanged);
	g_cvCrowbarDamage.AddChangeHook(OnConVarsChanged);
	g_cvDisableAdvertisements.AddChangeHook(OnConVarsChanged);
	g_cvHealthBoost.AddChangeHook(OnConVarsChanged);
	g_cvHealthModifier.AddChangeHook(OnConVarsChanged);
	g_cvJumpBoost.AddChangeHook(OnConVarsChanged);
	g_cvLongJumpPush.AddChangeHook(OnConVarsChanged);
	g_cvLongJumpSound.AddChangeHook(OnConVarsChanged);
	g_cvNoFallDamage.AddChangeHook(OnConVarsChanged);
	g_cvShowAllKills.AddChangeHook(OnConVarsChanged);
	g_cvSpawnRPG.AddChangeHook(OnConVarsChanged);
	g_cvUpgradePriceDistort.AddChangeHook(OnConVarsChanged);
	g_cvUpgradePriceHealthBoost.AddChangeHook(OnConVarsChanged);
	g_cvUpgradePriceJumpBoost.AddChangeHook(OnConVarsChanged);
	g_cvUpgradePriceLongJump.AddChangeHook(OnConVarsChanged);
	g_cvUseSourceMenus.AddChangeHook(OnConVarsChanged);

	AutoExecConfig(true, "kings-deathmatch");

	char sPath[PLATFORM_MAX_PATH];

	BuildPath(Path_SM, sPath, sizeof(sPath), "data/kingsdeathmatch");
	if (!DirExists(sPath))
	{
		CreateDirectory(sPath, 511);
	}

	BuildPath(Path_SM, g_sAdvertisementsDatabase, PLATFORM_MAX_PATH, "data/kingsdeathmatch/advertisements.txt");
	if(!FileExists(g_sAdvertisementsDatabase))
	{
		g_bNoAdvertisements = false;
	}

	BuildPath(Path_SM, g_sClientsDatabase, PLATFORM_MAX_PATH, "data/kingsdeathmatch/clients.txt");

	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);

	AddCommandListener(Handle_Chat, "say");
	AddCommandListener(Handle_Chat, "say_team");
	
	RegConsoleCmd("sm_boost", Command_HealthBoost, "Adds a boost of health.");
	RegConsoleCmd("sm_credits", Command_Credits, "Brings up the credit menu.");
	RegConsoleCmd("sm_defaultweapon", Command_DefaultWeapon, "Changes the default weapon.");
	RegConsoleCmd("sm_distort", Command_Distort, "Distorts your player model.");
	RegConsoleCmd("sm_hb", Command_HealthBoost, "Adds a boost of health.");
	RegConsoleCmd("sm_health", Command_HealthBoost, "Adds a boost of health.");
	RegConsoleCmd("sm_healthboost", Command_HealthBoost, "Adds a boost of health.");
	RegConsoleCmd("sm_jb", Command_JumpBoost, "Gives you a big jump boost.");
	RegConsoleCmd("sm_jump", Command_JumpBoost, "Gives you a big jump boost.");
	RegConsoleCmd("sm_jumpboost", Command_JumpBoost, "Gives you a big jump boost.");
	RegConsoleCmd("sm_lj", Command_LongJump, "Gives you the long jump module.");
	RegConsoleCmd("sm_longjump", Command_LongJump, "Gives you the long jump module.");
	RegConsoleCmd("sm_private", Command_PrivateMatch, "Sets the match to private with a password.");
	RegConsoleCmd("sm_privatematch", Command_PrivateMatch, "Sets the match to private with a password.");
	RegConsoleCmd("sm_store", Command_Credits, "Brings up the credit menu.");

	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientAuthorized(i))
		{
			OnClientPutInServer(i);
		}
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
		}
	}
	
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}

	g_kvAdvertisements = new KeyValues("Advertisements");
	
	g_kvAdvertisements.ImportFromFile(g_sAdvertisementsDatabase);

	//Sound from Black Mesa: Source (2012 Mod)
	AddFileToDownloadsTable("sound/bms/weapons/jumpmod/jumpmod_long1.mp3");
}

public void OnPluginEnd()
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientAuthorized(i))
		{
			OnClientDisconnect(i);
		}
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			SDKUnhook(i, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
		}
	}

	g_cvPassword.SetString("");

	g_kvAdvertisements.Close();
}

public void OnMapStart()
{
	char sClassname[64];
	
	for (int i = 0; i < GetMaxEntities() * 2; i++)
	{
		if (IsValidEntity(i))
		{
			GetEntityClassname(i, sClassname, sizeof(sClassname));
			
			if ((StrEqual(sClassname, "weapon_rpg") || StrEqual(sClassname, "item_rpg_round")) && !g_bRPG)
			{
				AcceptEntityInput(i, "kill");
			}
		}
	}
	
	g_hAdvertisements = CreateTimer(45.0, Timer_Advertisement, _, TIMER_REPEAT);
	
	CreateTimer(60.0, Timer_RPGRemove, _, TIMER_REPEAT);
	
	g_bPrivateMatchRunning = false;
}

public void OnMapEnd()
{
	CloseHandle(g_hAdvertisements);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			SDKUnhook(i, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
		}
	}

	g_bPrivateMatchRunning = false;
}

public void OnClientPutInServer(int iClient)
{
	char sIP[32], sCountry[4], sName[64];
	
	g_bDistort[iClient] = false;
	g_bJumpBoost[iClient] = false;
	g_bLongJumpPressed[iClient] = false;
	g_bLongJump[iClient][0] = false;
	g_bLongJump[iClient][1] = false;
	g_bPlayer[iClient] = true;
	g_bPreferPrivateMatches[iClient] = false;
	
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
	
	SDKHook(iClient, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	SDKHookEx(iClient, SDKHook_FireBulletsPost, Hook_FireBulletsPost);
	SDKHook(iClient, SDKHook_WeaponCanSwitchTo, Hook_WeaponCanSwitchTo);
	SDKHookEx(iClient, SDKHook_WeaponSwitchPost, Hook_WeaponSwitchPost);
	
	LoadClient(iClient);
}

public void OnClientDisconnect(int iClient)
{
	g_bDistort[iClient] = false;
	g_bJumpBoost[iClient] = false;
	g_bLongJumpPressed[iClient] = false;
	g_bLongJump[iClient][1] = false;
	g_bPlayer[iClient] = false;
	g_bPreferPrivateMatches[iClient] = false;
	
	SDKUnhook(iClient, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	
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
	g_iHealthBoost = g_cvHealthBoost.IntValue;
	g_fHealthModifier = g_cvHealthModifier.FloatValue;
	g_fJumpBoost = g_cvJumpBoost.FloatValue;
	g_bLongJumpSound = g_cvLongJumpSound.BoolValue;
	g_fPushForce = g_cvLongJumpPush.FloatValue;
	g_bMenu = g_cvUseSourceMenus.BoolValue;
	g_bNoAdvertisements = g_cvDisableAdvertisements.BoolValue;
	g_bNoFallDamage = g_cvNoFallDamage.BoolValue;
	g_bPrivateMatches = g_cvAllowPrivateMatches.BoolValue;
	g_bRPG = g_cvSpawnRPG.BoolValue;

	g_iUpgrade_Prices[0] = g_cvUpgradePriceDistort.IntValue;
	g_iUpgrade_Prices[1] = g_cvUpgradePriceHealthBoost.IntValue;
	g_iUpgrade_Prices[2] = g_cvUpgradePriceJumpBoost.IntValue;
	g_iUpgrade_Prices[3] = g_cvUpgradePriceLongJump.IntValue;
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVel[3], float fAngles[3], int &iWeapon, int &iSubtype, int &iCmdnum, int &iTickcount, int &iSeed, int iMouse[2])
{
	int iFlags = GetEntityFlags(iClient);
	float fVelocity[3];
	
	if ((iButtons & IN_JUMP) && (iFlags & FL_ONGROUND))
	{
		GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", fVelocity);
		
		fVelocity[2] = g_bJumpBoost[iClient] ? g_fJumpBoost : 50.0;
		TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, fVelocity);
	}

	for (int i = 0; i < MAX_BUTTONS; i++)
	{
		int iButton = (1 << i);
		
		if ((iButtons & iButton) && !(g_iLastButton[iClient] & iButton))
		{
			if((iButtons & IN_DUCK) && (iButton & IN_JUMP) && (iFlags & FL_ONGROUND) && !g_bLongJumpPressed[iClient] && g_bLongJump[iClient][1])
			{
				LongJumpFunction(iClient);
				
				g_bLongJumpPressed[iClient] = true;
			}
		}
		
		if ((g_iLastButton[iClient] & iButton) && !(iButtons & iButton))
		{
			if((iButton & IN_JUMP) && g_bLongJumpPressed[iClient])
			{
				g_bLongJumpPressed[iClient] = false;
			}
		}
	}
	
	g_iLastButton[iClient] = iButtons;
	
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

	if(g_bMenu)
	{
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
	}else{
		CPrintToChat(iClient, "[{red}KINGS{default}] Credit Menu (%i credits)", g_iCredits[iClient]);

		Format(sDescription, sizeof(sDescription), "Distort | %i Credits", g_iUpgrade_Prices[0]);
		CPrintToChat(iClient, " - %s - Command: !%s", sDescription, "distort");

		Format(sDescription, sizeof(sDescription), "Health Boost +%ihp | %i Credits", g_iHealthBoost, g_iUpgrade_Prices[1]);
		CPrintToChat(iClient, " - %s - Command: !%s", sDescription, "boost");

		Format(sDescription, sizeof(sDescription), "Jump Boost | %i Credits", g_iUpgrade_Prices[2]);
		CPrintToChat(iClient, " - %s - Command: !%s", sDescription, "jumpboost");

		Format(sDescription, sizeof(sDescription), "Long Jump | %i Credits", g_iUpgrade_Prices[3]);
		CPrintToChat(iClient, " - %s - Command: !%s", sDescription, "longjump");
	}
	
	return Plugin_Handled;
}

public Action Command_DefaultWeapon(int iClient, int iArgs)
{
	char sWeapon[64];

	GetCmdArg(1, sWeapon, sizeof(sWeapon));

	if(StrContains(sWeapon, "1", false) != -1 || StrContains(sWeapon, "crowbar", false) != -1)
	{
		Format(g_sDefaultWeapon[iClient], sizeof(g_sDefaultWeapon[]), "weapon_crowbar");

		CPrintToChat(iClient, "[{red}KINGS{default}] Changed default weapon to '{green}Crowbar{default}'.");
	}else if(StrContains(sWeapon, "2", false) != -1 || StrContains(sWeapon, "stunstick", false) != -1)
	{
		Format(g_sDefaultWeapon[iClient], sizeof(g_sDefaultWeapon[]), "weapon_stunstick");

		CPrintToChat(iClient, "[{red}KINGS{default}] Changed default weapon to '{green}Stunstick{default}'.");
	}else if(StrContains(sWeapon, "3", false) != -1 || StrContains(sWeapon, "gravity gun", false) != -1 || StrContains(sWeapon, "physcannon", false) != -1)
	{
		Format(g_sDefaultWeapon[iClient], sizeof(g_sDefaultWeapon[]), "weapon_physcannon");

		CPrintToChat(iClient, "[{red}KINGS{default}] Changed default weapon to '{green}Gravity Gun{default}'.");
	}else if(StrContains(sWeapon, "4", false) != -1 || StrContains(sWeapon, "pistol", false) != -1 || StrContains(sWeapon, "9mm", false) != -1)
	{
		Format(g_sDefaultWeapon[iClient], sizeof(g_sDefaultWeapon[]), "weapon_pistol");

		CPrintToChat(iClient, "[{red}KINGS{default}] Changed default weapon to '{green}9mm Pistol{default}'.");
	}else if(StrContains(sWeapon, "5", false) != -1 || StrContains(sWeapon, "magnum", false) != -1 || StrContains(sWeapon, "357", false) != -1 || StrContains(sWeapon, "revolver", false) != -1)
	{
		Format(g_sDefaultWeapon[iClient], sizeof(g_sDefaultWeapon[]), "weapon_357");

		CPrintToChat(iClient, "[{red}KINGS{default}] Changed default weapon to '{green}.357 Magnum{default}'.");
	}else if(StrContains(sWeapon, "6", false) != -1 || StrContains(sWeapon, "smg", false) != -1 || StrContains(sWeapon, "smg1", false) != -1)
	{
		Format(g_sDefaultWeapon[iClient], sizeof(g_sDefaultWeapon[]), "weapon_smg1");

		CPrintToChat(iClient, "[{red}KINGS{default}] Changed default weapon to '{green}SMG1{default}'.");
	}else if(StrContains(sWeapon, "7", false) != -1 || StrContains(sWeapon, "ar2", false) != -1 || StrContains(sWeapon, "pulse", false) != -1)
	{
		Format(g_sDefaultWeapon[iClient], sizeof(g_sDefaultWeapon[]), "weapon_ar2");

		CPrintToChat(iClient, "[{red}KINGS{default}] Changed default weapon to '{green}Pulse Rifle (AR2){default}'.");
	}else if(StrContains(sWeapon, "8", false) != -1 || StrContains(sWeapon, "shotgun", false) != -1)
	{
		Format(g_sDefaultWeapon[iClient], sizeof(g_sDefaultWeapon[]), "weapon_shotgun");

		CPrintToChat(iClient, "[{red}KINGS{default}] Changed default weapon to '{green}Shotgun{default}'.");
	}else if(StrContains(sWeapon, "9", false) != -1 || StrContains(sWeapon, "crossbow", false) != -1)
	{
		Format(g_sDefaultWeapon[iClient], sizeof(g_sDefaultWeapon[]), "weapon_crossbow");

		CPrintToChat(iClient, "[{red}KINGS{default}] Changed default weapon to '{green}Crossbow{default}'.");
	}else if(StrContains(sWeapon, "10", false) != -1 || StrContains(sWeapon, "grenade", false) != -1 || StrContains(sWeapon, "frag", false) != -1)
	{
		Format(g_sDefaultWeapon[iClient], sizeof(g_sDefaultWeapon[]), "weapon_frag");

		CPrintToChat(iClient, "[{red}KINGS{default}] Changed default weapon to '{green}Frag Grenade{default}'.");
	}else if(StrEqual(sWeapon, "", false))
	{
		Client_GetActiveWeaponName(iClient, g_sDefaultWeapon[iClient], sizeof(g_sDefaultWeapon[]));

		CPrintToChat(iClient, "[{red}KINGS{default}] Default weapon changed to your current weapon.");
	}else{
		Client_GetActiveWeaponName(iClient, g_sDefaultWeapon[iClient], sizeof(g_sDefaultWeapon[]));

		CPrintToChat(iClient, "[{red}KINGS{default}] Invalid weapon selection. Default weapon changed to your current weapon.");
	}

	SaveClient(iClient);

	//Client_ChangeWeapon(iClient, g_sDefaultWeapon[iClient]);

	return Plugin_Handled;
}

public Action Command_Distort(int iClient, int iArgs)
{
	if (g_iCredits[iClient] <= g_iUpgrade_Prices[0])
	{
		CPrintToChat(iClient, "[{red}KINGS{default}] You do not have enough credits.");
	} else {
		g_iCredits[iClient] -= g_iUpgrade_Prices[0];

		CPrintToChat(iClient, "[{red}KINGS{default}] You have bought the {green}distort effect{default} for {green}%i{default} credits for {green}%f{default} seconds.", g_iUpgrade_Prices[0], g_fCommand_Duration[0]);
		
		SetEntityRenderFx(iClient, RENDERFX_DISTORT);

		g_bDistort[iClient] = true;
		
		CreateTimer(g_fCommand_Duration[0], Timer_Visible, iClient);
		
		SaveClient(iClient);
	}
	
	return Plugin_Handled;
}

public Action Command_HealthBoost(int iClient, int iArgs)
{
	if (g_iCredits[iClient] <= g_iUpgrade_Prices[1])
	{
		CPrintToChat(iClient, "[{red}KINGS{default}] You do not have enough credits.");
	} else {
		g_iCredits[iClient] -= g_iUpgrade_Prices[1];
		
		CPrintToChat(iClient, "[{red}KINGS{default}] You have bought the {green}health boost{default} for {green}%i{default} credits. {green}%ihp{default} has been added to your health.", g_iUpgrade_Prices[1], g_iHealthBoost);
		
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
		CPrintToChat(iClient, "[{red}KINGS{default}] You do not have enough credits.");
	} else {
		g_iCredits[iClient] -= g_iUpgrade_Prices[2];

		CPrintToChat(iClient, "[{red}KINGS{default}] You have bought the {green}jump boost{default} for {green}%i{default} credits for {green}%f{default} seconds.", g_iUpgrade_Prices[2], g_fCommand_Duration[1]);
		
		g_bJumpBoost[iClient] = true;
		
		CreateTimer(g_fCommand_Duration[1], Timer_JumpBoost, iClient);
		
		SaveClient(iClient);
	}
	
	return Plugin_Handled;
}

public Action Command_LongJump(int iClient, int iArgs)
{
	if(g_bLongJump[iClient][0])
	{
		g_bLongJump[iClient][1] = !g_bLongJump[iClient][1];

		CPrintToChat(iClient, "[{red}KINGS{default}] Long jump has been %s.", g_bLongJump[iClient][1] ? "enabled" : "disabled");

		return Plugin_Handled;
	}

	if (g_iCredits[iClient] <= g_iUpgrade_Prices[3])
	{
		CPrintToChat(iClient, "[{red}KINGS{default}] You do not have enough credits.");
	} else {
		g_iCredits[iClient] -= g_iUpgrade_Prices[3];

		CPrintToChat(iClient, "[{red}KINGS{default}] You have bought the {green}long jump module{default} for {green}%i{default} credits.", g_iUpgrade_Prices[3]);
		
		g_bLongJump[iClient][0] = true;
		g_bLongJump[iClient][1] = true;
		
		SaveClient(iClient);
	}
	
	return Plugin_Handled;
}

public Action Handle_Chat(int iClient, char[] sCommand, int iArgs)
{
	if (IsChatTrigger())
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action Command_PrivateMatch(int iClient, int iArgs)
{
	if(!g_bPrivateMatches)
	{
		CPrintToChat(iClient, "[{red}KINGS{default}] Private matches are disabled.");
		return Plugin_Handled;
	}

	Format(g_sServerPassword, sizeof(g_sServerPassword), "kings-%i%i%i", GetRandomInt(0, 24), GetRandomInt(24, 64), GetRandomInt(64, 99));

	g_cvPassword.SetString(g_sServerPassword);

	g_bPrivateMatchRunning = true;

	return Plugin_Handled;
}

//Plugin Stocks/Extra Voids

//SDKHooks
public void Hook_FireBulletsPost(int iClient, int iShots, char[] sWeaponname)
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
	
	g_iAllDeaths[iClient] = LoadInteger(kvVault, sAuthID, "all_deaths", 0);
	g_iAllKills[iClient] = LoadInteger(kvVault, sAuthID, "all_kills", 0);
	g_iCredits[iClient] = LoadInteger(kvVault, sAuthID, "credits", 1500);

	LoadString(kvVault, sAuthID, "default_weapon", "weapon_357", g_sDefaultWeapon[iClient], sizeof(g_sDefaultWeapon[]));

	g_bLongJump[iClient][0] = view_as<bool>(LoadInteger(kvVault, sAuthID, "long_jump", 0));
	g_bLongJump[iClient][1] = view_as<bool>(LoadInteger(kvVault, sAuthID, "previous_lj_setting", 0));
	
	kvVault.Rewind();
	
	kvVault.Close();
}

public void LoadString(KeyValues kvVault, const char[] sKey, const char[] sSaveKey, const char[] sDefaultValue, char[] sReference, int iMaxLength)
{
	kvVault.JumpToKey(sKey, false);
	
	kvVault.GetString(sSaveKey, sReference, iMaxLength, sDefaultValue);

	kvVault.Rewind();
}

public void LongJumpFunction(int iClient)
{
	char sSound[64];
	float fEyeAngles[3], fPushForce[3];
	
	GetClientEyeAngles(iClient, fEyeAngles);

	fPushForce[0] = (g_fPushForce * Cosine(DegToRad(fEyeAngles[1])));
	fPushForce[1] = (g_fPushForce * Sine(DegToRad(fEyeAngles[1])));
	fPushForce[2] = (-50.0 * Sine(DegToRad(fEyeAngles[0])));

	TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, fPushForce);

	//Sound from Black Mesa: Source (2012 Mod)
	Format(sSound, sizeof(sSound), "bms/weapons/jumpmod/jumpmod_long1.mp3"/*, view_as<bool>(GetRandomInt(0, 1)) ? "long" : "boost"*/);

	PrecacheSound(sSound);

	if(g_bLongJumpSound)
		EmitSoundToClient(iClient, sSound, iClient, 2, 100, 0, 0.1, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
}

//SDKHooks
public Action Hook_OnTakeDamage(int iClient, int &iAttacker, int &iInflictor, float &fDamage, int &iDamagetype)
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
		iNewHealth -= g_iCrowbarDamage;
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
	
	SaveInteger(kvVault, sAuthID, "all_deaths", g_iAllDeaths[iClient]);
	SaveInteger(kvVault, sAuthID, "all_Kills", g_iAllKills[iClient]);
	SaveInteger(kvVault, sAuthID, "credits", g_iCredits[iClient]);

	SaveString(kvVault, sAuthID, "default_weapon", g_sDefaultWeapon[iClient]);

	SaveInteger(kvVault, sAuthID, "long_jump", view_as<int>(g_bLongJump[iClient][0]));
	SaveInteger(kvVault, sAuthID, "previous_lj_setting", view_as<int>(g_bLongJump[iClient][1]));
	
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

public void SaveString(KeyValues kvVault, const char[] sKey, const char[] sSaveKey, const char[] sVariable)
{
	kvVault.JumpToKey(sKey, true);
	
	kvVault.SetString(sSaveKey, sVariable);

	kvVault.Rewind();
}

//SDKHooks
public void Hook_WeaponSwitchPost(int iClient, int iWeapon)
{
	if (iWeapon != -1)
	{
		ReFillWeapon(iClient, iWeapon);
	}
}


public Action Hook_WeaponCanSwitchTo(int iClient, int iWeapon) 
{
	SetEntityFlags(iClient, GetEntityFlags(iClient) | FL_ONGROUND);
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
			g_iAllDeaths[iClient]++;
			g_iDeaths[iClient]++;
		} else {
			g_iAllKills[iAttacker]++;
			g_iKills[iAttacker]++;
			g_iAllDeaths[iClient]++;
			g_iDeaths[iClient]++;
			
			g_iCredits[iAttacker] += iRandom;
			
			CPrintToChatAll("{green}%N{default} got {green}%i{default} credits for killing {green}%N{default}!", iAttacker, iRandom, iClient);
			
			SaveClient(iClient);
		}
	} else {
		g_iAllKills[iClient]--;
		g_iKills[iClient]--;
		g_iAllDeaths[iClient]++;
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

	if(g_bDistort[iClient])
		SetEntityRenderFx(iClient, RENDERFX_DISTORT);
}

//Plugin Timers
public Action Timer_Advertisement(Handle hTimer)
{
	char sAdvertisement[256];
	
	switch (g_iAdvertisement)
	{
		case 1:
		{
			//Format(sAdvertisement, sizeof(sAdvertisement), "We have a {green}credits{default} system. Type {green}!credits{default} to use it.");
			LoadString(g_kvAdvertisements, "Messages", "1", "", sAdvertisement, sizeof(sAdvertisement));
			
			g_iAdvertisement = 2;
		}
		
		case 2:
		{
			//Format(sAdvertisement, sizeof(sAdvertisement), "Latest Update [{green}10/23/18{default}]: We have added a buyable {green}health boost{default}. Type {green}!credits{default} for more information.");
			LoadString(g_kvAdvertisements, "Messages", "2", "", sAdvertisement, sizeof(sAdvertisement));
			
			g_iAdvertisement = 3;
		}
		
		case 3:
		{
			//Format(sAdvertisement, sizeof(sAdvertisement), "Type {green}rtv{default} to vote to change the map.");
			LoadString(g_kvAdvertisements, "Messages", "3", "", sAdvertisement, sizeof(sAdvertisement));
			
			g_iAdvertisement = 4;
		}

		case 4:
		{
			//Format(sAdvertisement, sizeof(sAdvertisement), "Type {green}rtv{default} to vote to change the map.");
			LoadString(g_kvAdvertisements, "Messages", "4", "", sAdvertisement, sizeof(sAdvertisement));
			
			g_iAdvertisement = 5;
		}

		case 5:
		{
			//Format(sAdvertisement, sizeof(sAdvertisement), "Type {green}rtv{default} to vote to change the map.");
			LoadString(g_kvAdvertisements, "Messages", "5", "", sAdvertisement, sizeof(sAdvertisement));
			
			g_iAdvertisement = 6;
		}

		case 6:
		{
			//Format(sAdvertisement, sizeof(sAdvertisement), "Type {green}rtv{default} to vote to change the map.");
			LoadString(g_kvAdvertisements, "Messages", "6", "", sAdvertisement, sizeof(sAdvertisement));
			
			g_iAdvertisement = 1;
		}
	}
	
	if(!g_bNoAdvertisements)
		CPrintToChatAll(sAdvertisement);
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

	Client_ChangeWeapon(iClient, g_sDefaultWeapon[iClient]);
}

public Action Timer_JumpBoost(Handle hTimer, any iClient)
{
	if (IsClientConnected(iClient))
	{
		g_bJumpBoost[iClient] = false;
		
		CPrintToChat(iClient, "[{red}KINGS{default}] Your {green}jump-boost{default} has worn off.");
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
		fAllKTD = ((g_iAllDeaths[iClient] <= 0.0) ? 0.0 : view_as<float>(g_iAllKills[iClient]) / view_as<float>(g_iAllDeaths[iClient]));//FloatDiv(float(g_iKills[iClient]), float(g_iDeaths[iClient])));
		fRoundKTD = ((g_iDeaths[iClient] <= 0.0) ? 0.0 : view_as<float>(g_iKills[iClient]) / view_as<float>(g_iDeaths[iClient]));//FloatDiv(float(g_iKills[iClient]), float(g_iDeaths[iClient])));
		
		if(g_bAllKills)
		{
			g_bPrivateMatchRunning ? Format(sStatsHud[0], sizeof(sStatsHud[]), "Name: %N\nCredits: %i\n%.1f All-Time KTD\nServer Password: %s", iClient, g_iCredits[iClient], fAllKTD, g_sServerPassword) : Format(sStatsHud[0], sizeof(sStatsHud[]), "Name: %N\nCredits: %i\n%.1f All-Time KTD", iClient, g_iCredits[iClient], fAllKTD);
		}else{
			g_bPrivateMatchRunning ? Format(sStatsHud[0], sizeof(sStatsHud[]), "Name: %N\nCredits: %i\nServer Password: %s", iClient, g_iCredits[iClient], g_sServerPassword) : Format(sStatsHud[0], sizeof(sStatsHud[]), "Name: %N\nCredits: %i", iClient, g_iCredits[iClient]);
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
	
	for (int i = 0; i < GetMaxEntities() * 2; i++)
	{
		if (IsValidEntity(i))
		{
			GetEntityClassname(i, sClassname, sizeof(sClassname));
			
			if ((StrEqual(sClassname, "weapon_rpg") || StrEqual(sClassname, "item_rpg_round")) && !g_bRPG)
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

		g_bDistort[iClient] = false;
		
		CPrintToChat(iClient, "[{red}KINGS{default}] Your {green}distort{default} has worn off.");
	}
} 