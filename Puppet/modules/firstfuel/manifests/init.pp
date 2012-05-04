class firstfuel::web {
  package { 'gcc-c++': ensure => latest }
  package { make: ensure => latest }
  package { mysql: ensure => latest }
  package { mysql-devel: ensure => latest }
  package { sqlite-devel: ensure => latest }
  package { readline-devel: ensure => latest }
  package { libxml2: ensure => latest }
  package { libxml2-devel: ensure => latest }
  package { libyaml-devel: ensure => latest }
  package { subversion: ensure => latest }
  package { git: ensure => latest }
  package { mod_dav_svn: ensure => latest }
  package { ImageMagick: ensure => latest }
  package { ImageMagick-devel: ensure => latest }
  package { rubygems: ensure => latest }
  file { 'foo.bar':
    path => '/etc/foo.bar',
    ensure => file,
    source => 'puppet:///modules/firstfuel/foo.bar',
  }
  exec {
	"gem install mysql":
	path => "/bin:/usr/bin",
	user => root,
	group => root,
	alias => "install_gems",
	require => Package["rubygems"],
  }
}
