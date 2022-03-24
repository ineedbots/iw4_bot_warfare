#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include maps\mp\bots\_bot_utility;

init()
{
	setDvarIfUninitialized( "bots_sniperLoadout", false );
	setDvarIfUninitialized( "bots_oneHardIsSniper", false );

	level thread onBotConnected();

	level thread watchOneHardIsSniper();
}

onBotConnected()
{
	for ( ;; )
	{
		level waittill( "bot_connected", bot );

		bot thread onBotGivenLoadout();
	}
}

onBotGivenLoadout()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		self waittill( "bot_giveLoadout", allowCopycat );

		if ( !getDvarInt( "bots_sniperLoadout" ) )
			continue;

		self give_sniper_loadout();
	}
}

watchOneHardIsSniper()
{
	for(;;)
	{
		wait 1;

		if ( !getDvarInt( "bots_oneHardIsSniper" ) )
			continue;

		foreach (bot in level.bots)
		{
			if (bot.pers["bots"]["skill"]["base"] >= 7)
			{
				if (isAlive(bot) && !bot.isSniper)
					bot give_sniper_loadout();

				break;
			}
		}
	}
}

give_sniper_loadout()
{
	self.pers["bots"]["behavior"]["quickscope"] = true;

	// clear perks and weapons
	self takeAllWeapons();
	self.specialty = [];
	self _clearPerks();
	self maps\mp\gametypes\_class::_detachAll();

	// give perks
	self maps\mp\perks\_perks::givePerk( "specialty_fastreload" );
	self maps\mp\perks\_perks::givePerk( "specialty_quickdraw" );
	self maps\mp\perks\_perks::givePerk( "specialty_bulletdamage" );
	self maps\mp\perks\_perks::givePerk( "specialty_armorpiercing" );
	self maps\mp\perks\_perks::givePerk( "specialty_bulletaccuracy" );
	self maps\mp\perks\_perks::givePerk( "specialty_holdbreath" );

	// give weapons
	self _giveWeapon( "usp_mp", 0 );
	self SetWeaponAmmoClip( "usp_mp", 0 );
	self SetWeaponAmmoStock( "usp_mp", 0 );

	self _giveWeapon( "cheytac_mp", 0 );
	self setSpawnWeapon( "cheytac_mp" );

	// make into sniper model
	if ( level.environment != "" )
		self [[game[self.team + "_model"]["GHILLIE"]]]();
	else
		self [[game[self.team + "_model"]["SNIPER"]]]();

	self.isSniper = true;
}
