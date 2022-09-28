# typed: true
# frozen_string_literal: true
# rHCL original credit to http://github.com/winebarrel/rhcl/fork

module GeoEngineer

  module Utils
    # Hashicorp Configuration Language serializer
    class HCLDump
      class << self
        extend T::Sig

        sig { params(obj: Object).returns(String) }
        def dump(obj)
          raise TypeError, "wrong argument type #{obj.class} (expected Hash)" unless obj.is_a?(Hash)

          dump_private(obj).sub(/\A\s*\{/, '').sub(/\}\s*\z/, '').strip.gsub(/^\s+$/m, '')
        end

        private

        sig { params(obj: Object, depth: Integer).returns(String) }
        def dump_private(obj, depth = 0)
          prefix = '  ' * depth
          prefix0 = '  ' * (depth.zero? ? 0 : depth - 1)

          case obj
          when Array
            "[#{obj.map { |i| dump_private(i, depth + 1) }.join(', ')}]\n"
          when Hash
            contents = obj.map do |k, v|
              k = k.to_s.strip
              k = k.inspect unless k =~ /\A\w+\z/
              k + (v.is_a?(Hash) ? ' ' : " = ") + dump_private(v, depth + 1).strip
            end

            "#{prefix}{\n#{prefix}#{contents.join("\n#{prefix}")}\n#{prefix0}}\n"
          when Numeric, TrueClass, FalseClass
            obj.inspect
          else
            obj.to_s.inspect
          end
        end
      end
    end
  end
end