STANDARD_TEXT_FONT="Fonts\\FRIZQT__.TTF"
local objects={}
local methods={}
function methods:SetSize(w,h) self.w=w;self.h=h end
function methods:GetWidth() return self.w or 874 end
function methods:GetHeight() return self.h or 744 end
function methods:IsShown() return self.visible~=false end
function methods:Show() self.visible=true end
function methods:Hide() self.visible=false end
function methods:SetShown(v) self.visible=v end
function methods:GetFrameLevel() return self.level or 1 end
function methods:SetFrameLevel(l) self.level=l end
function methods:CreateTexture() return newobj('Texture',self) end
function methods:CreateFontString() return newobj('FontString',self) end
function methods:RegisterForDrag() end
function methods:RegisterForClicks() end
function methods:SetScript(name,fn) self.scripts=self.scripts or {}; self.scripts[name]=fn end
function methods:SetPoint(...) self.pt={...} end
function methods:SetTextColor(...) end
function methods:SetText(t) self.text=t end
function methods:GetText() return self.text end
function methods:SetBackdrop(...) end
function methods:SetBackdropColor(...) end
function methods:SetBackdropBorderColor(...) end
function methods:SetFont(...) end
function methods:SetJustifyH(...) end
function methods:SetJustifyV(...) end
function methods:SetWordWrap(...) end
function methods:SetTexture(...) end
function methods:SetColorTexture(...) end
function methods:SetAlpha(...) end
function methods:SetScale(...) end
function methods:SetHighlightTexture(...) end
function methods:SetEnabled(...) end
function methods:ClearAllPoints(...) end
function methods:SetWidth(w) self.w=w end
function methods:SetHeight(h) self.h=h end
function methods:GetParent() return self.parent end
function methods:SetClampedToScreen(...) end
function methods:SetMovable(...) end
function methods:EnableMouse(...) end
function methods:StartMoving(...) end
function methods:StopMovingOrSizing(...) end
function methods:SetFrameStrata(...) end
function newobj(kind,parent)
 local o=setmetatable({kind=kind,parent=parent,w=874,h=744,visible=true},{__index=methods})
 table.insert(objects,o);return o
end
UIParent=newobj('UIParent')
function CreateFrame(kind,name,parent,template) return newobj(kind,parent) end
local FF={char={posX=0,posY=0,hideMinimap=true,activeTab='today',guideX=0,guideY=0,guideVisible=true,guideCollapsed=false,hudMinimal=false},db={},media='Interface\\AddOns\\ForeverFlow\\Media\\',colors={}}
FF.colors={gold={.94,.7,.24},white={.95,.9,.85},muted={.64,.6,.57},border={.32,.27,.2},button={.2,.2,.2},panel={.16,.16,.16},bg={.1,.1,.1},green={.1,.9,.1}}
function FF:Refresh() end
function FF:SavePosition() end
function FF:Toggle() end
function FF:ToggleGuide() end
function FF:SetGuideScale() end

FF.char.trainingChecks={};FF.char.priority='balanced';FF.char.autoFollow=true;FF.char.professionCoachIndex=1
FF.db.mode='simple'
FF.MoneyText=function(_,n) return tostring(math.floor(n or 0))..' copper' end
FF.FindDiscoveries=function()return {{id=1,title='Example Quest',npc='Reported NPC',mapName='The Barrens',nearby=true,confidence='UNVERIFIED',x=45.2,y=33.6}} end
FF.RecipeFlowShoppingList=function()return {}end
FF.RecipeFlowSelected=function(self)return self.recipeFlow and self.recipeFlow.recipes[1]end
FF.TrackQuest=function()end;FF.MapAction=function()end;FF.SkipQuest=function()end
FF.ChooseQuest=function()end;FF.ShowDiscoveryOnMap=function()end;FF.ToggleSavedDiscovery=function()end;FF.SkipDiscovery=function()end
FF.UnpinCurrentQuest=function()end;FF.ToggleRouteDetails=function()end;FF.SetPriority=function()end;FF.SetAutoFollow=function()end
FF.SetGuideCollapsed=function()end;FF.SetGuideScale=function()end;FF.Message=function()end
assert(loadfile('ForeverFlow/UI.lua'))('ForeverFlow',FF)
assert(loadfile('ForeverFlow/PremiumUI.lua'))('ForeverFlow',FF)
assert(loadfile('ForeverFlow/PremiumPages.lua'))('ForeverFlow',FF)
local ok,err=xpcall(function()FF:CreateUI()end,debug.traceback)
assert(ok,err)
assert(FF.window:GetWidth()==1160)
assert(FF.legacyChrome==nil, 'A legacy graphical shell is still mounted')
assert(FF.premiumBase==nil, 'A second premium backdrop shell was created')
assert(FF.compatibility and not FF.compatibility:IsShown(), 'Data-only compatibility must be invisible')
for _,name in ipairs({'today','leveling','gold','skills','character','settings'}) do
 assert(FF.views[name].premium and FF.views[name].premium.root,name..' missing premium page')
 assert(FF.views[name].legacyContainer and not FF.views[name].legacyContainer:IsShown(),name..' legacy is shown')
 FF:ShowTab(name)
end
FF.snapshot={level=18,className='Shaman',zone='The Barrens',xp=2000,xpMax=7000,xpPercent=29,bagFree=20,bagTotal=48,durability=90,money=100250,questCount=3,questComplete=1,quests={{id=15,title='A Quest',firstObjective='0/4 Gnolls slain',done=false}},goldCategory='HERBALISM',goldTip='Gather as you quest.',tips={'Review talents','Train spells','Repair soon'},session={earned=10520,spent=1000,materials=2,questTurns=1},professions={primary={{name='Alchemy',skill=60,cap=150},{name='Herbalism',skill=77,cap=150}},secondary={{name='Cooking',skill=20,cap=75}}}}
FF.plan={category='QUESTING',title='A Quest',detail='0/4 Gnolls',where='The Barrens'}
FF.routeAdvice={reason='Continue nearby quests before cross-zone travel.',next='Afterwards visit another quest hub.'}
FF.char.activeTab='leveling'
FF:UpdatePremiumStudio()
assert(FF.views.leveling.premium.title:GetText()=='Your Quest Route')
assert(FF.views.gold.premium.money:GetText():find('copper'))
assert(FF.views.character.premium.name:GetText():find('Shaman'))
assert(FF.views.settings.premium.rows[1].status:GetText()=='ON')
FF.char.discoverView=true;FF.char.activeTab='leveling';FF:UpdatePremiumStudio()
assert(FF.views.leveling.premium.title:GetText()=='Discover Quests')
-- Click paths must mutate state, not just render decorative buttons.
local ui=FF.views
ui.leveling.premium.discover.scripts.OnClick()
assert(FF.char.discoverView==true)
ui.gold.premium.plus5.scripts.OnClick()
assert(FF.char.goldTarget>0)
ui.character.premium.checks[1].scripts.OnClick()
assert(FF.char.trainingChecks[1]==true)
local was=FF.char.hideMinimap
ui.settings.premium.rows[2].scripts.OnClick()
assert(FF.char.hideMinimap~=was)
print('BETA10 SINGLE-SHELL ALL SIX TABS PASS; '..#objects..' created mock elements; functional button clicks PASS')