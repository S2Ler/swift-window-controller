Pod::Spec.new do |s|
  s.name             = "SystemWindowController"
  s.version          = "0.2.1"
  s.summary          = "iOS Window Controller"
  s.description      = <<-DESC
A controller to manage additional windows where you can pressent view controllers independent from main app.
                       DESC

  s.homepage         = "https://github.com/diejmon/SystemWindowController"
  s.license          = 'MIT'
  s.author           = { "Alexander Belyavskiy" => "diejmon@gmail.com" }
  s.source           = { :git => "https://github.com/diejmon/SystemWindowController.git", :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.source_files = 'Sources/**/*'
end
