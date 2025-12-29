require 'rails_helper'

RSpec.describe Project, type: :model do
  describe "associations" do
    it "belongs to a client" do
      association = described_class.reflect_on_association(:client)
      expect(association.macro).to eq(:belongs_to)
    end

    it "is destroyed when client is destroyed" do
      client = create(:client)
      project = create(:project, client: client)
      expect { client.destroy }.to change(Project, :count).by(-1)
    end
  end

  describe "validations" do
    subject { build(:project) }

    it { is_expected.to be_valid }

    describe "name" do
      it "requires name to be present" do
        project = build(:project, name: nil)
        expect(project).not_to be_valid
        expect(project.errors[:name]).to include("can't be blank")
      end

      it "requires name to not be empty string" do
        project = build(:project, name: "")
        expect(project).not_to be_valid
        expect(project.errors[:name]).to include("can't be blank")
      end
    end

    describe "hourly_rate" do
      it "allows nil hourly_rate" do
        project = build(:project, hourly_rate: nil)
        expect(project).to be_valid
      end

      it "allows positive hourly_rate" do
        project = build(:project, hourly_rate: 100.00)
        expect(project).to be_valid
      end

      it "allows zero hourly_rate" do
        project = build(:project, hourly_rate: 0)
        expect(project).to be_valid
      end

      it "rejects negative hourly_rate" do
        project = build(:project, hourly_rate: -50)
        expect(project).not_to be_valid
        expect(project.errors[:hourly_rate]).to include("must be greater than or equal to 0")
      end

      it "allows decimal hourly_rate" do
        project = build(:project, hourly_rate: 125.50)
        expect(project).to be_valid
      end
    end

    describe "client" do
      it "requires a client" do
        project = build(:project)
        project.client = nil
        expect(project).not_to be_valid
        expect(project.errors[:client]).to include("must exist")
      end
    end
  end

  describe "scopes" do
    let!(:active_project) { create(:project, active: true) }
    let!(:inactive_project) { create(:project, active: false) }

    describe ".active" do
      it "returns only active projects" do
        expect(Project.active).to contain_exactly(active_project)
      end
    end

    describe ".inactive" do
      it "returns only inactive projects" do
        expect(Project.inactive).to contain_exactly(inactive_project)
      end
    end
  end

  describe "#effective_hourly_rate" do
    let(:client) { create(:client, hourly_rate: 120.00) }

    context "when project has its own hourly_rate" do
      it "returns the project's hourly_rate" do
        project = create(:project, client: client, hourly_rate: 150.00)
        expect(project.effective_hourly_rate).to eq(150.00)
      end

      it "returns zero when project rate is zero" do
        project = create(:project, client: client, hourly_rate: 0)
        expect(project.effective_hourly_rate).to eq(0)
      end
    end

    context "when project has no hourly_rate" do
      it "returns the client's hourly_rate" do
        project = create(:project, client: client, hourly_rate: nil)
        expect(project.effective_hourly_rate).to eq(120.00)
      end
    end

    context "when neither project nor client has hourly_rate" do
      it "returns nil" do
        client_without_rate = create(:client, hourly_rate: nil)
        project = create(:project, client: client_without_rate, hourly_rate: nil)
        expect(project.effective_hourly_rate).to be_nil
      end
    end
  end

  describe "default values" do
    it "defaults active to true" do
      project = Project.new
      expect(project.active).to be true
    end
  end

  describe "factory" do
    it "creates a valid project" do
      project = build(:project)
      expect(project).to be_valid
    end

    it "creates a project with associated client" do
      project = create(:project)
      expect(project.client).to be_present
    end

    it "creates an inactive project" do
      project = build(:project, :inactive)
      expect(project.active).to be false
    end

    it "creates a project without rate" do
      project = build(:project, :without_rate)
      expect(project.hourly_rate).to be_nil
    end

    it "creates a project with custom rate" do
      project = build(:project, :with_custom_rate, rate: 200.00)
      expect(project.hourly_rate).to eq(200.00)
    end

    it "generates unique names with sequence" do
      project1 = create(:project)
      project2 = create(:project)
      expect(project1.name).not_to eq(project2.name)
    end
  end
end
