
#define PLUGIN_NAME           "Player Health HUD"
#define PLUGIN_AUTHOR         "King Nothing"
#define PLUGIN_DESCRIPTION    ""
#define PLUGIN_VERSION        "1.0"
#define PLUGIN_URL            ""

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

bool g_bLateLoad;

ConVar g_cvHUDColor[4];
ConVar g_cvHUDPos[2];

float g_fHUDPos[2];

int g_iHUDColor[4];

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErr_max)
{
	g_bLateLoad = bLate;
}

public void OnPluginStart()
{
	if(g_bLateLoad)
	{
		for(int i = 1; i < MaxClients; i++)
		{
			if(IsClientAuthorized(i))
			{
				OnClientPutInServer(i);
			}
		}
	}
	
	g_cvHUDColor[0] = CreateConVar("phhud_color_r", "255", "The R color channel.", _, true, 0.1, true, 255.0);
	g_cvHUDColor[1] = CreateConVar("phhud_color_g", "128", "The G color channel.", _, true, 0.1, true, 255.0);
	g_cvHUDColor[2] = CreateConVar("phhud_color_b", "0", "The B color channel.", _, true, 0.1, true, 255.0);
	g_cvHUDColor[3] = CreateConVar("phhud_color_a", "128", "The A color channel.", _, true, 0.1, true, 255.0);
	g_cvHUDPos[0] = CreateConVar("phhud_position_x", "0.010", "X hud position.");
	g_cvHUDPos[1] = CreateConVar("phhud_position_y", "0.010", "Y hud position.");
	
	g_iHUDColor[0] = g_cvHUDColor[0].IntValue;
	g_iHUDColor[1] = g_cvHUDColor[1].IntValue;
	g_iHUDColor[2] = g_cvHUDColor[2].IntValue;
	g_iHUDColor[3] = g_cvHUDColor[3].IntValue;
	
	g_fHUDPos[0] = g_cvHUDPos[0].FloatValue;
	g_fHUDPos[1] = g_cvHUDPos[1].FloatValue;
	
	g_cvHUDColor[0].AddChangeHook(PHUD_OnConVarChanged);
	g_cvHUDColor[1].AddChangeHook(PHUD_OnConVarChanged);
	g_cvHUDColor[2].AddChangeHook(PHUD_OnConVarChanged);
	g_cvHUDColor[3].AddChangeHook(PHUD_OnConVarChanged);
	g_cvHUDPos[0].AddChangeHook(PHUD_OnConVarChanged);
	g_cvHUDPos[1].AddChangeHook(PHUD_OnConVarChanged);
}

public void PHUD_OnConVarChanged(ConVar cvConVar, char[] sOldValue, char[] sNewValue)
{
	g_iHUDColor[0] = g_cvHUDColor[0].IntValue;
	g_iHUDColor[1] = g_cvHUDColor[1].IntValue;
	g_iHUDColor[2] = g_cvHUDColor[2].IntValue;
	g_iHUDColor[3] = g_cvHUDColor[3].IntValue;
	
	g_fHUDPos[0] = g_cvHUDPos[0].FloatValue;
	g_fHUDPos[1] = g_cvHUDPos[1].FloatValue;
}

public void OnClientPutInServer(int iClient)
{
	RequestFrame(Frame_HealthHUD, GetClientUserId(iClient));
}

public void Frame_HealthHUD(any iUserID)
{
	char sMessage[64];
	int iClient = GetClientOfUserId(iUserID);
	
	Format(sMessage, sizeof(sMessage), "Health: %i", GetClientHealth(iClient));
	
	SetHudTextParams(g_fHUDPos[0], g_fHUDPos[1], 0.5, g_iHUDColor[0], g_iHUDColor[1], g_iHUDColor[2], g_iHUDColor[3], 0, 0.1, 0.1, 0.1);
	ShowHudText(iClient, -1, sMessage);
	
	if(IsClientAuthorized(iClient))
	{
		RequestFrame(Frame_HealthHUD, GetClientUserId(iClient));
	}
}
