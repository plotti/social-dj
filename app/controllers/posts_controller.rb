class PostsController < ActionController::Base
    def index
        accounts = YAML.load_file("#{Rails.root}/config/accounts.yml").collect{|s| URI.parse(s).path.gsub("/","")}
        @posts = []
        accounts.each do |account|
            logger.info("Working on #{account}.")
            result,url = Post.get_new_posts(account)
            if result == "error"
                system("open -a Safari #{url}")
            end
            #Cache those results. 
            #The more users request a page the less often you have to type in those captchas. 
            @posts += Post.get_new_posts(account)
        end
    end
end