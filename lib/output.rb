require 'erb'
require 'ostruct'

def render_erb(template, hash, output_file = nil)
  erb = File.read(File.join(__dir__, 'templates', "#{template}.erb"))
  File.open(output_file || template, 'w') do |f|
    f.print(ERB.new(erb).result(OpenStruct.new(hash).instance_eval { binding }))
  end
end
