init()
{
	if ( getDvarInt( "spawnpoints_test" ) )
		level thread doSpawnPointTest();
}

drawNoSight(sp)
{
	newdeathicon = newHudElem();
	newdeathicon.x = sp.origin[0];
	newdeathicon.y = sp.origin[1];
	newdeathicon.z = sp.origin[2] + 32;
	newdeathicon.alpha = .61;
	newdeathicon.archived = true;
	newdeathicon setShader( "headicon_dead", 5, 5 );
	newdeathicon setwaypoint( true, false );

	if (isDefined(sp.wp))
		sp.wp destroy();
	
	sp.wp = newdeathicon;
}

drawSight(sp)
{
	newdeathicon = newHudElem();
	newdeathicon.x = sp.origin[0];
	newdeathicon.y = sp.origin[1];
	newdeathicon.z = sp.origin[2] + 32;
	newdeathicon.alpha = .61;
	newdeathicon.archived = true;
	newdeathicon setShader( "rank_prestige1", 5, 5 );
	newdeathicon setwaypoint( true, false );

	if (isDefined(sp.wp))
		sp.wp destroy();
	
	sp.wp = newdeathicon;
}

doSpawnPointTest()
{
	for ( ;; )
	{
		wait 0.05;

		if ( !isdefined( level.spawnpoints ) )
			return;

		for (i = 0; i < level.spawnpoints.size; i++)
		{
			spawnpoint = level.spawnpoints[i];

			sight = false;

			if (level.teamBased)
			{
				sight = (spawnpoint.sights["axis"] > 0);
				if (!sight)
					sight = (spawnpoint.sights["allies"] > 0);
			}
			else
				sight = (spawnpoint.sights > 0);

			if (!sight)
				drawNoSight(spawnpoint);
			else
				drawSight(spawnpoint);
		}
	}
}
