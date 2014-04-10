require './loader'
require 'sinatra'

post '/receive_message' do
  msisdn = params[:From]
  tube_line = find_line(params[:Body])
  name = tube_line['Line']['Name']
  status = tube_line['Status']['Description']
  message = name +': '+ status
  send_message(msisdn, message)
end

def find_line(line)
  xml_to_json.find { |tube| tube['Line']['Name'] == line}
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