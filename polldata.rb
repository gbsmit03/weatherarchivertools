require 'open-uri'
require 'json'
require 'yaml'
require 'dbi'

begin
 parsedYaml = YAML.load(File.open("../private/config.yaml"))
 key = parsedYaml['key'] 
 stationList = parsedYaml['stations']
 dbName = parsedYaml['db']['name']
 dbHost = parsedYaml['db']['host']
 dbUser = parsedYaml['db']['user']
 dbPass = parsedYaml['db']['pass']
rescue ArgumentError => e
  puts "Could not parse YAML: #{e.message}"
end

#get station data
stationList.each do |station|
 print "getting station  #{station}\n"
  open("http://api.wunderground.com/api/#{key}/forecast/geolookup/conditions/q/pws:#{station}.json") do |f|
   json_string = f.read
   parsed_json = JSON.parse(json_string)
   temp_f = parsed_json['current_observation']['temp_f']
   precip_hr = parsed_json['current_observation']['precip_1hr_in']
   ob_time = parsed_json['current_observation']['observation_time']
   ob_epoch = parsed_json['current_observation']['observation_epoch']
   print "#{temp_f},#{precip_hr},#{ob_time},#{ob_epoch}\n"
   begin
     # connect to the MySQL server
     dbh = DBI.connect("DBI:Mysql:#{dbName}:#{dbHost}",
                            "#{dbUser}", "#{dbPass}")
     sth = dbh.prepare( "INSERT INTO weatherdata(stationid,
                   temperature,
                   preciphr,
                   lastupdatedtext,
                   lastupdatedepoch)
                   VALUES (?, ?, ?, ?, ?)" )
     sth.execute(station, temp_f, precip_hr, ob_time, ob_epoch)
     sth.finish
     dbh.commit
     print "Record has been created"
   rescue DBI::DatabaseError => e
     print "An error occurred"
     print "Error code:    #{e.err}"
     print "Error message: #{e.errstr}"
     dbh.rollback
   ensure
     # disconnect from server
     dbh.disconnect if dbh
   end
  end
end
