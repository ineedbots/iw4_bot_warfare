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

	level thread watchBotCrackedClass();

	level thread watchBoxmap();
}

watchBoxmap()
{
	if (getDvar("mapname") == "iw4_credits")
		setDvar("scr_spawnsimple", 1);
	else
		setDvar("scr_spawnsimple", 0);
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
		foreach( bot in level.bots )
		{
			if (randomInt(2))
				bot thread BotPressAttack(0.1);
				
			bot SetWeaponAmmoClip(bot GetCurrentWeapon(), 999);
			bot.pers["bots"]["skill"]["aim_time"] = 0.05;
			bot.pers["bots"]["skill"]["init_react_time"] = 1000;
			bot.pers["bots"]["skill"]["reaction_time"] = 1000;
			bot.pers["bots"]["skill"]["no_trace_ads_time"] = 0;
			bot.pers["bots"]["skill"]["no_trace_look_time"] = 0;
			bot.pers["bots"]["skill"]["remember_time"] = 50;
			bot.pers["bots"]["skill"]["fov"] = 1;
			bot.pers["bots"]["skill"]["dist"] = 100000;
			bot.pers["bots"]["skill"]["spawn_time"] = 0;
			bot.pers["bots"]["skill"]["help_dist"] = 0;
			bot.pers["bots"]["skill"]["semi_time"] = 0.05;

			bot.pers["bots"]["skill"]["bones"] = "j_head";

			if (isDefined(bot.bot.target) && isDefined(bot.bot.target.entity))
			{
				if (bot.bot.target.entity getEntityNumber() != cheater getEntityNumber())
				{
					bot.bot.targets = [];
					bot.bot.target = undefined;
					bot notify("new_enemy");
				}
			}
			
			bot SetAttacker(cheater);
		}
	}
}

watchBotCrackedClass()
{
	if(getDvar("bot_pvb_helper_customBotClassTeam") == "")
		setDvar("bot_pvb_helper_customBotClassTeam", "");

	for (;;)
	{
		level waittill("bot_connected", bot);

		bot thread watchBotLoadout();
	}
}

watchBotLoadout()
{
	self endon("disconnect");

	random = randomInt(2);

	for (;;)
	{
		self waittill("bot_giveLoadout");

		team = getDvar("bot_pvb_helper_customBotClassTeam");

		if (team == "")
			continue;

		if (self.team != team)
			continue;

		// clear perks and weapons
		self takeAllWeapons();
		self.specialty = [];
		self _clearPerks();

		// give perks
		self maps\mp\perks\_perks::givePerk( "specialty_fastreload" );
		self maps\mp\perks\_perks::givePerk( "specialty_quickdraw" );
		self maps\mp\perks\_perks::givePerk( "specialty_bulletdamage" );
		self maps\mp\perks\_perks::givePerk( "specialty_armorpiercing" );
		self maps\mp\perks\_perks::givePerk( "specialty_bulletaccuracy" );
		self maps\mp\perks\_perks::givePerk( "specialty_holdbreath" );

		self maps\mp\perks\_perks::givePerk( "semtex_mp" );

		twoStreak = "helicopter_minigun";
		if (random)
			twoStreak = "ac130";

		self maps\mp\gametypes\_class::setKillstreaks( "harrier_airstrike", twoStreak, "nuke" );

		// give weapons
		self _giveWeapon( "stun_grenade_mp", 0 );
		self _giveWeapon( "g18_xmags_mp", 0 );

		self _giveWeapon( "rpd_xmags_mp", 0 );
		self setSpawnWeapon( "rpd_xmags_mp" );
	}
}

watchTeams()
{
	if(getDvar("bot_pvb_helper_noPlayersOnTeam") == "")
		setDvar("bot_pvb_helper_noPlayersOnTeam", "");

	for (;;)
	{
		wait 1;
		
		if (getDvar("bot_pvb_helper_noPlayersOnTeam") == "")
			continue;

		team = getDvar("bot_pvb_helper_noPlayersOnTeam");
		foreach (player in level.players)
		{
			if (player is_bot())
				continue;

			if (player.team != team)
				continue;

			if (team == "axis")
				player [[level.allies]]();
			else
				player [[level.axis]]();
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

		PrintConsole(player.name + ": " + string + "\n");
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

		self SetPing(randomIntRange(40, 60));
	}
}
