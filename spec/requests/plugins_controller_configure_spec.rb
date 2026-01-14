require "rails_helper"

RSpec.describe "PluginsController Configuration", type: :request do
  let(:plugin_name) { "example" }

  describe "GET /plugins/:id/configure" do
    context "when authenticated" do
      before { sign_in }

      it "renders the configuration page" do
        get configure_plugin_path(plugin_name)

        expect(response).to have_http_status(:success)
      end

      it "renders the Plugins/Configure Inertia component" do
        get configure_plugin_path(plugin_name)

        expect(response.body).to include("Plugins/Configure")
      end

      it "includes plugin data in props" do
        get configure_plugin_path(plugin_name), headers: {
          "X-Inertia" => "true",
          "X-Inertia-Version" => ViteRuby.digest
        }

        json_response = JSON.parse(response.body)
        expect(json_response["component"]).to eq("Plugins/Configure")
        expect(json_response["props"]["plugin"]).to be_a(Hash)
        expect(json_response["props"]["plugin"]["plugin_name"]).to eq(plugin_name)
      end

      it "includes credential fields in props" do
        get configure_plugin_path(plugin_name), headers: {
          "X-Inertia" => "true",
          "X-Inertia-Version" => ViteRuby.digest
        }

        json_response = JSON.parse(response.body)
        expect(json_response["props"]["credential_fields"]).to be_an(Array)
        expect(json_response["props"]["credential_fields"].first["name"]).to eq("api_key")
      end

      it "includes setting fields in props" do
        get configure_plugin_path(plugin_name), headers: {
          "X-Inertia" => "true",
          "X-Inertia-Version" => ViteRuby.digest
        }

        json_response = JSON.parse(response.body)
        expect(json_response["props"]["setting_fields"]).to be_an(Array)
      end

      context "with existing credentials" do
        before do
          create(:plugin_configuration,
                 plugin_name: plugin_name,
                 credentials: { api_key: "secret_key_12345" }.to_json)
        end

        it "masks credential values" do
          get configure_plugin_path(plugin_name), headers: {
            "X-Inertia" => "true",
            "X-Inertia-Version" => ViteRuby.digest
          }

          json_response = JSON.parse(response.body)
          masked_key = json_response["props"]["credentials"]["api_key"]
          expect(masked_key).to include("*")
          expect(masked_key).to end_with("2345")
        end
      end

      context "with invalid plugin name" do
        it "redirects with error" do
          get configure_plugin_path("nonexistent")

          expect(response).to redirect_to(plugins_path)
          follow_redirect!
          expect(flash[:alert]).to include("not found")
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get configure_plugin_path(plugin_name)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "PATCH /plugins/:id/update_credentials" do
    context "when authenticated" do
      before { sign_in }

      it "saves credentials" do
        patch update_credentials_plugin_path(plugin_name), params: {
          credentials: { api_key: "new_secret_key", account_id: "acc_123" }
        }

        expect(response).to redirect_to(configure_plugin_path(plugin_name))
        follow_redirect!
        expect(flash[:notice]).to include("saved")

        config = PluginConfiguration.find_by(plugin_name: plugin_name)
        expect(config.credentials_hash["api_key"]).to eq("new_secret_key")
        expect(config.credentials_hash["account_id"]).to eq("acc_123")
      end

      it "replaces existing credentials" do
        create(:plugin_configuration,
               plugin_name: plugin_name,
               credentials: { old_key: "old_value" }.to_json)

        patch update_credentials_plugin_path(plugin_name), params: {
          credentials: { api_key: "new_key" }
        }

        config = PluginConfiguration.find_by(plugin_name: plugin_name)
        expect(config.credentials_hash["api_key"]).to eq("new_key")
        expect(config.credentials_hash["old_key"]).to be_nil
      end

      context "with invalid plugin name" do
        it "redirects to plugins index with error" do
          patch update_credentials_plugin_path("nonexistent"), params: {
            credentials: { api_key: "test" }
          }

          expect(response).to redirect_to(plugins_path)
          follow_redirect!
          expect(flash[:alert]).to include("not found")
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch update_credentials_plugin_path(plugin_name), params: {
          credentials: { api_key: "test" }
        }

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "PATCH /plugins/:id/update_settings" do
    context "when authenticated" do
      before { sign_in }

      it "saves settings" do
        patch update_settings_plugin_path(plugin_name), params: {
          settings: { sync_from_date: "2026-01-01", import_limit: "100" }
        }

        expect(response).to redirect_to(configure_plugin_path(plugin_name))
        follow_redirect!
        expect(flash[:notice]).to include("saved")

        config = PluginConfiguration.find_by(plugin_name: plugin_name)
        expect(config.settings_hash["sync_from_date"]).to eq("2026-01-01")
        expect(config.settings_hash["import_limit"]).to eq("100")
      end

      it "replaces existing settings" do
        create(:plugin_configuration,
               plugin_name: plugin_name,
               settings: { old_setting: "old_value" }.to_json)

        patch update_settings_plugin_path(plugin_name), params: {
          settings: { sync_from_date: "2026-01-01" }
        }

        config = PluginConfiguration.find_by(plugin_name: plugin_name)
        expect(config.settings_hash["sync_from_date"]).to eq("2026-01-01")
        expect(config.settings_hash["old_setting"]).to be_nil
      end

      context "with invalid plugin name" do
        it "redirects to plugins index with error" do
          patch update_settings_plugin_path("nonexistent"), params: {
            settings: { sync_from_date: "2026-01-01" }
          }

          expect(response).to redirect_to(plugins_path)
          follow_redirect!
          expect(flash[:alert]).to include("not found")
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch update_settings_plugin_path(plugin_name), params: {
          settings: { sync_from_date: "2026-01-01" }
        }

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /plugins/:id/clear_credentials" do
    context "when authenticated" do
      before do
        sign_in
        create(:plugin_configuration,
               plugin_name: plugin_name,
               credentials: { api_key: "secret" }.to_json)
      end

      it "clears all credentials" do
        delete clear_credentials_plugin_path(plugin_name)

        expect(response).to redirect_to(configure_plugin_path(plugin_name))
        follow_redirect!
        expect(flash[:notice]).to include("cleared")

        config = PluginConfiguration.find_by(plugin_name: plugin_name)
        expect(config.credentials).to be_nil
      end

      context "with invalid plugin name" do
        it "redirects to plugins index with error" do
          delete clear_credentials_plugin_path("nonexistent")

          expect(response).to redirect_to(plugins_path)
          follow_redirect!
          expect(flash[:alert]).to include("not found")
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        delete clear_credentials_plugin_path(plugin_name)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
