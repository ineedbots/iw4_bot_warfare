#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

init()
{
	setDvarIfUninitialized( "g_inactivitySpectator", 0.0 );
	level.inactivitySpectator = getDvarFloat("g_inactivitySpectator") * 1000;

	if (level.inactivitySpectator <= 0)
		return;

	thread watchPlayers();
}

watchPlayers()
{
	for(;;)
	{
		wait 1.5;

		theTime = getTime();

		for (i = 0; i < level.players.size; i++)
		{
			player = level.players[i];

			if (player.hasSpawned)
				continue;

			if (!isDefined(player.specTime))
			{
				player.specTime = theTime;
				continue;
			}

			if ((theTime - player.specTime) < level.inactivitySpectator)
				continue;

			kick( player getEntityNumber(), "EXE_PLAYERKICKED_INACTIVE" );
		}
	}
}
