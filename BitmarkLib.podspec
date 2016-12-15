Pod::Spec.new do |spec|
  spec.name = "BitmarkLib"
  spec.version = "1.0.0"
  spec.summary = "Bitmark library written on Swift."
  spec.homepage = "https://github.com/bitmark-inc/bitmark-lib-swift"
  spec.license = { type: 'MIT', file: 'LICENSE' }
  spec.authors = { "Bitmark Inc" => 'support@bitmark.com' }
  spec.social_media_url = "https://twitter.com/bitmarkinc"

  spec.platform = :ios, "9.1"
  spec.requires_arc = true
  spec.source = { git: "https://github.com/bitmark-inc/bitmark-lib-swift.git", tag: "v#{spec.version}", submodules: true }
  spec.source_files = "BitmarkLib/**/*.{h,swift}"

  spec.dependency "BigInt", "~> 2.1"
end
