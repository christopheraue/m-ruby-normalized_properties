require_relative 'lib/all/normalized_properties/version'

MRuby::Gem::Specification.new('mruby-normalized_properties') do |spec|
  spec.version       = NormalizedProperties::VERSION
  spec.summary       = %q{Normalized properties for models}
  spec.description   = %q{Normalized properties for models}

  spec.homepage     = "https://github.com/christopheraue/m-ruby-normalized_properties"
  spec.license      = 'Apache-2.0'
  spec.authors      = ['Christopher Aue']

  unless system("git merge-base --is-ancestor 5a9eedf5417266b82e3695ae0c29797182a5d04e HEAD")
    # mruby commit 5a9eedf fixed the usage of spec.rbfiles. mruby 1.3.0
    # did not have that commit, yet. Add the patch for this case:
    @generate_functions = true
    @objs << objfile("#{build_dir}/gem_init")
  end

  spec.rbfiles      =
    Dir["#{spec.dir}/lib/all/**/*.rb"].sort +
    Dir["#{spec.dir}/lib/mruby/**/*.rb"].sort
  spec.test_rbfiles = Dir["#{spec.dir}/test/mruby/*.rb"]

  spec.add_dependency 'mruby-hash-ext', :core => 'mruby-hash-ext'
  spec.add_dependency 'mruby-callbacks_attachable', '~> 3.0', github: 'christopheraue/m-ruby-callbacks_attachable'
end
