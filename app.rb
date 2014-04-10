require './loader'
require 'sinatra'

post '/receive_message' do
  msisdn = params[:From]
  puts "Okay, Got a Text from #{msisdn}!!"
  tube_line = find_line(params[:Body])
  if tube_line
    puts "#{msisdn} Provided nice params"
    message = create_message(tube_line)
    send_message(msisdn, message)
  else
    puts "#{msisdn} Provided bad, going to guess which line they ment"
    tube_line = guess_tube_line(params[:Body])
    if tube_line
      puts "Guessed the station for #{msisdn}"
      message = create_message(tube_line)
      send_message(msisdn, message)
    else
      puts "Still looking #{msisdn}"
      tube_line = dlr_and_central(params[:Body])
      puts tube_line
      message = create_message(tube_line)
      send_message(msisdn, message)
    end
  end
end

def find_line(line)
  xml_to_json.find { |tube| tube['Line']['Name'] == line}
end

def guess_tube_line(line)
  case line[0]
  when 'B', 'b'
    find_line('Bakerloo')
  when 'J', 'j'
    find_line('Jubilee')
  when 'L', 'l'
    find_line('London Overground')
  when 'M', 'm'
    find_line('Metropolitan')
  when 'N', 'n'
    find_line('Northern')
  when 'P', 'p'
    find_line('Piccadilly')
  when 'V', 'v'
    find_line('Victoria')
  when 'W', 'w'
    find_line('Waterloo & City')
  when 'H', 'h'
    find_line('Hammersmith and City')
  end
end

def dlr_and_central(line)
  case line
  when 'dis', 'Dis', 'district'
    find_line('District')
  when 'DRL', 'dlr', 'Dlr'
    find_line('DLR')
  when 'circle', 'cirlec', 'cir'
    find_line('Circle')
  when  'central', 'cen'
    find_line('Central')
  end
end

def xml_to_json
  puts 'API request to TFL'
  xml = HTTParty.get('http://cloud.tfl.gov.uk/TrackerNet/LineStatus')
  Crack::XML.parse(xml.body)['ArrayOfLineStatus']['LineStatus']
end

def send_message(msisdn, message)
  twillio.send_message(msisdn, message)
end

def twillio
  @client ||= TwillioClient.new
end

def create_message(tube_line)
  puts 'Creating the message'
  name = tube_line['Line']['Name']
  status = tube_line['Status']['Description']
  if status == 'Good Service'
    puts 'Service is good, no need for description'
    '🚈' + '👍' + name +': '+ status
  else
    puts 'Service is bad, creating a description'
    description = tube_line['StatusDetails']
    '🚈' + '👎' + name + ': ' + status + ': ' + description
  end
end