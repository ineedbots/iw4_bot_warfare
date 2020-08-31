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

		if(streak_name == "" || streak_name == "none")
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
	allowOp = (getDvarInt("bots_loadout_allow_op") >= 1);

	while (true)
	{
		perk = random(perks);

		if (!allowOp)
		{
			if (perkkind == "perk4")
				return "specialty_null";

			if (perk == "specialty_pistoldeath")
				continue;
		}

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
	allowOp = (getDvarInt("bots_loadout_allow_op") >= 1);

	while (true)
	{
		primary = random(primaries);

		if (!allowOp)
		{
			if (primary == "riotshield")
				continue;	
		}

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
	allowOp = (getDvarInt("bots_loadout_allow_op") >= 1);

	while (true)
	{
		secondary = random(secondaries);

		if (!allowOp)
		{
			if (secondary == "at4" || secondary == "rpg" || secondary == "m79")
				continue;
		}

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
	allowOp = (getDvarInt("bots_loadout_allow_op") >= 1);

	while (true)
	{
		att1 = random(atts);
		att2 = random(atts);

		if (!isValidAttachmentCombo(att1, att2))
			continue;

		if (!allowOp)
		{
			if (att1 == "gl" || att2 == "gl")
				continue;
		}

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
		self.bot_oma_class = undefined;
		self.help_time = undefined;

		self thread bot_dom_cap_think();
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

		class = self.class;
		if (isDefined(self.bot_oma_class))
			class = self.bot_oma_class;

		self botGiveLoadout(self.team, class, !isDefined(self.bot_oma_class));
		self.bot_oma_class = undefined;
	}
}

bot_inc_bots(obj, unreach)
{
	level endon("game_ended");
	
	if (!isDefined(obj.bots))
		obj.bots = 0;
	
	obj.bots++;
	
	ret = self waittill_any_return("death", "disconnect", "bad_path", "goal", "new_goal");
	
	if (isDefined(obj) && (ret != "bad_path" || !isDefined(unreach)))
		obj.bots--;
}

bots_watch_touch_obj(obj)
{
	self endon ("death");
	self endon ("disconnect");
	self endon ("bad_path");
	self endon ("goal");
	self endon ("new_goal");

	for (;;)
	{
		wait 0.05;

		if (!isDefined(obj))
		{
			self notify("bad_path");
			return;
		}

		if (self IsTouching(obj))
		{
			self notify("goal");
			return;
		}
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
		self thread bot_target_vehicle();
		self thread bot_weapon_think();
		self thread bot_crate_think();
		self thread bot_turret_think();
		self thread bot_revenge_think();
		self thread bot_uav_think();
		self thread bot_listen_to_steps();
		self thread bot_equipment_kill_think();
		self thread bot_jav_loc_think();
		self thread bot_perk_think();

		self thread bot_dom_def_think();
		self thread bot_dom_spawn_kill_think();
	}
}

bot_perk_think()
{
	self endon("disconnect");
	self endon("death");
	level endon("game_ended");

	for (;;)
	{
		wait randomIntRange(5,7);

		if (self IsUsingRemote())
			continue;

		if(self BotIsFrozen())
			continue;

		if(self isDefusing() || self isPlanting())
			continue;

		for (;self _hasPerk("specialty_blastshield");)
		{
			if (!self _hasPerk("_specialty_blastshield"))
			{
				if (randomInt(100) < 65)
					break;

				self _setPerk("_specialty_blastshield");
			}
			else
			{
				if (randomInt(100) < 90)
					break;

				self _unsetPerk("_specialty_blastshield");
			}

			break;
		}

		for (;self _hasPerk("specialty_onemanarmy") && self hasWeapon("onemanarmy_mp");)
		{
			curWeap = self GetCurrentWeapon();
			if (!isWeaponPrimary(curWeap) || self.disabledWeapon)
				break;

			if (self botIsClimbing())
				break;

			if(self IsBotReloading() || self IsBotFragging() || self IsBotKnifing())
				break;

			if (self HasThreat() || self HasBotJavelinLocation())
				break;

			anyWeapout = false;
			weaponsList = self GetWeaponsListAll();
			for (i = 0; i < weaponsList.size; i++)
			{
				weap = weaponsList[i];

				if (self getAmmoCount(weap) || weap == "onemanarmy_mp")
					continue;

				anyWeapout = true;
			}

			if ((!anyWeapout && randomInt(100) < 90) || randomInt(100) < 10)
				break;

			self BotFreezeControls(true);
			self setSpawnWeapon("onemanarmy_mp");

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
			self.bot_oma_class = class;

			self waittill("weapon_change");
			wait 1;
			self BotFreezeControls(false);

			self notify ( "menuresponse", game["menu_onemanarmy"], self.bot_oma_class );

			self waittill ( "changed_kit" );
			break;
		}
	}
}

bot_jav_loc_think()
{
	self endon("disconnect");
	self endon("death");
	level endon("game_ended");

	for (;;)
	{
		wait randomintRange(2, 4);

		if (randomInt(100) < 20)
			continue;

		if (!self GetAmmoCount("javelin_mp"))
			continue;

		if (self HasThreat() || self HasBotJavelinLocation())
			continue;

		if(self BotIsFrozen())
			continue;
		
		if(self IsBotReloading() || self IsBotFragging() || self IsBotKnifing())
			continue;
			
		if(self isDefusing() || self isPlanting())
			continue;

		curWeap = self GetCurrentWeapon();
		if (!isWeaponPrimary(curWeap) || self.disabledWeapon)
			continue;

		if (self botIsClimbing())
			continue;

		if (self IsUsingRemote())
			continue;

		traceForward = self maps\mp\_javelin::EyeTraceForward();
		if (!isDefined(traceForward))
			continue;

		loc = traceForward[0];
		if (self maps\mp\_javelin::TargetPointTooClose(loc))
			continue;

		if (!bulletTracePassed(self.origin + (0, 0, 5), self.origin + (0, 0, 2048), false, self))
			continue;

		if (!bulletTracePassed(loc + (0, 0, 5), loc + (0, 0, 2048), false, self))
			continue;

		self SetBotJavelinLocation(loc);
		self setSpawnWeapon("javelin_mp");

		wait 0.05;
		if (self GetCurrentWeapon() == "javelin_mp")
			self waittill_any("missile_fire", "weapon_change");
			
		self ClearBotJavelinLocation(loc);
	}
}

bot_equipment_kill_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon ( "game_ended" );

	myteam = self.pers[ "team" ];

	for ( ;; )
	{
		wait( RandomIntRange( 1, 3 ) );
		
		if(self HasScriptEnemy())
			continue;

		if(self.pers["bots"]["skill"]["base"] <= 1)
			continue;

		hasSitrep = self _HasPerk( "specialty_detectexplosive" );
		grenades = getEntArray( "grenade", "classname" );
		myEye = self getEye();
		myAngles = self getPlayerAngles();
		dist = 512*512;
		target = undefined;

		for ( i = 0; i < grenades.size; i++ )
		{
			item = grenades[i];

			if ( !IsDefined( item.name ) )
				continue;

			if ( IsDefined( item.owner ) && ((level.teamBased && item.owner.team == self.team) || item.owner == self) )
				continue;
			
			if (item.name != "c4_mp" && item.name != "claymore_mp")
				continue;
				
			if(!hasSitrep && !bulletTracePassed(myEye, item.origin, false, item))
				continue;
				
			if(getConeDot(item.origin, self.origin, myAngles) < 0.6)
				continue;
			
			if ( DistanceSquared( item.origin, self.origin ) < dist )
			{
				target = item;
				break;
			}
		}
		
		if ( !IsDefined( target ) )
		{
			for ( i = 0; i < level.players.size; i++ )
			{
				player = level.players[i];

				if ( player == self )
					continue;
				
				if(!isDefined(player.team))
					continue;
				
				if ( level.teamBased && player.team == myteam )
					continue;

				ti = player.setSpawnPoint;
				if(!isDefined(ti))
					continue;
				
				if(!isDefined(ti.bots))
					ti.bots = 0;
				
				if(ti.bots >= 2)
					continue;
				
				if(!hasSitrep && !bulletTracePassed(myEye, ti.origin, false, ti))
					continue;
				
				if(getConeDot(ti.origin, self.origin, myAngles) < 0.6)
					continue;

				if ( DistanceSquared( ti.origin, self.origin ) < dist )
				{
					target = ti;
					break;
				}
			}
		}
		
		if ( !IsDefined( target ) )
			continue;

		if (isDefined(target.enemyTrigger))
		{
			if ( self HasScriptGoal() || self.bot_lock_goal )
				continue;

			self SetScriptGoal(target.origin, 16);
			self thread bot_inc_bots(target, true);
			self thread bots_watch_touch_obj( target );
			
			path = self waittill_any_return("bad_path", "goal", "new_goal");

			if (path != "new_goal")
				self ClearScriptGoal();

			if (path != "goal")
				continue;

			target.enemyTrigger notify("trigger", self);
			continue;
		}

		self SetScriptEnemy( target );
		self bot_equipment_attack(target);
		self ClearScriptEnemy();
	}
}

bot_equipment_attack(equ)
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

bot_listen_to_steps()
{
	self endon("disconnect");
	self endon("death");
	
	for(;;)
	{
		wait 1;
		
		if(self HasScriptGoal() || self.bot_lock_goal)
			continue;
			
		if(self.pers["bots"]["skill"]["base"] < 3)
			continue;
			
		dist = level.bots_listenDist;
		if(self hasPerk("specialty_selectivehearing"))
			dist *= 1.4;
		
		dist *= dist;
		
		heard = undefined;
		for(i = level.players.size-1 ; i >= 0; i--)
		{
			player = level.players[i];

			if(player == self)
				continue;
			if(level.teamBased && self.team == player.team)
				continue;
			if(player.sessionstate != "playing")
				continue;
			if(!isReallyAlive(player))
				continue;

			if ( player is_bot() && lengthsquared( player getBotVelocity() ) < 20000 )
				continue;

			if( lengthsquared( player getVelocity() ) < 20000 )
				continue;
			
			if( distanceSquared(player.origin, self.origin) > dist )
				continue;
			
			if( player hasPerk("specialty_quieter"))
				continue;
				
			heard = player;
			break;
		}

		hasHeartbeat = (isSubStr(self GetCurrentWeapon(), "_heartbeat_") && !self IsEMPed());
		heartbeatDist = 350*350;

		if(!IsDefined(heard) && hasHeartbeat)
		{
			for(i = level.players.size-1 ; i >= 0; i--)
			{
				player = level.players[i];

				if(player == self)
					continue;
				if(level.teamBased && self.team == player.team)
					continue;
				if(player.sessionstate != "playing")
					continue;
				if(!isReallyAlive(player))
					continue;

				if (player hasPerk("specialty_heartbreaker"))
					continue;

				if (distanceSquared(player.origin, self.origin) > heartbeatDist)
					continue;

				if (GetConeDot(player.origin, self.origin, self GetPlayerAngles()) < 0.6)
					continue;

				heard = player;
			}
		}
		
		if(!IsDefined(heard))
			continue;
		
		if(bulletTracePassed(self getEye(), heard getTagOrigin( "j_spineupper" ), false, heard))
		{
			self setAttacker(heard);
			continue;
		}
		
		self SetScriptGoal( heard.origin, 64 );

		if (self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal")
			self ClearScriptGoal();
	}
}

bot_uav_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	
	for(;;)
	{
		wait 0.75;
		
		if ( self HasScriptGoal() || self.bot_lock_goal )
			continue;
			
		if(self.pers["bots"]["skill"]["base"] <= 1)
			continue;
			
		if (self isEMPed() || self.bot_isScrambled)
			continue;

		if (self _hasPerk("_specialty_blastshield"))
			continue;

		if ((level.teamBased && level.activeCounterUAVs[level.otherTeam[self.team]]) || (!level.teamBased && self.isRadarBlocked))
			continue;
		
		hasRadar = ((level.teamBased && level.activeUAVs[self.team]) || (!level.teamBased && level.activeUAVs[self.guid]));
		if( level.hardcoreMode && !hasRadar )
			continue;
			
		dist = self.pers["bots"]["skill"]["help_dist"];
		dist *= dist * 8;
		
		for ( i = level.players.size - 1; i >= 0; i-- )
		{
			player = level.players[i];
			
			if(player == self)
				continue;
				
			if(!isDefined(player.team))
				continue;
				
			if(player.sessionstate != "playing")
				continue;
			
			if(level.teambased && player.team == self.team)
				continue;
			
			if(!isReallyAlive(player))
				continue;
			
			if(DistanceSquared(self.origin, player.origin) > dist)
				continue;
			
			if((!isSubStr(player getCurrentWeapon(), "_silencer_") && player.bots_firing) || (hasRadar && !player hasPerk("specialty_coldblooded")))
			{
				self SetScriptGoal( player.origin, 128 );

				if (self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal")
					self ClearScriptGoal();
				break;
			}
		}
	}
}

bot_revenge_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	
	if(self.pers["bots"]["skill"]["base"] <= 1)
		return;
	
	if(!isDefined(self.killerLocation))
		return;
	
	for(;;)
	{
		wait( RandomIntRange( 1, 5 ) );
		
		if(self HasScriptGoal() || self.bot_lock_goal)
			return;
		
		if ( randomint( 100 ) < 75 )
			return;
		
		self SetScriptGoal( self.killerLocation, 64 );

		if (self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal")
			self ClearScriptGoal();
	}
}

turret_death_monitor(turret)
{
	self endon ("death");
	self endon ("disconnect");
	self endon ("bad_path");
	self endon ("goal");
	self endon ("new_goal");

	for (;;)
	{
		wait 0.05;

		if (!isDefined(turret))
			break;

		if (turret.health <= 20000)
			break;

		if (isDefined(turret.carriedBy))
			break;
	}

	self notify("bad_path");
}

bot_turret_attack( enemy )
{
	wait_time = RandomIntRange( 7, 10 );

	for ( i = 0; i < wait_time; i++ )
	{
		wait( 1 );

		if ( !IsDefined( enemy ) )
			return;
		
		if(enemy.health <= 20000)
			return;

		if (isDefined(enemy.carriedBy))
			return;

		//if ( !BulletTracePassed( self getEye(), enemy.origin + ( 0, 0, 15 ), false, enemy ) )
		//	return;
	}
}

bot_turret_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon ( "game_ended" );

	myteam = self.pers[ "team" ];

	for ( ;; )
	{
		wait( 1 );

		turrets = level.turrets;
		turretsKeys = getArrayKeys(turrets);
		if ( turretsKeys.size == 0 )
		{
			wait( randomintrange( 3, 5 ) );
			continue;
		}

		if(self.pers["bots"]["skill"]["base"] <= 1)
			continue;

		if (self HasScriptEnemy() || self IsUsingRemote())
			continue;

		myEye = self GetEye();
		turret = undefined;
		for (i = turretsKeys.size - 1; i >= 0; i--)
		{
			tempTurret = turrets[turretsKeys[i]];

			if(tempTurret.health <= 20000)
				continue;
			if (isDefined(tempTurret.carriedBy))
				continue;
			if(isDefined(tempTurret.owner) && tempTurret.owner == self)
				continue;
			if(tempTurret.team == self.pers["team"] && level.teamBased)
				continue;
			if(!bulletTracePassed(myEye, tempTurret.origin + (0, 0, 15), false, tempTurret))
				continue;

			turret = tempTurret;
		}

		if (!isDefined(turret))
			continue;

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
		if(self hasPerk("specialty_coldblooded"))
			facing = false;

		if ( facing && !BulletTracePassed( myEye, turret.origin + ( 0, 0, 15 ), false, turret ) )
			continue;
		
		if ( !IsDefined( turret.bots ) )
			turret.bots = 0;
		if ( turret.bots >= 2 )
			continue;
		
		if(!facing && !self HasScriptGoal() && !self.bot_lock_goal)
		{
			self SetScriptGoal(turret.origin, 32);
			self thread bot_inc_bots(turret, true);
			self thread turret_death_monitor( turret );
			self thread bots_watch_touch_obj( turret );
			
			if(self waittill_any_return("bad_path", "goal", "new_goal") != "new_goal")
				self ClearScriptGoal();
		}
		
		if(!isDefined(turret))
			continue;

		self SetScriptEnemy( turret, (0, 0, 15) );
		self bot_turret_attack(turret);
		self ClearScriptEnemy();
	}
}

bot_crate_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon("game_ended");
	
	myteam = self.pers[ "team" ];
	
	first = true;
	
	for ( ;; )
	{
		ret = "crate_physics_done";
		if(first)
			first = false;
		else
			ret = self waittill_any_timeout( randomintrange( 3, 5 ), "crate_physics_done" );
		
		if ( RandomInt( 100 ) < 20 && ret != "crate_physics_done" )
			continue;
		
		if ( self HasScriptGoal() || self.bot_lock_goal )
		{
			wait 0.1;//because bot_crate_landed notify causes a same frame ClearScriptGoal
			
			if( self HasScriptGoal() || self.bot_lock_goal )
				continue;
		}

		if(self isDefusing() || self isPlanting())
			continue;

		if(self IsUsingRemote() || self BotIsFrozen())
			continue;
		
		crates = getEntArray( "care_package", "targetname" );
		if ( crates.size == 0 )
			continue;

		wantsClosest = randomint(2);

		crate = undefined;
		for (i = crates.size - 1; i >= 0; i--)
		{
			tempCrate = crates[i];

			if (!isDefined(tempCrate.doingPhysics) || tempCrate.doingPhysics)
				continue;

			if ( !IsDefined( tempCrate.bots ) )
				tempCrate.bots = 0;
			
			if ( tempCrate.bots >= 3 )
				continue;

			if (isDefined(crate))
			{
				if (wantsClosest)
				{
					if (Distance(crate.origin, self.origin) < Distance(tempCrate.origin, self.origin))
						continue;
				}
				else
				{
					if (maps\mp\killstreaks\_killstreaks::getStreakCost(crate.crateType) > maps\mp\killstreaks\_killstreaks::getStreakCost(tempCrate.crateType))
						continue;
				}
			}

			crate = tempCrate;
		}

		if (!isDefined(crate))
			continue;

		self.bot_lock_goal = true;
		self SetScriptGoal(crate.origin, 32);
		self thread bot_inc_bots(crate, true);
		self thread bots_watch_touch_obj(crate);

		path = self waittill_any_return("bad_path", "goal", "new_goal");

		self.bot_lock_goal = false;

		if (path != "new_goal")
			self ClearScriptGoal();

		if (path != "goal")
			continue;

		self _DisableWeapon();
		self BotFreezeControls(true);

		waitTime = 5;
		if (crate.owner == self)
			waitTime = 1.5;
		
		crate waittill_notify_or_timeout("captured", waitTime);

		self _EnableWeapon();
		self BotFreezeControls(false);

		self notify("bot_force_check_switch");

		if (!isDefined(crate))
			continue;

		crate notify ( "captured", self );
	}
}

bot_weapon_think()
{
	self endon("death");
	self endon("disconnect");
	level endon("game_ended");
	
	for(;;)
	{
		self waittill_any_timeout(randomIntRange(2, 4), "bot_force_check_switch");
		
		if(self IsBotReloading() || self IsBotFragging() || self botIsClimbing() || self IsBotKnifing())
			continue;

		if(self BotIsFrozen() || self.disabledWeapon)
			continue;
			
		if(self isDefusing() || self isPlanting())
			continue;

		if (self IsUsingRemote())
			continue;

		curWeap = self GetCurrentWeapon();
		hasTarget = self hasThreat();
		if(hasTarget)
		{
			threat = self getThreat();
			rocketAmmo = self getRocketAmmo();
			
			if(entIsVehicle(threat) && isDefined(rocketAmmo))
			{
				if (curWeap != rocketAmmo)
					self setSpawnWeapon(rocketAmmo);
				continue;
			}
		}

		if (self HasBotJavelinLocation() && self GetAmmoCount("javelin_mp"))
		{
			if (curWeap != "javelin_mp")
				self setSpawnWeapon("javelin_mp");

			continue;
		}

		if (isDefined(self.bot_oma_class))
		{
			if (curWeap != "onemanarmy_mp")
				self setSpawnWeapon("onemanarmy_mp");
			continue;
		}
		
		if(curWeap != "none" && self getAmmoCount(curWeap) && curWeap != "stinger_mp" && curWeap != "javelin_mp" && curWeap != "onemanarmy_mp")
		{
			if(randomInt(100) > self.pers["bots"]["behavior"]["switch"])
				continue;
				
			if(hasTarget)
				continue;
		}
		
		weaponslist = self getweaponslistall();
		weap = "";
		while(weaponslist.size)
		{
			weapon = weaponslist[randomInt(weaponslist.size)];
			weaponslist = array_remove(weaponslist, weapon);
			
			if(!self getAmmoCount(weapon))
				continue;
					
			if (!isWeaponPrimary(weapon))
				continue;
				
			if(curWeap == weapon || weapon == "none" || weapon == "" || weapon == "javelin_mp" || weapon == "stinger_mp" || weapon == "onemanarmy_mp")
				continue;
				
			weap = weapon;
			break;
		}
		
		if(weap == "")
			continue;
		
		self setSpawnWeapon(weap);
	}
}

getRocketAmmo()
{
	answer = self getLockonAmmo();

	if (isDefined(answer))
		return answer;

	if(self getAmmoCount("rpg_mp"))
		answer = "rpg_mp";

	return answer;
}

getLockonAmmo()
{
	answer = undefined;
		
	if(self getAmmoCount("at4_mp"))
		answer = "at4_mp"; 
		
	if(self getAmmoCount("stinger_mp"))
		answer = "stinger_mp";

	if(self getAmmoCount("javelin_mp"))
		answer = "javelin_mp";

	return answer;
}

bot_target_vehicle()
{
	self endon("disconnect");
	self endon("death");

	for (;;)
	{
		wait randomIntRange(2, 4);

		if(self.pers["bots"]["skill"]["base"] <= 1)
			continue;

		if(self HasScriptEnemy())
			continue;

		if (self IsUsingRemote())
			continue;

		rocketAmmo = self getRocketAmmo();
		if(!isDefined(rocketAmmo) && self BotGetRandom() < 90)
			continue;

		targets = maps\mp\_stinger::GetTargetList();

		if (!targets.size)
			continue;

		lockOnAmmo = self getLockonAmmo();
		myEye = self GetEye();
		target = undefined;
		for (i = targets.size - 1; i >= 0; i--)
		{
			tempTarget = targets[i];

			if (isDefined(tempTarget.owner) && tempTarget.owner == self)
				continue;

			if(!bulletTracePassed( myEye, tempTarget.origin, false, tempTarget ))
				continue;

			if (tempTarget.health <= 0)
				continue;

			if (tempTarget.classname != "script_vehicle" && !isDefined(lockOnAmmo))
				continue;

			target = tempTarget;
		}

		if (!isDefined(target))
			continue;

		self SetScriptEnemy( target, (0, 0, 0) );
		self bot_attack_vehicle( target );
		self ClearScriptEnemy();
		self notify("bot_force_check_switch");
	}
}

bot_attack_vehicle( target )
{
	target endon("death");

	wait_time = RandomIntRange( 7, 10 );

	for ( i = 0; i < wait_time; i++ )
	{
		self notify("bot_force_check_switch");
		wait( 1 );

		if ( !IsDefined( target ) )
		{
			return;
		}
	}
}

getKillstreakTargetLocation()
{
	location = undefined;
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
		if(!bulletTracePassed(player.origin, player.origin+(0,0,2048), false, player) && self.pers["bots"]["skill"]["base"] > 3)
			continue;
			
		players[players.size] = player;
	}
	
	target = random(players);

	if(isDefined(target))
		location = target.origin + (randomIntRange((8-self.pers["bots"]["skill"]["base"])*-75, (8-self.pers["bots"]["skill"]["base"])*75), randomIntRange((8-self.pers["bots"]["skill"]["base"])*-75, (8-self.pers["bots"]["skill"]["base"])*75), 0);
	else if(self.pers["bots"]["skill"]["base"] <= 3)
		location = self.origin + (randomIntRange(-512, 512), randomIntRange(-512, 512), 0);

	return location;
}

bot_killstreak_think()
{
	self endon("disconnect");
	self endon("death");
	level endon("game_ended");

	for (;;)
	{
		wait randomIntRange(1, 3);

		if ( !isDefined( self.pers["killstreaks"][0] ) )
			continue;

		if(self BotIsFrozen())
			continue;
			
		if(self HasThreat() || self HasBotJavelinLocation())
			continue;
		
		if(self IsBotReloading() || self IsBotFragging() || self IsBotKnifing())
			continue;
			
		if(self isDefusing() || self isPlanting())
			continue;

		curWeap = self GetCurrentWeapon();
		if (!isWeaponPrimary(curWeap) || self.disabledWeapon)
			continue;

		if (self isEMPed())
			continue;

		if (self botIsClimbing())
			continue;

		if (self IsUsingRemote())
			continue;

		streakName = self.pers["killstreaks"][0].streakName;

		if (level.inGracePeriod && maps\mp\killstreaks\_killstreaks::deadlyKillstreak(streakName))
			continue;

		ksWeap = maps\mp\killstreaks\_killstreaks::getKillstreakWeapon( streakName );

		if (maps\mp\killstreaks\_killstreaks::isRideKillstreak(streakName) || maps\mp\killstreaks\_killstreaks::isCarryKillstreak(streakName))
		{
			if (self inLastStand())
				continue;
				
			if (streakName == "sentry")
			{
				myEye = self GetEye();
				angles = self GetPlayerAngles();

				forwardTrace = bulletTrace(myEye, myEye + AnglesToForward(angles)*1024, false, self);

				if (Distance(self.origin, forwardTrace["position"]) < 1000 && self.pers["bots"]["skill"]["base"] > 3)
					continue;

				self BotFreezeControls(true);
				wait 1;

				sentryGun = maps\mp\killstreaks\_autosentry::createSentryForPlayer( "sentry_minigun", self );
				sentryGun maps\mp\killstreaks\_autosentry::sentry_setPlaced();
				self notify( "sentry_placement_finished", sentryGun );

				self maps\mp\_matchdata::logKillstreakEvent( "sentry", self.origin );

				self maps\mp\killstreaks\_killstreaks::usedKillstreak( "sentry", true );
				self maps\mp\killstreaks\_killstreaks::shuffleKillStreaksFILO( "sentry" );
				self maps\mp\killstreaks\_killstreaks::giveOwnedKillstreakItem();
				wait 1;

				self BotFreezeControls(false);
			}
			else if (streakName == "predator_missile")
			{
				location = self getKillstreakTargetLocation();

				if(!isDefined(location))
					continue;

				self setUsingRemote( "remotemissile" );
				self setSpawnWeapon(ksWeap);
				self BotFreezeControls(true);
				wait 1;
				
				self maps\mp\killstreaks\_killstreaks::usedKillstreak( "predator_missile", true );
				self maps\mp\killstreaks\_killstreaks::shuffleKillStreaksFILO( "predator_missile" );
				self maps\mp\killstreaks\_killstreaks::giveOwnedKillstreakItem();

				rocket = MagicBullet( "remotemissile_projectile_mp", self.origin + (0.0,0.0,7000.0 - (self.pers["bots"]["skill"]["base"] * 400)), location, self );
				rocket.lifeId = self.pers["killstreaks"][0].lifeId;
				rocket.type = "remote";
					
				rocket thread maps\mp\gametypes\_weapons::AddMissileToSightTraces( self.pers["team"] );
				rocket thread maps\mp\killstreaks\_remotemissile::handleDamage();
				thread maps\mp\killstreaks\_remotemissile::MissileEyes( self, rocket );

				self waittill( "stopped_using_remote" );

				wait 1;
				self setSpawnWeapon(curWeap);
				self BotFreezeControls(false);
			}
			else if (streakName == "ac130")
			{
				if ( isDefined( level.ac130player ) || level.ac130InUse )
					continue;

				level.ac130InUse = true;
				self setUsingRemote( "ac130" );
				self setSpawnWeapon(ksWeap);

				self maps\mp\_matchdata::logKillstreakEvent( "ac130", self.origin );
	
				self.ac130LifeId = self.pers["killstreaks"][0].lifeId;
				level.ac130.planeModel.crashed = undefined;

				thread maps\mp\killstreaks\_ac130::setAC130Player( self );

				self maps\mp\killstreaks\_killstreaks::usedKillstreak( "ac130", true );
				self maps\mp\killstreaks\_killstreaks::shuffleKillStreaksFILO( "ac130" );
				self maps\mp\killstreaks\_killstreaks::giveOwnedKillstreakItem();

				self waittill( "stopped_using_remote" );

				wait 1;
				self setSpawnWeapon(curWeap);
			}
			else if (streakName == "helicopter_minigun")
			{
				if (isDefined( level.chopper ))
					continue;

				self setUsingRemote( "helicopter_minigun" );
				self setSpawnWeapon(ksWeap);

				self thread maps\mp\killstreaks\_helicopter::startHelicopter(self.pers["killstreaks"][0].lifeId, "minigun");

				self maps\mp\killstreaks\_killstreaks::usedKillstreak( "helicopter_minigun", true );
				self maps\mp\killstreaks\_killstreaks::shuffleKillStreaksFILO( "helicopter_minigun" );
				self maps\mp\killstreaks\_killstreaks::giveOwnedKillstreakItem();

				self waittill( "stopped_using_remote" );

				wait 1;
				self setSpawnWeapon(curWeap);
			}
		}
		else
		{
			if (streakName == "airdrop_mega" || streakName == "airdrop_sentry_minigun" || streakName == "airdrop")
			{
				if (self HasScriptGoal() || self.bot_lock_goal)
					continue;

				if (streakName != "airdrop_mega" && level.littleBirds > 2)
					continue;

				if(!bulletTracePassed(self.origin, self.origin+(0,0,2048), false, self) && self.pers["bots"]["skill"]["base"] > 3)
					continue;

				myEye = self GetEye();
				angles = self GetPlayerAngles();

				forwardTrace = bulletTrace(myEye, myEye + AnglesToForward(angles)*256, false, self);

				if (Distance(self.origin, forwardTrace["position"]) < 96 && self.pers["bots"]["skill"]["base"] > 3)
					continue;

				if (!bulletTracePassed(forwardTrace["position"], forwardTrace["position"]+(0,0,2048), false, self) && self.pers["bots"]["skill"]["base"] > 3)
					continue;

				self SetScriptGoal(self.origin, 16);
				if (self throwBotGrenade(ksWeap) != "grenade_fire")
				{
					self ClearScriptGoal();
					continue;
				}

				if (self waittill_any_timeout( 15, "new_goal", "crate_physics_done" ) != "new_goal")
					self ClearScriptGoal();
			}
			else
			{
				if (streakName == "harrier_airstrike" && level.planes > 1)
					continue;

				if (streakName == "nuke" && isDefined( level.nukeIncoming ))
					continue;

				if (streakName == "counter_uav" && self.pers["bots"]["skill"]["base"] > 3 && ((level.teamBased && level.activeCounterUAVs[self.team]) || (!level.teamBased && level.activeCounterUAVs[self.guid])))
					continue;

				if (streakName == "uav" && self.pers["bots"]["skill"]["base"] > 3 && ((level.teamBased && (level.activeUAVs[self.team] || level.activeCounterUAVs[level.otherTeam[self.team]])) || (!level.teamBased && (level.activeUAVs[self.guid] || self.isRadarBlocked))))
					continue;

				if (streakName == "emp" && self.pers["bots"]["skill"]["base"] > 3 && ((level.teamBased && level.teamEMPed[level.otherTeam[self.team]]) || (!level.teamBased && isDefined( level.empPlayer ))))
					continue;

				location = undefined;
				directionYaw = undefined;
				switch (streakName)
				{
					case "harrier_airstrike":
					case "stealth_airstrike":
					case "precision_airstrike":
						location = self getKillstreakTargetLocation();
						directionYaw = randomInt(360);

						if (!isDefined(location))
							continue;
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

bot_dom_spawn_kill_think()
{
	self endon( "death" );
	self endon( "disconnect" );

	if ( level.gametype != "dom" )
		return;

	myTeam = self.pers[ "team" ];		
	otherTeam = getOtherTeam( myTeam );

	for ( ;; )
	{
		wait( randomintrange( 10, 20 ) );
		
		if ( randomint( 100 ) < 20 )
			continue;
		
		if ( self HasScriptGoal() || self.bot_lock_goal)
			continue;
		
		myFlagCount = maps\mp\gametypes\dom::getTeamFlagCount( myTeam );

		if ( myFlagCount == level.flags.size )
			continue;

		otherFlagCount = maps\mp\gametypes\dom::getTeamFlagCount( otherTeam );
		
		if (myFlagCount <= otherFlagCount || otherFlagCount != 1)
			continue;
		
		flag = undefined;
		for ( i = 0; i < level.flags.size; i++ )
		{
			if ( level.flags[i] maps\mp\gametypes\dom::getFlagTeam() == myTeam )
				continue;
		}
		
		if(!isDefined(flag))
			continue;
		
		if(DistanceSquared(self.origin, flag.origin) < 2048*2048)
			continue;

		self SetScriptGoal( flag.origin, 1024 );
		
		self thread bot_dom_watch_flags(myFlagCount, myTeam);

		if (self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal")
			self ClearScriptGoal();
	}
}

bot_dom_watch_flags(count, myTeam)
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );

	for (;;)
	{
		wait 0.5;

		if (maps\mp\gametypes\dom::getTeamFlagCount( myTeam ) != count)
			break;
	}
	
	self notify("bad_path");
}

bot_dom_def_think()
{
	self endon( "death" );
	self endon( "disconnect" );

	if ( level.gametype != "dom" )
		return;

	myTeam = self.pers[ "team" ];

	for ( ;; )
	{
		wait( randomintrange( 1, 3 ) );
		
		if ( randomint( 100 ) < 35 )
			continue;
		
		if ( self HasScriptGoal() || self.bot_lock_goal )
			continue;
		
		flag = undefined;
		for ( i = 0; i < level.flags.size; i++ )
		{
			if ( level.flags[i] maps\mp\gametypes\dom::getFlagTeam() != myTeam )
				continue;
			
			if ( !level.flags[i].useObj.objPoints[myTeam].isFlashing )
				continue;
			
			if ( !isDefined(flag) || DistanceSquared(self.origin,level.flags[i].origin) < DistanceSquared(self.origin,flag.origin) )
				flag = level.flags[i];
		}
		
		if ( !isDefined(flag) )
			continue;

		self SetScriptGoal( flag.origin, 128 );
		
		self thread bot_dom_watch_for_flashing(flag, myTeam);
		self thread bots_watch_touch_obj(flag);

		if (self waittill_any_return( "goal", "bad_path", "new_goal" ) != "new_goal")
			self ClearScriptGoal();
	}
}

bot_dom_watch_for_flashing(flag, myTeam)
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );
	
	for (;;)
	{
		wait 0.5;

		if (!isDefined(flag))
			break;

		if (flag maps\mp\gametypes\dom::getFlagTeam() != myTeam || !flag.useObj.objPoints[myTeam].isFlashing)
			break;
	}
	
	self notify("bad_path");
}

bot_dom_cap_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	
	if ( level.gametype != "dom" )
		return;

	myTeam = self.pers[ "team" ];		
	otherTeam = getOtherTeam( myTeam );

	for ( ;; )
	{
		wait( randomintrange( 3, 12 ) );
		
		if ( self.bot_lock_goal )
		{
			continue;
		}

		if ( !isDefined(level.flags) || level.flags.size == 0 )
			continue;

		myFlagCount = maps\mp\gametypes\dom::getTeamFlagCount( myTeam );

		if ( myFlagCount == level.flags.size )
			continue;

		otherFlagCount = maps\mp\gametypes\dom::getTeamFlagCount( otherTeam );

		if ( myFlagCount < otherFlagCount )
		{
			if ( randomint( 100 ) < 15 )
				continue;
		}
		else if ( myFlagCount == otherFlagCount )
		{
			if ( randomint( 100 ) < 35 )
				continue;	
		}
		else if ( myFlagCount > otherFlagCount )
		{
			if ( randomint( 100 ) < 95 )
				continue;
		}

		flag = undefined;
		for ( i = 0; i < level.flags.size; i++ )
		{
			if ( level.flags[i] maps\mp\gametypes\dom::getFlagTeam() == myTeam )
				continue;

			if ( !isDefined(flag) || DistanceSquared(self.origin,level.flags[i].origin) < DistanceSquared(self.origin,flag.origin) )
				flag = level.flags[i];
		}

		if ( !isDefined(flag) )
			continue;
		
		self.bot_lock_goal = true;
		self SetScriptGoal( flag.origin, 64 );
		
		self thread bot_dom_go_cap_flag(flag, myteam);
		self thread bots_watch_touch_obj(flag);
	
		event = self waittill_any_return( "goal", "bad_path", "new_goal" );
		
		if (event != "new_goal")
			self ClearScriptGoal();

		if (event != "goal")
		{
			self.bot_lock_goal = false;
			continue;
		}
		
		self SetScriptGoal( self.origin, 64 );

		while ( flag maps\mp\gametypes\dom::getFlagTeam() != myTeam && self isTouching(flag) )
		{
			cur = flag.useObj.curProgress;
			wait 0.5;
			
			if(flag.useObj.curProgress == cur)
				break;//some enemy is near us, kill him
		}

		self ClearScriptGoal();
		
		self.bot_lock_goal = false;
	}
}

bot_dom_go_cap_flag(flag, myteam)
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "goal" );
	self endon( "bad_path" );
	self endon( "new_goal" );
	
	for (;;)
	{
		wait 0.5;

		if (!isDefined(flag))
			break;

		if (flag maps\mp\gametypes\dom::getFlagTeam() == myTeam)
			break;
	}
	
	self notify("bad_path");
}
