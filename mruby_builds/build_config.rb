MRuby::Build.new do
  if ENV['VisualStudioVersion'] || ENV['VSINSTALLDIR']
    toolchain :visualcpp
  else
    toolchain :gcc
  end

  enable_debug
end

MRuby::Build.new 'test', File.dirname(__FILE__) do
  self.gem_clone_dir = "#{MRUBY_ROOT}/build/mrbgems"

  if ENV['VisualStudioVersion'] || ENV['VSINSTALLDIR']
    toolchain :visualcpp
  else
    toolchain :gcc
  end

  enable_test
  gem File.expand_path File.dirname File.dirname __FILE__
end