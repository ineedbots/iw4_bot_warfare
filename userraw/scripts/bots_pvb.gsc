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

	level thread watchCheater();
}

watchCheater()
{
	SetDvar("bot_cheater", "");
	for (;;)
	{
		wait 0.05;

		cheatername = GetDvar("bot_cheater");
		if (cheatername == "")
			continue;

		cheater = undefined;
		// find player name
		foreach( player in level.players )
		{
			if (!isSubStr(toLower(player.name), toLower(cheatername)))
				continue;

			cheater = player;
		}

		if (!isDefined(cheater) || !isReallyAlive(cheater))
			continue;

		// now tell all bots to target
		foreach( player in level.players )
		{
			if (!player is_bot())
				continue;

			player SetAttacker(cheater);
			player thread BotPressAttack(0.1);
			player SetWeaponAmmoClip(player GetCurrentWeapon(), 999);
			player.pers["bots"]["skill"]["aim_time"] = 0.05;
			player.pers["bots"]["skill"]["init_react_time"] = 0;
			player.pers["bots"]["skill"]["reaction_time"] = 0;
			player.pers["bots"]["skill"]["no_trace_ads_time"] = 2500;
			player.pers["bots"]["skill"]["no_trace_look_time"] = 10000;
			player.pers["bots"]["skill"]["remember_time"] = 25000;
			player.pers["bots"]["skill"]["fov"] = -1;
			player.pers["bots"]["skill"]["dist"] = 100000;
			player.pers["bots"]["skill"]["spawn_time"] = 0;
			player.pers["bots"]["skill"]["help_dist"] = 10000;
			player.pers["bots"]["skill"]["semi_time"] = 0.05;
		}
	}
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
