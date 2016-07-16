
TEAM_GREEN = 1
TEAM_PURPLE = 2
TEAM_SPEC = 3

hook.Add("CreateTeams", "TeamCreator", function()
	team.SetUp(TEAM_GREEN, "Dogs", Color(0, 255, 0))
	team.SetUp(TEAM_PURPLE, "Cats", Color(255, 0, 255))
	team.SetUp(TEAM_SPEC, "Spectators", Color(255, 255, 255))

	team.SetSpawnPoint( TEAM_GREEN, {"info_player_terrorist"} )
	team.SetSpawnPoint( TEAM_PURPLE, {"info_player_counterterrorist"} )
end)