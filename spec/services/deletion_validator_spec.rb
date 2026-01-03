require 'rails_helper'

RSpec.describe DeletionValidator do
  describe ".can_delete_client?" do
    context "when client has no projects or invoices" do
      it "returns valid: true" do
        client = create(:client)

        result = described_class.can_delete_client?(client)

        expect(result[:valid]).to be true
      end
    end

    context "when client has projects" do
      it "returns valid: false with error message" do
        client = create(:client)
        create(:project, client: client)

        result = described_class.can_delete_client?(client)

        expect(result[:valid]).to be false
        expect(result[:error]).to include("projects")
      end
    end

    context "when client has invoices" do
      it "returns valid: false with error message" do
        client = create(:client)
        create(:invoice, client: client)

        result = described_class.can_delete_client?(client)

        expect(result[:valid]).to be false
        expect(result[:error]).to include("invoices")
      end
    end

    context "when client has both projects and invoices" do
      it "returns valid: false" do
        client = create(:client)
        create(:project, client: client)
        create(:invoice, client: client)

        result = described_class.can_delete_client?(client)

        expect(result[:valid]).to be false
      end
    end
  end

  describe ".can_delete_project?" do
    context "when project has no invoiced work entries" do
      it "returns valid: true" do
        project = create(:project)

        result = described_class.can_delete_project?(project)

        expect(result[:valid]).to be true
      end
    end

    context "when project has only unbilled work entries" do
      it "returns valid: true" do
        project = create(:project)
        create(:work_entry, project: project, status: :unbilled)

        result = described_class.can_delete_project?(project)

        expect(result[:valid]).to be true
      end
    end

    context "when project has invoiced work entries" do
      it "returns valid: false with error message" do
        project = create(:project)
        create(:work_entry, project: project, status: :invoiced)

        result = described_class.can_delete_project?(project)

        expect(result[:valid]).to be false
        expect(result[:error]).to include("invoiced")
      end
    end
  end
end
