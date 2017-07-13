// import Events from 'events'
// import net from 'net'
const Events = require('events')
const net = require('net')


let global_jsonrpc_id = 1


class Neutron extends Events.EventEmitter {

  constructor(path = '/tmp/neutron.sock') {
    super()
    this.setMaxListeners(0)
    this.promises = {}
    this.path = path
    this.socket = new net.Socket()
    this.msg = ''

    this.socket.on('data', (data) => {
      const s = data.toString()
      this.msg += s
      if (s[s.length-1] === "\n") {
        const msg = this.msg.slice(0, -1)
        this.msg = ''
        const messages = msg.split("\n")
        for (let i = 0; i < messages.length; i++) {
          try {
            const jsonrpc = JSON.parse(messages[i])
            if (typeof(jsonrpc['id']) !== 'number') {
              this.emit('err', {message: 'Missing id on jsonrpc reply'})
              this.emit('all')
            } else {
              if (jsonrpc['error']) {
                const error = jsonrpc['error']
                error.toString = () => {
                  this.message
                }
                if (jsonrpc['event'])
                  this.emit(`err-${jsonrpc['event']}`, error)
                this.emit(`err-${jsonrpc['id']}`, error)
                this.emit('all')
              } else {
                if (jsonrpc['event'])
                  this.emit(`json-${jsonrpc['event']}`, jsonrpc['result'])
                this.emit(`json-${jsonrpc['id']}`, jsonrpc['result'])
                this.emit('all')
              }
            }
          } catch(error) {
            this.emit('err', {message: 'Error to parse the response'})
            this.emit('all')
          }
        }
      }
    })

    this.socket.on('connect', () => {
      this.emit('connect')
      this.emit('all')
    })

    this.socket.on('end', () => {
      this.emit('end')
      this.emit('all')
      this.reconnect(2000)
    })

    this.socket.on('error', (error) => {
      this.emit('err-connection', error)
      this.emit('err', error)
      this.emit('all')
      this.reconnect(2000)
    })
  }

  connect() {
    // remote.process.on('uncaughtException', (error) => {
    //   this.emit('connection-error', error)
    //   this.emit('all')
    //   this.emit('all-errors')
    //   this.reconnect(2000)
    // })
    this.socket.connect({path: this.path})
  }

  reconnect(timeout = 0) {
    setTimeout(() => {
      console.log('Try to reconnect to the socket ' + this.path + '...')
      this.socket.end()
      this.socket.connect({path: this.path})
    }, timeout)
  }

  close() {
    this.socket.end()
  }

  real_send(method, params, {once = true}) {
    const id = global_jsonrpc_id++
    this.socket.write(JSON.stringify({
      jsonrpc: '2.0',
      method: method,
      params: params,
      once: once,
      id: id
    }) + "\n")
    return id
  }

  send(method, params, {once = true}) {
    const id = this.real_send(method, params, {once: once})
    return new Promise((resolve, reject) => {
      this.on(`json-${id}`, resolve)
      this.on(`err-${id}`, reject)
      this.on('err', reject)
    })
  }

}

const neutron = new Neutron()
neutron.on('connect', () => {
  console.log('Electron connected to Ruby!')
})
neutron.connect()
// export default neutron
module.exports = neutron
