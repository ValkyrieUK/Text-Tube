class TwillioClient

  def send_message(msisdn, message)
    puts "Sending a #{message} to #{msisdn}"
    twillio.account.messages.create(
      from: from_number,
      to: msisdn,
      body: message
    )
    puts "Message send to #{msisdn}"
  end

  private

  def from_number
    ENV['TWILLIO_NUMBER']
  end

  def twillio
    account_sid ||= ENV['TWILLIO_SID']
    auth_token ||= ENV['TWILLIO_TOKEN']
    @twillio_client ||= Twilio::REST::Client.new account_sid, auth_token
  end
end