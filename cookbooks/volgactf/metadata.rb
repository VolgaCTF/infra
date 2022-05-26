# frozen_string_literal: true

name 'volgactf'
maintainer 'Aleksandr Piatkin'
maintainer_email 'oss@aptkn.ch'
license 'MIT'
description 'Install and configure VolgaCTF infrastructure'
version '0.4.0'

depends 'firewall', '~> 3.0'
depends 'vlt', '~> 0.2'
depends 'nodejs', '~> 7.0'
depends 'ngx', '~> 2.2'
depends 'ngx-modules', '~> 1.3'
depends 'logrotate', '~> 2.2'
depends 'dhparam', '~> 2.0'
depends 'redirect', '~> 4.0'
depends 'redisio', '~> 4.2'
depends 'geolite2', '~> 2.2'
depends 'graphicsmagick', '~> 0.1'
depends 'postgresql', '~> 9.1'
depends 'git', '~> 10.1'
depends 'volgactf-qualifier', '~> 2.3'
depends 'ulimit', '~> 1.1'
depends 'ssmtp-lwrp', '~> 0.2'
depends 'cronic', '~> 2.0'
depends 'netdata', '~> 0.4'
depends 'ruby_rbenv', '~> 4.0'
depends 'volgactf-final', '~> 1.5'
depends 'docker', '~> 8.2'
