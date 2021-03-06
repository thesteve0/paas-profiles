﻿require 'minitest/autorun'
require 'json'
require 'active_support/core_ext'

require_relative '../models/vendor'

module PaasProfiles
  # create a test class for every profile
  Dir.glob(File.dirname(__FILE__) + '/../profiles/*.json') do |file|
    # filename
    filename = File.basename(file, '.json')

    # test class
    test_class = Class.new(MiniTest::Unit::TestCase) do
      # set file path
      @filepath = file
      # profile
      @profile = nil

      def self.filepath
        @filepath
      end

      # loads and validates profile
      def setup
        begin
          json = JSON.parse(File.read(self.class.filepath))
          @profile = Vendor.new(json)
          # profile validation
          assert(@profile.valid?, @profile.errors.full_messages)
        rescue JSON::ParserError
          assert(@profile != nil, 'JSON structure is not wellformed')
        end
      end

      def teardown
        @profile = nil
      end

      # filename must match lowercase vendor name after replacing [^a-z0-9] with '_'
      define_method('test_filename') do
        exp_name = @profile['name'].downcase.gsub(/[^a-z0-9]/, '_')
        assert_equal(exp_name, filename, 'Filename must match lowercase vendor name without all characters except a-z0-9 replaced by "_"')
      end

      # no runtime (language) duplicates
      define_method('test_runtime_duplicates') do
        uniq_runtimes = @profile.runtimes.uniq { |item| item['language'] }

        assert_equal(uniq_runtimes.length, @profile.runtimes.length, 'There must be no duplicate runtime entries in one profile. Merge them into one entity')
      end

      # no middleware (name) duplicates
      define_method('test_middleware_duplicates') do
        uniq_middleware = @profile.middlewares.uniq { |item| item['name'] }

        assert_equal(uniq_middleware.length, @profile.middlewares.length, 'There must be no duplicate middleware entries in one profile. Merge them into one entity')
      end

      # no framework (name) duplicates
      define_method('test_frameworks_duplicates') do
        uniq_frameworks = @profile.frameworks.uniq { |item| item['name'] }

        assert_equal(uniq_frameworks.length, @profile.frameworks.length, 'There must be no duplicate framework entries in one profile. Merge them into one entity')
      end

      # no native services (name) duplicates
      define_method('test_native_services_duplicates') do
        unless @profile.service.blank? || @profile.service.natives.blank?
          uniq_services = @profile.service.natives.uniq { |item| item['name'] }

          assert_equal(uniq_services.length, @profile.service.natives.length, 'There must be no duplicate native services entries in one profile. Merge them into one entity')
        end
      end

      # no add-on services (name) duplicates
      define_method('test_addon_services_duplicates') do
        unless @profile.service.blank? || @profile.service.addons.blank?
          uniq_services = @profile.service.addons.uniq { |item| item['name'] }

          assert_equal(uniq_services.length, @profile.service.addons.length, 'There must be no duplicate add-on services entries in one profile. Merge them into one entity')
        end
      end

      # no compliance duplicates
      define_method('test_compliance_duplicates') do
        uniq_compliance = @profile.compliance.uniq

        assert_equal(uniq_compliance.length, @profile.compliance.length, 'There must be no duplicate compliance entries in one profile. Remove duplicate values')
      end

      # no hosting duplicates
      define_method('test_hosting_duplicates') do
        uniq_hosting = @profile.hosting.uniq

        assert_equal(uniq_hosting.length, @profile.hosting.length, 'There must be no duplicate hosting entries in one profile. Remove duplicate values')
      end

      # middleware runtime must be present
      define_method('test_middleware_runtime_existence') do
        @profile.middlewares.each do |m|
          unless m['runtime'].blank?
            assert(@profile.runtimes.any? { |r| r['language'] == m['runtime'] }, 'Referenced middleware runtime must be defined under runtimes')
          end
        end
      end

      # framework runtime must be present
      define_method('test_frameworks_runtime_existence') do
        @profile.frameworks.each do |f|
          assert(@profile.runtimes.any? { |r| r['language'] == f['runtime'] }, 'Referenced framework runtime must be defined under runtimes')
        end
      end

      # TODO duplicate versions
      # TODO version formats
      # TODO service types
    end

    # self-descriptive classname
    self.const_set("Test#{filename.capitalize}", test_class)

  end
end