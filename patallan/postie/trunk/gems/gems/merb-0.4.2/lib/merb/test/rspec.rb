require 'hpricot'
require 'spec'
module Merb
  module Test
    module MerbRspecControllerRedirect
      class BeRedirect
        def matches?(target)
          @target = target
          target == 302
        end
        def failure_message
          "expected to redirect"
        end
        def negative_failure_message
          "expected not to redirect"
        end
      end

      class Redirect
        def matches?(target)
          @target = target
          BeRedirect.new.matches?(target.status)
        end
        def failure_message
          "expected #{@target.inspect} to redirect"
        end
        def negative_failure_message
          "expected #{@target.inspect} not to redirect"
        end
      end

      class RedirectTo
        def initialize(expected)
          @expected = expected
        end

        def matches?(target)
          @target = target.headers['Location']
          @redirected = BeRedirect.new.matches?(target.status)
          @target == @expected
        end

        def failure_message
          msg = "expected a redirect to <#{@expected}>, but "
          if @redirected
            msg << "found one to <#{@target}>" 
          else
            msg << "there was no redirect"
          end
        end

        def negative_failure_message
          "expected not to redirect to <#{@expected}>, but did anyway"
        end
      end

      def be_redirect
        BeRedirect.new
      end

      def redirect
        Redirect.new
      end

      def redirect_to(expected)
        RedirectTo.new(expected)
      end
    end
      
    module RspecMatchers
      class HaveSelector
        def initialize(expected)
          @expected = expected
        end
    
        def matches?(stringlike)
          @document = case stringlike
          when Hpricot::Elem
            stringlike
          when StringIO
            Hpricot.parse(stringlike.string)
          else
            Hpricot.parse(stringlike)
          end
          !@document.search(@expected).empty?
        end
    
        def failure_message
          "expected following text to match selector #{@expected}:\n#{@document}"
        end

        def negative_failure_message
          "expected following text to not match selector #{@expected}:\n#{@document}"
        end
      end
  
      class MatchTag
        def initialize(name, attrs)
          @name, @attrs = name, attrs
          @content = @attrs.delete(:content)
        end

        def matches?(target)
          @errors = []
          unless target.include?("<#{@name}")
            @errors << "Expected a <#{@name}>, but was #{target}"
          end
          @attrs.each do |attr, val|
            unless target.include?("#{attr}=\"#{val}\"")
              @errors << "Expected #{attr}=\"#{val}\", but was #{target}"
            end
          end
          if @content
            unless target.include?(">#{@content}<")
              @errors << "Expected #{target} to include #{@content}"
            end
          end
          @errors.size == 0
        end
    
        def failure_message
          @errors[0]
        end
    
        def negative_failure_message
          "Expected not to match against <#{@name} #{@attrs.map{ |a,v| "#{a}=\"#{v}\"" }.join(" ")}> tag, but it matched"
        end
      end
  
      class NotMatchTag
        def initialize(attrs)
          @attrs = attrs
        end
    
        def matches?(target)
          @errors = []
          @attrs.each do |attr, val|
            if target.include?("#{attr}=\"#{val}\"")
              @errors << "Should not include #{attr}=\"#{val}\", but was #{target}"
            end
          end
          @errors.size == 0
        end
    
        def failure_message
          @errors[0]
        end
      end
  
      def match_tag(name, attrs)
        MatchTag.new(name, attrs)
      end
      def not_match_tag(attrs)
        NotMatchTag.new(attrs)
      end
  
      def have_selector(expected)
        HaveSelector.new(expected)
      end
      alias_method :match_selector, :have_selector
      # alias_method :match_regex, :match
    end
  end
end