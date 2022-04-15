-- Created by Dalrae
local deathMessages = {
    "Well that was dumb.",
    "Didn't get the flag, did ya?",
    "That wasn't expected...",
    "You didn't expect that one.",
    "You died.",
    "Whoops",
    "I don't think you meant to do that",
    "Huh.",
    "Oh shit",
    "You were so close..",
    "Fuck",
    "No death message for you.",
    ""
}
NetworkSetFriendlyFireOption(true)
local objects = {}
local blips = {}
local gameInfo = nil
local myTeam = nil
local screenX, screenY = GetActiveScreenResolution()
function GetMinimapAnchor()
    local minimap = {}
    SetScriptGfxAlign(string.byte('L'), string.byte('B'))
    local minimapTopX, minimapTopY = GetScriptGfxPosition(-0.0045, 0.002 + (-0.188888))
    ResetScriptGfxAlign()

    local aspect_ratio = GetAspectRatio(0)
    local res_x, res_y = GetActiveScreenResolution()
    local xscale = 1.0 / res_x
    local yscale = 1.0 / res_y
    minimap.width = xscale * (res_x / (4 * aspect_ratio))
    minimap.right_x = minimapTopX+minimap.width
    return minimap
end

function DrawTxt(x, y, text, center, scale, font)
    --[[x1 = 50/(screenX-1920)
    if x1 > 1 then
        x1 = 0
    end
    x = x-x1]]
    SetTextFont(font or 4)
    SetTextProportional(0)
    SetTextScale(scale or 0.45, scale or 0.45)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow(0, 0, 0, 0,255)
    SetTextEdge(2, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(center == true)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

function DrawText3D(x, y, z, text)
	local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
	if onScreen then
		SetTextScale(0.35, 0.35)
		SetTextFont(4)
		SetTextProportional(1)
		SetTextColour(255, 255, 255, 215)
		SetTextDropShadow(0, 0, 0, 55)
		SetTextEdge(0, 0, 0, 150)
		SetTextDropShadow()
		SetTextOutline()
		SetTextEntry("STRING")
		SetTextCentre(1)
		AddTextComponentString(text)
		DrawText(_x,_y)
	end
end

function getPlayerTeams(player)
    local myTeam, otherTeam
    for playerT,playerInfo in pairs(gameInfo.PlayerTeams) do
        if tonumber(playerT) == tonumber(GetPlayerServerId(player)) then
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

function RespawnPlayer()
    CreateThread(function()
        repeat
            local randomCoord = vector3(myTeam.InitialFlagCoords.x+math.random(-500,500),myTeam.InitialFlagCoords.y+math.random(-500,500), 0.0)
            RequestCollisionAtCoord(randomCoord.x,randomCoord.y, randomCoord.z)
            local groundZ
            repeat
                _, groundZ = GetGroundZFor_3dCoord_2(randomCoord.x, randomCoord.y, 10000.0, false)
                Wait(0)
            until groundZ and groundZ ~= 0.0
            randomCoord = vector3(randomCoord.x, randomCoord.y, groundZ)
            SetEntityCoordsNoOffset(PlayerPedId(), randomCoord.x,randomCoord.y, randomCoord.z, false, false, false, true)
            NetworkResurrectLocalPlayer(randomCoord.xyz, 0.0, true, false) 
            SetPlayerInvincible(PlayerPedId(), false) 
            ClearPedBloodDamage(PlayerPedId())
            Wait(100)
        until not IsEntityInWater(PlayerPedId())
    end)
end

RegisterNetEvent("DalraeEvent:RespawnPlayer", RespawnPlayer)

TriggerServerEvent("DalraeEvent:Ping")
local numPSA = 0
RegisterNetEvent("DalraeEvent:PSAAnnouncement", function(message)
    numPSA = numPSA+1
    local curNumPSA = numPSA
    local startTimer = GetGameTimer()
    CreateThread(function()
        
        while true do
            Wait(1)
            local y = 0.14+(curNumPSA*0.06)
            DrawRect(0.48, y, 0.3, 0.05, 0.0, 0.0, 0.0, 255.0)
            DrawTxt(0.48, y-0.012, message, true, 0.3, 0)
            if GetGameTimer()-startTimer > 7000 then
                numPSA = numPSA-1
                break
            end
        end
    end)
    
end)

RegisterNetEvent("DalraeEvent:UpdateGameInfo", function(serverGameInfo)
    local oldGameInfo = gameInfo
    gameInfo = serverGameInfo
    myTeam, otherTeam = getPlayerTeams(PlayerId())
    for objectTeamName,objectItem in pairs(gameInfo.Objects) do -- Handle ped attachments
        local object = NetworkGetEntityFromNetworkId(objectItem.NetID)
        if DoesEntityExist(object) then
            local objectTeam
            if objectTeamName == myTeam.Name then
                objectTeam = myTeam
            elseif objectTeamName == otherTeam.Name then
                objectTeam = otherTeam
            end
            if objectTeam then
                if objectItem.AttachmentPed then
                    local objectAttachment = DoesEntityExist(NetworkGetEntityFromNetworkId(objectItem.AttachmentPed)) and NetworkGetEntityFromNetworkId(objectItem.AttachmentPed)
                    if objectAttachment then
                        AttachEntityToEntity(object, objectAttachment, GetPedBoneIndex(objectAttachment, 0x49D9))
                    end
                end
            end
        end
    end
end)

CreateThread(function()
    while true do -- Update blip coords
        Wait(500)
        if gameInfo and myTeam then
            for _,team in pairs(gameInfo.Teams) do
                if blips[team.Name.."Flag"] then
                    SetBlipCoords(blips[team.Name.."Flag"], team.CurrentFlagCoords.xyz)
                else
                    local blip = AddBlipForCoord(team.CurrentFlagCoords.xyz)
                    blips[team.Name.."Flag"] = blip
                    SetBlipSprite(blip, 38)
                    SetBlipColour(blip, team.BlipColor)
                    AddTextEntry('FlagBlip', ('%s team flag'):format(team.Name))
                    BeginTextCommandSetBlipName('FlagBlip')
                    AddTextComponentSubstringPlayerName('me')
                    EndTextCommandSetBlipName(blip)
                end

                if blips[team.Name.."Base"] then
                    SetBlipCoords(blips[team.Name.."Base"], team.InitialFlagCoords.xyz)
                else
                    local blip = AddBlipForCoord(team.InitialFlagCoords.xyz)
                    blips[team.Name.."Base"] = blip
                    SetBlipSprite(blip, 536)
                    SetBlipColour(blip, team.BlipColor)
                    AddTextEntry('BaseBlip', ('%s team base'):format(team.Name))
                    BeginTextCommandSetBlipName('BaseBlip')
                    AddTextComponentSubstringPlayerName('me')
                    EndTextCommandSetBlipName(blip)
                end
                
            end
            for playerT, playerInfo in pairs(gameInfo.PlayerTeams) do
                if blips[playerT] then
                    RemoveBlip(blips[playerT])
                end
                if (playerInfo.Team.Name == myTeam.Name or gameInfo.PlayerTeams[GetPlayerServerId(PlayerId())].BothTeams) then
                    if playerInfo.IsConnected and tonumber(playerT) ~= tonumber(GetPlayerServerId(PlayerId())) then
                        local blip = AddBlipForCoord(playerInfo.Position.xyz)
                        blips[playerT] = blip
                        SetBlipSprite(blip, 288)
                        SetBlipColour(blip, playerInfo.Team.BlipColor)
                        AddTextEntry('TeamBlip', 'Team member')
                        BeginTextCommandSetBlipName('TeamBlip')
                        AddTextComponentSubstringPlayerName('me')
                        EndTextCommandSetBlipName(blip)
                    end
                end
            end
        end
    end
end)

CreateThread(function()
    while not gameInfo or not gameInfo.gameWon do -- Do UI stuff
        Wait(1)
        if myTeam then
            if gameInfo then
                for playerT,playerInfo in pairs(gameInfo.PlayerTeams) do
                    if playerInfo.Team.Name == myTeam.Name then
                        local isAiming, aimingAt = GetEntityPlayerIsFreeAimingAt(PlayerId())
                        if isAiming and aimingAt == GetPlayerPed(GetPlayerFromServerId(playerT) )then
                            SetPlayerCanDoDriveBy(PlayerId(), false)
                            DisablePlayerFiring(PlayerId(), true)
                            DisableControlAction(0, 140)
                            DrawTxt(0.45, 0.9, "~h~~r~You can't shoot your own team.")
                        end
                    end
                end
                DrawTxt(GetMinimapAnchor().right_x+0.01, 0.8, ("Your Team: %s"):format(myTeam.TextColorPrefix..myTeam.Name))
                DrawTxt(0.5, 0, ("Your Goal: Pick up the %s~s~ team's flag, and prevent the other team from grabbing yours"):format(otherTeam.TextColorPrefix..otherTeam.Name), true)
                DrawTxt(GetMinimapAnchor().right_x+0.01, 0.88, "Points:")
                local i = 0
                for _,team in pairs(gameInfo.Teams) do
                    i = i+1
                    DrawTxt(GetMinimapAnchor().right_x+0.01, (0.89)+(0.02*i), ("%s :"):format(team.TextColorPrefix..team.Name))
                    DrawTxt(GetMinimapAnchor().right_x+0.035, (0.89)+(0.02*i), ("%s"):format(team.TextColorPrefix..team.Points or 0))
                end
                if otherTeam.FlagPickup and otherTeam.FlagPickup.Player == GetPlayerServerId(PlayerId()) and not IsEntityDead(PlayerPedId()) then
                    DrawTxt(0.45, 0.9, ("You have the %s~s~ team's flag! Get it to your base!"):format(otherTeam.TextColorPrefix..otherTeam.Name))
                    if GetDistanceBetweenCoords(myTeam.InitialFlagCoords, GetEntityCoords(PlayerPedId()), true) < 6 then
                        if not gameInfo.CapWithFlagGone and not myTeam.FlagPickup or gameInfo.CapWithFlagGone then
                            TriggerServerEvent("DalraeEvent:CaptureFlag")
                        else
                            DrawTxt(0.45, 0.9, "You need your flag at your base to capture the other team's flag!")
                        end
                    end
                elseif not otherTeam.FlagPickup and GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), otherTeam.CurrentFlagCoords, true) < 6 and not IsEntityDead(PlayerPedId()) then
                    if not IsPedInAnyVehicle(PlayerPedId()) then
                        DrawTxt(0.5, 0.9, ("Press ~g~E~s~ to pick up the %s~s~ team's flag"):format(otherTeam.TextColorPrefix..otherTeam.Name), true)
                        if IsControlJustReleased(0, 38) then -- E
                            TriggerServerEvent("DalraeEvent:PickupFlag")
                        end
                    else
                        DrawTxt(0.5, 0.9, "You need to get out of your vehicle to pick up the flag", true)
                    end
                end
                if myTeam.FlagDropped and GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), myTeam.CurrentFlagCoords, true) < 6 and not IsEntityDead(PlayerPedId()) then
                    DrawTxt(0.5, 0.9, "Press ~g~E~s~ to return your team's flag", true)
                    if IsControlJustReleased(0, 38) then -- E
                        TriggerServerEvent("DalraeEvent:ReturnFlag")
                    end
                end
            end
            if gameInfo and gameInfo.PlayerTeams then
                for playerT, playerInfo in pairs(gameInfo.PlayerTeams) do
                    if (playerInfo.Team.Name == myTeam.Name or gameInfo.PlayerTeams[GetPlayerServerId(PlayerId())].BothTeams) and GetPlayerServerId(PlayerId()) ~= playerT then
                        local playerPed = NetworkGetEntityFromNetworkId(playerInfo.PlayerPed)
                        if playerPed > 0 and DoesEntityExist(playerPed) then
                            local coords = GetEntityCoords(playerPed)
                            coords = GetPedBoneCoords(playerPed, 0x796E)
                            DrawText3D(coords.x, coords.y, coords.z+0.2, playerInfo.Team.TextColorPrefix..playerInfo.PlayerName, vector3(0,0,0))
                        end
                    end
                end
            end
            if IsEntityDead(PlayerPedId()) and not deathDeb then
                deathDeb = true
                CreateThread(function()
                    CreateThread(function()
                        StartScreenEffect("DeathFailOut", 0, 0)
                        if not locksound then
                            PlaySoundFrontend(-1, "Bed", "WastedSounds", 1)
                            locksound = true
                        end
                        ShakeGameplayCam("DEATH_FAIL_IN_EFFECT_SHAKE", 1.0)
                        local scaleform = RequestScaleformMovie("MP_BIG_MESSAGE_FREEMODE")
                        if HasScaleformMovieLoaded(scaleform) then
                            Citizen.Wait(0)
                            BeginScaleformMovieMethod(scaleform, "SHOW_SHARD_WASTED_MP_MESSAGE")
                            BeginTextComponent("STRING")
                            AddTextComponentString("~r~wasted")
                            EndTextComponent()
                            PopScaleformMovieFunctionVoid()
                            Citizen.Wait(500)
                            PlaySoundFrontend(-1, "TextHit", "WastedSounds", 1)
                            local deathMsg = deathMessages[math.random(1,#deathMessages)]
                            while IsEntityDead(PlayerPedId()) do
                                DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
                                DrawTxt(0.5, 0.54, deathMsg, true)
                                Citizen.Wait(0)
                            end
                            locksound = false
                        end
                        StopScreenEffect("DeathFailOut")
                    end)
                    Wait(7000)
                    RespawnPlayer()
                    
                    deathDeb = false
                end)
            end
        end
    end
end)
