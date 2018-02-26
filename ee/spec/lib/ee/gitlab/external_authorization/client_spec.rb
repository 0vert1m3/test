require 'spec_helper'

describe EE::Gitlab::ExternalAuthorization::Client do
  let(:user) { build(:user, email: 'dummy_user@example.com') }
  let(:dummy_url) { 'https://dummy.net/' }
  subject(:client) { described_class.build(user, 'dummy_label') }

  before do
    stub_application_setting(external_authorization_service_url: dummy_url)
  end

  describe '#request_access' do
    it 'performs requests to the configured endpoint' do
      expect(Excon).to receive(:post).with(dummy_url, any_args)

      client.request_access
    end

    it 'adds the correct params for the user to the body of the request' do
      expected_body = {
        user_identifier: 'dummy_user@example.com',
        project_classification_label: 'dummy_label'
      }.to_json
      expect(Excon).to receive(:post)
                         .with(dummy_url, hash_including(body: expected_body))

      client.request_access
    end

    it 'returns an expected response' do
      expect(Excon).to receive(:post)

      expect(client.request_access)
        .to be_kind_of(::EE::Gitlab::ExternalAuthorization::Response)
    end

    it 'wraps exceptions if the request fails' do
      expect(Excon).to receive(:post) { raise Excon::Error.new('the request broke') }

      expect { client.request_access }
        .to raise_error(EE::Gitlab::ExternalAuthorization::RequestFailed)
    end

    describe 'for ldap users' do
      let(:user) do
        create(:omniauth_user,
               email: 'dummy_user@example.com',
               extern_uid: 'external id',
               provider: 'ldapprovider')
      end

      it 'includes the ldap dn for ldap users' do
        expected_body = {
          user_identifier: 'dummy_user@example.com',
          project_classification_label: 'dummy_label',
          user_ldap_dn: 'external id'
        }.to_json
        expect(Excon).to receive(:post)
                           .with(dummy_url, hash_including(body: expected_body))

        client.request_access
      end
    end
  end
end