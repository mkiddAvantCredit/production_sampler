require 'production_sampler/production_sampler_error'
require 'production_sampler/version'
require 'hashie'
require 'money-rails'

module ProductionSampler
  class ProductionSampler
    attr_accessor :app_models

    def initialize(load_models: nil)
      if load_models.nil?
        # load everything
        Rails.application.eager_load!
      else
        # load only the specified models
        load_models.each { |m| load_model(m) }
      end
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
      filtered_klass = model_spec[:base_model]
      filtered_klass = filtered_klass.send(model_spec[:scope]) if model_spec[:scope]
      if model_spec[:where]
        filtered_klass = filtered_klass.where(model_spec[:where][:expression], *model_spec[:where][:parameters])
      end

      result = []

      # If no ID numbers are specified, then don't grab any. This is meant to just pull a sample, not a whole table.
      model_objects = model_spec[:ids].present? ? filtered_klass.where(id: model_spec[:ids]) : filtered_klass.none

      model_objects.each do |obj|
        model_data = filtered_attributes(obj, model_spec)

        if model_spec[:associations].present?
          model_spec[:associations].each do |associated_model_spec|
            association_name = associated_model_spec[:association_name]

            associated_model_spec[:base_model] = obj.send(association_name).klass

            associated_model_spec[:ids] = obj.send(association_name).pluck(:id)
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

    def filtered_attributes(object, spec)
      if spec[:columns]   # user specifies a whitelist
        attr = Hashie::Mash.new
        spec[:columns].each do |col_name|
          attr.merge!(col_name => object.send(col_name)) if object.respond_to?(col_name)
        end
        return attr
      elsif spec[:exclude_columns]   # user specifies columns to be exclude
        Hashie::Mash.new(object.attributes.reject { |k,_v| spec[:exclude_columns].include? k.to_sym})
      else
        Hashie::Mash.new  # didn't whitelist or exclude any columns
      end
    end

    def load_model(model_name)
      model_name.constantize.inspect
    end

  end
end
