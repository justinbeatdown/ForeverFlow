-- ForeverFlow world-wide offline discovery (data credited in third-party license).
-- Source is documentary; it cannot prove server-specific acceptance/availability.
local _,FF=...
local floor,abs=math.floor,math.abs
local function safe(f,...)
 if type(f)~='function' then return nil end
 local ok,r=pcall(f,...);if ok then return r end
end
local function completed(id)
 if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
  return safe(C_QuestLog.IsQuestFlaggedCompleted,id)==true
 end
 if IsQuestFlaggedCompleted then return safe(IsQuestFlaggedCompleted,id)==true end
 return false
end
local function raceAllowed(mask)
 if mask==0 then return true end
 local _,_,id=UnitRace('player');id=tonumber(id)
 if not id then return nil end
 return floor(mask/2^(id-1))%2==1
end
local function classAllowed(mask)
 if mask==0 then return true end
 local _,_,id=UnitClass('player');id=tonumber(id)
 if not id then return nil end
 return floor(mask/2^(id-1))%2==1
end
local function gateParts(g)
 if not g then return 1,nil,0,0,0 end
 return floor(g/1e11),floor(g%1e11/1e9),floor(g%1e9/1e8),floor(g%1e8/1e4),floor(g%1e4)
end
local function eligible(data,id,level,active)
 local min,questLevel,flags,races,classes=gateParts(data.gates[id])
 if level < min then return false end
 if questLevel and questLevel>level+2 then return false end
 if data.maxLevel and data.maxLevel[id] and level>data.maxLevel[id] then return false end
 if races~=0 and raceAllowed(races)~=true then return false end
 if classes~=0 and classAllowed(classes)~=true then return false end
 -- Never present dependent quest chains as immediately available.
 local p=data.pre and data.pre[id]
 if p then
  local found=false
  for _,need in ipairs(p) do if completed(need) then found=true;break end end
  if not found then return false end
 end
 p=data.preAll and data.preAll[id]
 if p then for _,need in ipairs(p) do if not completed(need) then return false end end end
 p=data.excl and data.excl[id]
 if p then for _,other in ipairs(p) do if active[other] or completed(other) then return false end end end
 local parent=data.parent and data.parent[id]
 if parent and not active[parent] then return false end
 local nextID=data.chain and data.chain[id]
 if nextID and (active[nextID] or completed(nextID)) then return false end
 -- Profession/reputation gates require independent in-game verification.
 if (data.skill and data.skill[id]) or (data.minRep and data.minRep[id]) or
    (data.maxRep and data.maxRep[id]) then return false end
 -- Skip monthly/repeatable from default leveling flow.
 if flags%2==1 then return false end
 return true,questLevel,min
end
local function decode(packed)
 local source=floor(packed/1e9)
 local kind=floor(packed%1e9/1e8)
 local rest=packed%1e8
 return source,kind,floor(rest/1e4)/100,(rest%1e4)/100
end
local function mapName(mapID)
 if C_Map and C_Map.GetMapInfo then
  local result=safe(C_Map.GetMapInfo,mapID)
  if type(result)=='table' and type(result.name)=='string' then return result.name end
 end
 return 'Map '..tostring(mapID)
end
local function activeIDs(snapshot)
 local ids={}
 for _,q in ipairs(snapshot.quests or {}) do if type(q.id)=='number' then ids[q.id]=true end end
 return ids
end
function FF:WorldQuestCandidates(snapshot,mapID,browseAll,saved,ignored)
 local data=self.worldQuestData
 if type(data)~='table' or type(data.start)~='table' then return {} end
 local level=tonumber(snapshot.level) or 1
 local clock=GetTime and GetTime() or 0
 local cacheKey=table.concat({tostring(mapID), tostring(level), tostring(browseAll), tostring(#(snapshot.quests or {}))}, ':')
 local cache=self._worldQuestCache
 if cache and cache.key==cacheKey and clock-cache.when<5 then return cache.results end
 local active=activeIDs(snapshot)
 local list={}
 local oldByID={}
 for _,r in ipairs(self.questCatalog or {}) do oldByID[r[1]]=r end
 local max= browseAll and 220 or 80
 for id,maps in pairs(data.start) do
  local relevant=browseAll or saved[id] or (mapID and maps[mapID])
  if relevant and not active[id] and not ignored[id] then
   local ok,ql,minimum=eligible(data,id,level,active)
   if ok and not completed(id) then
    for zone,points in pairs(maps) do
     if zone==mapID or browseAll or saved[id] then
      local encoded=points[1]
      if type(encoded)=='number' then
       local source,kind,x,y=decode(encoded)
       if x>=0 and x<=100 and y>=0 and y<=100 then
        local localQuest=(zone==mapID)
        local old=oldByID[id]
        local npc=old and old[7] or (kind==1 and 'NPC # '..source or kind==2 and 'Object # '..source or 'Item start')
        local title=(data.names and data.names[id]) or 'Quest # '..id
        local score=(localQuest and 210 or 0)+(saved[id] and 50 or 0)
          +math.max(-90,70-abs(level-(ql or level))*16)
          -(ql and ql>level and (ql-level)*6 or 0)
        list[#list+1]={id=id,title=title,areaID=zone,mapID=zone,
         mapName=mapName(zone),level=ql,minLevel=minimum,npc=npc,x=x,y=y,
         source='offline',confidence='DATABASE / UNVERIFIED',typeLabel='OFFLINE QUEST START',
         saved=saved[id]==true,nearby=localQuest,score=score,
         why=(localQuest and 'LOCAL | ' or 'TRAVEL REQUIRED | ')..'Reported pickup: '..npc..
          string.format(' %.1f, %.1f',x,y)..' | '..mapName(zone)..
          ' | Lv '..tostring(ql or '?')..'; confirm availability and prerequisites'}
        break
       end
      end
     end
    end
   end
  end
 end
 table.sort(list,function(a,b)
  if a.score~=b.score then return a.score>b.score end
  return a.id<b.id
 end)
 local unique,seen={},{}
 for _,q in ipairs(list) do
  local key=q.title:lower():gsub('[^%w]','')
  if not seen[key] then
   seen[key]=true
   unique[#unique+1]=q
   if #unique>=max then break end
  end
 end
 self._worldQuestCache={key=cacheKey,when=clock,results=unique}
 return unique
end
