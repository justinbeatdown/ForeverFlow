-- ForeverFlow premium WoW-native workspace. All inventory, skills, icons and
-- recipe content are from live game APIs; no illustrative data is displayed.
local _,FF=...
local oldMakeSkills=FF.MakeSkills
local oldCreateUI=FF.CreateUI
local oldShowTab=FF.ShowTab
local oldUpdateUI=FF.UpdateUI
local gold={.98,.73,.27}; local muted={.68,.65,.58}; local white={.94,.91,.84}
local function fill(frame,bg,edge)
 frame:SetBackdrop({bgFile=FF.media.."PremiumPanel.tga",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1,
  insets={left=1,right=1,top=1,bottom=1}})
 frame:SetBackdropColor(bg or .9,bg or .9,bg or .9,1)
 frame:SetBackdropBorderColor(edge or .25,(edge or .25)*.83,(edge or .25)*.57,1)
end
local function box(parent,x,y,w,h,edge)
 local b=CreateFrame('Frame',nil,parent,'BackdropTemplate')
 b:SetPoint('TOPLEFT',parent,'TOPLEFT',x,-y);b:SetSize(w,h);fill(b,.9,edge)
 return b
end
local function text(parent,s,x,y,w,h,font,color,just)
 local f=parent:CreateFontString(nil,'OVERLAY')
 f:SetFont(STANDARD_TEXT_FONT,font or 12,'')
 f:SetPoint('TOPLEFT',parent,'TOPLEFT',x,-y);f:SetSize(w,h or 21)
 f:SetJustifyH(just or 'LEFT');f:SetJustifyV('MIDDLE')
 f:SetText(s or '');f:SetTextColor(unpack(color or white));return f
end
local function line(parent,x,y,w,a)
 local t=parent:CreateTexture(nil,'ARTWORK');t:SetColorTexture(.75,.49,.17,a or .25)
 t:SetPoint('TOPLEFT',parent,'TOPLEFT',x,-y);t:SetSize(w,1);return t
end
local function btn(parent,caption,x,y,w,h,action)
 local b=CreateFrame('Button',nil,parent,'BackdropTemplate')
 b:SetPoint('TOPLEFT',parent,'TOPLEFT',x,-y);b:SetSize(w,h);fill(b,1,.38)
 b.t=text(b,caption,7,0,w-14,h,11,white,'CENTER')
 b.text=b.t -- legacy tab highlighting expects this field
 b:SetScript('OnClick',action)
 b:SetScript('OnEnter',function(self)
  self:SetBackdropBorderColor(.98,.69,.25,1)
 end)
 b:SetScript('OnLeave',function(self)
  self:SetBackdropBorderColor(self.ffSelected and .99 or .38,self.ffSelected and .71 or .31,self.ffSelected and .21 or .2,1)
 end)
 return b
end
local function selected(b,yes)
 if not b then return end
 b.ffSelected=not not yes
 b:SetBackdropBorderColor(yes and 1 or .38,yes and .72 or .31,yes and .24 or .2,1)
 if b.t then b.t:SetTextColor(yes and 1 or .94,yes and .84 or .91,yes and .48 or .84) end
end
local function image(parent,x,y,n)
 local t=parent:CreateTexture(nil,'ARTWORK')
 t:SetPoint('TOPLEFT',parent,'TOPLEFT',x,-y);t:SetSize(n,n)
 t:SetTexture('Interface\\Icons\\INV_Misc_QuestionMark')
 return t
end
local function cut(s,n)
 s=tostring(s or '')
 if #s>n then return s:sub(1,n-3)..'...' end
 return s
end
local function colorDifficulty(d)
 if d=='optimal' then return '|cffff9d41'
 elseif d=='medium' then return '|cffffff67'
 elseif d=='easy' then return '|cff83df8d'
 elseif d=='trivial' then return '|cff969696' end
 return '|cffc8b89a'
end
function FF:MakePremiumWorkbench(page,v)
 local u={}
 local whole=box(page,0,0,1044,534,.52);whole:SetFrameLevel(page:GetFrameLevel()+22)
 u.root=whole
 text(whole,'PROFESSION FLOW',16,9,280,28,18,gold)
 u.subtitle=text(whole,'Select a profession and inspect actual recipes and reagents from the game.',17,37,760,19,11,muted)
 u.refresh=btn(whole,'REFRESH',797,11,109,30,function() if FF.TryCaptureRecipes then FF:TryCaptureRecipes() end;FF:Refresh() end)
 u.open=btn(whole,'OPEN PROFESSION',915,11,116,30,function()
  if type(ToggleProfessions)=='function' then ToggleProfessions()
  elseif type(ToggleSpellBook)=='function' then ToggleSpellBook('professions')
  else FF:Message('Open Alchemy or another craft directly from your spellbook, then refresh.') end
 end)
 line(whole,13,63,1018,.39)
 -- Fixed content hierarchy: profession rail / real recipe list / reagent inspector.
 local rail=box(whole,12,73,208,406,.37)
 text(rail,'YOUR PROFESSIONS',12,9,180,20,11,gold)
 line(rail,10,31,188,.22)
 u.professions={}
 for i=1,6 do
  local y=38+(i-1)*54
  local b=btn(rail,'',9,y,190,49,function(self)
   FF.char.professionCoachIndex=self.ffProfessionIndex or 1
   FF:Refresh()
  end)
  b.icon=image(b,7,7,31)
  b.title=text(b,'',46,4,134,22,12,white)
  b.rank=text(b,'',46,25,132,18,10,muted)
  u.professions[i]=b
 end
 u.railFooter=text(rail,'Skill ranks come from your character.',12,367,184,27,10,muted)
 local list=box(whole,230,73,470,406,.37)
 text(list,'KNOWN RECIPES',12,9,221,21,12,gold)
 u.listStatus=text(list,'',231,9,228,21,10,muted,'RIGHT')
 line(list,11,35,448,.23)
 u.listEmpty=text(list,'Open a crafting profession window to load your known recipes.',17,71,436,85,13,white)
 u.rows={}
 for i=1,7 do
  local y=43+(i-1)*44
  local b=btn(list,'',9,y,451,41,function(self)
   if self.ffRecipeIndex then
    FF.char.premiumRecipePage=math.floor((self.ffRecipeIndex-1)/7)+1
    FF:RecipeFlowSelect(self.ffRecipeIndex)
   end
  end)
  b.icon=image(b,5,5,31)
  b.title=text(b,'',44,3,267,22,12,white)
  b.detail=text(b,'',44,22,300,16,10,muted)
  b.count=text(b,'',359,8,84,24,11,gold,'RIGHT')
  b:SetScript('OnEnter',function(self)
   self:SetBackdropBorderColor(.98,.69,.25,1)
   local d=FF.recipeFlow
   if d and d.recipes[self.ffRecipeIndex or 0] then FF:RecipeFlowTooltip(self,d.recipes[self.ffRecipeIndex]) end
  end)
  b:SetScript('OnLeave',function(self)
   selected(self,self.ffSelected)
   if GameTooltip then GameTooltip:Hide() end
  end)
  u.rows[i]=b
 end
 u.prev=btn(list,'< PREVIOUS',9,355,116,32,function()
  FF.char.premiumRecipePage=math.max(1,(FF.char.premiumRecipePage or 1)-1);FF:Refresh()
 end)
 u.page=text(list,'',143,357,170,27,11,gold,'CENTER')
 u.next=btn(list,'NEXT >',335,355,125,32,function()
  local d=FF.recipeFlow
  FF.char.premiumRecipePage=math.min(math.max(1,math.ceil((d and #d.recipes or 0)/7)),(FF.char.premiumRecipePage or 1)+1)
  FF:Refresh()
 end)
 local inspect=box(whole,710,73,322,406,.37)
 text(inspect,'SELECTED CRAFT',12,9,290,21,12,gold)
 line(inspect,11,35,300,.23)
 u.icon=image(inspect,12,45,42)
 u.name=text(inspect,'No recipe selected',63,45,249,27,14,white)
 u.difficulty=text(inspect,'',64,73,237,18,11,gold)
 line(inspect,12,97,298,.25)
 text(inspect,'REAGENTS',13,104,199,22,11,gold)
 text(inspect,'HAVE / NEED',214,105,95,20,10,muted,'RIGHT')
 u.ingredients={}
 for i=1,6 do
  local b=btn(inspect,'',10,130+(i-1)*34,303,32,function() end)
  b.icon=image(b,4,4,23)
  b.name=text(b,'',34,3,175,25,11,white)
  b.count=text(b,'',208,3,88,25,11,gold,'RIGHT')
  b:SetScript('OnEnter',function(self)
   self:SetBackdropBorderColor(.98,.69,.25,1)
   local r=FF:RecipeFlowSelected()
   if r and r.reagents[self.ffReagentIndex or 0] then FF:RecipeFlowTooltip(self,r.reagents[self.ffReagentIndex]) end
  end)
  b:SetScript('OnLeave',function(self)
   selected(self,false)
   if GameTooltip then GameTooltip:Hide() end
  end)
  u.ingredients[i]=b
 end
 u.missing=text(inspect,'',12,343,300,52,11,white)
 local flow=box(whole,12,488,1020,37,.44)
 u.flow=text(flow,'',13,4,800,29,12,white)
 u.bags=btn(flow,'BAGS',813,4,88,28,function()
  if type(ToggleAllBags)=='function' then ToggleAllBags()
  elseif type(OpenAllBags)=='function' then OpenAllBags() end
 end)
 u.nextAction=btn(flow,'NEXT CRAFT',910,4,101,28,function()
  local d=FF.recipeFlow
  if d and #d.recipes>0 then FF:RecipeFlowSelect((FF.char.recipeFlowSelected or 1)%#d.recipes+1) end
 end)
 return u
end
function FF:MakeSkills(p)
 local v=oldMakeSkills(self,p)
 v.premium=self:MakePremiumWorkbench(p,v)
 return v
end
function FF:CreateUI()
 oldCreateUI(self)
 local win=self.window
 win:SetSize(1098,785)
 -- Hide the old, cramped vertical navigation entirely. Replace it with a
 -- horizontal, anchored tab row matching the approved concept.
 local originalSide=self.tabButtons.today and self.tabButtons.today:GetParent()
 if originalSide then originalSide:Hide() end
 local oldInfo=self.status and self.status:GetParent()
 if oldInfo then oldInfo:Hide() end
 local nav=box(win,20,96,1058,43,.44)
 self.premiumTabs={}
 local names={{'today','TODAY'},{'leveling','LEVELING'},{'gold','GOLD'},{'skills','SKILLS'},{'character','CHARACTER'},{'settings','SETTINGS'}}
 for i,item in ipairs(names) do
  local b=btn(nav,item[2],9+(i-1)*175,5,165,32,function() FF:ShowTab(item[1]) end)
  self.premiumTabs[item[1]]=b
  self.tabButtons[item[1]]=b
 end
 local strip=box(win,20,147,1058,47,.32)
 self.premiumStatus=text(strip,'',13,7,690,30,14,white)
 self.premiumXP=text(strip,'',736,7,307,30,12,gold,'RIGHT')
 for _,page in pairs(self.pages) do
  page:ClearAllPoints();page:SetPoint('TOPLEFT',win,'TOPLEFT',27,-205)
  page:SetSize(1044,536)
 end
 -- A utility inspector makes the existing Today, Leveling and Gold content
 -- readable at the wider size without inventing information or fake charts.
 self.premiumContext={}
 for _,tab in ipairs({'today','leveling','gold','character','settings'}) do
  local p=self.pages[tab]
  local rail=box(p,650,9,380,490,.34)
  text(rail,tab=='gold' and 'CRAFTING & MATERIALS' or 'LIVE CHARACTER CONTEXT',14,14,348,22,12,gold)
  line(rail,13,40,354,.24)
  local a=text(rail,'',14,56,352,51,14,white)
  local b=text(rail,'',14,118,352,77,12,muted)
  line(rail,13,208,354,.19)
  local c=text(rail,'',14,219,352,108,12,white)
  local q=btn(rail,tab=='gold' and 'PROFESSION FLOW' or 'OPEN PROFESSION FLOW',14,390,351,36,function()
   FF:ShowTab('skills');if FF.TryCaptureRecipes then FF:TryCaptureRecipes() end
  end)
  self.premiumContext[tab]={a=a,b=b,c=c,button=q}
 end
 -- Original header logo is preserved, but the title/sidebar no longer compete.
 local baseRule=box(win,20,750,1058,23,.25)
 text(baseRule,'FOREVERFLOW   /   QUEST  •  CRAFT  •  GATHER',11,1,680,21,10,muted)
 text(baseRule,'WoW FOREVER  /  0.5.6 BETA',772,1,272,21,10,muted,'RIGHT')
 self:ShowTab(self.char.activeTab or 'today')
end
function FF:ShowTab(name)
 oldShowTab(self,name)
 if self.premiumTabs then
  for tab,b in pairs(self.premiumTabs) do selected(b,tab==name) end
 end
 -- When Skills is selected, show the real profession workspace by default.
 if name=='skills' and self.views and self.views.skills and self.views.skills.premium then
  self.views.skills.premium.root:Show()
  if self.TryCaptureRecipes and not (self.recipeFlow and self.recipeFlow.count>0) then
   self:TryCaptureRecipes()
  end
 end
end
function FF:UpdatePremium()
 if not self.snapshot or not self.views then return end
 local s=self.snapshot
 if self.premiumStatus then
  self.premiumStatus:SetText(('LEVEL %s   /   %s   /   %s'):format(tostring(s.level or '?'),tostring(s.className or '?'),tostring(s.zone or 'Unknown')))
 end
 if self.premiumXP then
  local xp=(tonumber(s.xp) or 0);local max=tonumber(s.xpMax) or 0
  self.premiumXP:SetText(max>0 and ('%d%% to next level'):format(math.floor(xp*100/max+.5)) or 'Level progress unavailable')
 end
 if self.premiumContext then
  for tab,k in pairs(self.premiumContext) do
   k.a:SetText(('Level %s %s\n%s'):format(s.level or '?',s.className or '',s.zone or ''))
   k.b:SetText(('Bags: %s free   |   Durability: %s\nSession: %s gold net'):format(
      tostring(s.bagFree or '?'),tostring(s.durability or '?'),
      self.MoneyText and self:MoneyText((s.session and s.session.earned or 0)-(s.session and s.session.spent or 0),true) or '?'))
   local r=self.RecipeFlowSelected and self:RecipeFlowSelected()
   if r then
    local missing=self.RecipeFlowShoppingList and self:RecipeFlowShoppingList() or {}
    if #missing>0 then
     local list={}
     for i=1,math.min(4,#missing) do list[#list+1]=missing[i].need..'x '..missing[i].name end
     k.c:SetText('SELECTED RECIPE: '..cut(r.name,36)..'\nMissing materials:\n'..table.concat(list,'\n'))
    else k.c:SetText('SELECTED RECIPE: '..cut(r.name,36)..'\nMaterials ready based on last profession scan.') end
   else
    k.c:SetText('PROFESSION FLOW\nOpen a real crafting window and check recipes and materials alongside questing.')
   end
  end
 end
 local v=self.views.skills
 if not v or not v.premium then return end
 local u=v.premium
 local all={}
 for _,p in ipairs(s.professions and s.professions.primary or {}) do all[#all+1]=p end
 for _,p in ipairs(s.professions and s.professions.secondary or {}) do all[#all+1]=p end
 local chosen=math.max(1,math.min(#all,tonumber(self.char.professionCoachIndex) or 1))
 for i,b in ipairs(u.professions) do
  local p=all[i]
  b.ffProfessionIndex=i
  b:SetShown(p~=nil)
  if p then
   b.title:SetText(cut(p.name,17))
   b.rank:SetText((p.skill or '?')..' / '..(p.cap or '?'))
   local name=type(p.name)=='string' and p.name:lower() or ''
   local native=name:find('herb') and 'Interface\\Icons\\INV_Misc_Herb_11' or
    name:find('alchem') and 'Interface\\Icons\\Trade_Alchemy' or
    name:find('cook') and 'Interface\\Icons\\INV_Misc_Food_15' or
    name:find('fish') and 'Interface\\Icons\\Trade_Fishing' or
    name:find('first aid') and 'Interface\\Icons\\Spell_Holy_SealOfSacrifice' or
    'Interface\\Icons\\INV_Misc_QuestionMark'
   b.icon:SetTexture(native)
   selected(b,i==chosen)
  end
 end
 local d=self.recipeFlow
 u.subtitle:SetText(d and ('Observed: '..cut(d.name,30)..'   |   '..#d.recipes..' real client recipes   |   '..d.source..' API') or
  (self.recipeFlowStatus or 'Open your profession crafting window; its real recipes will appear here.'))
 local page=math.max(1,tonumber(self.char.premiumRecipePage) or 1)
 local pages=math.max(1,math.ceil((d and #d.recipes or 0)/7))
 if page>pages then page=pages;self.char.premiumRecipePage=pages end
 u.listStatus:SetText(d and (#d.recipes..' RECIPES') or 'AWAITING DATA')
 u.listEmpty:SetShown(not d or #d.recipes==0)
 if not d then
  u.listEmpty:SetText((self.recipeFlowStatus or 'Open the game profession UI to read known recipes.')..'\n\nRefresh after selecting a profession in the game. No recipes are fabricated.')
 end
 for i,b in ipairs(u.rows) do
  local idx=(page-1)*7+i
  local r=d and d.recipes[idx]
  b.ffRecipeIndex=r and idx or nil
  b:SetShown(r~=nil)
  if r then
   b.icon:SetTexture(r.texture or (r.id and GetItemIcon and GetItemIcon(r.id)) or 'Interface\\Icons\\INV_Misc_QuestionMark')
   b.title:SetText(colorDifficulty(r.difficulty)..cut(r.name,37)..'|r')
   b.detail:SetText((r.difficulty or 'unknown'):upper()..'  /  '..tostring(#r.reagents)..' ingredients')
   b.count:SetText((r.available or 0)..' craftable')
   selected(b,idx==(self.char.recipeFlowSelected or 1))
  end
 end
 u.page:SetText(page..' / '..pages)
 u.prev:SetEnabled(page>1);u.next:SetEnabled(page<pages)
 local r=self.RecipeFlowSelected and self:RecipeFlowSelected()
 u.name:SetText(r and cut(r.name,32) or 'Select a recipe')
 u.difficulty:SetText(r and (tostring(r.difficulty or 'unknown'):upper()..'  /  '..tostring(r.available or 0)..' craftable') or 'No live recipe selected')
 u.icon:SetTexture(r and (r.texture or (r.id and GetItemIcon and GetItemIcon(r.id))) or 'Interface\\Icons\\INV_Misc_QuestionMark')
 local missing={}
 for i,b in ipairs(u.ingredients) do
  local re=r and r.reagents[i]
  b.ffReagentIndex=re and i or nil
  b:SetShown(re~=nil)
  if re then
   b.name:SetText(cut(re.name,26))
   b.count:SetText((re.missing>0 and '|cffff796a' or '|cff85e19b')..re.owned..' / '..re.need..'|r')
   b.icon:SetTexture(re.texture or (re.id and GetItemIcon and GetItemIcon(re.id)) or 'Interface\\Icons\\INV_Misc_QuestionMark')
   if re.missing>0 then missing[#missing+1]=re.missing..'x '..re.name end
  end
 end
 u.missing:SetText(not r and 'Open a crafting window and refresh to load real recipes.' or
  (#missing>0 and ('MISSING: '..cut(table.concat(missing,', '),93)) or 'Materials available for one craft (last scan).'))
 u.flow:SetText(not r and 'NEXT: Open Alchemy or another craft in the game, then refresh.' or
  (#missing>0 and ('NEXT: Collect '..cut(missing[1],54)) or ('READY: '..cut(r.name,50)..'  /  Craft using the game profession window.')))
end
function FF:UpdateUI()
 oldUpdateUI(self)
 self:UpdatePremium()
end
