class Post 
      include Mongoid::Document
      include Mongoid::Attributes::Dynamic

      def self.get_new_posts(account)
        url = "https://rss-bridge.herokuapp.com/?action=display&bridge=Facebook&u=#{account}&format=Html"
        result = HTTParty.get(url)
        if result.body.include?("Facebook captcha challenge")
            return ["error",url]
        end
        doc = Nokogiri::HTML(result.body)
        return doc.css("img")
      end
end
