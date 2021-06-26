require 'asciidoctor/extensions' unless RUBY_ENGINE == 'opal'

# A docinfo processor that appends the Google Analytics code to the bottom of the HTML.
#
# Usage
#
#   :google-analytics-account: UA-XXXXXXXX-1
#
# Requires Asciidoctor >= 1.5.2
Asciidoctor::Extensions.register do
  if @document.basebackend? 'html'
    docinfo_processor do
      at_location :footer
      process do |doc|
        next unless (ga_account_id = doc.attr 'google-analytics-account')
        %(<script>
(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
})(window,document,'script','https://www.google-analytics.com/analytics.js','ga');
ga('create','#{ga_account_id}','auto');
ga('send','pageview');
</script>)
      end
    end
  end
end
