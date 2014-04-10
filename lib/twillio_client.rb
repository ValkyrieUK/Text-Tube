class TwillioClient

  def send_message(msisdn, message)
    # puts msisdn
    # puts message
    twillio.account.messages.create(
      from: from_number,
      to: msisdn,
      body: message
    )
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