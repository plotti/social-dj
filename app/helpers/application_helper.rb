module ApplicationHelper
    def cp(path)
      "active" if request.url.include?(path)
    end

  

end
