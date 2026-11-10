-- ForeverFlow 0.5.6-beta1 / player-first HUD. UI and suggestions only: no movement, combat or selling automation.
local addonName, FF = ...
FF.version = "0.5.6-beta9"
FF.addon = addonName or "ForeverFlow"
FF.media = "Interface\\AddOns\\ForeverFlow\\Media\\"
FF.colors = {
    bg={0.10,0.075,0.052,0.98}, panel={0.14,0.105,0.070,1},
    panel2={0.19,0.14,0.09,1}, button={0.22,0.16,0.10,1},
    border={0.37,0.28,0.16,1}, gold={1.0,0.75,0.26,1},
    white={0.99,0.95,0.84,1}, muted={0.77,0.72,0.59,1},
    green={0.43,0.85,0.48,1}, orange={1,0.55,0.22,1},
    blue={0.58,0.78,1,1}
}
local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end
local function numberOr(x,def) return type(x)=="number" and x or def end
FF.Trim = trim
function FF:Message(s) print("|cffffbf6bForeverFlow|r "..tostring(s)) end

function FF:InitDB()
    if type(ForeverFlowDB)~="table" then ForeverFlowDB={} end
    if type(ForeverFlowCharDB)~="table" then ForeverFlowCharDB={} end
    self.db, self.char = ForeverFlowDB, ForeverFlowCharDB
    local db, c=self.db,self.char
    if db.mode~="advanced" then db.mode="simple" end
    if db.quiet==nil then db.quiet=db.reminders==false end
    if c.priority~="level" and c.priority~="gold" and c.priority~="balanced" then c.priority="balanced" end
    if c.guideVisible==nil then c.guideVisible=true end
    if c.guideCollapsed==nil then c.guideCollapsed=false end
    -- A genuinely small always-on HUD is the default for this HUD redesign.
    if not c.hudRibbonUpgrade then c.hudMinimal=true; c.hudRibbonUpgrade=true end
    if c.autoFollow==nil then c.autoFollow=true end
    if c.showPace==nil then c.showPace=true end
    if c.hudMinimal==nil then c.hudMinimal=false end
    if not c.liveGuideUpgrade then
        -- On first install/upgrade, make the small Live Guide the default experience.
        c.visible=false; c.liveGuideUpgrade=true
    elseif c.visible==nil then c.visible=false end
    if c.hideMinimap==nil then c.hideMinimap=false end
    if c.locked==nil then c.locked=false end
    if c.guideLocked==nil then c.guideLocked=false end
    c.guideScale=math.max(.8,math.min(1.2,numberOr(c.guideScale,1)))
    c.posX=numberOr(c.posX,0); c.posY=numberOr(c.posY,0)
    c.guideX=numberOr(c.guideX,-620); c.guideY=numberOr(c.guideY,170)
    c.minimapAngle=numberOr(c.minimapAngle,42)
    c.goldTarget=math.max(0,math.floor(numberOr(c.goldTarget,0))) -- 0 = automatic
    c.gatherTarget=math.max(1,math.floor(numberOr(c.gatherTarget,20)))
    c.manualQuestID=numberOr(c.manualQuestID,0)
    c.skippedQuestID=numberOr(c.skippedQuestID,0)
    if type(c.trainingChecks)~="table" then c.trainingChecks={false,false,false} end
    c.trainingLevel=numberOr(c.trainingLevel,0)
    if type(c.lifetime)~="table" then c.lifetime={} end
    c.lifetime.quests=numberOr(c.lifetime.quests,0)
    c.lifetime.materials=numberOr(c.lifetime.materials,0)
    c.lifetime.earned=numberOr(c.lifetime.earned,0)
    c.lifetime.sessions=numberOr(c.lifetime.sessions,0)
    if c.discoverView==nil then c.discoverView=false end
    if c.discoverBrowseAll==nil then c.discoverBrowseAll=false end
    c.discoverPage=math.max(1,math.floor(numberOr(c.discoverPage,1)))
    if type(c.savedDiscoveries)~="table" then c.savedDiscoveries={} end
    if type(c.skippedDiscoveries)~="table" then c.skippedDiscoveries={} end
    if type(c.seenDiscoveries)~="table" then c.seenDiscoveries={} end
    c.recipeFlowPage=math.max(1,math.floor(numberOr(c.recipeFlowPage,1)))
    c.recipeFlowSelected=math.max(1,math.floor(numberOr(c.recipeFlowSelected,1)))
    if c.compact==nil then c.compact=false end -- migration from v0.2
end

function FF:StartSession()
    local s={start=(GetTime and GetTime() or 0), money=(GetMoney and GetMoney() or 0),
        level=(UnitLevel and UnitLevel("player") or 1),
        initialLevel=(UnitLevel and UnitLevel("player") or 1), xp=(UnitXP and UnitXP("player") or 0),
        xpMax=(UnitXPMax and UnitXPMax("player") or 0),
        earned=0, spent=0, xpEarned=0, materials=0, questTurns=0, inventoryBaseline=nil}
    self.session=s
    self.char.lifetime.sessions=self.char.lifetime.sessions+1
    if self.char.trainingLevel~=s.level then
        self.char.trainingChecks={false,false,false}; self.char.trainingLevel=s.level
    end
    self:RecordInventory(true)
    self.lastFollowSignature=nil
    self.autoFollowStatus="WAITING"
end

function FF:RecordMoneyAndXP()
    if not self.session or not self.session.start then return end
    local s=self.session
    if GetMoney then
        local ok,value=pcall(GetMoney)
        if ok and type(value)=="number" then
            if type(s.money)=="number" then
                local diff=value-s.money
                if diff>0 then
                    s.earned=s.earned+diff
                    self.char.lifetime.earned=self.char.lifetime.earned+diff
                elseif diff<0 then s.spent=s.spent-diff end
            end
            s.money=value
        end
    end
    if UnitLevel and UnitXP and UnitXPMax then
        local level=UnitLevel("player"); local xp=UnitXP("player"); local maximum=UnitXPMax("player")
        if type(level)=="number" and type(xp)=="number" then
            if level==s.level and xp>s.xp then s.xpEarned=s.xpEarned+xp-s.xp end
            if level>s.level then
                local carry=(type(s.xpMax)=="number" and s.xpMax>0) and math.max(0,s.xpMax-s.xp) or 0
                s.xpEarned=s.xpEarned+carry+xp
            end
            s.level=level; s.xp=xp; s.xpMax=maximum
        end
    end
end

function FF:EnsureReady()
    if not self.char then self:InitDB() end
    if not self.session or not self.session.start then self:StartSession() end
    if not self.window or not self.guide or not self.views then
        if self.window then self.window:Hide() end
        if self.guide then self.guide:Hide() end
        self.window=nil; self.guide=nil; self.views=nil; self.pages=nil; self.minimap=nil
        if not self.CreateUI then error("UI.lua missing from addon; reinstall the complete ForeverFlow folder") end
        self:CreateUI()
    end
    self:Refresh()
end

function FF:TryInitialize(context)
    local ok,err=pcall(function() self:EnsureReady() end)
    if not ok then
        self.lastError=tostring(err)
        self:Message("Setup error ("..tostring(context).."): "..self.lastError)
        self:Message("Try /flow debug, then enable /console scriptErrors 1 if needed.")
        return false
    end
    self.lastError=nil
    return true
end

function FF:Refresh()
    if not self.char or not self.window then return end
    if InCombatLockdown and InCombatLockdown() then return end
    if not (self.window:IsShown() or (self.guide and self.guide:IsShown())) then return end
    local ok, snapshot = pcall(self.CollectSnapshot, self)
    if not ok then self.lastError=tostring(snapshot); return end
    self.snapshot=snapshot
    local okPlan,plan=pcall(self.ChoosePlan,self,snapshot)
    if not okPlan then self.lastError=tostring(plan); return end
    self.plan=plan
    if self.BuildRouteAdvice then
        local good,advice=pcall(self.BuildRouteAdvice,self,snapshot,plan)
        if good then self.routeAdvice=advice else self.lastRouteError=tostring(advice) end
    end
    -- This runs only when the recommended quest or its objective changes; it is
    -- NOT a 6-second reassertion that would fight a user's manual map choice.
    if self.SyncRecommendedQuest then self:SyncRecommendedQuest(plan) end
    local okUI,err=pcall(self.UpdateUI,self)
    if not okUI then self.lastError=tostring(err) end
end

function FF:Toggle()
    if not self.window then return end
    self.char.visible=not self.window:IsShown()
    self.window:SetShown(self.char.visible)
    self:Refresh()
end
function FF:SetGuideScale(scale)
    if not self.char then return end
    scale=tonumber(scale)
    if not scale then self:Message("Use /flow scale 0.8 through 1.2");return end
    self.char.guideScale=math.max(.8,math.min(1.2,scale))
    if self.guide then self.guide:SetScale(self.char.guideScale) end
    self:Message("Guide scale: "..math.floor(self.char.guideScale*100+.5).."%")
    self:Refresh()
end
function FF:ToggleGuide()
    if not self.guide then return end
    self.char.guideVisible=not self.guide:IsShown()
    self.guide:SetShown(self.char.guideVisible)
    self:Refresh()
end
function FF:SetPriority(priority)
    if priority~="gold" and priority~="level" then priority="balanced" end
    self.char.priority=priority; self.char.skippedQuestID=0
    self:Refresh()
end
function FF:PinCurrentQuest()
    local quest=self.plan and self.plan.quest
    if not quest or type(quest.id)~="number" then
        self:Message("No suggested quest available to pin.")
        return
    end
    self.char.manualQuestID=quest.id
    self.char.skippedQuestID=0
    self:Message("Pinned: "..tostring(quest.title)..". Use /flow unpin to resume automatic selection.")
    self:Refresh()
end
function FF:UnpinCurrentQuest()
    self.char.manualQuestID=0
    self.char.skippedQuestID=0
    self.stableQuestID=nil
    self:Message("Automatic quest selection restored.")
    self:Refresh()
end
function FF:SessionSummary()
    local snapshot=self.snapshot
    if not snapshot or not snapshot.session then
        self:Message("Session data unavailable.")
        return
    end
    local session=snapshot.session
    local pace=self:LevelingPace(snapshot)
    self:Message("Session: "..math.floor((snapshot.elapsed or 0)/60).." min | XP +"..math.floor(session.xpEarned or 0).." | Quests "..tostring(session.questTurns or 0))
    self:Message("XP/hr: "..(pace.reliable and tostring(pace.rate) or "warming up").." | Level ETA: "..pace.eta)
    self:Message("Net gold: "..self:MoneyText((session.earned or 0)-(session.spent or 0),true).." | Materials +"..tostring(session.materials or 0))
end
function FF:SkipQuest()
    if self.plan and self.plan.quest and self.plan.quest.id then
        self.char.skippedQuestID=self.plan.quest.id
        self.char.manualQuestID=0
    else
        self.char.skippedQuestID=0
    end
    self:Refresh()
end
function FF:ChooseQuest(id)
    self.char.manualQuestID=type(id)=="number" and id or 0
    self.char.skippedQuestID=0
    self:Refresh()
end
function FF:SavePosition(frame,kind)
    if not frame then return end
    local x,y=frame:GetCenter()
    local cx,cy=UIParent:GetCenter()
    if not x or not y or not cx or not cy then return end
    if kind=="guide" then self.char.guideX=x-cx; self.char.guideY=y-cy
    else self.char.posX=x-cx; self.char.posY=y-cy end
end
-- Follow only when the recommendation changes, or the player explicitly
-- requests it. Never move, cast, interact or auto-complete quests.
function FF:SetAutoFollow(enabled)
    self.char.autoFollow=not not enabled
    self.lastFollowSignature=nil
    self.autoFollowStatus=self.char.autoFollow and "WAITING" or "OFF"
    self:Refresh()
end

function FF:QuestSignature(plan)
    local q=plan and plan.quest
    if not q or type(q.id)~="number" then return "no-quest" end
    local wp=q.waypoint
    local position=(wp and type(wp.id)=="number" and type(wp.x)=="number" and type(wp.y)=="number")
        and (":"..wp.id..":"..string.format("%.4f:%.4f",wp.x,wp.y)) or ""
    return tostring(q.id)..":"..tostring(q.done)..position
end

local function safeAPI(fn,...)
    if type(fn)~="function" then return false,nil end
    local ok,result=pcall(fn,...)
    return ok,result
end

function FF:SyncRecommendedQuest(plan,force)
    if not self.char or not self.char.autoFollow and not force then
        self.autoFollowStatus="OFF"
        return
    end
    local q=plan and plan.quest
    if not q or type(q.id)~="number" then
        self.autoFollowStatus="NO QUEST"
        self.lastFollowSignature="no-quest"
        return
    end
    local signature=self:QuestSignature(plan)
    if not force and signature==self.lastFollowSignature then return end
    -- Save the signature BEFORE changing watched/focused quest; Blizzard may
    -- fire QUEST_LOG_UPDATE synchronously. This prevents a refresh loop.
    self.lastFollowSignature=signature
    if InCombatLockdown and InCombatLockdown() then
        self.lastFollowSignature=nil -- retry after combat
        self.autoFollowStatus="AFTER COMBAT"
        return
    end
    local watchRequested=false
    if C_QuestLog and C_QuestLog.AddQuestWatch then
        local ok,result=safeAPI(C_QuestLog.AddQuestWatch,q.id)
        watchRequested=ok and result~=false
    end
    if C_QuestLog and C_QuestLog.SetSelectedQuest then
        safeAPI(C_QuestLog.SetSelectedQuest,q.id)
    end
    local focusRequested=false
    local focusConfirmed=false
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID then
        local ok,result=safeAPI(C_SuperTrack.SetSuperTrackedQuestID,q.id)
        focusRequested=ok and result~=false
        if focusRequested and C_SuperTrack.GetSuperTrackedQuestID then
            local readOK,current=safeAPI(C_SuperTrack.GetSuperTrackedQuestID)
            focusConfirmed=readOK and current==q.id
        end
    end
    local pinned=false
    local mapHint=q.waypoint
    if not focusRequested and mapHint and mapHint.source=="nativeQuest" then
        if mapHint.id and C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates then
            -- Never replace a user's pin. A compatible native client hint may be
            -- used only if the map is empty or still contains our prior pin.
            local existing=C_Map.GetUserWaypoint and select(2,safeAPI(C_Map.GetUserWaypoint)) or nil
            local canUpdate=not existing
            if existing and self.ownedWaypoint and type(existing)=="table" then
                local p=existing.position
                if type(p)=="table" and type(p.x)=="number" and type(p.y)=="number" then
                    canUpdate=existing.uiMapID==self.ownedWaypoint.id
                        and math.abs(p.x-self.ownedWaypoint.x)<.002
                        and math.abs(p.y-self.ownedWaypoint.y)<.002
                end
            end
            if canUpdate then
                local pointOK,point=safeAPI(UiMapPoint.CreateFromCoordinates,mapHint.id,mapHint.x,mapHint.y)
                if pointOK and point then
                    local setOK,didSet=safeAPI(C_Map.SetUserWaypoint,point)
                    pinned=setOK and didSet~=false
                    if pinned then
                        self.ownedWaypoint={id=mapHint.id,x=mapHint.x,y=mapHint.y}
                        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                            safeAPI(C_SuperTrack.SetSuperTrackedUserWaypoint,true)
                        end
                    end
                end
            end
        end
    end
    self.autoFollowStatus=focusConfirmed and "QUEST FOCUSED"
        or focusRequested and "FOCUS REQUESTED"
        or pinned and "HINT PIN SET"
        or watchRequested and "WATCH REQUESTED" or "MAP NEEDED"
    self.autoFollowDetail=mapHint and (mapHint.source=="mapPOI" and "Map POI (not verified objective)"
        or "Native quest route hint (not verified objective)") or "No compatible quest coordinates"

end

function FF:Debug()
    self:Message("v"..self.version.." | live guide: "..tostring(self.guide~=nil).." | dashboard: "..tostring(self.window~=nil))
    self:Message("Quests: "..tostring(self.snapshot and self.snapshot.questCount or "unknown").." | priority: "..tostring(self.char and self.char.priority))
    self:Message("Minimap: "..tostring(self.minimap~=nil).." | last error: "..tostring(self.lastError or "none"))
    self:Message("Auto-follow: "..tostring(self.char and self.char.autoFollow).." | "..tostring(self.autoFollowStatus or "waiting").." | quest "..tostring(self.plan and self.plan.quest and self.plan.quest.id))
    self:Message("Destination: "..tostring(self.autoFollowDetail or "unknown").." | "..tostring(self.plan and self.plan.destinationQuality or "no classification"))
end

SLASH_FOREVERFLOW1="/flow"
SLASH_FOREVERFLOW2="/foreverflow"
SlashCmdList.FOREVERFLOW=function(input)
    local cmd,arg=trim(input):match("^(%S*)%s*(.-)%s*$")
    cmd=string.lower(cmd or "")
    if not FF:TryInitialize("slash") then return end
    local tabs={today=true,leveling=true,gold=true,skills=true,character=true,settings=true}
    if cmd=="" then FF:Toggle()
    elseif cmd=="guide" then FF:ToggleGuide()
    elseif cmd=="scale" then FF:SetGuideScale(arg)
    elseif cmd=="hud" then
        if arg=="tiny" or arg=="min" then FF.char.hudMinimal=true
        elseif arg=="normal" or arg=="full" then FF.char.hudMinimal=false
        else FF.char.hudMinimal=not FF.char.hudMinimal end
        FF:SetGuideCollapsed(FF.char.guideCollapsed);FF:Refresh()
    elseif tabs[cmd] then FF:ShowTab(cmd); FF.window:Show(); FF.char.visible=true; FF:Refresh()
    elseif cmd=="level" or cmd=="gold" or cmd=="balanced" then FF:SetPriority(cmd)
    elseif cmd=="priority" then FF:SetPriority(arg)
    elseif cmd=="auto" or cmd=="unpin" then FF:UnpinCurrentQuest()
    elseif cmd=="pin" then FF:PinCurrentQuest()
    elseif cmd=="route" or cmd=="plan" then FF:DescribeRoute()
    elseif cmd=="routepickups" then FF:OpenRouteDiscovery()
    elseif cmd=="discover" then
        FF.char.discoverView=true
        FF.window:Show();FF.char.visible=true;FF:ShowTab("leveling")
        if FF.snapshot then FF:FindDiscoveries(FF.snapshot,true) end
        FF:Refresh()
    elseif cmd=="discoverzones" then FF.char.discoverBrowseAll=not FF.char.discoverBrowseAll;FF:Refresh()
    elseif cmd=="discoverreset" then FF:ResetSkippedDiscoveries()
    elseif cmd=="stats" or cmd=="session" then FF:SessionSummary()
    elseif cmd=="pace" then
        FF.char.showPace=not FF.char.showPace
        FF:Message("Leveling pace display: "..(FF.char.showPace and "ON" or "OFF"))
        FF:Refresh()
    elseif cmd=="next" then FF:SkipQuest()
    elseif cmd=="map" then FF:MapAction()
    elseif cmd=="track" then FF:TrackQuest()
    elseif cmd=="follow" then
        if arg=="on" then FF:SetAutoFollow(true)
        elseif arg=="off" then FF:SetAutoFollow(false)
        else FF:SetAutoFollow(not FF.char.autoFollow) end
        FF:Message("Automatic quest following: "..(FF.char.autoFollow and "ON" or "OFF"))
    elseif cmd=="focus" then FF:SyncRecommendedQuest(FF.plan,true);FF:Refresh()
    elseif cmd=="debug" or cmd=="status" then FF:Debug()
    elseif cmd=="goldstatus" then
        local snapshot=FF.snapshot
        FF:Message(FF:GoldHudSummary(snapshot))
        if snapshot and snapshot.session then
            FF:Message("Earned "..FF:MoneyText(snapshot.session.earned or 0).." | spent "..FF:MoneyText(snapshot.session.spent or 0).." | materials +"..tostring(snapshot.session.materials or 0).." (includes transfers)")
        end
    elseif cmd=="where" then
        local plan=FF.plan
        FF:Message(plan and (plan.title.." | "..(plan.where or "No location")) or "No active quest recommendation")
        FF:Message("Coordinates are quest route/map hints, not verified target locations.")
    elseif cmd=="why" then
        local q=FF.plan and FF.plan.quest
        if q then
            FF:Message("Selected "..q.title.." | level "..tostring(q.level).." | rank "..string.format("%.0f",q.score or 0))
            FF:Message("Factors: "..(q.zoneMatch and "same quest-log zone; " or "")..(q.near and "nearby; " or "")..(q.done and "ready to turn in; " or "active objective; ").."sticky recommendation avoids unnecessary bouncing.")
        else FF:Message("No quest recommendation is available.") end
    elseif cmd=="resetpos" then
        FF.char.posX=0; FF.char.posY=0; FF.char.guideX=-620; FF.char.guideY=170
        FF.window:ClearAllPoints(); FF.window:SetPoint("CENTER", UIParent,"CENTER",0,0)
        FF.guide:ClearAllPoints(); FF.guide:SetPoint("CENTER",UIParent,"CENTER",-620,170)
        FF:Message("Window positions reset.")
    elseif cmd=="help" then
        FF:Message("/flow dashboard  |  /flow guide toggle HUD  |  /flow hud tiny|normal  |  /flow scale 0.8-1.2")
        FF:Message("/flow priority level|gold|balanced  |  /flow follow on|off  |  /flow focus")
        FF:Message("/flow map  |  /flow track  |  /flow pin  |  /flow unpin  |  /flow next")
        FF:Message("/flow stats  |  /flow pace (toggle XP estimate)  |  /flow hud tiny|normal")
        FF:Message("/flow route (explain the next best action) | /flow routepickups | /flow discover")
        FF:Message("/flow discoverreset (revisit skipped quests)")
        FF:Message("/flow leveling|skills|character|settings  |  /flow where  |  /flow why  |  /flow goldstatus  |  /flow status  |  /flow resetpos")
    else FF:Message("Unknown command. Type /flow help.") end
end

local events=CreateFrame("Frame")
for _,event in ipairs({"ADDON_LOADED","PLAYER_LOGIN"}) do events:RegisterEvent(event) end
local optional={"PLAYER_LEVEL_UP","PLAYER_XP_UPDATE","QUEST_LOG_UPDATE","QUEST_ACCEPTED",
 "QUEST_REMOVED","QUEST_TURNED_IN","BAG_UPDATE_DELAYED","PLAYER_MONEY",
 "UPDATE_INVENTORY_DURABILITY","PLAYER_EQUIPMENT_CHANGED","SKILL_LINES_CHANGED",
 "ZONE_CHANGED","ZONE_CHANGED_NEW_AREA","PLAYER_REGEN_ENABLED","SPELLS_CHANGED",
 "GOSSIP_SHOW","QUEST_GREETING","TRADE_SKILL_SHOW","TRADE_SKILL_UPDATE","TRADE_SKILL_LIST_UPDATE","TRADE_SKILL_NAME_UPDATE",
 "TRADE_SKILL_DETAILS_UPDATE","TRADE_SKILL_DATA_SOURCE_CHANGED","NEW_RECIPE_LEARNED","CRAFT_SHOW","CRAFT_UPDATE"}
FF.skippedEvents={}
for _,event in ipairs(optional) do
    if not pcall(events.RegisterEvent,events,event) then
        FF.skippedEvents[#FF.skippedEvents+1]=event
    end
end
local timer=0
events:SetScript("OnEvent",function(_,event,arg1)
    if event=="ADDON_LOADED" then
        if arg1==addonName then
            local ok,err=pcall(function() FF:InitDB() end)
            if not ok then FF:Message("Settings problem: "..tostring(err)) end
        end
        return
    end
    if event=="PLAYER_LOGIN" then
        if FF:TryInitialize("login") then
            FF:Message("Live Guide active. /flow = dashboard; /flow guide = floating guide.")
        end
        return
    end
    if not FF.char or not FF.session then return end
    if event=="TRADE_SKILL_SHOW" or event=="TRADE_SKILL_UPDATE" then
        if FF.CaptureRecipeFlow then FF:CaptureRecipeFlow("trade") end
    elseif event=="CRAFT_SHOW" or event=="CRAFT_UPDATE" then
        if FF.CaptureRecipeFlow then FF:CaptureRecipeFlow("craft") end
    end
    if event=="TRADE_SKILL_LIST_UPDATE" or event=="TRADE_SKILL_NAME_UPDATE" or
       event=="TRADE_SKILL_DETAILS_UPDATE" or event=="TRADE_SKILL_DATA_SOURCE_CHANGED" or
       event=="NEW_RECIPE_LEARNED" then
        if FF.TryCaptureRecipes then FF:TryCaptureRecipes() end
    end
    if event=="TRADE_SKILL_SHOW" or event=="CRAFT_SHOW" then
        -- The Blizzard pane commonly fires SHOW before recipes are populated.
        -- A second scan runs after its list update without user interaction.
        if C_Timer and C_Timer.After then
            C_Timer.After(.45,function()
                if FF.char and FF.TryCaptureRecipes then FF:TryCaptureRecipes() end
            end)
        end
    end
    if event=="GOSSIP_SHOW" or event=="QUEST_GREETING" then
        if FF.RememberNearbyQuests then FF:RememberNearbyQuests() end
    end
    if event=="QUEST_TURNED_IN" then
        FF.session.questTurns=FF.session.questTurns+1
        FF.char.lifetime.quests=FF.char.lifetime.quests+1
        FF.char.skippedQuestID=0
        if arg1==FF.char.manualQuestID then FF.char.manualQuestID=0 end
    elseif event=="QUEST_REMOVED" then
        if arg1==FF.char.manualQuestID then FF.char.manualQuestID=0 end
    elseif event=="PLAYER_LEVEL_UP" then
        FF.char.trainingChecks={false,false,false}
        FF.char.trainingLevel=tonumber(arg1) or (UnitLevel and UnitLevel("player") or 1)
        if not FF.db.quiet then FF:Message("Level up! ForeverFlow updated your plan.") end
    elseif event=="BAG_UPDATE_DELAYED" then
        FF:RecordInventory(false)
        if FF.RecipeFlowRefreshInventory then FF:RecipeFlowRefreshInventory() end
    end
    FF:RecordMoneyAndXP()
    FF:Refresh()
end)
events:SetScript("OnUpdate",function(_,delta)
    if not FF.window or not FF.guide then return end
    if not (FF.window:IsShown() or FF.guide:IsShown()) then return end
    if FF.views and FF.views.skills and FF.pages and FF.pages.skills and FF.pages.skills:IsShown() then
        FF.recipePollElapsed=(FF.recipePollElapsed or 0)+delta
        if FF.recipePollElapsed>=3 and not (FF.recipeFlow and FF.recipeFlow.count>0) then
            FF.recipePollElapsed=0
            if FF.TryCaptureRecipes then FF:TryCaptureRecipes() end
        end
    end
    timer=timer+delta
    if timer<6 then return end
    timer=0
    FF:RecordMoneyAndXP()
    FF:Refresh()
end)