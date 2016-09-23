# Shaddox (DEPRECATED)

This project is entirely unfinished. Please don't actually use it.

Ruby gem for provisioning systems. Here's the idea of how it works:

Provisioning/deployment configuration is defined in a Doxfile in the project directory. It might look something like this:
```ruby
server :box1, {
    :address => "0.0.0.0"
    :installer => :apt
}

repo :main, {
    :repository => "https://github.com/foo/bar.git"
}

task :provision do
    install 'tree'
    sh "tree"
    sh "echo 'Hello, world!'"
end

task :deploy do
    target_dir = "~/target-dir"
    auto_deploy_git :main, target_dir
    cd target_dir do
        ls
    end
    symlink "#{target_dir}/current", "~/foobar"
end
```

You could then use shaddox to provision the server `:box1`
```shaddox provision box1```
or your local machine
```shaddox provision local```

To execute provisioning blocks on the target machine, shaddow will generate a shadow script that might look something like this:
```ruby
require 'shaddox/shadow'
Shadow.new(:installer => :apt) do
    ## Begin compiled task ##
    
    install 'tree'
    sh "tree"
    sh "echo 'Hello, world!"
    
    ## End compiled task ##
end
```

Shaddox then asks the target machine to execute the shaddow, ensuring that Ruby and the Shaddox gem are install first (using bootstrap.sh). Typically on remote machines this means SCP'ing a generated shadow over and executing it over SSH.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'shaddox'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install shaddox

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it ( https://github.com/[my-github-username]/shaddox/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
