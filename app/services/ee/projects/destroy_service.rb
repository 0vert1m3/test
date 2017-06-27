module EE
  module Projects
    module DestroyService
      def execute
        raise NotImplementedError unless defined?(super)

        super

        log_geo_event(project)
      end

      def log_geo_event(project)
        ::Geo::RepositoryDeletedEventStore.new(project,
          repo_path: repo_path,
          wiki_path: wiki_path).create
      end

      # Removes physical repository in a Geo replicated secondary node
      # There is no need to do any database operation as it will be
      # replicated by itself.
      def geo_replicate
        # Flush the cache for both repositories. This has to be done _before_
        # removing the physical repositories as some expiration code depends on
        # Git data (e.g. a list of branch names).
        flush_caches(project, wiki_path)

        trash_repositories!
        remove_tracking_entries!
        log_info("Project \"#{project.name}\" was removed")
      end
    end
  end
end