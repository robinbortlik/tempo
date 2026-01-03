require 'rails_helper'

RSpec.describe LogoService do
  let(:settings) { Setting.instance }

  describe "#to_data_url" do
    context "when logo is attached" do
      before do
        settings.logo.attach(
          io: StringIO.new("fake image data"),
          filename: "logo.png",
          content_type: "image/png"
        )
      end

      it "returns a data URL with correct format" do
        service = described_class.new(settings)
        result = service.to_data_url

        expect(result).to start_with("data:image/png;base64,")
      end

      it "includes base64 encoded content" do
        service = described_class.new(settings)
        result = service.to_data_url

        base64_part = result.split(",").last
        expect { Base64.strict_decode64(base64_part) }.not_to raise_error
      end
    end

    context "when logo is not attached" do
      before do
        settings.logo.purge if settings.logo.attached?
      end

      it "returns nil" do
        service = described_class.new(settings)

        expect(service.to_data_url).to be_nil
      end
    end
  end

  describe ".to_data_url" do
    it "creates instance and calls to_data_url" do
      settings.logo.purge if settings.logo.attached?

      result = described_class.to_data_url(settings)

      expect(result).to be_nil
    end

    context "with attached logo" do
      before do
        settings.logo.attach(
          io: StringIO.new("fake image data"),
          filename: "logo.png",
          content_type: "image/png"
        )
      end

      it "returns data URL via class method" do
        result = described_class.to_data_url(settings)

        expect(result).to start_with("data:image/png;base64,")
      end
    end
  end
end
