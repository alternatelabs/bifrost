require "json"
require "./spec_helper"

describe Bifrost do
  describe "GET /" do
    # You can use get,post,put,patch,delete to call the corresponding route.
    it "renders" do
      get "/"
      response.body.should contain "Bifröst is an open source websocket server"
    end
  end

  describe "GET /info.json" do
    it "returns stats" do
      get "info.json"
      resp = JSON.parse(response.body)
      resp["stats"]["connected"].should eq 0
      resp["stats"]["deliveries"].should eq 0
    end
  end

  describe "POST /broadcast" do
    context "invalid JWT" do
      it "returns bad request" do
        payload = {
          exp: Time.now.epoch + 3600, # 1 hour
        }
        jwt = JWT.encode(payload, "bad-secret-key", "HS512")
        post "/broadcast", headers: HTTP::Headers{"Content-Type" => "application/json"}, body: {token: jwt}.to_json

        response.status_code.should eq 400
        json = JSON.parse(response.body)
        json["error"].should eq("Bad signature")
      end
    end

    context "expired JWT" do
      it "returns bad request" do
        payload = {
          exp: Time.now.epoch - 10,
        }
        jwt = JWT.encode(payload, ENV["JWT_SECRET"], "HS512")
        post "/broadcast", headers: HTTP::Headers{"Content-Type" => "application/json"}, body: {token: jwt}.to_json

        response.status_code.should eq 400
        json = JSON.parse(response.body)
        json["error"].should eq("Bad signature")
      end
    end

    context "valid JWT" do
      it "returns success" do
        payload = {
          exp:     Time.now.epoch + 3600,
          channel: "user:12",
          message: {test: "test"}.to_json,
        }
        jwt = JWT.encode(payload, ENV["JWT_SECRET"], "HS512")
        post "/broadcast", headers: HTTP::Headers{"Content-Type" => "application/json"}, body: {token: jwt}.to_json

        response.status_code.should eq 200
        json = JSON.parse(response.body)
        json["message"].should eq("Success")
      end
    end
  end
end
