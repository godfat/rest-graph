
Dir["#{File.dirname(__FILE__)}/*.rb"].each{ |file|
  next if file == __FILE__

  if respond_to?(:require_relative, true)
    require_relative File.basename(file)
  else
    require file
  end
}
