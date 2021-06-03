//King's Deathmatch: Developed by King Nothing.
#pragma semicolon 1

#define DEBUG

#define PLUGIN_NAME           "King's Deathmatch"
#define PLUGIN_AUTHOR         "RockZehh"
#define PLUGIN_DESCRIPTION    "A custom deathmatch plugin for Half-Life 2: Deathmatch."
#define PLUGIN_VERSION        "1.4.0"
#define PLUGIN_URL            "https://github.com/rockzehh/kings-deathmatch"

#include <discord>
#include <geoip>
//#include <kingsdeathmatch>
#include <morecolors>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <smlib>
#undef REQUIRE_PLUGIN
#include <updater>

#pragma newdecls required

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

#define UPDATE_URL	"https://raw.githubusercontent.com/rockzehh/kingsdeathmatch/master/addons/sourcemod/updater.txt"

//Global Variables:
//Booleans:
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

//ConVars:
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

//Floats:
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

//Handles:
Handle g_hAdvertisements;
Handle g_hStatHud[MAXPLAYERS + 1];

//Integers:
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

//KeyValues:
KeyValues g_kvAdvertisements;

//Strings:
char g_sAdvertisementsDatabase[PLATFORM_MAX_PATH];
char g_sClientsDatabase[PLATFORM_MAX_PATH];
char g_sDefaultWeapon[MAXPLAYERS + 1][64];
char g_sMap[128];
char g_sModelName[MAXPLAYERS + 1][64];
char g_sModelsDatabase[PLATFORM_MAX_PATH];
char g_sNicknameColor[MAXPLAYERS + 1][MAX_NAME_LENGTH];
char g_sNicknameText[MAXPLAYERS + 1][MAX_NAME_LENGTH];
char g_sServerPassword[128];

//Plugin Information:
public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

//Functions:
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

public void OnConVarsChanged(ConVar cvConVar, char[] sOldValue, char[] sNewValue)
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

public void OnLibraryAdded(const char[] sName)
{
	if (StrEqual(sName, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
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

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_HL2DM)
		SetFailState("This plugin is for the game HL2DM only.");
	
}

