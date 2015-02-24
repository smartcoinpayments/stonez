```ruby
Stonez.configure do |config|
ENV['STONE_USE_SSL'    ] == "true"
  config.merchant_id = "abc"
  config.hostname    = "hostname"
  config.root_path   = ""
  config.port        = "80"
  config.use_ssl     = false
end
```
