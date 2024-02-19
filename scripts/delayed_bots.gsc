#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

init() {
	setDvarIfUninitialized( "bots_manage_fill", 0 );
	setDvarIfUninitialized( "bots_manage_fill_later", getDvarInt("bots_manage_fill") );
    println("[Delayed Bots] bots_manage_fill: " + getDvarInt("bots_manage_fill") + " | bots_manage_fill_later: " + getDvarInt("bots_manage_fill_later"));
	setDvar( "bots_manage_fill", 0 );
    if (getDvarInt("bots_manage_fill_later") > 0) {
        level thread onPlayerConnect();
    }
    
}

onPlayerConnect() {
    level waittill("connected", player);
    println("[Delayed Bots] " + player.name + " (" + player getEntityNumber() + ") connected");
    player thread onPlayerSpawned();
}

onPlayerSpawned() {
    self endon("disconnect");
    self waittill("spawned_player");

    bots_to_spawn = getDvarInt("bots_manage_fill_later");
    println("[Delayed Bots] " + self.name + " (" + self getEntityNumber() + ") spawned. Filling " + bots_to_spawn + " bots...");
    if (bots_to_spawn > 0) {
        setDvar("bots_manage_fill", bots_to_spawn);
        setDvar("bots_manage_fill_later", 0);
        self iPrintlnBold("Spawning " + bots_to_spawn + " bots now...");
    }
}
