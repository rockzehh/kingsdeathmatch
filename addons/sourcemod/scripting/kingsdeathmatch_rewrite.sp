//King's Deathmatch: Developed by King Nothing.
#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR         "RockZehh"
#define PLUGIN_VERSION        "2.0"

#include <geoip>
#include <morecolors>
#include <sdkhooks>
#include <sdktools>
#include <smlib>
#include <sourcemod>
#include <steamworks>
#undef REQUIRE_PLUGIN
#include <updater>

#pragma newdecls required

#define MAX_BUTTONS 26

//Hitgroups:
#define HITGROUP_GENERIC   0
#define HITGROUP_HEAD      1
#define HITGROUP_CHEST     2
#define HITGROUP_STOMACH   3
#define HITGROUP_LEFTARM   4
#define HITGROUP_RIGHTARM  5
#define HITGROUP_LEFTLEG   6
#define HITGROUP_RIGHTLEG  7

//Suit Globals:
#define SUIT_DEVICE_BREATHER	0x00000004
#define SUIT_DEVICE_FLASHLIGHT	0x00000002
#define SUIT_DEVICE_SPRINT		0x00000001

//Weapon Globals:
#define GRENADES 10
#define RPG_ROUNDS 8

#define UPDATE_URL	"https://raw.githubusercontent.com/rockzehh/kingsdeathmatch/master/addons/sourcemod/kdm_updater.upd"

//Variables:
enum DMAchievements
{
	ACHIEVEMENT_ONEKTD, //1250 Kills
	ACHIEVEMENT_TWOKTD, //2000 Kills
	ACHIEVEMENT_THREEKTD, //3000 Kills
	ACHIEVEMENT_FOURKTD, //4000 Kills
	ACHIEVEMENT_FIVEKTD, //5000 Kills
	ACHIEVEMENT_SIXKTD, //6000 Kills
	ACHIEVEMENT_SEVENKTD, //7500 Kills
	ACHIEVEMENT_EIGHTKTD, //9000 Kills
	ACHIEVEMENT_NINEKTD, //9500 Kills
	ACHIEVEMENT_TENKTD, //10000 Kills
	ACHIEVEMENT_1000KILLS,
	ACHIEVEMENT_7500KILLS,
	ACHIEVEMENT_15000KILLS,
	ACHIEVEMENT_30000KILLS,
	ACHIEVEMENT_50000KILLS,
	ACHIEVEMENT_69420KILLS,
	ACHIEVEMENT_75000KILLS,
	ACHIEVEMENT_90000KILLS,
	ACHIEVEMENT_100000KILLS,
	ACHIEVEMENT_250000KILLS,
	ACHIEVEMENT_500000KILLS,
	ACHIEVEMENT_1000000KILLS,
	ACHIEVEMENT_100HEADSHOTS,
	ACHIEVEMENT_250HEADSHOTS,
	ACHIEVEMENT_500HEADSHOTS,
	ACHIEVEMENT_1000HEADSHOTS,
	ACHIEVEMENT_2500HEADSHOTS,
	ACHIEVEMENT_5000HEADSHOTS,
	ACHIEVEMENT_10000HEADSHOTS,
	ACHIEVEMENT_1000GENERIC,
	ACHIEVEMENT_NEGONEKTD,
	ACHIEVEMENT_100PERFECTMAPS,
	ACHIEVEMENT_500PERFECTMAPS,
	ACHIEVEMENT_1000PERFECTMAPS,
	ACHIEVEMENT_1000SUICIDE,
	ACHIEVEMENT_2500SUICIDE,
	ACHIEVEMENT_5000SUICIDE,
	ACHIEVEMENT_250CROWBAR,
	ACHIEVEMENT_750CROWBAR,
	ACHIEVEMENT_1500CROWBAR,
	ACHIEVEMENT_CHILDABUSE,
	ACHIEVEMENT_250HEALTHBOOSTS,
	ACHIEVEMENT_1000HEALTHBOOSTS,
}

enum struct DMCredits
{
	ConVar cvHealthBoostAmount;
	ConVar cvJumpBoostAmount;
	ConVar cvLJPushForce;
	ConVar cvPlayLJSound;
	ConVar cvPriceColorNick;
	ConVar cvPriceHB;
	ConVar cvPriceJB;
	ConVar cvPriceLJ;
	
	float fJumpBoostAmount;
	float fLJPushForce;
	
	int iHealthBoostAmount;
	int iPlayLJSound;
	int iPriceColorNick;
	int iPriceHB;
	int iPriceJB;
	int iPriceLJ;
}

enum struct DMPlayer
{
	ConVar cvAltDamage;
	ConVar cvChangeModel;
	ConVar cvCustomFOV;
	ConVar cvDamageModifier;
	ConVar cvDefaultJumpVel;
	ConVar cvEnableCustomFOV;
	ConVar cvNoFallDamage;
	ConVar cvShowAllKTD;
	ConVar cvStartFOV;
	ConVar cvStartHealth;
	ConVar cvTPoseFix;
	
	bool bAltDamage;
	bool bChangeModel;
	bool bColoredNickname[MAXPLAYERS + 1];
	bool bDeveloper[MAXPLAYERS + 1];
	bool bEnableCustomFOV;
	bool bGodMode[MAXPLAYERS + 1];
	bool bHasProtection[MAXPLAYERS + 1];
	bool bIsPlayer[MAXPLAYERS + 1];
	bool bJumpPressed[MAXPLAYERS + 1];
	bool bNoFallDamage;
	bool bShowAllKTD;
	bool bTPoseFix;
	
	float fDamageModifier;
	float fDefaultJumpVel;
	
	Handle hStatsHud;
	
	int iAllDeaths[MAXPLAYERS + 1];
	int iAllHeadshots[MAXPLAYERS + 1];
	int iAllKills[MAXPLAYERS + 1];
	int iCredits[MAXPLAYERS + 1];
	int iCustomFOV;
	int iGeneric[MAXPLAYERS + 1];
	int iHeadshots[MAXPLAYERS + 1];
	int iHealthBoosts[MAXPLAYERS + 1];
	int iHitBot[MAXPLAYERS + 1];
	int iHitGroup[MAXPLAYERS + 1];
	int iLastButton[MAXPLAYERS + 1];
	int iPerfectMaps[MAXPLAYERS + 1];
	int iStartFOV;
	int iStartHealth;
	int iSuicides[MAXPLAYERS + 1];
	
	StringMap smDeaths;
	StringMap smKills;
}

enum struct DMServer
{
	ConVar cvAllowPrivateMatches;
	ConVar cvDisableAchievements;
	ConVar cvDisableChatAdverts;
	ConVar cvEnableColorNicks;
	ConVar cvEnableDemos;
	ConVar cvEnableJumpBoost;
	ConVar cvEnableLongJump;
	ConVar cvEnableNicknames;
	ConVar cvServerPassword;
	ConVar cvUseSourceMenus;
	
	bool bAllowPrivateMatches;
	bool bDisableAchievements;
	bool bDisableChatAdverts;
	bool bEnableColorNicks;
	bool bEnableDemos;
	bool bEnableJumpBoost;
	bool bEnableLongJump;
	bool bEnableModels;
	bool bEnableNicknames;
	bool bLateLoad;
	bool bPrivateMatch;
	bool bUseSourceMenus;
	
	char sAchievementsDB[PLATFORM_MAX_PATH];
	char sAdvertisementsDB[PLATFORM_MAX_PATH];
	char sClientsDB[PLATFORM_MAX_PATH];
	char sMap[128];
	char sModelsDB[PLATFORM_MAX_PATH];
	char sServerPassword[64];
	
	Handle hAdvertisements;
	Handle hRemoveRPG;
	Handle hStatsHud;
	
	int iAdvertisement;
	
	KeyValues kvAdvertisements;
}

enum struct DMSourceTV
{
	ConVar cvAutoRecord;
	ConVar cvEnable;
	ConVar cvMaxTVClients;
	ConVar cvName;
}

enum struct DMWeapons
{
	ConVar cvAllowRPG;
	ConVar cvAllowSMGGernade;
	ConVar cvCrowbarDamage;
	
	bool bAllowRPG;
	bool bAllowSMGGernade;
	
	int iCrowbarDamage;
}

bool g_bJumpBoost[MAXPLAYERS + 1][2];
bool g_bLongJump[MAXPLAYERS + 1][2];

char g_sAuthID[MAXPLAYERS + 1][64];
char g_sDefaultWeapon[MAXPLAYERS + 1][64];
char g_sModelName[MAXPLAYERS + 1][64];
char g_sNicknameColor[MAXPLAYERS + 1][MAX_NAME_LENGTH];
char g_sNicknameText[MAXPLAYERS + 1][MAX_NAME_LENGTH];

DMCredits g_dmCredits;
DMPlayer g_dmPlayer;
DMServer g_dmServer;
DMSourceTV g_dmSourceTV;
DMWeapons g_dmWeapons;

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

//Plugin Information:
public Plugin myinfo =
{
	name = "King's Deathmatch",
	author = PLUGIN_AUTHOR,
	description = "A custom deathmatch plugin for Half-Life 2: Deathmatch.",
	version = PLUGIN_VERSION,
	url = "https://github.com/rockzehh/kings-deathmatch"
};

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErr_max)
{
	g_dmServer.bLateLoad = bLate;
}

//Plugin Forwards:
public void OnClientPutInServer(int iClient)
{
	int iDeaths, iKills;
	
	GetClientAuthId(iClient, AuthId_Steam3, g_sAuthID[iClient], sizeof(g_sAuthID[]));
	
	//Restore deaths/kills if connected on the same map.
	if(g_dmPlayer.smDeaths.GetValue(g_sAuthID[iClient], iDeaths))
	{
		Client_SetDeaths(iClient, iDeaths);
	}
	
	if(g_dmPlayer.smKills.GetValue(g_sAuthID[iClient], iKills))
	{
		Client_SetScore(iClient, iKills);
	}
	
	g_bJumpBoost[iClient][0] = false;
	g_bJumpBoost[iClient][1] = false;
	g_bLongJump[iClient][0] = false;
	g_bLongJump[iClient][1] = false;
	
	g_dmPlayer.bColoredNickname[iClient] = false;
	g_dmPlayer.bDeveloper[iClient] = false;
	g_dmPlayer.bGodMode[iClient] = false;
	g_dmPlayer.bHasProtection[iClient] = true;
	g_dmPlayer.bIsPlayer[iClient] = true;
	g_dmPlayer.bJumpPressed[iClient] = false;
	
	g_dmPlayer.iAllDeaths[iClient] = 0;
	g_dmPlayer.iAllHeadshots[iClient] = 0;
	g_dmPlayer.iAllKills[iClient] = 0;
	g_dmPlayer.iCredits[iClient] = 0;
	g_dmPlayer.iGeneric[iClient] = 0;
	g_dmPlayer.iHeadshots[iClient] = 0;
	g_dmPlayer.iHealthBoosts[iClient] = 0;
	g_dmPlayer.iHitBot[iClient] = 0;
	g_dmPlayer.iHitGroup[iClient] = 0;
	g_dmPlayer.iLastButton[iClient] = 0;
	g_dmPlayer.iPerfectMaps[iClient] = 0;
	g_dmPlayer.iSuicides[iClient] = 0;
	
	LoadClient(iClient);
	
	GivePlayerGuns(iClient);
	
	SDKHook(iClient, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	SDKHook(iClient, SDKHook_TraceAttackPost,  Hook_TraceAttackPost);
	SDKHook(iClient, SDKHook_WeaponCanSwitchTo, Hook_WeaponCanSwitchTo);
	SDKHookEx(iClient, SDKHook_FireBulletsPost, Hook_FireBulletsPost);
	SDKHookEx(iClient, SDKHook_WeaponSwitchPost, Hook_WeaponSwitchPost);
}

public void OnConVarsChanged(ConVar cvConVar, char[] sOldValue, char[] sNewValue)
{
	g_dmCredits.fJumpBoostAmount = g_dmCredits.cvJumpBoostAmount.FloatValue;
	g_dmCredits.fLJPushForce = g_dmCredits.cvLJPushForce.FloatValue;
	g_dmCredits.iHealthBoostAmount = g_dmCredits.cvHealthBoostAmount.IntValue;
	g_dmCredits.iPriceColorNick = g_dmCredits.cvPriceColorNick.IntValue;
	g_dmCredits.iPriceHB = g_dmCredits.cvPriceHB.IntValue;
	g_dmCredits.iPriceJB = g_dmCredits.cvPriceJB.IntValue;
	g_dmCredits.iPriceLJ = g_dmCredits.cvPriceLJ.IntValue;
	
	g_dmPlayer.bAltDamage = g_dmPlayer.cvAltDamage.BoolValue;
	g_dmPlayer.bChangeModel = g_dmPlayer.cvChangeModel.BoolValue;
	g_dmPlayer.bEnableCustomFOV = g_dmPlayer.cvEnableCustomFOV.BoolValue;
	g_dmPlayer.bNoFallDamage = g_dmPlayer.cvNoFallDamage.BoolValue;
	g_dmPlayer.bShowAllKTD = g_dmPlayer.cvShowAllKTD.BoolValue;
	g_dmPlayer.bTPoseFix = g_dmPlayer.cvTPoseFix.BoolValue;
	g_dmPlayer.fDamageModifier = g_dmPlayer.cvDamageModifier.FloatValue;
	g_dmPlayer.fDefaultJumpVel = g_dmPlayer.cvDefaultJumpVel.FloatValue;
	g_dmPlayer.iCustomFOV = g_dmPlayer.cvCustomFOV.IntValue;
	g_dmPlayer.iStartFOV = g_dmPlayer.cvStartFOV.IntValue;
	g_dmPlayer.iStartHealth = g_dmPlayer.cvStartHealth.IntValue;
	
	g_dmServer.bAllowPrivateMatches = g_dmServer.cvAllowPrivateMatches.BoolValue;
	g_dmServer.bDisableAchievements = g_dmServer.cvDisableAchievements.BoolValue;
	g_dmServer.bDisableChatAdverts = g_dmServer.cvDisableChatAdverts.BoolValue;
	g_dmServer.bEnableColorNicks = g_dmServer.cvEnableColorNicks.BoolValue;
	g_dmServer.bEnableDemos = g_dmServer.cvEnableDemos.BoolValue;
	g_dmServer.bEnableJumpBoost = g_dmServer.cvEnableJumpBoost.BoolValue;
	g_dmServer.bEnableLongJump = g_dmServer.cvEnableLongJump.BoolValue;
	g_dmServer.bEnableNicknames = g_dmServer.cvEnableNicknames.BoolValue;
	g_dmServer.bUseSourceMenus = g_dmServer.cvUseSourceMenus.BoolValue;
	
	g_dmSourceTV.cvEnable.BoolValue = g_dmServer.bEnableDemos;
	g_dmSourceTV.cvAutoRecord.BoolValue = true;
	g_dmSourceTV.cvMaxTVClients.IntValue = 0;
	g_dmSourceTV.cvName.SetString("WonderBread's Security Monitor");
	
	g_dmWeapons.bAllowRPG = g_dmWeapons.cvAllowRPG.BoolValue;
	g_dmWeapons.bAllowSMGGernade = g_dmWeapons.cvAllowSMGGernade.BoolValue;
	g_dmWeapons.iCrowbarDamage = g_dmWeapons.cvCrowbarDamage.IntValue;
}

public void OnClientDisconnect(int iClient)
{
	g_dmPlayer.smDeaths.SetValue(g_sAuthID[iClient], Client_GetDeaths(iClient));
	g_dmPlayer.smKills.SetValue(g_sAuthID[iClient], Client_GetScore(iClient));
	
	SaveClient(iClient);
	
	SDKUnhook(iClient, SDKHook_FireBulletsPost, Hook_FireBulletsPost);
	SDKUnhook(iClient, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	SDKUnhook(iClient, SDKHook_TraceAttackPost,  Hook_TraceAttackPost);
	SDKUnhook(iClient, SDKHook_WeaponCanSwitchTo, Hook_WeaponCanSwitchTo);
	SDKUnhook(iClient, SDKHook_WeaponSwitchPost, Hook_WeaponSwitchPost);
}

public void OnLibraryAdded(const char[] sName)
{
	if (StrEqual(sName, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public void OnMapEnd()
{
	g_dmPlayer.smDeaths.Clear();
	g_dmPlayer.smKills.Clear();
	
	g_dmServer.hAdvertisements.Close();
	g_dmServer.hRemoveRPG.Close();
	g_dmServer.hStatsHud.Close();
}

public void OnMapStart()
{
	g_dmPlayer.smDeaths.Clear();
	g_dmPlayer.smKills.Clear();
	
	RemoveRPGs();
	
	g_dmServer.hAdvertisements = CreateTimer(45.0, Timer_Advertisements, _, TIMER_REPEAT);
	g_dmServer.hRemoveRPG = CreateTimer(30.0, Timer_RPGRemove, _, TIMER_REPEAT);
	g_dmServer.hStatsHud = CreateTimer(0.1, Timer_StatsHUD, _, TIMER_REPEAT);
}

public void OnPluginEnd()
{
	g_dmServer.kvAdvertisements.Close();
}

public void OnPluginStart()
{
	//Game Check:
	if(GetEngineVersion() != Engine_HL2DM)
	SetFailState("This plugin is for Half-Life 2: Deathmatch only.");
	
	//Commands:
	/*AddCommandListener(Handle_Chat, "say");
	AddCommandListener(Handle_Chat, "say_team");

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
	RegConsoleCmd("sm_jb", Command_JumpBoost, "Gives you a big jump boost.");
	RegConsoleCmd("sm_jump", Command_JumpBoost, "Gives you a big jump boost.");
	RegConsoleCmd("sm_jumpboost", Command_JumpBoost, "Gives you a big jump boost.");
	RegConsoleCmd("sm_lj", Command_LongJump, "Gives you bunnyhopping.");
	RegConsoleCmd("sm_longjump", Command_LongJump, "Gives you bunnyhopping.");
	RegConsoleCmd("sm_model", Command_PlayerModel, "Changes your player model.");
	RegConsoleCmd("sm_nick", Command_ChangeNickname, "Changes your player nickname.");
	RegConsoleCmd("sm_playermodel", Command_PlayerModel, "Changes your player model.");
	RegConsoleCmd("sm_private", Command_PrivateMatch, "Sets the match to private with a password.");
	RegConsoleCmd("sm_privatematch", Command_PrivateMatch, "Sets the match to private with a password.");
	RegConsoleCmd("sm_store", Command_Credits, "Brings up the credit menu.");*/
	
	//ConVars:
	CreateConVar("kings-deathmatch", "1", "Notifies the server that the plugin is running.");
	CreateConVar("kdm_plugin_version", PLUGIN_VERSION, "The version of the plugin the server is running.");
	
	//Credits:
	g_dmCredits.cvHealthBoostAmount = CreateConVar("kdm_healthboost_amount", "75", "The amount of health the health boost will do.");
	g_dmCredits.cvJumpBoostAmount = CreateConVar("kdm_jumpboost_amount", "500.0", "The added jump velocity.");
	g_dmCredits.cvLJPushForce = CreateConVar("kdm_longjump_push_force", "650.0", "The amount of force that the long jump does.");
	g_dmCredits.cvPriceColorNick = CreateConVar("kdm_colornickname_price", "25000", "The amount of credits you need to buy the colored nickname.");
	g_dmCredits.cvPriceHB = CreateConVar("kdm_healthboost_price", "350", "The amount of credits you need to pay to use the health boost.");
	g_dmCredits.cvPriceJB = CreateConVar("kdm_jumpboost_price", "1750", "The amount of credits you need to pay to use the jump boost module.");
	g_dmCredits.cvPriceLJ = CreateConVar("kdm_longjump_price", "2500", "The amount of credits you need to pay to use the long jump module.");
	
	g_dmCredits.fJumpBoostAmount = g_dmCredits.cvJumpBoostAmount.FloatValue;
	g_dmCredits.fLJPushForce = g_dmCredits.cvLJPushForce.FloatValue;
	g_dmCredits.iHealthBoostAmount = g_dmCredits.cvHealthBoostAmount.IntValue;
	g_dmCredits.iPriceColorNick = g_dmCredits.cvPriceColorNick.IntValue;
	g_dmCredits.iPriceHB = g_dmCredits.cvPriceHB.IntValue;
	g_dmCredits.iPriceJB = g_dmCredits.cvPriceJB.IntValue;
	g_dmCredits.iPriceLJ = g_dmCredits.cvPriceLJ.IntValue;
	
	g_dmCredits.cvHealthBoostAmount.AddChangeHook(OnConVarsChanged);
	g_dmCredits.cvJumpBoostAmount.AddChangeHook(OnConVarsChanged);
	g_dmCredits.cvLJPushForce.AddChangeHook(OnConVarsChanged);
	g_dmCredits.cvPriceColorNick.AddChangeHook(OnConVarsChanged);
	g_dmCredits.cvPriceHB.AddChangeHook(OnConVarsChanged);
	g_dmCredits.cvPriceJB.AddChangeHook(OnConVarsChanged);
	g_dmCredits.cvPriceLJ.AddChangeHook(OnConVarsChanged);
	
	//Player:
	g_dmPlayer.cvAltDamage = CreateConVar("kdm_player_alternatedamage", "1", "Decides if the players have alternate damage.", _, true, 0.1, true, 1.0);
	g_dmPlayer.cvChangeModel = CreateConVar("kdm_player_model_change", "1", "Decides if the player can change their model.", _, true, 0.1, true, 1.0);
	g_dmPlayer.cvCustomFOV = CreateConVar("kdm_player_custom_fov", "115", "The custom FOV value.");
	g_dmPlayer.cvDamageModifier = CreateConVar("kdm_player_damage_modifier", "0.5", "Damage modifier. A better description will be added.");
	g_dmPlayer.cvDefaultJumpVel = CreateConVar("kdm_player_jump_velocity", "100.0", "The default jump velocity.");
	g_dmPlayer.cvEnableCustomFOV = CreateConVar("kdm_player_custom_fov_enable", "1", "Decides to use the custom FOV on the players.", _, true, 0.1, true, 1.0);
	g_dmPlayer.cvNoFallDamage = CreateConVar("kdm_player_nofalldamage", "1", "Decides if to disable fall damage.", _, true, 0.1, true, 1.0);
	g_dmPlayer.cvShowAllKTD = CreateConVar("kdm_player_hud_showallkills", "1", "Shows the stats for the players overall kills.", _, true, 0.1, true, 1.0);
	g_dmPlayer.cvStartFOV = CreateConVar("kdm_player_start_fov", "20", "The custom start animation FOV value.");
	g_dmPlayer.cvStartHealth = CreateConVar("kdm_player_start_health", "175", "The start player health.");
	g_dmPlayer.cvTPoseFix = CreateConVar("kdm_player_tposefix", "1", "Decides if to fix the T-Pose falling glitch.", _, true, 0.1, true, 1.0);
	
	g_dmPlayer.bAltDamage = g_dmPlayer.cvAltDamage.BoolValue;
	g_dmPlayer.bChangeModel = g_dmPlayer.cvChangeModel.BoolValue;
	g_dmPlayer.bEnableCustomFOV = g_dmPlayer.cvEnableCustomFOV.BoolValue;
	g_dmPlayer.bNoFallDamage = g_dmPlayer.cvNoFallDamage.BoolValue;
	g_dmPlayer.bShowAllKTD = g_dmPlayer.cvShowAllKTD.BoolValue;
	g_dmPlayer.bTPoseFix = g_dmPlayer.cvTPoseFix.BoolValue;
	g_dmPlayer.fDamageModifier = g_dmPlayer.cvDamageModifier.FloatValue;
	g_dmPlayer.fDefaultJumpVel = g_dmPlayer.cvDefaultJumpVel.FloatValue;
	g_dmPlayer.iCustomFOV = g_dmPlayer.cvCustomFOV.IntValue;
	g_dmPlayer.iStartFOV = g_dmPlayer.cvStartFOV.IntValue;
	g_dmPlayer.iStartHealth = g_dmPlayer.cvStartHealth.IntValue;
	
	g_dmPlayer.cvChangeModel.AddChangeHook(OnConVarsChanged);
	g_dmPlayer.cvCustomFOV.AddChangeHook(OnConVarsChanged);
	g_dmPlayer.cvDamageModifier.AddChangeHook(OnConVarsChanged);
	g_dmPlayer.cvDefaultJumpVel.AddChangeHook(OnConVarsChanged);
	g_dmPlayer.cvEnableCustomFOV.AddChangeHook(OnConVarsChanged);
	g_dmPlayer.cvNoFallDamage.AddChangeHook(OnConVarsChanged);
	g_dmPlayer.cvShowAllKTD.AddChangeHook(OnConVarsChanged);
	g_dmPlayer.cvStartFOV.AddChangeHook(OnConVarsChanged);
	g_dmPlayer.cvStartHealth.AddChangeHook(OnConVarsChanged);
	g_dmPlayer.cvTPoseFix.AddChangeHook(OnConVarsChanged);
	
	//Server:
	g_dmServer.cvAllowPrivateMatches = CreateConVar("kdm_server_allow_private_matches", "1", "If users can start a private match.", _, true, 0.1, true, 1.0);
	g_dmServer.cvDisableAchievements = CreateConVar("kdm_server_achievements", "1", "Decides if server achievements should be used.", _, true, 0.1, true, 1.0);
	g_dmServer.cvDisableChatAdverts = CreateConVar("kdm_chat_disable_advertisements", "0", "Decides if chat advertisements should be displayed.", _, true, 0.1, true, 1.0);
	g_dmServer.cvEnableColorNicks = CreateConVar("kdm_colornickname_enable", "1", "Decides if colored nicknames are enabled.", _, true, 0.1, true, 1.0);
	g_dmServer.cvEnableDemos = CreateConVar("kdm_demos_enable", "1", "Decides if the SourceTV demo recording is enabled.", _, true, 0.1, true, 1.0);
	g_dmServer.cvEnableJumpBoost = CreateConVar("kdm_jumpboost_enable", "1", "Decides if the jump boost module is enabled.", _, true, 0.1, true, 1.0);
	g_dmServer.cvEnableLongJump = CreateConVar("kdm_longjump_enable", "1", "Decides if the long jump module is enabled.", _, true, 0.1, true, 1.0);
	g_dmServer.cvEnableNicknames = CreateConVar("kdm_nickname_enable", "1", "Decides if nicknames are enabled.", _, true, 0.1, true, 1.0);
	g_dmServer.cvServerPassword = FindConVar("sv_password");
	g_dmServer.cvUseSourceMenus = CreateConVar("kdm_server_usesourcemenus", "0", "Decides to use the chat option or the menu system.", _, true, 0.1, true, 1.0);
	
	g_dmServer.bAllowPrivateMatches = g_dmServer.cvAllowPrivateMatches.BoolValue;
	g_dmServer.bDisableAchievements = g_dmServer.cvDisableAchievements.BoolValue;
	g_dmServer.bDisableChatAdverts = g_dmServer.cvDisableChatAdverts.BoolValue;
	g_dmServer.bEnableColorNicks = g_dmServer.cvEnableColorNicks.BoolValue;
	g_dmServer.bEnableDemos = g_dmServer.cvEnableDemos.BoolValue;
	g_dmServer.bEnableJumpBoost = g_dmServer.cvEnableJumpBoost.BoolValue;
	g_dmServer.bEnableLongJump = g_dmServer.cvEnableLongJump.BoolValue;
	g_dmServer.bEnableNicknames = g_dmServer.cvEnableNicknames.BoolValue;
	g_dmServer.bUseSourceMenus = g_dmServer.cvUseSourceMenus.BoolValue;
	
	g_dmServer.cvAllowPrivateMatches.AddChangeHook(OnConVarsChanged);
	g_dmServer.cvDisableAchievements.AddChangeHook(OnConVarsChanged);
	g_dmServer.cvDisableChatAdverts.AddChangeHook(OnConVarsChanged);
	g_dmServer.cvEnableColorNicks.AddChangeHook(OnConVarsChanged);
	g_dmServer.cvEnableDemos.AddChangeHook(OnConVarsChanged);
	g_dmServer.cvEnableJumpBoost.AddChangeHook(OnConVarsChanged);
	g_dmServer.cvEnableLongJump.AddChangeHook(OnConVarsChanged);
	g_dmServer.cvEnableNicknames.AddChangeHook(OnConVarsChanged);
	g_dmServer.cvServerPassword.AddChangeHook(OnConVarsChanged);
	g_dmServer.cvUseSourceMenus.AddChangeHook(OnConVarsChanged);
	
	//SourceTV:
	g_dmSourceTV.cvEnable = FindConVar("tv_enable");
	g_dmSourceTV.cvAutoRecord = FindConVar("tv_autorecord");
	g_dmSourceTV.cvMaxTVClients = FindConVar("tv_maxclients");
	g_dmSourceTV.cvName = FindConVar("tv_name");
	
	g_dmSourceTV.cvEnable.BoolValue = g_dmServer.bEnableDemos;
	g_dmSourceTV.cvAutoRecord.BoolValue = true;
	g_dmSourceTV.cvMaxTVClients.IntValue = 0;
	g_dmSourceTV.cvName.SetString("WonderBread's Security Monitor");
	
	g_dmSourceTV.cvEnable.AddChangeHook(OnConVarsChanged);
	
	//Weapons:
	g_dmWeapons.cvAllowRPG = CreateConVar("kdm_wep_allow_rpg", "0", "Decides if the RPG is allowed to spawn.", _, true, 0.1, true, 1.0);
	g_dmWeapons.cvAllowSMGGernade = CreateConVar("kdm_wep_allow_smg_gernade", "0", "Decides if the SMG gernade is allowed to spawn.", _, true, 0.1, true, 1.0);
	g_dmWeapons.cvCrowbarDamage = CreateConVar("kdm_wep_crowbar_damage", "1000", "The damage the crowbar will do.");
	
	g_dmWeapons.bAllowRPG = g_dmWeapons.cvAllowRPG.BoolValue;
	g_dmWeapons.bAllowSMGGernade = g_dmWeapons.cvAllowSMGGernade.BoolValue;
	g_dmWeapons.iCrowbarDamage = g_dmWeapons.cvCrowbarDamage.IntValue;
	
	g_dmWeapons.cvAllowRPG.AddChangeHook(OnConVarsChanged);
	g_dmWeapons.cvAllowSMGGernade.AddChangeHook(OnConVarsChanged);
	g_dmWeapons.cvCrowbarDamage.AddChangeHook(OnConVarsChanged);
	
	AutoExecConfig(true, "kings-deathmatch");
	
	//BuildPaths:
	char sPath[PLATFORM_MAX_PATH];
	
	BuildPath(Path_SM, sPath, sizeof(sPath), "data/kingsdeathmatch");
	if (!DirExists(sPath))
	{
		CreateDirectory(sPath, 511);
	}
	
	BuildPath(Path_SM, g_dmServer.sAchievementsDB, PLATFORM_MAX_PATH, "data/kingsdeathmatch/achievements.txt");
	if(!FileExists(g_dmServer.sAchievementsDB))
	{
		g_dmServer.bDisableAchievements = false;
	}
	
	BuildPath(Path_SM, g_dmServer.sAdvertisementsDB, PLATFORM_MAX_PATH, "data/kingsdeathmatch/advertisements.txt");
	if(!FileExists(g_dmServer.sAdvertisementsDB))
	{
		g_dmServer.bDisableChatAdverts = false;
	}
	
	BuildPath(Path_SM, g_dmServer.sClientsDB, PLATFORM_MAX_PATH, "data/kingsdeathmatch/clients.txt");
	
	BuildPath(Path_SM, g_dmServer.sModelsDB, PLATFORM_MAX_PATH, "data/kingsdeathmatch/models.txt");
	if(!FileExists(g_dmServer.sModelsDB))
	{
		g_dmServer.bEnableModels = false;
	}
	
	//Events:
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	//Libraries:
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	
	//StringMaps:
	g_dmPlayer.smDeaths = CreateTrie();
	g_dmPlayer.smKills = CreateTrie();
	
	//Server:
	//Advertisements:
	g_dmServer.kvAdvertisements = new KeyValues("Advertisements");
	
	g_dmServer.kvAdvertisements.ImportFromFile(g_dmServer.sAdvertisementsDB);
	
	g_dmServer.iAdvertisement = 1;
	
	//Gamemode Description:
	SteamWorks_SetGameDescription("King's DM");
	
	//Late Load:
	if(g_dmServer.bLateLoad)
	{
		for (int i = 1; i < MaxClients; i++)
		{
			if(Client_IsValid(i))
			{
				OnClientPutInServer(i);
			}
		}
	}
}

//Events:
public Action Event_PlayerDeath(Event eEvent, char[] sName, bool bDontBroadcast)
{
	char sAttackerColor[MAX_NAME_LENGTH], sClientColor[MAX_NAME_LENGTH];
	
	int iAttacker = GetClientOfUserId(eEvent.GetInt("attacker"));
	int iClient = GetClientOfUserId(eEvent.GetInt("userid"));
	int iRandom;
	
	if(Client_IsValid(iAttacker) && Client_IsValid(iClient))
	{
		Format(sAttackerColor, sizeof(sAttackerColor), "%s", StrEqual(g_sNicknameColor[iAttacker], "") ? "default" : g_sNicknameColor[iAttacker]);
		Format(sClientColor, sizeof(sClientColor), "%s", StrEqual(g_sNicknameColor[iClient], "") ? "default" : g_sNicknameColor[iClient]);
		
		if(iClient != iAttacker)
		{
			if(iAttacker <= 0)
			{
				g_dmPlayer.iAllDeaths[iClient]++;
				
				CPrintToChatAll("{%s}%N{default} got killed by the world... somehow.", sClientColor, iClient);
			}else if(g_dmPlayer.iHitGroup[iClient] <= 0 || g_dmPlayer.iHitGroup[iClient] >= 7)
			{
				switch(g_dmPlayer.iHitGroup[iClient])
				{
					case HITGROUP_GENERIC:
					{
						iRandom = GetRandomInt(11, 24);
						
						g_dmPlayer.iAllDeaths[iClient]++;
						g_dmPlayer.iAllKills[iAttacker]++;
						g_dmPlayer.iGeneric[iClient]++;
						
						g_dmPlayer.iCredits[iAttacker] += iRandom;
						
						switch(GetRandomInt(0, 2))
						{
							case 0:
							{
								CPrintToChatAll("{%s}%N{default} got {green}+%i{default} credits for killing {%s}%N{default}.", sAttackerColor, iAttacker, iRandom, sClientColor, iClient);
							}
							
							case 1:
							{
								CPrintToChatAll("{%s}%N{default} got {green}+%i{default} credits for fucking obliterating {%s}%N{default}.", sAttackerColor, iAttacker, iRandom, sClientColor, iClient);
							}
							
							case 2:
							{
								CPrintToChatAll("{%s}%N{default} fucking creamed {%s}%N{default}. ({green}+%i{default} credits)", sAttackerColor, iAttacker, sClientColor, iClient, iRandom);
							}
						}	
					}
					case HITGROUP_HEAD:
					{
						iRandom = GetRandomInt(21, 33);
						
						g_dmPlayer.iAllDeaths[iClient]++;
						g_dmPlayer.iAllHeadshots[iClient]++;
						g_dmPlayer.iAllKills[iAttacker]++;
						g_dmPlayer.iHeadshots[iClient]++;
						
						g_dmPlayer.iCredits[iAttacker] += iRandom;
						
						switch(GetRandomInt(0, 2))
						{
							case 0:
							{
								CPrintToChatAll("{%s}%N{default} got {green}+%i{default} credits for shooting {%s}%N{default} in the head.", sAttackerColor, iAttacker, iRandom, sClientColor, iClient);
							}
							
							case 1:
							{
								CPrintToChatAll("{%s}%N{default} got {green}+%i{default} credits for blowing {%s}%N{default}'s fucking brains out.", sAttackerColor, iAttacker, iRandom, sClientColor, iClient);
							}
							
							case 2:
							{
								CPrintToChatAll("{%s}%N{default} blew a hole through {%s}%N{default}'s head. ({green}+%i{default} credits)", sAttackerColor, iAttacker, sClientColor, iClient, iRandom);
							}
						}
					}
					case HITGROUP_CHEST:
					{
						iRandom = GetRandomInt(13, 20);
						
						g_dmPlayer.iAllDeaths[iClient]++;
						g_dmPlayer.iAllKills[iAttacker]++;
						
						g_dmPlayer.iCredits[iAttacker] += iRandom;
						
						switch(GetRandomInt(0, 1))
						{
							case 0:
							{
								CPrintToChatAll("{%s}%N{default} got {green}+%i{default} credits for breaking {%s}%N{default}'s heart. </3", sAttackerColor, iAttacker, iRandom, sClientColor, iClient);
							}
							
							case 1:
							{
								CPrintToChatAll("{%s}%N{default} stole {%s}%N{default}'s torso. :( ({green}+%i{default} credits)", sAttackerColor, iAttacker, sClientColor, iClient, iRandom);
							}
						}
					}
					case HITGROUP_STOMACH:
					{
						iRandom = GetRandomInt(9, 18);
						
						g_dmPlayer.iAllDeaths[iClient]++;
						g_dmPlayer.iAllKills[iAttacker]++;
						
						g_dmPlayer.iCredits[iAttacker] += iRandom;
						
						switch(GetRandomInt(0, 2))
						{
							case 0:
							{
								CPrintToChatAll("{%s}%N{default} got {green}+%i{default} credits for busting {%s}%N{default}'s gut.", sAttackerColor, iAttacker, iRandom, sClientColor, iClient);
							}
							
							case 1:
							{
								CPrintToChatAll("{%s}%N{default} got {green}+%i{default} credits for reliefing {%s}%N{default} of gas.", sAttackerColor, iAttacker, iRandom, sClientColor, iClient);
							}
							
							case 2:
							{
								CPrintToChatAll("{%s}%N{default} stole {%s}%N{default}'s stomach. ({green}+%i{default} credits)", sAttackerColor, iAttacker, sClientColor, iClient, iRandom);
							}
						}
					}
					case HITGROUP_LEFTARM:
					{
						iRandom = GetRandomInt(14, 26);
						
						g_dmPlayer.iAllDeaths[iClient]++;
						g_dmPlayer.iAllKills[iAttacker]++;
						
						g_dmPlayer.iCredits[iAttacker] += iRandom;
						
						switch(GetRandomInt(0, 1))
						{
							case 0:
							{
								CPrintToChatAll("{%s}%N{default} got {green}+%i{default} credits for breaking {%s}%N{default}'s useless hand.", sAttackerColor, iAttacker, iRandom, sClientColor, iClient);
							}
							
							case 1:
							{
								CPrintToChatAll("{%s}%N{default} stole {%s}%N{default}'s left arm. Guess he didn't need it anyways.. ({green}+%i{default} credits)", sAttackerColor, iAttacker, sClientColor, iClient, iRandom);
							}
						}
					}
					case HITGROUP_RIGHTARM:
					{
						iRandom = GetRandomInt(8, 18);
						
						g_dmPlayer.iAllDeaths[iClient]++;
						g_dmPlayer.iAllKills[iAttacker]++;
						
						g_dmPlayer.iCredits[iAttacker] += iRandom;
						
						switch(GetRandomInt(0, 1))
						{
							case 0:
							{
								CPrintToChatAll("{%s}%N{default} got {green}+%i{default} credits for stealing {%s}%N{default}'s magic hand.", sAttackerColor, iAttacker, iRandom, sClientColor, iClient);
							}
							
							case 1:
							{
								CPrintToChatAll("{%s}%N{default} broke {%s}%N{default}'s middle finger. What a dick.. ({green}+%i{default} credits)", sAttackerColor, iAttacker, sClientColor, iClient, iRandom);
							}
						}
					}
					case HITGROUP_LEFTLEG:
					{
						iRandom = GetRandomInt(19, 28);
						
						g_dmPlayer.iAllDeaths[iClient]++;
						g_dmPlayer.iAllKills[iAttacker]++;
						
						g_dmPlayer.iCredits[iAttacker] += iRandom;
						
						CPrintToChatAll("{%s}%N{default} got {green}+%i{default} credits for breaking {%s}%N{default}'s left leg.", sAttackerColor, iAttacker, iRandom, sClientColor, iClient);
					}
					case HITGROUP_RIGHTLEG:
					{
						iRandom = GetRandomInt(19, 28);
						
						g_dmPlayer.iAllDeaths[iClient]++;
						g_dmPlayer.iAllKills[iAttacker]++;
						
						g_dmPlayer.iCredits[iAttacker] += iRandom;
						
						CPrintToChatAll("{%s}%N{default} got {green}+%i{default} credits for breaking {%s}%N{default}'s right leg.", sAttackerColor, iAttacker, iRandom, sClientColor, iClient);
					}
				}
			}else{
				iRandom = GetRandomInt(11, 24);
				
				g_dmPlayer.iAllDeaths[iClient]++;
				g_dmPlayer.iAllKills[iAttacker]++;
				
				g_dmPlayer.iCredits[iAttacker] += iRandom;
				
				switch(GetRandomInt(0, 2))
				{
					case 0:
					{
						CPrintToChatAll("{%s}%N{default} got {green}+%i{default} credits for killing {%s}%N{default}.", sAttackerColor, iAttacker, iRandom, sClientColor, iClient);
					}
					
					case 1:
					{
						CPrintToChatAll("{%s}%N{default} got {green}+%i{default} credits for fucking obliterating {%s}%N{default}.", sAttackerColor, iAttacker, iRandom, sClientColor, iClient);
					}
					
					case 2:
					{
						CPrintToChatAll("{%s}%N{default} fucking creamed {%s}%N{default}. ({green}+%i{default} credits)", sAttackerColor, iAttacker, sClientColor, iClient, iRandom);
					}
				}	
			}
		}else{
			g_dmPlayer.iAllDeaths[iClient]++;
			g_dmPlayer.iAllKills[iClient]--;
			g_dmPlayer.iSuicides[iClient]++;
			
			iRandom = GetRandomInt(3, 8);
			
			g_dmPlayer.iCredits[iClient] -= iRandom;
			
			CPrintToChatAll("{%s}%N{default} has lost {green}%i{default} points for commiting suicide.", sClientColor, iClient, iRandom);
		}
		
		if(Client_GetScore(iAttacker) >= FindConVar("mp_fraglimit").IntValue)
		{
			g_dmPlayer.iPerfectMaps[iAttacker]++;
		}
		
		CreateTimer(0.1, Timer_Fire, GetClientUserId(iClient));
		
		CreateTimer(1.5, Timer_Dissolve, GetClientUserId(iClient));
	}
}

public Action Event_PlayerSpawn(Event eEvent, char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(eEvent.GetInt("userid"));
	
	if(Client_IsValid(iClient))
	{
		SetEntityHealth(iClient, g_dmPlayer.iStartHealth);
		
		GivePlayerGuns(iClient);
	}
}

//Hooks:
public void Hook_FireBulletsPost(int iClient, int iShots, char[] sWeaponname)
{
	int iWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	
	if (iWeapon != -1)
	{
		ReFillWeapon(iClient, iWeapon);
	}
	
	if(g_dmPlayer.bHasProtection[iClient] && Client_IsValid(iClient))
	{
		SetEntProp(iClient, Prop_Data, "m_takedamage", 2, 1);
		
		SetEntityRenderColor(iClient, 255, 255, 255, 255);
		SetEntityRenderFx(iClient, RENDERFX_NONE);
		
		g_dmPlayer.bHasProtection[iClient] = false;
	}
}

public Action Hook_OnTakeDamage(int iClient, int &iAttacker, int &iInflictor, float &fDamage, int &iDamagetype)
{
	if(Client_IsValid(iAttacker) && Client_IsValid(iClient))
	{
		if(g_dmPlayer.bDeveloper[iAttacker] || g_dmPlayer.bGodMode[iAttacker])
		{
			return Plugin_Handled;
		}else if(iDamagetype == DMG_FALL && g_dmPlayer.bNoFallDamage)
		{
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public void Hook_TraceAttackPost(int iVictim, int iAttacker, int iInflictor, float fDamage, int iDamageType, int iAmmoType, int iHitbox, int iHitGroup)
{
	g_dmPlayer.iHitGroup[iVictim] = iHitGroup;
}

public Action Hook_WeaponCanSwitchTo(int iClient, int iWeapon)
{
	// Hands animation fix by toizy
	if(g_dmPlayer.bTPoseFix)
	SetEntityFlags(iClient, GetEntityFlags(iClient) | FL_ONGROUND);
}

public void Hook_WeaponSwitchPost(int iClient, int iWeapon)
{
	if (iWeapon != -1)
	{
		ReFillWeapon(iClient, iWeapon);
	}
}

//Stocks:
stock void GivePlayerGuns(int iClient)
{
	if(Client_IsValid(iClient))
	{
		GivePlayerItem(iClient, "weapon_crowbar");
		
		if(g_dmWeapons.bAllowRPG)
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

stock void LoadClient(int iClient)
{
	if(Client_IsValid(iClient))
	{
		KeyValues kvVault = new KeyValues("Credits");
		
		kvVault.ImportFromFile(g_dmServer.sClientsDB);
		
		kvVault.JumpToKey(g_sAuthID[iClient], false);
		
		g_dmPlayer.iAllDeaths[iClient] = LoadInteger(kvVault, g_sAuthID[iClient], "all_deaths", 0);
		g_dmPlayer.iGeneric[iClient] = LoadInteger(kvVault, g_sAuthID[iClient], "all_generic", 0);
		g_dmPlayer.iHeadshots[iClient] = LoadInteger(kvVault, g_sAuthID[iClient], "all_headshots", 0);
		g_dmPlayer.iHealthBoosts[iClient] = LoadInteger(kvVault, g_sAuthID[iClient], "all_healthboosts", 0);
		g_dmPlayer.iHitBot[iClient] = LoadInteger(kvVault, g_sAuthID[iClient], "all_hitbot", 0);
		g_dmPlayer.iAllKills[iClient] = LoadInteger(kvVault, g_sAuthID[iClient], "all_kills", 0);
		g_dmPlayer.iHitBot[iClient] = LoadInteger(kvVault, g_sAuthID[iClient], "all_perfectmaps", 0);
		g_dmPlayer.iSuicides[iClient] = LoadInteger(kvVault, g_sAuthID[iClient], "all_suicides", 0);
		
		g_dmPlayer.iCredits[iClient] = LoadInteger(kvVault, g_sAuthID[iClient], "credits", 1500);
		
		LoadString(kvVault, g_sAuthID[iClient], "default_weapon", "weapon_357", g_sDefaultWeapon[iClient], sizeof(g_sDefaultWeapon));
		
		g_bJumpBoost[iClient][0] = view_as<bool>(LoadInteger(kvVault, g_sAuthID[iClient], "jump_boost", 0));
		g_bJumpBoost[iClient][1] = view_as<bool>(LoadInteger(kvVault, g_sAuthID[iClient], "previous_jb_setting", 0));
		
		g_bLongJump[iClient][0] = view_as<bool>(LoadInteger(kvVault, g_sAuthID[iClient], "long_jump", 0));
		g_bLongJump[iClient][1] = view_as<bool>(LoadInteger(kvVault, g_sAuthID[iClient], "previous_lj_setting", 0));
		
		LoadString(kvVault ,g_sAuthID[iClient], "nickname_color", "default", g_sNicknameColor[iClient], sizeof(g_sNicknameColor));
		LoadString(kvVault, g_sAuthID[iClient], "nickname_text", "", g_sNicknameText[iClient], sizeof(g_sNicknameText));
		
		LoadString(kvVault, g_sAuthID[iClient], "player_model", "", g_sModelName[iClient], sizeof(g_sModelName));
		
		kvVault.Rewind();
		
		kvVault.Close();
	}
}

stock int LoadInteger(KeyValues kvVault, char[] sKey, char[] sSaveKey, int iDefaultValue)
{
	kvVault.JumpToKey(sKey, false);
	
	int iVariable = kvVault.GetNum(sSaveKey, iDefaultValue);
	
	kvVault.Rewind();
	
	return iVariable;
}

stock void LoadString(KeyValues kvVault, const char[] sKey, const char[] sSaveKey, const char[] sDefaultValue, char[] sReference, int iMaxLength)
{
	kvVault.JumpToKey(sKey, false);
	
	kvVault.GetString(sSaveKey, sReference, iMaxLength, sDefaultValue);
	
	kvVault.Rewind();
}

stock void ProperKTDCalculation(const float fKTD, char sResult[32])
{
	char sKTDCalc[2][32], sSplitString[3][32];
	float fCopyKTD = fKTD;
	
	RoundToZero(fCopyKTD);
	
	FloatToString(fCopyKTD, sKTDCalc[0], sizeof(sKTDCalc[]));
	
	ExplodeString(sKTDCalc[0], ".", sSplitString, 2, sizeof(sSplitString[]), true);
	
	Format(sSplitString[2], sizeof(sSplitString[]), "%c.%c%c%c%c", sSplitString[1][1], sSplitString[1][2], sSplitString[1][3], sSplitString[1][4], sSplitString[1][5]);
	
	int iDecimal = RoundToNearest(StringToFloat(sSplitString[2]));
	
	Format(sResult, sizeof(sResult), "%s.%c%i", sSplitString[0], sSplitString[1][0], iDecimal);
}

public void ReFillWeapon(int iClient, int iWeapon)
{
	int iPrimaryAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
	
	if (iPrimaryAmmoType != -1)
	{
		if (iPrimaryAmmoType != RPG_ROUNDS && iPrimaryAmmoType != GRENADES)
		{
			(/*g_dmWeapons.bAllowSMGGernade && */iWeapon == 10) ? SetEntProp(iWeapon, Prop_Send, "m_iClip1", 0) : SetEntProp(iWeapon, Prop_Send, "m_iClip1", g_iClip_Sizes[iPrimaryAmmoType]);
		}
		
		SetEntProp(iClient, Prop_Send, "m_iAmmo", 255, _, iPrimaryAmmoType);
	}
	
	
	int iSecondaryAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iSecondaryAmmoType");
	
	if (iSecondaryAmmoType != -1)
	{
		SetEntProp(iClient, Prop_Send, "m_iAmmo", 255, _, iSecondaryAmmoType);
	}
}

stock void RemoveRPGs()
{
	char sClassname[64];
	
	for (int i = 0; i < GetMaxEntities() * 2; i++)
	{
		if (IsValidEntity(i))
		{
			GetEntityClassname(i, sClassname, sizeof(sClassname));
			
			if ((StrEqual(sClassname, "weapon_rpg") || StrEqual(sClassname, "item_rpg_round")) && !g_dmWeapons.bAllowRPG)
			{
				RemoveEntity(i);
			}
		}
	}
}

stock void SaveClient(int iClient)
{
	if(Client_IsValid(iClient))
	{
		KeyValues kvVault = new KeyValues("Credits");
		
		kvVault.ImportFromFile(g_dmServer.sClientsDB);
		
		SaveInteger(kvVault, g_sAuthID[iClient], "all_deaths", g_dmPlayer.iAllDeaths[iClient]);
		SaveInteger(kvVault, g_sAuthID[iClient], "all_generic", g_dmPlayer.iGeneric[iClient]);
		SaveInteger(kvVault, g_sAuthID[iClient], "all_headshots", g_dmPlayer.iHeadshots[iClient]);
		SaveInteger(kvVault, g_sAuthID[iClient], "all_healthboosts", g_dmPlayer.iHealthBoosts[iClient]);
		SaveInteger(kvVault, g_sAuthID[iClient], "all_hitbot", g_dmPlayer.iHitBot[iClient]);
		SaveInteger(kvVault, g_sAuthID[iClient], "all_kills", g_dmPlayer.iAllKills[iClient]);
		SaveInteger(kvVault, g_sAuthID[iClient], "all_perfectmaps", g_dmPlayer.iHitBot[iClient]);
		SaveInteger(kvVault, g_sAuthID[iClient], "all_suicides", g_dmPlayer.iSuicides[iClient]);
		
		SaveInteger(kvVault, g_sAuthID[iClient], "credits", g_dmPlayer.iCredits[iClient]);
		
		SaveString(kvVault, g_sAuthID[iClient], "default_weapon", g_sDefaultWeapon[iClient]);
		
		SaveInteger(kvVault, g_sAuthID[iClient], "jump_boost", view_as<int>(g_bJumpBoost[iClient][0]));
		SaveInteger(kvVault, g_sAuthID[iClient], "previous_jb_setting", view_as<int>(g_bJumpBoost[iClient][1]));
		
		SaveInteger(kvVault, g_sAuthID[iClient], "long_jump", view_as<int>(g_bLongJump[iClient][0]));
		SaveInteger(kvVault, g_sAuthID[iClient], "previous_lj_setting", view_as<int>(g_bLongJump[iClient][1]));
		
		SaveString(kvVault, g_sAuthID[iClient], "nickname_color", g_sNicknameColor[iClient]);
		SaveString(kvVault, g_sAuthID[iClient], "nickname_text", g_sNicknameText[iClient]);
		
		SaveString(kvVault, g_sAuthID[iClient], "player_model", g_sModelName[iClient]);
		
		kvVault.ExportToFile(g_dmServer.sClientsDB);
		
		kvVault.Close();
	}
}

stock void SaveInteger(KeyValues kvVault, char[] sKey, char[] sSaveKey, int iVariable)
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

stock void SaveString(KeyValues kvVault, const char[] sKey, const char[] sSaveKey, const char[] sVariable)
{
	kvVault.JumpToKey(sKey, true);
	
	kvVault.SetString(sSaveKey, sVariable);
	
	kvVault.Rewind();
}

//Timers:
public Action Timer_Advertisements(Handle hTimer)
{
	char sAdvertisement[256];
	
	switch (g_dmServer.iAdvertisement)
	{
		case 1:
		{
			LoadString(g_dmServer.kvAdvertisements, "Messages", "1", "", sAdvertisement, sizeof(sAdvertisement));
			
			g_dmServer.iAdvertisement = 2;
		}
		
		case 2:
		{
			LoadString(g_dmServer.kvAdvertisements, "Messages", "2", "", sAdvertisement, sizeof(sAdvertisement));
			
			g_dmServer.iAdvertisement = 3;
		}
		
		case 3:
		{
			LoadString(g_dmServer.kvAdvertisements, "Messages", "3", "", sAdvertisement, sizeof(sAdvertisement));
			
			g_dmServer.iAdvertisement = 4;
		}
		
		case 4:
		{
			LoadString(g_dmServer.kvAdvertisements, "Messages", "4", "", sAdvertisement, sizeof(sAdvertisement));
			
			g_dmServer.iAdvertisement = 5;
		}
		
		case 5:
		{
			LoadString(g_dmServer.kvAdvertisements, "Messages", "5", "", sAdvertisement, sizeof(sAdvertisement));
			
			g_dmServer.iAdvertisement = 6;
		}
		
		case 6:
		{
			LoadString(g_dmServer.kvAdvertisements, "Messages", "6", "", sAdvertisement, sizeof(sAdvertisement));
			
			g_dmServer.iAdvertisement = 7;
		}
		
		case 7:
		{
			LoadString(g_dmServer.kvAdvertisements, "Messages", "7", "", sAdvertisement, sizeof(sAdvertisement));
			
			g_dmServer.iAdvertisement = 1;
		}
	}
	
	if(!g_dmServer.bDisableChatAdverts)
	CPrintToChatAll(sAdvertisement);
}

public Action Timer_Dissolve(Handle hTimer, any iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if(g_dmPlayer.bIsPlayer[iClient] && Client_IsValid(iClient))
	{
		Effect_DissolvePlayerRagDoll(iClient, DISSOLVE_ELECTRICAL_LIGHT);
	}
}

public Action Timer_Fire(Handle hTimer, any iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if(g_dmPlayer.bIsPlayer[iClient] && Client_IsValid(iClient))
	{
		int iRagdoll = GetEntPropEnt(iClient, Prop_Send, "m_hRagdoll");
		
		IgniteEntity(iRagdoll, 5.0);
	}
}

public Action Timer_RPGRemove(Handle hTimer)
{
	RemoveRPGs();
}

public Action Timer_StatsHUD(Handle hTimer)
{
	char sAllKTD[32], sRoundKTD[32], sStatsHud[3][128];
	
	float fAllKTD, fRoundKTD;
	
	int iTimeleft;
	
	GetMapTimeLeft(iTimeleft);
	
	for (int iClient = 1; iClient < MaxClients; iClient++)
	{
		if (IsClientInGame(iClient) && Client_IsValid(iClient))
		{
			if(!IsClientSourceTV(iClient))
			{
				fAllKTD = (view_as<float>(g_dmPlayer.iAllKills[iClient]) / view_as<float>(g_dmPlayer.iAllDeaths[iClient]));
				fRoundKTD = (view_as<float>(Client_GetScore(iClient)) / view_as<float>(Client_GetDeaths(iClient)));
				
				fAllKTD = ((g_dmPlayer.iAllDeaths[iClient] < 0) ? 0.0 : fAllKTD);
				fRoundKTD = ((Client_GetDeaths(iClient) < 0) ? 0.0 : fRoundKTD);
				
				ProperKTDCalculation(fAllKTD, sAllKTD);
				ProperKTDCalculation(fRoundKTD, sRoundKTD);
				
				if(g_dmPlayer.bShowAllKTD)
				{
					Format(sStatsHud[0], sizeof(sStatsHud[]), "Name: %N\nCredits: %i\n\nKills: %i/%i\nDeaths: %i\nHeadshots: %i\n\n%s All-Time KTD\n%s Round KTD", iClient, g_dmPlayer.iCredits[iClient], Client_GetScore(iClient), FindConVar("mp_fraglimit").IntValue, Client_GetDeaths(iClient), g_dmPlayer.iAllHeadshots[iClient], sAllKTD, sRoundKTD);
				}else{
					Format(sStatsHud[0], sizeof(sStatsHud[]), "Name: %N\nCredits: %i\n\nKills: %i/%i\nDeaths: %i\nHeadshots: %i\n\n%s Round KTD", iClient, g_dmPlayer.iCredits[iClient], Client_GetScore(iClient), FindConVar("mp_fraglimit").IntValue, Client_GetDeaths(iClient), g_dmPlayer.iAllHeadshots[iClient], sRoundKTD);
				}
				
				g_dmServer.bPrivateMatch ? Format(sStatsHud[1], sizeof(sStatsHud[]), "Password: %s\nCurrent Map: %s\nTimeleft: %d:%02d", g_dmServer.sServerPassword, g_dmServer.sMap, iTimeleft <= 0 ? 00 : (iTimeleft / 60), iTimeleft <= 0 ? 00 : (iTimeleft % 60)) : Format(sStatsHud[1], sizeof(sStatsHud[]), "Current Map: %s\nTimeleft: %d:%02d", g_dmServer.sMap, iTimeleft <= 0 ? 00 : (iTimeleft / 60), iTimeleft <= 0 ? 00 : (iTimeleft % 60));
				
			}else{
				for (int i = 1; i < MaxClients; i++)
				{
					if(IsClientInGame(i) && Client_IsValid(i) && !IsClientSourceTV(i))
					{
						Format(sStatsHud[0], sizeof(sStatsHud[]), "");
						Format(sStatsHud[0], sizeof(sStatsHud[]), "%s%N | Kills: %i/%i / Deaths: %i | Headshots: %i\n", sStatsHud[0], i, Client_GetScore(i), FindConVar("mp_fraglimit").IntValue, Client_GetDeaths(i), g_dmPlayer.iAllHeadshots[i]);
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
}
