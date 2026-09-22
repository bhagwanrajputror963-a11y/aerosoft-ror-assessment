ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

module SignInHelper
  def sign_in_as(user, password: "password123")
    post login_path, params: { email: user.email, password: password }
  end
end

module FragmentCachingHelper
  # Fragment caching is off in the test env by default (no-op cache store),
  # so a test that wants to prove real caching + invalidation behavior
  # needs to opt into a real store for the duration of the block.
  def with_fragment_caching
    original_store = ActionController::Base.cache_store
    original_perform_caching = ActionController::Base.perform_caching

    store = ActiveSupport::Cache::MemoryStore.new
    ActionController::Base.cache_store = store
    ApplicationController.cache_store = store
    ActionController::Base.perform_caching = true

    yield
  ensure
    ActionController::Base.cache_store = original_store
    ApplicationController.cache_store = original_store
    ActionController::Base.perform_caching = original_perform_caching
  end
end

module JobCardHelper
  # Scopes an assertion to a single job card's markup, so "does the page
  # mention Applied anywhere" (too loose when multiple cards are on the
  # page) becomes "does *this job's* card say Applied".
  def within_job_card(job)
    card = Nokogiri::HTML5.fragment(response.body).at_css("a[href='#{Rails.application.routes.url_helpers.job_path(job)}']").ancestors(".card").first
    assert card, "No job card found for #{job.title.inspect} in the response"
    yield card.to_html
  end
end

class ActionDispatch::IntegrationTest
  include SignInHelper
  include FragmentCachingHelper
  include JobCardHelper
end
