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
	
	if ( !getdvarint( "developer_script" ) )
	{
		self setplayerdata( "experience", self bot_get_rank() );
		self setplayerdata( "prestige", self bot_get_prestige() );
		
		self setplayerdata( "cardTitle", random( getCardTitles() ) );
		self setplayerdata( "cardIcon", random( getCardIcons() ) );
	}
	
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
	
	self.killerlocation = undefined;
	self.lastkiller = undefined;
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
	self.challengedata = [];
}

/*
	Gets the prestige
*/
bot_get_prestige()
{
	p_dvar = getdvarint( "bots_loadout_prestige" );
	p = 0;
	
	if ( p_dvar == -1 )
	{
		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[ i ];
			
			if ( !isdefined( player.team ) )
			{
				continue;
			}
			
			if ( player is_bot() )
			{
				continue;
			}
			
			p = player getplayerdata( "prestige" );
			break;
		}
	}
	else if ( p_dvar == -2 )
	{
		p = randomint( 12 );
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
	rank_dvar = getdvarint( "bots_loadout_rank" );
	
	if ( rank_dvar == -1 )
	{
		ranks = [];
		bot_ranks = [];
		human_ranks = [];
		
		for ( i = level.players.size - 1; i >= 0; i-- )
		{
			player = level.players[ i ];
			
			if ( player == self )
			{
				continue;
			}
			
			if ( !isdefined( player.pers[ "rank" ] ) )
			{
				continue;
			}
			
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
		{
			human_ranks[ human_ranks.size ] = Round( random_normal_distribution( 45, 20, 0, level.maxrank ) );
		}
		
		human_avg = array_average( human_ranks );
		
		while ( bot_ranks.size + human_ranks.size < 5 )
		{
			// add some random ranks for better random number distribution
			rank = human_avg + randomintrange( -10, 10 );
			human_ranks[ human_ranks.size ] = rank;
		}
		
		ranks = array_combine( human_ranks, bot_ranks );
		
		avg = array_average( ranks );
		s = array_std_deviation( ranks, avg );
		
		rank = Round( random_normal_distribution( avg, s, 0, level.maxrank ) );
	}
	else if ( rank_dvar == 0 )
	{
		rank = Round( random_normal_distribution( 45, 20, 0, level.maxrank ) );
	}
	else
	{
		rank = Round( random_normal_distribution( rank_dvar, 5, 0, level.maxrank ) );
	}
	
	return maps\mp\gametypes\_rank::getrankinfominxp( rank );
}

/*
	returns an array of all card titles
*/
getCardTitles()
{
	cards = [];
	
	for ( i = 0; i < 600; i++ )
	{
		card_name = tablelookupbyrow( "mp/cardTitleTable.csv", i, 0 );
		
		if ( card_name == "" )
		{
			continue;
		}
		
		if ( !issubstr( card_name, "cardtitle_" ) )
		{
			continue;
		}
		
		cards[ cards.size ] = card_name;
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
		card_name = tablelookupbyrow( "mp/cardIconTable.csv", i, 0 );
		
		if ( card_name == "" )
		{
			continue;
		}
		
		if ( !issubstr( card_name, "cardicon_" ) )
		{
			continue;
		}
		
		cards[ cards.size ] = card_name;
	}
	
	return cards;
}

/*
	returns if attachment is valid with attachment 2
*/
isValidAttachmentCombo( att1, att2 )
{
	colIndex = tablelookuprownum( "mp/attachmentCombos.csv", 0, att1 );
	
	if ( tablelookup( "mp/attachmentCombos.csv", 0, att2, colIndex ) == "no" )
	{
		return false;
	}
	
	return true;
}

/*
	returns all attachments for the given gun
*/
getAttachmentsForGun( gun )
{
	row = tablelookuprownum( "mp/statStable.csv", 4, gun );
	
	attachments = [];
	
	for ( h = 0; h < 10; h++ )
	{
		attachmentName = tablelookupbyrow( "mp/statStable.csv", row, h + 11 );
		
		if ( attachmentName == "" )
		{
			attachments[ attachments.size ] = "none";
			break;
		}
		
		attachments[ attachments.size ] = attachmentName;
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
		weapon_type = tablelookupbyrow( "mp/statstable.csv", i, 2 );
		
		if ( weapon_type != "weapon_assault" && weapon_type != "weapon_riot" && weapon_type != "weapon_smg" && weapon_type != "weapon_sniper" && weapon_type != "weapon_lmg" )
		{
			continue;
		}
		
		weapon_name = tablelookupbyrow( "mp/statstable.csv", i, 4 );
		
		primaries[ primaries.size ] = weapon_name;
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
		weapon_type = tablelookupbyrow( "mp/statstable.csv", i, 2 );
		
		if ( weapon_type != "weapon_pistol" && weapon_type != "weapon_machine_pistol" && weapon_type != "weapon_projectile" && weapon_type != "weapon_shotgun" )
		{
			continue;
		}
		
		weapon_name = tablelookupbyrow( "mp/statstable.csv", i, 4 );
		
		if ( weapon_name == "gl" )
		{
			continue;
		}
		
		secondaries[ secondaries.size ] = weapon_name;
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
		camo_name = tablelookupbyrow( "mp/camoTable.csv", i, 1 );
		
		if ( camo_name == "" )
		{
			continue;
		}
		
		camos[ camos.size ] = camo_name;
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
		perk_type = tablelookupbyrow( "mp/perktable.csv", i, 5 );
		
		if ( perk_type != perktype )
		{
			continue;
		}
		
		perk_name = tablelookupbyrow( "mp/perktable.csv", i, 1 );
		
		if ( perk_name == "specialty_c4death" )
		{
			continue;
		}
		
		if ( perk_name == "_specialty_blastshield" )
		{
			continue;
		}
		
		perks[ perks.size ] = perk_name;
	}
	
	return perks;
}

/*
	returns kill cost for a streak
*/
getKillsNeededForStreak( streak )
{
	return int( tablelookup( "mp/killstreakTable.csv", 1, streak, 4 ) );
}

/*
	returns all killstreaks
*/
getKillstreaks()
{
	killstreaks = [];
	
	for ( i = 0; i < 40; i++ )
	{
		streak_name = tablelookupbyrow( "mp/killstreakTable.csv", i, 1 );
		
		if ( streak_name == "" || streak_name == "none" )
		{
			continue;
		}
		
		if ( streak_name == "b1" )
		{
			continue;
		}
		
		if ( streak_name == "sentry" ) // theres an airdrop version
		{
			continue;
		}
		
		if ( issubstr( streak_name, "KILLSTREAKS_" ) )
		{
			continue;
		}
		
		killstreaks[ killstreaks.size ] = streak_name;
	}
	
	return killstreaks;
}

/*
	bots chooses a random perk
*/
chooseRandomPerk( perkkind, primary, primaryAtts )
{
	perks = getPerks( perkkind );
	rank = self maps\mp\gametypes\_rank::getrankforxp( self getplayerdata( "experience" ) );
	allowOp = ( getdvarint( "bots_loadout_allow_op" ) >= 1 );
	reasonable = getdvarint( "bots_loadout_reasonable" );
	
	while ( true )
	{
		perk = random( perks );
		
		if ( !allowOp )
		{
			if ( perkkind == "perk4" )
			{
				return "specialty_null";
			}
			
			if ( perk == "specialty_pistoldeath" )
			{
				continue;
			}
			
			if ( perk == "specialty_coldblooded" )
			{
				continue;
			}
			
			if ( perk == "specialty_localjammer" )
			{
				continue;
			}
		}
		
		if ( reasonable )
		{
			if ( perk == "specialty_bling" )
			{
				continue;
			}
			
			if ( perk == "specialty_localjammer" )
			{
				continue;
			}
			
			if ( perk == "throwingknife_mp" )
			{
				continue;
			}
			
			if ( perk == "specialty_blastshield" )
			{
				continue;
			}
			
			if ( perk == "frag_grenade_mp" )
			{
				continue;
			}
			
			if ( perk == "specialty_copycat" )
			{
				continue;
			}
			
			if ( perkkind == "perk1" )
			{
				if ( perk == "specialty_onemanarmy" )
				{
					if ( primaryAtts[ 0 ] != "gl"/* && primaryAtts[ 1 ] != "gl"*/ )
					{
						continue;
					}
				}
			}
			
			if ( perkkind == "perk2" )
			{
				if ( perk != "specialty_bulletdamage" )
				{
					if ( perk == "specialty_explosivedamage" )
					{
						if ( primaryAtts[ 0 ] != "gl"/* && primaryAtts[ 1 ] != "gl"*/ )
						{
							continue;
						}
					}
					else
					{
						if ( randomint( 100 ) < 10 )
						{
							continue;
						}
						
						if ( primary == "cheytac" )
						{
							continue;
						}
						
						if ( primary == "rpd" )
						{
							continue;
						}
						
						if ( primary == "ak47" && randomint( 100 ) < 80 )
						{
							continue;
						}
						
						if ( primary == "aug" )
						{
							continue;
						}
						
						if ( primary == "barrett" && randomint( 100 ) < 80 )
						{
							continue;
						}
						
						if ( primary == "tavor" && randomint( 100 ) < 80 )
						{
							continue;
						}
						
						if ( primary == "scar" )
						{
							continue;
						}
						
						if ( primary == "masada" && randomint( 100 ) < 60 )
						{
							continue;
						}
						
						if ( primary == "m4" && randomint( 100 ) < 80 )
						{
							continue;
						}
						
						if ( primary == "m16" )
						{
							continue;
						}
						
						if ( primary == "fal" )
						{
							continue;
						}
						
						if ( primary == "famas" )
						{
							continue;
						}
					}
				}
			}
		}
		
		if ( perk == "specialty_null" )
		{
			continue;
		}
		
		if ( !self isitemunlocked( perk ) )
		{
			continue;
		}
		
		if ( randomfloatrange( 0, 1 ) < ( ( rank / level.maxrank ) + 0.1 ) )
		{
			self.pers[ "bots" ][ "unlocks" ][ "upgraded_" + perk ] = true;
		}
		
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
		{
			continue;
		}
		
		return camo;
	}
}

/*
	choose a random primary
*/
chooseRandomPrimary()
{
	primaries = getPrimaries();
	allowOp = ( getdvarint( "bots_loadout_allow_op" ) >= 1 );
	reasonable = getdvarint( "bots_loadout_reasonable" );
	
	while ( true )
	{
		primary = random( primaries );
		
		if ( !allowOp )
		{
			if ( primary == "riotshield" )
			{
				continue;
			}
		}
		
		if ( reasonable )
		{
			if ( primary == "riotshield" )
			{
				continue;
			}
			
			if ( primary == "wa2000" )
			{
				continue;
			}
			
			if ( primary == "uzi" )
			{
				continue;
			}
			
			if ( primary == "sa80" )
			{
				continue;
			}
			
			if ( primary == "fn2000" )
			{
				continue;
			}
			
			if ( primary == "m240" )
			{
				continue;
			}
			
			if ( primary == "mg4" )
			{
				continue;
			}
		}
		
		if ( !self isitemunlocked( primary ) )
		{
			continue;
		}
		
		return primary;
	}
}

/*
	choose a random secondary
*/
chooseRandomSecondary( perk1 )
{
	if ( perk1 == "specialty_onemanarmy" )
	{
		return "onemanarmy";
	}
	
	secondaries = getSecondaries();
	allowOp = ( getdvarint( "bots_loadout_allow_op" ) >= 1 );
	reasonable = getdvarint( "bots_loadout_reasonable" );
	
	while ( true )
	{
		secondary = random( secondaries );
		
		if ( !allowOp )
		{
			if ( secondary == "at4" || secondary == "rpg" || secondary == "m79" )
			{
				continue;
			}
		}
		
		if ( reasonable )
		{
			if ( secondary == "ranger" )
			{
				continue;
			}
			
			if ( secondary == "model1887" )
			{
				continue;
			}
		}
		
		if ( !self isitemunlocked( secondary ) )
		{
			continue;
		}
		
		if ( secondary == "onemanarmy" )
		{
			continue;
		}
		
		return secondary;
	}
}

/*
	chooses random attachements for a gun
*/
chooseRandomAttachmentComboForGun( gun )
{
	atts = getAttachmentsForGun( gun );
	rank = self maps\mp\gametypes\_rank::getrankforxp( self getplayerdata( "experience" ) );
	allowOp = ( getdvarint( "bots_loadout_allow_op" ) >= 1 );
	reasonable = getdvarint( "bots_loadout_reasonable" );
	
	if ( randomfloatrange( 0, 1 ) >= ( ( rank / level.maxrank ) + 0.1 ) )
	{
		retAtts = [];
		retAtts[ 0 ] = "none";
		retAtts[ 1 ] = "none";
		
		return retAtts;
	}
	
	while ( true )
	{
		att1 = random( atts );
		att2 = random( atts );
		
		if ( !isValidAttachmentCombo( att1, att2 ) )
		{
			continue;
		}
		
		if ( !allowOp )
		{
			if ( att1 == "gl" || att2 == "gl" )
			{
				continue;
			}
		}
		
		if ( reasonable )
		{
			if ( att1 == "shotgun" || att2 == "shotgun" )
			{
				continue;
			}
			
			if ( att1 == "akimbo" || att2 == "akimbo" )
			{
				if ( gun != "ranger" && gun != "model1887" && gun != "glock" )
				{
					continue;
				}
			}
			
			if ( att1 == "acog" || att2 == "acog" )
			{
				continue;
			}
			
			if ( att1 == "thermal" || att2 == "thermal" )
			{
				continue;
			}
			
			if ( att1 == "rof" || att2 == "rof" )
			{
				continue;
			}
			
			if ( att1 == "silencer" || att2 == "silencer" )
			{
				if ( gun == "spas12" || gun == "aa12" || gun == "striker" || gun == "rpd" || gun == "m1014" || gun == "cheytac" || gun == "barrett" || gun == "aug" || gun == "m240" || gun == "mg4" || gun == "sa80" || gun == "wa2000" )
				{
					continue;
				}
			}
		}
		
		retAtts = [];
		retAtts[ 0 ] = att1;
		retAtts[ 1 ] = att2;
		
		return retAtts;
	}
}

/*
	choose a random tacticle grenade
*/
chooseRandomTactical()
{
	tacts = strtok( "flash_grenade,smoke_grenade,concussion_grenade", "," );
	reasonable = getdvarint( "bots_loadout_reasonable" );
	
	while ( true )
	{
		tact = random( tacts );
		
		if ( reasonable )
		{
			if ( tact == "smoke_grenade" )
			{
				continue;
			}
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
	{
		n = 15;
	}
	
	rank = self maps\mp\gametypes\_rank::getrankforxp( self getplayerdata( "experience" ) );
	
	if ( randomfloatrange( 0, 1 ) < ( ( rank / level.maxrank ) + 0.1 ) )
	{
		self.pers[ "bots" ][ "unlocks" ][ "ghillie" ] = true;
		self.pers[ "bots" ][ "behavior" ][ "quickscope" ] = true;
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
		{
			primaryAtts[ 1 ] = "none";
		}
		
		perk2 = chooseRandomPerk( "perk2", primary, primaryAtts );
		primaryCamo = chooseRandomCamo();
		secondary = chooseRandomSecondary( perk1 );
		secondaryAtts = chooseRandomAttachmentComboForGun( secondary );
		
		if ( perk1 != "specialty_bling" || !isdefined( self.pers[ "bots" ][ "unlocks" ][ "upgraded_specialty_bling" ] ) )
		{
			secondaryAtts[ 1 ] = "none";
		}
		
		if ( !getdvarint( "developer_script" ) )
		{
			self setplayerdata( "customClasses", i, "weaponSetups", 0, "weapon", primary );
			self setplayerdata( "customClasses", i, "weaponSetups", 0, "attachment", 0, primaryAtts[ 0 ] );
			self setplayerdata( "customClasses", i, "weaponSetups", 0, "attachment", 1, primaryAtts[ 1 ] );
			self setplayerdata( "customClasses", i, "weaponSetups", 0, "camo", primaryCamo );
			
			self setplayerdata( "customClasses", i, "weaponSetups", 1, "weapon", secondary );
			self setplayerdata( "customClasses", i, "weaponSetups", 1, "attachment", 0, secondaryAtts[ 0 ] );
			self setplayerdata( "customClasses", i, "weaponSetups", 1, "attachment", 1, secondaryAtts[ 1 ] );
			
			self setplayerdata( "customClasses", i, "perks", 0, equipment );
			self setplayerdata( "customClasses", i, "perks", 1, perk1 );
			self setplayerdata( "customClasses", i, "perks", 2, perk2 );
			self setplayerdata( "customClasses", i, "perks", 3, perk3 );
			self setplayerdata( "customClasses", i, "perks", 4, deathstreak );
			self setplayerdata( "customClasses", i, "specialGrenade", tactical );
		}
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
		ks = killstreaks[ i ];
		
		if ( ks == "" )
		{
			continue;
		}
		
		if ( ks == "none" )
		{
			continue;
		}
		
		ksV = getKillsNeededForStreak( ks );
		
		if ( ksV <= 0 )
		{
			continue;
		}
		
		if ( ksV != ksVal )
		{
			continue;
		}
		
		return true;
	}
	
	return false;
}

/*
	bots set their killstreaks
*/
setKillstreaks()
{
	rankId = self maps\mp\gametypes\_rank::getrankforxp( self getplayerdata( "experience" ) ) + 1;
	
	allStreaks = getKillstreaks();
	
	killstreaks = [];
	killstreaks[ 0 ] = "";
	killstreaks[ 1 ] = "";
	killstreaks[ 2 ] = "";
	
	chooseableStreaks = 0;
	
	if ( rankId >= 10 )
	{
		chooseableStreaks++;
	}
	
	if ( rankId >= 15 )
	{
		chooseableStreaks++;
	}
	
	if ( rankId >= 22 )
	{
		chooseableStreaks++;
	}
	
	reasonable = getdvarint( "bots_loadout_reasonable" );
	op = getdvarint( "bots_loadout_allow_op" );
	
	i = 0;
	
	while ( i < chooseableStreaks )
	{
		slot = randomint( 3 );
		
		if ( killstreaks[ slot ] != "" )
		{
			continue;
		}
		
		streak = random( allStreaks );
		
		if ( isColidingKillstreak( killstreaks, streak ) )
		{
			continue;
		}
		
		if ( reasonable )
		{
			if ( streak == "stealth_airstrike" )
			{
				continue;
			}
			
			if ( streak == "airdrop_mega" )
			{
				continue;
			}
			
			if ( streak == "emp" )
			{
				continue;
			}
			
			if ( streak == "airdrop_sentry_minigun" )
			{
				continue;
			}
			
			if ( streak == "airdrop" )
			{
				continue;
			}
			
			if ( streak == "precision_airstrike" )
			{
				continue;
			}
			
			if ( streak == "helicopter" )
			{
				continue;
			}
		}
		
		if ( op )
		{
			if ( streak == "nuke" )
			{
				continue;
			}
		}
		
		killstreaks[ slot ] = streak;
		i++;
	}
	
	if ( killstreaks[ 0 ] == "" )
	{
		killstreaks[ 0 ] = "uav";
	}
	
	if ( killstreaks[ 1 ] == "" )
	{
		killstreaks[ 1 ] = "airdrop";
	}
	
	if ( killstreaks[ 2 ] == "" )
	{
		killstreaks[ 2 ] = "predator_missile";
	}
	
	if ( !getdvarint( "developer_script" ) )
	{
		self setplayerdata( "killstreaks", 0, killstreaks[ 0 ] );
		self setplayerdata( "killstreaks", 1, killstreaks[ 1 ] );
		self setplayerdata( "killstreaks", 2, killstreaks[ 2 ] );
	}
}

/*
	The callback for when the bot gets killed.
*/
onKilled( eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration )
{
	self.killerlocation = undefined;
	self.lastkiller = undefined;
	
	if ( !isdefined( self ) || !isdefined( self.team ) )
	{
		return;
	}
	
	if ( sMeansOfDeath == "MOD_FALLING" || sMeansOfDeath == "MOD_SUICIDE" )
	{
		return;
	}
	
	if ( iDamage <= 0 )
	{
		return;
	}
	
	if ( !isdefined( eAttacker ) || !isdefined( eAttacker.team ) )
	{
		return;
	}
	
	if ( eAttacker == self )
	{
		return;
	}
	
	if ( level.teambased && eAttacker.team == self.team )
	{
		return;
	}
	
	if ( !isdefined( eInflictor ) || eInflictor.classname != "player" )
	{
		return;
	}
	
	if ( !isalive( eAttacker ) )
	{
		return;
	}
	
	self.killerlocation = eAttacker.origin;
	self.lastkiller = eAttacker;
}

/*
	The callback for when the bot gets damaged.
*/
onDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset )
{
	if ( !isdefined( self ) || !isdefined( self.team ) )
	{
		return;
	}
	
	if ( !isalive( self ) )
	{
		return;
	}
	
	if ( sMeansOfDeath == "MOD_FALLING" || sMeansOfDeath == "MOD_SUICIDE" )
	{
		return;
	}
	
	if ( iDamage <= 0 )
	{
		return;
	}
	
	if ( !isdefined( eAttacker ) || !isdefined( eAttacker.team ) )
	{
		return;
	}
	
	if ( eAttacker == self )
	{
		return;
	}
	
	if ( level.teambased && eAttacker.team == self.team )
	{
		return;
	}
	
	if ( !isdefined( eInflictor ) || eInflictor.classname != "player" )
	{
		return;
	}
	
	if ( !isalive( eAttacker ) )
	{
		return;
	}
	
	if ( !issubstr( sWeapon, "_silencer_" ) )
	{
		self bot_cry_for_help( eAttacker );
	}
	
	self setAttacker( eAttacker );
}

/*
	When the bot gets attacked, have the bot ask for help from teammates.
*/
bot_cry_for_help( attacker )
{
	if ( !level.teambased )
	{
		return;
	}
	
	theTime = gettime();
	
	if ( isdefined( self.help_time ) && theTime - self.help_time < 1000 )
	{
		return;
	}
	
	self.help_time = theTime;
	
	for ( i = level.players.size - 1; i >= 0; i-- )
	{
		player = level.players[ i ];
		
		if ( !player is_bot() )
		{
			continue;
		}
		
		if ( !isdefined( player.team ) )
		{
			continue;
		}
		
		if ( !isalive( player ) )
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
		
		dist = player.pers[ "bots" ][ "skill" ][ "help_dist" ];
		dist *= dist;
		
		if ( distancesquared( self.origin, player.origin ) > dist )
		{
			continue;
		}
		
		if ( randomint( 100 ) < 50 )
		{
			self setAttacker( attacker );
			
			if ( randomint( 100 ) > 70 )
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
	
	self BotNotifyBotEvent( "killcam", "start" );
	
	wait 0.5 + randomint( 3 );
	
	if ( randomint( 100 ) > 25 )
	{
		self notify( "use_copycat" );
	}
	
	wait 0.1;
	
	self notify( "abort_killcam" );
	
	self BotNotifyBotEvent( "killcam", "stop" );
}

/*
	Selects a class for the bot.
*/
classWatch()
{
	self endon( "disconnect" );
	
	for ( ;; )
	{
		while ( !isdefined( self.pers[ "team" ] ) || !allowClassChoiceUtil() )
		{
			wait .05;
		}
		
		wait 0.5;
		
		if ( !isvalidclass( self.class ) || !isdefined( self.bot_change_class ) )
		{
			self notify( "menuresponse", game[ "menu_changeclass" ], self chooseRandomClass() );
		}
		
		self.bot_change_class = true;
		
		while ( isdefined( self.pers[ "team" ] ) && isvalidclass( self.class ) && isdefined( self.bot_change_class ) )
		{
			wait .05;
		}
	}
}

/*
	Chooses a random class
*/
chooseRandomClass()
{
	reasonable = getdvarint( "bots_loadout_reasonable" );
	class = "";
	rank = self maps\mp\gametypes\_rank::getrankforxp( self getplayerdata( "experience" ) ) + 1;
	
	if ( rank < 4 || ( randomint( 100 ) < 2 && !reasonable ) )
	{
		while ( class == "" )
		{
			switch ( randomint( 5 ) )
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
					{
						class = "class3";
					}
					
					break;
					
				case 4:
					if ( rank >= 3 )
					{
						class = "class4";
					}
					
					break;
			}
		}
	}
	else
	{
		class = "custom" + ( randomint( 5 ) + 1 );
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
		while ( !isdefined( self.pers[ "team" ] ) || !allowTeamChoiceUtil() )
		{
			wait .05;
		}
		
		wait 0.1;
		
		if ( self.team != "axis" && self.team != "allies" )
		{
			self notify( "menuresponse", game[ "menu_team" ], getdvar( "bots_team" ) );
		}
		
		while ( isdefined( self.pers[ "team" ] ) )
		{
			wait .05;
		}
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
		if ( getdvarint( "bots_skill" ) != 9 )
		{
			switch ( self.pers[ "bots" ][ "skill" ][ "base" ] )
			{
				case 1:
					self.pers[ "bots" ][ "skill" ][ "aim_time" ] = 0.6;
					self.pers[ "bots" ][ "skill" ][ "init_react_time" ] = 1500;
					self.pers[ "bots" ][ "skill" ][ "reaction_time" ] = 1000;
					self.pers[ "bots" ][ "skill" ][ "no_trace_ads_time" ] = 500;
					self.pers[ "bots" ][ "skill" ][ "no_trace_look_time" ] = 600;
					self.pers[ "bots" ][ "skill" ][ "remember_time" ] = 750;
					self.pers[ "bots" ][ "skill" ][ "fov" ] = 0.7;
					self.pers[ "bots" ][ "skill" ][ "dist_max" ] = 2500;
					self.pers[ "bots" ][ "skill" ][ "dist_start" ] = 1000;
					self.pers[ "bots" ][ "skill" ][ "spawn_time" ] = 0.75;
					self.pers[ "bots" ][ "skill" ][ "help_dist" ] = 0;
					self.pers[ "bots" ][ "skill" ][ "semi_time" ] = 0.9;
					self.pers[ "bots" ][ "skill" ][ "shoot_after_time" ] = 1;
					self.pers[ "bots" ][ "skill" ][ "aim_offset_time" ] = 1.5;
					self.pers[ "bots" ][ "skill" ][ "aim_offset_amount" ] = 4;
					self.pers[ "bots" ][ "skill" ][ "bone_update_interval" ] = 2;
					self.pers[ "bots" ][ "skill" ][ "bones" ] = "j_spineupper,j_ankle_le,j_ankle_ri";
					self.pers[ "bots" ][ "skill" ][ "ads_fov_multi" ] = 0.5;
					self.pers[ "bots" ][ "skill" ][ "ads_aimspeed_multi" ] = 0.5;
					
					self.pers[ "bots" ][ "behavior" ][ "strafe" ] = 0;
					self.pers[ "bots" ][ "behavior" ][ "nade" ] = 10;
					self.pers[ "bots" ][ "behavior" ][ "sprint" ] = 30;
					self.pers[ "bots" ][ "behavior" ][ "camp" ] = 5;
					self.pers[ "bots" ][ "behavior" ][ "follow" ] = 5;
					self.pers[ "bots" ][ "behavior" ][ "crouch" ] = 20;
					self.pers[ "bots" ][ "behavior" ][ "switch" ] = 2;
					self.pers[ "bots" ][ "behavior" ][ "class" ] = 2;
					self.pers[ "bots" ][ "behavior" ][ "jump" ] = 0;
					break;
					
				case 2:
					self.pers[ "bots" ][ "skill" ][ "aim_time" ] = 0.55;
					self.pers[ "bots" ][ "skill" ][ "init_react_time" ] = 1000;
					self.pers[ "bots" ][ "skill" ][ "reaction_time" ] = 800;
					self.pers[ "bots" ][ "skill" ][ "no_trace_ads_time" ] = 1000;
					self.pers[ "bots" ][ "skill" ][ "no_trace_look_time" ] = 1250;
					self.pers[ "bots" ][ "skill" ][ "remember_time" ] = 1500;
					self.pers[ "bots" ][ "skill" ][ "fov" ] = 0.65;
					self.pers[ "bots" ][ "skill" ][ "dist_max" ] = 3000;
					self.pers[ "bots" ][ "skill" ][ "dist_start" ] = 1500;
					self.pers[ "bots" ][ "skill" ][ "spawn_time" ] = 0.65;
					self.pers[ "bots" ][ "skill" ][ "help_dist" ] = 500;
					self.pers[ "bots" ][ "skill" ][ "semi_time" ] = 0.75;
					self.pers[ "bots" ][ "skill" ][ "shoot_after_time" ] = 0.75;
					self.pers[ "bots" ][ "skill" ][ "aim_offset_time" ] = 1;
					self.pers[ "bots" ][ "skill" ][ "aim_offset_amount" ] = 3;
					self.pers[ "bots" ][ "skill" ][ "bone_update_interval" ] = 1.5;
					self.pers[ "bots" ][ "skill" ][ "bones" ] = "j_spineupper,j_ankle_le,j_ankle_ri,j_head";
					self.pers[ "bots" ][ "skill" ][ "ads_fov_multi" ] = 0.5;
					self.pers[ "bots" ][ "skill" ][ "ads_aimspeed_multi" ] = 0.5;
					
					self.pers[ "bots" ][ "behavior" ][ "strafe" ] = 10;
					self.pers[ "bots" ][ "behavior" ][ "nade" ] = 15;
					self.pers[ "bots" ][ "behavior" ][ "sprint" ] = 45;
					self.pers[ "bots" ][ "behavior" ][ "camp" ] = 5;
					self.pers[ "bots" ][ "behavior" ][ "follow" ] = 5;
					self.pers[ "bots" ][ "behavior" ][ "crouch" ] = 15;
					self.pers[ "bots" ][ "behavior" ][ "switch" ] = 2;
					self.pers[ "bots" ][ "behavior" ][ "class" ] = 2;
					self.pers[ "bots" ][ "behavior" ][ "jump" ] = 10;
					break;
					
				case 3:
					self.pers[ "bots" ][ "skill" ][ "aim_time" ] = 0.4;
					self.pers[ "bots" ][ "skill" ][ "init_react_time" ] = 750;
					self.pers[ "bots" ][ "skill" ][ "reaction_time" ] = 500;
					self.pers[ "bots" ][ "skill" ][ "no_trace_ads_time" ] = 1000;
					self.pers[ "bots" ][ "skill" ][ "no_trace_look_time" ] = 1500;
					self.pers[ "bots" ][ "skill" ][ "remember_time" ] = 2000;
					self.pers[ "bots" ][ "skill" ][ "fov" ] = 0.6;
					self.pers[ "bots" ][ "skill" ][ "dist_max" ] = 4000;
					self.pers[ "bots" ][ "skill" ][ "dist_start" ] = 2250;
					self.pers[ "bots" ][ "skill" ][ "spawn_time" ] = 0.5;
					self.pers[ "bots" ][ "skill" ][ "help_dist" ] = 750;
					self.pers[ "bots" ][ "skill" ][ "semi_time" ] = 0.65;
					self.pers[ "bots" ][ "skill" ][ "shoot_after_time" ] = 0.65;
					self.pers[ "bots" ][ "skill" ][ "aim_offset_time" ] = 0.75;
					self.pers[ "bots" ][ "skill" ][ "aim_offset_amount" ] = 2.5;
					self.pers[ "bots" ][ "skill" ][ "bone_update_interval" ] = 1;
					self.pers[ "bots" ][ "skill" ][ "bones" ] = "j_spineupper,j_spineupper,j_ankle_le,j_ankle_ri,j_head";
					self.pers[ "bots" ][ "skill" ][ "ads_fov_multi" ] = 0.5;
					self.pers[ "bots" ][ "skill" ][ "ads_aimspeed_multi" ] = 0.5;
					
					self.pers[ "bots" ][ "behavior" ][ "strafe" ] = 20;
					self.pers[ "bots" ][ "behavior" ][ "nade" ] = 20;
					self.pers[ "bots" ][ "behavior" ][ "sprint" ] = 50;
					self.pers[ "bots" ][ "behavior" ][ "camp" ] = 5;
					self.pers[ "bots" ][ "behavior" ][ "follow" ] = 5;
					self.pers[ "bots" ][ "behavior" ][ "crouch" ] = 10;
					self.pers[ "bots" ][ "behavior" ][ "switch" ] = 2;
					self.pers[ "bots" ][ "behavior" ][ "class" ] = 2;
					self.pers[ "bots" ][ "behavior" ][ "jump" ] = 25;
					break;
					
				case 4:
					self.pers[ "bots" ][ "skill" ][ "aim_time" ] = 0.3;
					self.pers[ "bots" ][ "skill" ][ "init_react_time" ] = 600;
					self.pers[ "bots" ][ "skill" ][ "reaction_time" ] = 400;
					self.pers[ "bots" ][ "skill" ][ "no_trace_ads_time" ] = 1500;
					self.pers[ "bots" ][ "skill" ][ "no_trace_look_time" ] = 2000;
					self.pers[ "bots" ][ "skill" ][ "remember_time" ] = 3000;
					self.pers[ "bots" ][ "skill" ][ "fov" ] = 0.55;
					self.pers[ "bots" ][ "skill" ][ "dist_max" ] = 5000;
					self.pers[ "bots" ][ "skill" ][ "dist_start" ] = 3350;
					self.pers[ "bots" ][ "skill" ][ "spawn_time" ] = 0.35;
					self.pers[ "bots" ][ "skill" ][ "help_dist" ] = 1000;
					self.pers[ "bots" ][ "skill" ][ "semi_time" ] = 0.5;
					self.pers[ "bots" ][ "skill" ][ "shoot_after_time" ] = 0.5;
					self.pers[ "bots" ][ "skill" ][ "aim_offset_time" ] = 0.5;
					self.pers[ "bots" ][ "skill" ][ "aim_offset_amount" ] = 2;
					self.pers[ "bots" ][ "skill" ][ "bone_update_interval" ] = 0.75;
					self.pers[ "bots" ][ "skill" ][ "bones" ] = "j_spineupper,j_spineupper,j_ankle_le,j_ankle_ri,j_head,j_head";
					self.pers[ "bots" ][ "skill" ][ "ads_fov_multi" ] = 0.5;
					self.pers[ "bots" ][ "skill" ][ "ads_aimspeed_multi" ] = 0.5;
					
					self.pers[ "bots" ][ "behavior" ][ "strafe" ] = 30;
					self.pers[ "bots" ][ "behavior" ][ "nade" ] = 25;
					self.pers[ "bots" ][ "behavior" ][ "sprint" ] = 55;
					self.pers[ "bots" ][ "behavior" ][ "camp" ] = 5;
					self.pers[ "bots" ][ "behavior" ][ "follow" ] = 5;
					self.pers[ "bots" ][ "behavior" ][ "crouch" ] = 10;
					self.pers[ "bots" ][ "behavior" ][ "switch" ] = 2;
					self.pers[ "bots" ][ "behavior" ][ "class" ] = 2;
					self.pers[ "bots" ][ "behavior" ][ "jump" ] = 35;
					break;
					
				case 5:
					self.pers[ "bots" ][ "skill" ][ "aim_time" ] = 0.25;
					self.pers[ "bots" ][ "skill" ][ "init_react_time" ] = 500;
					self.pers[ "bots" ][ "skill" ][ "reaction_time" ] = 300;
					self.pers[ "bots" ][ "skill" ][ "no_trace_ads_time" ] = 2500;
					self.pers[ "bots" ][ "skill" ][ "no_trace_look_time" ] = 3000;
					self.pers[ "bots" ][ "skill" ][ "remember_time" ] = 4000;
					self.pers[ "bots" ][ "skill" ][ "fov" ] = 0.5;
					self.pers[ "bots" ][ "skill" ][ "dist_max" ] = 7500;
					self.pers[ "bots" ][ "skill" ][ "dist_start" ] = 5000;
					self.pers[ "bots" ][ "skill" ][ "spawn_time" ] = 0.25;
					self.pers[ "bots" ][ "skill" ][ "help_dist" ] = 1500;
					self.pers[ "bots" ][ "skill" ][ "semi_time" ] = 0.4;
					self.pers[ "bots" ][ "skill" ][ "shoot_after_time" ] = 0.35;
					self.pers[ "bots" ][ "skill" ][ "aim_offset_time" ] = 0.35;
					self.pers[ "bots" ][ "skill" ][ "aim_offset_amount" ] = 1.5;
					self.pers[ "bots" ][ "skill" ][ "bone_update_interval" ] = 0.5;
					self.pers[ "bots" ][ "skill" ][ "bones" ] = "j_spineupper,j_head";
					self.pers[ "bots" ][ "skill" ][ "ads_fov_multi" ] = 0.5;
					self.pers[ "bots" ][ "skill" ][ "ads_aimspeed_multi" ] = 0.5;
					
					self.pers[ "bots" ][ "behavior" ][ "strafe" ] = 40;
					self.pers[ "bots" ][ "behavior" ][ "nade" ] = 35;
					self.pers[ "bots" ][ "behavior" ][ "sprint" ] = 60;
					self.pers[ "bots" ][ "behavior" ][ "camp" ] = 5;
					self.pers[ "bots" ][ "behavior" ][ "follow" ] = 5;
					self.pers[ "bots" ][ "behavior" ][ "crouch" ] = 10;
					self.pers[ "bots" ][ "behavior" ][ "switch" ] = 2;
					self.pers[ "bots" ][ "behavior" ][ "class" ] = 2;
					self.pers[ "bots" ][ "behavior" ][ "jump" ] = 50;
					break;
					
				case 6:
					self.pers[ "bots" ][ "skill" ][ "aim_time" ] = 0.2;
					self.pers[ "bots" ][ "skill" ][ "init_react_time" ] = 250;
					self.pers[ "bots" ][ "skill" ][ "reaction_time" ] = 150;
					self.pers[ "bots" ][ "skill" ][ "no_trace_ads_time" ] = 2500;
					self.pers[ "bots" ][ "skill" ][ "no_trace_look_time" ] = 4000;
					self.pers[ "bots" ][ "skill" ][ "remember_time" ] = 5000;
					self.pers[ "bots" ][ "skill" ][ "fov" ] = 0.45;
					self.pers[ "bots" ][ "skill" ][ "dist_max" ] = 10000;
					self.pers[ "bots" ][ "skill" ][ "dist_start" ] = 7500;
					self.pers[ "bots" ][ "skill" ][ "spawn_time" ] = 0.2;
					self.pers[ "bots" ][ "skill" ][ "help_dist" ] = 2000;
					self.pers[ "bots" ][ "skill" ][ "semi_time" ] = 0.25;
					self.pers[ "bots" ][ "skill" ][ "shoot_after_time" ] = 0.25;
					self.pers[ "bots" ][ "skill" ][ "aim_offset_time" ] = 0.25;
					self.pers[ "bots" ][ "skill" ][ "aim_offset_amount" ] = 1;
					self.pers[ "bots" ][ "skill" ][ "bone_update_interval" ] = 0.25;
					self.pers[ "bots" ][ "skill" ][ "bones" ] = "j_spineupper,j_head,j_head";
					self.pers[ "bots" ][ "skill" ][ "ads_fov_multi" ] = 0.5;
					self.pers[ "bots" ][ "skill" ][ "ads_aimspeed_multi" ] = 0.5;
					
					self.pers[ "bots" ][ "behavior" ][ "strafe" ] = 50;
					self.pers[ "bots" ][ "behavior" ][ "nade" ] = 45;
					self.pers[ "bots" ][ "behavior" ][ "sprint" ] = 65;
					self.pers[ "bots" ][ "behavior" ][ "camp" ] = 5;
					self.pers[ "bots" ][ "behavior" ][ "follow" ] = 5;
					self.pers[ "bots" ][ "behavior" ][ "crouch" ] = 10;
					self.pers[ "bots" ][ "behavior" ][ "switch" ] = 2;
					self.pers[ "bots" ][ "behavior" ][ "class" ] = 2;
					self.pers[ "bots" ][ "behavior" ][ "jump" ] = 75;
					break;
					
				case 7:
					self.pers[ "bots" ][ "skill" ][ "aim_time" ] = 0.1;
					self.pers[ "bots" ][ "skill" ][ "init_react_time" ] = 100;
					self.pers[ "bots" ][ "skill" ][ "reaction_time" ] = 50;
					self.pers[ "bots" ][ "skill" ][ "no_trace_ads_time" ] = 2500;
					self.pers[ "bots" ][ "skill" ][ "no_trace_look_time" ] = 4000;
					self.pers[ "bots" ][ "skill" ][ "remember_time" ] = 7500;
					self.pers[ "bots" ][ "skill" ][ "fov" ] = 0.4;
					self.pers[ "bots" ][ "skill" ][ "dist_max" ] = 15000;
					self.pers[ "bots" ][ "skill" ][ "dist_start" ] = 10000;
					self.pers[ "bots" ][ "skill" ][ "spawn_time" ] = 0.05;
					self.pers[ "bots" ][ "skill" ][ "help_dist" ] = 3000;
					self.pers[ "bots" ][ "skill" ][ "semi_time" ] = 0.1;
					self.pers[ "bots" ][ "skill" ][ "shoot_after_time" ] = 0;
					self.pers[ "bots" ][ "skill" ][ "aim_offset_time" ] = 0;
					self.pers[ "bots" ][ "skill" ][ "aim_offset_amount" ] = 0;
					self.pers[ "bots" ][ "skill" ][ "bone_update_interval" ] = 0.05;
					self.pers[ "bots" ][ "skill" ][ "bones" ] = "j_head";
					self.pers[ "bots" ][ "skill" ][ "ads_fov_multi" ] = 0.5;
					self.pers[ "bots" ][ "skill" ][ "ads_aimspeed_multi" ] = 0.5;
					
					self.pers[ "bots" ][ "behavior" ][ "strafe" ] = 65;
					self.pers[ "bots" ][ "behavior" ][ "nade" ] = 65;
					self.pers[ "bots" ][ "behavior" ][ "sprint" ] = 70;
					self.pers[ "bots" ][ "behavior" ][ "camp" ] = 5;
					self.pers[ "bots" ][ "behavior" ][ "follow" ] = 5;
					self.pers[ "bots" ][ "behavior" ][ "crouch" ] = 5;
					self.pers[ "bots" ][ "behavior" ][ "switch" ] = 2;
					self.pers[ "bots" ][ "behavior" ][ "class" ] = 2;
					self.pers[ "bots" ][ "behavior" ][ "jump" ] = 90;
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
	rankVar = getdvarint( "bots_skill" );
	
	switch ( rankVar )
	{
		case 0:
			self.pers[ "bots" ][ "skill" ][ "base" ] = Round( random_normal_distribution( 3.5, 1.75, 1, 7 ) );
			break;
			
		case 8:
			break;
			
		case 9:
			self.pers[ "bots" ][ "skill" ][ "base" ] = randomintrange( 1, 7 );
			self.pers[ "bots" ][ "skill" ][ "aim_time" ] = 0.05 * randomintrange( 1, 20 );
			self.pers[ "bots" ][ "skill" ][ "init_react_time" ] = 50 * randomint( 100 );
			self.pers[ "bots" ][ "skill" ][ "reaction_time" ] = 50 * randomint( 100 );
			self.pers[ "bots" ][ "skill" ][ "remember_time" ] = 50 * randomint( 100 );
			self.pers[ "bots" ][ "skill" ][ "no_trace_ads_time" ] = 50 * randomint( 100 );
			self.pers[ "bots" ][ "skill" ][ "no_trace_look_time" ] = 50 * randomint( 100 );
			self.pers[ "bots" ][ "skill" ][ "fov" ] = randomfloatrange( -1, 1 );
			
			randomNum = randomintrange( 500, 25000 );
			self.pers[ "bots" ][ "skill" ][ "dist_start" ] = randomNum;
			self.pers[ "bots" ][ "skill" ][ "dist_max" ] = randomNum * 2;
			
			self.pers[ "bots" ][ "skill" ][ "spawn_time" ] = 0.05 * randomint( 20 );
			self.pers[ "bots" ][ "skill" ][ "help_dist" ] = randomintrange( 500, 25000 );
			self.pers[ "bots" ][ "skill" ][ "semi_time" ] = randomfloatrange( 0.05, 1 );
			self.pers[ "bots" ][ "skill" ][ "shoot_after_time" ] = randomfloatrange( 0.05, 1 );
			self.pers[ "bots" ][ "skill" ][ "aim_offset_time" ] = randomfloatrange( 0.05, 1 );
			self.pers[ "bots" ][ "skill" ][ "aim_offset_amount" ] = randomfloatrange( 0.05, 1 );
			self.pers[ "bots" ][ "skill" ][ "bone_update_interval" ] = randomfloatrange( 0.05, 1 );
			self.pers[ "bots" ][ "skill" ][ "bones" ] = "j_head,j_spineupper,j_ankle_le,j_ankle_ri";
			
			self.pers[ "bots" ][ "behavior" ][ "strafe" ] = randomint( 100 );
			self.pers[ "bots" ][ "behavior" ][ "nade" ] = randomint( 100 );
			self.pers[ "bots" ][ "behavior" ][ "sprint" ] = randomint( 100 );
			self.pers[ "bots" ][ "behavior" ][ "camp" ] = randomint( 100 );
			self.pers[ "bots" ][ "behavior" ][ "follow" ] = randomint( 100 );
			self.pers[ "bots" ][ "behavior" ][ "crouch" ] = randomint( 100 );
			self.pers[ "bots" ][ "behavior" ][ "switch" ] = randomint( 100 );
			self.pers[ "bots" ][ "behavior" ][ "class" ] = randomint( 100 );
			self.pers[ "bots" ][ "behavior" ][ "jump" ] = randomint( 100 );
			break;
			
		default:
			self.pers[ "bots" ][ "skill" ][ "base" ] = rankVar;
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
		
		self.wantsafespawn = true;
	}
}

/*
	Watches when the bot is given a loadout
*/
onGiveLoadout_loop()
{
	class = self.class;
	
	if ( isdefined( self.bot_oma_class ) )
	{
		class = self.bot_oma_class;
	}
	
	if ( allowClassChoiceUtil() )
	{
		self botGiveLoadout( self.team, class, !isdefined( self.bot_oma_class ) );
	}
	
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
		
		if ( randomint( 100 ) <= self.pers[ "bots" ][ "behavior" ][ "class" ] )
		{
			self.bot_change_class = undefined;
		}
		
		self.bot_lock_goal = false;
		self.bot_oma_class = undefined;
		self.help_time = undefined;
		self.bot_was_follow_script_update = undefined;
		self.bot_stuck_on_carepackage = undefined;
		
		if ( getdvarint( "bots_play_obj" ) )
		{
			self thread bot_dom_cap_think();
		}
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
	
	gameflagwait( "prematch_done" );
	
	// inventory usage
	if ( getdvarint( "bots_play_killstreak" ) )
	{
		self thread bot_killstreak_think();
	}
	
	self thread bot_weapon_think();
	self thread doReloadCancel();
	self thread bot_perk_think();
	
	// script targeting
	if ( getdvarint( "bots_play_target_other" ) )
	{
		self thread bot_target_vehicle();
		self thread bot_equipment_kill_think();
		self thread bot_turret_think();
	}
	
	// airdrop
	if ( getdvarint( "bots_play_take_carepackages" ) )
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
	if ( getdvarint( "bots_play_camp" ) )
	{
		self thread bot_think_follow();
		self thread bot_think_camp();
	}
	
	// nades
	if ( getdvarint( "bots_play_nade" ) )
	{
		self thread bot_jav_loc_think();
		self thread bot_use_tube_think();
		self thread bot_use_grenade_think();
		self thread bot_use_equipment_think();
		self thread bot_watch_riot_weapons();
		self thread bot_watch_think_mw2(); // bots play mw2
	}
	
	// obj
	if ( getdvarint( "bots_play_obj" ) )
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
	
	if ( !isdefined( obj ) )
	{
		return;
	}
	
	if ( !isdefined( obj.bots ) )
	{
		obj.bots = 0;
	}
	
	obj.bots++;
	
	ret = self waittill_any_return( "death", "disconnect", "bad_path", "goal", "new_goal" );
	
	if ( isdefined( obj ) && ( ret != "bad_path" || !isdefined( unreach ) ) )
	{
		obj.bots--;
	}
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
		
		if ( !isdefined( obj ) )
		{
			self notify( "bad_path" );
			return;
		}
		
		if ( self istouching( obj ) )
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
		
		if ( !isdefined( obj ) )
		{
			break;
		}
		
		if ( !isdefined( obj.carrier ) || carrier == obj.carrier )
		{
			break;
		}
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
		
		if ( !isdefined( obj ) )
		{
			break;
		}
		
		if ( isdefined( obj.carrier ) )
		{
			break;
		}
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
		{
			break;
		}
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
		
		if ( level.bombplanted )
		{
			break;
		}
		
		if ( self istouching( plant.trigger ) )
		{
			break;
		}
	}
	
	if ( level.bombplanted )
	{
		self notify( "bad_path" );
	}
	else
	{
		self notify( "goal" );
	}
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
		
		if ( !level.bombplanted )
		{
			break;
		}
		
		if ( self istouching( plant.trigger ) )
		{
			break;
		}
	}
	
	if ( !level.bombplanted )
	{
		self notify( "bad_path" );
	}
	else
	{
		self notify( "goal" );
	}
}

/*
	Waits for the bot to stop moving
*/
bot_wait_stop_move()
{
	while ( !self isonground() || lengthsquared( self getvelocity() ) > 1 )
	{
		wait 0.25;
	}
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
	
	if ( !self hasweapon( weap ) )
	{
		return false;
	}
	
	self switchtoweapon( weap );
	
	if ( self getcurrentweapon() == weap )
	{
		return true;
	}
	
	self waittill_any_timeout( 5, "weapon_change" );
	
	return ( self getcurrentweapon() == weap );
}

/*
	Bots throw the grenade
*/
botThrowGrenade( nade, time )
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );
	
	if ( !self getammocount( nade ) )
	{
		return false;
	}
	
	if ( isSecondaryGrenade( nade ) )
	{
		self thread BotPressSmoke( time );
	}
	else
	{
		self thread BotPressFrag( time );
	}
	
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
	{
		if ( !isdefined( result ) || distancesquared( self.origin, array[ i ].curorigin ) < distancesquared( self.origin, result.curorigin ) )
		{
			result = array[ i ];
		}
	}
	
	return result;
}

/*
	Returns an weapon thats a rocket with ammo
*/
getRocketAmmo()
{
	answer = self getLockonAmmo();
	
	if ( isdefined( answer ) )
	{
		return answer;
	}
	
	if ( self getammocount( "rpg_mp" ) )
	{
		answer = "rpg_mp";
	}
	
	return answer;
}

/*
	Returns a weapon thats lockon with ammo
*/
getLockonAmmo()
{
	answer = undefined;
	
	if ( self getammocount( "at4_mp" ) )
	{
		answer = "at4_mp";
	}
	
	if ( self getammocount( "stinger_mp" ) )
	{
		answer = "stinger_mp";
	}
	
	if ( self getammocount( "javelin_mp" ) )
	{
		answer = "javelin_mp";
	}
	
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
	threat = self getThreat();
	
	if ( !isplayer( threat ) )
	{
		return;
	}
	
	if ( randomint( 100 ) > self.pers[ "bots" ][ "behavior" ][ "follow" ] * 5 )
	{
		return;
	}
	
	self BotNotifyBotEvent( "follow_threat", "start", threat );
	
	self SetScriptGoal( threat.origin, 64 );
	self thread stop_go_target_on_death( threat );
	
	if ( self waittill_any_return( "new_goal", "goal", "bad_path" ) != "new_goal" )
	{
		self ClearScriptGoal();
	}
	
	self BotNotifyBotEvent( "follow_threat", "stop", threat );
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
		{
			continue;
		}
		
		if ( !self hasThreat() )
		{
			continue;
		}
		
		self follow_target_loop();
	}
}

/*
	Bot logic for bot determining to camp.
*/
bot_think_camp_loop()
{
	campSpot = getWaypointForIndex( random( self waypointsNear( getWaypointsOfType( "camp" ), 1024 ) ) );
	
	if ( !isdefined( campSpot ) )
	{
		return;
	}
	
	time = randomintrange( 30, 90 );
	
	self BotNotifyBotEvent( "camp", "go", campSpot, time );
	
	self SetScriptGoal( campSpot.origin, 16 );
	
	ret = self waittill_any_return( "new_goal", "goal", "bad_path" );
	
	if ( ret != "new_goal" )
	{
		self ClearScriptGoal();
	}
	
	if ( ret != "goal" )
	{
		return;
	}
	
	self BotNotifyBotEvent( "camp", "start", campSpot, time );
	
	self thread killCampAfterTime( time );
	self CampAtSpot( campSpot.origin, campSpot.origin + anglestoforward( campSpot.angles ) * 2048 );
	
	self BotNotifyBotEvent( "camp", "stop", campSpot, time );
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
		{
			continue;
		}
		
		if ( randomint( 100 ) > self.pers[ "bots" ][ "behavior" ][ "camp" ] )
		{
			continue;
		}
		
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
	
	timeleft = maps\mp\gametypes\_gamelogic::gettimeremaining() / 1000;
	
	while ( time > 0 && timeleft >= 60 )
	{
		wait 1;
		timeleft = maps\mp\gametypes\_gamelogic::gettimeremaining() / 1000;
		time--;
	}
	
	wait 0.05;
	
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
		
		if ( !isdefined( ent ) )
		{
			break;
		}
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
	
	if ( isdefined( anglePos ) )
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
	distSq = self.pers[ "bots" ][ "skill" ][ "help_dist" ] * self.pers[ "bots" ][ "skill" ][ "help_dist" ];
	
	for ( i = level.players.size - 1; i >= 0; i-- )
	{
		player = level.players[ i ];
		
		if ( player == self )
		{
			continue;
		}
		
		if ( !isreallyalive( player ) )
		{
			continue;
		}
		
		if ( player.team != self.team )
		{
			continue;
		}
		
		if ( distancesquared( player.origin, self.origin ) > distSq )
		{
			continue;
		}
		
		follows[ follows.size ] = player;
	}
	
	toFollow = random( follows );
	
	if ( !isdefined( toFollow ) )
	{
		return;
	}
	
	time = randomintrange( 10, 20 );
	
	self BotNotifyBotEvent( "follow", "start", toFollow, time );
	
	self thread killFollowAfterTime( time );
	self followPlayer( toFollow );
	
	self BotNotifyBotEvent( "follow", "stop", toFollow, time );
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
		wait randomintrange( 3, 5 );
		
		if ( self HasScriptGoal() || self.bot_lock_goal || self HasScriptAimPos() )
		{
			continue;
		}
		
		if ( randomint( 100 ) > self.pers[ "bots" ][ "behavior" ][ "follow" ] )
		{
			continue;
		}
		
		if ( !level.teambased )
		{
			continue;
		}
		
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
		
		if ( !isdefined( self.bot_was_follow_script_update ) )
		{
			break;
		}
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
		
		if ( !isdefined( who ) || !isreallyalive( who ) )
		{
			break;
		}
		
		self SetScriptAimPos( who.origin + ( 0, 0, 42 ) );
		myGoal = self GetScriptGoal();
		
		if ( isdefined( myGoal ) && distancesquared( myGoal, who.origin ) < 64 * 64 )
		{
			continue;
		}
		
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
	for ( ; self _hasperk( "specialty_blastshield" ); )
	{
		if ( !self _hasperk( "_specialty_blastshield" ) )
		{
			if ( randomint( 100 ) < 65 )
			{
				break;
			}
			
			self _setperk( "_specialty_blastshield" );
		}
		else
		{
			if ( randomint( 100 ) < 90 )
			{
				break;
			}
			
			self _unsetperk( "_specialty_blastshield" );
		}
		
		break;
	}
	
	for ( ; self _hasperk( "specialty_onemanarmy" ) && self hasweapon( "onemanarmy_mp" ); )
	{
		if ( self hasThreat() || self HasBotJavelinLocation() )
		{
			break;
		}
		
		if ( self inLastStand() && !self inFinalStand() )
		{
			break;
		}
		
		anyWeapout = false;
		weaponsList = self getweaponslistall();
		
		for ( i = 0; i < weaponsList.size; i++ )
		{
			weap = weaponsList[ i ];
			
			if ( self getammocount( weap ) || weap == "onemanarmy_mp" )
			{
				continue;
			}
			
			anyWeapout = true;
		}
		
		if ( ( !anyWeapout && randomint( 100 ) < 90 ) || randomint( 100 ) < 10 )
		{
			break;
		}
		
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
		
		self notify ( "menuresponse", game[ "menu_onemanarmy" ], self.bot_oma_class );
		
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
		wait randomintrange( 5, 7 );
		
		if ( self isusingremote() )
		{
			continue;
		}
		
		if ( self BotIsFrozen() )
		{
			continue;
		}
		
		if ( self isDefusing() || self isPlanting() )
		{
			continue;
		}
		
		self bot_perk_think_loop();
	}
}

/*
	Bots thinking of using a noobtube
*/
bot_use_tube_think_loop( data )
{
	if ( data.dofastcontinue )
	{
		data.dofastcontinue = false;
	}
	else
	{
		wait randomintrange( 3, 7 );
		
		chance = self.pers[ "bots" ][ "behavior" ][ "nade" ] / 2;
		
		if ( chance > 20 )
		{
			chance = 20;
		}
		
		if ( randomint( 100 ) > chance )
		{
			return;
		}
	}
	
	tube = self getValidTube();
	
	if ( !isdefined( tube ) )
	{
		return;
	}
	
	if ( self hasThreat() || self HasBotJavelinLocation() || self HasScriptAimPos() )
	{
		return;
	}
	
	if ( self BotIsFrozen() )
	{
		return;
	}
	
	if ( self IsBotFragging() || self IsBotSmoking() )
	{
		return;
	}
	
	if ( self isDefusing() || self isPlanting() )
	{
		return;
	}
	
	if ( self isusingremote() )
	{
		return;
	}
	
	if ( self inLastStand() && !self inFinalStand() )
	{
		return;
	}
	
	loc = undefined;
	
	if ( !self nearAnyOfWaypoints( 128, getWaypointsOfType( "tube" ) ) )
	{
		tubeWp = getWaypointForIndex( random( self waypointsNear( getWaypointsOfType( "tube" ), 1024 ) ) );
		
		myEye = self geteye();
		
		if ( !isdefined( tubeWp ) || self HasScriptGoal() || self.bot_lock_goal )
		{
			traceForward = bullettrace( myEye, myEye + anglestoforward( self getplayerangles() ) * 900 * 5, false, self );
			
			loc = traceForward[ "position" ];
			dist = distancesquared( self.origin, loc );
			
			if ( dist < level.bots_mingrenadedistance || dist > level.bots_maxgrenadedistance * 5 )
			{
				return;
			}
			
			if ( !bullettracepassed( self.origin + ( 0, 0, 5 ), self.origin + ( 0, 0, 2048 ), false, self ) )
			{
				return;
			}
			
			if ( !bullettracepassed( loc + ( 0, 0, 5 ), loc + ( 0, 0, 2048 ), false, self ) )
			{
				return;
			}
			
			loc += ( 0, 0, dist / 16000 );
		}
		else
		{
			self BotNotifyBotEvent( "tube", "go", tubeWp, tube );
			
			self SetScriptGoal( tubeWp.origin, 16 );
			
			ret = self waittill_any_return( "new_goal", "goal", "bad_path" );
			
			if ( ret != "new_goal" )
			{
				self ClearScriptGoal();
			}
			
			if ( ret != "goal" )
			{
				return;
			}
			
			data.dofastcontinue = true;
			return;
		}
	}
	else
	{
		tubeWp = getWaypointForIndex( self getNearestWaypointOfWaypoints( getWaypointsOfType( "tube" ) ) );
		loc = tubeWp.origin + anglestoforward( tubeWp.angles ) * 2048;
	}
	
	if ( !isdefined( loc ) )
	{
		return;
	}
	
	self BotNotifyBotEvent( "tube", "start", loc, tube );
	
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
	
	data = spawnstruct();
	data.dofastcontinue = false;
	
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
	if ( data.dofastcontinue )
	{
		data.dofastcontinue = false;
	}
	else
	{
		wait randomintrange( 2, 4 );
		
		chance = self.pers[ "bots" ][ "behavior" ][ "nade" ] / 2;
		
		if ( chance > 20 )
		{
			chance = 20;
		}
		
		if ( randomint( 100 ) > chance )
		{
			return;
		}
	}
	
	nade = undefined;
	
	if ( self getammocount( "claymore_mp" ) )
	{
		nade = "claymore_mp";
	}
	
	if ( self getammocount( "flare_mp" ) )
	{
		nade = "flare_mp";
	}
	
	if ( self getammocount( "c4_mp" ) )
	{
		nade = "c4_mp";
	}
	
	if ( !isdefined( nade ) )
	{
		return;
	}
	
	if ( self hasThreat() || self HasBotJavelinLocation() || self HasScriptAimPos() )
	{
		return;
	}
	
	if ( self BotIsFrozen() )
	{
		return;
	}
	
	if ( self IsBotFragging() || self IsBotSmoking() )
	{
		return;
	}
	
	if ( self isDefusing() || self isPlanting() )
	{
		return;
	}
	
	if ( self isusingremote() )
	{
		return;
	}
	
	if ( self inLastStand() && !self _hasperk( "specialty_laststandoffhand" ) && !self inFinalStand() )
	{
		return;
	}
	
	loc = undefined;
	
	if ( !self nearAnyOfWaypoints( 128, getWaypointsOfType( "claymore" ) ) )
	{
		clayWp = getWaypointForIndex( random( self waypointsNear( getWaypointsOfType( "claymore" ), 1024 ) ) );
		
		if ( !isdefined( clayWp ) || self HasScriptGoal() || self.bot_lock_goal )
		{
			myEye = self geteye();
			loc = myEye + anglestoforward( self getplayerangles() ) * 256;
			
			if ( !bullettracepassed( myEye, loc, false, self ) )
			{
				return;
			}
		}
		else
		{
			self BotNotifyBotEvent( "equ", "go", clayWp, nade );
			
			self SetScriptGoal( clayWp.origin, 16 );
			
			ret = self waittill_any_return( "new_goal", "goal", "bad_path" );
			
			if ( ret != "new_goal" )
			{
				self ClearScriptGoal();
			}
			
			if ( ret != "goal" )
			{
				return;
			}
			
			data.dofastcontinue = true;
			return;
		}
	}
	else
	{
		clayWp = getWaypointForIndex( self getNearestWaypointOfWaypoints( getWaypointsOfType( "claymore" ) ) );
		loc = clayWp.origin + anglestoforward( clayWp.angles ) * 2048;
	}
	
	if ( !isdefined( loc ) )
	{
		return;
	}
	
	self BotNotifyBotEvent( "equ", "start", loc, nade );
	
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
	
	data = spawnstruct();
	data.dofastcontinue = false;
	
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
	if ( data.dofastcontinue )
	{
		data.dofastcontinue = false;
	}
	else
	{
		wait randomintrange( 4, 7 );
		
		chance = self.pers[ "bots" ][ "behavior" ][ "nade" ] / 2;
		
		if ( chance > 20 )
		{
			chance = 20;
		}
		
		if ( randomint( 100 ) > chance )
		{
			return;
		}
	}
	
	nade = self getValidGrenade();
	
	if ( !isdefined( nade ) )
	{
		return;
	}
	
	if ( self hasThreat() || self HasBotJavelinLocation() || self HasScriptAimPos() )
	{
		return;
	}
	
	if ( self BotIsFrozen() )
	{
		return;
	}
	
	if ( self IsBotFragging() || self IsBotSmoking() )
	{
		return;
	}
	
	if ( self isDefusing() || self isPlanting() )
	{
		return;
	}
	
	if ( self isusingremote() )
	{
		return;
	}
	
	if ( self inLastStand() && !self _hasperk( "specialty_laststandoffhand" ) && !self inFinalStand() )
	{
		return;
	}
	
	loc = undefined;
	
	if ( !self nearAnyOfWaypoints( 128, getWaypointsOfType( "grenade" ) ) )
	{
		nadeWp = getWaypointForIndex( random( self waypointsNear( getWaypointsOfType( "grenade" ), 1024 ) ) );
		
		myEye = self geteye();
		
		if ( !isdefined( nadeWp ) || self HasScriptGoal() || self.bot_lock_goal )
		{
			traceForward = bullettrace( myEye, myEye + anglestoforward( self getplayerangles() ) * 900, false, self );
			
			loc = traceForward[ "position" ];
			dist = distancesquared( self.origin, loc );
			
			if ( dist < level.bots_mingrenadedistance || dist > level.bots_maxgrenadedistance )
			{
				return;
			}
			
			if ( !bullettracepassed( self.origin + ( 0, 0, 5 ), self.origin + ( 0, 0, 2048 ), false, self ) )
			{
				return;
			}
			
			if ( !bullettracepassed( loc + ( 0, 0, 5 ), loc + ( 0, 0, 2048 ), false, self ) )
			{
				return;
			}
			
			loc += ( 0, 0, dist / 3000 );
		}
		else
		{
			self BotNotifyBotEvent( "nade", "go", nadeWp, nade );
			
			self SetScriptGoal( nadeWp.origin, 16 );
			
			ret = self waittill_any_return( "new_goal", "goal", "bad_path" );
			
			if ( ret != "new_goal" )
			{
				self ClearScriptGoal();
			}
			
			if ( ret != "goal" )
			{
				return;
			}
			
			data.dofastcontinue = true;
			return;
		}
	}
	else
	{
		nadeWp = getWaypointForIndex( self getNearestWaypointOfWaypoints( getWaypointsOfType( "grenade" ) ) );
		loc = nadeWp.origin + anglestoforward( nadeWp.angles ) * 2048;
	}
	
	if ( !isdefined( loc ) )
	{
		return;
	}
	
	self BotNotifyBotEvent( "nade", "start", loc, nade );
	
	self SetScriptAimPos( loc );
	self BotStopMoving( true );
	wait 1;
	
	time = 0.5;
	
	if ( nade == "frag_grenade_mp" )
	{
		time = 2;
	}
	
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
	
	data = spawnstruct();
	data.dofastcontinue = false;
	
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
	
	if ( !isdefined( tube ) )
	{
		if ( self getammocount( "at4_mp" ) )
		{
			tube = "at4_mp";
		}
		else if ( self getammocount( "rpg_mp" ) )
		{
			tube = "rpg_mp";
		}
		else
		{
			return;
		}
	}
	
	if ( self getcurrentweapon() == tube )
	{
		return;
	}
	
	chance = self.pers[ "bots" ][ "behavior" ][ "nade" ];
	
	if ( randomint( 100 ) > chance )
	{
		return;
	}
	
	self thread changeToWeapon( tube );
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
		wait randomintrange( 1, 4 );
		
		if ( self BotIsFrozen() )
		{
			continue;
		}
		
		if ( self isDefusing() || self isPlanting() )
		{
			continue;
		}
		
		if ( self isusingremote() )
		{
			continue;
		}
		
		if ( self inLastStand() && !self inFinalStand() )
		{
			continue;
		}
		
		if ( self hasThreat() )
		{
			continue;
		}
		
		self bot_watch_think_mw2_loop();
	}
}

/*
	Bots will use gremades/wweapons while having a target while using a shield
*/
bot_watch_riot_weapons_loop()
{
	threat = self getThreat();
	dist = distancesquared( threat.origin, self.origin );
	curWeap = self getcurrentweapon();
	
	if ( randomint( 2 ) )
	{
		nade = self getValidGrenade();
		
		if ( !isdefined( nade ) )
		{
			return;
		}
		
		if ( dist <= level.bots_mingrenadedistance || dist >= level.bots_maxgrenadedistance )
		{
			return;
		}
		
		if ( randomint( 100 ) > self.pers[ "bots" ][ "behavior" ][ "nade" ] )
		{
			return;
		}
		
		self botThrowGrenade( nade );
	}
	else
	{
		if ( randomint( 100 ) > self.pers[ "bots" ][ "behavior" ][ "switch" ] * 10 )
		{
			return;
		}
		
		weaponslist = self getweaponslistall();
		weap = "";
		
		while ( weaponslist.size )
		{
			weapon = weaponslist[ randomint( weaponslist.size ) ];
			weaponslist = array_remove( weaponslist, weapon );
			
			if ( !self getammocount( weapon ) )
			{
				continue;
			}
			
			if ( !isWeaponPrimary( weapon ) )
			{
				continue;
			}
			
			if ( curWeap == weapon || weapon == "none" || weapon == "" || weapon == "javelin_mp" || weapon == "stinger_mp" || weapon == "onemanarmy_mp" )
			{
				continue;
			}
			
			weap = weapon;
			break;
		}
		
		if ( weap == "" )
		{
			return;
		}
		
		self thread changeToWeapon( weap );
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
		wait randomintrange( 2, 4 );
		
		if ( self BotIsFrozen() )
		{
			continue;
		}
		
		if ( self isDefusing() || self isPlanting() )
		{
			continue;
		}
		
		if ( self isusingremote() )
		{
			continue;
		}
		
		if ( self inLastStand() && !self inFinalStand() )
		{
			continue;
		}
		
		if ( !self hasThreat() )
		{
			continue;
		}
		
		if ( !self.hasriotshieldequipped )
		{
			continue;
		}
		
		self bot_watch_riot_weapons_loop();
	}
}

/*
	BOts thinking of using javelins
*/
bot_jav_loc_think_loop( data )
{
	if ( data.dofastcontinue )
	{
		data.dofastcontinue = false;
	}
	else
	{
		wait randomintrange( 2, 4 );
		
		chance = self.pers[ "bots" ][ "behavior" ][ "nade" ] / 2;
		
		if ( chance > 20 )
		{
			chance = 20;
		}
		
		if ( randomint( 100 ) > chance && self getcurrentweapon() != "javelin_mp" )
		{
			return;
		}
	}
	
	if ( !self getammocount( "javelin_mp" ) )
	{
		return;
	}
	
	if ( self hasThreat() || self HasBotJavelinLocation() || self HasScriptAimPos() )
	{
		return;
	}
	
	if ( self BotIsFrozen() )
	{
		return;
	}
	
	if ( self isDefusing() || self isPlanting() )
	{
		return;
	}
	
	if ( self isusingremote() )
	{
		return;
	}
	
	if ( self inLastStand() && !self inFinalStand() )
	{
		return;
	}
	
	if ( self isemped() )
	{
		return;
	}
	
	loc = undefined;
	
	if ( !self nearAnyOfWaypoints( 128, getWaypointsOfType( "javelin" ) ) )
	{
		javWp = getWaypointForIndex( random( self waypointsNear( getWaypointsOfType( "javelin" ), 1024 ) ) );
		
		if ( !isdefined( javWp ) || self HasScriptGoal() || self.bot_lock_goal )
		{
			traceForward = self maps\mp\_javelin::eyetraceforward();
			
			if ( !isdefined( traceForward ) )
			{
				return;
			}
			
			loc = traceForward[ 0 ];
			
			if ( self maps\mp\_javelin::targetpointtooclose( loc ) )
			{
				return;
			}
			
			if ( !bullettracepassed( self.origin + ( 0, 0, 5 ), self.origin + ( 0, 0, 2048 ), false, self ) )
			{
				return;
			}
			
			if ( !bullettracepassed( loc + ( 0, 0, 5 ), loc + ( 0, 0, 2048 ), false, self ) )
			{
				return;
			}
		}
		else
		{
			self BotNotifyBotEvent( "jav", "go", javWp );
			
			self SetScriptGoal( javWp.origin, 16 );
			
			ret = self waittill_any_return( "new_goal", "goal", "bad_path" );
			
			if ( ret != "new_goal" )
			{
				self ClearScriptGoal();
			}
			
			if ( ret != "goal" )
			{
				return;
			}
			
			data.dofastcontinue = true;
			return;
		}
	}
	else
	{
		javWp = getWaypointForIndex( self getNearestWaypointOfWaypoints( getWaypointsOfType( "javelin" ) ) );
		loc = javWp.jav_point;
	}
	
	if ( !isdefined( loc ) )
	{
		return;
	}
	
	self BotNotifyBotEvent( "jav", "start", loc );
	
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
	
	data = spawnstruct();
	data.dofastcontinue = false;
	
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
	myTeam = self.pers[ "team" ];
	hasSitrep = self _hasperk( "specialty_detectexplosive" );
	grenades = getentarray( "grenade", "classname" );
	myEye = self geteye();
	myAngles = self getplayerangles();
	dist = 512 * 512;
	target = undefined;
	
	for ( i = 0; i < grenades.size; i++ )
	{
		item = grenades[ i ];
		
		if ( !isdefined( item ) )
		{
			continue;
		}
		
		if ( !isdefined( item.name ) )
		{
			continue;
		}
		
		if ( isdefined( item.owner ) && ( ( level.teambased && item.owner.team == self.team ) || item.owner == self ) )
		{
			continue;
		}
		
		if ( item.name != "c4_mp" && item.name != "claymore_mp" )
		{
			continue;
		}
		
		if ( !hasSitrep && !bullettracepassed( myEye, item.origin, false, item ) )
		{
			continue;
		}
		
		if ( getConeDot( item.origin, self.origin, myAngles ) < 0.6 )
		{
			continue;
		}
		
		if ( distancesquared( item.origin, self.origin ) < dist )
		{
			target = item;
			break;
		}
	}
	
	grenades = undefined;
	
	if ( !isdefined( target ) )
	{
		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[ i ];
			
			if ( player == self )
			{
				continue;
			}
			
			if ( !isdefined( player.team ) )
			{
				continue;
			}
			
			if ( level.teambased && player.team == myTeam )
			{
				continue;
			}
			
			ti = player.setspawnpoint;
			
			if ( !isdefined( ti ) )
			{
				continue;
			}
			
			if ( !isdefined( ti.bots ) )
			{
				ti.bots = 0;
			}
			
			if ( ti.bots >= 2 )
			{
				continue;
			}
			
			if ( !hasSitrep && !bullettracepassed( myEye, ti.origin, false, ti ) )
			{
				continue;
			}
			
			if ( getConeDot( ti.origin, self.origin, myAngles ) < 0.6 )
			{
				continue;
			}
			
			if ( distancesquared( ti.origin, self.origin ) < dist )
			{
				target = ti;
				break;
			}
		}
	}
	
	if ( !isdefined( target ) )
	{
		return;
	}
	
	if ( isdefined( target.enemytrigger ) && !self HasScriptGoal() && !self.bot_lock_goal )
	{
		self BotNotifyBotEvent( "attack_equ", "go_ti", target );
		
		self SetScriptGoal( target.origin, 64 );
		self thread bot_inc_bots( target, true );
		self thread bots_watch_touch_obj( target );
		
		path = self waittill_any_return( "bad_path", "goal", "new_goal" );
		
		if ( path != "new_goal" )
		{
			self ClearScriptGoal();
		}
		
		if ( path != "goal" || !isdefined( target ) )
		{
			return;
		}
		
		if ( randomint( 100 ) < self.pers[ "bots" ][ "behavior" ][ "camp" ] * 8 )
		{
			self BotNotifyBotEvent( "attack_equ", "camp_ti", target );
			
			self thread killCampAfterTime( randomintrange( 10, 20 ) );
			self thread killCampAfterEntGone( target );
			self CampAtSpot( target.origin, target.origin + ( 0, 0, 42 ) );
		}
		
		if ( isdefined( target ) )
		{
			self BotNotifyBotEvent( "attack_equ", "trigger_ti", target );
			self thread BotPressUse();
		}
		
		return;
	}
	
	self BotNotifyBotEvent( "attack_equ", "start", target );
	
	self SetScriptEnemy( target );
	self bot_equipment_attack( target );
	self ClearScriptEnemy();
	
	self BotNotifyBotEvent( "attack_equ", "stop", target );
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
		wait( randomintrange( 1, 3 ) );
		
		if ( self HasScriptEnemy() )
		{
			continue;
		}
		
		if ( self.pers[ "bots" ][ "skill" ][ "base" ] <= 1 )
		{
			continue;
		}
		
		self bot_equipment_kill_think_loop();
	}
}

/*
	Bots target the equipment for a time then stop
*/
bot_equipment_attack( equ )
{
	wait_time = randomintrange( 7, 10 );
	
	for ( i = 0; i < wait_time; i++ )
	{
		wait( 1 );
		
		if ( !isdefined( equ ) )
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
	dist = level.bots_listendist;
	
	if ( self _hasperk( "specialty_selectivehearing" ) )
	{
		dist *= 1.4;
	}
	
	dist *= dist;
	
	heard = undefined;
	
	for ( i = level.players.size - 1 ; i >= 0; i-- )
	{
		player = level.players[ i ];
		
		if ( player == self )
		{
			continue;
		}
		
		if ( level.teambased && self.team == player.team )
		{
			continue;
		}
		
		if ( player.sessionstate != "playing" )
		{
			continue;
		}
		
		if ( !isreallyalive( player ) )
		{
			continue;
		}
		
		if ( lengthsquared( player getvelocity() ) < 20000 )
		{
			continue;
		}
		
		if ( distancesquared( player.origin, self.origin ) > dist )
		{
			continue;
		}
		
		if ( player _hasperk( "specialty_quieter" ) )
		{
			continue;
		}
		
		heard = player;
		break;
	}
	
	hasHeartbeat = ( issubstr( self getcurrentweapon(), "_heartbeat_" ) && !self isemped() );
	heartbeatDist = 350 * 350;
	
	if ( !isdefined( heard ) && hasHeartbeat )
	{
		for ( i = level.players.size - 1 ; i >= 0; i-- )
		{
			player = level.players[ i ];
			
			if ( player == self )
			{
				continue;
			}
			
			if ( level.teambased && self.team == player.team )
			{
				continue;
			}
			
			if ( player.sessionstate != "playing" )
			{
				continue;
			}
			
			if ( !isreallyalive( player ) )
			{
				continue;
			}
			
			if ( player _hasperk( "specialty_heartbreaker" ) )
			{
				continue;
			}
			
			if ( distancesquared( player.origin, self.origin ) > heartbeatDist )
			{
				continue;
			}
			
			if ( getConeDot( player.origin, self.origin, self getplayerangles() ) < 0.6 )
			{
				continue;
			}
			
			heard = player;
			break;
		}
	}
	
	if ( !isdefined( heard ) )
	{
		return;
	}
	
	self BotNotifyBotEvent( "heard_target", "start", heard );
	
	if ( bullettracepassed( self geteye(), heard gettagorigin( "j_spineupper" ), false, heard ) )
	{
		self setAttacker( heard );
		return;
	}
	
	if ( self HasScriptGoal() || self.bot_lock_goal )
	{
		return;
	}
	
	self SetScriptGoal( heard.origin, 64 );
	
	if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
	{
		self ClearScriptGoal();
	}
	
	self BotNotifyBotEvent( "heard_target", "stop", heard );
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
		
		if ( self.pers[ "bots" ][ "skill" ][ "base" ] < 3 )
		{
			continue;
		}
		
		self bot_listen_to_steps_loop();
	}
}

/*
	Bots will look at the uav and target targets
*/
bot_uav_think_loop()
{
	hasRadar = ( ( level.teambased && level.activeuavs[ self.team ] ) || ( !level.teambased && level.activeuavs[ self.guid ] ) );
	
	if ( level.hardcoremode && !hasRadar )
	{
		return;
	}
	
	dist = self.pers[ "bots" ][ "skill" ][ "help_dist" ];
	dist *= dist * 8;
	
	for ( i = level.players.size - 1; i >= 0; i-- )
	{
		player = level.players[ i ];
		
		if ( player == self )
		{
			continue;
		}
		
		if ( !isdefined( player.team ) )
		{
			continue;
		}
		
		if ( player.sessionstate != "playing" )
		{
			continue;
		}
		
		if ( level.teambased && player.team == self.team )
		{
			continue;
		}
		
		if ( !isreallyalive( player ) )
		{
			continue;
		}
		
		distFromPlayer = distancesquared( self.origin, player.origin );
		
		if ( distFromPlayer > dist )
		{
			continue;
		}
		
		if ( ( !issubstr( player getcurrentweapon(), "_silencer_" ) && player.bots_firing ) || ( hasRadar && !player _hasperk( "specialty_coldblooded" ) ) )
		{
			self BotNotifyBotEvent( "uav_target", "start", player );
			
			distSq = self.pers[ "bots" ][ "skill" ][ "help_dist" ] * self.pers[ "bots" ][ "skill" ][ "help_dist" ];
			
			if ( distFromPlayer < distSq && bullettracepassed( self geteye(), player gettagorigin( "j_spineupper" ), false, player ) )
			{
				self setAttacker( player );
			}
			
			if ( !self HasScriptGoal() && !self.bot_lock_goal )
			{
				self SetScriptGoal( player.origin, 128 );
				self thread stop_go_target_on_death( player );
				
				if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
				{
					self ClearScriptGoal();
				}
				
				self BotNotifyBotEvent( "uav_target", "stop", player );
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
		
		if ( self.pers[ "bots" ][ "skill" ][ "base" ] <= 1 || self isusingremote() )
		{
			continue;
		}
		
		if ( self isemped() || self.bot_isscrambled )
		{
			continue;
		}
		
		if ( self _hasperk( "_specialty_blastshield" ) )
		{
			continue;
		}
		
		if ( ( level.teambased && level.activecounteruavs[ level.otherteam[ self.team ] ] ) || ( !level.teambased && self.isradarblocked ) )
		{
			continue;
		}
		
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
	
	if ( self.pers[ "bots" ][ "skill" ][ "base" ] <= 1 )
	{
		return;
	}
	
	if ( isdefined( self.lastkiller ) && isreallyalive( self.lastkiller ) )
	{
		if ( bullettracepassed( self geteye(), self.lastkiller gettagorigin( "j_spineupper" ), false, self.lastkiller ) )
		{
			self setAttacker( self.lastkiller );
		}
	}
	
	if ( !isdefined( self.killerlocation ) )
	{
		return;
	}
	
	loc = self.killerlocation;
	
	for ( ;; )
	{
		wait( randomintrange( 1, 5 ) );
		
		if ( self HasScriptGoal() || self.bot_lock_goal )
		{
			return;
		}
		
		if ( randomint( 100 ) < 75 )
		{
			return;
		}
		
		self BotNotifyBotEvent( "revenge", "start", loc, self.lastkiller );
		
		self SetScriptGoal( loc, 64 );
		
		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearScriptGoal();
		}
		
		self BotNotifyBotEvent( "revenge", "stop", loc, self.lastkiller );
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
		
		if ( !isdefined( turret ) )
		{
			break;
		}
		
		if ( turret.health <= 20000 )
		{
			break;
		}
		
		if ( isdefined( turret.carriedby ) )
		{
			break;
		}
	}
	
	self notify( "bad_path" );
}

/*
	Bots will target the turret for a time
*/
bot_turret_attack( enemy )
{
	wait_time = randomintrange( 7, 10 );
	
	for ( i = 0; i < wait_time; i++ )
	{
		wait( 1 );
		
		if ( !isdefined( enemy ) )
		{
			return;
		}
		
		if ( enemy.health <= 20000 )
		{
			return;
		}
		
		if ( isdefined( enemy.carriedby ) )
		{
			return;
		}
		
		// if ( !bullettracepassed( self geteye(), enemy.origin + ( 0, 0, 15 ), false, enemy ) )
		//	return;
	}
}

/*
	Bots will think when to target a turret
*/
bot_turret_think_loop()
{
	myTeam = self.pers[ "team" ];
	turretsKeys = getarraykeys( level.turrets );
	
	if ( turretsKeys.size == 0 )
	{
		wait( randomintrange( 3, 5 ) );
		return;
	}
	
	if ( self.pers[ "bots" ][ "skill" ][ "base" ] <= 1 )
	{
		return;
	}
	
	if ( self HasScriptEnemy() || self isusingremote() )
	{
		return;
	}
	
	myEye = self geteye();
	turret = undefined;
	
	for ( i = turretsKeys.size - 1; i >= 0; i-- )
	{
		tempTurret = level.turrets[ turretsKeys[ i ] ];
		
		if ( !isdefined( tempTurret ) )
		{
			continue;
		}
		
		if ( tempTurret.health <= 20000 )
		{
			continue;
		}
		
		if ( isdefined( tempTurret.carriedby ) )
		{
			continue;
		}
		
		if ( isdefined( tempTurret.owner ) && tempTurret.owner == self )
		{
			continue;
		}
		
		if ( level.teambased && tempTurret.team == myTeam )
		{
			continue;
		}
		
		if ( !bullettracepassed( myEye, tempTurret.origin + ( 0, 0, 15 ), false, tempTurret ) )
		{
			continue;
		}
		
		turret = tempTurret;
	}
	
	turretsKeys = undefined;
	
	if ( !isdefined( turret ) )
	{
		return;
	}
	
	forward = anglestoforward( turret.angles );
	forward = vectornormalize( forward );
	
	delta = self.origin - turret.origin;
	delta = vectornormalize( delta );
	
	dot = vectordot( forward, delta );
	
	facing = true;
	
	if ( dot < 0.342 ) // cos 70 degrees
	{
		facing = false;
	}
	
	if ( turret isStunned() )
	{
		facing = false;
	}
	
	if ( self _hasperk( "specialty_coldblooded" ) )
	{
		facing = false;
	}
	
	if ( facing && !bullettracepassed( myEye, turret.origin + ( 0, 0, 15 ), false, turret ) )
	{
		return;
	}
	
	if ( !isdefined( turret.bots ) )
	{
		turret.bots = 0;
	}
	
	if ( turret.bots >= 2 )
	{
		return;
	}
	
	if ( !facing && !self HasScriptGoal() && !self.bot_lock_goal )
	{
		self BotNotifyBotEvent( "turret_attack", "go", turret );
		
		self SetScriptGoal( turret.origin, 32 );
		self thread bot_inc_bots( turret, true );
		self thread turret_death_monitor( turret );
		self thread bots_watch_touch_obj( turret );
		
		if ( self waittill_any_return( "bad_path", "goal", "new_goal" ) != "new_goal" )
		{
			self ClearScriptGoal();
		}
	}
	
	if ( !isdefined( turret ) )
	{
		return;
	}
	
	self BotNotifyBotEvent( "turret_attack", "start", turret );
	
	self SetScriptEnemy( turret, ( 0, 0, 25 ) );
	self bot_turret_attack( turret );
	self ClearScriptEnemy();
	
	self BotNotifyBotEvent( "turret_attack", "stop", turret );
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
	crates = getentarray( "care_package", "targetname" );
	
	if ( crates.size == 0 )
	{
		return;
	}
	
	crate = undefined;
	
	for ( i = crates.size - 1; i >= 0; i-- )
	{
		tempCrate = crates[ i ];
		
		if ( !isdefined( tempCrate ) )
		{
			continue;
		}
		
		if ( !isdefined( tempCrate.doingphysics ) || tempCrate.doingphysics )
		{
			continue;
		}
		
		if ( isdefined( crate ) && distancesquared( crate.origin, self.origin ) < distancesquared( tempCrate.origin, self.origin ) )
		{
			continue;
		}
		
		crate = tempCrate;
	}
	
	if ( !isdefined( crate ) )
	{
		return;
	}
	
	radius = getdvarfloat( "player_useRadius" );
	
	if ( distancesquared( crate.origin, self.origin ) > radius * radius )
	{
		return;
	}
	
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
		
		if ( self hasThreat() )
		{
			continue;
		}
		
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
	{
		data.first = false;
	}
	else
	{
		ret = self waittill_any_timeout( randomintrange( 3, 5 ), "crate_physics_done" );
	}
	
	myTeam = self.pers[ "team" ];
	crate = self.bot_stuck_on_carepackage;
	self.bot_stuck_on_carepackage = undefined;
	
	if ( !isdefined( crate ) )
	{
		if ( randomint( 100 ) < 20 && ret != "crate_physics_done" )
		{
			return;
		}
		
		if ( self HasScriptGoal() || self.bot_lock_goal )
		{
			return;
		}
		
		if ( self isDefusing() || self isPlanting() )
		{
			return;
		}
		
		if ( self isusingremote() || self BotIsFrozen() )
		{
			return;
		}
		
		if ( self inLastStand() )
		{
			return;
		}
		
		crates = getentarray( "care_package", "targetname" );
		
		if ( crates.size == 0 )
		{
			return;
		}
		
		wantsClosest = randomint( 2 );
		
		crate = undefined;
		
		for ( i = crates.size - 1; i >= 0; i-- )
		{
			tempCrate = crates[ i ];
			
			if ( !isdefined( tempCrate ) )
			{
				continue;
			}
			
			if ( !isdefined( tempCrate.doingphysics ) || tempCrate.doingphysics )
			{
				continue;
			}
			
			if ( !isdefined( tempCrate.bots ) )
			{
				tempCrate.bots = 0;
			}
			
			if ( tempCrate.bots >= 3 )
			{
				continue;
			}
			
			if ( isdefined( crate ) )
			{
				if ( wantsClosest )
				{
					if ( distancesquared( crate.origin, self.origin ) < distancesquared( tempCrate.origin, self.origin ) )
					{
						continue;
					}
				}
				else
				{
					if ( maps\mp\killstreaks\_killstreaks::getstreakcost( crate.cratetype ) > maps\mp\killstreaks\_killstreaks::getstreakcost( tempCrate.cratetype ) )
					{
						continue;
					}
				}
			}
			
			crate = tempCrate;
		}
		
		crates = undefined;
		
		if ( !isdefined( crate ) )
		{
			return;
		}
		
		self BotNotifyBotEvent( "crate_cap", "go", crate );
		
		self.bot_lock_goal = true;
		
		radius = getdvarfloat( "player_useRadius" ) - 16;
		self SetScriptGoal( crate.origin, radius );
		self thread bot_inc_bots( crate, true );
		self thread bots_watch_touch_obj( crate );
		
		path = self waittill_any_return( "bad_path", "goal", "new_goal" );
		
		self.bot_lock_goal = false;
		
		if ( path != "new_goal" )
		{
			self ClearScriptGoal();
		}
		
		if ( path != "goal" || !isdefined( crate ) || distancesquared( self.origin, crate.origin ) > radius * radius )
		{
			if ( isdefined( crate ) && path == "bad_path" )
			{
				self BotNotifyBotEvent( "crate_cap", "unreachable", crate );
			}
			
			return;
		}
	}
	
	self BotNotifyBotEvent( "crate_cap", "start", crate );
	
	self BotRandomStance();
	
	self BotFreezeControls( true );
	self bot_wait_stop_move();
	
	waitTime = 3.25;
	
	if ( !isdefined( crate.owner ) || crate.owner == self )
	{
		waitTime = 0.75;
	}
	
	self thread BotPressUse( waitTime );
	wait waitTime;
	
	self BotFreezeControls( false );
	
	// check if actually captured it?
	self BotNotifyBotEvent( "crate_cap", "stop", crate );
}

/*
	Bots will capture carepackages
*/
bot_crate_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	data = spawnstruct();
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
	{
		return;
	}
	
	if ( self isDefusing() || self isPlanting() )
	{
		return;
	}
	
	if ( self isusingremote() )
	{
		return;
	}
	
	if ( self inLastStand() && !self inFinalStand() )
	{
		return;
	}
	
	curWeap = self getcurrentweapon();
	
	if ( !maps\mp\gametypes\_weapons::isprimaryweapon( curWeap ) )
	{
		return;
	}
	
	if ( ret == "reload" )
	{
		// check single reloads
		if ( self getweaponammoclip( curWeap ) < weaponclipsize( curWeap ) )
		{
			return;
		}
	}
	
	// check difficulty
	if ( self.pers[ "bots" ][ "skill" ][ "base" ] <= 3 )
	{
		return;
	}
	
	// check if got another weapon
	weaponslist = self getweaponslistprimaries();
	weap = "";
	
	while ( weaponslist.size )
	{
		weapon = weaponslist[ randomint( weaponslist.size ) ];
		weaponslist = array_remove( weaponslist, weapon );
		
		if ( !maps\mp\gametypes\_weapons::isprimaryweapon( weapon ) )
		{
			continue;
		}
		
		if ( curWeap == weapon || weapon == "none" || weapon == "" )
		{
			continue;
		}
		
		weap = weapon;
		break;
	}
	
	if ( weap == "" )
	{
		return;
	}
	
	// do the cancel
	wait 0.1;
	self thread changeToWeapon( weap );
	wait 0.25;
	self thread changeToWeapon( curWeap );
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
	ret = self waittill_any_timeout( randomintrange( 2, 4 ), "bot_force_check_switch" );
	
	if ( self BotIsFrozen() )
	{
		return;
	}
	
	if ( self isDefusing() || self isPlanting() )
	{
		return;
	}
	
	if ( self isusingremote() )
	{
		return;
	}
	
	if ( self inLastStand() && !self inFinalStand() )
	{
		return;
	}
	
	curWeap = self getcurrentweapon();
	hasTarget = self hasThreat();
	
	if ( hasTarget )
	{
		threat = self getThreat();
		rocketAmmo = self getRocketAmmo();
		
		if ( entIsVehicle( threat ) && isdefined( rocketAmmo ) )
		{
			if ( curWeap != rocketAmmo )
			{
				self thread changeToWeapon( rocketAmmo );
			}
			
			return;
		}
	}
	
	if ( self HasBotJavelinLocation() && self getammocount( "javelin_mp" ) )
	{
		if ( curWeap != "javelin_mp" )
		{
			self thread changeToWeapon( "javelin_mp" );
		}
		
		return;
	}
	
	if ( isdefined( self.bot_oma_class ) )
	{
		if ( curWeap != "onemanarmy_mp" )
		{
			self thread changeToWeapon( "onemanarmy_mp" );
		}
		
		return;
	}
	
	force = ( ret == "bot_force_check_switch" );
	
	if ( data.first )
	{
		data.first = false;
		
		if ( randomint( 100 ) > self.pers[ "bots" ][ "behavior" ][ "initswitch" ] )
		{
			return;
		}
	}
	else
	{
		if ( curWeap != "none" && self getammocount( curWeap ) && curWeap != "stinger_mp" && curWeap != "javelin_mp" && curWeap != "onemanarmy_mp" )
		{
			if ( randomint( 100 ) > self.pers[ "bots" ][ "behavior" ][ "switch" ] )
			{
				return;
			}
			
			if ( hasTarget )
			{
				return;
			}
		}
		else
		{
			force = true;
		}
	}
	
	weaponslist = self getweaponslistall();
	weap = "";
	
	while ( weaponslist.size )
	{
		weapon = weaponslist[ randomint( weaponslist.size ) ];
		weaponslist = array_remove( weaponslist, weapon );
		
		if ( !self getammocount( weapon ) && !force )
		{
			continue;
		}
		
		if ( !isWeaponPrimary( weapon ) )
		{
			continue;
		}
		
		if ( curWeap == weapon || weapon == "none" || weapon == "" || weapon == "javelin_mp" || weapon == "stinger_mp" || weapon == "onemanarmy_mp" )
		{
			continue;
		}
		
		weap = weapon;
		break;
	}
	
	if ( weap == "" )
	{
		return;
	}
	
	self thread changeToWeapon( weap );
}

/*
	Bots will think to switch weapons
*/
bot_weapon_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	data = spawnstruct();
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
	
	if ( !isdefined( rocketAmmo ) && self BotGetRandom() < 90 )
	{
		return;
	}
	
	if ( isdefined( rocketAmmo ) && rocketAmmo == "javelin_mp" && self isemped() )
	{
		return;
	}
	
	targets = maps\mp\_stinger::gettargetlist();
	
	if ( !targets.size )
	{
		return;
	}
	
	lockOnAmmo = self getLockonAmmo();
	myEye = self geteye();
	target = undefined;
	
	for ( i = targets.size - 1; i >= 0; i-- )
	{
		tempTarget = targets[ i ];
		
		if ( isdefined( tempTarget.owner ) && tempTarget.owner == self )
		{
			continue;
		}
		
		if ( !bullettracepassed( myEye, tempTarget.origin, false, tempTarget ) )
		{
			continue;
		}
		
		if ( tempTarget.health <= 0 )
		{
			continue;
		}
		
		if ( tempTarget.classname != "script_vehicle" && !isdefined( lockOnAmmo ) )
		{
			continue;
		}
		
		target = tempTarget;
	}
	
	targets = undefined;
	
	if ( !isdefined( target ) )
	{
		return;
	}
	
	self BotNotifyBotEvent( "attack_vehicle", "start", target, rocketAmmo );
	
	self SetScriptEnemy( target, ( 0, 0, 0 ) );
	self bot_attack_vehicle( target );
	self ClearScriptEnemy();
	self notify( "bot_force_check_switch" );
	
	self BotNotifyBotEvent( "attack_vehicle", "stop", target, rocketAmmo );
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
		wait randomintrange( 2, 4 );
		
		if ( self.pers[ "bots" ][ "skill" ][ "base" ] <= 1 )
		{
			continue;
		}
		
		if ( self HasScriptEnemy() )
		{
			continue;
		}
		
		if ( self isusingremote() )
		{
			continue;
		}
		
		self bot_target_vehicle_loop();
	}
}

/*
	Bots target the killstreak for a time and stops
*/
bot_attack_vehicle( target )
{
	target endon( "death" );
	
	wait_time = randomintrange( 7, 10 );
	
	for ( i = 0; i < wait_time; i++ )
	{
		self notify( "bot_force_check_switch" );
		wait( 1 );
		
		if ( !isdefined( target ) )
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
		player = level.players[ i ];
		
		if ( player == self )
		{
			continue;
		}
		
		if ( !isdefined( player.team ) )
		{
			continue;
		}
		
		if ( level.teambased && self.team == player.team )
		{
			continue;
		}
		
		if ( player.sessionstate != "playing" )
		{
			continue;
		}
		
		if ( !isreallyalive( player ) )
		{
			continue;
		}
		
		if ( player _hasperk( "specialty_coldblooded" ) )
		{
			continue;
		}
		
		if ( !bullettracepassed( player.origin, player.origin + ( 0, 0, 2048 ), false, player ) && self.pers[ "bots" ][ "skill" ][ "base" ] > 3 )
		{
			continue;
		}
		
		players[ players.size ] = player;
	}
	
	target = random( players );
	
	if ( isdefined( target ) )
	{
		location = target.origin + ( randomintrange( ( 8 - self.pers[ "bots" ][ "skill" ][ "base" ] ) * -75, ( 8 - self.pers[ "bots" ][ "skill" ][ "base" ] ) * 75 ), randomintrange( ( 8 - self.pers[ "bots" ][ "skill" ][ "base" ] ) * -75, ( 8 - self.pers[ "bots" ][ "skill" ][ "base" ] ) * 75 ), 0 );
	}
	else if ( self.pers[ "bots" ][ "skill" ][ "base" ] <= 3 )
	{
		location = self.origin + ( randomintrange( -512, 512 ), randomintrange( -512, 512 ), 0 );
	}
	
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
	
	if ( isdefined( isac130 ) && isac130 )
	{
		level.ac130inuse = false;
	}
	
	if ( isdefined( self ) )
	{
		self clearusingremote();
	}
}

/*
	Returns if any harriers exists that is an enemy
*/
isAnyEnemyPlanes()
{
	if ( !isdefined( level.harriers ) )
	{
		return false;
	}
	
	for ( i = 0; i < level.harriers.size; i++ )
	{
		plane = level.harriers[ i ];
		
		if ( !isdefined( plane ) )
		{
			continue;
		}
		
		if ( level.teambased && plane.team == self.team )
		{
			continue;
		}
		
		if ( isdefined( plane.owner ) && plane.owner == self )
		{
			continue;
		}
		
		return true;
	}
	
	return false;
}

/*
	Bots think to use killstreaks
*/
bot_killstreak_think_loop( data )
{
	if ( data.dofastcontinue )
	{
		data.dofastcontinue = false;
	}
	else
	{
		wait randomintrange( 1, 3 );
	}
	
	if ( !isdefined( self.pers[ "killstreaks" ][ 0 ] ) )
	{
		return;
	}
	
	if ( self BotIsFrozen() )
	{
		return;
	}
	
	if ( self hasThreat() || self HasBotJavelinLocation() )
	{
		return;
	}
	
	if ( self isDefusing() || self isPlanting() )
	{
		return;
	}
	
	if ( self isemped() )
	{
		return;
	}
	
	if ( self isusingremote() )
	{
		return;
	}
	
	if ( self inLastStand() && !self inFinalStand() )
	{
		return;
	}
	
	
	if ( isdefined( self.iscarrying ) && self.iscarrying )
	{
		self notify( "place_sentry" );
	}
	
	curWeap = self getcurrentweapon();
	
	if ( issubstr( curWeap, "airdrop_" ) )
	{
		self thread BotPressAttack( 0.05 );
	}
	
	
	streakName = self.pers[ "killstreaks" ][ 0 ].streakname;
	
	if ( level.ingraceperiod && maps\mp\killstreaks\_killstreaks::deadlykillstreak( streakName ) )
	{
		return;
	}
	
	ksWeap = maps\mp\killstreaks\_killstreaks::getkillstreakweapon( streakName );
	
	if ( curWeap == "none" || !isWeaponPrimary( curWeap ) )
	{
		curWeap = self getlastweapon();
	}
	
	lifeId = self.pers[ "killstreaks" ][ 0 ].lifeid;
	
	if ( !isdefined( lifeId ) )
	{
		lifeId = -1;
	}
	
	if ( isStrStart( streakName, "helicopter_" ) && self isAnyEnemyPlanes() && self.pers[ "bots" ][ "skill" ][ "base" ] > 3 )
	{
		return;
	}
	
	if ( maps\mp\killstreaks\_killstreaks::isridekillstreak( streakName ) || maps\mp\killstreaks\_killstreaks::iscarrykillstreak( streakName ) )
	{
		if ( self inLastStand() )
		{
			return;
		}
		
		if ( lifeId == self.deaths && !self HasScriptGoal() && !self.bot_lock_goal && streakName != "sentry" && !self nearAnyOfWaypoints( 128, getWaypointsOfType( "camp" ) ) )
		{
			campSpot = getWaypointForIndex( random( self waypointsNear( getWaypointsOfType( "camp" ), 1024 ) ) );
			
			if ( isdefined( campSpot ) )
			{
				self BotNotifyBotEvent( "killstreak", "camp", streakName, campSpot );
				
				self SetScriptGoal( campSpot.origin, 16 );
				
				if ( self waittill_any_return( "new_goal", "goal", "bad_path" ) != "new_goal" )
				{
					self ClearScriptGoal();
				}
				
				data.dofastcontinue = true;
				return;
			}
		}
		
		if ( streakName == "sentry" )
		{
			if ( self HasScriptAimPos() )
			{
				return;
			}
			
			myEye = self geteye();
			angles = self getplayerangles();
			
			forwardTrace = bullettrace( myEye, myEye + anglestoforward( angles ) * 1024, false, self );
			
			if ( distancesquared( self.origin, forwardTrace[ "position" ] ) < 1000 * 1000 && self.pers[ "bots" ][ "skill" ][ "base" ] > 3 )
			{
				return;
			}
			
			self BotNotifyBotEvent( "killstreak", "call", streakName );
			
			self BotStopMoving( true );
			self SetScriptAimPos( forwardTrace[ "position" ] );
			
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
			
			self BotStopMoving( false );
			self ClearScriptAimPos();
		}
		else if ( streakName == "predator_missile" )
		{
			location = self getKillstreakTargetLocation();
			
			if ( !isdefined( location ) )
			{
				return;
			}
			
			self BotNotifyBotEvent( "killstreak", "call", streakName, location );
			
			self BotRandomStance();
			self setusingremote( "remotemissile" );
			self thread clear_remote_on_death();
			self BotStopMoving( true );
			
			if ( !self changeToWeapon( ksWeap ) )
			{
				self clearusingremote();
				self notify( "bot_clear_remote_on_death" );
				self BotStopMoving( false );
				return;
			}
			
			wait 0.05;
			self thread changeToWeapon( ksWeap ); // prevent script from changing back
			
			wait 1;
			self notify( "bot_clear_remote_on_death" );
			self BotStopMoving( false );
			
			if ( self isemped() )
			{
				self clearusingremote();
				self thread changeToWeapon( curWeap );
				return;
			}
			
			self BotFreezeControls( true );
			
			self maps\mp\killstreaks\_killstreaks::usedkillstreak( "predator_missile", true );
			self maps\mp\killstreaks\_killstreaks::shufflekillstreaksfilo( "predator_missile" );
			self maps\mp\killstreaks\_killstreaks::giveownedkillstreakitem();
			
			rocket = magicbullet( "remotemissile_projectile_mp", self.origin + ( 0.0, 0.0, 7000.0 - ( self.pers[ "bots" ][ "skill" ][ "base" ] * 400 ) ), location, self );
			rocket.lifeid = lifeId;
			rocket.type = "remote";
			
			rocket thread maps\mp\gametypes\_weapons::addmissiletosighttraces( self.pers[ "team" ] );
			rocket thread maps\mp\killstreaks\_remotemissile::handledamage();
			thread maps\mp\killstreaks\_remotemissile::missileeyes( self, rocket );
			
			self waittill( "stopped_using_remote" );
			
			wait 1;
			self BotFreezeControls( false );
		}
		else if ( streakName == "ac130" )
		{
			if ( isdefined( level.ac130player ) || level.ac130inuse )
			{
				return;
			}
			
			self BotNotifyBotEvent( "killstreak", "call", streakName );
			
			self BotRandomStance();
			self BotStopMoving( true );
			self changeToWeapon( ksWeap );
			
			wait 3;
			self BotStopMoving( false );
		}
		else if ( streakName == "helicopter_minigun" )
		{
			if ( isdefined( level.chopper ) )
			{
				return;
			}
			
			self BotNotifyBotEvent( "killstreak", "call", streakName );
			
			self BotRandomStance();
			self BotStopMoving( true );
			self changeToWeapon( ksWeap );
			
			wait 3;
			self BotStopMoving( false );
		}
	}
	else
	{
		if ( streakName == "airdrop_mega" || streakName == "airdrop_sentry_minigun" || streakName == "airdrop" )
		{
			if ( self HasScriptAimPos() )
			{
				return;
			}
			
			if ( streakName != "airdrop_mega" && level.littlebirds > 2 )
			{
				return;
			}
			
			if ( !bullettracepassed( self.origin, self.origin + ( 0, 0, 2048 ), false, self ) && self.pers[ "bots" ][ "skill" ][ "base" ] > 3 )
			{
				return;
			}
			
			myEye = self geteye();
			angles = self getplayerangles();
			
			forwardTrace = bullettrace( myEye, myEye + anglestoforward( angles ) * 256, false, self );
			
			if ( distancesquared( self.origin, forwardTrace[ "position" ] ) < 96 * 96 && self.pers[ "bots" ][ "skill" ][ "base" ] > 3 )
			{
				return;
			}
			
			if ( !bullettracepassed( forwardTrace[ "position" ], forwardTrace[ "position" ] + ( 0, 0, 2048 ), false, self ) && self.pers[ "bots" ][ "skill" ][ "base" ] > 3 )
			{
				return;
			}
			
			self BotNotifyBotEvent( "killstreak", "call", streakName );
			
			self BotStopMoving( true );
			self SetScriptAimPos( forwardTrace[ "position" ] );
			
			if ( !self changeToWeapon( ksWeap ) )
			{
				self BotStopMoving( false );
				self ClearScriptAimPos();
				return;
			}
			
			self thread fire_current_weapon();
			
			ret = self waittill_any_timeout( 5, "grenade_fire" );
			
			self notify( "stop_firing_weapon" );
			
			if ( ret == "timeout" )
			{
				self BotStopMoving( false );
				self ClearScriptAimPos();
				return;
			}
			
			if ( randomint( 100 ) < 80 && !self HasScriptGoal() && !self.bot_lock_goal )
			{
				self waittill_any_timeout( 15, "crate_physics_done", "new_goal" );
			}
			
			self BotStopMoving( false );
			self ClearScriptAimPos();
		}
		else
		{
			if ( streakName == "harrier_airstrike" && level.planes > 1 )
			{
				return;
			}
			
			if ( streakName == "nuke" && isdefined( level.nukeincoming ) )
			{
				return;
			}
			
			if ( streakName == "counter_uav" && self.pers[ "bots" ][ "skill" ][ "base" ] > 3 && ( ( level.teambased && level.activecounteruavs[ self.team ] ) || ( !level.teambased && level.activecounteruavs[ self.guid ] ) ) )
			{
				return;
			}
			
			if ( streakName == "uav" && self.pers[ "bots" ][ "skill" ][ "base" ] > 3 && ( ( level.teambased && ( level.activeuavs[ self.team ] || level.activecounteruavs[ level.otherteam[ self.team ] ] ) ) || ( !level.teambased && ( level.activeuavs[ self.guid ] || self.isradarblocked ) ) ) )
			{
				return;
			}
			
			if ( streakName == "emp" && self.pers[ "bots" ][ "skill" ][ "base" ] > 3 && ( ( level.teambased && level.teamemped[ level.otherteam[ self.team ] ] ) || ( !level.teambased && isdefined( level.empplayer ) ) ) )
			{
				return;
			}
			
			location = undefined;
			directionYaw = undefined;
			
			switch ( streakName )
			{
				case "harrier_airstrike":
				case "stealth_airstrike":
				case "precision_airstrike":
					location = self getKillstreakTargetLocation();
					directionYaw = randomint( 360 );
					
					if ( !isdefined( location ) )
					{
						return;
					}
					
				case "helicopter":
				case "helicopter_flares":
				case "uav":
				case "nuke":
				case "counter_uav":
				case "emp":
					self BotStopMoving( true );
					
					self BotNotifyBotEvent( "killstreak", "call", streakName, location, directionYaw );
					
					if ( self changeToWeapon( ksWeap ) )
					{
						wait 1;
						
						if ( isdefined( location ) )
						{
							self BotFreezeControls( true );
							
							self notify( "confirm_location", location, directionYaw );
							wait 1;
							
							self BotFreezeControls( false );
						}
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
	
	data = spawnstruct();
	data.dofastcontinue = false;
	
	for ( ;; )
	{
		self bot_killstreak_think_loop( data );
	}
}

/*
	Bots do random stance
*/
BotRandomStance()
{
	if ( randomint( 100 ) < 80 )
	{
		self BotSetStance( "prone" );
	}
	else if ( randomint( 100 ) < 60 )
	{
		self BotSetStance( "crouch" );
	}
	else
	{
		self BotSetStance( "stand" );
	}
}

/*
	Bots will use a random equipment
*/
BotUseRandomEquipment()
{
	self endon( "death" );
	self endon( "disconnect" );
	
	nade = undefined;
	
	// in mw2, can only one of these...
	if ( self getammocount( "claymore_mp" ) )
	{
		nade = "claymore_mp";
	}
	
	if ( self getammocount( "flare_mp" ) )
	{
		nade = "flare_mp";
	}
	
	if ( self getammocount( "c4_mp" ) )
	{
		nade = "c4_mp";
	}
	
	if ( !isdefined( nade ) )
	{
		return;
	}
	
	self botThrowGrenade( nade, 0.05 );
}

/*
	Bots will look at a random thing
*/
BotLookAtRandomThing( obj_target )
{
	self endon( "death" );
	self endon( "disconnect" );
	
	if ( self HasScriptAimPos() )
	{
		return;
	}
	
	rand = randomint( 100 );
	
	nearestEnemy = undefined;
	
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[ i ];
		
		if ( !isdefined( player ) || !isdefined( player.team ) )
		{
			continue;
		}
		
		if ( !isalive( player ) )
		{
			continue;
		}
		
		if ( level.teambased && self.team == player.team )
		{
			continue;
		}
		
		if ( !isdefined( nearestEnemy ) || distancesquared( self.origin, player.origin ) < distancesquared( self.origin, nearestEnemy.origin ) )
		{
			nearestEnemy = player;
		}
	}
	
	origin = ( 0, 0, self getplayerviewheight() );
	
	if ( isdefined( nearestEnemy ) && distancesquared( self.origin, nearestEnemy.origin ) < 1024 * 1024 && rand < 40 )
	{
		origin += ( nearestEnemy.origin[ 0 ], nearestEnemy.origin[ 1 ], self.origin[ 2 ] );
	}
	else if ( isdefined( obj_target ) && rand < 50 )
	{
		origin += ( obj_target.origin[ 0 ], obj_target.origin[ 1 ], self.origin[ 2 ] );
	}
	else if ( rand < 85 )
	{
		origin += self.origin + anglestoforward( ( 0, self.angles[ 1 ] - 180, 0 ) ) * 1024;
	}
	else
	{
		origin += self.origin + anglestoforward( ( 0, randomint( 360 ), 0 ) ) * 1024;
	}
	
	self SetScriptAimPos( origin );
	wait 2;
	self ClearScriptAimPos();
}

/*
	Bots will do stuff while waiting for objective
*/
bot_do_random_action_for_objective( obj_target )
{
	self endon( "death" );
	self endon( "disconnect" );
	self notify( "bot_do_random_action_for_objective" );
	self endon( "bot_do_random_action_for_objective" );
	
	if ( !isdefined( self.bot_random_obj_action ) )
	{
		self.bot_random_obj_action = true;
		
		if ( randomint( 100 ) < 80 )
		{
			self thread BotUseRandomEquipment();
		}
		
		if ( randomint( 100 ) < 75 )
		{
			self thread BotLookAtRandomThing( obj_target );
		}
	}
	else
	{
		if ( self getstance() != "prone" && randomint( 100 ) < 15 )
		{
			self BotSetStance( "prone" );
		}
		else if ( randomint( 100 ) < 5 )
		{
			self thread BotLookAtRandomThing( obj_target );
		}
	}
	
	wait 2;
	self.bot_random_obj_action = undefined;
}

/*
	Bots hang around the enemy's flag to spawn kill em
*/
bot_dom_spawn_kill_think_loop()
{
	myTeam = self.pers[ "team" ];
	otherTeam = getotherteam( myTeam );
	myFlagCount = maps\mp\gametypes\dom::getteamflagcount( myTeam );
	
	if ( myFlagCount == level.flags.size )
	{
		return;
	}
	
	otherFlagCount = maps\mp\gametypes\dom::getteamflagcount( otherTeam );
	
	if ( myFlagCount <= otherFlagCount || otherFlagCount != 1 )
	{
		return;
	}
	
	flag = undefined;
	
	for ( i = 0; i < level.flags.size; i++ )
	{
		if ( level.flags[ i ] maps\mp\gametypes\dom::getflagteam() == myTeam )
		{
			continue;
		}
		
		flag = level.flags[ i ];
	}
	
	if ( !isdefined( flag ) )
	{
		return;
	}
	
	if ( distancesquared( self.origin, flag.origin ) < 2048 * 2048 )
	{
		return;
	}
	
	self BotNotifyBotEvent( "dom", "start", "spawnkill", flag );
	
	self SetScriptGoal( flag.origin, 1024 );
	
	self thread bot_dom_watch_flags( myFlagCount, myTeam );
	
	if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
	{
		self ClearScriptGoal();
	}
	
	self BotNotifyBotEvent( "dom", "stop", "spawnkill", flag );
}

/*
	Bots hang around the enemy's flag to spawn kill em
*/
bot_dom_spawn_kill_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	
	if ( level.gametype != "dom" )
	{
		return;
	}
	
	for ( ;; )
	{
		wait( randomintrange( 10, 20 ) );
		
		if ( randomint( 100 ) < 20 )
		{
			continue;
		}
		
		if ( self HasScriptGoal() || self.bot_lock_goal )
		{
			continue;
		}
		
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
		
		if ( maps\mp\gametypes\dom::getteamflagcount( myTeam ) != count )
		{
			break;
		}
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
		if ( level.flags[ i ] maps\mp\gametypes\dom::getflagteam() != myTeam )
		{
			continue;
		}
		
		if ( !level.flags[ i ].useobj.objpoints[ myTeam ].isflashing )
		{
			continue;
		}
		
		if ( !isdefined( flag ) || distancesquared( self.origin, level.flags[ i ].origin ) < distancesquared( self.origin, flag.origin ) )
		{
			flag = level.flags[ i ];
		}
	}
	
	if ( !isdefined( flag ) )
	{
		return;
	}
	
	self BotNotifyBotEvent( "dom", "start", "defend", flag );
	
	self SetScriptGoal( flag.origin, 128 );
	
	self thread bot_dom_watch_for_flashing( flag, myTeam );
	self thread bots_watch_touch_obj( flag );
	
	if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
	{
		self ClearScriptGoal();
	}
	
	self BotNotifyBotEvent( "dom", "stop", "defend", flag );
}

/*
	Bots watches their own flags and protects them when they are under capture
*/
bot_dom_def_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	
	if ( level.gametype != "dom" )
	{
		return;
	}
	
	for ( ;; )
	{
		wait( randomintrange( 1, 3 ) );
		
		if ( randomint( 100 ) < 35 )
		{
			continue;
		}
		
		if ( self HasScriptGoal() || self.bot_lock_goal )
		{
			continue;
		}
		
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
		
		if ( !isdefined( flag ) )
		{
			break;
		}
		
		if ( flag maps\mp\gametypes\dom::getflagteam() != myTeam || !flag.useobj.objpoints[ myTeam ].isflashing )
		{
			break;
		}
	}
	
	self notify( "bad_path" );
}

/*
	Bots capture dom flags
*/
bot_dom_cap_think_loop()
{
	myTeam = self.pers[ "team" ];
	otherTeam = getotherteam( myTeam );
	
	myFlagCount = maps\mp\gametypes\dom::getteamflagcount( myTeam );
	
	if ( myFlagCount == level.flags.size )
	{
		return;
	}
	
	otherFlagCount = maps\mp\gametypes\dom::getteamflagcount( otherTeam );
	
	if ( game[ "teamScores" ][ myTeam ] >= game[ "teamScores" ][ otherTeam ] )
	{
		if ( myFlagCount < otherFlagCount )
		{
			if ( randomint( 100 ) < 15 )
			{
				return;
			}
		}
		else if ( myFlagCount == otherFlagCount )
		{
			if ( randomint( 100 ) < 35 )
			{
				return;
			}
		}
		else if ( myFlagCount > otherFlagCount )
		{
			if ( randomint( 100 ) < 95 )
			{
				return;
			}
		}
	}
	
	flag = undefined;
	flags = [];
	
	for ( i = 0; i < level.flags.size; i++ )
	{
		if ( level.flags[ i ] maps\mp\gametypes\dom::getflagteam() == myTeam )
		{
			continue;
		}
		
		flags[ flags.size ] = level.flags[ i ];
	}
	
	if ( randomint( 100 ) > 30 )
	{
		for ( i = 0; i < flags.size; i++ )
		{
			if ( !isdefined( flag ) || distancesquared( self.origin, level.flags[ i ].origin ) < distancesquared( self.origin, flag.origin ) )
			{
				flag = level.flags[ i ];
			}
		}
	}
	else if ( flags.size )
	{
		flag = random( flags );
	}
	
	if ( !isdefined( flag ) )
	{
		return;
	}
	
	self BotNotifyBotEvent( "dom", "go", "cap", flag );
	
	self.bot_lock_goal = true;
	self SetScriptGoal( flag.origin, 64 );
	
	self thread bot_dom_go_cap_flag( flag, myTeam );
	
	event = self waittill_any_return( "goal", "bad_path", "new_goal" );
	
	if ( event != "new_goal" )
	{
		self ClearScriptGoal();
	}
	
	if ( event != "goal" )
	{
		self.bot_lock_goal = false;
		return;
	}
	
	self BotNotifyBotEvent( "dom", "start", "cap", flag );
	
	self SetScriptGoal( self.origin, 64 );
	
	while ( flag maps\mp\gametypes\dom::getflagteam() != myTeam && self istouching( flag ) )
	{
		cur = flag.useobj.curprogress;
		wait 0.5;
		
		if ( flag.useobj.curprogress == cur )
		{
			break; // some enemy is near us, kill him
		}
		
		self thread bot_do_random_action_for_objective( flag );
	}
	
	self BotNotifyBotEvent( "dom", "stop", "cap", flag );
	
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
	{
		return;
	}
	
	for ( ;; )
	{
		wait( randomintrange( 3, 12 ) );
		
		if ( self.bot_lock_goal )
		{
			continue;
		}
		
		if ( !isdefined( level.flags ) || level.flags.size == 0 )
		{
			continue;
		}
		
		self bot_dom_cap_think_loop();
	}
}

/*
	Bot goes to the flag, watching while they don't have the flag
*/
bot_dom_go_cap_flag( flag, myTeam )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );
	
	for ( ;; )
	{
		wait randomintrange( 2, 4 );
		
		if ( !isdefined( flag ) )
		{
			break;
		}
		
		if ( flag maps\mp\gametypes\dom::getflagteam() == myTeam )
		{
			break;
		}
		
		if ( self istouching( flag ) )
		{
			break;
		}
	}
	
	if ( flag maps\mp\gametypes\dom::getflagteam() == myTeam )
	{
		self notify( "bad_path" );
	}
	else
	{
		self notify( "goal" );
	}
}

/*
	Bots play headquarters
*/
bot_hq_loop()
{
	myTeam = self.pers[ "team" ];
	otherTeam = getotherteam( myTeam );
	
	radio = level.radio;
	gameobj = radio.gameobject;
	origin = ( radio.origin[ 0 ], radio.origin[ 1 ], radio.origin[ 2 ] + 5 );
	
	// if neut or enemy
	if ( gameobj.ownerteam != myTeam )
	{
		if ( gameobj.interactteam == "none" ) // wait for it to become active
		{
			if ( self HasScriptGoal() )
			{
				return;
			}
			
			if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
			{
				return;
			}
			
			self SetScriptGoal( origin, 256 );
			
			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			{
				self ClearScriptGoal();
			}
			
			return;
		}
		
		// capture it
		
		self BotNotifyBotEvent( "hq", "go", "cap" );
		
		self.bot_lock_goal = true;
		self SetScriptGoal( origin, 64 );
		self thread bot_hq_go_cap( gameobj, radio );
		
		event = self waittill_any_return( "goal", "bad_path", "new_goal" );
		
		if ( event != "new_goal" )
		{
			self ClearScriptGoal();
		}
		
		if ( event != "goal" )
		{
			self.bot_lock_goal = false;
			return;
		}
		
		if ( !self istouching( gameobj.trigger ) || level.radio != radio )
		{
			self.bot_lock_goal = false;
			return;
		}
		
		self BotNotifyBotEvent( "hq", "start", "cap" );
		
		self SetScriptGoal( self.origin, 64 );
		
		while ( self istouching( gameobj.trigger ) && gameobj.ownerteam != myTeam && level.radio == radio )
		{
			cur = gameobj.curprogress;
			wait 0.5;
			
			if ( cur == gameobj.curprogress )
			{
				break; // no prog made, enemy must be capping
			}
			
			self thread bot_do_random_action_for_objective( gameobj.trigger );
		}
		
		self ClearScriptGoal();
		self.bot_lock_goal = false;
		
		self BotNotifyBotEvent( "hq", "stop", "cap" );
	}
	else // we own it
	{
		if ( gameobj.objpoints[ myTeam ].isflashing ) // underattack
		{
			self BotNotifyBotEvent( "hq", "start", "defend" );
			
			self.bot_lock_goal = true;
			self SetScriptGoal( origin, 64 );
			self thread bot_hq_watch_flashing( gameobj, radio );
			
			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			{
				self ClearScriptGoal();
			}
			
			self.bot_lock_goal = false;
			
			self BotNotifyBotEvent( "hq", "stop", "defend" );
			return;
		}
		
		if ( self HasScriptGoal() )
		{
			return;
		}
		
		if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
		{
			return;
		}
		
		self SetScriptGoal( origin, 256 );
		
		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearScriptGoal();
		}
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
	{
		return;
	}
	
	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );
		
		if ( self.bot_lock_goal )
		{
			continue;
		}
		
		if ( !isdefined( level.radio ) )
		{
			continue;
		}
		
		if ( !isdefined( level.radio.gameobject ) )
		{
			continue;
		}
		
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
		
		if ( !isdefined( obj ) )
		{
			break;
		}
		
		if ( self istouching( obj.trigger ) )
		{
			break;
		}
		
		if ( level.radio != radio )
		{
			break;
		}
	}
	
	if ( level.radio != radio )
	{
		self notify( "bad_path" );
	}
	else
	{
		self notify( "goal" );
	}
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
	
	myTeam = self.team;
	
	for ( ;; )
	{
		wait 0.5;
		
		if ( !isdefined( obj ) )
		{
			break;
		}
		
		if ( !obj.objpoints[ myTeam ].isflashing )
		{
			break;
		}
		
		if ( level.radio != radio )
		{
			break;
		}
	}
	
	self notify( "bad_path" );
}

/*
	Bots play sab
*/
bot_sab_loop()
{
	myTeam = self.pers[ "team" ];
	otherTeam = getotherteam( myTeam );
	
	bomb = level.sabbomb;
	bombteam = bomb.ownerteam;
	carrier = bomb.carrier;
	timeleft = maps\mp\gametypes\_gamelogic::gettimeremaining() / 1000;
	
	// the bomb is ours, we are on the offence
	if ( bombteam == myTeam )
	{
		site = level.bombzones[ otherTeam ];
		origin = ( site.curorigin[ 0 ] + 50, site.curorigin[ 1 ] + 50, site.curorigin[ 2 ] + 5 );
		
		// protect our planted bomb
		if ( level.bombplanted )
		{
			// kill defuser
			if ( site isInUse() ) // somebody is defusing our bomb we planted
			{
				self BotNotifyBotEvent( "sab", "start", "defuser" );
				
				self.bot_lock_goal = true;
				self SetScriptGoal( origin, 64 );
				
				self thread bot_defend_site( site );
				
				if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
				{
					self ClearScriptGoal();
				}
				
				self.bot_lock_goal = false;
				
				self BotNotifyBotEvent( "sab", "stop", "defuser" );
				return;
			}
			
			// else hang around the site
			if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
			{
				return;
			}
			
			self.bot_lock_goal = true;
			self SetScriptGoal( origin, 256 );
			
			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			{
				self ClearScriptGoal();
			}
			
			self.bot_lock_goal = false;
			return;
		}
		
		// we are not the carrier
		if ( !self isBombCarrier() )
		{
			// lets escort the bomb carrier
			if ( self HasScriptGoal() )
			{
				return;
			}
			
			origin = carrier.origin;
			
			if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
			{
				return;
			}
			
			self SetScriptGoal( origin, 256 );
			self thread bot_escort_obj( bomb, carrier );
			
			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			{
				self ClearScriptGoal();
			}
			
			return;
		}
		
		// we are the carrier of the bomb, lets check if we need to plant
		timepassed = gettimepassed() / 1000;
		
		if ( timepassed < 120 && timeleft >= 90 && randomint( 100 ) < 98 )
		{
			return;
		}
		
		self BotNotifyBotEvent( "sab", "go", "plant" );
		
		self.bot_lock_goal = true;
		self SetScriptGoal( origin, 1 );
		
		self thread bot_go_plant( site );
		event = self waittill_any_return( "goal", "bad_path", "new_goal" );
		
		if ( event != "new_goal" )
		{
			self ClearScriptGoal();
		}
		
		if ( event != "goal" || level.bombplanted || !self istouching( site.trigger ) || site isInUse() || self inLastStand() || self hasThreat() )
		{
			self.bot_lock_goal = false;
			return;
		}
		
		self BotNotifyBotEvent( "sab", "start", "plant" );
		
		self BotRandomStance();
		self SetScriptGoal( self.origin, 64 );
		self bot_wait_stop_move();
		
		waitTime = ( site.usetime / 1000 ) + 2.5;
		self thread BotPressUse( waitTime );
		wait waitTime;
		
		self ClearScriptGoal();
		self.bot_lock_goal = false;
		
		self BotNotifyBotEvent( "sab", "stop", "plant" );
	}
	else if ( bombteam == otherTeam ) // the bomb is theirs, we are on the defense
	{
		site = level.bombzones[ myTeam ];
		
		if ( !isdefined( site.bots ) )
		{
			site.bots = 0;
		}
		
		// protect our site from planters
		if ( !level.bombplanted )
		{
			// kill bomb carrier
			if ( site.bots > 2 || randomint( 100 ) < 45 )
			{
				if ( self HasScriptGoal() )
				{
					return;
				}
				
				if ( carrier _hasperk( "specialty_coldblooded" ) )
				{
					return;
				}
				
				origin = carrier.origin;
				
				self SetScriptGoal( origin, 64 );
				self thread bot_escort_obj( bomb, carrier );
				
				if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
				{
					self ClearScriptGoal();
				}
				
				return;
			}
			
			// protect bomb site
			origin = ( site.curorigin[ 0 ] + 50, site.curorigin[ 1 ] + 50, site.curorigin[ 2 ] + 5 );
			
			self thread bot_inc_bots( site );
			
			if ( site isInUse() ) // somebody is planting
			{
				self BotNotifyBotEvent( "sab", "start", "planter" );
				
				self.bot_lock_goal = true;
				self SetScriptGoal( origin, 64 );
				self thread bot_inc_bots( site );
				
				self thread bot_defend_site( site );
				
				if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
				{
					self ClearScriptGoal();
				}
				
				self.bot_lock_goal = false;
				
				self BotNotifyBotEvent( "sab", "stop", "planter" );
				return;
			}
			
			// else hang around the site
			if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
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
			{
				self ClearScriptGoal();
			}
			
			self.bot_lock_goal = false;
			return;
		}
		
		// bomb is planted we need to defuse
		origin = ( site.curorigin[ 0 ] + 50, site.curorigin[ 1 ] + 50, site.curorigin[ 2 ] + 5 );
		
		// someone else is defusing, lets just hang around
		if ( site.bots > 1 )
		{
			if ( self HasScriptGoal() )
			{
				return;
			}
			
			if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
			{
				return;
			}
			
			self SetScriptGoal( origin, 256 );
			self thread bot_go_defuse( site );
			
			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			{
				self ClearScriptGoal();
			}
			
			return;
		}
		
		// lets go defuse
		self BotNotifyBotEvent( "sab", "go", "defuse" );
		
		self.bot_lock_goal = true;
		
		self SetScriptGoal( origin, 1 );
		self thread bot_inc_bots( site );
		self thread bot_go_defuse( site );
		
		event = self waittill_any_return( "goal", "bad_path", "new_goal" );
		
		if ( event != "new_goal" )
		{
			self ClearScriptGoal();
		}
		
		if ( event != "goal" || !level.bombplanted || site isInUse() || !self istouching( site.trigger ) || self inLastStand() || self hasThreat() )
		{
			self.bot_lock_goal = false;
			return;
		}
		
		self BotNotifyBotEvent( "sab", "start", "defuse" );
		
		self BotRandomStance();
		self SetScriptGoal( self.origin, 64 );
		self bot_wait_stop_move();
		
		waitTime = ( site.usetime / 1000 ) + 2.5;
		self thread BotPressUse( waitTime );
		wait waitTime;
		
		self ClearScriptGoal();
		self.bot_lock_goal = false;
		
		self BotNotifyBotEvent( "sab", "stop", "defuse" );
	}
	else // we need to go get the bomb!
	{
		origin = ( bomb.curorigin[ 0 ], bomb.curorigin[ 1 ], bomb.curorigin[ 2 ] + 5 );
		
		self BotNotifyBotEvent( "sab", "start", "bomb" );
		
		self.bot_lock_goal = true;
		self SetScriptGoal( origin, 64 );
		
		self thread bot_get_obj( bomb );
		
		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearScriptGoal();
		}
		
		self.bot_lock_goal = false;
		
		self BotNotifyBotEvent( "sab", "stop", "bomb" );
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
	{
		return;
	}
	
	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );
		
		if ( self isusingremote() || self.bot_lock_goal )
		{
			continue;
		}
		
		if ( !isdefined( level.sabbomb ) )
		{
			continue;
		}
		
		if ( !isdefined( level.bombzones ) || !level.bombzones.size )
		{
			continue;
		}
		
		if ( self isPlanting() || self isDefusing() )
		{
			continue;
		}
		
		self bot_sab_loop();
	}
}

/*
	Bots play sd defenders
*/
bot_sd_defenders_loop( data )
{
	myTeam = self.pers[ "team" ];
	otherTeam = getotherteam( myTeam );
	
	// bomb not planted, lets protect our sites
	if ( !level.bombplanted )
	{
		timeleft = maps\mp\gametypes\_gamelogic::gettimeremaining() / 1000;
		
		if ( timeleft >= 90 )
		{
			return;
		}
		
		// check for a bomb carrier, and camp the bomb
		if ( !level.multibomb && isdefined( level.sdbomb ) )
		{
			bomb = level.sdbomb;
			carrier = level.sdbomb.carrier;
			
			if ( !isdefined( carrier ) )
			{
				origin = ( bomb.curorigin[ 0 ], bomb.curorigin[ 1 ], bomb.curorigin[ 2 ] + 5 );
				
				// hang around the bomb
				if ( self HasScriptGoal() )
				{
					return;
				}
				
				if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
				{
					return;
				}
				
				self SetScriptGoal( origin, 256 );
				
				self thread bot_get_obj( bomb );
				
				if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
				{
					self ClearScriptGoal();
				}
				
				return;
			}
		}
		
		// pick a site to protect
		if ( !isdefined( level.bombzones ) || !level.bombzones.size )
		{
			return;
		}
		
		sites = [];
		
		for ( i = 0; i < level.bombzones.size; i++ )
		{
			sites[ sites.size ] = level.bombzones[ i ];
		}
		
		if ( !sites.size )
		{
			return;
		}
		
		if ( data.rand > 50 )
		{
			site = self bot_array_nearest_curorigin( sites );
		}
		else
		{
			site = random( sites );
		}
		
		if ( !isdefined( site ) )
		{
			return;
		}
		
		origin = ( site.curorigin[ 0 ] + 50, site.curorigin[ 1 ] + 50, site.curorigin[ 2 ] + 5 );
		
		if ( site isInUse() ) // somebody is planting
		{
			self BotNotifyBotEvent( "sd", "start", "planter", site );
			
			self.bot_lock_goal = true;
			self SetScriptGoal( origin, 64 );
			
			self thread bot_defend_site( site );
			
			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			{
				self ClearScriptGoal();
			}
			
			self.bot_lock_goal = false;
			
			self BotNotifyBotEvent( "sd", "stop", "planter", site );
			return;
		}
		
		// else hang around the site
		if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
		{
			return;
		}
		
		self.bot_lock_goal = true;
		self SetScriptGoal( origin, 256 );
		
		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearScriptGoal();
		}
		
		self.bot_lock_goal = false;
		return;
	}
	
	// bomb is planted, we need to defuse
	if ( !isdefined( level.defuseobject ) )
	{
		return;
	}
	
	defuse = level.defuseobject;
	
	if ( !isdefined( defuse.bots ) )
	{
		defuse.bots = 0;
	}
	
	origin = ( defuse.curorigin[ 0 ], defuse.curorigin[ 1 ], defuse.curorigin[ 2 ] + 5 );
	
	// someone is going to go defuse ,lets just hang around
	if ( defuse.bots > 1 )
	{
		if ( self HasScriptGoal() )
		{
			return;
		}
		
		if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
		{
			return;
		}
		
		self SetScriptGoal( origin, 256 );
		self thread bot_go_defuse( defuse );
		
		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearScriptGoal();
		}
		
		return;
	}
	
	// lets defuse
	self BotNotifyBotEvent( "sd", "go", "defuse" );
	
	self.bot_lock_goal = true;
	self SetScriptGoal( origin, 1 );
	self thread bot_inc_bots( defuse );
	self thread bot_go_defuse( defuse );
	
	event = self waittill_any_return( "goal", "bad_path", "new_goal" );
	
	if ( event != "new_goal" )
	{
		self ClearScriptGoal();
	}
	
	if ( event != "goal" || !level.bombplanted || defuse isInUse() || !self istouching( defuse.trigger ) || self inLastStand() || self hasThreat() )
	{
		self.bot_lock_goal = false;
		return;
	}
	
	self BotNotifyBotEvent( "sd", "start", "defuse" );
	
	self BotRandomStance();
	self SetScriptGoal( self.origin, 64 );
	self bot_wait_stop_move();
	
	waitTime = ( defuse.usetime / 1000 ) + 2.5;
	self thread BotPressUse( waitTime );
	wait waitTime;
	
	self ClearScriptGoal();
	self.bot_lock_goal = false;
	
	self BotNotifyBotEvent( "sd", "stop", "defuse" );
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
	{
		return;
	}
	
	if ( self.team == game[ "attackers" ] )
	{
		return;
	}
	
	data = spawnstruct();
	data.rand = self BotGetRandom();
	
	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );
		
		if ( self isusingremote() || self.bot_lock_goal )
		{
			continue;
		}
		
		if ( self isPlanting() || self isDefusing() )
		{
			continue;
		}
		
		self bot_sd_defenders_loop( data );
	}
}

/*
	Bots play sd attackers
*/
bot_sd_attackers_loop( data )
{
	if ( data.first )
	{
		data.first = false;
	}
	else
	{
		wait( randomintrange( 3, 5 ) );
	}
	
	if ( self isusingremote() || self.bot_lock_goal )
	{
		return;
	}
	
	myTeam = self.pers[ "team" ];
	otherTeam = getotherteam( myTeam );
	
	// bomb planted
	if ( level.bombplanted )
	{
		if ( !isdefined( level.defuseobject ) )
		{
			return;
		}
		
		site = level.defuseobject;
		
		origin = ( site.curorigin[ 0 ], site.curorigin[ 1 ], site.curorigin[ 2 ] + 5 );
		
		if ( site isInUse() ) // somebody is defusing
		{
			self BotNotifyBotEvent( "sd", "start", "defuser" );
			
			self.bot_lock_goal = true;
			
			self SetScriptGoal( origin, 64 );
			
			self thread bot_defend_site( site );
			
			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			{
				self ClearScriptGoal();
			}
			
			self.bot_lock_goal = false;
			
			self BotNotifyBotEvent( "sd", "stop", "defuser" );
			return;
		}
		
		// else hang around the site
		if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
		{
			return;
		}
		
		self.bot_lock_goal = true;
		self SetScriptGoal( origin, 256 );
		
		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearScriptGoal();
		}
		
		self.bot_lock_goal = false;
		return;
	}
	
	timeleft = maps\mp\gametypes\_gamelogic::gettimeremaining() / 1000;
	timepassed = gettimepassed() / 1000;
	
	// dont have a bomb
	if ( !self isBombCarrier() && !level.multibomb )
	{
		if ( !isdefined( level.sdbomb ) )
		{
			return;
		}
		
		bomb = level.sdbomb;
		carrier = level.sdbomb.carrier;
		
		// bomb is picked up
		if ( isdefined( carrier ) )
		{
			// escort the bomb carrier
			if ( self HasScriptGoal() )
			{
				return;
			}
			
			origin = carrier.origin;
			
			if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
			{
				return;
			}
			
			self SetScriptGoal( origin, 256 );
			self thread bot_escort_obj( bomb, carrier );
			
			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			{
				self ClearScriptGoal();
			}
			
			return;
		}
		
		if ( !isdefined( bomb.bots ) )
		{
			bomb.bots = 0;
		}
		
		origin = ( bomb.curorigin[ 0 ], bomb.curorigin[ 1 ], bomb.curorigin[ 2 ] + 5 );
		
		// hang around the bomb if other is going to go get it
		if ( bomb.bots > 1 )
		{
			if ( self HasScriptGoal() )
			{
				return;
			}
			
			if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
			{
				return;
			}
			
			self SetScriptGoal( origin, 256 );
			
			self thread bot_get_obj( bomb );
			
			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			{
				self ClearScriptGoal();
			}
			
			return;
		}
		
		// go get the bomb
		self BotNotifyBotEvent( "sd", "start", "bomb" );
		
		self.bot_lock_goal = true;
		self SetScriptGoal( origin, 64 );
		self thread bot_inc_bots( bomb );
		self thread bot_get_obj( bomb );
		
		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearScriptGoal();
		}
		
		self.bot_lock_goal = false;
		
		self BotNotifyBotEvent( "sd", "stop", "bomb" );
		return;
	}
	
	// check if to plant
	if ( timepassed < 120 && timeleft >= 90 && randomint( 100 ) < 98 )
	{
		return;
	}
	
	if ( !isdefined( level.bombzones ) || !level.bombzones.size )
	{
		return;
	}
	
	sites = [];
	
	for ( i = 0; i < level.bombzones.size; i++ )
	{
		sites[ sites.size ] = level.bombzones[ i ];
	}
	
	if ( !sites.size )
	{
		return;
	}
	
	if ( data.rand > 50 )
	{
		plant = self bot_array_nearest_curorigin( sites );
	}
	else
	{
		plant = random( sites );
	}
	
	if ( !isdefined( plant ) )
	{
		return;
	}
	
	origin = ( plant.curorigin[ 0 ] + 50, plant.curorigin[ 1 ] + 50, plant.curorigin[ 2 ] + 5 );
	
	self BotNotifyBotEvent( "sd", "go", "plant", plant );
	
	self.bot_lock_goal = true;
	self SetScriptGoal( origin, 1 );
	self thread bot_go_plant( plant );
	
	event = self waittill_any_return( "goal", "bad_path", "new_goal" );
	
	if ( event != "new_goal" )
	{
		self ClearScriptGoal();
	}
	
	if ( event != "goal" || level.bombplanted || plant.visibleteam == "none" || !self istouching( plant.trigger ) || self inLastStand() || self hasThreat() || plant isInUse() )
	{
		self.bot_lock_goal = false;
		return;
	}
	
	self BotNotifyBotEvent( "sd", "start", "plant", plant );
	
	self BotRandomStance();
	self SetScriptGoal( self.origin, 64 );
	self bot_wait_stop_move();
	
	waitTime = ( plant.usetime / 1000 ) + 2.5;
	self thread BotPressUse( waitTime );
	wait waitTime;
	
	self ClearScriptGoal();
	self.bot_lock_goal = false;
	
	self BotNotifyBotEvent( "sd", "stop", "plant", plant );
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
	{
		return;
	}
	
	if ( self.team != game[ "attackers" ] )
	{
		return;
	}
	
	data = spawnstruct();
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
	otherTeam = getotherteam( myTeam );
	
	myflag = level.teamflags[ myTeam ];
	myzone = level.capzones[ myTeam ];
	
	theirflag = level.teamflags[ otherTeam ];
	theirzone = level.capzones[ otherTeam ];
	
	if ( !myflag maps\mp\gametypes\_gameobjects::ishome() )
	{
		carrier = myflag.carrier;
		
		if ( !isdefined( carrier ) ) // someone doesnt has our flag
		{
			if ( !isdefined( theirflag.carrier ) && distancesquared( self.origin, theirflag.curorigin ) < distancesquared( self.origin, myflag.curorigin ) ) // no one has their flag and its closer
			{
				self BotNotifyBotEvent( "cap", "start", "their_flag", theirflag );
				
				self bot_cap_get_flag( theirflag );
				
				self BotNotifyBotEvent( "cap", "stop", "their_flag", theirflag );
			}
			else // go get it
			{
				self BotNotifyBotEvent( "cap", "start", "my_flag", myflag );
				
				self bot_cap_get_flag( myflag );
				
				self BotNotifyBotEvent( "cap", "stop", "my_flag", myflag );
			}
			
			return;
		}
		else
		{
			if ( theirflag maps\mp\gametypes\_gameobjects::ishome() && randomint( 100 ) < 50 )
			{
				// take their flag
				self BotNotifyBotEvent( "cap", "start", "their_flag", theirflag );
				
				self bot_cap_get_flag( theirflag );
				
				self BotNotifyBotEvent( "cap", "stop", "their_flag", theirflag );
			}
			else
			{
				if ( self HasScriptGoal() )
				{
					return;
				}
				
				if ( !isdefined( theirzone.bots ) )
				{
					theirzone.bots = 0;
				}
				
				origin = theirzone.curorigin;
				
				if ( theirzone.bots > 2 || randomint( 100 ) < 45 )
				{
					// kill carrier
					if ( carrier _hasperk( "specialty_coldblooded" ) )
					{
						return;
					}
					
					origin = carrier.origin;
					
					self SetScriptGoal( origin, 64 );
					self thread bot_escort_obj( myflag, carrier );
					
					if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
					{
						self ClearScriptGoal();
					}
					
					return;
				}
				
				self thread bot_inc_bots( theirzone );
				
				// camp their zone
				if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
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
				{
					self ClearScriptGoal();
				}
			}
		}
	}
	else // our flag is ok
	{
		if ( self isFlagCarrier() ) // if have flag
		{
			// go cap
			origin = myzone.curorigin;
			
			self BotNotifyBotEvent( "cap", "start", "cap" );
			
			self.bot_lock_goal = true;
			self SetScriptGoal( origin, 32 );
			
			self thread bot_get_obj( myflag );
			evt = self waittill_any_return( "goal", "bad_path", "new_goal" );
			
			wait 1;
			
			if ( evt != "new_goal" )
			{
				self ClearScriptGoal();
			}
			
			self.bot_lock_goal = false;
			
			self BotNotifyBotEvent( "cap", "stop", "cap" );
			return;
		}
		
		carrier = theirflag.carrier;
		
		if ( !isdefined( carrier ) ) // if no one has enemy flag
		{
			self BotNotifyBotEvent( "cap", "start", "their_flag", theirflag );
			
			self bot_cap_get_flag( theirflag );
			
			self BotNotifyBotEvent( "cap", "stop", "their_flag", theirflag );
			return;
		}
		
		// escort them
		
		if ( self HasScriptGoal() )
		{
			return;
		}
		
		origin = carrier.origin;
		
		if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
		{
			return;
		}
		
		self SetScriptGoal( origin, 256 );
		self thread bot_escort_obj( theirflag, carrier );
		
		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearScriptGoal();
		}
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
	{
		return;
	}
	
	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );
		
		if ( self isusingremote() || self.bot_lock_goal )
		{
			continue;
		}
		
		if ( !isdefined( level.capzones ) )
		{
			continue;
		}
		
		if ( !isdefined( level.teamflags ) )
		{
			continue;
		}
		
		self bot_cap_loop();
	}
}

/*
	Gets the carriers ent num
*/
getCarrierEntNum()
{
	carrierNum = -1;
	
	if ( isdefined( self.carrier ) )
	{
		carrierNum = self.carrier getentitynumber();
	}
	
	return carrierNum;
}

/*
	Bots go and get the flag
*/
bot_cap_get_flag( flag )
{
	origin = flag.curorigin;
	
	// go get it
	
	self.bot_lock_goal = true;
	self SetScriptGoal( origin, 32 );
	
	self thread bot_get_obj( flag );
	
	evt = self waittill_any_return( "goal", "bad_path", "new_goal" );
	
	if ( evt != "new_goal" )
	{
		self ClearScriptGoal();
	}
	
	if ( evt != "goal" )
	{
		self.bot_lock_goal = false;
		return;
	}
	
	self SetScriptGoal( self.origin, 64 );
	curCarrier = flag getCarrierEntNum();
	
	while ( curCarrier == flag getCarrierEntNum() && self istouching( flag.trigger ) )
	{
		cur = flag.curprogress;
		wait 0.5;
		
		if ( flag.curprogress == cur )
		{
			break; // some enemy is near us, kill him
		}
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
		
		if ( ( plant.label == "_b" && level.bombbplanted ) || ( plant.label == "_a" && level.bombaplanted ) )
		{
			break;
		}
		
		if ( self istouching( plant.trigger ) )
		{
			break;
		}
	}
	
	if ( ( plant.label == "_b" && level.bombbplanted ) || ( plant.label == "_a" && level.bombaplanted ) )
	{
		self notify( "bad_path" );
	}
	else
	{
		self notify( "goal" );
	}
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
	
	l1 = level.bombaplanted;
	l2 = level.bombbplanted;
	
	for ( ;; )
	{
		wait 0.5;
		
		if ( l1 != level.bombaplanted || l2 != level.bombbplanted )
		{
			break;
		}
	}
	
	self notify( "bad_path" );
}

/*
	Bots play demo attackers
*/
bot_dem_attackers_loop()
{
	myTeam = self.pers[ "team" ];
	otherTeam = getotherteam( myTeam );
	
	bombs = []; // sites with bombs
	sites = []; // sites to bomb at
	bombed = 0; // exploded sites
	
	for ( i = 0; i < level.bombzones.size; i++ )
	{
		bomb = level.bombzones[ i ];
		
		if ( isdefined( bomb.bombexploded ) && bomb.bombexploded )
		{
			bombed++;
			continue;
		}
		
		if ( bomb.label == "_a" )
		{
			if ( level.bombaplanted )
			{
				bombs[ bombs.size ] = bomb;
			}
			else
			{
				sites[ sites.size ] = bomb;
			}
			
			continue;
		}
		
		if ( bomb.label == "_b" )
		{
			if ( level.bombbplanted )
			{
				bombs[ bombs.size ] = bomb;
			}
			else
			{
				sites[ sites.size ] = bomb;
			}
			
			continue;
		}
	}
	
	timeleft = maps\mp\gametypes\_gamelogic::gettimeremaining() / 1000;
	
	shouldLet = ( game[ "teamScores" ][ myTeam ] > game[ "teamScores" ][ otherTeam ] && timeleft < 90 && bombed == 1 );
	
	// spawnkill conditions
	// if we have bombed one site or 1 bomb is planted with lots of time left, spawn kill
	// if we want the other team to win for overtime and they do not need to defuse, spawn kill
	if ( ( ( bombed + bombs.size == 1 && timeleft >= 90 ) || ( shouldLet && !bombs.size ) ) && randomint( 100 ) < 95 )
	{
		if ( self HasScriptGoal() )
		{
			return;
		}
		
		spawnPoints = maps\mp\gametypes\_spawnlogic::getspawnpointarray( "mp_dd_spawn_defender_start" );
		
		if ( !spawnPoints.size )
		{
			return;
		}
		
		spawnpoint = maps\mp\gametypes\_spawnlogic::getspawnpoint_random( spawnPoints );
		
		if ( distancesquared( spawnpoint.origin, self.origin ) <= 2048 * 2048 )
		{
			return;
		}
		
		self SetScriptGoal( spawnpoint.origin, 1024 );
		
		self thread bot_dem_attack_spawnkill();
		
		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearScriptGoal();
		}
		
		return;
	}
	
	// let defuse conditions
	// if enemy is going to lose and lots of time left, let them defuse to play longer
	// or if want to go into overtime near end of the extended game
	if ( ( ( bombs.size + bombed == 2 && timeleft >= 90 ) || ( shouldLet && bombs.size ) ) && randomint( 100 ) < 95 )
	{
		spawnPoints = maps\mp\gametypes\_spawnlogic::getspawnpointarray( "mp_dd_spawn_attacker_start" );
		
		if ( !spawnPoints.size )
		{
			return;
		}
		
		spawnpoint = maps\mp\gametypes\_spawnlogic::getspawnpoint_random( spawnPoints );
		
		if ( distancesquared( spawnpoint.origin, self.origin ) <= 1024 * 1024 )
		{
			return;
		}
		
		self.bot_lock_goal = true;
		self SetScriptGoal( spawnpoint.origin, 512 );
		
		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearScriptGoal();
		}
		
		self.bot_lock_goal = false;
		return;
	}
	
	// defend bomb conditions
	// if time is running out and we have a bomb planted
	if ( bombs.size && timeleft < 90 && ( !sites.size || randomint( 100 ) < 95 ) )
	{
		site = self bot_array_nearest_curorigin( bombs );
		origin = ( site.curorigin[ 0 ] + 50, site.curorigin[ 1 ] + 50, site.curorigin[ 2 ] + 5 );
		
		if ( site isInUse() ) // somebody is defusing
		{
			self BotNotifyBotEvent( "dem", "start", "defuser", site );
			
			self.bot_lock_goal = true;
			self SetScriptGoal( origin, 64 );
			
			self thread bot_defend_site( site );
			
			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			{
				self ClearScriptGoal();
			}
			
			self.bot_lock_goal = false;
			
			self BotNotifyBotEvent( "dem", "stop", "defuser", site );
			return;
		}
		
		// else hang around the site
		if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
		{
			return;
		}
		
		self.bot_lock_goal = true;
		self SetScriptGoal( origin, 256 );
		
		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearScriptGoal();
		}
		
		self.bot_lock_goal = false;
		return;
	}
	
	// else go plant
	if ( !sites.size )
	{
		return;
	}
	
	plant = self bot_array_nearest_curorigin( sites );
	
	if ( !isdefined( plant ) )
	{
		return;
	}
	
	if ( !isdefined( plant.bots ) )
	{
		plant.bots = 0;
	}
	
	origin = ( plant.curorigin[ 0 ] + 50, plant.curorigin[ 1 ] + 50, plant.curorigin[ 2 ] + 5 );
	
	// hang around the site if lots of time left
	if ( plant.bots > 1 && timeleft >= 60 )
	{
		if ( self HasScriptGoal() )
		{
			return;
		}
		
		if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
		{
			return;
		}
		
		self SetScriptGoal( origin, 256 );
		self thread bot_dem_go_plant( plant );
		
		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearScriptGoal();
		}
		
		return;
	}
	
	self BotNotifyBotEvent( "dem", "go", "plant", plant );
	
	self.bot_lock_goal = true;
	
	self SetScriptGoal( origin, 1 );
	self thread bot_inc_bots( plant );
	self thread bot_dem_go_plant( plant );
	
	event = self waittill_any_return( "goal", "bad_path", "new_goal" );
	
	if ( event != "new_goal" )
	{
		self ClearScriptGoal();
	}
	
	if ( event != "goal" || ( plant.label == "_b" && level.bombbplanted ) || ( plant.label == "_a" && level.bombaplanted ) || plant isInUse() || !self istouching( plant.trigger ) || self inLastStand() || self hasThreat() )
	{
		self.bot_lock_goal = false;
		return;
	}
	
	self BotNotifyBotEvent( "dem", "start", "plant", plant );
	
	self BotRandomStance();
	self SetScriptGoal( self.origin, 64 );
	self bot_wait_stop_move();
	
	waitTime = ( plant.usetime / 1000 ) + 2.5;
	self thread BotPressUse( waitTime );
	wait waitTime;
	
	self ClearScriptGoal();
	
	self.bot_lock_goal = false;
	
	self BotNotifyBotEvent( "dem", "stop", "plant", plant );
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
	{
		return;
	}
	
	if ( self.team != game[ "attackers" ] )
	{
		return;
	}
	
	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );
		
		if ( self isusingremote() || self.bot_lock_goal )
		{
			continue;
		}
		
		if ( !isdefined( level.bombzones ) || !level.bombzones.size )
		{
			continue;
		}
		
		self bot_dem_attackers_loop();
	}
}

/*
	Bots play demo defenders
*/
bot_dem_defenders_loop()
{
	myTeam = self.pers[ "team" ];
	otherTeam = getotherteam( myTeam );
	
	bombs = []; // sites with bombs
	sites = []; // sites to bomb at
	bombed = 0; // exploded sites
	
	for ( i = 0; i < level.bombzones.size; i++ )
	{
		bomb = level.bombzones[ i ];
		
		if ( isdefined( bomb.bombexploded ) && bomb.bombexploded )
		{
			bombed++;
			continue;
		}
		
		if ( bomb.label == "_a" )
		{
			if ( level.bombaplanted )
			{
				bombs[ bombs.size ] = bomb;
			}
			else
			{
				sites[ sites.size ] = bomb;
			}
			
			continue;
		}
		
		if ( bomb.label == "_b" )
		{
			if ( level.bombbplanted )
			{
				bombs[ bombs.size ] = bomb;
			}
			else
			{
				sites[ sites.size ] = bomb;
			}
			
			continue;
		}
	}
	
	timeleft = maps\mp\gametypes\_gamelogic::gettimeremaining() / 1000;
	
	shouldLet = ( timeleft < 60 && ( ( bombed == 0 && bombs.size != 2 ) || ( game[ "teamScores" ][ myTeam ] > game[ "teamScores" ][ otherTeam ] && bombed == 1 ) ) && randomint( 100 ) < 98 );
	
	// spawnkill conditions
	// if nothing to defuse with a lot of time left, spawn kill
	// or letting a bomb site to explode but a bomb is planted, so spawnkill
	if ( ( !bombs.size && timeleft >= 60 && randomint( 100 ) < 95 ) || ( shouldLet && bombs.size == 1 ) )
	{
		if ( self HasScriptGoal() )
		{
			return;
		}
		
		spawnPoints = maps\mp\gametypes\_spawnlogic::getspawnpointarray( "mp_dd_spawn_attacker_start" );
		
		if ( !spawnPoints.size )
		{
			return;
		}
		
		spawnpoint = maps\mp\gametypes\_spawnlogic::getspawnpoint_random( spawnPoints );
		
		if ( distancesquared( spawnpoint.origin, self.origin ) <= 2048 * 2048 )
		{
			return;
		}
		
		self SetScriptGoal( spawnpoint.origin, 1024 );
		
		self thread bot_dem_defend_spawnkill();
		
		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearScriptGoal();
		}
		
		return;
	}
	
	// let blow up conditions
	// let enemy blow up at least one to extend play time
	// or if want to go into overtime after extended game
	if ( shouldLet )
	{
		spawnPoints = maps\mp\gametypes\_spawnlogic::getspawnpointarray( "mp_dd_spawn_defender_start" );
		
		if ( !spawnPoints.size )
		{
			return;
		}
		
		spawnpoint = maps\mp\gametypes\_spawnlogic::getspawnpoint_random( spawnPoints );
		
		if ( distancesquared( spawnpoint.origin, self.origin ) <= 1024 * 1024 )
		{
			return;
		}
		
		self.bot_lock_goal = true;
		self SetScriptGoal( spawnpoint.origin, 512 );
		
		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearScriptGoal();
		}
		
		self.bot_lock_goal = false;
		return;
	}
	
	// defend conditions
	// if no bombs planted with little time left
	if ( !bombs.size && timeleft < 60 && randomint( 100 ) < 95 && sites.size )
	{
		site = self bot_array_nearest_curorigin( sites );
		origin = ( site.curorigin[ 0 ] + 50, site.curorigin[ 1 ] + 50, site.curorigin[ 2 ] + 5 );
		
		if ( site isInUse() ) // somebody is planting
		{
			self BotNotifyBotEvent( "dem", "start", "planter", site );
			
			self.bot_lock_goal = true;
			self SetScriptGoal( origin, 64 );
			
			self thread bot_defend_site( site );
			
			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			{
				self ClearScriptGoal();
			}
			
			self.bot_lock_goal = false;
			
			self BotNotifyBotEvent( "dem", "stop", "planter", site );
			return;
		}
		
		// else hang around the site
		
		if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
		{
			return;
		}
		
		self.bot_lock_goal = true;
		self SetScriptGoal( origin, 256 );
		
		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearScriptGoal();
		}
		
		self.bot_lock_goal = false;
		return;
	}
	
	// else go defuse
	
	if ( !bombs.size )
	{
		return;
	}
	
	defuse = self bot_array_nearest_curorigin( bombs );
	
	if ( !isdefined( defuse ) )
	{
		return;
	}
	
	if ( !isdefined( defuse.bots ) )
	{
		defuse.bots = 0;
	}
	
	origin = ( defuse.curorigin[ 0 ] + 50, defuse.curorigin[ 1 ] + 50, defuse.curorigin[ 2 ] + 5 );
	
	// hang around the site if not in danger of losing
	if ( defuse.bots > 1 && bombed + bombs.size != 2 )
	{
		if ( self HasScriptGoal() )
		{
			return;
		}
		
		if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
		{
			return;
		}
		
		self SetScriptGoal( origin, 256 );
		
		self thread bot_dem_go_defuse( defuse );
		
		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearScriptGoal();
		}
		
		return;
	}
	
	self BotNotifyBotEvent( "dem", "go", "defuse", defuse );
	
	self.bot_lock_goal = true;
	
	self SetScriptGoal( origin, 1 );
	self thread bot_inc_bots( defuse );
	self thread bot_dem_go_defuse( defuse );
	
	event = self waittill_any_return( "goal", "bad_path", "new_goal" );
	
	if ( event != "new_goal" )
	{
		self ClearScriptGoal();
	}
	
	if ( event != "goal" || ( defuse.label == "_b" && !level.bombbplanted ) || ( defuse.label == "_a" && !level.bombaplanted ) || defuse isInUse() || !self istouching( defuse.trigger ) || self inLastStand() || self hasThreat() )
	{
		self.bot_lock_goal = false;
		return;
	}
	
	self BotNotifyBotEvent( "dem", "start", "defuse", defuse );
	
	self BotRandomStance();
	self SetScriptGoal( self.origin, 64 );
	self bot_wait_stop_move();
	
	waitTime = ( defuse.usetime / 1000 ) + 2.5;
	self thread BotPressUse( waitTime );
	wait waitTime;
	
	self ClearScriptGoal();
	
	self.bot_lock_goal = false;
	
	self BotNotifyBotEvent( "dem", "stop", "defuse", defuse );
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
	{
		return;
	}
	
	if ( self.team == game[ "attackers" ] )
	{
		return;
	}
	
	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );
		
		if ( self isusingremote() || self.bot_lock_goal )
		{
			continue;
		}
		
		if ( !isdefined( level.bombzones ) || !level.bombzones.size )
		{
			continue;
		}
		
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
		
		if ( self istouching( defuse.trigger ) )
		{
			break;
		}
		
		if ( ( defuse.label == "_b" && !level.bombbplanted ) || ( defuse.label == "_a" && !level.bombaplanted ) )
		{
			break;
		}
	}
	
	if ( ( defuse.label == "_b" && !level.bombbplanted ) || ( defuse.label == "_a" && !level.bombaplanted ) )
	{
		self notify( "bad_path" );
	}
	else
	{
		self notify( "goal" );
	}
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
		
		if ( level.bombbplanted || level.bombaplanted )
		{
			break;
		}
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
		player = level.players[ i ];
		
		if ( player.team != self.team )
		{
			continue;
		}
		
		if ( distancesquared( self.origin, player.origin ) >= 2048 * 2048 )
		{
			continue;
		}
		
		if ( player inLastStand() )
		{
			needsRevives[ needsRevives.size ] = player;
		}
	}
	
	if ( !needsRevives.size )
	{
		return;
	}
	
	revive = random( needsRevives );
	
	self BotNotifyBotEvent( "revive", "go", revive );
	self.bot_lock_goal = true;
	
	self SetScriptGoal( revive.origin, 64 );
	self thread stop_go_target_on_death( revive );
	
	ret = self waittill_any_return( "new_goal", "goal", "bad_path" );
	
	if ( ret != "new_goal" )
	{
		self ClearScriptGoal();
	}
	
	self.bot_lock_goal = false;
	
	if ( ret != "goal" || !isdefined( revive ) || distancesquared( self.origin, revive.origin ) >= 100 * 100 || !revive inLastStand() || revive isBeingRevived() || !isalive( revive ) )
	{
		return;
	}
	
	self BotNotifyBotEvent( "revive", "start", revive );
	
	self BotFreezeControls( true );
	self bot_wait_stop_move();
	
	waitTime = 3.25;
	self thread BotPressUse( waitTime );
	wait waitTime;
	
	self BotFreezeControls( false );
	
	self BotNotifyBotEvent( "revive", "stop", revive );
}

/*
	Bots think to revive
*/
bot_think_revive()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	if ( !level.diehardmode || !level.teambased )
	{
		return;
	}
	
	for ( ;; )
	{
		wait( randomintrange( 1, 3 ) );
		
		if ( self HasScriptGoal() || self.bot_lock_goal )
		{
			continue;
		}
		
		if ( self isDefusing() || self isPlanting() )
		{
			continue;
		}
		
		if ( self isusingremote() || self BotIsFrozen() )
		{
			continue;
		}
		
		if ( self inLastStand() )
		{
			continue;
		}
		
		self bot_think_revive_loop();
	}
}

/*
	Bots play the Global thermonuclear warfare
*/
bot_gtnw_loop()
{
	myTeam = self.team;
	theirteam = getotherteam( myTeam );
	origin = level.nukesite.trigger.origin;
	trigger = level.nukesite.trigger;
	
	ourCapCount = level.nukesite.touchlist[ myTeam ];
	theirCapCount = level.nukesite.touchlist[ theirteam ];
	rand = self BotGetRandom();
	
	if ( ( !ourCapCount && !theirCapCount ) || rand <= 20 )
	{
		// go cap the obj
		self BotNotifyBotEvent( "gtnw", "go", "cap" );
		
		self.bot_lock_goal = true;
		self SetScriptGoal( origin, 64 );
		self thread bots_watch_touch_obj( trigger );
		
		ret = self waittill_any_return( "goal", "bad_path", "new_goal" );
		
		if ( ret != "new_goal" )
		{
			self ClearScriptGoal();
		}
		
		if ( ret != "goal" || !self istouching( trigger ) )
		{
			self.bot_lock_goal = false;
			return;
		}
		
		self BotNotifyBotEvent( "gtnw", "start", "cap" );
		
		self SetScriptGoal( self.origin, 64 );
		
		while ( self istouching( trigger ) )
		{
			cur = level.nukesite.curprogress;
			wait 0.5;
			
			if ( cur == level.nukesite.curprogress )
			{
				break; // no prog made, enemy must be capping
			}
			
			self thread bot_do_random_action_for_objective( trigger );
		}
		
		self ClearScriptGoal();
		self.bot_lock_goal = false;
		
		self BotNotifyBotEvent( "gtnw", "stop", "cap" );
		return;
	}
	
	if ( theirCapCount )
	{
		// kill capturtour
		self.bot_lock_goal = true;
		
		self SetScriptGoal( origin, 64 );
		self thread bots_watch_touch_obj( trigger );
		
		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearScriptGoal();
		}
		
		self.bot_lock_goal = false;
		return;
	}
	
	// else hang around the site
	if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
	{
		return;
	}
	
	self.bot_lock_goal = true;
	self SetScriptGoal( origin, 256 );
	
	if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
	{
		self ClearScriptGoal();
	}
	
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
	{
		return;
	}
	
	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );
		
		if ( self isusingremote() || self.bot_lock_goal )
		{
			continue;
		}
		
		if ( !isdefined( level.nukesite ) || !isdefined( level.nukesite.trigger ) )
		{
			continue;
		}
		
		self bot_gtnw_loop();
	}
}

/*
	Bots play oneflag
*/
bot_oneflag_loop()
{
	myTeam = self.pers[ "team" ];
	otherTeam = getotherteam( myTeam );
	
	if ( myTeam == game[ "attackers" ] )
	{
		myzone = level.capzones[ myTeam ];
		theirflag = level.teamflags[ otherTeam ];
		
		if ( self isFlagCarrier() )
		{
			// go cap
			origin = myzone.curorigin;
			
			self BotNotifyBotEvent( "oneflag", "start", "cap" );
			
			self.bot_lock_goal = true;
			self SetScriptGoal( origin, 32 );
			
			evt = self waittill_any_return( "goal", "bad_path", "new_goal" );
			
			wait 1;
			
			if ( evt != "new_goal" )
			{
				self ClearScriptGoal();
			}
			
			self.bot_lock_goal = false;
			
			self BotNotifyBotEvent( "oneflag", "stop", "cap" );
			return;
		}
		
		carrier = theirflag.carrier;
		
		if ( !isdefined( carrier ) ) // if no one has enemy flag
		{
			self BotNotifyBotEvent( "oneflag", "start", "their_flag" );
			self bot_cap_get_flag( theirflag );
			self BotNotifyBotEvent( "oneflag", "stop", "their_flag" );
			return;
		}
		
		// escort them
		
		if ( self HasScriptGoal() )
		{
			return;
		}
		
		origin = carrier.origin;
		
		if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
		{
			return;
		}
		
		self SetScriptGoal( origin, 256 );
		self thread bot_escort_obj( theirflag, carrier );
		
		if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
		{
			self ClearScriptGoal();
		}
	}
	else
	{
		myflag = level.teamflags[ myTeam ];
		theirzone = level.capzones[ otherTeam ];
		
		if ( !myflag maps\mp\gametypes\_gameobjects::ishome() )
		{
			carrier = myflag.carrier;
			
			if ( !isdefined( carrier ) ) // someone doesnt has our flag
			{
				self BotNotifyBotEvent( "oneflag", "start", "my_flag" );
				self bot_cap_get_flag( myflag );
				self BotNotifyBotEvent( "oneflag", "stop", "my_flag" );
				return;
			}
			
			if ( self HasScriptGoal() )
			{
				return;
			}
			
			if ( !isdefined( theirzone.bots ) )
			{
				theirzone.bots = 0;
			}
			
			origin = theirzone.curorigin;
			
			if ( theirzone.bots > 2 || randomint( 100 ) < 45 )
			{
				// kill carrier
				if ( carrier _hasperk( "specialty_coldblooded" ) )
				{
					return;
				}
				
				origin = carrier.origin;
				
				self SetScriptGoal( origin, 64 );
				self thread bot_escort_obj( myflag, carrier );
				
				if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
				{
					self ClearScriptGoal();
				}
				
				return;
			}
			
			self thread bot_inc_bots( theirzone );
			
			// camp their zone
			if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
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
			{
				self ClearScriptGoal();
			}
		}
		else
		{
			// is home, lets hang around and protect
			if ( self HasScriptGoal() )
			{
				return;
			}
			
			origin = myflag.curorigin;
			
			if ( distancesquared( origin, self.origin ) <= 1024 * 1024 )
			{
				return;
			}
			
			self SetScriptGoal( origin, 256 );
			self thread bot_get_obj( myflag );
			
			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			{
				self ClearScriptGoal();
			}
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
	{
		return;
	}
	
	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );
		
		if ( self isusingremote() || self.bot_lock_goal )
		{
			continue;
		}
		
		if ( !isdefined( level.capzones ) || !isdefined( level.teamflags ) )
		{
			continue;
		}
		
		self bot_oneflag_loop();
	}
}

/*
	Bots play arena
*/
bot_arena_loop()
{
	flag = level.arenaflag;
	myTeam = self.team;
	
	self BotNotifyBotEvent( "arena", "go", "cap" );
	
	self.bot_lock_goal = true;
	self SetScriptGoal( flag.trigger.origin, 64 );
	
	event = self waittill_any_return( "goal", "bad_path", "new_goal" );
	
	if ( event != "new_goal" )
	{
		self ClearScriptGoal();
	}
	
	if ( event != "goal" || !self istouching( flag.trigger ) )
	{
		self.bot_lock_goal = false;
		return;
	}
	
	self BotNotifyBotEvent( "arena", "start", "cap" );
	
	self SetScriptGoal( self.origin, 64 );
	
	while ( self istouching( flag.trigger ) && flag.ownerteam != myTeam )
	{
		cur = flag.curprogress;
		wait 0.5;
		
		if ( cur == flag.curprogress )
		{
			break; // no prog made, enemy must be capping
		}
		
		self thread bot_do_random_action_for_objective( flag.trigger );
	}
	
	self ClearScriptGoal();
	self.bot_lock_goal = false;
	
	self BotNotifyBotEvent( "arena", "stop", "cap" );
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
	{
		return;
	}
	
	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );
		
		if ( self isusingremote() || self.bot_lock_goal )
		{
			continue;
		}
		
		if ( !isdefined( level.arenaflag ) )
		{
			continue;
		}
		
		self bot_arena_loop();
	}
}

/*
	bot_vip_loop

	For those wondering why i call a function for these loops like this
	its because, the variables created in this function will be free'd once the function exits,
	if it was in the infinite loop, the function never exits, thus the variables are never free'd

	This isnt leaking variables, but freeing variables that will no longer be used, an optimization of sorts
*/
bot_vip_loop()
{
	vip = undefined;
	
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[ i ];
		
		if ( !isreallyalive( player ) )
		{
			continue;
		}
		
		if ( isdefined( player.isvip ) && player.isvip )
		{
			vip = player;
		}
	}
	
	if ( self.team == game[ "defenders" ] )
	{
		if ( isdefined( self.isvip ) && self.isvip )
		{
			if ( isdefined( level.extractionzone ) && !isdefined( level.extractiontime ) )
			{
				// go to extraction zone
				self BotNotifyBotEvent( "vip", "start", "cap" );
				
				self.bot_lock_goal = true;
				self SetScriptGoal( level.extractionzone.trigger.origin, 32 );
				
				evt = self waittill_any_return( "goal", "bad_path", "new_goal" );
				
				wait 1;
				
				if ( evt != "new_goal" )
				{
					self ClearScriptGoal();
				}
				
				self.bot_lock_goal = false;
				
				self BotNotifyBotEvent( "vip", "stop", "cap" );
			}
		}
		else if ( isdefined( vip ) )
		{
			// protect the vip
			if ( distancesquared( vip.origin, self.origin ) <= 1024 * 1024 )
			{
				return;
			}
			
			self SetScriptGoal( vip.origin, 256 );
			
			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			{
				self ClearScriptGoal();
			}
		}
	}
	else
	{
		if ( isdefined( level.extractionzone ) && !isdefined( level.extractiontime ) && self BotGetRandom() < 65 )
		{
			// camp the extraction zone
			if ( distancesquared( level.extractionzone.trigger.origin, self.origin ) <= 1024 * 1024 )
			{
				return;
			}
			
			self SetScriptGoal( level.extractionzone.trigger.origin, 256 );
			
			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			{
				self ClearScriptGoal();
			}
		}
		else if ( isdefined( vip ) )
		{
			// kill the vip
			self SetScriptGoal( vip.origin, 32 );
			
			if ( self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal" )
			{
				self ClearScriptGoal();
			}
		}
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
	{
		return;
	}
	
	for ( ;; )
	{
		wait( randomintrange( 3, 5 ) );
		
		if ( self isusingremote() || self.bot_lock_goal )
		{
			continue;
		}
		
		self bot_vip_loop();
	}
}
