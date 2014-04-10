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
      message = create_message(tube_line)
      send_message(msisdn, message)
    else
      tube_line = dlr_and_central(params[:Body])
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
  end
end

def dlr_and_central(line)
  case line
  when 'DRL', 'dlr', 'Dlr'
    find_line('DLR')
  when 'District', 'Disrtict', 'Dis', 'dis', 'district'
    find_line('Disrict')
  when 'circle', 'cirlec', 'cir'
    find_line('Circle')
  when 'Central', 'central', 'cen'
    find_line('Central')
  end
end

def xml_to_json
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
  name = tube_line['Line']['Name']
  status = tube_line['Status']['Description']
  if status == 'Good Service'
    '🚈' + '👍' + name +': '+ status
  else
    description = tube_line['StatusDetails']
    '🚈' + '👎' + name + ': ' + status + ': ' + description
  end
end