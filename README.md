# Neutron

Neutron is a mini framework to build desktop app with [Electron](https://electron.atom.io/) and [Ruby](https://www.ruby-lang.org/).
Neutron follow the pattern `MVC` where the `V` is handled by Electron and (if you want) [ReactJS](https://facebook.github.io/react/).
The `MC` can be handled with pure Ruby code.


## Installation

Install it yourself as:

    $ gem install neutron


## Usage

First of all generate a new Neutron project:

    $ neutron project_name

It will generate a new folder with the follow tree
```
.
├── LICENSE.txt
├── README.md
└── src
    ├── Gemfile
    ├── Gemfile.lock
    ├── assets
    │   ├── index.html
    │   ├── javascripts
    │   │   ├── components
    │   │   │   └── neutron_entry_point_component.js
    │   │   └── neutron.js
    │   └── stylesheets
    ├── backend.rb
    ├── main.rb
    ├── main_window.js
    ├── node_modules/
    └── package.json
```
You can run the just generated app with the command:

    $ cd project_name/src
    $ ruby main.rb

- The `main.rb` is the main of your app.
- The `main_window.js` is the Electron entry point file where the [Electron app](https://electron.atom.io/docs/api/app/) and the [main browser window](https://electron.atom.io/docs/api/browser-window/) are created.
- The `backend.rb` is a Ruby class where you can add your instance methods that can be called from the view, from your React components of your Javascript code. This class extends `Neutron::Controller` and looks like this:
```
class MyController < Neutron::Controller
  def ping
    return 'pong'
  end

  def add(a, b)
    return(a + b)
  end
end
```
- The `neutron_entry_point_component.js` is the main component that render all your application.


### Communication between Electron and Ruby

Inside a React component you can import the Neutron module with

    import neutron from 'neutron'

and use neutron to call a controller method like this:

    neutron.send('method_name', [params], options).then((result) => {...}).catch((error) => {...})

You can call a Ruby Controller method with `neutron.send` method that return a JS promise with the return value of the method or an error.

For example you can have a component like this:
```
import React from 'react'
import neutron from 'neutron'

export default class Sum extends React.Component {

  constructor(props) {
    super(props)
    this.state = {}
  }

  sum() {
    const a = parseInt(this.a.value)
    const b = parseInt(this.b.value)
    neutron.send('add', [a, b]).then((result) => {
      this.setState({result: result})
    }).catch((error) => {
      console.log(error)
    })
  }

  render() {
    return(
      <div>
        <p>
          <input ref={(input) => this.a = input}/>
          +
          <input ref={(input) => this.b = input}/>
          = {this.state.result}
        </p>
        <p>
          <button onClick={this.sum.bind(this)}>Calculate</button>
        </p>
      </div>
    )
  }
}
```
In this componenet the sum is calculated by the method `add` in the Ruby controller.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pioz/neutron.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
