# Capture-The-Flag-FiveM
An event script I made for Transport Tycoon. Releasing it here because it is a simple script that people may enjoy.


NOTE: Some of the commands should be restricted to staff, including:

``/setflag [red/blue]`` (Sets the flag position to your current location)

``/resetflag [red/blue]`` (Sets the flag position to it's original starting position)

``/setbase [red/blue]`` (Sets the base position to your current location)

``/bothteams`` (Toggles the ability to see all player's minimap blips)

``/switchteams`` (Switches to the opposite team with a 5 minute cooldown)



Reference for colors: http://www.kronzky.info/fivemwiki/index.php?title=Text_Colors and https://wiki.rage.mp/index.php?title=Blip::color



team.Name - Sets what team 1 will display as

team.TextColorPrefix - The color of the team name on UIs 

team.ChatColorPrefix - The color of the team name in chat

team.BlipColor - The color of the blip

flagLocations - An array containing all valid base starting locations

maxPoints - The amount of points it takes for a team to win

captureWithFlagGone - Whether the player can get a point for their team without their own flag at their base
