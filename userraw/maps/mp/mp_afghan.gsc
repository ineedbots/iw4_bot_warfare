#include maps\mp\_utility;
#include common_scripts\utility;

main()
{
	maps\mp\mp_afghan_precache::main();
	maps\createart\mp_afghan_art::main();
	maps\mp\mp_afghan_fx::main();
	maps\mp\_explosive_barrels::main();
	maps\mp\_load::main();

	maps\mp\_compass::setupMiniMap( "compass_map_mp_afghan" );
	
	setdvar( "compassmaxrange", "3000" );

	ambientPlay( "ambient_mp_desert" );

	game[ "attackers" ] = "allies";
	game[ "defenders" ] = "axis";
	
	setdvar( "r_lightGridEnableTweaks", 1 );
	setdvar( "r_lightGridIntensity", 1.2 );
	setdvar( "r_lightGridContrast", 0 );	
	
	//thread killTrigger( (206, 2414, 257 - 120), 55, 100 );
}
