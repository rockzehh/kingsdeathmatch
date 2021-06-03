//King's Deathmatch: Developed by King Nothing.
#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR         "RockZehh"
#define PLUGIN_VERSION        "1.4.0"

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
public void OnLibraryAdded(const char[] sName)
{
	if (StrEqual(sName, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_HL2DM)
	SetFailState("This plugin is for Half-Life 2: Deathmatch only.");
	
	CreateConVar("kings-deathmatch", "1", "Notifies the server that the plugin is running.");
	CreateConVar("kdm_plugin_version", PLUGIN_VERSION, "The version of the plugin the server is running.");
	
	CreateConVar("kdm_chat_disable_advertisements", "0", "Decides if chat advertisements should be displayed.", _, true, 0.1, true, 1.0);
	CreateConVar("kdm_colornickname_enable", "1", "Decides if colored nicknames are enabled.", _, true, 0.1, true, 1.0);
	CreateConVar("kdm_colornickname_price", "25000", "The amount of credits you need to buy the colored nickname.");
	CreateConVar("kdm_demos_enable", "1", "Decides if the SourceTV demo recording is enabled.", _, true, 0.1, true, 1.0);
	CreateConVar("kdm_healthboost_amount", "75", "The amount of health the health boost will do.");
	CreateConVar("kdm_healthboost_price", "350", "The amount of credits you need to pay to use the health boost.");
	CreateConVar("kdm_invisible_enable", "1", "Decides if the invisiblity effect is enabled.", _, true, 0.1, true, 1.0);
	CreateConVar("kdm_invisible_price", "500", "The amount of credits you need to pay to use the invisible effect.");
	CreateConVar("kdm_jetpack_enable", "1", "Decides if the jetpack module is enabled.", _, true, 0.1, true, 1.0);
	CreateConVar("kdm_jumpboost_amount", "500.0", "The added jump velocity.");
	CreateConVar("kdm_jumpboost_enable", "1", "Decides if the jump boost module is enabled.", _, true, 0.1, true, 1.0);
	CreateConVar("kdm_jumpboost_price", "1750", "The amount of credits you need to pay to use the jump boost module.");
	CreateConVar("kdm_longjump_enable", "1", "Decides if the long jump module is enabled.", _, true, 0.1, true, 1.0);
	CreateConVar("kdm_longjump_play_sound", "1", "Decides if to play the long jump sound.", _, true, 0.1, true, 1.0);
	CreateConVar("kdm_longjump_price", "2500", "The amount of credits you need to pay to use the long jump module.");
	CreateConVar("kdm_longjump_push_force", "650.0", "The amount of force that the long jump does.");
	CreateConVar("kdm_nickname_enable", "1", "Decides if nicknames are enabled.", _, true, 0.1, true, 1.0);
	CreateConVar("kdm_player_alternatedamage", "0", "Decides if the players have alternate damage.", _, true, 0.1, true, 1.0);
	CreateConVar("kdm_player_custom_fov", "115", "The custom FOV value.");
	CreateConVar("kdm_player_custom_fov_enable", "1", "Decides to use the custom FOV on the players.", _, true, 0.1, true, 1.0);
	CreateConVar("kdm_player_damage_modifier", "0.5", "Damage modifier. A better description will be added.");
	CreateConVar("kdm_player_hud_showallkills", "1", "Shows the stats for the players overall kills.", _, true, 0.1, true, 1.0);
	CreateConVar("kdm_player_jump_velocity", "100.0", "The default jump velocity.");
	CreateConVar("kdm_player_model_change", "1", "Decides if the player can change their model.", _, true, 0.1, true, 1.0);
	CreateConVar("kdm_player_nofalldamage", "1", "Decides if to disable fall damage.", _, true, 0.1, true, 1.0);
	CreateConVar("kdm_player_start_fov", "20", "The custom start animation FOV value.");
	CreateConVar("kdm_player_start_health", "175", "The start player health.");
	CreateConVar("kdm_player_tposefix", "0", "Decides if to fix the T-Pose falling glitch.", _, true, 0.1, true, 1.0);
	CreateConVar("kdm_server_allow_private_matches", "1", "If users can start a private match.", _, true, 0.1, true, 1.0);
	CreateConVar("kdm_server_usesourcemenus", "0", "Decides to use the chat option or the menu system.", _, true, 0.1, true, 1.0);
	CreateConVar("kdm_wep_allow_rpg", "0", "Decides if the RPG is allowed to spawn.", _, true, 0.1, true, 1.0);
	CreateConVar("kdm_wep_crowbar_damage", "500", "The damage the crowbar will do.");
	
	FindConVar("sv_password");
	FindConVar("tv_enable");
	FindConVar("tv_autorecord");
	FindConVar("tv_maxclients");
	FindConVar("tv_name");
}

