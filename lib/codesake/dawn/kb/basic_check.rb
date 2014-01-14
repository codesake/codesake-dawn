require 'cvss'

module Codesake
  module Dawn
    module Kb
      module BasicCheck

        include Codesake::Dawn::Utils

        attr_reader :name
        attr_reader :cvss
        attr_reader :cwe
        attr_reader :owasp
        attr_reader :release_date
        attr_reader :applies
        attr_reader :kind
        attr_reader :message
        attr_reader :remediation
        attr_reader :aux_links
        attr_reader :mitigated

        # This is the ruby version used by the target application. set in
        # Engine class around line #107
        attr_accessor :ruby_version

        # This is an array of ruby versions that lead a parcitular version to
        # be exploitable.
        # In example, consider CVE-2013-1655, the Puppet rubygem version
        # vulnerability can be exploited only if ruby version is 1.9.3 or
        # higher
        attr_reader :ruby_vulnerable_versions

        # The framework target version
        attr_reader   :target_version
        # The versions of the framework that fixes the vulnerability
        attr_reader   :fixes_version

        # Vulnerability evidences
        attr_reader   :evidences

        # Check status. Returns the latest vuln? call result
        attr_reader   :status

        # Put the check in debug mode
        attr_accessor :debug

        def initialize(options={})
          @applies                  = []
          @ruby_version             = ""
          @ruby_vulnerable_versions = []
          @name         = options[:name]
          @cvss         = options[:cvss]
          @cwe          = options[:cwe]
          @owasp        = options[:owasp]
          @release_date = options[:release_date]
          @applies      = options[:applies] unless options[:applies].nil?
          @kind         = options[:kind]
          @message      = options[:message]
          @remediation  = options[:mitigation]
          @aux_links    = options[:aux_links]

          @target_version = options[:target_version]
          @fixes_version  = options[:fixes_version]
          @ruby_version   = options[:ruby_version]

          @evidences    = []
          @mitigated    = false
          @status       = false
          @debug        = false

        end

        def applies_to?(name)
          ! @applies.find_index(name).nil?
        end
        def cve_link
          "http://cve.mitre.org/cgi-bin/cvename.cgi?name=#{@name}"
        end
        def nvd_link
          "http://web.nvd.nist.gov/view/vuln/detail?vulnId=#{@name}"
        end

        # Public: checks if the ruby version used for target application works a pre-requisite to exploit a particular vulnerability.
        #
        #   Take the CVE-2013-1655 as example. The Puppet rubygem vulnerability
        #   can be exploited only if the ruby version is 1.9.3 or following. For
        #   such a reason this method will check for the ruby version used by the
        #   target.
        #
        # Returns:
        #   true if the running ruby is vulnerable or false otherwise
        def is_ruby_vulnerable_version?
          return false if @ruby_vulnerable_versions.nil?

          found = false


          @ruby_vulnerable_versions.each do |v|
            found = true if v == @ruby_version
          end

          found
        end

        # @target_version = '2.3.11'
        # @fixes_version = ['2.3.18', '3.2.13', '3.1.12' ]
        def is_vulnerable_version?(target = nil, fixes = nil)
          target  = @target_version if target.nil?
          fixes   = @fixes_version  if fixes.nil?

          vulnerable = false

          return vulnerable if target.nil? || fixes.empty?

          target_v_array = target.split(".").map! { |n| n.to_i }
          fixes.each do |fv|
            fixes_v_array = fv.split(".").map! { |n| n.to_i }

            debug_me "target_array = #{target_v_array}"
            debug_me "fixes_array = #{fixes_v_array}"
            if target_v_array[0] == fixes_v_array[0]
              vulnerable = true if target_v_array[1] < fixes_v_array[1] # same major but previous minor
              if target_v_array[1] == fixes_v_array[1]
                vulnerable = true if target_v_array[2] < fixes_v_array[2]
                debug_me "target array count = #{target_v_array.count}"
                debug_me "fixes array count = #{fixes_v_array.count}"
                debug_me "same patchlevel?: #{(target_v_array[2] == fixes_v_array[2])}"
                case
                when target_v_array.count == 4 && fixes_v_array.count == 4 &&
                  target_v_array[2] == fixes_v_array[2]
                then
                  # In order to support CVE-2013-7086 security check we must be
                  # able to handle the 'fourth' version number -> 1.5.0.4
                  vulnerable = true if target_v_array[3] < fixes_v_array[3]
                  vulnerable = false if target_v_array[3] >= fixes_v_array[3]
                when target_v_array[2] >= fixes_v_array[2]
                  vulnerable = false
                else
                  vulnerable = true
                end
              end
            end
            debug_me("RET IS #{vulnerable}")
          end

          vulnerable
        end

        def cvss_score
          return Cvss::Engine.new.score(self.cvss) unless self.cvss.nil?
          "    "
        end

        def mitigated?
          self.mitigated
        end

      end
    end
  end
end
