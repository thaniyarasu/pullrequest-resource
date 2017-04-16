require 'json'
require 'ostruct'
require 'json'

class Input
  class Params < OpenStruct
    class Merge < OpenStruct
      def method
        self['method']
      end
    end

    def merge
      Merge.new(self['merge'] || {})
    end

    def git
      OpenStruct.new(self['git'] || {})
    end
  end

  def self.instance(payload: nil)
    @instance = new(payload: payload) if payload
    @instance ||= begin
                    payload = JSON.parse(ARGF.read)
                    payload ||= JSON.parse(File.read("ci/job.json")) if ENV['DEV']
                    new(payload: payload)
                  end
  end

  def self.reset
    @instance = nil
  end

  def initialize(payload:)
    @payload = payload
  end

  def source
    OpenStruct.new @payload.fetch('source', {})
  end

  def version
    OpenStruct.new @payload.fetch('version', {})
  end

  def params
    Params.new @payload.fetch('params', {})
  end
end
