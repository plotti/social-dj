class AccountsController < ApplicationController

	def index
		user_accounts = current_user.accounts
		puts user_accounts
		all_accounts = Account.where(:private => false).all.uniq.each{|s| s.selected = false} 
		if user_accounts == nil || user_accounts == []
			@accounts = all_accounts
		else
			@accounts = user_accounts + (all_accounts - user_accounts)
		end
	end

	def custom_accounts
		accounts = URI.extract(params["accounts"])
	    accounts.each do |account|
	    	name = account.split("/").last
	    	platform = account.gsub("//","").split("/").first.gsub("www","").gsub(".com","")
	    	link = account
	    	account = Account.create(:name => name, :platform => platform, :link => link, :private => true, :selected => true)
	    	current_user.accounts << account
	    end
	    redirect_to :controller => 'posts', :action => 'index' 
	end

	def update
		account = Account.find(params["account"]["id"])
		account.selected = true
		if params["account"]["selected"] == "1"
			current_user.accounts << account
		else
			current_user.accounts.delete(account)
		end
		render :nothing => true
	end

end