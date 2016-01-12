require 'ltn12'
json = require("json")
local https = require 'ssl.https'
local http = require 'socket.http'

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
    log(body, code, hdrs, stat)
    return
  end
  return json.decode(table.concat(response_body))
end


response = http_get('https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20weather.forecast%20where%20woeid%20in%20(select%20woeid%20from%20geo.places(1)%20where%20text%3D%22moscow%2C%20ru%22)&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys', true)
yahoo_windspeed = speed_milh2ms(response.query.results.channel.wind.speed)
yahoo_humidity = response.query.results.channel.atmosphere.humidity
yahoo_temp = deg_fah2cel(response.query.results.channel.item.condition.temp)

response = http_get('http://api.openweathermap.org/data/2.5/weather?q=moscow,ru&appid=95473e638011a52a5ddd7ebeec959926&units=metric', false)
owm_windspeed = response.wind.speed
owm_humidity = response.main.humidity
owm_temp = response.main.temp
owm_cloud = response.clouds.all
own_lon = response.coord.lon 
own_lat = response.coord.lat


datetime = os.date("*t",os.time())
m = datetime.month 
h = datetime.hour 

if (m == 12 or m == 1 or m == 2 or m == 3 or m == 4) then
  radiation = 300
elseif (m == 5 or m == 6 or m == 11 or m == 10 or m == 9) then
	radiation = 500
elseif (m == 7 or m == 8) then
	radiation = 800
end

sunrise, sunset = rscalc(own_lat, own_lon) 
sunrise = math_round((sunrise/60),0) 
sunset = math_round((sunset/60),0) 
noon = math_round(sunrise+(sunset-sunrise)/2, 0)
radiation_multiplier = normalize(noon-sunrise, 0, true, math.abs(noon-h))/100

radiation = radiation*radiation_multiplier

a_temp_yahoo = apparent_temp(yahoo_humidity, yahoo_temp, yahoo_windspeed, radiation)
a_temp_owm = apparent_temp(owm_humidity, owm_temp, owm_windspeed, radiation)
a_temp = math_round((a_temp_yahoo+a_temp_owm)/2, 1)

--log(a_temp)
grp.update('Apparent temp', a_temp)

