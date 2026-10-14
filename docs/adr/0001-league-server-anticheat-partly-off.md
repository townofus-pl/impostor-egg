# League Server runs Impostor AntiCheat with three checks off

Impostor's default AntiCheat kicks and IP-bans TOU-Mira players during normal play: `ForbidProtocolExtensions` trips on TOU custom colors and the Miner's vents, and `EnableRoleChecks` treats every MiraAPI role as a vanilla crewmate that cannot vent. So the League Server keeps AntiCheat on but sets `EnableRoleChecks`, `ForbidProtocolExtensions` and `BanIpFromGame` to false. We did not register a mod ID from `DramaAferaStats.Client` to skip AntiCheat for league games, because it costs code and gives the same result as turning AntiCheat off.

## Consequences

- If the first test match still shows kicks, the fallback is `AntiCheat.Enabled` false. This is a one-line config change.
