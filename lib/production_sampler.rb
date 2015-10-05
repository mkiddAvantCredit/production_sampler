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

    def build_hashie(sample_model_spec)
      if sample_model_spec.class != Hashie::Mash
        raise ProductionSamplerError.new('Value passed to build_hashie must be a Hashie::Mash')
      end

       return extract_model(sample_model_spec)
    end

    private

    def extract_model(sample_model_spec)
      model_klass = sample_model_spec[:base_model]

      result = []

      # If there's ids, grab the ID's, else grab all
      model_items = sample_model_spec[:ids].present? ? model_klass.where(id: sample_model_spec[:ids]) : model_klass.none

      model_items.each do |model_object|
        model_data = filtered_attributes(model_object.attributes, sample_model_spec[:columns])

        if sample_model_spec[:associations].present?
          sample_model_spec[:associations].each do |associated_model_spec|
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

    def filtered_attributes(attributes={}, columns=[])
      Hashie::Mash.new(attributes.select { |k,v| columns.include? k.to_sym })
    end

  end
end
