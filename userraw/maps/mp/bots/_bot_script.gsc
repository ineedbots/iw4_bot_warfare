#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\bots\_bot_utility;

/*
	When the bot gets added into the game.
*/
added()
{
	self endon("disconnect");

	self setPlayerData("experience", self bot_get_rank());
	self setPlayerData("prestige", 0);
	
	self setPlayerData("cardTitle", random(getCardTitles()));
	self setPlayerData("cardIcon", random(getCardIcons()));

	self setClasses();
	self setKillstreaks();

	self set_diff();
}

/*
	When the bot connects to the game.
*/
connected()
{
	self endon("disconnect");
	
	self thread difficulty();
	self thread teamWatch();
	self thread classWatch();

	self thread onBotSpawned();
	self thread onSpawned();

	self thread onDeath();
	self thread onGiveLoadout();

	self thread onKillcam();
}

/*
	Gets an exp amount for the bot that is nearish the host's xp.
*/
bot_get_rank()
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

	if( !human_ranks.size )
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

	return maps\mp\gametypes\_rank::getRankInfoMinXP( rank );
}

getCardTitles()
{
	cards = [];

	for (i = 0; i < 600; i++)
	{
		card_name = tableLookupByRow( "mp/cardTitleTable.csv", i, 0 );

		if (card_name == "")
			continue;
			
		if (!isSubStr(card_name, "cardtitle_"))
			continue;

		cards[cards.size] = card_name;
	}

	return cards;
}

getCardIcons()
{
	cards = [];

	for (i = 0; i < 300; i++)
	{
		card_name = tableLookupByRow( "mp/cardIconTable.csv", i, 0 );

		if (card_name == "")
			continue;

		if (!isSubStr(card_name, "cardicon_"))
			continue;

		cards[cards.size] = card_name;
	}

	return cards;
}

isValidAttachmentCombo(att1, att2)
{
	colIndex = tableLookupRowNum( "mp/attachmentCombos.csv", 0, att1 );

	if (tableLookup( "mp/attachmentCombos.csv", 0, att2, colIndex ) == "no")
		return false;

	return true;
}

getAttachmentsForGun(gun)
{
	row = tableLookupRowNum( "mp/statStable.csv", 4, gun );

	attachments = [];
	for ( h = 0; h < 10; h++ )
	{
		attachmentName = tableLookupByRow( "mp/statStable.csv", row, h + 11 );
		
		if( attachmentName == "" )
		{
			attachments[attachments.size] = "none";
			break;
		}
		
		attachments[attachments.size] = attachmentName;
	}

	return attachments;
}

getPrimaries()
{
	primaries = [];

	for (i = 0; i < 160; i++)
	{
		weapon_type = tableLookupByRow( "mp/statstable.csv", i, 2 );

		if (weapon_type != "weapon_assault" && weapon_type != "weapon_riot" && weapon_type != "weapon_smg" && weapon_type != "weapon_sniper" && weapon_type != "weapon_lmg")
			continue;

		weapon_name = tableLookupByRow( "mp/statstable.csv", i, 4 );

		primaries[primaries.size] = weapon_name;
	}

	return primaries;
}

getSecondaries()
{
	secondaries = [];

	for (i = 0; i < 160; i++)
	{
		weapon_type = tableLookupByRow( "mp/statstable.csv", i, 2 );

		if (weapon_type != "weapon_pistol" && weapon_type != "weapon_machine_pistol" && weapon_type != "weapon_projectile" && weapon_type != "weapon_shotgun")
			continue;

		weapon_name = tableLookupByRow( "mp/statstable.csv", i, 4 );

		if (weapon_name == "gl")
			continue;

		secondaries[secondaries.size] = weapon_name;
	}

	return secondaries;
}

getCamos()
{
	camos = [];

	for (i = 0; i < 15; i++)
	{
		camo_name = tableLookupByRow( "mp/camoTable.csv", i, 1 );

		if (camo_name == "")
			continue;

		camos[camos.size] = camo_name;
	}

	return camos;
}

getPerks(perktype)
{
	perks = [];
	for (i = 0; i < 50; i++)
	{
		perk_type = tableLookupByRow( "mp/perktable.csv", i, 5 );

		if (perk_type != perktype)
			continue;

		perk_name = tableLookupByRow( "mp/perktable.csv", i, 1 );

		if (perk_name == "specialty_c4death")
			continue;

		if (perk_name == "_specialty_blastshield")
			continue;

		perks[perks.size] = perk_name;
	}

	return perks;
}

getKillsNeededForStreak(streak)
{
	return int(tableLookup("mp/killstreakTable.csv", 1, streak, 4));
}

getKillstreaks()
{
	killstreaks = [];
	for (i = 0; i < 40; i++)
	{
		streak_name = tableLookupByRow( "mp/killstreakTable.csv", i, 1 );

		if(streak_name == "")
			continue;

		if(streak_name == "b1")
			continue;

		if(streak_name == "sentry") // theres an airdrop version
			continue;

		if (isSubstr(streak_name, "KILLSTREAKS_"))
			continue;

		killstreaks[killstreaks.size] = streak_name;
	}
	return killstreaks;
}

chooseRandomPerk(perkkind)
{
	perks = getPerks(perkkind);
	rank = self maps\mp\gametypes\_rank::getRankForXp( self getPlayerData("experience") );

	while (true)
	{
		perk = random(perks);

		if (perk == "specialty_null")
			continue;

		if (!self isItemUnlocked(perk))
			continue;

		if (RandomFloatRange(0, 1) < (rank / level.maxRank))
			self.pers["bots"]["unlocks"]["upgraded_"+perk] = true;

		return perk;
	}
}

chooseRandomCamo()
{
	camos = getCamos();

	while (true)
	{
		camo = random(camos);

		if (camo == "gold" || camo == "prestige")
			continue;

		return camo;
	}
}

chooseRandomPrimary()
{
	primaries = getPrimaries();

	while (true)
	{
		primary = random(primaries);

		if (!self isItemUnlocked(primary))
			continue;

		return primary;
	}
}

chooseRandomSecondary(perk1)
{
	if (perk1 == "specialty_onemanarmy")
		return "onemanarmy";

	secondaries = getSecondaries();

	while (true)
	{
		secondary = random(secondaries);

		if (!self isItemUnlocked(secondary))
			continue;

		if (secondary == "onemanarmy")
			continue;

		return secondary;
	}
}

chooseRandomAttachmentComboForGun(gun)
{
	atts = getAttachmentsForGun(gun);

	while (true)
	{
		att1 = random(atts);
		att2 = random(atts);

		if (!isValidAttachmentCombo(att1, att2))
			continue;

		retAtts = [];
		retAtts[0] = att1;
		retAtts[1] = att2;

		return retAtts;
	}
}

chooseRandomTactical()
{
	tacts = strTok("flash_grenade,smoke_grenade,concussion_grenade", ",");

	while (true)
	{
		tact = random(tacts);

		return tact;
	}
}

setClasses()
{
	rank = self maps\mp\gametypes\_rank::getRankForXp( self getPlayerData("experience") );

	if (RandomFloatRange(0, 1) < (rank / level.maxRank))
		self.pers["bots"]["unlocks"]["ghillie"] = true;

	for (i = 0; i < 5; i++)
	{
		equipment = chooseRandomPerk("equipment");
		perk1 = chooseRandomPerk("perk1");
		perk2 = chooseRandomPerk("perk2");
		perk3 = chooseRandomPerk("perk3");
		deathstreak = chooseRandomPerk("perk4");
		tactical = chooseRandomTactical();
		primary = chooseRandomPrimary();
		primaryAtts = chooseRandomAttachmentComboForGun(primary);
		primaryCamo = chooseRandomCamo();
		secondary = chooseRandomSecondary(perk1);
		secondaryAtts = chooseRandomAttachmentComboForGun(secondary);

		self setPlayerData("customClasses", i, "weaponSetups", 0, "weapon", primary);
		self setPlayerData("customClasses", i, "weaponSetups", 0, "attachment", 0, primaryAtts[0]);
		self setPlayerData("customClasses", i, "weaponSetups", 0, "attachment", 1, primaryAtts[1]);
		self setPlayerData("customClasses", i, "weaponSetups", 0, "camo", primaryCamo);

		self setPlayerData("customClasses", i, "weaponSetups", 1, "weapon", secondary);
		self setPlayerData("customClasses", i, "weaponSetups", 1, "attachment", 0, secondaryAtts[0]);
		self setPlayerData("customClasses", i, "weaponSetups", 1, "attachment", 1, secondaryAtts[1]);

		self setPlayerData("customClasses", i, "perks", 0, equipment);
		self setPlayerData("customClasses", i, "perks", 1, perk1);
		self setPlayerData("customClasses", i, "perks", 2, perk2);
		self setPlayerData("customClasses", i, "perks", 3, perk3);
		self setPlayerData("customClasses", i, "perks", 4, deathstreak);
		self setPlayerData("customClasses", i, "specialGrenade", tactical);
	}
}

isColidingKillstreak(killstreaks, killstreak)
{
	ksVal = getKillsNeededForStreak(killstreak);

	for (i = 0; i < killstreaks.size; i++)
	{
		ks = killstreaks[i];

		if (ks == "")
			continue;

		if (ks == "none")
			continue;

		ksV = getKillsNeededForStreak(ks);

		if (ksV <= 0)
			continue;

		if (ksV != ksVal)
			continue;

		return true;
	}

	return false;
}

setKillstreaks()
{
	rankId = self maps\mp\gametypes\_rank::getRankForXp( self getPlayerData( "experience" ) ) + 1;

	allStreaks = getKillstreaks();

	killstreaks = [];
	killstreaks[0] = "";
	killstreaks[1] = "";
	killstreaks[2] = "";

	chooseableStreaks = 0;
	if (rankId >= 10)
		chooseableStreaks++;
	if (rankId >= 15)
		chooseableStreaks++;
	if (rankId >= 22)
		chooseableStreaks++;

	i = 0;
	while (i < chooseableStreaks)
	{
		slot = randomInt(3);

		if (killstreaks[slot] != "")
			continue;

		streak = random(allStreaks);

		if (isColidingKillstreak(killstreaks, streak))
			continue;

		killstreaks[slot] = streak;
		i++;
	}

	if (killstreaks[0] == "")
		killstreaks[0] = "uav";
	if (killstreaks[1] == "")
		killstreaks[1] = "airdrop";
	if (killstreaks[2] == "")
		killstreaks[2] = "predator_missile";

	self setPlayerData("killstreaks", 0, killstreaks[0]);
	self setPlayerData("killstreaks", 1, killstreaks[1]);
	self setPlayerData("killstreaks", 2, killstreaks[2]);
}

/*
	The callback for when the bot gets killed.
*/
onKilled(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration)
{
	self.killerLocation = undefined;

	if(!IsDefined( self ) || !isDefined(self.team))
		return;

	if ( sMeansOfDeath == "MOD_FALLING" || sMeansOfDeath == "MOD_SUICIDE" )
		return;

	if ( iDamage <= 0 )
		return;
	
	if(!IsDefined( eAttacker ) || !isDefined(eAttacker.team))
		return;
		
	if(eAttacker == self)
		return;
		
	if(level.teamBased && eAttacker.team == self.team)
		return;

	if ( !IsDefined( eInflictor ) || eInflictor.classname != "player" )
		return;
		
	if(!isAlive(eAttacker))
		return;
	
	self.killerLocation = eAttacker.origin;
}

/*
	The callback for when the bot gets damaged.
*/
onDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset)
{
	if(!IsDefined( self ) || !isDefined(self.team))
		return;
		
	if(!isAlive(self))
		return;

	if ( sMeansOfDeath == "MOD_FALLING" || sMeansOfDeath == "MOD_SUICIDE" )
		return;

	if ( iDamage <= 0 )
		return;
	
	if(!IsDefined( eAttacker ) || !isDefined(eAttacker.team))
		return;
		
	if(eAttacker == self)
		return;
		
	if(level.teamBased && eAttacker.team == self.team)
		return;

	if ( !IsDefined( eInflictor ) || eInflictor.classname != "player" )
		return;
		
	if(!isAlive(eAttacker))
		return;
		
	if (!isSubStr(sWeapon, "_silencer_"))
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
		
		if(!isDefined(player.team))
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

onKillcam()
{
	level endon("game_ended");
	self endon("disconnect");
	
	for(;;)
	{
		self waittill("begin_killcam");

		self thread doKillcamStuff();
	}
}

doKillcamStuff()
{
	self endon("disconnect");
	self endon("killcam_ended");

	wait 0.5 + randomInt(3);

	if (randomInt(100) > 25)
		self notify("use_copycat");

	wait 0.1;

	self notify("abort_killcam");
}

/*
	Selects a class for the bot.
*/
classWatch()
{
	self endon("disconnect");

	for(;;)
	{
		while(!isdefined(self.pers["team"]))
			wait .05;
			
		wait 0.5;
		
		class = "";
		rank = self maps\mp\gametypes\_rank::getRankForXp( self getPlayerData( "experience" ) ) + 1;
		if(rank < 4 || randomInt(100) < 2)
		{
			while(class == "")
			{
				switch(randomInt(5))
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
						if(rank >= 2)
							class = "class3";
						break;
					case 4:
						if(rank >= 3)
							class = "class4";
						break;
				}
			}
		}
		else
		{
			class = "custom"+(randomInt(5)+1);
		}
		
		self notify("menuresponse", game["menu_changeclass"], class);
		self.bot_change_class = true;
			
		while(isdefined(self.pers["team"]) && isdefined(self.pers["class"]) && isDefined(self.bot_change_class))
			wait .05;
	}
}

/*
	Makes sure the bot is on a team.
*/
teamWatch()
{
	self endon("disconnect");

	for(;;)
	{
		while(!isdefined(self.pers["team"]))
			wait .05;
			
		wait 0.05;
		self notify("menuresponse", game["menu_team"], getDvar("bots_team"));
			
		while(isdefined(self.pers["team"]))
			wait .05;
	}
}

/*
	Updates the bot's difficulty variables.
*/
difficulty()
{
	self endon("disconnect");

	for(;;)
	{
		wait 1;
		
		rankVar = GetDvarInt("bots_skill");
		
		if(rankVar == 9)
			continue;
			
		switch(self.pers["bots"]["skill"]["base"])
		{
			case 1:
				self.pers["bots"]["skill"]["aim_time"] = 0.6;
				self.pers["bots"]["skill"]["init_react_time"] = 1500;
				self.pers["bots"]["skill"]["reaction_time"] = 1000;
				self.pers["bots"]["skill"]["no_trace_ads_time"] = 500;
				self.pers["bots"]["skill"]["no_trace_look_time"] = 600;
				self.pers["bots"]["skill"]["remember_time"] = 750;
				self.pers["bots"]["skill"]["fov"] = 0.7;
				self.pers["bots"]["skill"]["dist"] = 1000;
				self.pers["bots"]["skill"]["spawn_time"] = 0.75;
				self.pers["bots"]["skill"]["help_dist"] = 0;
				self.pers["bots"]["skill"]["semi_time"] = 0.9;
				self.pers["bots"]["behavior"]["strafe"] = 0;
				self.pers["bots"]["behavior"]["nade"] = 10;
				self.pers["bots"]["behavior"]["sprint"] = 10;
				self.pers["bots"]["behavior"]["camp"] = 5;
				self.pers["bots"]["behavior"]["follow"] = 5;
				self.pers["bots"]["behavior"]["crouch"] = 70;
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
				self.pers["bots"]["skill"]["dist"] = 1500;
				self.pers["bots"]["skill"]["spawn_time"] = 0.65;
				self.pers["bots"]["skill"]["help_dist"] = 500;
				self.pers["bots"]["skill"]["semi_time"] = 0.75;
				self.pers["bots"]["behavior"]["strafe"] = 10;
				self.pers["bots"]["behavior"]["nade"] = 15;
				self.pers["bots"]["behavior"]["sprint"] = 15;
				self.pers["bots"]["behavior"]["camp"] = 5;
				self.pers["bots"]["behavior"]["follow"] = 5;
				self.pers["bots"]["behavior"]["crouch"] = 60;
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
				self.pers["bots"]["skill"]["dist"] = 2250;
				self.pers["bots"]["skill"]["spawn_time"] = 0.5;
				self.pers["bots"]["skill"]["help_dist"] = 750;
				self.pers["bots"]["skill"]["semi_time"] = 0.65;
				self.pers["bots"]["behavior"]["strafe"] = 20;
				self.pers["bots"]["behavior"]["nade"] = 20;
				self.pers["bots"]["behavior"]["sprint"] = 20;
				self.pers["bots"]["behavior"]["camp"] = 5;
				self.pers["bots"]["behavior"]["follow"] = 5;
				self.pers["bots"]["behavior"]["crouch"] = 50;
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
				self.pers["bots"]["skill"]["dist"] = 3350;
				self.pers["bots"]["skill"]["spawn_time"] = 0.35;
				self.pers["bots"]["skill"]["help_dist"] = 1000;
				self.pers["bots"]["skill"]["semi_time"] = 0.5;
				self.pers["bots"]["behavior"]["strafe"] = 30;
				self.pers["bots"]["behavior"]["nade"] = 25;
				self.pers["bots"]["behavior"]["sprint"] = 30;
				self.pers["bots"]["behavior"]["camp"] = 5;
				self.pers["bots"]["behavior"]["follow"] = 5;
				self.pers["bots"]["behavior"]["crouch"] = 40;
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
				self.pers["bots"]["skill"]["dist"] = 5000;
				self.pers["bots"]["skill"]["spawn_time"] = 0.25;
				self.pers["bots"]["skill"]["help_dist"] = 1500;
				self.pers["bots"]["skill"]["semi_time"] = 0.4;
				self.pers["bots"]["behavior"]["strafe"] = 40;
				self.pers["bots"]["behavior"]["nade"] = 35;
				self.pers["bots"]["behavior"]["sprint"] = 40;
				self.pers["bots"]["behavior"]["camp"] = 5;
				self.pers["bots"]["behavior"]["follow"] = 5;
				self.pers["bots"]["behavior"]["crouch"] = 30;
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
				self.pers["bots"]["skill"]["dist"] = 7500;
				self.pers["bots"]["skill"]["spawn_time"] = 0.2;
				self.pers["bots"]["skill"]["help_dist"] = 2000;
				self.pers["bots"]["skill"]["semi_time"] = 0.25;
				self.pers["bots"]["behavior"]["strafe"] = 50;
				self.pers["bots"]["behavior"]["nade"] = 45;
				self.pers["bots"]["behavior"]["sprint"] = 50;
				self.pers["bots"]["behavior"]["camp"] = 5;
				self.pers["bots"]["behavior"]["follow"] = 5;
				self.pers["bots"]["behavior"]["crouch"] = 20;
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
				self.pers["bots"]["skill"]["dist"] = 10000;
				self.pers["bots"]["skill"]["spawn_time"] = 0.05;
				self.pers["bots"]["skill"]["help_dist"] = 3000;
				self.pers["bots"]["skill"]["semi_time"] = 0.1;
				self.pers["bots"]["behavior"]["strafe"] = 65;
				self.pers["bots"]["behavior"]["nade"] = 65;
				self.pers["bots"]["behavior"]["sprint"] = 65;
				self.pers["bots"]["behavior"]["camp"] = 5;
				self.pers["bots"]["behavior"]["follow"] = 5;
				self.pers["bots"]["behavior"]["crouch"] = 5;
				self.pers["bots"]["behavior"]["switch"] = 2;
				self.pers["bots"]["behavior"]["class"] = 2;
				self.pers["bots"]["behavior"]["jump"] = 90;
				break;
		}
	}
}

/*
	Sets the bot difficulty.
*/
set_diff()
{
	rankVar = GetDvarInt("bots_skill");
	
	switch(rankVar)
	{
		case 0:
			self.pers["bots"]["skill"]["base"] = Round( random_normal_distribution( 3.5, 1.75, 1, 7 ) );
			break;
		case 8:
			break;
		case 9:
			self.pers["bots"]["skill"]["base"] = randomIntRange(1, 7);
			self.pers["bots"]["skill"]["aim_time"] = 0.05 * randomIntRange(1, 20);
			self.pers["bots"]["skill"]["init_react_time"] = 50 * randomInt(100);
			self.pers["bots"]["skill"]["reaction_time"] = 50 * randomInt(100);
			self.pers["bots"]["skill"]["remember_time"] = 50 * randomInt(100);
			self.pers["bots"]["skill"]["no_trace_ads_time"] = 50 * randomInt(100);
			self.pers["bots"]["skill"]["no_trace_look_time"] = 50 * randomInt(100);
			self.pers["bots"]["skill"]["fov"] = randomFloatRange(-1, 1);
			self.pers["bots"]["skill"]["dist"] = randomIntRange(500, 25000);
			self.pers["bots"]["skill"]["spawn_time"] = 0.05 * randomInt(20);
			self.pers["bots"]["skill"]["help_dist"] = randomIntRange(500, 25000);
			self.pers["bots"]["skill"]["semi_time"] = randomFloatRange(0.05, 1);
			self.pers["bots"]["behavior"]["strafe"] = randomInt(100);
			self.pers["bots"]["behavior"]["nade"] = randomInt(100);
			self.pers["bots"]["behavior"]["sprint"] = randomInt(100);
			self.pers["bots"]["behavior"]["camp"] = randomInt(100);
			self.pers["bots"]["behavior"]["follow"] = randomInt(100);
			self.pers["bots"]["behavior"]["crouch"] = randomInt(100);
			self.pers["bots"]["behavior"]["switch"] = randomInt(100);
			self.pers["bots"]["behavior"]["class"] = randomInt(100);
			self.pers["bots"]["behavior"]["jump"] = randomInt(100);
			break;
		default:
			self.pers["bots"]["skill"]["base"] = rankVar;
			break;
	}
}

/*
	When the bot spawns.
*/
onSpawned()
{
	self endon("disconnect");
	
	for(;;)
	{
		self waittill("spawned_player");
		
		if(randomInt(100) <= self.pers["bots"]["behavior"]["class"])
			self.bot_change_class = undefined;

		self.bot_lock_goal = false;
		self.help_time = undefined;
	}
}

onDeath()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("death");

		self.wantSafeSpawn = true;
	}
}

onGiveLoadout()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("giveLoadout");

		self botGiveLoadout(self.team, self.class, true);
	}
}

/*
	When the bot spawned, after the difficulty wait. Start the logic for the bot.
*/
onBotSpawned()
{
	self endon("disconnect");
	level endon("game_ended");
	
	for(;;)
	{
		self waittill("bot_spawned");
		gameFlagWait("prematch_done");

		self thread bot_killstreak_think();
	}
}

bot_killstreak_think()
{
	self endon("disconnect");
	self endon("death");
	level endon("game_ended");

	if (randomInt(2))
		self maps\mp\killstreaks\_killstreaks::tryGiveKillstreak("airdrop");
	else if (randomInt(2))
		self maps\mp\killstreaks\_killstreaks::tryGiveKillstreak("airdrop_sentry_minigun");
	else
		self maps\mp\killstreaks\_killstreaks::tryGiveKillstreak("airdrop_mega");

	for (;;)
	{
		wait randomIntRange(1, 3);

		if ( !isDefined( self.pers["killstreaks"][0] ) )
			continue;

		if(self BotIsFrozen())
			continue;
			
		if(self HasThreat())
			continue;
		
		if(self IsBotReloading() || self IsBotFragging() || self IsKnifing())
			continue;
			
		if(self isDefusing() || self isPlanting())
			continue;

		curWeap = self GetCurrentWeapon();
		if (!isWeaponDroppable(curWeap))
			continue;

		if (self isEMPed())
			continue;

		streakName = self.pers["killstreaks"][0].streakName;

		ksWeap = maps\mp\killstreaks\_killstreaks::getKillstreakWeapon( streakName );

		if (maps\mp\killstreaks\_killstreaks::isRideKillstreak(streakName) || maps\mp\killstreaks\_killstreaks::isCarryKillstreak(streakName))
		{
			// sentry
			// predator_missile
			// ac130
			// helicopter_minigun
		}
		else
		{
			if (streakName == "airdrop_mega" || streakName == "airdrop_sentry_minigun" || streakName == "airdrop")
			{
				if (self.bot_lock_goal || self HasScriptGoal())
					continue;

				if (streakName != "airdrop_mega" && level.littleBirds > 2)
					continue;

				if(!bulletTracePassed(self.origin, self.origin+(0,0,2048), false, self) && self.pers["bots"]["skill"]["base"] > 3)
					continue;

				myEye = self GetEye();
				angles = self GetPlayerAngles();

				forwardTrace = bulletTrace(myEye, myEye + AnglesToForward(angles)*256, false, self);

				if (Distance(self.origin, forwardTrace["position"]) < 96)
					continue;

				if (!bulletTracePassed(forwardTrace["position"], forwardTrace["position"]+(0,0,2048), false, self) && self.pers["bots"]["skill"]["base"] > 3)
					continue;

				self SetScriptGoal(self.origin, 16);
				self throwBotGrenade(ksWeap);

				self waittill_any_timeout( 1, "bad_path" );
				self ClearScriptGoal();
			}
			else
			{
				if (streakName == "harrier_airstrike" && level.planes > 1)
					continue;

				if (streakName == "nuke" && isDefined( level.nukeIncoming ))
					continue;

				location = undefined;
				directionYaw = undefined;
				switch (streakName)
				{
					case "harrier_airstrike":
					case "stealth_airstrike":
					case "precision_airstrike":
						players = [];
						for(i = level.players.size - 1; i >= 0; i--)
						{
							player = level.players[i];
						
							if(player == self)
								continue;
							if(!isDefined(player.team))
								continue;
							if(level.teamBased && self.team == player.team)
								continue;
							if(player.sessionstate != "playing")
								continue;
							if(!isReallyAlive(player))
								continue;
							if(player _hasPerk("specialty_coldblooded"))
								continue;
							if(!bulletTracePassed(player.origin, player.origin+(0,0,512), false, player) && self.pers["bots"]["skill"]["base"] > 3)
								continue;
								
							players[players.size] = player;
						}
						
						target = random(players);

						if(isDefined(target))
							location = target.origin + (randomIntRange((8-self.pers["bots"]["skill"]["base"])*-75, (8-self.pers["bots"]["skill"]["base"])*75), randomIntRange((8-self.pers["bots"]["skill"]["base"])*-75, (8-self.pers["bots"]["skill"]["base"])*75), 0);
						else if(self.pers["bots"]["skill"]["base"] <= 3)
							location = self.origin + (randomIntRange(-512, 512), randomIntRange(-512, 512), 0);
						
						directionYaw = randomInt(360);
					case "helicopter":
					case "helicopter_flares":
					case "uav":
					case "nuke":
					case "counter_uav":
					case "emp":
						self BotFreezeControls(true);
						self setSpawnWeapon(ksWeap);
						wait 1;
						if (isDefined(location))
						{
							self notify( "confirm_location", location, directionYaw );
							wait 1;
						}
						self setSpawnWeapon(curWeap);
						self BotFreezeControls(false);
						break;
				}
			}
		}
	}
}
