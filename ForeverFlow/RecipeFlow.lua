-- Live, read-only profession recipe / ingredient workflow.
-- Only records what the player's opened trade skill or crafting window exposes.
-- WoW Forever API variations are handled with protected calls.
local _, FF = ...
local function call(fn, ...)
    if type(fn) ~= 'function' then return nil end
    local ok,a,b,c,d,e,f=pcall(fn,...)
    if ok then return a,b,c,d,e,f end
end
local function lower(s) return type(s)=='string' and s:lower() or '' end
local function linkID(link)
    if type(link)~='string' then return nil end
    return tonumber(link:match('item:(%d+)'))
end
local function modernCollect()
    local api=C_TradeSkillUI
    if not api or type(api.GetAllRecipeIDs)~='function' then return nil end
    local ids=call(api.GetAllRecipeIDs)
    if type(ids)~='table' or #ids==0 then return nil end
    local profession=call(api.GetBaseProfessionInfo)
    local name=type(profession)=='table' and (profession.professionName or profession.name or profession.professionDisplayName)
    if type(name)~='string' or name=='' then name=call(api.GetTradeSkillDisplayName) end
    if type(name)~='string' or name=='' then name=call(api.GetTradeSkillLine) end
    if type(name)~='string' or name=='' then name='Opened profession' end
    local recipes={}
    for _,id in ipairs(ids) do
        if #recipes>=700 then break end
        local info=call(api.GetRecipeInfo,id)
        -- GetAllRecipeIDs may also contain UNLEARNED entries with the filters open.
        if type(info)=='table' and type(info.name)=='string' and
           info.learned~=false and not info.isHeader and not info.isDummyRecipe then
            local schematic=call(api.GetRecipeSchematic,id,false)
            local slots=type(schematic)=='table' and schematic.reagentSlotSchematics or nil
            local reagents={}
            local missingTotal=0
            local function addReagent(itemID,need,owned,texture,label,link)
                if #reagents>=16 then return end
                itemID=tonumber(itemID)
                need=math.max(0,tonumber(need) or 0)
                if owned==nil and itemID then owned=call(GetItemCount,itemID) end
                owned=math.max(0,tonumber(owned) or 0)
                local itemName,itemLink
                if itemID then itemName,itemLink=call(GetItemInfo,itemID) end
                label=label or itemName or (itemID and ('Item #'..itemID)) or 'Unknown reagent'
                link=link or itemLink
                texture=texture or (itemID and call(GetItemIcon,itemID))
                local missing=math.max(0,need-owned)
                missingTotal=missingTotal+missing
                reagents[#reagents+1]={name=label,need=need,owned=owned,missing=missing,
                    link=link,id=itemID,texture=texture}
            end
            if type(slots)=='table' then
                for _,slot in ipairs(slots) do
                    if #reagents>=16 then break end
                    if type(slot)=='table' and type(slot.reagents)=='table' and #slot.reagents>0 then
                        local reagent=slot.reagents[1]
                        if type(reagent)=='table' then
                            addReagent(reagent.itemID,slot.quantityRequired or reagent.quantityRequired,
                                nil,reagent.icon or reagent.iconID,reagent.name,reagent.itemLink)
                        end
                    end
                end
            end
            -- Forever/Classic-modern can expose reagent methods instead of
            -- schematic slots. This fallback does not invent reagent quantities.
            if #reagents==0 and type(api.GetRecipeNumReagents)=='function' then
                local n=tonumber(call(api.GetRecipeNumReagents,id)) or 0
                for i=1,math.min(n,16) do
                    local r=call(api.GetRecipeReagentInfo,id,i)
                    if type(r)=='table' then
                        addReagent(r.itemID,r.quantityRequired or r.quantity,r.numAvailable,
                            r.icon or r.iconID,r.name,r.itemLink)
                    end
                end
            end
            local outputID=info.itemID or (schematic and schematic.outputItemID)
            local outputLink
            if outputID then _,outputLink=call(GetItemInfo,outputID) end
            local available=tonumber(info.numAvailable) or tonumber(call(api.GetRecipeNumAvailable,id)) or 0
            local diff=info.relativeDifficulty
            local diffName=({[0]='optimal',[1]='medium',[2]='easy',[3]='trivial'})[diff] or
                (info.canSkillUp==true and 'skill-up' or 'unknown')
            recipes[#recipes+1]={name=info.name,index=id,source='modern',link=outputLink or info.hyperlink,id=outputID,
                texture=info.icon or info.iconID or (schematic and schematic.icon) or
                    (outputID and call(GetItemIcon,outputID)),
                difficulty=diffName,canSkillUp=info.canSkillUp,available=available,
                reagents=reagents,missingTotal=missingTotal}
        end
    end
    if #recipes==0 then return nil end
    return {name=name,source='modern',recipes=recipes,count=#recipes,observed=GetTime and GetTime() or 0}
end
local function collect(source)
    local trade=source=='trade'
    local total=tonumber(call(trade and GetNumTradeSkills or GetNumCrafts)) or 0
    local line=call((trade and GetTradeSkillLine) or (not trade and GetCraftDisplaySkillLine))
    if type(line)~='string' or line=='' then line=source=='trade' and 'Trade Skill' or 'Crafting' end
    local recipes={}
    for i=1,math.min(total,700) do
        local name,difficulty,available=call((trade and GetTradeSkillInfo) or (not trade and GetCraftInfo),i)
        if type(name)=='string' and name~='' and difficulty~='header' and difficulty~='subheader' then
            local output=call((trade and GetTradeSkillItemLink) or (not trade and GetCraftItemLink),i)
            local recipeIcon=call((trade and GetTradeSkillIcon) or (not trade and GetCraftIcon),i)
            if not recipeIcon and linkID(output) and type(GetItemIcon)=="function" then recipeIcon=call(GetItemIcon,linkID(output)) end
            local reagents={}
            local n=tonumber(call((trade and GetTradeSkillNumReagents) or (not trade and GetCraftNumReagents),i)) or 0
            local craftable=math.max(0,tonumber(available) or 0)
            local missingTotal=0
            for j=1,math.min(n,16) do
                local rn,rt,need,owned=call((trade and GetTradeSkillReagentInfo) or (not trade and GetCraftReagentInfo),i,j)
                need=math.max(0,tonumber(need) or 0)
                owned=math.max(0,tonumber(owned) or 0)
                local rlink=call((trade and GetTradeSkillReagentItemLink) or (not trade and GetCraftReagentItemLink),i,j)
                if type(rn)=='string' and rn~='' then
                    local missing=math.max(0,need-owned)
                    missingTotal=missingTotal+missing
                    reagents[#reagents+1]={name=rn,need=need,owned=owned,missing=missing,
                        link=rlink,id=linkID(rlink),texture=rt}
                end
            end
            recipes[#recipes+1]={name=name,index=i,source=source,link=output,id=linkID(output),texture=recipeIcon,
                difficulty=difficulty or 'unknown',available=craftable,reagents=reagents,
                missingTotal=missingTotal}
        end
    end
    return {name=line,source=source,recipes=recipes,count=#recipes,observed=GetTime and GetTime() or 0}
end
function FF:CaptureRecipeFlow(source)
    if not self.char then return false end
    local data
    local legacy=source=='trade' and type(GetNumTradeSkills)=='function'
       or source=='craft' and type(GetNumCrafts)=='function'
    if legacy then data=collect(source) end
    if not data or data.count==0 then data=modernCollect() end
    if not data or data.count==0 then
        local tradeN=tonumber(call(GetNumTradeSkills)) or 0
        local craftN=tonumber(call(GetNumCrafts)) or 0
        local modern=C_TradeSkillUI and type(C_TradeSkillUI.GetAllRecipeIDs)=='function'
        local ids=modern and call(C_TradeSkillUI.GetAllRecipeIDs)
        local modernN=type(ids)=='table' and #ids or 0
        self.recipeFlowStatus='Client recipes: trade '..tradeN..', craft '..craftN..', modern '..modernN..'. Open the profession recipe list and Refresh.'
        if self.Refresh then self:Refresh() end
        return false
    end
    local previous=self.recipeFlow
    local changed=not previous or previous.name~=data.name or previous.source~=data.source
    self.recipeFlow=data
    self.recipeFlowStatus=data.count..' recipes loaded from '..data.source..' profession API'
    if changed then
        self.char.recipeFlowPage=1
        self.char.recipeFlowSelected=1
        self.char.recipeReagentPage=0
        self.char.premiumRecipePage=1
    end
    if self.Refresh then self:Refresh() end
    return true
end
function FF:TryCaptureRecipes()
    -- Profession events may fire before the recipes have populated; retry from
    -- game events, the Refresh control, and while the workbench is visible.
    local trade=(TradeSkillFrame and TradeSkillFrame.IsShown and TradeSkillFrame:IsShown())
    local craft=(CraftFrame and CraftFrame.IsShown and CraftFrame:IsShown())
    if C_TradeSkillUI and type(C_TradeSkillUI.GetAllRecipeIDs)=='function' then
        local ids=call(C_TradeSkillUI.GetAllRecipeIDs)
        if type(ids)=='table' and #ids>0 then return self:CaptureRecipeFlow('modern') end
    end
    if trade then return self:CaptureRecipeFlow('trade') end
    if craft then return self:CaptureRecipeFlow('craft') end
    if type(GetNumTradeSkills)=='function' and (tonumber(call(GetNumTradeSkills)) or 0)>0 then
        return self:CaptureRecipeFlow('trade')
    end
    if type(GetNumCrafts)=='function' and (tonumber(call(GetNumCrafts)) or 0)>0 then
        return self:CaptureRecipeFlow('craft')
    end
    self.recipeFlowStatus='Open a crafting profession window, then press Refresh Recipes.'
    return false
end
function FF:RecipeFlowSelected()
    local data=self.recipeFlow
    local index=self.char and math.max(1,tonumber(self.char.recipeFlowSelected) or 1) or 1
    return data and data.recipes[index] or nil,data,index
end
function FF:RecipeFlowSelect(index)
    if not self.recipeFlow or not self.char then return end
    index=math.max(1,math.min(#self.recipeFlow.recipes,math.floor(tonumber(index) or 1)))
    self.char.recipeFlowSelected=index
    self.char.recipeFlowPage=math.floor((index-1)/5)+1
    self.char.recipeReagentPage=0
    self:Refresh()
end
function FF:RecipeFlowPage(step)
    local data=self.recipeFlow
    if not data or not self.char then return end
    local maxPage=math.max(1,math.ceil(#data.recipes/5))
    self.char.recipeFlowPage=math.max(1,math.min(maxPage,(self.char.recipeFlowPage or 1)+(step or 0)))
    self:Refresh()
end
function FF:RecipeFlowShoppingList()
    local recipe=self:RecipeFlowSelected()
    if not recipe then return {} end
    local out={}
    for _,r in ipairs(recipe.reagents) do
        if r.missing>0 then out[#out+1]={name=r.name,need=r.missing,id=r.id,link=r.link} end
    end
    return out
end
function FF:RecipeFlowMatchProfession(p)
    local data=self.recipeFlow
    return data and p and lower(data.name)==lower(p.name)
end
function FF:RecipeFlowTooltip(owner,entry)
    if not GameTooltip or not owner or not entry then return end
    GameTooltip:SetOwner(owner,'ANCHOR_RIGHT')
    if type(entry.link)=='string' and entry.link:find('|Hitem:') then
        local ok=pcall(GameTooltip.SetHyperlink,GameTooltip,entry.link)
        if not ok then GameTooltip:SetText(entry.name or 'Item') end
    else
        GameTooltip:SetText(entry.name or 'Recipe')
        GameTooltip:AddLine('No item tooltip was supplied by the game client.',.8,.7,.5,true)
    end
    GameTooltip:Show()
end
