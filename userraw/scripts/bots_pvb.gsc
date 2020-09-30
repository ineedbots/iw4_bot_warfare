#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include maps\mp\bots\_bot_utility;

init()
{
	level thread onBotConnected();

	level thread onSomeoneSaid();

	level thread onBotSayVar();

	level thread watchTeams();
}

watchTeams()
{
	for (;;)
	{
		wait 1;

		foreach (player in level.players)
		{
			if (player.team == "axis" && !player is_bot())
				player [[level.allies]]();
		}
	}
}

onBotSayVar()
{
	SetDvar("bot_say", "");
	for (;;)
	{
		wait 0.05;

		toSay = GetDvar("bot_say");
		if (toSay == "")
			continue;

		bot = random(getBotArray());

		if (!isDefined(bot))
			continue;

		SetDvar("bot_say", "");
		bot sayall(toSay);
	}
}

onSomeoneSaid()
{
	for (;;)
	{
		level waittill("say", string, player);

		//PrintConsole(player.name + ": " + string + "\n");
	}
}

onBotConnected()
{
	for (;;)
	{
		level waittill("bot_connected", bot);

		bot thread setBotPing();
	}
}

setBotPing()
{
	self endon("disconnect");

	for (;;)
	{
		wait 0.05;

		//self SetPing(randomIntRange(40, 60));
	}
}
