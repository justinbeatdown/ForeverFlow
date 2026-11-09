-- Live, read-only snapshots and transparent heuristics; no vendor pricing or fabricated routes.
local _, FF = ...
local function num(x,default) return type(x)=="number" and x or default end
local function safeCall(fn, ...)
    if type(fn)~="function" then return nil end
    local ok,a,b,c,d=pcall(fn,...)
    if ok then return a,b,c,d end
    return nil
end
local function clamp(n,a,b) return math.max(a,math.min(b,n)) end
local function findText(s)
    if type(s)~="string" then return nil end
    s=s:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
    return s
end
function FF:MoneyText(value, sign)
    local n=num(value,0); local prefix=n<0 and "-" or (sign and n>0 and "+" or "")
    n=math.abs(math.floor(n)); local g=math.floor(n/10000)
    local s=math.floor(n%10000/100); local c=n%100
    if g>0 then return string.format("%s%dg %02ds",prefix,g,s) end
    return string.format("%s%ds %02dc",prefix,s,c)
end
function FF:ReadBags()
    if not C_Container then return nil,nil end
    local slots,free=0,0
    for bag=0,4 do
        local n=safeCall(C_Container.GetContainerNumSlots,bag)
        local f=safeCall(C_Container.GetContainerNumFreeSlots,bag)
        slots=slots+num(n,0); free=free+num(f,0)
    end
    if slots==0 then return nil,nil end
    return free,slots
end
function FF:ReadDurability()
    if not GetInventoryItemDurability then return nil end
    local a,b=0,0
    for i=1,18 do
        local current,max=safeCall(GetInventoryItemDurability,i)
        if type(current)=="number" and type(max)=="number" and max>0 then a=a+current; b=b+max end
    end
    if b<=0 then return nil end
    return math.floor(a*100/b+0.5)
end
local mats={
    [2447]="herb",[765]="herb",[2449]="herb",[785]="herb",[2450]="herb",[2453]="herb",
    [3355]="herb",[3356]="herb",[3357]="herb",[3818]="herb",[3821]="herb",[3358]="herb",
    [4625]="herb",[8831]="herb",[8838]="herb",[8839]="herb",[8845]="herb",[8846]="herb",
    [13463]="herb",[13465]="herb",[13466]="herb",[13467]="herb",[13468]="herb",
    [2770]="ore",[2771]="ore",[2772]="ore",[2775]="ore",[2776]="ore",[3858]="ore",
    [7911]="ore",[10620]="ore",[2835]="ore",[2836]="ore",[2318]="leather",
    [2319]="leather",[4234]="leather",[4304]="leather",[8170]="leather"
}
FF.materialIDs=mats
function FF:RecordInventory(initial)
    if not self.session or not C_Container or not C_Container.GetContainerItemInfo then return end
    local now={}
    for bag=0,4 do
        local count=num(safeCall(C_Container.GetContainerNumSlots,bag),0)
        for slot=1,count do
            local info=safeCall(C_Container.GetContainerItemInfo,bag,slot)
            if type(info)=="table" then
                local id=info.itemID; local amount=num(info.stackCount,0)
                if mats[id] and amount>0 then now[id]=(now[id] or 0)+amount end
            end
        end
    end
    local before=self.session.inventoryBaseline
    if before and not initial then
        for id,n in pairs(now) do
            local gained=math.max(0,n-(before[id] or 0))
            if gained>0 then
                self.session.materials=self.session.materials+gained
                self.char.lifetime.materials=self.char.lifetime.materials+gained
                self.session[mats[id]]=(self.session[mats[id]] or 0)+gained
            end
        end
    end
    self.session.inventoryBaseline=now
end

local function profession(idx)
    local name,icon,rank,cap,_,_,skillID=safeCall(GetProfessionInfo,idx)
    if type(name)~="string" or name=="" then return nil end
    return {name=name, icon=icon, skill=num(rank,0), cap=num(cap,0), id=skillID}
end
function FF:ReadProfessions()
    local r={primary={},secondary={}}
    if not GetProfessions or not GetProfessionInfo then return r end
    local a,b,c,d,e=safeCall(GetProfessions)
    for _,idx in ipairs({a or false,b or false}) do if idx then
        local p=profession(idx); if p then r.primary[#r.primary+1]=p end
    end end
    for _,idx in ipairs({c or false,d or false,e or false}) do if idx then
        local p=profession(idx); if p then r.secondary[#r.secondary+1]=p end
    end end
    return r
end

local function questObjectives(id)
    if not C_QuestLog or not id then return {},nil end
    local objectiveList=safeCall(C_QuestLog.GetQuestObjectives,id)
    local result,progress,total={},0,0
    if type(objectiveList)=="table" then
        for _,obj in ipairs(objectiveList) do
            if type(obj)=="table" then
                local caption=findText(obj.text)
                if caption and caption~="" then
                    result[#result+1]={text=caption, done=obj.finished==true,
                        current=num(obj.fulfilled,0),required=num(obj.required,0)}
                    if obj.finished then progress=progress+1 end
                    total=total+1
                end
            end
        end
    end
    return result, (total>0 and progress/total or nil)
end
local function waypoint(id)
    if not C_QuestLog or not id then return nil end
    local mapID,x,y=safeCall(C_QuestLog.GetNextWaypoint,id)
    local title=findText(safeCall(C_QuestLog.GetNextWaypointText,id))
    local info=nil
    if type(mapID)=="number" and type(x)=="number" and type(y)=="number" and x>=0 and x<=1 and y>=0 and y<=1 then
        local mapInfo=C_Map and safeCall(C_Map.GetMapInfo,mapID)
        info={id=mapID,x=x,y=y,mapName=(type(mapInfo)=="table" and mapInfo.name or nil),text=title}
    elseif title and title~="" then info={text=title} end
    return info
end
function FF:ReadQuests(level)
    local q, count, complete={},nil,0
    if not C_QuestLog or not C_QuestLog.GetNumQuestLogEntries or not C_QuestLog.GetInfo then return q,count,complete end
    local entries,realQuests=safeCall(C_QuestLog.GetNumQuestLogEntries)
    if type(entries)~="number" then return q,count,complete end
    count=num(realQuests,0)
    -- Quest POI fallback: modern Forever APIs sometimes expose quest positions
    -- via map POIs even when GetNextWaypoint is empty.
    local poiByID={}
    local currentMap = C_Map and safeCall(C_Map.GetBestMapForUnit,"player")
    if type(currentMap)=="number" and C_QuestLog.GetQuestsOnMap then
        local pois=safeCall(C_QuestLog.GetQuestsOnMap,currentMap)
        if type(pois)=="table" then
            for _,poi in ipairs(pois) do
                if type(poi)=="table" and type(poi.questID)=="number" and not poi.isQuestStart
                    and type(poi.x)=="number" and type(poi.y)=="number"
                    and poi.x>=0 and poi.x<=1 and poi.y>=0 and poi.y<=1 then
                    poiByID[poi.questID]={id=currentMap,x=poi.x,y=poi.y,source="mapPOI"}
                end
            end
        end
    end
    local header = nil
    local playerArea = (safeCall(GetZoneText) or ""):lower()
    for index=1,math.min(250,entries) do
        local info=safeCall(C_QuestLog.GetInfo,index)
        if type(info)=="table" and info.isHeader and type(info.title)=="string" then
            header=info.title
        end
        if type(info)=="table" and not info.isHeader and not info.isHidden and type(info.title)=="string" then
            local id=info.questID
            local done = type(id)=="number" and safeCall(C_QuestLog.IsComplete,id)==true or info.isComplete==true
            local objectives,progress=questObjectives(id)
            if done then complete=complete+1 end
            local levelReq=num(info.level,0)
            local dist=nil
            if type(id)=="number" then
                local value=safeCall(C_QuestLog.GetDistanceSqToQuest,id)
                if type(value)=="number" and value>=0 then dist=value end
            end
            local wp=waypoint(id)
            if not wp or not wp.id then
                local poi=poiByID[id]
                if poi then
                    local mapInfo=C_Map and safeCall(C_Map.GetMapInfo,poi.id)
                    poi.mapName=type(mapInfo)=="table" and mapInfo.name or nil
                    poi.text=wp and wp.text or nil
                    wp=poi
                end
            end
            local first=nil
            for _,objective in ipairs(objectives) do if not objective.done then first=objective.text;break end end
            -- Locality matters more than completion: do not send a level 15 player
            -- across the continent just to turn in a remote completed quest.
            local sameZone=type(header)=="string" and header:lower()==playerArea and playerArea~=""
            local hasDistance=type(dist)=="number" and dist>=0
            local yards=hasDistance and math.sqrt(dist) or nil
            local near=hasDistance and yards<600
            local bias=levelReq>0 and math.max(-70,33-math.abs(level-levelReq)*8) or 0
            if levelReq>level+3 then bias=bias-70 end
            local proximity = (near and 65 or (hasDistance and math.max(-22,40-yards/120) or 0))
            local locality = sameZone and 85 or (header and -18 or 0)
            local completion = done and (sameZone or near or wp and wp.id) and 40 or (done and -24 or 0)
            local score=bias+proximity+locality+completion+(progress and progress*12 or 0)
            q[#q+1]={id=id,title=info.title,level=levelReq,done=done,objectives=objectives,
                firstObjective=first,progress=progress,score=score,waypoint=wp,distanceSq=dist,
                questArea=header,zoneMatch=sameZone,near=near}
        end
    end
    if count==0 then count=#q end
    table.sort(q,function(a,b)
        if a.score~=b.score then return a.score>b.score end
        return a.title<b.title
    end)
    return q,count,complete
end

local tips={
 SHAMAN={"For Elemental-style solo leveling, keep space between you and enemies when possible.",
 "Review new lightning, healing and totem abilities after leveling.",
 "Use a shield, heals or utility when a pull gets uncomfortable."},
 WARRIOR={"Weapon upgrades matter a lot while leveling.","Use defensive abilities when a pull gets risky.","Visit a trainer and review talents after levels."},
 PALADIN={"Review blessings, seals and new defensive tools.","Compare your weapon when damage slows down.","Your healing can shorten downtime."},
 HUNTER={"Check your pet's health and utility.","Keep room to fight at range.","Restock, repair and clear bags between longer trips."},
 MAGE={"Use range and crowd control to make pulls safer.","Plan around mana recovery.","Review new spells and talents after levels."},
 PRIEST={"Use your defensive toolkit before hard pulls.","Balance mana and downtime.","Check new spells when you gain levels."},
 ROGUE={"Start fights deliberately; keep weapons upgraded.","Control and escape tools can save a bad pull.","Review talents after leveling."},
 WARLOCK={"Look after your demon while questing.","Use control and damage-over-time spells carefully.","Review new spells and talents as they unlock."},
 DRUID={"Try the strengths of your forms.","Your heals and utility can rescue a hard pull.","Keep talents and abilities current."},
}
local function professionGoldAdvice(s)
    local herbs,ore,skin,alchemy=false,false,false,false
    for _,p in ipairs(s.professions.primary) do
        local name=string.lower(p.name)
        if string.find(name,"herb",1,true) then herbs=true end
        if string.find(name,"mining",1,true) then ore=true end
        if string.find(name,"skin",1,true) then skin=true end
        if string.find(name,"alchem",1,true) then alchemy=true end
    end
    if s.bagFree and s.bagFree<=4 then
        return "Vendor low-value loot and repair before another farming loop.","INVENTORY"
    end
    if herbs then
        return "Gather herbs along your quest route. Keep useful crafting herbs; sell spare stacks after checking prices.","HERBALISM"
    elseif ore then
        return "Mine reachable nodes while questing. Ore and stone can help earn gold or train professions.","MINING"
    elseif skin then
        return "Skin eligible enemies you already defeat. Avoid detours that slow your leveling.","SKINNING"
    elseif alchemy then
        return "Use gathered materials to level Alchemy; compare reagent costs before selling potions.","ALCHEMY"
    end
    return "Finish quests, loot useful drops, and vendor unwanted gray items. Check prices before selling valuables.","QUEST GOLD"
end
function FF:CollectSnapshot()
    local level=num(safeCall(UnitLevel,"player"),1)
    local name,tag=safeCall(UnitClass,"player")
    local xp,maximum=num(safeCall(UnitXP,"player"),0),num(safeCall(UnitXPMax,"player"),0)
    local free,total=self:ReadBags()
    local quests,count,completed=self:ReadQuests(level)
    local professions=self:ReadProfessions()
    local elapsed=math.max(0,(GetTime and GetTime() or 0)-num(self.session.start,0))
    local money=num(safeCall(GetMoney),0)
    local s={level=level,className=name or "Adventurer",classTag=tag or "",zone=safeCall(GetZoneText) or "Unknown area",
        xp=xp,xpMax=maximum,xpPercent=maximum>0 and clamp(xp/maximum*100,0,100) or nil,
        bagFree=free,bagTotal=total,durability=self:ReadDurability(),
        quests=quests,questCount=count,questComplete=completed,professions=professions,
        money=money,elapsed=elapsed,session=self.session,
        levelsGained=math.max(0,level-(self.session.initialLevel or self.session.level)),tips=tips[tag] or {"Check your spellbook after every level.",
        "Keep your gear repaired.","Quest and gather at a comfortable pace."}}
    s.goldTip,s.goldCategory=professionGoldAdvice(s)
    local found=false
    for _,p in ipairs(professions.primary) do
        if p.cap>0 and p.skill>=p.cap-5 then
            s.skillTip=p.name.." is "..p.skill.."/"..p.cap..". Ask a trainer about the next rank."
            found=true;break
        end
    end
    if not found then
        local first=professions.primary[1]
        s.skillTip=first and ("Level "..first.name.." while questing: "..first.skill.."/"..(first.cap>0 and first.cap or "?")..".")
            or "Consider learning a gathering profession for useful materials and extra income."
    end
    return s
end

local function targetQuest(s,c)
    local pinned,skip=nil,c.skippedQuestID
    if c.manualQuestID and c.manualQuestID>0 then
        for _,q in ipairs(s.quests) do if q.id==c.manualQuestID then pinned=q;break end end
        if not pinned then c.manualQuestID=0 end
    end
    if pinned then return pinned end
    local best=nil
    for _,q in ipairs(s.quests) do if q.id~=skip then best=q;break end end
    best=best or s.quests[1]
    -- Small distance/score changes should not make the recommendation bounce
    -- between nearby quests and take the native focus away every few seconds.
    if best and FF.stableQuestID and FF.stableQuestID~=skip then
        for _,q in ipairs(s.quests) do
            if q.id==FF.stableQuestID and q.score>=best.score-22 then return q end
        end
    end
    return best
end
function FF:ChoosePlan(s)
    local quest=targetQuest(s,self.char)
    self.stableQuestID=quest and quest.id or nil
    local action={quest=quest,category="AUTO GUIDE",title="Find a nearby quest",detail="Look for a nearby quest giver (!) in your current area.",where="",goldTip=s.goldTip,goldCategory=s.goldCategory}
    if quest then
        action.category=quest.done and "READY TO TURN IN" or "QUESTING NEXT"
        action.title=quest.title
        action.detail=quest.done and "Objectives complete - find the quest giver to collect your reward."
            or (quest.firstObjective or "Follow the objectives in your quest log.")
        if quest.waypoint then
            if quest.waypoint.text and quest.waypoint.text~="" then action.where=quest.waypoint.text end
            if quest.waypoint.id then
                local coords=string.format("%.1f, %.1f",quest.waypoint.x*100,quest.waypoint.y*100)
                local named=quest.waypoint.mapName or s.zone
                local loc=named.." ("..coords..")"
                action.where=(action.where~="" and (action.where.."  |  ") or "Waypoint: ")..loc
            end
        else
            if quest.questArea and quest.questArea~="" then
                action.where="Quest-log area: "..quest.questArea.." (not an exact NPC pin)"
            else action.where="Check your quest map for the objective location" end
        end
    elseif s.questCount==0 then
        action.detail="No quests in the log. Visit a nearby quest giver or explore an appropriate-level zone."
        action.where="Talk to quest givers marked with ! on your map."
    end
    -- Progress hints are shown separately from the quest name, not masquerading
    -- as verified quest coordinates.
    if quest and not quest.done and #quest.objectives>0 then
        for _,objective in ipairs(quest.objectives) do
            if not objective.done and objective.required>0 then
                action.progress=math.min(objective.current,objective.required).."/"..objective.required
                break
            end
        end
    end
    if s.bagFree and s.bagFree<=2 then
        action.title="Clear your bags before the next objective"
        action.detail="Only "..s.bagFree.." free slots. Vendor low-value items, then resume your quest."
        action.category="QUICK FIX"
    elseif s.durability and s.durability<=20 then
        action.title="Repair your equipment soon"
        action.detail="Gear durability is only "..s.durability.."%. Find a repair vendor before a longer outing."
        action.category="QUICK FIX"
    elseif self.char.priority=="gold" and s.bagFree and s.bagFree>3 then
        action.category="GOLD + LEVELING"
        if quest then action.detail=action.detail.." Gather useful materials along the way." end
    end
    if self.char.priority=="level" then action.goldTip="Optional gold: "..s.goldTip end
    return action
end

function FF:TrackQuest()
    local id=self.plan and self.plan.quest and self.plan.quest.id
    if not id then self:Message("No quest selected yet.");return end
    if C_QuestLog and C_QuestLog.AddQuestWatch then
        local ok=pcall(C_QuestLog.AddQuestWatch,id)
        if ok then self:Message("Quest added to tracker. If it is already tracked, no change was needed.");return end
    end
    self:Message("The quest tracker API is unavailable; open your quest log (L) and track the quest there.")
end
function FF:MapAction()
    local wp=self.plan and self.plan.quest and self.plan.quest.waypoint
    if wp and wp.id and C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates then
        local ok,err=pcall(function()
            local point=UiMapPoint.CreateFromCoordinates(wp.id,wp.x,wp.y)
            C_Map.SetUserWaypoint(point)
            if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                pcall(C_SuperTrack.SetSuperTrackedUserWaypoint,true)
            end
        end)
        if ok then self:Message("Map pin set using the game's quest waypoint.");return end
        self.lastError=tostring(err)
    end
    if ToggleWorldMap then
        local ok=pcall(ToggleWorldMap)
        if ok then self:Message("Opened your map. The client didn't supply a usable pin for this quest.");return end
    end
    self:Message("Press M to open your map. No compatible waypoint API was available.")
end
