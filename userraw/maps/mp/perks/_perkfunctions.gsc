/******************************************************************* 
//						_perkfunctions.gsc  
//	
//	Holds all the perk set/unset and listening functions 
//	
//	Jordan Hirsh	Sept. 11th 	2008
********************************************************************/

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\perks\_perks;


blastshieldUseTracker( perkName, useFunc )
{
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( "end_perkUseTracker" );
	level endon ( "game_ended" );

	for ( ;; )
	{
		self waittill ( "empty_offhand" );

		if ( !isOffhandWeaponEnabled() )
			continue;
			
		self [[useFunc]]( self _hasPerk( "_specialty_blastshield" ) );
	}
}

perkUseDeathTracker()
{
	self endon ( "disconnect" );
	
	self waittill("death");
	self._usePerkEnabled = undefined;
}

setRearView()
{
	//self thread perkUseTracker( "specialty_rearview", ::toggleRearView );
}

unsetRearView()
{
	self notify ( "end_perkUseTracker" );
}

toggleRearView( isEnabled )
{
	if ( isEnabled )
	{
		self _setPerk( "_specialty_rearview" );
		self SetRearViewRenderEnabled(true);
	}
	else
	{
		self _unsetPerk( "_specialty_rearview" );
		self SetRearViewRenderEnabled(false);
	}
}


setEndGame()
{
	if ( isdefined( self.endGame ) )
		return;
		
	self.maxhealth = ( maps\mp\gametypes\_tweakables::getTweakableValue( "player", "maxhealth" ) * 4 );
	self.health = self.maxhealth;
	self.endGame = true;
	self.attackerTable[0] = "";
	self visionSetNakedForPlayer("end_game", 5 );
	self thread endGameDeath( 7 );
	self.hasDoneCombat = true;
}


unsetEndGame()
{
	self notify( "stopEndGame" );
	self.endGame = undefined;
	revertVisionSet();
	
	if (! isDefined( self.endGameTimer ) )
		return;
	
	self.endGameTimer destroyElem();
	self.endGameIcon destroyElem();		
}


revertVisionSet()
{
	self VisionSetNakedForPlayer( getDvar( "mapname" ), 1 );	
}

endGameDeath( duration )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "joined_team" );
	level endon( "game_ended" );
	self endon( "stopEndGame" );
		
	wait( duration + 1 );
	//self visionSetNakedForPlayer("end_game2", 1 );
	//wait(1);
	self _suicide();			
}

setCombatHigh()
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "unset_combathigh" );
	level endon( "end_game" );
	
	self.damageBlockedTotal = 0;
	//self visionSetNakedForPlayer( "end_game", 1 );

	if ( level.splitscreen )
	{
		yOffset = 56;
		iconSize = 21; // 32/1.5
	}
	else
	{
		yOffset = 112;
		iconSize = 32;
	}

	self.combatHighOverlay = newClientHudElem( self );
	self.combatHighOverlay.x = 0;
	self.combatHighOverlay.y = 0;
	self.combatHighOverlay.alignX = "left";
	self.combatHighOverlay.alignY = "top";
	self.combatHighOverlay.horzAlign = "fullscreen";
	self.combatHighOverlay.vertAlign = "fullscreen";
	self.combatHighOverlay setshader ( "combathigh_overlay", 640, 480 );
	self.combatHighOverlay.sort = -10;
	self.combatHighOverlay.archived = true;
	
	self.combatHighTimer = createTimer( "hudsmall", 1.0 );
	self.combatHighTimer setPoint( "CENTER", "CENTER", 0, yOffset );
	self.combatHighTimer setTimer( 10.0 );
	self.combatHighTimer.color = (.8,.8,0);
	self.combatHighTimer.archived = false;
	self.combatHighTimer.foreground = true;

	self.combatHighIcon = self createIcon( "specialty_painkiller", iconSize, iconSize );
	self.combatHighIcon.alpha = 0;
	self.combatHighIcon setParent( self.combatHighTimer );
	self.combatHighIcon setPoint( "BOTTOM", "TOP" );
	self.combatHighIcon.archived = true;
	self.combatHighIcon.sort = 1;
	self.combatHighIcon.foreground = true;

	self.combatHighOverlay.alpha = 0.0;	
	self.combatHighOverlay fadeOverTime( 1.0 );
	self.combatHighIcon fadeOverTime( 1.0 );
	self.combatHighOverlay.alpha = 1.0;
	self.combatHighIcon.alpha = 0.85;
	
	self thread unsetCombatHighOnDeath();
	
	wait( 8 );

	self.combatHighIcon	fadeOverTime( 2.0 );
	self.combatHighIcon.alpha = 0.0;
	
	self.combatHighOverlay fadeOverTime( 2.0 );
	self.combatHighOverlay.alpha = 0.0;
	
	self.combatHighTimer fadeOverTime( 2.0 );
	self.combatHighTimer.alpha = 0.0;

	wait( 2 );
	self.damageBlockedTotal = undefined;

	self _unsetPerk( "specialty_combathigh" );
}

unsetCombatHighOnDeath()
{
	self endon ( "disconnect" );
	self endon ( "unset_combathigh" );
	
	self waittill ( "death" );
	
	self thread _unsetPerk( "specialty_combathigh" );
}

unsetCombatHigh()
{
	self notify ( "unset_combathigh" );
	self.combatHighOverlay destroy();
	self.combatHighIcon destroy();
	self.combatHighTimer destroy();
}

setSiege()
{
	self thread trackSiegeEnable();
	self thread trackSiegeDissable();
}

trackSiegeEnable()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( "stop_trackSiege" );
	
	for ( ;; )
	{
		self waittill ( "gambit_on" );
		
		//self setStance( "crouch" );
		//self thread stanceStateListener();
		//self thread jumpStateListener();  
		self.moveSpeedScaler = 0;
		self maps\mp\gametypes\_weapons::updateMoveSpeedScale( "primary" );
		class = weaponClass( self getCurrentWeapon() );
		
		if ( class == "pistol" || class == "smg" ) 
			self setSpreadOverride( 1 );
		else
			self setSpreadOverride( 2 );
		
		self player_recoilScaleOn( 0 );
		self allowJump(false);	
	}	
}

trackSiegeDissable()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( "stop_trackSiege" );
	
	for ( ;; )
	{
		self waittill ( "gambit_off" );
		
		unsetSiege();
	}	
}

stanceStateListener()
{
	self endon ( "death" );
	self endon ( "disconnect" );	
	
	self notifyOnPlayerCommand( "adjustedStance", "+stance" );

	for ( ;; )
	{
		self waittill( "adjustedStance" );
		if ( self.moveSPeedScaler != 0 )
			continue;
			
		unsetSiege();
	}
}

jumpStateListener()
{
	self endon ( "death" );
	self endon ( "disconnect" );	
	
	self notifyOnPlayerCommand( "jumped", "+goStand" );

	for ( ;; )
	{
		self waittill( "jumped" );
		if ( self.moveSPeedScaler != 0 )
			continue;
				
		unsetSiege();
	}
}

unsetSiege()
{
	self.moveSpeedScaler = 1;
	//if siege is not cut add check to see if
	//using lightweight and siege for movespeed scaler
	self resetSpreadOverride();
	self maps\mp\gametypes\_weapons::updateMoveSpeedScale( "primary" );
	self player_recoilScaleOff();
	self allowJump(true);
}


setFinalStand()
{
	self _setperk( "specialty_pistoldeath");
}

unsetFinalStand()
{
	self _unsetperk( "specialty_pistoldeath" );
}


setChallenger()
{
	if ( !level.hardcoreMode )
	{
		self.maxhealth = maps\mp\gametypes\_tweakables::getTweakableValue( "player", "maxhealth" );
		
		if ( isDefined( self.xpScaler ) && self.xpScaler == 1 && self.maxhealth > 30 )
		{		
			self.xpScaler = 2;
		}	
	}
}

unsetChallenger()
{
	self.xpScaler = 1;
}


setSaboteur()
{
	self.objectiveScaler = 1.2;
}

unsetSaboteur()
{
	self.objectiveScaler = 1;
}


setLightWeight()
{
	self.moveSpeedScaler = 1.07;	
	self maps\mp\gametypes\_weapons::updateMoveSpeedScale( "primary" );
}

unsetLightWeight()
{
	self.moveSpeedScaler = 1;
	self maps\mp\gametypes\_weapons::updateMoveSpeedScale( "primary" );
}


setBlackBox()
{
	self.killStreakScaler = 1.5;
}

unsetBlackBox()
{
	self.killStreakScaler = 1;
}

setSteelNerves()
{
	self _setperk( "specialty_bulletaccuracy" );
	self _setperk( "specialty_holdbreath" );
}

unsetSteelNerves()
{
	self _unsetperk( "specialty_bulletaccuracy" );
	self _unsetperk( "specialty_holdbreath" );
}

setDelayMine()
{
}

unsetDelayMine()
{
}


setBackShield()
{
	self AttachShieldModel( "weapon_riot_shield_mp", "tag_shield_back" );	
}


unsetBackShield()
{
	self DetachShieldModel( "weapon_riot_shield_mp", "tag_shield_back" );
}


setLocalJammer()
{
	if ( !self isEMPed() )
		self RadarJamOn();
}


unsetLocalJammer()
{
	self RadarJamOff();
}


setAC130()
{
	self thread killstreakThink( "ac130", 7, "end_ac130Think" );
}

unsetAC130()
{
	self notify ( "end_ac130Think" );
}


setSentryMinigun()
{
	self thread killstreakThink( "airdrop_sentry_minigun", 2, "end_sentry_minigunThink" );
}

unsetSentryMinigun()
{
	self notify ( "end_sentry_minigunThink" );
}

setCarePackage()
{
	self thread killstreakThink( "airdrop", 2, "endCarePackageThink" );
}

unsetCarePackage()
{
	self notify ( "endCarePackageThink" );
}

setTank()
{
	self thread killstreakThink( "tank", 6, "end_tankThink" );
}

unsetTank()
{
	self notify ( "end_tankThink" );
}

setPrecision_airstrike()
{
	println( "!precision airstrike!" );
	self thread killstreakThink( "precision_airstrike", 6, "end_precision_airstrike" );
}

unsetPrecision_airstrike()
{
	self notify ( "end_precision_airstrike" );
}

setPredatorMissile()
{
	self thread killstreakThink( "predator_missile", 4, "end_predator_missileThink" );
}

unsetPredatorMissile()
{
	self notify ( "end_predator_missileThink" );
}


setHelicopterMinigun()
{
	self thread killstreakThink( "helicopter_minigun", 5, "end_helicopter_minigunThink" );
}

unsetHelicopterMinigun()
{
	self notify ( "end_helicopter_minigunThink" );
}



killstreakThink( streakName, streakVal, endonString )
{
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( endonString );
	
	for ( ;; )
	{
		self waittill ( "killed_enemy" );
		
		if ( self.pers["cur_kill_streak"] != streakVal )
			continue;

		self thread maps\mp\killstreaks\_killstreaks::giveKillstreak( streakName );
		self thread maps\mp\gametypes\_hud_message::killstreakSplashNotify( streakName, streakVal );
		return;
	}
}


setThermal()
{
	self ThermalVisionOn();
}


unsetThermal()
{
	self ThermalVisionOff();
}


setOneManArmy()
{
	self thread oneManArmyWeaponChangeTracker();
}


unsetOneManArmy()
{
	self notify ( "stop_oneManArmyTracker" );
}


oneManArmyWeaponChangeTracker()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	self endon ( "stop_oneManArmyTracker" );
	
	for ( ;; )
	{
		self waittill( "weapon_change", newWeapon );

		if ( newWeapon != "onemanarmy_mp" )	
			continue;
	
		//if ( self isUsingRemote() )
		//	continue;
		
		self thread selectOneManArmyClass();	
	}
}


isOneManArmyMenu( menu )
{
	if ( menu == game["menu_onemanarmy"] )
		return true;

	if ( isDefined( game["menu_onemanarmy_defaults_splitscreen"] ) && menu == game["menu_onemanarmy_defaults_splitscreen"] )
		return true;

	if ( isDefined( game["menu_onemanarmy_custom_splitscreen"] ) && menu == game["menu_onemanarmy_custom_splitscreen"] )
		return true;

	return false;
}


selectOneManArmyClass()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	
	self _disableWeaponSwitch();
	self _disableOffhandWeapons();
	self _disableUsability();
	
	self openPopupMenu( game["menu_onemanarmy"] );
	
	self thread closeOMAMenuOnDeath();
	
	self waittill ( "menuresponse", menu, className );

	self _enableWeaponSwitch();
	self _enableOffhandWeapons();
	self _enableUsability();
	
	if ( className == "back" || !isOneManArmyMenu( menu ) || self isUsingRemote() )
	{
		if ( self getCurrentWeapon() == "onemanarmy_mp" )
		{
			self _disableWeaponSwitch();
			self _disableOffhandWeapons();
			self _disableUsability();
			self switchToWeapon( self getLastWeapon() );
			self waittill ( "weapon_change" );
			self _enableWeaponSwitch();
			self _enableOffhandWeapons();
			self _enableUsability();
		}
		return;
	}	
	
	self thread giveOneManArmyClass( className );	
}

closeOMAMenuOnDeath()
{
	self endon ( "menuresponse" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	
	self waittill ( "death" );

	self _enableWeaponSwitch();
	self _enableOffhandWeapons();
	self _enableUsability();

	self closePopupMenu();
}

giveOneManArmyClass( className )
{
	self endon ( "death" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );

	if ( self _hasPerk( "specialty_omaquickchange" ) )
	{
		changeDuration = 3.0;
		self playLocalSound( "foly_onemanarmy_bag3_plr" );
		self playSoundToTeam( "foly_onemanarmy_bag3_npc", "allies", self );
		self playSoundToTeam( "foly_onemanarmy_bag3_npc", "axis", self );
	}
	else
	{
		changeDuration = 6.0;
		self playLocalSound( "foly_onemanarmy_bag6_plr" );
		self playSoundToTeam( "foly_onemanarmy_bag6_npc", "allies", self );
		self playSoundToTeam( "foly_onemanarmy_bag6_npc", "axis", self );
	}
		
	self thread omaUseBar( changeDuration );
		
	self _disableWeapon();
	self _disableOffhandWeapons();
	self _disableUsability();
	
	wait ( changeDuration );

	self _enableWeapon();
	self _enableOffhandWeapons();
	self _enableUsability();
	
	self.OMAClassChanged = true;

	self maps\mp\gametypes\_class::giveLoadout( self.pers["team"], className, false );
	
	// handle the fact that detachAll in giveLoadout removed the CTF flag from our back
	// it would probably be better to handle this in _detachAll itself, but this is a safety fix
	if ( isDefined( self.carryFlag ) )
		self attach( self.carryFlag, "J_spine4", true );
	
	self notify ( "changed_kit" );
	level notify ( "changed_kit" );
}


omaUseBar( duration )
{
	self endon( "disconnect" );
	
	useBar = createPrimaryProgressBar( 25 );
	useBarText = createPrimaryProgressBarText( 25 );
	useBarText setText( &"MPUI_CHANGING_KIT" );

	useBar updateBar( 0, 1 / duration );
	for ( waitedTime = 0; waitedTime < duration && isAlive( self ) && !level.gameEnded; waitedTime += 0.05 )
		wait ( 0.05 );
	
	useBar destroyElem();
	useBarText destroyElem();
}


setBlastShield()
{
	self thread blastshieldUseTracker( "specialty_blastshield", ::toggleBlastShield );
	self SetWeaponHudIconOverride( "primaryoffhand", "specialty_blastshield" );
}


unsetBlastShield()
{
	self notify ( "end_perkUseTracker" );
	self SetWeaponHudIconOverride( "primaryoffhand", "none" );
}

toggleBlastShield( isEnabled )
{
	if ( !isEnabled )
	{
		self VisionSetNakedForPlayer( "black_bw", 0.15 );
		wait ( 0.15 );
		self _setPerk( "_specialty_blastshield" );
		self VisionSetNakedForPlayer( getDvar( "mapname" ), 0 );
		self playSoundToPlayer( "item_blast_shield_on", self );
	}
	else
	{
		self VisionSetNakedForPlayer( "black_bw", 0.15 );
		wait ( 0.15 );	
		self _unsetPerk( "_specialty_blastshield" );
		self VisionSetNakedForPlayer( getDvar( "mapname" ), 0 );
		self playSoundToPlayer( "item_blast_shield_off", self );
	}
}


setFreefall()
{
	//eventually set a listener to do a roll when falling damage is taken
}

unsetFreefall()
{
}


setTacticalInsertion()
{
	self _giveWeapon( "flare_mp", 0 );
	self giveStartAmmo( "flare_mp" );
	
	self thread monitorTIUse();
}

unsetTacticalInsertion()
{
	self notify( "end_monitorTIUse" );
}

clearPreviousTISpawnpoint()
{
	self waittill_any ( "disconnect", "joined_team", "joined_spectators" );
	
	if ( isDefined ( self.setSpawnpoint ) )
		self deleteTI( self.setSpawnpoint );
}

updateTISpawnPosition()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	self endon ( "end_monitorTIUse" );
	
	while ( isReallyAlive( self ) )
	{
		if ( self isValidTISpawnPosition() )
			self.TISpawnPosition = self.origin;

		wait ( 0.05 );
	}
}

isValidTISpawnPosition()
{
	if ( CanSpawn( self.origin ) && self IsOnGround() )
		return true;
	else
		return false;
}

monitorTIUse()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	self endon ( "end_monitorTIUse" );

	self thread updateTISpawnPosition();
	self thread clearPreviousTISpawnpoint();
	
	for ( ;; )
	{
		self waittill( "grenade_fire", lightstick, weapName );
				
		if ( weapName != "flare_mp" )
			continue;
		
		//lightstick delete();
		
		if ( isDefined( self.setSpawnPoint ) )
			self deleteTI( self.setSpawnPoint );

		if ( !isDefined( self.TISpawnPosition ) )
			continue;

		if ( self touchingBadTrigger() )
			continue;

		TIGroundPosition = playerPhysicsTrace( self.TISpawnPosition + (0,0,16), self.TISpawnPosition - (0,0,2048) ) + (0,0,1);
		
		glowStick = spawn( "script_model", TIGroundPosition );
		glowStick.angles = self.angles;
		glowStick.team = self.team;
		glowStick.enemyTrigger =  spawn( "script_origin", TIGroundPosition );
		glowStick thread GlowStickSetupAndWaitForDeath( self );
		glowStick.playerSpawnPos = self.TISpawnPosition;
		
		glowStick thread maps\mp\gametypes\_weapons::createBombSquadModel( "weapon_light_stick_tactical_bombsquad", "tag_fire_fx", level.otherTeam[self.team], self );
		
		self.setSpawnPoint = glowStick;		
		return;
	}
}


GlowStickSetupAndWaitForDeath( owner )
{
	self setModel( level.spawnGlowModel["enemy"] );
	if ( level.teamBased )
		self maps\mp\_entityheadIcons::setTeamHeadIcon( self.team , (0,0,20) );
	else
		self maps\mp\_entityheadicons::setPlayerHeadIcon( owner, (0,0,20) );

	self thread GlowStickDamageListener( owner );
	self thread GlowStickEnemyUseListener( owner );
	self thread GlowStickUseListener( owner );
	self thread GlowStickTeamUpdater( level.otherTeam[self.team], level.spawnGlow["enemy"], owner );	

	dummyGlowStick = spawn( "script_model", self.origin+ (0,0,0) );
	dummyGlowStick.angles = self.angles;
	dummyGlowStick setModel( level.spawnGlowModel["friendly"] );
	dummyGlowStick setContents( 0 );
	dummyGlowStick thread GlowStickTeamUpdater( self.team, level.spawnGlow["friendly"], owner );
	
	dummyGlowStick playLoopSound( "emt_road_flare_burn" );

	self waittill ( "death" );
	
	dummyGlowStick stopLoopSound();
	dummyGlowStick delete();
}


GlowStickTeamUpdater( showForTeam, showEffect, owner )
{
	self endon ( "death" );
	
	// PlayFXOnTag fails if run on the same frame the parent entity was created
	wait ( 0.05 );
	
	//PlayFXOnTag( showEffect, self, "TAG_FX" );
	angles = self getTagAngles( "tag_fire_fx" );
	fxEnt = SpawnFx( showEffect, self getTagOrigin( "tag_fire_fx" ), anglesToForward( angles ), anglesToUp( angles ) );
	TriggerFx( fxEnt );
	
	self thread deleteOnDeath( fxEnt );
	
	for ( ;; )
	{
		self hide();
		fxEnt hide();
		foreach ( player in level.players )
		{
			if ( player.team == showForTeam && level.teamBased )
			{
				self showToPlayer( player );
				fxEnt showToPlayer( player );
			}
			else if ( !level.teamBased && player == owner && showEffect == level.spawnGlow["friendly"] )
			{
				self showToPlayer( player );
				fxEnt showToPlayer( player );
			}
			else if ( !level.teamBased && player != owner && showEffect == level.spawnGlow["enemy"] )
			{
				self showToPlayer( player );
				fxEnt showToPlayer( player );
			}
		}
		
		level waittill_either ( "joined_team", "player_spawned" );
	}
}

deleteOnDeath( ent )
{
	self waittill( "death" );
	if ( isdefined( ent ) )
		ent delete();
}

GlowStickDamageListener( owner )
{
	self endon ( "death" );

	self setCanDamage( true );
	// use large health to work around teamkilling issue
	self.health = 5000;

	for ( ;; )
	{
		self waittill ( "damage", amount, attacker );

		if ( level.teambased && isDefined( owner ) && attacker != owner && ( isDefined( attacker.team ) && attacker.team == self.team ) )
		{
			self.health += amount;
			continue;
		}
		
		if ( self.health < (5000-20) )
		{
			if ( isDefined( owner ) && attacker != owner )
			{
				attacker notify ( "destroyed_insertion", owner );
				attacker notify( "destroyed_explosive" ); // count towards SitRep Pro challenge
				owner thread leaderDialogOnPlayer( "ti_destroyed" );
			}
			
			attacker thread deleteTI( self );
		}
	}
}

GlowStickUseListener( owner )
{
	self endon ( "death" );
	level endon ( "game_ended" );
	owner endon ( "disconnect" );
	
	self setCursorHint( "HINT_NOICON" );
	self setHintString( &"MP_PICKUP_TI" );
	
	self thread updateEnemyUse( owner );

	for ( ;; )
	{
		self waittill ( "trigger", player );
		
		player playSound( "chemlight_pu" );
		player thread setTacticalInsertion();
		player thread deleteTI( self );
	}
}

updateEnemyUse( owner )
{
	self endon ( "death" );
	
	for ( ;; )
	{
		self setSelfUsable( owner );
		level waittill_either ( "joined_team", "player_spawned" );
	}
}

deleteTI( TI )
{
	if (isDefined( TI.enemyTrigger ) )
		TI.enemyTrigger Delete();
	
	spot = TI.origin;
	spotAngles = TI.angles;
	
	TI Delete();
	
	dummyGlowStick = spawn( "script_model", spot );
	dummyGlowStick.angles = spotAngles;
	dummyGlowStick setModel( level.spawnGlowModel["friendly"] );
	
	dummyGlowStick setContents( 0 );
	thread dummyGlowStickDelete( dummyGlowStick );
}

dummyGlowStickDelete( stick )
{
	wait(2.5);
	stick Delete();
}

GlowStickEnemyUseListener( owner )
{
	self endon ( "death" );
	level endon ( "game_ended" );
	owner endon ( "disconnect" );
	
	self.enemyTrigger setCursorHint( "HINT_NOICON" );
	self.enemyTrigger setHintString( &"MP_DESTROY_TI" );
	self.enemyTrigger makeEnemyUsable( owner );
	
	for ( ;; )
	{
		self.enemyTrigger waittill ( "trigger", player );
		
		player notify ( "destroyed_insertion", owner );
		player notify( "destroyed_explosive" ); // count towards SitRep Pro challenge

		//playFX( level.spawnGlowSplat, self.origin);		
		
		if ( isDefined( owner ) && player != owner )
			owner thread leaderDialogOnPlayer( "ti_destroyed" );

		player thread deleteTI( self );
	}	
}

setLittlebirdSupport()
{
	self thread killstreakThink( "littlebird_support", 2, "end_littlebird_support_think" );
}

unsetLittlebirdSupport()
{
	self notify ( "end_littlebird_support_think" );
}

setC4Death()
{
	if ( ! self _hasperk( "specialty_pistoldeath" ) )
		self _setperk( "specialty_pistoldeath");
}

unsetC4Death()
{

}