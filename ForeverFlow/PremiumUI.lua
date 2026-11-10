-- ForeverFlow 0.5.6 Beta 8: one production UI shell and profession workbench.
-- Gameplay values and item textures are read from the client; no fabricated
-- prices, recipes, material locations, or estimated skill-up counts.
local _,FF=...
local unpack=unpack or table.unpack
local legacyToday=FF.MakeToday
local legacySkills=FF.MakeSkills
local legacyCreate=FF.CreateUI
local legacyTab=FF.ShowTab
local legacyUpdate=FF.UpdateUI
local GOLD={1,.78,.37}; local TEXT={.94,.91,.84}; local MUTED={.66,.63,.58}
local GREEN={.50,.88,.53}; local RED={1,.49,.39}
local function safe(fn,...)
 if type(fn)~='function' then return nil end
 local ok,a,b=pcall(fn,...); if ok then return a,b end
end
local function trim(s,n)
 s=tostring(s or '')
 if #s>n then return s:sub(1,n-3)..'...' end
 return s
end
local function surface(parent,x,y,w,h,edge,texture)
 local f=CreateFrame('Frame',nil,parent,'BackdropTemplate')
 f:SetPoint('TOPLEFT',parent,'TOPLEFT',x,-y);f:SetSize(w,h)
 f:SetBackdrop({bgFile=FF.media..(texture or 'PremiumPanel.tga'),edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1,
  insets={left=1,right=1,top=1,bottom=1}})
 f:SetBackdropColor(.92,.92,.92,.98)
 f:SetBackdropBorderColor(edge or .29,(edge or .29)*.79,(edge or .29)*.54,1)
 return f
end
local function label(parent,content,x,y,w,h,size,color,just)
 local s=parent:CreateFontString(nil,'OVERLAY')
 s:SetFont(STANDARD_TEXT_FONT,size or 12,'')
 s:SetPoint('TOPLEFT',parent,'TOPLEFT',x,-y);s:SetSize(w,h or 19)
 s:SetJustifyH(just or 'LEFT');s:SetJustifyV('MIDDLE');s:SetWordWrap(false)
 s:SetText(content or '');s:SetTextColor(unpack(color or TEXT))
 return s
end
local function sep(parent,x,y,w,a)
 local t=parent:CreateTexture(nil,'ARTWORK');t:SetColorTexture(.83,.57,.24,a or .28)
 t:SetPoint('TOPLEFT',parent,'TOPLEFT',x,-y);t:SetSize(w,1);return t
end
local function art(parent,x,y,n,file)
 local t=parent:CreateTexture(nil,'ARTWORK');t:SetPoint('TOPLEFT',parent,'TOPLEFT',x,-y)
 t:SetSize(n,n);t:SetTexture(file or 'Interface\\Icons\\INV_Misc_QuestionMark');return t
end
local function button(parent,name,x,y,w,h,onClick)
 local b=CreateFrame('Button',nil,parent,'BackdropTemplate')
 b:SetPoint('TOPLEFT',parent,'TOPLEFT',x,-y);b:SetSize(w,h)
 b:SetBackdrop({bgFile=FF.media..'ButtonBG.tga',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1,
  insets={left=1,right=1,top=1,bottom=1}})
 b:SetBackdropColor(.9,.9,.9,1);b:SetBackdropBorderColor(.32,.28,.23,1)
 b.caption=label(b,name,7,1,w-14,h-2,11,TEXT,'CENTER');b.text=b.caption
 b:SetScript('OnClick',onClick or function() end)
 b:SetScript('OnEnter',function(self)self:SetBackdropBorderColor(.99,.75,.3,1)end)
 b:SetScript('OnLeave',function(self)
  if self.ffOn then self:SetBackdropBorderColor(1,.72,.22,1)
  else self:SetBackdropBorderColor(.32,.28,.23,1) end
 end)
 return b
end
local function active(b,yes)
 if not b then return end
 b.ffOn=not not yes
 b:SetBackdropBorderColor(yes and 1 or .35,yes and .72 or .29,yes and .22 or .20,1)
 if b.caption then b.caption:SetTextColor(unpack(yes and GOLD or TEXT)) end
end
local function colorDifficulty(s)
 s=tostring(s or ''):lower()
 if s=='optimal' then return '|cffffa240'
 elseif s=='medium' then return '|cffffff61'
 elseif s=='easy' then return '|cff7fe290'
 elseif s=='trivial' then return '|cff999999' end
 return '|cffe8d2aa'
end
local function tooltip(owner,entry)
 if FF.RecipeFlowTooltip then FF:RecipeFlowTooltip(owner,entry) end
end
local function profIcon(p)
 local name=(p and p.name or ''):lower()
 if name:find('herb',1,true) then return 'Interface\\Icons\\INV_Misc_Herb_11'
 elseif name:find('alchem',1,true) then return 'Interface\\Icons\\Trade_Alchemy'
 elseif name:find('cook',1,true) then return 'Interface\\Icons\\INV_Misc_Food_15'
 elseif name:find('first aid',1,true) then return 'Interface\\Icons\\Spell_Holy_SealOfSacrifice'
 elseif name:find('fish',1,true) then return 'Interface\\Icons\\Trade_Fishing'
 elseif name:find('mining',1,true) then return 'Interface\\Icons\\Trade_Mining'
 elseif name:find('skin',1,true) then return 'Interface\\Icons\\INV_Misc_Pelt_Wolf_01'
 elseif name:find('enchant',1,true) then return 'Interface\\Icons\\Trade_Engraving'
 elseif name:find('tailor',1,true) then return 'Interface\\Icons\\Trade_Tailoring'
 elseif name:find('leather',1,true) then return 'Interface\\Icons\\Trade_LeatherWorking'
 elseif name:find('engineering',1,true) then return 'Interface\\Icons\\Trade_Engineering'
 elseif name:find('smith',1,true) then return 'Interface\\Icons\\Trade_BlackSmithing' end
 return 'Interface\\Icons\\INV_Misc_QuestionMark'
end
local function bar(parent,x,y,w,h)
 local bg=surface(parent,x,y,w,h,.22,'ButtonBG.tga')
 local fill=bg:CreateTexture(nil,'ARTWORK')
 fill:SetTexture(FF.media..'GoldButtonBG.tga')
 fill:SetPoint('TOPLEFT',bg,'TOPLEFT',1,-1)
 fill:SetSize(1,h-2)
 return function(v)fill:SetWidth(math.max(1,(w-2)*math.max(0,math.min(1,v or 0))))end
end

function FF:MakePremiumWorkbench(page)
 local root=surface(page,0,0,1116,597,.44)
 root:SetFrameLevel(page:GetFrameLevel()+30)
 local u={root=root}
 -- Real three-column studio: professions | known recipes | selected craft.
 local rail=surface(root,9,9,216,577,.35)
 label(rail,'PROFESSIONS',14,9,188,25,15,GOLD)
 sep(rail,12,36,190,.39)
 u.prof={}
 for i=1,7 do
  local b=button(rail,'',9,43+(i-1)*66,198,59,function(self)
   if FF.char then FF.char.professionCoachIndex=self.ffIndex or 1 end
   if FF.TryCaptureRecipes then FF:TryCaptureRecipes() end
   FF:Refresh()
  end)
  b.icon=art(b,8,8,36)
  b.name=label(b,'',52,5,135,23,12,TEXT)
  b.skill=label(b,'',52,27,131,18,10,MUTED)
  b.progress=bar(b,53,49,126,5)
  u.prof[i]=b
 end
 u.railHelp=label(rail,'Select a profession. Open its crafting window to read recipes.',12,516,187,49,10,MUTED)
 -- Main profession header: same information hierarchy as approved rendering.
 u.profIcon=art(root,243,15,38,'Interface\\Icons\\Trade_Alchemy')
 u.header=label(root,'Profession Flow',293,10,490,34,21,GOLD)
 u.subheader=label(root,'Your next craft, materials, and practical next step.',294,44,572,20,11,MUTED)
 u.skill=label(root,'',857,11,229,20,12,TEXT,'RIGHT')
 u.skillBar=bar(root,859,38,226,12)
 sep(root,238,70,859,.42)
 -- Recipe mode controls are actual filters, not inert decoration.
 u.best=button(root,'BEST SKILL-UPS',241,79,163,31,function()
  FF.char.premiumFilter='best';FF.char.premiumRecipePage=1;FF:Refresh()
 end)
 u.all=button(root,'ALL RECIPES',411,79,143,31,function()
  FF.char.premiumFilter='all';FF.char.premiumRecipePage=1;FF:Refresh()
 end)
 u.mat=button(root,'NEED MATERIALS',562,79,151,31,function()
  FF.char.premiumFilter='missing';FF.char.premiumRecipePage=1;FF:Refresh()
 end)
 u.refresh=button(root,'REFRESH',1002,79,93,31,function()
  if FF.TryCaptureRecipes then FF:TryCaptureRecipes() end
  FF:Refresh()
 end)
 local list=surface(root,239,119,537,287,.35)
 label(list,'RECIPE',13,8,236,20,11,GOLD)
 label(list,'SKILL',277,8,71,20,10,MUTED,'RIGHT')
 label(list,'CRAFTABLE',367,8,155,20,10,MUTED,'RIGHT')
 sep(list,11,32,515,.32)
 u.recipes={}
 for i=1,6 do
  local b=button(list,'',11,38+(i-1)*36,514,33,function(self)
   if self.ffRecipeIndex then FF:RecipeFlowSelect(self.ffRecipeIndex) end
  end)
  b.icon=art(b,4,3,27)
  b.name=label(b,'',38,1,232,30,12,TEXT)
  b.diff=label(b,'',271,1,100,30,11,GOLD,'RIGHT')
  b.count=label(b,'',388,1,117,30,11,TEXT,'RIGHT')
  b:SetScript('OnEnter',function(self)
   self:SetBackdropBorderColor(1,.75,.25,1)
   local d=FF.recipeFlow
   if d and d.recipes[self.ffRecipeIndex or 0] then tooltip(self,d.recipes[self.ffRecipeIndex]) end
  end)
  b:SetScript('OnLeave',function(self)
   active(self,self.ffOn)
   if GameTooltip then GameTooltip:Hide() end
  end)
  u.recipes[i]=b
 end
 u.empty=label(list,'Open Alchemy or another craft window in the game to load your known recipes.',20,56,493,103,13,TEXT)
 u.prev=button(list,'<',12,258,57,25,function()
  FF.char.premiumRecipePage=math.max(1,(FF.char.premiumRecipePage or 1)-1);FF:Refresh()
 end)
 u.page=label(list,'',170,258,192,25,11,MUTED,'CENTER')
 u.next=button(list,'>',454,258,70,25,function()
  FF.char.premiumRecipePage=(FF.char.premiumRecipePage or 1)+1;FF:Refresh()
 end)
 local detail=surface(root,786,119,310,287,.35)
 label(detail,'SELECTED RECIPE',12,8,280,22,11,GOLD)
 sep(detail,11,31,288,.32)
 u.itemIcon=art(detail,12,39,43)
 u.item=label(detail,'Select a recipe',64,37,235,29,14,TEXT)
 u.difficulty=label(detail,'',64,65,233,19,11,MUTED)
 sep(detail,11,94,288,.28)
 label(detail,'REAGENTS',11,99,157,23,11,GOLD)
 label(detail,'HAVE / NEED',202,99,96,23,10,MUTED,'RIGHT')
 u.reagents={}
 for i=1,4 do
  local b=button(detail,'',10,124+(i-1)*30,289,28,function()end)
  b.icon=art(b,4,3,22)
  b.name=label(b,'',31,2,168,23,11,TEXT)
  b.count=label(b,'',201,2,81,23,11,GOLD,'RIGHT')
  b:SetScript('OnEnter',function(self)
   self:SetBackdropBorderColor(1,.75,.25,1)
   local r=FF:RecipeFlowSelected()
   if r and r.reagents[self.ffIndex or 0] then tooltip(self,r.reagents[self.ffIndex]) end
  end)
  b:SetScript('OnLeave',function(self)
   active(self,false)
   if GameTooltip then GameTooltip:Hide() end
  end)
  u.reagents[i]=b
 end
 u.missing=label(detail,'',12,248,286,31,11,RED)
 -- Action flow is no longer a one-line advice string.
 local steps=surface(root,239,416,537,113,.38)
 label(steps,'YOUR PROFESSION FLOW',13,7,480,24,13,GOLD)
 sep(steps,11,31,514,.32)
 u.steps={}
 for i=1,3 do
  local y=34+(i-1)*25
  local badge=surface(steps,13,y+2,19,19,.45,'GoldButtonBG.tga')
  label(badge,tostring(i),0,0,19,19,11,GOLD,'CENTER')
  u.steps[i]=label(steps,'',44,y,477,23,11,TEXT)
 end
 local results=surface(root,786,416,310,113,.38)
 label(results,'CRAFTING STATUS',12,7,288,24,13,GOLD)
 sep(results,11,31,288,.32)
 u.result1=label(results,'',13,37,283,20,11,TEXT)
 u.result2=label(results,'',13,60,283,20,11,MUTED)
 u.result3=label(results,'',13,84,283,20,11,GOLD)
 u.back=button(root,'OPEN PROFESSION',240,544,157,39,function()
  if type(ToggleProfessions)=='function' then ToggleProfessions()
  elseif type(ToggleSpellBook)=='function' then ToggleSpellBook('professions')
  else FF:Message('Open the relevant profession from your spellbook, then use Refresh.') end
 end)
 u.track=button(root,'TRACK MATERIALS',557,544,174,39,function()
  local missing=FF.RecipeFlowShoppingList and FF:RecipeFlowShoppingList() or {}
  local recipe=FF.RecipeFlowSelected and FF:RecipeFlowSelected()
  if recipe and FF.char then FF.char.trackedRecipeName=recipe.name end
  if #missing==0 then FF:Message('Recipe selected. Materials available for the current craft.')
  else
   local parts={}
   for i=1,math.min(5,#missing) do parts[#parts+1]=missing[i].need..' '..missing[i].name end
   FF:Message('Materials to acquire: '..table.concat(parts,', '))
  end
 end)
 u.bags=button(root,'OPEN BAGS',740,544,144,39,function()
  if type(ToggleAllBags)=='function' then ToggleAllBags()
  elseif type(OpenAllBags)=='function' then OpenAllBags() end
 end)
 u.nextCraft=button(root,'NEXT RECIPE >',895,544,200,39,function()
  local d=FF.recipeFlow
  if d and #d.recipes>0 then FF:RecipeFlowSelect(((FF.char.recipeFlowSelected or 1)%#d.recipes)+1) end
 end)
 return u
end

-- The Today page is now a first-class handcrafted studio as well.  Retain
-- the original data-bound controls in an unseen container for compatibility,
-- rather than overlaying the old dashboard under a cosmetic frame.
function FF:MakePremiumToday(page)
 local root=surface(page,0,0,1116,597,.38,'WindowBG.tga')
 root:SetFrameLevel(page:GetFrameLevel()+30)
 local u={root=root}
 -- A quick-action rail mirrors the profession navigator: one consistent
 -- information hierarchy throughout the addon.
 local rail=surface(root,9,9,215,577,.34)
 label(rail,'YOUR ADVENTURE',15,12,188,24,15,GOLD)
 sep(rail,12,40,190,.42)
 u.now=button(rail,'CURRENT QUEST',10,54,195,57,function()FF:TrackQuest()end)
 u.map=button(rail,'QUEST MAP',10,120,195,57,function()FF:MapAction()end)
 u.next=button(rail,'NEXT SUGGESTION',10,186,195,57,function()FF:SkipQuest()end)
 sep(rail,12,263,190,.27)
 label(rail,'PLAYSTYLE',15,274,180,24,12,GOLD)
 u.priority={}
 for i,item in ipairs({{'balanced','BALANCED'},{'level','FAST LEVELING'},{'gold','MORE GOLD'}}) do
  u.priority[item[1]]=button(rail,item[2],10,309+(i-1)*44,195,37,function()FF:SetPriority(item[1])end)
 end
 label(rail,'Live recommendations; you control every action.',15,490,185,67,11,MUTED)
 -- Hero and action panels use WoW-style gold hairline separators, not
 -- large unrelated cards or text-only filler.
 u.icon=art(root,246,19,38,'Interface\\Icons\\INV_Misc_Map_01')
 label(root,'TODAY  /  YOUR NEXT BEST ACTION',291,15,520,25,19,GOLD)
 u.zone=label(root,'',293,44,635,23,12,MUTED)
 u.xp=label(root,'',902,16,180,22,12,GOLD,'RIGHT')
 u.xpBar=bar(root,866,47,224,11)
 sep(root,240,72,855,.45)
 local hero=surface(root,240,85,552,239,.40)
 label(hero,'CURRENT QUEST',16,12,512,21,12,GOLD)
 sep(hero,13,39,525,.30)
 u.kind=label(hero,'',17,49,500,22,12,MUTED)
 u.title=label(hero,'',16,77,508,35,23,TEXT)
 u.progress=label(hero,'',17,121,495,25,13,TEXT)
 u.where=label(hero,'',17,149,510,36,11,MUTED)
 u.reason=label(hero,'',17,191,512,38,11,GOLD)
 local info=surface(root,802,85,294,239,.38)
 label(info,'CHARACTER STATUS',14,12,270,22,13,GOLD)
 sep(info,13,40,268,.31)
 u.character=label(info,'',16,54,263,33,15,TEXT)
 u.questCount=label(info,'',16,99,264,28,12,TEXT)
 u.bags=label(info,'',16,132,263,27,12,TEXT)
 u.durability=label(info,'',16,165,260,26,12,TEXT)
 u.money=label(info,'',16,198,261,26,12,GOLD)
 local route=surface(root,240,336,552,193,.37)
 label(route,'YOUR ROUTE  /  WHAT COMES NEXT',15,11,524,24,14,GOLD)
 sep(route,13,40,526,.30)
 u.route=label(route,'',16,53,519,59,13,TEXT)
 u.after=label(route,'',16,114,516,39,11,MUTED)
 u.pickups=button(route,'FIND PICKUPS',13,155,174,30,function()FF:OpenRouteDiscovery()end)
 u.why=button(route,'WHY THIS ROUTE?',195,155,168,30,function()FF:ToggleRouteDetails()end)
 u.skills=button(route,'PROFESSIONS',371,155,168,30,function()FF:ShowTab('skills')end)
 local materials=surface(root,802,336,294,193,.37)
 label(materials,'YOUR NEXT GAIN',14,11,260,24,14,GOLD)
 sep(materials,13,40,267,.30)
 u.material=label(materials,'',15,52,261,93,12,TEXT)
 button(materials,'OPEN GOLD & MATERIALS',13,154,267,30,function()FF:ShowTab('gold')end)
 u.footer=label(root,'REAL QUESTS   •   REAL ITEMS   •   NO AUTOMATED GAMEPLAY',243,546,845,25,11,MUTED)
 return u
end
function FF:MakeToday(page)
 local hidden=CreateFrame('Frame',nil,page)
 hidden:SetPoint('TOPLEFT',page,'TOPLEFT',0,0);hidden:SetSize(652,506)
 local v=legacyToday(self,hidden)
 hidden:Hide();v.legacyContainer=hidden
 v.premium=self:MakePremiumToday(page)
 return v
end

function FF:MakeSkills(page)
 -- Legacy UI.lua still needs its skill controls for its data bindings. Build
 -- them in an invisible sibling container rather than under the visible page;
 -- the premium studio is the ONE interactive Skills UI.
 local hidden=CreateFrame('Frame',nil,page)
 hidden:SetPoint('TOPLEFT',page,'TOPLEFT',0,0)
 hidden:SetSize(652,506)
 local v=legacySkills(self,hidden)
 hidden:Hide()
 v.legacyContainer=hidden
 v.premium=self:MakePremiumWorkbench(page)
 return v
end

-- Beta 10: a single, native frame tree. No legacy window or chrome is created.
-- The invisible compatibility views provide data bindings only; no hidden
-- graphical layer can bleed through the premium layout.
function FF:CreateUI()
 if self.window then return end
 local win=CreateFrame('Frame',nil,UIParent,'BackdropTemplate')
 win:SetSize(1160,767)
 win:SetPoint('CENTER',UIParent,'CENTER',self.char.posX or 0,self.char.posY or 0)
 win:SetFrameStrata('DIALOG')
 win:SetClampedToScreen(true)
 win:SetMovable(true)
 win:EnableMouse(true)
 win:RegisterForDrag('LeftButton')
 win:SetBackdrop({bgFile=FF.media..'WindowBG.tga',
  edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=2,
  insets={left=2,right=2,top=2,bottom=2}})
 win:SetBackdropColor(.94,.94,.94,1)
 win:SetBackdropBorderColor(.76,.49,.17,1)
 win:SetScript('OnDragStart',function(self)
  if not FF.char.locked then self:StartMoving() end
 end)
 win:SetScript('OnDragStop',function(self)
  self:StopMovingOrSizing()
  FF:SavePosition(self,'main')
 end)
 self.window=win
 self.legacyChrome=nil
 self.premiumBase=nil
 self.premiumContexts=nil

 -- Legacy view references live in an invisible, offscreen data-only parent.
 -- This is not a second window and cannot draw over the game UI.
 local compatibility=CreateFrame('Frame',nil,win)
 compatibility:SetSize(652,506)
 compatibility:SetPoint('TOPLEFT',win,'TOPLEFT',0,0)
 compatibility:Hide()
 self.compatibility=compatibility
 self.status=label(compatibility,'',0,0,500,20,12,TEXT)
 self.xpText=label(compatibility,'',0,20,200,20,11,MUTED)
 self.xp=function()end

 -- The approved art direction has ONE header, ONE content surface, ONE footer.
 local header=surface(win,9,9,1142,75,.57,'WindowBG.tga')
 header:SetFrameLevel(win:GetFrameLevel()+2)
 art(header,12,11,50,FF.media..'MinimapIconRound.tga')
 local wordmark=header:CreateTexture(nil,'ARTWORK')
 wordmark:SetTexture(FF.media..'HeaderWordmark.tga')
 wordmark:SetPoint('TOPLEFT',header,'TOPLEFT',72,-8)
 wordmark:SetSize(233,49)
 label(header,'SMART LEVELING + GOLD',76,53,235,16,10,GOLD)
 self.premiumTabs={}
 self.tabButtons={}
 local nav={{'today','TODAY'},{'leveling','LEVELING'},
            {'gold','GOLD'},{'skills','SKILLS'},
            {'character','CHARACTER'},{'settings','SETTINGS'}}
 for i,entry in ipairs(nav) do
  local b=button(header,entry[2],329+(i-1)*127,24,119,36,
   function() FF:ShowTab(entry[1]) end)
  self.premiumTabs[entry[1]]=b
  self.tabButtons[entry[1]]=b
 end
 self.premiumClose=button(header,'X',1110,7,23,23,
  function()FF:Toggle()end)

 self.pages={}
 self.views={}
 for _,tab in ipairs(nav) do
  local name=tab[1]
  local page=CreateFrame('Frame',nil,win)
  page:SetPoint('TOPLEFT',win,'TOPLEFT',22,-96)
  page:SetSize(1116,602)
  self.pages[name]=page
 end
 -- Each Make* constructor builds exactly one visible premium page. Any older
 -- controls needed by UpdateUI are parented to hidden compatibility children.
 self.views.today=self:MakeToday(self.pages.today)
 self.views.leveling=self:MakeLeveling(self.pages.leveling)
 self.views.gold=self:MakeGold(self.pages.gold)
 self.views.skills=self:MakeSkills(self.pages.skills)
 self.views.character=self:MakeCharacter(self.pages.character)
 self.views.settings=self:MakeSettings(self.pages.settings)

 local bottom=surface(win,9,709,1142,43,.28,'WindowBG.tga')
 bottom:SetFrameLevel(win:GetFrameLevel()+2)
 label(bottom,'FOREVERFLOW   •   YOU PLAY, WE GUIDE',15,12,600,22,10,MUTED)
 self.premiumVersion=label(bottom,
  'WoW FOREVER  /  '..tostring(self.version or 'development'),
  832,12,291,22,10,MUTED,'RIGHT')
 -- Live guide and minimap remain independent game UI elements, not overlays
 -- on the main workbench.
 self:CreateGuide()
 self:CreateMinimapButton()
 self:ShowTab(self.pages[self.char.activeTab] and self.char.activeTab or 'today')
 win:SetShown(self.char.visible==true)
 self:Refresh()
end

function FF:ShowTab(name)
 legacyTab(self,name)
 if self.premiumTabs then
  for tab,b in pairs(self.premiumTabs) do active(b,tab==name) end
 end
 if self.premiumInfo then self.premiumInfo:SetShown(name~='skills' and name~='today') end
 if name=='skills' and self.TryCaptureRecipes and not (self.recipeFlow and #self.recipeFlow.recipes>0) then
  -- Game-side API may not have loaded a profession; this is an attempt, not a promise.
  self:TryCaptureRecipes()
 end
end

function FF:UpdatePremiumStudio()
 if not self.snapshot or not self.views then return end
 local s=self.snapshot
 if self.premiumCharacter then
  self.premiumCharacter:SetText(('LEVEL %s     %s     •     %s'):format(tostring(s.level or '?'),tostring(s.className or '?'),tostring(s.zone or '?')))
 end
 if self.premiumXP then
  local m=tonumber(s.xpMax) or 0
  self.premiumXP:SetText(m>0 and (math.floor((tonumber(s.xp) or 0)/m*100+.5)..'% to next level') or 'XP unavailable')
 end
 if self.premiumContexts then
  for _,v in pairs(self.premiumContexts) do
   v.a:SetText(('Level %s %s\n%s'):format(tostring(s.level or '?'),tostring(s.className or ''),tostring(s.zone or '')))
   v.b:SetText(('Free bag slots: %s     •     Durability: %s\nGold and inventory are read from the current game session.'):format(tostring(s.bagFree or '?'),tostring(s.durability or '?')))
   local r=FF.RecipeFlowSelected and FF:RecipeFlowSelected()
   if r then
    local missing=FF.RecipeFlowShoppingList and FF:RecipeFlowShoppingList() or {}
    local lines={'SELECTED CRAFT: '..trim(r.name,36)}
    for i=1,math.min(4,#missing) do lines[#lines+1]=missing[i].need..' × '..trim(missing[i].name,26) end
    if #missing==0 then lines[#lines+1]='Materials ready for one craft (last scan).' end
    v.c:SetText(table.concat(lines,'\n'))
   else v.c:SetText('Open Skills to inspect recipes, reagents and your next profession step.') end
  end
 end
 local t=self.views.today and self.views.today.premium
 if t then
  local plan=self.plan or {}
  local advice=self.routeAdvice or {}
  t.kind:SetText(trim(plan.category or 'QUESTING',40))
  t.title:SetText(trim(plan.title or 'Ready for your next adventure',47))
  t.progress:SetText(trim(plan.detail or 'Open your quest log to choose a route.',68))
  t.where:SetText(trim(plan.where or (s.zone or 'Map not available'),91))
  t.reason:SetText(trim(advice.reason or 'Based on the current live quest log.',100))
  t.zone:SetText(tostring(s.zone or 'Unknown zone')..'  /  Level '..tostring(s.level or '?'))
  t.xp:SetText(s.xpPercent and (math.floor(s.xpPercent+.5)..'% TO NEXT LEVEL') or 'XP UNAVAILABLE')
  t.xpBar(s.xpPercent and s.xpPercent/100 or 0)
  t.character:SetText('Level '..tostring(s.level or '?')..'  '..tostring(s.className or 'Adventurer'))
  t.questCount:SetText('Quests  '..tostring(s.questCount or '?')..'   •   Ready  '..tostring(s.questComplete or 0))
  t.bags:SetText('Bag slots free  '..tostring(s.bagFree or '?')..' / '..tostring(s.bagTotal or '?'))
  t.durability:SetText('Durability  '..tostring(s.durability or '?')..'%')
  t.money:SetText('Gold  '..(self.MoneyText and self:MoneyText(s.money or 0) or '?'))
  t.route:SetText(trim(advice.reason or 'Follow your current objectives before taking a distant quest chain.',110))
  t.after:SetText(trim(advice.next or 'Check nearby quests after finishing your current objective.',97))
  local selected=self.RecipeFlowSelected and self:RecipeFlowSelected()
  local shopping=self.RecipeFlowShoppingList and self:RecipeFlowShoppingList() or {}
  if selected and #shopping>0 then
   t.material:SetText('For '..trim(selected.name,28)..':\nNeed '..tostring(shopping[1].need)..' × '..trim(shopping[1].name,34)..'.\nOpen Skills for reagents and next steps.')
  elseif selected then t.material:SetText('Materials ready for '..trim(selected.name,31)..' based on your last recipe scan.\nOpen Skills to plan a craft.')
  else t.material:SetText('Your professions and gathering can contribute to every quest route.\nOpen Skills to load real recipes and materials.') end
  for k,b in pairs(t.priority) do active(b,self.char.priority==k) end
 end
 local view=self.views.skills
 local u=view and view.premium
 if not u or not self.char then return end
 local all={}
 for _,p in ipairs(s.professions and s.professions.primary or {}) do all[#all+1]=p end
 for _,p in ipairs(s.professions and s.professions.secondary or {}) do all[#all+1]=p end
 local chosen=math.max(1,math.min(#all,tonumber(self.char.professionCoachIndex) or 1))
 for i,b in ipairs(u.prof) do
  local p=all[i]
  b.ffIndex=i;b:SetShown(p~=nil)
  if p then
   b.name:SetText(trim(p.name,18));b.skill:SetText(tostring(p.skill or '?')..' / '..tostring(p.cap or '?'))
   b.icon:SetTexture(profIcon(p))
   b.progress((tonumber(p.cap) or 0)>0 and (tonumber(p.skill) or 0)/p.cap or 0)
   active(b,i==chosen)
  end
 end
 local p=all[chosen]
 u.profIcon:SetTexture(profIcon(p))
 u.header:SetText('Profession Flow  —  '..(p and trim(p.name,28) or 'Your Skills'))
 u.skill:SetText(p and ('Skill '..tostring(p.skill or '?')..' / '..tostring(p.cap or '?')) or 'Choose a profession')
 u.skillBar(p and (tonumber(p.cap) or 0)>0 and ((tonumber(p.skill) or 0)/p.cap) or 0)
 local data=self.recipeFlow
 local matches=data and p and ((data.name or ''):lower()==(p.name or ''):lower())
 if not matches then data=nil end
 u.subheader:SetText(data and ('Observed from '..data.source..' profession API  •  '..#data.recipes..' known recipes')
  or (p and ('Open '..tostring(p.name)..' in the game to load its own live recipes, then REFRESH.') or (self.recipeFlowStatus or 'Open a real crafting window in WoW to load recipes.')))
 local filter=self.char.premiumFilter or 'best'
 active(u.best,filter=='best');active(u.all,filter=='all');active(u.mat,filter=='missing')
 local filtered={}
 if data then
  for idx,r in ipairs(data.recipes) do
   if filter=='all' or filter=='best' and r.difficulty~='trivial' or
      filter=='missing' and (r.missingTotal or 0)>0 then filtered[#filtered+1]=idx end
  end
 end
 local pages=math.max(1,math.ceil(#filtered/6))
 local page=math.max(1,math.min(pages,math.floor(tonumber(self.char.premiumRecipePage) or 1)))
 self.char.premiumRecipePage=page
 u.empty:SetShown(#filtered==0)
 if #filtered==0 then
  local msg=not data and (self.recipeFlowStatus or 'Open a profession window to read recipes.') or
   (filter=='best' and 'No observed skill-up recipes found. Try All Recipes.' or filter=='missing' and 'No observed recipes with missing materials.' or 'No recipes provided by the game client.')
  u.empty:SetText(msg)
 end
 for i,b in ipairs(u.recipes) do
  local idx=filtered[(page-1)*6+i]
  local r=idx and data.recipes[idx]
  b.ffRecipeIndex=idx;b:SetShown(r~=nil)
  if r then
   b.icon:SetTexture(r.texture or (r.id and safe(GetItemIcon,r.id)) or 'Interface\\Icons\\INV_Misc_QuestionMark')
   b.name:SetText(trim(r.name,30))
   b.diff:SetText(colorDifficulty(r.difficulty)..trim((r.difficulty or 'unknown'):upper(),11)..'|r')
   b.count:SetText(tostring(r.available or 0))
   active(b,idx==(self.char.recipeFlowSelected or 1))
  end
 end
 u.page:SetText(page..' / '..pages..'    •    '..#filtered..' recipes')
 u.prev:SetEnabled(page>1);u.next:SetEnabled(page<pages)
 local r=matches and self.RecipeFlowSelected and self:RecipeFlowSelected() or nil
 u.item:SetText(r and trim(r.name,28) or 'Select a recipe')
 u.itemIcon:SetTexture(r and (r.texture or (r.id and safe(GetItemIcon,r.id))) or 'Interface\\Icons\\INV_Misc_QuestionMark')
 u.difficulty:SetText(r and ('Difficulty: '..(r.difficulty or 'unknown')) or 'No live craft selected')
 local missing={}
 for i,b in ipairs(u.reagents) do
  local a=r and r.reagents[i]
  b.ffIndex=i;b:SetShown(a~=nil)
  if a then
   b.icon:SetTexture(a.texture or (a.id and safe(GetItemIcon,a.id)) or 'Interface\\Icons\\INV_Misc_QuestionMark')
   b.name:SetText(trim(a.name,23))
   b.count:SetText((a.missing>0 and '|cffff796a' or '|cff80e09b')..tostring(a.owned)..' / '..tostring(a.need)..'|r')
   if a.missing>0 then missing[#missing+1]=a end
  end
 end
 u.missing:SetText(not r and 'Live recipe data required' or #missing>0 and
  ('Missing: '..trim(tostring(missing[1].missing)..' '..missing[1].name,39)) or
  'All listed materials available for one craft')
 local first=missing[1]
 u.steps[1]:SetText(not r and 'Open Alchemy or another crafting profession in WoW.' or
  first and ('Acquire '..first.missing..' '..trim(first.name,31)..'.') or 'Materials verified for one craft (last scan).')
 u.steps[2]:SetText(not r and 'Refresh after the client loads its known recipes.' or
  #missing>1 and ('Also acquire '..missing[2].missing..' '..trim(missing[2].name,30)..'.') or 'Check profession rank, recipe color and available reagents.')
 u.steps[3]:SetText(not r and 'Select a recipe when it appears.' or
  ('Craft '..trim(r.name,42)..' using the game profession window.'))
 u.result1:SetText(r and ('Craftable reported: '..tostring(r.available or 0)) or 'No observed recipe yet')
 u.result2:SetText(r and ('Difficulty: '..tostring(r.difficulty or 'unknown')) or 'Waiting for the profession API')
 u.result3:SetText(r and (#missing>0 and (#missing..' reagent types missing') or 'Materials ready based on last scan')
  or 'No estimated value or fabricated price')
end
function FF:UpdateUI()
 legacyUpdate(self)
 self:UpdatePremiumStudio()
end