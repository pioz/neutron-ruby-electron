require 'neutron/backend'

class Backend < Neutron::Backend

  def add(a, b)
    return a + b
  end

end
