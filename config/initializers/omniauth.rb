OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, '1056289671111906', 'e2adb04ef6ed37cbfaf7788f4e8f16f4'
end
