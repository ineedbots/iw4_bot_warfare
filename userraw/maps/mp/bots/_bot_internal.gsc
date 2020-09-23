#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\bots\_bot_utility;

/*
	When a bot is added (once ever) to the game (before connected).
	We init all the persistent variables here.
*/
added()
{
	self endon("disconnect");
	
	self.pers["bots"] = [];
	
	self.pers["bots"]["skill"] = [];
	self.pers["bots"]["skill"]["base"] = 7;
	self.pers["bots"]["skill"]["aim_time"] = 0.05;
	self.pers["bots"]["skill"]["init_react_time"] = 0;
	self.pers["bots"]["skill"]["reaction_time"] = 0;
	self.pers["bots"]["skill"]["no_trace_ads_time"] = 2500;
	self.pers["bots"]["skill"]["no_trace_look_time"] = 10000;
	self.pers["bots"]["skill"]["remember_time"] = 25000;
	self.pers["bots"]["skill"]["fov"] = -1;
	self.pers["bots"]["skill"]["dist"] = 100000;
	self.pers["bots"]["skill"]["spawn_time"] = 0;
	self.pers["bots"]["skill"]["help_dist"] = 10000;
	self.pers["bots"]["skill"]["semi_time"] = 0.05;
	
	self.pers["bots"]["behavior"] = [];
	self.pers["bots"]["behavior"]["strafe"] = 50;
	self.pers["bots"]["behavior"]["nade"] = 50;
	self.pers["bots"]["behavior"]["sprint"] = 50;
	self.pers["bots"]["behavior"]["camp"] = 50;
	self.pers["bots"]["behavior"]["follow"] = 50;
	self.pers["bots"]["behavior"]["crouch"] = 10;
	self.pers["bots"]["behavior"]["switch"] = 1;
	self.pers["bots"]["behavior"]["class"] = 1;
	self.pers["bots"]["behavior"]["jump"] = 100;

	self.pers["bots"]["unlocks"] = [];
}

/*
	When a bot connects to the game.
	This is called when a bot is added and when multiround gamemode starts.
*/
connected()
{
	self endon("disconnect");
	
	self.bot = spawnStruct();

	self resetBotVars();
	
	self thread onPlayerSpawned();
	self thread onDisconnected();
	self thread onGameEnded();
	self thread onGiveLoadout();
}

/*
	The callback hook for when the bot gets killed.
*/
onKilled(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration)
{
	if (isDefined(self.bot_anim))
	{
		hidden = self isFakeAnimHidden();
		self botsDeleteFakeAnim();

		if (!hidden)
		{
			if (isDefined(eAttacker) && isDefined(eAttacker.guid) && isDefined(self.attackerData[eAttacker.guid]) && isDefined(self.attackerData[eAttacker.guid].firstTimeDamaged))
				self.attackerData[eAttacker.guid].firstTimeDamaged += 100; // two frames?? but it works??
				
			wait 0.05;
		}
	}
}

/*
	The callback hook when the bot gets damaged.
*/
onDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset)
{
}

/*
	The giveloadout watcher
*/
onGiveLoadout()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("giveLoadout");
		self botsDeleteFakeAnim();
	}
}

/*
	Watches for the game to end
*/
onGameEnded()
{
	self endon("disconnect");

	level waittill("game_ended");
	self botsDeleteFakeAnim();
}

/*
	Watches for when we disconnect
*/
onDisconnected()
{
	self waittill("disconnect");
	self botsDeleteFakeAnim();
}

/*
	We clear all of the script variables and other stuff for the bots.
*/
resetBotVars()
{
	self.bot.script_target = undefined;
	self.bot.script_target_offset = undefined;
	self.bot.targets = [];
	self.bot.target = undefined;
	self.bot.target_this_frame = undefined;
	self.bot.jav_loc = undefined;
	
	self.bot.script_aimpos = undefined;
	
	self.bot.script_goal = undefined;
	self.bot.script_goal_dist = 0.0;
	
	self.bot.next_wp = -1;
	self.bot.second_next_wp = -1;
	self.bot.towards_goal = undefined;
	self.bot.astar = [];
	self.bot.velocity = (0,0,0);
	self.bot.script_move_speed = 0;
	self.bot.last_pos = self.origin;
	self.bot.moveTo = self.origin;
	self.bot.climbing = false;
	self.bot.stop_move = false;
	
	self.bot.isfrozen = false;
	self.bot.isreloading = false;

	self.bot.isfragging = false;
	self.bot.isfraggingafter = false;
	self.bot.tryingtofrag = false;
	self.bot.tryingtofragpullback = false;
	
	self.bot.semi_time = false;
	self.bot.greedy_path = false;
	self.bot.is_cur_full_auto = false;
	
	self.bot.rand = randomInt(100);

	self.bot.isswitching = false;
	self.bot.switch_to_after_none = undefined;

	self.bot.stance = "stand";

	self.bot.running = false;
	self.bot.max_run_time = getdvarfloat("scr_player_sprinttime");
	self.bot.run_time = self.bot.max_run_time;
	self.bot.runningafter = false;

	self.bot.fire_pressed = false;
	self.bot.is_frozen_internal = true;

	self.bot.ads_pressed = false;
	self.bot.ads_lowest = 9;
	self.bot.ads_tightness = self.bot.ads_lowest;
	self.bot.ads_highest = 1;

	self.bot.jumping = false;
	self.bot.jumpingafter = false;

	self.bot.lockingon = false;

	self.bot.knifing = false;
	self.bot.knifingafter = false;
}

/*
	When the bot spawns.
*/
onPlayerSpawned()
{
	self endon("disconnect");
	
	for(;;)
	{
		self waittill("spawned_player");
		
		self resetBotVars();
		self thread onWeaponChange();
		self thread onLastStand();
		
		self thread reload_watch();
		self thread grenade_watch();
		self thread lockon_watch();
		self thread jav_loc_watch();
		self thread ti_fix();

		self thread adsHack();
		self thread fireHack();
		self thread stanceHack();
		self thread moveHack();

		self thread UseRunThink();
		self thread watchUsingRemote();
		
		self thread spawned();
	}
}

/*
	Fixes the ti script, because IsOnGround is always false when freezecontrols(true)
*/
ti_fix()
{
	self endon("disconnect");
	self endon("death");

	for (;;)
	{
		self waittill( "grenade_fire", lightstick, weapName );
				
		if ( weapName != "flare_mp" )
			continue;

		self.TISpawnPosition = self.origin;
	}
}

/*
	Watches and handles javelin location lock on.
*/
jav_loc_watch()
{
	self endon("disconnect");
	self endon("death");

	for (;;)
	{
		wait 0.05;

		if(!gameFlag( "prematch_done" ) || level.gameEnded || self.bot.isfrozen || self maps\mp\_flashgrenades::isFlashbanged())
			continue;

		if (!isDefined(self.bot.jav_loc))
			continue;

		weap = self getCurrentWeapon();
		if (weap != "javelin_mp")
			continue;

		if (!self GetCurrentWeaponClipAmmo())
			continue;

		if (self isEMPed())
			continue;

		self watchJavLock();
	}
}

/*
	Does the javelin lock on
*/
watchJavLock()
{
	self endon("bot_kill_lockon_jav");

	self thread watchJavLockEvents();
	self thread watchJavLockHas();

	self thread maps\mp\_javelin::LoopLocalSeekSound( "javelin_clu_aquiring_lock", 0.6 );
	wait 2;

	self notify( "stop_lockon_sound" );
	self PlayLocalSound( "javelin_clu_lock" );
	wait 1;

	while (isDefined(self.bot.jav_loc))
	{
		self WeaponLockFinalize( self.bot.jav_loc, (0,0,0), true );
		wait 0.05;
	}

	self notify("bot_kill_lockon_jav");
}

/*
	Watches while we have a location to lock on
*/
watchJavLockHas()
{
	self endon("bot_kill_lockon_jav");
	self endon("disconnect");
	self endon("death");

	while (isDefined(self.bot.jav_loc))
	{
		wait 0.05;
	}

	self notify( "stop_lockon_sound" );
	self notify("bot_kill_lockon_jav");
}

/*
	Watches when to kill the javelin lock on
*/
watchJavLockEvents()
{
	self endon("bot_kill_lockon_jav");
	self endon("disconnect");
	self endon("death");

	self waittill_any("flash_rumble_loop", "weapon_change", "missile_fire");

	self notify( "stop_lockon_sound" );
	self notify("bot_kill_lockon_jav");
}

/*
	Watches and does the vehicle lockon
*/
lockon_watch()
{
	self endon("disconnect");
	self endon("death");

	for (;;)
	{
		wait 0.05;

		if(!gameFlag( "prematch_done" ) || level.gameEnded || self.bot.isfrozen || self maps\mp\_flashgrenades::isFlashbanged())
			continue;

		if (!isDefined(self.bot.target) || !isDefined(self.bot.target.entity))
			continue;

		if (!entIsVehicle(self.bot.target.entity))
			continue;

		weap = self getCurrentWeapon();
		if (weap != "stinger_mp" && weap != "at4_mp" && weap != "javelin_mp")
			continue;

		if (!self GetCurrentWeaponClipAmmo())
			continue;

		if (weap == "javelin_mp" && self isEMPed())
			continue;

		self.bot.lockingon = true;
		self doLockon();
		self.bot.lockingon = false;
	}
}

/*
	Does the lock on
*/
doLockon()
{
	self endon("bot_kill_lockon");
	self thread watchBotLockonEvents();
	self thread watchBotLockonTrace();

	self thread doRocketLockingSound();
	wait 3;
	self notify("bot_kill_lockon_sound");

	self thread doRocketLockedSound();
	wait 1;
	self notify("bot_kill_lockon_sound");

	// fire!
	weap = self getCurrentWeapon();
	while (isDefined(self.bot.target) && isDefined(self.bot.target.entity))
	{
		self.stingerTarget = self.bot.target.entity;
		self.javelinTarget = self.bot.target.entity;

		if (weap != "javelin_mp")
		{
			if ( self.stingerTarget.model == "vehicle_av8b_harrier_jet_mp"  || self.stingerTarget.model == "vehicle_little_bird_armed" )
				self WeaponLockFinalize( self.stingerTarget );
			else
				self WeaponLockFinalize( self.stingerTarget, (100,0,-32) );
		}
		else
			self WeaponLockFinalize( self.javelinTarget, (0,0,0), false );

		if (weap == "at4_mp")
			self.bot.lockingon = false; // so that the bot can fire

		wait 0.05;
	}

	self notify("bot_kill_lockon");
}

/*
	Makes sure we have sight on the vehicle
*/
watchBotLockonTrace()
{
	self endon("death");
	self endon("disconnect");
	self endon("bot_kill_lockon");

	while (isDefined(self.bot.target) && isDefined(self.bot.target.entity) && self.bot.target.no_trace_time < 500)
		wait 0.05;

	self notify("bot_kill_lockon");
}

/*
	Stops the lock on when an event happens
*/
watchBotLockonEvents()
{
	self endon("death");
	self endon("disconnect");
	self endon("bot_kill_lockon");

	self waittill_any("flash_rumble_loop", "new_enemy", "weapon_change", "missile_fire");

	self notify("bot_kill_lockon");
}

/*
	Plays the beeps
*/
doRocketLockingSound()
{
	self endon("disconnect");
	self endon("death");
	self endon("bot_kill_lockon_sound");
	self endon("bot_kill_lockon");
	
	for(;;)
	{
		wait 0.6;

		if(isDefined(self.bot.target) && isDefined(self.bot.target.entity))
		{
			if ( isDefined( level.chopper ) && isDefined( level.chopper.gunner ) && self.bot.target.entity == level.chopper )
				level.chopper.gunner playLocalSound( "missile_locking" );

			if ( isDefined( level.ac130player ) && self.bot.target.entity == level.ac130.planeModel )
				level.ac130player playLocalSound( "missile_locking" );
			
			self playLocalSound( "stinger_locking" );
			self PlayRumbleOnEntity( "ac130_25mm_fire" );
		}
	}
}

/*
	Plays the beeps
*/
doRocketLockedSound()
{
	self endon("disconnect");
	self endon("death");
	self endon("bot_kill_lockon_sound");
	self endon("bot_kill_lockon");
	
	for(;;)
	{
		if(isDefined(self.bot.target) && isDefined(self.bot.target.entity))
		{
			if ( isDefined( level.chopper ) && isDefined( level.chopper.gunner ) && self.bot.target.entity == level.chopper )
				level.chopper.gunner playLocalSound( "missile_locking" );

			if ( isDefined( level.ac130player ) && self.bot.target.entity == level.ac130.planeModel )
				level.ac130player playLocalSound( "missile_locking" );
			
			self playLocalSound( "stinger_locked" );
			self PlayRumbleOnEntity( "ac130_25mm_fire" );
		}
		wait 0.25;
	}
}

/*
	Handles when the bot is to stop running and how much run time it has
*/
UseRunThink()
{
	self endon("death");
	self endon("disconnect");

	for(;;)
	{
		wait 0.05;

		if(self.bot.running)
		{
			if(!self _hasPerk("specialty_marathon"))
				self.bot.run_time -= 0.05;

			if (self.bot.run_time <= 0 ||
			self inLastStand() || self getStance() != "stand" ||
			level.gameEnded || !gameFlag( "prematch_done" ) ||
			self.bot.isfrozen || self.bot.climbing ||
			self.bot.isreloading ||
			self.bot.ads_pressed || self.bot.fire_pressed ||
			self.bot.isfragging || self.bot.knifing || 
			lengthsquared(self.bot.velocity) <= 25 ||
			self IsStunned() || self isArtShocked() || self maps\mp\_flashgrenades::isFlashbanged())
			{
				self.bot.running = false;
				self thread doRunDelay();
			}
		}
		else
		{
			if(self.bot.run_time < self.bot.max_run_time)
				self.bot.run_time += 0.05;
		}
	}
}

/*
	Adds a delay after running (simulates pulling up the gun from a sprint)
*/
doRunDelay()
{
	self endon("disconnect");
	self endon("death");
	self notify("bot_run_delay");
	self endon("bot_run_delay");

	if (self _hasPerk("specialty_fastsprintrecovery"))
		wait 0.5;
	else
		wait 1;

	self.bot.runningafter = false;
}

/*
	Sets our stance, because the executable is always setting the bot's stance to the dvar
*/
stanceHack()
{
	self endon("disconnect");
	self endon("death");

	self SetStance(self.bot.stance);
	for (;;)
	{
		wait 0.05;

		if(self inLastStand())
			continue;

		if (level.gameEnded || !gameFlag( "prematch_done" ))
			continue;

		if (self.bot.isfrozen)
			continue;
			
		self SetStance(self.bot.stance);
	}
}

/*
	Watches when we pull back a grenade
*/
grenade_watch()
{
	self endon("disconnect");
	self endon("death");

	for (;;)
	{
		self waittill("grenade_pullback", weaponName);
		self.bot.isfragging = true;
		self.bot.isfraggingafter = true;

		self waittill_any_timeout( 10, "grenade_fire", "weapon_change", "offhand_end" );

		self.bot.isfragging = false;
		self thread doFragAfterThread();
	}
}

/*
	Wait a bit to stop the frag
*/
doFragAfterThread()
{
	self endon("disconnect");
	self endon("death");
	self endon("grenade_pullback");

	wait 1;
	self.bot.isfraggingafter = false;
}

/*
	Basically unfreezes the bot when its clip is empty so it can reload
*/
emptyClipShoot()
{
	self endon("disconnect");
	self endon("death");

	for (;;)
	{
		wait 0.05;

		if (self.bot.isreloading || self GetCurrentWeaponClipAmmo())
			continue;

		cur = self GetCurrentWeapon();

		if (cur == "none" || IsWeaponClipOnly(cur) || !self GetWeaponAmmoStock(cur) || self IsUsingRemote())
			continue;

		self thread pressFire();
	}
}

/*
	Hides the animator script model when it needs too
*/
checkShouldHideAnim(shouldHideAnim)
{
	isHidden = self isFakeAnimHidden();

	if (self.bot.isreloading || self.bot.isfraggingafter)
		shouldHideAnim = true;

	if (self isInActiveAnim())
		shouldHideAnim = false;

	if (isHidden && !shouldHideAnim)
		self showFakeAnim();
	else if (!isHidden && shouldHideAnim)
		self hideFakeAnim();
}

/*
	Does the movement for the bot, as well as telling what passive animation to play, and foot sounds
*/
moveHack()
{
	self endon("disconnect");
	self endon("death");

	self.bot.last_pos = self.origin;
	self.bot.moveTo = self.origin;

	shouldHideAnim = true;
	for (timer = 0;;timer += 0.05)
	{
		self checkShouldHideAnim(shouldHideAnim);
		shouldHideAnim = true;
		wait 0.05;

		self.bot.velocity = (self.origin-self.bot.last_pos)*20;
		self.bot.last_pos = self.origin;

		if (DistanceSquared(self.bot.moveTo, self.origin) < 1)
			continue;

		if (level.gameEnded || !gameFlag( "prematch_done" ))
			continue;

		if (self.bot.isfrozen)
			continue;

		stance = self getStance();
		curWeap = self GetCurrentWeapon();
		weapClass = weaponClass(curWeap);
		inLastStand = self inLastStand();
		usingRemote = self isUsingRemote();
		moveTo = self.bot.moveTo;
		botAnim = "";

		if (!self.bot.climbing)
		{
			// a number between 0 and 1, 1 being totally flat, same level.    0 being totally above or below.      about 0.7 is a 45 degree angle
			verticleDegree = getConeDot(moveTo + (1, 1, 0), self.origin  + (-1, -1, 0), VectorToAngles((moveTo[0], moveTo[1], self.origin[2]) - self.origin));
			self.bot.climbing = (abs(moveTo[2] - self.origin[2]) > 50 && verticleDegree < 0.64);
		}

		// only climb if we are not inlaststand, not using a remote, not jumping, and on a waypoint path
		if (inLastStand || usingRemote || self.bot.jumpingafter || self.bot.next_wp == -1)
			self.bot.climbing = false;

		if (usingRemote)
			continue;

		moveSpeed = 10;
		if (self.bot.running)
			moveSpeed *= 1.5;
		if (self IsStunned() || self isArtShocked())
			moveSpeed *= 0.15;
		if (self.bot.ads_pressed)
			moveSpeed *= 0.35;

		if (inLastStand)
			moveSpeed *= 0.2;
		else
		{
			if (stance == "crouch")
				moveSpeed *= 0.5;
			if (stance == "prone")
				moveSpeed *= 0.2;
		}

		if (self.bot.climbing)
		{
			if (self _hasPerk("specialty_fastmantle"))
				moveSpeed = 6;
			else
				moveSpeed = 4;
		}

		switch ( weapClass )
		{
			case "rifle":
				if(self.hasRiotShieldEquipped)
					moveSpeed *= 0.8;
				else
					moveSpeed *= 0.95;
				break;
			case "mg":
				moveSpeed *= 0.875;
				break;
			case "spread":
				moveSpeed *= 0.95;
				break;
			case "rocketlauncher":
				moveSpeed *= 0.8;
				break;
		}

		if (self _hasPerk("specialty_lightweight"))
			moveSpeed *= 1.07;

		moveSpeed *= (getdvarfloat("g_speed")/190.0);
		moveSpeed *= self.moveSpeedScaler;

		self.bot.script_move_speed = moveSpeed;

		// do foot sound
		if ((moveSpeed > 0) && ((3.5 / moveSpeed) <= timer))
		{
			timer = 0;

			if (!self _hasPerk("specialty_quieter"))
			{
				if (self.bot.climbing)
					self playSound( "step_run_ladder" );
				else
				{
					myOg = self getOrigin();
					trace = bullettrace( myOg, myOg + (0.0, 0.0, -5.0), false, self );

					if (trace[ "surfacetype" ] != "none")
					{
						if (inLastStand)
							self playSound( "step_prone_" + trace[ "surfacetype" ] );
						else
						{
							switch( stance )
							{
								case "stand":
									self playSound( "step_run_" + trace[ "surfacetype" ] );
								break;
								case "crouch":
									self playSound( "step_walk_" + trace[ "surfacetype" ] );
								break;
								case "prone":
									self playSound( "step_prone_" + trace[ "surfacetype" ] );
								break;
							}
						}
					}
				}
			}
		}

		if (inLastStand)
			botAnim = "pb_laststand_crawl";
		else if (self.bot.climbing)
			botAnim = "pb_climbup";
		else if (stance == "prone")
			botAnim = "pb_prone_crawl";
		else
		{
			if (stance == "stand")
			{
				if (self.bot.running)
				{
					// sprint
					switch(weapClass)
					{
						case "pistol":
							botAnim = "pb_sprint_pistol";
						break;
						case "rocketlauncher":
							botAnim = "pb_sprint_RPG";
						break;
						default:
							botAnim = "pb_sprint";
						break;
					}

					if(self.hasRiotShieldEquipped)
						botAnim = "pb_sprint_shield";

					if(isSubStr(curWeap, "akimbo_"))
						botAnim = "pb_sprint_akimbo";
				}
				else
				{
					// stand
					switch(weapClass)
					{
						case "pistol":
							botAnim = "pb_pistol_run_fast";
						break;
						case "rocketlauncher":
							botAnim = "pb_combatrun_forward_RPG";
						break;
						default:
							botAnim = "pb_combatrun_forward_loop";
						break;
					}

					if(self.hasRiotShieldEquipped)
						botAnim = "pb_combatrun_forward_shield";

					if(isSubStr(curWeap, "akimbo_"))
						botAnim = "pb_combatrun_forward_akimbo";
				}
			}
			else
			{
				// crouch
				switch(weapClass)
				{
					case "pistol":
						botAnim = "pb_crouch_run_forward_pistol";
					break;
					case "rocketlauncher":
						botAnim = "pb_crouch_run_forward_RPG";
					break;
					default:
						botAnim = "pb_crouch_run_forward";
					break;
				}

				if(self.hasRiotShieldEquipped)
					botAnim = "pb_crouch_walk_forward_shield";

				if(isSubStr(curWeap, "akimbo_"))
					botAnim = "pb_crouch_walk_forward_akimbo";
			}
		}

		if (botAnim != "")
		{
			shouldHideAnim = false;

			if (!self botDoingAnim(botAnim))
				self botDoAnim(botAnim);
		}

		completedMove = false;
		if (DistanceSquared(self.origin, moveTo) < (moveSpeed * moveSpeed))
		{
			completedMove = true;
			self SetOrigin(moveTo);
		}

		// push out of players
		for (i = level.players.size - 1; i >= 0; i--)
		{
			player = level.players[i];

			if (player == self)
				continue;

			if (!isReallyAlive(player))
				continue;

			dist = distance(self.origin, player.origin);

			if (dist > level.botPushOutDist)
				continue;

			pushOutDir = VectorNormalize((self.origin[0], self.origin[1], 0)-(player.origin[0], player.origin[1], 0));
			trace = bulletTrace(self.origin + (0,0,20), (self.origin + (0,0,20)) + (pushOutDir * ((level.botPushOutDist-dist)+10)), false, self);
			//no collision, so push out
			if(trace["fraction"] == 1)
			{
				pushoutPos = self.origin + (pushOutDir * (level.botPushOutDist-dist));
				self SetOrigin((pushoutPos[0], pushoutPos[1], self.origin[2])); 
			}
		}

		if (completedMove)
			continue;

		if (!self.bot.climbing)
		{
			self SetOrigin(self.origin + (VectorNormalize((moveTo[0], moveTo[1], self.origin[2])-self.origin) * moveSpeed));

			// clamp to ground
			trace = physicsTrace(self.origin + (0.0,0.0,50.0), self.origin + (0.0,0.0,-40.0), false, undefined);
			if (self.bot.is_frozen_internal)
			{
				if(!self.bot.jumping && (trace[2] - (self.origin[2]-40.0)) > 0.0 && ((self.origin[2]+50.0) - trace[2]) > 0.0)
				{
					self SetOrigin(trace);
				}
				else
				{
					self SetOrigin(physicsTrace(self.origin + (0,0,5), self.origin - (0,0,5), false, undefined));
				}
			}

			continue;
		}
		
		self SetOrigin(self.origin + (VectorNormalize(moveTo-self.origin) * moveSpeed));
	}
}

/*
	Freezes and unfreezes the bot when told too,
	Bots are always wanting to fire, so we freeze to stop firing, and unfreeze to fire
*/
fireHack()
{
	self endon("disconnect");
	self endon("spawned_player");

	self FreezeControls(true);
	for (;;)
	{
		wait 0.05;

		if (!isAlive(self))
			return;

		shouldFire = self.bot.fire_pressed;

		if (self.bot.isswitching || self.bot.runningafter)
			shouldFire = false;

		if (self.bot.climbing || self.bot.knifing)
			shouldFire = false;

		if (self.bot.tryingtofrag)
		{
			if (self.bot.tryingtofragpullback)
				shouldFire = true;
			else
				shouldFire = false;
		}

		if (self.bot.isfrozen)
			shouldFire = false;

		if (isDefined(self.bot.target) && self IsUsingRemote())
			shouldFire = true;

		if (level.gameEnded || !gameFlag( "prematch_done" ))
			shouldFire = false;

		self.bot.is_frozen_internal = !shouldFire;
		self FreezeControls(!shouldFire);
	}
}

/*
	When the bot is told to ads.
	We use a smaller crosshair when we want to ads
*/
adsHack()
{
	self endon("disconnect");
	self endon("spawned_player");

	self setSpreadOverride(self.bot.ads_tightness);
	for (;;)
	{
		wait 0.05;

		if (!isAlive(self))
			return;

		shouldAds = self.bot.ads_pressed;

		if (level.gameEnded)
			shouldAds = false;

		if (!gameFlag( "prematch_done" ))
			shouldAds = false;

		if (self.bot.isfrozen)
			shouldAds = false;

		if (self.bot.climbing)
			shouldAds = false;

		if (shouldAds)
			self.bot.ads_tightness--;
		else
			self.bot.ads_tightness++;

		if (self _hasPerk("specialty_quickdraw"))
		{
			if (shouldAds)
				self.bot.ads_tightness--;
			else
				self.bot.ads_tightness++;
		}

		if (self.bot.ads_tightness < self.bot.ads_highest)
			self.bot.ads_tightness = self.bot.ads_highest;
		if (self.bot.ads_tightness > self.bot.ads_lowest)
			self.bot.ads_tightness = self.bot.ads_lowest;

		if (self.bot.ads_tightness >= self.bot.ads_lowest)
			self ResetSpreadOverride();
		else
			self setSpreadOverride(self.bot.ads_tightness);
	}
}

/*
	When the bot changes weapon.
*/
onWeaponChange()
{
	self endon("disconnect");
	self endon("death");

	self.bot.isswitching = false;
	
	self.bot.is_cur_full_auto = WeaponIsFullAuto(self GetCurrentWeapon());
	for(;;)
	{
		self waittill( "weapon_change", newWeapon );
		
		self.bot.is_cur_full_auto = WeaponIsFullAuto(newWeapon);

		if(level.gameEnded || !gameFlag( "prematch_done" ))
			continue;
		
		switch (newWeapon)
		{
			case "none":
				self thread doNoneSwitch();
			break;
			default:
				self thread doSwitch(newWeapon);
			break;
		}
	}
}

/*
	When the bot switches to a none weapon, we fix it
*/
doNoneSwitch()
{
	self endon("disconnect");
	self endon("death");
	self endon("weapon_change");

	self.bot.isswitching = false;

	while (self.disabledWeapon)
		wait 0.05;

	weap = self.lastDroppableWeapon;
	if (isDefined(self.bot.switch_to_after_none))
	{
		weap = self.bot.switch_to_after_none;
		self.bot.switch_to_after_none = undefined;
	}

	self SetSpawnWeapon(weap);
}

/*
	When the bot switches to a weapon, we play the active animation, and shoot delay
*/
doSwitch(newWeapon)
{
	self endon("disconnect");
	self endon("death");
	self endon("weapon_change");

	if (self.bot.climbing)
		return;

	waittillframeend;
	if (self.lastDroppableWeapon != newWeapon)
		return;

	if (!self inLastStand() && !self.bot.isfraggingafter && !self.bot.knifingafter)
		self thread botDoAnim("pt_stand_core_pullout", 0.5, true);

	self.bot.isswitching = true;

	wait 1;  // fast pullout?

	self.bot.isswitching = false;
}

/*
	Update's the bot if it is reloading.
*/
reload_watch()
{
	self endon("disconnect");
	self endon("death");
	
	for(;;)
	{
		self waittill("reload_start");
		self.bot.isreloading = true;

		self waittill_notify_or_timeout("reload", 7.5);
		self.bot.isreloading = false;
	}
}

/*
	When the bot enters laststand, we fix the weapons
*/
onLastStand()
{
	self endon("disconnect");
	self endon("death");

	while (true)
	{
		while (!self inLastStand())
			wait 0.05;

		if (!self inFinalStand() && !self IsUsingRemote())
		{
			while (self.bot.knifing || self.bot.tryingtofrag || self.disabledWeapon)
				wait 0.05;
			waittillframeend;

			pistol = undefined;
			weaponsList = self GetWeaponsListPrimaries();
			foreach ( weapon in weaponsList )
			{
				if ( maps\mp\gametypes\_weapons::isSideArm( weapon ) )
					pistol = weapon;
			}

			if (isDefined(pistol))
				self setSpawnWeapon(pistol);
		}

		while (self inLastStand())
			wait 0.05;
	}
}

/*
	When the bot uses a remote killstreak
*/
watchUsingRemote()
{
	self endon("disconnect");
	self endon("spawned_player");

	for (;;)
	{
		wait 1;

		if (!isAlive(self))
			return;

		if (!self IsUsingRemote())
			continue;

		if (isDefined(level.chopper) && isDefined(level.chopper.gunner) && level.chopper.gunner == self)
		{
			self watchUsingMinigun();

			if (isReallyAlive(self))
			{
				self setSpawnWeapon(self getLastWeapon());
				self.bot.targets = [];
			}
		}

		if (isDefined(level.ac130Player) && level.ac130player == self)
		{
			self thread watchAc130Weapon();
			self watchUsingAc130();

			if (isReallyAlive(self))
			{
				self setSpawnWeapon(self getLastWeapon());
				self.bot.targets = [];
			}
		}
	}
}

/*
	WHen it uses the helicopter minigun
*/
watchUsingMinigun()
{
	self endon("heliPlayer_removed");

	while (isDefined(level.chopper) && isDefined(level.chopper.gunner) && level.chopper.gunner == self)
	{
		if (self getCurrentWeapon() != "heli_remote_mp")
		{
			self setspawnweapon("heli_remote_mp");
		}

		if (isDefined(self.bot.target))
			self thread pressFire();

		wait 0.05;
	}
}

/*
	When it uses the ac130
*/
watchAc130Weapon()
{
	self endon("ac130player_removed");
	self endon("disconnect");
	self endon("spawned_player");

	while (isDefined(level.ac130Player) && level.ac130player == self)
	{
		curWeap = self GetCurrentWeapon();

		if (curWeap != "ac130_105mm_mp" && curWeap != "ac130_40mm_mp" && curWeap != "ac130_25mm_mp")
			self setSpawnWeapon("ac130_105mm_mp");

		if (isDefined(self.bot.target))
			self thread pressFire();

		wait 0.05;
	}
}

/*
	Swap between the ac130 weapons while in it
*/
watchUsingAc130()
{
	self endon("ac130player_removed");

	while (isDefined(level.ac130Player) && level.ac130player == self)
	{
		self setspawnweapon("ac130_105mm_mp");
		wait 3+randomInt(3);
		self setspawnweapon("ac130_40mm_mp");
		wait 4+randomInt(3);
		self setspawnweapon("ac130_25mm_mp");
		wait 4+randomInt(3);
	}
}

/*
	We wait for a time defined by the bot's difficulty and start all threads that control the bot.
*/
spawned()
{
	self endon("disconnect");
	self endon("death");

	wait self.pers["bots"]["skill"]["spawn_time"];
	
	self thread emptyClipShoot();

	self thread grenade_danager();

	self thread target();
	self thread aim();
	self thread check_reload();
	self thread stance();
	self thread onNewEnemy();
	self thread walk();

	self notify("bot_spawned");
}

/*
	Throws back frag grenades
	Does this by a hack
	Basically it'll throw its own frag grenade and delete the original frag
*/
grenade_danager()
{
	self endon("disconnect");
	self endon("death");
	
	for(;;)
	{
		wait 1;

		if (self inLastStand() && !self _hasPerk("specialty_laststandoffhand") && !self inFinalStand())
			continue;

		if (self.bot.isfrozen || level.gameEnded || !gameFlag( "prematch_done" ))
			continue;

		if(self.bot.isfraggingafter || self.bot.climbing || self.bot.knifingafter || self IsUsingRemote())
			continue;

		if(self isDefusing() || self isPlanting())
			continue;

		curWeap = self GetCurrentWeapon();

		if (!isWeaponPrimary(curWeap) || self.disabledWeapon)
			continue;

		myEye = self getEye();
		for (i = level.bots_fragList.count-1; i >= 0; i--)
		{
			frag = level.bots_fragList.data[i];

			if (isDefined(frag.throwback))
				continue;

			if (level.teamBased && frag.team == self.team)
				continue;

			if (lengthSquared(frag.velocity) > 10000)
				continue;

			if(DistanceSquared(self.origin, frag.origin) > 20000)
				continue;

			if (!bulletTracePassed( myEye, frag.origin, false, frag.grenade ))
				continue;

			frag.throwback = true;
			weap = "frag_grenade_mp";

			offhand = self GetCurrentOffhand();
			offhandcount = self GetAmmoCount(offhand);

			self TakeWeapon(offhand);// for some odd reason, mw2 will not give you a frag if you have any other primary offhand
			self GiveWeapon(weap);

			self thread watchThrowback(frag);
			self botThrowGrenade(weap);
			
			frag.throwback = undefined;

			self TakeWeapon(weap);
			self GiveWeapon(offhand);
			self setWeaponAmmoClip(offhand, offhandcount);
			break;
		}
	}
}

/*
	Watches if the throw was successful, and deletes the original
*/
watchThrowback(frag)
{
	self endon("bot_kill_throwback");
	self thread notifyAfterDelay(5, "bot_kill_throwback");
	self waittill( "grenade_fire", grenade, wName );

	// blew up already
	if (!isDefined(frag.grenade) || wName != "frag_grenade_mp")
	{
		grenade delete();
		return;
	}

	grenade.threwBack = true;
	self thread incPlayerStat( "throwbacks", 1 );
	grenade thread maps\mp\gametypes\_shellshock::grenade_earthQuake();
	grenade.originalOwner = frag.owner;
	frag.grenade delete();
}

/*
	Bots will update its needed stance according to the nodes on the level. Will also allow the bot to sprint when it can.
*/
stance()
{
	self endon("disconnect");
	self endon("death");
	
	for(;;)
	{
		self waittill_either("finished_static_waypoints", "new_static_waypoint");
	
		toStance = "stand";
		if(self.bot.next_wp != -1)
			toStance = level.waypoints[self.bot.next_wp].type;
		self.bot.climbing = (toStance == "climb");
		if(toStance == "climb")
			toStance = "stand";
			
		if(toStance != "stand" && toStance != "crouch" && toStance != "prone")
			toStance = "crouch";
			
		if(toStance == "stand" && randomInt(100) <= self.pers["bots"]["behavior"]["crouch"])
			toStance = "crouch";
			
		if(toStance == "stand")
			self stand();
		else if(toStance == "crouch")
			self crouch();
		else
			self prone();
			
		curweap = self getCurrentWeapon();
			
		if(toStance != "stand" || self.bot.running)
			continue;
			
		if(randomInt(100) > self.pers["bots"]["behavior"]["sprint"])
			continue;
			
		if(isDefined(self.bot.target) && self canFire(curweap) && self isInRange(self.bot.target.dist, curweap))
			continue;
			
		if(!isDefined(self.bot.towards_goal) || DistanceSquared(self.origin, self.bot.towards_goal) < level.bots_minSprintDistance || getConeDot(self.bot.towards_goal, self.origin, self GetPlayerAngles()) < 0.75)
			continue;
			
		self thread sprint();
	}
}

/*
	Bot will wait until firing.
*/
check_reload()
{
	self endon("disconnect");
	self endon("death");
	
	for(;;)
	{
		self waittill_notify_or_timeout( "weapon_fired", 5 );
		self thread reload_thread();
	}
}

/*
	Bot will reload after firing if needed.
*/
reload_thread()
{
	self endon("disconnect");
	self endon("death");
	self endon("weapon_fired");
	
	wait 2.5;

	if (self.bot.isfrozen || level.gameEnded || !gameFlag( "prematch_done" ))
		return;
	
	if(isDefined(self.bot.target) || self.bot.isreloading || self.bot.isfraggingafter || self.bot.climbing || self.bot.knifingafter)
		return;
		
	cur = self getCurrentWEapon();
	
	if(IsWeaponClipOnly(cur) || !self GetWeaponAmmoStock(cur) || self IsUsingRemote())
		return;
	
	maxsize = WeaponClipSize(cur);
	cursize = self GetWeaponammoclip(cur);
	
	if(cursize/maxsize < 0.5)
		self thread reload();
}

/*
	The main target thread, will update the bot's main target. Will auto target enemy players and handle script targets.
*/
target()
{
	self endon("disconnect");
	self endon("spawned_player");
	
	for(;;)
	{
		wait 0.05;

		if (!isAlive(self))
			return;
		
		if(self maps\mp\_flashgrenades::isFlashbanged() || self.bot.climbing)
			continue;
	
		myEye = self GetEye();
		theTime = getTime();
		myAngles = self GetPlayerAngles();
		distsq = self.pers["bots"]["skill"]["dist"];
		distsq *= distsq;
		myFov = self.pers["bots"]["skill"]["fov"];
		bestTargets = [];
		bestTime = 9999999999;
		rememberTime = self.pers["bots"]["skill"]["remember_time"];
		initReactTime = self.pers["bots"]["skill"]["init_react_time"];
		hasTarget = isDefined(self.bot.target);
		usingRemote = self isUsingRemote();
		vehEnt = undefined;

		if (usingRemote)
		{
			if ( level.ac130player == self )
				vehEnt = level.ac130.planeModel;
			if ( isDefined(level.chopper) && isDefined(level.chopper.gunner) && level.chopper.gunner == self )
				vehEnt = level.chopper;
		}
		
		if(hasTarget && !isDefined(self.bot.target.entity))
		{
			self.bot.target = undefined;
			hasTarget = false;
		}
		
		if(isDefined(self.bot.script_target))
		{
			ent = self.bot.script_target;
			key = ent getEntityNumber()+"";
			daDist = distanceSquared(self.origin, ent.origin);
			obj = self.bot.targets[key];
			isObjDef = isDefined(obj);
			entOrigin = ent.origin;
			if (isDefined(self.bot.script_target_offset))
				entOrigin += self.bot.script_target_offset;
			
			for(;;)
			{
				if(SmokeTrace(myEye, entOrigin, level.smokeRadius) && bulletTracePassed(myEye, entOrigin, false, ent))
				{
					if(!isObjDef)
					{
						obj = spawnStruct();
						obj.entity = ent;
						obj.last_seen_pos = (0, 0, 0);
						obj.dist = 0;
						obj.time = theTime;
						obj.trace_time = 0;
						obj.no_trace_time = 0;
						obj.trace_time_time = 0;
						obj.rand = randomInt(100);
						obj.didlook = false;
						obj.isplay = isPlayer(ent);
						obj.offset = self.bot.script_target_offset;
						
						self.bot.targets[key] = obj;
					}
					
					obj.no_trace_time = 0;
					obj.trace_time += 50;
					obj.dist = daDist;
					obj.last_seen_pos = ent.origin;
					obj.trace_time_time = theTime;
				}
				else
				{
					if(!isObjDef)
						break;
					
					obj.no_trace_time += 50;
					obj.trace_time = 0;
					obj.didlook = false;
					
					if(obj.no_trace_time > rememberTime)
					{
						self.bot.targets[key] = undefined;
						break;
					}
				}
				
				if(theTime - obj.time < initReactTime)
					break;
				
				timeDiff = theTime - obj.trace_time_time;
				if(timeDiff < bestTime)
				{
					bestTargets = [];
					bestTime = timeDiff;
				}
				
				if(timeDiff == bestTime)
					bestTargets[key] = obj;
				break;
			}
		}
		
		if(isDefined(self.bot.target_this_frame))
		{
			player = self.bot.target_this_frame;
		
			key = player getEntityNumber()+"";
			obj = self.bot.targets[key];
			daDist = distanceSquared(self.origin, player.origin);
			
			if(!isDefined(obj))
			{
				obj = spawnStruct();
				obj.entity = player;
				obj.last_seen_pos = (0, 0, 0);
				obj.dist = 0;
				obj.time = theTime;
				obj.trace_time = 0;
				obj.no_trace_time = 0;
				obj.trace_time_time = 0;
				obj.rand = randomInt(100);
				obj.didlook = false;
				obj.isplay = isPlayer(player);
				obj.offset = undefined;
				
				self.bot.targets[key] = obj;
			}
			
			obj.no_trace_time = 0;
			obj.trace_time += 50;
			obj.dist = daDist;
			obj.last_seen_pos = player.origin;
			obj.trace_time_time = theTime;
			
			self.bot.target_this_frame = undefined;
		}
		
		playercount = level.players.size;
		for(i = 0; i < playercount; i++)
		{
			player = level.players[i];

			if(player == self)
				continue;
			
			key = player getEntityNumber()+"";
			obj = self.bot.targets[key];
			daDist = distanceSquared(self.origin, player.origin);
			isObjDef = isDefined(obj);
			if((level.teamBased && self.team == player.team) || player.sessionstate != "playing" || !isReallyAlive(player) || (daDist > distsq && !usingRemote))
			{
				if(isObjDef)
					self.bot.targets[key] = undefined;
			
				continue;
			}

			canTargetPlayer = false;

			if (usingRemote)
			{
				canTargetPlayer = (bulletTracePassed(myEye, player getTagOrigin( "j_head" ), false, vehEnt)
													&& !player _hasPerk("specialty_coldblooded"));
			}
			else
			{
				canTargetPlayer = (bulletTracePassed(myEye, player getTagOrigin( "j_head" ), false, player) ||
								bulletTracePassed(myEye, player getTagOrigin( "j_ankle_le" ), false, player) ||
								bulletTracePassed(myEye, player getTagOrigin( "j_ankle_ri" ), false, player))
								&& (distanceSquared(PhysicsTrace( player getTagOrigin( "j_spine4" ), myEye ), myEye) <= 0.0)
								&& (SmokeTrace(myEye, player.origin, level.smokeRadius) ||
									daDist < level.bots_maxKnifeDistance*4)
								&& (getConeDot(player.origin, self.origin, myAngles) >= myFov ||
								(isObjDef && obj.trace_time));
			}
			
			if(canTargetPlayer)
			{
				if(!isObjDef)
				{
					obj = spawnStruct();
					obj.entity = player;
					obj.last_seen_pos = (0, 0, 0);
					obj.dist = 0;
					obj.time = theTime;
					obj.trace_time = 0;
					obj.no_trace_time = 0;
					obj.trace_time_time = 0;
					obj.rand = randomInt(100);
					obj.didlook = false;
					obj.isplay = isPlayer(player);
					obj.offset = undefined;
					
					self.bot.targets[key] = obj;
				}
				
				obj.no_trace_time = 0;
				obj.trace_time += 50;
				obj.dist = daDist;
				obj.last_seen_pos = player.origin;
				obj.trace_time_time = theTime;
			}
			else
			{
				if(!isObjDef)
					continue;
				
				obj.no_trace_time += 50;
				obj.trace_time = 0;
				obj.didlook = false;
				
				if(obj.no_trace_time > rememberTime)
				{
					self.bot.targets[key] = undefined;
					continue;
				}
			}
			
			if(theTime - obj.time < initReactTime)
				continue;
			
			timeDiff = theTime - obj.trace_time_time;
			if(timeDiff < bestTime)
			{
				bestTargets = [];
				bestTime = timeDiff;
			}
			
			if(timeDiff == bestTime)
				bestTargets[key] = obj;
		}
		
		if(hasTarget && isDefined(bestTargets[self.bot.target.entity getEntityNumber()+""]))
			continue;
		
		closest = 9999999999;
		toBeTarget = undefined;
		
		bestKeys = getArrayKeys(bestTargets);
		for(i = bestKeys.size - 1; i >= 0; i--)
		{
			theDist = bestTargets[bestKeys[i]].dist;
			if(theDist > closest)
				continue;
				
			closest = theDist;
			toBeTarget = bestTargets[bestKeys[i]];
		}
		
		beforeTargetID = -1;
		newTargetID = -1;
		if(hasTarget && isDefined(self.bot.target.entity))
			beforeTargetID = self.bot.target.entity getEntityNumber();
		if(isDefined(toBeTarget) && isDefined(toBeTarget.entity))
			newTargetID = toBeTarget.entity getEntityNumber();
		
		if(beforeTargetID != newTargetID)
		{
			self.bot.target = toBeTarget;
			self notify("new_enemy");
		}
	}
}

/*
	When the bot gets a new enemy.
*/
onNewEnemy()
{
	self endon("disconnect");
	self endon("death");
	
	for(;;)
	{
		self waittill("new_enemy");

		if(!isDefined(self.bot.target))
			continue;
			
		if(!isDefined(self.bot.target.entity) || !self.bot.target.isplay)
			continue;
			
		if(self.bot.target.didlook)
			continue;
			
		self thread watchToLook();
	}
}

/*
	Bots will jump or dropshot their enemy player.
*/
watchToLook()
{
	self endon("disconnect");
	self endon("death");
	self endon("new_enemy");
	
	for(;;)
	{
		while(isDefined(self.bot.target) && self.bot.target.didlook)
			wait 0.05;
	
		while(isDefined(self.bot.target) && self.bot.target.no_trace_time)
			wait 0.05;
			
		if(!isDefined(self.bot.target))
			break;
		
		self.bot.target.didlook = true;
		
		if(self.bot.isfrozen)
			continue;
		
		if(self.bot.target.dist > level.bots_maxShotgunDistance*2)
			continue;
			
		if(self.bot.target.dist <= level.bots_maxKnifeDistance)
			continue;
		
		curweap = self getCurrentWEapon();
		if(!self canFire(curweap))
			continue;
			
		if(!self isInRange(self.bot.target.dist, curweap))
			continue;
			
		if(randomInt(100) > self.pers["bots"]["behavior"]["jump"])
			continue;
		
		thetime = getTime();
		if(isDefined(self.bot.jump_time) && thetime - self.bot.jump_time <= 5000)
			continue;
			
		if(self.bot.target.rand <= self.pers["bots"]["behavior"]["strafe"])
		{
			if(self getStance() != "stand")
				continue;
			
			self.bot.jump_time = thetime;
			self thread jump();
		}
		else
		{
			if(getConeDot(self.bot.target.last_seen_pos, self.origin, self getPlayerAngles()) < 0.8 || self.bot.target.dist <= level.bots_noADSDistance)
				continue;
		
			self.bot.jump_time = thetime;
			self prone();
			wait 2.5;
			self crouch();
		}
	}
}

/*
	This is the bot's main aimming thread. The bot will aim at its targets or a node its going towards. Bots will aim, fire, ads, grenade.
*/
aim()
{
	self endon("disconnect");
	self endon("spawned_player"); // for remote killstreaks.
	
	for(;;)
	{
		wait 0.05;

		if (!isAlive(self))
			return;
		
		if(!gameFlag( "prematch_done" ) || level.gameEnded || self.bot.isfrozen || self maps\mp\_flashgrenades::isFlashbanged())
			continue;
			
		aimspeed = self.pers["bots"]["skill"]["aim_time"];
		if(self IsStunned() || self isArtShocked())
			aimspeed = 1;

		usingRemote = self IsUsingRemote();
		curweap = self getCurrentWeapon();
		eyePos = self getEye();
		
		if (isDefined(self.bot.jav_loc) && !usingRemote)
		{
			lookPos = self.bot.jav_loc;

			self thread bot_lookat(lookPos, aimspeed);
			self thread pressAds();
			
			if (curweap == "javelin_mp")
				self botFire();
			continue;
		}

		if(isDefined(self.bot.target) && isDefined(self.bot.target.entity) && !self.bot.climbing)
		{
			no_trace_look_time = self.pers["bots"]["skill"]["no_trace_look_time"];
			no_trace_time = self.bot.target.no_trace_time;

			if (no_trace_time <= no_trace_look_time)
			{
				trace_time = self.bot.target.trace_time;
				last_pos = self.bot.target.last_seen_pos;
				target = self.bot.target.entity;
				conedot = 0;
				isplay = self.bot.target.isplay;
				offset = self.bot.target.offset;
				dist = self.bot.target.dist;
				angles = self GetPlayerAngles();
				rand = self.bot.target.rand;
				no_trace_ads_time = self.pers["bots"]["skill"]["no_trace_ads_time"];
				reaction_time = self.pers["bots"]["skill"]["reaction_time"];
				nadeAimOffset = 0;
				myeye = self getEye();

				if(weaponClass(curweap) == "grenade" || curweap == "throwingknife_mp")
				{
					if (getWeaponClass(curweap) == "weapon_projectile")
						nadeAimOffset = dist/16000;
					else
						nadeAimOffset = dist/3000;
				}
				
				if(no_trace_time)
				{
					if(no_trace_time > no_trace_ads_time && !usingRemote)
					{
						if(isplay)
						{
							//better room to nade? cook time function with dist?
							if(!self.bot.isfraggingafter)
							{
								nade = self getValidGrenade();
								if(isDefined(nade) && rand <= self.pers["bots"]["behavior"]["nade"] && bulletTracePassed(myEye, myEye + (0, 0, 75), false, self) && bulletTracePassed(last_pos, last_pos + (0, 0, 100), false, target) && dist > level.bots_minGrenadeDistance && dist < level.bots_maxGrenadeDistance)
								{
									time = 0.5;
									if (nade == "frag_grenade_mp")
										time = 2;
									self thread botThrowGrenade(nade, time);
									self notify("kill_goal");
								}
							}
						}
					}
					else
					{
						if (self canAds(dist, curweap))
							self thread pressAds();
					}
					
					if (!usingRemote)
						self thread bot_lookat(last_pos + (0, 0, self getEyeHeight() + nadeAimOffset), aimspeed);
					else
						self thread bot_lookat(last_pos, aimspeed);
					continue;
				}
				
				if(isplay)
				{
					aimpos = target getTagOrigin( "j_spineupper" ) + (0, 0, nadeAimOffset);
					conedot = getConeDot(aimpos, eyePos, angles);

					if (!nadeAimOffset && conedot > 0.999)
						self thread bot_lookat(aimpos, 0.05);
					else
						self thread bot_lookat(aimpos, aimspeed);
				}
				else
				{
					aimpos = target.origin;
					if (isDefined(offset))
						aimpos += offset;
					aimpos += (0, 0, nadeAimOffset);
					conedot = getConeDot(aimpos, eyePos, angles);
					self thread bot_lookat(aimpos, aimspeed);
				}
				
				knifeDist = level.bots_maxKnifeDistance;
				if (self _hasPerk("specialty_extendedmelee"))
					knifeDist *= 1.4;
				if((isplay || target.classname == "misc_turret") && !self.bot.knifing && conedot > 0.9 && dist < knifeDist && trace_time > reaction_time && !usingRemote)
				{
					self thread knife(target, knifeDist);
					continue;
				}
				
				if(!self canFire(curweap) || !self isInRange(dist, curweap))
				{
					continue;
				}
				
				canADS = self canAds(dist, curweap);
				if (canADS)
					self thread pressAds();

				if((!canADS || self botAdsAmount() == 1.0) && (conedot > 0.95 || dist < level.bots_maxKnifeDistance) && trace_time > reaction_time)
				{
					self botFire();
				}
				
				continue;
			}
		}
		
		if (self.bot.next_wp != -1 && isDefined(level.waypoints[self.bot.next_wp].angles) && self.bot.climbing)
		{
			forwardPos = anglesToForward(level.waypoints[self.bot.next_wp].angles) * 1024;

			self thread bot_lookat(eyePos + forwardPos, aimspeed);
		}
		else if (isDefined(self.bot.script_aimpos))
		{
			self thread bot_lookat(self.bot.script_aimpos, aimspeed);
		}
		else if (!usingRemote)
		{
			lookat = undefined;
			if(self.bot.second_next_wp != -1 && !self.bot.running)
				lookat = level.waypoints[self.bot.second_next_wp].origin;
			else if(isDefined(self.bot.towards_goal))
				lookat = self.bot.towards_goal;
			
			if(isDefined(lookat))
				self thread bot_lookat(lookat + (0, 0, self getEyeHeight()), aimspeed);
		}
	}
}

/*
	Bots will fire their gun.
*/
botFire()
{
	if(self.bot.is_cur_full_auto)
	{
		self thread pressFire();
		return;
	}

	if(self.bot.semi_time)
		return;
		
	self thread pressFire();
	self thread doSemiTime();
}

/*
	Waits a time defined by their difficulty for semi auto guns (no rapid fire)
*/
doSemiTime()
{
	self endon("death");
	self endon("disconnect");
	self notify("bot_semi_time");
	self endon("bot_semi_time");
	
	self.bot.semi_time = true;
	wait self.pers["bots"]["skill"]["semi_time"];
	self.bot.semi_time = false;
}

/*
	Returns true if the bot can fire their current weapon.
*/
canFire(curweap)
{
	if(curweap == "none")
		return false;

	if(curweap == "at4_mp" && self.bot.lockingon)
		return false;

	if (self.bot.isreloading || self.bot.knifing)
		return false;

	if (curweap == "riotshield_mp" || curweap == "onemanarmy_mp")
		return false;

	if (self IsUsingRemote())
		return true;
		
	return self GetWeaponammoclip(curweap);
}

/*
	Returns true if the bot can ads their current gun.
*/
canAds(dist, curweap)
{
	if (self IsUsingRemote())
		return false;

	far = level.bots_noADSDistance;
	if(self hasPerk("specialty_bulletaccuracy"))
		far *= 1.4;

	if(dist < far)
		return false;
	
	weapclass = (weaponClass(curweap));
	if(weapclass == "spread" || weapclass == "grenade")
		return false;

	if (curweap == "riotshield_mp" || curweap == "onemanarmy_mp")
		return false;

	if (isSubStr(curweap, "_akimbo_"))
		return false;
	
	return true;
}

/*
	Returns true if the bot is in range of their target.
*/
isInRange(dist, curweap)
{
	weapclass = weaponClass(curweap);

	if (self IsUsingRemote())
		return true;
	
	if((weapclass == "spread" || isSubStr(curweap, "_akimbo_")) && dist > level.bots_maxShotgunDistance)
		return false;

	if (curweap == "riotshield_mp" && dist > level.bots_maxKnifeDistance)
		return false;
		
	return true;
}

/*
	Will kill the walk threads and do it again after a time
*/
killWalkCauseNoWaypoints()
{
	self endon("disconnect");
	self endon("death");
	self endon("kill_goal");

	wait 2;

	self notify("kill_goal");
}

/*
	This is the main walking logic for the bot.
*/
walk()
{
	self endon("disconnect");
	self endon("death");
	
	for(;;)
	{
		wait 0.05;
		
		self botMoveTo(self.origin);
		
		if(self.bot.isfrozen || self.bot.stop_move)
			continue;
			
		if(self maps\mp\_flashgrenades::isFlashbanged() && !self.bot.jumpingafter)
		{
			myVel = self GetBotVelocity();
			moveTo = PlayerPhysicsTrace(self.origin + (0, 0, 32), self.origin + (myVel[0], myVel[1], 0)*500, false, self);
			self botMoveTo(moveTo);
			continue;
		}
		
		hasTarget = (((isDefined(self.bot.target) && isDefined(self.bot.target.entity)) || isDefined(self.bot.jav_loc)) && !self.bot.climbing);
		if(hasTarget)
		{
			curweap = self getCurrentWeapon();
			
			if(isDefined(self.bot.jav_loc) || entIsVehicle(self.bot.target.entity) || self.bot.isfraggingafter)
			{
				continue;
			}
			
			if(self.bot.target.isplay && self.bot.target.trace_time && self canFire(curweap) && self isInRange(self.bot.target.dist, curweap) && !self.bot.jumpingafter)
			{
				if(self.bot.target.rand <= self.pers["bots"]["behavior"]["strafe"])
					self strafe(self.bot.target.entity);
				continue;
			}
		}
		
		dist = 16;
		if(level.waypointCount)
			goal = level.waypoints[randomInt(level.waypointCount)].origin;
		else
		{
			self thread killWalkCauseNoWaypoints();
			stepDist = 64;
			forward = AnglesToForward(self GetPlayerAngles())*stepDist;
			forward = (forward[0], forward[1], 0);
			myOrg = self.origin + (0, 0, 32);

			goal = playerPhysicsTrace(myOrg, myOrg + forward, false, self);
			goal = PhysicsTrace(goal + (0, 0, 50), goal + (0, 0, -40), false, self);

			// too small, lets bounce off the wall
			if (Distance(goal, myOrg) < stepDist - 1 || randomInt(100) < 5)
			{
				trace = bulletTrace(myOrg, myOrg + forward, false, self);

				if (trace["surfacetype"] == "none" || randomInt(100) < 25)
				{
					// didnt hit anything, just choose a random direction then
					dir = (0,randomIntRange(-180, 180),0);
					goal = playerPhysicsTrace(myOrg, myOrg + AnglesToForward(dir) * stepDist, false, self);
					goal = PhysicsTrace(goal + (0, 0, 50), goal + (0, 0, -40), false, self);
				}
				else
				{
					// hit a surface, lets get the reflection vector
					// r = d - 2 (d . n) n
					d = VectorNormalize(trace["position"] - myOrg);
					n = trace["normal"];
					
					r = d - 2 * (VectorDot(d, n)) * n;

					goal = playerPhysicsTrace(myOrg, myOrg + (r[0], r[1], 0) * stepDist, false, self);
					goal = PhysicsTrace(goal + (0, 0, 50), goal + (0, 0, -40), false, self);
				}
			}
		}
		
		isScriptGoal = false;
		if(isDefined(self.bot.script_goal) && !hasTarget)
		{
			goal = self.bot.script_goal;
			dist = self.bot.script_goal_dist;

			isScriptGoal = true;
		}
		else
		{
			if(hasTarget)
				goal = self.bot.target.last_seen_pos;
				
			self notify("new_goal_internal");
		}
		
		self doWalk(goal, dist, isScriptGoal);
		self.bot.towards_goal = undefined;
		self.bot.next_wp = -1;
		self.bot.second_next_wp = -1;
	}
}

/*
	The bot will strafe left or right from their enemy.
*/
strafe(target)
{
	self endon("kill_goal");
	self thread killWalkOnEvents();
	
	angles = VectorToAngles(vectorNormalize(target.origin - self.origin));
	anglesLeft = (0, angles[1]+90, 0);
	anglesRight = (0, angles[1]-90, 0);
	
	left = self.origin + anglestoforward(anglesLeft)*500;
	right = self.origin + anglestoforward(anglesRight)*500;
	
	traceLeft = PlayerPhysicsTrace(self.origin + (0, 0, 32), left, false, self);
	traceRight = PlayerPhysicsTrace(self.origin + (0, 0, 32), right, false, self);
	
	strafe = traceLeft;
	if(DistanceSquared(left, traceLeft) > DistanceSquared(right, traceRight))
		strafe = traceRight;
	
	self botMoveTo(strafe);
	wait 2;
	self notify("kill_goal");
}

/*
	Will kill the goal when the bot made it to its goal.
*/
watchOnGoal(goal, dis)
{
	self endon("disconnect");
	self endon("death");
	self endon("kill_goal");
	
	while(DistanceSquared(self.origin, goal) > dis)
		wait 0.05;
	
	self notify("goal_internal");
}

/*
	Cleans up the astar nodes when the goal is killed.
*/
cleanUpAStar(team)
{
	self waittill_any("death", "disconnect", "kill_goal");
	
	for(i = self.bot.astar.size - 1; i >= 0; i--)
		level.waypoints[self.bot.astar[i]].bots[team]--;
}

/*
	Calls the astar search algorithm for the path to the goal.
*/
initAStar(goal)
{
	team = undefined;
	if(level.teamBased)
		team = self.team;
		
	self.bot.astar = AStarSearch(self.origin, goal, team, self.bot.greedy_path);
	
	if(isDefined(team))
		self thread cleanUpAStar(team);
	
	return self.bot.astar.size - 1;
}

/*
	Cleans up the astar nodes for one node.
*/
removeAStar()
{
	remove = self.bot.astar.size-1;
	
	if(level.teamBased)
		level.waypoints[self.bot.astar[remove]].bots[self.team]--;
	
	self.bot.astar[remove] = undefined;
	
	return self.bot.astar.size - 1;
}

/*
	Will stop the goal walk when an enemy is found or flashed or a new goal appeared for the bot.
*/
killWalkOnEvents()
{
	self endon("kill_goal");
	self endon("disconnect");
	self endon("death");
	
	ret = self waittill_any_return("flash_rumble_loop", "new_enemy", "new_goal_internal", "goal_internal", "bad_path_internal");

	waittillframeend;
	
	self notify("kill_goal");
}

/*
	Does the notify for goal completion for outside scripts
*/
doWalkScriptNotify()
{
	self endon("disconnect");
	self endon("death");
	
	ret = self waittill_any_return("goal_internal", "kill_goal", "bad_path_internal");
	
	if (ret == "goal_internal")
		self notify("goal");
	else if (ret == "bad_path_internal")
		self notify("bad_path");
}

/*
	Will walk to the given goal when dist near. Uses AStar path finding with the level's nodes.
*/
doWalk(goal, dist, isScriptGoal)
{
	self endon("kill_goal");
	self endon("goal_internal");//so that the watchOnGoal notify can happen same frame, not a frame later
	
	distsq = dist*dist;
	if (isScriptGoal)
		self thread doWalkScriptNotify();

	self thread killWalkOnEvents();
	self thread watchOnGoal(goal, distsq);
	
	current = self initAStar(goal);
	// if a waypoint is closer than the goal
	//if (current >= 0 && DistanceSquared(self.origin, level.waypoints[self.bot.astar[current]].origin) < DistanceSquared(self.origin, goal))
	//{
		while(current >= 0)
		{
			// skip down the line of waypoints and go to the waypoint we have a direct path too
			/*for (;;)
			{
				if (current <= 0)
					break;

				ppt = PlayerPhysicsTrace(self.origin + (0,0,32), level.waypoints[self.bot.astar[current-1]].origin, false, self);
				if (DistanceSquared(level.waypoints[self.bot.astar[current-1]].origin, ppt) > 1.0)
					break;

				if (level.waypoints[self.bot.astar[current-1]].type == "climb" || level.waypoints[self.bot.astar[current]].type == "climb")
					break;

				current = self removeAStar();
			}*/

			self.bot.next_wp = self.bot.astar[current];
			self.bot.second_next_wp = -1;
			if(current > 0)
				self.bot.second_next_wp = self.bot.astar[current-1];
			
			self notify("new_static_waypoint");
			
			self movetowards(level.waypoints[self.bot.next_wp].origin);
		
			current = self removeAStar();
		}
	//}
	
	self.bot.next_wp = -1;
	self.bot.second_next_wp = -1;
	self notify("finished_static_waypoints");
	
	if(DistanceSquared(self.origin, goal) > distsq)
	{
		ppt = PlayerPhysicsTrace(self.origin + (0,0,32), goal, false, self);
		self movetowards(ppt);
	}
	
	self notify("finished_goal");
	
	wait 1;
	if(DistanceSquared(self.origin, goal) > distsq)
		self notify("bad_path_internal");
}

/*
	Will move towards the given goal. Will try to not get stuck by crouching, then jumping and then strafing around objects.
*/
movetowards(goal)
{
	if(isDefined(goal))
		self.bot.towards_goal = goal;

	lastOri = self.origin;
	stucks = 0;
	time = 0;
	while(distanceSquared(self.origin, self.bot.towards_goal) > level.bots_goalDistance)
	{
		if (time > 1)
		{
			time = 0;

			if (DistanceSquared(self.origin, lastOri) < 128)
				stucks++;
			else
				stucks = 0;

			if(stucks >= 3)
				self notify("bad_path_internal");

			lastOri = self.origin;
		}

		self botMoveTo(self.bot.towards_goal);
		wait 0.05;
		time += 0.05;
	}
	
	self.bot.towards_goal = undefined;
	self notify("completed_move_to");
}

/*
	Bot will knife.
*/
knife(ent, knifeDist)
{
	self endon("disconnect");
	self endon("death");
	level endon ( "game_ended" );

	if (level.gameEnded || !gameFlag( "prematch_done" ) || self.bot.isfrozen || self IsUsingRemote())
		return;

	curWeap = self GetCurrentWeapon();

	if (!isWeaponPrimary(curWeap) || self.disabledWeapon)
		return;

	if(self isDefusing() || self isPlanting())
		return;

	if (self.bot.knifing || self.bot.isfraggingafter)
		return;

	self notify("bot_kill_knife");
	self endon("bot_kill_knife");

	self.bot.knifing = true;
	self.bot.knifingafter = true;

	isplay = (isDefined(ent) && isPlayer(ent));
	usedRiot = self.hasRiotShieldEquipped;
	org = (0, 0, 99999999);
	if (isDefined(ent))
		org = ent.origin;
	distsq = DistanceSquared(self.origin, org);
	inLastStand = self inLastStand();
	stance = self getStance();
	damage = 135;
	if (usedRiot)
		damage = 52;

	botAnim = "";
	botAnimTime = 0;
	lastWeap = self GetCurrentWeapon();

	hasC4 = self HasWeapon("c4_mp"); // mw2 will give you the c4 despite having another offhand primary

	if (!usedRiot)
	{
		if (!hasC4)
			self giveWeapon("c4_mp");
		self setSpawnWeapon("c4_mp");
	}

	// play sound
	if (usedRiot)
	{
		self playSound("melee_riotshield_swing");
		botAnim = "pt_melee_shield";
		botAnimTime = 1;
	}
	else
	{
		if ((distsq / knifeDist) < 0.5)
		{
			self playSound("melee_swing_small");
			if (stance != "prone")
			{
				botAnim = "pt_melee_pistol_1";
				botAnimTime = 1;
			}
			else
			{
				botAnim = "pt_melee_prone_pistol";
				botAnimTime = 1;
			}
		}
		else
		{
			self playSound("melee_swing_ps_large");
			botAnim = "pt_melee_pistol_2";
			botAnimTime = 1.5;
		}
	}

	if (inLastStand)
	{
		botAnim = "pt_laststand_melee";
		botAnimTime = 1.5;
	}

	if (botAnim != "")
		self thread botDoAnim(botAnim, botAnimTime, true);

	wait 0.15;

	if (isDefined(ent) && isAlive(ent) && randomInt(20)) // 5percent chance of missing
	{
		if (isplay)
		{
			// teleport to target
			if (!inLastStand)
			{
				pushOutDir = VectorNormalize((self.origin[0], self.origin[1], 0)-(ent.origin[0], ent.origin[1], 0));
				pushoutPos = self.origin + (pushOutDir * (60-distance(ent.origin,self.origin)));
				self SetOrigin((pushoutPos[0], pushoutPos[1], ent.origin[2]));
				self notify("kill_goal");
			}

			for (;;)
			{
				// check riotshield
				if (ent.hasRiotShield)
				{
					entCone = ent getConeDot((self.origin[0], self.origin[1], 0), (ent.origin[0], ent.origin[1], 0), (0, ent GetPlayerAngles()[1], 0));
					if ((entCone > 0.65 && ent.hasRiotShieldEquipped) || (entCone < -0.65 && !ent.hasRiotShieldEquipped))
					{
						// play riot shield hitting knife sound
						if (!usedRiot)
							self playSound("melee_knife_hit_shield");
						else
							self playSound("melee_riotshield_impact");

						break;
					}
				}

				if (!usedRiot)
				{
					playFx( level.bots_bloodfx,ent.origin + (0.0, 0.0, 30.0) );
					self playSound("melee_knife_hit_body");
				}
				else
					self playSound("melee_riotshield_impact");

				ent thread maps\mp\gametypes\_callbacksetup::CodeCallback_PlayerDamage(self, self, damage, 0, "MOD_MELEE", curWeap, self.origin, VectorNormalize(ent.origin-self.origin), "none", 0);
				break;
			}
		}
		else
		{
			if (!usedRiot)
				self playSound("melee_hit_other");
			else
				self playSound("melee_riotshield_impact");
			
			ent notify( "damage", damage, self, self.angles, self.origin, "MOD_MELEE" );
		}
	}

	if(isSubStr(curWeap, "tactical_") || usedRiot)
		wait 1;
	else
		wait 1.5;

	if (!usedRiot)
	{
		if (!hasC4)
			self takeWeapon("c4_mp");
		self setSpawnWeapon(lastWeap);
	}
	
	self.bot.knifing = false;

	wait 1;

	self.bot.knifingafter = false;
}

/*
	Bot will reload.
*/
reload()
{
	cur = self GetCurrentWeapon();

	if (level.gameEnded || !gameFlag( "prematch_done" ) || self.bot.isfrozen || self IsUsingRemote())
		return;

	self SetWeaponAmmoStock(cur, self GetWeaponAmmoClip(cur) + self GetWeaponAmmoStock(cur));
	self setWeaponAmmoClip(cur, 0);
	// the script should reload for us.
}

/*
	Bot will throw the grenade and cook it
*/
botThrowGrenade(grenName, grenTime)
{
	self endon("death");
	self endon("disconnect");
	level endon ( "game_ended" );

	if (self inLastStand() && !self _hasPerk("specialty_laststandoffhand") && !self inFinalStand())
		return "laststand";

	if (level.gameEnded || !gameFlag( "prematch_done" ) || self.bot.isfrozen || self.bot.climbing || self IsUsingRemote())
		return "can't move";

	if(self isDefusing() || self isPlanting())
		return "bomb";

	curWeap = self GetCurrentWeapon();

	if (!isWeaponPrimary(curWeap) || self.disabledWeapon)
		return "cur weap is not droppable";

	if (self.bot.knifingafter)
		return "knifing";

	if (self.bot.tryingtofrag || self.bot.isfraggingafter)
		return "already nading";

	if (!self getAmmoCount(grenName))
		return "no ammo";

	self setSpawnWeapon(grenName);
	self.bot.tryingtofrag = true;
	self.bot.tryingtofragpullback = true;

	ret = self waittill_any_timeout( 5, "grenade_pullback", "grenade_fire" );

	if (ret == "grenade_pullback")
	{
		if (isDefined(grenTime))
		{
			self.bot.tryingtofragpullback = false;
			wait grenTime;
			self.bot.tryingtofragpullback = true;
		}

		ret = self waittill_any_timeout( 5, "grenade_fire", "weapon_change", "offhand_end" );
	}

	self.bot.tryingtofrag = false;
	self.bot.tryingtofragpullback = false;

	self setSpawnWeapon(curWeap);

	return ret;
}

/*
	Bots will press the ads for a time
*/
pressAds(time)
{
	self endon("death");
	self endon("disconnect");
	self notify("bot_ads");
	self endon("bot_ads");

	if(!isDefined(time))
		time = 0.1;
	
	self ads(true);
	
	if(time)
		wait time;
		
	self ads(false);
}

/*
	Bots will hold the ads
*/
ads(what)
{
	self.bot.ads_pressed = what;
}

/*
	Bots will press the fire for a time
*/
pressFire(time)
{
	self endon("death");
	self endon("disconnect");
	self notify("bot_fire");
	self endon("bot_fire");

	if(!isDefined(time))
		time = 0.1;
	
	self fire(true);
	
	if(time)
		wait time;
		
	self fire(false);
}

/*
	Bots will hold the fire
*/
fire(what)
{
	self.bot.fire_pressed = what;
}

/*
	Bot will jump.
*/
jump()
{
	self endon("death");
	self endon("disconnect");
	level endon ( "game_ended" );

	if (self inLastStand() || self getStance() != "stand" ||
			level.gameEnded || !gameFlag( "prematch_done" ) || self IsUsingRemote() ||
			self.bot.isfrozen || self.bot.stop_move || self.bot.climbing || self.bot.jumpingafter)
			return;

	self.bot.jumping = true;
	self.bot.jumpingafter = true;

	for (i = 0; i < 6; i++)
	{
		self SetOrigin(PlayerPhysicsTrace(self.origin + (0, 0, 5), self.origin + (0, 0, 13), false, self));
		wait 0.05;
	}

	self.bot.jumping = false;

	for (i = 0; i < 6; i++)
	{
		self SetOrigin(PhysicsTrace(self.origin + (0, 0, 5), self.origin + (0, 0, -5), false, self));
		wait 0.05;
	}

	self.bot.jumpingafter = false;
}

/*
	Bot will stand.
*/
stand()
{
	if (self IsUsingRemote())
		return;

	self.bot.stance = "stand";
}

/*
	Bot will crouch.
*/
crouch()
{
	if (self IsUsingRemote())
		return;

	self.bot.stance = "crouch";
}

/*
	Bot will prone.
*/
prone()
{
	if (self IsUsingRemote())
		return;
	
	curWeap = self GetCurrentWeapon();

	if (curWeap == "riotshield_mp")
		return;

	self.bot.stance = "prone";
}

/*
	Tells the moveHack where to move
*/
botMoveTo(to)
{
	self.bot.moveTo = to;
}

/*
	Bots will start to sprint
*/
sprint()
{
	if (self.bot.run_time < 2.0)
		return;

	self.bot.running = true;
	self.bot.runningafter = true;
}

/*
	Bots will look at the pos
*/
bot_lookat(pos, time)
{
	self notify("bots_aim_overlap");
	self endon("bots_aim_overlap");
	self endon("disconnect");
	self endon("death");
	self endon("spawned_player");
	level endon ( "game_ended" );

	if (level.gameEnded || !gameFlag( "prematch_done" ) || self.bot.isfrozen)
		return;

	if (!isDefined(pos))
		return;

	steps = time / 0.05;
	if (!isDefined(steps) || steps <= 0)
		steps = 1;

	myAngle=self getPlayerAngles();
	angles = VectorToAngles( (pos - self GetEye()) - anglesToForward(myAngle) );
	
	X=(angles[0]-myAngle[0]);
	while(X > 170.0)
		X=X-360.0;
	while(X < -170.0)
		X=X+360.0;
	X=X/steps;
	
	Y=(angles[1]-myAngle[1]);
	while(Y > 180.0)
		Y=Y-360.0;
	while(Y < -180.0)
		Y=Y+360.0;
		
	Y=Y/steps;
	
	for(i=0;i<steps;i++)
	{
		myAngle=(myAngle[0]+X,myAngle[1]+Y,0);
		self setPlayerAngles(myAngle);
		wait 0.05;
	}
}

/*
	Returns if the bot is doing an active animation
*/
isInActiveAnim()
{
	if (!isDefined(self.bot_anim))
		return false;

	return (self.bot_anim.inActiveAnim);
}

/*
	returns if the bot is doing the given anim
*/
botDoingAnim(animName)
{
	if (!isDefined(self.bot_anim))
		return false;

	return (self.bot_anim.animation == animName);
}

/*
	Bot plays the anim
*/
botDoAnim(animName, time, isActiveAnim)
{
	self endon("death");
	self endon("disconnect");

	if(!isDefined(self.bot_anim))
		self makeFakeAnim();

	if (!isDefined(isActiveAnim))
		isActiveAnim = false;
	if (!isActiveAnim && self.bot_anim.inActiveAnim)
		return;

	self notify("bot_kill_anim");
	self endon("bot_kill_anim");

	self.bot_anim.inActiveAnim = isActiveAnim;
	self.bot_anim.animation = animName;
	self.bot_anim scriptModelPlayAnim(animName);

	if (isDefined(time))
		wait time;

	self.bot_anim.inActiveAnim = false;
}

/*
	Creates the anim script model
*/
makeFakeAnim()
{
	if(isDefined(self.bot_anim))
		return;

	self.bot_anim = spawn("script_model", self.origin);
	self.bot_anim setModel(self.model);
	self.bot_anim LinkTo(self, "tag_origin", (0, 0, 0), (0, 0, 0));
	self.bot_anim notsolid();
	
	self.bot_anim.headmodel = spawn( "script_model", self.bot_anim getTagOrigin( "j_spine4" ));
	self.bot_anim.headmodel setModel(self.headmodel);
	self.bot_anim.headmodel.angles = (270, 0, 270);
	self.bot_anim.headmodel linkto( self.bot_anim, "j_spine4" );
	self.bot_anim.headmodel notsolid();

	self.bot_anim.animation = undefined;
	self.bot_anim.inActiveAnim = false;
	
	self showFakeAnim();
}

/*
	Deletes the anim script model
*/
botsDeleteFakeAnim()
{
	if(!isDefined(self.bot_anim))
		return;

	self hideFakeAnim();

	self notify("bot_kill_anim");

	self.bot_anim.headmodel delete();
	self.bot_anim.headmodel = undefined;
	self.bot_anim delete();
	self.bot_anim = undefined;
}

/*
	Returns if the script model is hidden
*/
isFakeAnimHidden()
{
	if (!isDefined(self.bot_anim))
		return true;

	return (self.bot_anim.hidden);
}

/*
	Shows the anim model
*/
showFakeAnim()
{
	if(isDefined(self))
	{
		self thread maps\mp\gametypes\_weapons::detach_all_weapons();
		self botHideParts();
	}

	if(!isDefined(self.bot_anim))
		return;

	self.bot_anim show();
	self.bot_anim.hidden = false;
	self.bot_anim.headmodel show();
}

/*
	Hides the anim model
*/
hideFakeAnim()
{
	if(isDefined(self))
	{
		self botShowParts();
		self thread maps\mp\gametypes\_weapons::stowedWeaponsRefresh();
	}

	if(!isDefined(self.bot_anim))
		return;

	self.bot_anim hide();
	self.bot_anim.hidden = true;
	self.bot_anim.headmodel hide();
}

/*
	Hides the bot's model
*/
botHideParts()
{
	//hideallparts
	self hidepart("j_ankle_le");//this is the only place where bot cannot be shot at...
	self hidepart("j_hiptwist_le");
	self hidepart("j_head");
	self hidepart("j_helmet");
	self hidepart("j_eyeball_le");
	self hidepart("j_clavicle_le");
}

/*
	Shows the bot's model
*/
botShowParts()
{
	self showpart("j_ankle_le");
	self showpart("j_hiptwist_le");
	self showpart("j_head");
	self showpart("j_helmet");
	self showpart("j_eyeball_le");
	self showpart("j_clavicle_le");
	//showallparts
}
