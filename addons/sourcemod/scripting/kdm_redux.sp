//King's Deathmatch - Redux: Developed by King Nothing/RockZehh.
//Other smaller code is sourced by various coders.
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

#define UPDATE_URL	"https://raw.githubusercontent.com/rockzehh/kingsdeathmatch/master/addons/sourcemod/kdmredux_updater.upd"

bool g_bAllowPrivateMatches;
bool g_bAllowRPG;
bool g_bChangeFOV;
bool g_bDisableAdvertisements;
bool g_bDisableFallDamage;
bool g_bEnableColoredNicknames;
bool g_bEnableJumpBoost;
bool g_bEnableLongJump;
bool g_bEnableLongJumpSound;
bool g_bEnableModelChange;
bool g_bEnableNicknames;
bool g_bHasColoredNickname[MAXPLAYERS + 1];
bool g_bHasGodMode[MAXPLAYERS + 1];
bool g_bHasProtection[MAXPLAYERS + 1];
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
bool g_bUsingJump[MAXPLAYERS + 1];

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
ConVar g_cvUpgradePriceHealthBoost;
ConVar g_cvUpgradePriceJumpBoost;
ConVar g_cvUpgradePriceLongJump;
ConVar g_cvUseSourceMenus;

enum struct Nicknames
{
	char Nickname[MAX_NAME_LENGTH];
	char NicknameColor[128];
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
	int CurrentStreak;
	int Deaths;
	int Headshots;
	int Kills;
}

float g_fCombineBallFireCooldown;
float g_fDefaultJumpVelocity;
float g_fJumpBoostVelocity;
float g_fLastCombineBallFireTime[MAXPLAYERS + 1];
float g_fLongJumpVelocity;

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
int g_iStartingHealth;
int g_iUpgrade_Prices[] =
{
	350, //Health Boost
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

//Events:
public Action Event_DisableGameEventMessages(Event eEvent, char[] sName, bool bDontBroadcast)
{
	bDontBroadcast = true;
}

public Action Event_PlayerDeath(Event eEvent, char[] sName, bool bDontBroadcast)
{
	char sWeapon[64];
	
	int iAttacker = GetClientOfUserId(eEvent.GetInt("attacker"));
	int iClient = GetClientOfUserId(eEvent.GetInt("userid"));
	
	eEvent.GetString("weapon", sWeapon, sizeof(sWeapon));
	
	g_fLastCombineBallFireTime[iClient] = GetGameTime();
	
	Client_SetFOV(iClient, 75);
	
	if(IsClientSourceTV(iClient))
	{
		g_ptPointType[iAttacker].AllHitBot++;
	}
	
	RequestFrame(Frame_IgniteRagdoll, GetClientUserId(iClient));
	
	g_iZoomStatus[iClient] = ZOOM_NONE;
	
	if(Client_GetScore(iAttacker) >= FindConVar("mp_fraglimit").IntValue)
	{
		g_ptPointType[iAttacker].AllPerfectMaps++;
	}
	
	SendDeathMessage(iClient, iAttacker, sWeapon);
	
	SaveClient(iAttacker);
	SaveClient(iClient);
}

public Action Event_PlayerSpawn(Event eEvent, char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(eEvent.GetInt("userid"));
	
	RequestFrame(Frame_GiveGuns, GetClientUserId(iClient));
	
	RequestFrame(Frame_SetModel, GetClientUserId(iClient));
	
	RequestFrame(Frame_SpawnProtection, GetClientUserId(iClient));
	
	Client_SetFOV(iClient, g_iDefaultFOV);
	
	SetEntityHealth(iClient, g_iStartingHealth);
}

//Forwards:
public void KDM_OnConVarChanged(ConVar cvConVar, char[] sOldValue, char[] sNewValue)
{
	g_bAllowPrivateMatches = g_cvAllowPrivateMatches.BoolValue;
	g_bAllowRPG = g_cvAllowRPG.BoolValue;
	g_fCombineBallFireCooldown = g_cvCombineBallCooldown.FloatValue;
	g_iCrowbarDamage = g_cvCrowbarDamage.IntValue;
	g_iDamageLevel = g_cvDamageLevel.IntValue;
	g_iDefaultFOV = g_cvDefaultFOV.IntValue;
	g_fDefaultJumpVelocity = g_cvDefaultJumpVelocity.FloatValue;
	g_bDisableAdvertisements = g_cvDisableAdvertisements.BoolValue;
	g_bDisableFallDamage = g_cvDisableFallDamage.BoolValue;
	g_bEnableColoredNicknames = g_cvEnableColoredNicks.BoolValue;
	g_bEnableJumpBoost = g_cvEnableJumpBoost.BoolValue;
	g_bEnableLongJump = g_cvEnableLongJump.BoolValue;
	g_bEnableModelChange = g_cvEnableModelChange.BoolValue;
	g_bEnableNicknames = g_cvEnableNicknames.BoolValue;
	g_iHealthBoostAmount = g_cvHealthBoostAmount.IntValue;
	g_fJumpBoostVelocity = g_cvJumpBoostVel.FloatValue;
	g_bPlayLongJumpSound = g_cvLongJumpSound.BoolValue;
	g_fLongJumpVelocity = g_cvLongJumpVel.FloatValue;
	SetPrivateMatch();
	g_cvSourceTV[0].BoolValue = g_cvEnableDemoRecording.BoolValue;
	g_cvSourceTV[1].BoolValue = true;
	g_cvSourceTV[2].IntValue = 0;
	g_iStartingHealth = g_cvStartHealth.IntValue;
	g_bUseTPoseFix = g_cvTPoseFix.BoolValue;
	g_bUseSourceMenus = g_cvUseSourceMenus.BoolValue;
	
	g_iUpgrade_Prices[0] = g_cvUpgradePriceHealthBoost.IntValue;
	g_iUpgrade_Prices[1] = g_cvUpgradePriceJumpBoost.IntValue;
	g_iUpgrade_Prices[2] = g_cvUpgradePriceLongJump.IntValue;
}

public void OnEntityCreated(int iEntity, char[] sClassname)
{
	if(StrEqual(sClassname, "env_sprite", false) || StrEqual(sClassname, "env_spritetrail", false))
	{
		RequestFrame(Frame_GetSpriteEntityData, EntIndexToEntRef(iEntity));
	}
	
	if(Entity_IsValid(i))
	{
		if(!g_bAllowRPG && (StrContains(sClassname, "rpg", false) != -1))
		{
			RemoveEntity(iEntity);
		}
	}
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
	CloseHamdle(g_hChatAdvertisements);
	
	g_smDeaths.Clear();
	g_smHeadshots.Clear();
	g_smKills.Clear();
}

public void OnMapStart()
{
	char sClassname[64];
	
	g_hChatAdvertisements = CreateTimer(45.0, Timer_ChatAdvertisements, _, TIMER_REPEAT);
	
	GetCurrentMap(g_sCurrentMap, sizeof(g_sCurrentMap));
	
	g_smDeaths.Clear();
	g_smHeadshots.Clear();
	g_smKills.Clear();
	
	for(int i = 0; i < GetMaxEntities() * 2; i++)
	{
		if(Entity_IsValid(i))
		{
			GetEntityClassname(i, sClassname, sizeof(sClassname));
			
			if(!g_bAllowRPG && (StrContains(sClassname, "rpg", false) != -1))
			{
				RemoveEntity(i);
			}
		}
	}
	
	SetPrivateMatch();
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVel[3], float fAngles[3], int &iWeapon, int &iSubtype, int &iCmdnum, int &iTickcount, int &iSeed, int iMouse[2])
{
	char sWeapon[64];
	float fVelocity[3];
	int iFlags;
	
	if(IsPlayerAlive(iClient))
	{
		iFlags = GetEntityFlags(iClient);
		GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", fVelocity);
		Client_GetWeapon(iClient, sWeapon);
		
		if(StrEqual(sWeaponClass, "weapon_ar2") && (iButtons & IN_ATTACK2))
		{
			if(g_fLastCombineBallFireTime[iClient] + g_fCombineBallFireCooldown <= GetGameTime())
			{
				g_fLastCombineBallFireTime[iClient] = GetGameTime();
			}else{
				if (iButtons & IN_ATTACK2)
				{
					iButtons &= ~IN_ATTACK2;
				}
			}
			
		}
		
		if(g_bInDeveloperMode[iClient])
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
		
		for (int i = 0; i < MAX_GAME_BUTTONS; i++)
		{
			int iButton = (1 << i);
			
			if((iButtons & iButton) && !(g_bLastPressedButton[iClient] & iButton))
			{
				if(!g_bUsingJump[iClient] && (iButtons & IN_JUMP) && (iFlags & FL_ONGROUND))
				{
					fVelocity[2] += g_bJumpBoost[iClient][1] ? g_fJumpBoostVelocity : g_fDefaultJumpVelocity;
					
					TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, fVelocity);
					
					g_bUsingJump[iClient] = true;
				}
				
				if(!g_bUsingJump[iClient] && g_bEnableLongJump && g_bLongJump[iClient][1] && (iButtons & IN_DUCK) && (iButtons & IN_JUMP) && (iFlags & FL_ONGROUND))
				{
					UseLongJump(iClient, fVelocity);
					
					g_bUsingJump[iClient] = true;
				}
			}
			
			if ((g_iLastPressedButton[iClient] & iButton) && !(iButtons & iButton))
			{
				if((iButton & IN_JUMP) && g_bUsingJump[iClient])
				{
					g_bUsingJump[iClient] = false;
				}
			}
		}
		
		//Shotgun altfire lagcomp fix by V952.
		int iActiveWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
		
		if(IsValidEdict(iActiveWeapon))
		{
			if(StrEqual(sWeapon, "weapon_shotgun") && (iButtons & IN_ATTACK2) == IN_ATTACK2)
			{
				iButtons |= IN_ATTACK;
			}
		}
		
		if(g_bHasProtection[iClient] && g_fSpawnTime[iClient] + 0.2 <= GetGameTime())
		{
			CheckClientSpawnProtection(iClient, iButtons);
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
		
		//Thank you to utHarper for the FOV fix! (https://raw.githubusercontent.com/utharper/sourcemod-hl2dm/master/addons/sourcemod/scripting/xfov.sp)
		if(g_iZoomStatus[iClient] == ZOOM_XBOW || g_iZoomStatus[iClient] == ZOOM_TOGL)
		{
			iButtoms &= ~IN_ZOOM;
		}
		
		if(g_iZoomStatus[iClient] == ZOOM_TOGL)
		{
			if(StrEqual(sWeapon, "weapon_crossbow"))
			{
				iButtoms &= ~IN_ATTACK2;
			}
			
			SetEntProp(iClient, Prop_Send, "m_iDefaultFOV", g_iDefaultFOV);
			
			return Plugin_Continue;
		}
		
		if(iButtons & IN_ZOOM)
		{
			if(!(g_iLastPressedButton & IN_ZOOM) && !g_iZoomStatus[iClient])
			{
				g_iZoomStatus[iClient] = ZOOM_SUIT;
			}
		}else if(g_iZoomStatus[iClient] == ZOOM_SUIT)
		{
			g_iZoomStatus[iClient] == ZOOM_NONE;
		}
		
		if((StrEqual(sWeapon, "weapon_crossbow")) && (iButtons & IN_ATTACK2) && !(g_iLastPressedButton[iClient] & IN_ATTACK2) || (!StrEqual(sWeapon, "weapon_crossbow") && g_iZoomStatus[iClient] == ZOOM_XBOX)
			{
				g_iZoomStatus[iClient] = g_iZoomStatus[iClient] == ZOOM_XBOW ? ZOOM_NONE : ZOOM_XBOW;
			}
			
			if(g_iZoomStatus[iClient] == ZOOM_NONE)
			{
				Client_SetFOV(iClient, g_iDefaultFOV);
			}
			
			g_iLastPressedButton[iClient] = iButtons;
		}
		
		return Plugin_Continue;
	}
}

public void OnPluginEnd()
{
	g_kvChatAdvertisements.Close();
	
	for(int i = 1; i < MaxClients; i++)
	{
		if(Client_IsValid(i))
		{
			OnClientDisconnect(i);
		}
	}
}

public void OnPluginStart()
{
	char sPath[PLATFORM_MAX_PATH];
	
	AddCommandListener(CMDHook_Chat, "say");
	AddCommandListener(CMDHook_Chat, "say_team");
	AddCommandListener(CMDHook_ToggleZoom, "toggle_zoom");
	
	AddDownloadPaths();
	
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
		g_bEnableModelChange = false;
	}
	
	g_kvChatAdvertisements = new KeyValues("Advertisements");
	
	g_kvChatAdvertisements.ImportFromFile(g_sDBAdvertisements);
	
	for(int i = 1; i < MaxClients; i++)
	{
		if(Client_IsValid(i))
		{
			OnClientPutInServer(i);
		}
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
	g_cvEnableColoredNicks = CreateConVar("kdm-sv_nickname_color_enable", "1", "Decides if colored nicknames are enabled.", _, true, 0.1, true, 1.0);
	g_cvEnableDemoRecording = CreateConVar("kdm-sv_record_demo", "1", "Decides if the SourceTV demo recording is enabled.", _, true, 0.1, true, 1.0);
	g_cvEnableJumpBoost = CreateConVar("kdm-sv_jumpboost_enable", "1", "Decides if the jump boost module is enabled.", _, true, 0.1, true, 1.0);
	g_cvEnableLongJump = CreateConVar("kdm-sv_longjump_enable", "1", "Decides if the long jump module is enabled.", _, true, 0.1, true, 1.0);
	g_cvEnableModelChange = CreateConVar("kdm-sv_model_change", "1", "Decides if the player can change their model.", _, true, 0.1, true, 1.0);
	g_cvEnableNicknames = CreateConVar("kdm-sv_nickname_enable", "1", "Decides if nicknames are enabled.", _, true, 0.1, true, 1.0);
	g_cvHealthBoostAmount = CreateConVar("kdm-cl_healthboost_amount", "75", "The amount of health the health boost will do.");
	g_cvJumpBoostVel = CreateConVar("kdm-cl_jumpboost_velocity", "600.0", "The added jump velocity.");
	g_cvLongJumpSound = CreateConVar("kdm-cl_longjump_sound", "1", "Decides if to play the long jump sound.", _, true, 0.1, true, 1.0);
	g_cvLongJumpVel = CreateConVar("kdm-cl_longjump_velocity", "800.0", "The added velcoity for the long jump.");
	g_cvPassword = FindConVar("sv_password");
	g_cvSourceTV[0] = FindConVar("tv_enable");
	g_cvSourceTV[1] = FindConVar("tv_autorecord");
	g_cvSourceTV[2] = FindConVar("tv_maxclients");
	g_cvStartHealth = CreateConVar("kdm-cl_start_health", "175", "The start player health.");
	g_cvTPoseFix = CreateConVar("kdm-cl_disable_tpose_glitch", "1", "Decides if to fix the T-Pose falling glitch.", _, true, 0.1, true, 1.0);
	g_cvUpgradePriceHealthBoost = CreateConVar("kdm-sv_healthboost_price", "350", "The amount of credits you need to pay to use the health boost.");
	g_cvUpgradePriceJumpBoost = CreateConVar("kdm-sv_jumpboost_price", "1750", "The amount of credits you need to pay to use the jump boost module.");
	g_cvUpgradePriceLongJump = CreateConVar("kdm-sv_longjump_price", "2500", "The amount of credits you need to pay to use the long jump module.");
	g_cvUseSourceMenus = CreateConVar("kdm-sv_use_source_menus", "0", "Decides to use the chat option or the source menu system.", _, true, 0.1, true, 1.0);
	
	CreateConVar("kdm_plugin_version", PLUGIN_VERSION, "The version of the plugin the server is running.");
	
	g_bAllowPrivateMatches = g_cvAllowPrivateMatches.BoolValue;
	g_bAllowRPG = g_cvAllowRPG.BoolValue;
	g_fCombineBallFireCooldown = g_cvCombineBallCooldown.FloatValue;
	g_iCrowbarDamage = g_cvCrowbarDamage.IntValue;
	g_iDamageLevel = g_cvDamageLevel.IntValue;
	g_iDefaultFOV = g_cvDefaultFOV.IntValue;
	g_fDefaultJumpVelocity = g_cvDefaultJumpVelocity.FloatValue;
	g_bDisableAdvertisements = g_cvDisableAdvertisements.BoolValue;
	g_bDisableFallDamage = g_cvDisableFallDamage.BoolValue;
	g_bEnableColoredNicknames = g_cvEnableColoredNicks.BoolValue;
	g_bEnableJumpBoost = g_cvEnableJumpBoost.BoolValue;
	g_bEnableLongJump = g_cvEnableLongJump.BoolValue;
	g_bEnableModelChange = g_cvEnableModelChange.BoolValue;
	g_bEnableNicknames = g_cvEnableNicknames.BoolValue;
	g_iHealthBoostAmount = g_cvHealthBoostAmount.IntValue;
	g_fJumpBoostVelocity = g_cvJumpBoostVel.FloatValue;
	g_bPlayLongJumpSound = g_cvLongJumpSound.BoolValue;
	g_fLongJumpVelocity = g_cvLongJumpVel.FloatValue;
	SetPrivateMatch();
	g_cvSourceTV[0].BoolValue = g_cvEnableDemoRecording.BoolValue;
	g_cvSourceTV[1].BoolValue = true;
	g_cvSourceTV[2].IntValue = 0;
	g_iStartingHealth = g_cvStartHealth.IntValue;
	g_bUseTPoseFix = g_cvTPoseFix.BoolValue;
	g_bUseSourceMenus = g_cvUseSourceMenus.BoolValue;
	
	g_iUpgrade_Prices[0] = g_cvUpgradePriceHealthBoost.IntValue;
	g_iUpgrade_Prices[1] = g_cvUpgradePriceJumpBoost.IntValue;
	g_iUpgrade_Prices[2] = g_cvUpgradePriceLongJump.IntValue;
	
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
	g_cvEnableJumpBoost.AddChangeHook(KDM_OnConVarChanged);
	g_cvEnableLongJump.AddChangeHook(KDM_OnConVarChanged);
	g_cvEnableModelChanger.AddChangeHook(KDM_OnConVarChanged);
	g_cvEnableNicknames.AddChangeHook(KDM_OnConVarChanged);
	g_cvHealthBoost.AddChangeHook(KDM_OnConVarChanged);
	g_cvJumpBoostVel.AddChangeHook(KDM_OnConVarChanged);
	g_cvLongJumpSound.AddChangeHook(KDM_OnConVarChanged);
	g_cvLongJumpVel.AddChangeHook(KDM_OnConVarChanged);
	g_cvPassword.AddChangeHook(KDM_OnConVarChanged);
	g_cvSourceTV[0].AddChangeHook(KDM_OnConVarChanged);
	g_cvStartHealth.AddChangeHook(KDM_OnConVarChanged);
	g_cvTPoseFix.AddChangeHook(KDM_OnConVarChanged);
	g_cvUpgradePriceHealthBoost.AddChangeHook(KDM_OnConVarChanged);
	g_cvUpgradePriceJumpBoost.AddChangeHook(KDM_OnConVarChanged);
	g_cvUpgradePriceLongJump.AddChangeHook(KDM_OnConVarChanged);
	g_cvUseSourceMenus.AddChangeHook(KDM_OnConVarChanged);
	
	HookEvent("player_changename", Event_DisableGameEventMessages, EventHookMode_Pre);
	HookEvent("player_connect", Event_DisableGameEventMessages, EventHookMode_Pre);
	HookEvent("player_connect_client", Event_DisableGameEventMessages, EventHookMode_Pre);
	HookEvent("player_disconnect", Event_DisableGameEventMessages, EventHookMode_Pre);
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	
	g_smDeaths = CreateTrie();
	g_smHeadshots = CreateTrie();
	g_smKills = CreateTrie();
	
	RegAdminCmd("devcmd_godmode", Developement_GodMode, Admin_Custom4, "Gives the developer godmode.");
	RegAdminCmd("sm_private", Command_PrivateMatch, Admin_Custom4, "Sets a password on the server.");
	RegAdminCmd("sm_privatematch", Command_PrivateMatch, Admin_Custom4, "Sets a password on the server.");
	RegAdminCmd("sm_setplayercredits", Command_SetPlayerCredits, Admin_Custom4, "Sets the players credits.");
	RegAdminCmd("sm_setplayernickcolor", Command_SetPlayerNickColor, Admin_Custom4, "Sets the players nickname color.");
	RegAdminCmd("sm_setplayernickname", Command_SetPlayerNickname, Admin_Custom4, "Sets the players nickname.");
	
	RegConsoleCmd("sm_boost", Command_HealthBoost, "Gives a boost of health to the player.");
	RegConsoleCmd("sm_changemodel", Command_ChangeModel, "Changes the players model.");
	RegConsoleCmd("sm_changenick", Command_ChangeNickname, "Changes the players nickname.");
	RegConsoleCmd("sm_changenickname", Command_ChangeNickname, "Changes the players nickname.");
	RegConsoleCmd("sm_credits", Command_CreditsMenu, "Brings up the credits menu to the player.");
	RegConsoleCmd("sm_creditsmenu", Command_CreditsMenu, "Brings up the credits menu to the player.");
	RegConsoleCmd("sm_default", Command_DefaultWeapon, "Sets the players default weapon.");
	RegConsoleCmd("sm_defaultweapon", Command_DefaultWeapon, "Sets the players default weapon.");
	RegConsoleCmd("sm_health", Command_HealthBoost, "Gives a boost of health to the player.");
	RegConsoleCmd("sm_healthboost", Command_HealthBoost, "Gives a boost of health to the player.");
	RegConsoleCmd("sm_hb", Command_HealthBoost, "Gives a boost of health to the player.");
	RegConsoleCmd("sm_jb", Command_JumpBoost, "Gives the players jump more velocity.");
	RegConsoleCmd("sm_jump", Command_JumpBoost, "Gives the players jump more velocity.");
	RegConsoleCmd("sm_jumpboost", Command_JumpBoost, "Gives the players jump more velocity.");
	RegConsoleCmd("sm_longjump", Command_LongJump, "Gives the players the long jump module.");
	RegConsoleCmd("sm_lj", Command_LongJump, "Gives the players the long jump module.");
	RegConsoleCmd("sm_model", Command_ChangeModel, "Changes the players model.");
	RegConsoleCmd("sm_nick", Command_ChangeNickname, "Changes the players nickname.");
	RegConsoleCmd("sm_setnick", Command_ChangeNickname, "Changes the players nickname.");
	RegConsoleCmd("sm_setnickname", Command_ChangeNickname, "Changes the players nickname.");
	RegConsoleCmd("sm_store", Command_CreditsMenu, "Brings up the credits menu to the player.");
	
	SteamWorks_SetGameDescription("King's Deathmatch");
	
	if(LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	
	//Execute plugin config.
	AutoExecConfig(true, "kdm_redux");
}

//Frames:
public void Frame_GetSpriteEntityData(int iRef) //Thanks to EasSidezz for the grenade sprite trail fix.
{
	char sClassname[2][64];
	int iGlow, iSprite = EntRefToEntIndex(iRef), iTrail;
	
	if(Entity_IsValid(iSprite))
	{
		int iGrenade = GetEntPropEnt(iSprite, Prop_Data, "m_hAttachedToEntity");
		
		if(iGrenade == -1) return;
		
		GetEdictClassname(iSprite, sClassname[0], sizeof(sClassname[]));
		
		if(StrEqual(sClassname[0], "npc_grenade_frag", false))
		{
			for(int i = MaxClients + 1; i < 2048; i++)
			{
				if(!Entity_IsValid(i)) continue;
				
				GetEdictClassname(i, sClassname[1], sizeof(sClassname[]));
				
				if(StrEqual(sClassname[1], "env_sprite", false) || StrEqual(sClassname[1], "env_spritetrail", false))
				{
					if(GetEntPropEnt(i, Prop_Data, "m_hAttachedToEntity") == iGrenade)
					{
						iGlow = GetEntPropEnt(iGrenade, Prop_Data, "m_pMainGlow");
						iTrail = GetEntPropEnt(iGrenade, Prop_Data, "m_pGlowTrail");
						
						if(i != iGlow && i != iTrail) RemoveEdict(i);
					}
				}
			}
		}
	}
	
	return;
}

public void Frame_GiveGuns(any iUserID)
{
	int iClient = GetClientOfUserId(iUserID);
	
	if(g_bIsPlayer[iClient])
	{
		GivePlayerItem(iClient, "weapon_357");
		GivePlayerItem(iClient, "weapon_ar2");
		GivePlayerItem(iClient, "weapon_crossbow");
		GivePlayerItem(iClient, "weapon_crowbar");
		GivePlayerItem(iClient, "weapon_frag");
		GivePlayerItem(iClient, "weapon_physcannon");
		GivePlayerItem(iClient, "weapon_pistol");
		GivePlayerItem(iClient, "weapon_shotgun");
		GivePlayerItem(iClient, "weapon_smg1");
		GivePlayerItem(iClient, "weapon_stunstick");
		
		if(g_bAllowRPG)
		{
			GivePlayerItem(iClient, "weapon_rpg");
		}
		
		Client_ChangeWeapon(iClient, g_sDefaultWeapon[iClient]);
		
		if(Client_GetActiveWeapon(iClient) != INVALID_ENT_REFERENCE)
		{
			ReFillWeapon(iClient, Client_GetActiveWeapon(iClient));
		}
	}
}

public void Frame_IgniteRagdoll(any iUserID)
{
	int iClient = GetClientOfUserId(iUserID);
	
	if(g_bIsPlayer[iClient])
	{
		float fForce[3], fVelocity[3];
		
		int iRagdoll = GetEntPropEnt(iClient, Prop_Send, "m_hRagdoll");
		
		GetEntPropVector(iRagdoll, Prop_Send, "m_vecForce", fForce);
		
		fForce[0] *= 15.0;
		fForce[1] *= 15.0;
		fForce[2] *= 15.0;
		
		SetEntPropVector(iRagdoll, Prop_Send, "m_vecForce", fForce);
		
		GetEntPropVector(iRagdoll, Prop_Send, "m_vecRagdollVelocity", fVelocity);
		
		fVelocity[0] *= 25.0;
		fVelocity[1] *= 25.0;
		fVelocity[2] *= 25.0;
		
		SetEntPropVector(iRagdoll, Prop_Send, "m_vecRagdollVelocity", fVelocity);
		
		IgniteEntity(iRagdoll, 5.0);
		
		CreateTimer(1.5, Timer_DissolveRagdoll, EntIndexToEntRef(iRagdoll), TIMER_DATA_HNDL_CLOSE);
	}
}

public void Frame_SetModel(any iUserID)
{
	int iClient = GetClientOfUserId(iUserID);
	
	if(g_bIsPlayer[iClient] && g_bEnableModelChange)
	{
		SetPlayerModel(iClient, g_sModelName[iClient]);
	}
}

public void Frame_SpawnProtection(any iUserID)
{
	int iClient = GetClientOfUserId(iUserID);
	
	if(g_bIsPlayer[iClient])
	{
		SetEntProp(iClient, Prop_Data, "m_takedamage", 0, 1);
		
		SetEntityRenderColor(iClient, 0, 255, 0, 128);
		SetEntityRenderFx(iClient, RENDERFX_FLICKER_FAST);
		
		g_bHasProtection[iClient] = true;
	}
}

//Stocks:
stock void CheckClientSpawnProtection(int iClient, int &iButtons)
{
	if((iButtons & IN_RUN) || (iButtons & IN_JUMP) || (iButtons & IN_DUCK) || (iButtons & IN_BACK) || (iButtons & IN_LEFT) ||
	(iButtons & IN_WALK) || (iButtons & IN_RIGHT) || (iButtons & IN_FORWARD) || (iButtons & IN_BACK) || (iButtons & IN_SPEED) ||
	(iButtons & IN_MOVELEFT) || (iButtons & IN_MOVERIGHT))
	{
		g_bHasProtection[iClient] = false;
		
		SetEntProp(iClient, Prop_Data, "m_takedamage", 2, 1);
		
		SetEntityRenderColor(iClient, 255, 255, 255, 255);
		SetEntityRenderFx(iClient, RENDERFX_NONE);
	}
}

stock int GetPlayerScoreboardPosition(int iClient) //Thanks to EasSidezz for this (https://forums.alliedmods.net/showthread.php?t=295000)
{
	int iCurrentPosition = 1, iFrags = GetClientFrags(iClient);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(Client_IsIngame(i) && Client_IsIngame(iClient) && !IsClientSourceTV(i))
		{
			if(GetClientFrags(i) > iFrags) iCurrentPosition++;
		}
	}
	
	return iCurrentPosition;
}

stock int LoadInteger(KeyValues kvVault, char[] sKey, char[] sSaveKey, int iDefaultValue)
{
	kvVault.JumpToKey(sKey, false);
	
	int iNumber = kvVault.GetNum(sSaveKey, iDefaultValue);
	
	kvVault.Rewind();
	
	return iNumber;
}

stock void LoadString(KeyValues kvVault, const char[] sKey, const char[] sSaveKey, const char[] sDefaultValue, char[] sReference, int iMaxLength)
{
	kvVault.JumpToKey(sKey, false);
	
	kvVault.GetString(sSaveKey, sReference, iMaxLength, sDefaultValue);
	
	kvVault.Rewind();
}

stock void DeathPrintToChat(int iAttacker, int iClient, int iCredits, const char[] sMessage, any ...)
{
	CCheckTrie();
	
	if(iClient <= 0 || iClient > MaxClients)
	{
		ThrowError("Invalid client index %i", iClient);
	}
	
	if(!IsClientInGame(iClient))
	{
		ThrowError("Client %i is not in game", iClient);
	}
	
	char sBuffer[MAX_BUFFER_LENGTH], sBuffer2[MAX_BUFFER_LENGTH], sTempString[MAX_BUFFER_LENGTH];
	
	SetGlobalTransTarget(iClient);
	
	Format(sBuffer, sizeof(sBuffer), "\x01%s", sMessage);
	VFormat(sBuffer2, sizeof(sBuffer2), sBuffer, 3);
	
	Format(sTempString, sizeof(sTempString), "{%s}%N{default}", StrEqual(g_nNickname[iAttacker].NicknameColor, "") ? "default" : g_nNickname[iAttacker].NicknameColor, iAttacker);
	ReplaceString(sBuffer2, sizeof(sBuffer2), "{ATTACKER}", sTempString, true);
	
	g_nNickname[iClient].NicknameColor
	
	Format(sTempString, sizeof(sTempString), "({green}%i{default} hp, {green}%i{default} suit)", GetClientHealth(iAttacker), Client_GetArmor(iAttacker));
	ReplaceString(sBuffer2, sizeof(sBuffer2), "{ATTACKERHEALTH}", sTempString, true);
	
	Format(sTempString, sizeof(sTempString), "{%s}%N{default}", StrEqual(g_nNickname[iClient].NicknameColor, "") ? "default" : g_nNickname[iClient].NicknameColor, iClient);
	ReplaceString(sBuffer2, sizeof(sBuffer2), "{CLIENT}", sTempString, true);
	
	Format(sTempString, sizeof(sTempString), "({green}+%i{default} credits)", iCredits);
	ReplaceString(sBuffer2, sizeof(sBuffer2), "{CREDITS}", sTempString, true);
	
	Format(sTempString, sizeof(sTempString), "{green}%i{default}", iCredits);
	ReplaceString(sBuffer2, sizeof(sBuffer2), "{LOSTCREDITS}", sTempString, true);
	
	CReplaceColorCodes(sBuffer2);
	CSendMessage(iClient, sBuffer2);
}

stock void RegPrintToChat(int iClient, const char[] sMessage, any ...)
{
	CCheckTrie();
	
	if(iClient <= 0 || iClient > MaxClients)
	{
		ThrowError("Invalid client index %i", iClient);
	}
	
	if(!IsClientInGame(iClient))
	{
		ThrowError("Client %i is not in game", iClient);
	}
	
	char sBuffer[MAX_BUFFER_LENGTH], sBuffer2[MAX_BUFFER_LENGTH], sTempString[MAX_BUFFER_LENGTH];
	
	SetGlobalTransTarget(iClient);
	
	Format(sBuffer, sizeof(sBuffer), "\x01%s", sMessage);
	VFormat(sBuffer2, sizeof(sBuffer2), sBuffer, 3);
	
	CReplaceColorCodes(sBuffer2);
	CSendMessage(iClient, sBuffer2);
}

stock void RegPrintToChatAll(const char[] sMessage, any ...)
{
	CCheckTrie();
	
	char sBuffer[MAX_BUFFER_LENGTH], sBuffer2[MAX_BUFFER_LENGTH];
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || CSkipList[i])
		{
			CSkipList[i] = false;
			continue;
		}
		
		SetGlobalTransTarget(i);
		
		Format(sBuffer, sizeof(sBuffer), "\x01%s", sMessage);
		VFormat(sBuffer2, sizeof(sBuffer2), sBuffer, 2);
		
		CReplaceColorCodes(sBuffer2);
		CSendMessage(i, sBuffer2);
	}
}

stock void SendClientDeathMessage(int iClient, int iAttacker, char[] sWeapon)
{
	char sAttackerColor[MAX_NAME_LENGTH], sAttackerHealth[64], sClientColor[MAX_NAME_LENGTH], sHitgroup[1];
	
	if(iClient != iAttacker)
	{
		if(iAttacker <= 0)
		{
			g_ptPointType[iClient].AllDeaths++;
			
			DeathPrintToChatAll(-1, iClient, 0, "{CLIENT} got killed by the world... somehow.");
		}else if(g_iHitgroup[iClient] > 0)
		{
			IntToString(g_iHitgroup[iClient], sHitgroup, sizeof(sHitgroup));
			
			switch(g_iHitgroup[iClient])
			{
				case HITGROUP_GENERIC:
				{
					LoadString(g_kvDeathMessages, sHitgroup, sWeapon, "", char[] sReference, int iMaxLength)
				}
				
				case HITGROUP_HEAD:
				{
					
				}
				
				case HITGROUP_CHEST:
				{
					
				}
				
				case HITGROUP_STOMACH:
				{
					
				}
				
				case HITGROUP_LEFTARM:
				{
					
				}
				
				case HITGROUP_RIGHTARM:
				{
					
				}
				
				case HITGROUP_LEFTLEG:
				{
					
				}
				
				case HITGROUP_RIGHTLEG:
				{
					
				}
			}
		}else{
			 
		}
	}
}

stock void SetPrivateMatch(bool bSet = false)
{
	char sPassword[64];
	
	g_cvPassword.GetString(sPassword, sizeof(sPassword));
	
	if(bSet)
	{
		if(StrContains(sPassword, "kings-", true) != -1 && g_bIsPrivateMatchRunning)
		{
			g_cvPassword.SetString("");
			
			g_bIsPrivateMatchRunning = false;
		}else{
			Format(sPassword, sizeof(sPassword), "kings-%i", GetRandomInt(12345, 99999));
			
			g_cvPassword.SetString(sPassword);
			
			g_bIsPrivateMatchRunning = true;
		}
	}else{
		g_bIsPrivateMatchRunning = (StrContains(sPassword, "kings-", true) != -1);
	}
}

//Timers:
public Action Timer_ChatAdvertisements(Handle hTimer)
{
	char sAdvertisement[MAX_MESSAGE_LENGTH];
	
	if(!g_bDisableAdvertisements)
	{
		KDMPrintToChatAll(sAdvertisement);
		
		//Advertisement chat sound:
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				ClientCommand(i, "play npc/stalker/stalker_footstep_%s1", view_as<bool>(GetRandomInt(0, 1)) ? "left" : "right");
			}
		}
	}
}

public Action Timer_DissolveRagdoll(Handle hTimer, any iRef)
{
	int iRagdoll = EntRefToEntIndex(iRef);
	
	DispatchKeyValue(iRagdoll, "targetname", "kdm_dissolve");
	
	AcceptEntityInput(g_iDissolver, "Dissolve");
}
