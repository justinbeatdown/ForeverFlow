-- ForeverFlow 0.5.6 Beta 6: native, concept-inspired profession studio.
-- Gameplay values and item textures are read from the client; no fabricated
-- prices, recipes, material locations, or estimated skill-up counts.
local _,FF=...
local unpack=unpack or table.unpack
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
 b:SetBackdropColor(.9,.9,.9,1);b:SetBackdropBorderColor(.35,.29,.20,1)
 b.caption=label(b,name,7,1,w-14,h-2,11,TEXT,'CENTER');b.text=b.caption
 b:SetScript('OnClick',onClick or function() end)
 b:SetScript('OnEnter',function(self)self:SetBackdropBorderColor(.99,.75,.3,1)end)
 b:SetScript('OnLeave',function(self)
  if self.ffOn then self:SetBackdropBorderColor(1,.72,.22,1)
  else self:SetBackdropBorderColor(.35,.29,.2,1) end
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
 for i=1,5 do
  local b=button(list,'',11,38+(i-1)*43,514,40,function(self)
   if self.ffRecipeIndex then FF:RecipeFlowSelect(self.ffRecipeIndex) end
  end)
  b.icon=art(b,5,5,30)
  b.name=label(b,'',42,1,228,36,12,TEXT)
  b.diff=label(b,'',271,2,100,35,11,GOLD,'RIGHT')
  b.count=label(b,'',388,2,117,35,11,TEXT,'RIGHT')
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

function FF:MakeSkills(page)
 local v=legacySkills(self,page)
 v.premium=self:MakePremiumWorkbench(page)
 return v
end

function FF:CreateUI()
 legacyCreate(self)
 local win=self.window
 win:SetSize(1160,767)
 -- Cover the old header with real approved brand assets, not generated art.
 local header=surface(win,14,11,1132,86,.58,'WindowBG.tga')
 header:SetFrameLevel(win:GetFrameLevel()+16)
 art(header,11,11,62,FF.media..'MinimapIconRound.tga')
 local wordmark=header:CreateTexture(nil,'ARTWORK')
 wordmark:SetTexture(FF.media..'HeaderWordmark.tga')
 wordmark:SetPoint('TOPLEFT',header,'TOPLEFT',74,-9);wordmark:SetSize(229,57)
 label(header,'SMART LEVELING + GOLD',81,59,238,18,10,GOLD)
 self.premiumTabs={}
 local nav={{'today','TODAY'},{'leveling','LEVELING'},{'gold','GOLD'},{'skills','SKILLS'},{'character','CHARACTER'},{'settings','SETTINGS'}}
 for i,entry in ipairs(nav) do
  local b=button(header,entry[2],327+(i-1)*129,31,122,38,function()FF:ShowTab(entry[1])end)
  self.premiumTabs[entry[1]]=b
  self.tabButtons[entry[1]]=b
 end
 self.premiumClose=button(header,'X',1106,4,22,22,function()FF:Toggle()end)
 -- Hide only superseded navigation/status, never the actual content/guide.
 local oldNav=self.pages and self.pages.today and self.pages.today:GetParent()
 -- Original sidebar and header are covered by a larger shared workspace.
 self.premiumBase=surface(win,14,104,1132,623,.47,'WindowBG.tga')
 self.premiumBase:SetFrameLevel(win:GetFrameLevel()+2)
 self.premiumBottom=surface(win,14,732,1132,23,.24,'ButtonBG.tga')
 self.premiumBottom:SetFrameLevel(win:GetFrameLevel()+17)
 label(self.premiumBottom,'FOREVERFLOW    •    YOU PLAY, WE GUIDE',12,1,510,21,10,MUTED)
 label(self.premiumBottom,'WoW FOREVER  /  0.5.6 BETA 6',835,1,281,21,10,MUTED,'RIGHT')
 -- Keep each game page above the background and place content below the header.
 for tab,page in pairs(self.pages) do
  page:ClearAllPoints()
  if tab=='skills' then
   page:SetPoint('TOPLEFT',win,'TOPLEFT',22,-111)
   page:SetSize(1116,602)
  else
   page:SetPoint('TOPLEFT',win,'TOPLEFT',29,-169)
   page:SetSize(1100,537)
  end
  page:SetFrameLevel(win:GetFrameLevel()+5)
 end
 -- A small live identity strip for pages other than Skills.
 self.premiumInfo=surface(win,22,114,1116,44,.27,'CardBG.tga')
 self.premiumInfo:SetFrameLevel(win:GetFrameLevel()+7)
 self.premiumCharacter=label(self.premiumInfo,'',13,5,835,32,13,TEXT)
 self.premiumXP=label(self.premiumInfo,'',870,5,230,32,12,GOLD,'RIGHT')
 -- A restrained right inspector makes legacy tabs less text-wall-like.
 self.premiumContexts={}
 for _,name in ipairs({'today','leveling','gold','character','settings'}) do
  local p=self.pages[name]
  local rail=surface(p,656,6,439,493,.38)
  label(rail,name=='gold' and 'GOLD & MATERIALS' or 'CHARACTER CONTEXT',15,11,401,24,13,GOLD)
  sep(rail,14,41,409,.35)
  local a=label(rail,'',17,59,398,41,15,TEXT)
  local b=label(rail,'',17,113,398,68,12,MUTED)
  sep(rail,14,196,409,.23)
  local c=label(rail,'',17,209,395,118,12,TEXT)
  button(rail,'OPEN PROFESSION FLOW',15,435,409,37,function()FF:ShowTab('skills')end)
  self.premiumContexts[name]={a=a,b=b,c=c}
 end
 self:ShowTab(self.char.activeTab or 'today')
end

function FF:ShowTab(name)
 legacyTab(self,name)
 if self.premiumTabs then
  for tab,b in pairs(self.premiumTabs) do active(b,tab==name) end
 end
 if self.premiumInfo then self.premiumInfo:SetShown(name~='skills') end
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
 local pages=math.max(1,math.ceil(#filtered/5))
 local page=math.max(1,math.min(pages,math.floor(tonumber(self.char.premiumRecipePage) or 1)))
 self.char.premiumRecipePage=page
 u.empty:SetShown(#filtered==0)
 if #filtered==0 then
  local msg=not data and (self.recipeFlowStatus or 'Open a profession window to read recipes.') or
   (filter=='best' and 'No observed skill-up recipes found. Try All Recipes.' or filter=='missing' and 'No observed recipes with missing materials.' or 'No recipes provided by the game client.')
  u.empty:SetText(msg)
 end
 for i,b in ipairs(u.recipes) do
  local idx=filtered[(page-1)*5+i]
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