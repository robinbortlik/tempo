require "rails_helper"

RSpec.describe "PluginsController History", type: :request do
  let(:plugin_name) { "example" }

  describe "GET /plugins/:id/history" do
    context "when authenticated" do
      before { sign_in }

      it "renders the history page" do
        get history_plugin_path(plugin_name)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Plugins/History")
      end

      it "includes sync histories in props" do
        create(:sync_history, plugin_name: plugin_name, status: :completed)
        create(:sync_history, plugin_name: plugin_name, status: :failed)

        get history_plugin_path(plugin_name), headers: {
          "X-Inertia" => "true",
          "X-Inertia-Version" => ViteRuby.digest
        }

        json_response = JSON.parse(response.body)
        expect(json_response["component"]).to eq("Plugins/History")
        expect(json_response["props"]["sync_histories"]).to be_an(Array)
        expect(json_response["props"]["sync_histories"].length).to eq(2)
      end

      it "includes stats in props" do
        3.times { create(:sync_history, plugin_name: plugin_name, status: :completed) }

        get history_plugin_path(plugin_name), headers: {
          "X-Inertia" => "true",
          "X-Inertia-Version" => ViteRuby.digest
        }

        json_response = JSON.parse(response.body)
        expect(json_response["props"]["stats"]).to be_a(Hash)
        expect(json_response["props"]["stats"]["total_syncs"]).to eq(3)
      end

      it "includes plugin info in props" do
        get history_plugin_path(plugin_name), headers: {
          "X-Inertia" => "true",
          "X-Inertia-Version" => ViteRuby.digest
        }

        json_response = JSON.parse(response.body)
        expect(json_response["props"]["plugin"]).to be_a(Hash)
        expect(json_response["props"]["plugin"]["plugin_name"]).to eq(plugin_name)
      end

      context "with invalid plugin name" do
        it "redirects with error" do
          get history_plugin_path("nonexistent")

          expect(response).to redirect_to(plugins_path)
          follow_redirect!
          expect(response.body).to include("not found")
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get history_plugin_path(plugin_name)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /plugins/:id/sync/:sync_id" do
    context "when authenticated" do
      before { sign_in }

      let!(:sync_history) do
        create(:sync_history,
               plugin_name: plugin_name,
               status: :completed,
               started_at: 2.minutes.ago,
               completed_at: 1.minute.ago,
               records_processed: 10,
               records_created: 5,
               records_updated: 3)
      end

      it "renders the sync detail page" do
        get show_sync_plugin_path(plugin_name, sync_id: sync_history.id)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Plugins/SyncDetail")
      end

      it "includes sync history detail in props" do
        get show_sync_plugin_path(plugin_name, sync_id: sync_history.id), headers: {
          "X-Inertia" => "true",
          "X-Inertia-Version" => ViteRuby.digest
        }

        json_response = JSON.parse(response.body)
        expect(json_response["component"]).to eq("Plugins/SyncDetail")
        expect(json_response["props"]["sync_history"]).to be_a(Hash)
        expect(json_response["props"]["sync_history"]["id"]).to eq(sync_history.id)
        expect(json_response["props"]["sync_history"]["records_processed"]).to eq(10)
      end

      it "includes audit entries in props" do
        create(:data_audit_log,
               sync_history: sync_history,
               source: plugin_name,
               action: :create_action,
               auditable_type: "MoneyTransaction",
               auditable_id: 1)

        get show_sync_plugin_path(plugin_name, sync_id: sync_history.id), headers: {
          "X-Inertia" => "true",
          "X-Inertia-Version" => ViteRuby.digest
        }

        json_response = JSON.parse(response.body)
        expect(json_response["props"]["sync_history"]["audit_entries"]).to be_an(Array)
        expect(json_response["props"]["sync_history"]["audit_entries"].length).to eq(1)
      end

      context "when sync doesn't exist" do
        it "redirects with error" do
          get show_sync_plugin_path(plugin_name, sync_id: 99999)

          expect(response).to redirect_to(history_plugin_path(plugin_name))
          follow_redirect!
          expect(response.body).to include("not found")
        end
      end

      context "when sync belongs to different plugin" do
        let!(:other_sync) { create(:sync_history, plugin_name: "other_plugin", status: :completed) }

        it "redirects with error" do
          get show_sync_plugin_path(plugin_name, sync_id: other_sync.id)

          expect(response).to redirect_to(history_plugin_path(plugin_name))
          follow_redirect!
          expect(response.body).to include("not found")
        end
      end
    end

    context "when not authenticated" do
      let!(:sync_history) { create(:sync_history, plugin_name: plugin_name, status: :completed) }

      it "redirects to login" do
        get show_sync_plugin_path(plugin_name, sync_id: sync_history.id)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
