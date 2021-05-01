Gem::Specification.new do |s|
  s.name = 'coinquery'
  s.version = '0.2.0'
  s.summary = 'Uses the Coingecko API. Inspired by the coingecko_client gem'
  s.authors = ['James Robertson']
  s.files = Dir['lib/coinquery.rb']
  s.add_runtime_dependency('excon', '~> 0.81', '>=0.81.0')
  s.add_runtime_dependency('unichron', '~> 0.3', '>=0.3.4')
  s.add_runtime_dependency('recordx_sqlite', '~> 0.3', '>=0.3.3')
  s.signing_key = '../privatekeys/coinquery.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'digital.robertson@gmail.com'
  s.homepage = 'https://github.com/jrobertson/coinquery'
end
