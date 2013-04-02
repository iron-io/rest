module Rest
  def self.ruby_major
    RUBY_VERSION.split('.')[0].to_i
  end
  def self.ruby_minor
    RUBY_VERSION.split('.')[1].to_i
  end
end

# 1.8 support
if Rest.ruby_major == 1 && Rest.ruby_minor == 8
  require 'rubygems'
  gem 'json'
end

require File.expand_path('rest/client', File.dirname(__FILE__))
