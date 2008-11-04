require 'active_support'

module Machinist
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    def blueprint(&blueprint)
      @blueprint = blueprint
    end
  
    def make(attributes = {})
      lathe = make_lathe attributes
      lathe.object.save!
      returning(lathe.object.reload) do |object|
        yield object if block_given?
      end
    end

    def make_params(attributes = {})
      lathe = make_lathe attributes
      lathe.object.attributes
    end

    private

    def make_lathe(attributes = {})
      raise "No blueprint for class #{self}" if @blueprint.nil?
      lathe = Lathe.new(self.new, attributes)
      lathe.instance_eval(&@blueprint)
      lathe
    end

  end
  
  class Lathe
    def initialize(object, attributes)
      @object = object
      @assigned_attributes = []
      attributes.each do |key, value|
        @object.send("#{key}=", value)
        @assigned_attributes << key
      end
    end

    attr_reader :object

    def method_missing(symbol, *args, &block)
      if @assigned_attributes.include?(symbol)
        @object.send(symbol)
      else
        value = if block
          block.call
        elsif args.first.is_a?(Hash) || args.empty?
          symbol.to_s.camelize.constantize.make(args.first || {})
        else
          args.first
        end
        @object.send("#{symbol}=", value)
        @assigned_attributes << symbol
      end
    end
  end
end
