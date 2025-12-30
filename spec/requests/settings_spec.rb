require 'rails_helper'

RSpec.describe SettingsController, type: :request do
  describe "GET /settings" do
    context "when authenticated" do
      before { sign_in }

      it "returns a successful response" do
        get settings_path
        expect(response).to have_http_status(:success)
      end

      it "renders the Settings/Show Inertia component" do
        get settings_path
        expect(response.body).to include('Settings/Show')
      end

      it "creates settings if none exist" do
        expect { get settings_path }.to change(Setting, :count).from(0).to(1)
      end

      it "returns existing settings data" do
        setting = create(:setting, company_name: "Test Company")
        get settings_path
        expect(response.body).to include('Test Company')
      end

      it "responds to Inertia requests with JSON" do
        setting = create(:setting, company_name: "Acme Corp", email: "info@acme.com")

        get settings_path, headers: {
          'X-Inertia' => 'true',
          'X-Inertia-Version' => ViteRuby.digest
        }

        expect(response).to have_http_status(:success)
        expect(response.headers['X-Inertia']).to eq('true')
        expect(response.content_type).to include('application/json')

        json_response = JSON.parse(response.body)
        expect(json_response['component']).to eq('Settings/Show')
        expect(json_response['props']['settings']['company_name']).to eq('Acme Corp')
        expect(json_response['props']['settings']['email']).to eq('info@acme.com')
      end

      it "includes logo_url when logo is attached" do
        setting = create(:setting, :with_logo)

        get settings_path, headers: {
          'X-Inertia' => 'true',
          'X-Inertia-Version' => ViteRuby.digest
        }

        json_response = JSON.parse(response.body)
        expect(json_response['props']['settings']['logo_url']).to be_present
      end

      it "returns nil logo_url when no logo is attached" do
        create(:setting)

        get settings_path, headers: {
          'X-Inertia' => 'true',
          'X-Inertia-Version' => ViteRuby.digest
        }

        json_response = JSON.parse(response.body)
        expect(json_response['props']['settings']['logo_url']).to be_nil
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get settings_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "PATCH /settings" do
    context "when authenticated" do
      before { sign_in }

      context "with valid params" do
        it "updates the settings" do
          setting = create(:setting, company_name: "Old Name")

          patch settings_path, params: {
            setting: { company_name: "New Name" }
          }

          expect(setting.reload.company_name).to eq("New Name")
        end

        it "redirects to settings with success notice" do
          create(:setting)

          patch settings_path, params: {
            setting: { company_name: "Updated Company" }
          }

          expect(response).to redirect_to(settings_path)
          follow_redirect!
          expect(flash[:notice]).to eq("Settings saved successfully.")
        end

        it "updates all settings fields" do
          setting = create(:setting, :minimal)

          patch settings_path, params: {
            setting: {
              company_name: "Acme Corp",
              address: "123 Main St",
              email: "contact@acme.com",
              phone: "+1-555-0100",
              vat_id: "VAT123",
              company_registration: "REG456",
              bank_name: "First Bank",
              bank_account: "1234567890",
              bank_swift: "FIRSTBANK"
            }
          }

          setting.reload
          expect(setting.company_name).to eq("Acme Corp")
          expect(setting.address).to eq("123 Main St")
          expect(setting.email).to eq("contact@acme.com")
          expect(setting.phone).to eq("+1-555-0100")
          expect(setting.vat_id).to eq("VAT123")
          expect(setting.company_registration).to eq("REG456")
          expect(setting.bank_name).to eq("First Bank")
          expect(setting.bank_account).to eq("1234567890")
          expect(setting.bank_swift).to eq("FIRSTBANK")
        end
      end

      context "with invalid params" do
        it "redirects with an error message for invalid email" do
          create(:setting)

          patch settings_path, params: {
            setting: { email: "invalid-email" }
          }

          expect(response).to redirect_to(settings_path)
          follow_redirect!
          expect(flash[:alert]).to include("Email")
        end
      end

      context "with logo upload" do
        it "attaches the logo" do
          setting = create(:setting)
          logo_file = fixture_file_upload(
            Rails.root.join('spec/fixtures/files/test_logo.png'),
            'image/png'
          )

          patch settings_path, params: {
            setting: { logo: logo_file }
          }

          expect(setting.reload.logo).to be_attached
        end

        it "replaces existing logo" do
          setting = create(:setting, :with_logo)
          original_blob_id = setting.logo.blob.id

          new_logo = fixture_file_upload(
            Rails.root.join('spec/fixtures/files/test_logo.png'),
            'image/png'
          )

          patch settings_path, params: {
            setting: { logo: new_logo }
          }

          setting.reload
          expect(setting.logo).to be_attached
          expect(setting.logo.blob.id).not_to eq(original_blob_id)
        end
      end

      context "when settings don't exist" do
        it "creates settings on update" do
          expect(Setting.count).to eq(0)

          patch settings_path, params: {
            setting: { company_name: "New Company" }
          }

          expect(Setting.count).to eq(1)
          expect(Setting.first.company_name).to eq("New Company")
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch settings_path, params: {
          setting: { company_name: "Test" }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
