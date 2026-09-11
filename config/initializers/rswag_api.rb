Rswag::Api.configure do |c|
  # Root folder where the OpenAPI spec is served from
  c.openapi_root = Rails.root.to_s + '/swagger'
end
