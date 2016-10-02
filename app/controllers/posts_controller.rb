class PostsController < ApplicationController    
        protect_from_forgery except: :post_to_facebook

    def login
        if current_user != nil
            redirect_to url_for( :action => :index)
        end
    end

    def index
        @posts = Post.where(:account.in => current_user.accounts).order_by(:time => 'desc').page(params[:page]).per(10)
    end

    def post_to_facebook
        url = "https://maker.ifttt.com/trigger/post_to_facebook/with/key/dp2XUqkdrC8BxnED9mzsqE"
        image_url = request.protocol + request.host_with_port + params["image"].gsub("jpg/","jpg")
        logger.info("Posted #{image_url} with #{params["title"]}")
        @result = HTTParty.post(url, 
        :body => {  
               :value1 => image_url, 
               :value2 => params["title"] 
             }.to_json,
        :headers => { 'Content-Type' => 'application/json' } )
        respond_to do |format|
            format.js {   
                flash[:notice] = "Posted Post to your facebook page!"
            }
        end
    end

end