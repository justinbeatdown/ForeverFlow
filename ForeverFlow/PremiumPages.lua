-- ForeverFlow 0.5.6 beta 9: consistent six-tab profession-grade interface.
-- All values are from the live client or explicitly marked as reported/unverified.
local _,FF=...
local unpack=unpack or table.unpack
local legacyLeveling=FF.MakeLeveling
local legacyGold=FF.MakeGold
local legacyCharacter=FF.MakeCharacter
local legacySettings=FF.MakeSettings
local oldCreate=FF.CreateUI
local oldShowTab=FF.ShowTab
local oldUpdatePremium=FF.UpdatePremiumStudio
local TEXT={.94,.91,.84};local GOLD={1,.78,.37};local DIM={.66,.64,.60}
local GREEN={.49,.87,.55};local RED={1,.49,.4}
local function panel(parent,x,y,w,h)
 local f=CreateFrame('Frame',nil,parent,'BackdropTemplate'); f:SetPoint('TOPLEFT',parent,'TOPLEFT',x,-y);f:SetSize(w,h)
 f:SetBackdrop({bgFile=FF.media..'PremiumPanel.tga',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1,insets={left=1,right=1,top=1,bottom=1}})
 f:SetBackdropColor(.92,.92,.92,.97);f:SetBackdropBorderColor(.37,.29,.19,1)
 return f
end
local function text(parent,value,x,y,w,h,size,color,align,wrap)
 local t=parent:CreateFontString(nil,'OVERLAY');t:SetFont(STANDARD_TEXT_FONT,size or 12,'')
 t:SetPoint('TOPLEFT',parent,'TOPLEFT',x,-y);t:SetSize(w,h or 21)
 t:SetTextColor(unpack(color or TEXT));t:SetJustifyH(align or 'LEFT');t:SetJustifyV('MIDDLE');t:SetWordWrap(wrap==true)
 t:SetText(value or '');return t
end
local function line(parent,x,y,w)
 local t=parent:CreateTexture(nil,'ARTWORK');t:SetColorTexture(.8,.57,.27,.35)
 t:SetPoint('TOPLEFT',parent,'TOPLEFT',x,-y);t:SetSize(w,1);return t
end
local function icon(parent,x,y,n,texture)
 local t=parent:CreateTexture(nil,'ARTWORK');t:SetPoint('TOPLEFT',parent,'TOPLEFT',x,-y);t:SetSize(n,n)
 t:SetTexture(texture or 'Interface\\Icons\\INV_Misc_QuestionMark');return t
end
local function btn(parent,label,x,y,w,h,fn)
 local b=CreateFrame('Button',nil,parent,'BackdropTemplate');b:SetPoint('TOPLEFT',parent,'TOPLEFT',x,-y);b:SetSize(w,h)
 b:SetBackdrop({bgFile=FF.media..'ButtonBG.tga',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1,insets={left=1,right=1,top=1,bottom=1}})
 b:SetBackdropColor(.95,.95,.95,1);b:SetBackdropBorderColor(.38,.29,.2,1)
 b.label=text(b,label,6,1,w-12,h-2,11,TEXT,'CENTER')
 b:SetScript('OnClick',fn or function()end)
 b:SetScript('OnEnter',function(self)self:SetBackdropBorderColor(1,.77,.34,1)end)
 b:SetScript('OnLeave',function(self)self:SetBackdropBorderColor(self.selected and 1 or .38,self.selected and .75 or .29,self.selected and .32 or .2,1)end)
 return b
end
local function selected(b,v)
 if not b then return end;b.selected=v==true
 b:SetBackdropBorderColor(v and 1 or .38,v and .75 or .29,v and .32 or .2,1)
 b.label:SetTextColor(unpack(v and GOLD or TEXT))
end
local function section(parent,title,x,y,w,h)
 local f=panel(parent,x,y,w,h);text(f,title,14,9,w-28,22,13,GOLD);line(f,13,38,w-26);return f
end
local function clip(s,n)
 s=tostring(s or '');return #s>n and s:sub(1,n-3)..'...' or s
end
local function hiddenLegacy(fn,self,page)
 local f=CreateFrame('Frame',nil,page);f:SetPoint('TOPLEFT',page,'TOPLEFT',0,0);f:SetSize(652,506)
 local v=fn(self,f);f:Hide();v.legacyContainer=f;return v
end
local function subtab(parent,x,y,w,name,onclick)
 return btn(parent,name,x,y,w,40,onclick)
end
local function premiumLeveling(page)
 local v={root=panel(page,0,0,1116,597)}
 local root=v.root
 local rail=section(root,'QUEST PLANNER',9,9,216,577)
 v.my=subtab(rail,10,49,196,'MY QUESTS',function()FF.char.discoverView=false;FF:Refresh()end)
 v.discover=subtab(rail,10,98,196,'DISCOVER QUESTS',function()FF.char.discoverView=true;FF.char.discoverPage=1;FF:Refresh()end)
 v.browse=subtab(rail,10,147,196,'BROWSE ZONES',function()FF.char.discoverView=true;FF.char.discoverBrowseAll=not FF.char.discoverBrowseAll;FF.char.discoverPage=1;FF:Refresh()end)
 line(rail,12,200,190)
 text(rail,'ROUTING',14,213,190,19,11,GOLD)
 v.pin=subtab(rail,10,244,196,'UNPIN / AUTO',function()FF:UnpinCurrentQuest()end)
 v.route=subtab(rail,10,293,196,'WHY THIS ROUTE?',function()FF:ToggleRouteDetails(true);FF:ShowTab('today')end)
 text(rail,'Pickups are reported data.\nLive quest-log entries are verified by your client.',13,485,189,79,11,DIM,'LEFT',true)
 icon(root,241,14,36,'Interface\\Icons\\INV_Misc_Map_01')
 v.title=text(root,'Questing Flow',288,11,570,32,21,GOLD)
 v.subtitle=text(root,'Accepted quests, pickup discovery and current route.',291,43,690,20,11,DIM)
 v.count=text(root,'',861,13,224,22,12,GOLD,'RIGHT')
 line(root,240,70,858)
 local listing=section(root,'QUESTS  /  PRIORITIZED',240,85,536,443)
 v.rows={}
 for i=1,5 do
  local yy=46+(i-1)*74
  local b=btn(listing,'',11,yy,512,67,function(self)
   if not self.entry then return end
   if FF.char.discoverView then FF:ShowDiscoveryOnMap(self.entry) else FF:ChooseQuest(self.entry.id) end
  end)
  b.icon=icon(b,9,10,31,'Interface\\Icons\\INV_Misc_Map_01')
  b.name=text(b,'',49,5,446,23,13,TEXT)
  b.detail=text(b,'',49,28,450,29,11,DIM)
  v.rows[i]=b
 end
 v.empty=text(listing,'',18,75,499,164,13,DIM,'LEFT',true)
 local actions=section(root,'NEXT ACTION',786,85,310,443)
 v.selectedTitle=text(actions,'',15,51,277,59,17,TEXT,'LEFT',true)
 v.selectedDetail=text(actions,'',15,122,278,108,12,DIM,'LEFT',true)
 line(actions,13,243,282)
 v.actionA=btn(actions,'OPEN MAP / TRACK',12,256,284,36,function()
  local e=v.entry
  if FF.char.discoverView and e then FF:ShowDiscoveryOnMap(e)
  elseif e then FF:ChooseQuest(e.id) else FF:MapAction()end
 end)
 v.actionB=btn(actions,'SAVE / PIN',12,302,284,36,function()
  local e=v.entry;if not e then return end
  if FF.char.discoverView then FF:ToggleSavedDiscovery(e.id) else FF:ChooseQuest(e.id)end
 end)
 v.actionC=btn(actions,'SKIP / NEXT',12,348,284,36,function()
  local e=v.entry;if not e then return end
  if FF.char.discoverView then FF:SkipDiscovery(e.id) else FF:SkipQuest() end
 end)
 v.status=text(actions,'',15,399,274,33,10,GOLD)
 v.prev=btn(root,'< PREVIOUS',239,542,139,38,function()FF.char.discoverPage=math.max(1,(FF.char.discoverPage or 1)-1);FF:Refresh()end)
 v.pagination=text(root,'',401,547,421,26,11,DIM,'CENTER')
 v.next=btn(root,'NEXT PAGE >',958,542,138,38,function()FF.char.discoverPage=(FF.char.discoverPage or 1)+1;FF:Refresh()end)
 return v
end
local function premiumGold(page)
 local v={root=panel(page,0,0,1116,597)};local root=v.root
 local rail=section(root,'YOUR WALLET',9,9,216,577)
 icon(rail,13,52,32,'Interface\\Icons\\INV_Misc_Coin_01')
 v.money=text(rail,'',12,91,190,50,21,TEXT)
 v.target=text(rail,'',12,150,188,75,11,DIM,'LEFT',true)
 line(rail,13,240,190)
 text(rail,'GOLD TARGET',13,251,187,20,12,GOLD)
 v.auto=btn(rail,'AUTO GOAL',10,288,194,38,function()FF.char.goldTarget=0;FF.char.autoGoldTargetCopper=nil;FF:Refresh()end)
 v.plus5=btn(rail,'CURRENT + 5G',10,338,194,38,function()FF.char.goldTarget=math.ceil((FF.snapshot.money or 0)/10000)+5;FF:Refresh()end)
 v.plus20=btn(rail,'CURRENT + 20G',10,388,194,38,function()FF.char.goldTarget=math.ceil((FF.snapshot.money or 0)/10000)+20;FF:Refresh()end)
 v.progress=text(rail,'',12,457,191,65,11,DIM,'LEFT',true)
 icon(root,242,15,36,'Interface\\Icons\\INV_Misc_Coin_02')
 text(root,'Gold & Gathering',291,11,610,34,21,GOLD)
 text(root,'Real session income, bag resources and selected craft materials.',293,44,760,21,11,DIM)
 line(root,239,70,856)
 local income=section(root,'SESSION CASH FLOW',240,85,537,198)
 v.earned=text(income,'',15,51,485,32,17,GREEN)
 v.spent=text(income,'',15,96,485,32,17,RED)
 v.net=text(income,'',15,145,493,28,13,GOLD)
 local gather=section(root,'GATHERING ON YOUR ROUTE',240,295,537,233)
 v.gather=text(gather,'',15,51,496,91,13,TEXT,'LEFT',true)
 v.bags=btn(gather,'OPEN BAGS',13,178,245,38,function()if ToggleAllBags then ToggleAllBags()elseif OpenAllBags then OpenAllBags()end end)
 btn(gather,'PROFESSION FLOW',268,178,255,38,function()FF:ShowTab('skills')end)
 local craft=section(root,'RECIPE MATERIALS',786,85,310,443)
 v.craftTitle=text(craft,'',13,53,279,53,15,TEXT,'LEFT',true)
 v.materialLines={}
 for i=1,5 do v.materialLines[i]=text(craft,'',14,119+(i-1)*42,280,38,11,DIM,'LEFT',true)end
 v.craftStatus=text(craft,'',14,355,282,51,11,GOLD,'LEFT',true)
 btn(root,'OPEN CHARACTER',240,542,221,38,function()FF:ShowTab('character')end)
 btn(root,'VIEW RECIPES',876,542,219,38,function()FF:ShowTab('skills')end)
 return v
end
local function premiumCharacter(page)
 local v={root=panel(page,0,0,1116,597)};local root=v.root
 local rail=section(root,'YOUR CHARACTER',9,9,216,577)
 v.icon=icon(rail,60,58,90,'Interface\\Icons\\Spell_Nature_Lightning')
 v.name=text(rail,'',14,164,189,46,15,TEXT,'CENTER',true)
 v.zone=text(rail,'',13,220,188,55,11,DIM,'CENTER',true)
 v.xp=text(rail,'',13,295,187,34,13,GOLD,'CENTER')
 v.money=text(rail,'',13,345,187,37,13,TEXT,'CENTER')
 v.health=text(rail,'',13,395,187,62,11,DIM,'CENTER',true)
 icon(root,240,15,36,'Interface\\Icons\\INV_Misc_Book_09')
 text(root,'Character Progress',293,12,620,34,21,GOLD)
 text(root,'Training, progression and practical readiness checks.',294,45,726,18,11,DIM)
 line(root,240,71,855)
 local checklist=section(root,'LEVEL-UP CHECKLIST',240,85,537,443)
 v.checks={}
 local names={'REVIEW NEW TALENTS','CHECK CLASS TRAINER ABILITIES','REPAIR & COMPARE EQUIPMENT'}
 for i=1,3 do
  local index=i
  local b=btn(checklist,'',12,52+(i-1)*85,512,73,function()
   FF.char.trainingChecks[index]=not FF.char.trainingChecks[index];FF:Refresh()
  end)
  b.status=text(b,'',13,13,44,42,21,GOLD)
  b.caption=text(b,names[i],66,12,435,22,13,TEXT)
  b.sub=text(b,'',66,38,438,22,11,DIM)
  v.checks[i]=b
 end
 v.questActivity=text(checklist,'',15,333,497,67,11,DIM,'LEFT',true)
 local tips=section(root,'CONTEXT FROM YOUR SESSION',786,85,310,443)
 v.tips={}
 for i=1,3 do v.tips[i]=text(tips,'',13,51+(i-1)*116,277,97,12,TEXT,'LEFT',true)end
 btn(root,'OPEN QUEST PLANNER',240,542,244,38,function()FF:ShowTab('leveling')end)
 btn(root,'VIEW SETTINGS',874,542,222,38,function()FF:ShowTab('settings')end)
 return v
end
local function premiumSettings(page)
 local v={root=panel(page,0,0,1116,597)};local root=v.root
 local rail=section(root,'YOUR EXPERIENCE',9,9,216,577)
 text(rail,'Your interface.\nYour pace.\nYour adventure.',14,60,182,112,18,TEXT,'LEFT',true)
 icon(rail,52,194,90,FF.media..'MinimapIconRound.tga')
 text(rail,'ForeverFlow does not move, fight, loot, buy or sell for you.',15,318,184,121,12,DIM,'LEFT',true)
 icon(root,242,15,36,'Interface\\Icons\\INV_Gizmo_02')
 text(root,'Interface & Automation',293,11,615,34,21,GOLD)
 text(root,'Controls work immediately and are saved per character when appropriate.',293,44,769,21,11,DIM)
 line(root,240,70,855)
 local options=section(root,'DISPLAY & QUEST CONTROLS',240,85,537,443)
 v.rows={}
 local config={
  {'LIVE GUIDE',function()FF:ToggleGuide()end},
  {'MINIMAP BUTTON',function()FF.char.hideMinimap=not FF.char.hideMinimap;FF:Refresh()end},
  {'AUTO-FOLLOW',function()FF:SetAutoFollow(not FF.char.autoFollow)end},
  {'COMPACT GUIDE',function()FF.char.hudMinimal=not FF.char.hudMinimal;FF:SetGuideCollapsed(FF.char.guideCollapsed);FF:Refresh()end},
  {'UNLOCK GUIDE POSITION',function()FF.char.guideLocked=not FF.char.guideLocked;FF:Refresh()end},
  {'LEVEL-UP CHAT TIPS',function()FF.db.quiet=not FF.db.quiet;FF:Refresh()end},
  {'ADVANCED DETAILS',function()FF.db.mode=FF.db.mode=='advanced' and 'simple' or 'advanced';FF:Refresh()end},
 }
 for i,pair in ipairs(config) do
  local b=btn(options,'',11,46+(i-1)*51,515,43,pair[2]);b.title=text(b,pair[1],13,6,349,29,12,TEXT)
  b.status=text(b,'',398,6,102,30,11,GOLD,'RIGHT');v.rows[i]=b
 end
 local tools=section(root,'DISPLAY TOOLS',786,85,310,443)
 v.scale=text(tools,'',15,54,278,35,13,TEXT)
 btn(tools,'CYCLE GUIDE SCALE',13,102,283,41,function()
  local c=FF.char.guideScale or 1;FF:SetGuideScale(c<.95 and 1 or (c<1.1 and 1.2 or .85))
 end)
 btn(tools,'RESET WINDOW POSITIONS',13,163,283,41,function()
  FF.char.posX=0;FF.char.posY=0;FF.char.guideX=-620;FF.char.guideY=170
  FF.window:ClearAllPoints();FF.window:SetPoint('CENTER',UIParent,'CENTER',0,0)
  FF.guide:ClearAllPoints();FF.guide:SetPoint('CENTER',UIParent,'CENTER',-620,170)
 end)
 line(tools,13,224,284)
 text(tools,'KEY COMMANDS',14,237,260,25,12,GOLD)
 text(tools,'/flow  - open dashboard\n/flow discover  - quest pickups\n/flow route  - route explanation\n/flow stats  - session summary',14,273,273,113,12,TEXT,'LEFT',true)
 btn(root,'RETURN TO TODAY',240,542,253,38,function()FF:ShowTab('today')end)
 return v
end
function FF:MakeLeveling(page)
 local v=hiddenLegacy(legacyLeveling,self,page);v.premium=premiumLeveling(page);return v
end
function FF:MakeGold(page)
 local v=hiddenLegacy(legacyGold,self,page);v.premium=premiumGold(page);return v
end
function FF:MakeCharacter(page)
 local v=hiddenLegacy(legacyCharacter,self,page);v.premium=premiumCharacter(page);return v
end
function FF:MakeSettings(page)
 local v=hiddenLegacy(legacySettings,self,page);v.premium=premiumSettings(page);return v
end
function FF:CreateUI()
 oldCreate(self)
 local win=self.window
 -- Keep the 1160x767 studio completely on-screen at common 768p and 900p UI scales.
 -- No change to child coordinates or the saved drag position is needed.
 if UIParent and UIParent.GetWidth and UIParent.GetHeight and win.SetScale then
  local width=UIParent:GetWidth() or 1160
  local height=UIParent:GetHeight() or 767
  local factor=math.min(1,(width-32)/1160,(height-32)/767)
  if factor>0 then win:SetScale(math.max(.6,factor)) end
 end
 if self.premiumInfo then self.premiumInfo:Hide() end
 if self.premiumContexts then for _,p in pairs(self.premiumContexts) do if p and p.Hide then p:Hide()end end end
 for _,page in pairs(self.pages or {}) do
  page:ClearAllPoints();page:SetPoint('TOPLEFT',win,'TOPLEFT',22,-111);page:SetSize(1116,602)
 end
 self:ShowTab(self.char.activeTab or 'today')
end
function FF:ShowTab(name)
 oldShowTab(self,name)
 if self.premiumInfo then self.premiumInfo:Hide() end
end
function FF:UpdatePremiumStudio()
 oldUpdatePremium(self)
 local s=self.snapshot
 if not s or not self.views or not self.char then return end
 local t=self.views.leveling and self.views.leveling.premium
 if t and self.char.activeTab=='leveling' then
  local isDiscover=self.char.discoverView==true
  selected(t.my,not isDiscover);selected(t.discover,isDiscover);selected(t.browse,isDiscover and self.char.discoverBrowseAll)
  t.title:SetText(isDiscover and 'Discover Quests' or 'Your Quest Route')
  t.subtitle:SetText(isDiscover and 'Potential pickups from offline reference data; availability is not guaranteed.' or 'Active objectives reported by your game client.')
  local list={}
  if isDiscover then
   local ok,r=pcall(self.FindDiscoveries,self,s)
   if ok and type(r)=='table' then list=r end
  else list=s.quests or {} end
  local pages=math.max(1,math.ceil(#list/5))
  local page=math.max(1,math.min(pages,tonumber(self.char.discoverPage) or 1));self.char.discoverPage=page
  t.count:SetText(#list..(isDiscover and ' REPORTED PICKUPS' or ' ACCEPTED QUESTS'))
  t.pagination:SetText('PAGE '..page..' / '..pages..'    •    '..#list..' MATCHES')
  t.prev:SetEnabled(page>1);t.next:SetEnabled(page<pages)
  t.empty:SetShown(#list==0)
  t.empty:SetText(isDiscover and 'No documented pickups match your filters. Try Browse Zones or speak to a nearby quest giver.' or 'No quests are visible in your quest log. Pick one up to begin route planning.')
  local picked=nil
  for i,b in ipairs(t.rows) do
   local q=list[(page-1)*5+i];b.entry=q;b:SetShown(q~=nil)
   if q then
    local title=q.title or q.name or ('Quest #'..q.id)
    b.name:SetText(clip(((page-1)*5+i)..'.  '..title,60))
    b.icon:SetTexture(q.done and 'Interface\\Icons\\INV_Misc_Note_02' or 'Interface\\Icons\\INV_Misc_Map_01')
    b.detail:SetText(clip(isDiscover and ((q.nearby and 'LOCAL  •  ' or 'TRAVEL  •  ')..tostring(q.mapName or s.zone)..'  •  '..tostring(q.npc or 'Pickup location unverified')) or (q.firstObjective or (q.done and 'Ready to turn in' or 'In your quest log')),92))
    if not picked then picked=q end
   end
  end
  t.entry=picked
  t.selectedTitle:SetText(picked and clip(picked.title,54) or 'No matching quest')
  t.selectedDetail:SetText(picked and (isDiscover and ('Reported pickup: '..tostring(picked.npc or 'unknown')..'\nZone: '..tostring(picked.mapName or '?')..'\nPrerequisites are unverified.') or (tostring(picked.firstObjective or 'Track this quest through your log.')..'\n'..(picked.done and 'READY TO TURN IN' or 'Accepted in your quest log'))) or 'Change filters or browse other zones to find questing opportunities.')
  t.status:SetText(isDiscover and 'OFFLINE + CLIENT HINTS  •  NOT GUARANTEED' or 'LIVE CLIENT QUEST LOG')
  t.actionB.label:SetText(isDiscover and 'SAVE FOR LATER' or 'PIN THIS QUEST')
  t.actionC.label:SetText(isDiscover and 'SKIP THIS PICKUP' or 'NEXT SUGGESTION')
 end
 local g=self.views.gold and self.views.gold.premium
 if g then
  g.money:SetText(self.MoneyText and self:MoneyText(s.money or 0) or '?')
  local goal=self.char.goldTarget or 0
  local target=goal>0 and goal*10000 or self.char.autoGoldTargetCopper or 0
  g.target:SetText(target>0 and ('Next target: '..self:MoneyText(target)) or 'Automatic goal adjusts as you earn gold.')
  selected(g.auto,goal==0)
  local earned=(s.session and s.session.earned) or 0;local spent=(s.session and s.session.spent) or 0
  g.earned:SetText('EARNED     +'..(self:MoneyText(earned)))
  g.spent:SetText('SPENT       -'..(self:MoneyText(spent)))
  g.net:SetText('NET THIS SESSION    '..self:MoneyText(earned-spent))
  g.gather:SetText((s.goldCategory or 'GATHERING')..'\n\n'..(s.goldTip or 'Gather along your normal quest route.')..'\n\nFree bag slots: '..tostring(s.bagFree or '?')..'  •  Material bag gains: '..tostring(s.session and s.session.materials or 0))
  g.progress:SetText(target>0 and (self:MoneyText(math.max(0,target-(s.money or 0)))..' left to reach your goal') or 'Set a goal to measure your progress.')
  local r=self.RecipeFlowSelected and self:RecipeFlowSelected() or nil
  local missing=self.RecipeFlowShoppingList and self:RecipeFlowShoppingList() or {}
  g.craftTitle:SetText(r and ('SELECTED CRAFT\n'..clip(r.name,31)) or 'OPEN A CRAFT\nSelect a recipe under Skills to plan materials.')
  for i,item in ipairs(g.materialLines) do local e=missing[i];item:SetText(e and ('NEED '..tostring(e.need)..' × '..clip(e.name,28)) or '')end
  g.craftStatus:SetText(r and (#missing==0 and 'Materials ready for one craft, according to last scan.' or 'Ingredient inventory is based on your last profession scan.') or 'Recipes and ingredient costs are never invented.')
 end
 local c=self.views.character and self.views.character.premium
 if c then
  c.name:SetText('LEVEL '..tostring(s.level or '?')..'  '..tostring(s.className or '?'))
  c.zone:SetText(tostring(s.zone or 'Unknown zone'))
  c.xp:SetText(tostring(s.xpPercent and math.floor(s.xpPercent+.5) or '?')..'% TO NEXT LEVEL')
  c.money:SetText(self.MoneyText and self:MoneyText(s.money or 0) or '')
  c.health:SetText('Free bags: '..tostring(s.bagFree or '?')..'\nDurability: '..tostring(s.durability or '?')..'%')
  for i,b in ipairs(c.checks) do local done=self.char.trainingChecks and self.char.trainingChecks[i];b.status:SetText(done and '|cff6ad995✓|r' or '[ ]');b.sub:SetText(done and 'Marked complete for this character' or 'Click to mark complete')end
  c.questActivity:SetText('CURRENT SESSION\nQuest turn-ins: '..tostring(s.session and s.session.questTurns or 0)..'  •  Accepted quests: '..tostring(s.questCount or 0))
  for i,tip in ipairs(c.tips) do tip:SetText(clip(s.tips and s.tips[i] or (i==1 and 'Keep gear repaired, and revisit trainers when new ranks become available.' or ''),130))end
 end
 local o=self.views.settings and self.views.settings.premium
 if o then
  local values={self.guide and self.guide:IsShown(),not self.char.hideMinimap,self.char.autoFollow,self.char.hudMinimal,not self.char.guideLocked,not self.db.quiet,self.db.mode=='advanced'}
  for i,b in ipairs(o.rows) do local on=values[i]==true;b.status:SetText(on and 'ON' or 'OFF');b.status:SetTextColor(unpack(on and GREEN or DIM))end
  o.scale:SetText('Guide size: '..math.floor((self.char.guideScale or 1)*100+.5)..'%')
 end
end