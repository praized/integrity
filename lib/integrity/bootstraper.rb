module Integrity
  def self.bootstrap(&block)
    Bootstraper.new(&block)
  end

  class Bootstraper
    class Project < Struct.new(:name, :scm, :uri, :branch, :command, :public)
      def public
        @public = true
      end

      def private
        @public = false
      end

      def save
        update
        fail "#{project.errors.full_messages.join(", ")}" unless project.valid?
        project.save
      end

      private
        def project
          @project ||= Integrity::Project.first_or_create(:name => name)
        end

        def update
          project.scm     = scm
          project.uri     = uri
          project.branch  = branch
          project.command = command
          project.public  = @public
        end
    end

    def initialize
      yield self
    end

    def project(name)
      project = Project.new(name)
      yield project
      project.save
    end
  end
end
