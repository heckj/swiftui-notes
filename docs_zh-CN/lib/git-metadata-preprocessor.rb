RUBY_ENGINE == 'opal' ?
  (require 'git-metadata-preprocessor/extension') :
  (require_relative 'git-metadata-preprocessor/extension')

Asciidoctor::Extensions.register do
  preprocessor GitMetadataPreprocessor
end
