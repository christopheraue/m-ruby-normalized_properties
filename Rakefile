Dir.chdir File.dirname __FILE__

# Ruby
ruby = {test: "rspec"}

mruby_dir = File.expand_path "mruby_builds"
mruby = { src: "#{mruby_dir}/_source",
          cfg: "#{mruby_dir}/build_config.rb",
          test: "#{mruby_dir}/test/bin/mrbtest" }

namespace :test do
  desc "Run the Ruby test suite"
  task :ruby do
    sh ruby[:test]
  end

  desc "Run the mruby test suite"
  task :mruby, [:reference] => "mruby:build" do
    sh mruby[:test]
  end
end

desc "Run the Ruby and mruby test suites"
task test: %w(test:ruby test:mruby)

namespace :mruby do
  file mruby[:src] do
    sh "git clone git://github.com/mruby/mruby.git #{mruby[:src]}"
  end

  desc "Checkout a tag or commit of the mruby source. Executes: git checkout reference"
  task :checkout, [:reference] => mruby[:src] do |t, args|
    args.with_defaults reference: 'master'
    `cd #{mruby[:src]} && git fetch --tags`
    current_ref = `cd #{mruby[:src]} && git rev-parse HEAD`
    checkout_ref = `cd #{mruby[:src]} && git rev-parse #{args.reference}`
    if checkout_ref != current_ref
      Rake::Task['mruby:clean'].invoke
      sh "cd #{mruby[:src]} && git checkout #{args.reference}"
    end
  end

  desc "Build mruby"
  task :build, [:reference] => :checkout do
    sh "cd #{mruby[:src]} && MRUBY_CONFIG=#{mruby[:cfg]} rake"
  end

  desc "Clean the mruby build"
  task clean: mruby[:src] do
    sh "cd #{mruby[:src]} && MRUBY_CONFIG=#{mruby[:cfg]} rake deep_clean"
  end

  desc "Update the source of mruby"
  task pull: :clean do
    sh "cd #{mruby[:src]} && git pull"
  end

  desc "Delete the mruby source"
  task delete: mruby[:src] do
    sh "rm -rf #{mruby[:src]}"
  end
end

task default: :test