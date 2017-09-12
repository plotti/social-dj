class Account 
      extend ActiveModel::Naming
      include ActiveModel::Conversion

      include Mongoid::Document
      include Mongoid::Attributes::Dynamic
      belongs_to :user

      field :name, type: String, default: ""
      field :platform, type: String, default: ""
      field :category, type: String
      field :link, type: String, default: ""
      field :image, type: String, default: "logos/placeholder.jpg"
      field :description, type:String, default: ""
      field :selected, type:Boolean, default: false
      field :private, default: false

      def self.read_in_accounts()
      	accounts = YAML.load_file("#{Rails.root}/config/accounts.yml").values.flatten
      	accounts.each do |account|
      		Account.create(account)
      	end
      end

end
