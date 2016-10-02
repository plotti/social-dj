class PostsController < ApplicationController    
    def index
        accounts = YAML.load_file("#{Rails.root}/config/accounts.yml").collect{|s| URI.parse(s).path.gsub("/","")}
        @results = []
        accounts[0..3].each do |account|
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

    def post_to_facebook
        page_id = "1858588047709172"
        podcast_date = podcast.date.strftime('%m/%d')
        graph = Koala::Facebook::API.new(settings.facebook_access_token)
        graph.put_object(page_id, "feed", {
            :name => "#{podcast.title} - #{podcast.speaker}, #{podcast_date}",
            :link => podcast.audio_url,
            :message => "New Podcast for #{podcast_date} is Available!"
        })
    end

end