class PostsController < ApplicationController    
    protect_from_forgery except: :post_to_facebook

    def login
        # if params["signed_request"] != nil
        #     session[:user_id] = Koala::Facebook::OAuth.new('1056289671111906','e2adb04ef6ed37cbfaf7788f4e8f16f4').parse_signed_request(params["signed_request"])["user_id"]
        #     redirect_to url_for(:action => :index)
        # end 
        if current_user != nil
            redirect_to url_for(:action => :index)
        end
    end

    def index
        if current_user == nil
            redirect_to("/signout")
        end
        if current_user.accounts == [] || current_user.accounts == nil
            redirect_to :controller => 'accounts', :action => 'index' 
        else
            @posts = Post.where(:account.in => current_user.accounts.collect{|s| s.link}).order_by(:time => 'desc').page(params[:page]).per(10)
        end
    end

    def saved
        @posts = current_user.posts.order_by(:time => 'desc').page(params[:page]).per(10)
        render :template => 'posts/index'
    end

    def adjust_ifttt_hook
        if request.post?
            current_user.ifttt_hook = params["ifttt_hook"]
            current_user.save
            redirect_to url_for(:action => :index)
        else
            if current_user.ifttt_hook == nil
                @ifttt_hook = "" #https://maker.ifttt.com/trigger/post_to_facebook/with/key/YOUR_IFTTT_HOOK_KEY"
            else
                @ifttt_hook = current_user.ifttt_hook
            end
        end
    end 

    def statistics
        @posts = current_user.posts.group_by(&:account)#.map{|key,val| {key => val.sum(&:posted_by)}}
    end

    def save
        post = Post.find(params["id"])
        current_user.posts << post
        respond_to do |format|
            format.js {   
                flash[:notice] = "Saved to your collection."
            }
        end
    end

    def post_to_facebook
        url = current_user.ifttt_hook
        image_url = request.protocol + request.host_with_port + params["image"].gsub("jpg/","jpg")
        title = params["title"] 
        logger.info("Posted #{image_url} with #{title}")
        post = Post.where(:id => params["id"]).first
        if image_url.include?("gif")
            title = "<a href='#{post.url}'>#{title}</a>"
        end
        post.posted_by << current_user.id
        post.save
        @result = HTTParty.post(url, 
        :body => {  
               :value1 => image_url, 
               :value2 => title,
             }.to_json,
        :headers => { 'Content-Type' => 'application/json' } )
        respond_to do |format|
            format.js {   
                flash[:notice] = "Posted Post to your facebook page!"
            }
        end
    end

end