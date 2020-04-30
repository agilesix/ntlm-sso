# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "ntlm-sso"
  s.version     = "0.0.1"
  s.authors     = ["rekado"]
  s.email       = ["rekado@elephly.net"]
  s.homepage    = "http://github.com/rekado/ntlm-sso"
  s.license     = 'BSD'

  s.summary     = "Rack authentication module for single sign on via NTLM"
  s.description =<<EOF
  A Rack middleware interface to automatically authenticate users via NTLM.
  This module stores the user name in the environment variable REMOTE_USER upon
  success.  Upon failure the REMOTE_USER variable is either left empty or
  filled with a default value, dependent on configuration. Failure to
  authenticate does not result in an error as authorisation is to be handled by
  your application based on the value in REMOTE_USER.
EOF

  s.rubyforge_project = "N/A"

  s.files         = `git ls-files`.split("\n")
  s.require_paths = ["lib"]

  s.add_runtime_dependency "ruby-ntlm"
end
