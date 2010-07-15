Raki::Plugin.register /^red|blue|green|yellow|grey|black|white|[0-9a-f]{3}|[0-9a-f]{6}$/i do
  
  name 'Color Plugin'
  description 'Changes the text color'
  url 'http://github.com/ydkn/raki'
  author 'Florian Schwab'
  version '0.1'
  
  execute do
    colors = {
        :red => 'f00',
        :green => '0f0',
        :blue => '00f',
        :yellow => 'ff0',
        :grey => 'aaa',
        :black => '000',
        :white => 'fff'
      }
      
    if callname.to_s =~ /^[0-9a-f]{3}|[0-9a-f]{6}$/i
      "<font style=\"color:##{callname.to_s};\">#{body}</font>"
    elsif colors.key? callname.to_sym
      "<font style=\"color:##{colors[callname.to_sym]};\">#{body}</font>"
    else
      raise Raki::Plugin::PluginError.new t 'color.invalid_color'
    end
  end
  
end
