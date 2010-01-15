module Integrity
  class Builder
    def self.build(b)
      new(b).build
    end

    def initialize(build)
      @build  = build
      @status = false
      @output = ""
    end

    def build
      start
      run
      complete
    end

    def start
      Integrity.log "Started building #{@build.project.uri} at #{commit}"

      repo.checkout

      metadata = repo.metadata

      @build.update(
        :started_at => Time.now,
        :commit     => {
          :identifier   => metadata["id"],
          :message      => metadata["message"],
          :author       => metadata["author"],
          :committed_at => metadata["timestamp"]
        }
      )
    end

    def complete
      Integrity.log "Build #{commit} exited with #{@status} got:\n #{@output}"

      @build.update!(
        :completed_at => Time.now,
        :successful   => @status,
        :output       => @output
      )

      @build.project.enabled_notifiers.each { |n| n.notify_of_build(@build) }
    end

    def run
      cmd = "(cd #{repo.directory} && RUBYOPT=#{clean_rubyopt} PATH=#{clean_path} && #{@build.project.command} 2>&1)"
      IO.popen(cmd, "r") { |io| @output = io.read }
      @status = $?.success?
    end

    def repo
      @repo ||= Repository.new(
        @build.id, @build.project.uri, @build.project.branch, commit
      )
    end

    def commit
      @build.commit.identifier
    end

    private
    
    def integrity_dir
      @integrity_dir ||= File.dirname(File.expand_path(File.join(File.dirname(__FILE__), "../")))
    end
    
    def clean_path
      ENV['PATH'].to_s.strip.split(':').reject{|path| path.include?(integrity_dir)}.join(':')
    end
    
    def clean_rubyopt
      ENV['RUBYOPT'].to_s.strip.split(' ').reject{|opt| opt.include?(integrity_dir)}.join(' ')
    end

  end
end
