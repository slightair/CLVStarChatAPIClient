Pod::Spec.new do |s|
  s.name     = 'CLVStarChatAPIClient'
  s.version  = '0.1.0'
  s.license  = 'BSD'
  s.summary  = 'StarChat API Objective-C Client'
  s.homepage = 'https://github.com/slightair/CLVStarChatAPIClient'
  s.author   = { 'Tomohiro Moro' => 'arksutite@gmail.com' }
  s.source   = { :git => 'https://github.com/slightair/CLVStarChatAPIClient.git', :tag => '0.1.0' }
  s.source_files = 'CLVStarChatAPIClient/*.{h,m}'
  s.clean_paths = "StarChatAPIClientExample"
  s.requires_arc = true
  s.dependency 'AFNetworking'
  s.dependency 'SBJson'
end
