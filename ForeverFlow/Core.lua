-- ForeverFlow 0.5.1 / player-first HUD. UI and suggestions only: no movement, combat or selling automation.
local addonName, FF = ...
FF.version = "0.5.1"
FF.addon = addonName or "ForeverFlow"
FF.media = "Interface\\AddOns\\ForeverFlow\\Media\\"
FF.colors = {
    bg={0.035,0.045,0.065,0.98}, panel={0.085,0.101,0.133,1},
    panel2={0.115,0.135,0.170,1}, button={0.135,0.160,0.202,1},
    border={0.27,0.30,0.36,1}, gold={1.0,0.73,0.30,1},
    white={0.97,0.97,0.96,1}, muted={0.69,0.74,0.80,1},
    green={0.43,0.87,0.60,1}, orange={1,0.53,0.28,1},
    blue={0.52,0.76,1,1}
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
    if c.hudMinimal==nil then c.hudMinimal=false end
    if not c.liveGuideUpgrade then
        -- On first install/upgrade, make the small Live Guide the default experience.
        c.visible=false; c.liveGuideUpgrade=true
    elseif c.visible==nil then c.visible=false end
    if c.hideMinimap==nil then c.hideMinimap=false end
    if c.locked==nil then c.locked=false end
    if c.guideLocked==nil then c.guideLocked=false end
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
    local watched=false
    if C_QuestLog and C_QuestLog.AddQuestWatch then
        watched=safeAPI(C_QuestLog.AddQuestWatch,q.id)
    end
    if C_QuestLog and C_QuestLog.SetSelectedQuest then
        safeAPI(C_QuestLog.SetSelectedQuest,q.id)
    end
    local focused=false
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID then
        -- Prefer native quest focus to a user waypoint. It supports Blizzard's
        -- objective arrow and can follow progress without stomping custom pins.
        focused=safeAPI(C_SuperTrack.SetSuperTrackedQuestID,q.id)
        if focused and C_SuperTrack.GetSuperTrackedQuestID then
            local ok,current=safeAPI(C_SuperTrack.GetSuperTrackedQuestID)
            if ok and type(current)=="number" and current~=q.id then focused=false end
        end
    end
    local pinned=false
    if not focused then
        local wp=q.waypoint
        if wp and type(wp.id)=="number" and type(wp.x)=="number" and type(wp.y)=="number"
            and C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates then
            -- Do not replace someone else's map pin. We only own our last pin.
            local existing=C_Map.GetUserWaypoint and select(2,safeAPI(C_Map.GetUserWaypoint)) or nil
            -- A previous FF pin is only ours while the player has not moved it.
            local canUpdate=(not existing)
            if existing and self.ownedWaypoint and type(existing)=="table" then
                local p=existing.position
                if type(p)=="table" then
                    local x,y=p.x,p.y
                    if type(x)=="number" and type(y)=="number" then
                        canUpdate=existing.uiMapID==self.ownedWaypoint.id
                            and math.abs(x-self.ownedWaypoint.x)<.002
                            and math.abs(y-self.ownedWaypoint.y)<.002
                    end
                end
            end
            if canUpdate then
                local pointOK,point=safeAPI(UiMapPoint.CreateFromCoordinates,wp.id,wp.x,wp.y)
                if pointOK and point then
                    local setOK,didSet=safeAPI(C_Map.SetUserWaypoint,point)
                    pinned=setOK and didSet~=false
                    if pinned then
                        self.ownedWaypoint={id=wp.id,x=wp.x,y=wp.y}
                        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                            safeAPI(C_SuperTrack.SetSuperTrackedUserWaypoint,true)
                        end
                    end
                end
            end
        end
    end
    self.autoFollowStatus=focused and "QUEST FOCUSED" or pinned and "PIN SET"
        or watched and "QUEST WATCHED" or "MANUAL MAP"
end

function FF:Debug()
    self:Message("v"..self.version.." | live guide: "..tostring(self.guide~=nil).." | dashboard: "..tostring(self.window~=nil))
    self:Message("Quests: "..tostring(self.snapshot and self.snapshot.questCount or "unknown").." | priority: "..tostring(self.char and self.char.priority))
    self:Message("Minimap: "..tostring(self.minimap~=nil).." | last error: "..tostring(self.lastError or "none"))
    self:Message("Auto-follow: "..tostring(self.char and self.char.autoFollow).." | "..tostring(self.autoFollowStatus or "waiting").." | quest "..tostring(self.plan and self.plan.quest and self.plan.quest.id))
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
    elseif cmd=="hud" then
        if arg=="tiny" or arg=="min" then FF.char.hudMinimal=true
        elseif arg=="normal" or arg=="full" then FF.char.hudMinimal=false
        else FF.char.hudMinimal=not FF.char.hudMinimal end
        FF:SetGuideCollapsed(FF.char.guideCollapsed);FF:Refresh()
    elseif tabs[cmd] then FF:ShowTab(cmd); FF.window:Show(); FF.char.visible=true; FF:Refresh()
    elseif cmd=="level" or cmd=="gold" or cmd=="balanced" then FF:SetPriority(cmd)
    elseif cmd=="priority" then FF:SetPriority(arg)
    elseif cmd=="auto" then FF:ChooseQuest(0)
    elseif cmd=="next" then FF:SkipQuest()
    elseif cmd=="map" then FF:MapAction()
    elseif cmd=="track" then FF:TrackQuest()
    elseif cmd=="follow" then
        if arg=="on" then FF:SetAutoFollow(true)
        elseif arg=="off" then FF:SetAutoFollow(false)
        else FF:SetAutoFollow(not FF.char.autoFollow) end
        FF:Message("Automatic quest following: "..(FF.char.autoFollow and "ON" or "OFF"))
    elseif cmd=="focus" then FF:SyncRecommendedQuest(FF.plan,true);FF:Refresh()
    elseif cmd=="debug" then FF:Debug()
    elseif cmd=="resetpos" then
        FF.char.posX=0; FF.char.posY=0; FF.char.guideX=-620; FF.char.guideY=170
        FF.window:ClearAllPoints(); FF.window:SetPoint("CENTER", UIParent,"CENTER",0,0)
        FF.guide:ClearAllPoints(); FF.guide:SetPoint("CENTER",UIParent,"CENTER",-620,170)
        FF:Message("Window positions reset.")
    elseif cmd=="help" then
        FF:Message("/flow dashboard  |  /flow guide toggle HUD  |  /flow hud tiny|normal resize HUD")
        FF:Message("/flow priority level|gold|balanced  |  /flow follow on|off  |  /flow focus")
        FF:Message("/flow map  |  /flow track  |  /flow auto  |  /flow hud tiny|normal")
        FF:Message("/flow leveling|skills|character|settings  |  /flow debug  |  /flow resetpos")
    else FF:Message("Unknown command. Type /flow help.") end
end

local events=CreateFrame("Frame")
for _,event in ipairs({"ADDON_LOADED","PLAYER_LOGIN"}) do events:RegisterEvent(event) end
local optional={"PLAYER_LEVEL_UP","PLAYER_XP_UPDATE","QUEST_LOG_UPDATE","QUEST_ACCEPTED",
 "QUEST_REMOVED","QUEST_TURNED_IN","BAG_UPDATE_DELAYED","PLAYER_MONEY",
 "UPDATE_INVENTORY_DURABILITY","PLAYER_EQUIPMENT_CHANGED","SKILL_LINES_CHANGED",
 "ZONE_CHANGED","ZONE_CHANGED_NEW_AREA","PLAYER_REGEN_ENABLED","SPELLS_CHANGED"}
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
    elseif event=="BAG_UPDATE_DELAYED" then FF:RecordInventory(false) end
    FF:RecordMoneyAndXP()
    FF:Refresh()
end)
events:SetScript("OnUpdate",function(_,delta)
    if not FF.window or not FF.guide then return end
    if not (FF.window:IsShown() or FF.guide:IsShown()) then return end
    timer=timer+delta
    if timer<6 then return end
    timer=0
    FF:RecordMoneyAndXP()
    FF:Refresh()
end)
