#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\perks\_perkfunctions;

init()
{
	level.perkFuncs = [];

	precacheShader( "combathigh_overlay" );	
	precacheShader( "specialty_painkiller" );

	precacheModel( "weapon_riot_shield_mp" );	
	precacheModel( "viewmodel_riot_shield_mp" );
	precacheString( &"MPUI_CHANGING_KIT" );

	//level.spawnGlowSplat = loadfx( "misc/flare_ambient_destroy" );

	level.spawnGlowModel["enemy"] = "mil_emergency_flare_mp";
	level.spawnGlowModel["friendly"] = "mil_emergency_flare_mp";
	level.spawnGlow["enemy"] = loadfx( "misc/flare_ambient" );
	level.spawnGlow["friendly"] = loadfx( "misc/flare_ambient_green" );
	level.c4Death = loadfx( "explosions/oxygen_tank_explosion" );

	level.spawnFire = loadfx( "props/barrelexp" );
	
	precacheModel( level.spawnGlowModel["friendly"] );
	precacheModel( level.spawnGlowModel["enemy"] );
	
	precacheString( &"MP_DESTROY_TI" );
	
	precacheShaders();

	level._effect["ricochet"] = loadfx( "impacts/large_metalhit_1" );

	// perks that currently only exist in script: these will error if passed to "setPerk", etc... CASE SENSITIVE! must be lower
	level.scriptPerks = [];
	level.perkSetFuncs = [];
	level.perkUnsetFuncs = [];
	level.fauxPerks = [];

	level.scriptPerks["specialty_blastshield"] = true;
	level.scriptPerks["_specialty_blastshield"] = true;
	level.scriptPerks["specialty_akimbo"] = true;
	level.scriptPerks["specialty_siege"] = true;
	level.scriptPerks["specialty_falldamage"] = true;
	level.scriptPerks["specialty_fmj"] = true;
	level.scriptPerks["specialty_shield"] = true;
	level.scriptPerks["specialty_feigndeath"] = true;
	level.scriptPerks["specialty_shellshock"] = true;
	level.scriptPerks["specialty_delaymine"] = true;
	level.scriptPerks["specialty_localjammer"] = true;
	level.scriptPerks["specialty_thermal"] = true;
	level.scriptPerks["specialty_finalstand"] = true;
	level.scriptPerks["specialty_blackbox"] = true;
	level.scriptPerks["specialty_steelnerves"] = true;
	level.scriptPerks["specialty_flashgrenade"] = true;
	level.scriptPerks["specialty_smokegrenade"] = true;
	level.scriptPerks["specialty_concussiongrenade"] = true;
	level.scriptPerks["specialty_challenger"] = true;	
	level.scriptPerks["specialty_tacticalinsertion"] = true;
	level.scriptPerks["specialty_saboteur"] = true;
	level.scriptPerks["specialty_endgame"] = true;
	level.scriptPerks["specialty_rearview"] = true;
	level.scriptPerks["specialty_hardline"] = true;
	level.scriptPerks["specialty_ac130"] = true;
	level.scriptPerks["specialty_sentry_minigun"] = true;
	level.scriptPerks["specialty_predator_missile"] = true;
	level.scriptPerks["specialty_helicopter_minigun"] = true;
	level.scriptPerks["specialty_tank"] = true;
	level.scriptPerks["specialty_precision_airstrike"] = true;
	level.scriptPerks["specialty_bling"] = true;
	level.scriptPerks["specialty_carepackage"] = true;
	level.scriptPerks["specialty_onemanarmy"] = true;
	level.scriptPerks["specialty_littlebird_support"] = true;
	level.scriptPerks["specialty_primarydeath"] = true;
	level.scriptPerks["specialty_secondarybling"] = true;	
	level.scriptPerks["specialty_combathigh"] = true;
	level.scriptPerks["specialty_c4death"] = true;
	level.scriptPerks["specialty_explosivedamage"] = true;
	level.scriptPerks["specialty_copycat"] = true;
	level.scriptPerks["specialty_laststandoffhand"] = true;
	level.scriptPerks["specialty_dangerclose"] = true;

	level.scriptPerks["specialty_extraspecialduration"] = true;
	level.scriptPerks["specialty_rollover"] = true;
	level.scriptPerks["specialty_armorpiercing"] = true;
	level.scriptPerks["specialty_omaquickchange"] = true;
	level.scriptPerks["specialty_fastmeleerecovery"] = true;

	level.scriptPerks["_specialty_rearview"] = true;
	level.scriptPerks["_specialty_onemanarmy"] = true;
	
	level.fauxPerks["specialty_tacticalinsertion"] = true;
	level.fauxPerks["specialty_shield"] = true;


	/*
	level.perkSetFuncs[""] = ::;
	level.perkUnsetFuncs[""] = ::;
	*/

	level.perkSetFuncs["specialty_blastshield"] = ::setBlastShield;
	level.perkUnsetFuncs["specialty_blastshield"] = ::unsetBlastShield;

	level.perkSetFuncs["specialty_siege"] = ::setSiege;
	level.perkUnsetFuncs["specialty_siege"] = ::unsetSiege;
	
	level.perkSetFuncs["specialty_falldamage"] = ::setFreefall;
	level.perkUnsetFuncs["specialty_falldamage"] = ::unsetFreefall;
	
	level.perkSetFuncs["specialty_localjammer"] = ::setLocalJammer;
	level.perkUnsetFuncs["specialty_localjammer"] = ::unsetLocalJammer;

	level.perkSetFuncs["specialty_thermal"] = ::setThermal;
	level.perkUnsetFuncs["specialty_thermal"] = ::unsetThermal;
	
	level.perkSetFuncs["specialty_blackbox"] = ::setBlackBox;
	level.perkUnsetFuncs["specialty_blackbox"] = ::unsetBlackBox;
	
	level.perkSetFuncs["specialty_lightweight"] = ::setLightWeight;
	level.perkUnsetFuncs["specialty_lightweight"] = ::unsetLightWeight;
	
	level.perkSetFuncs["specialty_steelnerves"] = ::setSteelNerves;
	level.perkUnsetFuncs["specialty_steelnerves"] = ::unsetSteelNerves;
	
	level.perkSetFuncs["specialty_delaymine"] = ::setDelayMine;
	level.perkUnsetFuncs["specialty_delaymine"] = ::unsetDelayMine;
			
	level.perkSetFuncs["specialty_finalstand"] = ::setFinalStand;
	level.perkUnsetFuncs["specialty_finalstand"] = ::unsetFinalStand;
	
	level.perkSetFuncs["specialty_combathigh"] = ::setCombatHigh;
	level.perkUnsetFuncs["specialty_combathigh"] = ::unsetCombatHigh;
	
	level.perkSetFuncs["specialty_challenger"] = ::setChallenger;
	level.perkUnsetFuncs["specialty_challenger"] = ::unsetChallenger;
	
	level.perkSetFuncs["specialty_saboteur"] = ::setSaboteur;
	level.perkUnsetFuncs["specialty_saboteur"] = ::unsetSaboteur;
	
	level.perkSetFuncs["specialty_endgame"] = ::setEndGame;
	level.perkUnsetFuncs["specialty_endgame"] = ::unsetEndGame;

	level.perkSetFuncs["specialty_rearview"] = ::setRearView;
	level.perkUnsetFuncs["specialty_rearview"] = ::unsetRearView;

	level.perkSetFuncs["specialty_ac130"] = ::setAC130;
	level.perkUnsetFuncs["specialty_ac130"] = ::unsetAC130;

	level.perkSetFuncs["specialty_sentry_minigun"] = ::setSentryMinigun;
	level.perkUnsetFuncs["specialty_sentry_minigun"] = ::unsetSentryMinigun;

	level.perkSetFuncs["specialty_predator_missile"] = ::setPredatorMissile;
	level.perkUnsetFuncs["specialty_predator_missile"] = ::unsetPredatorMissile;
	
	level.perkSetFuncs["specialty_tank"] = ::setTank;
	level.perkUnsetFuncs["specialty_tank"] = ::unsetTank;

	level.perkSetFuncs["specialty_precision_airstrike"] = ::setPrecision_airstrike;
	level.perkUnsetFuncs["specialty_precision_airstrike"] = ::unsetPrecision_airstrike;
	
	level.perkSetFuncs["specialty_helicopter_minigun"] = ::setHelicopterMinigun;
	level.perkUnsetFuncs["specialty_helicopter_minigun"] = ::unsetHelicopterMinigun;
	
	level.perkSetFuncs["specialty_carepackage"] = ::setCarePackage;
	level.perkUnsetFuncs["specialty_carepackage"] = ::unsetCarePackage;	

	level.perkSetFuncs["specialty_onemanarmy"] = ::setOneManArmy;
	level.perkUnsetFuncs["specialty_onemanarmy"] = ::unsetOneManArmy;	
	
	level.perkSetFuncs["specialty_littlebird_support"] = ::setLittlebirdSupport;
	level.perkUnsetFuncs["specialty_littlebird_support"] = ::unsetLittlebirdSupport;
	
	level.perkSetFuncs["specialty_c4death"] = ::setC4Death;
	level.perkUnsetFuncs["specialty_c4death"] = ::unsetC4Death;
	
	level.perkSetFuncs["specialty_tacticalinsertion"] = ::setTacticalInsertion;
	level.perkUnsetFuncs["specialty_tacticalinsertion"] = ::unsetTacticalInsertion;

	initPerkDvars();

	level thread onPlayerConnect();
}



precacheShaders()
{
	precacheShader( "specialty_blastshield" );
}


givePerk( perkName )
{	
	if ( IsSubStr( perkName, "_mp" ) )
	{
		if ( perkName == "frag_grenade_mp" )
			self SetOffhandPrimaryClass( "frag" );
		if ( perkName == "throwingknife_mp" )
			self SetOffhandPrimaryClass( "throwingknife" );
		
		self _giveWeapon( perkName, 0 );
		self giveStartAmmo( perkName );
		
		self setPerk( perkName, false );
		return;
	}

	if ( isSubStr( perkName, "specialty_null" ) || isSubStr( perkName, "specialty_weapon_" ) )
	{
		self setPerk( perkName, false );
		return;
	}
		
	self _setPerk( perkName );

}


validatePerk( perkIndex, perkName )
{	
	if ( getDvarInt ( "scr_game_perks" ) == 0 )
	{
		if ( tableLookup( "mp/perkTable.csv", 1, perkName, 5 ) != "equipment" )
			return "specialty_null";
	}

	/* Validation disabled for now	
	if ( tableLookup( "mp/perkTable.csv", 1, perkName, 5 ) != ("perk"+perkIndex) )
	{
		println( "^1Warning: (" + self.name + ") Perk " + perkName + " is not allowed for perk slot index " + perkIndex + "; replacing with no perk" );
		return "specialty_null";
	}
	*/

	return perkName;
}


onPlayerConnect()
{
	for(;;)
	{
		level waittill( "connected", player );
		player thread onPlayerSpawned();		
	}
}


onPlayerSpawned()
{
	self endon( "disconnect" );

	self.perks = [];
	self.weaponList = [];
	self.omaClassChanged = false;
		 
	for( ;; )
	{
		self waittill( "spawned_player" );

		self.omaClassChanged = false;
		self thread gambitUseTracker();
	}
}


drawLine( start, end, timeSlice )
{
	drawTime = int(timeSlice * 20);
	for( time = 0; time < drawTime; time++ )
	{
		line( start, end, (1,0,0),false, 1 );
		wait ( 0.05 );
	}
}


cac_modified_damage( victim, attacker, damage, meansofdeath, weapon, impactPoint, impactDir, hitLoc )
{
	assert( isPlayer( victim ) );
	assert( isDefined( victim.team ) );
	
	damageAdd = 0;

	if ( isPrimaryDamage( meansOfDeath ) )
	{	
		assert( isDefined( attacker ) );

		if ( isPlayer( attacker ) && weaponInheritsPerks( weapon ) && attacker _hasPerk( "specialty_bulletdamage" ) && victim _hasPerk( "specialty_armorvest" ) )
			damageAdd += 0;
		else if ( isPlayer( attacker ) && weaponInheritsPerks( weapon ) && attacker _hasPerk( "specialty_bulletdamage" ) )
			damageAdd += damage*level.bulletDamageMod;
		else if ( victim _hasPerk( "specialty_armorvest" ) )
			damageAdd -= damage*(1-level.armorVestMod);

		if ( isPlayer( attacker ) && attacker _hasPerk( "specialty_fmj" ) && victim _hasPerk ( "specialty_armorvest" ) )
			damageAdd += damage*level.hollowPointDamageMod;	
	}
	else if ( isExplosiveDamage( meansOfDeath ) )
	{
		if ( isPlayer( attacker ) && weaponInheritsPerks( weapon ) && attacker _hasPerk( "specialty_explosivedamage" ) && victim _hasPerk( "_specialty_blastshield" ) )
			damageAdd += 0;
		else if ( isPlayer( attacker ) && weaponInheritsPerks( weapon ) && attacker _hasPerk( "specialty_explosivedamage" ) )
			damageAdd += damage*level.explosiveDamageMod;
		else if ( victim _hasPerk( "_specialty_blastshield" ) )
			damageAdd -= damage*(1-level.blastShieldMod);
			
		if ( isKillstreakWeapon( weapon ) && isPlayer( attacker ) && attacker _hasPerk("specialty_dangerclose") )
			damageAdd += damage*level.dangerCloseMod;
	}
	else if (meansOfDeath == "MOD_FALLING")
	{
		if ( victim _hasPerk( "specialty_falldamage" ) )
		{	
			//eventually set a msg to do a roll
			damageAdd = 0;
			damage = 0;
		}	
	}
	
	if ( ( victim.xpScaler == 2 && isDefined( attacker ) ) && ( isPlayer( attacker ) || attacker.classname == "scrip_vehicle" ) )
		damageAdd += 200;
	
	if ( victim _hasperk( "specialty_combathigh" ) )
	{
		if ( IsDefined( self.damageBlockedTotal ) && (!level.teamBased || (isDefined( attacker ) && isDefined( attacker.team ) && victim.team != attacker.team)) )
		{
			damageTotal = damage + damageAdd;
			damageBlocked = (damageTotal - ( damageTotal / 3 ));
			self.damageBlockedTotal += damageBlocked;
			
			if ( self.damageBlockedTotal >= 101 )
			{
				self notify( "combathigh_survived" );
				self.damageBlockedTotal = undefined;
			}
		}

		if ( weapon != "throwingknife_mp" )
		{
			switch ( meansOfDeath )
			{
				case "MOD_FALLING":
				case "MOD_MELEE":
					break;
				default:
					damage = damage/3;
					damageAdd = damageAdd/3;
					break;
			}
		}
	}	
	
	return int( damage + damageAdd );
}

initPerkDvars()
{	
	level.bulletDamageMod = getIntProperty( "perk_bulletDamage", 40 )/100;			// increased bullet damage by this %
	level.hollowPointDamageMod = getIntProperty( "perk_hollowPointDamage", 65 )/100;	// increased bullet damage by this %
	level.armorVestMod = getIntProperty( "perk_armorVest", 75 )/100;					// percentage of damage you take
	level.explosiveDamageMod = getIntProperty( "perk_explosiveDamage", 40 )/100;		// increased explosive damage by this %
	level.blastShieldMod = getIntProperty( "perk_blastShield", 45 )/100;					// percentage of damage you take
	level.riotShieldMod = getIntProperty( "perk_riotShield", 100 )/100;
	level.dangerCloseMod = getIntProperty( "perk_dangerClose", 100 )/100;
	level.armorPiercingMod = getIntProperty( "perk_armorPiercingDamage", 40 )/100;			// increased bullet damage by this %
}

// CAC: Selector function, calls the individual cac features according to player's class settings
// Info: Called every time player spawns during loadout stage
cac_selector()
{
	perks = self.specialty;

	/*
	self.detectExplosives = false;

	if ( self _hasPerk( "specialty_detectexplosive" ) )
		self.detectExplosives = true;
		
	maps\mp\gametypes\_weapons::setupBombSquad();
	*/
}


gambitUseTracker()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );

	if ( getDvarInt ( "scr_game_perks" ) != 1 )
		return;
		
	gameFlagWait( "prematch_done" );

	self notifyOnPlayerCommand( "gambit_on", "+frag" );
}
