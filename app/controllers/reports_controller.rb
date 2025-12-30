# Public controller for client report portal
# Accessible via share_token, no authentication required
class ReportsController < ApplicationController
  # Skip authentication - this is a public endpoint
  allow_unauthenticated_access

  def show
    client = Client.find_by!(share_token: params[:share_token])
    service = ClientReportService.new(
      client: client,
      year: params[:year],
      month: params[:month]
    )

    render inertia: "Reports/Show", props: service.report
  end
end
