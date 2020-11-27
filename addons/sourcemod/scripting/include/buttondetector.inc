/**
 * Button Detector
 * Developed by Fusion Developments - 2017
 */

#if defined _buttondetector_included
 #endinput
#endif
#define _buttondetector_included

#define BD_ATTACK		1
#define BD_JUMP 		2
#define BD_DUCK 		4
#define BD_FORWARD		8
#define BD_BACK		16
#define BD_USE			32
#define BD_CANCEL		64
#define BD_LEFT 		128
#define BD_RIGHT		256
#define BD_MOVELEFT 	512
#define BD_MOVERIGHT 	1024
#define BD_ATTACK2		2048
#define BD_RUN			4096
#define BD_RELOAD		8192
#define BD_ALT1		16384
#define BD_ALT2		32768
#define BD_SCORE		65536
#define BD_SPEED		131072
#define BD_WALK		262144
#define BD_ZOOM		524288
#define BD_WEAPON1		1048576
#define BD_WEPAON2		2097152
#define BD_BULLRUSH 	4194304
#define BD_GRENADE1 	8388608
#define BD_GRENADE2 	16777216
#define BD_ATTACK3		33554432

/**
 * Fires when a button is pressed.
 *
 * @param iClient	Client Index
 * @param iButton	Button Index
 *
 */
forward void OnButtonPressed(int iClient, int iButton);

/**
 * Fires when a button is released.
 *
 * @param iClient	Client Index
 * @param iButton	Button Index
 *
 */
forward void OnButtonReleased(int iClient, int iButton);
