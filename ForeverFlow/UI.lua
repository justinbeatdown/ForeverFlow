-- ForeverFlow 0.5.5 UI | original classic fantasy bronze/black visual theme.
local _,FF=...
local C=FF.colors
local W,H=652,720
-- UX refresh: pages need stateful actions, not only read-only snapshots.
local TAB_NAMES={"today","leveling","gold","skills","character","settings"}
local TAB_LABELS={"TODAY","LEVELING","GOLD","SKILLS","CHARACTER","SETTINGS"}

local function paint(fs,c) fs:SetTextColor(c[1],c[2],c[3],c[4] or 1) end
local function skin(f,bg,border,texture)
    -- The three texture families are authored for ForeverFlow: metal, inset cards, controls.
    f:SetBackdrop({bgFile=FF.media..(texture or "CardBG.tga"),
        edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1,
        insets={left=1,right=1,top=1,bottom=1}})
    local b=border or C.border
    f:SetBackdropColor(1,1,1,1)
    f:SetBackdropBorderColor(b[1],b[2],b[3],b[4] or 1)
end
local function rule(f,x,y,w,a)
    local t=f:CreateTexture(nil,"OVERLAY")
    t:SetColorTexture(C.gold[1],C.gold[2],C.gold[3],a or .55)
    t:SetPoint("TOPLEFT",f,"TOPLEFT",x,-y);t:SetSize(w,1)
    return t
end
local function label(parent,copy,x,y,w,h,size,color,just)
    local f=parent:CreateFontString(nil,"OVERLAY")
    f:SetFont(STANDARD_TEXT_FONT,size or 12,"")
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y)
    f:SetSize(w,h or 20)
    f:SetJustifyH(just or "LEFT"); f:SetJustifyV("TOP")
    f:SetWordWrap(true); f:SetText(copy or "")
    paint(f,color or C.white)
    return f
end
local function panel(parent,x,y,w,h,fill)
    local f=CreateFrame("Frame",nil,parent,"BackdropTemplate")
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y);f:SetSize(w,h)
    skin(f,fill or C.panel,C.border,"CardBG.tga")
    return f
end
local function button(parent,caption,x,y,w,h,cb)
    local f=CreateFrame("Button",nil,parent,"BackdropTemplate")
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y);f:SetSize(w,h)
    skin(f,C.button,C.border,"ButtonBG.tga")
    f.text=label(f,caption,4,math.max(3,math.floor((h-14)/2)),w-8,18,11,C.white,"CENTER")
    f:SetScript("OnClick",cb)
    f:SetScript("OnEnter",function(self)
        self:SetBackdropBorderColor(C.gold[1],C.gold[2],C.gold[3],1)
        self:SetBackdropColor(1.22,1.17,1.08,1)
    end)
    f:SetScript("OnLeave",function(self)
        local active=self.ffActive==true
        self:SetBackdropBorderColor(active and C.gold[1] or C.border[1],active and C.gold[2] or C.border[2],active and C.gold[3] or C.border[3],1)
        self:SetBackdropColor(1,1,1,1)
    end)
    return f
end
local function heading(parent,copy)
    local f=label(parent,copy,12,10,parent:GetWidth()-24,20,12,C.gold)
    rule(parent,12,29,parent:GetWidth()-24,.26)
    return f
end
local function meter(parent,x,y,w,h)
    local bg=panel(parent,x,y,w,h,C.button)
    local fill=bg:CreateTexture(nil,"ARTWORK")
    fill:SetTexture(FF.media.."GoldButtonBG.tga")
    fill:SetPoint("TOPLEFT",bg,"TOPLEFT",1,-1)
    fill:SetSize(1,math.max(1,h-2))
    return function(fraction)
        fraction=type(fraction)=="number" and math.max(0,math.min(1,fraction)) or 0
        fill:SetWidth(math.max(1,(w-2)*fraction))
    end
end
local function icon(parent,file,x,y,w,h)
    local t=parent:CreateTexture(nil,"ARTWORK")
    t:SetTexture(FF.media..file)
    t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y);t:SetSize(w,h)
    return t
end
local function readable(value)
    if type(value)~="number" then return "--" end
    return math.floor(value+0.5).."%"
end
local function elapsedText(n)
    n=math.floor(math.max(0,n or 0))
    return math.floor(n/3600).."h "..string.format("%02d",math.floor(n%3600/60)).."m"
end
local function shorten(t,max)
    t=tostring(t or "")
    if #t>(max or 140) then return t:sub(1,(max or 140)-3).."..." end
    return t
end
local function switchHighlight(b,on)
    if not b then return end
    b.ffActive=not not on
    b:SetBackdrop({bgFile=FF.media..(on and "GoldButtonBG.tga" or "ButtonBG.tga"),
        edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1,
        insets={left=1,right=1,top=1,bottom=1}})
    b:SetBackdropColor(1,1,1,1)
    if on then
        b:SetBackdropBorderColor(C.gold[1],C.gold[2],C.gold[3],1)
        paint(b.text,{1,.87,.55})
    else
        b:SetBackdropBorderColor(C.border[1],C.border[2],C.border[3],1)
        paint(b.text,C.white)
    end
end
function FF:MakeToday(p)
    local v={}
    local top=panel(p,14,9,624,158)
    heading(top,"AUTO PILOT  /  YOUR NEXT BEST STEP")
    v.kind=label(top,"",12,34,590,18,11,C.gold)
    v.title=label(top,"",12,57,590,34,17,C.white)
    v.detail=label(top,"",12,94,590,36,12,C.white)
    v.where=label(top,"",12,131,592,20,11,C.muted)
    button(p,"SET MAP PIN",14,178,195,34,function() FF:MapAction() end)
    button(p,"TRACK QUEST",222,178,195,34,function() FF:TrackQuest() end)
    button(p,"NEXT SUGGESTION",430,178,208,34,function() FF:SkipQuest() end)
    local focus=panel(p,14,224,624,89)
    heading(focus,"PLAYSTYLE  /  WHAT SHOULD WE PRIORITIZE?")
    v.priorities={}
    for i,item in ipairs({{"balanced","BALANCED"},{"level","FAST LEVELING"},{"gold","MORE GOLD"}}) do
        v.priorities[item[1]]=button(focus,item[2],12+(i-1)*206,37,196,35,function() FF:SetPriority(item[1]) end)
    end
    local status=panel(p,14,324,624,83)
    heading(status,"CHARACTER AT A GLANCE")
    v.statusA=label(status,"",12,34,290,18,12,C.white)
    v.statusB=label(status,"",310,34,300,18,12,C.white)
    v.statusC=label(status,"",12,59,290,18,12,C.white)
    v.statusD=label(status,"",310,59,300,18,12,C.white)
    local summary=panel(p,14,417,624,82)
    heading(summary,"EARN GOLD WHILE YOU LEVEL")
    v.goldTip=label(summary,"",12,32,596,31,11,C.white)
    v.progress=label(summary,"",12,67,596,16,10,C.gold)
    return v
end
function FF:MakeLeveling(p)
    local v={}
    local intro=panel(p,14,9,624,107)
    heading(intro,"QUEST ROUTE: SELECTED FROM YOUR LIVE QUEST LOG")
    v.summary=label(intro,"",12,32,596,19,13,C.white)
    v.description=label(intro,"",12,53,596,27,11,C.muted)
    v.pace=label(intro,"",12,82,596,19,11,C.gold)
    local list=panel(p,14,127,624,305)
    v.listHeading=heading(list,"QUEST SHORTLIST  /  CHOOSE A ROUTE")
    v.rows={}
    for i=1,5 do
        local y=32+(i-1)*53
        local r={}
        r.name=label(list,"",12,y,456,21,12,C.white)
        r.objective=label(list,"",12,y+22,457,29,10,C.muted)
        r.pin=button(list,"PIN",507,y+4,105,31,function() if r.id then FF:ChooseQuest(r.id) end end)
        v.rows[i]=r
    end
    -- Separate mode: unaccepted quests are not part of auto-follow or the quest log.
    v.discoverRows={}
    for i=1,3 do
        local y=34+(i-1)*85
        local r={}
        r.name=label(list,"",12,y,585,20,12,C.gold)
        r.reason=label(list,"",12,y+21,375,52,10,C.muted)
        r.map=button(list,"MAP",392,y+33,66,27,function() FF:ShowDiscoveryOnMap(r.quest) end)
        r.save=button(list,"SAVE",467,y+33,68,27,function()
            if r.quest then FF:ToggleSavedDiscovery(r.quest.id) end
        end)
        r.skip=button(list,"SKIP",544,y+33,67,27,function()
            if r.quest then FF:SkipDiscovery(r.quest.id) end
        end)
        v.discoverRows[i]=r
    end
    v.empty=label(list,"",12,44,590,115,12,C.muted)
    local foot=panel(p,14,443,624,56)
    v.myQuests=button(foot,"MY QUESTS",12,11,187,33,function()
        FF.char.discoverView=false;FF:Refresh()
    end)
    v.discover=button(foot,"DISCOVER QUESTS",208,11,195,33,function()
        FF.char.discoverView=true
        if FF.snapshot then FF:FindDiscoveries(FF.snapshot,true) end
        FF:Refresh()
    end)
    v.action=button(foot,"AUTO / UNPIN",412,11,200,33,function()
        if FF.char.discoverView then
            FF:ResetSkippedDiscoveries()
        else
            FF:UnpinCurrentQuest()
        end
    end)
    return v
end
function FF:MakeGold(p)
    local v={}
    local top=panel(p,14,9,624,100)
    heading(top,"GOLD TRACKER - REAL COIN CHANGES")
    v.money=label(top,"",12,35,590,30,22,C.white)
    v.target=label(top,"",12,71,590,20,12,C.muted)
    local perf=panel(p,14,121,624,119)
    heading(perf,"YOUR SESSION (UPDATED AUTOMATICALLY)")
    v.sessionEarned=label(perf,"",12,32,590,20,12,C.white)
    v.sessionSpent=label(perf,"",12,56,590,20,12,C.white)
    v.goldPerHour=label(perf,"",12,80,590,25,11,C.muted)
    local advice=panel(p,14,251,624,116)
    heading(advice,"YOUR BEST CURRENT GOLD OPPORTUNITY")
    v.goldCategory=label(advice,"",12,34,594,20,12,C.gold)
    v.advice=label(advice,"",12,56,594,27,11,C.white)
    v.bags=button(advice,"OPEN BAGS",12,84,287,26,function()
        if type(ToggleAllBags)=="function" then ToggleAllBags()
        elseif type(OpenAllBags)=="function" then OpenAllBags()
        else FF:Message("Open your bags with the default bag shortcut (B).") end
    end)
    v.skills=button(advice,"PROFESSION PLAN",313,84,299,26,function() FF:ShowTab("skills") end)
    local controls=panel(p,14,379,624,120)
    heading(controls,"GOLD TARGET: AUTOMATIC BY DEFAULT")
    v.goalFill=meter(controls,12,35,600,9)
    v.goalDetail=label(controls,"",12,54,588,18,11,C.muted)
    v.auto=button(controls,"AUTO",12,83,186,29,function() FF.char.goldTarget=0;FF.char.autoGoldTargetCopper=nil;FF:Refresh() end)
    v.plus5=button(controls,"CURRENT +5G",210,83,193,29,function()
        local money=FF.snapshot and FF.snapshot.money or 0
        FF.char.goldTarget=math.ceil(money/10000)+5;FF:Refresh()
    end)
    v.plus20=button(controls,"CURRENT +20G",415,83,197,29,function()
        local money=FF.snapshot and FF.snapshot.money or 0
        FF.char.goldTarget=math.ceil(money/10000)+20;FF:Refresh()
    end)
    return v
end
function FF:MakeSkills(p)
    local v={}
    local top=panel(p,14,9,624,176)
    heading(top,"PROFESSIONS: LIVE SKILL PROGRESS")
    v.primary={}
    for i=1,2 do
        local y=35+(i-1)*64
        local x={}
        x.name=label(top,"",12,y,350,20,13,C.white)
        x.level=label(top,"",386,y,223,18,12,C.muted,"RIGHT")
        x.bar=meter(top,12,y+26,600,11)
        v.primary[i]=x
    end
    local secondary=panel(p,14,196,624,65)
    heading(secondary,"SECONDARY SKILLS")
    v.secondary=label(secondary,"",12,35,590,22,12,C.white)
    local acquisition=panel(p,14,273,624,105)
    heading(acquisition,"MATERIALS ACQUIRED THIS SESSION")
    v.materials=label(acquisition,"",12,34,590,25,18,C.white)
    v.materialsMore=label(acquisition,"",12,73,590,22,11,C.muted)
    local tip=panel(p,14,390,624,109)
    heading(tip,"NEXT SKILL STEP")
    v.skill=label(tip,"",12,31,596,25,12,C.white)
    v.gather=label(tip,"",12,54,596,17,10,C.gold)
    v.goal=button(tip,"GATHER TARGET +10",12,76,296,28,function()
        FF.char.gatherTarget=math.min(500,(FF.char.gatherTarget or 20)+10)
        FF:Refresh()
    end)
    v.professions=button(tip,"OPEN PROFESSIONS",318,76,294,28,function()
        if type(ToggleProfessions)=="function" then ToggleProfessions()
        elseif type(ToggleSpellBook)=="function" then ToggleSpellBook("professions")
        else FF:Message("Open your Professions panel from the game UI (default K).") end
    end)
    return v
end
function FF:MakeCharacter(p)
    local v={}
    local ch=panel(p,14,9,624,95)
    heading(ch,"CHARACTER COACH")
    v.name=label(ch,"",12,33,592,22,17,C.white)
    v.zone=label(ch,"",12,66,592,21,12,C.muted)
    local routine=panel(p,14,115,624,148)
    heading(routine,"LEVEL-UP CHECKLIST (OPTIONAL)")
    v.checks={}
    local list={"Review new talents", "Check new class abilities and trainer options", "Repair gear and compare useful upgrades"}
    for i=1,3 do
        local idx=i
        local b=button(routine,"",12,34+(i-1)*35,600,30,function()
            FF.char.trainingChecks[idx]=not FF.char.trainingChecks[idx];FF:Refresh()
        end)
        b.text:SetText(list[i]);b.text:SetJustifyH("LEFT")
        v.checks[i]={button=b,caption=list[i]}
    end
    local tips=panel(p,14,275,624,224)
    heading(tips,"SIMPLE CLASS ADVICE")
    v.tips={}
    for i=1,3 do v.tips[i]=label(tips,"",12,38+(i-1)*61,589,53,12,C.white) end
    return v
end
function FF:MakeSettings(p)
    local v={}
    local settings=panel(p,14,9,624,256)
    heading(settings,"YOUR EXPERIENCE")
    v.guide=button(settings,"",12,35,293,35,function() FF:ToggleGuide() end)
    v.minimap=button(settings,"",317,35,295,35,function() FF.char.hideMinimap=not FF.char.hideMinimap; FF:Refresh() end)
    v.simple=button(settings,"SIMPLE VIEW",12,80,293,35,function() FF.db.mode="simple";FF:Refresh() end)
    v.advanced=button(settings,"ADVANCED VIEW",317,80,295,35,function() FF.db.mode="advanced";FF:Refresh() end)
    v.lock=button(settings,"",12,125,293,35,function() FF.char.guideLocked=not FF.char.guideLocked;FF:Refresh() end)
    v.quiet=button(settings,"",317,125,295,35,function() FF.db.quiet=not FF.db.quiet;FF:Refresh() end)
    v.hudSize=button(settings,"HUD SIZE",12,171,293,34,function()
        FF.char.hudMinimal=not FF.char.hudMinimal
        FF:SetGuideCollapsed(FF.char.guideCollapsed);FF:Refresh()
    end)
    button(settings,"RESET POSITIONS",317,171,295,34,function()
        FF.char.posX=0; FF.char.posY=0; FF.char.guideX=-620; FF.char.guideY=170
        FF.window:ClearAllPoints(); FF.window:SetPoint("CENTER",UIParent,"CENTER",0,0)
        FF.guide:ClearAllPoints(); FF.guide:SetPoint("CENTER",UIParent,"CENTER",-620,170)
    end)
    v.scale=button(settings,"GUIDE SCALE",317,210,295,33,function()
        local current=FF.char.guideScale or 1
        FF:SetGuideScale(current<.95 and 1 or (current<1.1 and 1.2 or .85))
    end)
    v.autofollow=button(settings,"AUTO-FOLLOW",12,210,293,33,function()
        FF:SetAutoFollow(not FF.char.autoFollow)
    end)
    local info=panel(p,14,277,624,222)
    heading(info,"HOW TO USE FOREVERFLOW")
    label(info,"1   Log in: ForeverFlow suggests a quest and requests tracking.",12,35,590,27,13,C.white)
    label(info,"2   Follow the compact HUD. Expand it for more controls.",12,73,458,42,13,C.white)
    label(info,"3   /flow stats shows XP pace; /flow pin or unpin controls selection.",12,115,458,47,13,C.white)
    icon(info,"ForeverFlowLogo.tga",489,45,121,121)
    label(info,"No automatic movement/combat. Quest focus uses the native client; if unavailable, the map button remains available.",12,169,590,48,11,C.muted)
    return v
end

function FF:CreateGuide()
    -- A compact HUD ribbon (not a second dashboard). No buttons in the default
    -- 88px view; the extended view is optional for extra detail and controls.
    local g=CreateFrame("Frame",nil,UIParent,"BackdropTemplate")
    g:SetSize(302,103)
    g:SetScale(self.char.guideScale or 1)
    g:SetPoint("CENTER",UIParent,"CENTER",self.char.guideX,self.char.guideY)
    g:SetFrameStrata("MEDIUM");g:SetClampedToScreen(true)
    g:SetMovable(true);g:EnableMouse(true);g:RegisterForDrag("LeftButton")
    skin(g,C.bg,C.gold,"HUDBackground.tga")
    g:SetAlpha(.97)
    g:SetScript("OnDragStart",function(self) if not FF.char.guideLocked then self:StartMoving() end end)
    g:SetScript("OnDragStop",function(self) self:StopMovingOrSizing();FF:SavePosition(self,"guide") end)
    -- Compact emblem isolates the approved logo’s castle/path scene so it remains
    -- legible at 30px; full official mark is preserved on larger UI surfaces.
    -- Header divider starts at 38px, below the 34px badge edge.
    g.badge=icon(g,"GuideLogoSmall.tga",8,4,30,30)
    label(g,"FOREVER|cffffbd5cFLOW|r",45,7,130,20,12,C.white)
    g.follow=label(g,"AUTO-FOLLOW",167,10,82,14,9,C.gold,"RIGHT")
    g.collapse=button(g,"v",255,7,20,20,function(_,mouse)
        if mouse=="RightButton" then
            FF.char.guideCollapsed=not FF.char.guideCollapsed
            FF:SetGuideCollapsed(FF.char.guideCollapsed)
        elseif FF.char.guideCollapsed then
            FF:SetGuideCollapsed(false)
        else
            FF.char.hudMinimal=not FF.char.hudMinimal
            FF:SetGuideCollapsed(false)
        end
    end)
    g.collapse:RegisterForClicks("LeftButtonUp","RightButtonUp")
    button(g,"x",278,7,19,20,function() FF:ToggleGuide() end)
    rule(g,7,38,287,.56)
    g.content=CreateFrame("Frame",nil,g)
    g.content:SetPoint("TOPLEFT",g,"TOPLEFT",0,-42)
    g.content:SetSize(302,144)
    g.kind=label(g.content,"",9,0,283,16,9,C.gold)
    g.title=label(g.content,"",9,17,283,23,14,C.white)
    g.where=label(g.content,"",9,40,280,18,10,C.gold)
    -- The detailed text and buttons live ONLY in the expanded mode.
    g.detail=label(g.content,"",9,62,282,29,10,C.white)
    g.gold=label(g.content,"",9,95,282,15,10,C.green)
    -- An actual navigation control, not a perpetually static line of flavor text.
    g.goldLink=CreateFrame("Button",nil,g.content)
    g.goldLink:SetPoint("TOPLEFT",g.content,"TOPLEFT",7,-93)
    g.goldLink:SetSize(288,20)
    g.goldLink:RegisterForClicks("LeftButtonUp")
    g.goldLink:SetScript("OnClick",function()
        FF.window:Show(); FF.char.visible=true; FF:ShowTab("gold"); FF:Refresh()
    end)
    g.goldLink:SetScript("OnEnter",function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        GameTooltip:AddLine("ForeverFlow Gold Tracker",1,.78,.35)
        GameTooltip:AddLine("Session totals update from inventory and coin changes.",1,1,1)
        GameTooltip:AddLine("Material gains can include bag transfers, not just gathering.",.75,.75,.75)
        GameTooltip:AddLine("Click to open the Gold tab.",.6,1,.6)
        GameTooltip:Show()
    end)
    g.goldLink:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    g.map=button(g.content,"MAP",7,119,88,24,function() FF:MapAction() end)
    g.next=button(g.content,"NEXT",106,119,88,24,function() FF:SkipQuest() end)
    g.open=button(g.content,"DETAILS",205,119,90,24,function()
        FF.window:Show();FF.char.visible=true;FF:ShowTab("today")
    end)
    self.guide=g
    self:SetGuideCollapsed(self.char.guideCollapsed)
    g:SetShown(self.char.guideVisible)
end
function FF:SetGuideCollapsed(value)
    if not self.guide then return end
    self.char.guideCollapsed=value and true or false
    local compact=self.char.hudMinimal==true
    -- Collapsed header: 40px. Compact: 103px. Expanded: 190px.
    -- Every child ends INSIDE its parent; no clipped logos or buttons.
    self.guide:SetHeight(value and 40 or (compact and 103 or 190))
    self.guide.content:SetShown(not value)
    self.guide.collapse.text:SetText(value and "+" or (compact and "v" or "^"))
    self.guide.detail:SetShown(not value and not compact)
    self.guide.gold:SetShown(not value and not compact)
    self.guide.goldLink:SetShown(not value and not compact)
    self.guide.map:SetShown(not value and not compact)
    self.guide.next:SetShown(not value and not compact)
    self.guide.open:SetShown(not value and not compact)
end
function FF:PositionMinimapIcon()
    if not self.minimap or not Minimap then return end
    local theta=math.rad(self.char.minimapAngle or 210)
    local r=(Minimap.GetWidth and Minimap:GetWidth() or 140)/2+12
    self.minimap:ClearAllPoints()
    self.minimap:SetPoint("CENTER",Minimap,"CENTER",math.cos(theta)*r,math.sin(theta)*r)
end
function FF:CreateMinimapButton()
    if not Minimap then return end
    -- Critical: DO NOT parent to Minimap. Its internal mask/clipping cropped v0.3.
    local b=CreateFrame("Button",nil,UIParent)
    b:SetSize(34,34);b:SetFrameStrata("HIGH")
    -- A true round RGBA texture: no BackdropTemplate / square border or dark sticker.
    -- Independent of Blizzard minimap mask so other addon/minimap skins cannot clip it.
    local pic=b:CreateTexture(nil,"ARTWORK")
    pic:SetTexture(FF.media.."MinimapIconRound.tga")
    -- Inset the actual circular logo so its compass tips stay visible and
    -- the Blizzard circular highlight does not collide with other icons.
    pic:SetPoint("TOPLEFT",b,"TOPLEFT",2,-2)
    pic:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-2,2)
    b.icon=pic
    -- Blizzard's circular minimap-button hover ring, no rectangular highlight.
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")
    b:RegisterForClicks("LeftButtonUp","RightButtonUp")
    b:RegisterForDrag("LeftButton")
    b:SetScript("OnClick",function(_,which)
        if which=="RightButton" then FF:ToggleGuide() else FF:Toggle() end
    end)
    b:SetScript("OnDragStart",function(self)
        self:SetScript("OnUpdate",function()
            if not GetCursorPosition then return end
            local x,y=GetCursorPosition()
            local scale=(UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
            local cx,cy=Minimap:GetCenter()
            if cx and cy and x and y and scale>0 then
                local dx,dy=x/scale-cx,y/scale-cy
                local radians
                if math.atan2 then radians=math.atan2(dy,dx)
                elseif atan2 then radians=atan2(dy,dx)
                elseif dx>0 then radians=math.atan(dy/dx)
                elseif dx<0 then radians=math.atan(dy/dx)+(dy>=0 and math.pi or -math.pi)
                else radians=dy>=0 and math.pi/2 or -math.pi/2 end
                FF.char.minimapAngle=math.deg(radians)
                FF:PositionMinimapIcon()
            end
        end)
    end)
    b:SetScript("OnDragStop",function(self) self:SetScript("OnUpdate",nil) end)
    b:SetScript("OnEnter",function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self,"ANCHOR_LEFT")
        GameTooltip:AddLine("ForeverFlow",1,.78,.35)
        GameTooltip:AddLine("Left-click: Dashboard",1,1,1)
        GameTooltip:AddLine("Right-click: Toggle HUD",1,1,1)
        GameTooltip:AddLine("Drag to reposition",.7,.7,.7)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    self.minimap=b
    self:PositionMinimapIcon()
    b:SetShown(not self.char.hideMinimap)
end

function FF:CreateUI()
    if self.window then return end
    local win=CreateFrame("Frame",nil,UIParent,"BackdropTemplate")
    win:SetSize(W,H);win:SetPoint("CENTER",UIParent,"CENTER",self.char.posX,self.char.posY)
    win:SetFrameStrata("DIALOG");win:SetClampedToScreen(true)
    win:SetMovable(true);win:EnableMouse(true);win:RegisterForDrag("LeftButton")
    skin(win,C.bg,C.gold,"WindowBG.tga")
    win:SetScript("OnDragStart",function(self) if not FF.char.locked then self:StartMoving() end end)
    win:SetScript("OnDragStop",function(self) self:StopMovingOrSizing();FF:SavePosition(self,"main") end)
    self.window=win
    -- Real standalone wordmark art; no cropped logo scenery or subtitle.
    icon(win,"HeaderWordmark.tga",15,14,281,68)
    rule(win,14,90,624,.85)
    label(win,"SMART LEVELING + GOLD",309,26,233,21,14,C.gold)
    label(win,"Questing  /  Gold  /  Progress",309,51,235,20,11,C.muted)
    button(win,"GUIDE",551,12,57,25,function()
        if not FF.guide:IsShown() then FF:ToggleGuide() end
    end)
    button(win,"X",614,12,23,25,function() FF:Toggle() end)
    self.tabButtons={}
    for i,name in ipairs(TAB_NAMES) do
        local b=button(win,TAB_LABELS[i],14+(i-1)*105,106,99,30,function() FF:ShowTab(name) end)
        icon(b,"Tab"..({"Today","Leveling","Gold","Skills","Character","Settings"})[i]..".tga",6,5,20,20)
        b.text:ClearAllPoints()
        b.text:SetPoint("TOPLEFT",b,"TOPLEFT",24,-8)
        b.text:SetSize(73,16)
        b.text:SetJustifyH("CENTER")
        self.tabButtons[name]=b
    end
    self.status=label(win,"",16,147,470,20,13,C.white)
    self.xpText=label(win,"",473,148,165,20,11,C.muted,"RIGHT")
    self.xp=meter(win,15,172,623,9)
    self.pages={};self.views={}
    for _,tab in ipairs(TAB_NAMES) do
        local p=CreateFrame("Frame",nil,win)
        p:SetPoint("TOPLEFT",win,"TOPLEFT",0,-191);p:SetSize(W,506)
        self.pages[tab]=p
    end
    self.views.today=self:MakeToday(self.pages.today)
    self.views.leveling=self:MakeLeveling(self.pages.leveling)
    self.views.gold=self:MakeGold(self.pages.gold)
    self.views.skills=self:MakeSkills(self.pages.skills)
    self.views.character=self:MakeCharacter(self.pages.character)
    self.views.settings=self:MakeSettings(self.pages.settings)
    rule(win,14,695,624,.60)
    label(win,"AUTO PLAN   /   YOU PLAY, WE GUIDE   /   /flow help",16,701,624,18,10,C.muted)
    self:CreateGuide()
    self:CreateMinimapButton()
    self:ShowTab(self.pages[self.char.activeTab] and self.char.activeTab or "today")
    win:SetShown(self.char.visible)
    self:Refresh()
end
function FF:ShowTab(name)
    if not self.pages or not self.pages[name] then return end
    self.char.activeTab=name
    for _,tab in ipairs(TAB_NAMES) do
        self.pages[tab]:SetShown(tab==name)
        switchHighlight(self.tabButtons[tab],tab==name)
    end
    self:Refresh()
end

function FF:UpdateUI()
    local s=self.snapshot;local plan=self.plan
    if not s or not plan or not self.views then return end
    if self.guide then
        local g=self.guide
        g.kind:SetText(plan.category..(plan.progress and ("   •   "..plan.progress) or ""))
        g.title:SetText(shorten(plan.title,42))
        g.detail:SetText(shorten(plan.detail,99))
        local destination=plan.where
        if not destination or destination=="" then
            destination=plan.quest and (plan.quest.questArea or s.zone) or s.zone
        end
        g.where:SetText(shorten(destination,51))
        local state=self.char.autoFollow and (self.autoFollowStatus or "WAITING") or "OFF"
        local shortStatus=({["QUEST FOCUSED"]="FOCUSED",["FOCUS REQUESTED"]="FOCUS SENT",
          ["HINT PIN SET"]="HINT PIN",["WATCH REQUESTED"]="WATCH SENT",
          ["MAP NEEDED"]="MAP NEEDED",["AFTER COMBAT"]="IN COMBAT",
          ["NO QUEST"]="NO QUEST"})[state] or state
        g.follow:SetText(shorten(shortStatus,12))
        paint(g.follow,(state=="QUEST FOCUSED") and C.green or C.gold)
        g.gold:SetText(shorten(self:GoldHudSummary(s),53))
        g.map.text:SetText(plan.quest and plan.quest.waypoint and plan.quest.waypoint.id and "SET PIN" or "OPEN MAP")
    end
    self.status:SetText("LEVEL "..s.level.."  |  "..s.className.."  |  "..shorten(s.zone,30))
    self.xpText:SetText(s.xpPercent and readable(s.xpPercent).." to next level" or "XP not available")
    self.xp(s.xpPercent and s.xpPercent/100 or 0)
    local v=self.views.today
    v.kind:SetText(plan.category)
    v.title:SetText(shorten(plan.title,94))
    v.detail:SetText(shorten(plan.detail,167))
    v.where:SetText(shorten(plan.where,115))
    for priority,b in pairs(v.priorities) do switchHighlight(b,self.char.priority==priority) end
    v.statusA:SetText(s.questCount and ("Quests: "..s.questCount.."  ("..s.questComplete.." completed)") or "Quests: not available")
    v.statusB:SetText("Bags: "..(s.bagFree and (s.bagFree.."/"..s.bagTotal.." free") or "unavailable"))
    v.statusC:SetText("Money: "..self:MoneyText(s.money))
    v.statusD:SetText("Durability: "..readable(s.durability))
    v.goldTip:SetText(shorten(s.goldTip,131))
    v.progress:SetText("THIS SESSION: "..elapsedText(s.elapsed).." | XP +"..math.floor(s.session.xpEarned or 0).." | Quests "..s.session.questTurns.." | Materials "..s.session.materials)

    v=self.views.leveling
    local discoverMode=self.char.discoverView==true
    switchHighlight(v.myQuests,not discoverMode)
    switchHighlight(v.discover,discoverMode)
    v.action.text:SetText(discoverMode and "RESET SKIPPED" or
        (self.char.manualQuestID>0 and "UNPIN / RESUME AUTO" or "AUTO / UNPIN"))
    v.listHeading:SetText(discoverMode and "DISCOVER QUESTS  /  NOT IN YOUR LOG" or "QUEST SHORTLIST  /  CHOOSE A ROUTE")
    if discoverMode then
        local suggested,detail=self:FindDiscoveries(s)
        v.summary:SetText("DISCOVERY  |  "..#suggested.." suggestions  |  level "..s.level.."  |  "..shorten(s.zone,30))
        v.description:SetText(shorten(detail,105))
        v.pace:SetText("CLIENT-OBSERVED QUESTS  |  Eligibility and NPC pickup are not guaranteed")
        for i=1,5 do
            local r=v.rows[i];r.name:Hide();r.objective:Hide();r.pin:Hide()
        end
        local count=math.min(3,#suggested)
        v.empty:SetShown(count==0)
        v.empty:SetText("No new quest starts detected in this area yet.\n\nOpen a nearby quest giver, then press DISCOVER QUESTS again. Or move to another zone.\n\nOnly client-reported or previously observed quests appear; no invented quests or pickup locations.")
        for i=1,3 do
            local r=v.discoverRows[i]; local q=suggested[i]
            r.quest=q
            for _,part in ipairs({r.name,r.reason,r.map,r.save,r.skip}) do part:SetShown(q~=nil) end
            if q then
                r.name:SetText(shorten(i..". "..q.title.."  ["..q.confidence.."]",85))
                r.reason:SetText(shorten(q.why,125))
                r.save.text:SetText(q.saved and "UNSAVE" or "SAVE")
            end
        end
    else
        v.empty:Hide()
        for _,r in ipairs(v.discoverRows) do
            r.quest=nil
            for _,part in ipairs({r.name,r.reason,r.map,r.save,r.skip}) do part:Hide() end
        end
        for i=1,5 do
            v.rows[i].name:Show();v.rows[i].objective:Show()
        end
    end
    if not discoverMode then
    v.summary:SetText((s.questCount or "?").." quests  |  "..s.questComplete.." ready  |  "..(self.char.manualQuestID>0 and "manual quest pinned" or "auto selected"))
    local active=plan.quest
    v.description:SetText(active and
        ("ACTIVE: "..shorten(active.title,40).."  |  "..(self.char.manualQuestID>0 and "PINNED BY YOU" or "AUTO PICK").."  |  "..(active.done and "READY TO TURN IN" or "OBJECTIVES ACTIVE"))
        or "No active quest. Pick up quests and open your quest log.")
    local pace=self:LevelingPace(s)
    v.pace:SetText(self.char.showPace and ("SESSION PACE: "..(pace.reliable and (pace.rate.." XP/hr") or "calculating after 5 minutes").."  |  NEXT LEVEL: "..pace.eta) or "SESSION PACE: hidden (/flow pace)")
    for i=1,5 do
        local quest=s.quests[i];local row=v.rows[i]
        if quest then
            row.id=quest.id
            local selected=active and active.id==quest.id
            row.name:SetText((selected and "|cffffca5e> " or "|cffbb9d6d  ")..i..". "..shorten(quest.title,51).."|r"..(quest.done and "  |cff77dd98[TURN IN]|r" or ""))
            row.pin.ffActive=selected or quest.id==self.char.manualQuestID
            switchHighlight(row.pin,row.pin.ffActive)
            row.objective:SetText(shorten(quest.firstObjective or (quest.done and "Ready for quest turn-in" or "Open the quest log for objectives"),95))
            row.pin:SetShown(type(quest.id)=="number")
            row.pin.text:SetText(quest.id==self.char.manualQuestID and "PINNED" or (selected and "SELECTED" or "PIN QUEST"))
        else
            row.id=nil;row.name:SetText(i==1 and "No visible quests detected. Pick up quests or open collapsed log headers." or "")
            row.objective:SetText("");row.pin:Hide()
        end
    end
    end -- quest-log view
    v=self.views.gold
    v.money:SetText(self:MoneyText(s.money))
    local target=0
    if self.char.goldTarget>0 then target=self.char.goldTarget*10000
    else
        if not self.char.autoGoldTargetCopper or self.char.autoGoldTargetCopper<=s.money then
            self.char.autoGoldTargetCopper=(math.floor(s.money/10000)+5)*10000
        end
        target=self.char.autoGoldTargetCopper
    end
    v.target:SetText("Next goal: "..self:MoneyText(target)..(self.char.goldTarget==0 and " (auto)" or " (custom)"))
    v.sessionEarned:SetText("Gold gained: "..self:MoneyText(s.session.earned,true).."  |  Net: "..self:MoneyText(s.session.earned-s.session.spent,true))
    v.sessionSpent:SetText("Gold spent: "..self:MoneyText(s.session.spent))
    if s.elapsed>=180 then
        v.goldPerHour:SetText("Gained per hour (session): "..self:MoneyText(s.session.earned*3600/s.elapsed)..". Not a guaranteed farming rate.")
    else v.goldPerHour:SetText("Hourly rate appears after 3 minutes; short sessions are misleading.") end
    v.goldCategory:SetText(s.goldCategory.."  |  "..(s.bagFree and (s.bagFree.." bag slots free") or "bags unavailable"))
    v.advice:SetText(shorten(s.goldTip,150))
    v.goalFill(target>0 and s.money/target or 0)
    v.goalDetail:SetText(target>s.money and (self:MoneyText(target-s.money).." until next target") or "Gold target reached!")
    switchHighlight(v.auto,self.char.goldTarget==0)

    v=self.views.skills
    for i=1,2 do
        local p,u=s.professions.primary[i],v.primary[i]
        if p then
            u.name:SetText(p.name)
            u.level:SetText(p.skill.."/"..(p.cap>0 and p.cap or "?"))
            u.bar(p.cap>0 and p.skill/p.cap or 0)
        else u.name:SetText("Profession slot "..i..": unlearned");u.level:SetText("Ask a trainer");u.bar(0) end
    end
    local secondary={}
    for _,p in ipairs(s.professions.secondary) do secondary[#secondary+1]=p.name.." "..p.skill.."/"..(p.cap>0 and p.cap or "?") end
    v.secondary:SetText(#secondary>0 and table.concat(secondary,"   |   ") or "No secondary professions detected")
    v.materials:SetText((s.session.materials or 0).." known materials acquired")
    v.materialsMore:SetText("Herbs "..(s.session.herb or 0).."  |  Ore/stone "..(s.session.ore or 0).."  |  Leather "..(s.session.leather or 0))
    local got=s.session.materials or 0
    local goal=self.char.gatherTarget or 20
    local remaining=math.max(0,goal-got)
    v.skill:SetText(shorten(s.skillTip,118))
    v.gather:SetText("GATHERING GOAL: "..got.." / "..goal.."  |  "..(remaining>0 and (remaining.." materials left") or "GOAL REACHED").."  (bag gains, not proven harvests)")
    v.goal.text:SetText(remaining>0 and "RAISE GOAL +10" or "SET NEXT GOAL +10")

    v=self.views.character
    v.name:SetText(s.className.."  |  Level "..s.level)
    v.zone:SetText("Zone: "..s.zone.."  |  Session: "..elapsedText(s.elapsed).."  |  Quests turned in: "..s.session.questTurns)
    for i,rec in ipairs(v.checks) do
        local done=self.char.trainingChecks[i]==true
        rec.button.text:SetText((done and "|cff72dc98[ x ]|r " or "|cffffbd5c[   ]|r ")..rec.caption)
    end
    for i,tip in ipairs(v.tips) do
        tip:SetText("• "..(s.tips[i] or ""))
        tip:SetShown(self.db.mode=="advanced" or i<=2)
    end
    v=self.views.settings
    v.guide.text:SetText("LIVE GUIDE: "..(self.guide:IsShown() and "ON" or "OFF"))
    v.minimap.text:SetText("MINIMAP ICON: "..(self.char.hideMinimap and "OFF" or "ON"))
    v.lock.text:SetText("MOVE GUIDE: "..(self.char.guideLocked and "LOCKED" or "UNLOCKED"))
    v.hudSize.text:SetText("HUD SIZE: "..(self.char.hudMinimal and "COMPACT" or "EXPANDED"))
    v.autofollow.text:SetText("AUTO-FOLLOW: "..(self.char.autoFollow and "ON" or "OFF"))
    v.scale.text:SetText("GUIDE SCALE: "..math.floor((self.char.guideScale or 1)*100+.5).."%")
    switchHighlight(v.autofollow,self.char.autoFollow)
    v.quiet.text:SetText("LEVEL-UP CHAT TIPS: "..(self.db.quiet and "OFF" or "ON"))
    switchHighlight(v.simple,self.db.mode=="simple")
    switchHighlight(v.advanced,self.db.mode=="advanced")
    if self.minimap then self.minimap:SetShown(not self.char.hideMinimap) end
end
