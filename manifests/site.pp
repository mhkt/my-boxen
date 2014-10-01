require boxen::environment
require homebrew
require gcc

Exec {
  group       => 'staff',
  logoutput   => on_failure,
  user        => $boxen_user,

  path => [
    "${boxen::config::home}/rbenv/shims",
    "${boxen::config::home}/rbenv/bin",
    "${boxen::config::home}/rbenv/plugins/ruby-build/bin",
    "${boxen::config::home}/homebrew/bin",
    '/usr/bin',
    '/bin',
    '/usr/sbin',
    '/sbin'
  ],

  environment => [
    "HOMEBREW_CACHE=${homebrew::config::cachedir}",
    "HOME=/Users/${::boxen_user}"
  ]
}

File {
  group => 'staff',
  owner => $boxen_user
}

Package {
  provider => homebrew,
  require  => Class['homebrew']
}

Repository {
  provider => git,
  extra    => [
    '--recurse-submodules'
  ],
  require  => File["${boxen::config::bindir}/boxen-git-credential"],
  config   => {
    'credential.helper' => "${boxen::config::bindir}/boxen-git-credential"
  }
}

Service {
  provider => ghlaunchd
}

Homebrew::Formula <| |> -> Package <| |>

node default {
  # core modules, needed for most things
  include dnsmasq
  include git
  include hub
  include nginx

  # fail if FDE is not enabled
  if $::root_encrypted == 'no' {
    fail('Please enable full disk encryption and try again')
  }

  # node versions
  include nodejs::v0_6
  include nodejs::v0_8
  include nodejs::v0_10

  # default ruby versions
  ruby::version { '1.9.3': }
  ruby::version { '2.0.0': }
  ruby::version { '2.1.0': }
  ruby::version { '2.1.1': }
  ruby::version { '2.1.2': }

  # common, useful packages
  package {
    [
      'ack',
      'findutils',
      'gnu-tar'
    ]:
  }

  file { "${boxen::config::srcdir}/our-boxen":
    ensure => link,
    target => $boxen::config::repodir
  }

 # ------ MH CUSTOMIZATIONS ------- 
 include dropbox
 include spotify
 include evernote
 include sublime_text
 include chrome
 include iterm2::dev
 include divvy
 include onepassword
 include iterm2::dev

 sublime_text::package { 'Emmet':
   source => 'sergeche/emmet-sublime'
 }
 sublime_text::package { 'Handlebars':
   source => 'daaain/Handlebars'
 }

 # ensure a gem is installed for all ruby versions
 ruby_gem { 'bundler for all rubies':
   gem          => 'bundler',
   version      => '~> 1.0',
   ruby_version => '*',
 }

 package {
  ['s3cmd']:
 }

 # OSX customizations
 include osx::global::enable_standard_function_keys
 include osx::global::expand_print_dialog
 include osx::global::expand_save_dialog
 include osx::global::tap_to_click
 include osx::dock::autohide
 include osx::dock::clear_dock
 include osx::finder::unhide_library
 include osx::universal_access::ctrl_mod_zoom

 include iterm2::colors::solarized_dark

}
