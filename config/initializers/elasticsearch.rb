# https://github.com/elastic/elasticsearch-ruby/issues/1429#issuecomment-958162468
module Elasticsearch
  class Client
    def verify_with_version_or_header(*_args)
      @verified = true
    end
  end
end
