namespace :reference do
  desc "Clone the reference repository to the specified location, unless the repository already exists."
  task :clone do
    repo_path = File.expand_path(Rails.my_config(:reference_repository_path))
    unless File.exist?(repo_path)
      Dir.chdir(File.dirname(repo_path)) do
        cmd = "/usr/bin/env git clone #{ENV['G5KAPI_REFERENCE_REPOSITORY']} #{File.basename(repo_path)}"
        puts cmd
        system cmd
      end
    end
  end
  
  task :update => :clone do
    
  end
end