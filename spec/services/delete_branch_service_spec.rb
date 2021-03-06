require 'spec_helper'

describe DeleteBranchService do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:user) { create(:user) }
  let(:service) { described_class.new(project, user) }

  shared_examples 'a deleted branch' do |branch_name|
    it 'removes the branch' do
      expect(branch_exists?(branch_name)).to be true

      result = service.execute(branch_name)

      expect(result[:status]).to eq :success
      expect(branch_exists?(branch_name)).to be false
    end
  end

  describe '#execute' do
    context 'when user has access to push to repository' do
      before do
        project.add_developer(user)
      end

      it_behaves_like 'a deleted branch', 'feature'
    end

    context 'when user does not have access to push to repository' do
      it 'does not remove branch' do
        expect(branch_exists?('feature')).to be true

        result = service.execute('feature')

        expect(result[:status]).to eq :error
        expect(result[:message]).to eq 'You dont have push access to repo'
        expect(branch_exists?('feature')).to be true
      end
    end

    context 'when there is a push rule matching the branch name' do
      before do
        project.add_developer(user)
        create(:push_rule, branch_name_regex: '^(w*)$')
      end

      it_behaves_like 'a deleted branch', 'add-pdf-file'
    end
  end

  def branch_exists?(branch_name)
    repository.ref_exists?("refs/heads/#{branch_name}")
  end
end
