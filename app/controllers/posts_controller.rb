class PostsController < ApplicationController    
        protect_from_forgery except: :post_to_facebook

    def login
        if params["signed_request"] != nil
            session[:user_id] = Koala::Facebook::OAuth.new('1056289671111906','e2adb04ef6ed37cbfaf7788f4e8f16f4').parse_signed_request(params["signed_request"])["user_id"]
            redirect_to url_for(:action => :index)
        end 
        if current_user != nil
            redirect_to url_for(:action => :index)
        end
    end

    def index
        if current_user == nil
            redirect_to("/signout")
            #redirect_to url_for(:action => :login)
        end
        if current_user.accounts == []
            redirect_to url_for(:action => :set_up_accounts)
        elsif current_user.ifttt_hook == nil
            redirect_to url_for(:action => :adjust_ifttt_hook)
        else
            @posts = Post.where(:account.in => current_user.accounts).order_by(:time => 'desc').page(params[:page]).per(10)
        end
    end

    def set_up_accounts
        if request.post?
            accounts =  params["accounts"].split("\r").collect{|s| s.gsub("\n","")}
            puts accounts
            accounts = accounts.collect{|s| s.match(/www.facebook.com\/(.*)/)[1].gsub("/","") }
            current_user.accounts = accounts
            current_user.save
            redirect_to url_for(:action => :index)
        else
            if current_user.accounts == []
                @accounts = YAML.load_file("#{Rails.root}/config/accounts.yml").join("\n")
            else
                @accounts = current_user.accounts.collect{|s| "https://www.facebook.com/#{s}"}.join("\n")
            end
        end
    end

    def adjust_ifttt_hook
        if request.post?
            current_user.ifttt_hook = params["ifttt_hook"]
            current_user.save
            redirect_to url_for(:action => :index)
        else
            if current_user.ifttt_hook == nil
                @ifttt_hook = "https://maker.ifttt.com/trigger/post_to_facebook/with/key/YOUR_IFTTT_HOOK_KEY"
            else
                @ifttt_hook = current_user.ifttt_hook
            end
        end
    end 

    def post_to_facebook
        url = current_user.ifttt_hook
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