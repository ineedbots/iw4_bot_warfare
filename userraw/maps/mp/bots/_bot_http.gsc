#include maps\mp\bots\_bot_utility;

/*
	
*/
doVersionCheck()
{
	remoteVersion = getRemoteVersion();

	if (!isDefined(remoteVersion))
	{
		println("Error getting remote version of Bot Warfare.");
		return false;
	}

	if (level.bw_VERSION != remoteVersion)
	{
		println("There is a new version of Bot Warfare!");
		println("You are on version " + level.bw_VERSION + " but " + remoteVersion + " is available!");
		return false;
	}

	println("You are on the latest version of Bot Warfare!");
	return true;
}

/*
	
*/
getRemoteWaypoints(mapname)
{
  url = "https://raw.githubusercontent.com/ineedbots/iw4x_waypoints/master/" + mapname + "_wp.csv";

  println("Attempting to get remote waypoints from " + url);
  res = getLinesFromUrl(url);

  if (!res.lines.size)
    return;

  println("Loading remote waypoints...");

  wps = linesToWaypoints(res);

  if (wps.size)
  {
    level.waypoints = wps;
    println("Loaded " + wps.size + " waypoints from remote.");
  }
}

/*
	
*/
getRemoteVersion()
{
  request = httpGet( "https://raw.githubusercontent.com/ineedbots/iw4x_waypoints/master/version.txt" );
  request waittill( "done", success, data );
	request destroy();

  if (!success)
    return undefined;

  return strtok(data, "\n")[0];
}

/*
	
*/
linesToWaypoints(res)
{
  waypoints = [];
  waypointCount = int(res.lines[0]);
  
  if (waypointCount <= 0)
    return waypoints;

  for (i = 1; i <= waypointCount; i++)
  {
    tokens = tokenizeLine(res.lines[i], ",");
    
    waypoint = parseTokensIntoWaypoint(tokens);

    waypoints[i-1] = waypoint;
  }

  return waypoints;
}

/*
	
*/
getLinesFromUrl(url)
{
  result = spawnStruct();
  result.lines = [];

	request = httpGet( url );
  request waittill( "done", success, data );
	request destroy();

  if (!success)
    return result;

	line = "";
	for (i=0;i<data.size;i++)
	{
		c = data[i];
		
		if (c == "\n")
		{
			result.lines[result.lines.size] = line;

			line = "";
			continue;
		}

		line += c;
	}
  result.lines[result.lines.size] = line;

	return result;
}