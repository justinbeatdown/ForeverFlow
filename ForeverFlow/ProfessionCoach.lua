-- Character-aware profession guidance. Uses trained skill readings, not fake recipes or prices.
local _, FF = ...
local profiles={
 herbalism={"Herbalism","Gather herbs along your current quest route. Track Herbs in your bags; skill-ups happen when harvesting appropriate nodes.","Open tracking and look for herb nodes in zones matching your skill. Low-level nodes eventually go gray.","Gathering"},
 mining={"Mining","Track mineral deposits and mine reachable veins during quests. Smelt only when it actually grants skill and you have ore.","If nearby veins are too high-level, train on lower-level deposits; smelting recipes can sometimes bridge gaps.","Gathering"},
 skinning={"Skinning","Skin eligible beasts you already kill. Higher-level beasts require more Skinning skill.","Use regular questing kills for skill-ups before taking long farming detours.","Gathering"},
 alchemy={"Alchemy","Open Alchemy and sort by recipes that still offer skill-ups. Make useful potions from materials you already own.","Compare reagent availability before crafting batches. Visit a trainer when your skill approaches the current rank cap.","Crafting"},
 blacksmithing={"Blacksmithing","Use known orange/yellow recipes that fit your materials; avoid expensive crafts solely for skill points.","Check whether smelted bars, stone and vendor materials are available before committing to a craft.","Crafting"},
 enchanting={"Enchanting","Disenchant unwanted eligible gear and check which known enchants still give skill-ups.","Save dust and essences for your next useful enchant; do not assume every disenchant grants a skill point.","Crafting"},
 engineering={"Engineering","Check known orange/yellow gadgets and components, then batch only the parts needed for your next useful craft.","Engineering often needs bars, stone and cloth. Check your bag before buying more materials.","Crafting"},
 leatherworking={"Leatherworking","Check orange/yellow leather recipes and use skins you collect while questing.","Plan hides and leather conversions before crafting; avoid turning rare materials into unwanted items.","Crafting"},
 tailoring={"Tailoring","Use cloth from your normal questing kills for skill-up recipes; check which recipes are orange/yellow.","Craft cloth bolts only when needed for a useful or skill-granting recipe.","Crafting"},
 jewelcrafting={"Jewelcrafting","Use the trained recipe list to identify skill-granting cuts or crafts; check gem and ore supplies first.","Prospecting materials and recipe availability vary with server rules; verify them in your profession UI.","Crafting"},
 inscription={"Inscription","Use the available recipe list to identify skill-granting crafts. Check pigments and herbs first.","Milling availability and recipes depend on the server; verify before planning large batches.","Crafting"},
 cooking={"Cooking","Cook food ingredients gathered while questing. Prefer recipes that grant skill and provide useful food.","Check your cooking fire, vendor reagents and trainer recipes before preparing a batch.","Secondary"},
 fishing={"Fishing","Fish accessible waters when you want ingredients, skill-ups, or a relaxed gold break.","Check the zone's fish requirements and use a rod, lure or training if catches fail.","Secondary"},
 ["first aid"]={"First Aid","Save suitable cloth from enemies and craft bandages that still grant skill-ups.","Keep a small reserve for healing and ask a trainer about higher ranks when capped.","Secondary"},
 archaeology={"Archaeology","Follow the game's survey and digsite features if supported by this server.","Check the profession interface for digsite availability; do not assume retail-era features exist here.","Secondary"},
}
local function choose(name)
 name=type(name)=='string' and name:lower() or ''
 for key,profile in pairs(profiles) do if name:find(key,1,true) then return profile end end
 return {name~='' and name or 'Profession',"Open your profession spellbook and choose an orange/yellow skill-up recipe you can afford.","Check trainers, skill requirements and available materials before planning the next rank.","Profession"}
end
function FF:ProfessionCoachEntries(snapshot)
 local result={}
 local professions=snapshot and snapshot.professions or {}
 for _,group in ipairs({professions.primary or {},professions.secondary or {}}) do
  for _,p in ipairs(group) do
   local profile=choose(p.name)
   local skill=tonumber(p.skill) or 0
   local cap=tonumber(p.cap) or 0
   local remaining=math.max(0,cap-skill)
   local nextGoal=cap>0 and math.min(cap,math.floor(skill/25+1)*25) or skill+25
   local step
   if cap>0 and remaining<=5 then
    step="Near your trained cap: visit a profession trainer for a higher rank if available."
   elseif cap>0 and remaining>0 then
    step="Next milestone: "..nextGoal.." skill ("..remaining.." until trained cap)."
   else step="Check the profession trainer and recipe list for current skill requirements." end
   result[#result+1]={name=profile[1],skill=skill,cap=cap,kind=profile[4],step=step,
      action=profile[2],tip=profile[3],id=p.id}
  end
 end
 return result
end
function FF:SelectedProfessionCoach(snapshot)
 local choices=self:ProfessionCoachEntries(snapshot)
 if #choices==0 then
  return {name="Choose a profession",skill=0,cap=0,kind="Untrained",
   step="Visit a profession trainer to learn primary and secondary skills.",
   action="Gathering professions can complement questing; crafting professions convert materials into gear and consumables.",
   tip="Your character can have two primary professions; the available secondary skills depend on this game version."},0,0
 end
 local ix=(self.char and tonumber(self.char.professionCoachIndex)) or 1
 ix=math.max(1,math.min(#choices,math.floor(ix)))
 if self.char then self.char.professionCoachIndex=ix end
 return choices[ix],ix,#choices
end
function FF:NextProfessionCoach()
 if not self.snapshot or not self.char then return end
 local entries=self:ProfessionCoachEntries(self.snapshot)
 if #entries==0 then return end
 self.char.professionCoachIndex=((self.char.professionCoachIndex or 1)%#entries)+1
 self:Refresh()
end
