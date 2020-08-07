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
	self.pers["bots"]["behavior"]["strafe"] = 50; // should?
	self.pers["bots"]["behavior"]["nade"] = 50;
	self.pers["bots"]["behavior"]["sprint"] = 50;
	self.pers["bots"]["behavior"]["camp"] = 50;
	self.pers["bots"]["behavior"]["follow"] = 50;
	self.pers["bots"]["behavior"]["crouch"] = 10;
	self.pers["bots"]["behavior"]["switch"] = 1;
	self.pers["bots"]["behavior"]["class"] = 1;
	self.pers["bots"]["behavior"]["jump"] = 100; // how

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
}

/*
	The callback hook for when the bot gets killed.
*/
onKilled(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration)
{
}

/*
	The callback hook when the bot gets damaged.
*/
onDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset)
{
}

/*
	We clear all of the script variables and other stuff for the bots.
*/
resetBotVars()
{
	self.bot.script_target = undefined;
	self.bot.targets = [];
	self.bot.target = undefined;
	self.bot.target_this_frame = undefined;
	
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
	
	self.bot.isfrozen = false;
	self.bot.isreloading = false;

	self.bot.isfragging = false; // gotta think about grenades
	self.bot.issmoking = false;
	self.bot.isfraggingafter = false;
	self.bot.issmokingafter = false;
	
	self.bot.semi_time = false;
	self.bot.greedy_path = false;
	self.bot.is_cur_full_auto = false;
	
	self.bot.rand = randomInt(100);

	self.bot.isswitching = false;

	self.bot.stance = "stand";

	self.bot.running = false;
	self.bot.max_run_time = getdvarfloat("scr_player_sprinttime");
	self.bot.run_time = self.bot.max_run_time;
	self.bot.run_in_delay = false;

	self.bot.fire_pressed = false;

	self.bot.ads_pressed = false;
	self.bot.ads_lowest = 9;
	self.bot.ads_tightness = self.bot.ads_lowest;
	self.bot.ads_highest = 1;

	self.bot.jumping = false;
	self.bot.jumpingafter = false;
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

		self thread adsHack();
		self thread fireHack();
		self thread stanceHack();
		self thread moveHack();

		self thread UseRunThink();
		self thread watchUsingRemote();

		// grenades (pick up too), knife (players and ents), stinger, footsounds
		
		self thread spawned();
	}
}


/*
	Bot will knife.
*/
knife()
{
}

/*
	Bot will reload.
*/
reload()
{
	cur = self GetCurrentWeapon();

	self SetWeaponAmmoStock(cur, self GetWeaponAmmoClip(cur) + self GetWeaponAmmoStock(cur));
	self setWeaponAmmoClip(cur, 0);
	// the script should reload for us.
}

/*
	Bot will hold the frag button for a time
*/
frag(time)
{
}

/*
	Bot will hold the 'smoke' button for a time.
*/
smoke(time)
{
}

/*
	Bot will jump.
*/
jump()
{
	self endon("death");
	self endon("disconnect");

	if (isDefined(self.lastStand) || self getStance() != "stand" ||
			level.gameEnded || !gameFlag( "prematch_done" ) ||
			self.bot.isfrozen || self.bot.climbing || self.bot.jumping || self.bot.jumpingafter)
			return;

	self.bot.jumping = true;
	self.bot.jumpingafter = true;

	for (i = 0; i < 6; i++)
	{
		self SetOrigin(self.origin + (0, 0, 13));
		wait 0.05;
	}

	self.bot.jumping = false;

	for (i = 0; i < 6; i++)
	{
		self SetOrigin(self.origin + (0, 0, -5));
		wait 0.05;
	}

	self.bot.jumpingafter = false;
}

/*
	Bot will stand.
*/
stand()
{
	self botSetStance("stand");
}

/*
	Bot will crouch.
*/
crouch()
{
	self botSetStance("crouch");
}

/*
	Bot will prone.
*/
prone()
{
	self botSetStance("prone");
}

botMoveTo(to)
{
	self.bot.moveTo = to;
}

sprint()
{
	if (self.bot.run_time < 2.0)
		return;

	self.bot.running = true;
}

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
			isDefined(self.lastStand) || self getStance() != "stand" ||
			level.gameEnded || !gameFlag( "prematch_done" ) ||
			self.bot.isfrozen || self.bot.climbing ||
			self.bot.isreloading ||
			self.bot.ads_pressed || self.bot.fire_pressed ||
			self.bot.isfragging || self.bot.issmoking ||
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

doRunDelay()
{
	self endon("disconnect");
	self endon("death");
	self notify("bot_run_delay");
	self endon("bot_run_delay");

	self.bot.run_in_delay = true;

	if (self _hasPerk("specialty_fastsprintrecovery"))
		wait 0.5;
	else
		wait 1;

	self.bot.run_in_delay = false;
}

bot_lookat(pos, time)
{
	self notify("bots_aim_overlap");
	self endon("bots_aim_overlap");
	self endon("disconnect");
	self endon("death");
	self endon("spawned_player");
	level endon ( "game_ended" );

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

stanceHack()
{
	self endon("disconnect");
	self endon("death");

	self SetStance(self.bot.stance);
	for (;;)
	{
		wait 0.05;

		if(isDefined(self.lastStand))
			continue;

		if (level.gameEnded || !gameFlag( "prematch_done" ))
			continue;

		if (self.bot.isfrozen)
			continue;
			
		self SetStance(self.bot.stance);
	}
}

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

		if (IsWeaponClipOnly(cur) || !self GetWeaponAmmoStock(cur) || self IsUsingRemote())
			continue;

		self thread pressFire();
	}
}

moveHack()
{
	self endon("disconnect");
	self endon("death");

	self.bot.last_pos = self.origin;
	self.bot.moveTo = self.origin;

	for (;;)
	{
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
		inLastStand = isDefined(self.lastStand);
		usingRemote = self isUsingRemote();

		if (!self.bot.climbing)
		{
			// a number between 0 and 1, 1 being totally flat, same level.    0 being totally above or below.      about 0.7 is a 45 degree angle
			verticleDegree = getConeDot(self.bot.moveTo + (1, 1, 0), self.origin  + (-1, -1, 0), VectorToAngles((self.bot.moveTo[0], self.bot.moveTo[1], self.origin[2]) - self.origin));
			self.bot.climbing = (abs(self.bot.moveTo[2] - self.origin[2]) > 50 && verticleDegree < 0.64 && !self.bot.jumpingafter);
		}

		if (inLastStand || usingRemote)
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
			moveSpeed *= 1.15;

		moveSpeed *= (getdvarfloat("g_speed")/190.0);
		moveSpeed *= self.moveSpeedScaler;

		self.bot.script_move_speed = moveSpeed;

		completedMove = false;
		if (DistanceSquared(self.origin, self.bot.moveTo) < (moveSpeed * moveSpeed))
		{
			completedMove = true;
			self SetOrigin(self.bot.moveTo);
		}

		// push out of players

		if (completedMove)
			continue;

		if (!self.bot.climbing)
		{
			self SetOrigin(self.origin + (VectorNormalize((self.bot.moveTo[0], self.bot.moveTo[1], self.origin[2])-self.origin) * moveSpeed));

			// clamp to ground
			trace = physicsTrace(self.origin + (0.0,0.0,50.0), self.origin + (0.0,0.0,-40.0));
			if(!self.bot.jumping && (trace[2] - (self.origin[2]-40.0)) > 0.0 && ((self.origin[2]+50.0) - trace[2]) > 0.0)
			{
				self SetOrigin(trace);
			}
			else
			{
				self SetOrigin(self.origin - (0,0,5));
			}

			continue;
		}
		
		self SetOrigin(self.origin + (VectorNormalize(self.bot.moveTo-self.origin) * moveSpeed));
	}
}

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

		if (self.bot.isswitching || self.bot.run_in_delay || self.bot.running)
			shouldFire = false;

		if (self.bot.isfragging || self.bot.issmoking)
			shouldFire = true;

		if (level.gameEnded || !gameFlag( "prematch_done" ))
			shouldFire = false;

		if (self.bot.isfrozen || self.bot.climbing)
			shouldFire = false;

		self FreezeControls(!shouldFire);
	}
}

adsHack()
{
	self endon("disconnect");
	self endon("spawned_player");

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
		
		switch (newWeapon)
		{
			case "none":
				if(isDefined(self.lastDroppableWeapon) && self.lastDroppableWeapon != "none")
					self setSpawnWeapon(self.lastDroppableWeapon);
			break;//grenades
			case "ac130_105mm_mp":
			case "ac130_40mm_mp":
			case "ac130_25mm_mp":
			case "heli_remote_mp":
			break;
			default:
				self thread doSwitch();
			break;
		}
	}
}

doSwitch()
{
	self endon("disconnect");
	self endon("death");
	self notify("bot_weapon_change");
	self endon("bot_weapon_change");

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

onLastStand()
{
	self endon("disconnect");
	self endon("death");

	while (true)
	{
		while (!isDefined(self.lastStand))
			wait 0.05;

		if (!isDefined(self.inFinalStand) || !self.inFinalStand)
		{
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

		while (isDefined(self.lastStand))
			wait 0.05;
	}
}

watchUsingRemote()
{
	self endon("disconnect");
	self endon("spawned_player");

	for (;;)
	{
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

		wait 1;
	}
}

watchUsingMinigun()
{
	self endon("heliPlayer_removed");

	while (isDefined(level.chopper) && isDefined(level.chopper.gunner) && level.chopper.gunner == self)
	{
		if (self getCurrentWeapon() != "heli_remote_mp")
		{
			self setspawnweapon("heli_remote_mp");
		}

		wait 0.05;
	}
}

watchAc130Weapon()
{
	self endon("ac130player_removed");
	self endon("disconnect");

	while (isDefined(level.ac130Player) && level.ac130player == self)
	{
		curWeap = self GetCurrentWeapon();

		if (curWeap != "ac130_105mm_mp" && curWeap != "ac130_40mm_mp" && curWeap != "ac130_25mm_mp")
			self setSpawnWeapon("ac130_105mm_mp");

		wait 0.05;
	}
}

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

	self thread target();
	self thread aim();
	self thread check_reload();
	self thread stance();
	self thread onNewEnemy();
	self thread walk();

	self notify("bot_spawned");
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
	
	if(isDefined(self.bot.target) || self.bot.isreloading || self.bot.isfraggingafter || self.bot.issmokingafter || self.bot.climbing)
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
				if(daDist > distsq)
				{
					if(isObjDef)
						self.bot.targets[key] = undefined;
				
					break;
				}
				
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
			
		if(!isDefined(self.bot.target.entity) || !isPlayer(self.bot.target.entity))
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
			self jump();
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
				curweap = self getCurrentWeapon();
				eyePos = self getEye();
				angles = self GetPlayerAngles();
				rand = self.bot.target.rand;
				no_trace_ads_time = self.pers["bots"]["skill"]["no_trace_ads_time"];
				reaction_time = self.pers["bots"]["skill"]["reaction_time"];
				nadeAimOffset = 0;
				myeye = self getEye();
				
				if(self.bot.isfraggingafter || self.bot.issmokingafter)
					nadeAimOffset = dist/3000;
				else if(weaponClass(curweap) == "grenade")
					nadeAimOffset = dist/16000;
				
				if(no_trace_time)
				{
					if(no_trace_time > no_trace_ads_time && !usingRemote)
					{
						self ads(false);
						
						if(isplay)
						{
							//better room to nade? cook time function with dist?
							if(!self.bot.isfraggingafter && !self.bot.issmokingafter)
							{
								nade = self getValidGrenade();
								if(isDefined(nade) && rand <= self.pers["bots"]["behavior"]["nade"] && bulletTracePassed(myEye, myEye + (0, 0, 75), false, self) && bulletTracePassed(last_pos, last_pos + (0, 0, 100), false, target)) //bots_minGrenadeDistance
								{
									if(nade == "frag_grenade_mp")
										self thread frag(2.5);
									else
										self thread smoke(0.5);
										
									self notify("kill_goal");
								}
							}
						}
						else
						{
							self stopNading();
						}
					}
					
					if (!usingRemote)
						self thread bot_lookat(last_pos + (0, 0, self getEyeHeight() + nadeAimOffset), aimspeed);
					else
						self thread bot_lookat(last_pos, aimspeed);
					continue;
				}
				
				self stopNading();
				
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
				
				if(false && isplay && conedot > 0.9 && dist < level.bots_maxKnifeDistance && trace_time > reaction_time)
				{
					self ads(false);
					self knife();
					continue;
				}
				
				if(!self canFire(curweap) || !self isInRange(dist, curweap))
				{
					self ads(false);
					continue;
				}
				
				canADS = self canAds(dist, curweap);
				self ads(canADS);

				if((!canADS || self botAdsAmount() == 1.0) && (conedot > 0.95 || dist < level.bots_maxKnifeDistance) && trace_time > reaction_time)
				{
					self botFire();
				}
				
				continue;
			}
		}
		
		self ads(false);
		self stopNading();
		
		if (!isDefined(self.bot.script_aimpos))
		{
			if (!usingRemote)
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
		else
		{
			self thread bot_lookat(self.bot.script_aimpos, aimspeed);
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
	Stop the bot from nading.
*/
stopNading()
{
	if(self.bot.isfragging)
		self thread frag(0);
	if(self.bot.issmoking)
		self thread smoke(0);
}

/*
	Returns a random grenade in the bot's inventory.
*/
getValidGrenade()
{
	grenadeTypes = [];
	grenadeTypes[grenadeTypes.size] = "frag_grenade_mp";
	grenadeTypes[grenadeTypes.size] = "smoke_grenade_mp";
	grenadeTypes[grenadeTypes.size] = "flash_grenade_mp";
	grenadeTypes[grenadeTypes.size] = "concussion_grenade_mp";
	
	possibles = [];
	
	for(i = 0; i < grenadeTypes.size; i++)
	{
		if ( !self hasWeapon( grenadeTypes[i] ) )
			continue;
			
		if ( !self getAmmoCount( grenadeTypes[i] ) )
			continue;
			
		possibles[possibles.size] = grenadeTypes[i];
	}
	
	return random(possibles);
}

/*
	Returns true if the bot can fire their current weapon.
*/
canFire(curweap)
{
	if(curweap == "none")
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
	
	if(weapclass == "spread" && dist > level.bots_maxShotgunDistance)
		return false;
		
	return true;
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
		
		if(self.bot.isfrozen)
			continue;
			
		if(self maps\mp\_flashgrenades::isFlashbanged())
		{
			self botMoveTo(self.origin + self GetBotVelocity()*self.bot.script_move_speed);
			continue;
		}
		
		hasTarget = (isDefined(self.bot.target) && isDefined(self.bot.target.entity) && !self.bot.climbing);
		if(hasTarget)
		{
			curweap = self getCurrentWeapon();
			
			if(self.bot.target.entity.classname == "script_vehicle" || self.bot.isfraggingafter || self.bot.issmokingafter)
			{
				continue;
			}
			
			if(isPlayer(self.bot.target.entity) && self.bot.target.trace_time && self canFire(curweap) && self isInRange(self.bot.target.dist, curweap))
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
			goal = (0, 0, 0);
		
		if(isDefined(self.bot.script_goal) && !hasTarget)
		{
			goal = self.bot.script_goal;
			dist = self.bot.script_goal_dist;
		}
		else
		{
			if(hasTarget)
				goal = self.bot.target.last_seen_pos;
				
			self notify("new_goal");
		}
		
		self doWalk(goal, dist);
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
	
	myOrg = self.origin + (0, 0, 16);
	left = myOrg + anglestoforward(anglesLeft)*500;
	right = myOrg + anglestoforward(anglesRight)*500;
	
	traceLeft = BulletTrace(myOrg, left, false, self);
	traceRight = BulletTrace(myOrg, right, false, self);
	
	strafe = traceLeft["position"];
	if(traceRight["fraction"] > traceLeft["fraction"])
		strafe = traceRight["position"];
	
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
		
	self notify("goal");
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
	
	self waittill_any("flash_rumble_loop", "new_enemy", "new_goal", "goal", "bad_path");
	
	self notify("kill_goal");
}

/*
	Will walk to the given goal when dist near. Uses AStar path finding with the level's nodes.
*/
doWalk(goal, dist)
{
	self endon("kill_goal");
	self endon("goal");//so that the watchOnGoal notify can happen same frame, not a frame later
	
	distsq = dist*dist;
	self thread killWalkOnEvents();
	self thread watchOnGoal(goal, distsq);
	
	current = self initAStar(goal);
	while(current >= 0)
	{
		self.bot.next_wp = self.bot.astar[current];
		self.bot.second_next_wp = -1;
		if(current != 0)
			self.bot.second_next_wp = self.bot.astar[current-1];
		
		self notify("new_static_waypoint");
		
		self movetowards(level.waypoints[self.bot.next_wp].origin);
	
		current = self removeAStar();
	}
	
	self.bot.next_wp = -1;
	self.bot.second_next_wp = -1;
	self notify("finished_static_waypoints");
	
	if(DistanceSquared(self.origin, goal) > distsq)
	{
		self movetowards(goal);
	}
	
	self notify("finished_goal");
	
	wait 1;
	if(DistanceSquared(self.origin, goal) > distsq)
		self notify("bad_path");
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
	timeslow = 0;
	time = 0;
	while(distanceSquared(self.origin, self.bot.towards_goal) > level.bots_goalDistance)
	{
		self botMoveTo(self.bot.towards_goal);
		
		if(time > 2.5)
		{
			time = 0;
			if(distanceSquared(self.origin, lastOri) < 128)
			{
				stucks++;
				
				randomDir = self getRandomLargestStafe(stucks);
			
				self botMoveTo(randomDir);
				wait stucks;
			}
			
			lastOri = self.origin;
		}
		else if(timeslow > 1.5)
		{
			self thread jump();
		}
		else if(timeslow > 0.75)
		{
			self crouch();
		}
		
		wait 0.05;
		time += 0.05;
		if(lengthsquared(self getBotVelocity()) < 1000)
			timeslow += 0.05;
		else
			timeslow = 0;
		
		if(stucks == 3)
			self notify("bad_path");
	}
	
	self.bot.towards_goal = undefined;
	self notify("completed_move_to");
}

/*
	Will return the pos of the largest trace from the bot.
*/
getRandomLargestStafe(dist)
{
	//find a better algo?
	traces = NewHeap(::HeapTraceFraction);
	myOrg = self.origin + (0, 0, 16);
	
	traces HeapInsert(bulletTrace(myOrg, myOrg + (-100*dist, 0, 0), false, self));
	traces HeapInsert(bulletTrace(myOrg, myOrg + (100*dist, 0, 0), false, self));
	traces HeapInsert(bulletTrace(myOrg, myOrg + (0, 100*dist, 0), false, self));
	traces HeapInsert(bulletTrace(myOrg, myOrg + (0, -100*dist, 0), false, self));
	traces HeapInsert(bulletTrace(myOrg, myOrg + (-100*dist, -100*dist, 0), false, self));
	traces HeapInsert(bulletTrace(myOrg, myOrg + (-100*dist, 100*dist, 0), false, self));
	traces HeapInsert(bulletTrace(myOrg, myOrg + (100*dist, -100*dist, 0), false, self));
	traces HeapInsert(bulletTrace(myOrg, myOrg + (100*dist, 100*dist, 0), false, self));
	
	toptraces = [];
	
	top = traces.data[0];
	toptraces[toptraces.size] = top;
	traces HeapRemove();
	
	while(traces.data.size && top["fraction"] - traces.data[0]["fraction"] < 0.1)
	{
		toptraces[toptraces.size] = traces.data[0];
		traces HeapRemove();
	}
	
	return toptraces[randomInt(toptraces.size)]["position"];
}
