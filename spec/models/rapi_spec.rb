require 'spec_helper'

describe F5::Icontrol::RAPI do
  let(:host) { 'somehost' }
  let(:username) { 'me' }
  let(:password) { 'secret' }
  let(:base64) { Base64.encode64("#{username}:#{password}") }

  let(:baseurl) { "https://#{host}" }

  before(:all) { VCR.turn_off! }

  subject { F5::Icontrol::RAPI.new(username: username, password: password, host: host) }

  describe "asking for a collection" do
    context "collections" do
      it "gets the collection on the root node" do
        stub_request(:get, baseurl).
          to_return(body: pool_collection)
        subject.get_collection
        expect(WebMock).to have_requested(:get, "#{baseurl}/")
      end

      it "calls the url based on the method chain" do
        stub_request(:get, "#{baseurl}/foo/bar/").
          to_return(body: pool_collection)
        subject.foo.bar.get_collection
        expect(WebMock).to have_requested(:get, "#{baseurl}/foo/bar/")
      end

      it "returns an array of resources" do
        stub_request(:get, "#{baseurl}/foo/bar/").
          to_return(body: pool_collection)

        bars = subject.foo.bar.get_collection

        expect(bars).to be_an_instance_of(Array)
        expect(bars.first).to be_an_instance_of(F5::Icontrol::RAPI::Resource)
      end

      it "converts underscores to dashes in the call" do
        stub_request(:get, "#{baseurl}/foo-bar/").
          to_return(body: pool_collection)

        subject.foo_bar.get_collection

        expect(WebMock).to have_requested(:get, "#{baseurl}/foo-bar/")
      end
    end

    context "subcollections" do
      it "resolves the url based on the method chain and object id" do
        stub_request(:get, "#{baseurl}/mgmt/ltm/pool/").
          to_return(body: pool_collection)

        pools = subject.mgmt.ltm.pool.get_collection

        stub_request(:get, "#{baseurl}/mgmt/tm/ltm/pool/~Common~reallybasic/members?ver=11.5.1").
          to_return(body: pool_collection)

        pool = pools.first.members.load

        expect(WebMock).to have_requested(:get, "#{baseurl}/mgmt/tm/ltm/pool/~Common~reallybasic/members?ver=11.5.1")
      end

      it "understands `each` implicitly calls `get_collection`" do
        stub_request(:get, "#{baseurl}/foo/bar/").
          to_return(body: pool_collection)

        bars = subject.foo.bar.each

        expect(bars).to be_an_instance_of(Enumerator)
      end

    end
  end

  def pool_collection
    '{"kind":"tm:ltm:pool:poolcollectionstate","selfLink":"https://localhost/mgmt/tm/ltm/pool?ver=11.5.1","items":[{"kind":"tm:ltm:pool:poolstate","name":"reallybasic","partition":"Common","fullPath":"/Common/reallybasic","generation":845,"selfLink":"https://localhost/mgmt/tm/ltm/pool/~Common~reallybasic?ver=11.5.1","allowNat":"yes","allowSnat":"yes","ignorePersistedWeight":"disabled","ipTosToClient":"pass-through","ipTosToServer":"pass-through","linkQosToClient":"pass-through","linkQosToServer":"pass-through","loadBalancingMode":"round-robin","minActiveMembers":0,"minUpMembers":0,"minUpMembersAction":"failover","minUpMembersChecking":"disabled","queueDepthLimit":0,"queueOnConnectionLimit":"disabled","queueTimeLimit":0,"reselectTries":0,"slowRampTime":10,"membersReference":{"link":"https://localhost/mgmt/tm/ltm/pool/~Common~reallybasic/members?ver=11.5.1","isSubcollection":true}},{"kind":"tm:ltm:pool:poolstate","name":"reallybasic2","partition":"Common","fullPath":"/Common/reallybasic2","generation":819,"selfLink":"https://localhost/mgmt/tm/ltm/pool/~Common~reallybasic2?ver=11.5.1","allowNat":"yes","allowSnat":"yes","ignorePersistedWeight":"disabled","ipTosToClient":"pass-through","ipTosToServer":"pass-through","linkQosToClient":"pass-through","linkQosToServer":"pass-through","loadBalancingMode":"round-robin","minActiveMembers":0,"minUpMembers":0,"minUpMembersAction":"failover","minUpMembersChecking":"disabled","queueDepthLimit":0,"queueOnConnectionLimit":"disabled","queueTimeLimit":0,"reselectTries":0,"slowRampTime":10,"membersReference":{"link":"https://localhost/mgmt/tm/ltm/pool/~Common~reallybasic2/members?ver=11.5.1","isSubcollection":true}}]}'
  end
end