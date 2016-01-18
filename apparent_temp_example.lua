require 'ltn12'
json = require("json")
local https = require 'ssl.https'
local http = require 'socket.http'

function sun_radiation(month, lat, sunrise, sunset)
  local acc_all = 0
  local acc_hour = 0
  local noon_time = 0
  local noon_tmp = false
  local radiation = 
  {
    [1] = {[40] = 322, [44] = 261, [48] = 207, [52] = 164, [56] = 113, [60] = 68, [64] = 35, [68] = 0},
    [2] = {[40] = 417, [44] = 365, [48] = 324, [52] = 270, [56] = 220, [60] = 169, [64] = 134, [68] = 112},
    [3] = {[40] = 639, [44] = 603, [48] = 565, [52] = 528, [56] = 467, [60] = 406, [64] = 405, [68] = 282},
    [4] = {[40] = 757, [44] = 724, [48] = 702, [52] = 678, [56] = 650, [60] = 612, [64] = 585, [68] = 567},
    [5] = {[40] = 893, [44] = 872, [48] = 862, [52] = 850, [56] = 840, [60] = 825, [64] = 824, [68] = 809},
    [6] = {[40] = 897, [44] = 889, [48] = 881, [52] = 880, [56] = 873, [60] = 877, [64] = 864, [68] = 865},
    [7] = {[40] = 891, [44] = 886, [48] = 877, [52] = 882, [56] = 875, [60] = 856, [64] = 855, [68] = 889},
    [8] = {[40] = 803, [44] = 768, [48] = 736, [52] = 719, [56] = 695, [60] = 660, [64] = 641, [68] = 639},
    [9] = {[40] = 654, [44] = 619, [48] = 589, [52] = 540, [56] = 486, [60] = 454, [64] = 400, [68] = 355},
    [10] = {[40] = 510, [44] = 465, [48] = 406, [52] = 344, [56] = 267, [60] = 208, [64] = 173, [68] = 122},
    [11] = {[40] = 358, [44] = 308, [48] = 254, [52] = 194, [56] = 127, [60] = 84, [64] = 56, [68] = 34},
    [12] = {[40] = 298, [44] = 234, [48] = 184, [52] = 126, [56] = 84, [60] = 47, [64] = 0, [68] = 0},
  }

  lat = math_round(lat, 0) 
  radiation_value = radiation[month][lat]
  if (radiation_value == nil and radiation[month][lat-2] ~= nil and radiation[month][lat+2] ~= nil) then
    radiation_value = (radiation[month][lat-2]+radiation[month][lat+2])/2    
  end
  
  if (radiation_value == nil and radiation[month][lat-2] == nil and radiation[month][lat+2] == nil) then
    if (radiation[month][lat-1] ~= nil and radiation[month][lat+1] == nil) then
      intermediate_value = (radiation[month][lat-1]+radiation[month][lat+3])/2
      radiation_value = (radiation[month][lat-1]+intermediate_value)/2
    end
    if (radiation[month][lat-1] == nil and radiation[month][lat+1] ~= nil) then
      intermediate_value = (radiation[month][lat+1]+radiation[month][lat-3])/2
      radiation_value = ((radiation[month][lat+1]+intermediate_value))/2
    end
  end

  for i = 0,24*60 do  
    local acc_tmp = sun_bright(sunrise, sunset, 0, i)
    acc_all = acc_all + acc_tmp
    if (acc_tmp == 99 and noon_tmp == false) then
      noon_time=i 
    end
    if (acc_tmp == 100) then
      noon_time=i 
      noon_tmp = true
    end
  end

  for i = noon_time-30,noon_time+30 do  
    local acc_tmp = sun_bright(sunrise, sunset, 0, i)
    acc_hour = acc_hour + acc_tmp
  end
  return radiation_value*277.8/30/(acc_all/acc_hour)
end


function http_get(request_url, http_s)
  local request_body = ''
  local response_body = { }

  if (http_s == true) then
    body, code, hdrs, stat = https.request
      {
        url = request_url;
        method = "POST";
        headers =
        {
          ["Content-Type"] = "application/x-www-form-urlencoded";
          ["Content-Length"] = #request_body;
        };
        source = ltn12.source.string(request_body);
        sink = ltn12.sink.table(response_body);
        protocol = "tlsv1";
      }
  else
    body, code, hdrs, stat = http.request
      {
        url = request_url;
        method = "POST";
        headers =
        {
          ["Content-Type"] = "application/x-www-form-urlencoded";
          ["Content-Length"] = #request_body;
        };
        source = ltn12.source.string(request_body);
        sink = ltn12.sink.table(response_body);
      }
  end
  

  if (code ~= 200) then
    --log(body, code, hdrs, stat)
    return nil
  end
  return json.decode(table.concat(response_body))
end


local response_yahoo = http_get('https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20weather.forecast%20where%20woeid%20in%20(select%20woeid%20from%20geo.places(1)%20where%20text%3D%22moscow%2C%20ru%22)&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys', true)
local response_owm = http_get('http://api.openweathermap.org/data/2.5/weather?q=moscow,ru&appid=95473e638011a52a5ddd7ebeec959926&units=metric', false)

if (response_yahoo ~= nil and response_owm ~= nil) then
  local yahoo_windspeed = speed_milh2ms(response_yahoo.query.results.channel.wind.speed)
  local yahoo_humidity = response_yahoo.query.results.channel.atmosphere.humidity
  local yahoo_temp = deg_fah2cel(response_yahoo.query.results.channel.item.condition.temp)
  local owm_windspeed = response_owm.wind.speed
  local owm_humidity = response_owm.main.humidity
  local owm_temp = response_owm.main.temp
  local owm_cloud = response_owm.clouds.all
  local own_lon = response_owm.coord.lon 
  local own_lat = response_owm.coord.lat
  local windspeed = (yahoo_windspeed+owm_windspeed)/2
  local humidity = (yahoo_humidity+owm_humidity)/2
  local temp = (yahoo_temp+owm_temp)/2
  
  local sunrise, sunset = rscalc(own_lat, own_lon) 
  local datetime = os.date("*t",os.time())
  
  local radiation_max = sun_radiation(datetime.month, own_lat, sunrise, sunset)
  local radiation_multiplier = sun_bright(sunrise, sunset, datetime.hour, datetime.min)/100
  local radiation_cloud_multiplier = normalize(0, 100, owm_cloud)/100
  local radiation = radiation_max*radiation_multiplier*radiation_cloud_multiplier
  
  local a_temp = apparent_temp(humidity, temp, windspeed, radiation)

  grp.update('W_Apparent_temp', a_temp)
  grp.update('W_Windspeed', windspeed)
  grp.update('W_Humidity', humidity)
  grp.update('W_Temperature', temp)
  grp.update('W_Sun_radiation', radiation)
  grp.update('W_Cloud', owm_cloud)
end
