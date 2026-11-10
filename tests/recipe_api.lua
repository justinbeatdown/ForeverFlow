local FF={char={},Refresh=function()end}
assert(loadfile('ForeverFlow/RecipeFlow.lua'))('ForeverFlow',FF)
GetTime=function()return 15 end
C_Item={GetItemCount=function(id)return id==2450 and 8 or 0 end,
 GetItemInfo=function(id)return (id==2450 and 'Briarthorn' or 'Empty Vial'),'|Hitem:'..id..'|h[item]|h' end,
 GetItemIconByID=function(id)return id+5000 end}
C_TradeSkillUI={GetAllRecipeIDs=function()return {101,102}end,
 GetBaseProfessionInfo=function()return {professionName='Alchemy'} end,
 GetRecipeInfo=function(id)
 if id==101 then return {name='Potion',learned=true,relativeDifficulty=0,numAvailable=1} end
 return {name='Unlearned',learned=false}end,
 GetRecipeSchematic=function(id)return {outputItemID=555,reagentSlotSchematics={{quantityRequired=2,reagents={{itemID=2450}}},{quantityRequired=1,reagents={{itemID=3371}}}}}end}
assert(FF:TryCaptureRecipes())
assert(#FF.recipeFlow.recipes==1)
local r=FF.recipeFlow.recipes[1]
assert(r.reagents[1].name=='Briarthorn' and r.reagents[1].owned==8 and r.reagents[1].need==2)
assert(r.reagents[2].name=='Empty Vial' and r.reagents[2].missing==1)
assert(r.texture and r.link)
C_TradeSkillUI.GetRecipeSchematic=function()return {}end
C_TradeSkillUI.GetRecipeNumReagents=function()return 1 end
C_TradeSkillUI.GetRecipeReagentInfo=function()return 'Empty Vial',134514,3,1 end
assert(FF:TryCaptureRecipes())
local r=FF.recipeFlow.recipes[1]
assert(#r.reagents==1 and r.reagents[1].need==3 and r.reagents[1].owned==1 and r.reagents[1].missing==2)
-- Reagent status follows real inventory changes, not a stale profession snapshot.
C_Item.GetItemCount=function(id) return id==3371 and 7 or 0 end
-- The tuple fallback did not supply an itemID. Verify itemID-backed schematic path instead.
C_TradeSkillUI.GetRecipeSchematic=function()return {outputItemID=555,reagentSlotSchematics={{quantityRequired=2,reagents={{itemID=2450}}}}}end
assert(FF:CaptureRecipeFlow('modern'))
assert(FF.recipeFlow.recipes[1].reagents[1].owned==0)
C_Item.GetItemCount=function(id) return id==2450 and 10 or 0 end
FF:RecipeFlowRefreshInventory()
assert(FF.recipeFlow.recipes[1].reagents[1].owned==10)
assert(FF.recipeFlow.recipes[1].reagents[1].missing==0)
print('BETA9 MODERN PROFESSION REAGENT API AND INVENTORY REFRESH PASS')