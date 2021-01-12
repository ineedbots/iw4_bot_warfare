/*
	_class modded
	Author: INeedGames
	Date: 09/22/2020

	Features:
		- restrict certain killstreaks, deathstreaks, weapons, perks, attachments and weapon-attachment combos by dvars
		- define your stock killstreaks, deathstreaks weapons, perks which are given, when the player uses loadout which is restricted	
		- customize the amount of consecutive kills needed to get a certain killstreak by dvar

	dvar syntax to be used in server.cfg:
	set scr_allow_loadouttorestrict "0"

	e.g.:
	set scr_allow_gl "0" //to restrict grenade launcher attachment

	Thanks: banz
*/

#include common_scripts\utility;
// check if below includes are removable
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

init()
{
	level.classMap["class0"] = 0;
	level.classMap["class1"] = 1;
	level.classMap["class2"] = 2;
	level.classMap["class3"] = 3;
	level.classMap["class4"] = 4;
	level.classMap["class5"] = 5;
	level.classMap["class6"] = 6;
	level.classMap["class7"] = 7;
	level.classMap["class8"] = 8;
	level.classMap["class9"] = 9;
	level.classMap["class10"] = 10;
	level.classMap["class11"] = 11;
	level.classMap["class12"] = 12;
	level.classMap["class13"] = 13;
	level.classMap["class14"] = 14;

	level.classMap["custom1"] = 0;
	level.classMap["custom2"] = 1;
	level.classMap["custom3"] = 2;
	level.classMap["custom4"] = 3;
	level.classMap["custom5"] = 4;
	level.classMap["custom6"] = 5;
	level.classMap["custom7"] = 6;
	level.classMap["custom8"] = 7;
	level.classMap["custom9"] = 8;
	level.classMap["custom10"] = 9;
	level.classMap["custom11"] = 10;
	level.classMap["custom12"] = 11;
	level.classMap["custom13"] = 12;
	level.classMap["custom14"] = 13;
	level.classMap["custom15"] = 14;
	
	level.classMap["copycat"] = -1;
	
	/#
	// classes testclients may choose from.
	level.botClasses = [];
	level.botClasses[0] = "class0";
	level.botClasses[1] = "class0";
	level.botClasses[2] = "class0";
	level.botClasses[3] = "class0";
	level.botClasses[4] = "class0";
	#/
	
	level.defaultClass = "CLASS_ASSAULT";
	
	level.classTableName = "mp/classTable.csv";
	
	//precacheShader( "waypoint_bombsquad" );
	precacheShader( "specialty_pistoldeath" );
	precacheShader( "specialty_finalstand" );


	//private match dvars here: (examples)
	
	//blocking all ump45's
	/*setDvar("scr_allow_ump45", 0);
	setDvar("scr_allow_ak47_gl_mp", 0);
	//blocking all g18's with akimbo
	setDvar("scr_allow_glock_akimbo_mp", 0);
	setDvar("scr_allow_glock_akimbo_fmj_mp", 0);
	setDvar("scr_allow_glock_akimbo_silencer_mp", 0);
	setDvar("scr_allow_glock_akimbo_xmags_mp", 0);
	//blocking all aa12's
	setDvar("scr_allow_aa12", 0);
	//remove all thermal attachments
	setDvar("scr_allow_thermal", 0);
	//restrict claymore
	setDvar("scr_allow_claymore_mp", 0);
	//restrict commando perk
	setDvar("scr_allow_specialty_extendedmelee", 0);*/
	
	
	/*setDvar("scr_allow_gl", 0);
	setDvar("scr_allow_harrier_airstrike", 0);
	setDvar("scr_allow_nuke", 0);
	setDvar("scr_allow_akimbo", 0);
	setDvar("scr_streakcount_uav", 4);
	setDvar("scr_streakcount_emp", 13);
	setDvar("scr_streakcount_harrier_airstrike", 8);
	setDvar("scr_streakcount_nuke", 15);
	setDvar("scr_allow_mp5k_silencer_mp", 0);
	setDvar("scr_num_flash", 0);
	setDvar("scr_num_stun", 0);*/

	/*
	**	Things that will replace restricted ones, if more than one is specified one of those will be chosen 	
	**	randomly 
	*/
	//multiple definitions possible
	setDvarIfUninitialized( "scr_default_primarys", "m4,famas" );
	setDvarIfUninitialized( "scr_default_secondarys", "usp" );
	setDvarIfUninitialized( "scr_default_perks1", "specialty_fastreload,specialty_scavenger" );
	setDvarIfUninitialized( "scr_default_perks2", "specialty_bulletdamage" );
	setDvarIfUninitialized( "scr_default_perks3", "specialty_bulletaccuracy,specialty_detectexplosive" );
	setDvarIfUninitialized( "scr_default_equipment", "frag_grenade_mp" );
	setDvarIfUninitialized( "scr_default_offhand", "smoke_grenade" );
	setDvarIfUninitialized( "scr_default_deathstreak", "none" );

	// message
	setDvarIfUninitialized( "scr_restriction_messages", 0 );
	setDvarIfUninitialized("scr_num_flash", 2);
	setDvarIfUninitialized("scr_num_stun", 2);

	/*
	** Don't touch the definions below!
	*/
	level.defaultPrimarys = getDvar("scr_default_primarys");
	level.defaultSecondarys = getDvar("scr_default_secondarys");
	level.defaultPerks1 = getDvar("scr_default_perks1");
	level.defaultPerks2 = getDvar("scr_default_perks2");
	level.defaultPerks3 = getDvar("scr_default_perks3");
	
	level.defaultEquipment = getDvar("scr_default_equipment");
	level.defaultOffhand = getDvar("scr_default_offhand");
	level.defaultDeathstreak = getDvar("scr_default_deathstreak");

	level.restrictionMessages = getDvarInt("scr_restriction_messages");

	//only one Flash/Stun grenade
	level.numFlash = getDvarInt( "scr_num_flash");
	level.numStun = getDvarInt( "scr_num_stun");


	level thread onPlayerConnecting();
}


getClassChoice( response )
{
	assert( isDefined( level.classMap[response] ) );
	
	return response;
}

getWeaponChoice( response )
{
	tokens = strtok( response, "," );
	if ( tokens.size > 1 )
		return int(tokens[1]);
	else
		return 0;
}


logClassChoice( class, primaryWeapon, specialType, perks )
{
	if ( class == self.lastClass )
		return;

	self logstring( "choseclass: " + class + " weapon: " + primaryWeapon + " special: " + specialType );		
	for( i=0; i<perks.size; i++ )
		self logstring( "perk" + i + ": " + perks[i] );
	
	self.lastClass = class;
}


cac_getWeapon( classIndex, weaponIndex )
{
	return self getPlayerData( "customClasses", classIndex, "weaponSetups", weaponIndex, "weapon" );
}

cac_getWeaponAttachment( classIndex, weaponIndex )
{
	return self getPlayerData( "customClasses", classIndex, "weaponSetups", weaponIndex, "attachment", 0 );
}

cac_getWeaponAttachmentTwo( classIndex, weaponIndex )
{
	return self getPlayerData( "customClasses", classIndex, "weaponSetups", weaponIndex, "attachment", 1 );
}

cac_getWeaponCamo( classIndex, weaponIndex )
{
	return self getPlayerData( "customClasses", classIndex, "weaponSetups", weaponIndex, "camo" );
}

cac_getPerk( classIndex, perkIndex )
{
	return self getPlayerData( "customClasses", classIndex, "perks", perkIndex );
}

cac_getKillstreak( classIndex, streakIndex )
{
	return self getPlayerData( "killstreaks", streakIndex );
}

cac_getDeathstreak( classIndex )
{
	return self getPlayerData( "customClasses", classIndex, "perks", 4 );
}

cac_getOffhand( classIndex )
{
	return self getPlayerData( "customClasses", classIndex, "specialGrenade" );
}



table_getWeapon( tableName, classIndex, weaponIndex )
{
	if ( weaponIndex == 0 )
		return tableLookup( tableName, 0, "loadoutPrimary", classIndex + 1 );
	else
		return tableLookup( tableName, 0, "loadoutSecondary", classIndex + 1 );
}

table_getWeaponAttachment( tableName, classIndex, weaponIndex, attachmentIndex )
{
	tempName = "none";
	
	if ( weaponIndex == 0 )
	{
		if ( !isDefined( attachmentIndex ) || attachmentIndex == 0 )
			tempName = tableLookup( tableName, 0, "loadoutPrimaryAttachment", classIndex + 1 );
		else
			tempName = tableLookup( tableName, 0, "loadoutPrimaryAttachment2", classIndex + 1 );
	}
	else
	{
		if ( !isDefined( attachmentIndex ) || attachmentIndex == 0 )
			tempName = tableLookup( tableName, 0, "loadoutSecondaryAttachment", classIndex + 1 );
		else
			tempName = tableLookup( tableName, 0, "loadoutSecondaryAttachment2", classIndex + 1 );
	}
	
	if ( tempName == "" || tempName == "none" )
		return "none";
	else
		return tempName;
	
	
}

table_getWeaponCamo( tableName, classIndex, weaponIndex )
{
	if ( weaponIndex == 0 )
		return tableLookup( tableName, 0, "loadoutPrimaryCamo", classIndex + 1 );
	else
		return tableLookup( tableName, 0, "loadoutSecondaryCamo", classIndex + 1 );
}

table_getEquipment( tableName, classIndex, perkIndex )
{
	assert( perkIndex < 5 );
	return tableLookup( tableName, 0, "loadoutEquipment", classIndex + 1 );
}

table_getPerk( tableName, classIndex, perkIndex )
{
	assert( perkIndex < 5 );
	return tableLookup( tableName, 0, "loadoutPerk" + perkIndex, classIndex + 1 );
}

table_getOffhand( tableName, classIndex )
{
	return tableLookup( tableName, 0, "loadoutOffhand", classIndex + 1 );
}

table_getKillstreak( tableName, classIndex, streakIndex )
{
//	return tableLookup( tableName, 0, "loadoutStreak" + streakIndex, classIndex + 1 );
	return ( "none" );
}

table_getDeathstreak( tableName, classIndex )
{
	return tableLookup( tableName, 0, "loadoutDeathstreak", classIndex + 1 );
}

getClassIndex( className )
{
	assert( isDefined( level.classMap[className] ) );
	
	return level.classMap[className];
}

/*
getPerk( perkIndex )
{
	if( isSubstr( self.pers["class"], "CLASS_CUSTOM" ) )
		return cac_getPerk( self.class_num, perkIndex );
	else
		return table_getPerk( level.classTableName, self.class_num, perkIndex );	
}

getWeaponCamo( weaponIndex )
{
	if( isSubstr( self.pers["class"], "CLASS_CUSTOM" ) )
		return cac_getWeaponCamo( self.class_num, weaponIndex );
	else
		return table_getWeaponCamo( level.classTableName, self.class_num, weaponIndex );	
}
*/

cloneLoadout()
{
	clonedLoadout = [];
	
	class = self.curClass;
	
	if ( class == "copycat" )
		return ( undefined );
	
	if( isSubstr( class, "custom" ) )
	{
		class_num = getClassIndex( class );

		loadoutPrimaryAttachment2 = "none";
		loadoutSecondaryAttachment2 = "none";

		loadoutPrimary = cac_getWeapon( class_num, 0 );
		loadoutPrimaryAttachment = cac_getWeaponAttachment( class_num, 0 );
		loadoutPrimaryAttachment2 = cac_getWeaponAttachmentTwo( class_num, 0 );
		loadoutPrimaryCamo = cac_getWeaponCamo( class_num, 0 );
		loadoutSecondaryCamo = cac_getWeaponCamo( class_num, 1 );
		loadoutSecondary = cac_getWeapon( class_num, 1 );
		loadoutSecondaryAttachment = cac_getWeaponAttachment( class_num, 1 );
		loadoutSecondaryAttachment2 = cac_getWeaponAttachmentTwo( class_num, 1 );
		loadoutSecondaryCamo = cac_getWeaponCamo( class_num, 1 );
		loadoutEquipment = cac_getPerk( class_num, 0 );
		loadoutPerk1 = cac_getPerk( class_num, 1 );
		loadoutPerk2 = cac_getPerk( class_num, 2 );
		loadoutPerk3 = cac_getPerk( class_num, 3 );
		loadoutOffhand = cac_getOffhand( class_num );
		loadoutDeathStreak = cac_getDeathstreak( class_num );
	}
	else
	{
		class_num = getClassIndex( class );
		
		loadoutPrimary = table_getWeapon( level.classTableName, class_num, 0 );
		loadoutPrimaryAttachment = table_getWeaponAttachment( level.classTableName, class_num, 0 , 0);
		loadoutPrimaryAttachment2 = table_getWeaponAttachment( level.classTableName, class_num, 0, 1 );
		loadoutPrimaryCamo = table_getWeaponCamo( level.classTableName, class_num, 0 );
		loadoutSecondary = table_getWeapon( level.classTableName, class_num, 1 );
		loadoutSecondaryAttachment = table_getWeaponAttachment( level.classTableName, class_num, 1 , 0);
		loadoutSecondaryAttachment2 = table_getWeaponAttachment( level.classTableName, class_num, 1, 1 );;
		loadoutSecondaryCamo = table_getWeaponCamo( level.classTableName, class_num, 1 );
		loadoutEquipment = table_getEquipment( level.classTableName, class_num, 0 );
		loadoutPerk1 = table_getPerk( level.classTableName, class_num, 1 );
		loadoutPerk2 = table_getPerk( level.classTableName, class_num, 2 );
		loadoutPerk3 = table_getPerk( level.classTableName, class_num, 3 );
		loadoutOffhand = table_getOffhand( level.classTableName, class_num );
		loadoutDeathstreak = table_getDeathstreak( level.classTableName, class_num );
	}
	
	clonedLoadout["inUse"] = false;
	clonedLoadout["loadoutPrimary"] = loadoutPrimary;
	clonedLoadout["loadoutPrimaryAttachment"] = loadoutPrimaryAttachment;
	clonedLoadout["loadoutPrimaryAttachment2"] = loadoutPrimaryAttachment2;
	clonedLoadout["loadoutPrimaryCamo"] = loadoutPrimaryCamo;
	clonedLoadout["loadoutSecondary"] = loadoutSecondary;
	clonedLoadout["loadoutSecondaryAttachment"] = loadoutSecondaryAttachment;
	clonedLoadout["loadoutSecondaryAttachment2"] = loadoutSecondaryAttachment2;
	clonedLoadout["loadoutSecondaryCamo"] = loadoutSecondaryCamo;
	clonedLoadout["loadoutEquipment"] = loadoutEquipment;
	clonedLoadout["loadoutPerk1"] = loadoutPerk1;
	clonedLoadout["loadoutPerk2"] = loadoutPerk2;
	clonedLoadout["loadoutPerk3"] = loadoutPerk3;
	clonedLoadout["loadoutOffhand"] = loadoutOffhand;
	
	return ( clonedLoadout );
}

checkCustomStreakVal(streakname, streakval)
{
	if (getDvar("scr_streakcount_" + streakname) == "" || getDvarInt("scr_streakcount_" + streakname) < 2)
		return streakval;

	return getDvarInt("scr_streakcount_" + streakname);
}

checkRestrictions( loadout, slot )
{
	if ( getDvar( "scr_allow_" + loadout ) == "" || getDvarInt( "scr_allow_" + loadout ) )
		return loadout;

	if (level.restrictionMessages && !isDefined(self.restrictionMessages[self.class]))
		self iPrintLnBold("Server does not allow: " + loadout);

	switch ( slot )
	{
		case "loadoutPrimary":
			tokens = strTok( level.defaultPrimarys, "," );
			return random(tokens);

		case "loadoutSecondary":
			tokens = strTok( level.defaultSecondarys, "," );
			return random(tokens);
			
		case "loadoutPrimaryAttachment":
		case "loadoutPrimaryAttachment2":
		case "loadoutSecondaryAttachment":
		case "loadoutSecondaryAttachment2":
			return "none";

		case "loadoutEquipment":
			tokens = strTok( level.defaultEquipment, "," );
			return random(tokens);

		case "loadoutPerk1":
			tokens = strTok( level.defaultPerks1, "," );
			return random(tokens);

		case "loadoutPerk2":
			tokens = strTok( level.defaultPerks2, "," );
			return random(tokens);

		case "loadoutPerk3":
			tokens = strTok( level.defaultPerks3, "," );
			return random(tokens);

		case "loadoutDeathstreak":
			tokens = strTok( level.defaultDeathstreak, "," );
			return random(tokens);

		case "loadoutOffhand":
			tokens = strTok( level.defaultOffhand, "," );
			return random(tokens);

		case "loadoutKillstreak1":
		case "loadoutKillstreak2":
		case "loadoutKillstreak3":
			return "none";

		case "secondaryName":
			tokens = strTok( level.defaultSecondarys, "," );
			return random(tokens) + "_mp";

		case "primaryName":
			tokens = strTok( level.defaultPrimarys, "," );
			return random(tokens) + "_mp";
	}
}

giveLoadout( team, class, allowCopycat )
{
	self takeAllWeapons();
	
	primaryIndex = 0;
	
	// initialize specialty array
	self.specialty = [];

	if ( !isDefined( allowCopycat ) )
		allowCopycat = true;

	primaryWeapon = undefined;

	if ( isDefined( self.pers["copyCatLoadout"] ) && self.pers["copyCatLoadout"]["inUse"] && allowCopycat )
	{
		self maps\mp\gametypes\_class::setClass( "copycat" );
		self.class_num = getClassIndex( "copycat" );

		clonedLoadout = self.pers["copyCatLoadout"];

		loadoutPrimary = clonedLoadout["loadoutPrimary"];
		loadoutPrimaryAttachment = clonedLoadout["loadoutPrimaryAttachment"];
		loadoutPrimaryAttachment2 = clonedLoadout["loadoutPrimaryAttachment2"] ;
		loadoutPrimaryCamo = clonedLoadout["loadoutPrimaryCamo"];
		loadoutSecondary = clonedLoadout["loadoutSecondary"];
		loadoutSecondaryAttachment = clonedLoadout["loadoutSecondaryAttachment"];
		loadoutSecondaryAttachment2 = clonedLoadout["loadoutSecondaryAttachment2"];
		loadoutSecondaryCamo = clonedLoadout["loadoutSecondaryCamo"];
		loadoutEquipment = clonedLoadout["loadoutEquipment"];
		loadoutPerk1 = clonedLoadout["loadoutPerk1"];
		loadoutPerk2 = clonedLoadout["loadoutPerk2"];
		loadoutPerk3 = clonedLoadout["loadoutPerk3"];
		loadoutOffhand = clonedLoadout["loadoutOffhand"];
		loadoutDeathStreak = "specialty_copycat";		
	}
	else if ( isSubstr( class, "custom" ) )
	{
		class_num = getClassIndex( class );
		self.class_num = class_num;

		loadoutPrimary = cac_getWeapon( class_num, 0 );
		loadoutPrimaryAttachment = cac_getWeaponAttachment( class_num, 0 );
		loadoutPrimaryAttachment2 = cac_getWeaponAttachmentTwo( class_num, 0 );
		loadoutPrimaryCamo = cac_getWeaponCamo( class_num, 0 );
		loadoutSecondaryCamo = cac_getWeaponCamo( class_num, 1 );
		loadoutSecondary = cac_getWeapon( class_num, 1 );
		loadoutSecondaryAttachment = cac_getWeaponAttachment( class_num, 1 );
		loadoutSecondaryAttachment2 = cac_getWeaponAttachmentTwo( class_num, 1 );
		loadoutSecondaryCamo = cac_getWeaponCamo( class_num, 1 );
		loadoutEquipment = cac_getPerk( class_num, 0 );
		loadoutPerk1 = cac_getPerk( class_num, 1 );
		loadoutPerk2 = cac_getPerk( class_num, 2 );
		loadoutPerk3 = cac_getPerk( class_num, 3 );
		loadoutOffhand = cac_getOffhand( class_num );
		loadoutDeathStreak = cac_getDeathstreak( class_num );
	}
	else
	{
		class_num = getClassIndex( class );
		self.class_num = class_num;
		
		loadoutPrimary = table_getWeapon( level.classTableName, class_num, 0 );
		loadoutPrimaryAttachment = table_getWeaponAttachment( level.classTableName, class_num, 0 , 0);
		loadoutPrimaryAttachment2 = table_getWeaponAttachment( level.classTableName, class_num, 0, 1 );
		loadoutPrimaryCamo = table_getWeaponCamo( level.classTableName, class_num, 0 );
		loadoutSecondaryCamo = table_getWeaponCamo( level.classTableName, class_num, 1 );
		loadoutSecondary = table_getWeapon( level.classTableName, class_num, 1 );
		loadoutSecondaryAttachment = table_getWeaponAttachment( level.classTableName, class_num, 1 , 0);
		loadoutSecondaryAttachment2 = table_getWeaponAttachment( level.classTableName, class_num, 1, 1 );;
		loadoutSecondaryCamo = table_getWeaponCamo( level.classTableName, class_num, 1 );
		loadoutEquipment = table_getEquipment( level.classTableName, class_num, 0 );
		loadoutPerk1 = table_getPerk( level.classTableName, class_num, 1 );
		loadoutPerk2 = table_getPerk( level.classTableName, class_num, 2 );
		loadoutPerk3 = table_getPerk( level.classTableName, class_num, 3 );
		loadoutOffhand = table_getOffhand( level.classTableName, class_num );
		loadoutDeathstreak = table_getDeathstreak( level.classTableName, class_num );
	}

	if ( !(isDefined( self.pers["copyCatLoadout"] ) && self.pers["copyCatLoadout"]["inUse"] && allowCopycat) )
	{
		isCustomClass = isSubstr( class, "custom" );
		
		if ( !isValidPrimary( loadoutPrimary ) || (isCustomClass && !self isItemUnlocked( loadoutPrimary )) )
			loadoutPrimary = table_getWeapon( level.classTableName, 10, 0 );
		
		if ( !isValidAttachment( loadoutPrimaryAttachment ) || (isCustomClass && !self isItemUnlocked( loadoutPrimary + " " + loadoutPrimaryAttachment )) )
			loadoutPrimaryAttachment = table_getWeaponAttachment( level.classTableName, 10, 0 , 0);
		
		if ( !isValidAttachment( loadoutPrimaryAttachment2 ) || (isCustomClass && !self isItemUnlocked( loadoutPrimary + " " + loadoutPrimaryAttachment2 )) )
			loadoutPrimaryAttachment2 = table_getWeaponAttachment( level.classTableName, 10, 0, 1 );
		
		if ( !isValidCamo( loadoutPrimaryCamo ) || (isCustomClass && !self isItemUnlocked( loadoutPrimary + " " + loadoutPrimaryCamo )) )
			loadoutPrimaryCamo = table_getWeaponCamo( level.classTableName, 10, 0 );
		
		if ( !isValidSecondary( loadoutSecondary ) || (isCustomClass && !self isItemUnlocked( loadoutSecondary )) )
			loadoutSecondary = table_getWeapon( level.classTableName, 10, 1 );
		
		if ( !isValidAttachment( loadoutSecondaryAttachment ) || (isCustomClass && !self isItemUnlocked( loadoutSecondary + " " + loadoutSecondaryAttachment )) )
			loadoutSecondaryAttachment = table_getWeaponAttachment( level.classTableName, 10, 1 , 0);
		
		if ( !isValidAttachment( loadoutSecondaryAttachment2 ) || (isCustomClass && !self isItemUnlocked( loadoutSecondary + " " + loadoutSecondaryAttachment2 )) )
			loadoutSecondaryAttachment2 = table_getWeaponAttachment( level.classTableName, 10, 1, 1 );;
		
		if ( !isValidCamo( loadoutSecondaryCamo ) || (isCustomClass && !self isItemUnlocked( loadoutSecondary + " " + loadoutSecondaryCamo )) )
			loadoutSecondaryCamo = table_getWeaponCamo( level.classTableName, 10, 1 );
		
		if ( !isValidEquipment( loadoutEquipment ) || (isCustomClass && !self isItemUnlocked( loadoutEquipment )) )
			loadoutEquipment = table_getEquipment( level.classTableName, 10, 0 );
		
		if ( !isValidPerk1( loadoutPerk1 ) || (isCustomClass && !self isItemUnlocked( loadoutPerk1 )) )
			loadoutPerk1 = table_getPerk( level.classTableName, 10, 1 );
		
		if ( !isValidPerk2( loadoutPerk2 ) || (isCustomClass && !self isItemUnlocked( loadoutPerk2 )) )
			loadoutPerk2 = table_getPerk( level.classTableName, 10, 2 );
		
		if ( !isValidPerk3( loadoutPerk3 ) || (isCustomClass && !self isItemUnlocked( loadoutPerk3 )) )
			loadoutPerk3 = table_getPerk( level.classTableName, 10, 3 );
		
		if ( !isValidOffhand( loadoutOffhand ) )
			loadoutOffhand = table_getOffhand( level.classTableName, 10 );
		
		if ( !isValidDeathstreak( loadoutDeathstreak ) || (isCustomClass && !self isItemUnlocked( loadoutDeathstreak )) )
			loadoutDeathstreak = table_getDeathstreak( level.classTableName, 10 );
	}

	if ( loadoutPerk1 != "specialty_bling" )
	{
		loadoutPrimaryAttachment2 = "none";
		loadoutSecondaryAttachment2 = "none";
	}
	
	if ( loadoutPerk1 != "specialty_onemanarmy" && loadoutSecondary == "onemanarmy" )
		loadoutSecondary = table_getWeapon( level.classTableName, 10, 1 );

	//loadoutSecondaryCamo = "none";
	
	// start checking restrictions
	loadoutPrimary = self checkRestrictions( loadoutPrimary, "loadoutPrimary" );
	loadoutSecondary = self checkRestrictions( loadoutSecondary, "loadoutSecondary" );
	loadoutPrimaryAttachment = self checkRestrictions( loadoutPrimaryAttachment, "loadoutPrimaryAttachment" );
	loadoutPrimaryAttachment2 = self checkRestrictions( loadoutPrimaryAttachment2, "loadoutPrimaryAttachment2" );
	loadoutSecondaryAttachment = self checkRestrictions( loadoutSecondaryAttachment, "loadoutSecondaryAttachment" );
	loadoutSecondaryAttachment2 = self checkRestrictions( loadoutSecondaryAttachment2, "loadoutSecondaryAttachment2" );
	loadoutEquipment = self checkRestrictions( loadoutEquipment, "loadoutEquipment" );
	loadoutPerk1 = self checkRestrictions( loadoutPerk1, "loadoutPerk1" );
	loadoutPerk2 = self checkRestrictions( loadoutPerk2, "loadoutPerk2" );
	loadoutPerk3 = self checkRestrictions( loadoutPerk3, "loadoutPerk3" );
	loadoutDeathstreak = self checkRestrictions( loadoutDeathstreak, "loadoutDeathstreak" );
	loadoutOffhand = self checkRestrictions( loadoutOffhand, "loadoutOffhand" );


	if ( level.killstreakRewards )
	{
		if ( getDvarInt( "scr_classic" ) == 1 )
		{
			loadoutKillstreak1 = "uav";
			loadoutKillstreak2 = "precision_airstrike";
			loadoutKillstreak3 = "helicopter";
		}
		else
		{
			loadoutKillstreak1 = self getPlayerData( "killstreaks", 0 );
			loadoutKillstreak2 = self getPlayerData( "killstreaks", 1 );
			loadoutKillstreak3 = self getPlayerData( "killstreaks", 2 );
		}
	}
	else
	{
		loadoutKillstreak1 = "none";
		loadoutKillstreak2 = "none";
		loadoutKillstreak3 = "none";
	}

	// restrict killstreaks
	loadoutKillstreak1 = self checkRestrictions( loadoutKillstreak1, "loadoutKillstreak1" );
	loadoutKillstreak2 = self checkRestrictions( loadoutKillstreak2, "loadoutKillstreak2" );
	loadoutKillstreak3 = self checkRestrictions( loadoutKillstreak3, "loadoutKillstreak3" );
	
	secondaryName = buildWeaponName( loadoutSecondary, loadoutSecondaryAttachment, loadoutSecondaryAttachment2 );
	secondaryName = self checkRestrictions( secondaryName, "secondaryName" );

	self _giveWeapon( secondaryName, int(tableLookup( "mp/camoTable.csv", 1, loadoutSecondaryCamo, 0 ) ) );

	self.loadoutPrimaryCamo = int(tableLookup( "mp/camoTable.csv", 1, loadoutPrimaryCamo, 0 ));
	self.loadoutPrimary = loadoutPrimary;
	self.loadoutSecondary = loadoutSecondary;
	self.loadoutSecondaryCamo = int(tableLookup( "mp/camoTable.csv", 1, loadoutSecondaryCamo, 0 ));
	
	self SetOffhandPrimaryClass( "other" );
	
	// Action Slots
	//self _SetActionSlot( 1, "" );
	self _SetActionSlot( 1, "nightvision" );
	self _SetActionSlot( 3, "altMode" );
	self _SetActionSlot( 4, "" );

	// Perks
	self _clearPerks();
	self _detachAll();
	
	// these special case giving pistol death have to come before
	// perk loadout to ensure player perk icons arent overwritten
	if ( level.dieHardMode )
		self maps\mp\perks\_perks::givePerk( "specialty_pistoldeath" );
	
	// only give the deathstreak for the initial spawn for this life.
	if ( loadoutDeathStreak != "specialty_null" && getTime() == self.spawnTime )
	{
		deathVal = int( tableLookup( "mp/perkTable.csv", 1, loadoutDeathStreak, 6 ) );
				
		if ( self getPerkUpgrade( loadoutPerk1 ) == "specialty_rollover" || self getPerkUpgrade( loadoutPerk2 ) == "specialty_rollover" || self getPerkUpgrade( loadoutPerk3 ) == "specialty_rollover" )
			deathVal -= 1;
		
		if ( self.pers["cur_death_streak"] == deathVal )
		{
			self thread maps\mp\perks\_perks::givePerk( loadoutDeathStreak );
			self thread maps\mp\gametypes\_hud_message::splashNotify( loadoutDeathStreak );
		}
		else if ( self.pers["cur_death_streak"] > deathVal )
		{
			self thread maps\mp\perks\_perks::givePerk( loadoutDeathStreak );
		}
	}

	self loadoutAllPerks( loadoutEquipment, loadoutPerk1, loadoutPerk2, loadoutPerk3 );
		
	self setKillstreaks( loadoutKillstreak1, loadoutKillstreak2, loadoutKillstreak3 );
		
	if ( self hasPerk( "specialty_extraammo", true ) && getWeaponClass( secondaryName ) != "weapon_projectile" )
		self giveMaxAmmo( secondaryName );

	// Primary Weapon
	primaryName = buildWeaponName( loadoutPrimary, loadoutPrimaryAttachment, loadoutPrimaryAttachment2 );
	primaryName = self checkRestrictions( primaryName, "primaryName" );
	
	self _giveWeapon( primaryName, self.loadoutPrimaryCamo );
	
	// fix changing from a riotshield class to a riotshield class during grace period not giving a shield
	if ( primaryName == "riotshield_mp" && level.inGracePeriod )
		self notify ( "weapon_change", "riotshield_mp" );

	if ( self hasPerk( "specialty_extraammo", true ) )
		self giveMaxAmmo( primaryName );

	self setSpawnWeapon( primaryName );
	
	primaryTokens = strtok( primaryName, "_" );
	self.pers["primaryWeapon"] = primaryTokens[0];
	
	// Primary Offhand was given by givePerk (it's your perk1)
	
	// Secondary Offhand
	offhandSecondaryWeapon = loadoutOffhand + "_mp";
	if ( loadoutOffhand == "flash_grenade" )
		self SetOffhandSecondaryClass( "flash" );
	else
		self SetOffhandSecondaryClass( "smoke" );
	
	self giveWeapon( offhandSecondaryWeapon );
	if( loadOutOffhand == "smoke_grenade" )
		self setWeaponAmmoClip( offhandSecondaryWeapon, 1 );
	else if( loadOutOffhand == "flash_grenade" )
		self setWeaponAmmoClip( offhandSecondaryWeapon, level.numFlash );
	else if( loadOutOffhand == "concussion_grenade" )
		self setWeaponAmmoClip( offhandSecondaryWeapon, level.numStun );
	else
		self setWeaponAmmoClip( offhandSecondaryWeapon, 1 );
	
	primaryWeapon = primaryName;
	self.primaryWeapon = primaryWeapon;
	self.secondaryWeapon = secondaryName;

	self maps\mp\gametypes\_teams::playerModelForWeapon( self.pers["primaryWeapon"], getBaseWeaponName( secondaryName ) );
		
	self.isSniper = (weaponClass( self.primaryWeapon ) == "sniper");
	
	self maps\mp\gametypes\_weapons::updateMoveSpeedScale( "primary" );

	// cac specialties that require loop threads
	self maps\mp\perks\_perks::cac_selector();

	self.restrictionMessages[self.class] = true;
	
	self notify ( "changed_kit" );
	self notify ( "giveLoadout" );
}

_detachAll()
{
	if ( isDefined( self.hasRiotShield ) && self.hasRiotShield )
	{
		if ( self.hasRiotShieldEquipped )
		{
			self DetachShieldModel( "weapon_riot_shield_mp", "tag_weapon_left" );
			self.hasRiotShieldEquipped = false;
		}
		else
		{
			self DetachShieldModel( "weapon_riot_shield_mp", "tag_shield_back" );
		}
		
		self.hasRiotShield = false;
	}
	
	self detachAll();
}

isPerkUpgraded( perkName )
{
	perkUpgrade = tablelookup( "mp/perktable.csv", 1, perkName, 8 );
	
	if ( perkUpgrade == "" || perkUpgrade == "specialty_null" )
		return false;
		
	if ( !self isItemUnlocked( perkUpgrade ) )
		return false;
		
	return true;
}

getPerkUpgrade( perkName )
{
	perkUpgrade = tablelookup( "mp/perktable.csv", 1, perkName, 8 );
	
	if ( perkUpgrade == "" || perkUpgrade == "specialty_null" )
		return "specialty_null";
		
	if ( !self isItemUnlocked( perkUpgrade ) )
		return "specialty_null";
		
	return ( perkUpgrade );
}

loadoutAllPerks( loadoutEquipment, loadoutPerk1, loadoutPerk2, loadoutPerk3 )
{
	loadoutEquipment = maps\mp\perks\_perks::validatePerk( 1, loadoutEquipment );
	loadoutPerk1 = maps\mp\perks\_perks::validatePerk( 1, loadoutPerk1 );
	loadoutPerk2 = maps\mp\perks\_perks::validatePerk( 2, loadoutPerk2 );
	loadoutPerk3 = maps\mp\perks\_perks::validatePerk( 3, loadoutPerk3 );

	self maps\mp\perks\_perks::givePerk( loadoutEquipment );
	self maps\mp\perks\_perks::givePerk( loadoutPerk1 );
	self maps\mp\perks\_perks::givePerk( loadoutPerk2 );
	self maps\mp\perks\_perks::givePerk( loadoutPerk3 );
	
	perkUpgrd[0] = tablelookup( "mp/perktable.csv", 1, loadoutPerk1, 8 );
	perkUpgrd[1] = tablelookup( "mp/perktable.csv", 1, loadoutPerk2, 8 );
	perkUpgrd[2] = tablelookup( "mp/perktable.csv", 1, loadoutPerk3, 8 );
	
	foreach( upgrade in perkUpgrd )
	{
		if ( upgrade == "" || upgrade == "specialty_null" )
			continue;
			
		if ( self isItemUnlocked( upgrade ) )
			self maps\mp\perks\_perks::givePerk( upgrade );
	}

}

trackRiotShield()
{
	self endon ( "death" );
	self endon ( "disconnect" );

	self.hasRiotShield = self hasWeapon( "riotshield_mp" );
	self.hasRiotShieldEquipped = (self.currentWeaponAtSpawn == "riotshield_mp");
	
	// note this function must play nice with _detachAll().
	
	if ( self.hasRiotShield )
	{
		if ( self.hasRiotShieldEquipped )
		{
			self AttachShieldModel( "weapon_riot_shield_mp", "tag_weapon_left" );
		}
		else
		{
			self AttachShieldModel( "weapon_riot_shield_mp", "tag_shield_back" );
		}
	}
	
	for ( ;; )
	{
		self waittill ( "weapon_change", newWeapon );
		
		if ( newWeapon == "riotshield_mp" )
		{
			// defensive check in case we somehow get an extra "weapon_change"
			if ( self.hasRiotShieldEquipped )
				continue;
			
			if ( self.hasRiotShield )
				self MoveShieldModel( "weapon_riot_shield_mp", "tag_shield_back", "tag_weapon_left" );
			else
				self AttachShieldModel( "weapon_riot_shield_mp", "tag_weapon_left" );
			
			self.hasRiotShield = true;
			self.hasRiotShieldEquipped = true;
		}
		else if ( (self IsMantling()) && (newWeapon == "none") )
		{
			// Do nothing, we want to keep that weapon on their arm.
		}
		else if ( self.hasRiotShieldEquipped )
		{
			assert( self.hasRiotShield );
			self.hasRiotShield = self hasWeapon( "riotshield_mp" );
			
			if ( self.hasRiotShield )
				self MoveShieldModel( "weapon_riot_shield_mp", "tag_weapon_left", "tag_shield_back" );
			else
				self DetachShieldModel( "weapon_riot_shield_mp", "tag_weapon_left" );
			
			self.hasRiotShieldEquipped = false;
		}
		else if ( self.hasRiotShield )
		{
			if ( !self hasWeapon( "riotshield_mp" ) )
			{
				// we probably just lost all of our weapons (maybe switched classes)
				self DetachShieldModel( "weapon_riot_shield_mp", "tag_shield_back" );
				self.hasRiotShield = false;
			}
		}
	}
}


tryAttach( placement ) // deprecated; hopefully we won't need to bring this defensive function back
{
	if ( !isDefined( placement ) || placement != "back" )
		tag = "tag_weapon_left";
	else
		tag = "tag_shield_back";
	
	attachSize = self getAttachSize();
	
	for ( i = 0; i < attachSize; i++ )
	{
		attachedTag = self getAttachTagName( i );
		if ( attachedTag == tag &&  self getAttachModelName( i ) == "weapon_riot_shield_mp" )
		{
			return;
		}
	}
	
	self AttachShieldModel( "weapon_riot_shield_mp", tag );
}

tryDetach( placement ) // deprecated; hopefully we won't need to bring this defensive function back
{
	if ( !isDefined( placement ) || placement != "back" )
		tag = "tag_weapon_left";
	else
		tag = "tag_shield_back";
	
	
	attachSize = self getAttachSize();
	
	for ( i = 0; i < attachSize; i++ )
	{
		attachedModel = self getAttachModelName( i );
		if ( attachedModel == "weapon_riot_shield_mp" )
		{
			self DetachShieldModel( attachedModel, tag);
			return;
		}
	}
	return;
}



buildWeaponName( baseName, attachment1, attachment2 )
{
	if ( !isDefined( level.letterToNumber ) )
		level.letterToNumber = makeLettersToNumbers();

	// disable bling when perks are disabled
	if ( getDvarInt ( "scr_game_perks" ) == 0 )
	{
		attachment2 = "none";

		if ( baseName == "onemanarmy" )
			return ( "beretta_mp" );
	}

	weaponName = baseName;
	attachments = [];

	if ( attachment1 != "none" && attachment2 != "none" )
	{
		if ( level.letterToNumber[attachment1[0]] < level.letterToNumber[attachment2[0]] )
		{
			
			attachments[0] = attachment1;
			attachments[1] = attachment2;
			
		}
		else if ( level.letterToNumber[attachment1[0]] == level.letterToNumber[attachment2[0]] )
		{
			if ( level.letterToNumber[attachment1[1]] < level.letterToNumber[attachment2[1]] )
			{
				attachments[0] = attachment1;
				attachments[1] = attachment2;
			}
			else
			{
				attachments[0] = attachment2;
				attachments[1] = attachment1;
			}	
		}
		else
		{
			attachments[0] = attachment2;
			attachments[1] = attachment1;
		}		
	}
	else if ( attachment1 != "none" )
	{
		attachments[0] = attachment1;
	}
	else if ( attachment2 != "none" )
	{
		attachments[0] = attachment2;	
	}
	
	foreach ( attachment in attachments )
	{
		weaponName += "_" + attachment;
	}

	if ( !isValidWeapon( weaponName + "_mp" ) )
		return ( baseName + "_mp" );
	else
		return ( weaponName + "_mp" );
}


makeLettersToNumbers()
{
	array = [];
	
	array["a"] = 0;
	array["b"] = 1;
	array["c"] = 2;
	array["d"] = 3;
	array["e"] = 4;
	array["f"] = 5;
	array["g"] = 6;
	array["h"] = 7;
	array["i"] = 8;
	array["j"] = 9;
	array["k"] = 10;
	array["l"] = 11;
	array["m"] = 12;
	array["n"] = 13;
	array["o"] = 14;
	array["p"] = 15;
	array["q"] = 16;
	array["r"] = 17;
	array["s"] = 18;
	array["t"] = 19;
	array["u"] = 20;
	array["v"] = 21;
	array["w"] = 22;
	array["x"] = 23;
	array["y"] = 24;
	array["z"] = 25;
	
	return array;
}

setKillstreaks( streak1, streak2, streak3 )
{
	self.killStreaks = [];

	if ( self _hasPerk( "specialty_hardline" ) && ( getDvarInt( "scr_classic" ) != 1 ) )
		modifier = -1;
	else
		modifier = 0;
	
	/*if ( streak1 == "none" && streak2 == "none" && streak3 == "none" )
	{
		streak1 = "uav";
		streak2 = "precision_airstrike";
		streak3 = "helicopter";
	}*/

	killStreaks = [];

	if ( streak1 != "none" )
	{
		//if ( !level.splitScreen )
			streakVal = int( tableLookup( "mp/killstreakTable.csv", 1, streak1, 4 ) );
		//else
		//	streakVal = int( tableLookup( "mp/killstreakTable.csv", 1, streak1, 5 ) );

		streakVal = self checkCustomStreakVal(streak1, streakVal);
		killStreaks[streakVal + modifier] = streak1;
	}

	if ( streak2 != "none" )
	{
		//if ( !level.splitScreen )
			streakVal = int( tableLookup( "mp/killstreakTable.csv", 1, streak2, 4 ) );
		//else
		//	streakVal = int( tableLookup( "mp/killstreakTable.csv", 1, streak2, 5 ) );

		if ( ( getDvarInt( "scr_classic" ) == 1 ) && ( streak2 == "precision_airstrike" ) )
		{
			streakVal = ( streakVal - 1 );
		}

		streakVal = self checkCustomStreakVal(streak2, streakVal);
		killStreaks[streakVal + modifier] = streak2;
	}

	if ( streak3 != "none" )
	{
		//if ( !level.splitScreen )
			streakVal = int( tableLookup( "mp/killstreakTable.csv", 1, streak3, 4 ) );
		//else
		//	streakVal = int( tableLookup( "mp/killstreakTable.csv", 1, streak3, 5 ) );

		streakVal = self checkCustomStreakVal(streak3, streakVal);
		killStreaks[streakVal + modifier] = streak3;
	}

	// foreach doesn't loop through numbers arrays in number order; it loops through the elements in the order
	// they were added.  We'll use this to fix it for now.
	maxVal = 0;
	foreach ( streakVal, streakName in killStreaks )
	{
		if ( streakVal > maxVal )
			maxVal = streakVal;
	}

	for ( streakIndex = 0; streakIndex <= maxVal; streakIndex++ )
	{
		if ( !isDefined( killStreaks[streakIndex] ) )
			continue;
			
		streakName = killStreaks[streakIndex];
			
		self.killStreaks[ streakIndex ] = killStreaks[ streakIndex ];
	}
	// end lameness

	// defcon rollover
	maxRollOvers = 10;
	if (isDefined(level.maxKillstreakRollover))
		maxRollOvers = level.maxKillstreakRollover;

	newKillstreaks = self.killstreaks;
	for ( rollOver = 1; rollOver <= maxRollOvers; rollOver++ )
	{
		foreach ( streakVal, streakName in self.killstreaks )
		{
			newKillstreaks[ streakVal + (maxVal*rollOver) ] = streakName + "-rollover" + rollOver;
		}
	}
	
	self.killstreaks = newKillstreaks;
	self.maxKillstreakVal = maxVal;
}


replenishLoadout() // used by ammo hardpoint.
{
	team = self.pers["team"];
	class = self.pers["class"];

    weaponsList = self GetWeaponsListAll();
    for( idx = 0; idx < weaponsList.size; idx++ )
    {
		weapon = weaponsList[idx];

		self giveMaxAmmo( weapon );
		self SetWeaponAmmoClip( weapon, 9999 );

		if ( weapon == "claymore_mp" || weapon == "claymore_detonator_mp" )
			self setWeaponAmmoStock( weapon, 2 );
    }
	
	if ( self getAmmoCount( level.classGrenades[class]["primary"]["type"] ) < level.classGrenades[class]["primary"]["count"] )
 		self SetWeaponAmmoClip( level.classGrenades[class]["primary"]["type"], level.classGrenades[class]["primary"]["count"] );

	if ( self getAmmoCount( level.classGrenades[class]["secondary"]["type"] ) < level.classGrenades[class]["secondary"]["count"] )
 		self SetWeaponAmmoClip( level.classGrenades[class]["secondary"]["type"], level.classGrenades[class]["secondary"]["count"] );	
}


onPlayerConnecting()
{
	for(;;)
	{
		level waittill( "connected", player );

		if ( !isDefined( player.pers["class"] ) )
		{
			player.pers["class"] = "";
		}
		player.class = player.pers["class"];
		player.lastClass = "";
		player.detectExplosives = false;
		player.bombSquadIcons = [];
		player.bombSquadIds = [];
		player.restrictionMessages = [];
	}
}


fadeAway( waitDelay, fadeDelay )
{
	wait waitDelay;
	
	self fadeOverTime( fadeDelay );
	self.alpha = 0;
}


setClass( newClass )
{
	self.curClass = newClass;
}

getPerkForClass( perkSlot, className )
{
    class_num = getClassIndex( className );

    if( isSubstr( className, "custom" ) )
        return cac_getPerk( class_num, perkSlot );
    else
        return table_getPerk( level.classTableName, class_num, perkSlot );
}


classHasPerk( className, perkName )
{
	return( getPerkForClass( 0, className ) == perkName || getPerkForClass( 1, className ) == perkName || getPerkForClass( 2, className ) == perkName );
}

isValidPrimary( refString )
{
	switch ( refString )
	{
		case "riotshield":
		case "ak47":
		case "m16":
		case "m4":
		case "fn2000":
		case "masada":
		case "famas":
		case "fal":
		case "scar":
		case "tavor":
		case "mp5k":
		case "uzi":
		case "p90":
		case "kriss":
		case "ump45":
		case "barrett":
		case "wa2000":
		case "m21":
		case "cheytac":
		case "rpd":
		case "sa80":
		case "mg4":
		case "m240":
		case "aug":
		case "peacekeeper":
		case "ak47classic":
		case "ak74u":
		case "m40a3":
		case "dragunov":
			return true;
		default:
			assertMsg( "Replacing invalid primary weapon: " + refString );
			return false;
	}
}

isValidSecondary( refString )
{
	switch ( refString )
	{
		case "beretta":
		case "usp":
		case "deserteagle":
		case "coltanaconda":
		case "glock":
		case "beretta393":
		case "pp2000":
		case "tmp":
		case "m79":
		case "rpg":
		case "at4":
		case "stinger":
		case "javelin":
		case "ranger":
		case "model1887":
		case "striker":
		case "aa12":
		case "m1014":
		case "spas12":
		case "onemanarmy":
		case "deserteaglegold":
			return true;
		default:
			assertMsg( "Replacing invalid secondary weapon: " + refString );
			return false;
	}
}

isValidAttachment( refString )
{
	switch ( refString )
	{
		case "none":
		case "acog":
		case "reflex":
		case "silencer":
		case "grip":
		case "gl":
		case "akimbo":
		case "thermal":
		case "shotgun":
		case "heartbeat":
		case "fmj":
		case "rof":
		case "xmags":
		case "eotech":  
		case "tactical":
			return true;
		default:
			assertMsg( "Replacing invalid equipment weapon: " + refString );
			return false;
	}
}

isValidCamo( refString )
{
	switch ( refString )
	{
		case "none":
		case "woodland":
		case "desert":
		case "arctic":
		case "digital":
		case "red_urban":
		case "red_tiger":
		case "blue_tiger":
		case "orange_fall":
			return true;
		default:
			assertMsg( "Replacing invalid camo: " + refString );
			return false;
	}
}

isValidEquipment( refString )
{
	switch ( refString )
	{
		case "frag_grenade_mp":
		case "semtex_mp":
		case "throwingknife_mp":
		case "specialty_tacticalinsertion":
		case "specialty_blastshield":
		case "claymore_mp":
		case "c4_mp":
			return true;
		default:
			assertMsg( "Replacing invalid equipment: " + refString );
			return false;
	}
}


isValidOffhand( refString )
{
	switch ( refString )
	{
		case "flash_grenade":
		case "concussion_grenade":
		case "smoke_grenade":
			return true;
		default:
			assertMsg( "Replacing invalid offhand: " + refString );
			return false;
	}
}

isValidPerk1( refString )
{
	switch ( refString )
	{
		case "specialty_marathon":
		case "specialty_fastreload":
		case "specialty_scavenger":
		case "specialty_bling":
		case "specialty_onemanarmy":
			return true;
		default:
			assertMsg( "Replacing invalid perk1: " + refString );
			return false;
	}
}

isValidPerk2( refString )
{
	switch ( refString )
	{
		case "specialty_bulletdamage":
		case "specialty_lightweight":
		case "specialty_hardline":
		case "specialty_coldblooded":
		case "specialty_explosivedamage":
			return true;
		default:
			assertMsg( "Replacing invalid perk2: " + refString );
			return false;
	}
}

isValidPerk3( refString )
{
	switch ( refString )
	{
		case "specialty_extendedmelee":
		case "specialty_bulletaccuracy":
		case "specialty_localjammer":
		case "specialty_heartbreaker":
		case "specialty_detectexplosive":
		case "specialty_pistoldeath":
			return true;
		default:
			assertMsg( "Replacing invalid perk3: " + refString );
			return false;
	}
}

isValidDeathStreak( refString )
{
	switch ( refString )
	{
		case "specialty_copycat":
		case "specialty_combathigh":
		case "specialty_grenadepulldeath":
		case "specialty_finalstand":
			return true;
		default:
			assertMsg( "Replacing invalid death streak: " + refString );
			return false;
	}
}

isValidWeapon( refString )
{
	if ( !isDefined( level.weaponRefs ) )
	{
		level.weaponRefs = [];

		foreach ( weaponRef in level.weaponList )
			level.weaponRefs[ weaponRef ] = true;
	}

	if ( isDefined( level.weaponRefs[ refString ] ) )
		return true;

	assertMsg( "Replacing invalid weapon/attachment combo: " + refString );
	
	return false;
}
