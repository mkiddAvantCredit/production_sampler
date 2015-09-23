$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
ENV["RAILS_ENV"] = "test"
ENV["RAILS_ROOT"] = File.expand_path("../dummy")

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"
require 'production_sampler'
Rails.backtrace_cleaner.remove_silencers!
