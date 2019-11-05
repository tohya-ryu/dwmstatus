require 'date'
require 'open_weather'
require 'resolv'

def has_internet?
  # https://stackoverflow.com/a/22837368
  begin
    dns_resolver = Resolv::DNS.new()
    dns_resolver.getaddress(DNS_CHECK_ADDRESS)
    return true
  rescue StandardError
    return false
  end
end

fork {
  weather_wait_thread = Thread.new { }
  weather_wait_thread.join
  dns_wait_thread = Thread.new { }
  dns_wait_thread.join
  temp = " ??.??°C"
  internetf = false
  connstate = ""
  while true do
=begin
    unless dns_wait_thread.alive?
      internetf = has_internet?
      dns_wait_thread = Thread.new {
        sleep DNS_CHECK_INTERVAL
      }
    end
=end
    unless weather_wait_thread.alive?
      excaught = false
      tmp = temp
      options = { units: "metric", APPID: OPEN_WEATHER_API_KEY }
      begin
        out = OpenWeather::Current.city_id(OPEN_WEATHER_CITY_ID, options)
      rescue StandardError
        excaught = true
      end
      unless excaught
        if out.is_a?(Hash)
          if out.has_key?('main')
            if out['main'].is_a?(Hash)
              if out['main'].has_key?('temp')
                tmp = out['main']['temp']
                tmp = tmp.to_s
                if tmp.length < 6
                  s = 6 - tmp.length
                  while s > 0
                    tmp.prepend(" ")
                    s -= 1
                  end
                end
                tmp << "°C"
              end
            end
          end
        end
      end
      temp = tmp
      weather_wait_thread = Thread.new {
        sleep OPEN_WEATHER_INTERVAL
      }
    end

    if has_internet?
      connstate = "[C-I]"
    else
      connstate = "[C-O]"
    end

    ibus_engine = %x{ ibus engine }
    user = %x{ whoami }
    host = %x{ hostname }
    battery_capacity = %x{ cat /sys/class/power_supply/BAT0/capacity }
    battery_status = %x{ cat /sys/class/power_supply/BAT0/status }
    user.delete!("\n")
    host.delete!("\n")
    battery_capacity.delete!("\n")
    battery_status.delete!("\n")
    ibus_engine = "[EN]" if ibus_engine == "xkb:us::eng\n"
    ibus_engine = "[JP]" if ibus_engine == "anthy\n"
    battery_status = "[=]" if battery_status == "Full"
    battery_status = "[<]" if battery_status == "Discharging"
    battery_status = "[>]" if battery_status == "Charging"
    datetime = Time.now.strftime("%a %Y-%m-%d %H:%M:%S")
    str = "#{user}@#{host} "
    str << "#{ibus_engine} BAT(#{battery_capacity}#{battery_status}) "
    str << "#{connstate} "
    str << "#{temp} #{datetime}"
    %x{ xsetroot -name " #{str} " }
    sleep 1
  end
}
