module Grim
  class GhostScriptProcessor

    # ghostscript prints out a warning, this regex matches it
    WarningRegex = /\*\*\*\*.*\n/

    def initialize(options={})
      @ghostscript_path = options[:ghostscript_path]
      @original_path        = ENV['PATH']
    end

    def count(path)
      command = ["-dNODISPLAY", "-q",
        "-sFile=#{Shellwords.shellescape(path)}",
        File.expand_path('../../../lib/pdf_info.ps', __FILE__)]
      @ghostscript_path ? command.unshift(@ghostscript_path) : command.unshift('gs')
      result = `#{command.join(' ')}`
      result.gsub(WarningRegex, '').to_i
    end

    def save(pdf, index, path, options, processor_options)
      quality = options.fetch(:quality, Grim::QUALITY)

      command = [@ghostscript_path, "-q", "-dSAFER", #"-dQUIET",
        "-dBATCH", "-dNOPAUSE", "-dNOPROMPT", "-dMaxBitmap=500000000",
        "-dDOINTERPOLATE", "-dAlignToPixels=0", "-dGridFitTT=2", "-sDEVICE=jpeg",
        "-dTextAlphaBits=4", "-dGraphicsAlphaBits=4", "-dUseCIEColor", "-dNOTRANSPARENCY",
        "-dUseCropBox", "-r#{quality.to_s}", "-dFirstPage=#{index + 1}", "-dLastPage=#{index + 1}",
        "-sOutputFile=#{path}", "#{Shellwords.shellescape(pdf.path)}"]

      command.unshift("PATH=#{File.dirname(@ghostscript_path)}:#{ENV['PATH']}") if @ghostscript_path

      result = `#{command.join(' ')}`

      $? == 0 || raise(UnprocessablePage, result)
    end
  end
end