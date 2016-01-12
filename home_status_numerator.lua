local vlad_phone_present = grp.getvalue('vlad_phone_present')
local anna_phone_present = grp.getvalue('anna_phone_present')

local MT_Hallway = grp.getvalue('MT_Hallway')
local MT_Bathroom = grp.getvalue('MT_Bathroom')


local PL_Hall_Meta = grp.getvalue('PL_Hall_Meta')
local PL_Kitchen_Meta = grp.getvalue('PL_Kitchen_Meta')
local L_Hallway = grp.getvalue('L_Hallway')
local L_Bathroom = grp.getvalue('L_Bathroom')

local PL_Alternative_ALL
if (PL_Hall_Meta == 0 and PL_Kitchen_Meta == 0 and L_Hallway == 0) then
  PL_Alternative_ALL = 0
end
if (PL_Hall_Meta > 0 or PL_Kitchen_Meta == 0 or L_Hallway == 0) then
  PL_Alternative_ALL = PL_Hall_Meta
end
if (PL_Hall_Meta > 0 or PL_Kitchen_Meta > 0 or L_Hallway > 0) then
  PL_Alternative_ALL = 100
end


local Noolite_raw = grp.getvalue('Noolite_raw')
--local time = os.date("*t",os.time())
--local h = time.hour
local S_Night = grp.getvalue('S_Night')
local S_Nobody = grp.getvalue('S_Nobody')
local S_Active = grp.getvalue('S_Active')
local factors = {}
factors.active = 0
factors.night = 0
factors.nobody = 0
--local history = storage.get('history', history_default)
--history[object_name].value = object_value

function upd_factors(Active_factor, Night_factor, Nobody_factor, factors)
  if (Active_factor ~= nil) then factors.active = factors.active + Active_factor end
  if (Night_factor ~= nil) then factors.night = factors.night + Night_factor end
  if (Nobody_factor ~= nil) then factors.nobody = factors.nobody + Nobody_factor end
  return factors
end


if (PL_Alternative_ALL == 100) then
  factors = upd_factors(20, -10, -40, factors)
end

if (PL_Alternative_ALL < 10 and PL_Alternative_ALL > 0) then
  factors = upd_factors(nil, 0.5, -20, factors)
  if (S_Active < 30) then 
    factors = upd_factors(0.5, nil, nil, factors)
  end
end

if (PL_Alternative_ALL == 0) then
  factors = upd_factors(-1, 10, 0.2, factors)
end

if (vlad_phone_present == true) then
  factors = upd_factors(0.5, -0.5, -20, factors)
else
  factors = upd_factors(-0.2, 0.2, 0.2, factors)
end

if (anna_phone_present == true) then
  factors = upd_factors(0.5, -0.5, -20, factors)
else
  factors = upd_factors(-0.2, 0.2, 0.2, factors)
end

if (MT_Hallway > 0) then
	factors = upd_factors(10, -15, -40, factors)
else
  factors = upd_factors(-0.5, 0.2, 0.2, factors)
end

if (MT_Bathroom > 0) then
	factors = upd_factors(5, -10, -40, factors)
else
  factors = upd_factors(-0.5, 0.2, 0.2, factors)
end


S_Night = S_Night*(factors.night/100+1)
S_Nobody = S_Nobody*(factors.nobody/100+1)
S_Active = S_Active*(factors.active/100+1)

if (S_Night <= 1) then S_Night = 1 end
if (S_Nobody <= 1) then S_Nobody = 1 end
if (S_Active <= 1) then S_Active = 1 end
if (S_Night >= 100) then S_Night = 100 end
if (S_Nobody >= 100) then S_Nobody = 100 end
if (S_Active >= 100) then S_Active = 100 end

if (S_Night ~= grp.getvalue('S_Night')) then grp.update('S_Night', S_Night) end
if (S_Nobody ~= grp.getvalue('S_Nobody')) then grp.update('S_Nobody', S_Nobody) end
if (S_Active ~= grp.getvalue('S_Active')) then grp.update('S_Active', S_Active) end