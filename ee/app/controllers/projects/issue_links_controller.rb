module Projects
  class IssueLinksController < Projects::ApplicationController
    include IssuableLinks

    before_action :authorize_admin_issue_link!, only: [:create, :destroy]
    before_action :authorize_issue_link_association!, only: :destroy

    private

    def issues
      IssueLinks::ListService.new(issue, current_user).execute
    end

    def authorize_admin_issue_link!
      render_403 unless can?(current_user, :admin_issue_link, @project)
    end

    def authorize_issue_link_association!
      render_404 if link.target != issue && link.source != issue
    end

    def issue
      @issue ||=
        IssuesFinder.new(current_user, project_id: @project.id)
                    .execute
                    .find_by!(iid: params[:issue_id])
    end

    def create_service
      IssueLinks::CreateService.new(issue, current_user, create_params)
    end

    def destroy_service
      IssueLinks::DestroyService.new(link, current_user)
    end

    def link
      @link ||= IssueLink.find(params[:id])
    end
  end
end
