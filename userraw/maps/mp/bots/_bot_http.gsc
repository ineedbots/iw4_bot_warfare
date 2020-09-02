getRemoteWaypoints(mapname)
{
  printLn( "Getting waypoints from csv: " );
  //"https://raw.githubusercontent.com/ineedbots/iw4x_waypoints/master/mp_rust_wp.csv"
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

	return result;
}