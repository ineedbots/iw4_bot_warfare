#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include maps\mp\bots\_bot_utility;

init()
{
	setDvarIfUninitialized( "bots_test", true );

	if (!getDvarInt("bots_test"))
		return;

	level thread onConnected();
}

onConnected()
{
	for (;;)
	{
		level waittill("connected", player);

		player thread test();
	}
}

test()
{
	self endon("disconnect");

	for (;;)
	{
		wait 0.05;

		if (self is_bot())
		{
		}
		else
		{
		}
	}
}
