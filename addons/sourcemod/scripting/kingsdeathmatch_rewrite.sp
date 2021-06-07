//King's Deathmatch: Developed by King Nothing.
#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR         "RockZehh"
#define PLUGIN_VERSION        "2.0"

#include <discord>
#include <geoip>
#include <morecolors>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <smlib>
#include <steamworks>
#undef REQUIRE_PLUGIN
#include <updater>

#pragma newdecls required

#define MAX_BUTTONS 26

//Achievements:
enum Achievements
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
	ACHIEVEMENT_,
	ACHIEVEMENT_,
	ACHIEVEMENT_,
	ACHIEVEMENT_,
	ACHIEVEMENT_,
	ACHIEVEMENT_,
	ACHIEVEMENT_,
	ACHIEVEMENT_,
	ACHIEVEMENT_,
	ACHIEVEMENT_,
	ACHIEVEMENT_,
	ACHIEVEMENT_,
	ACHIEVEMENT_,
}

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
enum struct DMAchivements
{
	
}

enum struct DMCredits
{
	ConVar cvHealthBoostAmount;
	ConVar cvJumpBoostAmount;
	ConVar cvLJPushForce;
	ConVar cvPlayLJSound;
	ConVar cvPriceColorNick;
	ConVar cvPriceHB;
	ConVar cvPriceInvisible;
	ConVar cvPriceJB;
	ConVar cvPriceLJ;
	
	float fJumpBoostAmount;
	float fLJPushForce;
	
	int iHealthBoostAmount;
	int iPlayLJSound;
	int iPriceColorNick;
	int iPriceHB;
	int iPriceInvisible;
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
	bool bInvisible[MAXPLAYERS + 1];
	bool bIsPlayer[MAXPLAYERS + 1];
	bool bJumpBoost[MAXPLAYERS + 1][2];
	bool bJumpPressed[MAXPLAYERS + 1];
	bool bLongJump[MAXPLAYERS + 1][2];
	bool bNoFallDamage;
	bool bShowAllKTD;
	bool bTPoseFix;
	
	char sDefaultWeapon[MAXPLAYERS + 1][64];
	char sModelName[MAXPLAYERS + 1][64];
	char sNicknameColor[MAXPLAYERS + 1][MAX_NAME_LENGTH];
	char sNicknameText[MAXPLAYERS + 1][MAX_NAME_LENGTH];
	
	float fDamageModifier;
	float fDefaultJumpVel;
	
	Handle hStatsHud;
	
	int iAllDeaths[MAXPLAYERS + 1];
	int iAllHeadshots[MAXPLAYERS + 1];
	int iAllKills[MAXPLAYERS + 1];
	int iCredits[MAXPLAYERS + 1];
	int iHeadshots[MAXPLAYERS + 1];
	int iHitgroup[MAXPLAYERS + 1];
	int iLastButton[MAXPLAYERS + 1];
	int iStartFOV;
	int iStartHealth;
}

enum struct DMServer
{
	ConVar cvAllowPrivateMatches;
	ConVar cvDisableAchievements;
	ConVar cvDisableChatAdverts;
	ConVar cvEnableColorNicks;
	ConVar cvEnableDemos;
	ConVar cvEnableInvisible;
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
	bool bEnableInvisible;
	bool bEnableJumpBoost;
	bool bEnableLongJump;
	bool bEnableModels;
	bool bEnableNicknames;
	bool bPrivateMatch;
	bool bUseSourceMenus;
	
	char sAchievementsDB[PLATFORM_MAX_PATH];
	char sAdvertisementsDB[PLATFORM_MAX_PATH];
	char sClientsDB[PLATFORM_MAX_PATH];
	char sMap[128];
	char sModelsDB[PLATFORM_MAX_PATH];
	char sServerPassword[64];
	
	Handle hAdvertisements;
	
	int iAdvertisement = 1;
	
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
	ConVar cvCrowbarDamage;
	
	bool bAllowRPG;
	
	float g_fCommand_Duration[] =
	{
		15.0, //Invisibility
	};
	
	int iClip_Sizes[] =
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
	int iCrowbarDamage;
}

DMAchivements g_dmAchivements;
DMCredits g_dmCredits;
DMPlayer g_dmPlayer;
DMServer g_dmServer;
DMSourceTV g_dmSourceTV;
DMWeapons g_dmWeapons;

//Plugin Information:
public Plugin myinfo =
{
	name = "King's Deathmatch",
	author = PLUGIN_AUTHOR,
	description = "A custom deathmatch plugin for Half-Life 2: Deathmatch.",
	version = PLUGIN_VERSION,
	url = "https://github.com/rockzehh/kings-deathmatch"
};

//Plugin Forwards:
public void OnConVarsChanged(ConVar cvConVar, char[] sOldValue, char[] sNewValue)
{
	g_dmCredits.bPlayLJSound = g_dmCredits.cvPlayLJSound.BoolValue;
	g_dmCredits.fJumpBoostAmount = g_dmCredits.cvJumpBoostAmount.FloatValue;
	g_dmCredits.fLJPushForce = g_dmCredits.cvLJPushForce.FloatValue;
	g_dmCredits.iHealthBoostAmount = g_dmCredits.cvHealthBoostAmount.IntValue;;
	g_dmCredits.iPriceColorNick = g_dmCredits.cvPriceColorNick.IntValue;
	g_dmCredits.iPriceHB = g_dmCredits.cvPriceHB.IntValue;
	g_dmCredits.iPriceInvisible = g_dmCredits.cvPriceInvisible.IntValue;
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
	g_dmServer.bDisableChatAdverts = g_dmServer.cvDisableChatAdverts.BoolValue;
	g_dmServer.bEnableColorNicks = g_dmServer.cvEnableColorNicks.BoolValue;
	g_dmServer.bEnableDemos = g_dmServer.cvEnableDemos.BoolValue;
	g_dmServer.bEnableInvisible = g_dmServer.cvEnableInvisible.BoolValue;
	g_dmServer.bEnableJumpBoost = g_dmServer.cvEnableJumpBoost.BoolValue;
	g_dmServer.bEnableLongJump = g_dmServer.cvEnableLongJump.BoolValue;
	g_dmServer.bEnableNicknames = g_dmServer.cvEnableNicknames.BoolValue;
	g_dmServer.bUseSourceMenus = g_dmServer.cvUseSourceMenus.BoolValue;
	
	g_dmSourceTV.cvEnable.BoolValue = g_dmServer.bEnableDemos;
	g_dmSourceTV.cvAutoRecord.BoolValue = true;
	g_dmSourceTV.cvMaxTVClients.IntValue = 0;
	g_dmSourceTV.cvName.SetString("WonderBread's Security Monitor");
	
	g_dmWeapons.bAllowRPG = g_dmWeapons.cvAllowRPG.BoolValue;
	g_dmWeapons.iCrowbarDamage = g_dmWeapons.cvCrowbarDamage.IntValue;
}

public void OnLibraryAdded(const char[] sName)
{
	if (StrEqual(sName, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public void OnPluginStart()
{	
	//Game Check:
	if(GetEngineVersion() != Engine_HL2DM)
	SetFailState("This plugin is for Half-Life 2: Deathmatch only.");
	
	//Commands:
	AddCommandListener(Handle_Chat, "say");
	AddCommandListener(Handle_Chat, "say_team");
	
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
	
	//ConVars:
	CreateConVar("kings-deathmatch", "1", "Notifies the server that the plugin is running.");
	CreateConVar("kdm_plugin_version", PLUGIN_VERSION, "The version of the plugin the server is running.");
	
	//Credits:
	g_dmCredits.cvHealthBoostAmount = CreateConVar("kdm_healthboost_amount", "75", "The amount of health the health boost will do.");
	g_dmCredits.cvJumpBoostAmount = CreateConVar("kdm_jumpboost_amount", "500.0", "The added jump velocity.");
	g_dmCredits.cvLJPushForce = CreateConVar("kdm_longjump_push_force", "650.0", "The amount of force that the long jump does.");
	g_dmCredits.cvPlayLJSound = CreateConVar("kdm_longjump_play_sound", "1", "Decides if to play the long jump sound.", _, true, 0.1, true, 1.0);
	g_dmCredits.cvPriceColorNick = CreateConVar("kdm_colornickname_price", "25000", "The amount of credits you need to buy the colored nickname.");
	g_dmCredits.cvPriceHB = CreateConVar("kdm_healthboost_price", "350", "The amount of credits you need to pay to use the health boost.");
	g_dmCredits.cvPriceInvisible = CreateConVar("kdm_invisible_price", "500", "The amount of credits you need to pay to use the invisible effect.");
	g_dmCredits.cvPriceJB = CreateConVar("kdm_jumpboost_price", "1750", "The amount of credits you need to pay to use the jump boost module.");
	g_dmCredits.cvPriceLJ = CreateConVar("kdm_longjump_price", "2500", "The amount of credits you need to pay to use the long jump module.");
	
	g_dmCredits.bPlayLJSound = g_dmCredits.cvPlayLJSound.BoolValue;
	g_dmCredits.fJumpBoostAmount = g_dmCredits.cvJumpBoostAmount.FloatValue;
	g_dmCredits.fLJPushForce = g_dmCredits.cvLJPushForce.FloatValue;
	g_dmCredits.iHealthBoostAmount = g_dmCredits.cvHealthBoostAmount.IntValue;;
	g_dmCredits.iPriceColorNick = g_dmCredits.cvPriceColorNick.IntValue;
	g_dmCredits.iPriceHB = g_dmCredits.cvPriceHB.IntValue;
	g_dmCredits.iPriceInvisible = g_dmCredits.cvPriceInvisible.IntValue;
	g_dmCredits.iPriceJB = g_dmCredits.cvPriceJB.IntValue;
	g_dmCredits.iPriceLJ = g_dmCredits.cvPriceLJ.IntValue;
	
	g_dmCredits.cvHealthBoostAmount.AddChangeHook(OnConVarsChanged);
	g_dmCredits.cvJumpBoostAmount.AddChangeHook(OnConVarsChanged);
	g_dmCredits.cvLJPushForce.AddChangeHook(OnConVarsChanged);
	g_dmCredits.cvPlayLJSound.AddChangeHook(OnConVarsChanged);
	g_dmCredits.cvPriceColorNick.AddChangeHook(OnConVarsChanged);
	g_dmCredits.cvPriceHB.AddChangeHook(OnConVarsChanged);
	g_dmCredits.cvPriceInvisible.AddChangeHook(OnConVarsChanged);
	g_dmCredits.cvPriceJB.AddChangeHook(OnConVarsChanged);
	g_dmCredits.cvPriceLJ.AddChangeHook(OnConVarsChanged);
	
	//Player:
	g_dmPlayer.cvAltDamage = CreateConVar("kdm_player_alternatedamage", "0", "Decides if the players have alternate damage.", _, true, 0.1, true, 1.0);
	g_dmPlayer.cvChangeModel = CreateConVar("kdm_player_model_change", "1", "Decides if the player can change their model.", _, true, 0.1, true, 1.0);
	g_dmPlayer.cvCustomFOV = CreateConVar("kdm_player_custom_fov", "115", "The custom FOV value.");
	g_dmPlayer.cvDamageModifier = CreateConVar("kdm_player_damage_modifier", "0.5", "Damage modifier. A better description will be added.");
	g_dmPlayer.cvDefaultJumpVel = CreateConVar("kdm_player_jump_velocity", "100.0", "The default jump velocity.");
	g_dmPlayer.cvEnableCustomFOV = CreateConVar("kdm_player_custom_fov_enable", "1", "Decides to use the custom FOV on the players.", _, true, 0.1, true, 1.0);
	g_dmPlayer.cvNoFallDamage = CreateConVar("kdm_player_nofalldamage", "1", "Decides if to disable fall damage.", _, true, 0.1, true, 1.0);
	g_dmPlayer.cvShowAllKTD = CreateConVar("kdm_player_hud_showallkills", "1", "Shows the stats for the players overall kills.", _, true, 0.1, true, 1.0);
	g_dmPlayer.cvStartFOV = CreateConVar("kdm_player_start_fov", "20", "The custom start animation FOV value.");
	g_dmPlayer.cvStartHealth = CreateConVar("kdm_player_start_health", "175", "The start player health.");
	g_dmPlayer.cvTPoseFix = CreateConVar("kdm_player_tposefix", "0", "Decides if to fix the T-Pose falling glitch.", _, true, 0.1, true, 1.0);
	
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
	g_dmServer.cvDisableAchievements = CreateConVar("kdm_server_achievements", "0", "Decides if server achievements should be used.", _, true, 0.1, true, 1.0);
	g_dmServer.cvDisableChatAdverts = CreateConVar("kdm_chat_disable_advertisements", "0", "Decides if chat advertisements should be displayed.", _, true, 0.1, true, 1.0);
	g_dmServer.cvEnableColorNicks = CreateConVar("kdm_colornickname_enable", "1", "Decides if colored nicknames are enabled.", _, true, 0.1, true, 1.0);
	g_dmServer.cvEnableDemos = CreateConVar("kdm_demos_enable", "1", "Decides if the SourceTV demo recording is enabled.", _, true, 0.1, true, 1.0);
	g_dmServer.cvEnableInvisible = CreateConVar("kdm_invisible_enable", "1", "Decides if the invisiblity effect is enabled.", _, true, 0.1, true, 1.0);
	g_dmServer.cvEnableJumpBoost = CreateConVar("kdm_jumpboost_enable", "1", "Decides if the jump boost module is enabled.", _, true, 0.1, true, 1.0);
	g_dmServer.cvEnableLongJump = CreateConVar("kdm_longjump_enable", "1", "Decides if the long jump module is enabled.", _, true, 0.1, true, 1.0);
	g_dmServer.cvEnableNicknames = CreateConVar("kdm_nickname_enable", "1", "Decides if nicknames are enabled.", _, true, 0.1, true, 1.0);
	g_dmServer.cvServerPassword = FindConVar("sv_password");
	g_dmServer.cvUseSourceMenus = CreateConVar("kdm_server_usesourcemenus", "0", "Decides to use the chat option or the menu system.", _, true, 0.1, true, 1.0);
	
	g_dmServer.bAllowPrivateMatches = g_dmServer.cvAllowPrivateMatches.BoolValue;
	g_dmServer.bDisableAchievments = g_dmServer.cvDisableAchievments.BoolValue;
	g_dmServer.bDisableChatAdverts = g_dmServer.cvDisableChatAdverts.BoolValue;
	g_dmServer.bEnableColorNicks = g_dmServer.cvEnableColorNicks.BoolValue;
	g_dmServer.bEnableDemos = g_dmServer.cvEnableDemos.BoolValue;
	g_dmServer.bEnableInvisible = g_dmServer.cvEnableInvisible.BoolValue;
	g_dmServer.bEnableJumpBoost = g_dmServer.cvEnableJumpBoost.BoolValue;
	g_dmServer.bEnableLongJump = g_dmServer.cvEnableLongJump.BoolValue;
	g_dmServer.bEnableNicknames = g_dmServer.cvEnableNicknames.BoolValue;
	g_dmServer.bUseSourceMenus = g_dmServer.cvUseSourceMenus.BoolValue;
	
	g_dmServer.cvAllowPrivateMatches.AddChangeHook(OnConVarsChanged);
	g_dmServer.cvAchivements.AddChangeHook(OnConVarsChanged);
	g_dmServer.cvDisableChatAdverts.AddChangeHook(OnConVarsChanged);
	g_dmServer.cvEnableColorNicks.AddChangeHook(OnConVarsChanged);
	g_dmServer.cvEnableDemos.AddChangeHook(OnConVarsChanged);
	g_dmServer.cvEnableInvisible.AddChangeHook(OnConVarsChanged);
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
	g_dmWeapons.cvCrowbarDamage = CreateConVar("kdm_wep_crowbar_damage", "1000", "The damage the crowbar will do.");
	
	g_dmWeapons.bAllowRPG = g_dmWeapons.cvAllowRPG.BoolValue;
	g_dmWeapons.iCrowbarDamage = g_dmWeapons.cvCrowbarDamage.IntValue;
	
	g_dmWeapons.cvAllowRPG.AddChangeHook(OnConVarsChanged);
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
	if(!FileExists(g_sAchievementsDatabase))
	{
		g_dmServer.bDisableAchievements = false;
	}
	
	BuildPath(Path_SM, g_dmServer.sAdvertisementsDB, PLATFORM_MAX_PATH, "data/kingsdeathmatch/advertisements.txt");
	if(!FileExists(g_sAdvertisementsDatabase))
	{
		g_dmServer.bDisableChatAdverts = false;
	}
	
	BuildPath(Path_SM, g_dmServer.sClientsDB, PLATFORM_MAX_PATH, "data/kingsdeathmatch/clients.txt");
	
	BuildPath(Path_SM, g_dmServer.sModelsDB, PLATFORM_MAX_PATH, "data/kingsdeathmatch/models.txt");
	if(!FileExists(g_sModelsDatabase))
	{
		g_dmServer.bEnableModels = false;
	}
	
	//Libraries:
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	
	//Server:
	//Advertisements:
	g_dmServer.kvAdvertisements = new KeyValues("Advertisements");
	
	g_dmServer.Advertisements.ImportFromFile(g_dmServer.sAdvertisementsDB);
	
	//Gamemode Description:
	SteamWorks_SetGameDescription("King's DM");
}
