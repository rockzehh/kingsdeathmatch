//King's Deathmatch: Developed by King Nothing.

#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "RockZehh"
#define PLUGIN_VERSION "1.4.0"

#define MAX_BUTTONS 26

#include <sourcemod>
#include <morecolors>
#include <sdktools>
#include <sdkhooks>
#include <smlib/clients>
#include <geoip>
#include <discord>
#undef REQUIRE_PLUGIN
#include <updater>

#pragma newdecls required

#define GRENADES 10
#define RPG_ROUNDS 8

#define SUIT_DEVICE_BREATHER	0x00000004
#define SUIT_DEVICE_FLASHLIGHT	0x00000002
#define SUIT_DEVICE_SPRINT		0x00000001

#define UPDATE_URL	"https://raw.githubusercontent.com/rockzehh/kingsdeathmatch/master/addons/sourcemod/updater.txt"

enum struct ConVars {
	ConVar AllowPrivateMatches;
	ConVar ColorNickPrice;
	ConVar CrowbarDamage;
	ConVar DefaultFOV;
	ConVar DefaultJumpVel;
	ConVar DisableAdverts;
	ConVar DisableFallDamage;
	ConVar EnableColoredNick;
	ConVar EnableInvisible;
	ConVar EnableJetpack;
	ConVar EnableJumpBoost;
	ConVar EnableLongJump;
	ConVar EnableModelChange;
	ConVar EnableNick;    
	ConVar EnableRPG;
	ConVar EnableSourceTV;
	ConVar FallingFix;
	ConVar HalfDamage;
	ConVar HealthBoost;
	ConVar HealthBoostPrice;
	ConVar HealthModifier;
	ConVar InvisibilityPrice;
	ConVar Jetpack;
	ConVar JetpackPrice;
	ConVar JumpBoost;
	ConVar JumpBoostPrice;
	ConVar LongJumpPrice;
	ConVar LongJumpSound;
	ConVar LongJumpVel;
	ConVar ServerPassword;
	ConVar ShowAllKills;
	ConVar SourceTV[3];
	ConVar StartFOV;
	ConVar StartHealth;
	ConVar UseFOV;
	ConVar UseRegMenus;
}

enum struct Items {
	bool EnableColorNick;
	bool EnableInvisibility;
	bool EnableJetpack;
	bool EnableJumpBoost;
	bool EnableLongJump;
	bool EnableLongJumpSound;
	bool EnableModelChange;
	bool EnableNickname;
	
	float JetpackVel;
	float JumpBoostVel;
	float PushVel;
	
	
	int HealthBoost;
}

enum struct Player {
	Handle StatsHUD;
	
	bool ColoredNick;
	bool DevMode;
	bool GodMode;
	bool InZoom;
	bool Invisible;
	bool IsPlayer;
	bool Jetpack[2];
	bool JumpBoost[2];
	bool JumpPressed;
	bool LongJump[2];
	bool SpawnProtect;
	
	char DefaultWeapon[64];
	char Model[64];
	char NickColor[MAX_NAME_LENGTH];
	char Nickname[MAX_NAME_LENGTH];
	
	int AllDeaths;
	int AllKills;
	int Credits;
	int LastButtonPressed;
	int RoundDeaths;
	int RoundKills;
}

enum struct Server {
	Handle Adverts;
	
	KeyValues AdvertsKeyVaules;
	
	bool AllKills;
	bool AltDamage;
	bool ChangeFOV;
	bool FallFix;
	bool NoAdverts;
	bool NoFallDamage;
	bool PrivateMatchAllowed;
	bool PrivateMatchRunning;
	bool RegMenu;
	
	char AdvertsDB[PLATFORM_MAX_PATH];
	char ClientsDB[PLATFORM_MAX_PATH];
	char ModelsDB[PLATFORM_MAX_PATH];
	char Password[128];
	
	float DamageModifier;
	float JumpVel;
	
	int Advertisement;
	int DefaultFOV;
	int DefaultHealth;
	int StartFOV;
}

enum struct Weapons {
	bool DisableRPG;
	
	int CrowbarDamage;
}

ConVars g_cvConVars;

float g_fUpgradeDuration[] =
{
	15.0, //Invisibility
	120.0, //Jump Boost
};

int g_iClipSizes[] =
{
	0,  //skip
	30,  //AR2			pri
	255,  //AR2AltFire	sec
	18,  //Pistol		pri
	45,  //SMG1			pri
	6,  //357			pri
	1,  //XBowBolt		pri
	6,  //Buckshot		pri
	255,  //RPG_ROUNDS		pri
	255,  //SMG1_GRENADES	sec
	255,  //GRENADES		pri
	255,  //Slam			sec
};

int g_iUpgradePrices[] =
{
	350, //Health Boost
	500, //Invisibility
	1750, //Jump Boost
	2500, //Long Jump
	2000, //Jetpack
	25000, //Colored Nicknames
};

Items g_itItems;

Player g_pPlayer[MAXPLAYERS + 1];

Server g_sServer;

Weapons g_wWeapons;

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
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	
	AutoExecConfig(true, "kings-deathmatch");
	
	char sPath[PLATFORM_MAX_PATH];
	
	BuildPath(Path_SM, sPath, sizeof(sPath), "data/kingsdeathmatch");
	if (!DirExists(sPath))
	{
		CreateDirectory(sPath, 511);
	}
	
	BuildPath(Path_SM, g_sServer.AdvertsDB, PLATFORM_MAX_PATH, "data/kingsdeathmatch/advertisements.txt");
	if(!FileExists(g_sServer.AdvertsDB))
	{
		g_sServer.NoAdverts = false;
	}
	
	BuildPath(Path_SM, g_sServer.ClientsDB, PLATFORM_MAX_PATH, "data/kingsdeathmatch/clients.txt");
	
	BuildPath(Path_SM, g_sServer.ModelsDB, PLATFORM_MAX_PATH, "data/kingsdeathmatch/models.txt");
	if(!FileExists(g_sServer.ModelsDB))
	{
		g_itItems.EnableModelChange = false;
	}
	
	CreateConVar("kings-deathmatch", "1", "Notifies the server that the plugin is running.");
	
	g_cvConVars.AllowPrivateMatches = CreateConVar("kdm_server_allow_private_matches", "1", "If users can start a private match.", _, true, 0.1, true, 1.0);
	g_cvConVars.ColorNickPrice = CreateConVar("kdm_colornickname_price", "25000", "The amount of credits you need to buy the colored nickname.");
	g_cvConVars.CrowbarDamage = CreateConVar("kdm_wep_crowbar_damage", "500", "The damage the crowbar will do.");
	g_cvConVars.DefaultFOV = CreateConVar("kdm_player_custom_fov", "110", "The custom FOV value.");
	g_cvConVars.DefaultJumpVel = CreateConVar("kdm_player_jump_velocity", "100.0", "The default jump velocity.");
	g_cvConVars.DisableAdverts = CreateConVar("kdm_chat_disable_advertisements", "0", "Decides if chat advertisements should be displayed.", _, true, 0.1, true, 1.0);
	g_cvConVars.DisableFallDamage = CreateConVar("kdm_player_nofalldamage", "1", "Decides if to disable fall damage.", _, true, 0.1, true, 1.0);
	g_cvConVars.EnableColoredNick = CreateConVar("kdm_colornickname_enable", "1", "Decides if colored nicknames are enabled.", _, true, 0.1, true, 1.0);
	g_cvConVars.EnableInvisible = CreateConVar("kdm_invisible_enable", "1", "Decides if the invisiblity effect is enabled.", _, true, 0.1, true, 1.0);
	g_cvConVars.EnableJetpack = CreateConVar("kdm_jetpack_enable", "1", "Decides if the jetpack module is enabled.", _, true, 0.1, true, 1.0);
	g_cvConVars.EnableJumpBoost = CreateConVar("kdm_jumpboost_enable", "1", "Decides if the jump boost module is enabled.", _, true, 0.1, true, 1.0);
	g_cvConVars.EnableLongJump = CreateConVar("kdm_longjump_enable", "1", "Decides if the long jump module is enabled.", _, true, 0.1, true, 1.0);
	g_cvConVars.EnableModelChange = CreateConVar("kdm_player_model_change", "1", "Decides if the player can change their model.", _, true, 0.1, true, 1.0);
	g_cvConVars.EnableNick = CreateConVar("kdm_nickname_enable", "1", "Decides if nicknames are enabled.", _, true, 0.1, true, 1.0);
	g_cvConVars.EnableRPG = CreateConVar("kdm_wep_allow_rpg", "0", "Decides if the RPG is allowed to spawn.", _, true, 0.1, true, 1.0);
	g_cvConVars.EnableSourceTV = CreateConVar("kdm_demos_enable", "1", "Decides if the SourceTV demo recording is enabled.", _, true, 0.1, true, 1.0);
	g_cvConVars.FallingFix = CreateConVar("kdm_player_tposefix", "0", "Decides if to fix the T-Pose falling glitch.", _, true, 0.1, true, 1.0);
	g_cvConVars.HalfDamage = CreateConVar("kdm_player_alternatedamage", "0", "Decides if the players have alternate damage.", _, true, 0.1, true, 1.0);
	g_cvConVars.HealthBoost = CreateConVar("kdm_healthboost_amount", "75", "The amount of health the health boost will do.");
	g_cvConVars.HealthBoostPrice = CreateConVar("kdm_healthboost_price", "350", "The amount of credits you need to pay to use the health boost.");
	g_cvConVars.HealthModifier = CreateConVar("kdm_player_damage_modifier", "0.5", "Damage modifier. A better description will be added.");
	g_cvConVars.InvisibilityPrice = CreateConVar("kdm_invisible_price", "500", "The amount of credits you need to pay to use the invisible effect.");
	g_cvConVars.Jetpack = CreateConVar("kdm_jetpack_velocity", "60.0", "Jetpack velocity. A better description will be added.");
	g_cvConVars.JetpackPrice = CreateConVar("kdm_jetpack_price", "2000", "The amount of credits you need to pay to use the jetpack module.");
	g_cvConVars.JumpBoost = CreateConVar("kdm_jumpboost_amount", "500.0", "The added jump velocity.");
	g_cvConVars.JumpBoostPrice = CreateConVar("kdm_jumpboost_price", "1750", "The amount of credits you need to pay to use the jump boost module.");
	g_cvConVars.LongJumpPrice = CreateConVar("kdm_longjump_price", "2500", "The amount of credits you need to pay to use the long jump module.");
	g_cvConVars.LongJumpSound = CreateConVar("kdm_longjump_play_sound", "1", "Decides if to play the long jump sound.", _, true, 0.1, true, 1.0);
	g_cvConVars.LongJumpVel = CreateConVar("kdm_longjump_push_force", "500.0", "The amount of force that the long jump does.");
	g_cvConVars.ServerPassword = FindConVar("sv_password");
	g_cvConVars.ShowAllKills = CreateConVar("kdm_player_hud_showallkills", "1", "Shows the stats for the players overall kills.", _, true, 0.1, true, 1.0);
	g_cvConVars.SourceTV[0] = FindConVar("tv_enable");
	g_cvConVars.SourceTV[1] = FindConVar("tv_autorecord");
	g_cvConVars.SourceTV[2] = FindConVar("tv_maxclients");
	g_cvConVars.StartFOV = CreateConVar("kdm_player_start_fov", "20", "The custom start animation FOV value.");
	g_cvConVars.StartHealth = CreateConVar("kdm_player_start_health", "250", "The start player health.");
	g_cvConVars.UseFOV = CreateConVar("kdm_player_custom_fov_enable", "1", "Decides to use the custom FOV on the players.", _, true, 0.1, true, 1.0);
	g_cvConVars.UseRegMenus = CreateConVar("kdm_server_usesourcemenus", "0", "Decides to use the chat option or the menu system.", _, true, 0.1, true, 1.0);
	
	CreateConVar("kdm_plugin_version", PLUGIN_VERSION, "The version of the plugin the server is running.");
	
	g_cvConVars.ServerPassword.GetString(g_sServer.Password, sizeof(g_sServer.Password));
	g_cvConVars.SourceTV[0].BoolValue = g_cvConVars.EnableSourceTV.BoolValue;
	g_cvConVars.SourceTV[1].BoolValue = true;
	g_cvConVars.SourceTV[2].IntValue = 0;
	
	g_itItems.EnableColorNick = g_cvConVars.EnableColoredNick.BoolValue;
	g_itItems.EnableInvisibility = g_cvConVars.EnableInvisible.BoolValue;
	g_itItems.EnableJetpack = g_cvConVars.EnableJetpack.BoolValue;
	g_itItems.EnableJumpBoost = g_cvConVars.EnableJumpBoost.BoolValue;
	g_itItems.EnableLongJump = g_cvConVars.EnableLongJump.BoolValue;
	g_itItems.EnableLongJumpSound = g_cvConVars.LongJumpSound.BoolValue;
	g_itItems.EnableModelChange = g_cvConVars.EnableModelChange.BoolValue;
	g_itItems.EnableNickname = g_cvConVars.EnableNick.BoolValue;
	g_itItems.HealthBoost = g_cvConVars.HealthBoost.IntValue;
	g_itItems.JetpackVel = g_cvConVars.Jetpack.FloatValue;
	g_itItems.JumpBoostVel = g_cvConVars.JumpBoost.FloatValue;
	g_itItems.PushVel = g_cvConVars.LongJumpVel.FloatValue;
	g_iUpgradePrices[0] = g_cvConVars.HealthBoostPrice.IntValue;
	g_iUpgradePrices[1] = g_cvConVars.InvisibilityPrice.IntValue;
	g_iUpgradePrices[2] = g_cvConVars.JumpBoostPrice.IntValue;
	g_iUpgradePrices[3] = g_cvConVars.LongJumpPrice.IntValue;
	g_iUpgradePrices[4] = g_cvConVars.JetpackPrice.IntValue;
	g_iUpgradePrices[5] = g_cvConVars.ColorNickPrice.IntValue;
	
	g_sServer.AllKills = g_cvConVars.ShowAllKills.BoolValue;
	g_sServer.AltDamage = g_cvConVars.HalfDamage.BoolValue;
	g_sServer.ChangeFOV = g_cvConVars.UseFOV.BoolValue;
	g_sServer.DamageModifier = g_cvConVars.HealthModifier.FloatValue;
	g_sServer.DefaultFOV = g_cvConVars.DefaultFOV.IntValue;
	g_sServer.DefaultHealth = g_cvConVars.StartHealth.IntValue;
	g_sServer.FallFix = g_cvConVars.FallingFix.BoolValue;
	g_sServer.JumpVel = g_cvConVars.DefaultJumpVel.FloatValue;
	g_sServer.NoAdverts = g_cvConVars.DisableAdverts.BoolValue;
	g_sServer.NoFallDamage = g_cvConVars.DisableFallDamage.BoolValue;
	g_sServer.PrivateMatchAllowed = g_cvConVars.AllowPrivateMatches.BoolValue;
	g_sServer.PrivateMatchRunning = StrEqual(g_sServer.Password, "") ? false : true;
	g_sServer.RegMenu = g_cvConVars.UseRegMenus.BoolValue;
	g_sServer.StartFOV = g_cvConVars.StartFOV.IntValue;
	
	g_wWeapons.CrowbarDamage = g_cvConVars.CrowbarDamage.IntValue;
	g_wWeapons.DisableRPG = g_cvConVars.EnableRPG.BoolValue;
	
	g_cvConVars.AllowPrivateMatches.AddChangeHook(OnConVarsChanged);
	g_cvConVars.ColorNickPrice.AddChangeHook(OnConVarsChanged);
	g_cvConVars.CrowbarDamage.AddChangeHook(OnConVarsChanged);
	g_cvConVars.DefaultFOV.AddChangeHook(OnConVarsChanged);
	g_cvConVars.DefaultJumpVel.AddChangeHook(OnConVarsChanged);
	g_cvConVars.DisableAdverts.AddChangeHook(OnConVarsChanged);
	g_cvConVars.DisableFallDamage.AddChangeHook(OnConVarsChanged);
	g_cvConVars.EnableColoredNick.AddChangeHook(OnConVarsChanged);
	g_cvConVars.EnableInvisible.AddChangeHook(OnConVarsChanged);
	g_cvConVars.EnableJetpack.AddChangeHook(OnConVarsChanged);
	g_cvConVars.EnableJumpBoost.AddChangeHook(OnConVarsChanged);
	g_cvConVars.EnableLongJump.AddChangeHook(OnConVarsChanged);
	g_cvConVars.EnableModelChange.AddChangeHook(OnConVarsChanged);
	g_cvConVars.EnableNick.AddChangeHook(OnConVarsChanged);
	g_cvConVars.EnableRPG.AddChangeHook(OnConVarsChanged);
	g_cvConVars.EnableSourceTV.AddChangeHook(OnConVarsChanged);
	g_cvConVars.FallingFix.AddChangeHook(OnConVarsChanged);
	g_cvConVars.HalfDamage.AddChangeHook(OnConVarsChanged);
	g_cvConVars.HealthBoost.AddChangeHook(OnConVarsChanged);
	g_cvConVars.HealthBoostPrice.AddChangeHook(OnConVarsChanged);
	g_cvConVars.HealthModifier.AddChangeHook(OnConVarsChanged);
	g_cvConVars.InvisibilityPrice.AddChangeHook(OnConVarsChanged);
	g_cvConVars.Jetpack.AddChangeHook(OnConVarsChanged);
	g_cvConVars.JetpackPrice.AddChangeHook(OnConVarsChanged);
	g_cvConVars.JumpBoost.AddChangeHook(OnConVarsChanged);
	g_cvConVars.JumpBoostPrice.AddChangeHook(OnConVarsChanged);
	g_cvConVars.LongJumpPrice.AddChangeHook(OnConVarsChanged);
	g_cvConVars.LongJumpSound.AddChangeHook(OnConVarsChanged);
	g_cvConVars.LongJumpVel.AddChangeHook(OnConVarsChanged);
	g_cvConVars.ShowAllKills.AddChangeHook(OnConVarsChanged);
	g_cvConVars.StartFOV.AddChangeHook(OnConVarsChanged);
	g_cvConVars.StartHealth.AddChangeHook(OnConVarsChanged);
	g_cvConVars.UseFOV.AddChangeHook(OnConVarsChanged);
	g_cvConVars.UseRegMenus.AddChangeHook(OnConVarsChanged);
	
	HookEvent("player_class", Event_PlayerClass);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	AddCommandListener(Handle_Chat, "say");
	AddCommandListener(Handle_Chat, "say_team");
	
	//Custom admin shit flag is Admin_Custom4.
	
	RegAdminCmd("dev_discord", Dev_TestDiscord, view_as<int>(Admin_Custom4), "Sends a test message to the CoN discord.");
	RegAdminCmd("dev_gmode", Dev_GodMode, view_as<int>(Admin_Custom4), "Gives the player god mode. This is for development purposes ONLY.");
	RegAdminCmd("sm_changecredits", Command_ChangeCredits, view_as<int>(Admin_Custom4), "Changes the players credits.");
	RegAdminCmd("sm_setnickname", Command_SetNickname, view_as<int>(Admin_Custom4), "Sets the player nickname.");
	
	RegConsoleCmd("sm_boost", Command_HealthBoost, "Adds a boost of health.");
	RegConsoleCmd("sm_changemodel", Command_PlayerModel, "Changes your player model.");
	RegConsoleCmd("sm_changenickname", Command_ChangeNickname, "Changes your player nickname.");
	RegConsoleCmd("sm_credits", Command_Credits, "Brings up the credit menu.");
	RegConsoleCmd("sm_default", Command_DefaultWeapon, "Changes the default weapon.");
	RegConsoleCmd("sm_defaultweapon", Command_DefaultWeapon, "Changes the default weapon.");
	RegConsoleCmd("sm_hb", Command_HealthBoost, "Adds a boost of health.");
	RegConsoleCmd("sm_health", Command_HealthBoost, "Adds a boost of health.");
	RegConsoleCmd("sm_healthboost", Command_HealthBoost, "Adds a boost of health.");
	RegConsoleCmd("sm_invisibility", Command_Invisibility, "Makes your player model invisible.");
	RegConsoleCmd("sm_invisible", Command_Invisibility, "Makes your player model invisible.");
	RegConsoleCmd("sm_jb", Command_JumpBoost, "Gives you a big jump boost.");
	RegConsoleCmd("sm_jetpack", Command_Jetpack, "Gives you a jetpack module.");
	RegConsoleCmd("sm_jump", Command_JumpBoost, "Gives you a big jump boost.");
	RegConsoleCmd("sm_jumpboost", Command_JumpBoost, "Gives you a big jump boost.");
	RegConsoleCmd("sm_lj", Command_LongJump, "Gives you bunnyhopping.");
	RegConsoleCmd("sm_longjump", Command_LongJump, "Gives you bunnyhopping.");
	RegConsoleCmd("sm_model", Command_PlayerModel, "Changes your player model.");
	RegConsoleCmd("sm_nick", Command_ChangeNickname, "Changes your player nickname.");
	RegConsoleCmd("sm_playermodel", Command_PlayerModel, "Changes your player model.");
	RegConsoleCmd("sm_private", Command_PrivateMatch, "Sets the match to private with a password.");
	RegConsoleCmd("sm_privatematch", Command_PrivateMatch, "Sets the match to private with a password.");
	RegConsoleCmd("sm_store", Command_Credits, "Brings up the credit menu.");
	
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientAuthorized(i))
		{
			OnClientPutInServer(i);
		}
		
		if (IsClientConnected(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
		}
	}
	
	g_sServer.AdvertsKeyVaules = new KeyValues("Advertisements");
	
	g_sServer.AdvertsKeyVaules.ImportFromFile(g_sServer.AdvertsDB);
	
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
		
		if (IsClientConnected(i))
		{
			SDKUnhook(i, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
		}
	}
	
	g_sServer.AdvertsKeyVaules.Close();
}

public void OnMapStart()
{
	char sClassname[64];
	
	for (int i = 0; i < GetMaxEntities() * 2; i++)
	{
		if (IsValidEntity(i))
		{
			GetEntityClassname(i, sClassname, sizeof(sClassname));
			
			if ((StrEqual(sClassname, "weapon_rpg") || StrEqual(sClassname, "item_rpg_round")) && !g_wWeapons.DisableRPG)
			{
				AcceptEntityInput(i, "kill");
			}
		}
	}
	
	g_sServer.Adverts = CreateTimer(45.0, Timer_Advertisement, _, TIMER_REPEAT);
	
	CreateTimer(15.0, Timer_RPGRemove, _, TIMER_REPEAT);
	
	g_sServer.PrivateMatchRunning = StrEqual(g_sServer.Password, "") ? false : true;
}
public void OnMapEnd()
{
	CloseHandle(g_sServer.Adverts);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			SDKUnhook(i, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
		}
	}
	
	g_sServer.PrivateMatchRunning = StrEqual(g_sServer.Password, "") ? false : true;
}

public void OnClientPutInServer(int iClient)
{
	//Custom admin shit flag is Admin_Custom4.
	g_pPlayer[iClient].ColoredNick = false;
	g_pPlayer[iClient].DevMode = false;
	g_pPlayer[iClient].Invisible = false;
	g_pPlayer[iClient].InZoom = false;
	g_pPlayer[iClient].IsPlayer = true;
	g_pPlayer[iClient].JumpBoost[0] = false;
	g_pPlayer[iClient].JumpBoost[1] = false;
	g_pPlayer[iClient].JumpPressed = false;
	g_pPlayer[iClient].LongJump[0] = false;
	g_pPlayer[iClient].LongJump[1] = false;
	g_pPlayer[iClient].SpawnProtect = false;
	
	g_pPlayer[iClient].StatsHUD = CreateTimer(0.1, Timer_StatHud, iClient, TIMER_REPEAT);
	
	g_pPlayer[iClient].AllDeaths = 0;
	g_pPlayer[iClient].AllKills = 0;
	g_pPlayer[iClient].Credits = 0;
	g_pPlayer[iClient].RoundDeaths = 0;
	g_pPlayer[iClient].RoundKills = 0;
	
	SDKHook(iClient, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	SDKHook(iClient, SDKHook_WeaponCanSwitchTo, Hook_WeaponCanSwitchTo);
	SDKHookEx(iClient, SDKHook_FireBulletsPost, Hook_FireBulletsPost);
	SDKHookEx(iClient, SDKHook_WeaponSwitchPost, Hook_WeaponSwitchPost);
	
	LoadClient(iClient);
	
	SetClientNickname(iClient);
	
	SetPlayerFOV(iClient, true);
	
	CreateTimer(0.1, Timer_ModelChanger, iClient);
}

public void OnClientDisconnect(int iClient)
{
	if(g_pPlayer[iClient].IsPlayer)
	{
		g_pPlayer[iClient].DevMode = false;
		g_pPlayer[iClient].Invisible = false;
		g_pPlayer[iClient].InZoom = false;
		g_pPlayer[iClient].IsPlayer = false;
		g_pPlayer[iClient].JumpPressed = false;
		g_pPlayer[iClient].SpawnProtect = false;
		
		SDKUnhook(iClient, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
		
		CloseHandle(g_pPlayer[iClient].StatsHUD);
		
		SaveClient(iClient);
	}
}

public void OnConVarsChanged(ConVar convar, char[] oldValue, char[] newValue)
{
	g_cvConVars.AllowPrivateMatches.AddChangeHook(OnConVarsChanged);
	g_cvConVars.ColorNickPrice.AddChangeHook(OnConVarsChanged);
	g_cvConVars.CrowbarDamage.AddChangeHook(OnConVarsChanged);
	g_cvConVars.DefaultFOV.AddChangeHook(OnConVarsChanged);
	g_cvConVars.DefaultJumpVel.AddChangeHook(OnConVarsChanged);
	g_cvConVars.DisableAdverts.AddChangeHook(OnConVarsChanged);
	g_cvConVars.DisableFallDamage.AddChangeHook(OnConVarsChanged);
	g_cvConVars.EnableColoredNick.AddChangeHook(OnConVarsChanged);
	g_cvConVars.EnableInvisible.AddChangeHook(OnConVarsChanged);
	g_cvConVars.EnableJetpack.AddChangeHook(OnConVarsChanged);
	g_cvConVars.EnableJumpBoost.AddChangeHook(OnConVarsChanged);
	g_cvConVars.EnableLongJump.AddChangeHook(OnConVarsChanged);
	g_cvConVars.EnableModelChange.AddChangeHook(OnConVarsChanged);
	g_cvConVars.EnableNick.AddChangeHook(OnConVarsChanged);
	g_cvConVars.EnableRPG.AddChangeHook(OnConVarsChanged);
	g_cvConVars.EnableSourceTV.AddChangeHook(OnConVarsChanged);
	g_cvConVars.FallingFix.AddChangeHook(OnConVarsChanged);
	g_cvConVars.HalfDamage.AddChangeHook(OnConVarsChanged);
	g_cvConVars.HealthBoost.AddChangeHook(OnConVarsChanged);
	g_cvConVars.HealthBoostPrice.AddChangeHook(OnConVarsChanged);
	g_cvConVars.HealthModifier.AddChangeHook(OnConVarsChanged);
	g_cvConVars.InvisibilityPrice.AddChangeHook(OnConVarsChanged);
	g_cvConVars.Jetpack.AddChangeHook(OnConVarsChanged);
	g_cvConVars.JetpackPrice.AddChangeHook(OnConVarsChanged);
	g_cvConVars.JumpBoost.AddChangeHook(OnConVarsChanged);
	g_cvConVars.JumpBoostPrice.AddChangeHook(OnConVarsChanged);
	g_cvConVars.LongJumpPrice.AddChangeHook(OnConVarsChanged);
	g_cvConVars.LongJumpSound.AddChangeHook(OnConVarsChanged);
	g_cvConVars.LongJumpVel.AddChangeHook(OnConVarsChanged);
	g_cvConVars.ShowAllKills.AddChangeHook(OnConVarsChanged);
	g_cvConVars.StartFOV.AddChangeHook(OnConVarsChanged);
	g_cvConVars.StartHealth.AddChangeHook(OnConVarsChanged);
	g_cvConVars.UseFOV.AddChangeHook(OnConVarsChanged);
	g_cvConVars.UseRegMenus.AddChangeHook(OnConVarsChanged);
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVel[3], float fAngles[3], int &iWeapon, int &iSubtype, int &iCmdnum, int &iTickcount, int &iSeed, int iMouse[2])
{
	char sWeapon[128];
	int iFlags = GetEntityFlags(iClient);
	float fSpawnPoint[3], fVelocity[3];
	
	GetClientAbsOrigin(iClient, fSpawnPoint);
	
	Client_GetWeapon(iClient, sWeapon);
	
	if(g_pPlayer[iClient].DevMode)
	{
		if (iButtons & IN_ATTACK)
		{
			iButtons &= ~IN_ATTACK;
		}else if (iButtons & IN_ATTACK2)
		{
			iButtons &= ~IN_ATTACK2;
		}
		
		return Plugin_Continue;
	}
	
	if(g_pPlayer[iClient].SpawnProtect)
	{
		if(iButtons & IN_RUN || iButtons & IN_JUMP || iButtons & IN_DUCK || iButtons & IN_BACK || iButtons & IN_LEFT || iButtons & IN_WALK || iButtons & IN_RIGHT || iButtons & IN_SPEED || iButtons & IN_ATTACK || iButtons & IN_FORWARD || iButtons & IN_ATTACK2 || iButtons & IN_ATTACK3 || iButtons & IN_MOVELEFT || iButtons & IN_MOVERIGHT)
		{
			SetEntProp(iClient, Prop_Data, "m_takedamage", 2, 1);
			
			SetEntityRenderColor(iClient, 255, 255, 255, 255);
			SetEntityRenderFx(iClient, g_pPlayer[iClient].Invisible ? RENDERFX_DISTORT : RENDERFX_NONE);
			
			g_pPlayer[iClient].SpawnProtect = false;
		}
	}
	
	for (int i = 0; i < MAX_BUTTONS; i++)
	{
		int iButton = (1 << i);
		
		if ((iButtons & iButton) && !(g_pPlayer[iClient].LastButtonPressed & iButton))
		{
			if((iButtons & IN_DUCK) && (iButton & IN_JUMP) && (iFlags & FL_ONGROUND) && !g_pPlayer[iClient].JumpPressed && g_pPlayer[iClient].LongJump[1] && g_itItems.EnableLongJump)
			{
				LongJumpFunction(iClient);
				
				g_pPlayer[iClient].JumpPressed = true;
			}else if ((iButtons & IN_JUMP) && (iFlags & FL_ONGROUND) && !g_pPlayer[iClient].JumpPressed)
			{
				GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", fVelocity);
				
				fVelocity[2] += g_pPlayer[iClient].JumpBoost[1] ? g_itItems.JumpBoostVel : g_sServer.JumpVel;
				TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, fVelocity);
				
				g_pPlayer[iClient].JumpPressed = true;
			}
			
			if((iButtons & IN_ZOOM))
			{
				g_pPlayer[iClient].InZoom = true;
			}
		}
		
		if ((g_pPlayer[iClient].LastButtonPressed & iButton) && !(iButtons & iButton))
		{
			if((iButton & IN_ZOOM))
			{
				Client_SetFOV(iClient, g_sServer.DefaultFOV);
				g_pPlayer[iClient].InZoom = false;
			}
			
			if((iButton & IN_JUMP) && g_pPlayer[iClient].JumpPressed)
			{
				g_pPlayer[iClient].JumpPressed = false;
			}
		}
	}
	
	g_pPlayer[iClient].LastButtonPressed = iButtons;
	
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
	
	return Plugin_Continue;
}

//Development Commands:
public Action Dev_GodMode(int iClient, int iArgs)
{
	g_pPlayer[iClient].GodMode = !g_pPlayer[iClient].GodMode;
	g_pPlayer[iClient].GodMode ? SetEntProp(iClient, Prop_Data, "m_takedamage", 0, 1) : SetEntProp(iClient, Prop_Data, "m_takedamage", 2, 1);
	
	g_pPlayer[iClient].DevMode = g_pPlayer[iClient].GodMode;
	
	CPrintToChat(iClient, "[{blue}KINGS-DEV{default}] God Mode has been %s.", g_pPlayer[iClient].GodMode ? "Enabled" : "Disabled");
	
	return Plugin_Handled;
}

public Action Dev_TestDiscord(int iClient, int iArgs)
{
	if(iArgs < 1)
	{
		CReplyToCommand(iClient, "[{blue}KINGS-DEV{default}] {green}dev_discord{default} <message>");
		
		return Plugin_Handled;
	}
	
	char sMessage[MAX_MESSAGE_LENGTH];
	
	GetCmdArgString(sMessage, sizeof(sMessage));
	
	Format(sMessage, sizeof(sMessage), "TEST: %s", sMessage);
	
	Discord_EscapeString(sMessage, sizeof(sMessage));
	
	Discord_SendMessage("test_discord", sMessage);
	
	return Plugin_Handled;
}

//Normal Commands:
public Action Command_ChangeCredits(int iClient, int iArgs)
{
	if(iArgs < 2)
	{
		CReplyToCommand(iClient, "[{red}KINGS{default}] {green}sm_changecredits{default} <player> <credits>");
		
		return Plugin_Handled;
	}
	
	char sCredits[16], sPlayer[MAX_NAME_LENGTH];
	
	GetCmdArg(2, sCredits, sizeof(sCredits));
	GetCmdArg(1, sPlayer, sizeof(sPlayer));
	
	int iPlayer = FindTarget(iClient, sPlayer, true, false);
	
	if(iPlayer == -1)
	{
		CReplyToCommand(iClient, "[{red}KINGS{default}] Player {green}%s{default} cannot be found.", sPlayer);
		
		return Plugin_Handled;
	}
	
	g_pPlayer[iClient].Credits = StringToInt(sCredits);
	
	CReplyToCommand(iClient, "[{red}KINGS{default}] Set player {green}%N{default} credits to {green}%i{default}.", iPlayer, StringToInt(sCredits));
	
	return Plugin_Handled;
}

public Action Command_ChangeNickname(int iClient, int iArgs)
{
	if(iArgs < 1)
	{
		CReplyToCommand(iClient, "[{red}KINGS{default}] {green}sm_changenickname{default} <nickname> <color>");
		
		return Plugin_Handled;
	}
	
	char sColor[64], sNickname[MAX_NAME_LENGTH];
	
	GetCmdArg(1, sNickname, sizeof(sNickname));
	GetCmdArg(2, sColor, sizeof(sColor));
	
	if(g_itItems.EnableNickname)
	{
		if(CColorExists(sColor) || g_itItems.EnableColorNick || g_pPlayer[iClient].ColoredNick)
		{
			Format(g_pPlayer[iClient].NickColor, sizeof(g_pPlayer[].NickColor), sColor);
			Format(g_pPlayer[iClient].Nickname, sizeof(g_pPlayer[].Nickname), sNickname);
			
			SetClientNickname(iClient);
			
			SaveClient(iClient);
			
			CReplyToCommand(iClient, "[{red}KINGS{default}] Set {green}%N{default}'s nickname to {%s}%s{default}.", iClient, sColor, sNickname);
			
			return Plugin_Handled;
		}else{
			
			if(!g_pPlayer[iClient].ColoredNick)
			{
				CReplyToCommand(iClient, "[{red}KINGS{default}] Color {green}%s{default} cannot be found.", sColor);
				return Plugin_Handled;
			}else{
				CReplyToCommand(iClient, "[{red}KINGS{default}] You cannot color your nickname.", sColor);
			}
			
			CReplyToCommand(iClient, "[{red}KINGS{default}] Set {green}%N{default}'s nickname to {default}%s{default}.", iClient, sNickname);
			
			return Plugin_Handled;
		}
	}else{
		CReplyToCommand(iClient, "[{red}KINGS{default}] Nicknames are disabled.");
		
		return Plugin_Handled;
	}
}

public Action Command_Credits(int iClient, int iArgs)
{
	char sDescription[128];
	
	if(g_sServer.RegMenu)
	{
		Menu hMenu = new Menu(Menu_Credits, MENU_ACTIONS_ALL);
		
		hMenu.SetTitle("Credit Menu (%i credits)", g_pPlayer[iClient].Credits);
		
		Format(sDescription, sizeof(sDescription), "Health Boost +%ihp | %i Credits", g_itItems.HealthBoost, g_iUpgradePrices[0]);
		hMenu.AddItem("opt_healthboost", sDescription);
		
		Format(sDescription, sizeof(sDescription), "Invisibility | %i Credits", g_iUpgradePrices[1]);
		hMenu.AddItem("opt_distort", sDescription);
		
		Format(sDescription, sizeof(sDescription), "Jump Boost | %i Credits | %s", g_iUpgradePrices[2], g_pPlayer[iClient].JumpBoost[0] ? (g_pPlayer[iClient].JumpBoost[1] ? "Enabled" : "Disabled") : "Lifetime Purchase");
		hMenu.AddItem("opt_jumpboost", sDescription);
		
		Format(sDescription, sizeof(sDescription), "Long Jump | %i Credits | %s", g_iUpgradePrices[3], g_pPlayer[iClient].LongJump[0] ? (g_pPlayer[iClient].LongJump[1] ? "Enabled" : "Disabled") : "Lifetime Purchase");
		hMenu.AddItem("opt_longjump", sDescription);
		
		hMenu.ExitButton = true;
		
		hMenu.Display(iClient, MENU_TIME_FOREVER);
	}else{
		CPrintToChat(iClient, "[{red}KINGS{default}] Credit Menu (%i credits)", g_pPlayer[iClient].Credits);
		
		Format(sDescription, sizeof(sDescription), "Health Boost +%ihp | %i Credits", g_itItems.HealthBoost, g_iUpgradePrices[0]);
		CPrintToChat(iClient, " - %s - Command: !%s", sDescription, "boost");
		
		Format(sDescription, sizeof(sDescription), "Invisibility | %i Credits", g_iUpgradePrices[1]);
		CPrintToChat(iClient, " - %s - Command: !%s", sDescription, "invisible");
		
		Format(sDescription, sizeof(sDescription), "Jump Boost | %i Credits | %s", g_iUpgradePrices[2], g_pPlayer[iClient].JumpBoost[0] ? (g_pPlayer[iClient].JumpBoost[1] ? "Enabled" : "Disabled") : "Lifetime Purchase");
		CPrintToChat(iClient, " - %s - Command: !%s", sDescription, "jumpboost");
		
		Format(sDescription, sizeof(sDescription), "Long Jump | %i Credits | %s", g_iUpgradePrices[3], g_pPlayer[iClient].LongJump[0] ? (g_pPlayer[iClient].LongJump[1] ? "Enabled" : "Disabled") : "Lifetime Purchase");
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
		Format(g_pPlayer[iClient].DefaultWeapon, sizeof(g_pPlayer[].DefaultWeapon), "weapon_crowbar");
		
		CPrintToChat(iClient, "[{red}KINGS{default}] Changed default weapon to '{green}Crowbar{default}'.");
	}else if(StrContains(sWeapon, "2", false) != -1 || StrContains(sWeapon, "stunstick", false) != -1)
	{
		Format(g_pPlayer[iClient].DefaultWeapon, sizeof(g_pPlayer[].DefaultWeapon), "weapon_stunstick");
		
		CPrintToChat(iClient, "[{red}KINGS{default}] Changed default weapon to '{green}Stunstick{default}'.");
	}else if(StrContains(sWeapon, "3", false) != -1 || StrContains(sWeapon, "gravity gun", false) != -1 || StrContains(sWeapon, "physcannon", false) != -1)
	{
		Format(g_pPlayer[iClient].DefaultWeapon, sizeof(g_pPlayer[].DefaultWeapon), "weapon_physcannon");
		
		CPrintToChat(iClient, "[{red}KINGS{default}] Changed default weapon to '{green}Gravity Gun{default}'.");
	}else if(StrContains(sWeapon, "4", false) != -1 || StrContains(sWeapon, "pistol", false) != -1 || StrContains(sWeapon, "9mm", false) != -1)
	{
		Format(g_pPlayer[iClient].DefaultWeapon, sizeof(g_pPlayer[].DefaultWeapon), "weapon_pistol");
		
		CPrintToChat(iClient, "[{red}KINGS{default}] Changed default weapon to '{green}9mm Pistol{default}'.");
	}else if(StrContains(sWeapon, "5", false) != -1 || StrContains(sWeapon, "magnum", false) != -1 || StrContains(sWeapon, "357", false) != -1 || StrContains(sWeapon, "revolver", false) != -1)
	{
		Format(g_pPlayer[iClient].DefaultWeapon, sizeof(g_pPlayer[].DefaultWeapon), "weapon_357");
		
		CPrintToChat(iClient, "[{red}KINGS{default}] Changed default weapon to '{green}.357 Magnum{default}'.");
	}else if(StrContains(sWeapon, "6", false) != -1 || StrContains(sWeapon, "smg", false) != -1 || StrContains(sWeapon, "smg1", false) != -1)
	{
		Format(g_pPlayer[iClient].DefaultWeapon, sizeof(g_pPlayer[].DefaultWeapon), "weapon_smg1");
		
		CPrintToChat(iClient, "[{red}KINGS{default}] Changed default weapon to '{green}SMG1{default}'.");
	}else if(StrContains(sWeapon, "7", false) != -1 || StrContains(sWeapon, "ar2", false) != -1 || StrContains(sWeapon, "pulse", false) != -1)
	{
		Format(g_pPlayer[iClient].DefaultWeapon, sizeof(g_pPlayer[].DefaultWeapon), "weapon_ar2");
		
		CPrintToChat(iClient, "[{red}KINGS{default}] Changed default weapon to '{green}Pulse Rifle (AR2){default}'.");
	}else if(StrContains(sWeapon, "8", false) != -1 || StrContains(sWeapon, "shotgun", false) != -1)
	{
		Format(g_pPlayer[iClient].DefaultWeapon, sizeof(g_pPlayer[].DefaultWeapon), "weapon_shotgun");
		
		CPrintToChat(iClient, "[{red}KINGS{default}] Changed default weapon to '{green}Shotgun{default}'.");
	}else if(StrContains(sWeapon, "9", false) != -1 || StrContains(sWeapon, "crossbow", false) != -1)
	{
		Format(g_pPlayer[iClient].DefaultWeapon, sizeof(g_pPlayer[].DefaultWeapon), "weapon_crossbow");
		
		CPrintToChat(iClient, "[{red}KINGS{default}] Changed default weapon to '{green}Crossbow{default}'.");
	}else if(StrContains(sWeapon, "10", false) != -1 || StrContains(sWeapon, "grenades", false) != -1 || StrContains(sWeapon, "frag", false) != -1)
	{
		Format(g_pPlayer[iClient].DefaultWeapon, sizeof(g_pPlayer[].DefaultWeapon), "weapon_frag");
		
		CPrintToChat(iClient, "[{red}KINGS{default}] Changed default weapon to '{green}Frag grenades{default}'.");
	}else if(StrEqual(sWeapon, "", false))
	{
		Client_GetActiveWeaponName(iClient, g_pPlayer[iClient].DefaultWeapon, sizeof(g_pPlayer[].DefaultWeapon));
		
		CPrintToChat(iClient, "[{red}KINGS{default}] Default weapon changed to your current weapon.");
	}else{
		Client_GetActiveWeaponName(iClient, g_pPlayer[iClient].DefaultWeapon, sizeof(g_pPlayer[].DefaultWeapon));
		
		CPrintToChat(iClient, "[{red}KINGS{default}] Invalid weapon selection. Default weapon changed to your current weapon.");
	}
	
	SaveClient(iClient);
	
	//Client_ChangeWeapon(iClient, g_pPlayer[iClient].DefaultWeapon);
	
	return Plugin_Handled;
}

public Action Command_HealthBoost(int iClient, int iArgs)
{
	if (g_pPlayer[iClient].Credits <= g_iUpgradePrices[0])
	{
		CPrintToChat(iClient, "[{red}KINGS{default}] You do not have enough credits.");
	} else {
		g_pPlayer[iClient].Credits -= g_iUpgradePrices[0];
		
		CPrintToChat(iClient, "[{red}KINGS{default}] You have bought the {green}Health Boost{default} for {green}%i{default} credits. {green}%ihp{default} has been added to your health.", g_iUpgradePrices[1], g_itItems.HealthBoost);
		
		int iNewHealth = (GetClientHealth(iClient) + g_itItems.HealthBoost);
		
		SetEntityHealth(iClient, iNewHealth);
		
		SaveClient(iClient);
	}
	
	return Plugin_Handled;
}

public Action Command_Invisibility(int iClient, int iArgs)
{
	if(!g_itItems.EnableInvisibility)
	{
		return Plugin_Handled;
	}
	
	if (g_pPlayer[iClient].Credits <= g_iUpgradePrices[1])
	{
		CPrintToChat(iClient, "[{red}KINGS{default}] You do not have enough credits.");
	} else {
		g_pPlayer[iClient].Credits -= g_iUpgradePrices[1];
		
		CPrintToChat(iClient, "[{red}KINGS{default}] You have bought the {green}Invisibility Effect{default} for {green}%i{default} credits for {green}%f.f{default} seconds.", g_iUpgradePrices[0], g_fUpgradeDuration[0]);
		
		SetEntityRenderColor(iClient, 255, 255, 255, 0);
		
		g_pPlayer[iClient].Invisible = true;
		
		CreateTimer(g_fUpgradeDuration[0], Timer_Visible, iClient);
		
		SaveClient(iClient);
	}
	
	return Plugin_Handled;
}

public Action Command_Jetpack(int iClient, int iArgs)
{
	if(!g_itItems.EnableJumpBoost)
	{
		return Plugin_Handled;
	}
	
	if(g_pPlayer[iClient].Jetpack[0])
	{
		g_pPlayer[iClient].Jetpack[1] = !g_pPlayer[iClient].Jetpack[1];
		
		CPrintToChat(iClient, "[{red}KINGS{default}] Jetpack has been %s.", g_pPlayer[iClient].Jetpack[1] ? "Enabled" : "Disabled");
		
		SaveClient(iClient);
		
		return Plugin_Handled;
	}
	
	if (g_pPlayer[iClient].Credits <= g_iUpgradePrices[4])
	{
		CPrintToChat(iClient, "[{red}KINGS{default}] You do not have enough credits.");
	} else {
		g_pPlayer[iClient].Credits -= g_iUpgradePrices[4];
		
		CPrintToChat(iClient, "[{red}KINGS{default}] You have bought the {green}Jetpack Module{default} for {green}%i{default} credits.", g_iUpgradePrices[4]);
		
		g_pPlayer[iClient].Jetpack[0] = true;
		g_pPlayer[iClient].Jetpack[1] = true;
		
		SaveClient(iClient);
	}
	
	return Plugin_Handled;
}

public Action Command_JumpBoost(int iClient, int iArgs)
{
	if(!g_itItems.EnableJumpBoost)
	{
		return Plugin_Handled;
	}
	
	if(g_pPlayer[iClient].JumpBoost[0])
	{
		g_pPlayer[iClient].JumpBoost[1] = !g_pPlayer[iClient].JumpBoost[1];
		
		CPrintToChat(iClient, "[{red}KINGS{default}] Jump Boost has been %s.", g_pPlayer[iClient].JumpBoost[1] ? "Enabled" : "Disabled");
		
		SaveClient(iClient);
		
		return Plugin_Handled;
	}
	
	if (g_pPlayer[iClient].Credits <= g_iUpgradePrices[2])
	{
		CPrintToChat(iClient, "[{red}KINGS{default}] You do not have enough credits.");
	} else {
		g_pPlayer[iClient].Credits -= g_iUpgradePrices[2];
		
		CPrintToChat(iClient, "[{red}KINGS{default}] You have bought the {green}Jump Boost Module{default} for {green}%i{default} credits.", g_iUpgradePrices[2]);
		
		g_pPlayer[iClient].JumpBoost[0] = true;
		g_pPlayer[iClient].JumpBoost[1] = true;
		
		//CreateTimer(g_fUpgradeDuration[1], Timer_JumpBoost, iClient);
		
		SaveClient(iClient);
	}
	
	return Plugin_Handled;
}

public Action Command_LongJump(int iClient, int iArgs)
{
	if(g_pPlayer[iClient].LongJump[0])
	{
		g_pPlayer[iClient].LongJump[1] = !g_pPlayer[iClient].LongJump[1];
		
		CPrintToChat(iClient, "[{red}KINGS{default}] Long Jump has been %s.", g_pPlayer[iClient].LongJump[1] ? "Enabled" : "Disabled");
		
		SaveClient(iClient);
		
		return Plugin_Handled;
	}
	
	if (g_pPlayer[iClient].Credits <= g_iUpgradePrices[3])
	{
		CPrintToChat(iClient, "[{red}KINGS{default}] You do not have enough credits.");
	} else {
		g_pPlayer[iClient].Credits -= g_iUpgradePrices[3];
		
		CPrintToChat(iClient, "[{red}KINGS{default}] You have bought the {green}Long Jump Module{default} for {green}%i{default} credits.", g_iUpgradePrices[3]);
		
		g_pPlayer[iClient].LongJump[0] = true;
		g_pPlayer[iClient].LongJump[1] = true;
		
		SaveClient(iClient);
	}
	
	return Plugin_Handled;
}

public Action Command_PlayerModel(int iClient, int iArgs)
{
	if(!g_itItems.EnableModelChange)
	{
		return Plugin_Handled;
	}
	
	char sArg[64], sModels[256], sName[64];
	
	GetCmdArg(1, sArg, sizeof(sArg));
	
	/*SetPlayerModel(iClient, sArg);

	CReplyToCommand(iClient, "[{red}KINGS{default}] Player changing: %s, %s", SetPlayerModel(iClient, sArg) ? "true" : "false", sArg);

	return Plugin_Handled;*/
	
	if(SetPlayerModel(iClient, sArg))
	{
		SetPlayerModel(iClient, sArg);
		
		CReplyToCommand(iClient, "[{red}KINGS{default}] Set player model to {green}%s{default}.", sArg);
		
		return Plugin_Handled;
	}else if(StrEqual(sArg, "list")){
		KeyValues kvModels = new KeyValues("PlayerModels");
		
		kvModels.ImportFromFile(g_sServer.ModelsDB);
		
		if (!kvModels.JumpToKey("Models", false))
		{
			kvModels.Close();
			
			CReplyToCommand(iClient, "[{red}KINGS{default}] Cannot print model list. (Cannot jump to key)");
			
			return Plugin_Handled;
		}
		
		if (!kvModels.GotoFirstSubKey(false))
		{
			kvModels.Close();
			
			CReplyToCommand(iClient, "[{red}KINGS{default}] Cannot print model list. (Cannot goto first sub key)");
			
			return Plugin_Handled;
		}
		
		do
		{
			kvModels.GetSectionName(sName, sizeof(sName));
			
			if(StrEqual(sModels, ""))
			{
				Format(sModels, sizeof(sModels), "%s", sName);
			}else{
				Format(sModels, sizeof(sModels), "%s, %s", sModels, sName);
			}
		} while (kvModels.GotoNextKey(false));
		
		kvModels.Close();
		
		CReplyToCommand(iClient, "[{red}KINGS{default}] Player Models: %s", sModels);
		
		return Plugin_Handled;
	}else if(StrEqual(sArg, "")){
		CReplyToCommand(iClient, "[{red}KINGS{default}] {green}sm_playermodel{default} <npcname|list>");
		
		return Plugin_Handled;
	}else{
		KeyValues kvModels = new KeyValues("PlayerModels");
		
		kvModels.ImportFromFile(g_sServer.ModelsDB);
		
		if (!kvModels.JumpToKey("Models", false))
		{
			kvModels.Close();
			
			CReplyToCommand(iClient, "[{red}KINGS{default}] Cannot print model list. (Cannot jump to key)");
			
			return Plugin_Handled;
		}
		
		if (!kvModels.GotoFirstSubKey(false))
		{
			kvModels.Close();
			
			CReplyToCommand(iClient, "[{red}KINGS{default}] Cannot print model list. (Cannot goto first sub key)");
			
			return Plugin_Handled;
		}
		
		do
		{
			kvModels.GetSectionName(sName, sizeof(sName));
			
			if(StrEqual(sModels, ""))
			{
				Format(sModels, sizeof(sModels), "%s", sName);
			}else{
				Format(sModels, sizeof(sModels), "%s, %s", sModels, sName);
			}
		} while (kvModels.GotoNextKey(false));
		
		kvModels.Close();
		
		CReplyToCommand(iClient, "[{red}KINGS{default}] Player Models: %s", sModels);
		
		return Plugin_Handled;
	}
}

public Action Command_PrivateMatch(int iClient, int iArgs)
{
	if(CheckCommandAccess(iClient, "dev_gmode", view_as<int>(Admin_Custom4)))
	{
		g_sServer.PrivateMatchRunning = !g_sServer.PrivateMatchRunning;
		
		g_sServer.PrivateMatchRunning ? Format(g_sServer.Password, sizeof(g_sServer.Password), "kings-%i%i%i", GetRandomInt(0, 24), GetRandomInt(24, 64), GetRandomInt(64, 99)) : Format(g_sServer.Password, sizeof(g_sServer.Password), "");
		
		g_cvConVars.ServerPassword.SetString(g_sServer.Password);
		
		CPrintToChat(iClient, "[{red}KINGS{default}] Private matches are %s.", g_sServer.PrivateMatchRunning ? "Enabled" : "Disabled");
		
		return Plugin_Handled;
	}else{
		if(g_sServer.PrivateMatchRunning)
		{
			CPrintToChat(iClient, "[{red}KINGS{default}] Only Admins can disable the private match.");
			return Plugin_Handled;
		}
		
		if(!g_sServer.PrivateMatchAllowed)
		{
			CPrintToChat(iClient, "[{red}KINGS{default}] Private matches are Disabled.");
			return Plugin_Handled;
		}
		
		Format(g_sServer.Password, sizeof(g_sServer.Password), "kings-%i%i%i", GetRandomInt(0, 24), GetRandomInt(24, 64), GetRandomInt(64, 99));
		
		g_cvConVars.ServerPassword.SetString(g_sServer.Password);
		
		g_sServer.PrivateMatchRunning = true;
		
		return Plugin_Handled;
	}
}

public Action Command_SetNickname(int iClient, int iArgs)
{
	if(iArgs < 2)
	{
		CReplyToCommand(iClient, "[{red}KINGS{default}] {green}sm_setnickname{default} <player> <nickname> <color>");
		
		return Plugin_Handled;
	}
	
	char sColor[64], sPlayer[MAX_NAME_LENGTH], sNickname[MAX_NAME_LENGTH];
	
	GetCmdArg(1, sPlayer, sizeof(sPlayer));
	GetCmdArg(2, sNickname, sizeof(sNickname));
	GetCmdArg(3, sColor, sizeof(sColor));
	
	int iPlayer = FindTarget(iClient, sPlayer, true, false);
	
	if(iPlayer == -1)
	{
		CReplyToCommand(iClient, "[{red}KINGS{default}] Player {green}%s{default} cannot be found.", sPlayer);
		
		return Plugin_Handled;
	}
	
	if(g_itItems.EnableNickname)
	{
		if(CColorExists(sColor) || g_itItems.EnableColorNick)
		{
			Format(g_pPlayer[iPlayer].NickColor, sizeof(g_pPlayer[].NickColor), sColor);
			Format(g_pPlayer[iPlayer].Nickname, sizeof(g_pPlayer[].Nickname), sNickname);
			
			SetClientNickname(iPlayer);
			
			SaveClient(iPlayer);
			
			CReplyToCommand(iClient, "[{red}KINGS{default}] Set {green}%N{default}'s nickname to {%s}%s{default}.", iPlayer, sColor, sNickname);
			
			return Plugin_Handled;
		}else{
			CReplyToCommand(iClient, "[{red}KINGS{default}] Color {green}%s{default} cannot be found.", sColor);
			CReplyToCommand(iClient, "[{red}KINGS{default}] Set {green}%N{default}'s nickname to {default}%s{default}.", iPlayer, sNickname);
			
			return Plugin_Handled;
		}
	}else{
		CReplyToCommand(iClient, "[{red}KINGS{default}] Nicknames are disabled.");
		
		return Plugin_Handled;
	}
}

public Action Handle_Chat(int iClient, char[] sCommand, int iArgs)
{
	char sColor[128], sFullMessage[MAX_MESSAGE_LENGTH], sMessage[MAX_MESSAGE_LENGTH];
	
	if (IsChatTrigger())
	{
		return Plugin_Handled;
	}else{
		GetCmdArgString(sMessage, sizeof(sMessage));
		
		StripQuotes(sMessage);
		
		CRemoveTags(sMessage, sizeof(sMessage));
		
		Format(sColor, sizeof(sColor), "%s", StrEqual(g_pPlayer[iClient].NickColor, "") ? "default" : g_pPlayer[iClient].NickColor);
		Format(sFullMessage, sizeof(sFullMessage), "{%s}%N{default} : %s", sColor, iClient, sMessage);
		
		//CPrintToChatAll("{%s}%N{default} : %s", sColor, iClient, sMessage);
		//CPrintToChatAll("{%s}%s", sColor, sColor);
		CPrintToChatAll(sFullMessage);
		
		return Plugin_Handled;
	}
}

public Action Handle_Zoom(int iClient, char[] sCommand, int iArgs)
{
	SetPlayerFOV(iClient, false);
	
	return Plugin_Continue;
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
	
	if(g_pPlayer[iClient].SpawnProtect)
	{
		SetEntProp(iClient, Prop_Data, "m_takedamage", 2, 1);
		
		SetEntityRenderColor(iClient, 255, 255, 255, 255);
		SetEntityRenderFx(iClient, (g_itItems.EnableInvisibility && g_pPlayer[iClient].Invisible) ? RENDERFX_DISTORT : RENDERFX_NONE);
		
		g_pPlayer[iClient].SpawnProtect = false;
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
	
	kvVault.ImportFromFile(g_sServer.ClientsDB);
	
	kvVault.JumpToKey(sAuthID, false);
	
	g_pPlayer[iClient].AllDeaths = LoadInteger(kvVault, sAuthID, "all_deaths", 0);
	g_pPlayer[iClient].AllKills = LoadInteger(kvVault, sAuthID, "all_kills", 0);
	g_pPlayer[iClient].Credits = LoadInteger(kvVault, sAuthID, "credits", 1500);
	
	LoadString(kvVault, sAuthID, "default_weapon", "weapon_357", g_pPlayer[iClient].DefaultWeapon, sizeof(g_pPlayer[].DefaultWeapon));
	
	g_pPlayer[iClient].Jetpack[0] = view_as<bool>(LoadInteger(kvVault, sAuthID, "jetpack", 0));
	g_pPlayer[iClient].Jetpack[1] = view_as<bool>(LoadInteger(kvVault, sAuthID, "previous_jet_setting", 0));
	
	g_pPlayer[iClient].JumpBoost[0] = view_as<bool>(LoadInteger(kvVault, sAuthID, "jump_boost", 0));
	g_pPlayer[iClient].JumpBoost[1] = view_as<bool>(LoadInteger(kvVault, sAuthID, "previous_jb_setting", 0));
	
	g_pPlayer[iClient].LongJump[0] = view_as<bool>(LoadInteger(kvVault, sAuthID, "long_jump", 0));
	g_pPlayer[iClient].LongJump[1] = view_as<bool>(LoadInteger(kvVault, sAuthID, "previous_lj_setting", 0));
	
	LoadString(kvVault, sAuthID, "nickname_color", "", g_pPlayer[iClient].NickColor, sizeof(g_pPlayer[].NickColor));
	LoadString(kvVault, sAuthID, "nickname_text", "", g_pPlayer[iClient].Nickname, sizeof(g_pPlayer[].Nickname));
	
	LoadString(kvVault, sAuthID, "player_model", "", g_pPlayer[iClient].Model, sizeof(g_pPlayer[].Model));
	
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
	
	fPushForce[0] = (g_itItems.PushVel * Cosine(DegToRad(fEyeAngles[1])));
	fPushForce[1] = (g_itItems.PushVel * Sine(DegToRad(fEyeAngles[1])));
	fPushForce[2] = (-50.0 * Sine(DegToRad(fEyeAngles[0])));
	
	TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, fPushForce);
	
	//Sound from Black Mesa: Source (2012 Mod)
	Format(sSound, sizeof(sSound), "bms/weapons/jumpmod/jumpmod_long1.mp3"/*, view_as<bool>(GetRandomInt(0, 1)) ? "long" : "boost"*/);
	
	PrecacheSound(sSound);
	
	if(g_itItems.EnableLongJumpSound)
	EmitSoundToClient(iClient, sSound, iClient, 2, 100, 0, 0.1, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
}

public void ReFillWeapon(int iClient, int iWeapon)
{
	int iPrimaryAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
	
	if (iPrimaryAmmoType != -1)
	{
		if (iPrimaryAmmoType != RPG_ROUNDS && iPrimaryAmmoType != GRENADES)
		{
			SetEntProp(iWeapon, Prop_Send, "m_iClip1", g_iClipSizes[iPrimaryAmmoType]);
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
	
	kvVault.ImportFromFile(g_sServer.ClientsDB);
	
	SaveInteger(kvVault, sAuthID, "all_deaths", g_pPlayer[iClient].AllDeaths);
	SaveInteger(kvVault, sAuthID, "all_Kills", g_pPlayer[iClient].AllKills);
	SaveInteger(kvVault, sAuthID, "credits", g_pPlayer[iClient].Credits);
	
	SaveString(kvVault, sAuthID, "default_weapon", g_pPlayer[iClient].DefaultWeapon);
	
	SaveInteger(kvVault, sAuthID, "jetpack", view_as<int>(g_pPlayer[iClient].Jetpack[0]));
	SaveInteger(kvVault, sAuthID, "previous_jet_setting", view_as<int>(g_pPlayer[iClient].Jetpack[1]));
	
	SaveInteger(kvVault, sAuthID, "jump_boost", view_as<int>(g_pPlayer[iClient].JumpBoost[0]));
	SaveInteger(kvVault, sAuthID, "previous_jb_setting", view_as<int>(g_pPlayer[iClient].JumpBoost[1]));
	
	SaveInteger(kvVault, sAuthID, "long_jump", view_as<int>(g_pPlayer[iClient].LongJump[0]));
	SaveInteger(kvVault, sAuthID, "previous_lj_setting", view_as<int>(g_pPlayer[iClient].LongJump[1]));
	
	SaveString(kvVault, sAuthID, "nickname_color", g_pPlayer[iClient].NickColor);
	SaveString(kvVault, sAuthID, "nickname_text", g_pPlayer[iClient].Nickname);
	
	SaveString(kvVault, sAuthID, "player_model", g_pPlayer[iClient].Model);
	
	kvVault.ExportToFile(g_sServer.ClientsDB);
	
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

public void SetClientNickname(int iClient)
{
	char sCountry[3], sIP[64], sName[MAX_NAME_LENGTH];
	
	GetClientIP(iClient, sIP, sizeof(sIP));
	
	GeoipCode3(sIP, sCountry);
	
	if(IsClientSourceTV(iClient))
	{
		Format(sName, sizeof(sName), "WonderBread's Security Monitor");
	}else{
		if(StrEqual(g_pPlayer[iClient].Nickname, ""))
		{
			Format(sName, sizeof(sName), "[%s] %N", (StrEqual(sCountry, "")) ? "USA" : sCountry, iClient);
		}else{
			Format(sName, sizeof(sName), "[%s] %s", (StrEqual(sCountry, "")) ? "USA" : sCountry, g_pPlayer[iClient].Nickname);
		}
	}
	
	SetClientName(iClient, sName);
}

public void SetPlayerFOV(int iClient, bool bFirstJoin)
{
	if(g_sServer.ChangeFOV)
	{
		Client_SetFOV(iClient, bFirstJoin ? g_sServer.StartFOV : 80);
		
		for (int i = Client_GetFOV(iClient); i <= g_sServer.DefaultFOV; i++)
		{
			Client_SetFOV(iClient, i);
		}
	}
}

public bool SetPlayerModel(int iClient, char[] sModelName)
{
	char sModel[256];
	
	KeyValues kvModels = new KeyValues("PlayerModels");
	
	if(!kvModels.ImportFromFile(g_sServer.ModelsDB))
	{
		kvModels.Close();
		
		return false;
	}
	
	LoadString(kvModels, "Models", sModelName, "null", sModel, sizeof(sModel));
	
	kvModels.Rewind();
	
	if(StrEqual(sModel, "null"))
	{
		kvModels.Close();
		
		return false;
	}
	
	kvModels.Close();
	
	Format(g_pPlayer[iClient].Model, sizeof(g_pPlayer[].Model), sModelName);
	
	SaveClient(iClient);
	
	PrecacheModel(sModel);
	
	Entity_SetModel(iClient, sModel);
	
	return true;
}

//SDKHooks
public Action Hook_OnTakeDamage(int iClient, int &iAttacker, int &iInflictor, float &fDamage, int &iDamagetype)
{
	bool bSuicide;
	char sWeapon[64];
	
	if(g_pPlayer[iAttacker].DevMode)
	{
		return Plugin_Handled;
	}
	
	if (iAttacker == iClient)
	bSuicide = true;
	
	if(g_pPlayer[iClient].IsPlayer && g_pPlayer[iAttacker].IsPlayer)
	{
		GetClientWeapon(bSuicide ? iClient : iAttacker, sWeapon, sizeof(sWeapon));
	}
	
	if(iDamagetype == DMG_FALL && g_sServer.NoFallDamage)
	{
		return Plugin_Handled;
	}
	
	int iNewHealth = (GetClientHealth(iClient) - RoundFloat((fDamage * g_sServer.DamageModifier)));
	
	if (StrEqual(sWeapon, "weapon_crowbar") || StrEqual(sWeapon, "weapon_stunstick"))
	{
		iNewHealth -= g_wWeapons.CrowbarDamage;
	}
	
	if(g_sServer.AltDamage)
	{
		int iHealthMathShit = iNewHealth / 2;
		
		iNewHealth = iHealthMathShit;
	}
	
	SetEntityHealth(iClient, iNewHealth);
	
	return Plugin_Continue;
}

public void Hook_WeaponSwitchPost(int iClient, int iWeapon)
{
	if (iWeapon != -1)
	{
		ReFillWeapon(iClient, iWeapon);
	}
}

public Action Hook_WeaponCanSwitchTo(int iClient, int iWeapon)
{
	if(g_sServer.FallFix)
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
			
			if (StrEqual(sInfo, "opt_colornickname"))
			{
				FakeClientCommand(iParam1, "sm_colornickname");
			} else if (StrEqual(sInfo, "opt_distort"))
			{
				FakeClientCommand(iParam1, "sm_distort");
			} else if (StrEqual(sInfo, "opt_jetpackt"))
			{
				FakeClientCommand(iParam1, "sm_jetpack");
			} else if (StrEqual(sInfo, "opt_jumpboost"))
			{
				FakeClientCommand(iParam1, "sm_jumpboost");
			} else if (StrEqual(sInfo, "opt_healthboost"))
			{
				FakeClientCommand(iParam1, "sm_healthboost");
			} else if (StrEqual(sInfo, "opt_longjump"))
			{
				FakeClientCommand(iParam1, "sm_longjump");
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
/*public Action Event_PlayerChangename(Event eEvent, char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(eEvent.GetInt("userid"));

	SetClientNickname(iClient);
}*/

public Action Event_PlayerClass(Event eEvent, char[] sName, bool bDontBroadcast)
{
	eEvent.BroadcastDisabled = true;
}

public Action Event_PlayerDeath(Handle hEvent, char[] sName, bool bDontBroadcast)
{
	char sAttackerColor[MAX_NAME_LENGTH], sClientColor[MAX_NAME_LENGTH];
	
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	
	Format(sAttackerColor, sizeof(sAttackerColor), "%s", StrEqual(g_pPlayer[iAttacker].NickColor, "") ? "default" : g_pPlayer[iAttacker].NickColor);
	Format(sClientColor, sizeof(sClientColor), "%s", StrEqual(g_pPlayer[iClient].NickColor, "") ? "default" : g_pPlayer[iClient].NickColor);
	
	Client_SetFOV(iClient, 90);
	
	int iRandom = GetRandomInt(7, 15);
	
	if (iAttacker != iClient)
	{
		if (iAttacker == -1 || iAttacker == 0)
		{
			g_pPlayer[iClient].AllDeaths++;
			g_pPlayer[iClient].RoundDeaths++;
		} else {
			g_pPlayer[iAttacker].AllKills++;
			g_pPlayer[iAttacker].RoundKills++;
			g_pPlayer[iClient].AllDeaths++;
			g_pPlayer[iClient].RoundDeaths++;
			
			bool bHeadshot = GetEventBool(hEvent, "headshot");
			
			if(bHeadshot)
			{
				g_pPlayer[iAttacker].Credits += 16;
				
				CPrintToChatAll("{%s}%N{default} ({green}%i{default}HP, {green}%i{default} Suit) got {green}16{default} credits for getting a headshot kill on {%s}%N{default}!", sAttackerColor, iAttacker, GetClientHealth(iAttacker), Client_GetArmor(iAttacker), sClientColor, iClient);
			}else{
				g_pPlayer[iAttacker].Credits += iRandom;
				
				CPrintToChatAll("{%s}%N{default} ({green}%i{default}HP, {green}%i{default} Suit) got {green}%i{default} credits for killing {%s}%N{default}!", sAttackerColor, iAttacker, GetClientHealth(iAttacker), Client_GetArmor(iAttacker), iRandom, sClientColor, iClient);
			}
			
			SaveClient(iClient);
		}
	} else {
		g_pPlayer[iClient].AllKills--;
		g_pPlayer[iClient].RoundKills--;
		g_pPlayer[iClient].AllDeaths++;
		g_pPlayer[iClient].RoundDeaths++;
		
		g_pPlayer[iClient].Credits -= iRandom;
		
		CPrintToChatAll("{%s}%N{default} has lost {green}%i{default} credits for killing themselves.", sClientColor, iClient, iRandom);
	}
	
	SaveClient(iClient);
	
	CreateTimer(0.1, Timer_Visible, iClient);
	
	CreateTimer(0.1, Timer_Fire, iClient);
	
	CreateTimer(1.5, Timer_Dissolve, iClient);
}

public Action Event_PlayerSpawn(Handle hEvent, char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	CreateTimer(0.1, Timer_Guns, iClient);
	
	CreateTimer(0.1, Timer_Protection, iClient);
	
	if(g_itItems.EnableModelChange)
	SetPlayerModel(iClient, g_pPlayer[iClient].Model);
	
	if(g_itItems.EnableInvisibility && g_pPlayer[iClient].Invisible)
	SetEntityRenderFx(iClient, RENDERFX_DISTORT);
	
	CreateTimer(0.1, Timer_FOV, iClient);
	
	SetEntityHealth(iClient, g_sServer.DefaultHealth);
}

public Action Event_RoundEnd(Handle hEvent, char[] sName, bool bDontBroadcast)
{
	char sMap[128], sMessage[MAX_MESSAGE_LENGTH];
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "winner"));
	
	CPrintToChatAll("{red}[KINGS]{default} Congratulations to {%s}%N{default} for winning round with {green}%i{default} kills and {green}%i{default} deaths.", view_as<bool>(GetRandomInt(0, 1)) ? "blue" : "green", g_pPlayer[iClient].RoundKills, g_pPlayer[iClient].RoundDeaths);
	
	Format(sMessage, sizeof(sMessage), "King's Deathmatch | Map: %s\n", sMap);
	
	for (int i = 1; i < MaxClients; i++)
	{
		if(g_pPlayer[i].IsPlayer && !IsClientSourceTV(i))
		{
			Format(sMessage, sizeof(sMessage), "%s%N - Kills: %i | Deaths: %i\n", i == iClient ? "[WINNER] " : "", g_pPlayer[i].RoundKills, g_pPlayer[i].RoundDeaths);
		}
	}
	
	Discord_EscapeString(sMessage, sizeof(sMessage));
	
	Discord_SendMessage("test_discord", sMessage);
}

//Plugin Timers
public Action Timer_Advertisement(Handle hTimer)
{
	char sAdvertisement[256];
	
	switch (g_sServer.Advertisement)
	{
		case 1:
		{
			//Format(sAdvertisement, sizeof(sAdvertisement), "We have a {green}credits{default} system. Type {green}!credits{default} to use it.");
			LoadString(g_sServer.AdvertsKeyVaules, "Messages", "1", "", sAdvertisement, sizeof(sAdvertisement));
			
			g_sServer.Advertisement = 2;
		}
		
		case 2:
		{
			//Format(sAdvertisement, sizeof(sAdvertisement), "Latest Update [{green}10/23/18{default}]: We have added a buyable {green}health boost{default}. Type {green}!credits{default} for more information.");
			LoadString(g_sServer.AdvertsKeyVaules, "Messages", "2", "", sAdvertisement, sizeof(sAdvertisement));
			
			g_sServer.Advertisement = 3;
		}
		
		case 3:
		{
			//Format(sAdvertisement, sizeof(sAdvertisement), "Type {green}rtv{default} to vote to change the map.");
			LoadString(g_sServer.AdvertsKeyVaules, "Messages", "3", "", sAdvertisement, sizeof(sAdvertisement));
			
			g_sServer.Advertisement = 4;
		}
		
		case 4:
		{
			//Format(sAdvertisement, sizeof(sAdvertisement), "Type {green}rtv{default} to vote to change the map.");
			LoadString(g_sServer.AdvertsKeyVaules, "Messages", "4", "", sAdvertisement, sizeof(sAdvertisement));
			
			g_sServer.Advertisement = 5;
		}
		
		case 5:
		{
			//Format(sAdvertisement, sizeof(sAdvertisement), "Type {green}rtv{default} to vote to change the map.");
			LoadString(g_sServer.AdvertsKeyVaules, "Messages", "5", "", sAdvertisement, sizeof(sAdvertisement));
			
			g_sServer.Advertisement = 6;
		}
		
		case 6:
		{
			//Format(sAdvertisement, sizeof(sAdvertisement), "Type {green}rtv{default} to vote to change the map.");
			LoadString(g_sServer.AdvertsKeyVaules, "Messages", "6", "", sAdvertisement, sizeof(sAdvertisement));
			
			g_sServer.Advertisement = 1;
		}
	}
	
	if(!g_sServer.NoAdverts)
	CPrintToChatAll(sAdvertisement);
}

public Action Timer_Dissolve(Handle hTimer, any iClient)
{
	if(g_pPlayer[iClient].IsPlayer)
	{
		int iRagdoll = GetEntPropEnt(iClient, Prop_Send, "m_hRagdoll");
		
		int iDissolver = CreateEntityByName("env_entity_dissolver");
		
		DispatchKeyValue(iRagdoll, "targetname", "dissolved");
		
		DispatchKeyValue(iDissolver, "dissolvetype", "3");
		DispatchKeyValue(iDissolver, "target", "dissolved");
		
		AcceptEntityInput(iDissolver, "Dissolve");
		
		AcceptEntityInput(iDissolver, "Kill");
	}
}

public Action Timer_Fire(Handle hTimer, any iClient)
{
	if(g_pPlayer[iClient].IsPlayer)
	{
		int iRagdoll = GetEntPropEnt(iClient, Prop_Send, "m_hRagdoll");
		
		IgniteEntity(iRagdoll, 5.0);
	}
}

public Action Timer_FOV(Handle hTimer, any iClient)
{
	SetPlayerFOV(iClient, true);
}

public Action Timer_Guns(Handle hTimer, any iClient)
{
	if(g_pPlayer[iClient].IsPlayer)
	{
		GivePlayerItem(iClient, "weapon_crowbar");
		
		if(g_wWeapons.DisableRPG)
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
		
		Client_ChangeWeapon(iClient, g_pPlayer[iClient].DefaultWeapon);
		
		if(Client_GetActiveWeapon(iClient) != INVALID_ENT_REFERENCE)
		ReFillWeapon(iClient, Client_GetActiveWeapon(iClient));
	}
}

/*public Action Timer_JumpBoost(Handle hTimer, any iClient)
{
	if (g_pPlayer[iClient].IsPlayer)
	{
		g_pPlayer[iClient].JumpBoost = false;

		CPrintToChat(iClient, "[{red}KINGS{default}] Your {green}jump-boost{default} has worn off.");
	}
}*/

public Action Timer_ModelChanger(Handle hTimer, any iClient)
{
	if(g_itItems.EnableModelChange)
	SetPlayerModel(iClient, g_pPlayer[iClient].Model);
}

public Action Timer_Protection(Handle hTimer, any iClient)
{
	SetEntProp(iClient, Prop_Data, "m_takedamage", 0, 1);
	
	SetEntityRenderColor(iClient, 0, 255, 0, 128);
	SetEntityRenderFx(iClient, RENDERFX_FLICKER_FAST);
	
	g_pPlayer[iClient].SpawnProtect = true;
}

public Action Timer_StatHud(Handle hTimer, any iClient)
{
	char sStatsHud[2][128];
	
	float fAllKTD, fRoundKTD;
	
	int iTimeleft;
	
	GetMapTimeLeft(iTimeleft);
	
	if (IsClientInGame(iClient))
	{
		fAllKTD = ((g_pPlayer[iClient].AllDeaths <= 0.0) ? 0.0 : view_as<float>(g_pPlayer[iClient].AllKills) / view_as<float>(g_pPlayer[iClient].AllDeaths));//FloatDiv(float(g_pPlayer[iClient].RoundKills), float(g_pPlayer[iClient].RoundDeaths)));
		fRoundKTD = ((g_pPlayer[iClient].RoundDeaths <= 0.0) ? 0.0 : view_as<float>(g_pPlayer[iClient].RoundKills) / view_as<float>(g_pPlayer[iClient].RoundDeaths));//FloatDiv(float(g_pPlayer[iClient].RoundKills), float(g_pPlayer[iClient].RoundDeaths)));
		
		if(g_sServer.AllKills)
		{
			g_sServer.PrivateMatchRunning ? Format(sStatsHud[0], sizeof(sStatsHud[]), "Name: %N\nCredits: %i\n%.1f All-Time KTD\nServer Password: %s", iClient, g_pPlayer[iClient].Credits, fAllKTD, g_sServer.Password) : Format(sStatsHud[0], sizeof(sStatsHud[]), "Name: %N\nCredits: %i\n%.1f All-Time KTD", iClient, g_pPlayer[iClient].Credits, fAllKTD);
		}else{
			g_sServer.PrivateMatchRunning ? Format(sStatsHud[0], sizeof(sStatsHud[]), "Name: %N\nCredits: %i\nServer Password: %s", iClient, g_pPlayer[iClient].Credits, g_sServer.Password) : Format(sStatsHud[0], sizeof(sStatsHud[]), "Name: %N\nCredits: %i", iClient, g_pPlayer[iClient].Credits);
		}
		
		Format(sStatsHud[1], sizeof(sStatsHud[]), "Stats:\n%i Kills\n%i Deaths\n%.1f Round KTD\nTimeleft: %d:%02d", Client_GetScore(iClient), Client_GetDeaths(iClient), fRoundKTD, iTimeleft <= 0 ? 00 : (iTimeleft / 60), iTimeleft <= 0 ? 00 : (iTimeleft % 60));
		
		if(IsClientSourceTV(iClient))
		{
			for (int i = 1; i < MaxClients; i++)
			{
				if(g_pPlayer[i].IsPlayer && !IsClientSourceTV(i))
				{
					Format(sStatsHud[0], sizeof(sStatsHud[]), "");
					Format(sStatsHud[0], sizeof(sStatsHud[]), "%s%N | Kills: %i / Deaths: %i\n", sStatsHud[0], i, Client_GetScore(i), Client_GetDeaths(i));
				}
			}
			
			Format(sStatsHud[1], sizeof(sStatsHud[]), "Timeleft: %d:%02d", iTimeleft <= 0 ? 00 : (iTimeleft / 60), iTimeleft <= 0 ? 00 : (iTimeleft % 60));
		}
		
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
			
			if ((StrEqual(sClassname, "weapon_rpg") || StrEqual(sClassname, "item_rpg_round")) && !g_wWeapons.DisableRPG)
			{
				AcceptEntityInput(i, "kill");
			}
		}
	}
}

public Action Timer_Visible(Handle hTimer, any iClient)
{
	if (g_pPlayer[iClient].IsPlayer && g_pPlayer[iClient].Invisible)
	{
		SetEntityRenderColor(iClient, 255, 255, 255, 255);
		
		g_pPlayer[iClient].Invisible = false;
		
		CPrintToChat(iClient, "[{red}KINGS{default}] Your {green}invisibility{default} has worn off.");
	}
}
