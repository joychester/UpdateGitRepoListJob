require 'eventmachine'
require 'em-http-request'
require 'json'

Git_URI = "https://api.github.com/api/v3/orgs/:orgname/repos?page=1&per_page=100"
token = "token sometokenwhichcanbeused"
json_body=""

EM.run do 
	conn = EM::HttpRequest.new(Git_URI)
	http = conn.get :header => {"Content-Type" => "application/json" , "Authorization" => token}

	http.callback {
		json_body = http.response
		EM.stop
	}

	http.errback {
		p "Something wrong with the github remote server"
		EM.stop
	}
end

app_repo_list,domain_repo_list,qe_repo_list,ecomm_repo_list,others = Array.new(5){[]}
# the key(is a symbol) should be the same as file name
repo_list_hash = {:app_list => app_repo_list, :domain_list => domain_repo_list, :qe_list => qe_repo_list, :ecomm_list => ecomm_repo_list}

parsed = JSON.parse(json_body)
parsed.each do |h|
	repo_name = h["ssh_url"] 
	if repo_name.include?("app-")
	 	app_repo_list << repo_name
	elsif repo_name.include?("domain-")
	 	domain_repo_list << repo_name
	elsif repo_name.include?("qe-")
	 	qe_repo_list << repo_name
	elsif repo_name.include?("ecomm-")
	 	ecomm_repo_list << repo_name
	else
		others << repo_name
	end
end

#update the git_list file for each type of repo
def dump_updated_repo_list(repo_file_name, repo_list)
	p "updating #{repo_file_name} file..."

	if File.exist?("#{repo_file_name}") && File.writable?("#{repo_file_name}")
		f = File.open("#{repo_file_name}", "w+")
		f.truncate(0)
		repo_list.each do |l| 
			f.puts(l)
		end
		f.close()
		p "updating #{repo_file_name} file completed!"
	else
		p "can not find writable file for #{repo_file_name}, please double check..."
	end
end

#loop process all type of git repo list
repo_list_hash.each do |git_file_name, repo_array|
	dump_updated_repo_list(git_file_name, repo_array)
end
