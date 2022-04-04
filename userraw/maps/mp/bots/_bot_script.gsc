/*
	_bot_script
	Author: INeedGames
	Date: 09/26/2020
	Tells the bots what to do.
	Similar to t5's _bot
*/

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\bots\_bot_utility;

/*
	When the bot gets added into the game.
*/
added()
{
	self endon( "disconnect" );

	self setPlayerData( "experience", self bot_get_rank() );
	self setPlayerData( "prestige", self bot_get_prestige() );

	self setPlayerData( "cardTitle", random( getCardTitles() ) );
	self setPlayerData( "cardIcon", random( getCardIcons() ) );

	self setClasses();
	self setKillstreaks();

	self set_diff();
}

/*
	When the bot connects to the game.
*/
connected()
{
	self endon( "disconnect" );

	self.killerLocation = undefined;
	self.lastKiller = undefined;
	self.bot_change_class = true;

	self thread difficulty();
	self thread teamWatch();
	self thread classWatch();

	self thread onBotSpawned();
	self thread onSpawned();

	self thread onDeath();
	self thread onGiveLoadout();

	self thread onKillcam();

	wait 0.1;
	self.challengeData = [];
}

/*
	Gets the prestige
*/
bot_get_prestige()
{
	p_dvar = getDvarInt( "bots_loadout_prestige" );
	p = 0;

	if ( p_dvar == -1 )
	{
		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[i];

			if ( !isDefined( player.team ) )
				continue;

			if ( player is_bot() )
				continue;

			p = player getPlayerData( "prestige" );
			break;
		}
	}
	else if ( p_dvar == -2 )
	{
		p = randomInt( 12 );
	}
	else
	{
		p = p_dvar;
	}

	return p;
}

/*
	Gets an exp amount for the bot that is nearish the host's xp.
*/
bot_get_rank()
{
	rank = 1;
	rank_dvar = getDvarInt( "bots_loadout_rank" );

	if ( rank_dvar == -1 )
	{
		ranks = [];
		bot_ranks = [];
		human_ranks = [];

		for ( i = level.players.size - 1; i >= 0; i-- )
		{
			player = level.players[i];

			if ( player == self )
				continue;

			if ( !IsDefined( player.pers[ "rank" ] ) )
				continue;

			if ( player is_bot() )
			{
				bot_ranks[ bot_ranks.size ] = player.pers[ "rank" ];
			}
			else
			{
				human_ranks[ human_ranks.size ] = player.pers[ "rank" ];
			}
		}

		if ( !human_ranks.size )
			human_ranks[ human_ranks.size ] = Round( random_normal_distribution( 45, 20, 0, level.maxRank ) );

		human_avg = array_average( human_ranks );

		while ( bot_ranks.size + human_ranks.size < 5 )
		{
			// add some random ranks for better random number distribution
			rank = human_avg + RandomIntRange( -10, 10 );
			human_ranks[ human_ranks.size ] = rank;
		}

		ranks = array_combine( human_ranks, bot_ranks );

		avg = array_average( ranks );
		s = array_std_deviation( ranks, avg );

		rank = Round( random_normal_distribution( avg, s, 0, level.maxRank ) );
	}
	else if ( rank_dvar == 0 )
	{
		rank = Round( random_normal_distribution( 45, 20, 0, level.maxRank ) );
	}
	else
	{
		rank = Round( random_normal_distribution( rank_dvar, 5, 0, level.maxRank ) );
	}

	return maps\mp\gametypes\_rank::getRankInfoMinXP( rank );
}

/*
	returns an array of all card titles
*/
getCardTitles()
{
	cards = [];

	for ( i = 0; i < 600; i++ )
	{
		card_name = tableLookupByRow( "mp/cardTitleTable.csv", i, 0 );

		if ( card_name == "" )
			continue;

		if ( !isSubStr( card_name, "cardtitle_" ) )
			continue;

		cards[cards.size] = card_name;
	}

	return cards;
}

/*
	returns an array of all card icons
*/
getCardIcons()
{
	cards = [];

	for ( i = 0; i < 300; i++ )
	{
		card_name = tableLookupByRow( "mp/cardIconTable.csv", i, 0 );

		if ( card_name == "" )
			continue;

		if ( !isSubStr( card_name, "cardicon_" ) )
			continue;

		cards[cards.size] = card_name;
	}

	return cards;
}

/*
	returns if attachment is valid with attachment 2
*/
isValidAttachmentCombo( att1, att2 )
{
	colIndex = tableLookupRowNum( "mp/attachmentCombos.csv", 0, att1 );

	if ( tableLookup( "mp/attachmentCombos.csv", 0, att2, colIndex ) == "no" )
		return false;

	return true;
}

/*
	returns all attachments for the given gun
*/
getAttachmentsForGun( gun )
{
	row = tableLookupRowNum( "mp/statStable.csv", 4, gun );

	attachments = [];

	for ( h = 0; h < 10; h++ )
	{
		attachmentName = tableLookupByRow( "mp/statStable.csv", row, h + 11 );

		if ( attachmentName == "" )
		{
			attachments[attachments.size] = "none";
			break;
		}

		attachments[attachments.size] = attachmentName;
	}

	return attachments;
}

/*
	returns all primaries
*/
getPrimaries()
{
	primaries = [];

	for ( i = 0; i < 160; i++ )
	{
		weapon_type = tableLookupByRow( "mp/statstable.csv", i, 2 );

		if ( weapon_type != "weapon_assault" && weapon_type != "weapon_riot" && weapon_type != "weapon_smg" && weapon_type != "weapon_sniper" && weapon_type != "weapon_lmg" )
			continue;

		weapon_name = tableLookupByRow( "mp/statstable.csv", i, 4 );

		primaries[primaries.size] = weapon_name;
	}

	return primaries;
}

/*
	returns all secondaries
*/
getSecondaries()
{
	secondaries = [];

	for ( i = 0; i < 160; i++ )
	{
		weapon_type = tableLookupByRow( "mp/statstable.csv", i, 2 );

		if ( weapon_type != "weapon_pistol" && weapon_type != "weapon_machine_pistol" && weapon_type != "weapon_projectile" && weapon_type != "weapon_shotgun" )
			continue;

		weapon_name = tableLookupByRow( "mp/statstable.csv", i, 4 );

		if ( weapon_name == "gl" )
			continue;

		secondaries[secondaries.size] = weapon_name;
	}

	return secondaries;
}

/*
	returns all camos
*/
getCamos()
{
	camos = [];

	for ( i = 0; i < 15; i++ )
	{
		camo_name = tableLookupByRow( "mp/camoTable.csv", i, 1 );

		if ( camo_name == "" )
			continue;

		camos[camos.size] = camo_name;
	}

	return camos;
}

/*
	returns all perks for the given type
*/
getPerks( perktype )
{
	perks = [];

	for ( i = 0; i < 50; i++ )
	{
		perk_type = tableLookupByRow( "mp/perktable.csv", i, 5 );

		if ( perk_type != perktype )
			continue;

		perk_name = tableLookupByRow( "mp/perktable.csv", i, 1 );

		if ( perk_name == "specialty_c4death" )
			continue;

		if ( perk_name == "_specialty_blastshield" )
			continue;

		perks[perks.size] = perk_name;
	}

	return perks;
}

/*
	returns kill cost for a streak
*/
getKillsNeededForStreak( streak )
{
	return int( tableLookup( "mp/killstreakTable.csv", 1, streak, 4 ) );
}

/*
	returns all killstreaks
*/
getKillstreaks()
{
	killstreaks = [];

	for ( i = 0; i < 40; i++ )
	{
		streak_name = tableLookupByRow( "mp/killstreakTable.csv", i, 1 );

		if ( streak_name == "" || streak_name == "none" )
			continue;

		if ( streak_name == "b1" )
			continue;

		if ( streak_name == "sentry" ) // theres an airdrop version
			continue;

		if ( isSubstr( streak_name, "KILLSTREAKS_" ) )
			continue;

		killstreaks[killstreaks.size] = streak_name;
	}

	return killstreaks;
}

/*
	bots chooses a random perk
*/
chooseRandomPerk( perkkind, primary, primaryAtts )
{
	perks = getPerks( perkkind );
	rank = self maps\mp\gametypes\_rank::getRankForXp( self getPlayerData( "experience" ) );
	allowOp = ( getDvarInt( "bots_loadout_allow_op" ) >= 1 );
	reasonable = getDvarInt( "bots_loadout_reasonable" );

	while ( true )
	{
		perk = random( perks );

		if ( !allowOp )
		{
			if ( perkkind == "perk4" )
				return "specialty_null";

			if ( perk == "specialty_pistoldeath" )
				continue;

			if ( perk == "specialty_coldblooded" )
				continue;

			if ( perk == "specialty_localjammer" )
				continue;
		}

		if ( reasonable )
		{
			if ( perk == "specialty_bling" )
				continue;

			if ( perk == "specialty_localjammer" )
				continue;

			if ( perk == "throwingknife_mp" )
				continue;

			if ( perk == "specialty_blastshield" )
				continue;

			if ( perk == "frag_grenade_mp" )
				continue;

			if ( perk == "specialty_copycat" )
				continue;

			if ( perkkind == "perk1" )
			{
				if ( perk == "specialty_onemanarmy" )
				{
					if ( primaryAtts[0] != "gl"/* && primaryAtts[1] != "gl"*/ )
						continue;
				}
			}

			if ( perkkind == "perk2" )
			{
				if ( perk != "specialty_bulletdamage" )
				{
					if ( perk == "specialty_explosivedamage" )
					{
						if ( primaryAtts[0] != "gl"/* && primaryAtts[1] != "gl"*/ )
							continue;
					}
					else
					{
						if ( randomInt( 100 ) < 10 )
							continue;

						if ( primary == "cheytac" )
							continue;

						if ( primary == "rpd" )
							continue;

						if ( primary == "ak47" && randomInt( 100 ) < 80 )
							continue;

						if ( primary == "aug" )
							continue;

						if ( primary == "barrett" && randomInt( 100 ) < 80 )
							continue;

						if ( primary == "tavor" && randomInt( 100 ) < 80 )
							continue;

						if ( primary == "scar" )
							continue;

						if ( primary == "masada" && randomInt( 100 ) < 60 )
							continue;

						if ( primary == "m4" && randomInt( 100 ) < 80 )
							continue;

						if ( primary == "m16" )
							continue;

						if ( primary == "fal" )
							continue;

						if ( primary == "famas" )
							continue;
					}
				}
			}
		}

		if ( perk == "specialty_null" )
			continue;

		if ( !self isItemUnlocked( perk ) )
			continue;

		if ( RandomFloatRange( 0, 1 ) < ( ( rank / level.maxRank ) + 0.1 ) )
			self.pers["bots"]["unlocks"]["upgraded_" + perk] = true;

		return perk;
	}
}

/*
	choose a random camo
*/
chooseRandomCamo()
{
	camos = getCamos();

	while ( true )
	{
		camo = random( camos );

		if ( camo == "gold" || camo == "prestige" )
			continue;

		return camo;
	}
}

/*
	choose a random primary
*/
chooseRandomPrimary()
{
	primaries = getPrimaries();
	allowOp = ( getDvarInt( "bots_loadout_allow_op" ) >= 1 );
	reasonable = getDvarInt( "bots_loadout_reasonable" );

	while ( true )
	{
		primary = random( primaries );

		if ( !allowOp )
		{
			if ( primary == "riotshield" )
				continue;
		}

		if ( reasonable )
		{
			if ( primary == "riotshield" )
				continue;

			if ( primary == "wa2000" )
				continue;

			if ( primary == "uzi" )
				continue;

			if ( primary == "sa80" )
				continue;

			if ( primary == "fn2000" )
				continue;

			if ( primary == "m240" )
				continue;

			if ( primary == "mg4" )
				continue;
		}

		if ( !self isItemUnlocked( primary ) )
			continue;

		return primary;
	}
}

/*
	choose a random secondary
*/
chooseRandomSecondary( perk1 )
{
	if ( perk1 == "specialty_onemanarmy" )
		return "onemanarmy";

	secondaries = getSecondaries();
	allowOp = ( getDvarInt( "bots_loadout_allow_op" ) >= 1 );
	reasonable = getDvarInt( "bots_loadout_reasonable" );

	while ( true )
	{
		secondary = random( secondaries );

		if ( !allowOp )
		{
			if ( secondary == "at4" || secondary == "rpg" || secondary == "m79" )
				continue;
		}

		if ( reasonable )
		{
			if ( secondary == "ranger" )
				continue;

			if ( secondary == "model1887" )
				continue;
		}

		if ( !self isItemUnlocked( secondary ) )
			continue;

		if ( secondary == "onemanarmy" )
			continue;

		return secondary;
	}
}

/*
	chooses random attachements for a gun
*/
chooseRandomAttachmentComboForGun( gun )
{
	atts = getAttachmentsForGun( gun );
	rank = self maps\mp\gametypes\_rank::getRankForXp( self getPlayerData( "experience" ) );
	allowOp = ( getDvarInt( "bots_loadout_allow_op" ) >= 1 );
	reasonable = getDvarInt( "bots_loadout_reasonable" );

	if ( RandomFloatRange( 0, 1 ) >= ( ( rank / level.maxRank ) + 0.1 ) )
	{
		retAtts = [];
		retAtts[0] = "none";
		retAtts[1] = "none";

		return retAtts;
	}

	while ( true )
	{
		att1 = random( atts );
		att2 = random( atts );

		if ( !isValidAttachmentCombo( att1, att2 ) )
			continue;

		if ( !allowOp )
		{
			if ( att1 == "gl" || att2 == "gl" )
				continue;
		}

		if ( reasonable )
		{
			if ( att1 == "shotgun" || att2 == "shotgun" )
				continue;

			if ( att1 == "akimbo" || att2 == "akimbo" )
			{
				if ( gun != "ranger" && gun != "model1887" && gun != "glock" )
					continue;
			}

			if ( att1 == "acog" || att2 == "acog" )
				continue;

			if ( att1 == "thermal" || att2 == "thermal" )
				continue;

			if ( att1 == "rof" || att2 == "rof" )
				continue;

			if ( att1 == "silencer" || att2 == "silencer" )
			{
				if ( gun == "spas12" || gun == "aa12" || gun == "striker" || gun == "rpd" || gun == "m1014" || gun == "cheytac" || gun == "barrett" || gun == "aug" || gun == "m240" || gun == "mg4" || gun == "sa80" || gun == "wa2000" )
					continue;
			}
		}

		retAtts = [];
		retAtts[0] = att1;
		retAtts[1] = att2;

		return retAtts;
	}
}

/*
	choose a random tacticle grenade
*/
chooseRandomTactical()
{
	tacts = strTok( "flash_grenade,smoke_grenade,concussion_grenade", "," );
	reasonable = getDvarInt( "bots_loadout_reasonable" );

	while ( true )
	{
		tact = random( tacts );

		if ( reasonable )
		{
			if ( tact == "smoke_grenade" )
				continue;
		}

		return tact;
	}
}

/*
	sets up all classes for a bot
*/
setClasses()
{
	n = 5;

	if ( !self is_bot() )
		n = 15;

	rank = self maps\mp\gametypes\_rank::getRankForXp( self getPlayerData( "experience" ) );

	if ( RandomFloatRange( 0, 1 ) < ( ( rank / level.maxRank ) + 0.1 ) )
	{
		self.pers["bots"]["unlocks"]["ghillie"] = true;
		self.pers["bots"]["behavior"]["quickscope"] = true;
	}

	for ( i = 0; i < n; i++ )
	{
		equipment = chooseRandomPerk( "equipment" );
		perk3 = chooseRandomPerk( "perk3" );
		deathstreak = chooseRandomPerk( "perk4" );
		tactical = chooseRandomTactical();
		primary = chooseRandomPrimary();
		primaryAtts = chooseRandomAttachmentComboForGun( primary );
		perk1 = chooseRandomPerk( "perk1", primary, primaryAtts );

		if ( perk1 != "specialty_bling" )
			primaryAtts[1] = "none";

		perk2 = chooseRandomPerk( "perk2", primary, primaryAtts );
		primaryCamo = chooseRandomCamo();
		secondary = chooseRandomSecondary( perk1 );
		secondaryAtts = chooseRandomAttachmentComboForGun( secondary );

		if ( perk1 != "specialty_bling" || !isDefined( self.pers["bots"]["unlocks"]["upgraded_specialty_bling"] ) )
			secondaryAtts[1] = "none";

		self setPlayerData( "customClasses", i, "weaponSetups", 0, "weapon", primary );
		self setPlayerData( "customClasses", i, "weaponSetups", 0, "attachment", 0, primaryAtts[0] );
		self setPlayerData( "customClasses", i, "weaponSetups", 0, "attachment", 1, primaryAtts[1] );
		self setPlayerData( "customClasses", i, "weaponSetups", 0, "camo", primaryCamo );

		self setPlayerData( "customClasses", i, "weaponSetups", 1, "weapon", secondary );
		self setPlayerData( "customClasses", i, "weaponSetups", 1, "attachment", 0, secondaryAtts[0] );
		self setPlayerData( "customClasses", i, "weaponSetups", 1, "attachment", 1, secondaryAtts[1] );

		self setPlayerData( "customClasses", i, "perks", 0, equipment );
		self setPlayerData( "customClasses", i, "perks", 1, perk1 );
		self setPlayerData( "customClasses", i, "perks", 2, perk2 );
		self setPlayerData( "customClasses", i, "perks", 3, perk3 );
		self setPlayerData( "customClasses", i, "perks", 4, deathstreak );
		self setPlayerData( "customClasses", i, "specialGrenade", tactical );
	}
}

/*
	returns if killstreak is going to have the same kill cost
*/
isColidingKillstreak( killstreaks, killstreak )
{
	ksVal = getKillsNeededForStreak( killstreak );

	for ( i = 0; i < killstreaks.size; i++ )
	{
		ks = killstreaks[i];

		if ( ks == "" )
			continue;

		if ( ks == "none" )
			continue;

		ksV = getKillsNeededForStreak( ks );

		if ( ksV <= 0 )
			continue;

		if ( ksV != ksVal )
			continue;

		return true;
	}

	return false;
}

/*
	bots set their killstreaks
*/
setKillstreaks()
{
	rankId = self maps\mp\gametypes\_rank::getRankForXp( self getPlayerData( "experience" ) ) + 1;

	allStreaks = getKillstreaks();

	killstreaks = [];
	killstreaks[0] = "";
	killstreaks[1] = "";
	killstreaks[2] = "";

	chooseableStreaks = 0;

	if ( rankId >= 10 )
		chooseableStreaks++;

	if ( rankId >= 15 )
		chooseableStreaks++;

	if ( rankId >= 22 )
		chooseableStreaks++;

	reasonable = getDvarInt( "bots_loadout_reasonable" );
	op = getDvarInt( "bots_loadout_allow_op" );

	i = 0;

	while ( i < chooseableStreaks )
	{
		slot = randomInt( 3 );

		if ( killstreaks[slot] != "" )
			continue;

		streak = random( allStreaks );

		if ( isColidingKillstreak( killstreaks, streak ) )
			continue;

		if ( reasonable )
		{
			if ( streak == "stealth_airstrike" )
				continue;

			if ( streak == "airdrop_mega" )
				continue;

			if ( streak == "emp" )
				continue;

			if ( streak == "airdrop_sentry_minigun" )
				continue;

			if ( streak == "airdrop" )
				continue;

			if ( streak == "precision_airstrike" )
				continue;

			if ( streak == "helicopter" )
				continue;
		}

		if ( op )
		{
			if ( streak == "nuke" )
				continue;
		}

		killstreaks[slot] = streak;
		i++;
	}

	if ( killstreaks[0] == "" )
		killstreaks[0] = "uav";

	if ( killstreaks[1] == "" )
		killstreaks[1] = "airdrop";

	if ( killstreaks[2] == "" )
		killstreaks[2] = "predator_missile";

	self setPlayerData( "killstreaks", 0, killstreaks[0] );
	self setPlayerData( "killstreaks", 1, killstreaks[1] );
	self setPlayerData( "killstreaks", 2, killstreaks[2] );
}

/*
	The callback for when the bot gets killed.
*/
onKilled( eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration )
{
	self.killerLocation = undefined;
	self.lastKiller = undefined;

	if ( !IsDefined( self ) || !isDefined( self.team ) )
		return;

	if ( sMeansOfDeath == "MOD_FALLING" || sMeansOfDeath == "MOD_SUICIDE" )
		return;

	if ( iDamage <= 0 )
		return;

	if ( !IsDefined( eAttacker ) || !isDefined( eAttacker.team ) )
		return;

	if ( eAttacker == self )
		return;

	if ( level.teamBased && eAttacker.team == self.team )
		return;

	if ( !IsDefined( eInflictor ) || eInflictor.classname != "player" )
		return;

	if ( !isAlive( eAttacker ) )
		return;

	self.killerLocation = eAttacker.origin;
	self.lastKiller = eAttacker;
}

/*
	The callback for when the bot gets damaged.
*/
onDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset )
{
	if ( !IsDefined( self ) || !isDefined( self.team ) )
		return;

	if ( !isAlive( self ) )
		return;

	if ( sMeansOfDeath == "MOD_FALLING" || sMeansOfDeath == "MOD_SUICIDE" )
		return;

	if ( iDamage <= 0 )
		return;

	if ( !IsDefined( eAttacker ) || !isDefined( eAttacker.team ) )
		return;

	if ( eAttacker == self )
		return;

	if ( level.teamBased && eAttacker.team == self.team )
		return;

	if ( !IsDefined( eInflictor ) || eInflictor.classname != "player" )
		return;

	if ( !isAlive( eAttacker ) )
		return;

	if ( !isSubStr( sWeapon, "_silencer_" ) )
		self bot_cry_for_help( eAttacker );

	self SetAttacker( eAttacker );
}

/*
	When the bot gets attacked, have the bot ask for help from teammates.
*/
bot_cry_for_help( attacker )
{
	if ( !level.teamBased )
	{
		return;
	}

	theTime = GetTime();

	if ( IsDefined( self.help_time ) && theTime - self.help_time < 1000 )
	{
		return;
	}

	self.help_time = theTime;

	for ( i = level.players.size - 1; i >= 0; i-- )
	{
		player = level.players[i];

		if ( !player is_bot() )
		{
			continue;
		}

		if ( !isDefined( player.team ) )
			continue;

		if ( !IsAlive( player ) )
		{
			continue;
		}

		if ( player == self )
		{
			continue;
		}

		if ( player.team != self.team )
		{
			continue;
		}

		dist = player.pers["bots"]["skill"]["help_dist"];
		dist *= dist;

		if ( DistanceSquared( self.origin, player.origin ) > dist )
		{
			continue;
		}

		if ( RandomInt( 100 ) < 50 )
		{
			self SetAttacker( attacker );

			if ( RandomInt( 100 ) > 70 )
			{
				break;
			}
		}
	}
}

/*
	watches when the bot enters a killcam
*/
onKillcam()
{
	level endon( "game_ended" );
	self endon( "disconnect" );

	for ( ;; )
	{
		self waittill( "begin_killcam" );

		self thread doKillcamStuff();
	}
}

/*
	bots use copy cat and skip killcams
*/
doKillcamStuff()
{
	self endon( "disconnect" );
	self endon( "killcam_ended" );

	wait 0.5 + randomInt( 3 );

	if ( randomInt( 100 ) > 25 )
		self notify( "use_copycat" );

	wait 0.1;

	self notify( "abort_killcam" );
}

/*
	Selects a class for the bot.
*/
classWatch()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		while ( !isdefined( self.pers["team"] ) || !allowClassChoice() )
			wait .05;

		wait 0.5;

		if ( !isValidClass( self.class ) || !isDefined( self.bot_change_class ) )
			self notify( "menuresponse", game["menu_changeclass"], self chooseRandomClass() );

		self.bot_change_class = true;

		while ( isdefined( self.pers["team"] ) && isValidClass( self.class ) && isDefined( self.bot_change_class ) )
			wait .05;
	}
}

/*
	Chooses a random class
*/
chooseRandomClass()
{
	reasonable = getDvarInt( "bots_loadout_reasonable" );
	class = "";
	rank = self maps\mp\gametypes\_rank::getRankForXp( self getPlayerData( "experience" ) ) + 1;

	if ( rank < 4 || ( randomInt( 100 ) < 2 && !reasonable ) )
	{
		while ( class == "" )
		{
			switch ( randomInt( 5 ) )
			{
				case 0:
					class = "class0";
					break;

				case 1:
					class = "class1";
					break;

				case 2:
					class = "class2";
					break;

				case 3:
					if ( rank >= 2 )
						class = "class3";

					break;

				case 4:
					if ( rank >= 3 )
						class = "class4";

					break;
			}
		}
	}
	else
	{
		class = "custom" + ( randomInt( 5 ) + 1 );
	}

	return class;
}

/*
	Makes sure the bot is on a team.
*/
teamWatch()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		while ( !isdefined( self.pers["team"] ) || !allowTeamChoice() )
			wait .05;

		wait 0.1;

		if ( self.team != "axis" || self.team != "allies" )
			self notify( "menuresponse", game["menu_team"], getDvar( "bots_team" ) );

		while ( isdefined( self.pers["team"] ) )
			wait .05;
	}
}

/*
	Updates the bot's difficulty variables.
*/
difficulty()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		if ( GetDvarInt( "bots_skill" ) != 9 )
		{
			switch ( self.pers["bots"]["skill"]["base"] )
			{
				case 1:
					self.pers["bots"]["skill"]["aim_time"] = 0.6;
					self.pers["bots"]["skill"]["init_react_time"] = 1500;
					self.pers["bots"]["skill"]["reaction_time"] = 1000;
					self.pers["bots"]["skill"]["no_trace_ads_time"] = 500;
					self.pers["bots"]["skill"]["no_trace_look_time"] = 600;
					self.pers["bots"]["skill"]["remember_time"] = 750;
					self.pers["bots"]["skill"]["fov"] = 0.7;
					self.pers["bots"]["skill"]["dist_max"] = 2500;
					self.pers["bots"]["skill"]["dist_start"] = 1000;
					self.pers["bots"]["skill"]["spawn_time"] = 0.75;
					self.pers["bots"]["skill"]["help_dist"] = 0;
					self.pers["bots"]["skill"]["semi_time"] = 0.9;
					self.pers["bots"]["skill"]["shoot_after_time"] = 1;
					self.pers["bots"]["skill"]["aim_offset_time"] = 1.5;
					self.pers["bots"]["skill"]["aim_offset_amount"] = 4;
					self.pers["bots"]["skill"]["bone_update_interval"] = 2;
					self.pers["bots"]["skill"]["bones"] = "j_spineupper,j_ankle_le,j_ankle_ri";
					self.pers["bots"]["skill"]["ads_fov_multi"] = 0.5;
					self.pers["bots"]["skill"]["ads_aimspeed_multi"] = 0.5;

					self.pers["bots"]["behavior"]["strafe"] = 0;
					self.pers["bots"]["behavior"]["nade"] = 10;
					self.pers["bots"]["behavior"]["sprint"] = 30;
					self.pers["bots"]["behavior"]["camp"] = 5;
					self.pers["bots"]["behavior"]["follow"] = 5;
					self.pers["bots"]["behavior"]["crouch"] = 20;
					self.pers["bots"]["behavior"]["switch"] = 2;
					self.pers["bots"]["behavior"]["class"] = 2;
					self.pers["bots"]["behavior"]["jump"] = 0;
					break;

				case 2:
					self.pers["bots"]["skill"]["aim_time"] = 0.55;
					self.pers["bots"]["skill"]["init_react_time"] = 1000;
					self.pers["bots"]["skill"]["reaction_time"] = 800;
					self.pers["bots"]["skill"]["no_trace_ads_time"] = 1000;
					self.pers["bots"]["skill"]["no_trace_look_time"] = 1250;
					self.pers["bots"]["skill"]["remember_time"] = 1500;
					self.pers["bots"]["skill"]["fov"] = 0.65;
					self.pers["bots"]["skill"]["dist_max"] = 3000;
					self.pers["bots"]["skill"]["dist_start"] = 1500;
					self.pers["bots"]["skill"]["spawn_time"] = 0.65;
					self.pers["bots"]["skill"]["help_dist"] = 500;
					self.pers["bots"]["skill"]["semi_time"] = 0.75;
					self.pers["bots"]["skill"]["shoot_after_time"] = 0.75;
					self.pers["bots"]["skill"]["aim_offset_time"] = 1;
					self.pers["bots"]["skill"]["aim_offset_amount"] = 3;
					self.pers["bots"]["skill"]["bone_update_interval"] = 1.5;
					self.pers["bots"]["skill"]["bones"] = "j_spineupper,j_ankle_le,j_ankle_ri,j_head";
					self.pers["bots"]["skill"]["ads_fov_multi"] = 0.5;
					self.pers["bots"]["skill"]["ads_aimspeed_multi"] = 0.5;

					self.pers["bots"]["behavior"]["strafe"] = 10;
					self.pers["bots"]["behavior"]["nade"] = 15;
					self.pers["bots"]["behavior"]["sprint"] = 45;
					self.pers["bots"]["behavior"]["camp"] = 5;
					self.pers["bots"]["behavior"]["follow"] = 5;
					self.pers["bots"]["behavior"]["crouch"] = 15;
					self.pers["bots"]["behavior"]["switch"] = 2;
					self.pers["bots"]["behavior"]["class"] = 2;
					self.pers["bots"]["behavior"]["jump"] = 10;
					break;

				case 3:
					self.pers["bots"]["skill"]["aim_time"] = 0.4;
					self.pers["bots"]["skill"]["init_react_time"] = 750;
					self.pers["bots"]["skill"]["reaction_time"] = 500;
					self.pers["bots"]["skill"]["no_trace_ads_time"] = 1000;
					self.pers["bots"]["skill"]["no_trace_look_time"] = 1500;
					self.pers["bots"]["skill"]["remember_time"] = 2000;
					self.pers["bots"]["skill"]["fov"] = 0.6;
					self.pers["bots"]["skill"]["dist_max"] = 4000;
					self.pers["bots"]["skill"]["dist_start"] = 2250;
					self.pers["bots"]["skill"]["spawn_time"] = 0.5;
					self.pers["bots"]["skill"]["help_dist"] = 750;
					self.pers["bots"]["skill"]["semi_time"] = 0.65;
					self.pers["bots"]["skill"]["shoot_after_time"] = 0.65;
					self.pers["bots"]["skill"]["aim_offset_time"] = 0.75;
					self.pers["bots"]["skill"]["aim_offset_amount"] = 2.5;
					self.pers["bots"]["skill"]["bone_update_interval"] = 1;
					self.pers["bots"]["skill"]["bones"] = "j_spineupper,j_spineupper,j_ankle_le,j_ankle_ri,j_head";
					self.pers["bots"]["skill"]["ads_fov_multi"] = 0.5;
					self.pers["bots"]["skill"]["ads_aimspeed_multi"] = 0.5;

					self.pers["bots"]["behavior"]["strafe"] = 20;
					self.pers["bots"]["behavior"]["nade"] = 20;
					self.pers["bots"]["behavior"]["sprint"] = 50;
					self.pers["bots"]["behavior"]["camp"] = 5;
					self.pers["bots"]["behavior"]["follow"] = 5;
					self.pers["bots"]["behavior"]["crouch"] = 10;
					self.pers["bots"]["behavior"]["switch"] = 2;
					self.pers["bots"]["behavior"]["class"] = 2;
					self.pers["bots"]["behavior"]["jump"] = 25;
					break;

				case 4:
					self.pers["bots"]["skill"]["aim_time"] = 0.3;
					self.pers["bots"]["skill"]["init_react_time"] = 600;
					self.pers["bots"]["skill"]["reaction_time"] = 400;
					self.pers["bots"]["skill"]["no_trace_ads_time"] = 1500;
					self.pers["bots"]["skill"]["no_trace_look_time"] = 2000;
					self.pers["bots"]["skill"]["remember_time"] = 3000;
					self.pers["bots"]["skill"]["fov"] = 0.55;
					self.pers["bots"]["skill"]["dist_max"] = 5000;
					self.pers["bots"]["skill"]["dist_start"] = 3350;
					self.pers["bots"]["skill"]["spawn_time"] = 0.35;
					self.pers["bots"]["skill"]["help_dist"] = 1000;
					self.pers["bots"]["skill"]["semi_time"] = 0.5;
					self.pers["bots"]["skill"]["shoot_after_time"] = 0.5;
					self.pers["bots"]["skill"]["aim_offset_time"] = 0.5;
					self.pers["bots"]["skill"]["aim_offset_amount"] = 2;
					self.pers["bots"]["skill"]["bone_update_interval"] = 0.75;
					self.pers["bots"]["skill"]["bones"] = "j_spineupper,j_spineupper,j_ankle_le,j_ankle_ri,j_head,j_head";
					self.pers["bots"]["skill"]["ads_fov_multi"] = 0.5;
					self.pers["bots"]["skill"]["ads_aimspeed_multi"] = 0.5;

					self.pers["bots"]["behavior"]["strafe"] = 30;
					self.pers["bots"]["behavior"]["nade"] = 25;
					self.pers["bots"]["behavior"]["sprint"] = 55;
					self.pers["bots"]["behavior"]["camp"] = 5;
					self.pers["bots"]["behavior"]["follow"] = 5;
					self.pers["bots"]["behavior"]["crouch"] = 10;
					self.pers["bots"]["behavior"]["switch"] = 2;
					self.pers["bots"]["behavior"]["class"] = 2;
					self.pers["bots"]["behavior"]["jump"] = 35;
					break;

				case 5:
					self.pers["bots"]["skill"]["aim_time"] = 0.25;
					self.pers["bots"]["skill"]["init_react_time"] = 500;
					self.pers["bots"]["skill"]["reaction_time"] = 300;
					self.pers["bots"]["skill"]["no_trace_ads_time"] = 2500;
					self.pers["bots"]["skill"]["no_trace_look_time"] = 3000;
					self.pers["bots"]["skill"]["remember_time"] = 4000;
					self.pers["bots"]["skill"]["fov"] = 0.5;
					self.pers["bots"]["skill"]["dist_max"] = 7500;
					self.pers["bots"]["skill"]["dist_start"] = 5000;
					self.pers["bots"]["skill"]["spawn_time"] = 0.25;
					self.pers["bots"]["skill"]["help_dist"] = 1500;
					self.pers["bots"]["skill"]["semi_time"] = 0.4;
					self.pers["bots"]["skill"]["shoot_after_time"] = 0.35;
					self.pers["bots"]["skill"]["aim_offset_time"] = 0.35;
					self.pers["bots"]["skill"]["aim_offset_amount"] = 1.5;
					self.pers["bots"]["skill"]["bone_update_interval"] = 0.5;
					self.pers["bots"]["skill"]["bones"] = "j_spineupper,j_head";
					self.pers["bots"]["skill"]["ads_fov_multi"] = 0.5;
					self.pers["bots"]["skill"]["ads_aimspeed_multi"] = 0.5;

					self.pers["bots"]["behavior"]["strafe"] = 40;
					self.pers["bots"]["behavior"]["nade"] = 35;
					self.pers["bots"]["behavior"]["sprint"] = 60;
					self.pers["bots"]["behavior"]["camp"] = 5;
					self.pers["bots"]["behavior"]["follow"] = 5;
					self.pers["bots"]["behavior"]["crouch"] = 10;
					self.pers["bots"]["behavior"]["switch"] = 2;
					self.pers["bots"]["behavior"]["class"] = 2;
					self.pers["bots"]["behavior"]["jump"] = 50;
					break;

				case 6:
					self.pers["bots"]["skill"]["aim_time"] = 0.2;
					self.pers["bots"]["skill"]["init_react_time"] = 250;
					self.pers["bots"]["skill"]["reaction_time"] = 150;
					self.pers["bots"]["skill"]["no_trace_ads_time"] = 2500;
					self.pers["bots"]["skill"]["no_trace_look_time"] = 4000;
					self.pers["bots"]["skill"]["remember_time"] = 5000;
					self.pers["bots"]["skill"]["fov"] = 0.45;
					self.pers["bots"]["skill"]["dist_max"] = 10000;
					self.pers["bots"]["skill"]["dist_start"] = 7500;
					self.pers["bots"]["skill"]["spawn_time"] = 0.2;
					self.pers["bots"]["skill"]["help_dist"] = 2000;
					self.pers["bots"]["skill"]["semi_time"] = 0.25;
					self.pers["bots"]["skill"]["shoot_after_time"] = 0.25;
					self.pers["bots"]["skill"]["aim_offset_time"] = 0.25;
					self.pers["bots"]["skill"]["aim_offset_amount"] = 1;
					self.pers["bots"]["skill"]["bone_update_interval"] = 0.25;
					self.pers["bots"]["skill"]["bones"] = "j_spineupper,j_head,j_head";
					self.pers["bots"]["skill"]["ads_fov_multi"] = 0.5;
					self.pers["bots"]["skill"]["ads_aimspeed_multi"] = 0.5;

					self.pers["bots"]["behavior"]["strafe"] = 50;
					self.pers["bots"]["behavior"]["nade"] = 45;
					self.pers["bots"]["behavior"]["sprint"] = 65;
					self.pers["bots"]["behavior"]["camp"] = 5;
					self.pers["bots"]["behavior"]["follow"] = 5;
					self.pers["bots"]["behavior"]["crouch"] = 10;
					self.pers["bots"]["behavior"]["switch"] = 2;
					self.pers["bots"]["behavior"]["class"] = 2;
					self.pers["bots"]["behavior"]["jump"] = 75;
					break;

				case 7:
					self.pers["bots"]["skill"]["aim_time"] = 0.1;
					self.pers["bots"]["skill"]["init_react_time"] = 100;
					self.pers["bots"]["skill"]["reaction_time"] = 50;
					self.pers["bots"]["skill"]["no_trace_ads_time"] = 2500;
					self.pers["bots"]["skill"]["no_trace_look_time"] = 4000;
					self.pers["bots"]["skill"]["remember_time"] = 7500;
					self.pers["bots"]["skill"]["fov"] = 0.4;
					self.pers["bots"]["skill"]["dist_max"] = 15000;
					self.pers["bots"]["skill"]["dist_start"] = 10000;
					self.pers["bots"]["skill"]["spawn_time"] = 0.05;
					self.pers["bots"]["skill"]["help_dist"] = 3000;
					self.pers["bots"]["skill"]["semi_time"] = 0.1;
					self.pers["bots"]["skill"]["shoot_after_time"] = 0;
					self.pers["bots"]["skill"]["aim_offset_time"] = 0;
					self.pers["bots"]["skill"]["aim_offset_amount"] = 0;
					self.pers["bots"]["skill"]["bone_update_interval"] = 0.05;
					self.pers["bots"]["skill"]["bones"] = "j_head";
					self.pers["bots"]["skill"]["ads_fov_multi"] = 0.5;
					self.pers["bots"]["skill"]["ads_aimspeed_multi"] = 0.5;

					self.pers["bots"]["behavior"]["strafe"] = 65;
					self.pers["bots"]["behavior"]["nade"] = 65;
					self.pers["bots"]["behavior"]["sprint"] = 70;
					self.pers["bots"]["behavior"]["camp"] = 5;
					self.pers["bots"]["behavior"]["follow"] = 5;
					self.pers["bots"]["behavior"]["crouch"] = 5;
					self.pers["bots"]["behavior"]["switch"] = 2;
					self.pers["bots"]["behavior"]["class"] = 2;
					self.pers["bots"]["behavior"]["jump"] = 90;
					break;
			}
		}

		wait 5;
	}
}

/*
	Sets the bot difficulty.
*/
set_diff()
{
	rankVar = GetDvarInt( "bots_skill" );

	switch ( rankVar )
	{
		case 0:
			self.pers["bots"]["skill"]["base"] = Round( random_normal_distribution( 3.5, 1.75, 1, 7 ) );
			break;

		case 8:
			break;

		case 9:
			self.pers["bots"]["skill"]["base"] = randomIntRange( 1, 7 );
			self.pers["bots"]["skill"]["aim_time"] = 0.05 * randomIntRange( 1, 20 );
			self.pers["bots"]["skill"]["init_react_time"] = 50 * randomInt( 100 );
			self.pers["bots"]["skill"]["reaction_time"] = 50 * randomInt( 100 );
			self.pers["bots"]["skill"]["remember_time"] = 50 * randomInt( 100 );
			self.pers["bots"]["skill"]["no_trace_ads_time"] = 50 * randomInt( 100 );
			self.pers["bots"]["skill"]["no_trace_look_time"] = 50 * randomInt( 100 );
			self.pers["bots"]["skill"]["fov"] = randomFloatRange( -1, 1 );

			randomNum = randomIntRange( 500, 25000 );
			self.pers["bots"]["skill"]["dist_start"] = randomNum;
			self.pers["bots"]["skill"]["dist_max"] = randomNum * 2;

			self.pers["bots"]["skill"]["spawn_time"] = 0.05 * randomInt( 20 );
			self.pers["bots"]["skill"]["help_dist"] = randomIntRange( 500, 25000 );
			self.pers["bots"]["skill"]["semi_time"] = randomFloatRange( 0.05, 1 );
			self.pers["bots"]["skill"]["shoot_after_time"] = randomFloatRange( 0.05, 1 );
			self.pers["bots"]["skill"]["aim_offset_time"] = randomFloatRange( 0.05, 1 );
			self.pers["bots"]["skill"]["aim_offset_amount"] = randomFloatRange( 0.05, 1 );
			self.pers["bots"]["skill"]["bone_update_interval"] = randomFloatRange( 0.05, 1 );
			self.pers["bots"]["skill"]["bones"] = "j_head,j_spineupper,j_ankle_le,j_ankle_ri";

			self.pers["bots"]["behavior"]["strafe"] = randomInt( 100 );
			self.pers["bots"]["behavior"]["nade"] = randomInt( 100 );
			self.pers["bots"]["behavior"]["sprint"] = randomInt( 100 );
			self.pers["bots"]["behavior"]["camp"] = randomInt( 100 );
			self.pers["bots"]["behavior"]["follow"] = randomInt( 100 );
			self.pers["bots"]["behavior"]["crouch"] = randomInt( 100 );
			self.pers["bots"]["behavior"]["switch"] = randomInt( 100 );
			self.pers["bots"]["behavior"]["class"] = randomInt( 100 );
			self.pers["bots"]["behavior"]["jump"] = randomInt( 100 );
			break;

		default:
			self.pers["bots"]["skill"]["base"] = rankVar;
			break;
	}
}

/*
	Allows the bot to spawn when force respawn is disabled
	Watches when the bot dies
*/
onDeath()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		self waittill( "death" );

		self.wantSafeSpawn = true;
	}
}

/*
	Watches when the bot is given a loadout
*/
onGiveLoadout_loop()
{
	class = self.class;

	if ( isDefined( self.bot_oma_class ) )
		class = self.bot_oma_class;

	self botGiveLoadout( self.team, class, !isDefined( self.bot_oma_class ) );
	self.bot_oma_class = undefined;
}

/*
	Watches when the bot is given a loadout
*/
onGiveLoadout()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		self waittill( "giveLoadout" );

		self onGiveLoadout_loop();
	}
}

/*
	When the bot spawns.
*/
onSpawned()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		self waittill( "spawned_player" );

		if ( randomInt( 100 ) <= self.pers["bots"]["behavior"]["class"] )
			self.bot_change_class = undefined;

		self.bot_lock_goal = false;
		self.bot_oma_class = undefined;
		self.help_time = undefined;
		self.bot_was_follow_script_update = undefined;
		self.bot_stuck_on_carepackage = undefined;

		if ( getDvarInt( "bots_play_obj" ) )
			self thread bot_dom_cap_think();
	}
}

/*
	When the bot spawned, after the difficulty wait. Start the logic for the bot.
*/
onBotSpawned()
{
	self endon( "disconnect" );
	level endon( "game_ended" );

	for ( ;; )
	{
		self waittill( "bot_spawned" );

		self thread start_bot_threads();
	}
}

/*
	Starts all the bot thinking
*/
start_bot_threads()
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	self endon( "death" );

	gameFlagWait( "prematch_done" );

	// inventory usage
	if ( getDvarInt( "bots_play_killstreak" ) )
		self thread bot_killstreak_think();

	self thread bot_weapon_think();
	self thread doReloadCancel();
	self thread bot_perk_think();

	// script targeting
	if ( getDvarInt( "bots_play_target_other" ) )
	{
		self thread bot_target_vehicle();
		self thread bot_equipment_kill_think();
		self thread bot_turret_think();
	}

	// airdrop
	if ( getDvarInt( "bots_play_take_carepackages" ) )
	{
		self thread bot_watch_stuck_on_crate();
		self thread bot_crate_think();
	}

	// awareness
	self thread bot_revenge_think();
	self thread bot_uav_think();
	self thread bot_listen_to_steps();
	self thread follow_target();

	// camp and follow
	if ( getDvarInt( "bots_play_camp" ) )
	{
		self thread bot_think_follow();
		self thread bot_think_camp();
	}

	// nades
	if ( getDvarInt( "bots_play_nade" ) )
	{
		self thread bot_jav_loc_think();
		self thread bot_use_tube_think();
		self thread bot_use_grenade_think();
		self thread bot_use_equipment_think();
		self thread bot_watch_riot_weapons();
		self thread bot_watch_think_mw2(); // bots play mw2
	}

	// obj
	if ( getDvarInt( "bots_play_obj" ) )
	{
		self thread bot_dom_def_think();
		self thread bot_dom_spawn_kill_think();

		self thread bot_hq();

		self thread bot_cap();

		self thread bot_sab();

		self thread bot_sd_defenders();
		self thread bot_sd_attackers();

		self thread bot_dem_attackers();
		self thread bot_dem_defenders();

		self thread bot_gtnw();
		self thread bot_oneflag();
		self thread bot_arena();
		self thread bot_vip();
	}

	self thread bot_think_revive();
}

/*
	Increments the number of bots approching the obj, decrements when needed
	Used for preventing too many bots going to one obj, or unreachable objs
*/
bot_inc_bots( obj, unreach )
{
	level endon( "game_ended" );
	self endon( "bot_inc_bots" );

	if ( !isDefined( obj ) )
		return;

	if ( !isDefined( obj.bots ) )
		obj.bots = 0;

	obj.bots++;

	ret = self waittill_any_return( "death", "disconnect", "bad_path", "goal", "new_goal" );

	if ( isDefined( obj ) && ( ret != "bad_path" || !isDefined( unreach ) ) )
		obj.bots--;
}

/*
	Watches when the bot is touching the obj and calls 'goal'
*/
bots_watch_touch_obj( obj )
{
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( "bad_path" );
	self endon ( "goal" );
	self endon ( "new_goal" );

	for ( ;; )
	{
		wait 0.5;

		if ( !isDefined( obj ) )
		{
			self notify( "bad_path" );
			return;
		}

		if ( self IsTouching( obj ) )
		{
			self notify( "goal" );
			return;
		}
	}
}

/*
	Watches while the obj is being carried, calls 'goal' when complete
*/
bot_escort_obj( obj, carrier )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	for ( ;; )
	{
		wait 0.5;

		if ( !isDefined( obj ) )
			break;

		if ( !isDefined( obj.carrier ) || carrier == obj.carrier )
			break;
	}

	self notify( "goal" );
}

/*
	Watches while the obj is not being carried, calls 'goal' when complete
*/
bot_get_obj( obj )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	for ( ;; )
	{
		wait 0.5;

		if ( !isDefined( obj ) )
			break;

		if ( isDefined( obj.carrier ) )
			break;
	}

	self notify( "goal" );
}

/*
	bots will defend their site from a planter/defuser
*/
bot_defend_site( site )
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	for ( ;; )
	{
		wait 0.5;

		if ( !site isInUse() )
			break;
	}

	self notify( "bad_path" );
}

/*
	Bots will go plant the bomb
*/
bot_go_plant( plant )
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	for ( ;; )
	{
		wait 1;

		if ( level.bombPlanted )
			break;

		if ( self isTouching( plant.trigger ) )
			break;
	}

	if ( level.bombPlanted )
		self notify( "bad_path" );
	else
		self notify( "goal" );
}

/*
	Bots will go defuse the bomb
*/
bot_go_defuse( plant )
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	for ( ;; )
	{
		wait 1;

		if ( !level.bombPlanted )
			break;

		if ( self isTouching( plant.trigger ) )
			break;
	}

	if ( !level.bombPlanted )
		self notify( "bad_path" );
	else
		self notify( "goal" );
}

/*
	Creates a bomb use thread and waits for an output
*/
bot_use_bomb_thread( bomb )
{
	self thread bot_use_bomb( bomb );
	self waittill_any( "bot_try_use_fail", "bot_try_use_success" );
}

/*
	Waits for the time to call bot_try_use_success or fail
*/
bot_bomb_use_time( wait_time )
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "bot_try_use_fail" );
	self endon( "bot_try_use_success" );

	self waittill( "bot_try_use_weapon" );

	wait 0.05;
	elapsed = 0;

	while ( wait_time > elapsed )
	{
		wait 0.05;//wait first so waittill can setup
		elapsed += 0.05;

		if ( self InLastStand() )
		{
			self notify( "bot_try_use_fail" );
			return;//needed?
		}
	}

	self notify( "bot_try_use_success" );
}

/*
	Bot switches to the bomb weapon
*/
bot_use_bomb_weapon( weap )
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "disconnect" );

	lastWeap = self getCurrentWeapon();

	if ( self getCurrentWeapon() != weap )
	{
		self GiveWeapon( weap );

		if ( !self ChangeToWeapon( weap ) )
		{
			self notify( "bot_try_use_fail" );
			return;
		}
	}
	else
	{
		wait 0.05;//allow a waittill to setup as the notify may happen on the same frame
	}

	self notify( "bot_try_use_weapon" );
	ret = self waittill_any_return( "bot_try_use_fail", "bot_try_use_success" );

	if ( lastWeap != "none" )
		self thread ChangeToWeapon( lastWeap );
	else
		self takeWeapon( weap );
}

/*
	Bot tries to use the bomb site
*/
bot_use_bomb( bomb )
{
	level endon( "game_ended" );

	bomb.inUse = true;

	myteam = self.team;

	self BotFreezeControls( true );

	bomb [[bomb.onBeginUse]]( self );

	self clientClaimTrigger( bomb.trigger );
	self.claimTrigger = bomb.trigger;

	self thread bot_bomb_use_time( bomb.useTime / 1000 );
	self thread bot_use_bomb_weapon( bomb.useWeapon );

	result = self waittill_any_return( "death", "disconnect", "bot_try_use_fail", "bot_try_use_success" );

	if ( isDefined( self ) )
	{
		self.claimTrigger = undefined;
		self BotFreezeControls( false );
	}

	bomb [[bomb.onEndUse]]( myteam, self, ( result == "bot_try_use_success" ) );
	bomb.trigger releaseClaimedTrigger();

	if ( result == "bot_try_use_success" )
		bomb [[bomb.onUse]]( self );

	bomb.inUse = false;
}

/*
	Fires the bots weapon until told to stop
*/
fire_current_weapon()
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "weapon_change" );
	self endon( "stop_firing_weapon" );

	for ( ;; )
	{
		self thread BotPressAttack( 0.05 );
		wait 0.1;
	}
}

/*
	Changes to the weap
*/
changeToWeapon( weap )
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );

	if ( !self HasWeapon( weap ) )
		return false;

	self BotChangeToWeapon( weap );

	if ( self GetCurrentWeapon() == weap )
		return true;

	self waittill_any_timeout( 5, "weapon_change" );

	return ( self GetCurrentWeapon() == weap );
}

/*
	Bots throw the grenade
*/
botThrowGrenade( nade, time )
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );

	if ( !self GetAmmoCount( nade ) )
		return false;

	if ( isSecondaryGrenade( nade ) )
		self thread BotPressSmoke( time );
	else
		self thread BotPressFrag( time );

	ret = self waittill_any_timeout( 5, "grenade_fire" );

	return ( ret == "grenade_fire" );
}

/*
	Gets the object thats the closest in the array
*/
bot_array_nearest_curorigin( array )
{
	result = undefined;

	for ( i = 0; i < array.size; i++ )
		if ( !isDefined( result ) || DistanceSquared( self.origin, array[i].curorigin ) < DistanceSquared( self.origin, result.curorigin ) )
			result = array[i];

	return result;
}

/*
	Returns an weapon thats a rocket with ammo
*/
getRocketAmmo()
{
	answer = self getLockonAmmo();

	if ( isDefined( answer ) )
		return answer;

	if ( self getAmmoCount( "rpg_mp" ) )
		answer = "rpg_mp";

	return answer;
}

/*
	Returns a weapon thats lockon with ammo
*/
getLockonAmmo()
{
	answer = undefined;

	if ( self getAmmoCount( "at4_mp" ) )
		answer = "at4_mp";

	if ( self getAmmoCount( "stinger_mp" ) )
		answer = "stinger_mp";

	if ( self getAmmoCount( "javelin_mp" ) )
		answer = "javelin_mp";

	return answer;
}

/*
	Clears goal when events death
*/
stop_go_target_on_death( tar )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "new_goal" );
	self endon( "bad_path" );
	self endon( "goal" );

	tar waittill_either( "death", "disconnect" );

	self ClearScriptGoal();
}

/*
	Goes to the target's location if it had one
*/
follow_target_loop()
{
	threat = self GetThreat();

	if ( !isPlayer( threat ) )
		return;

	if ( randomInt( 100 ) > self.pers["bots"]["behavior"]["follow"] * 5 )
		return;

	self SetScriptGoal( threat.origin, 64 );
	self thread stop_go_target_on_death( threat );

	if ( self waittill_any_return( "new_goal", "goal", "bad_path" ) != "new_goal" )
		self ClearScriptGoal();
}

/*
	Goes to the target's location if it had one
*/
follow_target()
{
	self endon( "death" );
	self endon( "disconnect" );

	for ( ;; )
	{
		wait 1;

		if ( self HasScriptGoal() || self.bot_lock_goal )
			continue;

		if ( !self HasThreat() )
			continue;

		self follow_target_loop();
	}
}

/*
	Bot logic for bot determining to camp.
*/
bot_think_camp_loop()
{
	campSpot = getWaypointForIndex( random( self waypointsNear( getWaypointsOfType( "camp" ), 1024 ) ) );

	if ( !isDefined( campSpot ) )
		return;

	self SetScriptGoal( campSpot.origin, 16 );

	ret = self waittill_any_return( "new_goal", "goal", "bad_path" );

	if ( ret != "new_goal" )
		self ClearScriptGoal();

	if ( ret != "goal" )
		return;

	self thread killCampAfterTime( randomIntRange( 10, 20 ) );
	self CampAtSpot( campSpot.origin, campSpot.origin + AnglesToForward( campSpot.angles ) * 2048 );
}

/*
	Bot logic for bot determining to camp.
*/
bot_think_camp()
{
	self endon( "death" );
	self endon( "disconnect" );

	for ( ;; )
	{
		wait randomintrange( 4, 7 );

		if ( self HasScriptGoal() || self.bot_lock_goal || self HasScriptAimPos() )
			continue;

		if ( randomInt( 100 ) > self.pers["bots"]["behavior"]["camp"] )
			continue;

		self bot_think_camp_loop();
	}
}

/*
	Kills the camping thread when time
*/
killCampAfterTime( time )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "kill_camp_bot" );

	wait time + 0.05;
	self ClearScriptGoal();
	self ClearScriptAimPos();

	self notify( "kill_camp_bot" );
}

/*
	Kills the camping thread when ent gone
*/
killCampAfterEntGone( ent )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "kill_camp_bot" );

	for ( ;; )
	{
		wait 0.05;

		if ( !isDefined( ent ) )
			break;
	}

	self ClearScriptGoal();
	self ClearScriptAimPos();

	self notify( "kill_camp_bot" );
}

/*
	Camps at the spot
*/
CampAtSpot( origin, anglePos )
{
	self endon( "kill_camp_bot" );

	self SetScriptGoal( origin, 64 );

	if ( isDefined( anglePos ) )
	{
		self SetScriptAimPos( anglePos );
	}

	self waittill( "new_goal" );
	self ClearScriptAimPos();

	self notify( "kill_camp_bot" );
}

/*
	Bot logic for bot determining to follow another player.
*/
bot_think_follow_loop()
{
	follows = [];
	distSq = self.pers["bots"]["skill"]["help_dist"] * self.pers["bots"]["skill"]["help_dist"];

	for ( i = level.players.size - 1; i >= 0; i-- )
	{
		player = level.players[i];

		if ( player == self )
			continue;

		if ( !isReallyAlive( player ) )
			continue;

		if ( player.team != self.team )
			continue;

		if ( DistanceSquared( player.origin, self.origin ) > distSq )
			continue;

		follows[follows.size] = player;
	}

	toFollow = random( follows );

	if ( !isDefined( toFollow ) )
		return;

	self thread killFollowAfterTime( randomIntRange( 10, 20 ) );
	self followPlayer( toFollow );
}

/*
	Bot logic for bot determining to follow another player.
*/
bot_think_follow()
{
	self endon( "death" );
	self endon( "disconnect" );

	for ( ;; )
	{
		wait randomIntRange( 3, 5 );

		if ( self HasScriptGoal() || self.bot_lock_goal || self HasScriptAimPos() )
			continue;

		if ( randomInt( 100 ) > self.pers["bots"]["behavior"]["follow"] )
			continue;

		if ( !level.teamBased )
			continue;

		self bot_think_follow_loop();
	}
}

/*
	Kills follow when new goal
*/
watchForFollowNewGoal()
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "kill_follow_bot" );

	for ( ;; )
	{
		self waittill( "new_goal" );

		if ( !isDefined( self.bot_was_follow_script_update ) )
			break;
	}

	self ClearScriptAimPos();
	self notify( "kill_follow_bot" );
}

/*
	Kills follow when time
*/
killFollowAfterTime( time )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "kill_follow_bot" );

	wait time;

	self ClearScriptGoal();
	self ClearScriptAimPos();
	self notify( "kill_follow_bot" );
}

/*
	Determine bot to follow a player
*/
followPlayer( who )
{
	self endon( "kill_follow_bot" );

	self thread watchForFollowNewGoal();

	for ( ;; )
	{
		wait 0.05;

		if ( !isDefined( who ) || !isReallyAlive( who ) )
			break;

		self SetScriptAimPos( who.origin + ( 0, 0, 42 ) );
		myGoal = self GetScriptGoal();

		if ( isDefined( myGoal ) && DistanceSquared( myGoal, who.origin ) < 64 * 64 )
			continue;

		self.bot_was_follow_script_update = true;
		self SetScriptGoal( who.origin, 32 );
		waittillframeend;
		self.bot_was_follow_script_update = undefined;

		self waittill_either( "goal", "bad_path" );
	}

	self ClearScriptGoal();
	self ClearScriptAimPos();

	self notify( "kill_follow_bot" );
}

/*
	Bots thinking of using one man army and blast shield
*/
bot_perk_think_loop()
{
	for ( ; self _hasPerk( "specialty_blastshield" ); )
	{
		if ( !self _hasPerk( "_specialty_blastshield" ) )
		{
			if ( randomInt( 100 ) < 65 )
				break;

			self _setPerk( "_specialty_blastshield" );
		}
		else
		{
			if ( randomInt( 100 ) < 90 )
				break;

			self _unsetPerk( "_specialty_blastshield" );
		}

		break;
	}

	for ( ; self _hasPerk( "specialty_onemanarmy" ) && self hasWeapon( "onemanarmy_mp" ); )
	{
		if ( self HasThreat() || self HasBotJavelinLocation() )
			break;

		if ( self InLastStand() && !self InFinalStand() )
			break;

		anyWeapout = false;
		weaponsList = self GetWeaponsListAll();

		for ( i = 0; i < weaponsList.size; i++ )
		{
			weap = weaponsList[i];

			if ( self getAmmoCount( weap ) || weap == "onemanarmy_mp" )
				continue;

			anyWeapout = true;
		}

		if ( ( !anyWeapout && randomInt( 100 ) < 90 ) || randomInt( 100 ) < 10 )
			break;

		class = self chooseRandomClass();
		self.bot_oma_class = class;

		if ( !self changeToWeapon( "onemanarmy_mp" ) )
		{
			self.bot_oma_class = undefined;
			break;
		}

		self BotFreezeControls( true );
		wait 1;
		self BotFreezeControls( false );

		self notify ( "menuresponse", game["menu_onemanarmy"], self.bot_oma_class );

		self waittill_any_timeout ( 10, "changed_kit" );
		break;
	}
}

/*
	Bots thinking of using one man army and blast shield
*/
bot_perk_think()
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );

	for ( ;; )
	{
		wait randomIntRange( 5, 7 );

		if ( self IsUsingRemote() )
			continue;

		if ( self BotIsFrozen() )
			continue;

		if ( self isDefusing() || self isPlanting() )
			continue;

		self bot_perk_think_loop();
	}
}

/*
	Bots thinking of using a noobtube
*/
bot_use_tube_think_loop( data )
{
	if ( data.doFastContinue )
		data.doFastContinue = false;
	else
	{
		wait randomintRange( 3, 7 );

		chance = self.pers["bots"]["behavior"]["nade"] / 2;

		if ( chance > 20 )
			chance = 20;

		if ( randomInt( 100 ) > chance )
			return;
	}

	tube = self getValidTube();

	if ( !isDefined( tube ) )
		return;

	if ( self HasThreat() || self HasBotJavelinLocation() || self HasScriptAimPos() )
		return;

	if ( self BotIsFrozen() )
		return;

	if ( self IsBotFragging() || self IsBotSmoking() )
		return;

	if ( self isDefusing() || self isPlanting() )
		return;

	if ( self IsUsingRemote() )
		return;

	if ( self InLastStand() && !self InFinalStand() )
		return;

	loc = undefined;

	if ( !self nearAnyOfWaypoints( 128, getWaypointsOfType( "tube" ) ) )
	{
		tubeWp = getWaypointForIndex( random( self waypointsNear( getWaypointsOfType( "tube" ), 1024 ) ) );

		myEye = self GetEye();

		if ( !isDefined( tubeWp ) || self HasScriptGoal() || self.bot_lock_goal )
		{
			traceForward = BulletTrace( myEye, myEye + AnglesToForward( self GetPlayerAngles() ) * 900 * 5, false, self );

			loc = traceForward["position"];
			dist = DistanceSquared( self.origin, loc );

			if ( dist < level.bots_minGrenadeDistance || dist > level.bots_maxGrenadeDistance * 5 )
				return;

			if ( !bulletTracePassed( self.origin + ( 0, 0, 5 ), self.origin + ( 0, 0, 2048 ), false, self ) )
				return;

			if ( !bulletTracePassed( loc + ( 0, 0, 5 ), loc + ( 0, 0, 2048 ), false, self ) )
				return;

			loc += ( 0, 0, dist / 16000 );
		}
		else
		{
			self SetScriptGoal( tubeWp.origin, 16 );

			ret = self waittill_any_return( "new_goal", "goal", "bad_path" );

			if ( ret != "new_goal" )
				self ClearScriptGoal();

			if ( ret != "goal" )
				return;

			data.doFastContinue = true;
			return;
		}
	}
	else
	{
		tubeWp = getWaypointForIndex( self getNearestWaypointOfWaypoints( getWaypointsOfType( "tube" ) ) );
		loc = tubeWp.origin + AnglesToForward( tubeWp.angles ) * 2048;
	}

	if ( !isDefined( loc ) )
		return;

	self SetScriptAimPos( loc );
	self BotStopMoving( true );
	wait 1;

	if ( self changeToWeapon( tube ) )
	{
		self thread fire_current_weapon();
		self waittill_any_timeout( 5, "missile_fire", "weapon_change" );
		self notify( "stop_firing_weapon" );
	}

	self ClearScriptAimPos();
	self BotStopMoving( false );
}

/*
	Bots thinking of using a noobtube
*/
bot_use_tube_think()
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );

	data = spawnStruct();
	data.doFastContinue = false;

	for ( ;; )
	{
		self bot_use_tube_think_loop( data );
	}
}

/*
	Bots thinking of using claymores and TIs
*/
bot_use_equipment_think_loop( data )
{
	if ( data.doFastContinue )
		data.doFastContinue = false;
	else
	{
		wait randomintRange( 2, 4 );

		chance = self.pers["bots"]["behavior"]["nade"] / 2;

		if ( chance > 20 )
			chance = 20;

		if ( randomInt( 100 ) > chance )
			return;
	}

	nade = undefined;

	if ( self GetAmmoCount( "claymore_mp" ) )
		nade = "claymore_mp";

	if ( self GetAmmoCount( "flare_mp" ) )
		nade = "flare_mp";

	if ( self GetAmmoCount( "c4_mp" ) )
		nade = "c4_mp";

	if ( !isDefined( nade ) )
		return;

	if ( self HasThreat() || self HasBotJavelinLocation() || self HasScriptAimPos() )
		return;

	if ( self BotIsFrozen() )
		return;

	if ( self IsBotFragging() || self IsBotSmoking() )
		return;

	if ( self isDefusing() || self isPlanting() )
		return;

	if ( self IsUsingRemote() )
		return;

	if ( self inLastStand() && !self _hasPerk( "specialty_laststandoffhand" ) && !self inFinalStand() )
		return;

	loc = undefined;

	if ( !self nearAnyOfWaypoints( 128, getWaypointsOfType( "claymore" ) ) )
	{
		clayWp = getWaypointForIndex( random( self waypointsNear( getWaypointsOfType( "claymore" ), 1024 ) ) );

		if ( !isDefined( clayWp ) || self HasScriptGoal() || self.bot_lock_goal )
		{
			myEye = self GetEye();
			loc = myEye + AnglesToForward( self GetPlayerAngles() ) * 256;

			if ( !bulletTracePassed( myEye, loc, false, self ) )
				return;
		}
		else
		{
			self SetScriptGoal( clayWp.origin, 16 );

			ret = self waittill_any_return( "new_goal", "goal", "bad_path" );

			if ( ret != "new_goal" )
				self ClearScriptGoal();

			if ( ret != "goal" )
				return;

			data.doFastContinue = true;
			return;
		}
	}
	else
	{
		clayWp = getWaypointForIndex( self getNearestWaypointOfWaypoints( getWaypointsOfType( "claymore" ) ) );
		loc = clayWp.origin + AnglesToForward( clayWp.angles ) * 2048;
	}

	if ( !isDefined( loc ) )
		return;

	self SetScriptAimPos( loc );
	self BotStopMoving( true );
	wait 1;

	self botThrowGrenade( nade, 0.05 );

	self ClearScriptAimPos();
	self BotStopMoving( false );
}

/*
	Bots thinking of using claymores and TIs
*/
bot_use_equipment_think()
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );

	data = spawnStruct();
	data.doFastContinue = false;

	for ( ;; )
	{
		self bot_use_equipment_think_loop( data );
	}
}

/*
	Bots thinking of using grenades
*/
bot_use_grenade_think_loop( data )
{
	if ( data.doFastContinue )
		data.doFastContinue = false;
	else
	{
		wait randomintRange( 4, 7 );

		chance = self.pers["bots"]["behavior"]["nade"] / 2;

		if ( chance > 20 )
			chance = 20;

		if ( randomInt( 100 ) > chance )
			return;
	}

	nade = self getValidGrenade();

	if ( !isDefined( nade ) )
		return;

	if ( self HasThreat() || self HasBotJavelinLocation() || self HasScriptAimPos() )
		return;

	if ( self BotIsFrozen() )
		return;

	if ( self IsBotFragging() || self IsBotSmoking() )
		return;

	if ( self isDefusing() || self isPlanting() )
		return;

	if ( self IsUsingRemote() )
		return;

	if ( self inLastStand() && !self _hasPerk( "specialty_laststandoffhand" ) && !self inFinalStand() )
		return;

	loc = undefined;

	if ( !self nearAnyOfWaypoints( 128, getWaypointsOfType( "grenade" ) ) )
	{
		nadeWp = getWaypointForIndex( random( self waypointsNear( getWaypointsOfType( "grenade" ), 1024 ) ) );

		myEye = self GetEye();

		if ( !isDefined( nadeWp ) || self HasScriptGoal() || self.bot_lock_goal )
		{
			traceForward = BulletTrace( myEye, myEye + AnglesToForward( self GetPlayerAngles() ) * 900, false, self );

			loc = traceForward["position"];
			dist = DistanceSquared( self.origin, loc );

			if ( dist < level.bots_minGrenadeDistance || dist > level.bots_maxGrenadeDistance )
				return;

			if ( !bulletTracePassed( self.origin + ( 0, 0, 5 ), self.origin + ( 0, 0, 2048 ), false, self ) )
				return;

			if ( !bulletTracePassed( loc + ( 0, 0, 5 ), loc + ( 0, 0, 2048 ), false, self ) )
				return;

			loc += ( 0, 0, dist / 3000 );
		}
		else
		{
			self SetScriptGoal( nadeWp.origin, 16 );

			ret = self waittill_any_return( "new_goal", "goal", "bad_path" );

			if ( ret != "new_goal" )
				self ClearScriptGoal();

			if ( ret != "goal" )
				return;

			data.doFastContinue = true;
			return;
		}
	}
	else
	{
		nadeWp = getWaypointForIndex( self getNearestWaypointOfWaypoints( getWaypointsOfType( "grenade" ) ) );
		loc = nadeWp.origin + AnglesToForward( nadeWp.angles ) * 2048;
	}

	if ( !isDefined( loc ) )
		return;

	self SetScriptAimPos( loc );
	self BotStopMoving( true );
	wait 1;

	time = 0.5;

	if ( nade == "frag_grenade_mp" )
		time = 2;

	self botThrowGrenade( nade, time );

	self ClearScriptAimPos();
	self BotStopMoving( false );
}

/*
	Bots thinking of using grenades
*/
bot_use_grenade_think()
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );

	data = spawnStruct();
	data.doFastContinue = false;

	for ( ;; )
	{
		self bot_use_grenade_think_loop( data );
	}
}

/*
	Bots play mw2
*/
bot_watch_think_mw2_loop()
{
	tube = self getValidTube();

	if ( !isDefined( tube ) )
	{
		if ( self GetAmmoCount( "at4_mp" ) )
			tube = "at4_mp";
		else if ( self GetAmmoCount( "rpg_mp" ) )
			tube = "rpg_mp";
		else
			return;
	}

	if ( self GetCurrentWeapon() == tube )
		return;

	chance = self.pers["bots"]["behavior"]["nade"];

	if ( randomInt( 100 ) > chance )
		return;

	self thread ChangeToWeapon( tube );
}

/*
	Bots play mw2
*/
bot_watch_think_mw2()
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );

	for ( ;; )
	{
		wait randomIntRange( 1, 4 );

		if ( self BotIsFrozen() )
			continue;

		if ( self isDefusing() || self isPlanting() )
			continue;

		if ( self IsUsingRemote() )
			continue;

		if ( self InLastStand() && !self InFinalStand() )
			continue;

		if ( self HasThreat() )
			continue;

		self bot_watch_think_mw2_loop();
	}
}

/*
	Bots will use gremades/wweapons while having a target while using a shield
*/
bot_watch_riot_weapons_loop()
{
	threat = self GetThreat();
	dist = DistanceSquared( threat.origin, self.origin );
	curWeap = self GetCurrentWeapon();

	if ( randomInt( 2 ) )
	{
		nade = self getValidGrenade();

		if ( !isDefined( nade ) )
			return;

		if ( dist <= level.bots_minGrenadeDistance || dist >= level.bots_maxGrenadeDistance )
			return;

		if ( randomInt( 100 ) > self.pers["bots"]["behavior"]["nade"] )
			return;

		self botThrowGrenade( nade );
	}
	else
	{
		if ( randomInt( 100 ) > self.pers["bots"]["behavior"]["switch"] * 10 )
			return;

		weaponslist = self getweaponslistall();
		weap = "";

		while ( weaponslist.size )
		{
			weapon = weaponslist[randomInt( weaponslist.size )];
			weaponslist = array_remove( weaponslist, weapon );

			if ( !self getAmmoCount( weapon ) )
				continue;

			if ( !isWeaponPrimary( weapon ) )
				continue;

			if ( curWeap == weapon || weapon == "none" || weapon == "" || weapon == "javelin_mp" || weapon == "stinger_mp" || weapon == "onemanarmy_mp" )
				continue;

			weap = weapon;
			break;
		}

		if ( weap == "" )
			return;

		self thread ChangeToWeapon( weap );
	}
}

/*
	Bots will use gremades/wweapons while having a target while using a shield
*/
bot_watch_riot_weapons()
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );

	for ( ;; )
	{
		wait randomIntRange( 2, 4 );

		if ( self BotIsFrozen() )
			continue;

		if ( self isDefusing() || self isPlanting() )
			continue;

		if ( self IsUsingRemote() )
			continue;

		if ( self InLastStand() && !self InFinalStand() )
			continue;

		if ( !self HasThreat() )
			continue;

		if ( !self.hasRiotShieldEquipped )
			continue;

		self bot_watch_riot_weapons_loop();
	}
}

/*
	BOts thinking of using javelins
*/
bot_jav_loc_think_loop( data )
{
	if ( data.doFastContinue )
		data.doFastContinue = false;
	else
	{
		wait randomintRange( 2, 4 );

		chance = self.pers["bots"]["behavior"]["nade"] / 2;

		if ( chance > 20 )
			chance = 20;

		if ( randomInt( 100 ) > chance && self getCurrentWeapon() != "javelin_mp" )
			return;
	}

	if ( !self GetAmmoCount( "javelin_mp" ) )
		return;

	if ( self HasThreat() || self HasBotJavelinLocation() || self HasScriptAimPos() )
		return;

	if ( self BotIsFrozen() )
		return;

	if ( self isDefusing() || self isPlanting() )
		return;

	if ( self IsUsingRemote() )
		return;

	if ( self InLastStand() && !self InFinalStand() )
		return;

	if ( self isEMPed() )
		return;

	loc = undefined;

	if ( !self nearAnyOfWaypoints( 128, getWaypointsOfType( "javelin" ) ) )
	{
		javWp = getWaypointForIndex( random( self waypointsNear( getWaypointsOfType( "javelin" ), 1024 ) ) );

		if ( !isDefined( javWp ) || self HasScriptGoal() || self.bot_lock_goal )
		{
			traceForward = self maps\mp\_javelin::EyeTraceForward();

			if ( !isDefined( traceForward ) )
				return;

			loc = traceForward[0];

			if ( self maps\mp\_javelin::TargetPointTooClose( loc ) )
				return;

			if ( !bulletTracePassed( self.origin + ( 0, 0, 5 ), self.origin + ( 0, 0, 2048 ), false, self ) )
				return;

			if ( !bulletTracePassed( loc + ( 0, 0, 5 ), loc + ( 0, 0, 2048 ), false, self ) )
				return;
		}
		else
		{
			self SetScriptGoal( javWp.origin, 16 );

			ret = self waittill_any_return( "new_goal", "goal", "bad_path" );

			if ( ret != "new_goal" )
				self ClearScriptGoal();

			if ( ret != "goal" )
				return;

			data.doFastContinue = true;
			return;
		}
	}
	else
	{
		javWp = getWaypointForIndex( self getNearestWaypointOfWaypoints( getWaypointsOfType( "javelin" ) ) );
		loc = javWp.jav_point;
	}

	if ( !isDefined( loc ) )
		return;

	self SetBotJavelinLocation( loc );

	if ( self changeToWeapon( "javelin_mp" ) )
	{
		self waittill_any_timeout( 10, "missile_fire", "weapon_change" );
	}

	self ClearBotJavelinLocation();
}

/*
	BOts thinking of using javelins
*/
bot_jav_loc_think()
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );

	data = spawnStruct();
	data.doFastContinue = false;

	for ( ;; )
	{
		self bot_jav_loc_think_loop( data );
	}
}

/*
	Bots thinking of targeting equipment, c4, claymores and TIs
*/
bot_equipment_kill_think_loop()
{
	myteam = self.pers[ "team" ];
	hasSitrep = self _HasPerk( "specialty_detectexplosive" );
	grenades = getEntArray( "grenade", "classname" );
	myEye = self getEye();
	myAngles = self getPlayerAngles();
	dist = 512 * 512;
	target = undefined;

	for ( i = 0; i < grenades.size; i++ )
	{
		item = grenades[i];

		if ( !isDefined( item ) )
			continue;

		if ( !IsDefined( item.name ) )
			continue;

		if ( IsDefined( item.owner ) && ( ( level.teamBased && item.owner.team == self.team ) || item.owner == self ) )
			continue;

		if ( item.name != "c4_mp" && item.name != "claymore_mp" )
			continue;

		if ( !hasSitrep && !bulletTracePassed( myEye, item.origin, false, item ) )
			continue;

		if ( getConeDot( item.origin, self.origin, myAngles ) < 0.6 )
			continue;

		if ( DistanceSquared( item.origin, self.origin ) < dist )
		{
			target = item;
			break;
		}
	}

	grenades = undefined;

	if ( !IsDefined( target ) )
	{
		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[i];

			if ( player == self )
				continue;

			if ( !isDefined( player.team ) )
				continue;

			if ( level.teamBased && player.team == myteam )
				continue;

			ti = player.setSpawnPoint;

			if ( !isDefined( ti ) )
				continue;

			if ( !isDefined( ti.bots ) )
				ti.bots = 0;

			if ( ti.bots >= 2 )
				continue;

			if ( !hasSitrep && !bulletTracePassed( myEye, ti.origin, false, ti ) )
				continue;

			if ( getConeDot( ti.origin, self.origin, myAngles ) < 0.6 )
				continue;

			if ( DistanceSquared( ti.origin, self.origin ) < dist )
			{
				target = ti;
				break;
			}
		}
	}

	if ( !IsDefined( target ) )
		return;

	if ( isDefined( target.enemyTrigger ) && !self HasScriptGoal() && !self.bot_lock_goal )
	{
		self SetScriptGoal( target.origin, 64 );
		self thread bot_inc_bots( target, true );
		self thread bots_watch_touch_obj( target );

		path = self waittill_any_return( "bad_path", "goal", "new_goal" );

		if ( path != "new_goal" )
			self ClearScriptGoal();

		if ( path != "goal" || !isDefined( target ) )
			return;

		if ( randomInt( 100 ) < self.pers["bots"]["behavior"]["camp"] * 8 )
		{
			self thread killCampAfterTime( randomIntRange( 10, 20 ) );
			self thread killCampAfterEntGone( target );
			self CampAtSpot( target.origin, target.origin + ( 0, 0, 42 ) );
		}

		if ( isDefined( target ) )
			target.enemyTrigger notify( "trigger", self );

		return;
	}

	self SetScriptEnemy( target );
	self bot_equipment_attack( target );
	self ClearScriptEnemy();
}

/*
	Bots thinking of targeting equipment, c4, claymores and TIs
*/
bot_equipment_kill_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon ( "game_ended" );

	for ( ;; )
	{
		wait( RandomIntRange( 1, 3 ) );

		if ( self HasScriptEnemy() )
			continue;

		if ( self.pers["bots"]["skill"]["base"] <= 1 )
			continue;

		self bot_equipment_kill_think_loop();
	}
}

/*
	Bots target the equipment for a time then stop
*/
bot_equipment_attack( equ )
{
	wait_time = RandomIntRange( 7, 10 );

	for ( i = 0; i < wait_time; i++ )
	{
		wait( 1 );

		if ( !IsDefined( equ ) )
		{
			return;
		}
	}
}

/*
	Bots will listen to foot steps and target nearby targets
*/
bot_listen_to_steps_loop()
{
	dist = level.bots_listenDist;

	if ( self _hasPerk( "specialty_selectivehearing" ) )
		dist *= 1.4;

	dist *= dist;

	heard = undefined;

	for ( i = level.players.size - 1 ; i >= 0; i-- )
	{
		player = level.players[i];

		if ( player == self )
			continue;

		if ( level.teamBased && self.team == player.team )
			continue;

		if ( player.sessionstate != "playing" )
			continue;

		if ( !isReallyAlive( player ) )
			continue;

		if ( lengthsquared( player getVelocity() ) < 20000 )
			continue;

		if ( distanceSquared( player.origin, self.origin ) > dist )
			continue;

		if ( player _hasPerk( "specialty_quieter" ) )
			continue;

		heard = player;
		break;
	}

	hasHeartbeat = ( isSubStr( self GetCurrentWeapon(), "_heartbeat_" ) && !self IsEMPed() );
	heartbeatDist = 350 * 350;

	if ( !IsDefined( heard ) && hasHeartbeat )
	{
		for ( i = level.players.size - 1 ; i >= 0; i-- )
		{
			player = level.players[i];

			if ( player == self )
				continue;

			if ( level.teamBased && self.team == player.team )
				continue;

			if ( player.sessionstate != "playing" )
				continue;

			if ( !isReallyAlive( player ) )
				continue;

			if ( player _hasPerk( "specialty_heartbreaker" ) )
				continue;

			if ( distanceSquared( player.origin, self.origin ) > heartbeatDist )
				continue;

			if ( GetConeDot( player.origin, self.origin, self GetPlayerAngles() ) < 0.6 )
				continue;

			heard = player;
			break;
		}
	}

	if ( !IsDefined( heard ) )
		return;

	if ( bulletTracePassed( self getEye(), heard getTagOrigin( "j_spineupper" ), false, heard ) )
	{
		self setAttacker( heard );
		return;
	}

	if ( self HasScriptGoal() || self.bot_lock_goal )
		return;

	self SetScriptGoal( heard.origin, 64 );

	if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		self ClearScriptGoal();
}

/*
	Bots will listen to foot steps and target nearby targets
*/
bot_listen_to_steps()
{
	self endon( "disconnect" );
	self endon( "death" );

	for ( ;; )
	{
		wait 1;

		if ( self.pers["bots"]["skill"]["base"] < 3 )
			continue;

		self bot_listen_to_steps_loop();
	}
}

/*
	Bots will look at the uav and target targets
*/
bot_uav_think_loop()
{
	hasRadar = ( ( level.teamBased && level.activeUAVs[self.team] ) || ( !level.teamBased && level.activeUAVs[self.guid] ) );

	if ( level.hardcoreMode && !hasRadar )
		return;

	dist = self.pers["bots"]["skill"]["help_dist"];
	dist *= dist * 8;

	for ( i = level.players.size - 1; i >= 0; i-- )
	{
		player = level.players[i];

		if ( player == self )
			continue;

		if ( !isDefined( player.team ) )
			continue;

		if ( player.sessionstate != "playing" )
			continue;

		if ( level.teambased && player.team == self.team )
			continue;

		if ( !isReallyAlive( player ) )
			continue;

		distFromPlayer = DistanceSquared( self.origin, player.origin );

		if ( distFromPlayer > dist )
			continue;

		if ( ( !isSubStr( player getCurrentWeapon(), "_silencer_" ) && player.bots_firing ) || ( hasRadar && !player _hasPerk( "specialty_coldblooded" ) ) )
		{
			distSq = self.pers["bots"]["skill"]["help_dist"] * self.pers["bots"]["skill"]["help_dist"];

			if ( distFromPlayer < distSq && bulletTracePassed( self getEye(), player getTagOrigin( "j_spineupper" ), false, player ) )
			{
				self SetAttacker( player );
			}

			if ( !self HasScriptGoal() && !self.bot_lock_goal )
			{
				self SetScriptGoal( player.origin, 128 );
				self thread stop_go_target_on_death( player );

				if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
					self ClearScriptGoal();
			}

			break;
		}
	}
}

/*
	Bots will look at the uav and target targets
*/
bot_uav_think()
{
	self endon( "death" );
	self endon( "disconnect" );

	for ( ;; )
	{
		wait 0.75;

		if ( self.pers["bots"]["skill"]["base"] <= 1 )
			continue;

		if ( self isEMPed() || self.bot_isScrambled )
			continue;

		if ( self _hasPerk( "_specialty_blastshield" ) )
			continue;

		if ( ( level.teamBased && level.activeCounterUAVs[level.otherTeam[self.team]] ) || ( !level.teamBased && self.isRadarBlocked ) )
			continue;

		self bot_uav_think_loop();
	}
}

/*
	bots will go to their target's kill location
*/
bot_revenge_think()
{
	self endon( "death" );
	self endon( "disconnect" );

	if ( self.pers["bots"]["skill"]["base"] <= 1 )
		return;

	if ( isDefined( self.lastKiller ) && isReallyAlive( self.lastKiller ) )
	{
		if ( bulletTracePassed( self getEye(), self.lastKiller getTagOrigin( "j_spineupper" ), false, self.lastKiller ) )
		{
			self setAttacker( self.lastKiller );
		}
	}

	if ( !isDefined( self.killerLocation ) )
		return;

	loc = self.killerLocation;

	for ( ;; )
	{
		wait( RandomIntRange( 1, 5 ) );

		if ( self HasScriptGoal() || self.bot_lock_goal )
			return;

		if ( randomint( 100 ) < 75 )
			return;

		self SetScriptGoal( loc, 64 );

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			self ClearScriptGoal();
	}
}

/*
	Watches the target's health, calls 'bad_path'
*/
turret_death_monitor( turret )
{
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( "bad_path" );
	self endon ( "goal" );
	self endon ( "new_goal" );

	for ( ;; )
	{
		wait 0.5;

		if ( !isDefined( turret ) )
			break;

		if ( turret.health <= 20000 )
			break;

		if ( isDefined( turret.carriedBy ) )
			break;
	}

	self notify( "bad_path" );
}

/*
	Bots will target the turret for a time
*/
bot_turret_attack( enemy )
{
	wait_time = RandomIntRange( 7, 10 );

	for ( i = 0; i < wait_time; i++ )
	{
		wait( 1 );

		if ( !IsDefined( enemy ) )
			return;

		if ( enemy.health <= 20000 )
			return;

		if ( isDefined( enemy.carriedBy ) )
			return;

		//if ( !BulletTracePassed( self getEye(), enemy.origin + ( 0, 0, 15 ), false, enemy ) )
		//	return;
	}
}

/*
	Bots will think when to target a turret
*/
bot_turret_think_loop()
{
	myteam = self.pers[ "team" ];
	turretsKeys = getArrayKeys( level.turrets );

	if ( turretsKeys.size == 0 )
	{
		wait( randomintrange( 3, 5 ) );
		return;
	}

	if ( self.pers["bots"]["skill"]["base"] <= 1 )
		return;

	if ( self HasScriptEnemy() || self IsUsingRemote() )
		return;

	myEye = self GetEye();
	turret = undefined;

	for ( i = turretsKeys.size - 1; i >= 0; i-- )
	{
		tempTurret = level.turrets[turretsKeys[i]];

		if ( !isDefined( tempTurret ) )
			continue;

		if ( tempTurret.health <= 20000 )
			continue;

		if ( isDefined( tempTurret.carriedBy ) )
			continue;

		if ( isDefined( tempTurret.owner ) && tempTurret.owner == self )
			continue;

		if ( level.teamBased && tempTurret.team == myteam )
			continue;

		if ( !bulletTracePassed( myEye, tempTurret.origin + ( 0, 0, 15 ), false, tempTurret ) )
			continue;

		turret = tempTurret;
	}

	turretsKeys = undefined;

	if ( !isDefined( turret ) )
		return;

	forward = AnglesToForward( turret.angles );
	forward = VectorNormalize( forward );

	delta = self.origin - turret.origin;
	delta = VectorNormalize( delta );

	dot = VectorDot( forward, delta );

	facing = true;

	if ( dot < 0.342 ) // cos 70 degrees
		facing = false;

	if ( turret isStunned() )
		facing = false;

	if ( self _hasPerk( "specialty_coldblooded" ) )
		facing = false;

	if ( facing && !BulletTracePassed( myEye, turret.origin + ( 0, 0, 15 ), false, turret ) )
		return;

	if ( !IsDefined( turret.bots ) )
		turret.bots = 0;

	if ( turret.bots >= 2 )
		return;

	if ( !facing && !self HasScriptGoal() && !self.bot_lock_goal )
	{
		self SetScriptGoal( turret.origin, 32 );
		self thread bot_inc_bots( turret, true );
		self thread turret_death_monitor( turret );
		self thread bots_watch_touch_obj( turret );

		if ( self waittill_any_return( "bad_path", "goal", "new_goal" ) != "new_goal" )
			self ClearScriptGoal();
	}

	if ( !isDefined( turret ) )
		return;

	self SetScriptEnemy( turret, ( 0, 0, 25 ) );
	self bot_turret_attack( turret );
	self ClearScriptEnemy();
}

/*
	Bots will think when to target a turret
*/
bot_turret_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon ( "game_ended" );

	for ( ;; )
	{
		wait( 1 );

		self bot_turret_think_loop();
	}
}

/*
	Checks if the bot is stuck on a carepackage
*/
bot_watch_stuck_on_crate_loop()
{
	crates = getEntArray( "care_package", "targetname" );

	if ( crates.size == 0 )
		return;

	crate = undefined;

	for ( i = crates.size - 1; i >= 0; i-- )
	{
		tempCrate = crates[i];

		if ( !isDefined( tempCrate ) )
			continue;

		if ( !isDefined( tempCrate.doingPhysics ) || tempCrate.doingPhysics )
			continue;

		if ( isDefined( crate ) && DistanceSquared( crate.origin, self.origin ) < DistanceSquared( tempCrate.origin, self.origin ) )
			continue;

		crate = tempCrate;
	}

	if ( !isDefined( crate ) )
		return;

	radius = GetDvarFloat( "player_useRadius" );

	if ( DistanceSquared( crate.origin, self.origin ) > radius * radius )
		return;

	self.bot_stuck_on_carepackage = crate;
	self notify( "crate_physics_done" );
}

/*
	Checks if the bot is stuck on a carepackage
*/
bot_watch_stuck_on_crate()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	for ( ;; )
	{
		wait 3;

		if ( self HasThreat() )
			continue;

		self bot_watch_stuck_on_crate_loop();
	}
}

/*
	Bots will capture carepackages
*/
bot_crate_think_loop( data )
{
	ret = "crate_physics_done";

	if ( data.first )
		data.first = false;
	else
		ret = self waittill_any_timeout( randomintrange( 3, 5 ), "crate_physics_done" );

	myteam = self.pers[ "team" ];
	crate = self.bot_stuck_on_carepackage;
	self.bot_stuck_on_carepackage = undefined;

	if ( !isDefined( crate ) )
	{
		if ( RandomInt( 100 ) < 20 && ret != "crate_physics_done" )
			return;

		if ( self HasScriptGoal() || self.bot_lock_goal )
			return;

		if ( self isDefusing() || self isPlanting() )
			return;

		if ( self IsUsingRemote() || self BotIsFrozen() )
			return;

		if ( self inLastStand() )
			return;

		crates = getEntArray( "care_package", "targetname" );

		if ( crates.size == 0 )
			return;

		wantsClosest = randomint( 2 );

		crate = undefined;

		for ( i = crates.size - 1; i >= 0; i-- )
		{
			tempCrate = crates[i];

			if ( !isDefined( tempCrate ) )
				continue;

			if ( !isDefined( tempCrate.doingPhysics ) || tempCrate.doingPhysics )
				continue;

			if ( !IsDefined( tempCrate.bots ) )
				tempCrate.bots = 0;

			if ( tempCrate.bots >= 3 )
				continue;

			if ( isDefined( crate ) )
			{
				if ( wantsClosest )
				{
					if ( DistanceSquared( crate.origin, self.origin ) < DistanceSquared( tempCrate.origin, self.origin ) )
						continue;
				}
				else
				{
					if ( maps\mp\killstreaks\_killstreaks::getStreakCost( crate.crateType ) > maps\mp\killstreaks\_killstreaks::getStreakCost( tempCrate.crateType ) )
						continue;
				}
			}

			crate = tempCrate;
		}

		crates = undefined;

		if ( !isDefined( crate ) )
			return;

		self.bot_lock_goal = true;

		radius = GetDvarFloat( "player_useRadius" );
		self SetScriptGoal( crate.origin, radius );
		self thread bot_inc_bots( crate, true );
		self thread bots_watch_touch_obj( crate );

		path = self waittill_any_return( "bad_path", "goal", "new_goal" );

		self.bot_lock_goal = false;

		if ( path != "new_goal" )
			self ClearScriptGoal();

		if ( path != "goal" || !isDefined( crate ) || DistanceSquared( self.origin, crate.origin ) > radius * radius )
			return;
	}

	self _DisableWeapon();
	self BotFreezeControls( true );

	waitTime = 3;

	if ( isDefined( crate.owner ) && crate.owner == self )
		waitTime = 0.5;

	crate waittill_notify_or_timeout( "captured", waitTime );

	self _EnableWeapon();
	self BotFreezeControls( false );

	self notify( "bot_force_check_switch" );

	if ( !isDefined( crate ) )
		return;

	crate notify ( "captured", self );
}

/*
	Bots will capture carepackages
*/
bot_crate_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	data = spawnStruct();
	data.first = true;

	for ( ;; )
	{
		self bot_crate_think_loop( data );
	}
}

/*
	Reload cancels
*/
doReloadCancel_loop()
{
	ret = self waittill_any_return( "reload", "weapon_change" );

	if ( self BotIsFrozen() )
		return;

	if ( self isDefusing() || self isPlanting() )
		return;

	if ( self IsUsingRemote() )
		return;

	if ( self InLastStand() && !self InFinalStand() )
		return;

	curWeap = self GetCurrentWeapon();

	if ( !maps\mp\gametypes\_weapons::isPrimaryWeapon( curWeap ) )
		return;

	if ( ret == "reload" )
	{
		// check single reloads
		if ( self GetWeaponAmmoClip( curWeap ) < WeaponClipSize( curWeap ) )
			return;
	}

	// check difficulty
	if ( self.pers["bots"]["skill"]["base"] <= 3 )
		return;

	// check if got another weapon
	weaponslist = self GetWeaponsListPrimaries();
	weap = "";

	while ( weaponslist.size )
	{
		weapon = weaponslist[randomInt( weaponslist.size )];
		weaponslist = array_remove( weaponslist, weapon );

		if ( !maps\mp\gametypes\_weapons::isPrimaryWeapon( weapon ) )
			continue;

		if ( curWeap == weapon || weapon == "none" || weapon == "" )
			continue;

		weap = weapon;
		break;
	}

	if ( weap == "" )
		return;

	// do the cancel
	wait 0.1;
	self thread ChangeToWeapon( weap );
	wait 0.25;
	self thread ChangeToWeapon( curWeap );
	wait 2;
}

/*
	Reload cancels
*/
doReloadCancel()
{
	self endon( "disconnect" );
	self endon( "death" );

	for ( ;; )
	{
		self doReloadCancel_loop();
	}
}

/*
	Bots will think to switch weapons
*/
bot_weapon_think_loop( data )
{
	self waittill_any_timeout( randomIntRange( 2, 4 ), "bot_force_check_switch" );

	if ( self BotIsFrozen() )
		return;

	if ( self isDefusing() || self isPlanting() )
		return;

	if ( self IsUsingRemote() )
		return;

	if ( self InLastStand() && !self InFinalStand() )
		return;

	curWeap = self GetCurrentWeapon();
	hasTarget = self hasThreat();

	if ( hasTarget )
	{
		threat = self getThreat();
		rocketAmmo = self getRocketAmmo();

		if ( entIsVehicle( threat ) && isDefined( rocketAmmo ) )
		{
			if ( curWeap != rocketAmmo )
				self thread ChangeToWeapon( rocketAmmo );

			return;
		}
	}

	if ( self HasBotJavelinLocation() && self GetAmmoCount( "javelin_mp" ) )
	{
		if ( curWeap != "javelin_mp" )
			self thread ChangeToWeapon( "javelin_mp" );

		return;
	}

	if ( isDefined( self.bot_oma_class ) )
	{
		if ( curWeap != "onemanarmy_mp" )
			self thread ChangeToWeapon( "onemanarmy_mp" );

		return;
	}

	if ( data.first )
	{
		data.first = false;

		if ( randomInt( 100 ) > self.pers["bots"]["behavior"]["initswitch"] )
			return;
	}
	else
	{
		if ( curWeap != "none" && self getAmmoCount( curWeap ) && curWeap != "stinger_mp" && curWeap != "javelin_mp" && curWeap != "onemanarmy_mp" )
		{
			if ( randomInt( 100 ) > self.pers["bots"]["behavior"]["switch"] )
				return;

			if ( hasTarget )
				return;
		}
	}

	weaponslist = self getweaponslistall();
	weap = "";

	while ( weaponslist.size )
	{
		weapon = weaponslist[randomInt( weaponslist.size )];
		weaponslist = array_remove( weaponslist, weapon );

		if ( !self getAmmoCount( weapon ) )
			continue;

		if ( !isWeaponPrimary( weapon ) )
			continue;

		if ( curWeap == weapon || weapon == "none" || weapon == "" || weapon == "javelin_mp" || weapon == "stinger_mp" || weapon == "onemanarmy_mp" )
			continue;

		weap = weapon;
		break;
	}

	if ( weap == "" )
		return;

	self thread ChangeToWeapon( weap );
}

/*
	Bots will think to switch weapons
*/
bot_weapon_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	data = spawnStruct();
	data.first = true;

	for ( ;; )
	{
		self bot_weapon_think_loop( data );
	}
}

/*
	Bots think when to target vehicles
*/
bot_target_vehicle_loop()
{
	rocketAmmo = self getRocketAmmo();

	if ( !isDefined( rocketAmmo ) && self BotGetRandom() < 90 )
		return;

	if ( isDefined( rocketAmmo ) && rocketAmmo == "javelin_mp" && self isEMPed() )
		return;

	targets = maps\mp\_stinger::GetTargetList();

	if ( !targets.size )
		return;

	lockOnAmmo = self getLockonAmmo();
	myEye = self GetEye();
	target = undefined;

	for ( i = targets.size - 1; i >= 0; i-- )
	{
		tempTarget = targets[i];

		if ( isDefined( tempTarget.owner ) && tempTarget.owner == self )
			continue;

		if ( !bulletTracePassed( myEye, tempTarget.origin, false, tempTarget ) )
			continue;

		if ( tempTarget.health <= 0 )
			continue;

		if ( tempTarget.classname != "script_vehicle" && !isDefined( lockOnAmmo ) )
			continue;

		target = tempTarget;
	}

	targets = undefined;

	if ( !isDefined( target ) )
		return;

	self SetScriptEnemy( target, ( 0, 0, 0 ) );
	self bot_attack_vehicle( target );
	self ClearScriptEnemy();
	self notify( "bot_force_check_switch" );
}

/*
	Bots think when to target vehicles
*/
bot_target_vehicle()
{
	self endon( "disconnect" );
	self endon( "death" );

	for ( ;; )
	{
		wait randomIntRange( 2, 4 );

		if ( self.pers["bots"]["skill"]["base"] <= 1 )
			continue;

		if ( self HasScriptEnemy() )
			continue;

		if ( self IsUsingRemote() )
			continue;

		self bot_target_vehicle_loop();
	}
}

/*
	Bots target the killstreak for a time and stops
*/
bot_attack_vehicle( target )
{
	target endon( "death" );

	wait_time = RandomIntRange( 7, 10 );

	for ( i = 0; i < wait_time; i++ )
	{
		self notify( "bot_force_check_switch" );
		wait( 1 );

		if ( !IsDefined( target ) )
		{
			return;
		}
	}
}

/*
	Returns an origin thats good to use for a kill streak
*/
getKillstreakTargetLocation()
{
	location = undefined;
	players = [];

	for ( i = level.players.size - 1; i >= 0; i-- )
	{
		player = level.players[i];

		if ( player == self )
			continue;

		if ( !isDefined( player.team ) )
			continue;

		if ( level.teamBased && self.team == player.team )
			continue;

		if ( player.sessionstate != "playing" )
			continue;

		if ( !isReallyAlive( player ) )
			continue;

		if ( player _hasPerk( "specialty_coldblooded" ) )
			continue;

		if ( !bulletTracePassed( player.origin, player.origin + ( 0, 0, 2048 ), false, player ) && self.pers["bots"]["skill"]["base"] > 3 )
			continue;

		players[players.size] = player;
	}

	target = random( players );

	if ( isDefined( target ) )
		location = target.origin + ( randomIntRange( ( 8 - self.pers["bots"]["skill"]["base"] ) * -75, ( 8 - self.pers["bots"]["skill"]["base"] ) * 75 ), randomIntRange( ( 8 - self.pers["bots"]["skill"]["base"] ) * -75, ( 8 - self.pers["bots"]["skill"]["base"] ) * 75 ), 0 );
	else if ( self.pers["bots"]["skill"]["base"] <= 3 )
		location = self.origin + ( randomIntRange( -512, 512 ), randomIntRange( -512, 512 ), 0 );

	return location;
}

/*
	Clears remote usage when bot dies
*/
clear_remote_on_death( isac130 )
{
	self endon( "bot_clear_remote_on_death" );
	level endon( "game_ended" );

	self waittill_either( "death", "disconnect" );

	if ( isDefined( isac130 ) && isac130 )
		level.ac130InUse = false;

	if ( isDefined( self ) )
		self ClearUsingRemote();
}

/*
	Returns if any harriers exists that is an enemy
*/
isAnyEnemyPlanes()
{
	if ( !isDefined( level.harriers ) )
		return false;

	for ( i = 0; i < level.harriers.size; i++ )
	{
		plane = level.harriers[i];

		if ( !isDefined( plane ) )
			continue;

		if ( level.teamBased && plane.team == self.team )
			continue;

		if ( isDefined( plane.owner ) && plane.owner == self )
			continue;

		return true;
	}

	return false;
}

/*
	Bots think to use killstreaks
*/
bot_killstreak_think_loop( data )
{
	if ( data.doFastContinue )
		data.doFastContinue = false;
	else
	{
		wait randomIntRange( 1, 3 );
	}

	if ( !isDefined( self.pers["killstreaks"][0] ) )
		return;

	if ( self BotIsFrozen() )
		return;

	if ( self HasThreat() || self HasBotJavelinLocation() )
		return;

	if ( self isDefusing() || self isPlanting() )
		return;

	if ( self isEMPed() )
		return;

	if ( self IsUsingRemote() )
		return;

	if ( self InLastStand() && !self InFinalStand() )
		return;


	if ( isDefined( self.isCarrying ) && self.isCarrying )
		self notify( "place_sentry" );

	curWeap = self GetCurrentWeapon();

	if ( isSubStr( curWeap, "airdrop_" ) )
		self thread BotPressAttack( 0.05 );


	streakName = self.pers["killstreaks"][0].streakName;

	if ( level.inGracePeriod && maps\mp\killstreaks\_killstreaks::deadlyKillstreak( streakName ) )
		return;

	ksWeap = maps\mp\killstreaks\_killstreaks::getKillstreakWeapon( streakName );

	if ( curWeap == "none" || !isWeaponPrimary( curWeap ) )
		curWeap = self GetLastWeapon();

	lifeId = self.pers["killstreaks"][0].lifeId;

	if ( !isDefined( lifeId ) )
		lifeId = -1;

	if ( isStrStart( streakName, "helicopter_" ) && self isAnyEnemyPlanes() && self.pers["bots"]["skill"]["base"] > 3 )
		return;

	if ( maps\mp\killstreaks\_killstreaks::isRideKillstreak( streakName ) || maps\mp\killstreaks\_killstreaks::isCarryKillstreak( streakName ) )
	{
		if ( self inLastStand() )
			return;

		if ( lifeId == self.deaths && !self HasScriptGoal() && !self.bot_lock_goal && streakName != "sentry" && !self nearAnyOfWaypoints( 128, getWaypointsOfType( "camp" ) ) )
		{
			campSpot = getWaypointForIndex( random( self waypointsNear( getWaypointsOfType( "camp" ), 1024 ) ) );

			if ( isDefined( campSpot ) )
			{
				self SetScriptGoal( campSpot.origin, 16 );

				if ( self waittill_any_return( "new_goal", "goal", "bad_path" ) != "new_goal" )
					self ClearScriptGoal();

				data.doFastContinue = true;
				return;
			}
		}

		if ( streakName == "sentry" )
		{
			if ( self HasScriptAimPos() )
				return;

			myEye = self GetEye();
			angles = self GetPlayerAngles();

			forwardTrace = bulletTrace( myEye, myEye + AnglesToForward( angles ) * 1024, false, self );

			if ( DistanceSquared( self.origin, forwardTrace["position"] ) < 1000 * 1000 && self.pers["bots"]["skill"]["base"] > 3 )
				return;

			self BotStopMoving( true );
			self SetScriptAimPos( forwardTrace["position"] );

			if ( !self changeToWeapon( ksWeap ) )
			{
				self BotStopMoving( false );
				self ClearScriptAimPos();
				return;
			}

			wait 1;
			self notify( "place_sentry" );
			wait 0.05;
			self notify( "cancel_sentry" );
			wait 0.5;

			self thread changeToWeapon( curWeap );

			self BotStopMoving( false );
			self ClearScriptAimPos();
		}
		else if ( streakName == "predator_missile" )
		{
			location = self getKillstreakTargetLocation();

			if ( !isDefined( location ) )
				return;

			self setUsingRemote( "remotemissile" );
			self thread clear_remote_on_death();
			self BotStopMoving( true );

			if ( !self changeToWeapon( ksWeap ) )
			{
				self ClearUsingRemote();
				self notify( "bot_clear_remote_on_death" );
				self BotStopMoving( false );
				return;
			}

			wait 1;
			self notify( "bot_clear_remote_on_death" );
			self BotStopMoving( false );

			if ( self isEMPed() )
			{
				self ClearUsingRemote();
				self thread changeToWeapon( curWeap );
				return;
			}

			self BotFreezeControls( true );

			self maps\mp\killstreaks\_killstreaks::usedKillstreak( "predator_missile", true );
			self maps\mp\killstreaks\_killstreaks::shuffleKillStreaksFILO( "predator_missile" );
			self maps\mp\killstreaks\_killstreaks::giveOwnedKillstreakItem();

			rocket = MagicBullet( "remotemissile_projectile_mp", self.origin + ( 0.0, 0.0, 7000.0 - ( self.pers["bots"]["skill"]["base"] * 400 ) ), location, self );
			rocket.lifeId = lifeId;
			rocket.type = "remote";

			rocket thread maps\mp\gametypes\_weapons::AddMissileToSightTraces( self.pers["team"] );
			rocket thread maps\mp\killstreaks\_remotemissile::handleDamage();
			thread maps\mp\killstreaks\_remotemissile::MissileEyes( self, rocket );

			self waittill( "stopped_using_remote" );

			wait 1;
			self BotFreezeControls( false );
			self thread changeToWeapon( curWeap );
		}
		else if ( streakName == "ac130" )
		{
			if ( isDefined( level.ac130player ) || level.ac130InUse )
				return;

			self BotStopMoving( true );
			self changeToWeapon( ksWeap );
			self BotStopMoving( false );

			wait 3;

			if ( !isDefined( level.ac130player ) || level.ac130player != self )
				self thread changeToWeapon( curWeap );
		}
		else if ( streakName == "helicopter_minigun" )
		{
			if ( isDefined( level.chopper ) )
				return;

			self BotStopMoving( true );
			self changeToWeapon( ksWeap );
			self BotStopMoving( false );

			wait 3;

			if ( !isDefined( level.chopper ) || !isDefined( level.chopper.gunner ) || level.chopper.gunner != self )
				self thread changeToWeapon( curWeap );
		}
	}
	else
	{
		if ( streakName == "airdrop_mega" || streakName == "airdrop_sentry_minigun" || streakName == "airdrop" )
		{
			if ( self HasScriptAimPos() )
				return;

			if ( streakName != "airdrop_mega" && level.littleBirds > 2 )
				return;

			if ( !bulletTracePassed( self.origin, self.origin + ( 0, 0, 2048 ), false, self ) && self.pers["bots"]["skill"]["base"] > 3 )
				return;

			myEye = self GetEye();
			angles = self GetPlayerAngles();

			forwardTrace = bulletTrace( myEye, myEye + AnglesToForward( angles ) * 256, false, self );

			if ( DistanceSquared( self.origin, forwardTrace["position"] ) < 96 * 96 && self.pers["bots"]["skill"]["base"] > 3 )
				return;

			if ( !bulletTracePassed( forwardTrace["position"], forwardTrace["position"] + ( 0, 0, 2048 ), false, self ) && self.pers["bots"]["skill"]["base"] > 3 )
				return;

			self BotStopMoving( true );
			self SetScriptAimPos( forwardTrace["position"] );

			if ( !self changeToWeapon( ksWeap ) )
			{
				self BotStopMoving( false );
				self ClearScriptAimPos();
				return;
			}

			self thread fire_current_weapon();

			ret = self waittill_any_timeout( 5, "grenade_fire" );

			self notify( "stop_firing_weapon" );
			self thread changeToWeapon( curWeap );

			if ( ret == "timeout" )
			{
				self BotStopMoving( false );
				self ClearScriptAimPos();
				return;
			}

			if ( randomInt( 100 ) < 80 && !self HasScriptGoal() && !self.bot_lock_goal )
				self waittill_any_timeout( 15, "crate_physics_done", "new_goal" );

			self BotStopMoving( false );
			self ClearScriptAimPos();
		}
		else
		{
			if ( streakName == "harrier_airstrike" && level.planes > 1 )
				return;

			if ( streakName == "nuke" && isDefined( level.nukeIncoming ) )
				return;

			if ( streakName == "counter_uav" && self.pers["bots"]["skill"]["base"] > 3 && ( ( level.teamBased && level.activeCounterUAVs[self.team] ) || ( !level.teamBased && level.activeCounterUAVs[self.guid] ) ) )
				return;

			if ( streakName == "uav" && self.pers["bots"]["skill"]["base"] > 3 && ( ( level.teamBased && ( level.activeUAVs[self.team] || level.activeCounterUAVs[level.otherTeam[self.team]] ) ) || ( !level.teamBased && ( level.activeUAVs[self.guid] || self.isRadarBlocked ) ) ) )
				return;

			if ( streakName == "emp" && self.pers["bots"]["skill"]["base"] > 3 && ( ( level.teamBased && level.teamEMPed[level.otherTeam[self.team]] ) || ( !level.teamBased && isDefined( level.empPlayer ) ) ) )
				return;

			location = undefined;
			directionYaw = undefined;

			switch ( streakName )
			{
				case "harrier_airstrike":
				case "stealth_airstrike":
				case "precision_airstrike":
					location = self getKillstreakTargetLocation();
					directionYaw = randomInt( 360 );

					if ( !isDefined( location ) )
						return;

				case "helicopter":
				case "helicopter_flares":
				case "uav":
				case "nuke":
				case "counter_uav":
				case "emp":
					self BotStopMoving( true );

					if ( self changeToWeapon( ksWeap ) )
					{
						wait 1;

						if ( isDefined( location ) )
						{
							self BotFreezeControls( true );

							self notify( "confirm_location", location, directionYaw );
							wait 1;

							self BotFreezeControls( false );
						}

						self thread changeToWeapon( curWeap );
					}

					self BotStopMoving( false );
					break;
			}
		}
	}
}

/*
	Bots think to use killstreaks
*/
bot_killstreak_think()
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );

	data = spawnStruct();
	data.doFastContinue = false;

	for ( ;; )
	{
		self bot_killstreak_think_loop( data );
	}
}

/*
	Bots hang around the enemy's flag to spawn kill em
*/
bot_dom_spawn_kill_think_loop()
{
	myTeam = self.pers[ "team" ];
	otherTeam = getOtherTeam( myTeam );
	myFlagCount = maps\mp\gametypes\dom::getTeamFlagCount( myTeam );

	if ( myFlagCount == level.flags.size )
		return;

	otherFlagCount = maps\mp\gametypes\dom::getTeamFlagCount( otherTeam );

	if ( myFlagCount <= otherFlagCount || otherFlagCount != 1 )
		return;

	flag = undefined;

	for ( i = 0; i < level.flags.size; i++ )
	{
		if ( level.flags[i] maps\mp\gametypes\dom::getFlagTeam() == myTeam )
			continue;

		flag = level.flags[i];
	}

	if ( !isDefined( flag ) )
		return;

	if ( DistanceSquared( self.origin, flag.origin ) < 2048 * 2048 )
		return;

	self SetScriptGoal( flag.origin, 1024 );

	self thread bot_dom_watch_flags( myFlagCount, myTeam );

	if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		self ClearScriptGoal();
}

/*
	Bots hang around the enemy's flag to spawn kill em
*/
bot_dom_spawn_kill_think()
{
	self endon( "death" );
	self endon( "disconnect" );

	if ( level.gametype != "dom" )
		return;

	for ( ;; )
	{
		wait( randomintrange( 10, 20 ) );

		if ( randomint( 100 ) < 20 )
			continue;

		if ( self HasScriptGoal() || self.bot_lock_goal )
			continue;

		self bot_dom_spawn_kill_think_loop();
	}
}

/*
	Calls 'bad_path' when the flag count changes
*/
bot_dom_watch_flags( count, myTeam )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	for ( ;; )
	{
		wait 0.5;

		if ( maps\mp\gametypes\dom::getTeamFlagCount( myTeam ) != count )
			break;
	}

	self notify( "bad_path" );
}

/*
	Bots watches their own flags and protects them when they are under capture
*/
bot_dom_def_think_loop()
{
	myTeam = self.pers[ "team" ];
	flag = undefined;

	for ( i = 0; i < level.flags.size; i++ )
	{
		if ( level.flags[i] maps\mp\gametypes\dom::getFlagTeam() != myTeam )
			continue;

		if ( !level.flags[i].useObj.objPoints[myTeam].isFlashing )
			continue;

		if ( !isDefined( flag ) || DistanceSquared( self.origin, level.flags[i].origin ) < DistanceSquared( self.origin, flag.origin ) )
			flag = level.flags[i];
	}

	if ( !isDefined( flag ) )
		return;

	self SetScriptGoal( flag.origin, 128 );

	self thread bot_dom_watch_for_flashing( flag, myTeam );
	self thread bots_watch_touch_obj( flag );

	if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		self ClearScriptGoal();
}

/*
	Bots watches their own flags and protects them when they are under capture
*/
bot_dom_def_think()
{
	self endon( "death" );
	self endon( "disconnect" );

	if ( level.gametype != "dom" )
		return;

	for ( ;; )
	{
		wait( randomintrange( 1, 3 ) );

		if ( randomint( 100 ) < 35 )
			continue;

		if ( self HasScriptGoal() || self.bot_lock_goal )
			continue;

		self bot_dom_def_think_loop();
	}
}

/*
	Watches while the flag is under capture
*/
bot_dom_watch_for_flashing( flag, myTeam )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	for ( ;; )
	{
		wait 0.5;

		if ( !isDefined( flag ) )
			break;

		if ( flag maps\mp\gametypes\dom::getFlagTeam() != myTeam || !flag.useObj.objPoints[myTeam].isFlashing )
			break;
	}

	self notify( "bad_path" );
}

/*
	Bots capture dom flags
*/
bot_dom_cap_think_loop()
{
	myTeam = self.pers[ "team" ];
	otherTeam = getOtherTeam( myTeam );

	myFlagCount = maps\mp\gametypes\dom::getTeamFlagCount( myTeam );

	if ( myFlagCount == level.flags.size )
		return;

	otherFlagCount = maps\mp\gametypes\dom::getTeamFlagCount( otherTeam );

	if ( game["teamScores"][myteam] >= game["teamScores"][otherTeam] )
	{
		if ( myFlagCount < otherFlagCount )
		{
			if ( randomint( 100 ) < 15 )
				return;
		}
		else if ( myFlagCount == otherFlagCount )
		{
			if ( randomint( 100 ) < 35 )
				return;
		}
		else if ( myFlagCount > otherFlagCount )
		{
			if ( randomint( 100 ) < 95 )
				return;
		}
	}

	flag = undefined;
	flags = [];

	for ( i = 0; i < level.flags.size; i++ )
	{
		if ( level.flags[i] maps\mp\gametypes\dom::getFlagTeam() == myTeam )
			continue;

		flags[flags.size] = level.flags[i];
	}

	if ( randomInt( 100 ) > 30 )
	{
		for ( i = 0; i < flags.size; i++ )
		{
			if ( !isDefined( flag ) || DistanceSquared( self.origin, level.flags[i].origin ) < DistanceSquared( self.origin, flag.origin ) )
				flag = level.flags[i];
		}
	}
	else if ( flags.size )
	{
		flag = random( flags );
	}

	if ( !isDefined( flag ) )
		return;

	self.bot_lock_goal = true;
	self SetScriptGoal( flag.origin, 64 );

	self thread bot_dom_go_cap_flag( flag, myteam );

	event = self waittill_any_return( "goal", "bad_path", "new_goal" );

	if ( event != "new_goal" )
		self ClearScriptGoal();

	if ( event != "goal" )
	{
		self.bot_lock_goal = false;
		return;
	}

	self SetScriptGoal( self.origin, 64 );

	while ( flag maps\mp\gametypes\dom::getFlagTeam() != myTeam && self isTouching( flag ) )
	{
		cur = flag.useObj.curProgress;
		wait 0.5;

		if ( flag.useObj.curProgress == cur )
			break;//some enemy is near us, kill him
	}

	self ClearScriptGoal();

	self.bot_lock_goal = false;
}

/*
	Bots capture dom flags
*/
bot_dom_cap_think()
{
	self endon( "death" );
	self endon( "disconnect" );

	if ( level.gametype != "dom" )
		return;

	for ( ;; )
	{
		wait( randomintrange( 3, 12 ) );

		if ( self.bot_lock_goal )
		{
			continue;
		}

		if ( !isDefined( level.flags ) || level.flags.size == 0 )
			continue;

		self bot_dom_cap_think_loop();
	}
}

/*
	Bot goes to the flag, watching while they don't have the flag
*/
bot_dom_go_cap_flag( flag, myteam )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	for ( ;; )
	{
		wait randomintrange( 2, 4 );

		if ( !isDefined( flag ) )
			break;

		if ( flag maps\mp\gametypes\dom::getFlagTeam() == myTeam )
			break;

		if ( self isTouching( flag ) )
			break;
	}

	if ( flag maps\mp\gametypes\dom::getFlagTeam() == myTeam )
		self notify( "bad_path" );
	else
		self notify( "goal" );
}

/*
	Bots play headquarters
*/
bot_hq_loop()
{
	myTeam = self.pers[ "team" ];
	otherTeam = getOtherTeam( myTeam );

	radio = level.radio;
	gameobj = radio.gameobject;
	origin = ( radio.origin[0], radio.origin[1], radio.origin[2] + 5 );

	//if neut or enemy
	if ( gameobj.ownerTeam != myTeam )
	{
		if ( gameobj.interactTeam == "none" ) //wait for it to become active
		{
			if ( self HasScriptGoal() )
				return;

			if ( DistanceSquared( origin, self.origin ) <= 1024 * 1024 )
				return;

			self SetScriptGoal( origin, 256 );

			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
				self ClearScriptGoal();

			return;
		}

		//capture it

		self.bot_lock_goal = true;
		self SetScriptGoal( origin, 64 );
		self thread bot_hq_go_cap( gameobj, radio );

		event = self waittill_any_return( "goal", "bad_path", "new_goal" );

		if ( event != "new_goal" )
			self ClearScriptGoal();

		if ( event != "goal" )
		{
			self.bot_lock_goal = false;
			return;
		}

		if ( !self isTouching( gameobj.trigger ) || level.radio != radio )
		{
			self.bot_lock_goal = false;
			return;
		}

		self SetScriptGoal( self.origin, 64 );

		while ( self isTouching( gameobj.trigger ) && gameobj.ownerTeam != myTeam && level.radio == radio )
		{
			cur = gameobj.curProgress;
			wait 0.5;

			if ( cur == gameobj.curProgress )
				break;//no prog made, enemy must be capping
		}

		self ClearScriptGoal();
		self.bot_lock_goal = false;
	}
	else//we own it
	{
		if ( gameobj.objPoints[myteam].isFlashing ) //underattack
		{
			self.bot_lock_goal = true;
			self SetScriptGoal( origin, 64 );
			self thread bot_hq_watch_flashing( gameobj, radio );

			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
				self ClearScriptGoal();

			self.bot_lock_goal = false;
			return;
		}

		if ( self HasScriptGoal() )
			return;

		if ( DistanceSquared( origin, self.origin ) <= 1024 * 1024 )
			return;

		self SetScriptGoal( origin, 256 );

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			self ClearScriptGoal();
	}
}

/*
	Bots play headquarters
*/
bot_hq()
{
	self endon( "death" );
	self endon( "disconnect" );

	if ( level.gametype != "koth" )
		return;

	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );

		if ( self.bot_lock_goal )
		{
			continue;
		}

		if ( !isDefined( level.radio ) )
			continue;

		if ( !isDefined( level.radio.gameobject ) )
			continue;

		self bot_hq_loop();
	}
}

/*
	Waits until not touching the trigger and it is the current radio.
*/
bot_hq_go_cap( obj, radio )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	for ( ;; )
	{
		wait randomintrange( 2, 4 );

		if ( !isDefined( obj ) )
			break;

		if ( self isTouching( obj.trigger ) )
			break;

		if ( level.radio != radio )
			break;
	}

	if ( level.radio != radio )
		self notify( "bad_path" );
	else
		self notify( "goal" );
}

/*
	Waits while the radio is under attack.
*/
bot_hq_watch_flashing( obj, radio )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	myteam = self.team;

	for ( ;; )
	{
		wait 0.5;

		if ( !isDefined( obj ) )
			break;

		if ( !obj.objPoints[myteam].isFlashing )
			break;

		if ( level.radio != radio )
			break;
	}

	self notify( "bad_path" );
}

/*
	Bots play sab
*/
bot_sab_loop()
{
	myTeam = self.pers[ "team" ];
	otherTeam = getOtherTeam( myTeam );

	bomb = level.sabBomb;
	bombteam = bomb.ownerTeam;
	carrier = bomb.carrier;
	timeleft = maps\mp\gametypes\_gamelogic::getTimeRemaining() / 1000;

	// the bomb is ours, we are on the offence
	if ( bombteam == myTeam )
	{
		site = level.bombZones[otherTeam];
		origin = ( site.curorigin[0] + 50, site.curorigin[1] + 50, site.curorigin[2] + 5 );

		// protect our planted bomb
		if ( level.bombPlanted )
		{
			// kill defuser
			if ( site isInUse() ) //somebody is defusing our bomb we planted
			{
				self.bot_lock_goal = true;
				self SetScriptGoal( origin, 64 );

				self thread bot_defend_site( site );

				if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
					self ClearScriptGoal();

				self.bot_lock_goal = false;
				return;
			}

			//else hang around the site
			if ( DistanceSquared( origin, self.origin ) <= 1024 * 1024 )
				return;

			self.bot_lock_goal = true;
			self SetScriptGoal( origin, 256 );

			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
				self ClearScriptGoal();

			self.bot_lock_goal = false;
			return;
		}

		// we are not the carrier
		if ( !self isBombCarrier() )
		{
			// lets escort the bomb carrier
			if ( self HasScriptGoal() )
				return;

			origin = carrier.origin;

			if ( DistanceSquared( origin, self.origin ) <= 1024 * 1024 )
				return;

			self SetScriptGoal( origin, 256 );
			self thread bot_escort_obj( bomb, carrier );

			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
				self ClearScriptGoal();

			return;
		}

		// we are the carrier of the bomb, lets check if we need to plant
		timepassed = getTimePassed() / 1000;

		if ( timepassed < 120 && timeleft >= 90 && randomInt( 100 ) < 98 )
			return;

		self.bot_lock_goal = true;
		self SetScriptGoal( origin, 1 );

		self thread bot_go_plant( site );
		event = self waittill_any_return( "goal", "bad_path", "new_goal" );

		if ( event != "new_goal" )
			self ClearScriptGoal();

		if ( event != "goal" || level.bombPlanted || !self isTouching( site.trigger ) || site IsInUse() || self inLastStand() || self HasThreat() )
		{
			self.bot_lock_goal = false;
			return;
		}

		self SetScriptGoal( self.origin, 64 );

		self bot_use_bomb_thread( site );
		wait 1;

		self ClearScriptGoal();
		self.bot_lock_goal = false;
	}
	else if ( bombteam == otherTeam ) // the bomb is theirs, we are on the defense
	{
		site = level.bombZones[myteam];

		if ( !isDefined( site.bots ) )
			site.bots = 0;

		// protect our site from planters
		if ( !level.bombPlanted )
		{
			//kill bomb carrier
			if ( site.bots > 2 || randomInt( 100 ) < 45 )
			{
				if ( self HasScriptGoal() )
					return;

				if ( carrier _hasPerk( "specialty_coldblooded" ) )
					return;

				origin = carrier.origin;

				self SetScriptGoal( origin, 64 );
				self thread bot_escort_obj( bomb, carrier );

				if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
					self ClearScriptGoal();

				return;
			}

			//protect bomb site
			origin = ( site.curorigin[0] + 50, site.curorigin[1] + 50, site.curorigin[2] + 5 );

			self thread bot_inc_bots( site );

			if ( site isInUse() ) //somebody is planting
			{
				self.bot_lock_goal = true;
				self SetScriptGoal( origin, 64 );
				self thread bot_inc_bots( site );

				self thread bot_defend_site( site );

				if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
					self ClearScriptGoal();

				self.bot_lock_goal = false;
				return;
			}

			//else hang around the site
			if ( DistanceSquared( origin, self.origin ) <= 1024 * 1024 )
			{
				wait 4;
				self notify( "bot_inc_bots" );
				site.bots--;
				return;
			}

			self.bot_lock_goal = true;
			self SetScriptGoal( origin, 256 );
			self thread bot_inc_bots( site );

			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
				self ClearScriptGoal();

			self.bot_lock_goal = false;
			return;
		}

		// bomb is planted we need to defuse
		origin = ( site.curorigin[0] + 50, site.curorigin[1] + 50, site.curorigin[2] + 5 );

		// someone else is defusing, lets just hang around
		if ( site.bots > 1 )
		{
			if ( self HasScriptGoal() )
				return;

			if ( DistanceSquared( origin, self.origin ) <= 1024 * 1024 )
				return;

			self SetScriptGoal( origin, 256 );
			self thread bot_go_defuse( site );

			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
				self ClearScriptGoal();

			return;
		}

		// lets go defuse
		self.bot_lock_goal = true;

		self SetScriptGoal( origin, 1 );
		self thread bot_inc_bots( site );
		self thread bot_go_defuse( site );

		event = self waittill_any_return( "goal", "bad_path", "new_goal" );

		if ( event != "new_goal" )
			self ClearScriptGoal();

		if ( event != "goal" || !level.bombPlanted || site IsInUse() || !self isTouching( site.trigger ) || self InLastStand() || self HasThreat() )
		{
			self.bot_lock_goal = false;
			return;
		}

		self SetScriptGoal( self.origin, 64 );

		self bot_use_bomb_thread( site );
		wait 1;
		self ClearScriptGoal();

		self.bot_lock_goal = false;
	}
	else // we need to go get the bomb!
	{
		origin = ( bomb.curorigin[0], bomb.curorigin[1], bomb.curorigin[2] + 5 );

		self.bot_lock_goal = true;
		self SetScriptGoal( origin, 64 );

		self thread bot_get_obj( bomb );

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			self ClearScriptGoal();

		self.bot_lock_goal = false;
		return;
	}
}

/*
	Bots play sab
*/
bot_sab()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	if ( level.gametype != "sab" )
		return;

	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );

		if ( self IsUsingRemote() || self.bot_lock_goal )
		{
			continue;
		}

		if ( !isDefined( level.sabBomb ) )
			continue;

		if ( !isDefined( level.bombZones ) || !level.bombZones.size )
			continue;

		if ( self IsPlanting() || self isDefusing() )
			continue;

		self bot_sab_loop();
	}
}

/*
	Bots play sd defenders
*/
bot_sd_defenders_loop( data )
{
	myTeam = self.pers[ "team" ];
	otherTeam = getOtherTeam( myTeam );

	// bomb not planted, lets protect our sites
	if ( !level.bombPlanted )
	{
		timeleft = maps\mp\gametypes\_gamelogic::getTimeRemaining() / 1000;

		if ( timeleft >= 90 )
			return;

		// check for a bomb carrier, and camp the bomb
		if ( !level.multiBomb && isDefined( level.sdBomb ) )
		{
			bomb = level.sdBomb;
			carrier = level.sdBomb.carrier;

			if ( !isDefined( carrier ) )
			{
				origin = ( bomb.curorigin[0], bomb.curorigin[1], bomb.curorigin[2] + 5 );

				//hang around the bomb
				if ( self HasScriptGoal() )
					return;

				if ( DistanceSquared( origin, self.origin ) <= 1024 * 1024 )
					return;

				self SetScriptGoal( origin, 256 );

				self thread bot_get_obj( bomb );

				if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
					self ClearScriptGoal();

				return;
			}
		}

		// pick a site to protect
		if ( !isDefined( level.bombZones ) || !level.bombZones.size )
			return;

		sites = [];

		for ( i = 0; i < level.bombZones.size; i++ )
		{
			sites[sites.size] = level.bombZones[i];
		}

		if ( !sites.size )
			return;

		if ( data.rand > 50 )
			site = self bot_array_nearest_curorigin( sites );
		else
			site = random( sites );

		if ( !isDefined( site ) )
			return;

		origin = ( site.curorigin[0] + 50, site.curorigin[1] + 50, site.curorigin[2] + 5 );

		if ( site isInUse() ) //somebody is planting
		{
			self.bot_lock_goal = true;
			self SetScriptGoal( origin, 64 );

			self thread bot_defend_site( site );

			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
				self ClearScriptGoal();

			self.bot_lock_goal = false;
			return;
		}

		//else hang around the site
		if ( DistanceSquared( origin, self.origin ) <= 1024 * 1024 )
			return;

		self.bot_lock_goal = true;
		self SetScriptGoal( origin, 256 );

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			self ClearScriptGoal();

		self.bot_lock_goal = false;
		return;
	}

	// bomb is planted, we need to defuse
	if ( !isDefined( level.defuseObject ) )
		return;

	defuse = level.defuseObject;

	if ( !isDefined( defuse.bots ) )
		defuse.bots = 0;

	origin = ( defuse.curorigin[0], defuse.curorigin[1], defuse.curorigin[2] + 5 );

	// someone is going to go defuse ,lets just hang around
	if ( defuse.bots > 1 )
	{
		if ( self HasScriptGoal() )
			return;

		if ( DistanceSquared( origin, self.origin ) <= 1024 * 1024 )
			return;

		self SetScriptGoal( origin, 256 );
		self thread bot_go_defuse( defuse );

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			self ClearScriptGoal();

		return;
	}

	// lets defuse
	self.bot_lock_goal = true;
	self SetScriptGoal( origin, 1 );
	self thread bot_inc_bots( defuse );
	self thread bot_go_defuse( defuse );

	event = self waittill_any_return( "goal", "bad_path", "new_goal" );

	if ( event != "new_goal" )
		self ClearScriptGoal();

	if ( event != "goal" || !level.bombPlanted || defuse isInUse() || !self isTouching( defuse.trigger ) || self InLastStand() || self HasThreat() )
	{
		self.bot_lock_goal = false;
		return;
	}

	self SetScriptGoal( self.origin, 64 );

	self bot_use_bomb_thread( defuse );
	wait 1;
	self ClearScriptGoal();
	self.bot_lock_goal = false;
}

/*
	Bots play sd defenders
*/
bot_sd_defenders()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	if ( level.gametype != "sd" )
		return;

	if ( self.team == game["attackers"] )
		return;

	data = spawnStruct();
	data.rand = self BotGetRandom();

	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );

		if ( self IsUsingRemote() || self.bot_lock_goal )
		{
			continue;
		}

		if ( self IsPlanting() || self isDefusing() )
			continue;

		self bot_sd_defenders_loop( data );
	}
}

/*
	Bots play sd attackers
*/
bot_sd_attackers_loop( data )
{
	if ( data.first )
		data.first = false;
	else
		wait( randomintrange( 3, 5 ) );

	if ( self IsUsingRemote() || self.bot_lock_goal )
	{
		return;
	}

	myTeam = self.pers[ "team" ];
	otherTeam = getOtherTeam( myTeam );

	//bomb planted
	if ( level.bombPlanted )
	{
		if ( !isDefined( level.defuseObject ) )
			return;

		site = level.defuseObject;

		origin = ( site.curorigin[0], site.curorigin[1], site.curorigin[2] + 5 );

		if ( site IsInUse() ) //somebody is defusing
		{
			self.bot_lock_goal = true;

			self SetScriptGoal( origin, 64 );

			self thread bot_defend_site( site );

			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
				self ClearScriptGoal();

			self.bot_lock_goal = false;
			return;
		}

		//else hang around the site
		if ( DistanceSquared( origin, self.origin ) <= 1024 * 1024 )
			return;

		self.bot_lock_goal = true;
		self SetScriptGoal( origin, 256 );

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			self ClearScriptGoal();

		self.bot_lock_goal = false;
		return;
	}

	timeleft = maps\mp\gametypes\_gamelogic::getTimeRemaining() / 1000;
	timepassed = getTimePassed() / 1000;

	//dont have a bomb
	if ( !self IsBombCarrier() && !level.multiBomb )
	{
		if ( !isDefined( level.sdBomb ) )
			return;

		bomb = level.sdBomb;
		carrier = level.sdBomb.carrier;

		//bomb is picked up
		if ( isDefined( carrier ) )
		{
			//escort the bomb carrier
			if ( self HasScriptGoal() )
				return;

			origin = carrier.origin;

			if ( DistanceSquared( origin, self.origin ) <= 1024 * 1024 )
				return;

			self SetScriptGoal( origin, 256 );
			self thread bot_escort_obj( bomb, carrier );

			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
				self ClearScriptGoal();

			return;
		}

		if ( !isDefined( bomb.bots ) )
			bomb.bots = 0;

		origin = ( bomb.curorigin[0], bomb.curorigin[1], bomb.curorigin[2] + 5 );

		//hang around the bomb if other is going to go get it
		if ( bomb.bots > 1 )
		{
			if ( self HasScriptGoal() )
				return;

			if ( DistanceSquared( origin, self.origin ) <= 1024 * 1024 )
				return;

			self SetScriptGoal( origin, 256 );

			self thread bot_get_obj( bomb );

			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
				self ClearScriptGoal();

			return;
		}

		// go get the bomb
		self.bot_lock_goal = true;
		self SetScriptGoal( origin, 64 );
		self thread bot_inc_bots( bomb );
		self thread bot_get_obj( bomb );

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			self ClearScriptGoal();

		self.bot_lock_goal = false;
		return;
	}

	// check if to plant
	if ( timepassed < 120 && timeleft >= 90 && randomInt( 100 ) < 98 )
		return;

	if ( !isDefined( level.bombZones ) || !level.bombZones.size )
		return;

	sites = [];

	for ( i = 0; i < level.bombZones.size; i++ )
	{
		sites[sites.size] = level.bombZones[i];
	}

	if ( !sites.size )
		return;

	if ( data.rand > 50 )
		plant = self bot_array_nearest_curorigin( sites );
	else
		plant = random( sites );

	if ( !isDefined( plant ) )
		return;

	origin = ( plant.curorigin[0] + 50, plant.curorigin[1] + 50, plant.curorigin[2] + 5 );

	self.bot_lock_goal = true;
	self SetScriptGoal( origin, 1 );
	self thread bot_go_plant( plant );

	event = self waittill_any_return( "goal", "bad_path", "new_goal" );

	if ( event != "new_goal" )
		self ClearScriptGoal();

	if ( event != "goal" || level.bombPlanted || plant.visibleTeam == "none" || !self isTouching( plant.trigger ) || self InLastStand() || self HasThreat() || plant IsInUse() )
	{
		self.bot_lock_goal = false;
		return;
	}

	self SetScriptGoal( self.origin, 64 );

	self bot_use_bomb_thread( plant );
	wait 1;

	self ClearScriptGoal();
	self.bot_lock_goal = false;
}

/*
	Bots play sd attackers
*/
bot_sd_attackers()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	if ( level.gametype != "sd" )
		return;

	if ( self.team != game["attackers"] )
		return;

	data = spawnStruct();
	data.rand = self BotGetRandom();
	data.first = true;

	for ( ;; )
	{
		self bot_sd_attackers_loop( data );
	}
}

/*
	Bots play capture the flag
*/
bot_cap_loop()
{
	myTeam = self.pers[ "team" ];
	otherTeam = getOtherTeam( myTeam );

	myflag = level.teamFlags[myteam];
	myzone = level.capZones[myteam];

	theirflag = level.teamFlags[otherTeam];
	theirzone = level.capZones[otherTeam];

	if ( !myflag maps\mp\gametypes\_gameobjects::isHome() )
	{
		carrier = myflag.carrier;

		if ( !isDefined( carrier ) ) //someone doesnt has our flag
		{
			if ( !isDefined( theirflag.carrier ) && DistanceSquared( self.origin, theirflag.curorigin ) < DistanceSquared( self.origin, myflag.curorigin ) ) //no one has their flag and its closer
				self bot_cap_get_flag( theirflag );
			else//go get it
				self bot_cap_get_flag( myflag );

			return;
		}
		else
		{
			if ( theirflag maps\mp\gametypes\_gameobjects::isHome() && randomint( 100 ) < 50 )
			{
				//take their flag
				self bot_cap_get_flag( theirflag );
			}
			else
			{
				if ( self HasScriptGoal() )
					return;

				if ( !isDefined( theirzone.bots ) )
					theirzone.bots = 0;

				origin = theirzone.curorigin;

				if ( theirzone.bots > 2 || randomInt( 100 ) < 45 )
				{
					//kill carrier
					if ( carrier _hasPerk( "specialty_coldblooded" ) )
						return;

					origin = carrier.origin;

					self SetScriptGoal( origin, 64 );
					self thread bot_escort_obj( myflag, carrier );

					if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
						self ClearScriptGoal();

					return;
				}

				self thread bot_inc_bots( theirzone );

				//camp their zone
				if ( DistanceSquared( origin, self.origin ) <= 1024 * 1024 )
				{
					wait 4;
					self notify( "bot_inc_bots" );
					theirzone.bots--;
					return;
				}

				self SetScriptGoal( origin, 256 );
				self thread bot_inc_bots( theirzone );
				self thread bot_escort_obj( myflag, carrier );

				if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
					self ClearScriptGoal();
			}
		}
	}
	else//our flag is ok
	{
		if ( self isFlagCarrier() ) //if have flag
		{
			//go cap
			origin = myzone.curorigin;

			self.bot_lock_goal = true;
			self SetScriptGoal( origin, 32 );

			self thread bot_get_obj( myflag );
			evt = self waittill_any_return( "goal", "bad_path", "new_goal" );

			wait 1;

			if ( evt != "new_goal" )
				self ClearScriptGoal();

			self.bot_lock_goal = false;
			return;
		}

		carrier = theirflag.carrier;

		if ( !isDefined( carrier ) ) //if no one has enemy flag
		{
			self bot_cap_get_flag( theirflag );
			return;
		}

		//escort them

		if ( self HasScriptGoal() )
			return;

		origin = carrier.origin;

		if ( DistanceSquared( origin, self.origin ) <= 1024 * 1024 )
			return;

		self SetScriptGoal( origin, 256 );
		self thread bot_escort_obj( theirflag, carrier );

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			self ClearScriptGoal();
	}
}

/*
	Bots play capture the flag
*/
bot_cap()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	if ( level.gametype != "ctf" )
		return;

	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );

		if ( self IsUsingRemote() || self.bot_lock_goal )
		{
			continue;
		}

		if ( !isDefined( level.capZones ) )
			continue;

		if ( !isDefined( level.teamFlags ) )
			continue;

		self bot_cap_loop();
	}
}

/*
	Gets the carriers ent num
*/
getCarrierEntNum()
{
	carrierNum = -1;

	if ( isDefined( self.carrier ) )
		carrierNum = self.carrier getEntityNumber();

	return carrierNum;
}

/*
	Bots go and get the flag
*/
bot_cap_get_flag( flag )
{
	origin = flag.curorigin;

	//go get it

	self.bot_lock_goal = true;
	self SetScriptGoal( origin, 32 );

	self thread bot_get_obj( flag );

	evt = self waittill_any_return( "goal", "bad_path", "new_goal" );

	if ( evt != "new_goal" )
		self ClearScriptGoal();

	if ( evt != "goal" )
	{
		self.bot_lock_goal = false;
		return;
	}

	self SetScriptGoal( self.origin, 64 );
	curCarrier = flag getCarrierEntNum();

	while ( curCarrier == flag getCarrierEntNum() && self isTouching( flag.trigger ) )
	{
		cur = flag.curProgress;
		wait 0.5;

		if ( flag.curProgress == cur )
			break;//some enemy is near us, kill him
	}

	self ClearScriptGoal();

	self.bot_lock_goal = false;
}

/*
	Bots go plant the demo bomb
*/
bot_dem_go_plant( plant )
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	for ( ;; )
	{
		wait 0.5;

		if ( ( plant.label == "_b" && level.bombBPlanted ) || ( plant.label == "_a" && level.bombAPlanted ) )
			break;

		if ( self isTouching( plant.trigger ) )
			break;
	}

	if ( ( plant.label == "_b" && level.bombBPlanted ) || ( plant.label == "_a" && level.bombAPlanted ) )
		self notify( "bad_path" );
	else
		self notify( "goal" );
}

/*
	Bots spawn kill dom attackers
*/
bot_dem_attack_spawnkill()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	l1 = level.bombAPlanted;
	l2 = level.bombBPlanted;

	for ( ;; )
	{
		wait 0.5;

		if ( l1 != level.bombAPlanted || l2 != level.bombBPlanted )
			break;
	}

	self notify( "bad_path" );
}

/*
	Bots play demo attackers
*/
bot_dem_attackers_loop()
{
	myTeam = self.pers[ "team" ];
	otherTeam = getOtherTeam( myTeam );

	bombs = [];//sites with bombs
	sites = [];//sites to bomb at
	bombed = 0;//exploded sites

	for ( i = 0; i < level.bombZones.size; i++ )
	{
		bomb = level.bombZones[i];

		if ( isDefined( bomb.bombExploded ) && bomb.bombExploded )
		{
			bombed++;
			continue;
		}

		if ( bomb.label == "_a" )
		{
			if ( level.bombAPlanted )
				bombs[bombs.size] = bomb;
			else
				sites[sites.size] = bomb;

			continue;
		}

		if ( bomb.label == "_b" )
		{
			if ( level.bombBPlanted )
				bombs[bombs.size] = bomb;
			else
				sites[sites.size] = bomb;

			continue;
		}
	}

	timeleft = maps\mp\gametypes\_gamelogic::getTimeRemaining() / 1000;

	shouldLet = ( game["teamScores"][myteam] > game["teamScores"][otherTeam] && timeleft < 90 && bombed == 1 );

	//spawnkill conditions
	//if we have bombed one site or 1 bomb is planted with lots of time left, spawn kill
	//if we want the other team to win for overtime and they do not need to defuse, spawn kill
	if ( ( ( bombed + bombs.size == 1 && timeleft >= 90 ) || ( shouldLet && !bombs.size ) ) && randomInt( 100 ) < 95 )
	{
		if ( self HasScriptGoal() )
			return;

		spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_dd_spawn_defender_start" );

		if ( !spawnPoints.size )
			return;

		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );

		if ( DistanceSquared( spawnpoint.origin, self.origin ) <= 2048 * 2048 )
			return;

		self SetScriptGoal( spawnpoint.origin, 1024 );

		self thread bot_dem_attack_spawnkill();

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			self ClearScriptGoal();

		return;
	}

	//let defuse conditions
	//if enemy is going to lose and lots of time left, let them defuse to play longer
	//or if want to go into overtime near end of the extended game
	if ( ( ( bombs.size + bombed == 2 && timeleft >= 90 ) || ( shouldLet && bombs.size ) ) && randomInt( 100 ) < 95 )
	{
		spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_dd_spawn_attacker_start" );

		if ( !spawnPoints.size )
			return;

		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );

		if ( DistanceSquared( spawnpoint.origin, self.origin ) <= 1024 * 1024 )
			return;

		self.bot_lock_goal = true;
		self SetScriptGoal( spawnpoint.origin, 512 );

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			self ClearScriptGoal();

		self.bot_lock_goal = false;
		return;
	}

	//defend bomb conditions
	//if time is running out and we have a bomb planted
	if ( bombs.size && timeleft < 90 && ( !sites.size || randomInt( 100 ) < 95 ) )
	{
		site = self bot_array_nearest_curorigin( bombs );
		origin = ( site.curorigin[0] + 50, site.curorigin[1] + 50, site.curorigin[2] + 5 );

		if ( site IsInUse() ) //somebody is defusing
		{
			self.bot_lock_goal = true;
			self SetScriptGoal( origin, 64 );

			self thread bot_defend_site( site );

			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
				self ClearScriptGoal();

			self.bot_lock_goal = false;
			return;
		}

		//else hang around the site
		if ( DistanceSquared( origin, self.origin ) <= 1024 * 1024 )
			return;

		self.bot_lock_goal = true;
		self SetScriptGoal( origin, 256 );

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			self ClearScriptGoal();

		self.bot_lock_goal = false;
		return;
	}

	//else go plant
	if ( !sites.size )
		return;

	plant = self bot_array_nearest_curorigin( sites );

	if ( !isDefined( plant ) )
		return;

	if ( !isDefined( plant.bots ) )
		plant.bots = 0;

	origin = ( plant.curorigin[0] + 50, plant.curorigin[1] + 50, plant.curorigin[2] + 5 );

	//hang around the site if lots of time left
	if ( plant.bots > 1 && timeleft >= 60 )
	{
		if ( self HasScriptGoal() )
			return;

		if ( DistanceSquared( origin, self.origin ) <= 1024 * 1024 )
			return;

		self SetScriptGoal( origin, 256 );
		self thread bot_dem_go_plant( plant );

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			self ClearScriptGoal();

		return;
	}

	self.bot_lock_goal = true;

	self SetScriptGoal( origin, 1 );
	self thread bot_inc_bots( plant );
	self thread bot_dem_go_plant( plant );

	event = self waittill_any_return( "goal", "bad_path", "new_goal" );

	if ( event != "new_goal" )
		self ClearScriptGoal();

	if ( event != "goal" || ( plant.label == "_b" && level.bombBPlanted ) || ( plant.label == "_a" && level.bombAPlanted ) || plant IsInUse() || !self isTouching( plant.trigger ) || self InLastStand() || self HasThreat() )
	{
		self.bot_lock_goal = false;
		return;
	}

	self SetScriptGoal( self.origin, 64 );

	self bot_use_bomb_thread( plant );
	wait 1;

	self ClearScriptGoal();

	self.bot_lock_goal = false;
}

/*
	Bots play demo attackers
*/
bot_dem_attackers()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	if ( level.gametype != "dd" )
		return;

	if ( self.team != game["attackers"] )
		return;

	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );

		if ( self IsUsingRemote() || self.bot_lock_goal )
		{
			continue;
		}

		if ( !isDefined( level.bombZones ) || !level.bombZones.size )
			continue;

		self bot_dem_attackers_loop();
	}
}

/*
	Bots play demo defenders
*/
bot_dem_defenders_loop()
{
	myTeam = self.pers[ "team" ];
	otherTeam = getOtherTeam( myTeam );

	bombs = [];//sites with bombs
	sites = [];//sites to bomb at
	bombed = 0;//exploded sites

	for ( i = 0; i < level.bombZones.size; i++ )
	{
		bomb = level.bombZones[i];

		if ( isDefined( bomb.bombExploded ) && bomb.bombExploded )
		{
			bombed++;
			continue;
		}

		if ( bomb.label == "_a" )
		{
			if ( level.bombAPlanted )
				bombs[bombs.size] = bomb;
			else
				sites[sites.size] = bomb;

			continue;
		}

		if ( bomb.label == "_b" )
		{
			if ( level.bombBPlanted )
				bombs[bombs.size] = bomb;
			else
				sites[sites.size] = bomb;

			continue;
		}
	}

	timeleft = maps\mp\gametypes\_gamelogic::getTimeRemaining() / 1000;

	shouldLet = ( timeleft < 60 && ( ( bombed == 0 && bombs.size != 2 ) || ( game["teamScores"][myteam] > game["teamScores"][otherTeam] && bombed == 1 ) ) && randomInt( 100 ) < 98 );

	//spawnkill conditions
	//if nothing to defuse with a lot of time left, spawn kill
	//or letting a bomb site to explode but a bomb is planted, so spawnkill
	if ( ( !bombs.size && timeleft >= 60 && randomInt( 100 ) < 95 ) || ( shouldLet && bombs.size == 1 ) )
	{
		if ( self HasScriptGoal() )
			return;

		spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_dd_spawn_attacker_start" );

		if ( !spawnPoints.size )
			return;

		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );

		if ( DistanceSquared( spawnpoint.origin, self.origin ) <= 2048 * 2048 )
			return;

		self SetScriptGoal( spawnpoint.origin, 1024 );

		self thread bot_dem_defend_spawnkill();

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			self ClearScriptGoal();

		return;
	}

	//let blow up conditions
	//let enemy blow up at least one to extend play time
	//or if want to go into overtime after extended game
	if ( shouldLet )
	{
		spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_dd_spawn_defender_start" );

		if ( !spawnPoints.size )
			return;

		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );

		if ( DistanceSquared( spawnpoint.origin, self.origin ) <= 1024 * 1024 )
			return;

		self.bot_lock_goal = true;
		self SetScriptGoal( spawnpoint.origin, 512 );

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			self ClearScriptGoal();

		self.bot_lock_goal = false;
		return;
	}

	//defend conditions
	//if no bombs planted with little time left
	if ( !bombs.size && timeleft < 60 && randomInt( 100 ) < 95 && sites.size )
	{
		site = self bot_array_nearest_curorigin( sites );
		origin = ( site.curorigin[0] + 50, site.curorigin[1] + 50, site.curorigin[2] + 5 );

		if ( site IsInUse() ) //somebody is planting
		{
			self.bot_lock_goal = true;
			self SetScriptGoal( origin, 64 );

			self thread bot_defend_site( site );

			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
				self ClearScriptGoal();

			self.bot_lock_goal = false;
			return;
		}

		//else hang around the site

		if ( DistanceSquared( origin, self.origin ) <= 1024 * 1024 )
			return;

		self.bot_lock_goal = true;
		self SetScriptGoal( origin, 256 );

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			self ClearScriptGoal();

		self.bot_lock_goal = false;
		return;
	}

	//else go defuse

	if ( !bombs.size )
		return;

	defuse = self bot_array_nearest_curorigin( bombs );

	if ( !isDefined( defuse ) )
		return;

	if ( !isDefined( defuse.bots ) )
		defuse.bots = 0;

	origin = ( defuse.curorigin[0] + 50, defuse.curorigin[1] + 50, defuse.curorigin[2] + 5 );

	//hang around the site if not in danger of losing
	if ( defuse.bots > 1 && bombed + bombs.size != 2 )
	{
		if ( self HasScriptGoal() )
			return;

		if ( DistanceSquared( origin, self.origin ) <= 1024 * 1024 )
			return;

		self SetScriptGoal( origin, 256 );

		self thread bot_dem_go_defuse( defuse );

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			self ClearScriptGoal();

		return;
	}

	self.bot_lock_goal = true;

	self SetScriptGoal( origin, 1 );
	self thread bot_inc_bots( defuse );
	self thread bot_dem_go_defuse( defuse );

	event = self waittill_any_return( "goal", "bad_path", "new_goal" );

	if ( event != "new_goal" )
		self ClearScriptGoal();

	if ( event != "goal" || ( defuse.label == "_b" && !level.bombBPlanted ) || ( defuse.label == "_a" && !level.bombAPlanted ) || defuse IsInUse() || !self isTouching( defuse.trigger ) || self InLastStand() || self HasThreat() )
	{
		self.bot_lock_goal = false;
		return;
	}

	self SetScriptGoal( self.origin, 64 );

	self bot_use_bomb_thread( defuse );
	wait 1;

	self ClearScriptGoal();

	self.bot_lock_goal = false;
}

/*
	Bots play demo defenders
*/
bot_dem_defenders()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	if ( level.gametype != "dd" )
		return;

	if ( self.team == game["attackers"] )
		return;

	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );

		if ( self IsUsingRemote() || self.bot_lock_goal )
		{
			continue;
		}

		if ( !isDefined( level.bombZones ) || !level.bombZones.size )
			continue;

		self bot_dem_defenders_loop();
	}
}

/*
	Bots go defuse
*/
bot_dem_go_defuse( defuse )
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	for ( ;; )
	{
		wait 0.5;

		if ( self isTouching( defuse.trigger ) )
			break;

		if ( ( defuse.label == "_b" && !level.bombBPlanted ) || ( defuse.label == "_a" && !level.bombAPlanted ) )
			break;
	}

	if ( ( defuse.label == "_b" && !level.bombBPlanted ) || ( defuse.label == "_a" && !level.bombAPlanted ) )
		self notify( "bad_path" );
	else
		self notify( "goal" );
}

/*
	Bots go spawn kill
*/
bot_dem_defend_spawnkill()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	for ( ;; )
	{
		wait 0.5;

		if ( level.bombBPlanted || level.bombAPlanted )
			break;
	}

	self notify( "bad_path" );
}

/*
	Bots think to revive
*/
bot_think_revive_loop()
{
	needsRevives = [];

	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];

		if ( player.team != self.team )
			continue;

		if ( distanceSquared( self.origin, player.origin ) >= 2048 * 2048 )
			continue;

		if ( player inLastStand() )
			needsRevives[needsRevives.size] = player;
	}

	if ( !needsRevives.size )
		return;

	revive = random( needsRevives );
	self.bot_lock_goal = true;

	self SetScriptGoal( revive.origin, 64 );
	self thread stop_go_target_on_death( revive );

	ret = self waittill_any_return( "new_goal", "goal", "bad_path" );

	if ( ret != "new_goal" )
		self ClearScriptGoal();

	self.bot_lock_goal = false;

	if ( ret != "goal" || !isDefined( revive ) || distanceSquared( self.origin, revive.origin ) >= 100 * 100 || !revive inLastStand() || revive isBeingRevived() || !isAlive( revive ) )
		return;

	self _DisableWeapon();
	self BotFreezeControls( true );

	wait 3;

	self _EnableWeapon();
	self BotFreezeControls( false );

	if ( !isDefined( revive ) || distanceSquared( self.origin, revive.origin ) >= 100 * 100 || !revive inLastStand() || revive isBeingRevived() || !isAlive( revive ) )
		return;

	self thread maps\mp\gametypes\_hud_message::SplashNotifyDelayed( "reviver", 200 );
	self thread maps\mp\gametypes\_rank::giveRankXP( "reviver", 200 );

	revive.lastStand = undefined;
	revive clearLowerMessage( "last_stand" );

	if ( revive _hasPerk( "specialty_lightweight" ) )
		revive.moveSpeedScaler = 1.07;
	else
		revive.moveSpeedScaler = 1;

	revive.maxHealth = 100;

	revive maps\mp\gametypes\_weapons::updateMoveSpeedScale( "primary" );
	revive maps\mp\gametypes\_playerlogic::lastStandRespawnPlayer();

	revive setPerk( "specialty_pistoldeath", true );
	revive.beingRevived = false;

	// reviveEnt delete();
}

/*
	Bots think to revive
*/
bot_think_revive()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	if ( !level.dieHardMode || !level.teamBased )
		return;

	for ( ;; )
	{
		wait( randomintrange( 1, 3 ) );

		if ( self HasScriptGoal() || self.bot_lock_goal )
			continue;

		if ( self isDefusing() || self isPlanting() )
			continue;

		if ( self IsUsingRemote() || self BotIsFrozen() )
			continue;

		if ( self inLastStand() )
			continue;

		self bot_think_revive_loop();
	}
}

/*
	Bots play the Global thermonuclear warfare
*/
bot_gtnw_loop()
{
	myteam = self.team;
	theirteam = getOtherTeam( myteam );
	origin = level.nukeSite.trigger.origin;
	trigger = level.nukeSite.trigger;

	ourCapCount = level.nukeSite.touchList[myteam];
	theirCapCount = level.nukeSite.touchList[theirteam];
	rand = self BotGetRandom();

	if ( ( !ourCapCount && !theirCapCount ) || rand <= 20 )
	{
		// go cap the obj
		self.bot_lock_goal = true;
		self SetScriptGoal( origin, 64 );
		self thread bots_watch_touch_obj( trigger );

		ret = self waittill_any_return( "goal", "bad_path", "new_goal" );

		if ( ret != "new_goal" )
			self ClearScriptGoal();

		if ( ret != "goal" || !self isTouching( trigger ) )
		{
			self.bot_lock_goal = false;
			return;
		}

		self SetScriptGoal( self.origin, 64 );

		while ( self isTouching( trigger ) )
		{
			cur = level.nukeSite.curProgress;
			wait 0.5;

			if ( cur == level.nukeSite.curProgress )
				break;//no prog made, enemy must be capping
		}

		self ClearScriptGoal();
		self.bot_lock_goal = false;
		return;
	}

	if ( theirCapCount )
	{
		// kill capturtour
		self.bot_lock_goal = true;

		self SetScriptGoal( origin, 64 );
		self thread bots_watch_touch_obj( trigger );

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			self ClearScriptGoal();

		self.bot_lock_goal = false;
		return;
	}

	//else hang around the site
	if ( DistanceSquared( origin, self.origin ) <= 1024 * 1024 )
		return;

	self.bot_lock_goal = true;
	self SetScriptGoal( origin, 256 );

	if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		self ClearScriptGoal();

	self.bot_lock_goal = false;
}

/*
	Bots play the Global thermonuclear warfare
*/
bot_gtnw()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	if ( level.gametype != "gtnw" )
		return;

	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );

		if ( self IsUsingRemote() || self.bot_lock_goal )
		{
			continue;
		}

		if ( !isDefined( level.nukeSite ) || !isDefined( level.nukeSite.trigger ) )
			continue;

		self bot_gtnw_loop();
	}
}

/*
	Bots play oneflag
*/
bot_oneflag_loop()
{
	myTeam = self.pers[ "team" ];
	otherTeam = getOtherTeam( myTeam );

	if ( myteam == game["attackers"] )
	{
		myzone = level.capZones[myteam];
		theirflag = level.teamFlags[otherTeam];

		if ( self isFlagCarrier() )
		{
			//go cap
			origin = myzone.curorigin;

			self.bot_lock_goal = true;
			self SetScriptGoal( origin, 32 );

			evt = self waittill_any_return( "goal", "bad_path", "new_goal" );

			wait 1;

			if ( evt != "new_goal" )
				self ClearScriptGoal();

			self.bot_lock_goal = false;
			return;
		}

		carrier = theirflag.carrier;

		if ( !isDefined( carrier ) ) //if no one has enemy flag
		{
			self bot_cap_get_flag( theirflag );
			return;
		}

		//escort them

		if ( self HasScriptGoal() )
			return;

		origin = carrier.origin;

		if ( DistanceSquared( origin, self.origin ) <= 1024 * 1024 )
			return;

		self SetScriptGoal( origin, 256 );
		self thread bot_escort_obj( theirflag, carrier );

		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			self ClearScriptGoal();
	}
	else
	{
		myflag = level.teamFlags[myteam];
		theirzone = level.capZones[otherTeam];

		if ( !myflag maps\mp\gametypes\_gameobjects::isHome() )
		{
			carrier = myflag.carrier;

			if ( !isDefined( carrier ) ) //someone doesnt has our flag
			{
				self bot_cap_get_flag( myflag );
				return;
			}

			if ( self HasScriptGoal() )
				return;

			if ( !isDefined( theirzone.bots ) )
				theirzone.bots = 0;

			origin = theirzone.curorigin;

			if ( theirzone.bots > 2 || randomInt( 100 ) < 45 )
			{
				//kill carrier
				if ( carrier _hasPerk( "specialty_coldblooded" ) )
					return;

				origin = carrier.origin;

				self SetScriptGoal( origin, 64 );
				self thread bot_escort_obj( myflag, carrier );

				if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
					self ClearScriptGoal();

				return;
			}

			self thread bot_inc_bots( theirzone );

			//camp their zone
			if ( DistanceSquared( origin, self.origin ) <= 1024 * 1024 )
			{
				wait 4;
				self notify( "bot_inc_bots" );
				theirzone.bots--;
				return;
			}

			self SetScriptGoal( origin, 256 );
			self thread bot_inc_bots( theirzone );
			self thread bot_escort_obj( myflag, carrier );

			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
				self ClearScriptGoal();
		}
		else
		{
			// is home, lets hang around and protect
			if ( self HasScriptGoal() )
				return;

			origin = myflag.curorigin;

			if ( DistanceSquared( origin, self.origin ) <= 1024 * 1024 )
				return;

			self SetScriptGoal( origin, 256 );
			self thread bot_get_obj( myflag );

			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
				self ClearScriptGoal();
		}
	}
}

/*
	Bots play oneflag
*/
bot_oneflag()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	if ( level.gametype != "oneflag" )
		return;

	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );

		if ( self IsUsingRemote() || self.bot_lock_goal )
		{
			continue;
		}

		if ( !isDefined( level.capZones ) || !isDefined( level.teamFlags ) )
			continue;

		self bot_oneflag_loop();
	}
}

/*
	Bots play arena
*/
bot_arena_loop()
{
	flag = level.arenaFlag;
	myTeam = self.team;

	self.bot_lock_goal = true;
	self SetScriptGoal( flag.trigger.origin, 64 );

	event = self waittill_any_return( "goal", "bad_path", "new_goal" );

	if ( event != "new_goal" )
		self ClearScriptGoal();

	if ( event != "goal" || !self isTouching( flag.trigger ) )
	{
		self.bot_lock_goal = false;
		return;
	}

	self SetScriptGoal( self.origin, 64 );

	while ( self isTouching( flag.trigger ) && flag.ownerTeam != myTeam )
	{
		cur = flag.curProgress;
		wait 0.5;

		if ( cur == flag.curProgress )
			break;//no prog made, enemy must be capping
	}

	self ClearScriptGoal();
	self.bot_lock_goal = false;
}

/*
	Bots play arena
*/
bot_arena()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	if ( level.gametype != "arena" )
		return;

	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );

		if ( self IsUsingRemote() || self.bot_lock_goal )
		{
			continue;
		}

		if ( !isDefined( level.arenaFlag ) )
			continue;

		self bot_arena_loop();
	}
}

/*
	Bots play arena
*/
bot_vip()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	if ( level.gametype != "vip" )
		return;

	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );

		if ( self IsUsingRemote() || self.bot_lock_goal )
		{
			continue;
		}

		/*  case "vip"://maybe used at gaming events. (ya right, this is not even finished)
			if(isDefined(level.extractionZone))
			{
				if(self.team == game["defenders"])
				{
					if(isDefined(self.isVip) && self.isVip)
					{
						if(!isDefined(level.extractionTime))
						{
							self.bots_objDoing = "vip";
							self thread bots\talk::bots_vip_extract();
							self bots_goToLoc(level.extractionZone.trigger.origin, ::bots_nullFunc, 0, 0, 0);
							if(distance(level.extractionZone.trigger.origin, self.origin) <= level.bots_useNear)
								level.extractionZone [[level.extractionZone.onUse]](self);

							self thread bots\talk::bots_vip_extractDone();
							self.bots_objDoing = "none";
						}
						else
						{
							wps = bots_getWaypointsNear(level.bots_goalPoint.origin, level.bots_goalRad);
							wp = undefined;
							if(wps.size > 0)
							{
								wp = wps[randomint(wps.size)];
							}
							if(isDefined(wp) && self.bots_traitRandom != 3)
							{
								self bots_goToLoc(level.waypoints[wp].origin, ::bots_nullFunc, 0, 0, 0);
							}
							else
							{
								self bots_goToLoc(level.waypoints[randomint(level.waypointCount)].origin, ::bots_nullFunc, 0, 0, 0);
							}
						}
					}
					else
					{
						if(self.bots_traitRandom)
						{
							tarPlay = undefined;
							foreach(player in level.players)
							{
								if(!isDefined(player.isVip) || !player.isVip)
									continue;

								if(!bots_isReallyAlive(player))
									continue;

								tarPlay = player;
								break;
							}

							self thread bots\talk::bots_vip_protect(tarPlay);
							self bots_goFollow(tarPlay, 30, false);
						}
						else
						{
							wps = bots_getWaypointsNear(level.bots_goalPoint.origin, level.bots_goalRad);
							wp = undefined;
							if(wps.size > 0)
							{
								wp = wps[randomint(wps.size)];
							}
							if(isDefined(wp) && self.bots_traitRandom != 3)
							{
								self bots_goToLoc(level.waypoints[wp].origin, ::bots_nullFunc, 0, 0, 0);
							}
							else
							{
								self bots_goToLoc(level.waypoints[randomint(level.waypointCount)].origin, ::bots_nullFunc, 0, 0, 0);
							}
						}
					}
				}
				else
				{
					tarPlay = undefined;
					foreach(player in level.players)
					{
						if(!isDefined(player.isVip) || !player.isVip)
							continue;

						if(!bots_isReallyAlive(player))
							continue;

						tarPlay = player;
						break;
					}

					if((!isDefined(level.extractionTime) || self.bots_traitRandom < 2) && isDefined(tarPlay))
					{
						self thread bots\talk::bots_vip_kill(tarPlay);
						self bots_goFollow(tarPlay, 30, false);
					}
					else
					{
						wps = bots_getWaypointsNear(level.extractionZone.trigger.origin, randomFloatRange(100,1000));
						wp = undefined;
						if(wps.size > 0)
						{
							wp = wps[randomint(wps.size)];
						}
						if(isDefined(wp) && self.bots_traitRandom != 3)
						{
							self thread bots\talk::bots_vip_hangaround();
							self bots_goToLoc(level.waypoints[wp].origin, ::bots_nullFunc, 0, 0, 0);
						}
						else
						{
							self bots_goToLoc(level.waypoints[randomint(level.waypointCount)].origin, ::bots_nullFunc, 0, 0, 0);
						}
					}
				}
			}
		    break;*/
	}
}
