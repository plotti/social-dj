class Post 
      include Mongoid::Document
      include Mongoid::Attributes::Dynamic


      field :title, type: String, default: ""
      field :description, type: String, default: ""
      field :time, type: DateTime
      field :url, type: String, default: ""
      field :account, type: String, default: ""
      field :movie_poster, type: String
      field :image_url, type: String, default: ""
      field :posted_by, type:Array, default: []
      mount_uploader :image, PostUploader
      validates_uniqueness_of :url
      validates_uniqueness_of :title

      def self.dedupe
        # find all models and group them on keys which should be common
        grouped = all.group_by{|model| [model.title] }
        grouped.values.each do |duplicates|
          # the first one we want to keep right?
          first_one = duplicates.shift # or pop for last one
          # if there are any more left, they are duplicates
          # so delete all of them
          duplicates.each{|double| double.destroy} # duplicates can now be destroyed
        end
      end

      def self.collect_new_posts
        accounts = User.all.collect{|s| s.accounts}.flatten
        accounts.each do |account|
            results = Post.get_new_posts(account)
            logger.info("Collected #{results.count} new items for #{account}. #{Post.count}")
        end
      end
  
      def self.get_new_posts(account_url)
        if account_url.include?("facebook")
          results = Post.get_new_fb_posts(account_url)
        elsif account_url.include?("twitter")
          results = Post.get_new_twitter_posts(account_url)
        elsif account_url.include?("instagram")
          results = Post.get_new_instagram_posts(account_url)
        elsif account_url.include?("reddit")
          results = Post.get_new_reddit_posts(account_url)
        else
          logger.info("Type of account not supported yet: #{account_url}")
        end
      end

      def self.get_new_reddit_posts(account_url="https://www.reddit.com/r/woahdude.rss")
        feed = Feedjira::Feed.fetch_and_parse account_url
        feed.entries.each do |entry|
            url = entry.url
            post = Post.where(:url => url).first
            if post == nil
                logger.info("Collecting #{url} for #{account_url}")
                p = Post.new
                begin
                    image_url = Nokogiri::HTML(entry.content).at('a:contains("link")')["href"].gsub(".gifv",".mp4")
                    p.remote_image_url = image_url#,{ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE})
                rescue
                    logger.error("Something went wrong with #{image_url}")
                end
                p.title = entry.title
                p.description = ""
                p.account = account_url
                p.url = url
                p.time = entry.updated.to_datetime
                if p.remote_image_url != nil
                    begin
                        p.save!
                        logger.info("Saved post with #{url}")
                    rescue
                        logger.info("Turns out that post already exists?! #{url}")
                    end
                else
                    logger.info("Skipped post #{url} because it did't have images.")
                end
            else
                logger.info("Post with #{url} already exists.")
                p = post
            end
        end
      end

      def self.get_new_twitter_posts(account_url)
        account = account_url.match(/twitter.com\/(.*)/)[1].gsub("/","")
        url = "http://rss-bridge.crossplatformanalytics.ch/?action=display&bridge=Twitter&u=#{account}&format=Html"
        result = HTTParty.get(url)
        doc = Nokogiri::HTML(result.body)
        results = []
        doc.css(".feeditem").each do |item|
            p = Post.create_post(item,account_url)
            next if p == nil
            results << p
        end
        return results
      end

      def self.get_new_instagram_posts(account_url)
        account = account_url.match(/instagram.com\/(.*)/)[1].gsub("/","")
        url = "http://rss-bridge.crossplatformanalytics.ch/?action=display&bridge=Instagram&u=#{account}&format=Html"
        result = HTTParty.get(url)
        doc = Nokogiri::HTML(result.body)
        results = []
        doc.css(".feeditem").each do |item|
            p = Post.create_post(item,account_url,{:image_selector => "img", :text_selector => "h2"})
            next if p == nil
            results << p
        end
        return results
      end


      def self.get_new_fb_posts(account_url)
        account = account_url.match(/www.facebook.com\/(.*)/)[1].gsub("/","")
        url = "http://rss-bridge.crossplatformanalytics.ch/?action=display&bridge=Facebook&u=#{account}&format=Html"
        result = HTTParty.get(url)
        path = Rails.root
        results = []
        no_capcha_needed = true
        if result.body.include?("Facebook captcha challenge")
            no_capcha_needed = false
            logger.error("Capcha: Error collecting new items for #{url}.")
            logger.info("Trying to solve it.")
            command = "php -f #{path}/fb-captcha-solver.php '#{url}' 10"
            logger.info(command)
            result = `#{command}`
            logger.info(result)
            if result.include?("Successfully")
                no_capcha_needed = true
            end
        end
        if no_capcha_needed
            result = HTTParty.get(url)
            doc = Nokogiri::HTML(result.body)
            results = []
            doc.css(".feeditem").each do |item|
                p = Post.create_post(item,account_url)
                next if p == nil
                results << p
            end
            return results
        else
            logger.info("Could not solve capcha.")
        end
        return results
      end

      def download_image(item,selector="a+ a img")
        item.css(selector).each do |image|
            next if image["src"].include? "50x50" #we got the icon
            image_url = image["src"]
            if image_url != [] && image_url != nil
                self.image_url = image_url
                begin
                    logger.info("Downloading Image url #{image_url}")
                    self.remote_image_url = image_url#,{ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE})
                    #self.image = open(image_url,{ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE})
                rescue
                    logger.error("Something went wrong with #{image_url}")
                end
            else
                logger.error("Wrong image #{image_url}")
            end
        end
      end

      def set_title_and_description(item,selector=".content")
        title = item.css(selector).text.gsub(/.*·/,"")
        if title.length > 70 #more than 70 letters
            tokenizer = Punkt::SentenceTokenizer.new(title)
            segments = tokenizer.sentences_from_text(title, :output => :sentences_text)
            self.description = segments[1..99].join(" ")
            if segments[0].length > 70
                temp = segments[0].truncate(70)
            else
                temp = segments[0]
            end
            self.title = temp
        else
            self.title = title
            self.description = ""
        end
      end

      def set_url(item)
        url = item.css(".itemtitle")[0]["href"]
        if !url.include?(account) && url.include?("fbcdn")
            logger.info("URL #{url} does not contain account #{account}.")
            return nil #usually repostes and other shit
        else
            self.url = url
        end
      end

      def set_time(item)
        time = item.css("time").text
        self.time = DateTime.parse(time)
      end


      def self.create_post(item,account,options={})
        default_options = {:image_selector => "a+ a img", :text_selector => ".content"}
        options = default_options.merge(options)
        url = item.css(".itemtitle")[0]["href"]
        post = Post.where(:url => url).first
        if post == nil
            logger.info("Collecting #{url} for #{account}")
            p = Post.new
            p.download_image(item,options[:image_selector])
            p.set_title_and_description(item,options[:text_selector])
            p.account = account
            p.set_url(item)
            p.set_time(item)
            if p.image != nil
                begin
                    p.save!
                    logger.info("Saved post with #{url}")
                rescue
                    logger.info("Turns out that post already exists?! #{url}")
                end
            else
                logger.info("Skipped post #{url} because it did't have images.")
            end
        else
            logger.info("Post with #{url} already exists.")
            p = post
        end
        return p
      end

end
