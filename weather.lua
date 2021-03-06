
function deg_fah2cel(fah_degrees)  
  --[[  
  The function converts degrees Fahrenheit to Celsius
  Функция переводит градусы фаренгейта в градусы цельсия  
  ]]--
  return 5/9*(fah_degrees-32)
end

function deg_cel2fah(cel_degrees)  
  --[[  
  The function convert degrees Celsius to Fahrenheit
  Функция переводит градусы цельсия в градусы фаренгейта   
  ]]--
  return 9*cel_degrees/5+32
end

function speed_ms2milh(wind_speed_ms)  
  --[[   
  The function converts the wind speed from meters per second to miles per hour
  Функция переводит скорость ветра из метров в секунду в мили в час   
  ]]--
  return wind_speed_ms*60*60/1000*0.621371
end

function speed_milh2ms(wind_speed_mh)  
  --[[  
  The function converts the wind speed from miles per hour to meters per second
  Функция переводит скорость ветра из миль в час в метры в секунду  
  ]]--
  return wind_speed_mh/0.621371/60/60*1000
end

function math_round(num, accuracy) 
  --[[  
  The function rounds a number to the specified accuracy ('accuracy' - the number of decimal places)
  Функция округляет число с заданной точностью ('accuracy' - количество знаков после запятой) 
  ]]--
  if (accuracy == 0) then
    num = math.floor(num+0.49)
  else
    num = tonumber(string.format('%0.'..accuracy..'f',num))
  end
  return num
end

function apparent_temp(rel_him, temp_с, wind_speed_ms, radiation) 
  --[[
  The function takes the dry bulb temperature in the temperature felt by human, adjusted for wind speed, amount of sun and humidity.
  'rel_him' - Relative humidity
  'temp_s'' - Temperature in degrees Celsius(Use deg_fah2cel to convert from degrees Fahrenheit)
  'wind_speed_ms' - The wind speed in meters per second(Use speed_milh2ms to convert from miles per hour)
  'radiation' - solar radiation in watts per square meter (approximate levels can be determined based on the time of year, the weather and current time. In the summer afternoon in the bright sun - 800, in the fall and spring 450, in the winter of 300, with cloud cover is reduced by half, after sunset is reduced to zero) to compute without it you can not specify (pass nil), or pass zero.
  The function returns the value in degrees Celsius(Use deg_cel2fah to convert to Fahrenheit)

  Функция перевода температуры сухого термометра в температуру, ощущаемую человеком, с учетом скорости ветра, солнечного излучения и влажностью.
  'rel_him' — Относительная влажность
  'temp_с'' — Температура в градусах цельсия
  'wind_speed_ms' — Скорость ветра в метрах в секунду. 
  'radiation' — Солнечное излучение в ваттах на квадратный метр(примерные уровни можно определить исходя из времени года, погоды и текущего времени. Летом днем на ярком солнце - 800, осенью и весной 450, зимой 300, при облачности снижается вдвое, после заката солнца снижается до нуля), для расчета без него можно не указывать(передавать nil), или передавать ноль.
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
  The function for calculating wind and cold index - a simplified version of the apparent temperature.
  'temp_s'' - Temperature in degrees Celsius(Use deg_fah2cel to convert from degrees Fahrenheit)
  'wind_speed_ms' - The wind speed in meters per second(Use speed_milh2ms to convert from miles per hour)
  The function returns the value in degrees Celsius(Use deg_cel2fah to convert to Fahrenheit)
  Dependencies: 'speed_ms2milh', 'deg_cel2fah', 'deg_fah2cel'

  Функция расчета ветро-холодового индекса — упрощенной версии кажущейся температуры на основе температуры сухого термометра и скорости ветра. 
  'temp_с' — Температура в градусах цельсия
  'wind_speed_ms' — Скорость ветра в метрах в секунду. 
  Функция возвращает значение в градусах цельсия
  Зависимости: 'speed_ms2milh', 'deg_cel2fah', 'deg_fah2cel'
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
  The function converts relative to absolute humidity (amount of water in the air)
  'rel_him' - Relative humidity
  'temp_s'' - Temperature in degrees Celsius(Use deg_fah2cel to convert from degrees Fahrenheit)
  'pressure_in_mmhg' - pressure in mmHg or 'pressure_in_pa' - pressure in Pascals (instead of missing values can be passed 'nil')
  The function returns the value in kg/m3
  Dependencies: 'pressure_saturated_water_vapor'

  Функция перевода относительной влажности в абсолютную(количество воды в воздухе)
  'rel_him' — Относительная влажность
  'temp_с' — Температура в градусах цельсия
  'pressure_in_mmhg' — давление в мм ртутного столба или 'pressure_in_pa' — давление в паскалях(вместо отсутствующего значения можно передавать 'nil')
  Функция возвращает значение в кг/м3
  Зависимости: 'pressure_saturated_water_vapor'
  ]]--
  local pressure_svf = pressure_saturated_water_vapor(temp_с, pressure_in_mmhg, pressure_in_pa)
  local result = ((rel_him/100)*pressure_svf)*100/(461.5*(temp_с+273.15))
  return result
end

function pressure_saturated_water_vapor(temp_с, pressure_in_mmhg, pressure_in_pa)
  --[[
  The function for calculating the pressure of saturated steam at a given pressure and temperature
  'temp_s'' - Temperature in degrees Celsius(Use deg_fah2cel to convert from degrees Fahrenheit)
  'pressure_in_mmhg' - pressure in mmHg or 'pressure_in_pa' - pressure in Pascals (instead of missing values can be passed 'nil')
  The function returns a value in hPa

  Функция расчета давления насыщенного водяного пара при определенном давлении и температуре
  'temp_с' — Температура в градусах цельсия
  'pressure_in_mmhg' — давление в мм ртутного столба или 'pressure_in_pa' — давление в паскалях(вместо отсутствующего значения можно передавать 'nil')
  Функция возвращает значение в гектопаскалях(hPa)
  ]]--
  if (pressure_in_mmhg ~= nil and pressure_in_pa == nil) then
    pressure_in_pa = pressure_in_mmhg*133.322/100
  end
  local result = (1.0016+(3.15*(10^-6)*pressure_in_pa)-(0.074/pressure_in_pa)) * (6.112*(math.exp((17.62*temp_с)/(243.12+temp_с))))
  return result
end

function normalize(max,min,data)
  --[[
  The function of bringing in any range of values to percent:
  'max' - the maximum value of the range
  'min' - the minimum value of the range
  'data' - value
  The function returns a percentage value.
  Example: Conversion the signal quality of the -db percentage. -90db is a weak signal, -50db is a good signal. Convert -60db power value of the received signal in percentage of the reception quality:
  normalize (50,90,60) = 75%
  Example: Conversion of the battery voltage to percentage charge. Maximum battery voltage is 3V, the minimum operating voltage 1.9V. Convert the value of 2.2V in percentage charge:
  normalize (3,1.9,2.2) = 28%
  
  Функция приведения значения в произвольном диапазоне к процентам:
  'max' — максимальное значение диапазона
  'min' — минимальное значение диапазона
  'data' — значение
  Функция возвращает процентное значение.
  Пример: Пересчет качества сигнала из -db в проценты. -90db это плохой прием, -50db это хороший прием. Переведем полученное значение мощности принятого сигнала -60db в проценты качества приема:
  normalize(50,90,60) = 75%
  Пример: Пересчет напряжения батареи в проценты заряда. Максимальное напряжение батареи 3в, минимальное напряжение работы устройства 1.9в. Переведем значение 2.2в в проценты заряда:
  normalize(3,1.9,2.2) = 28%
  ]]--

  if (max < min) then 
    data = math.max(math.min(data, min), max)
    data = math.ceil(((data-max)*(100/(min-max)))-100)
    if (data > 0) then data = 0 end
    if (data < -100) then data = -100 end 
    data = math.abs(data)
  else
    data = math.max(math.min(data, max), min)
    data = math.ceil((data-min)*(100/(max-min)))
    if (data > 100) then data = 100 end 
    if (data < 0) then data = 0 end 
  end
  return data
end

function sun_bright(sunrise, sunset, h, m)
  --[[
  Function luminance calculating sun percentage of maximum per day
  'sunrise' - sunrise (in minutes)
  'sunset' - call time (in minutes)
  'h' - the hour
  'm' - the minutes
  The function returns a percentage value.
  Example: calculating the brightness of the sun at 12:23 when the sun rises at 8:00 and sets at 18:
  sun_bright (8 * 60, 18 * 60, 12, 23) = 87%

  Функция вычисления яркости солнца в процентах от максимального за день
  'sunrise' — время восхода(в минутах)
  'sunset' — время захода(в минутах)
  'h' — значение часов
  'm' — значение минут
  Функция возвращает процентное значение.
  Пример: вычисление яркости солнца в 12:23, если солнце восходит в 8 часов, а заходит в 18:
  sun_bright(8*60, 18*60, 12, 23) = 87%
  ]]--
  m = m + h*60
  noon = sunrise+(sunset-sunrise)/2
  bright = normalize(0, noon-sunrise, math.abs(noon-m))
  return bright
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
if (normalize(0, 100, 40) == 60) and (normalize(1000, 0, 600) == 60 and (normalize(100, 0, -60) == 0) and (normalize(100, 0, 110) == 100)) then print("Test normalize passed") else print("Test normalize failed") end
if (sun_bright(527, 993, 12, 40) == 100 and sun_bright(527, 993, 8, 0) == 0 and sun_bright(527, 993, 17, 0) == 0) then print("Test sun_bright passed") else print("Test sun_bright failed") end



