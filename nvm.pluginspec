Jenkins::Plugin::Specification.new do |plugin|
  plugin.name = 'nvm'
  plugin.display_name = 'NVM Build Environment'
  plugin.version = '0.3'
  plugin.description = 'Run Jenkins builds in NVM environment'

  plugin.url = 'https://wiki.jenkins-ci.org/display/JENKINS/NVM+Plugin'
  plugin.developed_by 'Tim Fischbach', 'tfischbach@codevise.de'
  plugin.uses_repository :github => 'codevise/jenkins-nvm-plugin'

  plugin.depends_on 'ruby-runtime', '0.12'
  plugin.depends_on 'token-macro', '1.9'
end
