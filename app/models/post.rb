class Post 
      include Mongoid::Document
      include Mongoid::Attributes::Dynamic

      def self.get_new_posts(account)
        results = Rails.cache.fetch("fetch_#{account}", :expires_in => 1.hours) do
            url = "http://rss-bridge.crossplatformanalytics.ch/?action=display&bridge=Facebook&u=#{account}&format=Html"
            result = HTTParty.get(url)
            if result.body.include?("Facebook captcha challenge")
                return ["error",url]
            end
            doc = Nokogiri::HTML(result.body)
            results = []
            doc.css(".feeditem").each do |item|
                image = item.css("a+ a img")[0]["src"] rescue []
                next if image == []
                title = item.css(".content").text.gsub(/.*·/,"")
                description = ""
                if title.length > 70 #more than 70 letters
                    tokenizer = Punkt::SentenceTokenizer.new(title)
                    segments = tokenizer.sentences_from_text(title, :output => :sentences_text)
                    description = segments[1..99].join(" ")
                    title = segments[0]
                end
                time = DateTime.parse(item.css("time").text)
                url = item.css(".itemtitle")[0]["href"]
                next if !url.include?(account) #usually repostes and other shit
                results << {:title => title, :image => image, :url => url, :time => time, :description => description}
            end
            results
        end
      end
end
