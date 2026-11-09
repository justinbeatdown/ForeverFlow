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
    local saved=self.char.savedDiscoveries or {}
    local function add(q)
        if not validID(q.id) or current[q.id] or completed(q.id) or ignored[q.id] then return end
        if byID[q.id] then
            -- Fresh client information takes precedence over cached NPC sightings.
            if q.source=="clientLine" then byID[q.id]=q end
            return
        end
        byID[q.id]=q
    end
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
    for _,q in pairs(byID) do
        local levelDiff=type(q.level)=="number" and math.abs(level-q.level) or nil
        q.saved=saved[q.id]==true
        q.score=(q.source=="clientLine" and 65 or q.source=="questPOI" and 48 or 40)
            +(q.saved and 45 or 0)+(q.mapID==mapID and 20 or -10)
            +(levelDiff and math.max(-60,22-levelDiff*8) or 0)
        local why=q.saved and "Saved for later; " or ""
        why=why..(q.source=="seenNPC" and ("Seen at "..(q.npc or "a quest giver").."; " )
            or q.source=="questPOI" and "Map shows a quest start; "
            or "Client lists a possible quest line; ")
        why=why..(levelDiff and ("quest level ~"..q.level.."; ") or "level requirements not confirmed; ")
            .."check the quest giver for eligibility"
        q.why=why
        list[#list+1]=q
    end
    table.sort(list,function(a,b)
        if a.score~=b.score then return a.score>b.score end
        return a.id<b.id
    end)
    self.discoveredQuests=list
    local info=(#list>0 and (#list.." possible unaccepted quests found on map / previously seen")
        or "No unaccepted quests exposed by this client here. Talk to a quest giver or try another zone.")
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
    if type(ToggleWorldMap)=="function" then safe(ToggleWorldMap) end
    if validID(q.mapID) and WorldMapFrame and type(WorldMapFrame.SetMapID)=="function" then
        safe(WorldMapFrame.SetMapID,WorldMapFrame,q.mapID)
    end
    self:Message("Map area: "..tostring(q.mapName or "unknown")..". A quest-giver pickup pin is NOT verified.")
end
