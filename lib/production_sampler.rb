require "production_sampler/version"

module ProductionSampler
  class ProductionSampler
    attr_accessor :app_models

    def initialize
      Rails.application.eager_load!
      @app_models = ActiveRecord::Base.descendants.map { |d| d.name }.sort
    end
  end
end
