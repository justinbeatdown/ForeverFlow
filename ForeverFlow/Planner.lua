-- ForeverFlow 0.5.5 beta 5: deterministic, local-only next-action planner.
-- This is an ADVISOR. It never moves the character, auto-accepts quests or asserts
-- unverified travel times, experience rewards, or quest-chain eligibility.
local _, FF = ...
local function short(s,n)
    s=tostring(s or "")
    return #s>n and s:sub(1,n-3).."..." or s
end
local function questProgress(q)
    local current,total=0,0
    for _,o in ipairs(q.objectives or {}) do
        local required=tonumber(o.required) or 0
        local done=tonumber(o.current) or 0
        if required>0 then current=current+math.min(required,math.max(0,done)); total=total+required end
    end
    return current,total
end
function FF:BuildRouteAdvice(s,plan)
    local advice={kind="EXPLORE",title="Find your next quest",reason="Check your quest log or speak to a nearby quest giver.",next="Open Discover Quests for reported quest pickups.",where="",quest=plan and plan.quest,confidence="GENERAL TIP"}
    if not s or not self.char then return advice end
    local q=plan and plan.quest
    local list=nil
    if self.FindDiscoveries then
        local ok,found=pcall(self.FindDiscoveries,self,s,false)
        if ok and type(found)=="table" then list=found end
    end
    local localPick,travelPick,savedPick=nil,nil,nil
    for _,candidate in ipairs(list or {}) do
        if candidate.flags~="elite" and (not candidate.level or candidate.level<=s.level+2) then
            if candidate.saved and not savedPick then savedPick=candidate end
            if candidate.nearby and not localPick then localPick=candidate end
            if not candidate.nearby and not travelPick then travelPick=candidate end
        end
    end
    -- Prefer already accepted, same-zone quests over unverified pickups.
    -- A completed quest is a useful follow-up, but only if we actually know
    -- its status from the live log. Never assert a turn-in NPC coordinate.
    local activeFollowup=nil
    for _,candidate in ipairs(s.quests or {}) do
        if candidate.id and (not q or candidate.id~=q.id) and
            (candidate.zoneMatch or candidate.near) and
            (not candidate.level or candidate.level<=s.level+3) then
            if not activeFollowup or (candidate.done and not activeFollowup.done) then
                activeFollowup=candidate
            end
        end
    end
    local later=savedPick or localPick or travelPick
    if activeFollowup then
        advice.next="Afterwards: "..(activeFollowup.done and "turn in " or "continue ")..short(activeFollowup.title,45).." (already in your quest log)."
    elseif later then
        advice.next="Afterwards: "..(later.saved and "your saved pickup " or "check ")..short(later.title,31).." ("..(later.nearby and "local" or "travel to "..tostring(later.mapName or "another zone")).."; pickup unverified)."
    else
        advice.next="Afterwards: open Discover Quests to review reported quest pickups."
    end
    advice.pickup=later
    advice.activeFollowup=activeFollowup
    if q then
        local have,needed=questProgress(q)
        advice.kind=q.done and "TURN IN" or "FINISH CURRENT QUEST"
        advice.title=q.title
        advice.confidence="LIVE QUEST LOG"
        local localText=(q.zoneMatch and "In your current zone. " or q.near and "Nearby objective. " or "Already accepted. ")
        if q.done then
            advice.reason="Objectives complete. Turn in for the reward before detouring to another quest hub."
        elseif needed>0 then
            advice.reason=localText.."Objective progress "..have.."/"..needed.."; finish this route before a cross-zone trip."
        else
            advice.reason=localText.."Continue your current objective before starting a distant pickup chain."
        end
        advice.where=plan.where or ""
        if q.level and q.level>s.level+3 then
            advice.kind="CHECK DIFFICULTY"
            advice.reason="Quest level "..q.level.." is above your level "..s.level..". Consider a safer nearby quest if combat is difficult."
        end
    elseif localPick then
        advice.kind="LOCAL PICKUP TO CHECK"
        advice.title=localPick.title
        advice.reason="Reported pickup from "..tostring(localPick.npc or "a quest giver").." in your current zone. Check prerequisites with the NPC."
        advice.next="Use Discover Quests > MAP to inspect the reported pickup location."
        advice.confidence="UNVERIFIED PICKUP"
    elseif travelPick then
        advice.kind="TRAVEL PLAN TO CHECK"
        advice.title="Consider "..tostring(travelPick.mapName or "another zone")
        advice.reason="No suitable local pickup in the current catalog. This is a possible next hub, not a faster-route guarantee."
        advice.next="Review "..short(travelPick.title,38).." and its prerequisites in Discover Quests."
        advice.confidence="LIMITED CATALOG"
    end
    if s.bagFree and s.bagFree<=2 then
        advice.kind="BAGS NEARLY FULL"
        advice.title="Make room for quest rewards"
        advice.reason="Only "..s.bagFree.." free slots. Empty bags before gathering or continuing the route."
        advice.next=q and ("Then return to "..short(q.title,43)..".") or advice.next
        advice.confidence="LIVE CHARACTER STATE"
    elseif s.durability and s.durability<=20 then
        advice.kind="REPAIR SOON"
        advice.title="Repair before your next long outing"
        advice.reason="Your gear durability is "..math.floor(s.durability+0.5).."%. Find a repair vendor before risky pulls."
        advice.next=q and ("Then return to "..short(q.title,43)..".") or advice.next
        advice.confidence="LIVE CHARACTER STATE"
    end
    return advice
end
function FF:DescribeRoute()
    local a=self.routeAdvice
    if not a then self:Message("Route plan has not loaded. Open ForeverFlow first.");return end
    self:Message(a.kind..": "..a.title)
    self:Message(a.reason)
    self:Message(a.next)
    self:Message("Evidence: "..a.confidence..". Offline pickups and prerequisites are unverified.")
end
function FF:OpenRouteDiscovery()
    self.char.discoverView=true
    self.char.discoverPage=1
    if self.window then self.window:Show();self.char.visible=true end
    if self.ShowTab then self:ShowTab("leveling") end
    self:Refresh()
end
