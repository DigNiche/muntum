require 'fileutils'

# Generate only the native callback setting; never copy unrelated .env values.
def configure_kakao(project_root)
  environment_path = File.join(project_root, '.env')
  key = ''
  if File.exist?(environment_path)
    File.foreach(environment_path) do |line|
      match = line.match(/^\s*KAKAO_NATIVE_APP_KEY\s*=\s*(.*?)\s*$/)
      next unless match

      key = match[1].sub(/\A(['"])(.*)\1\z/, '\2')
    end
  end
  unless key.empty? || key.match?(/\A[0-9a-fA-F]{32}\z/)
    raise 'KAKAO_NATIVE_APP_KEY must be a 32-character hexadecimal client key in .env'
  end

  scheme = key.empty? ? 'kakaounconfigured' : "kakao#{key}"
  output_path = File.join(project_root, 'ios', 'Flutter', 'Kakao.local.xcconfig')
  FileUtils.mkdir_p(File.dirname(output_path))
  File.write(output_path, "// Generated locally. Do not commit.\nKAKAO_LOGIN_SCHEME = #{scheme}\n")
end

configure_kakao(File.expand_path('..', __dir__)) if $PROGRAM_NAME == __FILE__
