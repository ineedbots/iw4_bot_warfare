#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\perks\_perkfunctions;

init()
{
	if (true)
		return;
	preCache();
	setDvarIfUninitialized("scr_allowSpecialist", true);
	setDvarIfUninitialized("scr_allowStalkerPerk", true);
	setDvarIfUninitialized("scr_allowViewKickPerk", true);
	setDvarIfUninitialized("scr_allowArmorvestPerk", true);
	
	level thread onPlayerConnect();
}

onPlayerConnect()
{
	for(;;)
	{
		level waittill("connected", player);
		player thread onPlayerSpawn();
	}
}

onPlayerSpawn()
{
	self endon("disconnect");
	for(;;)
	{
		self waittill("spawned_player");
		self thread doPerks();
		self thread startUpSpecialist();
	}
}

stopOnDeath()
{
	self endon("disconnect");
	self waittill("death");
	self.moveSpeedScaler = 1.0;
	/*self setclientdvars("bg_viewkickScale", 0.2,
						  "bg_viewkickMax", 90,
						  "bg_viewkickMin", 5,
						  "bg_viewkickRandom", 0.4,
						  "bg_shock_viewKickFadeTime", 3,
						  "bg_shock_viewKickPeriod", 0.75,
						  "bg_shock_viewKickRadius", 0.05);
	*/
}

doPerks()
{
	self endon("disconnect");
	self endon("death");
	self thread stopOnDeath();
	for(;;)
	{
		if(getDvarInt("scr_allowStalkerPerk") && self _hasPerk("specialty_delaymine"))
		{
			switch( WeaponClass( self getCurrentWeapon() ) )
			{
				case "rifle":
					self.moveSpeedScaler = 1 + (1.2*self playerADS());
					self maps\mp\gametypes\_weapons::updateMoveSpeedScale( "primary" );
				break;
				case "smg":
					self.moveSpeedScaler = 1 + (0.3*self playerADS());
					self maps\mp\gametypes\_weapons::updateMoveSpeedScale( "primary" );
				break;
				case "mg":
					self.moveSpeedScaler = 1 + (1*self playerADS());
					self maps\mp\gametypes\_weapons::updateMoveSpeedScale( "primary" );
				break;
				case "sniper":
					self.moveSpeedScaler = 1 + (0.2*self playerADS());
					self maps\mp\gametypes\_weapons::updateMoveSpeedScale( "primary" );
				break;
				case "pistol":
					self.moveSpeedScaler = 1 + (0.3*self playerADS());
					self maps\mp\gametypes\_weapons::updateMoveSpeedScale( "primary" );
				break;
				case "spread":
					self.moveSpeedScaler = 1 + (0.3*self playerADS());
					self maps\mp\gametypes\_weapons::updateMoveSpeedScale( "primary" );
				break;
				case "rocketlauncher":
					self.moveSpeedScaler = 1 + (1*self playerADS());
					self maps\mp\gametypes\_weapons::updateMoveSpeedScale( "primary" );
				break;
				default:
					self.moveSpeedScaler = 1.0;
					self maps\mp\gametypes\_weapons::updateMoveSpeedScale( "primary" );
				break;
			}
		}
		else
		{
			self.moveSpeedScaler = 1.0;
			self maps\mp\gametypes\_weapons::updateMoveSpeedScale( "primary" );
		}
		
		/*if(getDvarInt("scr_allowViewkickPerk") && self _hasPerk("specialty_secondarybling"))
		{
			self setclientdvars("bg_viewkickScale", 0.0,
						  "bg_viewkickMax", 0,
						  "bg_viewkickMin", 0,
						  "bg_viewkickRandom", 0.0,
						  "bg_shock_viewKickFadeTime", 0,
						  "bg_shock_viewKickPeriod", 0.0,
						  "bg_shock_viewKickRadius", 0.0);
		}
		else
		{
			self setclientdvars("bg_viewkickScale", 0.2,
						  "bg_viewkickMax", 90,
						  "bg_viewkickMin", 5,
						  "bg_viewkickRandom", 0.4,
						  "bg_shock_viewKickFadeTime", 3,
						  "bg_shock_viewKickPeriod", 0.75,
						  "bg_shock_viewKickRadius", 0.05);
		}*/
		
		if(getDvarInt("scr_allowArmorvestPerk") && self _hasPerk("specialty_rollover"))
		{
			if(!self _hasPerk("specialty_armorvest"))
				self _setPerk("specialty_armorvest");
		}
		else
		{
			if(self _hasPerk("specialty_armorvest"))
				self _unSetPerk("specialty_armorvest");
		}
		waitframe();
	}
}

startUpSpecialist()
{
	self endon("disconnect");
	self endon("death");
	
	if(self getPlayerData("killstreaks", 0) == "airdrop_mega" && self getPlayerData("killstreaks", 1) == "nuke" && self getPlayerData("killstreaks", 2) == "none" && isSubStr(self.curClass, "custom") && level.killstreakRewards && getdvarint("scr_game_perks") && !self hasWeapon("onemanarmy_mp") && getDvarInt("scr_allowSpecialist"))
	{
		if(!isDefined(self.pers["specialist"]["class_num"]) || self.pers["specialist"]["class_num"] != self.class_num)
		{
			self initSpecialist();//init perks
		}
		self doSpecHUD();//show the HUD
		self multiRoundFix();//give perks and stuff on start of new round
		self thread specThink();//watches kills and gives bonus
	}
}

initSpecialist()
{
	self.pers["specialist"]["class_num"] = self.class_num;
	
	self.pers["specialist"]["perks"][0] = getRandomPerk( 0 );
	self.pers["specialist"]["perks"][1] = getRandomPerk( 1 );
	self.pers["specialist"]["perks"][2] = getRandomPerk( 2 );

	while(self getPlayerData("customClasses", self.pers["specialist"]["class_num"], "perks", 1) == self.pers["specialist"]["perks"][0])
	{
		self.pers["specialist"]["perks"][0] = getRandomPerk( 0 );
	}
	while(self getPlayerData("customClasses", self.pers["specialist"]["class_num"], "perks", 2) == self.pers["specialist"]["perks"][1])
	{
		self.pers["specialist"]["perks"][1] = getRandomPerk( 1 );
	}
	while(self getPlayerData("customClasses", self.pers["specialist"]["class_num"], "perks", 3) == self.pers["specialist"]["perks"][2])
	{
		self.pers["specialist"]["perks"][2] = getRandomPerk( 2 );
	}
}

multiRoundFix()
{
	self.specialist_message_1=false;
	self.specialist_message_2=false;
	self.specialist_message_3=false;
	self.specialist_message_4=false;
	self.topStreak = 0;
	hasHardline = self _hasPerk("specialty_hardline");
	for(i=0;i<=self.pers["cur_kill_streak"];i++)
	{
		if(hasHardline)
			ii = i + 1;
		else
			ii = i;
		
		self.topStreak = i;
		
		switch(ii)
		{
			case 2:
				self.specialist_message_1 = true;
				self _setPerk(self.pers["specialist"]["perks"][0]);
				upgrade = tablelookup( "mp/perktable.csv", 1, self.pers["specialist"]["perks"][0], 8 );
				if ( self isItemUnlocked( upgrade ) )
					self _setPerk( upgrade );
				
				self.ksOneIcon.alpha = 1;
			break;
			case 4:
				self.specialist_message_2 = true;
				self _setPerk(self.pers["specialist"]["perks"][1]);
				upgrade = tablelookup( "mp/perktable.csv", 1, self.pers["specialist"]["perks"][1], 8 );
				if ( self isItemUnlocked( upgrade ) )
					self _setPerk( upgrade );
				
				self.ksTwoIcon.alpha = 1;
			break;
			case 6:
				self.specialist_message_3 = true;
				self _setPerk(self.pers["specialist"]["perks"][2]);
				upgrade = tablelookup( "mp/perktable.csv", 1, self.pers["specialist"]["perks"][2], 8 );
				if ( self isItemUnlocked( upgrade ) )
					self _setPerk( upgrade );
				
				self.ksThrIcon.alpha = 1;
			break;
			case 8:
				self.specialist_message_4 = true;
				self setAllPerks();	
				self.ksForIcon.alpha = 1;
			break;
		}
	}
	self thread maps\mp\gametypes\_class::setKillstreaks( "nuke", "none", "none" );//update for hardline
}

specThink()
{
	self endon("disconnect");
	self endon("death");
	self thread stopSpecialistPerkOnDeath();
	for(;;)
	{
		self waittill("killed_enemy");
		hasHardline = self _hasPerk("specialty_hardline");
		for(i=self.topStreak;i<=self.pers["cur_kill_streak"];i++)
		{
			if(hasHardline)
				ii = i + 1;
			else
				ii = i;
				
			if(i > self.topStreak)
			{
				self.topStreak = i;
				if(ii%2 == 0)
				{
					self thread maps\mp\gametypes\_rank::giveRankXP( "specialist_bonus", 50 );
				
					if(!level.hardcoreMode)
						self thread underScorePopup("Specialist Bonus!", (1, 1, 0.5), 0);
				}
			}
			switch(ii)
			{
				case 2:
					if(!self.specialist_message_1)
					{
						self.specialist_message_1=true;
						self.ksOneIcon.alpha = 1;
						self Specialist( self.SpeicliastPerk1S, GetGoodColor(), self.SpecialistPerk1M, self.SpecialistPerk1D, self.pers["specialist"]["perks"][0] );
						self notify( "received_earned_killstreak" ); 
					}
				break;
				case 4:
					if(!self.specialist_message_2)
					{
						self.specialist_message_2=true;
						self.ksTwoIcon.alpha = 1;
						self Specialist( self.SpeicliastPerk2S, GetGoodColor(), self.SpecialistPerk2M, self.SpecialistPerk2D, self.pers["specialist"]["perks"][1] );
						self notify( "received_earned_killstreak" ); 
					}
				break;
				case 6:
					if(!self.specialist_message_3)
					{
						self.specialist_message_3=true; 
						self.ksThrIcon.alpha = 1;
						self Specialist( self.SpeicliastPerk3S, GetGoodColor(), self.SpecialistPerk3M, self.SpecialistPerk3D, self.pers["specialist"]["perks"][2] );
						self notify( "received_earned_killstreak" ); 
					}
				break;
				case 8:
					if(!self.specialist_message_4)
					{
						self.specialist_message_4=true;
						self.ksForIcon.alpha = 1;
						self setAllPerks();	
						upgrade = tablelookup( "mp/perktable.csv", 1, "specialty_onemanarmy", 8 );
						if ( self isItemUnlocked( upgrade ) )
							self Specialist( "Specialist Bonus", GetGoodColor(), "specialty_onemanarmy_upgrade", "Received all Perks!" );
						else
							self Specialist( "Specialist Bonus", GetGoodColor(), "specialty_onemanarmy", "Received all Perks!" );
						
						self notify( "received_earned_killstreak" ); 
					}
				break;
			}
		}
		self thread maps\mp\gametypes\_class::setKillstreaks( "nuke", "none", "none" );//update for hardline
	}
}

stopSpecialistPerkOnDeath()
{
	self endon("disconnect");
	self waittill("death");
	self player_recoilScaleOn( 1 );
	self player_recoilScaleOff();  
}

//spec fuctions - mainly from Intricate
preCache()
{
	PrecacheShader(getPerkMaterial(tablelookup( "mp/perktable.csv", 1, "specialty_scavenger", 8 )));
	PrecacheShader(getPerkMaterial(tablelookup( "mp/perktable.csv", 1, "specialty_fastreload", 8 )));
	PrecacheShader(getPerkMaterial(tablelookup( "mp/perktable.csv", 1, "specialty_marathon", 8 )));
	PrecacheShader(getPerkMaterial(tablelookup( "mp/perktable.csv", 1, "specialty_bulletdamage", 8 )));
	PrecacheShader(getPerkMaterial(tablelookup( "mp/perktable.csv", 1, "specialty_lightweight", 8 )));
	PrecacheShader(getPerkMaterial(tablelookup( "mp/perktable.csv", 1, "specialty_coldblooded", 8 )));
	PrecacheShader(getPerkMaterial(tablelookup( "mp/perktable.csv", 1, "specialty_explosivedamage", 8 )));
	PrecacheShader(getPerkMaterial(tablelookup( "mp/perktable.csv", 1, "specialty_hardline", 8 )));
	PrecacheShader(getPerkMaterial(tablelookup( "mp/perktable.csv", 1, "specialty_bulletaccuracy", 8 )));
	PrecacheShader(getPerkMaterial(tablelookup( "mp/perktable.csv", 1, "specialty_heartbreaker", 8 )));
	PrecacheShader(getPerkMaterial(tablelookup( "mp/perktable.csv", 1, "specialty_detectexplosive", 8 )));
	PrecacheShader(getPerkMaterial(tablelookup( "mp/perktable.csv", 1, "specialty_extendedmelee", 8 )));
	PrecacheShader(getPerkMaterial(tablelookup( "mp/perktable.csv", 1, "specialty_localjammer", 8 )));
	PrecacheShader(getPerkMaterial("specialty_scavenger"));
	PrecacheShader(getPerkMaterial("specialty_fastreload"));
	PrecacheShader(getPerkMaterial("specialty_marathon"));
	PrecacheShader(getPerkMaterial("specialty_bulletdamage"));
	PrecacheShader(getPerkMaterial("specialty_lightweight"));
	PrecacheShader(getPerkMaterial("specialty_coldblooded"));
	PrecacheShader(getPerkMaterial("specialty_explosivedamage"));
	PrecacheShader(getPerkMaterial("specialty_hardline"));
	PrecacheShader(getPerkMaterial("specialty_bulletaccuracy"));
	PrecacheShader(getPerkMaterial("specialty_heartbreaker"));
	PrecacheShader(getPerkMaterial("specialty_detectexplosive"));
	PrecacheShader(getPerkMaterial("specialty_extendedmelee"));
	PrecacheShader(getPerkMaterial("specialty_localjammer"));
	PrecacheShader("specialty_onemanarmy");
	PrecacheShader("specialty_onemanarmy_upgrade");
	
	//Strings
	PrecacheString( &"PERKS_MARATHON" );	
	PrecacheString( &"PERKS_SLEIGHT_OF_HAND" );	
	PrecacheString( &"PERKS_SCAVENGER" );	
	//--
	PrecacheString( &"PERKS_STOPPING_POWER" );	
	PrecacheString( &"PERKS_LIGHTWEIGHT" );	
	PrecacheString( &"PERKS_COLDBLOODED" );	
	PrecacheString( &"PERKS_DANGERCLOSE" );
	PrecacheString( &"PERKS_HARDLINE" );	
	//--
	PrecacheString( &"PERKS_EXTENDEDMELEE" );	
	PrecacheString( &"PERKS_STEADY_AIM" );	
	PrecacheString( &"PERKS_LOCALJAMMER" );	
	PrecacheString( &"PERKS_BOMB_SQUAD" );	
	PrecacheString( &"PERKS_NINJA" );
	//Description
	PrecacheString( &"PERKS_DESC_MARATHON" );
	PrecacheString( &"PERKS_FASTER_RELOADING" );
	PrecacheString( &"PERKS_DESC_SCAVENGER" );
	//--
	PrecacheString( &"PERKS_INCREASED_BULLET_DAMAGE" );
	PrecacheString( &"PERKS_DESC_LIGHTWEIGHT" );
	PrecacheString( &"PERKS_DESC_COLDBLOODED" );
	PrecacheString( &"PERKS_HIGHER_EXPLOSIVE_WEAPON" );
	PrecacheString( &"PERKS_DESC_HARDLINE" );
	//--
	PrecacheString( &"PERKS_DESC_EXTENDEDMELEE" );
	PrecacheString( &"PERKS_INCREASED_HIPFIRE_ACCURACY" );
	PrecacheString( &"PERKS_DESC_LOCALJAMMER" );
	PrecacheString( &"PERKS_ABILITY_TO_SEEK_OUT_ENEMY" );
	PrecacheString( &"PERKS_DESC_HEARTBREAKER" );
}

doSpecHUD()
{
	upgrade = tablelookup( "mp/perktable.csv", 1, self.pers["specialist"]["perks"][0], 8 );
	if ( self isItemUnlocked( upgrade ) )
	{
		self.SpecialistPerk1M = getPerkMaterial( upgrade );
	}
	else
	{
		self.SpecialistPerk1M = getPerkMaterial( self.pers["specialist"]["perks"][0] );
	}
	
	upgrade = tablelookup( "mp/perktable.csv", 1, self.pers["specialist"]["perks"][1], 8 );
	if ( self isItemUnlocked( upgrade ) )
	{
		self.SpecialistPerk2M = getPerkMaterial( upgrade );
	}
	else
	{
		self.SpecialistPerk2M = getPerkMaterial( self.pers["specialist"]["perks"][1] );
	}
	
	upgrade = tablelookup( "mp/perktable.csv", 1, self.pers["specialist"]["perks"][2], 8 );
	if ( self isItemUnlocked( upgrade ) )
	{
		self.SpecialistPerk3M = getPerkMaterial( upgrade );
	}
	else
	{
		self.SpecialistPerk3M = getPerkMaterial( self.pers["specialist"]["perks"][2] );
	}
	//--
	self.SpeicliastPerk1S = getPerkString( self.pers["specialist"]["perks"][0] );
	self.SpeicliastPerk2S = getPerkString( self.pers["specialist"]["perks"][1] );
	self.SpeicliastPerk3S = getPerkString( self.pers["specialist"]["perks"][2] );
	//--
	self.SpecialistPerk1D = getPerkDescription( self.pers["specialist"]["perks"][0] );
	self.SpecialistPerk2D = getPerkDescription( self.pers["specialist"]["perks"][1] );
	self.SpecialistPerk3D = getPerkDescription( self.pers["specialist"]["perks"][2] );
	//Intricate - They're set so leggo.
	if(!level.hardCoreMode)
	{
		self.ksOneIcon = createKSIcon( self.SpecialistPerk1M, -90 );
		self.ksTwoIcon = createKSIcon( self.SpecialistPerk2M, -115 );
		self.ksThrIcon = createKSIcon( self.SpecialistPerk3M, -140 );
		
		upgrade = tablelookup( "mp/perktable.csv", 1, "specialty_onemanarmy", 8 );
		if ( self isItemUnlocked( upgrade ) )
		{
			self.ksForIcon = createKSIcon( "specialty_onemanarmy_upgrade", -165 );
		}
		else
		{
			self.ksForIcon = createKSIcon( "specialty_onemanarmy", -165 );
		}
	}
	
	// Create the under score popup element
	self.mw3_scorePopup = newClientHudElem( self );
	self.mw3_scorePopup.horzAlign = "center";
	self.mw3_scorePopup.vertAlign = "middle";
	self.mw3_scorePopup.alignX = "center";
	self.mw3_scorePopup.alignY = "middle";
	self.mw3_scorePopup.x = 35;
	self.mw3_scorePopup.y = -48;
	self.mw3_scorePopup.font = "hudbig";
	self.mw3_scorePopup.fontscale = 0.65;
	self.mw3_scorePopup.archived = false;
	self.mw3_scorePopup.color = (0.5, 0.5, 0.5);
	self.mw3_scorePopup.sort = 10000;
	
	self thread destorySpecHudOnEnd();
}

destorySpecHudOnEnd()
{
	self waittill_either("death", "disconnect");
	
	self.ksOneIcon.alpha = 0;
	self.ksTwoIcon.alpha = 0;
	self.ksThrIcon.alpha = 0;
	self.ksForIcon.alpha = 0;
	self.ksForIcon destroy();
	self.ksThrIcon destroy();
	self.ksTwoIcon destroy();
	self.ksOneIcon destroy();
	
	self.mw3_scorePopup.alpha = 0;
	self.mw3_scorePopup destroy();
}

Specialist( text, glowColor, shader, description, perk )
{
	//Intricate - Well since we have for the 8th kill SetAllPerks, I couldn't make a big ass line.
	//So instead we'll add an extra property to see if we have a perk to be set.
	if( isDefined( perk ) )
	{
		self _setPerk( perk );
		upgrade = tablelookup( "mp/perktable.csv", 1, perk, 8 );
		if ( self isItemUnlocked( upgrade ) )
			self _setPerk( upgrade );
	}

	notifyData = spawnStruct();

	notifyData.glowColor = glowColor;
	notifyData.hideWhenInMenu = false;
	notifyData.titleText = text;
	notifyData.notifyText = description;
	notifyData.iconName = shader;
	notifyData.sound = "mp_bonus_start";

	self thread maps\mp\gametypes\_hud_message::notifyMessage( notifyData );
}

underScorePopup(string, hudColor, glowAlpha)
{
	// Display text under the score popup
	self endon( "disconnect" );

	if ( string == "" )
		return;

	self notify( "underScorePopup" );
	self endon( "underScorePopup" );

	self.mw3_scorePopup.color = hudColor;
	self.mw3_scorePopup.glowColor = hudColor;
	self.mw3_scorePopup.glowAlpha = glowAlpha;

	self.mw3_scorePopup setText(string);
	self.mw3_scorePopup.alpha = 0.85;

	wait 1.0;

	self.mw3_scorePopup fadeOverTime( 0.75 );
	self.mw3_scorePopup.alpha = 0;
}

setAllPerks()
{
	self _setPerk("specialty_marathon");
	if ( self isItemUnlocked( "specialty_fastmantle" ) )
		self _setPerk("specialty_fastmantle");
		
	self _setPerk("specialty_fastreload");
	if ( self isItemUnlocked( "specialty_quickdraw" ) )
		self _setPerk("specialty_quickdraw");
		
	self _setPerk("specialty_lightweight");
	if ( self isItemUnlocked( "specialty_fastsprintrecovery" ) )
		self _setPerk("specialty_fastsprintrecovery");
		
	self _setPerk("specialty_bulletdamage");
	if ( self isItemUnlocked( "specialty_armorpiercing" ) )
		self _setPerk("specialty_armorpiercing");
		
	self _setPerk("specialty_coldblooded");
	if ( self isItemUnlocked( "specialty_spygame" ) )
		self _setPerk("specialty_spygame");
		
	self _setPerk("specialty_explosivedamage");
	if ( self isItemUnlocked( "specialty_dangerclose" ) )
		self _setPerk("specialty_dangerclose");	
		
	self _setPerk("specialty_extendedmelee");
	if ( self isItemUnlocked( "specialty_falldamage" ) )
		self _setPerk("specialty_falldamage");
		
	self _setPerk("specialty_bulletaccuracy");
	if ( self isItemUnlocked( "specialty_holdbreath" ) )
		self _setPerk("specialty_holdbreath");
		
	self _setPerk("specialty_heartbreaker");
	if ( self isItemUnlocked( "specialty_quieter" ) )
		self _setPerk("specialty_quieter");
		
	self _setPerk("specialty_detectexplosive");
	if ( self isItemUnlocked( "specialty_selectivehearing" ) )
		self _setPerk("specialty_selectivehearing");
		
	if ( self isItemUnlocked( "specialty_delaymine" ) )
		self _setPerk("specialty_delaymine");//stalker
		
	self _setPerk("specialty_hardline");//no oma, scav pro, laststand (pro), or scramb for less annoyance
	if ( self isItemUnlocked( "specialty_rollover" ) )
		self _setPerk("specialty_rollover");//jugs
	
	self _setPerk("specialty_scavenger");
	
	if ( self isItemUnlocked( "specialty_secondarybling" ) )
		self _setPerk("specialty_secondarybling");//no flinch
	
	self player_recoilScaleOn(0.75);//recoil prof
}

getRandomPerk( type )
{
	perks = [];
	//Intricate - Much thanks to master131 for showing me arrary's & strTok.
	perks[perks.size] = strTok("specialty_scavenger,specialty_fastreload,specialty_marathon", ",");
	perks[perks.size] = strTok("specialty_bulletdamage,specialty_lightweight,specialty_coldblooded,specialty_explosivedamage,specialty_hardline", ",");
	perks[perks.size] = strTok("specialty_bulletaccuracy,specialty_heartbreaker,specialty_detectexplosive,specialty_extendedmelee,specialty_localjammer", ",");

	return perks[type][randomInt(perks[type].size)];
}

getPerkDescription( perk )
{
	//Intricate - Thanks to EMZ for the Black Ops variant, changed for MW2.
	//Intricate - This function gives the STRING for the PERK DESCRIPTION.
	return tableLookUpIString( "mp/perkTable.csv", 1, perk, 4 );
}

getPerkMaterial( perk )
{
	//Intricate - Thanks to EMZ for the Black Ops variant, changed for MW2.
	//Intricate - This function gives the MATERIAL for the PERK. (Most of the time in MW2 the name of the perk = shader but other times it's not.)
	return tableLookUp( "mp/perkTable.csv", 1, perk, 3 );
}

getPerkString( perk )
{
	//Intricate - Thanks to EMZ for the Black Ops variant, changed for MW2.
	//Intricate - This function gives the STRING for the PERK.
	return tableLookUpIString( "mp/perkTable.csv", 1, perk, 2 );
}

getGoodColor()
{
	color = [];
	//Intricate - This is momo5502's code, rather interesting way too :D.
	for( i = 0; i < 3; i++ )
	{
		color[i] = randomint( 2 );
	}

	if( color[0] == color[1] && color[1] == color[2] )
	{
		rand = randomint(3);
		color[rand] += 1;
		color[rand] %= 2;
	}

	return ( color[0], color[1], color[2] );
}

createKSIcon( ksShader, y )
{
	ksIcon = createIcon( ksShader, 20, 20 );
	ksIcon setPoint( "BOTTOM RIGHT", "BOTTOM RIGHT", -32, y );
	ksIcon.alpha = 0.5;
	ksIcon.hideWhenInMenu = true;
	ksIcon.foreground = true;
	return ksIcon;
}