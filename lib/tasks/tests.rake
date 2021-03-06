namespace :vivo do
  desc "Runs all tests"
  task :tests do
    Dir.glob("./test/**/*_test.rb").each do |file|
      require file
    end
  end

  desc "Runs tests in the file indicated"
  task :test, [:file_name] => :environment do |cmd, args|
    file = args[:file_name]
    abort "No file name was received" if file == nil
    require file
  end

  # desc "Runs tests related to solr_lite"
  # task :testsolr do
  #   Dir.glob("./test/lib/solr_lite/*_test.rb").each do |file|
  #     require file
  #   end
  # end
end
