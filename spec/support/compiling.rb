require 'tmpdir'

module Compiling
  def self.compiler
    @compiler ||= ENV.fetch('CC', 'gcc')
  end

  def self.execute(code)
    Dir.mktmpdir do |directory|
      executable = File.join(directory, 'test')
      output = IO.popen([compiler, include_icu, '-o', executable, *%w(-x c -), :err => [:child, :out]].compact, File::RDWR) do |io|
        io.write(code)
        io.close_write
        io.read
      end

      raise RuntimeError, output unless $?.success?

      %x(#{executable})
    end
  end

  def self.include_icu
    @include_icu ||= "-I#{File.join(ENV['ICU_DIR'], 'include')}" if ENV['ICU_DIR']
  end
end
