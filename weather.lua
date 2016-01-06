
function deg_fah2cel(fah_degrees)  --[[  Функция переводит градусы фаренгейта в градусы цельсия  ]]--
  return 5/9*(fah_degrees-32)
end

function deg_cel2fah(cel_degrees)  --[[  Функция переводит градусы цельсия в градусы фаренгейта   ]]--
  return 9*cel_degrees/5+32
end

function speed_ms2milh(wind_speed_ms)  --[[   Функция переводит скорость ветра в м/с в мили/час   ]]--
  return wind_speed_ms*60*60/1000*0.621371
end

function speed_milh2ms(wind_speed_mh)  --[[  Функция переводит скорость ветра в милях/час в м/с  ]]--
  return wind_speed_mh/0.621371/60/60*1000
end

function math_round(num, accuracy) --[[  Функция округляет число с заданной точностью (accuracy - количество знаков после запятой) ]]--
    return tonumber(string.format('%0.'..accuracy..'f',num))
end

function apparent_temp(rel_him, temp_с, wind_speed_ms, radiation) 
  --[[
  Функция перевода температуры сухого термометра в температуру, ощущаемую человеком с учетом скорости ветра, солнечного излучения и влажностью.
  rel_him — Относительная влажность
  temp_с — Температура в градусах цельсия
  wind_speed_ms — Скорость ветра в метрах в секунду. 
  radiation — Солнечное излучение в ваттах на квадратный метр(примерные уровни можно определить исходя из времени года, погоды и текущего времени. Летом днем на ярком солнце - 800, осенью и весной 450, зимой 300, при облачности снижается вдвое, после заката солна снижается до нуля), для расчета без него можно не указывать, или указывать ноль.
  Функция возвращает значение в градусах цельсия
  ]]--
  if (radiation == nil) then radiation = 0 end
  if (wind_speed_ms == nil) then wind_speed_ms = 0 end
  local vapor_tension = (rel_him/100)*6.112*(math.exp((17.27*temp_с)/(237.7+temp_с)))
  local apparent_temp_с = temp_с+(0.348*vapor_tension)-(0.7*wind_speed_ms)+(0.7*(radiation/(wind_speed_ms+10)))-4.25
  return apparent_temp_с
end

function wind_chill(temp_c, wind_speed_ms)
  --[[
  Функция расчета ветро-холодового индекса — упрощенной версии кажущейся температуры на основе температуры сухого термометра и скорости ветра. 
  temp_с — Температура в градусах цельсия
  wind_speed_ms — Скорость ветра в метрах в секунду. 
  Функция возвращает значение в градусах цельсия
  Зависимости: speed_ms2milh, deg_cel2fah, deg_fah2cel
  ]]--
  if (wind_speed_ms > 1.3 and temp_c < 10) then
    local wind_speed_mh = speed_ms2milh(wind_speed_ms)
    local temp_f = deg_cel2fah(temp_c)
    wind_chill_c = deg_fah2cel(35.74+(0.6215*temp_f)-(35.75*wind_speed_mh^0.16)+(0.4275*temp_f*wind_speed_mh^0.16))
  else
    wind_chill_c = temp_c
  end
  return wind_chill_c
end

function rel2abs_him(rel_him, temp_с, pressure_in_mmhg, pressure_in_pa) 
  --[[
  Функция перевода относительной влажности в абсолютную(количество воды в воздухе)
  rel_him — Относительная влажность
  temp_с — Температура в градусах цельсия
  pressure_in_mmhg — давление в мм ртутного столба или pressure_in_pa — давление в паскалях(вместо отсутствующего значения можно передавать nil)
  Функция возвращает значение в кг/м3

  Зависимости: pressure_saturated_water_vapor
  ]]--
  local pressure_svf = pressure_saturated_water_vapor(temp_с, pressure_in_mmhg, pressure_in_pa)
  local result = ((rel_him/100)*pressure_svf)*100/(461.5*(temp_с+273.15))
  return result
end

function pressure_saturated_water_vapor(temp_с, pressure_in_mmhg, pressure_in_pa)
  --[[
  Функция расчета давления насыщенного водяного пара при определенном давлении и температуре
  temp_с — Температура в градусах цельсия
  pressure_in_mmhg — давление в мм ртутного столба или pressure_in_pa — давление в паскалях(вместо отсутствующего значения можно передавать nil)
  Функция возвращает значение в гектопаскалях
  ]]--
  if (pressure_in_mmhg ~= nil and pressure_in_pa == nil) then
    pressure_in_pa = pressure_in_mmhg*133.322/100
  end
  local result = (1.0016+(3.15*(10^-6)*pressure_in_pa)-(0.074/pressure_in_pa)) * (6.112*(math.exp((17.62*temp_с)/(243.12+temp_с))))
  return result
end

if (math_round(12.66, 1) == 12.7) and (math_round(12.11, 1) == 12.1) then print("Test math_round passed") else print("Test math_round failed") end
if (math_round(deg_fah2cel(10), 1) == -12.2) then print("Test deg_fah2cel passed") else print("Test deg_fah2cel failed") end
if (math_round(deg_cel2fah(10), 1) == 50) then print("Test deg_cel2fah passed") else print("Test deg_cel2fah failed") end
if (math_round(speed_ms2milh(10), 1) == 22.4) then print("Test speed_ms2milh passed") else print("Test speed_ms2milh failed") end
if (math_round(speed_milh2ms(10), 1) == 4.5) then print("Test speed_milh2ms passed") else print("Test speed_milh2ms failed") end
if (math_round(apparent_temp(70, 27, 5, 0), 1) == 27.9) then print("Test apparent_temp passed") else print("Test apparent_temp failed") end
if (math_round(wind_chill(-15, 10), 1) == -26.9) then print("Test wind_chill passed") else print("Test wind_chill failed") end
if (math_round(rel2abs_him(60, 25, 760), 3) == 0.014) then print("Test rel2abs_him passed") else print("Test rel2abs_him failed") end
if (math_round(pressure_saturated_water_vapor(25, 760), 2) == 31.75) then print("Test pressure_saturated_water_vapor passed") else print("Test pressure_saturated_water_vapor failed") end