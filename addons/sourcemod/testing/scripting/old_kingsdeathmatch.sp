//King's Deathmatch: Developed by King Nothing.
#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "RockZehh"
#define PLUGIN_VERSION "1.4.0"

#define MAX_BUTTONS 26

#include <discord>
#include <geoip>
//#include <kingsdeathmatch>
#include <morecolors>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <smlib/clients>
#undef REQUIRE_PLUGIN
#include <updater>

#pragma newdecls required

#define GRENADES 10

#define HITGROUP_GENERIC   0
#define HITGROUP_HEAD      1
#define HITGROUP_CHEST     2
#define HITGROUP_STOMACH   3
#define HITGROUP_LEFTARM   4
#define HITGROUP_RIGHTARM  5
#define HITGROUP_LEFTLEG   6
#define HITGROUP_RIGHTLEG  7

#define RPG_ROUNDS 8

#define SUIT_DEVICE_BREATHER	0x00000004
#define SUIT_DEVICE_FLASHLIGHT	0x00000002
#define SUIT_DEVICE_SPRINT		0x00000001

#define UPDATE_URL	"https://raw.githubusercontent.com/rockzehh/kingsdeathmatch/master/addons/sourcemod/updater.txt"

bool g_bAllKills;
bool g_bAltDamage;
bool g_bColoredNickname[MAXPLAYERS + 1];
bool g_bDev[MAXPLAYERS + 1];
bool g_bEnableColorNickname;
bool g_bEnableInvisibility;
bool g_bEnableJetpack;
bool g_bEnableJumpBoost;
bool g_bEnableLongJump;
bool g_bEnableModelChanger;
bool g_bEnableNickname;
bool g_bFOV;
bool g_bFallFix;
bool g_bGod[MAXPLAYERS + 1];
bool g_bInZoom[MAXPLAYERS + 1];
bool g_bInvisibility[MAXPLAYERS + 1];
bool g_bJetpack[MAXPLAYERS + 1][2];
bool g_bJumpBoost[MAXPLAYERS + 1][2];
bool g_bLongJumpPressed[MAXPLAYERS + 1];
bool g_bLongJumpSound;
bool g_bLongJump[MAXPLAYERS + 1][2];
bool g_bMenu;
bool g_bNoAdvertisements;
bool g_bNoFallDamage;
bool g_bPlayer[MAXPLAYERS + 1] = false;
bool g_bPreferPrivateMatches[MAXPLAYERS + 1];
bool g_bPrivateMatchRunning;
bool g_bPrivateMatches;
bool g_bProtection[MAXPLAYERS + 1];
bool g_bRPG;
bool g_bZoom[MAXPLAYERS + 1];

char g_sAdvertisementsDatabase[PLATFORM_MAX_PATH];
char g_sClientsDatabase[PLATFORM_MAX_PATH];
char g_sDefaultWeapon[MAXPLAYERS + 1][64];
char g_sMap[128];
char g_sModelsDatabase[PLATFORM_MAX_PATH];
char g_sModelName[MAXPLAYERS + 1][64];
char g_sNicknameColor[MAXPLAYERS + 1][MAX_NAME_LENGTH];
char g_sNicknameText[MAXPLAYERS + 1][MAX_NAME_LENGTH];
char g_sServerPassword[128];

ConVar g_cvAllowPrivateMatches;
ConVar g_cvCrowbarDamage;
ConVar g_cvDefaultJumpVelocity;
ConVar g_cvDisableAdvertisements;
ConVar g_cvEnableColorNickname;
ConVar g_cvEnableInvisibility;
ConVar g_cvEnableJetpack;
ConVar g_cvEnableJumpBoost;
ConVar g_cvEnableLongJump;
ConVar g_cvEnableModelChanger;
ConVar g_cvEnableNickname;
ConVar g_cvEnableSourceTVDemos;
ConVar g_cvFOV;
ConVar g_cvFallingFix;
ConVar g_cvHalfDamage;
ConVar g_cvHealthBoost;
ConVar g_cvHealthModifier;
ConVar g_cvJetpack;
ConVar g_cvJumpBoost;
ConVar g_cvLongJumpPush;
ConVar g_cvLongJumpSound;
ConVar g_cvNoFallDamage;
ConVar g_cvPassword;
ConVar g_cvShowAllKills;
ConVar g_cvSourceTV[3];
ConVar g_cvSpawnRPG;
ConVar g_cvStartFOV;
ConVar g_cvStartHealth;
ConVar g_cvUpgradePriceColorNickname;
ConVar g_cvUpgradePriceHealthBoost;
ConVar g_cvUpgradePriceInvisibility;
ConVar g_cvUpgradePriceJetpack;
ConVar g_cvUpgradePriceJumpBoost;
ConVar g_cvUpgradePriceLongJump;
ConVar g_cvUseFOV;
ConVar g_cvUseSourceMenus;

float g_fCommand_Duration[] =
{
	15.0, //Invisibility
	120.0, //Jump Boost
};
float g_fDamageModifier;
float g_fJetpack;
float g_fJumpBoost;
float g_fPushForce;
float g_fSpawnPoint[MAXPLAYERS + 1][3];
float g_fStandardJumpVel;

Handle g_hAdvertisements;
Handle g_hStatHud[MAXPLAYERS + 1];

int g_iAdvertisement = 1;
int g_iAllDeaths[MAXPLAYERS + 1];
int g_iAllHeadshots[MAXPLAYERS + 1];
int g_iAllKills[MAXPLAYERS + 1];
int g_iClip_Sizes[] =
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
int g_iCredits[MAXPLAYERS + 1];
int g_iCrowbarDamage;
int g_iDeaths[MAXPLAYERS + 1];
int g_iFOV;
int g_iHeadshots[MAXPLAYERS + 1];
int g_iHealthBoost;
int g_iHitgroup[MAXPLAYERS + 1];
int g_iKills[MAXPLAYERS + 1];
int g_iLastButton[MAXPLAYERS + 1];
int g_iStartFOV;
int g_iStartHealth;
int g_iUpgrade_Prices[] =
{
	350, //Health Boost
	500, //Invisibility
	1750, //Jump Boost
	2500, //Long Jump
	2000, //Jetpack
	25000, //Colored Nicknames
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
	
	g_cvAllowPrivateMatches = CreateConVar("kdm_server_allow_private_matches", "1", "If users can start a private match.", _, true, 0.1, true, 1.0);
	g_cvCrowbarDamage = CreateConVar("kdm_wep_crowbar_damage", "500", "The damage the crowbar will do.");
	g_cvDefaultJumpVelocity = CreateConVar("kdm_player_jump_velocity", "100.0", "The default jump velocity.");
	g_cvDisableAdvertisements = CreateConVar("kdm_chat_disable_advertisements", "0", "Decides if chat advertisements should be displayed.", _, true, 0.1, true, 1.0);
	g_cvEnableColorNickname = CreateConVar("kdm_colornickname_enable", "1", "Decides if colored nicknames are enabled.", _, true, 0.1, true, 1.0);
	g_cvEnableInvisibility = CreateConVar("kdm_invisible_enable", "1", "Decides if the invisiblity effect is enabled.", _, true, 0.1, true, 1.0);
	g_cvEnableJetpack = CreateConVar("kdm_jetpack_enable", "1", "Decides if the jetpack module is enabled.", _, true, 0.1, true, 1.0);
	g_cvEnableJumpBoost = CreateConVar("kdm_jumpboost_enable", "1", "Decides if the jump boost module is enabled.", _, true, 0.1, true, 1.0);
	g_cvEnableLongJump = CreateConVar("kdm_longjump_enable", "1", "Decides if the long jump module is enabled.", _, true, 0.1, true, 1.0);
	g_cvEnableModelChanger = CreateConVar("kdm_player_model_change", "1", "Decides if the player can change their model.", _, true, 0.1, true, 1.0);
	g_cvEnableSourceTVDemos = CreateConVar("kdm_demos_enable", "1", "Decides if the SourceTV demo recording is enabled.", _, true, 0.1, true, 1.0);
	g_cvFallingFix = CreateConVar("kdm_player_tposefix", "0", "Decides if to fix the T-Pose falling glitch.", _, true, 0.1, true, 1.0);
	g_cvFOV = CreateConVar("kdm_player_custom_fov", "115", "The custom FOV value.");
	g_cvHalfDamage = CreateConVar("kdm_player_alternatedamage", "0", "Decides if the players have alternate damage.", _, true, 0.1, true, 1.0);
	g_cvHealthBoost = CreateConVar("kdm_healthboost_amount", "75", "The amount of health the health boost will do.");
	g_cvHealthModifier = CreateConVar("kdm_player_damage_modifier", "0.5", "Damage modifier. A better description will be added.");
	g_cvJetpack = CreateConVar("kdm_jetpack_velocity", "60.0", "Jetpack velocity. A better description will be added.");
	g_cvJumpBoost = CreateConVar("kdm_jumpboost_amount", "500.0", "The added jump velocity.");
	g_cvLongJumpPush = CreateConVar("kdm_longjump_push_force", "650.0", "The amount of force that the long jump does.");
	g_cvLongJumpSound = CreateConVar("kdm_longjump_play_sound", "1", "Decides if to play the long jump sound.", _, true, 0.1, true, 1.0);
	g_cvEnableNickname = CreateConVar("kdm_nickname_enable", "1", "Decides if nicknames are enabled.", _, true, 0.1, true, 1.0);
	g_cvNoFallDamage = CreateConVar("kdm_player_nofalldamage", "1", "Decides if to disable fall damage.", _, true, 0.1, true, 1.0);
	g_cvPassword = FindConVar("sv_password");
	g_cvShowAllKills = CreateConVar("kdm_player_hud_showallkills", "1", "Shows the stats for the players overall kills.", _, true, 0.1, true, 1.0);
	g_cvSourceTV[0] = FindConVar("tv_enable");
	g_cvSourceTV[1] = FindConVar("tv_autorecord");
	g_cvSourceTV[2] = FindConVar("tv_maxclients");
	g_cvSpawnRPG = CreateConVar("kdm_wep_allow_rpg", "0", "Decides if the RPG is allowed to spawn.", _, true, 0.1, true, 1.0);
	g_cvStartFOV = CreateConVar("kdm_player_start_fov", "20", "The custom start animation FOV value.");
	g_cvStartHealth = CreateConVar("kdm_player_start_health", "175", "The start player health.");
	g_cvUpgradePriceHealthBoost = CreateConVar("kdm_healthboost_price", "350", "The amount of credits you need to pay to use the health boost.");
	g_cvUpgradePriceInvisibility = CreateConVar("kdm_invisible_price", "500", "The amount of credits you need to pay to use the invisible effect.");
	g_cvUpgradePriceJetpack = CreateConVar("kdm_jetpack_price", "2000", "The amount of credits you need to pay to use the jetpack module.");
	g_cvUpgradePriceJumpBoost = CreateConVar("kdm_jumpboost_price", "1750", "The amount of credits you need to pay to use the jump boost module.");
	g_cvUpgradePriceLongJump = CreateConVar("kdm_longjump_price", "2500", "The amount of credits you need to pay to use the long jump module.");
	g_cvUpgradePriceColorNickname = CreateConVar("kdm_colornickname_price", "25000", "The amount of credits you need to buy the colored nickname.");
	g_cvUseFOV = CreateConVar("kdm_player_custom_fov_enable", "1", "Decides to use the custom FOV on the players.", _, true, 0.1, true, 1.0);
	g_cvUseSourceMenus = CreateConVar("kdm_server_usesourcemenus", "0", "Decides to use the chat option or the menu system.", _, true, 0.1, true, 1.0);
	
	CreateConVar("kdm_plugin_version", PLUGIN_VERSION, "The version of the plugin the server is running.");
	
	g_bAllKills = g_cvShowAllKills.BoolValue;
	g_iCrowbarDamage = g_cvCrowbarDamage.IntValue;
	g_fDamageModifier = g_cvHealthModifier.FloatValue;
	g_bEnableColorNickname = g_cvEnableColorNickname.BoolValue;
	g_bEnableInvisibility = g_cvEnableInvisibility.BoolValue;
	g_bEnableJetpack = g_cvEnableJetpack.BoolValue;
	g_bEnableJumpBoost = g_cvEnableJumpBoost.BoolValue;
	g_bEnableLongJump = g_cvEnableLongJump.BoolValue;
	g_bEnableModelChanger = g_cvEnableModelChanger.BoolValue;
	g_bEnableNickname = g_cvEnableNickname.BoolValue;
	g_bFallFix = g_cvFallingFix.BoolValue;
	g_bFOV = g_cvUseFOV.BoolValue;
	g_iFOV = g_cvFOV.IntValue;
	g_bAltDamage = g_cvHalfDamage.BoolValue;
	g_iHealthBoost = g_cvHealthBoost.IntValue;
	g_fJetpack = g_cvJetpack.FloatValue;
	g_fJumpBoost = g_cvJumpBoost.FloatValue;
	g_bLongJumpSound = g_cvLongJumpSound.BoolValue;
	g_fPushForce = g_cvLongJumpPush.FloatValue;
	g_bMenu = g_cvUseSourceMenus.BoolValue;
	g_bNoAdvertisements = g_cvDisableAdvertisements.BoolValue;
	g_bNoFallDamage = g_cvNoFallDamage.BoolValue;
	g_cvPassword.GetString(g_sServerPassword, sizeof(g_sServerPassword));
	g_bPrivateMatchRunning = StrEqual(g_sServerPassword, "") ? false : true;
	g_bPrivateMatches = g_cvAllowPrivateMatches.BoolValue;
	g_bRPG = g_cvSpawnRPG.BoolValue;
	g_cvSourceTV[0].BoolValue = g_cvEnableSourceTVDemos.BoolValue;
	g_cvSourceTV[1].BoolValue = true;
	g_cvSourceTV[2].IntValue = 0;
	g_fStandardJumpVel = g_cvDefaultJumpVelocity.FloatValue;
	g_iStartFOV = g_cvStartFOV.IntValue;
	g_iStartHealth = g_cvStartHealth.IntValue;
	
	g_iUpgrade_Prices[0] = g_cvUpgradePriceHealthBoost.IntValue;
	g_iUpgrade_Prices[1] = g_cvUpgradePriceInvisibility.IntValue;
	g_iUpgrade_Prices[2] = g_cvUpgradePriceJumpBoost.IntValue;
	g_iUpgrade_Prices[3] = g_cvUpgradePriceLongJump.IntValue;
	g_iUpgrade_Prices[4] = g_cvUpgradePriceJetpack.IntValue;
	g_iUpgrade_Prices[5] = g_cvUpgradePriceColorNickname.IntValue;
	
	g_cvAllowPrivateMatches.AddChangeHook(OnConVarsChanged);
	g_cvCrowbarDamage.AddChangeHook(OnConVarsChanged);
	g_cvDefaultJumpVelocity.AddChangeHook(OnConVarsChanged);
	g_cvDisableAdvertisements.AddChangeHook(OnConVarsChanged);
	g_cvEnableColorNickname.AddChangeHook(OnConVarsChanged);
	g_cvEnableInvisibility.AddChangeHook(OnConVarsChanged);
	g_cvEnableJetpack.AddChangeHook(OnConVarsChanged);
	g_cvEnableJumpBoost.AddChangeHook(OnConVarsChanged);
	g_cvEnableLongJump.AddChangeHook(OnConVarsChanged);
	g_cvEnableModelChanger.AddChangeHook(OnConVarsChanged);
	g_cvEnableNickname.AddChangeHook(OnConVarsChanged);
	g_cvEnableSourceTVDemos.AddChangeHook(OnConVarsChanged);
	g_cvFallingFix.AddChangeHook(OnConVarsChanged);
	g_cvFOV.AddChangeHook(OnConVarsChanged);
	g_cvHealthBoost.AddChangeHook(OnConVarsChanged);
	g_cvHealthModifier.AddChangeHook(OnConVarsChanged);
	g_cvHalfDamage.AddChangeHook(OnConVarsChanged);
	g_cvJetpack.AddChangeHook(OnConVarsChanged);
	g_cvJumpBoost.AddChangeHook(OnConVarsChanged);
	g_cvLongJumpPush.AddChangeHook(OnConVarsChanged);
	g_cvLongJumpSound.AddChangeHook(OnConVarsChanged);
	g_cvNoFallDamage.AddChangeHook(OnConVarsChanged);
	g_cvShowAllKills.AddChangeHook(OnConVarsChanged);
	g_cvSpawnRPG.AddChangeHook(OnConVarsChanged);
	g_cvStartFOV.AddChangeHook(OnConVarsChanged);
	g_cvStartHealth.AddChangeHook(OnConVarsChanged);
	g_cvUpgradePriceInvisibility.AddChangeHook(OnConVarsChanged);
	g_cvUpgradePriceHealthBoost.AddChangeHook(OnConVarsChanged);
	g_cvUpgradePriceJetpack.AddChangeHook(OnConVarsChanged);
	g_cvUpgradePriceJumpBoost.AddChangeHook(OnConVarsChanged);
	g_cvUpgradePriceLongJump.AddChangeHook(OnConVarsChanged);
	g_cvUpgradePriceColorNickname.AddChangeHook(OnConVarsChanged);
	g_cvUseFOV.AddChangeHook(OnConVarsChanged);
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
	
	BuildPath(Path_SM, g_sModelsDatabase, PLATFORM_MAX_PATH, "data/kingsdeathmatch/models.txt");
	if(!FileExists(g_sModelsDatabase))
	{
		g_bEnableModelChanger = false;
	}
	
	//HookEvent("player_changename", Event_PlayerChangename);
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
	RegConsoleCmd("sm_invisible", Command_Invisibility, "Makes your player model invisible.");
	RegConsoleCmd("sm_invisibility", Command_Invisibility, "Makes your player model invisible.");
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
		
		if (IsClientConnected(i))
		{
			SDKUnhook(i, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
		}
	}
	
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
	
	GetCurrentMap(g_sMap, sizeof(g_sMap));
	
	g_hAdvertisements = CreateTimer(45.0, Timer_Advertisement, _, TIMER_REPEAT);
	
	CreateTimer(15.0, Timer_RPGRemove, _, TIMER_REPEAT);
	
	g_bPrivateMatchRunning = StrEqual(g_sServerPassword, "") ? false : true;
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
	
	g_bPrivateMatchRunning = StrEqual(g_sServerPassword, "") ? false : true;
}

public void OnClientPutInServer(int iClient)
{
	//Custom admin shit flag is Admin_Custom4.
	g_bColoredNickname[iClient] = false;
	g_bDev[iClient] = false;
	g_bInvisibility[iClient] = false;
	g_bInZoom[iClient] = false;
	g_bJumpBoost[iClient][0] = false;
	g_bJumpBoost[iClient][1] = false;
	g_bLongJumpPressed[iClient] = false;
	g_bLongJump[iClient][0] = false;
	g_bLongJump[iClient][1] = false;
	g_bPlayer[iClient] = true;
	g_bPreferPrivateMatches[iClient] = false;
	g_bProtection[iClient] = false;
	g_bZoom[iClient] = false;
	
	g_hStatHud[iClient] = CreateTimer(0.1, Timer_StatHud, iClient, TIMER_REPEAT);
	
	g_iAllDeaths[iClient] = 0;
	g_iAllHeadshots[iClient] = 0;
	g_iAllKills[iClient] = 0;
	g_iCredits[iClient] = 0;
	g_iDeaths[iClient] = 0;
	g_iKills[iClient] = 0;
	g_iHeadshots[iClient] = 0;
	g_iHitgroup[iClient] = HITGROUP_GENERIC;
	
	SDKHookEx(iClient, SDKHook_FireBulletsPost, Hook_FireBulletsPost);
	SDKHook(iClient, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	SDKHook(iClient, SDKHook_TraceAttackPost,  Hook_TraceAttackPost);
	SDKHook(iClient, SDKHook_WeaponCanSwitchTo, Hook_WeaponCanSwitchTo);
	SDKHookEx(iClient, SDKHook_WeaponSwitchPost, Hook_WeaponSwitchPost);
	
	LoadClient(iClient);
	
	SetClientNickname(iClient);
	
	SetPlayerFOV(iClient, true);
	
	CreateTimer(0.1, Timer_ModelChanger, iClient);
}

public void OnClientDisconnect(int iClient)
{
	if(g_bPlayer[iClient])
	{
		g_bDev[iClient] = false;
		g_bInvisibility[iClient] = false;
		g_bInZoom[iClient] = false;
		g_bLongJumpPressed[iClient] = false;
		g_bPlayer[iClient] = false;
		g_bPreferPrivateMatches[iClient] = false;
		g_bProtection[iClient] = false;
		g_bZoom[iClient] = false;
		
		SDKUnhook(iClient, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
		
		CloseHandle(g_hStatHud[iClient]);
		
		SaveClient(iClient);
	}
}

public void OnConVarsChanged(ConVar convar, char[] oldValue, char[] newValue)
{
	g_bAllKills = g_cvShowAllKills.BoolValue;
	g_iCrowbarDamage = g_cvCrowbarDamage.IntValue;
	g_fDamageModifier = g_cvHealthModifier.FloatValue;
	g_bEnableColorNickname = g_cvEnableColorNickname.BoolValue;
	g_bEnableInvisibility = g_cvEnableInvisibility.BoolValue;
	g_bEnableJetpack = g_cvEnableJetpack.BoolValue;
	g_bEnableJumpBoost = g_cvEnableJumpBoost.BoolValue;
	g_bEnableLongJump = g_cvEnableLongJump.BoolValue;
	g_bEnableModelChanger = g_cvEnableModelChanger.BoolValue;
	g_bEnableNickname = g_cvEnableNickname.BoolValue;
	g_bFallFix = g_cvFallingFix.BoolValue;
	g_bFOV = g_cvUseFOV.BoolValue;
	g_iFOV = g_cvFOV.IntValue;
	g_bAltDamage = g_cvHalfDamage.BoolValue;
	g_iHealthBoost = g_cvHealthBoost.IntValue;
	g_fJetpack = g_cvJetpack.FloatValue;
	g_fJumpBoost = g_cvJumpBoost.FloatValue;
	g_bLongJumpSound = g_cvLongJumpSound.BoolValue;
	g_fPushForce = g_cvLongJumpPush.FloatValue;
	g_bMenu = g_cvUseSourceMenus.BoolValue;
	g_bNoAdvertisements = g_cvDisableAdvertisements.BoolValue;
	g_bNoFallDamage = g_cvNoFallDamage.BoolValue;
	g_cvPassword.GetString(g_sServerPassword, sizeof(g_sServerPassword));
	g_bPrivateMatchRunning = StrEqual(g_sServerPassword, "") ? false : true;
	g_bPrivateMatches = g_cvAllowPrivateMatches.BoolValue;
	g_bRPG = g_cvSpawnRPG.BoolValue;
	g_cvSourceTV[0].BoolValue = g_cvEnableSourceTVDemos.BoolValue;
	g_cvSourceTV[1].BoolValue = true;
	g_cvSourceTV[2].IntValue = 0;
	g_fStandardJumpVel = g_cvDefaultJumpVelocity.FloatValue;
	g_iStartFOV = g_cvStartFOV.IntValue;
	g_iStartHealth = g_cvStartHealth.IntValue;
	
	g_iUpgrade_Prices[0] = g_cvUpgradePriceHealthBoost.IntValue;
	g_iUpgrade_Prices[1] = g_cvUpgradePriceInvisibility.IntValue;
	g_iUpgrade_Prices[2] = g_cvUpgradePriceJumpBoost.IntValue;
	g_iUpgrade_Prices[3] = g_cvUpgradePriceLongJump.IntValue;
	g_iUpgrade_Prices[4] = g_cvUpgradePriceJetpack.IntValue;
	g_iUpgrade_Prices[5] = g_cvUpgradePriceColorNickname.IntValue;
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVel[3], float fAngles[3], int &iWeapon, int &iSubtype, int &iCmdnum, int &iTickcount, int &iSeed, int iMouse[2])
{
	char sWeapon[128];
	int iFlags = GetEntityFlags(iClient);
	float fSpawnPoint[3], fVelocity[3];
	
	GetClientAbsOrigin(iClient, fSpawnPoint);
	
	Client_GetWeapon(iClient, sWeapon);
	
	if(g_bDev[iClient])
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
	
	if(StrEqual(sWeapon, "weapon_smg1"))
	{
		if (iButtons & IN_ATTACK2)
		{
			iButtons &= ~IN_ATTACK2;
		}
		
		return Plugin_Continue;
	}
	
	if(g_bProtection[iClient])
	{
		if(iButtons & IN_RUN || iButtons & IN_JUMP || iButtons & IN_DUCK || iButtons & IN_BACK || iButtons & IN_LEFT || iButtons & IN_WALK || iButtons & IN_RIGHT || iButtons & IN_SPEED || iButtons & IN_ATTACK || iButtons & IN_FORWARD || iButtons & IN_ATTACK2 || iButtons & IN_ATTACK3 || iButtons & IN_MOVELEFT || iButtons & IN_MOVERIGHT)
		{
			SetEntProp(iClient, Prop_Data, "m_takedamage", 2, 1);
			
			SetEntityRenderColor(iClient, 255, 255, 255, 255);
			SetEntityRenderFx(iClient, g_bInvisibility[iClient] ? RENDERFX_DISTORT : RENDERFX_NONE);
			
			g_bProtection[iClient] = false;
		}
	}
	
	for (int i = 0; i < MAX_BUTTONS; i++)
	{
		int iButton = (1 << i);
		
		if ((iButtons & iButton) && !(g_iLastButton[iClient] & iButton))
		{
			if((iButtons & IN_DUCK) && (iButton & IN_JUMP) && (iFlags & FL_ONGROUND) && !g_bLongJumpPressed[iClient] && g_bLongJump[iClient][1] && g_bEnableLongJump)
			{
				LongJumpFunction(iClient);
				
				g_bLongJumpPressed[iClient] = true;
			}else if ((iButtons & IN_JUMP) && (iFlags & FL_ONGROUND) && !g_bLongJumpPressed[iClient])
			{
				GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", fVelocity);
				
				fVelocity[2] += g_bJumpBoost[iClient][1] ? g_fJumpBoost : g_fStandardJumpVel;
				TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, fVelocity);
				
				g_bLongJumpPressed[iClient] = true;
			}
			
			if((iButtons & IN_ZOOM))
			{
				g_bZoom[iClient] = true;
			}
		}
		
		if ((g_iLastButton[iClient] & iButton) && !(iButtons & iButton))
		{
			if((iButton & IN_ZOOM))
			{
				Client_SetFOV(iClient, g_iFOV);
				g_bZoom[iClient] = false;
			}
			
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
	
	return Plugin_Continue;
}

//Development Commands:
public Action Dev_GodMode(int iClient, int iArgs)
{
	g_bGod[iClient] = !g_bGod[iClient];
	g_bGod[iClient] ? SetEntProp(iClient, Prop_Data, "m_takedamage", 0, 1) : SetEntProp(iClient, Prop_Data, "m_takedamage", 2, 1);
	
	g_bDev[iClient] = g_bGod[iClient];
	
	CPrintToChat(iClient, "[{blue}KINGS-DEV{default}] God Mode has been %s.", g_bGod[iClient] ? "Enabled" : "Disabled");
	
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
	
	g_iCredits[iPlayer] = StringToInt(sCredits);
	
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
	
	if(g_bEnableNickname)
	{
		if(CColorExists(sColor) || g_bEnableColorNickname || g_bColoredNickname[iClient])
		{
			Format(g_sNicknameColor[iClient], sizeof(g_sNicknameColor[]), sColor);
			Format(g_sNicknameText[iClient], sizeof(g_sNicknameText[]), sNickname);
			
			SetClientNickname(iClient);
			
			SaveClient(iClient);
			
			CReplyToCommand(iClient, "[{red}KINGS{default}] Set {green}%N{default}'s nickname to {%s}%s{default}.", iClient, sColor, sNickname);
			
			return Plugin_Handled;
		}else{
			
			if(!g_bColoredNickname[iClient])
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
	
	if(g_bMenu)
	{
		Menu hMenu = new Menu(Menu_Credits, MENU_ACTIONS_ALL);
		
		hMenu.SetTitle("Credit Menu (%i credits)", g_iCredits[iClient]);
		
		Format(sDescription, sizeof(sDescription), "Health Boost +%ihp | %i Credits", g_iHealthBoost, g_iUpgrade_Prices[0]);
		hMenu.AddItem("opt_healthboost", sDescription);
		
		Format(sDescription, sizeof(sDescription), "Invisibility | %i Credits", g_iUpgrade_Prices[1]);
		hMenu.AddItem("opt_distort", sDescription);
		
		Format(sDescription, sizeof(sDescription), "Jump Boost | %i Credits | %s", g_iUpgrade_Prices[2], g_bJumpBoost[iClient][0] ? (g_bJumpBoost[iClient][1] ? "Enabled" : "Disabled") : "Lifetime Purchase");
		hMenu.AddItem("opt_jumpboost", sDescription);
		
		Format(sDescription, sizeof(sDescription), "Long Jump | %i Credits | %s", g_iUpgrade_Prices[3], g_bLongJump[iClient][0] ? (g_bLongJump[iClient][1] ? "Enabled" : "Disabled") : "Lifetime Purchase");
		hMenu.AddItem("opt_longjump", sDescription);
		
		hMenu.ExitButton = true;
		
		hMenu.Display(iClient, MENU_TIME_FOREVER);
	}else{
		CPrintToChat(iClient, "[{red}KINGS{default}] Credit Menu (%i credits)", g_iCredits[iClient]);
		
		Format(sDescription, sizeof(sDescription), "Health Boost +%ihp | %i Credits", g_iHealthBoost, g_iUpgrade_Prices[0]);
		CPrintToChat(iClient, " - %s - Command: !%s", sDescription, "boost");
		
		Format(sDescription, sizeof(sDescription), "Invisibility | %i Credits", g_iUpgrade_Prices[1]);
		CPrintToChat(iClient, " - %s - Command: !%s", sDescription, "invisible");
		
		Format(sDescription, sizeof(sDescription), "Jump Boost | %i Credits | %s", g_iUpgrade_Prices[2], g_bJumpBoost[iClient][0] ? (g_bJumpBoost[iClient][1] ? "Enabled" : "Disabled") : "Lifetime Purchase");
		CPrintToChat(iClient, " - %s - Command: !%s", sDescription, "jumpboost");
		
		Format(sDescription, sizeof(sDescription), "Long Jump | %i Credits | %s", g_iUpgrade_Prices[3], g_bLongJump[iClient][0] ? (g_bLongJump[iClient][1] ? "Enabled" : "Disabled") : "Lifetime Purchase");
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
	}else if(StrContains(sWeapon, "10", false) != -1 || StrContains(sWeapon, "grenades", false) != -1 || StrContains(sWeapon, "frag", false) != -1)
	{
		Format(g_sDefaultWeapon[iClient], sizeof(g_sDefaultWeapon[]), "weapon_frag");
		
		CPrintToChat(iClient, "[{red}KINGS{default}] Changed default weapon to '{green}Frag grenades{default}'.");
	}else if(StrEqual(sWeapon, "", false))
	{
		Client_GetActiveWeaponName(iClient, g_sDefaultWeapon[iClient], sizeof(g_sDefaultWeapon[]));
		
		CPrintToChat(iClient, "[{red}KINGS{default}] Default weapon changed to your current weapon.");
	}else{
		Client_GetActiveWeaponName(iClient, g_sDefaultWeapon[iClient], sizeof(g_sDefaultWeapon[]));
		
		CPrintToChat(iClient, "[{red}KINGS{default}] Invalid weapon selection. Default weapon changed to your current weapon.");
	}
	
	SaveClient(iClient);
	
	return Plugin_Handled;
}

public Action Command_HealthBoost(int iClient, int iArgs)
{
	if (g_iCredits[iClient] <= g_iUpgrade_Prices[0])
	{
		CPrintToChat(iClient, "[{red}KINGS{default}] You do not have enough credits.");
	} else {
		g_iCredits[iClient] -= g_iUpgrade_Prices[0];
		
		CPrintToChat(iClient, "[{red}KINGS{default}] You have bought the {green}Health Boost{default} for {green}%i{default} credits. {green}%ihp{default} has been added to your health.", g_iUpgrade_Prices[1], g_iHealthBoost);
		
		int iNewHealth = (GetClientHealth(iClient) + g_iHealthBoost);
		
		SetEntityHealth(iClient, iNewHealth);
		
		SaveClient(iClient);
	}
	
	return Plugin_Handled;
}

public Action Command_Invisibility(int iClient, int iArgs)
{
	if(!g_bEnableInvisibility)
	{
		return Plugin_Handled;
	}
	
	if (g_iCredits[iClient] <= g_iUpgrade_Prices[1])
	{
		CPrintToChat(iClient, "[{red}KINGS{default}] You do not have enough credits.");
	} else {
		g_iCredits[iClient] -= g_iUpgrade_Prices[1];
		
		CPrintToChat(iClient, "[{red}KINGS{default}] You have bought the {green}Invisibility Effect{default} for {green}%i{default} credits for {green}%f.f{default} seconds.", g_iUpgrade_Prices[0], g_fCommand_Duration[0]);
		
		SetEntityRenderColor(iClient, 255, 255, 255, 0);
		
		g_bInvisibility[iClient] = true;
		
		CreateTimer(g_fCommand_Duration[0], Timer_Visible, iClient);
		
		SaveClient(iClient);
	}
	
	return Plugin_Handled;
}

public Action Command_Jetpack(int iClient, int iArgs)
{
	if(!g_bEnableJumpBoost)
	{
		return Plugin_Handled;
	}
	
	if(g_bJetpack[iClient][0])
	{
		g_bJetpack[iClient][1] = !g_bJetpack[iClient][1];
		
		CPrintToChat(iClient, "[{red}KINGS{default}] Jetpack has been %s.", g_bJetpack[iClient][1] ? "Enabled" : "Disabled");
		
		SaveClient(iClient);
		
		return Plugin_Handled;
	}
	
	if (g_iCredits[iClient] <= g_iUpgrade_Prices[4])
	{
		CPrintToChat(iClient, "[{red}KINGS{default}] You do not have enough credits.");
	} else {
		g_iCredits[iClient] -= g_iUpgrade_Prices[4];
		
		CPrintToChat(iClient, "[{red}KINGS{default}] You have bought the {green}Jetpack Module{default} for {green}%i{default} credits.", g_iUpgrade_Prices[4]);
		
		g_bJetpack[iClient][0] = true;
		g_bJetpack[iClient][1] = true;
		
		SaveClient(iClient);
	}
	
	return Plugin_Handled;
}

public Action Command_JumpBoost(int iClient, int iArgs)
{
	if(!g_bEnableJumpBoost)
	{
		return Plugin_Handled;
	}
	
	if(g_bJumpBoost[iClient][0])
	{
		g_bJumpBoost[iClient][1] = !g_bJumpBoost[iClient][1];
		
		CPrintToChat(iClient, "[{red}KINGS{default}] Jump Boost has been %s.", g_bJumpBoost[iClient][1] ? "Enabled" : "Disabled");
		
		SaveClient(iClient);
		
		return Plugin_Handled;
	}
	
	if (g_iCredits[iClient] <= g_iUpgrade_Prices[2])
	{
		CPrintToChat(iClient, "[{red}KINGS{default}] You do not have enough credits.");
	} else {
		g_iCredits[iClient] -= g_iUpgrade_Prices[2];
		
		CPrintToChat(iClient, "[{red}KINGS{default}] You have bought the {green}Jump Boost Module{default} for {green}%i{default} credits.", g_iUpgrade_Prices[2]);
		
		g_bJumpBoost[iClient][0] = true;
		g_bJumpBoost[iClient][1] = true;
		
		//CreateTimer(g_fCommand_Duration[1], Timer_JumpBoost, iClient);
		
		SaveClient(iClient);
	}
	
	return Plugin_Handled;
}

public Action Command_LongJump(int iClient, int iArgs)
{
	if(g_bLongJump[iClient][0])
	{
		g_bLongJump[iClient][1] = !g_bLongJump[iClient][1];
		
		CPrintToChat(iClient, "[{red}KINGS{default}] Long Jump has been %s.", g_bLongJump[iClient][1] ? "Enabled" : "Disabled");
		
		SaveClient(iClient);
		
		return Plugin_Handled;
	}
	
	if (g_iCredits[iClient] <= g_iUpgrade_Prices[3])
	{
		CPrintToChat(iClient, "[{red}KINGS{default}] You do not have enough credits.");
	} else {
		g_iCredits[iClient] -= g_iUpgrade_Prices[3];
		
		CPrintToChat(iClient, "[{red}KINGS{default}] You have bought the {green}Long Jump Module{default} for {green}%i{default} credits.", g_iUpgrade_Prices[3]);
		
		g_bLongJump[iClient][0] = true;
		g_bLongJump[iClient][1] = true;
		
		SaveClient(iClient);
	}
	
	return Plugin_Handled;
}

public Action Command_PlayerModel(int iClient, int iArgs)
{
	if(!g_bEnableModelChanger)
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
		
		kvModels.ImportFromFile(g_sModelsDatabase);
		
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
		
		kvModels.ImportFromFile(g_sModelsDatabase);
		
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
		g_bPrivateMatchRunning = !g_bPrivateMatchRunning;
		
		g_bPrivateMatchRunning ? Format(g_sServerPassword, sizeof(g_sServerPassword), "kings-%i%i%i", GetRandomInt(0, 24), GetRandomInt(24, 64), GetRandomInt(64, 99)) : Format(g_sServerPassword, sizeof(g_sServerPassword), "");
		
		g_cvPassword.SetString(g_sServerPassword);
		
		CPrintToChat(iClient, "[{red}KINGS{default}] Private matches are %s.", g_bPrivateMatchRunning ? "Enabled" : "Disabled");
		
		return Plugin_Handled;
	}else{
		if(g_bPrivateMatchRunning)
		{
			CPrintToChat(iClient, "[{red}KINGS{default}] Only Admins can disable the private match.");
			return Plugin_Handled;
		}
		
		if(!g_bPrivateMatches)
		{
			CPrintToChat(iClient, "[{red}KINGS{default}] Private matches are Disabled.");
			return Plugin_Handled;
		}
		
		Format(g_sServerPassword, sizeof(g_sServerPassword), "kings-%i%i%i", GetRandomInt(0, 24), GetRandomInt(24, 64), GetRandomInt(64, 99));
		
		g_cvPassword.SetString(g_sServerPassword);
		
		g_bPrivateMatchRunning = true;
		
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
	
	if(g_bEnableNickname)
	{
		if(CColorExists(sColor) || g_bEnableColorNickname)
		{
			Format(g_sNicknameColor[iPlayer], sizeof(g_sNicknameColor[]), sColor);
			Format(g_sNicknameText[iPlayer], sizeof(g_sNicknameText[]), sNickname);
			
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
		
		Format(sColor, sizeof(sColor), "%s", StrEqual(g_sNicknameColor[iClient], "") ? "default" : g_sNicknameColor[iClient]);
		Format(sFullMessage, sizeof(sFullMessage), "{%s}%N{default} : %s", sColor, iClient, sMessage);
		
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
	
	if(g_bProtection[iClient])
	{
		SetEntProp(iClient, Prop_Data, "m_takedamage", 2, 1);
		
		SetEntityRenderColor(iClient, 255, 255, 255, 255);
		SetEntityRenderFx(iClient, (g_bEnableInvisibility && g_bInvisibility[iClient]) ? RENDERFX_DISTORT : RENDERFX_NONE);
		
		g_bProtection[iClient] = false;
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
	
	LoadString(kvVault, sAuthID, "default_weapon", "weapon_357", g_sDefaultWeapon[iClient], sizeof(g_sDefaultWeapon));
	
	g_bJetpack[iClient][0] = view_as<bool>(LoadInteger(kvVault, sAuthID, "jetpack", 0));
	g_bJetpack[iClient][1] = view_as<bool>(LoadInteger(kvVault, sAuthID, "previous_jet_setting", 0));
	
	g_bJumpBoost[iClient][0] = view_as<bool>(LoadInteger(kvVault, sAuthID, "jump_boost", 0));
	g_bJumpBoost[iClient][1] = view_as<bool>(LoadInteger(kvVault, sAuthID, "previous_jb_setting", 0));
	
	g_bLongJump[iClient][0] = view_as<bool>(LoadInteger(kvVault, sAuthID, "long_jump", 0));
	g_bLongJump[iClient][1] = view_as<bool>(LoadInteger(kvVault, sAuthID, "previous_lj_setting", 0));
	
	LoadString(kvVault, sAuthID, "nickname_color", "", g_sNicknameColor[iClient], sizeof(g_sNicknameColor));
	LoadString(kvVault, sAuthID, "nickname_text", "", g_sNicknameText[iClient], sizeof(g_sNicknameText));
	
	LoadString(kvVault, sAuthID, "player_model", "", g_sModelName[iClient], sizeof(g_sModelName));
	
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

public void ReFillWeapon(int iClient, int iWeapon)
{
	int iPrimaryAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
	
	if (iPrimaryAmmoType != -1)
	{
		if (iPrimaryAmmoType != RPG_ROUNDS && iPrimaryAmmoType != GRENADES)
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
	
	SaveInteger(kvVault, sAuthID, "jetpack", view_as<int>(g_bJetpack[iClient][0]));
	SaveInteger(kvVault, sAuthID, "previous_jet_setting", view_as<int>(g_bJetpack[iClient][1]));
	
	SaveInteger(kvVault, sAuthID, "jump_boost", view_as<int>(g_bJumpBoost[iClient][0]));
	SaveInteger(kvVault, sAuthID, "previous_jb_setting", view_as<int>(g_bJumpBoost[iClient][1]));
	
	SaveInteger(kvVault, sAuthID, "long_jump", view_as<int>(g_bLongJump[iClient][0]));
	SaveInteger(kvVault, sAuthID, "previous_lj_setting", view_as<int>(g_bLongJump[iClient][1]));
	
	SaveString(kvVault, sAuthID, "nickname_color", g_sNicknameColor[iClient]);
	SaveString(kvVault, sAuthID, "nickname_text", g_sNicknameText[iClient]);
	
	SaveString(kvVault, sAuthID, "player_model", g_sModelName[iClient]);
	
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

public void SetClientNickname(int iClient)
{
	char sCountry[3], sIP[64], sName[MAX_NAME_LENGTH];
	
	GetClientIP(iClient, sIP, sizeof(sIP));
	
	GeoipCode3(sIP, sCountry);
	if(IsClientSourceTV(iClient))
	{
		Format(sName, sizeof(sName), "WonderBread's Security Monitor");
	}else{
		if(StrEqual(g_sNicknameText[iClient], ""))
		{
			Format(sName, sizeof(sName), "[%s] %N", (StrEqual(sCountry, "")) ? "USA" : sCountry, iClient);
		}else{
			Format(sName, sizeof(sName), "[%s] %s", (StrEqual(sCountry, "")) ? "USA" : sCountry, g_sNicknameText[iClient]);
		}	
	}
	
	SetClientName(iClient, sName);
}

public void SetPlayerFOV(int iClient, bool bFirstJoin)
{
	if(g_bFOV)
	{
		Client_SetFOV(iClient, bFirstJoin ? g_iStartFOV : 80);
		
		for (int i = Client_GetFOV(iClient); i <= g_iFOV; i++)
		{
			Client_SetFOV(iClient, i);
		}
	}
}

public bool SetPlayerModel(int iClient, char[] sModelName)
{
	char sModel[256];
	
	KeyValues kvModels = new KeyValues("PlayerModels");
	
	if(!kvModels.ImportFromFile(g_sModelsDatabase))
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
	
	Format(g_sModelName[iClient], sizeof(g_sModelName[]), sModelName);
	
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
	
	if(g_bDev[iAttacker])
	{
		return Plugin_Handled;
	}
	
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
	
	int iNewHealth = (GetClientHealth(iClient) - RoundFloat((fDamage * g_fDamageModifier)));
	
	if (StrEqual(sWeapon, "weapon_crowbar") || StrEqual(sWeapon, "weapon_stunstick"))
	{
		iNewHealth -= g_iCrowbarDamage;
	}
	
	if(g_bAltDamage)
	{
		int iHealthMathShit = iNewHealth / 2;
		
		iNewHealth = iHealthMathShit;
	}
	
	SetEntityHealth(iClient, iNewHealth);
	
	return Plugin_Continue;
}

public void Hook_TraceAttackPost(int iVictim, int iAttacker, int iInflictor, float fDamage, int iDamageType, int iAmmoType, int iHitbox, int iHitgroup)
{
	g_iHitgroup[iVictim] = iHitgroup;
	
	//PrintToChatAll("%N's Hitgroup: %i", iVictim, iHitgroup);
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
	if(g_bFallFix)
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

public Action Event_PlayerDeath(Event eEvent, char[] sName, bool bDontBroadcast)
{
	char sAttackerColor[MAX_NAME_LENGTH], sClientColor[MAX_NAME_LENGTH], sWeapon[128];
	
	int iAttacker = GetClientOfUserId(eEvent.GetInt("attacker"));
	int iClient = GetClientOfUserId(eEvent.GetInt("userid"));
	
	eEvent.GetString("weapon", sWeapon, sizeof(sWeapon), "");
	
	Format(sAttackerColor, sizeof(sAttackerColor), "%s", StrEqual(g_sNicknameColor[iAttacker], "") ? "default" : g_sNicknameColor[iAttacker]);
	Format(sClientColor, sizeof(sClientColor), "%s", StrEqual(g_sNicknameColor[iClient], "") ? "default" : g_sNicknameColor[iClient]);
	
	Client_SetFOV(iClient, 90);
	
	if (iAttacker != iClient)
	{
		if (iAttacker == -1 || iAttacker == 1)
		{
			g_iAllDeaths[iClient]++;
			g_iDeaths[iClient]++;
		} else if(g_iHitgroup[iClient] > 0)
			switch(g_iHitgroup[iClient])
			{
				case HITGROUP_HEAD:
				{
					int iRandom = GetRandomInt(23, 32);
					
					g_iCredits[iAttacker] += iRandom;
					
					g_iAllHeadshots[iAttacker]++;
					g_iHeadshots[iAttacker]++;
					
					switch(GetRandomInt(0, 1))
					{
						case 0:
						{
							CPrintToChatAll("{%s}%N{default} ({green}%i{default}HP, {green}%i{default} Suit) got {green}%i{default} credits for getting a headshot kill on {%s}%N{default}!", sAttackerColor, iAttacker, GetClientHealth(iAttacker), Client_GetArmor(iAttacker), iRandom, sClientColor, iClient);
						}
						
						case 1:
						{
							CPrintToChatAll("{%s}%N{default} ({green}%i{default}HP, {green}%i{default} Suit) got {green}%i{default} credits for blowing {%s}%N{default}'s brains out.", sAttackerColor, iAttacker, GetClientHealth(iAttacker), Client_GetArmor(iAttacker), iRandom, sClientColor, iClient);
						}
					}
				}
				
				case HITGROUP_CHEST:
				{
					int iRandom = GetRandomInt(10, 13);
					
					g_iCredits[iAttacker] += iRandom;
					
					g_iHeadshots[iAttacker] = 0;
					
					CPrintToChatAll("{%s}%N{default} ({green}%i{default}HP, {green}%i{default} Suit) stole {%s}%N{default}'s torso. (+{green}%i{default} credits)", sAttackerColor, iAttacker, GetClientHealth(iAttacker), Client_GetArmor(iAttacker), sClientColor, iClient, iRandom);
				}
				
				case HITGROUP_GENERIC:
				{
					int iRandom = GetRandomInt(7, 18);
					
					g_iCredits[iAttacker] += iRandom;
					
					g_iHeadshots[iAttacker] = 0;
					
					CPrintToChatAll("{%s}%N{default} ({green}%i{default}HP, {green}%i{default} Suit) got {green}%i{default} credits for killing {%s}%N{default}!", sAttackerColor, iAttacker, GetClientHealth(iAttacker), Client_GetArmor(iAttacker), iRandom, sClientColor, iClient);
				}
				
				case HITGROUP_STOMACH:
				{
					int iRandom = GetRandomInt(10, 13);
					
					g_iCredits[iAttacker] += iRandom;
					
					g_iHeadshots[iAttacker] = 0;
					
					CPrintToChatAll("{%s}%N{default} ({green}%i{default}HP, {green}%i{default} Suit) fucking gutted {%s}%N{default}. (+{green}%i{default} credits)", sAttackerColor, iAttacker, GetClientHealth(iAttacker), Client_GetArmor(iAttacker), sClientColor, iClient, iRandom);
				}
				
				case HITGROUP_LEFTARM:
				{
					int iRandom = GetRandomInt(4, 11);
					
					g_iCredits[iAttacker] += iRandom;
					
					g_iHeadshots[iAttacker] = 0;
					
					CPrintToChatAll("Eh, {%s}%N{default} didn't use that arm anyways. {%s}%N{default} ({green}%i{default}HP, {green}%i{default} Suit) (+{green}%i{default} credits)", sClientColor, iClient, sAttackerColor, iAttacker, GetClientHealth(iAttacker), Client_GetArmor(iAttacker), iRandom);
				}
				
				case HITGROUP_RIGHTARM:
				{
					int iRandom = GetRandomInt(6, 13);
					
					g_iCredits[iAttacker] += iRandom;
					
					g_iHeadshots[iAttacker] = 0;
					
					CPrintToChatAll("Oh no! {%s}%N{default}'s super hand! {%s}%N{default} ({green}%i{default}HP, {green}%i{default} Suit) (+{green}%i{default} credits)", sClientColor, iClient, sAttackerColor, iAttacker, GetClientHealth(iAttacker), Client_GetArmor(iAttacker), iRandom);
				}
				
				case HITGROUP_LEFTLEG:
				{
					int iRandom = GetRandomInt(3, 7);
					
					g_iCredits[iAttacker] += iRandom;
					
					g_iHeadshots[iAttacker] = 0;
					
					CPrintToChatAll("{%s}%N{default} ({green}%i{default}HP, {green}%i{default} Suit) got {green}%i{default} credits for killing {%s}%N{default}!", sAttackerColor, iAttacker, GetClientHealth(iAttacker), Client_GetArmor(iAttacker), iRandom, sClientColor, iClient);
				}
				
				case HITGROUP_RIGHTLEG:
				{
					int iRandom = GetRandomInt(3, 8);
					
					g_iCredits[iAttacker] += iRandom;
					
					g_iHeadshots[iAttacker] = 0;
					
					CPrintToChatAll("{%s}%N{default} ({green}%i{default}HP, {green}%i{default} Suit) got {green}%i{default} credits for killing {%s}%N{default}!", sAttackerColor, iAttacker, GetClientHealth(iAttacker), Client_GetArmor(iAttacker), iRandom, sClientColor, iClient);
				}
			}
		}
		
		SaveClient(iClient);
	} else {
		g_iAllKills[iClient]--;
		g_iKills[iClient]--;
		g_iAllDeaths[iClient]++;
		g_iDeaths[iClient]++;
		
		int iRandom = GetRandomInt(7, 15);
		
		g_iCredits[iClient] -= iRandom;
		
		g_iHeadshots[iAttacker] = 0;
		
		CPrintToChatAll("{%s}%N{default} has lost {green}%i{default} credits for killing themselves.", sClientColor, iClient, iRandom);
	}
	
	SaveClient(iClient);
	
	CreateTimer(0.1, Timer_Fire, iClient);
	
	CreateTimer(1.5, Timer_Dissolve, iClient);
}

public Action Event_PlayerSpawn(Event eEvent, char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(eEvent.GetInt("userid"));
	
	CreateTimer(0.1, Timer_Guns, iClient);
	
	CreateTimer(0.1, Timer_Protection, iClient);
	
	if(g_bEnableModelChanger)
	SetPlayerModel(iClient, g_sModelName[iClient]);
	
	if(g_bEnableInvisibility && g_bInvisibility[iClient])
	SetEntityRenderFx(iClient, RENDERFX_DISTORT);
	
	CreateTimer(0.1, Timer_FOV, iClient);
	
	SetEntityHealth(iClient, g_iStartHealth);
}

public Action Event_RoundEnd(Event eEvent, char[] sName, bool bDontBroadcast)
{
	char sMap[128], sMessage[MAX_MESSAGE_LENGTH];
	int iClient = GetClientOfUserId(eEvent.GetInt("winner"));
	
	CPrintToChatAll("{red}[KINGS]{default} Congratulations to {%s}%N{default} for winning round with {green}%i{default} kills and {green}%i{default} deaths.", view_as<bool>(GetRandomInt(0, 1)) ? "blue" : "green", g_iKills[iClient], g_iDeaths[iClient]);
	
	Format(sMessage, sizeof(sMessage), "King's Deathmatch | Map: %s\n", sMap);
	
	for (int i = 1; i < MaxClients; i++)
	{
		if(g_bPlayer[i] && !IsClientSourceTV(i))
		{
			Format(sMessage, sizeof(sMessage), "%s%N - Kills: %i | Deaths: %i\n", i == iClient ? "[WINNER] " : "", g_iKills[i], g_iDeaths[i]);
		}
	}
	
	Discord_EscapeString(sMessage, sizeof(sMessage));
	
	Discord_SendMessage("test_discord", sMessage);
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
	if(g_bPlayer[iClient])
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
	if(g_bPlayer[iClient])
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
	if(g_bPlayer[iClient])
	{
		GivePlayerItem(iClient, "weapon_crowbar");
		
		if(g_bRPG)
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
		
		if(Client_GetActiveWeapon(iClient) != INVALID_ENT_REFERENCE)
		ReFillWeapon(iClient, Client_GetActiveWeapon(iClient));
	}
}

/*public Action Timer_JumpBoost(Handle hTimer, any iClient)
{
	if (g_bPlayer[iClient])
	{
		g_bJumpBoost[iClient] = false;

		CPrintToChat(iClient, "[{red}KINGS{default}] Your {green}jump-boost{default} has worn off.");
	}
}*/

public Action Timer_ModelChanger(Handle hTimer, any iClient)
{
	if(g_bEnableModelChanger)
	SetPlayerModel(iClient, g_sModelName[iClient]);
}

public Action Timer_Protection(Handle hTimer, any iClient)
{
	SetEntProp(iClient, Prop_Data, "m_takedamage", 0, 1);
	
	GetClientAbsOrigin(iClient, g_fSpawnPoint[iClient]);
	
	SetEntityRenderColor(iClient, 0, 255, 0, 128);
	SetEntityRenderFx(iClient, RENDERFX_FLICKER_FAST);
	
	g_bProtection[iClient] = true;
}

public Action Timer_StatHud(Handle hTimer, any iClient)
{
	char sStatsHud[3][128];
	
	float fAllKTD, fRoundKTD;
	
	int iTimeleft;
	
	GetMapTimeLeft(iTimeleft);
	
	if (IsClientInGame(iClient))
	{
		fAllKTD = ((g_iAllDeaths[iClient] <= 0) ? 0.0 : view_as<float>(g_iAllKills[iClient]) / view_as<float>(g_iAllDeaths[iClient]));
		fRoundKTD = ((Client_GetDeaths(iClient) <= 0) ? 0.0 : view_as<float>(Client_GetScore(iClient)) / view_as<float>(Client_GetDeaths(iClient)));
		
		if(g_bAllKills)
		{
			Format(sStatsHud[0], sizeof(sStatsHud[]), "Name: %N\nCredits: %i\n\nKills: %i\nDeaths: %i\nHeadshots: %i\n\n%.2f All-Time KTD\n%.1f Round KTD", iClient, g_iCredits[iClient], Client_GetScore(iClient), Client_GetDeaths(iClient), g_iAllHeadshots[iClient], fAllKTD, fRoundKTD);
		}else{
			Format(sStatsHud[0], sizeof(sStatsHud[]), "Name: %N\nCredits: %i\n\nKills: %i\nDeaths: %i\nHeadshots: %i\n\n%.1f Round KTD", iClient, g_iCredits[iClient], Client_GetScore(iClient), Client_GetDeaths(iClient), g_iAllHeadshots[iClient], fRoundKTD);
		}
		
		g_bPrivateMatchRunning ? Format(sStatsHud[1], sizeof(sStatsHud[]), "Password: %s\nCurrent Map: %s\nTimeleft: %d:%02d", g_sServerPassword, g_sMap, iTimeleft <= 0 ? 00 : (iTimeleft / 60), iTimeleft <= 0 ? 00 : (iTimeleft % 60)) : Format(sStatsHud[1], sizeof(sStatsHud[]), "Current Map: %s\nTimeleft: %d:%02d", g_sMap, iTimeleft <= 0 ? 00 : (iTimeleft / 60), iTimeleft <= 0 ? 00 : (iTimeleft % 60));
		
		if(IsClientSourceTV(iClient))
		{
			for (int i = 1; i < MaxClients; i++)
			{
				if(g_bPlayer[i] && !IsClientSourceTV(i))
				{
					Format(sStatsHud[0], sizeof(sStatsHud[]), "");
					Format(sStatsHud[0], sizeof(sStatsHud[]), "%s%N | Kills: %i / Deaths: %i | Headshots: %i\n", sStatsHud[0], i, Client_GetScore(i), Client_GetDeaths(i), g_iAllHeadshots[iClient]);
				}
			}
			
			Format(sStatsHud[1], sizeof(sStatsHud[]), "Timeleft: %d:%02d", iTimeleft <= 0 ? 00 : (iTimeleft / 60), iTimeleft <= 0 ? 00 : (iTimeleft % 60));
		}
		
		SetHudTextParams(0.010, 0.010, 0.5, 255, 128, 0, 128, 0, 0.1, 0.1, 0.1);
		ShowHudText(iClient, -1, sStatsHud[0]);
		SetHudTextParams(1.0, 0.010, 0.5, 255, 128, 0, 128, 0, 0.1, 0.1, 0.1);
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
	if (g_bPlayer[iClient])
	{
		SetEntityRenderColor(iClient, 255, 255, 255, 255);
		
		g_bInvisibility[iClient] = false;
		
		CPrintToChat(iClient, "[{red}KINGS{default}] Your {green}invisibility{default} has worn off.");
	}
}