require 'grit'

module Grit
  module GitRuby
    class Repository
      # Added support for :until
      def rev_list(sha, options)
        if sha.is_a? Array
          (end_sha, sha) = sha
        end

        log = log(sha, options)
        log = log.sort { |a, b| a[2] <=> b[2] }.reverse

        if end_sha
          log = truncate_arr(log, end_sha)
        end

        if options[:until]
          limit = Time.parse(options[:until])
          while log.length > 0
            if log[0][2] > limit
              log.shift
            else
              break
            end
          end
        end

        # shorten the list if it's longer than max_count (had to get everything in branches)
        if options[:max_count]
          if (opt_len = options[:max_count].to_i) < log.size
            log = log[0, opt_len]
          end
        end
        if options[:pretty] == 'raw'
          log.map {|k, v| v }.join('')
        else
          log.map {|k, v| k }.join("\n")
        end
      end
    end
  end
end
