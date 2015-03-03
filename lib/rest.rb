module Rest
  def self.ruby_major
    RUBY_VERSION.split('.')[0].to_i
  end
  def self.ruby_minor
    RUBY_VERSION.split('.')[1].to_i
  end
end

unless Kernel.respond_to?(:require_relative)
  module Kernel
    p "using require relative shim"
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end
# 1.8 support
if Rest.ruby_major == 1 && Rest.ruby_minor == 8
  require 'rubygems'
  gem 'json'
end

require "pry"

require 'rest/errors'
require 'rest/wrappers/base_wrapper'
require 'rest/wrappers/internal_client_wrapper'
require 'rest/client'
