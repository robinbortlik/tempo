class HomeController < ApplicationController
  def index
    render inertia: "Home", props: {
      message: "Time tracking & invoicing"
    }
  end
end
