/*
	_weapons modded
	Author: INeedGames
	Date: 09/22/2020
	Adds dropping weapon, picking up equipment and friendly fire grenade team switching exploit fix.
	Fixes the semtex 'STUCK' challenge when the thrower dies.
	Fixes claymores from tripping when the victim is elevated from the claymore.
	Fixes stuns and flashes friendly fire on claymores and c4s.
	Fixes direct impact stun stunning the victim.
	Fixes missile and grenade threads being killed on death.
	Fixes new c4s and claymores after an emp not being affected 

	DVARS:
		- scr_allowDropWeaponOnCommand <bool>
			false - (default) allows the player to drop their weapon

		- scr_allowPickUpEquipment <bool>
			false - (default) allows the player to pick up their equipment once placed

		- scr_allowDropWeaponOnDeath <bool>
			true - (default) allows player dropping their weapon on death

		- scr_allowClaymoreBounces <bool>
			true - (default) allows players to use claymores from an elevated area, and the claymore will be placed far below the player.

		- scr_extraTeamIcons <bool>
			false - (default) adds team icons to more objects such as grenades

		- scr_deleteNadeOnTeamChange <bool>
			false - (default) deletes a grenade when it's owner changes team
*/

#include common_scripts\utility;
#include maps\mp\_utility;


attachmentGroup( attachmentName )
{
	return tableLookup( "mp/attachmentTable.csv", 4, attachmentName, 2 );
}

getAttachmentList()
{
	attachmentList = [];
	
	index = 0;
	attachmentName = tableLookup( "mp/attachmentTable.csv", 9, index, 4 );
	
	while ( attachmentName != "" )
	{
		attachmentList[attachmentList.size] = attachmentName;
		
		index++;
		attachmentName = tableLookup( "mp/attachmentTable.csv", 9, index, 4 );
	}
	
	return alphabetize( attachmentList );
}

init()
{
	level.scavenger_altmode = true;
	level.scavenger_secondary = true;
	
	// 0 is not valid
	level.maxPerPlayerExplosives = max( getIntProperty( "scr_maxPerPlayerExplosives", 2 ), 1 );
	level.riotShieldXPBullets = getIntProperty( "scr_riotShieldXPBullets", 15 );

	switch ( getIntProperty( "perk_scavengerMode", 0 ) )
	{
		case 1: // disable altmode
			level.scavenger_altmode = false;
			break;

		case 2: // disable secondary
			level.scavenger_secondary = false;
			break;
			
		case 3: // disable altmode and secondary
			level.scavenger_altmode = false;
			level.scavenger_secondary = false;
			break;		
	}
	
	setDvarIfUninitialized("scr_allowDropWeaponOnCommand", false);
	setDvarIfUninitialized("scr_allowPickUpEquipment", false);
	setDvarIfUninitialized("scr_allowDropWeaponOnDeath", true);
	setDvarIfUninitialized("scr_allowClaymoreBounces", true);
	setDvarIfUninitialized("scr_extraTeamIcons", false);
	setDvarIfUninitialized("scr_deleteNadeOnTeamChange", false);
	
	level.allowDropWeaponOnCommand = getDvarInt("scr_allowDropWeaponOnCommand");
	level.allowDropWeaponOnDeath = getDvarInt("scr_allowDropWeaponOnDeath");
	level.allowPickUpEquipment = getDvarInt("scr_allowPickUpEquipment");
	level.allowExtendedClaymoreTrace = getDvarInt("scr_allowClaymoreBounces");
	level.extraTeamIcons = getDvarInt("scr_extraTeamIcons");
	level.deleteNadeOnTeamChange = getDvarInt("scr_deleteNadeOnTeamChange");
	
	attachmentList = getAttachmentList();	
	
	// assigns weapons with stat numbers from 0-149
	// attachments are now shown here, they are per weapon settings instead
	
	max_weapon_num = 149;

	level.weaponList = [];
	for( weaponId = 0; weaponId <= max_weapon_num; weaponId++ )
	{
		weapon_name = tablelookup( "mp/statstable.csv", 0, weaponId, 4 );
		if( weapon_name == "" )
			continue;
	
		if ( !isSubStr( tableLookup( "mp/statsTable.csv", 0, weaponId, 2 ), "weapon_" ) )
			continue;
			
		level.weaponList[level.weaponList.size] = weapon_name + "_mp";
		/#
		if ( getDvar( "scr_dump_weapon_assets" ) != "" )
		{
			printLn( "" );
			printLn( "// " + weapon_name + " real assets" );
			printLn( "weapon,mp/" + weapon_name + "_mp" );
		}
		#/

		// the alphabetize function is slow so we try not to do it for every weapon/attachment combo; a code solution would be better.
		attachmentNames = [];
		for ( innerLoopCount = 0; innerLoopCount < 10; innerLoopCount++ )
		{
			// generating attachment combinations
			attachmentName = tablelookup( "mp/statStable.csv", 0, weaponId, innerLoopCount + 11 );
			
			if( attachmentName == "" )
				break;
			
			attachmentNames[attachmentName] = true;
		}

		// generate an alphabetized attachment list
		attachments = [];
		foreach ( attachmentName in attachmentList )
		{
			if ( !isDefined( attachmentNames[attachmentName] ) )
				continue;
				
			level.weaponList[level.weaponList.size] = weapon_name + "_" + attachmentName + "_mp";
			attachments[attachments.size] = attachmentName;
			/#
			if ( getDvar( "scr_dump_weapon_assets" ) != "" )
				println( "weapon,mp/" + weapon_name + "_" + attachmentName + "_mp" );
			#/
		}

		attachmentCombos = [];
		for ( i = 0; i < (attachments.size - 1); i++ )
		{
			colIndex = tableLookupRowNum( "mp/attachmentCombos.csv", 0, attachments[i] );
			for ( j = i + 1; j < attachments.size; j++ )
			{
				if ( tableLookup( "mp/attachmentCombos.csv", 0, attachments[j], colIndex ) == "no" )
					continue;
					
				attachmentCombos[attachmentCombos.size] = attachments[i] + "_" + attachments[j];
			}
		}

		/#
		if ( getDvar( "scr_dump_weapon_assets" ) != "" && attachmentCombos.size )
			println( "// " + weapon_name + " virtual assets" );
		#/
		
		foreach ( combo in attachmentCombos )
		{
			/#
			if ( getDvar( "scr_dump_weapon_assets" ) != "" )
				println( "weapon,mp/" + weapon_name + "_" + combo + "_mp" );
			#/

			level.weaponList[level.weaponList.size] = weapon_name + "_" + combo + "_mp";
		}
	}

	foreach ( weaponName in level.weaponList )
	{
		precacheItem( weaponName );
		
		/#
		if ( getDvar( "scr_dump_weapon_assets" ) != "" )
		{
			altWeapon = weaponAltWeaponName( weaponName );
			if ( altWeapon != "none" )
				println( "weapon,mp/" + altWeapon );				
		}
		#/
	}

	precacheItem( "flare_mp" );
	precacheItem( "scavenger_bag_mp" );
	precacheItem( "frag_grenade_short_mp" );	
	precacheItem( "destructible_car" );
	
	precacheShellShock( "default" );
	precacheShellShock( "concussion_grenade_mp" );
	thread maps\mp\_flashgrenades::main();
	thread maps\mp\_entityheadicons::init();

	claymoreDetectionConeAngle = 70;
	level.claymoreDetectionDot = cos( claymoreDetectionConeAngle );
	level.claymoreDetectionMinDist = 20;
	level.claymoreDetectionGracePeriod = .75;
	level.claymoreDetonateRadius = 192;
	
	// this should move to _stinger.gsc
	level.stingerFXid = loadfx ("explosions/aerial_explosion_large");

	// generating weapon type arrays which classifies the weapon as primary (back stow), pistol, or inventory (side pack stow)
	// using mp/statstable.csv's weapon grouping data ( numbering 0 - 149 )
	level.primary_weapon_array = [];
	level.side_arm_array = [];
	level.grenade_array = [];
	level.inventory_array = [];
	level.stow_priority_model_array = [];
	level.stow_offset_array = [];
	
	max_weapon_num = 149;
	for( i = 0; i < max_weapon_num; i++ )
	{
		weapon = tableLookup( "mp/statsTable.csv", 0, i, 4 );
		stow_model = tableLookup( "mp/statsTable.csv", 0, i, 9 );
		
		if ( stow_model == "" )
			continue;

		precacheModel( stow_model );		

		if ( isSubStr( stow_model, "weapon_stow_" ) )
			level.stow_offset_array[ weapon ] = stow_model;
		else
			level.stow_priority_model_array[ weapon + "_mp" ] = stow_model;
	}
	
	precacheModel( "weapon_claymore_bombsquad" );
	precacheModel( "weapon_c4_bombsquad" );
	precacheModel( "projectile_m67fraggrenade_bombsquad" );
	precacheModel( "projectile_semtex_grenade_bombsquad" );
	precacheModel( "weapon_light_stick_tactical_bombsquad" );
	
	level.killStreakSpecialCaseWeapons = [];
	level.killStreakSpecialCaseWeapons["cobra_player_minigun_mp"] = true;
	level.killStreakSpecialCaseWeapons["artillery_mp"] = true;
	level.killStreakSpecialCaseWeapons["stealth_bomb_mp"] = true;
	level.killStreakSpecialCaseWeapons["pavelow_minigun_mp"] = true;
	level.killStreakSpecialCaseWeapons["sentry_minigun_mp"] = true;
	level.killStreakSpecialCaseWeapons["harrier_20mm_mp"] = true;
	level.killStreakSpecialCaseWeapons["ac130_105mm_mp"] = true;
	level.killStreakSpecialCaseWeapons["ac130_40mm_mp"] = true;
	level.killStreakSpecialCaseWeapons["ac130_25mm_mp"] = true;
	level.killStreakSpecialCaseWeapons["remotemissile_projectile_mp"] = true;
	level.killStreakSpecialCaseWeapons["cobra_20mm_mp"] = true;
	level.killStreakSpecialCaseWeapons["sentry_minigun_mp"] = true;

	
	level thread onPlayerConnect();
	
	level thread watchSentryLimit();
	
	level.c4explodethisframe = false;

	array_thread( getEntArray( "misc_turret", "classname" ), ::turret_monitorUse );
	
//	thread dumpIt();
}


watchSentryLimit()
{
	for(;;)
	{
		sentries = getentarray( "misc_turret", "classname" );
		if(sentries.size > 30)
			sentries[0] delete();
		
		wait 0.05;
	}
}


dumpIt()
{
	
	wait ( 5.0 );
	/#
	max_weapon_num = 149;

	for( weaponId = 0; weaponId <= max_weapon_num; weaponId++ )
	{
		weapon_name = tablelookup( "mp/statstable.csv", 0, weaponId, 4 );
		if( weapon_name == "" )
			continue;
	
		if ( !isSubStr( tableLookup( "mp/statsTable.csv", 0, weaponId, 2 ), "weapon_" ) )
			continue;
			
		if ( getDvar( "scr_dump_weapon_challenges" ) != "" )
		{
			/*
			sharpshooter
			marksman
			veteran
			expert
			master
			*/

			weaponLStringName = tableLookup( "mp/statsTable.csv", 0, weaponId, 3 );
			weaponRealName = tableLookupIString( "mp/statsTable.csv", 0, weaponId, 3 );

			prefix = "WEAPON_";
			weaponCapsName = getSubStr( weaponLStringName, prefix.size, weaponLStringName.size );

			weaponGroup = tableLookup( "mp/statsTable.csv", 0, weaponId, 2 );
			
			weaponGroupSuffix = getSubStr( weaponGroup, prefix.size, weaponGroup.size );

			/*
			iprintln( "REFERENCE           TITLE_" + weaponCapsName + "_SHARPSHOOTER" );
			iprintln( "LANG_ENGLISH        ", weaponRealName, ": Sharpshooter" );
			iprintln( "" );
			iprintln( "REFERENCE           TITLE_" + weaponCapsName + "_MARKSMAN" );
			iprintln( "LANG_ENGLISH        ", weaponRealName, ": Marksman" );
			iprintln( "" );
			iprintln( "REFERENCE           TITLE_" + weaponCapsName + "_VETERAN" );
			iprintln( "LANG_ENGLISH        ", weaponRealName, ": Veteran" );
			iprintln( "" );
			iprintln( "REFERENCE           TITLE_" + weaponCapsName + "_EXPERT" );
			iprintln( "LANG_ENGLISH        ", weaponRealName, ": Expert" );
			iprintln( "" );
			iprintln( "REFERENCE           TITLE_" + weaponCapsName + "_Master" );
			iprintln( "LANG_ENGLISH        ", weaponRealName, ": Master" );
			*/
			
			iprintln( "cardtitle_" + weapon_name + "_sharpshooter,PLAYERCARDS_TITLE_" + weaponCapsName + "_SHARPSHOOTER,cardtitle_" + weaponGroupSuffix + "_sharpshooter,1,1,1" );
			iprintln( "cardtitle_" + weapon_name + "_marksman,PLAYERCARDS_TITLE_" + weaponCapsName + "_MARKSMAN,cardtitle_" + weaponGroupSuffix + "_marksman,1,1,1" );
			iprintln( "cardtitle_" + weapon_name + "_veteran,PLAYERCARDS_TITLE_" + weaponCapsName + "_VETERAN,cardtitle_" + weaponGroupSuffix + "_veteran,1,1,1" );
			iprintln( "cardtitle_" + weapon_name + "_expert,PLAYERCARDS_TITLE_" + weaponCapsName + "_EXPERT,cardtitle_" + weaponGroupSuffix + "_expert,1,1,1" );
			iprintln( "cardtitle_" + weapon_name + "_master,PLAYERCARDS_TITLE_" + weaponCapsName + "_MASTER,cardtitle_" + weaponGroupSuffix + "_master,1,1,1" );
			
			wait ( 0.05 );
		}
	}
	#/
}

bombSquadWaiter()
{
	self endon ( "disconnect" );
	
	for ( ;; )
	{
		self waittill ( "grenade_fire", weaponEnt, weaponName );
		
		team = level.otherTeam[self.team];
		
		if ( weaponName == "c4_mp" )
			weaponEnt thread createBombSquadModel( "weapon_c4_bombsquad", "tag_origin", team, self );
		else if ( weaponName == "claymore_mp" )
			weaponEnt thread createBombSquadModel( "weapon_claymore_bombsquad", "tag_origin", team, self );
		else if ( weaponName == "frag_grenade_mp" )
			weaponEnt thread createBombSquadModel( "projectile_m67fraggrenade_bombsquad", "tag_weapon", team, self );
		else if ( weaponName == "frag_grenade_short_mp" )
			weaponEnt thread createBombSquadModel( "projectile_m67fraggrenade_bombsquad", "tag_weapon", team, self );
		else if ( weaponName == "semtex_mp" )
			weaponEnt thread createBombSquadModel( "projectile_semtex_grenade_bombsquad", "tag_weapon", team, self );
	}
}


createBombSquadModel( modelName, tagName, teamName, owner )
{
	bombSquadModel = spawn( "script_model", (0,0,0) );
	bombSquadModel hide();
	wait ( 0.05 );
	
	if (!isDefined( self ) ) //grenade model may not be around if picked up
		return;
		
	bombSquadModel thread bombSquadVisibilityUpdater( teamName, owner );
	bombSquadModel setModel( modelName );
	bombSquadModel linkTo( self, tagName, (0,0,0), (0,0,0) );
	bombSquadModel SetContents( 0 );
	
	self waittill ( "death" );
	
	bombSquadModel delete();
}


bombSquadVisibilityUpdater( teamName, owner )
{
	self endon ( "death" );

	foreach ( player in level.players )
	{
		if ( level.teamBased )
		{
			if ( player.team == teamName && player _hasPerk( "specialty_detectexplosive" ) )
				self showToPlayer( player );
		}
		else
		{
			if ( isDefined( owner ) && player == owner )
				continue;
			
			if ( !player _hasPerk( "specialty_detectexplosive" ) )
				continue;
				
			self showToPlayer( player );
		}		
	}
	
	for ( ;; )
	{
		level waittill_any( "joined_team", "player_spawned", "changed_kit" );
		
		self hide();

		foreach ( player in level.players )
		{
			if ( level.teamBased )
			{
				if ( player.team == teamName && player _hasPerk( "specialty_detectexplosive" ) )
					self showToPlayer( player );
			}
			else
			{
				if ( isDefined( owner ) && player == owner )
					continue;
				
				if ( !player _hasPerk( "specialty_detectexplosive" ) )
					continue;
					
				self showToPlayer( player );
			}		
		}
	}
}


onPlayerConnect()
{
	for(;;)
	{
		level waittill("connected", player);

		player.hits = 0;
		player.hasDoneCombat = false;

		player KC_RegWeaponForFXRemoval( "remotemissile_projectile_mp" );

		player thread onPlayerSpawned();
		player thread bombSquadWaiter();
		player thread monitorSemtex();
	}
}


onPlayerSpawned()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("spawned_player");
		
		self.currentWeaponAtSpawn = self getCurrentWeapon(); // optimization so these threads we start don't have to call it.
		
		self.empEndTime = 0;
		self.concussionEndTime = 0;
		self.hasDoneCombat = false;
		self thread watchWeaponUsage();
		self thread watchGrenadeUsage();
		self thread watchWeaponChange();
		self thread watchStingerUsage();
		self thread watchJavelinUsage();
		self thread watchMissileUsage();
		self thread watchSentryUsage();
		self thread watchWeaponReload();
		self thread maps\mp\gametypes\_class::trackRiotShield();
		self thread watchDropWeaponOnCommand();

		self.lastHitTime = [];
		
		self.droppedDeathWeapon = undefined;
		self.tookWeaponFrom = [];
		
		self thread updateStowedWeapon();
		
		self thread updateSavedLastWeapon();
		
		self.currentWeaponAtSpawn = undefined;
	}
}

watchDropWeaponOnCommand()
{
	if( !level.allowDropWeaponOnCommand )
		return;
	
	self endon( "disconnect" );
	self endon( "death" );
	
	self notifyOnPlayerCommand( "drop_weapon_on_cmd", "+actionslot 2" );
	for(;;)
	{
		self waittill( "drop_weapon_on_cmd" );
		weapon = self GetCurrentWeapon();

		if ( !gameFlag( "prematch_done" ) || !isDefined( weapon ) )
			continue;

		if( level.gameEnded )
			continue;

		if( !mayDropWeapon( weapon ) )
			continue;

		if ( !self hasWeapon( weapon ) )      
			continue;

		if ( weapon != "riotshield_mp" )
		{
			if ( !(self AnyAmmoForWeaponModes( weapon )) )
			{
				continue;
			}

			clipAmmoR = self GetWeaponAmmoClip( weapon, "right" );
			clipAmmoL = self GetWeaponAmmoClip( weapon, "left" );
			if ( !clipAmmoR && !clipAmmoL )
			{
				continue;
			}

			stockAmmo = self GetWeaponAmmoStock( weapon );
			stockMax = WeaponMaxAmmo( weapon );
			if ( stockAmmo > stockMax )
				stockAmmo = stockMax;

			item = self dropItem( weapon );
			item ItemWeaponSetAmmo( clipAmmoR, stockAmmo, clipAmmoL );
		}
		else
		{
			item = self dropItem( weapon );   
			if ( !isDefined( item ) )
				continue;
			item ItemWeaponSetAmmo( 1, 1, 0 );
		}
		item.owner = self;

		item thread maps\mp\gametypes\_weapons::watchPickup();

		//deletes dropped weapon after 30 sec.
		item thread maps\mp\gametypes\_weapons::deletePickupAfterAWhile();

		detach_model = getWeaponModel( weapon );

		if ( !isDefined( detach_model ) )
			continue;

		if( isDefined( self.tag_stowed_back ) && detach_model == self.tag_stowed_back )
			self maps\mp\gametypes\_weapons::detach_back_weapon();

		if ( !isDefined( self.tag_stowed_hip ) )
			continue;

		if( detach_model == self.tag_stowed_hip )
			self maps\mp\gametypes\_weapons::detach_hip_weapon();
	}
}

WatchStingerUsage()
{
	self maps\mp\_stinger::StingerUsageLoop();
}


WatchJavelinUsage()
{
	self maps\mp\_javelin::JavelinUsageLoop();
}

watchWeaponChange()
{
	self endon("death");
	self endon("disconnect");
	
	self thread watchStartWeaponChange();
	self.lastDroppableWeapon = self.currentWeaponAtSpawn;
	self.hitsThisMag = [];

	weapon = self getCurrentWeapon();
	
	if ( isCACPrimaryWeapon( weapon ) && !isDefined( self.hitsThisMag[ weapon ] ) )
		self.hitsThisMag[ weapon ] = weaponClipSize( weapon );

	self.bothBarrels = undefined;

	if ( isSubStr( weapon, "ranger" ) )
		self thread watchRangerUsage( weapon );

	while(1)
	{
		self waittill( "weapon_change", newWeapon );
		
		tokedNewWeapon = StrTok( newWeapon, "_" );

		self.bothBarrels = undefined;

		if ( isSubStr( newWeapon, "ranger" ) )
			self thread watchRangerUsage( newWeapon );

		if ( tokedNewWeapon[0] == "gl" || ( tokedNewWeapon.size > 2 && tokedNewWeapon[2] == "attach" ) )
			newWeapon = self getCurrentPrimaryWeapon();

		if ( newWeapon != "none" )
		{
			if ( isCACPrimaryWeapon( newWeapon ) && !isDefined( self.hitsThisMag[ newWeapon ] ) )
				self.hitsThisMag[ newWeapon ] = weaponClipSize( newWeapon );
		}
		self.changingWeapon = undefined;
		if ( mayDropWeapon( newWeapon ) )
			self.lastDroppableWeapon = newWeapon;
	}
}


watchStartWeaponChange()
{
	self endon("death");
	self endon("disconnect");
	self.changingWeapon = undefined;

	while(1)
	{
		self waittill( "weapon_switch_started", newWeapon );
		self.changingWeapon = newWeapon;
	}
}

watchWeaponReload()
{
	self endon("death");
	self endon("disconnect");

	for ( ;; )
	{
		self waittill( "reload" );

		weaponName = self getCurrentWeapon();

		self.bothBarrels = undefined;
		
		if ( !isSubStr( weaponName, "ranger" ) )
			continue;

		self thread watchRangerUsage( weaponName );
	}
}


watchRangerUsage( rangerName )
{
	rightAmmo = self getWeaponAmmoClip( rangerName, "right" );
	leftAmmo = self getWeaponAmmoClip( rangerName, "left" );

	self endon ( "reload" );
	self endon ( "weapon_change" );

	for ( ;; )
	{
		self waittill ( "weapon_fired", weaponName );
		
		if ( weaponName != rangerName )
			continue;

		self.bothBarrels = undefined;

		if ( isSubStr( rangerName, "akimbo" ) )
		{
			newLeftAmmo = self getWeaponAmmoClip( rangerName, "left" );
			newRightAmmo = self getWeaponAmmoClip( rangerName, "right" );

			if ( leftAmmo != newLeftAmmo && rightAmmo != newRightAmmo )
				self.bothBarrels = true;
			
			if ( !newLeftAmmo || !newRightAmmo )
				return;
				
				
			leftAmmo = newLeftAmmo;
			rightAmmo = newRightAmmo;
		}
		else if ( rightAmmo == 2 && !self getWeaponAmmoClip( rangerName, "right" ) )
		{
			self.bothBarrels = true;
			return;
		}
	}
}


isHackWeapon( weapon )
{
	if ( weapon == "radar_mp" || weapon == "airstrike_mp" || weapon == "helicopter_mp" )
		return true;
	if ( weapon == "briefcase_bomb_mp" )
		return true;
	return false;
}


mayDropWeapon( weapon )
{
	if ( weapon == "none" )
		return false;
		
	if ( isSubStr( weapon, "ac130" ) )
		return false;

	invType = WeaponInventoryType( weapon );
	if ( invType != "primary" )
		return false;
	
	return true;
}

dropWeaponForDeath( attacker )
{
	if( !level.allowDropWeaponOnDeath )
		return;
	
	weapon = self.lastDroppableWeapon;
	
	if ( isdefined( self.droppedDeathWeapon ) )
		return;

	if ( level.inGracePeriod )
		return;
	
	if ( !isdefined( weapon ) )
	{
		/#
		if ( getdvar("scr_dropdebug") == "1" )
			println( "didn't drop weapon: not defined" );
		#/
		return;
	}
	
	if ( weapon == "none" )
	{
		/#
		if ( getdvar("scr_dropdebug") == "1" )
			println( "didn't drop weapon: weapon == none" );
		#/
		return;
	}
	
	if ( !self hasWeapon( weapon ) )
	{
		/#
		if ( getdvar("scr_dropdebug") == "1" )
			println( "didn't drop weapon: don't have it anymore (" + weapon + ")" );
		#/
		return;
	}
	
	if ( weapon != "riotshield_mp" )
	{
		if ( !(self AnyAmmoForWeaponModes( weapon )) )
		{
			/#
			if ( getdvar("scr_dropdebug") == "1" )
			  println( "didn't drop weapon: no ammo for weapon modes" );
			#/
			return;
		}

		clipAmmoR = self GetWeaponAmmoClip( weapon, "right" );
		clipAmmoL = self GetWeaponAmmoClip( weapon, "left" );
		if ( !clipAmmoR && !clipAmmoL )
		{
			/#
			if ( getdvar("scr_dropdebug") == "1" )
			  println( "didn't drop weapon: no ammo in clip" );
			#/
			return;
		}
  
		stockAmmo = self GetWeaponAmmoStock( weapon );
		stockMax = WeaponMaxAmmo( weapon );
		if ( stockAmmo > stockMax )
			stockAmmo = stockMax;

		item = self dropItem( weapon );
		item ItemWeaponSetAmmo( clipAmmoR, stockAmmo, clipAmmoL );
	}
	else
	{
		item = self dropItem( weapon );	
		if ( !isDefined( item ) )
			return;
		item ItemWeaponSetAmmo( 1, 1, 0 );
	}

	/#
	if ( getdvar("scr_dropdebug") == "1" )
		println( "dropped weapon: " + weapon );
	#/

	self.droppedDeathWeapon = true;

	item.owner = self;
	item.ownersattacker = attacker;

	item thread watchPickup();

	item thread deletePickupAfterAWhile();

	detach_model = getWeaponModel( weapon );

	if ( !isDefined( detach_model ) )
		return;

	if( isDefined( self.tag_stowed_back ) && detach_model == self.tag_stowed_back )
		self detach_back_weapon();

	if ( !isDefined( self.tag_stowed_hip ) )
		return;

	if( detach_model == self.tag_stowed_hip )
		self detach_hip_weapon();
}


detachIfAttached( model, baseTag )
{
	attachSize = self getAttachSize();
	
	for ( i = 0; i < attachSize; i++ )
	{
		attach = self getAttachModelName( i );
		
		if ( attach != model )
			continue;
		
		tag = self getAttachTagName( i );			
		self detach( model, tag );
		
		if ( tag != baseTag )
		{
			attachSize = self getAttachSize();
			
			for ( i = 0; i < attachSize; i++ )
			{
				tag = self getAttachTagName( i );
				
				if ( tag != baseTag )
					continue;
					
				model = self getAttachModelName( i );
				self detach( model, tag );
				
				break;
			}
		}		
		return true;
	}
	return false;
}


deletePickupAfterAWhile()
{
	self endon("death");
	
	wait 60;

	if ( !isDefined( self ) )
		return;

	self delete();
}

getItemWeaponName()
{
	classname = self.classname;
	assert( getsubstr( classname, 0, 7 ) == "weapon_" );
	weapname = getsubstr( classname, 7 );
	return weapname;
}

watchPickup()
{
	self endon("death");
	
	weapname = self getItemWeaponName();
	
	while(1)
	{
		self waittill( "trigger", player, droppedItem );
		
		if ( isdefined( droppedItem ) )
			break;
		// otherwise, player merely acquired ammo and didn't pick this up
	}
	
	/#
	if ( getdvar("scr_dropdebug") == "1" )
		println( "picked up weapon: " + weapname + ", " + isdefined( self.ownersattacker ) );
	#/

	assert( isdefined( player.tookWeaponFrom ) );
	
	// make sure the owner information on the dropped item is preserved
	droppedWeaponName = droppedItem getItemWeaponName();
	if ( isdefined( player.tookWeaponFrom[ droppedWeaponName ] ) )
	{
		droppedItem.owner = player.tookWeaponFrom[ droppedWeaponName ];
		droppedItem.ownersattacker = player;
		player.tookWeaponFrom[ droppedWeaponName ] = undefined;
	}
	droppedItem thread watchPickup();
	
	// take owner information from self and put it onto player
	if ( isdefined( self.ownersattacker ) && self.ownersattacker == player )
	{
		player.tookWeaponFrom[ weapname ] = self.owner;
	}
	else
	{
		player.tookWeaponFrom[ weapname ] = undefined;
	}
}

itemRemoveAmmoFromAltModes()
{
	origweapname = self getItemWeaponName();
	
	curweapname = weaponAltWeaponName( origweapname );
	
	altindex = 1;
	while ( curweapname != "none" && curweapname != origweapname )
	{
		self itemWeaponSetAmmo( 0, 0, 0, altindex );
		curweapname = weaponAltWeaponName( curweapname );
		altindex++;
	}
}


handleScavengerBagPickup( scrPlayer )
{
	self endon( "death" );
	level endon ( "game_ended" );

	assert( isDefined( scrPlayer ) );

	// Wait for the pickup to happen
	self waittill( "scavenger", destPlayer );
	assert( isDefined ( destPlayer ) );

	destPlayer notify( "scavenger_pickup" );
	destPlayer playLocalSound( "scavenger_pack_pickup" );
	
	offhandWeapons = destPlayer getWeaponsListOffhands();
	
	if ( destPlayer _hasPerk( "specialty_tacticalinsertion" ) && destPlayer getAmmoCount( "flare_mp" ) < 1 )
		destPlayer _setPerk( "specialty_tacticalinsertion");	
		
	foreach ( offhand in offhandWeapons )
	{		
		currentClipAmmo = destPlayer GetWeaponAmmoClip( offhand );
		destPlayer SetWeaponAmmoClip( offhand, currentClipAmmo + 1);
	}

	primaryWeapons = destPlayer getWeaponsListPrimaries();	
	foreach ( primary in primaryWeapons )
	{
		if ( !isCACPrimaryWeapon( primary ) && !level.scavenger_secondary )
			continue;
			
		currentStockAmmo = destPlayer GetWeaponAmmoStock( primary );
		addStockAmmo = weaponClipSize( primary );
		
		destPlayer setWeaponAmmoStock( primary, currentStockAmmo + addStockAmmo );

		altWeapon = weaponAltWeaponName( primary );

		if ( !isDefined( altWeapon ) || (altWeapon == "none") || !level.scavenger_altmode )
			continue;

		currentStockAmmo = destPlayer GetWeaponAmmoStock( altWeapon );
		addStockAmmo = weaponClipSize( altWeapon );

		destPlayer setWeaponAmmoStock( altWeapon, currentStockAmmo + addStockAmmo );
	}

	destPlayer maps\mp\gametypes\_damagefeedback::updateDamageFeedback( "scavenger" );
}


dropScavengerForDeath( attacker )
{
	if ( level.inGracePeriod )
		return;
	
 	if( !isDefined( attacker ) )
 		return;

 	if( attacker == self )
 		return;

	dropBag = self dropScavengerBag( "scavenger_bag_mp" );	
	dropBag thread handleScavengerBagPickup( self );

}

getWeaponBasedGrenadeCount(weapon)
{
	return 2;
}

getWeaponBasedSmokeGrenadeCount(weapon)
{
	return 1;
}

getFragGrenadeCount()
{
	grenadetype = "frag_grenade_mp";

	count = self getammocount(grenadetype);
	return count;
}

getSmokeGrenadeCount()
{
	grenadetype = "smoke_grenade_mp";

	count = self getammocount(grenadetype);
	return count;
}


watchWeaponUsage( weaponHand )
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon ( "game_ended" );
	
	for ( ;; )
	{	
		self waittill ( "weapon_fired", weaponName );

		self.hasDoneCombat = true;

		if ( !maps\mp\gametypes\_weapons::isPrimaryWeapon( weaponName ) && !maps\mp\gametypes\_weapons::isSideArm( weaponName ) )
			continue;
		
		if ( isDefined( self.hitsThisMag[ weaponName ] ) )
			self thread updateMagShots( weaponName );
			
		totalShots = self maps\mp\gametypes\_persistence::statGetBuffered( "totalShots" ) + 1;
		hits = self maps\mp\gametypes\_persistence::statGetBuffered( "hits" );
		self maps\mp\gametypes\_persistence::statSetBuffered( "totalShots", totalShots );
		self maps\mp\gametypes\_persistence::statSetBuffered( "accuracy", int(hits * 10000 / totalShots) );		
		self maps\mp\gametypes\_persistence::statSetBuffered( "misses", int(totalShots - hits) );
	}
}


updateMagShots( weaponName )
{
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( "updateMagShots_" + weaponName );
	
	self.hitsThisMag[ weaponName ]--;
	
	wait ( 0.05 );
	
	self.hitsThisMag[ weaponName ] = weaponClipSize( weaponName );
}


checkHitsThisMag( weaponName )
{
	self endon ( "death" );
	self endon ( "disconnect" );

	self notify ( "updateMagShots_" + weaponName );
	waittillframeend;
	
	if ( self.hitsThisMag[ weaponName ] == 0 )
	{
		weaponClass = getWeaponClass( weaponName );
		
		maps\mp\gametypes\_missions::genericChallenge( weaponClass );

		self.hitsThisMag[ weaponName ] = weaponClipSize( weaponName );
	}	
}


checkHit( weaponName, victim )
{
	if ( !maps\mp\gametypes\_weapons::isPrimaryWeapon( weaponName ) && !maps\mp\gametypes\_weapons::isSideArm( weaponName ) )
		return;

	// sometimes the "weapon_fired" notify happens after we hit the guy...
	waittillframeend;

	if ( isDefined( self.hitsThisMag[ weaponName ] ) )
		self thread checkHitsThisMag( weaponName );

	if ( !isDefined( self.lastHitTime[ weaponName ] ) )
		self.lastHitTime[ weaponName ] = 0;
		
	// already hit with this weapon on this frame
	if ( self.lastHitTime[ weaponName ] == getTime() )
		return;

	self.lastHitTime[ weaponName ] = getTime();

	totalShots = self maps\mp\gametypes\_persistence::statGetBuffered( "totalShots" );		
	hits = self maps\mp\gametypes\_persistence::statGetBuffered( "hits" ) + 1;

	if ( hits <= totalShots )
	{
		self maps\mp\gametypes\_persistence::statSetBuffered( "hits", hits );
		self maps\mp\gametypes\_persistence::statSetBuffered( "misses", int(totalShots - hits) );
		self maps\mp\gametypes\_persistence::statSetBuffered( "accuracy", int(hits * 10000 / totalShots) );
	}
}


attackerCanDamageItem( attacker, itemOwner )
{
	return friendlyFireCheck( itemOwner, attacker );
}

// returns true if damage should be done to the item given its owner and the attacker
friendlyFireCheck( owner, attacker, forcedFriendlyFireRule )
{
	if ( !isdefined( owner ) )// owner has disconnected? allow it
		return true;

	if ( !level.teamBased )// not a team based mode? allow it
		return true;

	attackerTeam = attacker.team;

	friendlyFireRule = level.friendlyfire;
	if ( isdefined( forcedFriendlyFireRule ) )
		friendlyFireRule = forcedFriendlyFireRule;

	if ( friendlyFireRule != 0 )// friendly fire is on? allow it
		return true;

	if ( attacker == owner )// owner may attack his own items
		return true;

	if ( !isdefined( attackerTeam ) )// attacker not on a team? allow it
		return true;

	if ( attackerTeam != owner.team )// attacker not on the same team as the owner? allow it
		return true;

	return false;// disallow it
}

watchGrenadeUsage()
{
	self endon( "spawned_player" );
	self endon( "disconnect" );

	self.throwingGrenade = undefined;
	self.gotPullbackNotify = false;

	if ( getIntProperty( "scr_deleteexplosivesonspawn", 1 ) == 1 )
	{
		// delete c4 from previous spawn
		if ( isdefined( self.c4array ) )
		{
			for ( i = 0; i < self.c4array.size; i++ )
			{
				if ( isdefined( self.c4array[ i ] ) )
					self.c4array[ i ] delete();
			}
		}
		self.c4array = [];
		// delete claymores from previous spawn
		if ( isdefined( self.claymorearray ) )
		{
			for ( i = 0; i < self.claymorearray.size; i++ )
			{
				if ( isdefined( self.claymorearray[ i ] ) )
					self.claymorearray[ i ] delete();
			}
		}
		self.claymorearray = [];
	}
	else
	{
		if ( !isdefined( self.c4array ) )
			self.c4array = [];
		if ( !isdefined( self.claymorearray ) )
			self.claymorearray = [];
	}

	thread watchC4();
	thread watchC4Detonation();
	thread watchC4AltDetonation();
	thread watchClaymores();
	thread deleteC4AndClaymoresOnDisconnect();

	self thread watchForThrowbacks();

	for ( ;; )
	{
		self waittill( "grenade_pullback", weaponName );

		self.hasDoneCombat = true;

		if ( weaponName == "claymore_mp" )
			continue;

		self.throwingGrenade = weaponName;
		self.gotPullbackNotify = true;
		
		if ( weaponName == "c4_mp" )
			self beginC4Tracking();
		else
			self beginGrenadeTracking();
			
		self.throwingGrenade = undefined;
	}
}

deleteOnOwnerTeamChange( owner )
{
	self notify( "delete_on_team_overlap" );
	self endon( "delete_on_team_overlap" );
	
	self endon( "death" );
	
	owner waittill_any( "disconnect", "joined_team", "joined_spectators" );
	
	self delete();
}

beginGrenadeTracking()
{
	self endon( "spawned_player" );
	self endon( "disconnect" );
	self endon( "offhand_end" );
	self endon( "weapon_change" );

	startTime = getTime();

	self waittill( "grenade_fire", grenade, weaponName );

	if ( ( getTime() - startTime > 1000 ) && weaponName == "frag_grenade_mp" )
		grenade.isCooked = true;

	self.changingWeapon = undefined;
	
	grenade.owner = self;
	
	switch( weaponName )
	{
		case "frag_grenade_mp":
		case "semtex_mp":
			grenade thread maps\mp\gametypes\_shellshock::grenade_earthQuake();
			grenade.originalOwner = self;
			
			if ( level.deleteNadeOnTeamChange )
				grenade thread deleteOnOwnerTeamChange( self );
			
			if( level.extraTeamIcons )
				grenade thread setClaymoreTeamHeadIcon( self.pers[ "team" ] );
			break;
		case "flash_grenade_mp":
		case "concussion_grenade_mp":
			grenade thread empExplodeWaiter();
			
			if ( level.deleteNadeOnTeamChange )
				grenade thread deleteOnOwnerTeamChange( self );
			
			if( level.extraTeamIcons )
				grenade thread setClaymoreTeamHeadIcon( self.pers[ "team" ] );
			break;
		case "smoke_grenade_mp":
			if( level.extraTeamIcons )
				grenade thread setClaymoreTeamHeadIcon( self.pers[ "team" ] );
			break;
		case "throwingknife_mp":
			if ( level.deleteNadeOnTeamChange )
				grenade thread deleteOnOwnerTeamChange( self );
			
			if( level.extraTeamIcons )
				grenade thread setClaymoreTeamHeadIcon( self.pers[ "team" ] );
			break;
	}
}

AddMissileToSightTraces( team )
{
	self.team = team;
	level.missilesForSightTraces[ level.missilesForSightTraces.size ] = self;
	
	self waittill( "death" );
	
	newArray = [];
	foreach( missile in level.missilesForSightTraces )
	{
		if ( missile != self )
			newArray[ newArray.size ] = missile;
	}
	level.missilesForSightTraces = newArray;
}

watchMissileUsage()
{
	self endon( "spawned_player" );
	self endon( "disconnect" );

	for ( ;; )
	{
		self waittill( "missile_fire", missile, weaponName );
		
		if ( isSubStr( weaponName, "gl_" ) )
		{
			missile.primaryWeapon = self getCurrentPrimaryWeapon();
			missile thread maps\mp\gametypes\_shellshock::grenade_earthQuake();
		}

		switch ( weaponName )
		{
			case "at4_mp":
			case "stinger_mp":
				level notify ( "stinger_fired", self, missile, self.stingerTarget );
				self thread setAltSceneObj( missile, "tag_origin", 65 );
				break;
			case "javelin_mp":
				level notify ( "stinger_fired", self, missile, self.javelinTarget );
				self thread setAltSceneObj( missile, "tag_origin", 65 );
				break;			
			default:
				break;
		}

		switch ( weaponName )
		{
			case "at4_mp":
			case "javelin_mp":
			case "rpg_mp":
			case "ac130_105mm_mp":
			case "ac130_40mm_mp":
			case "remotemissile_projectile_mp":
				missile thread maps\mp\gametypes\_shellshock::grenade_earthQuake();
			default:
				break;
		}
		if( level.extraTeamIcons && weaponName != "remotemissile_projectile_mp" )
			missile thread setClaymoreTeamHeadIcon( self.pers[ "team" ] );
		if ( level.deleteNadeOnTeamChange )
			missile thread deleteOnOwnerTeamChange( self );
	}
}


watchSentryUsage()
{
	self endon( "death" );
	self endon( "disconnect" );

	for ( ;; )
	{
		self waittill( "sentry_placement_finished", sentry );
		
		self thread setAltSceneObj( sentry, "tag_flash", 65 );
	}
}


empExplodeWaiter()
{
	self thread maps\mp\gametypes\_shellshock::endOnDeath();
	self endon( "end_explode" );

	self waittill( "explode", position );

	ents = getEMPDamageEnts( position, 512, false );

	foreach ( ent in ents )
	{
		if ( isDefined( ent.owner ) && !friendlyFireCheck( self.owner, ent.owner ) )
			continue;

		ent notify( "emp_damage", self.owner, 8.0 );
	}
}


beginC4Tracking()
{
	self endon( "spawned_player" );
	self endon( "disconnect" );

	self waittill_any( "grenade_fire", "weapon_change", "offhand_end" );
}


watchForThrowbacks()
{
	self endon( "spawned_player" );
	self endon( "disconnect" );

	for ( ;; )
	{
		self waittill( "grenade_fire", grenade, weapname );
		
		if ( self.gotPullbackNotify )
		{
			self.gotPullbackNotify = false;
			continue;
		}
		if ( !isSubStr( weapname, "frag_" ) && !isSubStr( weapname, "semtex_" ) )
			continue;

		// no grenade_pullback notify! we must have picked it up off the ground.
		grenade.threwBack = true;
		self thread incPlayerStat( "throwbacks", 1 );

		grenade thread maps\mp\gametypes\_shellshock::grenade_earthQuake();
		grenade.originalOwner = self;
		
		if( level.extraTeamIcons )
			grenade thread setClaymoreTeamHeadIcon( self.pers[ "team" ] );
		if ( level.deleteNadeOnTeamChange )
			grenade thread deleteOnOwnerTeamChange( self );
	}
}


watchC4()
{
	self endon( "spawned_player" );
	self endon( "disconnect" );

	//maxc4 = 2;

	while ( 1 )
	{
		self waittill( "grenade_fire", c4, weapname );
		if ( weapname == "c4" || weapname == "c4_mp" )
		{
			if ( !self.c4array.size )
				self thread watchC4AltDetonate();

			if ( self.c4array.size )
			{
				self.c4array = array_removeUndefined( self.c4array );
				
				if( self.c4array.size >= level.maxPerPlayerExplosives )
				{
					self.c4array[0] detonate();
				}
			}

			self.c4array[ self.c4array.size ] = c4;
			c4.owner = self;
			c4.team = self.team;
			c4.activated = false;
			c4.weaponName = weapname;

			c4 thread maps\mp\gametypes\_shellshock::c4_earthQuake();
			c4 thread c4Activate();
			c4 thread c4Damage();
			c4 thread c4EMPDamage();
			c4 thread c4EMPKillstreakWait();
			if( level.extraTeamIcons )
				c4 thread setClaymoreTeamHeadIcon( self.pers[ "team" ] );
			//c4 thread c4DetectionTrigger( self.pers[ "team" ] );
			c4 thread c4WatchPickup();
			if ( level.deleteNadeOnTeamChange )
				c4 thread deleteOnOwnerTeamChange( self );
		}
	}
}


c4EMPDamage()
{
	self endon( "death" );

	for ( ;; )
	{
		self waittill( "emp_damage", attacker, duration );

		if ( isPlayer(attacker) && !friendlyFireCheck( self.owner, attacker ) )
			continue;
		
		playfxOnTag( getfx( "sentry_explode_mp" ), self, "tag_origin" );

		self.disabled = true;
		self notify( "disabled" );

		wait( duration );

		self.disabled = undefined;
		self notify( "enabled" );
	}
}


c4EMPKillstreakWait()
{
	self endon( "death" );

	if ( (level.teamBased && level.teamEMPed[self.team]) || (!level.teamBased && isDefined( level.empPlayer ) && level.empPlayer != self.owner ) )
	{
		playfxOnTag( getfx( "sentry_explode_mp" ), self, "tag_origin" );
		
		self.disabled = true;
		self notify( "disabled" );
	}

	for ( ;; )
	{
		level waittill( "emp_update" );

		if ( (level.teamBased && level.teamEMPed[self.team]) || (!level.teamBased && isDefined( level.empPlayer ) && level.empPlayer != self.owner ) )
		{
			playfxOnTag( getfx( "sentry_explode_mp" ), self, "tag_origin" );

			self.disabled = true;
			self notify( "disabled" );
		}
		else
		{
			self.disabled = undefined;
			self notify( "enabled" );
		}
	}
}

deleteTeamHeadIconOnUndefined(ent, hud)
{
	ent endon( "death" );
	
	while ( isDefined(ent) )
		wait 0.05;
	
	hud destroy();
	hud = undefined;
	ent notify( "kill_entity_headicon_thread" );
}

setClaymoreTeamHeadIcon( team )
{
	self endon( "death" );
	
	if ( isDefined( self.weaponname ) && self.weaponname == "claymore_mp" && !level.allowExtendedClaymoreTrace )
	{
		self waittill( "missile_stuck" );
		self waittill( "claymore_trace_fixed" );
	}
	else
		wait 0.05;

	if ( !isDefined( self ) )
		return;
	
	if ( isDefined( self.entityHeadIcon ) )
	{
		self.entityHeadIconTeam = "none";
		self.entityHeadIcon destroy();
		self.entityHeadIcon = undefined;
		self notify( "kill_entity_headicon_thread" );
	}
	
	if ( level.teamBased )
		self maps\mp\_entityheadicons::setTeamHeadIcon( team, ( 0, 0, 20 ) );
	else if ( isDefined( self.owner ) )
		self maps\mp\_entityheadicons::setPlayerHeadIcon( self.owner, (0,0,20) );
	
	thread deleteTeamHeadIconOnUndefined(self, self.entityHeadIcon);
}


watchClaymores()
{
	self endon( "spawned_player" );
	self endon( "disconnect" );

	while ( 1 )
	{
		self waittill( "grenade_fire", claymore, weapname );
		if ( weapname == "claymore" || weapname == "claymore_mp" )
		{
			self.claymorearray = array_removeUndefined( self.claymorearray );
			
			if( self.claymoreArray.size >= level.maxPerPlayerExplosives )
				self.claymoreArray[0] detonate();
			
			self.claymorearray[ self.claymorearray.size ] = claymore;
			claymore.owner = self;
			claymore.team = self.team;
			claymore.weaponName = weapname;

			claymore thread c4Damage();
			claymore thread c4EMPDamage();
			claymore thread c4EMPKillstreakWait();
			claymore thread claymoreDetonation();
			//claymore thread claymoreDetectionTrigger_wait( self.pers[ "team" ] );
			claymore thread setClaymoreTeamHeadIcon( self.pers[ "team" ] );
			claymore thread c4WatchPickup();
			claymore thread claymoreWatchTrace();
			if ( level.deleteNadeOnTeamChange )
				claymore thread deleteOnOwnerTeamChange( self );
			 /#
			if ( getdvarint( "scr_claymoredebug" ) )
			{
				claymore thread claymoreDebug();
			}
			#/
		}
	}
}

claymoreWatchTrace()
{
	if( level.allowExtendedClaymoreTrace )
		return;
	
	self endon( "death" );
	
	// need to see if this is being placed far away from the player and not let it do that
	// this will fix a legacy bug where you can stand on a ledge and plant a claymore down on the ground far below you
	self Hide();
	
	self waittill( "missile_stuck" );
	wait 0.05;//wait for threads
	
	distanceZ = 40;
	
	if( distanceZ * distanceZ < DistanceSquared( self.origin, self.owner.origin ) )
	{
		secTrace = bulletTrace( self.owner.origin, self.owner.origin - (0, 0, distanceZ), false, self );
	
		if( secTrace["fraction"] == 1 )
		{
			self.owner SetWeaponAmmoStock( self.weaponname, self.owner GetWeaponAmmoStock( self.weaponname ) + 1 );
			self delete();
			return;
		}
		self.origin = secTrace["position"];
	}
	self Show();
	self notify( "claymore_trace_fixed" );
}

_notUsableForJoiningPlayers( owner )
{
	self endon ( "death" );
	level endon ( "game_ended" );
	owner endon ( "disconnect" );

	// as players join they need to be set to not be able to use this
	while( true )
	{
		level waittill( "player_spawned", player );
		if( IsDefined( player ) && player != owner )
		{
			self disablePlayerUse( player );
		}
	}
}

c4WatchPickup()
{
	if( !level.allowPickUpEquipment )
		return;
	
	self endon( "death" );
	
	self waittill( "missile_stuck" );
	if( !level.allowExtendedClaymoreTrace && self.weaponname == "claymore_mp" )
		self waittill( "claymore_trace_fixed" );

	trigger = spawn( "script_origin", self.origin );
	self thread deleteOnDeath( trigger );
	
	trigger setCursorHint( "HINT_NOICON" );

	if ( self.weaponname == "c4_mp" )
		trigger setHintString( &"MP_PICKUP_C4" );
	else if (self.weaponname == "claymore_mp" )
		trigger setHintString( &"MP_PICKUP_CLAYMORE" );

	trigger setSelfUsable( self.owner );
	trigger thread _notUsableForJoiningPlayers( self );
	
	for ( ;; )
	{
		trigger waittillmatch( "trigger", self.owner );
		usePressTime = getTime();
		while( self.owner UseButtonPressed() && (getTime() - usePressTime) < 500 )
			wait .05;
		
		if( self.owner UseButtonPressed() )
		{
			self.owner playLocalSound( "scavenger_pack_pickup" );
			self.owner SetWeaponAmmoStock( self.weaponname, self.owner GetWeaponAmmoStock( self.weaponname ) + 1 );

			self delete();
		}
	}
}

 /#
claymoreDebug()
{
	self waittill( "missile_stuck" );
	self thread showCone( acos( level.claymoreDetectionDot ), level.claymoreDetonateRadius, ( 1, .85, 0 ) );
	self thread showCone( 60, 256, ( 1, 0, 0 ) );
}

vectorcross( v1, v2 )
{
	return( v1[ 1 ] * v2[ 2 ] - v1[ 2 ] * v2[ 1 ], v1[ 2 ] * v2[ 0 ] - v1[ 0 ] * v2[ 2 ], v1[ 0 ] * v2[ 1 ] - v1[ 1 ] * v2[ 0 ] );
}

showCone( angle, range, color )
{
	self endon( "death" );

	start = self.origin;
	forward = anglestoforward( self.angles );
	right = vectorcross( forward, ( 0, 0, 1 ) );
	up = vectorcross( forward, right );

	fullforward = forward * range * cos( angle );
	sideamnt = range * sin( angle );

	while ( 1 )
	{
		prevpoint = ( 0, 0, 0 );
		for ( i = 0; i <= 20; i++ )
		{
			coneangle = i / 20.0 * 360;
			point = start + fullforward + sideamnt * ( right * cos( coneangle ) + up * sin( coneangle ) );
			if ( i > 0 )
			{
				line( start, point, color );
				line( prevpoint, point, color );
			}
			prevpoint = point;
		}
		wait .05;
	}
}
#/

claymoreDetonation()
{
	self endon( "death" );

	self waittill( "missile_stuck" );
	
	if( !level.allowExtendedClaymoreTrace )
		self waittill( "claymore_trace_fixed" );

	damagearea = spawn( "trigger_radius", self.origin + ( 0, 0, 0 - level.claymoreDetonateRadius ), 0, level.claymoreDetonateRadius, level.claymoreDetonateRadius * 2 );
	self thread deleteOnDeath( damagearea );

	while ( 1 )
	{
		damagearea waittill( "trigger", player );

		if ( getdvarint( "scr_claymoredebug" ) != 1 )
		{
			if ( isdefined( self.owner ) && player == self.owner )
				continue;
			if ( !friendlyFireCheck( self.owner, player, 0 ) )
				continue;
		}
		if ( lengthsquared( player getVelocity() ) < 10 )
			continue;
		
		if ( abs( player.origin[2] - self.origin[2] ) > 128 )
			continue;

		if ( !player shouldAffectClaymore( self ) )
			continue;

		if ( player damageConeTrace( self.origin, self ) > 0 )
			break;
	}
	
	self playsound ("claymore_activated");
	
	
	if ( player _hasPerk( "specialty_delaymine" ) )
		wait 3.0;
	else 
		wait level.claymoreDetectionGracePeriod;
		
	self detonate();
}

shouldAffectClaymore( claymore )
{
	if ( isDefined( claymore.disabled ) )
		return false;

	pos = self.origin + ( 0, 0, 32 );

	dirToPos = pos - claymore.origin;
	claymoreForward = anglesToForward( claymore.angles );

	dist = vectorDot( dirToPos, claymoreForward );
	if ( dist < level.claymoreDetectionMinDist )
		return false;

	dirToPos = vectornormalize( dirToPos );

	dot = vectorDot( dirToPos, claymoreForward );
	return( dot > level.claymoreDetectionDot );
}

deleteOnDeath( ent )
{
	self waittill( "death" );
	wait .05;
	if ( isdefined( ent ) )
		ent delete();
}

c4Activate()
{
	self endon( "death" );

	self waittill( "missile_stuck" );

	wait 0.05;

	self notify( "activated" );
	self.activated = true;
}

watchC4AltDetonate()
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "detonated" );
	level endon( "game_ended" );

	buttonTime = 0;
	for ( ;; )
	{
		if ( self UseButtonPressed() )
		{
			buttonTime = 0;
			while ( self UseButtonPressed() )
			{
				buttonTime += 0.05;
				wait( 0.05 );
			}

			println( "pressTime1: " + buttonTime );
			if ( buttonTime >= 0.5 )
				continue;

			buttonTime = 0;
			while ( !self UseButtonPressed() && buttonTime < 0.5 )
			{
				buttonTime += 0.05;
				wait( 0.05 );
			}

			println( "delayTime: " + buttonTime );
			if ( buttonTime >= 0.5 )
				continue;

			if ( !self.c4Array.size )
				return;

			self notify( "alt_detonate" );
		}
		wait( 0.05 );
	}
}

watchC4Detonation()
{
	self endon( "death" );
	self endon( "disconnect" );

	while ( 1 )
	{
		self waittillmatch( "detonate", "c4_mp" );
		newarray = [];
		for ( i = 0; i < self.c4array.size; i++ )
		{
			c4 = self.c4array[ i ];
			if ( isdefined( self.c4array[ i ] ) )
				c4 thread waitAndDetonate( 0.1 );
		}
		self.c4array = newarray;
		self notify( "detonated" );
	}
}


watchC4AltDetonation()
{
	self endon( "death" );
	self endon( "disconnect" );

	while ( 1 )
	{
		self waittill( "alt_detonate" );
		weap = self getCurrentWeapon();
		if ( weap != "c4_mp" )
		{
			newarray = [];
			for ( i = 0; i < self.c4array.size; i++ )
			{
				c4 = self.c4array[ i ];
				if ( isdefined( self.c4array[ i ] ) )
					c4 thread waitAndDetonate( 0.1 );
			}
			self.c4array = newarray;
			self notify( "detonated" );
		}
	}
}


waitAndDetonate( delay )
{
	self endon( "death" );
	wait delay;

	self waitTillEnabled();

	self detonate();
}

deleteC4AndClaymoresOnDisconnect()
{
	self endon( "spawned_player" );
	self waittill( "disconnect" );

	c4array = self.c4array;
	claymorearray = self.claymorearray;

	wait .05;

	for ( i = 0; i < c4array.size; i++ )
	{
		if ( isdefined( c4array[ i ] ) )
			c4array[ i ] delete();
	}
	for ( i = 0; i < claymorearray.size; i++ )
	{
		if ( isdefined( claymorearray[ i ] ) )
			claymorearray[ i ] delete();
	}
}

c4Damage()
{
	self endon( "death" );

	self setcandamage( true );
	self.maxhealth = 100000;
	self.health = self.maxhealth;

	attacker = undefined;

	while ( 1 )
	{
		self waittill( "damage", damage, attacker, direction_vec, point, type, modelName, tagName, partName, iDFlags, weapon );
		if ( !isPlayer( attacker ) )
			continue;

		// don't allow people to destroy C4 on their team if FF is off
		if ( !friendlyFireCheck( self.owner, attacker ) )
			continue;


		if( isDefined( weapon ) )
		{
			switch( weapon )
			{
				case "concussion_grenade_mp":
				case "flash_grenade_mp":
				case "smoke_grenade_mp":
					continue;
			}
		}
		else
		{
			if( damage < 5 )
				continue;
		}

		break;
	}

	if ( level.c4explodethisframe )
		wait .1 + randomfloat( .4 );
	else
		wait .05;

	if ( !isdefined( self ) )
		return;

	level.c4explodethisframe = true;

	thread resetC4ExplodeThisFrame();

	if ( isDefined( type ) && ( isSubStr( type, "MOD_GRENADE" ) || isSubStr( type, "MOD_EXPLOSIVE" ) ) )
		self.wasChained = true;

	if ( isDefined( iDFlags ) && ( iDFlags & level.iDFLAGS_PENETRATION ) )
		self.wasDamagedFromBulletPenetration = true;

	self.wasDamaged = true;
	
	if( isPlayer( attacker ) )
	{
		if( isDefined( level.extraDamageFeedback ) && level.extraDamageFeedback )
			attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback( "c4" );
		if( isDefined( level.allowPrintDamage ) && level.allowPrintDamage && attacker.printDamage )
			attacker iPrintLnBold( damage );
	}

	if ( level.teamBased )
	{
		// "destroyed_explosive" notify, for challenges
		if ( isdefined( attacker ) && isdefined( attacker.pers[ "team" ] ) && isdefined( self.owner ) && isdefined( self.owner.pers[ "team" ] ) )
		{
			if ( attacker.pers[ "team" ] != self.owner.pers[ "team" ] )
				attacker notify( "destroyed_explosive" );
		}
	}
	else
	{
		// checking isDefined attacker is defensive but it's too late in the project to risk issues by not having it
		if ( isDefined( self.owner ) && isDefined( attacker ) && attacker != self.owner )
			attacker notify( "destroyed_explosive" );		
	}

	self detonate( attacker );
	// won't get here; got death notify.
}

resetC4ExplodeThisFrame()
{
	wait .05;
	level.c4explodethisframe = false;
}

saydamaged( orig, amount )
{
	for ( i = 0; i < 60; i++ )
	{
		print3d( orig, "damaged! " + amount );
		wait .05;
	}
}

waitTillEnabled()
{
	if ( !isDefined( self.disabled ) )
		return;

	self waittill( "enabled" );
	assert( !isDefined( self.disabled ) );
}


c4DetectionTrigger( ownerTeam )
{
	self waittill( "activated" );

	trigger = spawn( "trigger_radius", self.origin - ( 0, 0, 128 ), 0, 512, 256 );
	trigger.detectId = "trigger" + getTime() + randomInt( 1000000 );

	trigger.owner = self;
	trigger thread detectIconWaiter( level.otherTeam[ ownerTeam ] );

	self waittill( "death" );
	trigger notify( "end_detection" );

	if ( isDefined( trigger.bombSquadIcon ) )
		trigger.bombSquadIcon destroy();

	trigger delete();
}


claymoreDetectionTrigger_wait( ownerTeam )
{
	self endon( "death" );
	self waittill( "missile_stuck" );

	self thread claymoreDetectionTrigger( ownerTeam );
}

claymoreDetectionTrigger( ownerTeam )
{
	trigger = spawn( "trigger_radius", self.origin - ( 0, 0, 128 ), 0, 512, 256 );
	trigger.detectId = "trigger" + getTime() + randomInt( 1000000 );

	trigger.owner = self;
	trigger thread detectIconWaiter( level.otherTeam[ ownerTeam ] );

	self waittill( "death" );
	trigger notify( "end_detection" );

	if ( isDefined( trigger.bombSquadIcon ) )
		trigger.bombSquadIcon destroy();

	trigger delete();
}


detectIconWaiter( detectTeam )
{
	self endon( "end_detection" );
	level endon( "game_ended" );

	while ( !level.gameEnded )
	{
		self waittill( "trigger", player );

		if ( !player.detectExplosives )
			continue;

		if ( level.teamBased && player.team != detectTeam )
			continue;
		else if ( !level.teamBased && player == self.owner.owner )
			continue;

		if ( isDefined( player.bombSquadIds[ self.detectId ] ) )
			continue;

		player thread showHeadIcon( self );
	}
}


setupBombSquad()
{
	self.bombSquadIds = [];

	if ( self.detectExplosives && !self.bombSquadIcons.size )
	{
		for ( index = 0; index < 4; index++ )
		{
			self.bombSquadIcons[ index ] = newClientHudElem( self );
			self.bombSquadIcons[ index ].x = 0;
			self.bombSquadIcons[ index ].y = 0;
			self.bombSquadIcons[ index ].z = 0;
			self.bombSquadIcons[ index ].alpha = 0;
			self.bombSquadIcons[ index ].archived = true;
			self.bombSquadIcons[ index ] setShader( "waypoint_bombsquad", 14, 14 );
			self.bombSquadIcons[ index ] setWaypoint( false, false );
			self.bombSquadIcons[ index ].detectId = "";
		}
	}
	else if ( !self.detectExplosives )
	{
		for ( index = 0; index < self.bombSquadIcons.size; index++ )
			self.bombSquadIcons[ index ] destroy();

		self.bombSquadIcons = [];
	}
}


showHeadIcon( trigger )
{
	triggerDetectId = trigger.detectId;
	useId = -1;
	for ( index = 0; index < 4; index++ )
	{
		detectId = self.bombSquadIcons[ index ].detectId;

		if ( detectId == triggerDetectId )
			return;

		if ( detectId == "" )
			useId = index;
	}

	if ( useId < 0 )
		return;

	self.bombSquadIds[ triggerDetectId ] = true;

	self.bombSquadIcons[ useId ].x = trigger.origin[ 0 ];
	self.bombSquadIcons[ useId ].y = trigger.origin[ 1 ];
	self.bombSquadIcons[ useId ].z = trigger.origin[ 2 ] + 24 + 128;

	self.bombSquadIcons[ useId ] fadeOverTime( 0.25 );
	self.bombSquadIcons[ useId ].alpha = 1;
	self.bombSquadIcons[ useId ].detectId = trigger.detectId;

	while ( isAlive( self ) && isDefined( trigger ) && self isTouching( trigger ) )
		wait( 0.05 );

	if ( !isDefined( self ) )
		return;

	self.bombSquadIcons[ useId ].detectId = "";
	self.bombSquadIcons[ useId ] fadeOverTime( 0.25 );
	self.bombSquadIcons[ useId ].alpha = 0;
	self.bombSquadIds[ triggerDetectId ] = undefined;
}


// these functions are used with scripted weapons (like c4, claymores, artillery)
// returns an array of objects representing damageable entities (including players) within a given sphere.
// each object has the property damageCenter, which represents its center (the location from which it can be damaged).
// each object also has the property entity, which contains the entity that it represents.
// to damage it, call damageEnt() on it.
getDamageableEnts( pos, radius, doLOS, startRadius )
{
	ents = [];

	if ( !isdefined( doLOS ) )
		doLOS = false;

	if ( !isdefined( startRadius ) )
		startRadius = 0;
	
	radiusSq = radius * radius;

	// players
	players = level.players;
	for ( i = 0; i < players.size; i++ )
	{
		if ( !isalive( players[ i ] ) || players[ i ].sessionstate != "playing" )
			continue;

		playerpos = get_damageable_player_pos( players[ i ] );
		distSq = distanceSquared( pos, playerpos );
		if ( distSq < radiusSq && ( !doLOS || weaponDamageTracePassed( pos, playerpos, startRadius, players[ i ] ) ) )
		{
			ents[ ents.size ] = get_damageable_player( players[ i ], playerpos );
		}
	}

	// grenades
	grenades = getentarray( "grenade", "classname" );
	for ( i = 0; i < grenades.size; i++ )
	{
		entpos = get_damageable_grenade_pos( grenades[ i ] );
		distSq = distanceSquared( pos, entpos );
		if ( distSq < radiusSq && ( !doLOS || weaponDamageTracePassed( pos, entpos, startRadius, grenades[ i ] ) ) )
		{
			ents[ ents.size ] = get_damageable_grenade( grenades[ i ], entpos );
		}
	}

	destructibles = getentarray( "destructible", "targetname" );
	for ( i = 0; i < destructibles.size; i++ )
	{
		entpos = destructibles[ i ].origin;
		distSq = distanceSquared( pos, entpos );
		if ( distSq < radiusSq && ( !doLOS || weaponDamageTracePassed( pos, entpos, startRadius, destructibles[ i ] ) ) )
		{
			newent = spawnstruct();
			newent.isPlayer = false;
			newent.isADestructable = false;
			newent.entity = destructibles[ i ];
			newent.damageCenter = entpos;
			ents[ ents.size ] = newent;
		}
	}

	destructables = getentarray( "destructable", "targetname" );
	for ( i = 0; i < destructables.size; i++ )
	{
		entpos = destructables[ i ].origin;
		distSq = distanceSquared( pos, entpos );
		if ( distSq < radiusSq && ( !doLOS || weaponDamageTracePassed( pos, entpos, startRadius, destructables[ i ] ) ) )
		{
			newent = spawnstruct();
			newent.isPlayer = false;
			newent.isADestructable = true;
			newent.entity = destructables[ i ];
			newent.damageCenter = entpos;
			ents[ ents.size ] = newent;
		}
	}
	
	//sentries
	sentries = getentarray( "misc_turret", "classname" );
	foreach ( sentry in sentries )
	{
		entpos = sentry.origin + (0,0,32);
		distSq = distanceSquared( pos, entpos );
		if ( distSq < radiusSq && ( !doLOS || weaponDamageTracePassed( pos, entpos, startRadius, sentry ) ) )
		{
			if ( sentry.model == "sentry_minigun" )
				ents[ ents.size ] = get_damageable_sentry(sentry, entpos);
		}
	}

	return ents;
}


getEMPDamageEnts( pos, radius, doLOS, startRadius )
{
	ents = [];

	if ( !isDefined( doLOS ) )
		doLOS = false;

	if ( !isDefined( startRadius ) )
		startRadius = 0;

	grenades = getEntArray( "grenade", "classname" );
	foreach ( grenade in grenades )
	{
		//if ( !isDefined( grenade.weaponName ) )
		//	continue;

		entpos = grenade.origin;
		dist = distance( pos, entpos );
		if ( dist < radius && ( !doLOS || weaponDamageTracePassed( pos, entpos, startRadius, grenade ) ) )
			ents[ ents.size ] = grenade;
	}

	turrets = getEntArray( "misc_turret", "classname" );
	foreach ( turret in turrets )
	{
		//if ( !isDefined( turret.weaponName ) )
		//	continue;

		entpos = turret.origin;
		dist = distance( pos, entpos );
		if ( dist < radius && ( !doLOS || weaponDamageTracePassed( pos, entpos, startRadius, turret ) ) )
			ents[ ents.size ] = turret;
	}

	return ents;
}


weaponDamageTracePassed( from, to, startRadius, ent )
{
	midpos = undefined;

	diff = to - from;
	if ( lengthsquared( diff ) < startRadius * startRadius )
		return true;
	
	dir = vectornormalize( diff );
	midpos = from + ( dir[ 0 ] * startRadius, dir[ 1 ] * startRadius, dir[ 2 ] * startRadius );

	trace = bullettrace( midpos, to, false, ent );

	if ( getdvarint( "scr_damage_debug" ) != 0 )
	{
		thread debugprint( from, ".dmg" );
		if ( isdefined( ent ) )
			thread debugprint( to, "." + ent.classname );
		else
			thread debugprint( to, ".undefined" );
		if ( trace[ "fraction" ] == 1 )
		{
			thread debugline( midpos, to, ( 1, 1, 1 ) );
		}
		else
		{
			thread debugline( midpos, trace[ "position" ], ( 1, .9, .8 ) );
			thread debugline( trace[ "position" ], to, ( 1, .4, .3 ) );
		}
	}

	return( trace[ "fraction" ] == 1 );
}

// eInflictor = the entity that causes the damage (e.g. a claymore)
// eAttacker = the player that is attacking
// iDamage = the amount of damage to do
// sMeansOfDeath = string specifying the method of death (e.g. "MOD_PROJECTILE_SPLASH")
// sWeapon = string specifying the weapon used (e.g. "claymore_mp")
// damagepos = the position damage is coming from
// damagedir = the direction damage is moving in
damageEnt( eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, damagepos, damagedir )
{
	if ( self.isPlayer )
	{
		self.damageOrigin = damagepos;
		self.entity thread [[ level.callbackPlayerDamage ]](
			eInflictor,// eInflictor The entity that causes the damage.( e.g. a turret )
			eAttacker,// eAttacker The entity that is attacking.
			iDamage,// iDamage Integer specifying the amount of damage done
			0,// iDFlags Integer specifying flags that are to be applied to the damage
			sMeansOfDeath,// sMeansOfDeath Integer specifying the method of death
			sWeapon,// sWeapon The weapon number of the weapon used to inflict the damage
			damagepos,// vPoint The point the damage is from?
			damagedir,// vDir The direction of the damage
			"none",// sHitLoc The location of the hit
			0// psOffsetTime The time offset for the damage
		 );
	}
	else
	{
		// destructable walls and such can only be damaged in certain ways.
		if ( self.isADestructable && ( sWeapon == "artillery_mp" || sWeapon == "claymore_mp" || sWeapon == "stealth_bomb_mp" ) )
			return;

		self.entity notify( "damage", iDamage, eAttacker, ( 0, 0, 0 ), ( 0, 0, 0 ), "MOD_EXPLOSIVE", "", "", "", undefined, sWeapon );
	}
}


debugline( a, b, color )
{
	for ( i = 0; i < 30 * 20; i++ )
	{
		line( a, b, color );
		wait .05;
	}
}

debugprint( pt, txt )
{
	for ( i = 0; i < 30 * 20; i++ )
	{
		print3d( pt, txt );
		wait .05;
	}
}


onWeaponDamage( eInflictor, sWeapon, meansOfDeath, damage, eAttacker )
{
	self endon( "death" );
	self endon( "disconnect" );

	switch( sWeapon )
	{
		case "concussion_grenade_mp":
			// should match weapon settings in gdt
			if ( !isDefined( eInflictor ) )//check to ensure inflictor wasnt destroyed.
				return;
			
			if( meansOfDeath == "MOD_IMPACT" ) // do not cause stun effect if it was direct hit
				return;
			
			radius = 512;
			scale = 1 - ( distance( self.origin, eInflictor.origin ) / radius );

			if ( scale < 0 )
				scale = 0;

			time = 2 + ( 4 * scale );
			
			if ( isDefined( self.stunScaler ) )
				time = time * self.stunScaler;
			
			wait( 0.05 );
			eAttacker notify( "stun_hit" );
			self notify( "concussed", eAttacker );
			if( eAttacker != self )
				eAttacker maps\mp\gametypes\_missions::processChallenge( "ch_alittleconcussed" );
			self shellShock( "concussion_grenade_mp", time );
			self.concussionEndTime = getTime() + ( time * 1000 );
			if( IsDefined( eInflictor.owner ) && eInflictor.owner == eAttacker && isDefined( level.extraDamageFeedback ) && level.extraDamageFeedback )
				eAttacker thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback( "stun" );
		break;

		case "weapon_cobra_mk19_mp":
			// mk19 is too powerful with shellshock slowdown
		break;

		default:
			// shellshock will only be done if meansofdeath is an appropriate type and if there is enough damage.
			maps\mp\gametypes\_shellshock::shellshockOnDamage( meansOfDeath, damage );
		break;
	}

}

// weapon stowing logic ===================================================================

// weapon class boolean helpers
isPrimaryWeapon( weapName )
{
	if ( weapName == "none" )
		return false;
		
	if ( weaponInventoryType( weapName ) != "primary" )
		return false;

	switch ( weaponClass( weapName ) )
	{
		case "rifle":
		case "smg":
		case "mg":
		case "spread":
		case "pistol":
		case "rocketlauncher":
		case "sniper":
			return true;

		default:
			return false;
	}	
}


isAltModeWeapon( weapName )
{
	if ( weapName == "none" )
		return false;
		
	return ( weaponInventoryType( weapName ) == "altmode" );
}

isInventoryWeapon( weapName )
{
	if ( weapName == "none" )
		return false;
		
	return ( weaponInventoryType( weapName ) == "item" );
}

isRiotShield( weapName )
{
	if ( weapName == "none" )
		return false;
		
	return ( WeaponType( weapName ) == "riotshield" );
}

isOffhandWeapon( weapName )
{
	if ( weapName == "none" )
		return false;
		
	return ( weaponInventoryType( weapName ) == "offhand" );
}

isSideArm( weapName )
{
	if ( weapName == "none" )
		return false;

	if ( weaponInventoryType( weapName ) != "primary" )
		return false;

	return ( weaponClass( weapName ) == "pistol" );
}


// This needs for than this.. this would qualify c4 as a grenade
isGrenade( weapName )
{
	weapClass = weaponClass( weapName );
	weapType = weaponInventoryType( weapName );

	if ( weapClass != "grenade" )
		return false;
		
	if ( weapType != "offhand" )
		return false;
}


getStowOffsetModel( weaponName )
{
	assert( isDefined( level.stow_offset_array ) );

	baseName = getBaseWeaponName( weaponName );
	
	return( level.stow_offset_array[baseName] );
}


stowPriorityWeapon()
{
	assert( isdefined( level.stow_priority_model_array ) );

	// returns the first large projectil the player owns in case player owns more than one
	foreach ( weapon_name, priority_weapon in level.stow_priority_model_array )
	{
		weaponName = getBaseWeaponName( weapon_name );
		weaponList = self getWeaponsListAll();
		
		foreach ( weapon in weaponList )
		{
			if( self getCurrentWeapon() == weapon )
				continue;
			
			if ( weaponName == getBaseWeaponName( weapon ) )
				return weaponName + "_mp";
		}
	}

	return "";
}

// thread loop life = player's life
updateStowedWeapon()
{
	self endon( "spawned" );
	self endon( "killed_player" );
	self endon( "disconnect" );

	self.tag_stowed_back = undefined;
	self.tag_stowed_hip = undefined;
	
	team = self.team;
	class = self.class;
	
	self thread stowedWeaponsRefresh();
	
	while ( true )
	{
		self waittill( "weapon_change", newWeapon );
		
		if ( newWeapon == "none" )
			continue;
			
		self thread stowedWeaponsRefresh();
	}
}

stowedWeaponsRefresh()
{
	self endon( "spawned" );
	self endon( "killed_player" );
	self endon( "disconnect" );
	
	detach_all_weapons();
	stow_on_back();
	stow_on_hip();
}


detach_all_weapons()
{
	if ( isDefined( self.tag_stowed_back ) )
		self detach_back_weapon();

	if ( isDefined( self.tag_stowed_hip ) )
		self detach_hip_weapon();
}


detach_back_weapon()
{
	detach_success = self detachIfAttached( self.tag_stowed_back, "tag_stowed_back" );

	// test for bug
	//assertex( detach_success, "Detaching: " + self.tag_stowed_back + " from tag: tag_stowed_back failed." );
	self.tag_stowed_back = undefined;
}


detach_hip_weapon()
{
	detach_success = self detachIfAttached( self.tag_stowed_hip, "tag_stowed_hip" );

	// test for bug
	//assertex( detach_success, "Detaching: " + detach_model + " from tag: tag_stowed_hip failed." );
	self.tag_stowed_hip = undefined;
}


FixHideTagList( hideTagList, stowWeapon )
{
	answer = [];

	for ( i = 0; i < hideTagList.size; i++ )
	{
		tag = hideTagList[ i ];

		if ( stowWeapon == "weapon_ak74u" )
		{
			if ( tag == "tag_reflex_sight" || tag == "tag_acog" || tag == "tag_ak47_mount" )
				continue;
		}
		else if ( stowWeapon == "weapon_ak47_classic" )
		{
			if ( tag == "tag_reflex_sight" || tag == "tag_acog" || tag == "tag_ak47_mount" )
				continue;
		}
		else if ( stowWeapon == "worldmodel_bo2_peacekeeper" )
		{
			if ( tag == "tag_holo" || tag == "tag_reflex" || tag == "tag_silencer" )
				continue;
		}
		else if ( stowWeapon == "weapon_beretta" )
		{
			if ( tag == "tag_knife" )
				continue;
		}

		answer[ answer.size ] = tag;
	}

	return answer;
}


stow_on_back()
{
	prof_begin( "stow_on_back" );
	currentWeapon = self getCurrentWeapon();
	currentIsAlt = isAltModeWeapon( currentWeapon );

	assert( !isDefined( self.tag_stowed_back ) );

	stowWeapon = undefined;
	stowCamo = 0;
	large_projectile = self stowPriorityWeapon();
	stowOffsetModel = undefined;

	if ( large_projectile != "" )
	{
		stowWeapon = large_projectile;
	}
	else
	{
		weaponsList = self getWeaponsListPrimaries();
		foreach ( weaponName in weaponsList )
		{
			if ( weaponName == currentWeapon )
				continue;
			
			invType = weaponInventoryType( weaponName );
			
			if ( invType != "primary" )
			{
				if ( invType == "altmode" )
					continue;
				
				if ( weaponClass( weaponName ) == "pistol" )
					continue;
			}
			
			if ( WeaponType( weaponName ) == "riotshield" )
				continue;
			
			// Don't stow the current on our back when we're using the alt
			if ( currentIsAlt && weaponAltWeaponName( weaponName ) == currentWeapon )
				continue;
				
			stowWeapon = weaponName;
			stowOffsetModel = getStowOffsetModel( stowWeapon );
			
			if ( stowWeapon == self.primaryWeapon )
				stowCamo = self.loadoutPrimaryCamo;
			else if ( stowWeapon == self.secondaryWeapon )
				stowCamo = self.loadoutSecondaryCamo;
			else
				stowCamo = 0;
		}		
	}

	if ( !isDefined( stowWeapon ) )
	{
		prof_end( "stow_on_back" );
		return;
	}

	if ( large_projectile != "" )
	{
		self.tag_stowed_back = level.stow_priority_model_array[ large_projectile ];
	}
	else
	{
		self.tag_stowed_back = getWeaponModel( stowWeapon, stowCamo );	
	}

	if ( isDefined( stowOffsetModel ) )
	{
		self attach( stowOffsetModel, "tag_stowed_back", true );
		attachTag = "tag_stow_back_mid_attach";
	}
	else
	{
		attachTag = "tag_stowed_back";
	}

	self attach( self.tag_stowed_back, attachTag, true );

	hideTagList = GetWeaponHideTags( stowWeapon );

	if ( !isDefined( hideTagList ) )
	{
		prof_end( "stow_on_back" );
		return;
	}
	
	hideTagList = FixHideTagList( hideTagList, self.tag_stowed_back );

	for ( i = 0; i < hideTagList.size; i++ )
		self HidePart( hideTagList[ i ], self.tag_stowed_back );
	
	prof_end( "stow_on_back" );
}

stow_on_hip()
{
	currentWeapon = self getCurrentWeapon();

	assert( !isDefined( self.tag_stowed_hip ) );

	stowWeapon = undefined;

	weaponsList = self getWeaponsListOffhands();
	foreach ( weaponName in weaponsList )
	{
		if ( weaponName == currentWeapon )
			continue;
			
		if ( weaponName != "c4_mp" && weaponName != "claymore_mp" )
			continue;
		
		stowWeapon = weaponName;
	}

	if ( !isDefined( stowWeapon ) )
		return;

	self.tag_stowed_hip = getWeaponModel( stowWeapon );
	self attach( self.tag_stowed_hip, "tag_stowed_hip_rear", true );

	hideTagList = GetWeaponHideTags( stowWeapon );
	
	if ( !isDefined( hideTagList ) )
		return;

	hideTagList = FixHideTagList( hideTagList, self.tag_stowed_hip );
	
	for ( i = 0; i < hideTagList.size; i++ )
		self HidePart( hideTagList[ i ], self.tag_stowed_hip );
}


updateSavedLastWeapon()
{
	self endon( "death" );
	self endon( "disconnect" );

	currentWeapon = self.currentWeaponAtSpawn;
	self.saved_lastWeapon = currentWeapon;

	for ( ;; )
	{
		self waittill( "weapon_change", newWeapon );
	
		if ( newWeapon == "none" )
		{
			self.saved_lastWeapon = currentWeapon;
			continue;
		}

		weaponInvType = weaponInventoryType( newWeapon );

		if ( weaponInvType != "primary" && weaponInvType != "altmode" )
		{
			self.saved_lastWeapon = currentWeapon;
			continue;
		}
		
		if ( newWeapon == "onemanarmy_mp" )
		{
			self.saved_lastWeapon = currentWeapon;
			continue;
		}

		self updateMoveSpeedScale( "primary" );

		self.saved_lastWeapon = currentWeapon;
		currentWeapon = newWeapon;
	}
}


EMPPlayer( numSeconds )
{
	self endon( "disconnect" );
	self endon( "death" );

	self thread clearEMPOnDeath();

}


clearEMPOnDeath()
{
	self endon( "disconnect" );

	self waittill( "death" );
}


updateMoveSpeedScale( weaponType )
{
	/*
	if ( self _hasPerk( "specialty_lightweight" ) )
		self.moveSpeedScaler = 1.10;
	else
		self.moveSpeedScaler = 1;
	*/
	
	if ( !isDefined( weaponType ) || weaponType == "primary" || weaponType != "secondary" )
		weaponType = self.primaryWeapon;
	else
		weaponType = self.secondaryWeapon;
	
	if( isDefined(self.primaryWeapon ) && self.primaryWeapon == "riotshield_mp" )
	{
		self setMoveSpeedScale( .8 * self.moveSpeedScaler );
		return;
	}
	
	if ( !isDefined( weaponType ) )
		weapClass = "none";
	else 
		weapClass = weaponClass( weaponType );
	
	
	switch ( weapClass )
	{
		case "rifle":
			self setMoveSpeedScale( 0.95 * self.moveSpeedScaler );
			break;
		case "pistol":
			self setMoveSpeedScale( 1.0 * self.moveSpeedScaler );
			break;
		case "mg":
			self setMoveSpeedScale( 0.875 * self.moveSpeedScaler );
			break;
		case "smg":
			self setMoveSpeedScale( 1.0 * self.moveSpeedScaler );
			break;
		case "spread":
			self setMoveSpeedScale( .95 * self.moveSpeedScaler );
			break;
		case "rocketlauncher":
			self setMoveSpeedScale( 0.80 * self.moveSpeedScaler );
			break;
		case "sniper":
			self setMoveSpeedScale( 1.0 * self.moveSpeedScaler );
			break;
		default:
			self setMoveSpeedScale( 1.0 * self.moveSpeedScaler );
			break;
	}
}


buildWeaponData( filterPerks )
{
	attachmentList = getAttachmentList();		
	max_weapon_num = 149;

	baseWeaponData = [];
	
	for( weaponId = 0; weaponId <= max_weapon_num; weaponId++ )
	{
		baseName = tablelookup( "mp/statstable.csv", 0, weaponId, 4 );
		if( baseName == "" )
			continue;

		assetName = baseName + "_mp";

		if ( !isSubStr( tableLookup( "mp/statsTable.csv", 0, weaponId, 2 ), "weapon_" ) )
			continue;
		
		if ( weaponInventoryType( assetName ) != "primary" )
			continue;

		weaponInfo = spawnStruct();
		weaponInfo.baseName = baseName;
		weaponInfo.assetName = assetName;
		weaponInfo.variants = [];

		weaponInfo.variants[0] = assetName;
		// the alphabetize function is slow so we try not to do it for every weapon/attachment combo; a code solution would be better.
		attachmentNames = [];
		for ( innerLoopCount = 0; innerLoopCount < 6; innerLoopCount++ )
		{
			// generating attachment combinations
			attachmentName = tablelookup( "mp/statStable.csv", 0, weaponId, innerLoopCount + 11 );
			
			if ( filterPerks )
			{
				switch ( attachmentName )
				{
					case "fmj":
					case "xmags":
					case "rof":
						continue;
				}
			}
			
			if( attachmentName == "" )
				break;
			
			attachmentNames[attachmentName] = true;
		}

		// generate an alphabetized attachment list
		attachments = [];
		foreach ( attachmentName in attachmentList )
		{
			if ( !isDefined( attachmentNames[attachmentName] ) )
				continue;
			
			weaponInfo.variants[weaponInfo.variants.size] = baseName + "_" + attachmentName + "_mp";
			attachments[attachments.size] = attachmentName;
		}

		for ( i = 0; i < (attachments.size - 1); i++ )
		{
			colIndex = tableLookupRowNum( "mp/attachmentCombos.csv", 0, attachments[i] );
			for ( j = i + 1; j < attachments.size; j++ )
			{
				if ( tableLookup( "mp/attachmentCombos.csv", 0, attachments[j], colIndex ) == "no" )
					continue;
					
				weaponInfo.variants[weaponInfo.variants.size] = baseName + "_" + attachments[i] + "_" + attachments[j] + "_mp";
			}
		}
		
		baseWeaponData[baseName] = weaponInfo;
	}
	
	return ( baseWeaponData );
}

monitorSemtex()
{
	self endon( "disconnect" );
	
	for( ;; )
	{
		self waittill( "grenade_fire", weapon );

		if ( !isSubStr(weapon.model, "semtex" ) )
			continue;
			
		weapon waittill( "missile_stuck", stuckTo );
			
		if ( !isPlayer( stuckTo ) )
			continue;
			
		if ( level.teamBased && isDefined( stuckTo.team ) && stuckTo.team == self.team )
		{
			weapon.isStuck = "friendly";
			continue;
		}
	
		weapon.isStuck = "enemy";
		weapon.stuckEnemyEntity = stuckTo;
		
		stuckTo maps\mp\gametypes\_hud_message::playerCardSplashNotify( "semtex_stuck", self );
		
		self thread maps\mp\gametypes\_hud_message::SplashNotify( "stuck_semtex", 100 );
		self notify( "process", "ch_bullseye" );
	}
}


turret_monitorUse()
{
	for( ;; )
	{
		self waittill ( "trigger", player );
		
		self thread turret_playerThread( player );
	}
}

turret_playerThread( player )
{
	player endon ( "death" );
	player endon ( "disconnect" );

	player notify ( "weapon_change", "none" );
	
	self waittill ( "turret_deactivate" );
	
	player notify ( "weapon_change", player getCurrentWeapon() );
}
