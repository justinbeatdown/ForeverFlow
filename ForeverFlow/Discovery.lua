-- ForeverFlow 0.5.5 beta: Quest Discovery using only information exposed by the client.
-- No third-party quest database, speculative coordinates or gameplay automation.
local _, FF = ...

local function safe(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a = pcall(fn, ...)
    if ok then return a end
    return nil
end
local function validID(x) return type(x)=="number" and x>0 and x<10000000 end
local function reportedQuestLevel(id, hint)
    local value=tonumber(hint)
    if not value and C_QuestLog then
        value=tonumber(safe(C_QuestLog.GetQuestDifficultyLevel,id))
    end
    if value and value>=1 and value<=100 then return value end
    return nil
end
local function limitedTitle(x)
    if type(x)~="string" or x=="" then return nil end
    return x:sub(1,105)
end
local function currentMap()
    return C_Map and safe(C_Map.GetBestMapForUnit,"player") or nil
end
local function playerZoneKey(mapID)
    local z=type(GetZoneText)=="function" and safe(GetZoneText) or nil
    local sub=type(GetSubZoneText)=="function" and safe(GetSubZoneText) or nil
    local info=C_Map and mapID and safe(C_Map.GetMapInfo,mapID)
    local names={z,sub,type(info)=="table" and info.name or nil}
    for _,name in ipairs(names) do
        if type(name)=="string" then
            local normalized=name:lower()
            if normalized:find("stonetalon",1,true) then return 406 end
            if normalized:find("barrens",1,true) then return 17 end
        end
    end
    if mapID==1413 then return 17 end
    if mapID==1442 then return 406 end
    return nil
end
local function playerPosition(mapID)
    local pos=C_Map and type(C_Map.GetPlayerMapPosition)=="function" and safe(C_Map.GetPlayerMapPosition,mapID,"player")
    if pos and type(pos.GetXY)=="function" then
        local ok,x,y=pcall(pos.GetXY,pos)
        if ok and type(x)=="number" and type(y)=="number" then return x*100,y*100 end
    end
    return nil,nil
end
local function faction()
    local value=type(UnitFactionGroup)=="function" and safe(UnitFactionGroup,"player") or nil
    if value=="Horde" then return "H" end
    if value=="Alliance" then return "A" end
    return nil
end
local function zoneTitle(id)
    local info = C_Map and safe(C_Map.GetMapInfo,id)
    return type(info)=="table" and limitedTitle(info.name) or "Current map"
end
local function completed(id)
    if C_QuestLog and type(C_QuestLog.IsQuestFlaggedCompleted)=="function" then
        return safe(C_QuestLog.IsQuestFlaggedCompleted,id)==true
    end
    if type(IsQuestFlaggedCompleted)=="function" then
        return safe(IsQuestFlaggedCompleted,id)==true
    end
    return false
end
local function ownQuestIDs(snapshot)
    local found={}
    for _,q in ipairs(snapshot.quests or {}) do
        if validID(q.id) then found[q.id]=true end
    end
    return found
end
function FF:RememberNearbyQuests()
    if not self.char then return end
    local mapID=currentMap()
    if not validID(mapID) then return end
    -- Do not store unverified pickup coordinates; showing the zone is sufficient.
    local npc=type(UnitName)=="function" and safe(UnitName,"npc") or nil
    local quests=nil
    if C_GossipInfo and type(C_GossipInfo.GetAvailableQuests)=="function" then
        quests=safe(C_GossipInfo.GetAvailableQuests)
    end
    if type(quests)~="table" then quests={} end
    local seen=self.char.seenDiscoveries
    if type(seen)~="table" then seen={};self.char.seenDiscoveries=seen end
    local stored=0
    for _,q in ipairs(quests) do
        local id=type(q)=="table" and (q.questID or q.questId) or nil
        local title=type(q)=="table" and limitedTitle(q.title or q.name) or nil
        if validID(id) and title then
            seen[id]={id=id,title=title,mapID=mapID,mapName=zoneTitle(mapID),
                npc=limitedTitle(npc),level=reportedQuestLevel(id,q.level),source="seenNPC"}
            stored=stored+1
        end
    end
    -- Older quest-greeting APIs may exist on certain Forever client builds.
    if stored==0 and type(GetNumAvailableQuests)=="function" and type(GetAvailableTitle)=="function" then
        local count=tonumber(safe(GetNumAvailableQuests)) or 0
        -- No ID available here; don't invent identity or store ambiguous records.
        self.discoveryGreetingCount=math.min(30,math.max(0,count))
    end
end

function FF:FindDiscoveries(snapshot, force)
    if not snapshot or not self.char then return {},"No character snapshot" end
    local mapID=currentMap()
    local current=ownQuestIDs(snapshot)
    local list,byID={},{}
    local level=tonumber(snapshot.level) or 1
    local seen=self.char.seenDiscoveries or {}
    local ignored=self.char.skippedDiscoveries or {}
    local zoneKey=playerZoneKey(mapID)
    local browseAll=self.char.discoverBrowseAll==true
    local playerFaction=faction()
    local saved=self.char.savedDiscoveries or {}
    local function add(q)
        if not validID(q.id) or current[q.id] or completed(q.id) or ignored[q.id] then return end
        if byID[q.id] then
            -- Merge new client observations while preserving useful catalog
            -- pickup details and coordinates instead of dropping them.
            local old=byID[q.id]
            if q.source=="seenNPC" or q.source=="clientLine" then
                old.confidence=q.source=="seenNPC" and "NPC SEEN" or "CLIENT HINT"
                old.clientSeen=true
                if q.npc and not old.npc then old.npc=q.npc end
                if q.title and q.title:sub(1,6)~="Quest " then old.title=q.title end
            end
            return
        end
        byID[q.id]=q
    end
    -- Offline catalog works immediately, even when quest-line APIs are absent.
    -- In current-zone mode, allow cross-zone suggestions when your actual zone
    -- has no eligible pickup; the user can also switch to browsing nearby hubs.
    local function catalogPass(includeOtherZone)
        for _,r in ipairs(self.questCatalog or {}) do
            local id,name,area,minLevel,questLevel,side,npc,x,y,flags=unpack(r)
            local match=(area==zoneKey)
            if (match or includeOtherZone or saved[id]) and (side=="B" or not playerFaction or side==playerFaction) then
                local zone=(self.catalogZones or {})[area]
                if zone and level>=minLevel and (questLevel<=level+7 or saved[id]) then
                    add({id=id,title=name,areaID=area,mapID=zone.uiMapID,
                        mapName=zone.name,level=questLevel,minLevel=minLevel,
                        npc=npc,x=x,y=y,flags=flags,source="offline",
                        confidence="REPORTED PICKUP",typeLabel="OFFLINE QUEST START",
                        nearby=match})
                end
            end
        end
    end
    catalogPass(browseAll)
    if validID(mapID) then
        if force and C_QuestLine and C_QuestLine.RequestQuestLinesForMap then
            safe(C_QuestLine.RequestQuestLinesForMap,mapID)
        end
        if C_QuestLine and type(C_QuestLine.GetAvailableQuestLines)=="function" then
            local lines=safe(C_QuestLine.GetAvailableQuestLines,mapID)
            if type(lines)=="table" then
                for _,q in ipairs(lines) do
                    if type(q)=="table" and not q.isHidden and not q.inProgress then
                        local id=q.questID or q.questId
                        if validID(id) then
                            local name=limitedTitle(q.questName or q.questLineName)
                            if not name and C_QuestLog then name=limitedTitle(safe(C_QuestLog.GetTitleForQuestID,id)) end
                            add({id=id,title=name or ("Quest #"..id),mapID=mapID,
                                mapName=zoneTitle(mapID),level=reportedQuestLevel(id,q.questLevel),
                                source="clientLine",typeLabel="QUEST LINE ON MAP",
                                confidence="CLIENT-LISTED",lineID=q.questLineID})
                        end
                    end
                end
            end
        end
        -- Some clients expose quest-start POIs, which are suggestions rather than
        -- verified quest-giver coordinates or guarantee of actual availability.
        if C_QuestLog and type(C_QuestLog.GetQuestsOnMap)=="function" then
            local pois=safe(C_QuestLog.GetQuestsOnMap,mapID)
            if type(pois)=="table" then
                for _,poi in ipairs(pois) do
                    if type(poi)=="table" and poi.isQuestStart and validID(poi.questID) then
                        local name=C_QuestLog and limitedTitle(safe(C_QuestLog.GetTitleForQuestID,poi.questID))
                        add({id=poi.questID,title=name or ("Quest #"..poi.questID),mapID=mapID,
                            mapName=zoneTitle(mapID),level=reportedQuestLevel(poi.questID),source="questPOI",typeLabel="MAP QUEST START",
                            confidence="MAP HINT"})
                    end
                end
            end
        end
    end
    for id,q in pairs(seen) do
        if validID(id) and type(q)=="table" and type(q.title)=="string" and
            (q.mapID==mapID or saved[id]) then
            add({id=id,title=q.title,mapID=q.mapID,mapName=q.mapName or "Previously visited area",
                npc=q.npc,level=reportedQuestLevel(id,q.level),source="seenNPC",typeLabel="QUEST GIVER SEEN",
                confidence="SEEN EARLIER"})
        end
    end
    -- If the present area truly has nothing useful, fall back to the other
    -- covered leveling hub rather than a dead 0-results view.
    if not next(byID) and not browseAll then catalogPass(true) end
    local px,py=playerPosition(mapID)
    for _,q in pairs(byID) do
        local levelDiff=type(q.level)=="number" and math.abs(level-q.level) or nil
        q.saved=saved[q.id]==true
        local sameZone=(q.areaID and q.areaID==zoneKey) or (q.mapID and q.mapID==mapID)
        local nearbyDistance=nil
        if q.source=="offline" and sameZone and px and py and q.x and q.y then
            nearbyDistance=math.sqrt((px-q.x)^2+(py-q.y)^2)
        end
        q.score=(q.source=="offline" and 70 or q.source=="clientLine" and 65 or q.source=="questPOI" and 55 or 45)
            +(q.saved and 18 or 0)+(sameZone and 48 or -48)
            +(levelDiff and math.max(-70,40-levelDiff*10) or 0)
            -(nearbyDistance and math.floor(nearbyDistance*.85) or 0)
            -(q.flags=="elite" and 75 or 0)
            -(q.minLevel and q.minLevel>level-1 and 6 or 0)
        if q.source=="offline" then
            q.why=(q.saved and "SAVED | " or "")
                ..(q.flags=="elite" and "ELITE / GROUP? | " or "")
                .."Pick up: "..(q.npc or "unknown")
                ..(q.x and string.format(" %.1f, %.1f",q.x,q.y) or "")
                .." | "..tostring(q.mapName or "Unknown zone")
                .." | Lv "..tostring(q.level or "?").."; prerequisites unverified"
        else
            q.why=(q.saved and "SAVED | " or "")
                ..(q.npc and ("Seen at "..q.npc.."; ") or "Client-listed quest start; ")
                .."Lv "..tostring(q.level or "?").."; confirm prerequisites"
        end
        list[#list+1]=q
    end
    table.sort(list,function(a,b)
        if a.score~=b.score then return a.score>b.score end
        return a.id<b.id
    end)
    self.discoveredQuests=list
    local info=(#list>0 and (#list.." possible quests: offline pickup records + client hints; check NPC / chain access")
        or "No matching quest starts in this area at your level. Try BROWSE ZONES or talk to a quest giver.")
    return list,info
end
function FF:ToggleSavedDiscovery(id)
    if not validID(id) then return end
    local t=self.char.savedDiscoveries
    t[id]=not t[id] or nil
    self:Refresh()
end
function FF:SkipDiscovery(id)
    if not validID(id) then return end
    self.char.skippedDiscoveries[id]=true
    self:Refresh()
end
function FF:ResetSkippedDiscoveries()
    self.char.skippedDiscoveries={}
    if self.snapshot then self:FindDiscoveries(self.snapshot,true) end
    self:Refresh()
end
function FF:ShowDiscoveryOnMap(q)
    if not q then return end
    if InCombatLockdown and InCombatLockdown() then
        self:Message("Open your world map after combat to review this quest area.")
        return
    end
    local zone=tostring(q.mapName or "unknown")
    if q.x and q.y then
        local formatted=string.format("%.1f, %.1f",q.x,q.y)
        -- Optional TomTom integration; user must already have TomTom installed.
        if TomTom and type(TomTom.AddWaypoint)=="function" and validID(q.mapID) then
            local ok=pcall(TomTom.AddWaypoint,TomTom,q.mapID,q.x/100,q.y/100,
                {title="ForeverFlow: "..tostring(q.npc or q.title),persistent=false})
            if ok then self:Message("TomTom waypoint: "..zone.." "..formatted.."; NPC: "..tostring(q.npc or "unknown")) end
        end
        if type(ToggleWorldMap)=="function" and (not WorldMapFrame or not WorldMapFrame:IsShown()) then safe(ToggleWorldMap) end
        if validID(q.mapID) and WorldMapFrame and type(WorldMapFrame.SetMapID)=="function" then
            safe(WorldMapFrame.SetMapID,WorldMapFrame,q.mapID)
        end
        self:Message("Reported pickup: "..tostring(q.npc or "quest giver").." in "..zone.." at "..formatted..". Check quest prerequisites.")
    else
        if type(ToggleWorldMap)=="function" and (not WorldMapFrame or not WorldMapFrame:IsShown()) then safe(ToggleWorldMap) end
        if validID(q.mapID) and WorldMapFrame and type(WorldMapFrame.SetMapID)=="function" then
            safe(WorldMapFrame.SetMapID,WorldMapFrame,q.mapID)
        end
        self:Message("Map area: "..zone..". Quest-giver pickup coordinates not known.")
    end
end
