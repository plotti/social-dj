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
      mount_uploader :image, PostUploader
      validates_uniqueness_of :url

      def self.collect_new_posts
        accounts = User.all.collect{|s| s.accounts}.flatten
        accounts.each do |account|
            result = Post.get_new_posts(account)
            logger.info("Collected #{result.count} new items for #{account}. #{Post.count}")
        end
      end
  
      def self.get_new_posts(account)
        url = "http://rss-bridge.crossplatformanalytics.ch/?action=display&bridge=Facebook&u=#{account}&format=Html"
        result = HTTParty.get(url)
        path = Rails.root
        no_capcha_needed = true
        if result.body.include?("Facebook captcha challenge")
            no_capcha_needed = false
            logger.error("Capcha: Error collecting new items for #{url}.")
            logger.info("Trying to solve it.")
            command = "php -f #{path}/fb-captcha-solver.php '#{url}' attempts=10"
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
                p = Post.create_post(item,account)
                next if p == nil
                results << p
            end
            return results
        else
            logger.info("Could not solve capcha.")
        end
      end

      def self.create_post(item,account)
        url = item.css(".itemtitle")[0]["href"]
        post = Post.where(:url => url).first
        if post == nil
            logger.info("Collecting #{url} for #{account}")
            p = Post.new
            image_url = item.css("a+ a img")[0]["src"] rescue []
            if image_url != [] && image_url != nil
                p.image_url = image_url
                begin
                    p.image = open(image_url)
                rescue
                    logger.error("Something went wrong with #{image_url}")
                end
            else
                logger.error("Wrong image #{image_url}")
                return nil
            end
            title = item.css(".content").text.gsub(/.*·/,"")
            if title.length > 70 #more than 70 letters
                tokenizer = Punkt::SentenceTokenizer.new(title)
                segments = tokenizer.sentences_from_text(title, :output => :sentences_text)
                p.description = segments[1..99].join(" ")
                p.title = segments[0]
            else
                p.title = title
                p.description = ""
            end
            p.time = DateTime.parse(item.css("time").text)
            url = item.css(".itemtitle")[0]["href"]
            p.account = account
            if !url.include?(account)
                logger.info("URL #{url} does not contain account #{account}.")
                return nil #usually repostes and other shit
            else
                p.url = url
            end
            p.save!
            logger.info("Saved post with #{url}")
        else
            logger.info("Post with #{url} already exists.")
            p = post
        end
        return p
      end

end
