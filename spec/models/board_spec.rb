require 'rails_helper'

describe Board do
  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:milestone) }
    it { is_expected.to have_one(:board_assignee) }
    it { is_expected.to have_one(:assignee).through(:board_assignee) }
    it { is_expected.to have_many(:board_labels) }
    it { is_expected.to have_many(:labels).through(:board_labels) }

    it { is_expected.to have_many(:lists).order(list_type: :asc, position: :asc).dependent(:delete_all) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:project) }
  end
end
