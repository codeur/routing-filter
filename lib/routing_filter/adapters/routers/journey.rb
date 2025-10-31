# frozen_string_literal: true

# Prepend the method lookup to intercept find_routes in rails.
#
# This enables us to intercept the incoming route paths before they are
# recognized by the rails router and transformed to a route set and dispatched
# to a controller.
module ActionDispatchJourneyRouterWithFiltering
  # NOTE: `find_routes`` was inlined as `recognize` in Rails 8.1+
  def recognize(req, &block)
    path = req.path_info

    filter_parameters = {}
    original_path = path.dup

    # Apply the custom user around_recognize filter callbacks
    @routes.filters.run(:around_recognize, path, req.env) do
      # Yield the filter parameters for adjustment by the user
      filter_parameters
    end

    # Recognize the routes
    super(req) do |route, parameters|
      # Merge in custom parameters that will be visible to the controller
      params = (parameters || {}).merge(filter_parameters)

      # Reset the path before yielding to the controller (prevents breakages in CSRF validation)
      req.path_info = original_path

      # Yield results are dispatched to the controller
      yield [route, params]
    end
  end
end

ActionDispatch::Journey::Router.prepend(ActionDispatchJourneyRouterWithFiltering)
