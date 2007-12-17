corelib = __DIR__+'/merb/caching'

%w[ action_cache
    fragment_cache
  ].each {|fn| require File.join(corelib, fn)}