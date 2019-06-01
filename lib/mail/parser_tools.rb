module Mail
  # Extends each field parser with utility methods.
  module ParserTools #:nodoc:
    # Slice bytes from ASCII-8BIT data and mark as UTF-8.
    if 'string'.respond_to?(:force_encoding)
      def chars(data, from_bytes, to_bytes)
        data.slice(from_bytes..to_bytes).force_encoding(Encoding::UTF_8)
      end
    else
      def chars(data, from_bytes, to_bytes)
        data.slice(from_bytes..to_bytes)
      end
    end

    RAGEL_VARS = [:@_trans_keys, :@_key_spans, :@_index_offsets, :@_indicies,
                  :@_trans_targs, :@_trans_actions, :@_eof_actions]

    class Array8
      def initialize(arr)
        @str = arr.pack("c*").freeze
      end

      def [](idx)
        @str.getbyte(idx)
      end
    end

    class Array16
      def initialize(arr)
        @low  = arr.map{ |x| x & 0xff }.pack("c*").freeze
        @high = arr.map{ |x| x >> 8 }.pack("c*").freeze
      end

      def [](idx)
        (@high.getbyte(idx) << 8) | @low.getbyte(idx)
      end
    end

    def optimize_ragel_data!
      (instance_variables & RAGEL_VARS).each do |var|
        array = instance_variable_get(var)
        max = array.max

        next if array.size <= 8

        array =
          if max < 2**8
            Array8.new(array)
          elsif max < 2**16
            Array16.new(array)
          else
            array
          end

        instance_variable_set(var, array)
      end
    end
  end
end
