#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "RockZehh"
#define PLUGIN_VERSION "1.0.0"

#define MAX_BUTTONS 26

#include <sourcemod>
#include <sdktools>
#include <buttondetector>

#pragma newdecls required

Handle g_hOnButtonPressed;
Handle g_hOnButtonReleased;

int g_iLastButton[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Button Detector", 
	author = PLUGIN_AUTHOR, 
	description = "This is a super simple plugin that detects button presses and releases.", 
	version = PLUGIN_VERSION, 
	url = "https://github.com/rockzehh/kings-deathmatch"
};

public void OnPluginStart()
{
	g_hOnButtonPressed = CreateGlobalForward("OnButtonPressed", ET_Hook, Param_Cell, Param_Cell);
	g_hOnButtonReleased = CreateGlobalForward("OnButtonReleased", ET_Hook, Param_Cell, Param_Cell);
}

public void OnClientPutInServer(int iClient)
{
	g_iLastButton[iClient] = 0;
}

public void OnClientDisconnect(int iClient)
{
	g_iLastButton[iClient] = 0;
}

//Plugin Forwards:
public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVel[3], float fAngles[3], int &iWeapon, int &iSubtype, int &iCmdnum, int &iTickcount, int &iSeed, int iMouse[2])
{
	for (int i = 0; i < MAX_BUTTONS; i++)
	{
		int iButton = (1 << i);
		
		if ((iButtons & iButton) && !(g_iLastButton[iClient] & iButton))
		{
			Call_StartForward(g_hOnButtonPressed);
			
			Call_PushCell(iClient);
			Call_PushCell(iButton);
			
			Call_Finish();
		}
		
		if ((g_iLastButton[iClient] & iButton) && !(iButtons & iButton))
		{
			Call_StartForward(g_hOnButtonReleased);
			
			Call_PushCell(iClient);
			Call_PushCell(iButton);
			
			Call_Finish();
		}
	}
	
	g_iLastButton[iClient] = iButtons;
}
