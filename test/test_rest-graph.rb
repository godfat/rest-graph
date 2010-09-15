
$LOAD_PATH << File.dirname(__FILE__)
$LOAD_PATH.uniq!

Dir["#{File.dirname(__FILE__)}/*.rb"].each{ |file|
  next if file == __FILE__
  next if ARGV.map{ |path| File.expand_path(path)
                }.include?(File.expand_path(file))
  require File.basename(file).sub(/\..+$/, '')
}
