module EE
  module Projects
    module MirrorsController
      extend ::Gitlab::Utils::Override
      extend ActiveSupport::Concern

      prepended do
        include SafeMirrorParams
      end

      def ssh_host_keys
        lookup = SshHostKey.new(project: project, url: params[:ssh_url])

        if lookup.error.present?
          # Failed to read keys
          render json: { message: lookup.error }, status: 400
        elsif lookup.known_hosts.nil?
          # Still working, come back later
          render body: nil, status: 204
        else
          render json: lookup
        end
      rescue ArgumentError => err
        render json: { message: err.message }, status: 400
      end

      override :update
      def update
        if project.update_attributes(safe_mirror_params)
          if project.mirror?
            project.force_import_job!

            flash[:notice] = "Mirroring settings were successfully updated. The project is being updated."
          elsif project.previous_changes.key?('mirror')
            flash[:notice] = "Mirroring was successfully disabled."
          else
            flash[:notice] = "Mirroring settings were successfully updated."
          end
        else
          flash[:alert] = project.errors.full_messages.join(', ').html_safe
        end

        respond_to do |format|
          format.html { redirect_to_repository_settings(project) }
          format.json do
            if project.errors.present?
              render json: project.errors, status: :unprocessable_entity
            else
              render json: ProjectMirrorSerializer.new.represent(project)
            end
          end
        end
      end

      override :update_now
      def update_now
        if params[:sync_remote]
          project.update_remote_mirrors
          flash[:notice] = "The remote repository is being updated..."
        else
          project.force_import_job!
          flash[:notice] = "The repository is being updated..."
        end

        redirect_to_repository_settings(project)
      end

      def mirror_params_attributes
        if can?(current_user, :admin_mirror, project)
          super + mirror_params_attributes_ee
        else
          super
        end
      end

      private

      def mirror_params_attributes_ee
        [
          :mirror,
          :import_url,
          :username_only_import_url,
          :mirror_user_id,
          :mirror_trigger_builds,
          :only_mirror_protected_branches,
          :mirror_overwrites_diverged_branches,

          import_data_attributes: %i[
            id
            auth_method
            password
            ssh_known_hosts
            regenerate_ssh_private_key
          ]
        ]
      end

      def safe_mirror_params
        params = mirror_params

        params[:mirror_user_id] = current_user.id unless valid_mirror_user?(params)

        import_data = params[:import_data_attributes]
        if import_data.present?
          # Prevent Rails from destroying the existing import data
          import_data[:id] ||= project.import_data&.id

          # If the known hosts data is being set, store details about who and when
          if import_data[:ssh_known_hosts].present?
            import_data[:ssh_known_hosts_verified_at] = Time.now
            import_data[:ssh_known_hosts_verified_by_id] = current_user.id
          end
        end

        params
      end
    end
  end
end
