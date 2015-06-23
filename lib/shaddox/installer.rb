module Shaddox

  class Installer
    def self.autodetect(pvr)
      return AptInstaller.new(pvr) if pvr.availiable? "apt-get"
      return BrewInstaller.new(pvr) if pvr.availiable? "brew"
      return PacmanInstaller.new(pvr) if pvr.availiable? "pacman"
      warn "Installer could not be automatically identified.", 1
      require 'highline/import'
      choose do |menu|
        menu.prompt = "Please select a package manager to use:"

        menu.choice(:manual) { return ManualInstaller.new(pvr) }
        menu.choice(:apt) { return AptInstaller.new(pvr) }
        menu.choice(:brew) { return BrewInstaller.new(pvr) }
      end
    end
    def initialize(pvr)
      @pvr = pvr
    end
    def install(package)
      raise "This should be implemented by subclass."
    end
    def installed?(cmd)
      @pvr.availiable?(cmd)
    end
  end

  class ManualInstaller < Installer
    def install(package)
      return if installed?(package)
      puts "Please install '#{package}' manually."
      gets
      raise "Could not install #{package}" unless installed?(package)
    end
  end

  class AptInstaller < Installer
    # def initialize(pvr)
    #   super(pvr)
    #   @pvr.exec("sudo apt-get update")
    # end
    def install(package)
      return if installed?(package)
      @pvr.exec("sudo apt-get install #{package}")
      raise "Could not install #{package}" unless installed?(package)
    end
  end

  class BrewInstaller < Installer
    # def initialize(pvr)
    #   super(pvr)
    #   @pvr.exec("brew update")
    # end
    def install(package)
      return if installed?(package)
      @pvr.exec("brew install #{package}")
      raise "Could not install #{package}" unless installed?(package)
    end
  end

  class PacmanInstaller < Installer
    # def initialize(pvr)
    #   super(pvr)
    #   @pvr.exec("pacman -Sy")
    # end
    def install(package)
      return if installed?(package)
      @pvr.exec("pacman -S #{package}")
      raise "Could not install #{package}" unless installed?(package)
    end
  end

end
