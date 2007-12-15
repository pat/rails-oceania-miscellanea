module Merb
  VERSION='0.4.2' unless defined?(::Merb::VERSION)
  
  # Merb::RELEASE meanings:
  # 'svn'   : unreleased
  # 'pre'   : pre-release Gem candidates
  #  nil    : released
  # You should never check in to trunk with this changed.  It should
  # stay 'svn'.  Change it to nil in release tags.
  RELEASE='svn' unless defined?(::Merb::RELEASE)
end