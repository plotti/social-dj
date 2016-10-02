class PostsController < ApplicationController    
    def index
        accounts = YAML.load_file("#{Rails.root}/config/accounts.yml").collect{|s| URI.parse(s).path.gsub("/","")}
        @results = []
        accounts[0..1].each do |account|
            logger.info("Working on #{account}.")
            result,url = Post.get_new_posts(account)
            if result == "error"
                system("open -a Safari #{url}")
            end
            @results += Post.get_new_posts(account)
        end
        @results = @results.sort{|a,b| a[:time] <=> b[:time]}.reverse
        @results = Kaminari.paginate_array(@results).page(params[:page]).per(10)
    end
end