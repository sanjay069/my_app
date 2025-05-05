require 'net/http'
require 'uri'
require 'json'
require 'googleauth'

class NotificationsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    fcm_token = params[:fcm_token]
    title     = params[:title]
    body      = params[:body]

    if fcm_token.blank? || title.blank? || body.blank?
      return render json: { error: "Missing parameters" }, status: :bad_request
    end

    response = send_fcm_notification(fcm_token, title, body)
    if response.code.to_i == 200
      render json: { success: "Notification sent" }, status: :ok
    else
      render json: { error: "Failed to send", details: response.body }, status: :unprocessable_entity
    end
  end

  private

  def send_fcm_notification(token, title, body)
    # Load your Firebase service account JSON key
    scope = ['https://www.googleapis.com/auth/firebase.messaging']
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open('config/credentials/fcm-service-account.json'),
      scope: scope
    )
    authorizer.fetch_access_token!

	  uri = URI.parse("https://fcm.googleapis.com/v1/projects/myfcmtestproject-7c8ec/messages:send")
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true

    headers = {
      "Authorization" => "Bearer #{authorizer.access_token}",
      "Content-Type" => "application/json"
    }

    payload = {
      message: {
        token: token,
        notification: {
          title: title,
          body: body
        }
      }
    }

    request = Net::HTTP::Post.new(uri.path, headers)
    request.body = payload.to_json
    https.request(request)
  end
end
