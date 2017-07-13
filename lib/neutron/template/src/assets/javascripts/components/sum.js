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
