module IssueLinks
  class DestroyService < IssuableLinks::DestroyService
    private

    def source
      @source ||= link.source
    end

    def target
      @target ||= link.target
    end

    def permission_to_remove_relation?
      can?(current_user, :admin_issue_link, source) && can?(current_user, :admin_issue_link, target)
    end

    def create_notes
      SystemNoteService.unrelate_issue(source, target, current_user)
      SystemNoteService.unrelate_issue(target, source, current_user)
    end
  end
end
