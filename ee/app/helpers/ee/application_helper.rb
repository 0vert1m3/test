module EE
  module ApplicationHelper
    extend ::Gitlab::Utils::Override

    override :read_only_message
    def read_only_message
      return super unless ::Gitlab::Geo.secondary_with_primary?

      (_('You are on a secondary (read-only) Geo node. If you want to make any changes, you must visit the %{primary_node}.') %
        { primary_node: link_to('primary node', ::Gitlab::Geo.primary_node.url) }).html_safe
    end

    def render_ce(partial, locals = {})
      render template: find_ce_partial(partial), locals: locals
    end

    def find_ce_partial(partial)
      ce_lookup_context.find(partial, [], true)
    end

    def ce_lookup_context
      @ce_lookup_context ||= begin
        context = lookup_context.dup

        # This could duplicate the paths we're going to modify
        context.view_paths = lookup_context.view_paths.paths

        # Discard lookup path ee/ for the new paths
        context.view_paths.paths.delete_if do |resolver|
          resolver.to_path.start_with?("#{Rails.root}/ee")
        end

        context
      end
    end

    def page_class
      class_names = super
      class_names += system_message_class

      class_names
    end

    def system_message_class
      class_names = []

      return class_names unless appearance

      class_names << 'with-system-header' if appearance.show_header?
      class_names << 'with-system-footer' if appearance.show_footer?

      class_names
    end

    override :autocomplete_data_sources
    def autocomplete_data_sources(object, noteable_type)
      return {} unless object && noteable_type

      return super unless object.is_a?(Group)

      {
        members: members_group_autocomplete_sources_path(object, type: noteable_type, type_id: params[:id])
      }
    end

    private

    def appearance
      ::Appearance.current
    end
  end
end
