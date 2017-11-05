require "./spec_helper"

describe RealtimeService do
  # You can use get,post,put,patch,delete to call the corresponding route.
  it "renders /" do
    get "/"
    JSON.parse(response.body)["name"].should eq "Serdar"
  end
end
