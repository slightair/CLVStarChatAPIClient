Pod::Spec.new do |s|
  s.name         = 'CLVStarChatAPIClient'
  s.version      = '0.2.3'
  s.license      = 'BSD'
  s.summary      = 'StarChat API Objective-C Client'
  s.homepage     = 'https://github.com/slightair/CLVStarChatAPIClient'
  s.author       = { 'Tomohiro Moro' => 'arksutite@gmail.com' }
  s.source       = { :git => 'https://github.com/slightair/CLVStarChatAPIClient.git', :tag => '0.2.3' }
  s.source_files = 'CLVStarChatAPIClient/*.{h,m}'
  s.clean_paths  = "StarChatAPIClientExample"
  s.requires_arc = true
  s.frameworks   = 'SystemConfiguration', 'CFNetwork'
  s.dependency 'AFNetworking'
  s.dependency 'SBJson'
  
  def s.post_install(target)
    prefix_header = config.project_pods_root + target.prefix_header_filename
    prefix_header.open('a') do |file|
      file.puts(%{#ifdef __OBJC__\n#import <SystemConfiguration/SystemConfiguration.h>\n#endif})
    end
  end
end
