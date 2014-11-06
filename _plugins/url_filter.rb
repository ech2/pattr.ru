module Jekyll
  module PattrUrlFilter
    def img(img_url, alt="")
      "<a href=\"#{img_url}\" target=\"_blank\">
        <img alt=\"#{alt}\" src=\"#{img_url}\"></img>
      </a>"
    end

    def url(title, url)
      "<a href=\"#{url}\" target=\"_blank\">#{title}</a>"
    end
    
  end
end

Liquid::Template.register_filter(Jekyll::PattrUrlFilter)
