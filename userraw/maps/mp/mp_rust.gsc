#include maps\mp\_utility;

main()
{

	maps\mp\mp_rust_precache::main();
	maps\createart\mp_rust_art::main();
	maps\mp\mp_rust_fx::main();

	maps\mp\_load::main();

	maps\mp\_compass::setupMiniMap( "compass_map_mp_rust" );

	setdvar( "compassmaxrange", "1400" );

	ambientPlay( "ambient_mp_duststorm" );

	game[ "attackers" ] = "allies";
	game[ "defenders" ] = "axis";
	
	//thread killTrigger( (1080, 1645, -156 - 30), 40, 30 );
}