require 'open-uri'
require 'json'
require 'yaml'

begin
 key = YAML.load(File.open("../private/config.yaml"))['key']
rescue ArgumentError => e
  puts "Could not parse YAML: #{e.message}"
end

open("http://api.wunderground.com/api/#{key}/conditions/q/SDF.json") do |f|
  json_string = f.read
  parsed_json = JSON.parse(json_string)
  temp_f = parsed_json['current_observation']['temp_f']
  precip_hr = parsed_json['current_observation']['precip_1hr_in']
  ob_time = parsed_json['current_observation']['observation_time']
  ob_epoch = parsed_json['current_observation']['observation_epoch']
  print "#{temp_f},#{precip_hr},#{ob_time},#{ob_epoch}\n"

  open('../private/output.csv', 'a') { |f|
     f.puts "#{temp_f},#{precip_hr},#{ob_time},#{ob_epoch}"
  }

end

