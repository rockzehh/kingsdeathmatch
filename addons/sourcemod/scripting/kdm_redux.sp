//King's Deathmatch - Redux: Developed by King Nothing/RockZehh.
//Other smaller code is provided by various coders.
//The official unofficial Council of Nerds Deathmatch plugin.

#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "King Nothing/RockZehh"
#define PLUGIN_VERSION "3.0"

#define MAX_GAME_BUTTONS 26

#include <discord>
#include <geoip>
#include <morecolors>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <smlib>
#include <steamworks>
#include <vphysics>
#undef REQUIRE_PLUGIN
#include <updater>

#pragma newdecls required

#define MAX_GRENADES 10
#define MAX_RPG_ROUNDS 8

//Hitgroups:
#define HITGROUP_GENERIC   0
#define HITGROUP_HEAD      1
#define HITGROUP_CHEST     2
#define HITGROUP_STOMACH   3
#define HITGROUP_LEFTARM   4
#define HITGROUP_RIGHTARM  5
#define HITGROUP_LEFTLEG   6
#define HITGROUP_RIGHTLEG  7

//Suit Device:
#define SUIT_DEVICE_SPRINT		0x00000001
#define SUIT_DEVICE_FLASHLIGHT	0x00000002
#define SUIT_DEVICE_BREATHER	0x00000004

#define UPDATE_URL	"https://raw.githubusercontent.com/rockzehh/kingsdeathmatch/master/addons/sourcemod/kdmclassic_updater.upd"

bool g_bAllowPrivateMatches;
bool g_bAllowRPG;
bool g_bChangeFOV;
bool g_bDisableAdvertisements;
bool g_bDisableFallDamage;
bool g_bEnableColoredNicknames;
bool g_bEnableInvisibility;
bool g_bEnableJumpBoost;
bool g_bEnableLongJump;
bool g_bEnableLongJumpSound;
bool g_bEnableModelChanger;
bool g_bEnableNicknames;
bool g_bHasColoredNickname[MAXPLAYERS + 1];
bool g_bHasGodMode[MAXPLAYERS + 1];
bool g_bHasProtection[MAXPLAYERS + 1];
bool g_bIsInvisible[MAXPLAYERS + 1];
bool g_bIsPlayer[MAXPLAYERS + 1];
bool g_bIsPrivateMatchRunning;
bool g_bInCoNDiscord[MAXPLAYERS + 1];
bool g_bInDeveloperMode[MAXPLAYERS + 1];
bool g_bJumpBoost[MAXPLAYERS + 1][2];
bool g_bLongJump[MAXPLAYERS + 1][2];
bool g_bShowAllKills;
bool g_bShowAttackerHealth[MAXPLAYERS + 1];
bool g_bUseSourceMenus;
bool g_bUseTPoseFix;
bool g_bUsingLongJump[MAXPLAYERS + 1];
bool g_bUsingZoom[MAXPLAYERS + 1];

char g_sAuthID[MAXPLAYERS][64];
char g_sCurrentMap[128];
char g_sDBAdvertisements[PLATFORM_MAX_PATH];
char g_sDBClients[PLATFORM_MAX_PATH];
char g_sDBModels[PLATFORM_MAX_PATH];
char g_sDefaultWeapon[MAXPLAYERS + 1][64];
char g_sModelName[MAXPLAYERS + 1][64];
char g_sServerPassword;

ConVar g_cvAllowPrivateMatches;
ConVar g_cvAllowRPG;
ConVar g_cvCombineBallCooldown;
ConVar g_cvCrowbarDamage;
ConVar g_cvDamageLevel;
ConVar g_cvDefaultFOV;
ConVar g_cvDefaultJumpVelocity;
ConVar g_cvDisableAdvertisements;
ConVar g_cvDisableFallDamage;
ConVar g_cvEnableColorNickname;
ConVar g_cvEnableDemoRecording;
ConVar g_cvEnableInvisibility;
ConVar g_cvEnableJumpBoost;
ConVar g_cvEnableLongJump;
ConVar g_cvEnableModelChanger;
ConVar g_cvEnableNickname;
ConVar g_cvHealthBoost;
ConVar g_cvJumpBoostVel;
ConVar g_cvLongJumpSound;
ConVar g_cvLongJumpVel;
ConVar g_cvPassword;
ConVar g_cvSourceTV[3];
ConVar g_cvStartHealth;
ConVar g_cvTPoseFix;
ConVar g_cvUpgradePriceColorNickname;
ConVar g_cvUpgradePriceHealthBoost;
ConVar g_cvUpgradePriceInvisibility;
ConVar g_cvUpgradePriceJumpBoost ;
ConVar g_cvUpgradePriceLongJump;
ConVar g_cvUseSourceMenus;

enum struct Nicknames
{
	char Nickname[MAX_NAME_LENGTH];
	char NicknameColor[128];
	
	int CustomNicknameColor;
}

enum struct PointsTracking
{
	int AllDeaths;
	int AllGeneric;
	int AllHeadshots;
	int AllHealthBoosts;
	int AllHitBot;
	int AllKills;
	int AllPerfectMaps;
	int AllSuicides;
	int Credits;
	int Deaths;
	int Headshots;
	int Kills;
}

float g_fCombineBallFireCooldown;
float g_fDefaultJumpVelocity;
float g_fJumpBoostVelocity;
float g_fLastCombineBallFireTime[MAXPLAYERS + 1];
float g_fLongJumpVelocity;
float g_fUpgradeDuration[] = 
{
	30.0, //Invisibility
};

Handle g_hAdvertisementTimer;
Handle g_hStatsHud;

int g_iBodyHitGroup[MAXPLAYERS + 1];
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
int g_iCrowbarDamage;
int g_iCurrentAdvertisement = 1;
int g_iDefaultFOV;
int g_iHealthBoostAmount;
int g_iLastPressedButton[MAXPLAYERS + 1];
int g_iStartingFOV[MAXPLAYERS + 1];
int g_iStartingHealth[MAXPLAYERS + 1];
int g_iUpgrade_Prices[] =
{
	350, //Health Boost
	1000, //Invisibility
	750, //Jump Boost
	1500, //Long Jump
};
int g_iZoomStatus[MAXPLAYERS + 1];
enum(+=1) { ZOOM_NONE, ZOOM_XBOW, ZOOM_SUIT, ZOOM_TOGL, FIRSTPERSON }

KeyValues g_kvChatAdvertisements;

Nicknames g_nNickname[MAXPLAYERS + 1];

PointsTracking g_ptPointType[MAXPLAYERS + 1];

StringMap g_smDeaths;
StringMap g_smHeadshots;
StringMap g_smKills;

public Plugin myinfo =
{
	name = "King's Deathmatch - Redux",
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

public void OnPluginStart()
{
	char sPath[PLATFORM_MAX_PATH];
	
	AddCommandListener(CMDHook_Chat, "say");
	AddCommandListener(CMDHook_Chat, "say_team");
	
	BuildPath(Path_SM, sPath, sizeof(sPath), "data/kdm_redux");
	if (!DirExists(sPath))
	{
		CreateDirectory(sPath, 511);
	}
	
	BuildPath(Path_SM, g_sDBAdvertisements, PLATFORM_MAX_PATH, "data/kdm_redux/advertisements.txt");
	if(!FileExists(g_sDBAdvertisements))
	{
		g_bDisableAdvertisements = false;
	}
	
	BuildPath(Path_SM, g_sDBClients, PLATFORM_MAX_PATH, "data/kdm_redux/clients.txt");
	
	BuildPath(Path_SM, g_sDBModels, PLATFORM_MAX_PATH, "data/kdm_redux/models.txt");
	if(!FileExists(g_sDBModels))
	{
		g_bEnableModelChanger = false;
	}
	
	CreateConVar("kings-deathmatch-redux", "1", "Notifies the server that the plugin is running.");
	
	g_cvAllowPrivateMatches = CreateConVar("kdm-sv_allow_private_matches", "1", "If users can start a private match.", _, true, 0.1, true, 1.0);
	g_cvAllowRPG = CreateConVar("kdm-wep_allow_rpg", "0", "Decides if the RPG is allowed.", _, true, 0.1, true, 1.0);
	g_cvCombineBallCooldown = CreateConVar("kdm-wep_combineball_cooldown", "2.5", "The number of seconds that the cooldown on combine balls last.");
	g_cvCrowbarDamage = CreateConVar("kdm-wep_crowbar_damage", "500", "The damage the crowbar will do.");
	g_cvDamageLevel = CreateConVar("kdm-cl_damage_level", "2", "Decides the level of damage that players take..", _, true, 1.0, true, 2.0);
	g_cvDefaultFOV = CreateConVar("kdm-cl_default_fov", "115", "The default FOV value.");
	g_cvDefaultJumpVelocity = CreateConVar("kdm-cl_jump_velocity", "100.0", "The default jump velocity.");
	g_cvDisableAdvertisements = CreateConVar("kdm-sv_disable_chat_advertisements", "0", "Decides if chat advertisements should be displayed.", _, true, 0.1, true, 1.0);
	g_cvDisableFallDamage = CreateConVar("kdm-cl_disable_fall_damage", "1", "Decides if to disable fall damage.", _, true, 0.1, true, 1.0);
	g_cvEnableColorNickname = CreateConVar("kdm-sv_colornickname_enable", "1", "Decides if colored nicknames are enabled.", _, true, 0.1, true, 1.0);
	g_cvEnableDemoRecording = CreateConVar("kdm-sv_record_demo", "1", "Decides if the SourceTV demo recording is enabled.", _, true, 0.1, true, 1.0);
	g_cvEnableInvisibility = CreateConVar("kdm-sv_invisible_enable", "1", "Decides if the invisiblity effect is enabled.", _, true, 0.1, true, 1.0);
	g_cvEnableJumpBoost = CreateConVar("kdm-sv_jumpboost_enable", "1", "Decides if the jump boost module is enabled.", _, true, 0.1, true, 1.0);
	g_cvEnableLongJump = CreateConVar("kdm-sv_longjump_enable", "1", "Decides if the long jump module is enabled.", _, true, 0.1, true, 1.0);
	g_cvEnableModelChanger = CreateConVar("kdm-sv_model_change", "1", "Decides if the player can change their model.", _, true, 0.1, true, 1.0);
	g_cvEnableNickname = CreateConVar("kdm-cl_nickname_enable", "1", "Decides if nicknames are enabled.", _, true, 0.1, true, 1.0);
	g_cvHealthBoost = CreateConVar("kdm-cl_healthboost_amount", "75", "The amount of health the health boost will do.");
	g_cvJumpBoostVel = CreateConVar("kdm-cl_jumpboost_velocity", "600.0", "The added jump velocity.");
	g_cvLongJumpSound = CreateConVar("kdm-cl_longjump_sound", "1", "Decides if to play the long jump sound.", _, true, 0.1, true, 1.0);
	g_cvLongJumpVel = CreateConVar("kdm-cl_longjump_velocity", "800.0", "The added velcoity for the long jump.");
	g_cvPassword = FindConVar("sv_password");
	g_cvSourceTV[0] = FindConVar("tv_enable");
	g_cvSourceTV[1] = FindConVar("tv_autorecord");
	g_cvSourceTV[2] = FindConVar("tv_maxclients");
	g_cvStartHealth = CreateConVar("kdm-cl_start_health", "175", "The start player health.");
	g_cvTPoseFix = CreateConVar("kdm-cl_disable_tpose_glitch", "1", "Decides if to fix the T-Pose falling glitch.", _, true, 0.1, true, 1.0);
	g_cvUpgradePriceColorNickname = CreateConVar("kdm-sv_colornickname_price", "25000", "The amount of credits you need to buy the colored nickname.");
	g_cvUpgradePriceHealthBoost = CreateConVar("kdm-sv_healthboost_price", "350", "The amount of credits you need to pay to use the health boost.");
	g_cvUpgradePriceInvisibility = CreateConVar("kdm-sv_invisible_price", "500", "The amount of credits you need to pay to use the invisible effect.");
	g_cvUpgradePriceJumpBoost = CreateConVar("kdm-sv_jumpboost_price", "1750", "The amount of credits you need to pay to use the jump boost module.");
	g_cvUpgradePriceLongJump = CreateConVar("kdm-sv_longjump_price", "2500", "The amount of credits you need to pay to use the long jump module.");
	g_cvUseSourceMenus = CreateConVar("kdm-sv_use_source_menus", "0", "Decides to use the chat option or the source menu system.", _, true, 0.1, true, 1.0);
	
	CreateConVar("kdm_plugin_version", PLUGIN_VERSION, "The version of the plugin the server is running.");
	
	g_bAllKills = g_cvShowAllKills.BoolValue;
	g_fCombineBallCooldown = g_cvCombineBallCooldown.FloatValue;
	g_iCrowbarDamage = g_cvCrowbarDamage.IntValue;
	g_bEnableColorNickname = g_cvEnableColorNickname.BoolValue;
	g_bEnableInvisibility = g_cvEnableInvisibility.BoolValue;
	g_bEnableJumpBoost = g_cvEnableJumpBoost.BoolValue;
	g_bEnableLongJump = g_cvEnableLongJump.BoolValue;
	g_bEnableModelChanger = g_cvEnableModelChanger.BoolValue;
	g_bEnableNickname = g_cvEnableNickname.BoolValue;
	g_bFallFix = g_cvFallingFix.BoolValue;
	g_bFOV = g_cvUseFOV.BoolValue;
	g_iFOV = g_cvFOV.IntValue;
	g_iHealthBoost = g_cvHealthBoost.IntValue;
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
	g_iUpgrade_Prices[4] = g_cvUpgradePriceColorNickname.IntValue;
	
	g_cvAllowPrivateMatches.AddChangeHook(KDM_OnConVarChanged);
g_cvAllowRPG.AddChangeHook(KDM_OnConVarChanged);
g_cvCombineBallCooldown.AddChangeHook(KDM_OnConVarChanged);
g_cvCrowbarDamage.AddChangeHook(KDM_OnConVarChanged);
g_cvDamageLevel.AddChangeHook(KDM_OnConVarChanged);
g_cvDefaultFOV.AddChangeHook(KDM_OnConVarChanged);
g_cvDefaultJumpVelocity.AddChangeHook(KDM_OnConVarChanged);
g_cvDisableAdvertisements.AddChangeHook(KDM_OnConVarChanged);
g_cvDisableFallDamage.AddChangeHook(KDM_OnConVarChanged);
g_cvEnableColorNickname.AddChangeHook(KDM_OnConVarChanged);
g_cvEnableDemoRecording.AddChangeHook(KDM_OnConVarChanged);
g_cvEnableInvisibility.AddChangeHook(KDM_OnConVarChanged);
g_cvEnableJumpBoost.AddChangeHook(KDM_OnConVarChanged);
g_cvEnableLongJump.AddChangeHook(KDM_OnConVarChanged);
g_cvEnableModelChanger.AddChangeHook(KDM_OnConVarChanged);
g_cvEnableNickname.AddChangeHook(KDM_OnConVarChanged);
g_cvHealthBoost.AddChangeHook(KDM_OnConVarChanged);
g_cvJumpBoostVel.AddChangeHook(KDM_OnConVarChanged);
g_cvLongJumpSound.AddChangeHook(KDM_OnConVarChanged);
g_cvLongJumpVel.AddChangeHook(KDM_OnConVarChanged);
g_cvPassword.AddChangeHook(KDM_OnConVarChanged);
g_cvSourceTV[3].AddChangeHook(KDM_OnConVarChanged);
g_cvStartHealth.AddChangeHook(KDM_OnConVarChanged);
g_cvTPoseFix.AddChangeHook(KDM_OnConVarChanged);
g_cvUpgradePriceColorNickname.AddChangeHook(KDM_OnConVarChanged);
g_cvUpgradePriceHealthBoost.AddChangeHook(KDM_OnConVarChanged);
g_cvUpgradePriceInvisibility.AddChangeHook(KDM_OnConVarChanged);
g_cvUpgradePriceJumpBoost .AddChangeHook(KDM_OnConVarChanged);
g_cvUpgradePriceLongJump.AddChangeHook(KDM_OnConVarChanged);
g_cvUseSourceMenus.AddChangeHook(KDM_OnConVarChanged);
	
	HookEvent("player_changename", Event_DisableGameEventMessages, EventHookMode_Pre);
	HookEvent("player_connect", Event_DisableGameEventMessages, EventHookMode_Pre);
	HookEvent("player_connect_client", Event_DisableGameEventMessages, EventHookMode_Pre);
	HookEvent("player_disconnect", Event_DisableGameEventMessages, EventHookMode_Pre);
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	
	//Execute plugin config.
	AutoExecConfig(true, "kdm_classic");
}
