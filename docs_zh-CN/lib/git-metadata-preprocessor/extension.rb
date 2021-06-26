require 'asciidoctor/extensions' unless RUBY_ENGINE == 'opal'

require 'rugged'
require 'pathname'

class GitMetadataPreprocessor < Asciidoctor::Extensions::Preprocessor
  def process document, reader

    begin
      repo = Rugged::Repository.discover('.')
    rescue
      $stderr.puts('Failed to find repository, git-metadata extension terminating')
      return
    end

    if repo.empty? || repo.bare?
      $stderr.puts('Repository is empty or bare repository, git-metadata extension terminating')
      return
    end

    doc_attrs = document.attributes
    head = repo.head

    doc_attrs['git-metadata-sha'] = head.target_id
    doc_attrs['git-metadata-sha-short'] = head.target_id.slice 0, 7
    doc_attrs['git-metadata-author-name'] = head.target.author[:name]
    doc_attrs['git-metadata-author-email'] = head.target.author[:email]
    doc_attrs['git-metadata-date'] = head.target.time.strftime '%Y-%m-%d'
    doc_attrs['git-metadata-time'] = head.target.time.strftime '%H:%M:%S'
    doc_attrs['git-metadata-timezone'] = head.target.time.strftime '%Z'
    doc_attrs['git-metadata-commit-message'] = head.target.message

    if repo.head_detached?
      doc_attrs['git-metadata-branch'] = 'HEAD detached'
    elsif repo.head_unborn?
      doc_attrs['git-metadata-branch'] = 'HEAD unborn'
    else
      doc_attrs['git-metadata-branch'] = repo.branches[head.name].name
    end

    tags = repo.tags
        .select {|t| t.target_id == head.target_id || (t.annotated? && t.annotation.target_id == head.target_id) }
        .map(&:name)
    doc_attrs['git-metadata-tag'] = tags * ', ' unless tags.empty?

    file_location = Pathname.new Dir.pwd
    repo_location = Pathname.new File.dirname(repo.path) # repo.path uses the .git directory
    doc_attrs['git-metadata-relative-path'] = repo_location.relative_path_from file_location
    doc_attrs['git-metadata-repo-path'] = repo_location.realpath

    if repo.remotes['origin']
      doc_attrs['git-metadata-remotes-origin'] = repo.remotes['origin'].url
    end

    nil
  end
end
