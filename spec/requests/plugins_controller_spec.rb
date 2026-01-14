require "rails_helper"

RSpec.describe "PluginsController", type: :request do
  describe "GET /plugins" do
    context "when authenticated" do
      before { sign_in }

      it "renders the plugins index page" do
        get plugins_path

        expect(response).to have_http_status(:success)
      end

      it "renders the Plugins/Index Inertia component" do
        get plugins_path

        expect(response.body).to include("Plugins/Index")
      end

      it "includes all registered plugins in props" do
        get plugins_path, headers: {
          "X-Inertia" => "true",
          "X-Inertia-Version" => ViteRuby.digest
        }

        json_response = JSON.parse(response.body)
        expect(json_response["component"]).to eq("Plugins/Index")
        expect(json_response["props"]["plugins"]).to be_an(Array)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get plugins_path

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "PATCH /plugins/:id/enable" do
    let(:plugin_name) { "example" }

    context "when authenticated" do
      before { sign_in }

      it "enables the plugin" do
        patch enable_plugin_path(plugin_name)

        expect(response).to redirect_to(plugins_path)
        follow_redirect!

        config = PluginConfiguration.find_by(plugin_name: plugin_name)
        expect(config.enabled).to be true
      end

      it "shows success notice" do
        patch enable_plugin_path(plugin_name)

        expect(response).to redirect_to(plugins_path)
        follow_redirect!
        expect(flash[:notice]).to include("enabled")
      end

      context "with invalid plugin name" do
        it "shows error alert" do
          patch enable_plugin_path("nonexistent")

          expect(response).to redirect_to(plugins_path)
          follow_redirect!
          expect(flash[:alert]).to include("not found")
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch enable_plugin_path(plugin_name)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "PATCH /plugins/:id/disable" do
    let(:plugin_name) { "example" }

    context "when authenticated" do
      before do
        sign_in
        create(:plugin_configuration, plugin_name: plugin_name, enabled: true)
      end

      it "disables the plugin" do
        patch disable_plugin_path(plugin_name)

        expect(response).to redirect_to(plugins_path)

        config = PluginConfiguration.find_by(plugin_name: plugin_name)
        expect(config.enabled).to be false
      end

      it "shows success notice" do
        patch disable_plugin_path(plugin_name)

        expect(response).to redirect_to(plugins_path)
        follow_redirect!
        expect(flash[:notice]).to include("disabled")
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch disable_plugin_path(plugin_name)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /plugins/:id/sync" do
    let(:plugin_name) { "example" }

    context "when authenticated" do
      before { sign_in }

      context "when plugin is enabled and configured" do
        before do
          create(:plugin_configuration,
                 plugin_name: plugin_name,
                 enabled: true,
                 credentials: { api_key: "test_api_key_12345" }.to_json)
        end

        it "executes plugin sync" do
          expect {
            post sync_plugin_path(plugin_name)
          }.to change(SyncHistory, :count).by(1)

          expect(response).to redirect_to(plugins_path)
        end

        it "shows success notice on successful sync" do
          post sync_plugin_path(plugin_name)

          expect(response).to redirect_to(plugins_path)
          follow_redirect!
          expect(flash[:notice]).to include("sync completed")
        end
      end

      context "when plugin is not enabled" do
        before do
          create(:plugin_configuration, plugin_name: plugin_name, enabled: false)
        end

        it "shows error alert" do
          post sync_plugin_path(plugin_name)

          expect(response).to redirect_to(plugins_path)
          follow_redirect!
          expect(flash[:alert]).to include("failed")
        end
      end

      context "when plugin is not configured" do
        before do
          create(:plugin_configuration,
                 plugin_name: plugin_name,
                 enabled: true,
                 credentials: nil)
        end

        it "shows error alert" do
          post sync_plugin_path(plugin_name)

          expect(response).to redirect_to(plugins_path)
          follow_redirect!
          expect(flash[:alert]).to include("failed")
        end
      end

      context "when plugin does not exist" do
        it "shows error alert" do
          post sync_plugin_path("nonexistent")

          expect(response).to redirect_to(plugins_path)
          follow_redirect!
          expect(flash[:alert]).to include("not found")
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post sync_plugin_path(plugin_name)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
