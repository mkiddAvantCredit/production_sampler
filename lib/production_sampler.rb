require 'production_sampler/production_sampler_error'
require 'production_sampler/version'
require 'hashie'

module ProductionSampler
  class ProductionSampler
    attr_accessor :app_models

    def initialize
      Rails.application.eager_load!
      @app_models = ActiveRecord::Base.descendants.map { |d| d.name }.sort
    end

    def build_hashie(model_spec)
      if model_spec.class != Hashie::Mash
        raise ProductionSamplerError.new('Value passed to build_hashie must be a Hashie::Mash')
      end

       return extract_model(model_spec)
    end

    private

    def extract_model(model_spec)
      model_klass = model_spec[:base_model]

      result = []

      # If no ID numbers are specified, then don't grab any. This is meant to just pull a sample, not a whole table.
      model_items = model_spec[:ids].present? ? model_klass.where(id: model_spec[:ids]) : model_klass.none

      model_items.each do |model_object|
        model_data = filtered_attributes(model_object.attributes, model_spec)

        if model_spec[:associations].present?
          model_spec[:associations].each do |associated_model_spec|
            association_name = associated_model_spec[:association_name]

            associated_model_spec[:base_model] = model_object.send(association_name).klass
            associated_model_spec[:ids] = model_object.send(association_name).pluck(:id)
            if associated_model_spec[:ids].present?
              model_data[association_name] ||= []
              model_data[association_name] = model_data[association_name] + (extract_model(associated_model_spec))
            end
          end
        end

        result << model_data
      end
      return result
    end

    private

    def filtered_attributes(attributes={}, spec)
      if spec[:columns]
        Hashie::Mash.new(attributes.select { |k,v| spec[:columns].include? k.to_sym })
      elsif spec[:exclude_columns]
        Hashie::Mash.new(attributes.reject { |k,v| spec[:exclude_columns].include? k.to_sym})
      else
        Hashie::Mash.new  # didn't whitelist or exclude any columns
      end
    end

  end
end
