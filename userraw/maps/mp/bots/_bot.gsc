/*
	_bot
	Author: INeedGames
	Date: 09/26/2020
	The entry point and manager of the bots.
*/

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\bots\_bot_utility;

/*
	Initiates the whole bot scripts.
*/
init()
{
	level.bw_VERSION = "2.0.0";

	if(getDvar("bots_main") == "")
		setDvar("bots_main", true);

	if (!getDvarInt("bots_main"))
		return;

	thread load_waypoints();
	thread hook_callbacks();
	
	setDvar("testClients_watchKillcam", true);
	setDvar("testclients_doReload", false);
	setDvar("testclients_doMove", false);
	setDvar("testclients_doAttack", true);
	setDvar("testclients_doCrouch", false);

	if(getDvar("bots_main_GUIDs") == "")
		setDvar("bots_main_GUIDs", "");//guids of players who will be given host powers, comma seperated
		
	if(getDvar("bots_manage_add") == "")
		setDvar("bots_manage_add", 0);//amount of bots to add to the game
	if(getDvar("bots_manage_fill") == "")
		setDvar("bots_manage_fill", 0);//amount of bots to maintain
	if(getDvar("bots_manage_fill_spec") == "")
		setDvar("bots_manage_fill_spec", true);//to count for fill if player is on spec team
	if(getDvar("bots_manage_fill_mode") == "")
		setDvar("bots_manage_fill_mode", 0);//fill mode, 0 adds everyone, 1 just bots, 2 maintains at maps, 3 is 2 with 1
	if(getDvar("bots_manage_fill_kick") == "")
		setDvar("bots_manage_fill_kick", false);//kick bots if too many
	
	if(getDvar("bots_team") == "")
		setDvar("bots_team", "autoassign");//which team for bots to join
	if(getDvar("bots_team_amount") == "")
		setDvar("bots_team_amount", 0);//amount of bots on axis team
	if(getDvar("bots_team_force") == "")
		setDvar("bots_team_force", false);//force bots on team
	if(getDvar("bots_team_mode") == "")
		setDvar("bots_team_mode", 0);//counts just bots when 1
	
	if(getDvar("bots_skill") == "")
		setDvar("bots_skill", 0);//0 is random, 1 is easy 7 is hard, 8 is custom, 9 is completely random
	if(getDvar("bots_skill_axis_hard") == "")
		setDvar("bots_skill_axis_hard", 0);//amount of hard bots on axis team
	if(getDvar("bots_skill_axis_med") == "")
		setDvar("bots_skill_axis_med", 0);
	if(getDvar("bots_skill_allies_hard") == "")
		setDvar("bots_skill_allies_hard", 0);
	if(getDvar("bots_skill_allies_med") == "")
		setDvar("bots_skill_allies_med", 0);
	
	if(getDvar("bots_loadout_reasonable") == "")//filter out the bad 'guns' and perks
		setDvar("bots_loadout_reasonable", false);
	if(getDvar("bots_loadout_allow_op") == "")//allows jug, marty and laststand
		setDvar("bots_loadout_allow_op", true);

	level.defuseObject = undefined;
	level.bots_smokeList = List();
	level.bots_fragList = List();
	
	level.bots_minSprintDistance = 315;
	level.bots_minSprintDistance *= level.bots_minSprintDistance;
	level.bots_minGrenadeDistance = 256;
	level.bots_minGrenadeDistance *= level.bots_minGrenadeDistance;
	level.bots_maxGrenadeDistance = 1024;
	level.bots_maxGrenadeDistance *= level.bots_maxGrenadeDistance;
	level.bots_maxKnifeDistance = 80;
	level.bots_maxKnifeDistance *= level.bots_maxKnifeDistance;
	level.bots_goalDistance = 27.5;
	level.bots_goalDistance *= level.bots_goalDistance;
	level.bots_noADSDistance = 200;
	level.bots_noADSDistance *= level.bots_noADSDistance;
	level.bots_maxShotgunDistance = 500;
	level.bots_maxShotgunDistance *= level.bots_maxShotgunDistance;
	level.bots_listenDist = 100;
	level.bots_listenDist *= level.bots_listenDist;
	level.botPushOutDist = 30;
	
	level.smokeRadius = 255;
	
	level.bots_nonfullautoguns = [];
	level.bots_nonfullautoguns["barrett"] = true;
	level.bots_nonfullautoguns["beretta"] = true;
	level.bots_nonfullautoguns["coltanaconda"] = true;
	level.bots_nonfullautoguns["deserteagle"] = true;
	level.bots_nonfullautoguns["fal"] = true;
	level.bots_nonfullautoguns["m21"] = true;
	level.bots_nonfullautoguns["m1014"] = true;
	level.bots_nonfullautoguns["ranger"] = true;
	level.bots_nonfullautoguns["striker"] = true;
	level.bots_nonfullautoguns["usp"] = true;
	level.bots_nonfullautoguns["wa2000"] = true;
	level.bots_nonfullautoguns["dragunov"] = true;

	level.bots_bloodfx = loadfx("impacts/flesh_hit_body_fatal_exit");
	PrecacheMpAnim("pb_combatrun_forward_loop");
	PrecacheMpAnim("pb_crouch_run_forward");
	PrecacheMpAnim("pb_sprint");

	PrecacheMpAnim("pb_crouch_walk_forward_shield");
	PrecacheMpAnim("pb_crouch_run_forward_pistol");
	PrecacheMpAnim("pb_crouch_run_forward_RPG");
	PrecacheMpAnim("pb_crouch_walk_forward_akimbo");
	
	PrecacheMpAnim("pb_combatrun_forward_shield");
	PrecacheMpAnim("pb_pistol_run_fast");
	PrecacheMpAnim("pb_combatrun_forward_RPG");
	PrecacheMpAnim("pb_combatrun_forward_akimbo");
	
	PrecacheMpAnim("pb_sprint_shield");
	PrecacheMpAnim("pb_sprint_akimbo");
	PrecacheMpAnim("pb_sprint_pistol");
	PrecacheMpAnim("pb_sprint_RPG");

	PrecacheMpAnim("pb_climbup");
	PrecacheMpAnim("pb_prone_crawl");
	PrecacheMpAnim("pb_laststand_crawl");

	PrecacheMpAnim("pb_combatrun_forward_loop");

	PrecacheMpAnim("pt_stand_core_pullout");
	
	PrecacheMpAnim("pt_melee_pistol_1");
	PrecacheMpAnim("pt_melee_prone_pistol");
	PrecacheMpAnim("pt_melee_pistol_2");
	PrecacheMpAnim("pt_laststand_melee");
	PrecacheMpAnim("pt_melee_shield");
	
	level thread fixGamemodes();
	
	level thread onPlayerConnect();
	level thread addNotifyOnAirdrops();
	level thread watchScrabler();
	
	level thread handleBots();
	
	level thread maps\mp\bots\_bot_http::doVersionCheck();
}

/*
	Starts the threads for bots.
*/
handleBots()
{
	level thread teamBots();
	level thread diffBots();
	level addBots();

	while(!level.intermission)
		wait 0.05;

	setDvar("bots_manage_add", getBotArray().size);
}

/*
	The hook callback for when any player becomes damaged.
*/
onPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset)
{
	if(self is_bot())
	{
		self maps\mp\bots\_bot_internal::onDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
		self maps\mp\bots\_bot_script::onDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
	}
	
	self [[level.prevCallbackPlayerDamage]](eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset);
}

/*
	The hook callback when any player gets killed.
*/
onPlayerKilled(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration)
{
	if(self is_bot())
	{
		self maps\mp\bots\_bot_internal::onKilled(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration);
		self maps\mp\bots\_bot_script::onKilled(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration);
	}
	
	self [[level.prevCallbackPlayerKilled]](eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration);
}

/*
	Starts the callbacks.
*/
hook_callbacks()
{
	level waittill( "prematch_over" ); // iw4madmin waits this long for some reason...
	wait 0.05; // so we need to be one frame after it sets up its callbacks.
	level.prevCallbackPlayerDamage = level.callbackPlayerDamage;
	level.callbackPlayerDamage = ::onPlayerDamage;
	
	level.prevCallbackPlayerKilled = level.callbackPlayerKilled;
	level.callbackPlayerKilled = ::onPlayerKilled;
}

/*
	Fixes gamemodes when level starts.
*/
fixGamemodes()
{
	for(i=0;i<19;i++)
	{
		if(isDefined(level.bombZones) && level.gametype == "sd")
		{
			for(i = 0; i < level.bombZones.size; i++)
				level.bombZones[i].onUse = ::onUsePlantObjectFix;
			break;
		}

		if(isDefined(level.radios) && level.gametype == "koth")
		{
			level thread fixKoth();
			
			break;
		}
		
		wait 0.05;
	}
}

/*
	Fixes the king of the hill headquarters obj
*/
fixKoth()
{
	level.radio = undefined;
	
	for(;;)
	{
		wait 0.05;
		
		if(!isDefined(level.radioObject))
		{
			continue;
		}
		
		for(i = level.radios.size - 1; i >= 0; i--)
		{
			if(level.radioObject != level.radios[i].gameobject)
				continue;
				
			level.radio = level.radios[i];
			break;
		}
		
		while(isDefined(level.radioObject) && level.radio.gameobject == level.radioObject)
			wait 0.05;
	}
}

/*
	Adds a notify when the airdrop is dropped
*/
addNotifyOnAirdrops()
{
	for (;;)
	{
		wait 1;
		dropCrates = getEntArray( "care_package", "targetname" );

		for (i = dropCrates.size - 1; i >= 0; i--)
		{
			airdrop = dropCrates[i];

			if (!isDefined(airdrop.owner))
				continue;

			if (isDefined(airdrop.doingPhysics))
				continue;

			airdrop.doingPhysics = true;
			airdrop thread doNotifyOnAirdrop();
		}
	}
}

/*
	Does the notify
*/
doNotifyOnAirdrop()
{
	self endon( "death" );
	self waittill( "physics_finished" );

	self.doingPhysics = false;
	self.owner notify("crate_physics_done");
}

/*
	Thread when any player connects. Starts the threads needed.
*/
onPlayerConnect()
{
	for(;;)
	{
		level waittill("connected", player);
		
		player thread onGrenadeFire();
		player thread onWeaponFired();
		
		player thread connected();
	}
}

/*
	Watches players with scrambler perk
*/
watchScrabler()
{
	for (;;)
	{
		wait 1;

		for ( i = level.players.size - 1; i >= 0; i-- )
		{
			player = level.players[i];

			player.bot_isScrambled = false;

			if (!player _HasPerk("specialty_localjammer") || !isReallyAlive(player))
				continue;

			if (player isEMPed())
				continue;

			for ( h = level.players.size - 1; h >= 0; h-- )
			{
				player2 = level.players[h];

				if (player2 == player)
					continue;

				if(level.teamBased && player2.team == player.team)
					continue;

				if (Distance(player2.origin, player.origin) > 100)
					continue;

				player.bot_isScrambled = true;
			}
		}
	}
}

/*
	Called when a player connects.
*/
connected()
{
	self endon("disconnect");

	if (!isDefined(self.pers["bot_host"]))
		self thread doHostCheck();

	if(!self is_bot())
		return;

	if (!isDefined(self.pers["isBot"]))
	{
		// fast_restart occured...
		self.pers["isBot"] = true;
	}
		
	if (!isDefined(self.pers["isBotWarfare"]))
	{
		self.pers["isBotWarfare"] = true;
		self thread added();
	}
	
	self thread maps\mp\bots\_bot_internal::connected();
	self thread maps\mp\bots\_bot_script::connected();

	level notify("bot_connected", self);
}

/*
	When a bot gets added into the game.
*/
added()
{
	self endon("disconnect");
	
	self thread maps\mp\bots\_bot_internal::added();
	self thread maps\mp\bots\_bot_script::added();
}

/*
	Adds a bot to the game.
*/
add_bot()
{
	bot = addtestclient();

	if (isdefined(bot))
	{
		bot.pers["isBot"] = true;
		bot.pers["isBotWarfare"] = true;
		bot thread added();
	}
}

/*
	A server thread for monitoring all bot's difficulty levels for custom server settings.
*/
diffBots()
{
	for(;;)
	{
		wait 1.5;
		
		var_allies_hard = getDVarInt("bots_skill_allies_hard");
		var_allies_med = getDVarInt("bots_skill_allies_med");
		var_axis_hard = getDVarInt("bots_skill_axis_hard");
		var_axis_med = getDVarInt("bots_skill_axis_med");
		var_skill = getDvarInt("bots_skill");
		
		allies_hard = 0;
		allies_med = 0;
		axis_hard = 0;
		axis_med = 0;
		
		if(var_skill == 8)
		{
			playercount = level.players.size;
			for(i = 0; i < playercount; i++)
			{
				player = level.players[i];
				
				if(!isDefined(player.pers["team"]))
					continue;
				
				if(!player is_bot())
					continue;
					
				if(player.pers["team"] == "axis")
				{
					if(axis_hard < var_axis_hard)
					{
						axis_hard++;
						player.pers["bots"]["skill"]["base"] = 7;
					}
					else if(axis_med < var_axis_med)
					{
						axis_med++;
						player.pers["bots"]["skill"]["base"] = 4;
					}
					else
						player.pers["bots"]["skill"]["base"] = 1;
				}
				else if(player.pers["team"] == "allies")
				{
					if(allies_hard < var_allies_hard)
					{
						allies_hard++;
						player.pers["bots"]["skill"]["base"] = 7;
					}
					else if(allies_med < var_allies_med)
					{
						allies_med++;
						player.pers["bots"]["skill"]["base"] = 4;
					}
					else
						player.pers["bots"]["skill"]["base"] = 1;
				}
			}
		}
		else if (var_skill != 0 && var_skill != 9) 
		{
			playercount = level.players.size;
			for(i = 0; i < playercount; i++)
			{
				player = level.players[i];
				
				if(!player is_bot())
					continue;
					
				player.pers["bots"]["skill"]["base"] = var_skill;
			}
		}
	}
}

/*
	A server thread for monitoring all bot's teams for custom server settings.
*/
teamBots()
{
	for(;;)
	{
		wait 1.5;
		teamAmount = getDvarInt("bots_team_amount");
		toTeam = getDvar("bots_team");
		
		alliesbots = 0;
		alliesplayers = 0;
		axisbots = 0;
		axisplayers = 0;
		
		playercount = level.players.size;
		for(i = 0; i < playercount; i++)
		{
			player = level.players[i];
			
			if(!isDefined(player.pers["team"]))
				continue;
			
			if(player is_bot())
			{
				if(player.pers["team"] == "allies")
					alliesbots++;
				else if(player.pers["team"] == "axis")
					axisbots++;
			}
			else
			{
				if(player.pers["team"] == "allies")
					alliesplayers++;
				else if(player.pers["team"] == "axis")
					axisplayers++;
			}
		}
		
		allies = alliesbots;
		axis = axisbots;
		
		if(!getDvarInt("bots_team_mode"))
		{
			allies += alliesplayers;
			axis += axisplayers;
		}
		
		if(toTeam != "custom")
		{
			if(getDvarInt("bots_team_force"))
			{
				if(toTeam == "autoassign")
				{
					if(abs(axis - allies) > 1)
					{
						toTeam = "axis";
						if(axis > allies)
							toTeam = "allies";
					}
				}
				
				if(toTeam != "autoassign")
				{
					playercount = level.players.size;
					for(i = 0; i < playercount; i++)
					{
						player = level.players[i];
						
						if(!isDefined(player.pers["team"]))
							continue;
						
						if(!player is_bot())
							continue;
							
						if(player.pers["team"] == toTeam)
							continue;
							
						player notify("menuresponse", game["menu_team"], toTeam);
						break;
					}
				}
			}
		}
		else
		{
			playercount = level.players.size;
			for(i = 0; i < playercount; i++)
			{
				player = level.players[i];
				
				if(!isDefined(player.pers["team"]))
					continue;
				
				if(!player is_bot())
					continue;
					
				if(player.pers["team"] == "axis")
				{
					if(axis > teamAmount)
					{
						player notify("menuresponse", game["menu_team"], "allies");
						break;
					}
				}
				else
				{
					if(axis < teamAmount)
					{
						player notify("menuresponse", game["menu_team"], "axis");
						break;
					}
					else if(player.pers["team"] != "allies")
					{
						player notify("menuresponse", game["menu_team"], "allies");
						break;
					}
				}
			}
		}
	}
}

/*
	A server thread for monitoring all bot's in game. Will add and kick bots according to server settings.
*/
addBots()
{
	level endon("game_ended");

	wait 3;
	
	for(;;)
	{
		wait 1.5;
		
		botsToAdd = GetDvarInt("bots_manage_add");
		SetDvar("bots_manage_add", 0);
		
		if(botsToAdd > 0)
		{
			if(botsToAdd > 64)
				botsToAdd = 64;
				
			for(; botsToAdd > 0; botsToAdd--)
			{
				level add_bot();
				wait 0.25;
			}
		}
		
		fillMode = getDVarInt("bots_manage_fill_mode");
		
		if(fillMode == 2 || fillMode == 3)
			setDvar("bots_manage_fill", getGoodMapAmount());
		
		fillAmount = getDvarInt("bots_manage_fill");
		
		players = 0;
		bots = 0;
		spec = 0;
		
		playercount = level.players.size;
		for(i = 0; i < playercount; i++)
		{
			player = level.players[i];
			
			if(player is_bot())
				bots++;
			else if(!isDefined(player.pers["team"]) || (player.pers["team"] != "axis" && player.pers["team"] != "allies"))
				spec++;
			else
				players++;
		}
		
		if(fillMode == 4)
		{
			axisplayers = 0;
			alliesplayers = 0;
			
			playercount = level.players.size;
			for(i = 0; i < playercount; i++)
			{
				player = level.players[i];
				
				if(player is_bot())
					continue;
				
				if(!isDefined(player.pers["team"]))
					continue;
				
				if(player.pers["team"] == "axis")
					axisplayers++;
				else if(player.pers["team"] == "allies")
					alliesplayers++;
			}
			
			result = fillAmount - abs(axisplayers - alliesplayers) + bots;
			
			if (players == 0)
			{
				if(bots < fillAmount)
					result = fillAmount-1;
				else if (bots > fillAmount)
					result = fillAmount+1;
				else
					result = fillAmount;
			}
			
			bots = result;
		}
		
		amount = bots;
		if(fillMode == 0 || fillMode == 2)
			amount += players;
		if(getDVarInt("bots_manage_fill_spec"))
			amount += spec;
			
		if(amount < fillAmount)
			setDvar("bots_manage_add", 1);
		else if(amount > fillAmount && getDvarInt("bots_manage_fill_kick"))
		{
			tempBot = random(getBotArray());
			if (isDefined(tempBot))
				kick( tempBot getEntityNumber(), "EXE_PLAYERKICKED" );
		}
	}
}

/*
	A thread for ALL players, will monitor and grenades thrown.
*/
onGrenadeFire()
{
	self endon("disconnect");
	for(;;)
	{
		self waittill ( "grenade_fire", grenade, weaponName );
		grenade.name = weaponName;

		if(weaponName == "smoke_grenade_mp")
			grenade thread AddToSmokeList();
		else if (isSubStr(weaponName, "frag_"))
			grenade thread AddToFragList(self);
		else if ( weaponName == "claymore" || weaponName == "claymore_mp" )
			grenade thread claymoreDetonationBotFix();
	}
}

/*
	Adds a frag grenade to the list of all frags
*/
AddToFragList(who)
{
	grenade = spawnstruct();
	grenade.origin = self getOrigin();
	grenade.velocity = (0, 0, 0);
	grenade.grenade = self;
	grenade.owner = who;
	grenade.team = who.team;
	grenade.throwback = undefined;

	grenade thread thinkFrag();
	
	level.bots_fragList ListAdd(grenade);
}

/*
	Watches while the frag exists
*/
thinkFrag()
{
	while(isDefined(self.grenade))
	{
		nowOrigin = self.grenade getOrigin();
		self.velocity = (nowOrigin - self.origin)*20;
		self.origin = nowOrigin;

		wait 0.05;
	}
	
	level.bots_fragList ListRemove(self);
}

/*
	Adds a smoke grenade to the list of smokes in the game. Used to prevent bots from seeing through smoke.
*/
AddToSmokeList()
{
	grenade = spawnstruct();
	grenade.origin = self getOrigin();
	grenade.state = "moving";
	grenade.grenade = self;
	
	grenade thread thinkSmoke();
	
	level.bots_smokeList ListAdd(grenade);
}

/*
	The smoke grenade logic.
*/
thinkSmoke()
{
	while(isDefined(self.grenade))
	{
		self.origin = self.grenade getOrigin();
		self.state = "moving";
		wait 0.05;
	}
	self.state = "smoking";
	wait 11.5;
	
	level.bots_smokeList ListRemove(self);
}

/*
	A thread for ALL players when they fire.
*/
onWeaponFired()
{
	self endon("disconnect");
	self.bots_firing = false;
	for(;;)
	{
		self waittill( "weapon_fired" );
		self thread doFiringThread();
	}
}

/*
	Lets bot's know that the player is firing.
*/
doFiringThread()
{
	self endon("disconnect");
	self endon("weapon_fired");
	self.bots_firing = true;
	wait 1;
	self.bots_firing = false;
}
