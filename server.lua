-- Created by Dalrae

--[[ CONFIG ]]
local team1 = {
        ["Name"] = "Red",
        ["TextColorPrefix"] = "~r~",
        ["ChatColorPrefix"] = "^8",
        ["BlipColor"] = 1
    }
local team2 = {
        ["Name"] = "Blue",
        ["TextColorPrefix"] = "~b~",
        ["ChatColorPrefix"] = "^4",
        ["BlipColor"] = 3
    }
local flagLocations = { -- Pairs of team flag locations
    { --Just some test points
        vector3(1920, 4709, 45),
        vector3(1941, 4721, 45)
    },
    --[[{ -- Paleto Gas Station, Los Santos Docks
        vector3(159, 6586, 35),
        vector3(-1336, -3044, 17)
    },]]
}
local maxPoints = 3 -- How many points to win
local captureWithFlagGone = false -- Should the player be able to capture without their flag being at the base?

--[[ END CONFIG ]]



function getDistance(a, b, noZ) -- Gets distance between two coords, third arg being true ignores the Z coord (up-down)
	local x, y, z = a.x-b.x, a.y-b.y, a.z-b.z
	if noZ then 
		return math.floor(math.sqrt(x*x+y*y))
	else
		return math.floor(math.sqrt(x*x+y*y+z*z))
	end
end

local gameInfo = {}
gameInfo.Teams = {}
gameInfo.PlayerTeams = {}
gameInfo.Objects = {}
gameInfo.CapWithFlagGone = captureWithFlagGone

function getPlayerTeams(player)
    local myTeam, otherTeam
    for playerT,playerInfo in pairs(gameInfo.PlayerTeams) do
        if tonumber(playerT) == tonumber(player) then
            myTeam = playerInfo.Team
            break
        end
    end
    for _,team in pairs(gameInfo.Teams) do
        if team.Name ~= myTeam.Name then
            otherTeam = team
            break
        end
    end
    return myTeam, otherTeam
end

function isPlayerValid(player)
    for _,playerT in pairs(GetPlayers()) do
        if tonumber(playerT) == tonumber(player) then
            return true
        end
    end
    return false
end

function createTeamFlag(team)
    if gameInfo.Objects[team.Name] then
        DeleteEntity(NetworkGetEntityFromNetworkId(gameInfo.Objects[team.Name].NetID))
        DeleteEntity(NetworkGetEntityFromNetworkId(gameInfo.Objects[team.Name.."Pole"].NetID))
    end
    local flag = CreateObjectNoOffset(GetHashKey("apa_prop_flag_script"), team.InitialFlagCoords.xyz, true, true, true)
    FreezeEntityPosition(flag, true)
    
    gameInfo.Objects[team.Name] = {
        ["NetID"] = NetworkGetNetworkIdFromEntity(flag)
    }
    local flagPole = CreateObjectNoOffset(GetHashKey("prop_flagpole_1a"), vector3(team.InitialFlagCoords.x, team.InitialFlagCoords.y, team.InitialFlagCoords.z-5.8).xyz, true, true, true)
    FreezeEntityPosition(flagPole, true)
    gameInfo.Objects[team.Name.."Pole"] = {
        ["NetID"] = NetworkGetNetworkIdFromEntity(flagPole)
    }
    if team.Name == gameInfo.Teams.Team1.Name then
        gameInfo.Teams.Team1.FlagPickup = nil
        gameInfo.Teams.Team1.FlagDropped = false
        gameInfo.Teams.Team1.CurrentFlagCoords = gameInfo.Teams.Team1.InitialFlagCoords
    else
        gameInfo.Teams.Team2.FlagPickup = nil
        gameInfo.Teams.Team2.FlagDropped = false
        gameInfo.Teams.Team2.CurrentFlagCoords = gameInfo.Teams.Team2.InitialFlagCoords
    end
end

RegisterServerEvent("DalraeEvent:Ping", function()
    if not gameInfo.PlayerTeams[source] then
        gameInfo.PlayerTeams[source] = {
            ["Team"] = math.random(0,1) == 0 and team1 or team2,
            ["Position"] = GetEntityCoords(GetPlayerPed(source)),
            ["IsConnected"] = true
        }
    end
end)


CreateThread(function()
    Wait(2000)
    gameInfo.Teams.Team1 = team1
    gameInfo.Teams.Team2 = team2
    local flagLocationPair = flagLocations[math.random(1, #flagLocations)]
    gameInfo.Teams.Team1.InitialFlagCoords = flagLocationPair[1]
    gameInfo.Teams.Team1.CurrentFlagCoords = flagLocationPair[1]
    gameInfo.Teams.Team1.Points = 0

    gameInfo.Teams.Team2.InitialFlagCoords = flagLocationPair[2]
    gameInfo.Teams.Team2.CurrentFlagCoords = flagLocationPair[2]
    gameInfo.Teams.Team2.Points = 0

    for teamIndex, team in pairs(gameInfo.Teams) do
        createTeamFlag(team)
    end
   
    while true do
        Wait(1000)
        --pcall(function()
            for playerT, playerInfo in pairs(gameInfo.PlayerTeams) do
                if isPlayerValid(playerT) then
                    gameInfo.PlayerTeams[playerT].Position = GetEntityCoords(GetPlayerPed(playerT))
                    gameInfo.PlayerTeams[playerT].PlayerPed = NetworkGetNetworkIdFromEntity(GetPlayerPed(playerT))
                    gameInfo.PlayerTeams[playerT].PlayerName = GetPlayerName(playerT)
                else
                    gameInfo.PlayerTeams[playerT].IsConnected = false
                end
            end
            for index,team in pairs(gameInfo.Teams) do
                if team.FlagPickup then
                    gameInfo.Teams[index].CurrentFlagCoords = GetEntityCoords(GetPlayerPed(team.FlagPickup.Player))
                    local flagPickup = team.FlagPickup
                    if isPlayerValid(team.FlagPickup.Player) then
                        if GetEntityHealth(GetPlayerPed(team.FlagPickup.Player)) <= 0 then -- If the player died while holding the flag
                            TriggerClientEvent("chatMessage", -1, ("^*^8EVENT NOTIFICATION: ^2%s^3 dropped the %s^3 team flag!"):format(GetPlayerName(team.FlagPickup.Player), team.ChatColorPrefix..team.Name))
                            createTeamFlag(team)
                            gameInfo.Teams[index].CurrentFlagCoords = GetEntityCoords(GetPlayerPed(flagPickup.Player))
                            SetEntityCoords(NetworkGetEntityFromNetworkId(gameInfo.Objects[team.Name].NetID), gameInfo.Teams[index].CurrentFlagCoords)
                            gameInfo.Teams[index].FlagDropped = true
                        end
                    else -- If the player left while holding the flag
                        TriggerClientEvent("chatMessage", -1, ("^*^8EVENT NOTIFICATION: ^2%s^3 dropped the %s^3 team flag!"):format(GetPlayerName(team.FlagPickup.Player), team.ChatColorPrefix..team.Name))
                        createTeamFlag(team)
                        gameInfo.Teams[index].CurrentFlagCoords = GetEntityCoords(GetPlayerPed(flagPickup.Player))
                        SetEntityCoords(NetworkGetEntityFromNetworkId(gameInfo.Objects[team.Name].NetID), gameInfo.Teams[index].CurrentFlagCoords)
                        gameInfo.Teams[index].FlagDropped = true
                    end
                end
            end
        --end)
        TriggerClientEvent("DalraeEvent:UpdateGameInfo", -1, gameInfo)
    end
end)

RegisterServerEvent("DalraeEvent:UpdateObjectTable", function(eventObjects)
    gameInfo.Objects = eventObjects
end)

RegisterServerEvent("DalraeEvent:PickupFlag", function()
    local myTeam, otherTeam = getPlayerTeams(source)
    if otherTeam.Name == gameInfo.Teams.Team1.Name then
        if not gameInfo.Teams.Team1.FlagPickup then
            gameInfo.Teams.Team1.FlagPickup = {["Player"] = source, ["Name"] = GetPlayerName(source)}
            gameInfo.Objects[gameInfo.Teams.Team1.Name].AttachmentPed = NetworkGetNetworkIdFromEntity(GetPlayerPed(source))
            TriggerClientEvent("DalraeEvent:PSAAnnouncement", -1, ("~h~~r~EVENT NOTIFICATION: %s~s~ picked up the %s~s~ team flag!"):format(myTeam.TextColorPrefix..GetPlayerName(source), otherTeam.TextColorPrefix..otherTeam.Name))
            TriggerClientEvent("chatMessage", -1, ("^*^8EVENT NOTIFICATION: %s^3 picked up the %s^3 team flag!"):format(myTeam.ChatColorPrefix..GetPlayerName(source), otherTeam.ChatColorPrefix..otherTeam.Name))
        end
    else
        if not gameInfo.Teams.Team2.FlagPickup then
            gameInfo.Teams.Team2.FlagPickup = {["Player"] = source, ["Name"] = GetPlayerName(source)}
            gameInfo.Objects[gameInfo.Teams.Team2.Name].AttachmentPed = NetworkGetNetworkIdFromEntity(GetPlayerPed(source))
            TriggerClientEvent("DalraeEvent:PSAAnnouncement", -1, ("~h~~r~EVENT NOTIFICATION: %s~s~ picked up the %s~s~ team flag!"):format(myTeam.TextColorPrefix..GetPlayerName(source), otherTeam.TextColorPrefix..otherTeam.Name))
            TriggerClientEvent("chatMessage", -1, ("^*^8EVENT NOTIFICATION: %s^3 picked up the %s^3 team flag!"):format(myTeam.ChatColorPrefix..GetPlayerName(source), otherTeam.ChatColorPrefix..otherTeam.Name))
        end
    end
end)

RegisterServerEvent("DalraeEvent:ReturnFlag", function()
    local myTeam, otherTeam = getPlayerTeams(source)
    if myTeam.Name == gameInfo.Teams.Team1.Name then
        gameInfo.Teams.Team1.FlagDropped = false
        createTeamFlag(gameInfo.Teams.Team1)
    else
        gameInfo.Teams.Team2.FlagDropped = false
        createTeamFlag(gameInfo.Teams.Team2)
    end
end)

RegisterServerEvent("DalraeEvent:CaptureFlag", function()
    local myTeam, otherTeam = getPlayerTeams(source)
    if otherTeam.Name == gameInfo.Teams.Team1.Name then
        if gameInfo.Teams.Team1.FlagPickup then
            gameInfo.Teams.Team1.LastFlagPickup = gameInfo.Teams.Team1.FlagPickup
            gameInfo.Teams.Team1.FlagPickup = nil
            gameInfo.Teams.Team1.FlagDropped = false
            gameInfo.Teams.Team1.CurrentFlagCoords = gameInfo.Teams.Team1.InitialFlagCoords
            gameInfo.Objects[gameInfo.Teams.Team1.Name].AttachmentPed = nil

            createTeamFlag(gameInfo.Teams.Team1)

            gameInfo.Teams.Team2.Points = gameInfo.Teams.Team2.Points+1
            TriggerClientEvent("DalraeEvent:PSAAnnouncement", -1, ("~h~~r~EVENT NOTIFICATION: %s~s~ captured the %s~s~ team flag!"):format(myTeam.TextColorPrefix..GetPlayerName(source), otherTeam.TextColorPrefix..otherTeam.Name))
            TriggerClientEvent("chatMessage", -1, ("^*^8EVENT NOTIFICATION: %s^3 captured the %s^3 team flag!"):format(myTeam.ChatColorPrefix..GetPlayerName(source), otherTeam.ChatColorPrefix..otherTeam.Name))
        end
    else
        if gameInfo.Teams.Team2.FlagPickup then
            gameInfo.Teams.Team2.LastFlagPickup = gameInfo.Teams.Team2.FlagPickup
            gameInfo.Teams.Team2.FlagPickup = nil
            gameInfo.Teams.Team2.FlagDropped = false
            gameInfo.Teams.Team2.CurrentFlagCoords = gameInfo.Teams.Team2.InitialFlagCoords
            gameInfo.Objects[gameInfo.Teams.Team2.Name].AttachmentPed = nil


            createTeamFlag(gameInfo.Teams.Team2)

            gameInfo.Teams.Team1.Points = gameInfo.Teams.Team1.Points+1
            TriggerClientEvent("DalraeEvent:PSAAnnouncement", -1, ("~h~~r~EVENT NOTIFICATION: %s~s~ captured the %s~s~ team flag!"):format(myTeam.TextColorPrefix..GetPlayerName(source), otherTeam.TextColorPrefix..otherTeam.Name))
            TriggerClientEvent("chatMessage", -1, ("^*^8EVENT NOTIFICATION: %s^3 captured the %s^3 team flag!"):format(myTeam.ChatColorPrefix..GetPlayerName(source), otherTeam.ChatColorPrefix..otherTeam.Name))
        end
    end
    if gameInfo.Teams.Team1.Points >= maxPoints then
        gameInfo.gameWon = gameInfo.Teams.Team1
        gameInfo.gameLost = gameInfo.Teams.Team2
    elseif gameInfo.Teams.Team2.Points >= maxPoints then
        gameInfo.gameWon = gameInfo.Teams.Team2
        gameInfo.gameLost = gameInfo.Teams.Team1
    end
    if gameInfo.gameWon and not gameInfo.gameAlreadyWon then
        gameInfo.gameAlreadyWon = true
        TriggerClientEvent("DalraeEvent:PSAAnnouncement", -1, ("~h~~r~EVENT NOTIFICATION: %s~s~ team won the game with ~g~%s~s~/~g~%s~s~!"):format(gameInfo.gameWon.TextColorPrefix..gameInfo.gameWon.Name, gameInfo.gameWon.Points, gameInfo.gameLost.Points))
        TriggerClientEvent("chatMessage", -1, ("^*^8EVENT NOTIFICATION: %s^3 team won the game with ^2%s^3/^2%s^3!"):format(gameInfo.gameWon.ChatColorPrefix..gameInfo.gameWon.Name, gameInfo.gameWon.Points, gameInfo.gameLost.Points))
    end
end)

RegisterCommand("setflag", function(source, args) -- Should be restricted to staff
    if args and args[1] and (args[1]:lower() == team1.Name:lower() or args[1]:lower() == team2.Name:lower()) then
        if args[1]:lower() == team1.Name:lower() then
            createTeamFlag(team1)
            gameInfo.Teams.Team1.CurrentFlagCoords = GetEntityCoords(GetPlayerPed(source))
            SetEntityCoords(NetworkGetEntityFromNetworkId(gameInfo.Objects[team1.Name].NetID), GetEntityCoords(GetPlayerPed(source)))
        else
            createTeamFlag(team2)
            gameInfo.Teams.Team2.CurrentFlagCoords = GetEntityCoords(GetPlayerPed(source))
            SetEntityCoords(NetworkGetEntityFromNetworkId(gameInfo.Objects[team2.Name].NetID), GetEntityCoords(GetPlayerPed(source)))
        end
    else
        TriggerClientEvent("chatMessage", source, "^*^8Command usage: /setflag [red/blue]")
    end
end)

RegisterCommand("resetflag", function(source, args) -- Should be restricted to staff
    if args and args[1] and (args[1]:lower() == team1.Name:lower() or args[1]:lower() == team2.Name:lower()) then
        if args[1]:lower() == team1.Name:lower() then
            createTeamFlag(team1)
            gameInfo.Teams.Team1.CurrentFlagCoords = gameInfo.Teams.Team1.InitialFlagCoords
            SetEntityCoords(NetworkGetEntityFromNetworkId(gameInfo.Objects[team1.Name].NetID), gameInfo.Teams.Team1.InitialFlagCoords)
        else
            createTeamFlag(team2)
            gameInfo.Teams.Team2.CurrentFlagCoords = gameInfo.Teams.Team2.InitialFlagCoords
            SetEntityCoords(NetworkGetEntityFromNetworkId(gameInfo.Objects[team2.Name].NetID), gameInfo.Teams.Team2.InitialFlagCoords)
        end
    else
        TriggerClientEvent("chatMessage", source, "^*^8Command usage: /resetflag [red/blue]")
    end
end)

RegisterCommand("setbase", function(source, args) -- Should be restricted to staff
    if args and args[1] and (args[1]:lower() == team1.Name:lower() or args[1]:lower() == team2.Name:lower()) then
        if args[1]:lower() == team1.Name:lower() then
            gameInfo.Teams.Team1.InitialFlagCoords = GetEntityCoords(GetPlayerPed(source))+vector3(0,0,4)
            createTeamFlag(team1)
        else
            gameInfo.Teams.Team2.InitialFlagCoords = GetEntityCoords(GetPlayerPed(source))+vector3(0,0,4)
            createTeamFlag(team2)
        end
    else
        TriggerClientEvent("chatMessage", source, "^*^8Command usage: /setflag [red/blue]")
    end
end)

RegisterCommand("bothteams", function(source, args) -- Should be restricted to staff
    gameInfo.PlayerTeams[source].BothTeams = not gameInfo.PlayerTeams[source].BothTeams
    if gameInfo.PlayerTeams[source].BothTeams then
        TriggerClientEvent("chatMessage", source, "^*^8You can now see both team's blips and name tags.")
    else
        TriggerClientEvent("chatMessage", source, "^*^8You can no longer see both team's blips and name tags.")
    end
end)

AddEventHandler("onResourceStop", function(name)
    if name == GetCurrentResourceName() then
        for _,objectItem in pairs(gameInfo.Objects) do
            local object = NetworkGetEntityFromNetworkId(objectItem.NetID)
            if DoesEntityExist(object) then
                DeleteEntity(object)
            end
        end
    end
end)
