class DashboardController < ApplicationController
  def show
    service = DashboardStatsService.new

    render inertia: "Dashboard/Index", props: {
      stats: service.stats,
      main_currency: Setting.instance.main_currency,
      charts: {
        time_by_client: service.time_by_client,
        time_by_project: service.time_by_project,
        earnings_over_time: service.earnings_over_time,
        hours_trend: service.hours_trend
      }
    }
  end

  # JSON endpoints for dynamic chart updates
  def time_by_client
    render json: DashboardStatsService.new.time_by_client
  end

  def time_by_project
    render json: DashboardStatsService.new.time_by_project
  end

  def earnings_over_time
    months = params[:months]&.to_i || 12
    render json: DashboardStatsService.new.earnings_over_time(months: months)
  end

  def hours_trend
    months = params[:months]&.to_i || 12
    render json: DashboardStatsService.new.hours_trend(months: months)
  end
end
