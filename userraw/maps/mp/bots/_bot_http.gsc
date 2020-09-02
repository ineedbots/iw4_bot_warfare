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

linesToWaypoints(res)
{
  waypoints = [];
  waypointCount = int(res.lines[0]);
  
  if (waypointCount <= 0)
    return waypoints;

  for (i = 1; i <= waypointCount; i++)
  {
    tokens = tokenizeLine(res.lines[i], ",");
    
    waypoint = spawnStruct();

    orgStr = tokens[0];
		orgToks = strtok(orgStr, " ");
		waypoint.origin = (int(orgToks[0]), int(orgToks[1]), int(orgToks[2]));

		childStr = tokens[1];
		childToks = strtok(childStr, " ");
		waypoint.childCount = childToks.size;
		waypoint.children = [];
		for( j=0; j<childToks.size; j++ )
			waypoint.children[j] = int(childToks[j]);

		type = tokens[2];
		waypoint.type = type;

		anglesStr = tokens[3];
		if (isDefined(anglesStr) && anglesStr != "")
		{
			anglesToks = strtok(anglesStr, " ");
			waypoint.angles = (int(anglesToks[0]), int(anglesToks[1]), int(anglesToks[2]));
		}

		javStr = tokens[4];
		if (isDefined(javStr) && javStr != "")
		{
			javToks = strtok(javStr, " ");
			waypoint.jav_point = (int(javToks[0]), int(javToks[1]), int(javToks[2]));
    }

    waypoints[i-1] = waypoint;
  }

  return waypoints;
}

tokenizeLine(line, tok)
{
  tokens = [];

  token = "";
  for (i = 0; i < line.size; i++)
  {
    c = line[i];

    if (c == tok)
    {
      tokens[tokens.size] = token;
      token = "";
      continue;
    }

    token += c;
  }
  tokens[tokens.size] = token;

  return tokens;
}

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