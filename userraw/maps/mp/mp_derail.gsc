#include maps\mp\_utility;

main()
{
	maps\mp\mp_derail_precache::main();
	maps\mp\mp_derail_fx::main();
	maps\createart\mp_derail_art::main();
	maps\mp\_load::main();

	maps\mp\_compass::setupMiniMap( "compass_map_mp_derail" );

	ambientPlay( "ambient_mp_snow" );

	game[ "attackers" ] = "axis";
	game[ "defenders" ] = "allies";

	setdvar( "r_specularcolorscale", "2.3" );
	setdvar( "compassmaxrange", "4000" );
	setdvar( "r_lightGridEnableTweaks", 1 );
	setdvar( "r_lightGridIntensity", 1 );
	setdvar( "r_lightGridContrast", .4 );
	
	//thread killTrigger( (2077, -91, 0), 75, 20 );
}
