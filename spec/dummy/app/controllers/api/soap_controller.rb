class Api::SoapController < ApplicationController
  def index
    tpl = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
    XML

    render plain: tpl, status: :ok, content_type: "application/xrd+xml"
  end
end
