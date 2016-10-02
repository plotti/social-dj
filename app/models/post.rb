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
        accounts = YAML.load_file("#{Rails.root}/config/accounts.yml").collect{|s| URI.parse(s).path.gsub("/","")}
        accounts.each do |account|
            Post.get_new_posts(account)
        end
      end
  
      def self.get_new_posts(account)
        url = "http://rss-bridge.crossplatformanalytics.ch/?action=display&bridge=Facebook&u=#{account}&format=Html"
        result = HTTParty.get(url)
        if result.body.include?("Facebook captcha challenge")
            return ["error",url]
        end
        doc = Nokogiri::HTML(result.body)
        results = []
        doc.css(".feeditem").each do |item|
            p = Post.create_post(item,account)
            next if p == nil
            results << p
        end
        return results
      end

      def self.create_post(item,account)
        url = item.css(".itemtitle")[0]["href"]
        post = Post.where(:url => url).first
        if post == nil
            logger.info("Collecting #{url} for #{account}")
            p = Post.new
            p.image_url = item.css("a+ a img")[0]["src"] rescue []
            if p.image_url == [] || p.image_url == nil
                return nil
            else
                p.image = open(p.image_url)
            end
            p.title = item.css(".content").text.gsub(/.*·/,"")
            p.description = ""
            if p.title.length > 70 #more than 70 letters
                tokenizer = Punkt::SentenceTokenizer.new(p.title)
                segments = tokenizer.sentences_from_text(p.title, :output => :sentences_text)
                description = segments[1..99].join(" ")
                title = segments[0]
            end
            p.time = DateTime.parse(item.css("time").text)
            p.url = item.css(".itemtitle")[0]["href"]
            p.account = account
            if !p.url.include?(account)
                return nil #usually repostes and other shit
            end
            p.save!
        else
            p = post
        end
        return p
      end

end
